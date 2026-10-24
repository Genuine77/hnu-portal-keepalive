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
