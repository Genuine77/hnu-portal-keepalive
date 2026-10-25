# HNU 校园网自动保活（可移植版 v6）
# 由 HNU-Portal.bat 释放到 %ProgramData%\HNU-Portal\ 后由计划任务以 SYSTEM 身份调用。
# 也可单独运行：文件所在目录即为工作目录（凭据、日志都放在同目录）。
#
# 认证方式：检测到掉线后，调用校园网门户的登录接口完成重新认证。
# 接口地址见下方 $phost / $pport；若门户升级导致地址或路径变化，改这两处即可。
#
# v4 变更（性能）：
#   1. 探测提到最前面，204 直接退出。原顺序是先做网卡定位再探测，导致每次（哪怕在线）
#      都要加载 NetTCPIP 模块，实测单次 CPU 约 2.2 秒、内存 160 MB。
#   2. 需要重认证时才定位网卡，且改为纯 .NET：
#        UDP connect 求"内核去门户所用的源 IP"（不发包）+ NetworkInterface 枚举取 MAC，
#      不再依赖 Find-NetRoute / Get-NetAdapter / Get-NetIPAddress。
#   3. 效果：在线态单次 CPU 降到约 1/3（实测数据见 CHANGELOG）。
#
# v5 变更（可靠性）：
#   1. 探测拿不到 204 时不再一律当作断网：先用缓存的门户 IP 判断门户是否可达，
#      可达就照常登录。修复"DNS 被挡/被劫持时整轮跳过、迟迟不恢复"。
#   2. 解析到的门户 IP 必须过校验（排除回环、链路本地、组播与 198.18.0.0/15 等
#      代理软件 fake-IP 段），坏地址不会写进缓存。
#   3. 认证成功后主动唤醒 Windows 的联网判定（NCSI），避免网已通、任务栏仍显示断网。
#
# v6 变更（探测不再经过 DNS）：
#   开着 VPN / 代理软件时，它们会把探针域名解析成 198.18.0.0/15 这类 fake-IP，
#   请求随即被隧道接管。结果是「VPN 能不能上外网」冒充了「校园网通不通」：
#   校园网早断了，探针照样回 204，脚本就地退出，一次也不会去重新认证。
#   现在探针改用固定公网 IP 直连，并用响应里的 remote_ip 反查是否被劫持。

$ErrorActionPreference = 'SilentlyContinue'

# ---------- 路径 ----------
if ($PSScriptRoot) { $base = $PSScriptRoot } else { $base = 'C:\ProgramData\HNU-Portal' }
$uf     = Join-Path $base 'user.txt'
$pf     = Join-Path $base 'pass.txt'
$ipf    = Join-Path $base 'portal.ip'
$log    = Join-Path $base 'keepalive.log'
$probeList = @('http://223.5.5.5/', 'http://119.29.29.29/')
$script:lastProbe = ''
$phost  = 'web.hnu.edu.cn'
$pport  = '801'
$portal = "http://$phost`:$pport/eportal/"

function Write-Log([string]$msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$ts $msg" -Encoding UTF8
}

