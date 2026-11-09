# HNU 校园网自动保活（可移植版 v8）
# 由 HNU-Portal.bat 释放到 %ProgramData%\HNU-Portal\ 后由计划任务以 SYSTEM 身份调用。
# 也可单独运行：文件所在目录即为工作目录（凭据、日志都放在同目录）。
#
# 认证方式：检测到掉线后，调用校园网门户的登录接口完成重新认证。
# 接口地址见下方 $phost / $pport；若门户升级导致地址或路径变化，改这两处即可。
#
# 诊断模式（不登录、不改任何东西，只打印判断过程）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File keepalive.ps1 -Diag
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
#
# v7 变更（门户地址不被污染）：
#   1. 门户地址改为"缓存优先"：缓存里的地址只要还能自证是门户就直接用，不再先问 DNS。
#      原来是 DNS 优先、缓存兜底，DNS 一旦被劫持到一个"格式合法"的地址（不一定落在
#      198.18.x），就会把缓存覆盖掉，之后每次登录都发错地方。
#   2. 新解析出的地址必须真的返回门户页面（带 EPortal 特征）才允许写进缓存，
#      只过格式校验不算数。
#
# v8 变更（TUN / 系统代理下能认证）：
#   开着 FlClash 这类代理软件的 TUN 模式时，0.0.0.0/0 被虚拟网卡接管。实测该网卡
#   会按规则排除 10.0.0.0/8、172.16.0.0/12、192.168.0.0/16 等私有网段，所以门户本身
#   仍然直连可达；真正坏掉的是下面三处，且 --noproxy '*' 对它们全部无效——它只关
#   应用层 HTTP 代理，管不了 IP 层劫持与 DNS 劫持：
#     1. 探针走隧道：测到的是"代理能不能上外网"，不是校园网通不通，可能一直回 204，
#        于是掉线了也不去认证（本版修掉的核心问题）；
#     2. 出口 IP 求错：UDP connect 公网地址时内核给出隧道源地址 198.18.0.1，被当成
#        不可信清空，直接 NOIP 跳过本轮；
#     3. DNS 被 fake-IP 改写：门户域名恒解析成 198.18.x，永远拿不到真地址。
#   本版对策：
#     1. 探针 IP 被隧道路由覆盖时，加一条 /32 指回物理网关。Windows 按最长前缀匹配，
#        /32 必然优先于隧道的 /1、/8 等网段，且这一层代理软件不参与决策。只动这几个
#        固定目标，不碰默认路由、不碰内网网段。加完会复核，没生效就标记探针不可信。
#     2. 出口 IP 改为「先问门户」（门户在内网，源地址必然是物理网卡地址），
#        本地网卡枚举作为兜底，公网探针不再参与。
#     3. 门户域名只向内网 DNS 查询（公网 DNS 的查询同样会被隧道劫持）；
#        缓存验不过时不再删除——删除会让下一轮连候选地址都没有，彻底失去自愈能力。
#     4. 探针不可信时不再据 204 直接退出，改为向门户试探一次：门户回"已在线"即收工。
#     5. 检测到隧道时跳过网卡重启（NCSI 唤醒），避免打断用户正在用的代理/隧道。

param(
    [switch]$Diag
)

$ErrorActionPreference = 'SilentlyContinue'

# ---------- 路径 ----------
if ($PSScriptRoot) { $base = $PSScriptRoot } else { $base = 'C:\ProgramData\HNU-Portal' }
$uf     = Join-Path $base 'user.txt'
$pf     = Join-Path $base 'pass.txt'
$ipf    = Join-Path $base 'portal.ip'
$log    = Join-Path $base 'keepalive.log'
$probeList = @('http://223.5.5.5/', 'http://119.29.29.29/')
$script:lastProbe   = ''
$script:probeTrusted = $true
$script:tunnelSeen   = $false
$phost  = 'web.hnu.edu.cn'
$pport  = '801'
$portal = "http://$phost`:$pport/eportal/"

function Write-Log([string]$msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$ts $msg" -Encoding UTF8
}

