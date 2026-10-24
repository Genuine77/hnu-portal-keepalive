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
set "B64=H4sIAAAAAAAEAK1Y7VMT5xb/nr/imTS9SUZ2ScB2LJ3cKUVQbnnJEKhzx3bokjxAdLObu7sBuV5mYlsLKBHaCgqCStXqtQo41YoE5I9pdhM++S/cc55nd7OJvNwPjc6Q7HPOec7r75yz74p7H5CzPQPEur9m3nle3v2xMvXUvPaktLdqvSy+25k25zbKj4vWw0J5ZpqMnXy3M+P7gJRvvkAmIa5qhiSLQ5JB9qeuWTffmtOb5MO4po5oUua0ZEgfflUl+4qY8zeAs7K+Zk7/VCoWzWtrpeIjkvhnor+9m1S2fysVdyub35VvPvkz/y3cUnpzD243Cwvl688qe/OVtdl3O8vW4lSp+Ic1kzdXnpTvrJu7C2bh99LWtvn6UWl3hT9BtaeeW4X1P/NXrFuPzL1b+9/tonYrT8z5WYdmht0C91TWH1Y2rliLb8ydObzhQd56dR0ssW7MlLf3QOl3O7NcL9dJ+7eeWNOvy8vfl5eKIMy68cice2Cuz1rT8/tTBWtxk8vkdtinK5vmar7y+Epp6zrcRQLZUVU3SCN8yYJ/3u3cqVx/xOWahany9mNzY6cy9ZKzWdOLldcb5tvvzbnb5uwiKGTdfFPZWyptPTQffg8eAEc55oydJEBl3XkJbrDyjyvf7YKtYBccERIVQZ1fwD5rbh5NXMmbM4X91V9AYlPkJCnfeQna7ufz5tQ2yDNv3Ntf2za356zbG+bVafPKMthuFtbM9eXSbsH8ocBlATNX1tqYs56toft/fmrlFzBE23s8ZdgHwlD59Yp57X5ld5f0UKO/Ld4ZJ9aTNXP1FgpZv4ueLyyAENIWHyDl7V9Jk9hEyo9/glCaP1w1n98m0Y8jpPtz7loCx2R/JQ9Swe92IG9BehS4ilxdEF3augkegzwpb28Qsae933EI+wycjpOkqig0aRDrxbd+uMm6v2XeKPJ4QLZB8CHa1vY86Yz7wcDSVsGc+9GcvQrWnUBTxlXtYqdiUG1YSlJi3V0ubb015xZJd2sbXO9chWw/FEpvVyuvFklHWkkJwNqn5gwKiXCGGvizNSVlQU71QWe8NZXSqK47NjdDEBemrbsrYAT3sQXeqbptf6kAsUXnRRubMRrMr9bCJpQEJCBpO9vac6a9q/eMXQS+QLumqVpr0kirSlyjw1SjClgRI8FEWqaKIU+0qYqRVnI06AMNBPdDeFZ6nvjSwyQUiCcSSS2dBdNUI0wuk8CQpKO8mgMySagMj6vHwbaWrzzo4QGPIJn0BXLDzIkx8g81rQhxyRi1OYM5nWqicckI+gLZQ4mykq7bRGlOdRARh7R0FqhkdeQQqouUZiU5PUZFoMFLNXWIImVw1DCyLY2NdjaJmpoRM+lcWkyqmcYRqlBNMugglBoyMQBApnE6JI4qOZGmcmJSwSNUgx2dikTxN9MKfvtt+Zz5mxZO2Ug5QaPf5xvOKSyO5JyWNqjQpY6EzuuGllZGvg5k9BGIhg+NChg6iMMMA09TInSoWgZgPDgBH6G7W0ilyNmzLZlMi64HGQPkoIBZAOlAbF+gf4QvJTlHiR/loXw/EdqVpJqC+8hAf8cp36RHJbwujq5qU1PUUSQJevyNJHOaLNJLoMlJIuhEyJBTRFBJz0AXEcZJ8MPLaPggCKaTQWL7u+nvASUny0wMpp1jZ0tLp94DB73auVHwQSILJRkKJMMsE/G6YCQSwYxCRo0aOU0BA5J+sV9LZ0JhVLkmyQEiy7vr2BfuPapPdUGBRA6hYW1qJiMpKY8lnqoi9YUUdgLhhokE2/v6evs4UFgzbxEroJ06"
set "B64=%B64%4qCOAejIOQANdVwn0QiJnoo0nwCYSFBtDPCiKRL95ARUNA8XvZQ2SBRNqWrZT3XDDl1umHmDUUXAEwcSZeuIoAKhzsB/tr08GbAshT5pPOy4L4CF9h5Vto7q+IDhZWFIAo0cTYfX1SkKTZf1/cofV8EvEfLF59ATn8JQU15Ywp43f4M0w2MYKZgeXqMhqeFSDGSIGdBp0Ax/KnZRZQRIhBEDhJ48FYm4QayxlJVFv5SW2R3/gfjUH75XITXpVn72rLSVt54/Qnife8p7LHZjBvXm5gtvl4a0KBdXzYePzYfLgPB8Tqq8gi9L1uoa2FrZLULn4jgN2eFJ3wBWkw0CblVy/GYnAv0XCSJU1fq2jgBLyXFDwpA0Q0jIgI5ESFAAwZROPrLL/KDLnMo9RB5jlCVASajZoPsIOeojdtklDB0SjCiE9QIAOUiyS9+9nXFi+gMEJkdJEOaD073nepjhnvq0HyMbA6AY6Ipl+fNbcG/j6Z4E9vf9/DKOZyvPKrvrlde/V/am+IyIlem5l/uT/Zw8yA3v+f2gLNme5VlSXluHHl83B+HUCknApqHK4wfW3Xk+zcAE4wWxQDad5e41tAkHkyV4cj4xoUPuizCBiKcVHYoPHHsWuo49jVA9xLtQGHL83CjMDELv0AUcoSAWg6JN1SFl0vIEt4nNR/asBL5gpSEDg8MndKQ1HVHL9YfEAss1DEiiOwn1qwmGCOgXkmRBu+wBMcbBa9iTJ2kbz2x5tXmSrsMnGxORFnm8NVwV53Q/fp9b1a2Jts5OcmBZz9hlXTOdTleH0ll332JDK0yLS9bzIhBa669qq/eDmqkVceL2RmX9v3x03c/PADbg/7kH9sj+5o9ycQmewAzLdwp+gTW3Zs0AulxxJ1pfIDPhpMSwqlEJnBsKpCAwUDufMY80QH42NYsf4b+gC4JV96d0NvUl7V5nZ3g1v1iO6WryItzSQ8ed+HsSLgGH1NDtvyGXCz/nD6CryTbsE55UaziWm//tn8hSYD2N4+fxPABihppUZZtrIJUN19omtvHYMN81kFMRz7ntYU7XpSYluV1JxQGcDMcS0Unx0HtiZVWn9lM3+Uk1aF48wYcYiSEI40UOItUo2Ye+A1D2r0LYg9G1tzNeB61+fGZbOUQx62IcC61b963fFxi+LQOmWit2UgOI1aGs377SBlZWfeWbL/jKBvVRgOHNLgW+lkGeS8l65KsmvILp7g28u+QNs1EZhjqxfu/jGNkqy/UHeijs7WnMLYrYm8V1AARJMnROIwdjrwLLxUA2eED1ePjqpWMKcoTtUtXskJS8eJiAwKiEk1lgWILFy31aNTqHRsMNZ3DrhAwHBY00ai8OKOmk5MF+rzmuajk3e49Ff4bOHoZqujNqN3MdjQ0tRz9189i5tc41QMt4eGBD3JD46IQOusv2TWBL9S783qWOUy0UrhVe01d8AWBU5THaqo2A3M/s6dXpDfWnQUGwnwQbYK+4zJrkZAt8wS0NvgCfHxtMdTHqVMbUi6wU0opnXXOcbO8oB21JTREinCHOgviZR5VvXN8IQgq2aQF4qcKqKpiMOWv1UVRSTEaFjiYCz8qYcrGUFo1Emo8mZvIGM9QYVVOx6JG0fhz/B6VkUs0pRqwh0sD2Af/xLLgOQI6lYmwxOJphXJaUQcaVzsZYzv2/9JBiwHAkdZBRS0mUfbRbHEJFytBjSC/oX1JNh5yJnRQjRztwLBbgK0wf1JqaCYeP1hZ0GIn9e1RIHhNwqOJMGiBr0ADYwSA6azgWijRssA2RoTermyzhGBtAkMXv"
set "B64=%B64%EbZGprod8MVqjUsjlP/CkQMHPwNgN4vNJvopcX8JMiXN1d8nTrjtK4N3giDP6OjwAJo0edEK2sLKPRiXsQeQyi+/Wdd/giEZR687d3Gnmt7kc/L+2qvS1nWYiWB9IroeJaXiw/LMrJnfqQEdu5dyG+pRMTBqZORD3m9Em+re5jT6a95ouDKwpdIUAzQmjvdY/zeKP1xLmEEvnNfoCL0Enagb4Stkc8PEBibE/KHzEeETSRhuFTq+vvxxw2TYHwy/j+OZjJjIJaFtuXBqBwhPzmhqLqufj34tsuG3iqCH43LVO9VIMYkO2DqURy/6mbArAddE9+NMGyzFYm568GfVXAtk+BOWlLEazHXODlxgm+2dyE7tQzZYflyzu3kbSm1OygZpZmvFgQszH9QC+ii+BMSwM43t0YoE7e7Djr3vJKIfR5h/HD6bIpEb4l4NRRoYibPDv69x3Qspf19760D/WdL7BakbyxhrzJYAXo8x1zsYShg4Oo5H5WNcF7/PeeV7yE0drZ1df9VNvv8BXuotYNwaAAA="

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
