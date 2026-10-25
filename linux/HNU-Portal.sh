#!/usr/bin/env bash
#
# HNU-Portal.sh —— 校园网自动保活（Linux 单文件版）
#
# 用法:
#   sudo ./HNU-Portal.sh            交互菜单（推荐）
#   sudo ./HNU-Portal.sh run        执行一次检测/重认证（供 systemd / cron 调用）
#        ./HNU-Portal.sh selftest   只读探测，不改动系统（不需要 root）
#        ./HNU-Portal.sh --help
#        ./HNU-Portal.sh --version
#
# 安装后落点:
#   程序   /usr/local/bin/hnu-portal
#   配置   /etc/hnu-portal/user 、 /etc/hnu-portal/pass     (600 root)
#   日志   /var/log/hnu-portal.log
#   调度   systemd timer；无 systemd 时自动退回 /etc/cron.d/hnu-portal
#
# 认证方式:
#   检测到掉线后，向校园网门户的登录接口提交一次认证请求，成功即恢复。
#   接口地址见下方 PORTAL_HOST / PORTAL_PORT；门户升级导致地址变化时改这两处。
#
# 可移植性要点:
#   - 不再写死固定网段，改为"按到门户的路由"自动定位网卡:
#       ip route get <门户IP>  →  dev / src
#   - DNS 失效时用缓存的 portal IP + curl --resolve 兜底
#   - 探测重试 3 次仍为 000 时，不直接判死：先看门户是否可达，可达就照常登录
#     （未认证时 DNS 常被挡，或者被代理软件劫持成 fake-IP，这两种都不是真断网）
#   - 解析到的门户地址必须过校验（回环/链路本地/组播/198.18.x 等一律不采纳、不入缓存）
#   - 账号/密码存 600 root；密码输入不回显，明文不落脚本
#
# v1.0.3 变更:
#   探针不再走域名。VPN/代理软件会把域名解析成 198.18.0.0/15 这类 fake-IP，
#   请求被隧道接管，于是"VPN 能不能上网"冒充了"校园网通不通"——校园网断了
#   探针照样回 204，脚本就地退出、永不重认证。改用固定公网 IP 直连，
#   并用响应里的对端地址反查是否被劫持。
#
# v1.0.4 变更:
#   门户地址改为"缓存优先"：缓存里的地址只要还能自证是门户就直接用，不再先问 DNS。
#   原来是 DNS 优先、缓存兜底，DNS 一旦被劫持到一个"格式合法"的地址（不一定落在
#   198.18.x），就会覆盖缓存；新解析出的地址也必须真的返回门户页面才允许写进缓存。

set -u

VERSION='1.0.4'

PORTAL_HOST='web.hnu.edu.cn'
PORTAL_PORT='801'
PROBE_URLS='http://223.5.5.5/ http://119.29.29.29/'

CONF_DIR='/etc/hnu-portal'
USER_FILE="$CONF_DIR/user"
PASS_FILE="$CONF_DIR/pass"
LOG_FILE='/var/log/hnu-portal.log'
LOCK_FILE='/run/hnu-portal.lock'
IP_CACHE='/run/hnu-portal.ip'
MAC_CACHE='/run/hnu-portal.mac'
BIN_PATH='/usr/local/bin/hnu-portal'

UNIT_DIR='/etc/systemd/system'
UNIT_SVC="$UNIT_DIR/hnu-portal.service"
UNIT_TMR="$UNIT_DIR/hnu-portal.timer"
CRON_FILE='/etc/cron.d/hnu-portal'

# 旧版（v1~v3）遗留路径，安装时自动迁移
LEGACY_USER='/etc/hnu-portal.user'
LEGACY_PASS='/etc/hnu-portal.pass'
LEGACY_BIN='/usr/local/bin/hnu-portal-keepalive.sh'

# ---------------------------------------------------------------- 输出 ----
if [ -t 1 ]; then
    C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_CYA=$'\033[36m'; C_OFF=$'\033[0m'
else
    C_RED=''; C_GRN=''; C_YEL=''; C_CYA=''; C_OFF=''
fi

say()  { printf '%s\n' "$*"; }
ok()   { printf '%s[OK]%s %s\n'   "$C_GRN" "$C_OFF" "$*"; }
bad()  { printf '%s[!!]%s %s\n'   "$C_RED" "$C_OFF" "$*"; }
warn() { printf '%s[??]%s %s\n'   "$C_YEL" "$C_OFF" "$*"; }
note() { printf '     %s\n' "$*"; }
pause_() { printf '\n按回车继续...'; read -r _ || true; printf '\n'; }