# 同一个提示不要每 2 分钟刷一行，只在内容变化时记一次
function Write-LogOnce([string]$msg) {
    $last = ''
    if (Test-Path $log) { $last = (Get-Content $log -Tail 1) -join '' }
    if ($last -notmatch [regex]::Escape($msg)) { Write-Log $msg }
}

# ============================================================
# 基础判定
# ============================================================

function Test-PortalIP([string]$ip) {
    # 只接受可信地址。开着 VPN / 代理的 fake-IP 时，DNS 会把域名解析成
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

function Test-TunnelIP([string]$ip) {
    # 代理软件 TUN 的 fake-IP / 隧道网段
    return ($ip -match '^198\.1[89]\.')
}

function Test-PrivateIPv4([string]$ip) {
    if (-not (Test-PortalIP $ip)) { return $false }
    $o = $ip.Split('.')
    $a = [int]$o[0]; $b = [int]$o[1]
    if ($a -eq 10) { return $true }
    if ($a -eq 172 -and $b -ge 16 -and $b -le 31) { return $true }
    if ($a -eq 192 -and $b -eq 168) { return $true }
    return $false
}

function Get-TunnelIndexes {
    # 纯 .NET 枚举，不加载 NetTCPIP 模块（约 80 ms）。
    # 只要有网卡持有 198.18/198.19 段地址，就认为本机装着代理软件的 TUN。
    $idx = @()
    try {
        foreach ($n in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            if ($n.OperationalStatus -ne 'Up') { continue }
            if ($n.NetworkInterfaceType -eq 'Loopback') { continue }
            $hit = $false
            foreach ($u in $n.GetIPProperties().UnicastAddresses) {
                if ($u.Address.AddressFamily -ne 'InterNetwork') { continue }
                if (Test-TunnelIP $u.Address.ToString()) { $hit = $true; break }
            }
            if ($hit) {
                $v4 = $n.GetIPProperties().GetIPv4Properties()
                if ($v4) { $idx += [int]$v4.Index }
            }
        }
    } catch {}
    return @($idx | Select-Object -Unique)
}

function Get-NetCtx {
    # 需要 NetTCPIP 模块（首次约 0.7 s），只在检测到隧道时才调用。
    $ctx = @{ Tunnel = @(); IfIndex = 0; Alias = ''; Gateway = ''; IP = '' }
    $ctx.Tunnel = @(Get-TunnelIndexes)
    if ($ctx.Tunnel.Count -eq 0) { return $ctx }

    $addrs  = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue)
    $routes = @(Get-NetRoute  -AddressFamily IPv4 -ErrorAction SilentlyContinue)

    $cands = @($addrs | Where-Object {
        $_ -and (Test-PortalIP $_.IPAddress) -and ($ctx.Tunnel -notcontains [int]$_.InterfaceIndex)
    })

    # 优先挑"有默认路由且下一跳可信"的网卡；隧道网卡已排除，不会被选中
    foreach ($a in $cands) {
        $dr = $routes | Where-Object {
            [int]$_.InterfaceIndex -eq [int]$a.InterfaceIndex -and
            $_.DestinationPrefix -eq '0.0.0.0/0' -and
            $_.NextHop -ne '0.0.0.0' -and (Test-PortalIP $_.NextHop)
        } | Select-Object -First 1
        if ($dr) {
            $ctx.IfIndex = [int]$a.InterfaceIndex
            $ctx.Alias   = $a.InterfaceAlias
            $ctx.IP      = $a.IPAddress
            $ctx.Gateway = $dr.NextHop
            return $ctx
        }
    }
    # 退一步：没有默认路由，但该网卡上有指向可信下一跳的路由，也能当网关
    foreach ($a in $cands) {
        $r = $routes | Where-Object {
            [int]$_.InterfaceIndex -eq [int]$a.InterfaceIndex -and
            $_.NextHop -ne '0.0.0.0' -and (Test-PrivateIPv4 $_.NextHop)
        } | Select-Object -First 1
        if ($r) {
            $ctx.IfIndex = [int]$a.InterfaceIndex
            $ctx.Alias   = $a.InterfaceAlias
            $ctx.IP      = $a.IPAddress
            $ctx.Gateway = $r.NextHop
            return $ctx
        }
    }
    return $ctx
}