function Get-ProbeCode {
    # 返回 204=在线 / 302=掉认证（被重定向到门户）/ 000=不通或探测不可信。
    # 探针刻意用固定公网 IP 而不是域名：域名一旦被 VPN 的 fake-IP 改写，
    # 探测的就变成了隧道出口，校园网状态完全测不出来。
    for ($round = 1; $round -le 2; $round++) {
        foreach ($t in $probeList) {
            # 单次探测可能被上游丢掉连接（本机并未掉线时也会返回 000），故每目标重试
            $o = & curl.exe -4 --noproxy '*' -s -m 6 --connect-timeout 3 -o NUL `
                 -w '%{http_code}|%{remote_ip}|%{redirect_url}' $t 2>$null
            if ([string]::IsNullOrWhiteSpace($o)) { $o = '000||' }
            $p   = "$o".Trim().Split('|')
            $c   = $p[0]
            $rip = if ($p.Count -gt 1) { $p[1] } else { '' }
            $rdr = if ($p.Count -gt 2) { $p[2] } else { '' }
            $script:lastProbe = "$($t -replace '^https?://','') -> $c remote=$rip"

            if ($c -ne '000') {
                if ($rip -and -not (Test-PortalIP $rip)) {
                    # 响应来自 fake-IP 段，说明这一发被隧道吸走了，结果不可信
                    $script:lastProbe = "$($t -replace '^https?://','') -> $c remote=$rip（fake-IP，结果丢弃）"
                    continue
                }
                # 被改写去认证页 = 掉认证
                if ($rdr -match '(?i)(hnu\.edu\.cn|eportal|wlanuserip)') { return '302' }
                # 拿到目标自己的真实响应（223.5.5.5 回 404，1.1.1.1 回 301）= 出网正常
                return '204'
            }
        }
        if ($round -lt 2) { Start-Sleep -Seconds 1 }
    }
    return '000'
}

function Test-PortalIP([string]$ip) {
    # 只接受可信的门户地址。开着 VPN / 代理的 fake-IP 时，DNS 会把域名解析成
    # 198.18.0.0/15 之类的保留段地址，这种地址一旦写进缓存，登录请求等于发进黑洞。
    if ([string]::IsNullOrWhiteSpace($ip)) { return $false }
    $o = $ip.Split('.')
    if ($o.Count -ne 4) { return $false }
    foreach ($x in $o) {
        if ($x -notmatch '^\d{1,3}$') { return $false }
        if ([int]$x -gt 255) { return $false }
    }
    $a = [int]$o[0]; $b = [int]$o[1]
    if ($a -eq 0 -or $a -ge 224) { return $false }
    if ($a -eq 127) { return $false }
    if ($a -eq 169 -and $b -eq 254) { return $false }
    if ($a -eq 198 -and $b -ge 18 -and $b -le 19) { return $false }
    return $true
}

function Test-PortalReachable([string]$ip) {
    # 不依赖 DNS，直接用 IP 判断门户是否可达：可达说明链路正常，只是还没认证
    if (-not (Test-PortalIP $ip)) { return $false }
    $c = & curl.exe -4 --noproxy '*' -s -m 6 --connect-timeout 3 -o NUL -w '%{http_code}' `
        --resolve "${phost}:${pport}:$ip" $portal 2>$null
    if ([string]::IsNullOrWhiteSpace($c)) { return $false }
    return ("$c".Trim() -ne '000')
}

function Repair-NetState([string]$ip) {
    # Windows 的"是否有 Internet"判定（NCSI）不会自己复查：它在认证之前就把网络
    # 标记成"需要登录的门户"，之后只有链路重新上线才会重测。于是会出现网已经通了、
    # 任务栏却一直显示断网图标的情况。这里用一次网卡重启把判定唤醒。
    try {
        Start-Sleep -Seconds 2
        $alias = (Get-NetIPAddress -IPAddress $ip -AddressFamily IPv4 -ErrorAction Stop |
                  Select-Object -First 1).InterfaceAlias
        if ([string]::IsNullOrWhiteSpace($alias)) { return }
        $conn = Get-NetConnectionProfile -InterfaceAlias $alias -ErrorAction SilentlyContinue |
                Select-Object -First 1
        if ($conn -and $conn.IPv4Connectivity -eq 'Internet') { return }
        Write-Log "NETSTATE   IPv4=$($conn.IPv4Connectivity)（系统未认出已联网）→ 重启网卡刷新判定"
        Restart-NetAdapter -Name $alias -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 10
        $c2 = Get-ProbeCode
        $conn2 = Get-NetConnectionProfile -InterfaceAlias $alias -ErrorAction SilentlyContinue |
                 Select-Object -First 1
        Write-Log "NETSTATE   after=$c2 IPv4=$($conn2.IPv4Connectivity)"
    } catch {
        Write-Log "NETSTATE   刷新失败：$($_.Exception.Message)"
    }
}

# ---------- 前置检查 ----------
if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    Write-Log 'ERROR      找不到 curl.exe（需 Windows 10 1803+ / Server 2019+）'
    exit 1
}

if (-not (Test-Path $uf)) { exit 0 }
if (-not (Test-Path $pf)) { exit 0 }

$user = (Get-Content $uf -Raw).Trim()
$pass = (Get-Content $pf -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($user) -or [string]::IsNullOrWhiteSpace($pass)) { exit 0 }

# 日志超 200 KB 只保留最后 300 行
if ((Test-Path $log) -and ((Get-Item $log).Length -gt 204800)) {
    Get-Content $log -Tail 300 | Set-Content $log -Encoding UTF8
}

# ---------- 第一步：只探测。在线就直接退出（绝大多数运行走这条最轻的路径）----------
$code = Get-ProbeCode
if ($code -eq '204') { exit 0 }

if ($code -eq '000') {
    # probe=000 有两种完全不同的情况：
    #   1. 真的断网；
    #   2. DNS 不可用（未认证时校园 DNS 常被挡、或 VPN 把解析劫持成 fake-IP）。
    # 第 2 种必须继续登录，否则会像旧版那样：明明只是掉认证，却整轮跳过、一直不恢复。
    $cached = ''
    if (Test-Path $ipf) { $cached = (Get-Content $ipf -Raw).Trim() }
    if (-not (Test-PortalReachable $cached)) {
        Start-Sleep -Seconds 5
        $code = Get-ProbeCode
        if ($code -eq '204') { exit 0 }
        if ($code -eq '000' -and -not (Test-PortalReachable $cached)) {
            $last = ''
            if (Test-Path $log) { $last = (Get-Content $log -Tail 1) -join '' }
            if ($last -notmatch 'NETDOWN') { Write-Log "NETDOWN    probe=000 且门户不可达（链路确实不通），本轮跳过 | $($script:lastProbe)" }
            exit 0
        }
    } else {
        Write-Log "PROBE       probe=000 但门户可达（$cached），判定为掉认证而非断网，继续登录"
    }
}

# ---------- 第二步：确实需要重认证，这时才解析门户 IP ----------
# 解析结果必须过校验：VPN/代理的 fake-IP 会把域名答成 198.18.x 这类地址，
# 直接拿来登录必然失败，而且会把这个坏地址写进缓存、让下次也失败。
$pip = ''
$cachedIP = ''
if (Test-Path $ipf) { $cachedIP = (Get-Content $ipf -Raw).Trim() }
try {
    $a = [System.Net.Dns]::GetHostAddresses($phost) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
    if ($a -and (Test-PortalIP $a.IPAddressToString)) { $pip = $a.IPAddressToString }
    elseif ($a) { Write-Log "DNS        解析到 $($a.IPAddressToString)（不在可信范围，已忽略）" }
} catch {}
if (-not $pip -and (Test-PortalIP $cachedIP)) { $pip = $cachedIP }
if ($pip) { Set-Content -Path $ipf -Value $pip -Encoding ASCII }

# ---------- 第三步：定位网卡（纯 .NET，可移植，不写死网段）----------
# UDP connect 只是让内核选出出口网卡并给出源地址，不握手、不发包
$myip = ''
foreach ($dst in @($pip, '223.5.5.5')) {
    if (-not $dst) { continue }
    try {
        $sock = New-Object System.Net.Sockets.Socket(
            [System.Net.Sockets.AddressFamily]::InterNetwork,
            [System.Net.Sockets.SocketType]::Dgram,
            [System.Net.Sockets.ProtocolType]::Udp)
        $sock.Connect($dst, 80)
        $myip = $sock.LocalEndPoint.Address.ToString()
        $sock.Close()
    } catch { $myip = '' }
    # 走 VPN 的链路会把源地址给成 198.18.x / 169.254.x，这种地址拿去登录必然失败
    if ($myip -and -not (Test-PortalIP $myip)) { $myip = '' }
    if ($myip) { break }
}

if (-not $myip) {
    $last = ''
    if (Test-Path $log) { $last = (Get-Content $log -Tail 1) -join '' }
    if ($last -notmatch 'NOIP') { Write-Log "NOIP       before=$code 无法确定本机出口 IP，本轮跳过" }
    exit 0
}

# 由源 IP 反查网卡取 MAC
$mac = ''
try {
    foreach ($n in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
        if ($n.OperationalStatus -ne 'Up') { continue }
        if ($n.NetworkInterfaceType -eq 'Loopback') { continue }
        $has = $false
        foreach ($u in $n.GetIPProperties().UnicastAddresses) {
            if ($u.Address.AddressFamily -eq 'InterNetwork' -and $u.Address.ToString() -eq $myip) { $has = $true; break }
        }
        if ($has) { $mac = ($n.GetPhysicalAddress().ToString()).ToLower(); break }
    }
} catch {}

$resolveArg = @()
if ($pip) { $resolveArg = @('--resolve', "${phost}:${pport}:$pip") }

function Invoke-Login([string]$m) {
    return & curl.exe -4 --noproxy '*' -s -m 20 -G $portal @resolveArg `
        --data-urlencode 'c=Portal' `
        --data-urlencode 'a=login' `
        --data-urlencode 'callback=dr1003' `
        --data-urlencode 'login_method=1' `
        --data-urlencode "user_account=,0,$user" `
        --data-urlencode "user_password=$pass" `
        --data-urlencode "wlan_user_ip=$myip" `
        --data-urlencode "wlan_user_mac=$m" `
        --data-urlencode 'wlan_ac_ip=' `
        --data-urlencode 'wlan_ac_name=' `
        --data-urlencode 'jsVersion=4.0' `
        --data-urlencode "v=$((Get-Random))" `
        --data-urlencode 'lang=zh-cn' `
        --data-urlencode 'terminal_type=1' 2>$null
}

$after = $code
$resp  = ''
$try   = 0
$usedMac = ''
$macPage = ''

for ($attempt = 1; $attempt -le 3; $attempt++) {
    $m = $mac
    if ($attempt -eq 2) {
        # 真实 MAC 被拒时，回退到门户页下发的 ss1 令牌值
        if (-not $macPage) {
            $html = & curl.exe -4 --noproxy '*' -s -m 12 @resolveArg "http://$phost/" 2>$null
            $joined = ($html -join "`n")
            $mm = [regex]::Match($joined, 'ss1="([0-9a-fA-F]{6,})"')
            if ($mm.Success) { $macPage = $mm.Groups[1].Value.ToLower() }
        }
        if ($macPage) { $m = $macPage }
    }
    if ([string]::IsNullOrWhiteSpace($m)) { $m = '000000000000' }
    $try = $attempt
    $usedMac = $m
    $resp = Invoke-Login $m
    Start-Sleep -Seconds 3
    $after = Get-ProbeCode
    if ($after -eq '204') { break }
    # 门户回「该 IP 已经在线」= 本机并没有掉线（多半是探测偶发误判），
    # 换 MAC 再试也是同一个答复，直接收工。
    if (("$resp") -match '"ret_code"\s*:\s*2') { break }
    if ($attempt -lt 3) { Start-Sleep -Seconds 5 }
}

$short = ($resp -join ' ')
if ($short.Length -gt 160) { $short = $short.Substring(0,160) }

if ($after -eq '204') {
    Write-Log "REAUTH OK   before=$code after=$after try=$try ip=$myip mac=$usedMac portal=$pip probe=$($script:lastProbe) resp=$short"
    # 认证已经成功，但系统可能仍显示"无 Internet / 需要操作"，这里主动唤醒一次判定
    Repair-NetState $myip
} elseif (("$resp") -match '"ret_code"\s*:\s*2') {
    Write-Log "REAUTH SKIP before=$code after=$after try=$try ip=$myip mac=$usedMac portal=$pip probe=$($script:lastProbe) note=门户返回已在线 resp=$short"
} else {
    Write-Log "REAUTH FAIL before=$code after=$after try=$try ip=$myip mac=$usedMac portal=$pip probe=$($script:lastProbe) resp=$short"
}
