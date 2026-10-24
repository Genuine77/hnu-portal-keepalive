@echo off
chcp 936 >nul 2>&1
title HNU 校园网自动保活
set "BASE=%ProgramData%\HNU-Portal"
set "PS1=%BASE%\keepalive.ps1"
set "TASKNAME=HNU Portal Keepalive"

rem ==================== 管理员自提权 ====================
net session >nul 2>&1
if not errorlevel 1 goto ELEVATED
echo.
echo   需要管理员权限，正在请求提权，请在弹窗中点"是"...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:ELEVATED
pushd "%~dp0"

rem ==================== 内嵌核心脚本（gzip + base64） ====================
set "B64=H4sIAAAAAAAEAK1Y/1cTxxb/PX/FnDQlyZFdErAepcZXyhfllS85Bup5x/bQZTNA6mY3b3cD8nicE9oqoMRQi0UQVOo3ahX0qFUJyB/T7Gb5yX/h3ZnZ3Wwi4Puh0XNIZu69M3Pv537m3nlf3P0EnenpR+bdNePW0/LOz9b0Y+PKeml31XxZfL89YxQ2y4+K5v18eXYGjR59vz3r+wSVF54TJS6uqLog8YOCjvamr5gL74yZZ+jTuKoMq0K6TdCFT7+piH2DjPlroGltrBkz10vFonFlrVR8gBL/SvS1dyNr649Sccd69mN5Yf2v3A+wSuntHVjdyN8oX31i7c5ba3Pvt5fNX6dLxT/N2Zyxsl6+tWHs3DDyL0pvtozXD0o7K2yEbHv6qZnf+Cs3ZS4+MHYX937cIbtbWTfm5xyZWboKrGNt3Lc2p8xrD4zCPVBtjDQe46IRrrEJGRu3zVdXQRQWblP51t5uxM6CjHzB2thAzccjUbCA0On2PjSi65nmhoYxPMiPyFkeJ7O8KBOJBpyhWg3/EGNMv06IScpwSq4TBUkaFMQLsaQajUSa6ujoQBrrI0oyxkyTT11Ww+qAIIpKVtZj9ZH6k9bLh0bh9Sk2kRE0bUxRk7GTxubl8t2pU3VjkiAP0LlUJnbSXHlirmx1xk9VDFYE0oIYO9nd0morCSJRcb/LQhrH6r7XvsaqllLk2FE+UjcaO7m3XACLp+pAajj2nxFOlOt0rKZTsiAN6OMZbO/dnJk3rtyxdheMW7cRO2Jowq9iLSvp/uZovT+tDfub/cwpzKd2NKji++0p/2QYLJkv1s2fChCF0pu89XAKIILAly2tCazrKXkY3NlFHIeOoDbyacgSj7zfntv74Z7xYNHK2dEFAFi7S0bhGWppRaU3V8yp6/beWrL6CGpXVUUNcdETJ8IONkaPIqNw07z1EoBh5h5ZP+4wNNDTRXlkXvsNEGIW5gH55krOmM3vrf4GCzdGjqLyrZew7F4uZ0xvgT3j2p29tS1jq2De3DQuzRhTy5BtRn7N2Fgu7eSNy3lmC5SNzW1r+qW5WTCfrBEs//LYzN0geN/aZflHP4BpcIVx5a61s4N6sN7XGu+MI3N9zVhdJEYodiF7wAhqjfej8tZD1Mg3ovKj65AXxuVLxtObKHosgrq/ZPmGYBrtreTA6t503o7DIuRanm2RbRdMl94smAtvIenKW5uI72nvcxxCP/1tcSQqsoxFHZnPf/DDSubdN8a14t7iujnzGlIXwlde/sncmkedcT8cEIJqFH425i7B6Y6QowCWL3TKAKghQcTIvA1hf2cUfkWAUljeWYqoXc6X3q1ar35FHSk5yYHqWSWrY9SATmOd/GxJChmwUxnojLckkwBAzTlzEwTxxox5ewUOwXxsgncqbttbykNsifOiDU2wWWvzofVoCokjlPTm4CC2pzffmpsLNq34AhRLLaIOORNX8RBWsQxHiaFgIiVhWZfGWxUZoJvFQR9sg3M/yHq9abz7yTPiSw2hUCCeSIhqKgPnU/QwmkCBQUEj9qom0CTCEgxXpoOtzd94+NhDx0E06Qtkh6gnY+ifSkrm4gIkAdMMEmrg9Yt60BfIHChEsswWSjGp/YTYJZHKgBTQ2wFSFzDOCFJqFPMgQxZVlUFMJIM2rdqQ4lUlzadT2RQvKumGYSxjVdDxAOQbURpRNJ0qVZMwmSLboFNAyOQ34/EY8tv2mfJ3zUzSpWy/zzeUlWkc0Tk1pWMOmCZ0XtNV4J1vA8BfEA0fOVRA18AcgRl4GiOuQ1HTgJHgOHy4"
set "B64=%B64%7m4umURnzjSn082aFqQKAESOoADggGxfEP9wXwtSFiM/sUfs+xHXLotKEtZD/X0dx32Tni2R5eLEVa1KEjsbEWEfdUjMqhKPL8JOjiJOQ1waHUecgnr6uxA3hoKfTpCDD4BhPBlEtr8bTwXkrCRRMwR2zjmbmzu1HpjoVc+NgA8SGcjLUEAMUySS5YKRSIQgiiiqWM+qMhxA9PN9aiodCpMtV4EceLK8s2Hey5l3HtRCnZMByCFysFYlnRbkpOcknqxCtYkUdgLhhgkF28+e7T3L2MKcfUcIAwoUxxwkM7AdOgfMoYxpKBpB0eORpiPAFQmsjgJpNEaiJ45ARrNw4YspHUXJUSq77MOabocuO0S9QaUi4Il9hTI1QpCBkGfgP/u8DAwkLbmzwljYcV+AJNoHUpkaqY8HjCwWBhCo6HA5slzNRuEOppWU9ecl8EsEffUlXIyPoUws31giF9/8NdQEw1Ck0X14Dw2ghkVJIEP0AJ06TrNRvgvLwyDCDetg9OjxSMQNYtVJaVr0CSmJrvFfiE/t5AcZUgW38pMnpTc58+kDwvGFx+yiJVcy5Xvj2XPvVQ2wKBdXjfuPjPvL5o1nrPK0XsGXJXN1Dc5q7RSB9RlPAzo88A2QbLJJwM1Kxt90hsP/RkFCVdW+rREgqeS4IaELqs4lJGBHxCUwkGBSQ5/Zab7fYk7mHmCPKkoCsCTkbNAdIhq1EZtwBUMHBCMKYf0eiBws2anvrk41CfyBAsURFIQioa33XA89uCc/7WGiRgkoBnslafnLO3BvQ1tPglzye7lluPWhhrV2NqzXL6zd6fJSkZXw3nWZP+nPyf3c8IHf90PJ1hxDSXltA671mmIIdkFAQEsi69E98/Y8K2mgjPGSWCCTyjD36uq4w8kCjJxPjGuAfR7KEL5N1iD5wLFn4NaxSxKshdgtFAaMnxuBmoHrHfye1FEQiwHeluoQ0ilpnJ2JFkl2wQS+oKkhgYKjx3WkVI2wlusPgQaW7TAg8G451KckKCMQvyCRBm3CQ2JUg+WwBycpm89se9U4SdXwk82JRJboeHO4Ys65/dh6bla3JFo7O9G+aT1rp3VViTpTqUzn3A6WVq5QMi6ZT4sgaG68qs7eT6pKV8ITNzetjd9Z/bqXmwVuIP8L9+y6/e2f5eISjEAha6w8M1ZzbAGzsGbOArtMuWWtL5AedyAxpKhYAOeGAkkIDOTOF9Qj9YDPxib+M/Iv6JJgxf1JjVZ9on3X2Qiv4ItiTFPEC7BKDx5z4u8BXAImsa7Zf0OuFvmc30euCm3knvBArf6j2uxvH3SCoNpGys+P6wCJ6YqoSLZWfzITrj4b38piQ31Xj45HPPO2h5lclwJ9dbucjAM56c5JeAfioQ/MSoqG7VEX/KgSNC+fkEESiUEI4wVGIpUo2ZO+fVj272LY/dm1tzNeQ61+MmafchAT1MUYF5qLd80XNyi/LbN3AQZqILEalvXbS9rESrOvvPCc9W2QH3ko3uxUYL0Z4FwQa5mvAniZwN0beLfTG6KlMhR1fG3zxziyRZJqJ7RQ2HunUbfIfG+GtANgSJDg5tSzUPbK0Fz0Z4L7ZI9Hr9Y6gSBj2C5FyZAHmoMMBEYEUpkFhgRovNzRyqGz5NCwwmnSegLCYYN6iuye75dTouDhfu9x3K1lXfR+lP0pO3sUKnCn0i5ynR3rahZ/7uLYWbXGNSBLdVhgQ+wg8ZFxDfYu2SvBWSprke9dyhhWQ+Fq41X3ii8Aioo0ilvUYbD7hV29OndD7WyQ4+yRYD30FRP0kpxshi+kS4Mv"
set "B64=%B64%oOcnF0ylMeqUR5ULNBVSsqddc5xs9yj7dUmNEcSdRk6D+IVnK9+5vuG4JHTTHOhimWZV0HnZCx4qZT/7HS5U8yZ4uHD1g+Ghsv7aR0TaD/g/ruI+L9LG4HCFqodHirn/V568QwbSh0oHPS+Uh7ul6vnycNGqt83DHTgaC7AW5izkmpIOhw/fbeVx9PAd1LycBt02nCSKMKTTDpGyN82bDGIcGyAkS75HaBuZ7HbIl2RrXBjG7BcpOUjhpwPtZshlE/0cub84CaOmyu8jR9zrK03WBEOe0tHRATZp9LIVXAsrd6BcJncAsn77w7x6HYpkUnrduk16qplnrE7eW3tVenMVaiJon5CmRVGpeL88O2fktqtIx75L2RlqWTEwoqelA943oo01rzkN/qoXDdcGuVJxkhIaNcfuWP93sj9cLZgmXjiv4mF8EW6ibkJfIVsbKjY4QswfOh/hTgjcUAvX8e3EsfrJsD8Y/pDH02k+kRXh2nLp1A4QmTmtKtmMdj76LU+L3wqDHszLFe9UIkUtOmTrSB7e6KfDrgXSJrofp9qgEIu58GBjFawF0myEgjJWxbnO3L4NbJPdE9nQPqCDZdNVvZv3QqnGpKSjJtpW7Nsws0ItoI2QR0ASdrpju7RCQfv2odPeN4nosQj1j6NnSySyg8yroUg9FXF6+A93XPMg5T/b3tLfdwb1foVqyjKqGrMtgNdj1PUOhyJKjo7jyeZjbC9+n/Pke8BKHS2dXX/XSr7/AYyNEtcuHAAA"