function Find-Route([string]$ip) {
    # 只取路由条目（Find-NetRoute 会同时返回地址条目）
    return (Find-NetRoute -RemoteIPAddress $ip -ErrorAction SilentlyContinue |
            Where-Object { $_.DestinationPrefix } | Select-Object -First 1)
}

function Sync-ProbeRoute {
    # 只在"探针确实被隧道接管"时动手，只动探针这两个固定 IP。
    # 原理：Windows 按最长前缀匹配选路，/32 必然优先于隧道的 0.0.0.0/1、1.0.0.0/8 等，
    # 而且这一层由内核路由表决定，代理软件不参与。
    $ctx = Get-NetCtx
    if ($ctx.Tunnel.Count -eq 0) { return $true }      # 没有隧道，探针本来就直连
    if (-not $ctx.IfIndex -or -not $ctx.Gateway) {
        Write-Log "ROUTE      检测到代理隧道，但找不到物理出口/网关，无法为探针固定路由"
        return $false
    }

    $ok = $true
    foreach ($u in $probeList) {
        $ip = ($u -replace '^https?://', '' -replace '/.*$', '')
        $cur = Find-Route $ip
        if (-not $cur) { $ok = $false; continue }

        if ($ctx.Tunnel -notcontains [int]$cur.InterfaceIndex) {
            # 已经是直连，但仍要检查是不是一条指向旧网关的僵尸 /32
            if ($cur.DestinationPrefix -eq "$ip/32" -and $cur.NextHop -ne $ctx.Gateway -and $cur.NextHop -ne '0.0.0.0') {
                Remove-NetRoute -DestinationPrefix "$ip/32" -InterfaceIndex $cur.InterfaceIndex -NextHop $cur.NextHop -Confirm:$false -ErrorAction SilentlyContinue
                New-NetRoute -DestinationPrefix "$ip/32" -InterfaceIndex $ctx.IfIndex -NextHop $ctx.Gateway -RouteMetric 1 -PolicyStore ActiveStore -ErrorAction SilentlyContinue | Out-Null
                Write-Log "ROUTE      探针 $ip 的旧路由（下一跳 $($cur.NextHop)）已失效，改指 $($ctx.Gateway)"
            }
            continue
        }

        # 被隧道接管：先清掉指向隧道的同前缀条目，再加直连
        foreach ($r in (Get-NetRoute -DestinationPrefix "$ip/32" -ErrorAction SilentlyContinue)) {
            Remove-NetRoute -DestinationPrefix "$ip/32" -InterfaceIndex $r.InterfaceIndex -NextHop $r.NextHop -Confirm:$false -ErrorAction SilentlyContinue
        }
        New-NetRoute -DestinationPrefix "$ip/32" -InterfaceIndex $ctx.IfIndex -NextHop $ctx.Gateway -RouteMetric 1 -PolicyStore ActiveStore -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep -Milliseconds 300

        $after = Find-Route $ip
        if ($after -and ($ctx.Tunnel -notcontains [int]$after.InterfaceIndex)) {
            Write-Log "ROUTE      探针 $ip 原本走隧道，已固定到 $($ctx.Alias)（网关 $($ctx.Gateway)）"
        } else {
            Write-Log "ROUTE      探针 $ip 仍被隧道接管，代理软件可能有 strict-route/防火墙强制接管，本项无法绕过"
            $ok = $false
        }
    }
    return $ok
}

# ============================================================
# 探测
# ============================================================

