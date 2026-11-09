# 排错手册

按"症状 → 原因 → 处理"组织。这些都是实际遇到过的情况。

## 日志文件是空的，是不是没生效？

**正常。** 脚本在线时检测到网络正常就直接退出，不写日志。只有真的发生过"掉线 → 重新认证"才会留下记录。

想确认它确实在跑：

```powershell
# Windows
Get-ScheduledTaskInfo -TaskName 'HNU Portal Keepalive' | Select LastRunTime, LastTaskResult
```

```bash
# Linux
systemctl list-timers hnu-portal.timer
```

`LastRunTime` / `NextRun` 在推进，就说明任务正常。

## 日志里出现 NETDOWN

```
2026-10-23 21:18:41  NETDOWN    probe=000（链路/DNS 不通，本轮跳过登录）
```

**原因**：这一轮检测请求根本没能发出去——网线没插、上游断了、或域名解析失败。脚本刻意不把这种情况当成"掉线"，所以不会去反复尝试登录。

**处理**：一般无需干预，链路恢复后自动继续。若短时间内连续出现很多条，检查网卡状态和 DNS 配置。

## 日志里出现 REAUTH FAIL

表示确实检测到掉线，但重新认证没成功。看末尾的返回内容判断：

| 返回内容 | 结论 | 处理 |
|---|---|---|
| 提示账号或密码相关错误 | 密码不对 | 用菜单 `2` 重新输入 |
| 内容为空 | 请求被中间设备拦截 | 不是密码问题，检查是否开了代理、VPN、防火墙 |
| 完全没有返回 | 链路问题 | 参见上面的 NETDOWN |

改动密码后最保险的做法是菜单 `2` 重新录一遍，而不是手工编辑文件。

## Windows：BAT 里中文全是乱码，或提示"命令语法不正确"

**原因**：文件编码或换行被改坏了。脚本需要在中文 Windows 的默认编码环境下运行，用编辑器"另存为 UTF-8"会破坏它。

**处理**：重新从 Release 下载原始文件，不要用编辑器打开后另存。

## Windows：双击 BAT 窗口一闪就没了，或报"输入行太长"

```
输入行太长。
命令语法不正确。
```

**原因**：v1.0.5 及更早的安装包里有个缺陷——它把内嵌脚本的整段 base64 直接写进同一条命令，而 `cmd.exe` 单条命令行上限是 8191 字符。脚本变大之后展开长度超过上限，这条命令必然失败，双击就闪退。

**为什么老机器上没遇到**：已经装过的机器 `%ProgramData%\HNU-Portal\keepalive.ps1` 已存在，这段释放逻辑会被直接跳过。所以它只在**全新机器**上暴露，看起来很像"某台电脑不兼容"，其实是版本问题。

**处理**：换用 v1.0.6 或更新的安装包。若已经装了旧版且能正常跑，可以不动。

**自查方法**（想确认旧包是否受影响）：

```bat
findstr /C:"FromBase64String" HNU-Portal.bat >nul && echo 旧写法
findstr /C:"ReadAllText" HNU-Portal.bat >nul && echo 新写法（分片写文件）
```

## Windows：计划任务返回码不是 0

| 返回码 | 含义 |
|---|---|
| `0` | 成功 |
| `0x1` | 脚本抛出异常，看 `keepalive.log` |
| `0x41301` | 上一次还没跑完，本轮被跳过（正常防堆积行为） |
| `0x41303` | 从未运行过 |
| `0x41306` | 运行超时被强制终止 |

查看当前设置：

```powershell
(Get-ScheduledTask -TaskName 'HNU Portal Keepalive').Settings |
  Select StartWhenAvailable, ExecutionTimeLimit, MultipleInstances
```

## Windows：开着 VPN / 代理软件（TUN 模式）时一直认证不上

典型表现是每轮只重复这三行，反复很久也不恢复，关掉代理软件后立刻就好了：

