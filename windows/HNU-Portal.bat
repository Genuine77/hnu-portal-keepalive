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
set "B64=H4sIAAAAAAAEAL06+1MTWbq/81ecipmb5GpCAupVt3JrGERlV5EiONYtx+s0SQMZk3Rup6OyLlVhFAiSAKM85C2Kg+vIwx1UTID8L7vpR37yX7jfd053pxMCuFV3b8Ya0qe/853v/Tr5ki+cIFfabhDlxYo8v67u/aINv5WfvCkWFpXt/JfdtDy+qa7lldWsOpIm905/2R2pO0HUyfe4yd0uiBIX8XRxEikNP1Em9+X0FvmmXRR6RC56kZO4b34og/1A5Ikx2KltrMjpp8V8Xn6yUsy/JoH/CnS2XCNa7rdifk/beqROvvlH6mc4pfh5GU6Xs1Pq6DutMKGtZL7szinTw8X8R2UkJS+8Uec35L0pOft7cScnf3pd3FtgK0j28LqS3fhHakCZeS0XZkqP9pC6hTfyRMaAGaGnwDnaxqq2OaBMf5Z3x/GEVynlwyhwooyNqLkCEP1lN8PoMoVUmnmjpD+pc4/V2TwgU8Zey+Ov5I2Mkp4oDWeV6S2Gk/Ghv13YkhdT2tpAcWcUziL2eK+QkEg9fImDfL7szmujrxleOTus5tbkzV1teJttU9LT2qdNef+xPP5czkwDQcrkZ60wW9xZlVcfgwRAUAY7904TgFLmt0EMSmpNe7QHvAJf8IoQnwfIeQn8KeMTyOJCSh7JlhZfAsYG72mizm8DtaVUSh7OAT55bLm0kpNz48rzTXkwLQ/MAe9ydkXemCvuZeWhLMMFmxmxyua48m4Fxf/srZKaQhXlCsxk6AfUoP06ID95oe3tkTZe6mxub20nypsVeXEGkWwsoeSzU4CENLffIGruV9LgaSDq2lNQpTw0KK8/J76zXnLtOyZaAq9JaSEFWEHuuiJnwDyyjERGLqAu7kyCxMBO1Nwm8bS1dBoCoZ8bF9tJUIjF+KBElPc/2+Ak5cWOPJZn+gBrA+WDtpXcBGlttwGDxZ2sPP6LnBkE7k4iK/cF8W5rTOLFbi7IE2VprrizL49Pk2tNzXC8cRRuG8oW9xe1D9PkUjgWcsPWDiEp8WAIl3kJH5tCXBzwlBda25tCIZFPJAyeG0GJU2llaQGYYDJWQDplsZVms6BbFJ6vvhG1QeWqTG2BS4ABkuYrTW2XW65ev2xxgntnylYDxlRafAG2U9NwRgvIBTg6GgwIW+dpJyXvj8p7z8ALlWn0ESRuMI2C230GegPxMWmCBImcXgUgXbpgWxO/wpna/r5FVGxB3nqvDq7JOzvM0YDaYmFDXs3aLrYFiPbyNyWzUg9/5CfwjWp+alvb29A+/a4VhsFktMIy/AMKlYGXuMtiNdraK2UJfaCSsMJgaSUPm8HVS28z6EJjT0uzq/L8kjoGLjZQerYPnqgsvAPHhEc1/1h5ul7cGSO+8+c8vnMer8db7ztD1HXT6Iv5V+rEkLa3CXGLdHN3eTfa/MYHKtyMvDjOXByILILEhma1wjyTmEXdumWnJ+QnyxCQijsQPN/Ik6uloafkJpiRcD9BgA9tYBItPr0K1g+ktzUHWtkppYGCPEi94dPfSqk5IJzFX+XFeDGfVZ7vq6s5pjU8tM7eIoqC2BSUwkKsXeS7eZGPgVX7iSMQjvAxKdLXLMSkcCzJO+qARLf5ISxKWVbqwt3EaW8PBIJiOA6mLkgu8pDYu7gE4qt4QfoJH4Hl8mtH84UfLNnEkkwcpL/OnuymAvaTPwrhmLudk3r1nY5kghc90gPJUWePHwoU5xIJHSjMoGoBsRQXjgNUROg5BOouz8e5SPge7wEYPFQUuniEdPRKUvxCfb0eXTyiEPVEw8mwJyhE63v4"
set "B64=%B64%GC9yEn8HPAk30YSAm+7zXZ7eWNLDh5KeYAxfIRn01TmvD58pVfBs0/GzzT9eYJD1PAOot9XVdSdjVI/kphiWePdVocd5KyGJ4VjPbXs00QPaqEOm7FIC0GHEAUnzxH1JEKOQ1h198HFfu+YOhciVKxei0QuJhINugJjkRisAcyC6LFA+7u+5SJInNsSH+G3E3RILCiE4j9zovHSurt9CEh7XjqJqFkK8TsgJwiIZizYYBSBpvPytuPNE2dkp7ryErKwVliBLoW8uvFMWcvLnj8rCW5atMR59XgZH0gqT4LPE6/Xqfjb/QllfxSSxOUUaCRxAT+sWRDDPMLDu+wOBv+4ITxrx28mThmSodIIA8W8kmBQjHv4BiOc0mHhMADU/6COOf3cQd4K4o+QsrOqadkvhKA+BHc5yC6TtxlXivk8c3zxEfd0BefD9DqKbScN/2mPJSMQ8DD3GUNGFC62JNnh5XbzZC+oLxCG7OO1BF3UiJMoBHKIzVFBqswdtnk4xHHW6KrDCSzf/P8SB9gZkicRYaPQ2OBClyEtJMYbL/ZUbUTLAC8IEJE6U3IEImDxxB3jgN5QgPn0D+7+OhtJWofBOPiHpHtzaXrbDcNxV1v74W1owzYDqi4UVMzqzKIlFyW5KXUyR79vbIEWy4ApA5cg68xHUjekBrEB58kRehoiZZdEeAqh+SmW0Ln4eVd/nAQuUverULARndhoWfoVZdS1rhOiUMvOrNUQDAEtM2uYnKBwg6hdzY1AYAEAp/4uyvYTh9Ot0CjKwaqCbw1DIxGkXMFSG455APBKWnA6Pw2UitQueZiGJPhjjyenDMICZ81ywF8AfkDC8E6zGTdE8AASCBC4PUI7//iH00Heqsd/uOAyhyVM4Jt3GzT0SaThz5jBwnQ8O+GA7hFve2+BmXZYF3+0yUxw1Sy+zUXjoAS9pOJQ7yxZfw398DdTZ88TNxUJIAD43nPkq3OfPlXcBRT7LI4QN3/nDcBhrkpjkD3OHDtQP1xXha3sFVgesagTLRqujhToUV0dXU3Psi7a5rTwf00uX9VdQTmFEBEd7vqkVnit/W2H1hckwmgJxVjgrOdJA/yXh8UfT0txuKH+FyD3MKw9ppuu/AF8wycGXcNxGjIxojaVfG0ePUJnTEkmph9GQ5qpQYgek/rCIhTpERukQ/VmKNBtTkbIwQmjDEOMlW3XJxopBbMU/vYe6VVl+jbrceATVPlMVRCxo3KA6hggHVZuaX9APUl4MaxtbEOhsrC1i4cmMojbshWDvxBiqf2GE2QTrWSHFYgYdwaNx5cMoltu5MaAXK9PhnDq2xUpINT8OVWQxNwSFpGGgRj0pZ7chTqJ9WqpKeX4fCMMO6tGgPPQB8EJcLQ1nwIAxqL5bYY0anCpPbGLQpvJgBa4RQiWxzxK0amahhnIahGqMw4rGWd1EEXf5K6iIuPWHS1w0HOkDd4L+2W2pf+EkIU7+YmIufwJ8BC35etdP2De6L4VFKN98Lo/ZBjYhDf9EWqc0W03SmtbBb/QCDbhpZl5Ey3OhG2py4KriVEMAlZxUFe81uKrNU1URgaSwyIdfPSgyg6B7YamPlRSGbTtq8mMWo8QGzXigs6mzBVYRk9/urI3WBe6h/p5X88tQ7YEXgEGCKbKWB1zm79AKMfvRZxQQC6e3mCHZzHM7IKah4Vj6bHcbF+VNecGJ3WExekGPBgcs4WgD9HktGmvQ9WVWuJXabPh/UOdx+qytBq4bzvYjA1aFNBzUCJNrPwnSsuHhMWh1jay+17YxnAHaO56WB0E+jtx4roEP"
set "B64=%B64%cj28gRNDbEVnCeFO3dvA4dzy6+r+kuUrFGazEI2iZZZT0VEScxkBukywo6Wj43oHY0MZ2ddHHQY6MEEIq2Y093mhCPA2noRCNMCL98CYGry+8yfBGlmPxD8Io7SBleqsSvulZDd1dgrlBZZrAsWrgKDthebWiGxGB4a9sLuDu+8yyn47drcHoOJVUMfHJDzMReuwo+HwuCpCIRnR4av2cRDk4iV/+g6Le73EXkhBDiKNsKytZCgdVqahk3SxEOOkDLRKfJSteq7ysR4AoQWn9/Q5r9dUYgWntBft5MIResZfQD/VLw+0pRXmpr57h5lpnSZebElesnzI5m04lrKMSjEy5Rfl1TV5dU6Z2mLDau0DfJlVFleAV20Puws2HAHrsJivHYudA4FCj7PwxuzXKmVbBUCrErPYoG2lH9YIZPjizio2MBsZefANWvNExkzDONtjO+h8T11Yxlf68G7efNXgIbSdwpHnJmRs2ni/LQ9b6VCcgkBhyWZyOHhPT9MeDbK5PmpjM7r0hNGq6dNHdgzIm+CgN8smcGp+Tc2vs+IFa1UoadOzWIU8Gldm1tSRdOnnV8qLTziufw4FyhgrZnE2QMnCLdntqmEgK0vMYaBxtj0IlTcfwl7aYdaNFlsMgwfSbtsAq3SpcJVPWfqGA2W0WeQb2Fyu40qaM9akUcNSqjLzoRZzCBydHlBH+yeJpRRFOMgmptysR1T78kMT2HmIm/rA4X8SoDl1WMcZJsl0t6VFhbxy8frNNsqkJXrry7it7AXFnUlW/TITpp1RmlW+6sqGvLEE61DPskGRsvDONJpqSpg0zSW9t9WnlrWyX3vH9e9a9GULPXtD+kzDIEaXsD6qojVLcSdnmrOWypQWlwzPzFid47B0ifErl2HxizFZdU3CZhvssoQ5aHkKbolPJ/RBuZp/piwtHBiPz4GL1x8cwlhHL+r6JDq9PnF5QHCi8j5vDljwOpGGUmW0oCy+ZlzBOerjj0apkAH+QYcMKb31emuOzSsH5gPaxl/xfu3dCl4e0u3o5vY4FPrUTnVBA4n08UhXp0DHOnu5LWHjjUBfApKVB6o6z8VYArIlILgCHaveZvAJJ5vVuiAp3ezlRd4ozuDcO57KZqRcSOs3TGCQNJcdWtQZ4wqaOqsaeM5jdj6dQoAmczZHZNKp9V43cTRwhrnS3egtjP4x71MIFHa1jtJvzRbesMGelnkk421TBop4ubCnToGiR2xoyUY5aSmIKIk1mTJUVcGJqT+GApfp5NKiyrLGjZE1O8OsCpoCza2tpGZZMKKXBRVXjOnyzWLGvDSnN49ZsFFlPQ+A7NanwrusV4/6RGbjr+z+sZQawR4H/o2/0nuazx/V/CysKLkJ04EwoY2vKCOjNMXp15J19mifYfPl4V8I7AQi7LdUIqcgSzQ0es7gfw4ztpdFHkrQq5qg0V301+jC7QkheBdOaePvG+Zosf8AvOSlhP7XWRFKb9WAqzB+rDMtln/q2N3sb2dfnIetF/HO6Pg9kEclIShE9F03QnFXJW8evd+hsjtFznkt73UJM7irQpCLtMRC7ZDCJIMTj2H8zgNoI0KC11dNgydlpVmnj7iImugCNd5lob6sJf0lC0CV+fj/Kg/Xzr/XW9urkq8N13Quu3i0Oj+rNJSZF8rvUzQLzelXNtSoCdaAFQnXZgQclmip96mT79m9O/gHTsJ0V2B362DnXJCxXLbMssHH0Nytijdv6rvp/RY2ntWX9yxkN0Ui1S8SzooKiIol5rkexzs8QMRFcP6XTLA54Y24o4b3WPZVY0cT"
set "B64=%B64%ZAH/qiDEu7jg3cMQ2HvpZItNKMzVMtNJOuKPeS7j1AssHAiUwki950YsHOQsqai6oKOkJU3rPTYZsSFQsoa5U2jTcg2KcQD+B9OOjVOrRAOwdA9TrJMx0t7blwDaI/pJwEv5LPx+VbjPi05XJfKKXFJn12fITWIP4P1W736N3FD91mHOnB2nak6dYZ8N8395ENwauyfcpa4QjlnuWA0h6zOw48fkDV7ivmxOtL+1EGadiIc4iXMDJj5GfcwR9Bs340dBcf4Iknc0EMg5ggboD4k+r7fxaGCK706Ul3qFkN93JKwNhwl3uGAQL6z8p7yn6HTBdvwWHC6AxYX8dMxw9Ib7ES52h+4Kx/3UAr8WHgwONhwJ7aDQXBBxHy0WAzDGRfljQH9KfM+LCbAg/2mP92gB3vPb2UCkAzxPiLpcR1MLNPT4/9zrDh6jcPDpaBgC2B0JghAq0bhGQbeh00BaVWG/iX4SJ3oxjSEXv3vpUCp0zQjF6LvtXA/PnurYJTsnQRCOS/pVu/FkXLjrz+Vrd3sUzwRElrrW2INXdtbYdQJnF9DiYEagvwoafcqugeX5JZzQpLdYb1Na+QDdAVRI2KskEj5SzK+qIxk5tVsRgvTMyng40PT2StHIV113+Rqqfp5Rbztw108xYrplkwWGnOVf248xm6sSMIoyuSXyPfwDyFLXMLQ59d1QzQFDfpvzltd9nnN3N7kv3X549lS/y+ZwHYzx0agnkAxCSjNDra4ufHNZFJLxxC3fbQ8tjMvR9fCYXZZVWW8Uo/X69/hhY9RlYsDJhPkxKhFqcH7TWNha2fLsUbZCTdRfEY+NdzVnLI16+6Yb+sEBC7M++rpiumJNNpUWeuSPJc6wIs6e6MVf9aDaKcV62UUcemair63zTt9ZL5WPsU+HCCS7mFSd3lMUxJgPHqS4atht62hputF5hVz/E6kq2fQrAIYBpO6nojciKqGh0hA8S1R+2j8hI35Gl02f7LFxA7s1ZL9gw6Zlb4jd5bAf+Jg/QrNBrWhei5J6/bedyrNscW/BxkYWpeGM9fdv7P6QzUzoiVX3sawKqauY0hyUwKWm1qv/Agn01/0viaAh0WEtAAA="

:MENU
cls
echo ============================================================
echo    湖南大学 校园网自动保活   v1.0.2
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