function Get-ProbeCode {
    # 返回 204=在线 / 302=掉认证 / 000=不通 / TUN=结果不可信（走了隧道）
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
            $name = $t -replace '^https?://', '' -replace '/.*$', ''
            $script:lastProbe = "$name -> $c remote=$rip"

            if ($c -eq '000') { continue }

            if ($rip -and -not (Test-PortalIP $rip)) {
                # 响应来自 fake-IP 段，说明这一发被隧道吸走了，结果不可信
                $script:lastProbe = "$name -> $c remote=$rip（fake-IP，结果丢弃）"
                $script:probeTrusted = $false
                continue
            }
            if (-not $script:probeTrusted) {
                # 路由层面已知这一发走隧道：它的 2xx 只代表代理能上外网
                $script:lastProbe = "$name -> $c（经由代理隧道，结果不可信）"
                continue
            }
            # 被改写去认证页 = 掉认证
            if ($rdr -match '(?i)(hnu\.edu\.cn|eportal|wlanuserip)') { return '302' }
            # 拿到目标自己的真实响应（223.5.5.5 回 404，1.1.1.1 回 301）= 出网正常
            return '204'
        }
        if ($round -lt 2) { Start-Sleep -Seconds 1 }
    }
    if (-not $script:probeTrusted) { return 'TUN' }
    return '000'
}

function Test-PortalReachable([string]$ip) {
    # 不依赖 DNS，直接用 IP 判断门户是否可达：可达说明链路正常，只是还没认证
    if (-not (Test-PortalIP $ip)) { return $false }
    $c = & curl.exe -4 --noproxy '*' -s -m 6 --connect-timeout 3 -o NUL -w '%{http_code}' `
        --resolve "${phost}:${pport}:$ip" $portal 2>$null
    if ([string]::IsNullOrWhiteSpace($c)) { return $false }
    return ("$c".Trim() -ne '000')
}

function Test-PortalIdentity([string]$ip) {
    # 确认这个地址背后真的是认证门户：返回 200 且页面带 EPortal 特征。
    # 只校验 IP 格式是不够的——DNS 被劫持（或域名恰好存在公网记录）时，
    # 一个格式完全合法的地址照样会被当成门户，一旦写进缓存，之后每次登录都发错地方。
    if (-not (Test-PortalIP $ip)) { return $false }
    $raw = & curl.exe -4 --noproxy '*' -s -m 8 --connect-timeout 3 `
           -w "`n#HTTP%{http_code}#" --resolve "${phost}:${pport}:$ip" $portal 2>$null
    if (-not $raw) { return $false }
    $txt  = ($raw -join "`n")
    $code = ''
    $m = [regex]::Match($txt, '#HTTP(\d{3})#')
    if ($m.Success) { $code = $m.Groups[1].Value; $txt = $txt -replace '#HTTP\d{3}#', '' }
    if ($code -eq '200' -and $txt -match '(?i)EPortal') { return $true }
    # 未认证时门户可能直接 302 到登录页（响应体为空），这时只能靠跳转目标判断
    if ($code -eq '302' -and $txt -match '(?i)eportal')      { return $true }
    return $false
}

function Get-CampusDns {
    # 纯 .NET 取网卡 DNS。只保留内网 DNS：公网 DNS（如 202.197.96.100）的查询
    # 在 TUN 下同样会被劫持成 fake-IP，问了也白问。
    $out = @()
    try {
        foreach ($n in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            if ($n.OperationalStatus -ne 'Up') { continue }
            foreach ($d in $n.GetIPProperties().DnsAddresses) {
                if ($d.AddressFamily -ne 'InterNetwork') { continue }
                $s = $d.ToString()
                if (Test-PrivateIPv4 $s) { $out += $s }
            }
        }
    } catch {}
    return @($out | Select-Object -Unique)
}