```
DNS    解析到 198.18.0.16（不在可信范围，已忽略）
PORTAL 缓存与 DNS 均未验证出门户地址，本轮不带地址尝试登录
NOIP   before=302 无法确定本机出口 IP，本轮跳过
```

v1.0.7 起已内置处理，正常情况下不需要再管。先跑一次诊断看当前判断过程：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\ProgramData\HNU-Portal\keepalive.ps1 -Diag
```

重点看三行：

- `隧道网卡 ifIndex`：检测到的代理隧道网卡
- `探针路由`：`ifIndex` 指向物理网卡才对；显示「走隧道」并且下面紧跟
  `ROUTE 探针 … 仍被隧道接管` 时，说明代理软件开了 strict-route 或防火墙强制接管，
  路由表层面绕不过去，只能关掉 TUN 才能稳定认证
- `探针实发`：`src=` 应该是校园网网卡地址（形如 `10.x.x.x`），
  `src=198.18.x.x` 说明这一发还在走隧道

**为什么开 TUN 会坏**

- 代理软件把 `0.0.0.0/0` 接管后，公网探针走的是隧道，测到的是「代理能不能上外网」，
  而不是「校园网通不通」；
- 求本机出口 IP 时，内核给出的是隧道源地址 `198.18.0.1`，被判定不可信后整轮跳过；
- DNS 被改成 fake-IP，门户域名恒解析成 `198.18.x`。

`--noproxy '*'` 对以上三种情况全部无效——它只关应用层 HTTP 代理，管不了 IP 层劫持和
DNS 劫持。v1.0.7 的做法是给探针加 `/32` 路由指回物理网关（Windows 按最长前缀匹配，
`/32` 必然优先于隧道的 `/1`、`/8` 网段），出口 IP 改为向内网门户询问，门户域名只查内网 DNS。

## Windows：任务在跑但网络没恢复

确认任务运行身份：

```powershell
(Get-ScheduledTask -TaskName 'HNU Portal Keepalive').Principal
```

应为 `NT AUTHORITY\SYSTEM`。若显示成某个普通用户名，说明注册时主体不对，删掉任务重新用菜单 `1` 安装。

## Linux：定时器在跑但没恢复

```bash
systemctl list-timers hnu-portal.timer      # NextRun 是否在推进
systemctl status hnu-portal.service         # 上次运行结果
journalctl -u hnu-portal.service -n 30      # 输出与报错
```

如果 `NextRun` 不动，检查是否被手动 `stop` 过，或存在重名的旧单元：

```bash
systemctl list-units --all | grep hnu
```

## Linux：识别到的网卡不对

先只读确认：

```bash
sudo bash HNU-Portal.sh selftest
```

脚本选的是"能把数据包发到校园网的那张网卡"，不是按网卡名写死的。多网卡机器上若识别错了，说明出口走的路由不是预期的，检查 `ip route` 和网络配置。

## 密码里带特殊字符

`$ & % ! " '` 这些字符在命令行里有特殊含义。**不要手工拼命令去写密码文件**，用菜单 `2` 录入（内部不会解释特殊字符）。

若手工编辑，Windows 用 `notepad`、Linux 用 `nano`，并确认**末尾没有换行**：

```bash
sudo wc -c /etc/hnu-portal/pass          # 字节数应正好等于密码字符数
sudo od -c /etc/hnu-portal/pass | tail -2   # 末尾不应出现 \n
```

## 想验证"掉线后能自动恢复"

本项目不提供主动注销功能（认证系统那侧不开放），手工验证步骤：

1. 在**目标机器自己的浏览器**里打开校园网认证页并注销
   （认证页按来源地址识别终端，在别的机器上点，下线的是那台机器）
2. 等 2 分钟
3. 看日志末尾是否出现 `REAUTH OK`

实测参考：从注销到恢复约 **78 秒**，日志显示 `try=1`（一次成功）。
