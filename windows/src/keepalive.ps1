# HNU 校园网自动保活（可移植版 v4）
# 由 HNU-Portal.bat 释放到 %ProgramData%\HNU-Portal\ 后由计划任务以 SYSTEM 身份调用。
# 也可单独运行：文件所在目录即为工作目录（凭据、日志都放在同目录）。
#
# 认证接口（2026-10-23 实测）：Dr.COM Portal 协议 :801
#   GET http://web.hnu.edu.cn:801/eportal/?c=Portal&a=login&callback=dr1003&login_method=1
#       &user_account=,0,<账号>&user_password=<密码>&wlan_user_ip=<本机IP>
#       &wlan_user_mac=<MAC>&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.0&v=<随机>&lang=zh-cn&terminal_type=1
#   成功返回 dr1003({"result":1,"msg":"Portal协议认证成功！"})
# 注意：不要用 ?c=ACSetting&a=Login + DDDDD/upass，那套老接口在这台 AC 上恒返回 Auth Error(-199)。
#
# v4 变更（性能）：
#   1. 探测提到最前面，204 直接退出。原顺序是先做网卡定位再探测，导致每次（哪怕在线）
#      都要加载 NetTCPIP 模块，实测单次 CPU 约 2.2 秒、内存 160 MB。
#   2. 需要重认证时才定位网卡，且改为纯 .NET：
#        UDP connect 求"内核去门户所用的源 IP"（不发包）+ NetworkInterface 枚举取 MAC，
#      不再依赖 Find-NetRoute / Get-NetAdapter / Get-NetIPAddress。
#   3. 效果：在线态单次 CPU 降到约 1/3（详见 chat 里的实测对比）。

$ErrorActionPreference = 'SilentlyContinue'

# ---------- 路径 ----------
if ($PSScriptRoot) { $base = $PSScriptRoot } else { $base = 'C:\ProgramData\HNU-Portal' }
$uf     = Join-Path $base 'user.txt'
$pf     = Join-Path $base 'pass.txt'
$ipf    = Join-Path $base 'portal.ip'
$log    = Join-Path $base 'keepalive.log'
$probe  = 'http://connect.rom.miui.com/generate_204'
$phost  = 'web.hnu.edu.cn'
$pport  = '801'
$portal = "http://$phost`:$pport/eportal/"

function Write-Log([string]$msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$ts $msg" -Encoding UTF8
}

function Get-ProbeCode {
    $c = & curl.exe -4 -s -m 8 -o NUL -w '%{http_code}' $probe 2>$null
    if ([string]::IsNullOrWhiteSpace($c)) { $c = '000' }
    return "$c".Trim()
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
    Start-Sleep -Seconds 5
    $code = Get-ProbeCode
    if ($code -eq '000') {
        $last = ''
        if (Test-Path $log) { $last = (Get-Content $log -Tail 1) -join '' }
        if ($last -notmatch 'NETDOWN') { Write-Log 'NETDOWN    probe=000（链路/DNS 不通，本轮跳过登录）' }
        exit 0
    }
    if ($code -eq '204') { exit 0 }
}

# ---------- 第二步：确实需要重认证，这时才解析门户 IP ----------
$pip = ''
try {
    $a = [System.Net.Dns]::GetHostAddresses($phost) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
    if ($a) { $pip = $a.IPAddressToString }
} catch {}
if (-not $pip -and (Test-Path $ipf)) { $pip = (Get-Content $ipf -Raw).Trim() }
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
    return & curl.exe -4 -s -m 20 -G $portal @resolveArg `
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
            $html = & curl.exe -4 -s -m 12 "http://$phost/" 2>$null
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
    if ($attempt -lt 3) { Start-Sleep -Seconds 5 }
}

$short = ($resp -join ' ')
if ($short.Length -gt 160) { $short = $short.Substring(0,160) }

if ($after -eq '204') {
    Write-Log "REAUTH OK   before=$code after=$after try=$try ip=$myip mac=$usedMac resp=$short"
} else {
    Write-Log "REAUTH FAIL before=$code after=$after try=$try ip=$myip mac=$usedMac resp=$short"
}