usage() {
    cat <<EOF
HNU-Portal.sh v$VERSION —— 湖南大学校园网自动保活（Linux）

用法:
  sudo ./HNU-Portal.sh            交互菜单
  sudo ./HNU-Portal.sh run        执行一次检测/重认证
       ./HNU-Portal.sh selftest   只读探测本机网络与门户可达性
       ./HNU-Portal.sh --help | --version

安装后:
  程序 $BIN_PATH
  配置 $CONF_DIR/{user,pass}
  日志 $LOG_FILE
  调度 systemd timer（无 systemd 则用 $CRON_FILE）
EOF
}

need_root() {
    if [ "$(id -u)" -eq 0 ]; then return 0; fi
    if command -v sudo >/dev/null 2>&1; then
        say "需要管理员权限，正在通过 sudo 重新执行..."
        exec sudo -E bash "$0" "$@"
    fi
    bad "需要 root 权限（请用 sudo 运行）"
    exit 1
}

# ---------------------------------------------------------------- 依赖 ----
have() { command -v "$1" >/dev/null 2>&1; }

ensure_curl() {
    have curl && return 0
    warn "未找到 curl，尝试安装..."
    if   have apt-get; then apt-get update -qq && apt-get install -y -qq curl
    elif have dnf;     then dnf install -y -q curl
    elif have yum;     then yum install -y -q curl
    elif have zypper;  then zypper -n install curl
    elif have apk;     then apk add --no-cache curl
    elif have pacman;  then pacman -Sy --noconfirm curl
    else bad "无法自动安装 curl，请手动安装后重试"; return 1
    fi >/dev/null 2>&1
    have curl && { ok "curl 已安装"; return 0; }
    bad "curl 安装失败"; return 1
}

# ------------------------------------------------------------ 网络探测 ----
# 安全写缓存：文件不可写时（非 root）静默跳过，不打印 shell 重定向错误
cache_put() {
    ( printf '%s\n' "$2" > "$1" ) 2>/dev/null || true
}

# 地址可信性校验：回环、链路本地、组播/保留段、代理软件 fake-IP 段一律不采纳。
# 这些地址一旦被当成门户地址，登录请求必然发进黑洞，看上去就像"认证失败"。
valid_ip() {
    case "$1" in
        ''|0.*|127.*|169.254.*|198.18.*|198.19.*|2[2-5][0-9].*|255.*) return 1 ;;
    esac
    printf '%s' "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || return 1
    local o
    for o in $(printf '%s' "$1" | tr '.' ' '); do
        case "$o" in ''|*[!0-9]*) return 1 ;; esac
        [ "$((10#$o))" -le 255 ] || return 1
    done
    return 0
}

# 不依赖 DNS，直接用 IP 判断门户是否可达：可达说明链路正常，只是还没认证
portal_reachable() {
    local ip code
    ip=${1:-}
    valid_ip "$ip" || return 1
    code=$(curl -4 --noproxy '*' -s -m 6 --connect-timeout 3 -o /dev/null -w '%{http_code}' \
           --resolve "$PORTAL_HOST:$PORTAL_PORT:$ip" \
           "http://$PORTAL_HOST:$PORTAL_PORT/eportal/" 2>/dev/null)
    [ -n "$code" ] || code='000'
    [ "$code" != '000' ]
}

# 确认地址背后真的是认证门户：HTTP 200 且页面带 EPortal 特征。
# 只校验 IP 格式不够：DNS 被劫持（或域名恰好有公网记录）时，
# 一个格式完全合法的地址照样会被当成门户，写进缓存后每次登录都发错地方。
portal_identity() {
    local ip=${1:-} body
    valid_ip "$ip" || return 1
    body=$(curl -4 --noproxy '*' -s -m 8 --connect-timeout 3 \
           --resolve "$PORTAL_HOST:$PORTAL_PORT:$ip" \
           "http://$PORTAL_HOST:$PORTAL_PORT/eportal/" 2>/dev/null)
    [ -n "$body" ] || return 1
    printf '%s' "$body" | grep -qi 'eportal'
}

# 域名解析出的候选地址（去重）
portal_candidates() {
    { have getent   && getent ahostsv4 "$PORTAL_HOST" 2>/dev/null | awk '{print $1}'
      have dig      && dig +short A "$PORTAL_HOST" 2>/dev/null
      have nslookup && nslookup "$PORTAL_HOST" 2>/dev/null | awk '/^Address:[ \t]/{print $2}'
    } 2>/dev/null | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' | awk '!seen[$0]++'
}