:MENU
cls
echo ============================================================
echo    湖南大学 校园网自动保活   v1.0.0
echo ============================================================
if exist "%PS1%" (echo    状态: 已安装) else (echo    状态: 尚未安装)
echo ------------------------------------------------------------
echo    [1] 安装 / 首次配置 (输入校园网账号和密码)
echo    [2] 修改账号或密码
echo    [3] 卸载 (清除本机上的脚本、凭据和计划任务)
echo    [4] 查看日志 (重新认证记录)
echo    [5] 立即检测并重连一次
echo    [0] 退出
echo ============================================================
echo.
set "CH="
set /p "CH=请输入序号后回车: "
if "%CH%"=="1" goto INSTALL
if "%CH%"=="2" goto CHANGE
if "%CH%"=="3" goto UNINSTALL
if "%CH%"=="4" goto SHOWLOG
if "%CH%"=="5" goto RUNTEST
if "%CH%"=="0" goto BYE
goto MENU

rem ==================== 释放核心脚本 ====================
:ENSURE_PS1
if exist "%PS1%" goto :EOF

:EXTRACT_PS1
if not exist "%BASE%" mkdir "%BASE%" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b=[Convert]::FromBase64String('%B64%');$ms=New-Object IO.MemoryStream(,$b);$gz=New-Object IO.Compression.GzipStream($ms,[IO.Compression.CompressionMode]::Decompress);$o=New-Object IO.MemoryStream;$gz.CopyTo($o);$gz.Dispose();[IO.File]::WriteAllBytes('%PS1%',$o.ToArray())"
if exist "%PS1%" (echo   [OK] 核心脚本已就绪) else (echo   [X] 释放失败，请检查杀毒软件是否拦截)
goto :EOF

