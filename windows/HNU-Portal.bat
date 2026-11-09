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
rem 这里只做分片赋值（每片一行）。写文件和拼接都在 :EXTRACT_PS1 里逐行进行，
rem 绝不能把整段 base64 拼进同一条命令：cmd.exe 单条命令行上限 8191 字符，
rem 脚本稍大一点就会整行溢出，报"输入行太长"+"命令语法不正确"。
set "P1=H4sIAAAAAAAEANV9+1cTWbro7/wVe8X0DbQmJGjbaq/MGcfW1jM+WILT6y71ODFEzXRIcpKgeNW1QAUCJIAKgjwEbFDaVsAnkYisdf6U06lK8lP/C+f79reralelEnz0nXuH7pmGZNd+fO/nrt/zm9vY4eOnmDo3r0w9L27cKfU9VQaWCpsz6uv87+/TyvBK8UleXcgW+9Ps8p7f3/fXbWPF0Rf4kLs5lkgFIp7zgRQr9w2oox+U9Cr7qjkRu5gItH8fSAW+OmMMO8OUkSF4srQ8r6TvFvJ5ZWC+kF9kLf+7pfXgMVZa/7WQ3yit3iqOLv3WdRNWKbybhdWV7Fhx8Flpc6Q0n/n9/aR6v6+Qf6v2dynTS8WpZWVjTMm+KuTWlbXFwsY0fYLb7nuuZpd/6+pWxxeVzfHyrQ3c3fSSMpLRxvTzVWCd0vJCaaVbvf9OeT+MK/zcpb4ZhJOoQ/3F9U3Y9O/vM7QvHUjl8SU1vVacvF18kIfJ1KFFZfhnZTmjpkfKfVn1/irNSecQ306vKjNdpSfdhdwgrMWc8UuxZIo1wi9xgM/v76dKg4s0r5LtK64/UVbel/pe02Nq+n5pbUX5cFsZnlAy92FD6ui70uaDQm5BWbgNEABA6cdZGVDvP1eX5vlx0oVcljYJwIDf4TkAfWFjrJCbLi1uwkzK8FO1/56SXVXSC/BgabOvuDQI4AFQwGyMxWNXQonkpVAkwtzHY4DcC+FIiLkPdoaCHalwLNoci4SDV9lfrsYDySRzH8JvfwqF4oFI+HLIE0/6mPv7cOAi39vlXQxOoE69ho2pXU9KtzakhXweANUjgL06PILgn+5S+rPlmUewxybvLlaceg2QLHd1KX3rcFZlaLY8v66sD6sTK0pPWumeBLwo2XllebKwkVV6szQXHpADUl0ZVp/NI2nce6p2jSH5rG8SOfMfIJHS425lYK60scGOh1KtB5qPNDME48w4TrL8EKkiOwaTsAPNp1hx/TFr8jSx4pO7AFmlt0d5PsF8u73s2F8I7Qy+ZuXpLpgVaEIQ2TiQbpa2SNuFqQu5UcRKbr24vsI8xw+2agDhP6e+b2bBWDQaCqaY+uKmA1ZS53LKUJ5oBTgBCBMoUV0fYUeaHYRxZfiOkumB023Ho1yJJX46Ek2FEhcCwRBTH04Wch+U4fvs2P4DsLy2FD7Wmy18mCm9uc8OhaNtbnj0ZKwjFQIi/SGUwj/3twXiMI/xwZHm/W1tiVAyqZ15JyBxLK0+nIZDEIxVgI4BtvKDLOAWgedr3InY4HBVx1aBXYE52IHD+4//cPDoiR8kBr38jUE1QOjlmTmgHVvCGdzEU4AQQoIBYIsz5bqUD4PKxj2QEEDhAHjcXE8aAff+HuANwEfQBAgyYgMBXaCtkcewZunDBwlU9IGy+qLY80TJ5TT+ulnYXFYWso7vj7ew0qNf1cx8I/xHGYDfOObHXpc2lktrr4DFgGRKm7PwL7Jk9yN8SqKa0pOf1YfIA+aNbfaU5/PwMIih8tMMstDQ3fKDBWXqYXEI2L+7fO8DSAl1+hkIDfizmL+t3n1eyA0x3949Ht8ej9fjbfR9w4rPdaIv5H8ujvSWNlZAprILgZ9CbqT55TccuBllZpjED2yyABDrfVDanCKISegWlJ0eUQZmQVgWciDYl5TRhXLvXfYjkFHsSpLBOUrdo0jx6QWgftj68QMtR2iVcvem0sO5Ye1luWsSxRTXDerccCGfVSc+FBfWCWs6PeyWpAhHPOG5mB8G6DAAv0Qcyvuu4kwX+1vzcaBa+byAEc7Xtwr5"
set "P2=Z3A6dWAA5irfTSuzcIwsoQBOZQEeCN3ii7wGK40mSitrwJvlyWEQxYDy8uSTcvc9kFbF5XnYdDF/DxgCaOm3rgzuA8QebJj//4CycJ+fDPZ/V+npKaz3wiBDz3QBr2Y5VLLagfQv1fFfAC7wBKoDvnUgR3VuDegB6R+11u1JpIbVF4BGEpxc3HQBM4JyFVgFSVKhshgrDq0C+9K0IJ2AVZSpdUCd0vMMlkZyBHlc2nyIIHz3Fr++l1XWR8t9GcA1S4TaY6nQuXAcEJVVZxeJj3Rm0BH5rYFIofo0ekP+eTGvzt4z87k8ioSmgwiy8H4COBrE3yT9TRuhgaDhQAiXNicA5GDeILVOrIiZgIe5XoETcNggHcFE5fFlpCMNGkhHQ7PqDB4EP2e0HDIZX03pmVbWwabI8O8AwOPGYYGN4ZNC7qlDnXsPOlkZSauvxhz67khio4xaniyNbADUtSUF5XUKblx9QWRKS5Ye9xan7oONgtt+NwicRxqOhBFoM9AB5dEHsAZYG5JsQUyTeOlbNyDERUtxehYZdXMUKIjAU55/wxVwWsk9ZgfJjmPF/nfKh27YFKqynu7Sck6WDCYx+ZRLKzw1ySw0RpbHQdrrFLDHoIDWU8iixVf5Yn6WGBVMJUQZJ8xKlj4UORAJJC8JlpRZG0kQZyMjiBjd6+H/NHpRNJceTKqDs6SBdTYlVVRaWaTP+VII8Ux/6cltJf2ApC3zaTPtAfT7vm3y+HaTcGjCv/fi30Ja7EZRW3zSrU73I7uiWM2AvgajV2iX6Wdg9dI6+Wzx9ltiKU3dTAE+1Oc/gxRGSxQ0/MQKAATwUcj1g9VHlgNzu6OxeCLWeZW5vnYxZeUdSTSlZ6l8a0kdnwNt/N9do/AvfA4IUXpeEQzXR5FpX9xkh1tbm4VghCkBFEiN671c47y4STSMSgRJm/4y7BPSvCAiSm9WSeihAc2tZ9qwQ6ClQuI5iNtgSKWw40bpCh/dBSAx5JlhFRXWh/BRbqHDZkmagSjTaCUNsAWPBRSygB2YTJu3gKvLjyY4JU2JuYAjgBHAPsfzogwffQBHkI0uknhC5Iy/JfurmH8Ajwk5vz5C3xqqwofCFwTAxj3QINKu0TJbKWzOq7me4i8ojEn4sOMnYHWyDJAoNpaNDYKGFfaEoaBH3wHHwTaFDOMKS+2+W6GzOpHgVnOlzWndMgKaos1qIoEABXRTfH7fBrEIFl2jgXWBDhxJHlKfA3Mo7mbmWePOJqZm+tAY6f8FUI4w63kFq2g2APARmPTlsU2w6ovvu5TMu3JP1oRUnAIkETACiVdAMq2L/NzoA/Zq3MNZSmMmoH/uBHUBocr8z+F8E4hW6X0Fx0LeHkavFgYrfbDhp8aapNXAJ1Tn+ogki49Wy/kJJCR+WnKb4ENAPCxMa+OMA3Pg8KECXcgCQSCkX84XR2eB30BSw2yl5VUCoY51Q5uYqY7rMVD7pHcIqVzh60pxiRbHRTRiI0ABExjgBudHaJR+E1zJIhTSjlv/YAijz6xpLSJxY7e9AnzGhnfqqpcTG4Jz5A5tipMn6PjSClcUZB/gZ8h2/GNwusEsAVDphKTJEYkR0eYgzc3VBHKCZr8r6TkQvEKK8d9xruVfQBoC7tGmBqHZ9aDc1U/nR2//5TxIXTzaRh7OqCy8QOHQ91S9nQa5ogxMGUfbpZG6wZ3awuCTMKvrSb43Qm9EhAFKK2MwAZlVBlNOPXSAQUsukAPMQnX0rbK2aCz7DSyrRRqEHBl/SyKAMAVWmTKyIkxlRga1bDGD045m8SjXJKAmYCXu"
set "P3=CBIjNNKcuF5dPJAItNfX4aqnk1fCqeCls07ukjfU1TkPJhKxxP4g9+QToQuhRCgKTqKfuVrAkY+mIlcPxKKpcLQj5KqDnbv1H0YBCemTuvAFVu9sbmkJJsJx8BxjqQZ2jTnPB5I4n+kLdoOFIvCx8bXrwL4zUuBIihu52I06Z8cFDjQ/+/dYOOpuDqQuiSddHclQwpPqTLnqnPGqgzA0IQaFaZTdIIpmheMwKhK7WGWUEdqAMbhoInY+dDScTMHgP9e7LqVS8X2NjU1NOz3f4D+Nrh1M+9Dn2+tpEv82uhrqnEkOkH1gxaSacRq+osulf8Hnbk10JFOhNgRhKtER0r9MdYB+irSEQlH+mPNCACBaJ8JKOM+V0HnPpWiHJ9TW4QlGcat4Qv7VHq8P/yZ7zs8cYoP08N/30cjGEA1odNTVXeiIchJhPybCqZD7aOxi/elkKhGOXjzrbE9eBERz8nKmkjAdxgYAiSHmPhRLtAdSzHUVftzHjrnb2tjhw/va2/clky7+wP62NjcSGFAaE2BG0Lv/Foh0hJgD58P5Hcx9MBqMtcF67FTroT11N5AYQa6QZa0Oj4CTiFLjcTdYwQzUSLq3fHdWSa+hgMDAIYa5SI4qy+8oiob8trxKfGtzwBPAB/aHRHwRovBPpPrWUDJlbJ+TvRhUj8DQTkhnaw2EI8zXwNz/ANqCWYC+tXnoKbDoUgC24CV2OhG6GOo8u2/fwWQwEA/V823g9PouOXhgBg4Q/xf8IDxn14vzXeSif+lsBkAJNpySjjQbAA3HNXhuQ0eBB0nHSf7qBoqN746mgG4HcROE3DF0jCyeu5jc7L+DqwTOAorJzZni2APQ5ZrOzKAf8SSreaDow1n8GnKtyNcHMwTME/CxYEA5f0d9/RBFrYZH7ZT79h1JHu+IRE4kfrwECGuJB4Cm8OiIw0Qo1ZGICsYVROCMISuH456WeCScqnd5QEzoxBHzHIh1IKNEQ2xXtRkuxBKhAJBOvbOTAXk5YxqY9Wk6JQJz/ceZtmu+HTtvOF3VJtTPFI6mzuLDF1Os6Ztvqg0X5wjAOeiJ2Gnv2e9Aekof+M4ahwowd+g/mZe5Ywl8yn0xxJqaqp5OesTX9O3HjNq9l7kD0TbcAP7d9M1Hzb13j/EU7Mgn/RmBP/dWm0P7jEvqG1YuaOUiuxoXmIJx6L7KtN7IhCnM7U95LaQn5tbQCTs/4/Gd3rP37BmknYotNCfCl0E0H2m+vMtuFwgDpA5NpAm2ZZ9Ds59KAz6vvAJC0AYx3zaZEbPbhJidvo+YYm+TiSLAXa/ykOmwJlCiUBfIjLaFOkNJHYlaDF+E2UVMqUpWIY1x8D1e1p4U0W5dHKIi41EDNNkz+LuQY438P3uZLLjA3wB3BUxSMPTV6fXSzz0gNW3iIdoKznBbJ7dWCE+pxFVJRBjyI4ry43TLVbA+2j2wd4+eSrjA1ToAwmPNLoDEA9jsj0SsXyTrG2RBpOMk6jkRDyX4ZIFISyqQ6khy+eY6FecSKSisT0kYSc9aV2m9Gg9xpLqOxmLx84HgT7UmcYJMNiwn+RsDCB1ciEY9P2CuA4w02GwqjKfxnIqGg6CtRf4jlLQeT99mh0eM0f57KNAejlylY/Kti2PU2qs2m0mOMGnu1lgL52YOZ/1oSM3fsfNwmp8sE9rAE56xO4Tz8i6cyg4G/JPLu+TP7GFwmUtdTnjbNRlweZeHc0/VjQmFwoJctl0zMeWf6/lk11lLKBIKptwnzv8DgzVuwMp/doQaKrgVQHwg1amzKeXlbDiy/Pg+BlGBL72e"
set "P4=b1lShF657Vjprqn9WSNhzUEVTHHOusYIRcRl37EjF+ikfub9ju2PhANJbj9+x34AWXwlcFX8BRvxGwYhTuaR5qkQOpJpYAzVbARUqrJcw50BUPjEAaCZJNMnlfN4zG0mUkQvGN+Gk8isfqEQ9gnMFCblOSl3+DkTiuODkKYJxYavsx8vgX+q4dqgVOc5kuhWpXXOo5+rQYyQgYqKDtktEI4mBU3CE5os4UCmw90QW9om4v5q5o4DRLIcJirkRkU4Yu0VWbEY4ddyvFO68sYgzdpLCiWTchBxka7+Qu65xYILcOHD4SAzprMtgQwpIF4VKvhjfypOHfRVoOIrWM0sJc95vgewhqMBLUYQpglcekjdZfvU8VBn6nAsTnJOjHVVQ5QYbIiPG5W8fSicAO/IZ7Zm2xJWmcVRbHCc/TkrnyC25K60NJh/ajN9M/1BgzUiqxxn8DdsVDukaZjEn1bBp8mqLu6OPF/E2DqPa8mEh0S00atnLQq5ARiAgdiRO0SHOllibkd/5N0sxsE27lGY9iPp7p9MdlsTkGHMfhEN/auQ0OdRkPy9rBZ5jQcX0lW9cmX4PpGMOjNfnFoG/WguDMHw90gGAyk8aSiSJGJsv8lLMT/oPskzxIba4U5MLa3ArpsObSY+eyFVHf1m+6DlajTo5gE42pwMgOklh8itzy8ryw8tyX0HJoQGltT+QWElDIiUOdVmFXJPKb8AWk8y74dmea5tsmZmBBQCgB6mrZkV0UQwJkd8Wl4ScySYAKDlSl2mPAkgk1JYIpkzv6T0vuI1GRnbFIrFtDFsqU8xPsipIsxtY0KIiXyhqF1A32VmkfLxpc2HZm/UxI8YKTA+Fewhc7ARHHOcPHGq9SB9qptvdEx9eZCeav8HkR3juRRKzTSSaMQNjs+pr8bQv6ICEY5SAp9DX9TsLBL3Cff4Jz12i39bfQs9gGwStcAOfj7EnQjFI1i35foPjNIm/21fI48pu6RvGj1fO/lnhuhzBjtQWhs8jlOapJ4AYUeCW+a0Sb7572QfxCwoaxtPMJfVfLLIVSD+tZfFPNbs6eUjAP9CnkduAUG8VITywpRXJE2mjj8hbGDFwq03ymoOk4WVHgzuwN5YccDx4RGHcP1xoKxeTJLWfoiugex8JBRnl0OSfKvchbEDi+qzgRtzayubtwHC8EI40b5PxF9qCsyKPR4PXfncDcrcZ+xMBhmf9VgI1EiQ+ZibikJbUkDrDPd3OUS/byHi2YkOEC8dkUjF5qvwNOWokVsw2zj+RDNw0rrVw5z1MgwbQC9hXm7hhTqWplwekBgfJAkTh2l9s38atMJXYpJtzKIgqNBQzfWoQ8Io02U3KE6S95q+zGCqc2BOkn9mcZFAcWF2rmpisaaPZSXiLyLgGuT7pcRrwP5fknxbUoFEyt0SCYUAAMfCkUg4GQICAr92p9dr0I0zcAHLamvKazHmo9xYPtQqi60o35KlsORt+plU2pNBzqEywPSqxjPcvG3AYCaX0FZWAn4zuElL+37aPlA9WNnKZKxQtRAGSdGOBXOP+yiN5YmXxe5flUcPlPfrSvqt/igcqjz/jrR6MT9W2uwz87usDGta1LGf/pC8G9Ww/nEZNxQR3Jw9EGszrFky0bGewU9VCawRiLDJD5KJqqbgb6/X66caLPij9dRxP5Wu6pURgGUgh8K6bj31i8mFZZTOq7eHbWpFuQ2KSp1SdCgV+S96qSTP8Zlye6LGKWMsADBCsbn6AisG0yP6LshcQ7xqlWTFgbdYdb6cUXqWRHVw3zpYl5otCzIV5SnYqphW"
set "P5=933HxO+YQmjS/tq+vcE2LJ6qbrXRVqnanTZMlAkHRL88lyvkHiG4Nx8CLVKRmjq9rrx7q04/pVo2LD15N4shIcIWIIRCkOpYj7oyTHVK2E6wMmYhWTjI/2Kg6CKeUCcIql2WwkB3krnb2W74VNS1uVPh9hCwCdsJBjU7fuoo+3uF0mXuK8z11TW0O88FgZZuXP/qml7aS3+0hRMw2TlY94YLjFzW9Cdn1Kq/t86IxihojYdwwZGvX3dZQ/Vxhp6ywxlzeFoT4fb6Bi3bdN1lDjk7g3ykM37ae9b8RYLb1FyUxjVH5SI6g7h0/LTvrFGV4qpYP8FjbhUPN4mHm2o+HA208xKY1KdZ8+ZJKopFEBx8Zvef8NSEGD8e01FXAX8YQDE7r9eaZqgci5DiesY2FZigXGAFtQDl8xpwYLRS31NzO0GmtPJanRgSXujwHaMSbCRHEgXz62ZhU5mI+AQQAHcZNfraxI+U97dM+sg6s7XgpjIzhD8VFiD+VOZTyMGymdkeeGS6godennmEXtLsogEtqbpWWb6FcrKpsxPjE6AFwYOXimxFee0nww71d34YA9lm77hCAdhA7yPgwQ1jkul6lW55/g1sQlc/NmQIPKcltuv/LdxQfynacQbLmc54gtHrojrp+pVIIIpFYECVcg2DC3SblRFBjQxuopvPxSh2Oq69wCj99Kyy/JCIF+Cg124xlMC7eOWxz8P/4Z/s9PoADH6s4MRs/POflVzOLiDnAlVr8LC5mEJXOEKEmOzEFmEi+kxGx1YkpS8LettlNlQ419vUAnAAnkS9FjgfqRIFxAwF9YTxvpqM3i5Ru1dqkn4htheNSRxSouNwYqW0OaG+nJdw/1m1B8Ev13tWJeeSNKEbxHIyFrmMtWjXeHXcjX3wC5Ie/AKSlmlVdLLi21rhBaueSIuXOpxBTdWJ8ANK7mpIPNIGrkg4ddUeh8X5ZYQzipOnog/1Vga7cXnDB+KCGJLj8Xfd+GjyegH9o9QEUtkBYipYoP4OXs5M/R48jKMs4AJUuSuq2LXS37Savq9Vrq8qixvYRTO9RCZjaXmVWnSpwkunRF7rR0003LajVhq9i4XanyifRqX32okytvVcH9U289mUmQhc+Sja3GNLmyZjDCjU8ffoNuzUkAl1m+ML6JNECWyy6gFSnbxYtJ6fhIoVYRcOke/FHRhFkM52TJNo1YrHUGbX4wRgxvBt159pu7bzRsM2uZyt3dPSEQzy3Ow1fT749AeQjfEk2GMeXgX6He3ET/8xzCQ+L592G1lQUqUPn4zbO0DDImVEj0vqRFCzqzJQrfkc00/1tl1R1c3NedG0AQqGoTIhypl/w3uLUYcUNu5hNy82ePRTXSGmCYafwqPlmTms8d54RiqI5Kfdvrn2st+3UHywb/7zGaVLBwLt8Y7k91GbsiVl+D4lEkX7G9oYvFLSKPbnMa1n+h9p5fFNEBVNHt/ebz17d3t83GXRi/81ETG9xGvaCrlBuR1ANMemR6SOyvL4MrX0FB9swO96AgIZ41+7asnYZVvVsiLAytYlRW1fWkrkTPKUtFQ1ZLtQZZaVmBVRsd2Ps3xm7Q5O8FG1OydJvBkyV9JpyvKk3A+q935Snoz3tbwF0S5Tbka9vyq3PFraQbGjsfeB0eIs5MCrJfX2sNFaKjWofP213KLy9dfIMek5sGlJt1R2qMi9KYZeA91EbaXvZo2+0dUX1ZpXgOkuf8t4c7hoaDOydEBf3Hexr04Pxy+QtNWGmevTsTnCfRJ0gmZ5CO+QhBM9U1nAIWwPbVaTShQP3aio"
set "P6=6WmwJMPa9Oi2Lp1MvAd74zRrii6YhYA0TCMbmOU493H4/4vmCDCwE5dDCaB/5uYVg/sZDjwRRU76hBy0+KlMRRtliPtddlnog51xgINgeyyJsib/LXyjowAOVyOKixQkfqTWLDzlnzAqi5ARPQegLy05DoGZ7bzcCpexDXxuE+251Awq2sfSmlxfeKI+vlkc6sMmaUOck6CnzlXeiYmGopqZ563L/Tay3Jm8iiiUZThgh2T04ZhUcVlP+GyoREslSizyEnFjkpeIJussh2KJg0Ccpnl0XGmSU5J5JhjCIRqsMtBC8kFO8uKpatLQWr5va4cGawX3JbLQL5Ygjx9lF9jc3LMvZW4p2IbNY/ybG8WxxQpf3ybzJe/MXiRYN9YiyRtDKGkdPxim0jt99rccOHLEJpIlySH9D57DtdOXEiCaT5xs3X+UfyrrDbzNSJuHWvsIOur4E6Eq5Hyhrj/WXgIdU2N6rXShLghtoPZRSALVwe8HGBAqKn0f0XZrWPdtKhF2QytXJG2D/DYxBO53af1X0GJkz4mLC+gsG/cceN3OyBAFnvDSp9Elhygte9ytvrhZ6nulrN7Rbhjp14Ilmg5TerLKh3HsweEXL7HmEy2tTL/5QJ17h6FurvfU6awyMM+vYnqme26yo1VVz+iBClnR2MFSwjOd0kAv7OLZPNr12k0QooWTXz5F56Uz6ne+4B0kmf7SyqIA1epMaWWssuyDFrCEa7R9mhq2amwPrYSRDAnXmT4KuvGLKdKAF0IbT189JXMD8S1W46Fn7af2anov/0wfzEQ0jL3sEkc4LOEjV4UHcfAiykC5k4WckiNS1AFvKzKuFeOOFDn2qAV45gMvLJKiCD2vyqPLImM+uClviF93tEx1SxRN+NzO6CktG9aVkRv75bAfVggY3gqpLxGcTRupUGM5no0y9/5ri4Atx7vp9Pgpxhuka4DIO8R+8YkVcVNZX4ZuA0AgzSzCKrpp15ZMyaYT5SIMqIsBaJZrn0qCQL43Zfop8DgPrUyKIDyAcXodDU7egS5XQRH09FCpDi0UF/wqJtFsLlA48hgvyujPYq90etVIAOI1MC9u6jDjFzk9RWkA0kmqpgdAFn8d1MwCfsKKbleTUWhblGawHy+zNMNGlF7KVs3HVWRpM3xmUZaOCiFohfE0WdmcDwjXrhHpZOWuSSWXQ4vqMBiVCfffWCOj20t0wtfmHbrLpeoQXZlGElmPhOmMSAggiorEgoHIv7hP/Yd0Av3/2e9DTrpdi4/twlajUOt5kCxGo3EoSRlXooDPcOV1dgBTlyaxFoTzrgyp0RRo+gwS9RmPCxsqPmGSKjNYHchkiuxpPunHmNM23mMyFsTaD6w1Eg9KVN8CX4ZSSfHf+goknLYZayIBTAZI+N/xUTPQf5Ge4fHv8YKEj3sOiDcVC8Yi4slTbfGGyrN6DlDkmUNtB9vjtYzhKXMaeRQRdBDcVvAgU1vRpJg8EkuG6uV6fEFDYmJTptwISvPUhR1j1I7DV3/GQvs4v/Zj+4xm1IkKrFrG0MlQPBBOoPZBkVUlhyZdg+egNBnWKnFSiIZSDuuleKIpiOtcvF1mdpHyviDeyYzC4FJ/Fs2GgQEsd8lPazqArp1JjziowY1i0/otgg496UHal0xduv4NHAysP+nHpfGTN4N4oSG/Zgmr/PvWi0OrdElfMT+MVzXhTXXdWghLu7FPyb6mS5vke/uUqQ+wMTRobvUovXh5Dhg9eEHb6BLdviBfeII+BIcH3Xhi8gxq2gJg5PAJZKtP3OtXcTsK2RwYmnuzRveo"
set "P7=oMb8MI52WvcmOHv8ZsBuvH6W7708+aE4PWjnaxw/2NrSup8XrVUrMLe91EW+w0UvprK6FRL1mWWVbbrYqId2BkSLoU17n6XlYsvmvFQsbhv2qtJYUa3tZeuUKN+zHDuUAysgpSQ7j2QWL/0Ut9GaV9UA8KnBvI/pFeJbEbEH+NWDINM2dBlDHkZsCXjbZXsee/rBmfzOevtpeYElj71RVgqt87WXdKkmUM5/997VyJ/cnfQaRio4IxlUdRLkIBKOdJOrCIwKeNUs0U1JfUf29QpeCWNNAl96IaIZm03/BHRuhU97NPDaWT8eQEZIUyVGHGa7aItpBUYWXpReoziHac95DnYGQ3FuPR8DHgxcDGlzUlmpdNkSVopvLFOHhPXKJdKIFMdvb0fKNFLOH1UDbmzYdfDkyRMn6Rh6U4w+HYqt6S5dm/m8zLfHu3M7eCQioN7k9e3dDtRIqYdQZxihDUex6m0e9eu4wJmdj/LCkW0HxS2D6pxY6lORt+gwpy3qnPwuausoS3KjbmuZhIs18Iaj2uNwOctGQRlzh770tocXUvz1L0zPpZILiCXgrDSfqZOMd+MKIQp/8QMcAdOOPvUcDUUvwhBeeujdtcfr1ZFY5Z4hXOO6KehKX9pcpySRW/HZs/LUW2o5FSGChdug02TS04t+eSINHfyJOd3LpNZmUfoqq9z8z6UlDPdZmukp9kBlw6KDTty+d7POCfr+iLixwqYH3uY+LHTS6SGpVNNLCK9uRFQpArR0B1bASr5vveI2NLxmzcxmJzpS8Y4Uc1nrt8238LP/WhMTVxSFuyonq3fwCoXXsuzbxxxsOzHA1ndxNTTYTSrfqW+elt+FZvuM3OgOCpNjSTxTXxX8TEOxlp5ySdW06vgcunta2YldwMeyBzl+Zdl3vREXuqB1qDGHqZOBadv2Oy0jWTiuf9YMf1684rf2Dcn7Bj290qukfzV2b4WvkaSz7NKSB5XTdhoc/ug8rx0u6S0HFKO2haMe3tbzvPrxi7+sVz24uMFYCsBLFFszs/wJ8bov7qCs0Y/jvBwOaOXgvH/SIdFMZRMk/7CiY8lMLeNzJPFcFXaiweSSYDTwwc34P/EtSajRG4U0zrJ0CNl1BzEX9Xfo/ojLXNTeoEUy8f+3iVsxxbsj6K0Eyw/LD3rKXf36Kwn0ygxUBVhoMSQXNVPxoeywYVHoxApt4BNw/dHdD/YVn9eTiaD/q2s8BMU7G9qSKb/c6uACE6OitYHuZDOSOxY8YUnx8B0JTx0cTTFHgyn4rBW+VdrKtrNSPbY0K3+cv5KgsDnv5xRgp8e2A3MxAH8x32sapNeD20so/ZJaG7Wi5YAs3FlbzW39IxmPXjvDxLgLg3fYYMUNb2fSr3LX7mkFWM0oC0+UhUl1bJVeIAM0h9V4M/NggZU28nQjhvLhNtC6pLntUVJRWLjLZUR4xKsuxt/qL3HRkm2PqLehPL+u9g+W5heVqYfqDA/o8FyJstqLaR7e/FO++TOyRjpf4z5bI32ldq/Cv/AMrEp38PKUDHYB0G3YPHeI4Fl7iXeJif1klW6M7ygLWS19LVIFVAdLByFowbra8RYmgZYpmUv3H2IGh4bSe2momurtK2VhFgArVSTZmvVhsusNBgZxyNWUtdzLzGx81FbZ1OL7dRHA0a7fRbTML5Y3RuQsmFjTYWJGg+qcoq62rVm7JBUUrYUEsNBeSnfSJcJ2vYp4h7C4/5xfvOwQ1wIXPszwtxTdtL1RGG/jFtgeXBStYj1vUayId9dkaDSG56YeYpSBSzN/E+WL9TfcULNk"
set "P8=Ib9WyPdQvI1QqGHIdOMpAPTkib+IHkztcnezDa8dK+2sr5QiolsN3zKkvc1ofbT4fJQqXR0mkccBWHfDClbRoiTOzqWYHz4D+u4v5Bbwik5e/I2kPJLRo4oGtPjt5aK0XbztZUr/qomuU5dz63KZLxnglB/P5eglLvgWqfR93qGoDgyI6ozKulXpAj+QUgzfDJQV71XIPynmn1MsFumSMz5i7dYwXmzQn0YmnsPCeyzTmBii/gi9MQYfyb62vD2Goqz622P+79X/iRNVvFSDXl5A7+jC5tuJFWVmGL5FgE59wJZOLpP4Ozx4prtff/sBdZgiVz7uVnqzFH+mHoWCuEXbqI1ErlGm5oA9SPzgKlS6wsPfBBakrvSI8ZYY88mrVI9UKR6RyN+gPawL0SvAsS4kLWYRF8SJLP+6jjQQ0OWZhxr9ZWQS0OJGllboSolTWxiah9eo/7I9EUoPCe7oiJtKadOW+T/7nLZntSVVQwxbG57kiiDRt1D18LaRyW/k4GMVc0sHbIWON6I6VcbJEqsCASRVjx9s/f7Ej8ctVJUTdSwkjoiwKClD1w1p78Pop651XQCYC86E1rLC0M52Ws+Q7WRXPZ22VE8j7y3/IkyLftA+mJTi736wmEtxyhKacWLE8/B7apPl4yoqum9UDDUJHeUuVUSRFYQ9FKZyNv5eHLr5e3BTvPtkKE8UyE2vtFyXqnT36e9IsMQ+P6tSSscLYjD3WK4R05jA1oTtl9EgdLtua8uwbb/KgWa2twFKUlCVj6mI5QqyO6Hb7udD6Ev5iWzF5Qd2yzsq7G+8/4u/XU68zUmkGOgNcrDFQJCY2MhR/XNKRz63bOSLS0acl3h2zdIe/EcUkdQuIKmsWqZElF2JCB+tkYa+Y/v7YC2guRSgLg9CbD0dpPnS1STsPSJWgrNIN87C70fxNZF416k8OQghqfpZkxD7ExdF0RHVsIktWr516b1trh223W3wHPeljWT8kejl2E+c+sNR6ep+DcgiD7d1oKDJy9w/6J1zf5Y2JneGtgVSATfMFIpylnIF/doLK2qNCvgjuL3agwDOESRAf1vC5/XurD2Yz3euPZS6FGvz+2qOdWBC41wgGMSouH+HdwfPcDi2fgQTHEBxbX6e6qj9ADZkn+NPYbwUKfBjxwPBwQM1R7v46EAQ564NFm0g9rhvMfQfyb+FEkmgIP8uvGGy1mYv+0V09iRwXqy9oaH2bmEPF/3/55I7uAXCgafbwyDAzqVACCEStWATso12ORAX3ZyL4tqLQlDk4u9enhhrO6aJYuTd5sBF0aFZRxeeBFIghOMpceWJ9he/N93427j2hPd04kRGAYb+DN6kby6+oCZ61Ai81X/wrnhB1NRDqgXVXyiHnSLDd/AOg2TSxwr5hWJ/Rul6bxJBQq/RGSou57yUao98VMDP12RiXvNrThodtpeVODHUTq4RLWTtfNUHttv1vNLTO5gLDud31J/2uvcG3Bf2uw+dvbZ7x40Gh+W2EmqENXfCGqjDbyzdsIakrS6/DbgZOOQzWq3r2knN9gZ9BrRw9R/9fmokPr9OOPSZQYXOdvqEk6vfJJu172xt9Z30mEb0lYa6fBmWZqULRVjlZgRZJem10FMPf+sCi26R2zW8qokiJr91Zf3MuJmHmhZ4fI7bkpNKdoB75/x6n+63GMleWQHHyFQIrWYfcVYA9xZMQfCSedmXeF0NhkMWsvpdCsabobTT1Ts41EC7abWPDi264ziT/Hof/K/JZT2YmUEjKbaz6sUS35B34ExewhcC+cmZjGtZJubSMqX4"
set "P9=tZxy9u3mt3rqz4kRLR3niZDqvTv4EJybMiRa0Mw+60djHPCp/2ooiaG4uk9GrtWKP3lw/6nWw+zEX5nF5BV1HTQ3kK6f06+mohjXPRr1kub3c4+F3DW7WBcdAEHnJ0g4tHgdd43FVZf8xbjUWkIFPCJIq73b1gG2uF4LiO/54JV76r1sYWPaQQ0C5b6M/FpdCpKI9/TgipYiRDL76sjr/hR6svMgBDxb/gpsUh2eOhijeAGPiGLSncBaJJIyVHWmWEAl3g7tP3L0/wHebtT9Dx2SPAgKfwAA"