# 确定门户地址：缓存优先，缓存不可用才解析，且新地址必须自证是门户才落盘
resolve_portal_ip() {
    local ip cand
    # 1) 缓存只要还能自证是门户就直接用，完全不碰 DNS
    if [ -r "$IP_CACHE" ]; then
        ip=$(tr -d ' \r\n' < "$IP_CACHE")
        if [ -n "$ip" ] && portal_identity "$ip"; then
            printf '%s' "$ip"; return 0
        fi
    fi
    # 缓存不可信时顺手清掉，免得一个坏地址一直留在盘上
    rm -f "$IP_CACHE" 2>/dev/null || true
    # 2) 缓存不可用才解析；候选必须自证是门户，才允许写进缓存
    for cand in $(portal_candidates); do
        if portal_identity "$cand"; then
            cache_put "$IP_CACHE" "$cand"
            printf '%s' "$cand"; return 0
        fi
    done
    # 3) 缓存和 DNS 都没能验明正身，就不要拿它们去登录了（大概率是假地址）
    log_msg "PORTAL     缓存与 DNS 均未验证出门户地址，本轮不带地址尝试登录"
    printf ''
}

route_field() {   # $1=目标IP  $2=dev|src
    ip route get "$1" 2>/dev/null \
        | sed -n "s/.*[[:space:]]$2[[:space:]]\([^[:space:]]*\).*/\1/p" \
        | head -n1
}

# 定位"能把包发到门户的那张网卡"及其 IP / MAC
detect_net() {
    local pip dev
    MYIP=''; MYDEV=''; MYMAC=''
    pip=$(resolve_portal_ip)
    if [ -n "$pip" ]; then
        dev=$(route_field "$pip" dev)
        MYIP=$(route_field "$pip" src)
    fi
    if [ -z "$MYIP" ]; then
        dev=$(route_field 1.1.1.1 dev)
        MYIP=$(route_field 1.1.1.1 src)
    fi
    MYDEV="$dev"
    if [ -n "$MYDEV" ] && [ -r "/sys/class/net/$MYDEV/address" ]; then
        MYMAC=$(tr -d ':\r\n' < "/sys/class/net/$MYDEV/address")
    fi
    [ -n "$MYMAC" ] && cache_put "$MAC_CACHE" "$MYMAC"
}

# 单次探测，返回 "状态码|对端IP|跳转地址"
probe_detail() {
    local url=$1 out code ip rdr
    out=$(curl -4 --noproxy '*' -s -m 6 --connect-timeout 3 -o /dev/null \
          -w '%{http_code}|%{remote_ip}|%{redirect_url}' "$url" 2>/dev/null)
    code=$(printf '%s' "$out" | cut -d'|' -f1)
    ip=$(printf '%s' "$out" | cut -d'|' -f2)
    rdr=$(printf '%s' "$out" | cut -d'|' -f3)
    [ -z "$code" ] && code='000'
    printf '%s|%s|%s' "$code" "$ip" "$rdr"
}

# 探测：返回 204=在线 / 302=掉认证 / 000=不通或探测不可信
# 探针用固定公网 IP 而不是域名，避免被代理软件的 fake-IP 改写目标；
# 若对端地址仍落在 198.18.0.0/15，说明这一发被隧道吸走，结果丢弃。
probe() {
    local round i d code ip rdr url rest
    for round in 1 2; do
        for url in $PROBE_URLS; do
            i=1
            while [ "$i" -le 2 ]; do
                d=$(probe_detail "$url")
                code=${d%%|*}; rest=${d#*|}; ip=${rest%%|*}; rdr=${rest#*|}
                if [ "$code" != '000' ]; then
                    case "$ip" in
                        198.18.*|198.19.*) : ;;   # fake-IP，结果不可信
                        *)
                            case "$rdr" in
                                *hnu.edu.cn*|*eportal*|*wlanuserip*) printf '302'; return 0 ;;
                                *) printf '204'; return 0 ;;
                            esac
                            ;;
                    esac
                fi
                [ "$i" -lt 2 ] && sleep 1
                i=$((i + 1))
            done
        done
    done
    printf '000'
}