function Resolve-PortalIP {
    # 确定门户地址：缓存优先，其次内网 DNS，新地址必须自证是门户才写缓存。
    # 注意：缓存验不过时**不再删除**。删掉之后下一轮连候选都没有，
    # 一旦 DNS 也被劫持就彻底失去自愈能力（v7 的问题）。
    $cached = ''
    if (Test-Path $ipf) { $cached = (Get-Content $ipf -Raw).Trim() }

    if ($cached -and (Test-PortalIdentity $cached)) { return $cached }

    $cands = @()
    foreach ($d in (Get-CampusDns)) {
        $ips = $null
        try {
            $ips = Resolve-DnsName -Name $phost -Server $d -Type A -DnsOnly -ErrorAction SilentlyContinue |
                   Where-Object { $_.Type -eq 'A' } | Select-Object -ExpandProperty IPAddress
        } catch {}
        if ($ips) {
            Write-Log "DNS        内网 DNS $d -> $($ips -join ', ')"
            $cands += @($ips)
        }
    }
    # 系统 DNS 兜底（TUN 下大概率是 fake-IP，会被下面的校验挡掉）
    try {
        $sys = [System.Net.Dns]::GetHostAddresses($phost) |
               Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
               ForEach-Object { $_.IPAddressToString }
        $cands += @($sys)
    } catch {}

    foreach ($c in ($cands | Select-Object -Unique)) {
        if (-not (Test-PortalIP $c)) {
            Write-Log "DNS        解析到 $c（不在可信范围，已忽略）"
            continue
        }
        if (Test-PortalIdentity $c) {
            Set-Content -Path $ipf -Value $c -Encoding ASCII
            if ($cached -and $cached -ne $c) {
                Write-Log "PORTAL     门户地址由 $cached 改为 $c（旧地址已失效，新地址已验证）"
            }
            return $c
        }
        Write-Log "DNS        解析到 $c（连不上门户或不像门户，已忽略）"
    }

    # 都没验明正身：保留缓存地址当"最后已知可用"，但要求至少链路有响应，
    # 免得把凭据 POST 到一个根本没有服务在听的地址。
    if ($cached -and (Test-PortalReachable $cached)) {
        Write-Log "PORTAL     缓存 $cached 本次未能自证门户身份，但链路可达，仍按该地址尝试"
        return $cached
    }
    if ($cached) { Write-Log "PORTAL     缓存 $cached 连同 DNS 均不可用（已保留，未删除）" }
    else         { Write-Log "PORTAL     缓存与 DNS 均未验证出门户地址" }
    return ''
}

function Get-EgressIP([string]$portalIp) {
    # 求"校园网认证记录的本机 IP"。
    # 关键：先拿门户地址去问内核——门户在内网，源地址必然是物理网卡地址；
    # 而公网地址（223.5.5.5）在 TUN 下会被路由到隧道，源地址变成 198.18.0.1，
    # 被判定不可信后整轮跳过，这就是日志里 NOIP 的来源。
    $dsts = @()
    if ($portalIp) { $dsts += $portalIp }

    # 门户地址未知时：隧道在场就先问物理出口网卡自己的地址（最可靠），
    # 否则才退到公网 IP 反求源地址（只有没隧道时才成立）
    if ($script:tunnelSeen) {
        $ctx = Get-NetCtx
        if ($ctx.IP) { $dsts += $ctx.IP }
    }
    foreach ($u in $probeList) {
        $dsts += ($u -replace '^https?://', '' -replace '/.*$', '')
    }

    # 最后兜底：本地网卡枚举。192.168.x 通常是 Hyper-V / 虚拟内网，
    # 排在后面，免得被当成校园网地址
    $local = @()
    try {
        foreach ($n in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            if ($n.OperationalStatus -ne 'Up') { continue }
            if ($n.NetworkInterfaceType -eq 'Loopback') { continue }
            foreach ($u in $n.GetIPProperties().UnicastAddresses) {
                if ($u.Address.AddressFamily -ne 'InterNetwork') { continue }
                $s = $u.Address.ToString()
                if ((Test-PortalIP $s) -and -not (Test-TunnelIP $s)) { $local += $s }
            }
        }
    } catch {}
    $dsts += @($local | Where-Object { $_ -notmatch '^192\.168\.' })
    $dsts += @($local | Where-Object { $_ -match '^192\.168\.' })

    foreach ($dst in ($dsts | Select-Object -Unique)) {
        try {
            $sock = New-Object System.Net.Sockets.Socket(
                [System.Net.Sockets.AddressFamily]::InterNetwork,
                [System.Net.Sockets.SocketType]::Dgram,
                [System.Net.Sockets.ProtocolType]::Udp)
            $sock.Connect($dst, 80)
            $ip = $sock.LocalEndPoint.Address.ToString()
            $sock.Close()
        } catch { $ip = '' }
        if (-not $ip) { continue }
        if (-not (Test-PortalIP $ip))  { continue }
        if (Test-TunnelIP $ip)         { continue }
        return $ip
    }
    return ''
}