:MENU
cls
echo ============================================================
echo    湖南大学 校园网自动保活   v1.0.7
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
set "B64F=%TEMP%\hnu-portal-payload.b64"
del "%B64F%" >nul 2>&1
>>"%B64F%" echo %P1%
>>"%B64F%" echo %P2%
>>"%B64F%" echo %P3%
>>"%B64F%" echo %P4%
>>"%B64F%" echo %P5%
>>"%B64F%" echo %P6%
>>"%B64F%" echo %P7%
>>"%B64F%" echo %P8%
>>"%B64F%" echo %P9%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText('%B64F%');$b=[Convert]::FromBase64String($s);$ms=New-Object IO.MemoryStream(,$b);$gz=New-Object IO.Compression.GzipStream($ms,[IO.Compression.CompressionMode]::Decompress);$o=New-Object IO.MemoryStream;$gz.CopyTo($o);$gz.Dispose();[IO.File]::WriteAllBytes('%PS1%',$o.ToArray())"
del "%B64F%" >nul 2>&1
if exist "%PS1%" goto :EXTRACT_OK
echo.
echo   [X] 释放核心脚本失败
echo       常见原因：杀毒软件拦截、%TEMP% 不可写
echo       可手动核对：%%ProgramData%%\HNU-Portal\keepalive.ps1 是否存在
echo.
pause
goto :EOF
:EXTRACT_OK
echo   [OK] 核心脚本已就绪
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