# 门户首页里下发的 ss1（历史/令牌值），作为 MAC 被拒时的回退
# 同样走 --resolve，避免域名被代理软件的 fake-IP 改写
page_mac() {
    local args=()
    if [ -n "${pip:-}" ]; then args=(--resolve "$PORTAL_HOST:80:$pip"); fi
    curl -4 --noproxy '*' ${args[@]+"${args[@]}"} -s -m 12 "http://$PORTAL_HOST/" 2>/dev/null \
        | tr -d '\r\n' \
        | grep -oE 'ss1="[0-9a-fA-F]{6,}"' \
        | head -n1 \
        | sed 's/.*="//; s/"$//' \
        | tr 'A-F' 'a-f'
}

# ---------------------------------------------------------------- 日志 ----
log_msg() {
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    printf '%s %s\n' "$ts" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

rotate_log() {
    [ -f "$LOG_FILE" ] || return 0
    local sz
    sz=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$sz" -gt 204800 ]; then
        tail -n 300 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
        chmod 640 "$LOG_FILE" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------ 认证动作 ----
portal_login() {
    local mac="$1" user="$2" pass="$3" myip="$4" pip="$5" url resp_args
    url="http://$PORTAL_HOST:$PORTAL_PORT/eportal/"
    resp_args=()
    [ -n "$pip" ] && resp_args=(--resolve "$PORTAL_HOST:$PORTAL_PORT:$pip")
    curl -4 --noproxy '*' -s -m 20 -G "$url" \
        "${resp_args[@]+"${resp_args[@]}"}" \
        --data-urlencode 'c=Portal' \
        --data-urlencode 'a=login' \
        --data-urlencode 'callback=dr1003' \
        --data-urlencode 'login_method=1' \
        --data-urlencode "user_account=,0,$user" \
        --data-urlencode "user_password=$pass" \
        --data-urlencode "wlan_user_ip=$myip" \
        --data-urlencode "wlan_user_mac=$mac" \
        --data-urlencode 'wlan_ac_ip=' \
        --data-urlencode 'wlan_ac_name=' \
        --data-urlencode 'jsVersion=4.0' \
        --data-urlencode "v=$RANDOM$RANDOM" \
        --data-urlencode 'lang=zh-cn' \
        --data-urlencode 'terminal_type=1' 2>/dev/null
}

read_creds() {
    CRED_USER=''; CRED_PASS=''
    [ -r "$USER_FILE" ] && CRED_USER=$(tr -d '\r\n' < "$USER_FILE")
    [ -r "$PASS_FILE" ] && CRED_PASS=$(tr -d '\r\n' < "$PASS_FILE")
}

# 单次检测 + 必要时重认证（run 模式主流程）
do_run() {
    need_root

    read_creds
    if [ -z "$CRED_USER" ] || [ -z "$CRED_PASS" ]; then
        exit 0     # 未配置凭据，静默退出
    fi

    if have flock; then
        exec 9>"$LOCK_FILE" 2>/dev/null || true
        flock -n 9 2>/dev/null || exit 0
    fi

    mkdir -p /run 2>/dev/null || true
    rotate_log

    detect_net
    local pip code after resp mac page i try
    pip=$(resolve_portal_ip)

    if [ -z "$MYIP" ]; then
        log_msg "NOIP       未能确定本机校园网 IP（MYDEV=${MYDEV:-none}），本轮跳过"
        exit 0
    fi

    code=$(probe)
    [ "$code" = '204' ] && exit 0

    if [ "$code" = '000' ]; then
        # probe=000 有两种情况：真断网，或 DNS 不可用（未认证时校园 DNS 常被挡，
        # 也可能被代理软件劫持成 fake-IP）。后者必须继续登录，否则整轮跳过、一直不恢复。
        # 缓存里的地址本身也可能已经坏了（曾被 DNS 污染过），所以不通时要再确认一次，
        # 不能因为一个坏缓存就把整轮判成断网。
        if portal_reachable "$pip"; then
            log_msg "PROBE      probe=000 但门户可达（$pip），判定为掉认证而非断网，继续登录"
        else
            pip=$(resolve_portal_ip)
            if [ -n "$pip" ]; then
                log_msg "PROBE      probe=000，重新确认到门户地址（$pip），判定为掉认证而非断网，继续登录"
            else
                sleep 5
                code=$(probe)
                [ "$code" = '204' ] && exit 0
                if [ "$code" = '000' ]; then
                    local last='' d ip rest
                    [ -f "$LOG_FILE" ] && last=$(tail -n 1 "$LOG_FILE" 2>/dev/null)
                    d=$(probe_detail "${PROBE_URLS%% *}"); rest=${d#*|}; ip=${rest%%|*}
                    case "$last" in
                        *NETDOWN*) : ;;
                        *)
                            case "$ip" in
                                198.18.*|198.19.*) log_msg "NETDOWN    probe=000（DNS 被劫持到伪造地址 $ip，本轮跳过登录）" ;;
                                *) log_msg "NETDOWN    probe=000 且门户不可达（链路确实不通），本轮跳过" ;;
                            esac
                            ;;
                    esac
                    exit 0
                fi
            fi
        fi
    fi

    mac="$MYMAC"
    page=''
    try=0
    after="$code"
    resp=''

    i=1
    while [ "$i" -le 3 ]; do
        case "$i" in
            2)
                if [ -z "$page" ]; then page=$(page_mac); fi
                [ -n "$page" ] && mac="$page"
                ;;
            3)
                mac="$MYMAC"
                ;;
        esac
        [ -z "$mac" ] && mac="$MYMAC"
        try=$i
        resp=$(portal_login "$mac" "$CRED_USER" "$CRED_PASS" "$MYIP" "$pip")
        sleep 3
        after=$(probe)
        [ "$after" = '204' ] && break
        # 门户回「该 IP 已经在线」= 本机并没有掉线，换 MAC 再试也是同一答复
        case "$resp" in *'"ret_code":2'*) break ;; esac
        [ "$i" -lt 3 ] && sleep 5
        i=$((i + 1))
    done

    local short
    short=$(printf '%s' "$resp" | tr -d '\r\n' | cut -c1-160)
    if [ "$after" = '204' ]; then
        log_msg "REAUTH OK   before=$code after=$after try=$try ip=$MYIP mac=$mac if=$MYDEV resp=$short"
    else
        case "$resp" in
            *'"ret_code":2'*)
                log_msg "REAUTH SKIP before=$code after=$after try=$try ip=$MYIP mac=$mac if=$MYDEV note=门户返回已在线 resp=$short" ;;
            *)
                log_msg "REAUTH FAIL before=$code after=$after try=$try ip=$MYIP mac=$mac if=$MYDEV resp=$short" ;;
        esac
    fi
    exit 0
}