rem ==================== 1 / 2 输入账号密码 ====================
:INSTALL
call :EXTRACT_PS1
if not exist "%PS1%" (pause & goto MENU)
goto PROMPT_CRED

:CHANGE
call :ENSURE_PS1
if not exist "%PS1%" (pause & goto MENU)
echo.
set "OLD="
if exist "%BASE%\user.txt" set /p "OLD=<%BASE%\user.txt"
if defined OLD echo   当前账号: %OLD%
echo.

:PROMPT_CRED
set "U="
set /p "U=请输入校园网账号（直接回车取消）: "
if not defined U goto MENU
powershell -NoProfile -Command "[IO.File]::WriteAllText('%BASE%\user.txt','%U%',[Text.Encoding]::ASCII)"
echo   账号已保存: %U%
echo.
echo   请输入校园网密码（输入时不回显，输完回车）:
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=Read-Host -AsSecureString '  密码';$p=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s);$t=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($p);[IO.File]::WriteAllText('%BASE%\pass.txt',$t,[Text.Encoding]::ASCII);[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($p);Write-Host ('  [OK] 密码已保存，长度 ' + $t.Length + ' 个字符')"
echo.
call :CREATE_TASK
call :SET_ACL
call :RUN_ONCE
echo.
echo ============================================================
echo   安装完成。此后每 2 分钟自动检测一次，掉线会自动重连。
echo   本窗口可以关闭。
echo ============================================================
pause
goto MENU

rem ==================== 创建计划任务 ====================
:CREATE_TASK
powershell -NoProfile -ExecutionPolicy Bypass -Command "$a=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File %PS1%';$t=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 2);$b=New-ScheduledTaskTrigger -AtStartup;$b.Delay='PT45S';$s=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -MultipleInstances IgnoreNew;$r=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest;Register-ScheduledTask -TaskName 'HNU Portal Keepalive' -Action $a -Trigger @($t,$b) -Settings $s -Principal $r -Force | Out-Null;if ($?) {Write-Host '  [OK] 计划任务已创建（SYSTEM 身份，每 2 分钟 + 开机 45 秒）'} else {Write-Host '  [X] 计划任务创建失败'}"
goto :EOF

:SET_ACL
icacls "%BASE%" /inheritance:r /grant:r "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F" >nul 2>&1
goto :EOF

rem ==================== 立即跑一次 ====================
:RUN_ONCE
echo.
echo   正在立即执行一次检测...
powershell -NoProfile -Command "Start-ScheduledTask -TaskName 'HNU Portal Keepalive';Start-Sleep -Seconds 10;$i=Get-ScheduledTaskInfo -TaskName 'HNU Portal Keepalive';Write-Host ('  退出码: ' + $i.LastTaskResult + '  (0 = 正常)')"
echo.
echo   当前网络状态:
curl.exe -4 -s -m 8 -o NUL -w "    generate_204 => %%{http_code}   [204=OK  302=NOT LOGGED IN]\n" http://connect.rom.miui.com/generate_204
goto :EOF

:RUNTEST
call :ENSURE_PS1
call :RUN_ONCE
if exist "%BASE%\keepalive.log" (
  echo.
  echo   最近的日志:
  powershell -NoProfile -Command "Get-Content '%BASE%\keepalive.log' -Tail 10 -ErrorAction SilentlyContinue"
)
echo.
pause
goto MENU

rem ==================== 4 查看日志 ====================
:SHOWLOG
if not exist "%BASE%\keepalive.log" (
  echo.
  echo   暂无日志。
  echo   没有日志是好事，说明从未发生过掉线重连。
  echo.
  pause
  goto MENU
)
start "" notepad "%BASE%\keepalive.log"
goto MENU

rem ==================== 3 卸载 ====================
:UNINSTALL
echo.
echo   将删除以下内容:
echo     - 计划任务 "HNU Portal Keepalive"
echo     - 目录 %BASE% （含凭据、脚本、日志）
echo.
set "YN="
set /p "YN=确认卸载请输入 Y 后回车（其他任意键取消）: "
if /i not "%YN%"=="Y" goto MENU
powershell -NoProfile -Command "Unregister-ScheduledTask -TaskName 'HNU Portal Keepalive' -Confirm:$false -ErrorAction SilentlyContinue"
if exist "%BASE%" rd /s /q "%BASE%"
echo.
if exist "%PS1%" (echo   [X] 删除失败，可能文件被占用) else (echo   [OK] 已卸载，本机不再自动保活)
echo.
pause
goto MENU

:BYE
popd
endlocal
exit /b 0
