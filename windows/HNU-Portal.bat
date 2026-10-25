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
set "B64=H4sIAAAAAAAEAL1ae1dT17b/n0+xRkxvwikJSVCvckbOKUVUbhUZgO24Qz02JhtITbJzk42Pq4wRqkCABKgCKi9FoVgrD1sVJEC+y2323slffoU751prv5IAHeOee2Kryd7rMZ+/+Vjrcy5/jJxvu0yUF0vy3Jq691Nx+I08+rqQX1De5z7vpuWJDXU1pyxn1ZE0uXXy8+5IzTGiTr3DSa52MSEFIu4bAYmUhkeVqX05vUm+aE+IPYlA9ExACnxx1Rh2lciT4zCzuL4kpx8Vcjl5dKmQWyGd/9nZ1XKRFHd+LeT2ipsP1KnXf6R+hF0Kn57D7nJ2Wh17W8xPFpcyn3dnlZnhQu6jMpKS51+rc+vy3rSc/b2wvSNvrRT25tkTJHt4Tcmu/5EaUJ6syPknpQd7SN38a3kyo40ZobvAPsX15eLGgDLzSd6dwB1epZQPY8CJMj6i7uSB6M+7GUaXLqTSk9dKekudfag+y8FiyviKPPFKXs8o6cnScFaZ2WRrMj742/lNeSFVXB0obI/BXsQe7xWTEqmHL3GQz+fdueLYCltXzg6rO6vyxm5x+D2bpqRnilsb8v5DeeKpnJkBgpSpT8X8s8L2srz8ECQAgtLYuXWcwChl7j2IQUmtFh/sAa/AF7wixOsGcl4Cf8rEJLI4n5JHsqWFl7Ciz3OcqHPvgdpSKiUP78B68vjz0tKOvDOhPN2QB9PywCzwLmeX5PXZwl5WHsqytWAyI1bZmFDeLqH4H79RUtOoop08Mxn6ATUUfx6QR18U9/ZImyB1Nbe3thPl9ZK88AQXWV9EyWenYRHS3H6ZqDs/E5/bR9TVR6BKeWhQXntKvCc95OLXTLQEXpPSfApWBblzRT4B88gyEhm5sHRhewokBnai7mwQd1tLlyYQ+rl8pp0ExVhMCEpEefejDXZSXmzL4zmmD7A2UD5oW9mZJK3tNmCwsJ2VJ36SM4PA3ZfIym0xcbM1JgmJ7kBQIMribGF7X56YIRebmmF7bSucNpQt7C8UP8yQs+FYyAVTO8Q+SQBDOCdI+LMpFIjDOsaD1vamUCghJJMazw2gxOm0sjgPTDAZKyAdQ2ylZ1nQLQrPW9+A2qByVaY3wSXAAEnz+aa2cy0XLp0zOcGtE4bVgDGVFl6A7VQ1nLE8cgGOjgYDwuY8bafk/TF57zF4oTKDPoLEDaZRcLuPQW8gPiZNkCCR08swiEsXbGvyZ9izuL9vEhV7IG++UwdX5e1t5mhAbSG/Li9nbWfaOknx5a9KZqke/pFH4RvV/PT74t56cev3Yn4YTKaYfw7/AYXKwEucZbKa4uorZRF9wEpYfrC0lIPJ4OqlNxl0ofFHpWfL8tyiOg4uNlB6vA+eqMy/BceEn2ruofJorbA9TrynT7m9p9wet6fee4Koa7rRF3Kv1Mmh4t4G4BbpDtwUXGjz6x+ocDPywgRzcSCyABIbelbMzzGJmdTNLTs9KY8+B0AqbAN4vpanlktDj8h3YEbi7SQBPooDU2jx6WWwfiC9rbmzle1SGsjLg9Qbtn4rpWaBcIa/youJQi6rPN1Xl3eY1nR7OGlCEap4pmc1NwHSISB+k3HIuyl1IUW+bW8DqzXzCxqhfv2gkHsL3Cmjo7BW6VFafg5sZJkKgKsy4QGwqe9ymqw0myhubIFvlmYnAO5A5aXZ1dLAY0ArdX0JiFZzj8EhwJb+SGWQDoA9IJj+PSovz1DOgP5H8uBgYWcIBhlYngJfzVKpZDWG9JfKk19ALjADIZeSDuaovNgCe0D7x8jwcBatYfMdqJEBJ4WbFDgj"
set "B64=%B64%BDCuVUCSirBAiDq+Ce7LlgV0AleR53ZAdfLgW9gazRHwuJhfRBF++oivH2flnanScAZ0TRJCVJSE6+E4KCqrPF9hfqQ7A25SY29JJMREU1AKi7H2hNAtJIQYwJOfODrDESEmRe42izEpHOsTHDVAkkv/EBZuTE9qwt3EaW/v7AwmwnHALFGqJfeI/UYgietZXpB+IkTgsfHa0dx41ZQWmLICB+mvsfd1U0/xk/8QwzFXe0Dq5TMdfUkh4ZbuSI4ae/zAQfFAMskHhdmoaoNYrhKOw6iI2HPAqJuCEA9EwrcEN4zBTRPiDeFCGAK1n3zldPRKUryxvt7na3CfwD/1jjqiPfR6T7t9/L96R22NPUkF0hgJJKV2XAblgEvSuI8/bgs33L2xPrcQ6nMHY/gKiaSvTnm8+JvSDL9tfA82+ftGNrJeYAPqbTU13X0xqmXyXSIsCa4LYo/zSlJKhGM91+zRZA/oqgZZtktJWA4DC+hBIK6zYiIK2ZvjLnxcFy+6QiFy/nxjNNqYTDroBAg9LrQRMBbCJYXSc30biPQJxIbr4fo24mqJBcUQ7Ecud509VdNvIgm3oxJoFkMCJwTSrvwU9yI/C2KAHQ0enx/SLuYmgDzo58MYy+VJgLVNhtMAPPXE4/H4mdtCbmQA1MRGIY9wwPfgaJPOKQ8nqrhXMZXB2ACOQ/EIIxb9gu77BF2JQho6m47bU58AohGS9A1gZxiBAAB4mZ4ErGDQBEgAaR/ihgYm6uhHDNTrGXnwNad3eEdZWNHo7RYT4GIJsS8WAiV5/0r4d1dEID7t15dfarrkU4RAsBemSSQcI4a9mgcxUlmCwAjG4Aq52MtfAR2V7e3C9kuUen4R4BTxfv6tMr8DkKPMv2FJMIZ5ALPdWa40kD4LLMr0ICR9kFIrL4YxA9uYtuxqF4GRfyPBvkTELdwBezsOiBITgco7d4njLw7iShJXlJyEpzz/cknhqAAJEWkgLpG0Xb5AvresSD+u28TxxT30ietgc0L//S/u6WjIfoTCCVjsOuzb7wCjJ76/2WN9kYhlKQQ0zUcaG1uTbTDgUuK7XvCfzjhkcU67WEsxDplwAMv37yNaWfiLUxix2UWbuysRjjpr3Z3xSFhyOu4DAlhGBulIe/yK55r1BYAEvKDoGnc3g4rB0Xok4qVbx694rxlw6qjYPxFKVJvs45N9h06uAlA2O1qSKyHEI5jHOv6BQk7+HaDHUedw1BLX35ATJmw/kg7QUy5TGOCKCVRijnIz1Mcg164AGncMAoazS0hKPCKAl+Hb2mpT8QOWTMMgOA7UqtaMKlPceK88HaeVUQoSdD1PkCe3ix82WRxnqYKOFlU3+afIBlzJyGG0XV/Kuw/Ad2xVtw3yaFzxsr/iyTGa/lI4gvSCIWZp6QPQqQPoAZIHk3EB6ANqOJx/D9c6IQRdxRh0FYLQfR5S7t+OBGIYfEERqERgS+pLxIgDELrcjhg1UBdgMk2RAHsIW++wPJ5/DsUH0xdIQ4+bBEHkOM2fvG76hz5p8HhBNH4CsIi519orSPwrttIogcDhsLw0qDK+MY45inK/6JQCCcnVGYFQT1ydAsg8lCRePon9re2BJmwJZRY7NSIsSEmPa/LEG1rxP2HmpZcXLM3HqroyW7aEGJozY33DMuayXJnvYs2YC5/GIGOGVQr5BXX6GfgC2w09ApLp1axWY2BcM9cYaJi0smLZNZQthZ1xdJz8XCn3k/J+UYtNR4Mlc1lNdPbuAMIOEydFUBiggaObgyPVjqjhFmDG8YNWMOLcHRrnRDM60GXu"
set "B64=%B64%UCThdv2Pq6F73rqGfrvjoAV1nsIx6RpORtQ8ceKg4ZyPAPDBZoiA4xCSb5geeK8ZTAWIS/gv4oEYlsBZrh6I4L4DuTNN8fr+/c+MOnmaoScQgL99J/7U2qdPGbOAIq/pJ6QY3tMHraE9kxIATQe4QwfqJ3AjIlT3CiyEWNuDlo4Z1mmCnOzwdsAs+8JgndfeFBawJgJHe7pRzD9VflsyAR4yXDWoHGagwf97nlKelDhMmYsLokZSjNzCjPkezeH7G+ELYi18gShKtFzfnKgc7XPBAzniz5w2e1BLTUxR2aLEDih5wgnsNAEySgfoz9RlsDEVKfMjhHa8YoJkK+85sLqXxQF5GctT1OX6A8j0maoAseSRLGTNgHCYGufmtYwawsf6JgCdjfX1GDzpKGrD6hrmTo6j+udHmE2w6hqSWcxVR3BrfPJhDPtFO+NALxbhEFTGN1kPRM1NYNmPjYABzUC1hoicfQ84ifZpaovIc/tAGLYAHwzKQx9gXcBVLMSnXrNan3UasViZ3EDQpvJgHRoNQqXEXRNoVY1CPv21HarQANZqzvIuIHEZX+2YRfEfZwPRcOQuuNMtMF5T3Q87iXFyv0q+0SlE0JIv3fgBG5+us+FEEvNOt97HbEIarHB5qDlSms0maWCtHf2Gl57ATTPzItqWELvDgD4u666aAKyclDUtqnBVnSdrqKCkMOTDr24UmUbQrbB0l4KlQ7NtR1V+9DKb2Npaujq7mrpa4Cmu5Lc7qy9bC+6h/p5Tc8+hrgIvwAJx6zfWswOX+Z+hR4TZD2+yAxbObDJDMrLFDsA0NBxTo9jVFogKurxgx+5wItrI0aDCEg43QK/HpDEf15deu1u16fsXqPMofVZXQ6Ab9vYjA2aF+Co1wuTaT4I0bbh3xLJcI8vviu8RzmDZ6+6WO0Ehjty4L4IPBnoEbU2EWEtHDeBO3VvH06XnK+V9NRavUJjNYjSKlmmEosMkphdJBsGOlo6OSx2MDWVkn/fqteXABAFWdTT3eiAJ8DR8CYlop5C4Bcbk83hPfwnWyFJr4U4YpQ2slEdV2gnq66bOTkd5gOWqg+Jlg2rsWFdoyKb1lrAH6OoI3K7lwarGjl29ilHxslFHYxJuVkvzsMPH4XZlhEIwoqeHxY+DIBcP+eZrTO55ij2fghgEFYuHFJcylA4z0xGxp5ZBjJMy0CoJUfbUfUGI9cAQmnB6jp/yeHQlWjilXbauQDhC97gP+il/WdFws5ib+vYtRqY1GnixJHnJ4iHrteG5iumsD5EptyAvr8rLs8r0JjtthYIZgpyysAS8FvewumBNYbAOk/naMdmpAAqOs/CGYinWalbZlg0w9wqOEdrF8sMzAhG+sL2MBQztmqE1T2b0MIztejaDHlBBtYmv+OnTnP7K5ya0nKIVP0Rs2uJ6Y5wW0v4cHQKJJTtUwpPj9Ayt0SCa87MidsiUnjROJkaMViPIm+BJZZYdIam5VTW3xpIXzFUhpU0/wyzkwYTyZFUdSZd+fKW82MLz5qeQoIyzZNbU+8xAHlJ2msXSEv00S9vbHoTMWwix9rIW5Ey2GAYPxHaQPszqUuEynzLVDRVptJ7ka6tZujRVI8oJc9CoYillkflAizlgHBrOAY2kw4mlFGF7x5CbeYtyX76nD3Ye4KZecPgfRChOKxptlGQ621SiQlw5c+m7NsqkNdzgY5xmeEFhe4plv8yEaWWUZpmvurQury+yTjhvyc6/1Y0GcAOiVHkvq9ZWRiATcln7RGscVguK7R2Xvm7hj01k7g3xVodGIxc8P+qkqUxh"
set "B64=%B64%e0e38mIqU1pY1Bw2Y/aZg6IowtpOhsEa473s+J+1PNglAOa3xumuCbaO8QNg1parOPadBc+vr+zNmDsy6tqU6ejyDj+11PsueE2GIqwyllcWVhhXsI/68KOWQWTo+cMUW5T2LN/ox8HWg+CB4voveG+Enimy6ej99jjtHeOpEhM0kEh/HooAdNCRGGBUK6zr0Xk3CTHMDcme+0wsCUEUFjgPhSyvPoSkkx1O1YLNfdcrJAQtZ4N9r7utNYqRX/ObE+AxNMQdmOtpXQwaUcvq+oBbL4i6xE4a41nfnkmn2ntu4mjgbOUyL8RYwD/6PQH0pGpb8dsg869Zv6+YeSDjqXkGcns5v6dOr2C3Fy1ZyzJNeRIlsSpTmqosnOj6Y0vgY9rQNKnS0Lh2Rsf20JOFps7m1lZSNVsY4dmC5epM2rgxk9Evg9Ej7izYqLKWw04tvc1g8S7zlRreqFn/hd2rKaVGsPShx2O81Pn0Uc09w8OwnUndgTDOTSwpI2M08vHrNjX26F3N5o2eYChJT7++ohKpg+Ch9ZkdOuQbIg/RwzG91c5NwVqc25Ni8Cbs0ibc1szRZP+d8FKQkvxfpwVKr1QZZzF+TD9Nll935Gz2b9fduABTz+AR+tFzAOYlMShG+KzLoXitlTc3L4Oo7OrIKY/pPZcwG3dBDAYiLbFQO0Q2SePErRm/s2LZiJgU+FPd4ImhNC5tQN8Pm9rhKgtk/HqIZgBgDxZ0rceep9t34rj7TllTGw8exnOV+GrgBt394MMmfM3crJxMfTa+vQHWdpNFJMOY+EuGk9Zs4p+VRVTPHi61tlekDvCMK+OGgM7hZ3mS8uSF8vs0DZaz/GiX+h6h51LmdEHLC3g+QEFCnXrHrr3xaybcY9nVNnDHQJCxbDiQ4Zcx9EqzfeoX5brpvQMsm8vvzrHI0hSJlL9IOi35GxVLzH0pLiToQoEIdi/7kqzLeTnuqOLkpnnlq6OnsLh0QRTjNwLBmwctYO+lfTnWX6lyEN9HDyhi7nPYswNHBAKlMFLvvhwLBwOmiFmejlLS+nQnOzJmshZWXxWvpKN1y9Uoxvb9X3U71nYtEw2MZb5AFetkjLT33k0C7RG+E/Bi7IXfL4i3hYSz1rq4JeTV2HkHvCnRQ+/S1FpCWPlbh94xd9RV7ZnDPBumKUYbuzV2S7xJXSEcM9190YTMO3hHN/l9HuI6p/fjvzIRZu7nhwJSwAUrCTHqY46gX7vPdNiogD+C5B0+COQcQQP0hxJej6fh8MF0vetRQeoVQ37voWNt2Aq5HggG8bjNX+epo70R29FTsDUCFhfy0ybJ4RPw3Pg6nRWO+6kF/tnxYHAw4dDRDjo6EMS1DxeLNjAWiApHDP0h+a2QSIIF+Y+7PYcL8Jbfzto5HeB5YrS29nBqgYYe/3/3uoJHKBx8OhoGALsuAQihErVDIHQb2sukyR9Wy+gnccJzfoRc/O6hLbXQRQ2K0XfbAz38wlkNu1YUkACE4xK/WKT9wnO/BuO3cbnIHsU9YSFT+q3NwQNHM3YdI+ycHyMCvZUw9ohf/JxbxP6SdnGrtPQBihhI5LCkSia9pJBbVkcycmrXAkE8sjIeKkr2Xika+VOHdV6fxXmtV+jqbVWvBNkx9LIeCduIxWLb9zFb2XWeKMrnSkLoEe5AxLqIMOfksyEBBeb8NucVj+t0wNXd5Dp77d7Juv5aW9mdIJZeRN2dfUEIbzrsctXhm3MJsS+evOK95qa5vIG0B+O3ITdDh3RF80H20W3TaK2+AvZY9I+WlVDj8+uGw54ZVmiPsifU"
set "B64=%B64%XP0WbNbeVe0WNfCKkxt9ZauIWSJ9bekTmQPPMcLbEHOLf6QyxY0Vmr3QUz/W/fwjlfUT45bbb0vK/Ai76Ia335dn5ewobcbRq3IDH/E+xMaGnF5mfQztoDL7khq8PITX3qAup8eiePUX6nh1bUqmZRLvAUx9lLdWzHcpnDYqG4hh2l0cG0QoenJsu5r8SyP876tgzOqGEYk0HHif5QTLVO3JXrxSivZMVcFzS+Lg4Ze+NrekvSc9VPHaPD6is+8GMxenp44O0Vq4laooO4+wdbQ0Xe46Ty59Q8ryUn5Kw1YAc/JTm9LCBqHxQLMoFo39tJZlDadqfS2CPPoZyTat0KBdIaZ9doEea8u9IXYSxy5C6nfgbZAr64faUHOw3pLyOFvYm7exuqM0nDFfv2env6y1RXcsO01nWVhNv95r+LOKP0CMnd+ALf9/izGGN9iYD7ELn9jLYHd0LRK2tAgraT3b1HrhX6vy/pr/BfcMCVDRNgAA"

:MENU
cls
echo ============================================================
echo    湖南大学 校园网自动保活   v1.0.3
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