# ------------------------------------------------------------ 调度装置 ----
sched_kind() {
    if have systemctl && [ -d /run/systemd/system ]; then
        printf 'systemd'
    elif [ -d /etc/cron.d ]; then
        printf 'cron'
    elif have crontab; then
        printf 'crontab'
    else
        printf 'none'
    fi
}

install_scheduler() {
    local kind
    kind=$(sched_kind)
    case "$kind" in
        systemd)
            cat > "$UNIT_SVC" <<EOF
[Unit]
Description=HNU Portal keepalive
Documentation=file://$BIN_PATH
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$BIN_PATH run
TimeoutStartSec=120
EOF
            cat > "$UNIT_TMR" <<EOF
[Unit]
Description=Run HNU Portal keepalive every 2 minutes

[Timer]
OnBootSec=45s
OnUnitActiveSec=2min
AccuracySec=10s
Unit=hnu-portal.service

[Install]
WantedBy=timers.target
EOF
            systemctl daemon-reload
            systemctl enable hnu-portal.timer >/dev/null 2>&1
            systemctl restart hnu-portal.timer >/dev/null 2>&1
            ok "已启用 systemd 定时器 hnu-portal.timer（每 2 分钟）"
            ;;
        cron)
            cat > "$CRON_FILE" <<EOF
# HNU Portal keepalive  (由 HNU-Portal.sh 生成，勿手改)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/2 * * * * root $BIN_PATH run >/dev/null 2>&1
@reboot    root sleep 45; $BIN_PATH run >/dev/null 2>&1
EOF
            chmod 644 "$CRON_FILE"
            ok "已写入 $CRON_FILE（每 2 分钟 + 开机 45 秒）"
            ;;
        crontab)
            ( crontab -l 2>/dev/null | grep -v 'hnu-portal' ;
              echo '*/2 * * * * '"$BIN_PATH"' run >/dev/null 2>&1' ;
              echo '@reboot sleep 45; '"$BIN_PATH"' run >/dev/null 2>&1' ) | crontab -
            ok "已写入 root crontab（每 2 分钟 + 开机 45 秒）"
            ;;
        *)
            warn "系统既没有 systemd 也没有 cron，无法安装定时任务"
            note "可手动把这条加进任意调度器： $BIN_PATH run"
            return 1
            ;;
    esac
    return 0
}

