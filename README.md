# hnu-portal-keepalive

湖南大学校园网 Portal 认证自动保活脚本，Windows 与 Linux 双平台。

系统定时检测网络是否处于已认证状态，一旦掉线就自动用你保存的账号密码重新登录。适合长期开机的服务器、无人值守的虚拟机、远程办公的固定工位——掉线后再不用专门开个浏览器去点登录页。

> 仅用于**本人设备、本人账号**的自动重新认证。不绕过任何计费、不共享账号、不修改网络配置。使用前请确认符合学校网络管理规定。

---

## 特性

- **单文件交付**：Windows 一个 `.bat`，Linux 一个 `.sh`，拷到新机器运行即可，无需安装任何依赖
- **交互式菜单**：安装、改密码、卸载、看日志、立即重连，一个界面全搞定
- **注册为系统任务**：Windows 用任务计划程序，Linux 用 systemd timer，关机重启后依然生效
- **装完即生效**：安装结束会立刻检测一次，不用等下个周期
- **开销极低**：没有常驻进程，每 2 分钟才醒一次、跑完就退出。Windows 单次约 0.44 秒 CPU、76 MB 内存；Linux 约 0.05 秒、11 MB。摊薄后分别占单核 0.37% 与 0.04%
- **凭据只存本机**：Windows 目录权限收紧为仅 `SYSTEM` 与 `Administrators` 可读，Linux 为 `600 root`

## 大致是怎么工作的

- 每 2 分钟检查一次当前网络是否处于已认证状态；
- 若发现掉线，就用本机保存的账号密码自动完成认证；
- 认证失败会重试几轮；若是链路本身不通，则只记录一笔并跳过，不做无意义的反复尝试。

日志平时是空的，**只有真的发生过掉线重连才会有内容**。

## 快速开始

### Windows

1. 下载 `hnu-portal-windows-*.zip`（见 [Releases](../../releases)），解压
2. 双击 `HNU-Portal.bat`，同意 UAC 提权
3. 选 `1`，输入校园网账号 → 回车 → 输入密码（屏幕上不显示，属正常）→ 回车
4. 最后一行会显示当前网络状态，出现「已认证」或「OK」字样就说明装好了

```
============================================================
   湖南大学 校园网自动保活   v1.0.6
============================================================
   状态: 已安装
------------------------------------------------------------
   [1] 安装 / 首次配置 (输入校园网账号和密码)
   [2] 修改账号或密码
   [3] 卸载 (清除本机上的脚本、凭据和计划任务)
   [4] 查看日志 (重新认证记录)
   [5] 立即检测并重连一次
   [0] 退出
============================================================
```

安装后的文件位置：

| 用途 | 路径 |
|---|---|
| 核心脚本 | `C:\ProgramData\HNU-Portal\keepalive.ps1` |
| 账号 / 密码 | `C:\ProgramData\HNU-Portal\{user,pass}.txt` |
| 日志（仅掉线时写入） | `C:\ProgramData\HNU-Portal\keepalive.log` |
| 计划任务 | 任务计划程序 → `HNU Portal Keepalive` |

### Linux

```bash
tar -xzf hnu-portal-linux-*.tar.gz
cd hnu-portal
sudo bash HNU-Portal.sh
```

选 `1`，按提示输入账号密码即可。

只想先看看脚本识别到的网卡和当前在线状态（只读，不改动任何配置）：

```bash
sudo bash HNU-Portal.sh selftest
```

安装后的文件位置：

| 用途 | 路径 |
|---|---|
| 程序 | `/usr/local/bin/hnu-portal` |
| 账号 / 密码 | `/etc/hnu-portal/{user,pass}`（`600 root`） |
| 日志 | `/var/log/hnu-portal.log` |
| 调度 | systemd `hnu-portal.timer`（无 systemd 的环境回退到 `cron`） |

## 排查

```bash
# Linux：看有没有发生过自动重认证
sudo grep -E 'REAUTH (OK|FAIL)|NETDOWN' /var/log/hnu-portal.log | tail -20
```

```powershell
# Windows
Get-Content C:\ProgramData\HNU-Portal\keepalive.log -Tail 20 -ErrorAction SilentlyContinue
Get-ScheduledTaskInfo -TaskName 'HNU Portal Keepalive' | Select LastRunTime, LastTaskResult
```

常见症状（日志为空是否正常、任务返回码含义、密码含特殊字符、菜单中文乱码等）见 [docs/troubleshooting.md](docs/troubleshooting.md)。

## 卸载

菜单里选 `3` 即可清理干净（程序、凭据、定时任务）。

如果连脚本都删掉了，手动执行：

```powershell
# Windows
Unregister-ScheduledTask -TaskName 'HNU Portal Keepalive' -Confirm:$false
Remove-Item 'C:\ProgramData\HNU-Portal' -Recurse -Force
```

```bash
# Linux
sudo systemctl disable --now hnu-portal.timer
sudo rm -f /etc/systemd/system/hnu-portal.{service,timer}
sudo systemctl daemon-reload
sudo rm -f /usr/local/bin/hnu-portal /var/log/hnu-portal.log
sudo rm -rf /etc/hnu-portal
```

## 修改检测周期

默认 2 分钟。想再省一点可以拉长，代价是掉线后恢复更慢。

```bash
# Linux
sudo sed -i 's/OnUnitActiveSec=2min/OnUnitActiveSec=5min/' /etc/systemd/system/hnu-portal.timer
sudo systemctl daemon-reload && sudo systemctl restart hnu-portal.timer
```

```powershell
# Windows
$t = Get-ScheduledTask -TaskName 'HNU Portal Keepalive'
($t.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskTimeTrigger' }).Repetition.Interval = 'PT5M'
Set-ScheduledTask -TaskName 'HNU Portal Keepalive' -Trigger $t.Triggers
```

## 从源码构建

Windows 版是单文件分发，由 `windows/src` 下的源文件生成。改了源码后在 `windows/src` 目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
```

Linux 版没有构建步骤，`HNU-Portal.sh` 本身既是安装器也是运行程序。

## 兼容性

| 平台 | 状态 |
|---|---|
| Windows Server 2022（PowerShell 5.1） | 已实测 |
| Windows 10 / 11 | 理论可用，未逐一实测 |
| Ubuntu 24.04 LTS（systemd） | 已实测 |
| Debian / RHEL / AlmaLinux | 同一套代码，调度回退到 `cron`，未逐一实测 |
| WSL | **不适用**。WSL2 的出口流量会被 NAT 成 Windows 的地址，门户看到的不再是 Linux 自己 |

## 反馈

欢迎提 Issue 反馈其他学校、其他版本认证系统的差异，或报告在别的发行版上的问题。

## License

[MIT](LICENSE)