function Repair-NetState([string]$ip) {
    # Windows 的"是否有 Internet"判定（NCSI）不会自己复查：它在认证之前就把网络
    # 标记成"需要登录的门户"，之后只有链路重新上线才会重测。于是会出现网已经通了、
    # 任务栏却一直显示断网图标的情况。这里用一次网卡重启把判定唤醒。
    if ($script:tunnelSeen) {
        # 重启物理网卡会把正在用的代理隧道一起打断，得不偿失，宁可图标难看
        Write-Log "NETSTATE   检测到代理隧道，跳过网卡重启（避免打断隧道）"
        return
    }
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

# ---------- 第零步：隧道处理 ----------
# 探针必须反映校园网，不能被代理隧道代言。检测到隧道就先固定探针路由。
$tunIdx = @(Get-TunnelIndexes)
$script:tunnelSeen = ($tunIdx.Count -gt 0)
if ($script:tunnelSeen) {
    $script:probeTrusted = Sync-ProbeRoute
}

# ---------- 诊断模式 ----------
if ($Diag) {
    Write-Output '================ HNU 校园网 · 诊断 ================'
    Write-Output ("时间            : " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    Write-Output ("工作目录        : " + $base)
    Write-Output ("隧道网卡 ifIndex: " + $(if ($script:tunnelSeen) { $tunIdx -join ',' } else { '无' }))
    $ctx = Get-NetCtx
    Write-Output ("物理出口        : " + $(if ($ctx.IfIndex) { "$($ctx.Alias)  ifIndex=$($ctx.IfIndex)  ip=$($ctx.IP)  gw=$($ctx.Gateway)" } else { '未识别' }))
    Write-Output ("内网 DNS        : " + $((Get-CampusDns) -join ', '))
    $cached = ''
    if (Test-Path $ipf) { $cached = (Get-Content $ipf -Raw).Trim() }
    Write-Output ("门户缓存        : " + $(if ($cached) { $cached } else { '空' }))
    Write-Output ("缓存自证门户    : " + (Test-PortalIdentity $cached))
    foreach ($u in $probeList) {
        $ip = ($u -replace '^https?://', '' -replace '/.*$', '')
        $r = Find-Route $ip
        $via = if ($r) { "ifIndex=$($r.InterfaceIndex) $($r.DestinationPrefix)" } else { '无路由' }
        Write-Output ("探针路由        : $ip -> $via" + $(if ($r -and ($tunIdx -contains [int]$r.InterfaceIndex)) { '（走隧道）' } else { '' }))
    }
    # 直接打印内核实际选用的源地址：能证明这一发走的是物理网卡还是隧道
    foreach ($u in $probeList) {
        $o = & curl.exe -4 --noproxy '*' -s -m 6 -o NUL -w '%{http_code}|src=%{local_ip}|dst=%{remote_ip}' $u 2>$null
        if ($o) { Write-Output ("探针实发        : $u -> $o") }
    }
    $code = Get-ProbeCode
    Write-Output ("探针结果        : $code   可信=" + $script:probeTrusted + "  明细=" + $script:lastProbe)
    Write-Output ("出口 IP         : " + (Get-EgressIP $cached))
    Write-Output '=================================================='
    exit 0
}

# ---------- 第一步：探测。在线就直接退出（绝大多数运行走这条最轻的路径）----------
$code = Get-ProbeCode
if ($code -eq '204') {
    # 在线时若门户缓存丢了，顺手补回来：否则将来掉线那一刻连候选地址都没有，
    # 而恰恰那时 DNS 最可能也不可用。已有缓存不做重复验证，免得每次在线运行都
    # 多发一个请求（在线路径必须足够轻）。
    if (-not (Test-Path $ipf)) {
        $fixed = Resolve-PortalIP
        if ($fixed) { Write-Log "PORTAL     缓存缺失，已在线时补齐门户地址 $fixed" }
    }
    exit 0
}

$resolvedPortal = ''
if ($code -eq 'TUN') {
    # 探针仍被隧道接管，204 不能作为"在线"依据。改为向门户试探：
    # 若本机其实在线，门户会回 ret_code=2（已在线），代价仅一次请求。
    Write-LogOnce "PROBE       探针被代理隧道接管（$($script:lastProbe)），改以门户应答判断"
    $code = 'TUN'
}
if ($code -eq '000') {
    # probe=000 有两种完全不同的情况：
    #   1. 真的断网；
    #   2. DNS 不可用（未认证时校园 DNS 常被挡、或 VPN 把解析劫持成 fake-IP）。
    # 第 2 种必须继续登录，否则会像旧版那样：明明只是掉认证，却整轮跳过、一直不恢复。
    $cached = ''
    if (Test-Path $ipf) { $cached = (Get-Content $ipf -Raw).Trim() }
    # 缓存里的地址本身也可能是坏的（曾被 DNS 污染过），所以不通时要再重新确认一次，
    # 不能因为一个坏缓存就把整轮判成断网。
    if (Test-PortalReachable $cached) {
        Write-Log "PROBE       probe=000 但门户可达（$cached），判定为掉认证而非断网，继续登录"
    } else {
        $resolvedPortal = Resolve-PortalIP
        if ($resolvedPortal) {
            Write-Log "PROBE       probe=000，重新确认到门户地址（$resolvedPortal），判定为掉认证而非断网，继续登录"
        } else {
            $cached = ''
        }
    }
    if (-not $cached -and -not $resolvedPortal) {
        Start-Sleep -Seconds 5
        $code = Get-ProbeCode
        if ($code -eq '204') { exit 0 }
        if ($code -eq '000') {
            Write-LogOnce "NETDOWN    probe=000 且门户不可达（链路确实不通），本轮跳过"
            exit 0
        }
    }
}

# ---------- 第二步：确定门户地址（缓存优先，不让 DNS 有机会覆盖）----------
$pip = $resolvedPortal
if (-not $pip) { $pip = Resolve-PortalIP }
if (-not $pip) {
    # 缓存和 DNS 都没能验明正身，就不要拿它们去登录了（大概率是假地址）
    Write-Log "PORTAL     缓存与 DNS 均未验证出门户地址，本轮不带地址尝试登录"
}

# ---------- 第三步：确定本机出口 IP ----------
$myip = Get-EgressIP $pip

if (-not $myip) {
    Write-LogOnce "NOIP       before=$code 无法确定本机出口 IP"
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
    if ($after -eq '204' -and $script:probeTrusted) { break }
    # 门户回「该 IP 已经在线」= 本机并没有掉线（多半是探测偶发误判），
    # 换 MAC 再试也是同一个答复，直接收工。
    if (("$resp") -match '"ret_code"\s*:\s*2') { break }
    if ($attempt -lt 3) { Start-Sleep -Seconds 5 }
}

$short = ($resp -join ' ')
if ($short.Length -gt 160) { $short = $short.Substring(0,160) }

$via = ''
if ($script:tunnelSeen) { $via = "tun=yes" }

if ($after -eq '204' -and $script:probeTrusted) {
    Write-Log "REAUTH OK   before=$code after=$after try=$try ip=$myip mac=$usedMac portal=$pip probe=$($script:lastProbe) $via resp=$short"
    # 认证已经成功，但系统可能仍显示"无 Internet / 需要操作"，这里主动唤醒一次判定
    Repair-NetState $myip
} elseif (("$resp") -match '"ret_code"\s*:\s*2') {
    Write-LogOnce "REAUTH SKIP before=$code after=$after ip=$myip note=门户返回已在线 $via"
} else {
    Write-Log "REAUTH FAIL before=$code after=$after try=$try ip=$myip mac=$usedMac portal=$pip probe=$($script:lastProbe) $via resp=$short"
}