remove_scheduler() {
    if have systemctl; then
        systemctl disable --now hnu-portal.timer >/dev/null 2>&1
        rm -f "$UNIT_TMR" "$UNIT_SVC"
        systemctl daemon-reload >/dev/null 2>&1
    fi
    rm -f "$CRON_FILE"
    if have crontab; then
        crontab -l 2>/dev/null | grep -v 'hnu-portal' | crontab - >/dev/null 2>&1
    fi
}

sched_status() {
    local kind
    kind=$(sched_kind)
    case "$kind" in
        systemd)
            if [ -f "$UNIT_TMR" ]; then
                local e a
                e=$(systemctl is-enabled hnu-portal.timer 2>/dev/null)
                a=$(systemctl is-active hnu-portal.timer 2>/dev/null)
                printf 'systemd timer (%s/%s)' "${e:-unknown}" "${a:-unknown}"
            else
                printf '未安装'
            fi
            ;;
        cron)    [ -f "$CRON_FILE" ] && printf 'cron.d' || printf '未安装' ;;
        crontab) crontab -l 2>/dev/null | grep -q 'hnu-portal' && printf 'contab' || printf '未安装' ;;
        *)       printf '无调度器' ;;
    esac
}

# ------------------------------------------------------------ 安装步骤 ----
write_creds() {
    local u="$1" p="$2"
    mkdir -p "$CONF_DIR"
    chmod 700 "$CONF_DIR"
    printf '%s' "$u" > "$USER_FILE.$$"
    printf '%s' "$p" > "$PASS_FILE.$$"
    mv "$USER_FILE.$$" "$USER_FILE"
    mv "$PASS_FILE.$$" "$PASS_FILE"
    chmod 600 "$USER_FILE" "$PASS_FILE"
    chown root:root "$USER_FILE" "$PASS_FILE" 2>/dev/null || true
}

migrate_legacy() {
    [ -f "$USER_FILE" ] && return 0
    [ -f "$LEGACY_USER" ] || return 0
    mkdir -p "$CONF_DIR"; chmod 700 "$CONF_DIR"
    cp -f "$LEGACY_USER" "$USER_FILE" 2>/dev/null
    [ -f "$LEGACY_PASS" ] && cp -f "$LEGACY_PASS" "$PASS_FILE" 2>/dev/null
    chmod 600 "$USER_FILE" "$PASS_FILE" 2>/dev/null
    ok "已从旧版路径迁移账号密码"
}

install_files() {
    local first=''
    [ -f "$BIN_PATH" ] || first=1

    migrate_legacy
    ensure_curl || return 1

    # 把自身装到系统路径（装完即可脱离原文件）
    install -m 755 "$0" "$BIN_PATH" 2>/dev/null || cp -f "$0" "$BIN_PATH"
    chmod 755 "$BIN_PATH"

    # 日志文件归属
    [ -f "$LOG_FILE" ] || : >> "$LOG_FILE"
    if getent group adm >/dev/null 2>&1; then
        chown root:adm "$LOG_FILE" 2>/dev/null || true
        chmod 640 "$LOG_FILE"
    else
        chmod 600 "$LOG_FILE"
    fi

    install_scheduler || true

    if [ -n "$first" ]; then
        ok "安装完成：$BIN_PATH"
    else
        ok "已更新：$BIN_PATH"
    fi
    note "日志：$LOG_FILE （只记录掉线重认证事件，在线时不写）"
    if [ -f "$LEGACY_BIN" ]; then
        note "检测到旧版 $LEGACY_BIN，已被本版取代，可安全删除："
        note "  sudo rm -f $LEGACY_BIN"
    fi
}

prompt_creds() {
    local u p p2
    while :; do
        printf '请输入校园网账号: '
        read -r u || return 1
        u=$(printf '%s' "$u" | tr -d ' \r\n\t')
        [ -n "$u" ] && break
        bad "账号不能为空"
    done
    while :; do
        printf '请输入校园网密码（不回显）: '
        read -rs p || return 1
        printf '\n'
        printf '请再输入一次确认: '
        read -rs p2 || return 1
        printf '\n'
        if [ "$p" != "$p2" ]; then
            bad "两次输入不一致，请重来"
            continue
        fi
        if [ -z "$p" ]; then
            bad "密码不能为空"
            continue
        fi
        break
    done
    write_creds "$u" "$p"
    CRED_USER="$u"; CRED_PASS="$p"
    ok "账号密码已保存到 $CONF_DIR （600 root，仅 root 可读）"
    return 0
}

