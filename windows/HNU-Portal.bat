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
set "B64=H4sIAAAAAAAEAK1YW1MbRxZ+16/okpWVVGYGCRyXQ0pbIRhsNlxUCOLaclJkGDUw8WhGOzMCs16q5CQOYCNDEsDmamND8PoCuOILRmB+TDSj4cl/YU93z0gjmcs+REkZqfuc0+f6ndP9IX9wBl3u6EHWw1Vz8UVx/xd77Kl5+0nhYNl6lf+wN25ObRU38tZarjgxjobOfdib8J1BxZmXhImLq5ohyHyfYKDDsdvWzHtzfBt9EtfUAU1IXRQM4ZNvymTfIHP6LnDam6vm+K+FfN68vVrIr6PEPxPdze3I3n1WyO/b2z8WZ578mf0BTim8ewCnm7nZ4p3n9sG0vTr5YW/Bmhsr5N9YE1lz6UlxcdPcnzVzfxR2ds2364X9JbZC1B57YeU2/8zetO6tmwf3Dn/cJ9otPTGnJ12aCXoKnGNvrtlbN625d+beFDnhcdZ6fQcsse5OFHcPQOkPe5NMr5KTDu89scbfFhd+Ks7nQZh1d92cemxuTlrj04djOWtum8lkdji7S9vmctbeuFnYuQNnoUB6UNUNVAtf0uCfD3uL9p11JtfMjRV3N8ytPXvsFWOzxufst1vm+5/Mqfvm5BwoZM28sw/mCztr5tpP4AFwlGvO0DkEVNbiK3CDld2wf9wHW8Eu2EIoyoM6j8A+a2qamLiUNSdyh8uPQGJd5BwqLr4CbQ+zWXNsF+SZdx8cru6au1PW/S3z1rh5cwFsN3Or5uZCYT9n/pxjsoCZKWttTVnPV4n7f3tqZWdJiHYPWMrQD4TB/v2mefuhvb+POrDR3RRvjSPryaq5fI8I2Vwhns/NghDUFO9Bxd3fUR1fh4obv0IozZ9vmS/uo+j5CGr/krkWwTY6XMqCVPC7E8h7kB45piJTF0QXdmbAY5Anxd0txHc0d7sOoZ+ei3EkqoqCRQNZL3/ww0nWwx3zbp7FA7INgg/RtnanUWvcDwYWdnLm1C/m5C2w7iwxZVjVrrUqBtb6BREja2WhsPPenJpD7Y1NcLx7FGH7OVd4v2y/nkMtkpLkgLVLzRgYEuESNsjPxqSQBjnlhdZ4YzKpYV13ba6HIM6OWytLYATzsQXeKbvtcD4HsSXOi9bWk2hQv1qz21ASkICo6XJjx6Xmts5LThH4As2apmqNoiGpSlzD/VjDClgRQ8GEJGPFkEeaVMWQlAwO+kADrvRBLCs9Kz6pH4UC8URC1KQ0mKYaYXQDBfoEncir2ECjCMuwXN4ONjV840EPD3gE0agvkOmnToyhf6iSwsUFY9DhDGZ0rPHGdSPoC6SPJUoLuu4QSYzqKCIGaVIaqGR14BiqaxinBVkawjzQkEM1tQ8TyuCgYaQbamudbOI1NcWnpIzEi2qqdgArWBMM3AulRpgoABCmYdzHDyoZHiczvKiQLaIG3boQiZLfVCv47XfkM+bvGhhlLWYEtX6frz+j0DiiK5pkYK5NHQhd1Q1NUga+DaT0AYiGjxgVMHQQRzIMPI0R16JqKYDx4Ah8uPZ2LplEly83pFINuh6kDJCDHMkCSAfk+IL4h/takDMY+Yk8It+PuGZFVJNwHurpbrngG/WoRI6LE1c1qUnsKHIGscxlUAI4BoBlP3pW2Llt7ewUdh4BCtsHK4BKBM6WnltLu+a7N9bSU4bOUOzQJgp7C/bBjLm4giKRCEW7SXPxofVijYDC1iyqR3AAPa1f1SA9JTA9+jmCv5yMUT35dvas6xnqHREo/obEjCbz+Dq45xzidMSl0HlIdSe2nCGlMJQuSOdU1NHThrhhFPzkBolQL3gAjwaRkxh1fw8oGVku"
set "B64=%B64%iSc14galoaFV74DNTu3KIAQskQb8CAXEMC0bokYQbCLpX6GbPyD6+W5NSoXCFVJhk8P/QkGSYaCWhtyF+khdkIjUsJHRFLI8WslIfAG2EJqEIWgGl5AhyRGXwGBvUkdRh4H964ihupEQV4ACtJTi/ibpow/Wq6GBU6DwQyQRmtRUSlCSHid7UAhVA0/YDU8prVGwuaurs4uZYE28J9gK44crDtIFGgO6AiCrDoP6ERS9EKk/C7CawNoQ4GtdJPrZWUgWlt74umSgKDGlrGU31g0n1TP9NCCUKgI+OJIoXUUEiAW4BNFy7GXFQ2CM6xKGw278AgSYPqJKV1GdnjPksDAN+sl05LgqRWFIoXOS/eYW+CWCvvoSZoinMAQWZ+fJjDB9F9XDMoxgVA+v0QACcCgJZIga0GrgFFvl27AyACTcgAFCz12IREpBrLCUwki3IMn0jP9AfKo3P0KUinQrPn9e2MlaL9ZJO5x6yoCETC+0NZrbL71TDaRFMb9srm2YawvQEdlcab+GL/PW8irYau/nodOzvgbZ4UnfAClqBzRLKMb6Hd0pFV6lb6sISMW4bjiy0D5l+HzkYeUyP1IeZZQF6CoAG8GK+q6O2I0SYeiYYEQhrN9D4wNJ1VhBOUn6Q8sQB1EQ5qmLnVc6qOGe+nSWCRvFwRhF5/HD396De2svdiTIPHSYXSDj7NJze3/TfvuHfTDGZmpSmZ5zmT89CHSa34/Kkt1JliXF1U2YiarmRjLlQxLQ6dHeeGytTLPpDyY+L4gF0lKaudfQRtxmKsDK1cSIDrnPw8TGX1R0KD5w7GXo0s70hvUQ69phyPErgzBjcZ1935ORE2LRyztULUJKkkeYTXSedGZL8AUtDZl0HoePa5E0naBWyR8CDSzTMCDwpcmxW01QRCB+QSIN2g0PiFEOVsOePJEcPHPkVeaJVIVPDiYSWtpCPLRlce60wM4rVXVjoqm1FR1Z1hNOWVdM8+PlIX6ydD+lQz5M1/PWizwQWpuvK6v3TMWUT3Di/pa9+V826h9mJwAbyP9Tj50rzrs3xfw8rMDMz+5g7ABratWaAHS5WboB+AKpETclYLzAAjg3FEhCYKB2vqAeqYH8rKvnPyX/BUsgWHZ/UqdTsuj0OifDy/lFc0xXxWtwSgceduPvSbgEbGJDd/6GSlzkc/UIuopsI33Ck2o1p3Kzv90jaQysF8m4fjoPgJihiqrscPUk0+FK2/gmFhvquxp0IeLZdzzM6NpUUZCblWQcwMlwLeHdFA99JFZWdeyslpIflYPmxROySCLRB2G8xkCkHCVn03cEyv5VCHs0una2xqug1U/WHCv7MMm6GMNC695D649Zim8LzrRMkxpArApl/c6RDrDS6ivOvGRXXKiPHAxvTimwayzkuSBWI1854RWS7t7Aly7F/fRqAUMdX31PZhjZKMvVG3oo7O1p1C0K35km1ycQJMjQOY0MTOQKXMZ60sEjqsfDVy2dpCBD2DZVTfcJ4rXjBAQGBTKZBfoFuKiWVstGZ4jRcMIlckuHDAcFDYloz/cokih4sN9rTkm1TCl7T0V/is4ehnK6U+pS5roaG1oGf17KY/fUKtcALeVhgQ0xQ+KDIzroLjsngS3ls8j3NnUYa6FwpfCKvuILAKMqD+FGbQDkfuFMr25vqN4NcpyzEqyBi80N2iRHG+ALudXCF+DzkwZTvki2KkPqNVoKkuK53rpOdm4nR13g6iKIu4TcC/UXHlW+K/mG45KCIXDAixVaVUEx5j5DnEQlxGSi0MlE4FmZpFwsqUUjkfqTiam8"
set "B64=%B64%3hQ2BtVkLHoirZ+M/72CKKoZxYjVRGrofcB/Ogu5DkCOJWP0YnAyw7AsKL2US0rHaM79v/SQYsBwInWQUgsikX2yW1xCRUjhU0i/17/Gmg45EzvHR0524FAswK4wXVBraiocPllb0GEg9u9BTjwl4FDFKQkgq9cA2CFBdF8DSKEI/Qa9IVL0pnWTRgxjAwRkyfcIvUYm213wJdUaFwYw++VjLxqCAbCbNpx3DfeX+7rh/C6/cQRS5EwQ5BkdXR5AkzovWkFbWHoA4zLpAch+9My68ysMyfSJZYXcqca32Zx8uPq6sHMHZiK4PiFdj6JCfq04MWlm9ypAx+mlzIZqVAwMGin5mKeXaF3V61et/6OHFSqDtFScpIBGxbEe6/9O8YcrCVPEC1c1PICvQydqJ/AVcrhhYgMTYv7Q1Qj3mcD1N3It3944XzMa9gfDH+N4KsUnMiK0rRKcOgEiO5c0NZPWr0a/5enwW0bQ43G57J1ypKhE7xPM6Q8CqXBJArkmlj7utEFTLFZKD7ZWzrVAiq3QpIxVYK67d+QFtt65EzmpfcwNlm1X3N28DaUyJ098mfqUDWoBfZA8mpKwU42d0QoFne5Dt71vEtHzEeofl8+hSGT6mFdDkRpK4t7hP9a46kHK39Xc2NN9GXV+harGMsoacySA12PU9S6GIgqOruOJ8jGmi9/nPpEfc1JLY2vbX3WS73+M0xW4DBwAAA=="

:MENU
cls
echo ============================================================
echo    湖南大学 校园网自动保活   v1.0.1
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