show_online_state() {
    local c
    c=$(probe)
    case "$c" in
        204) printf '%s已认证在线%s' "$C_GRN" "$C_OFF" ;;
        302) printf '%s未认证（需要登录）%s' "$C_YEL" "$C_OFF" ;;
        000) printf '%s探测不通（已重试 3 次）%s' "$C_RED" "$C_OFF" ;;
        *)   printf '未知（%s）' "$c" ;;
    esac
}

mask_user() {
    local u="$1"
    local n=${#u}
    if [ "$n" -le 4 ]; then
        printf '%s' "$u"
    else
        printf '%s***%s' "$(printf '%s' "$u" | cut -c1-4)" "$(printf '%s' "$u" | rev | cut -c1-2 | rev)"
    fi
}

menu_status() {
    if [ ! -f "$BIN_PATH" ]; then
        printf '尚未安装'
        return
    fi
    read_creds
    local who='未配置凭据'
    [ -n "$CRED_USER" ] && who="账号 $(mask_user "$CRED_USER")"
    printf '已安装（%s）| 调度: %s | 网络: %s' "$who" "$(sched_status)" "$(show_online_state)"
}

# ------------------------------------------------------------ 菜单动作 ----
act_install() {
    say ''
    if [ -f "$BIN_PATH" ] && [ -f "$USER_FILE" ]; then
        warn "本机已安装，继续将覆盖账号密码与定时任务"
    fi

    # 检测到旧版（v1~v3）凭据时，可直接沿用，免重新输入
    if [ ! -f "$USER_FILE" ] && [ -f "$LEGACY_USER" ] && [ -f "$LEGACY_PASS" ]; then
        local lu
        lu=$(tr -d '\r\n' < "$LEGACY_USER")
        say "检测到旧版凭据：账号 $(mask_user "$lu")"
        printf '直接沿用旧账号密码？[Y/n]: '
        local a=''
        read -r a || true
        case "$a" in
            n|N|no|NO) : ;;
            *)
                install_files
                say ''
                say '--- 立即执行一次检测 ---'
                "$BIN_PATH" run >/dev/null 2>&1
                say "当前网络: $(show_online_state)"
                pause_
                return 0
                ;;
        esac
        say '好，请重新输入账号密码。'
    fi

    prompt_creds || return 0
    install_files
    say ''
    say '--- 立即执行一次检测 ---'
    "$BIN_PATH" run >/dev/null 2>&1
    say "当前网络: $(show_online_state)"
    pause_
}

act_change() {
    say ''
    if [ ! -f "$USER_FILE" ]; then
        warn "尚未安装，请先选 1"
        pause_; return 0
    fi
    read_creds
    say "当前账号: $(mask_user "$CRED_USER")"
    prompt_creds || return 0
    install_files
    say ''
    say '--- 立即执行一次检测 ---'
    "$BIN_PATH" run >/dev/null 2>&1
    say "当前网络: $(show_online_state)"
    pause_
}

act_uninstall() {
    say ''
    warn "将删除：$BIN_PATH 、$CONF_DIR 、$LOG_FILE 、定时任务"
    printf '确认卸载？[y/N]: '
    local a=''
    read -r a || true
    case "$a" in
        y|Y|yes|YES) : ;;
        *) say '已取消'; pause_; return 0 ;;
    esac
    remove_scheduler
    rm -f "$BIN_PATH" "$LOG_FILE" "$IP_CACHE" "$MAC_CACHE" "$LOCK_FILE"
    rm -rf "$CONF_DIR"
    ok "已卸载"
    note "旧版遗留（如存在）需自行删除：$LEGACY_BIN 、$LEGACY_USER 、$LEGACY_PASS"
    pause_
}

act_log() {
    say ''
    if [ ! -f "$LOG_FILE" ]; then
        ok "暂无日志 —— 说明一直在线，没有发生过掉线重认证"
        pause_; return 0
    fi
    local n
    n=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    say "日志: $LOG_FILE （$n 行，仅显示最后 40 行）"
    say '------------------------------------------------------------'
    tail -n 40 "$LOG_FILE"
    say '------------------------------------------------------------'
    say 'REAUTH OK = 自动恢复成功 | REAUTH FAIL = 登录被拒 | NETDOWN = 链路/DNS 不通'
    pause_
}

act_test() {
    say ''
    if [ ! -f "$USER_FILE" ]; then
        warn "尚未安装，请先选 1"
        pause_; return 0
    fi
    read_creds
    say "账号: $(mask_user "$CRED_USER")"
    say '--- 执行检测/重认证 ---'
    "$BIN_PATH" run
    local c
    c=$(probe)
    say "探测结果: $c  ($( [ "$c" = 204 ] && echo '已认证' || echo '未认证' ))"
    if [ -f "$LOG_FILE" ]; then
        say '--- 本次新增日志 ---'
        tail -n 3 "$LOG_FILE"
    fi
    pause_
}

act_selftest() {
    local pip c dev myip mymac who
    say '==================== 只读自检（不改动系统）===================='
    say "脚本版本          : $VERSION"
    say "系统              : $(uname -srm)"
    say "发行版            : $( ( . /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-unknown}" ) || echo unknown )"
    say "init              : $( [ -d /run/systemd/system ] && echo systemd || ps -p 1 -o comm= 2>/dev/null || echo unknown )"
    say "调度方式          : $(sched_kind)"
    say ''
    pip=$(resolve_portal_ip)
    say "门户域名          : $PORTAL_HOST"
    say "门户 IP           : ${pip:-（解析失败且无缓存）}"
    say "缓存文件          : $IP_CACHE $( [ -s "$IP_CACHE" ] && echo "(有)" || echo "(无)" )"
    detect_net
    say "出口网卡          : ${MYDEV:-（未识别）}"
    say "本机校园网 IP      : ${MYIP:-（未识别）}"
    say "本机 MAC          : ${MYMAC:-（未识别）}"
    if [ -n "$pip" ]; then
        say "路由检查          : $(ip route get "$pip" 2>/dev/null | head -n1)"
    fi
    say ''
    c=$(probe)
    say "探针 223.5.5.5    : $c  $( case $c in 204) echo '(已认证)';; 302) echo '(未认证)';; 000) echo '(不通 / 探测不可信)';; *) echo '';; esac )"
    say ''
    if [ -r "$USER_FILE" ]; then
        who=$(tr -d '\r\n' < "$USER_FILE"); say "凭据              : 已配置（账号 $(mask_user "$who")）"
        if [ -r "$PASS_FILE" ]; then
            say "密码长度          : $(tr -d '\r\n' < "$PASS_FILE" | wc -c) 字节"
        else
            say "密码文件          : 不可读（非 root 时属正常）"
        fi
    else
        say "凭据              : 未配置"
        if [ -f "$LEGACY_USER" ]; then
            say "旧版凭据          : 检测到 $LEGACY_USER（安装时会自动迁移）"
        fi
    fi
    say ''
    say "依赖工具          : curl=$(have curl && echo yes || echo NO)  ip=$(have ip && echo yes || echo NO)  flock=$(have flock && echo yes || echo NO)"
    say '============================================================'
}

# ---------------------------------------------------------------- 菜单 ----
main_menu() {
    while :; do
        clear 2>/dev/null || true
        cat <<EOF
============================================================
   湖南大学 校园网自动保活   v$VERSION  (Linux)
============================================================
   状态: $(menu_status)
------------------------------------------------------------
   [1] 安装 / 首次配置 (输入校园网账号和密码)
   [2] 修改账号或密码
   [3] 卸载 (清除本机上的脚本、凭据和定时任务)
   [4] 查看日志 (重新认证记录)
   [5] 立即检测并重连一次
   [0] 退出
============================================================
EOF
        printf '请输入序号后回车: '
        local ch=''
        read -r ch || { say ''; exit 0; }
        ch=$(printf '%s' "$ch" | tr -d ' \r\n\t')
        case "$ch" in
            1) act_install ;;
            2) act_change ;;
            3) act_uninstall ;;
            4) act_log ;;
            5) act_test ;;
            0) say '再见'; exit 0 ;;
            *) ;;
        esac
    done
}

# ---------------------------------------------------------------- 入口 ----
case "${1:-}" in
    run)
        shift
        do_run
        ;;
    selftest)
        act_selftest
        exit 0
        ;;
    --help|-h|help)
        usage
        exit 0
        ;;
    --version|-V)
        printf 'HNU-Portal.sh %s\n' "$VERSION"
        exit 0
        ;;
    '')
        need_root
        ensure_curl || { bad "缺少 curl，无法继续"; exit 1; }
        main_menu
        ;;
    *)
        bad "未知参数: $1"
        usage
        exit 1
        ;;
esac
