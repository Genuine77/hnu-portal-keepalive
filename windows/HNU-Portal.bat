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
set "B64=H4sIAAAAAAAEAL07aVdTWbbf+RVnxdQLdJmQgNpqr3QXbWEVrxVZgl3rLbXtmFwgbUjykuDwlLVCKRAwAUoZBIKI4lC2AloOkTD8l67ce5NP9Rfe3mefOyaAr153U5aGe8+w5zm/FHcOsG/bzzHl0bK88Frd+qE88lIee1HaWVTeFX/ZzMgTa+rzorKSU0cz7Opvf9kcrTvA1Kk3uMndEUukAhHP5UCKVUbGlKltObPOvuhIxHoSgb6vA6nAFxeMZReYPDkOO8ury3LmXqlYlMeWS8WnrPO/OrtaT7Pyxt9Lxa3y+m116sXP6e/hltKnJbhdzk2rd1+VdybLy9lfNueVmZFS8YMympbzL9SFVXlrWs79VCpsyB+flrby9ATBHnmt5FZ/Tg8qs0/lndnK7S2ELv9Cnsxqa0b5LXBPeXWlvDaozHySNyfwhidp5f1dwEQZH1U3dgDoXzazBJdOpMrsCyXzUZ2/o84V4TBl/Kk88URezSqZycpITplZpzMJD/E2vy4vpsvPB0uFu3AXc8Z7Y8kUa4QPcaDPL5sL5btP6Vw5N6JuPJfXNssj72ibkpkpf1yTt+/IEw/k7AwApEx9Ku/MlQor8sodoAAQSkPn6iEGq5SFd0AGJf28fHsLcAW84BVjPg+A8xjwUyYmEcV8Wh7NVRYfw4lN3kNMXXgH0FbSaXlkA86Tx5cqyxvyxoTyYE0eysiD84C7nFuWV+dLWzl5OEdnwWYCVlmbUF4tI/nvv1TS08iijR0SGf4DbCg/G5THHpW3tli7lOo60dHWwZQXy/LiLB6y+hApn5uGQ9iJjnNM3XjGmjxNTH1+D1gpDw/Jrx8w3xEvO/1HIi2D16yST8OpQHfByFkQjxyBSODC0aXCFFAM5ETdWGOe9tYujSD859zXHSwYi0alYIopb753wE3Ko4I8XiR+gLQB84HbysYka+twAIKlQk6e+EHODgF2XyIq12KJK23RlJToDgQlpjycLxW25YkZdrrlBFyvXYXbhnOl7cXy+xl2MhwNuWHr2Vh/SgJB+EZK4a8toUAczjEetHW0hEIJKZnUcG4GJk5nlId5QIJorAB1DLJV5nLAWySer7EZucHpqkyvg0qAALIT37a0f9N66sw3JiW4etiQGhCmyuIjkJ2agnN3B7EARUeBAWILnAppefuuvHUftFCZQR1B4IYySLjN+8A3IB9REyjI5MwKLBLUBdmafAZ3lre3TaSiB/L6G3XouVwokKIBtKWdVXkl5/i6vZOVH/9dyS43wj/yGHzinJ9+V95aLX/8qbwzAiJT3lmCPwChMvgYd5mkpvz8ifIQdcAK2M5QZbkIm0HVKy+zqELj9ypzK/LCQ3UcVGywcn8bNFHJvwLFhF/V4h3l3utSYZz5jh31+I56vB5vo+8wU1/rQl8qPlEnh8tba2C3WHfgiuRGmV99z4mblRcnSMUByBJQbHiuvLNAFDOxW0h2ZlIeWwKDVCqA8XwhT61Uhu+x70CMYteSDPAoD06hxGdWQPoB9PYTnW10S2VwRx7i2vDxbSU9D4CT/VUeTZSKOeXBtrqyQVzT5eGIyYpwxhOf1eIEUIcB+U3CIW+m1cU0+3NHO0itGV/gCNfr26XiK8BOGRuDsyr3MvISoJEjFgBWNuKBYVPfFDVaaTJRXvsIulmZnwBzByyvzD+vDN4Ha6WuLgPQavE+KATI0s/pLMIBZg8A5n+PySszHDOA/548NFTaGIZFhi1Pg67mOFVyGkL6S2X2R6AL7ECTy0EHcVQefQR5QPlHz3BnHqVh/Q2wkQwnNzdp"
set "B64=%B64%UEZwYIKrYEmq3AJj6vg6qC8dC9YJVEVe2ADWyUOv4GoUR7DH5Z2HSMJPH/D1/Zy8MVUZyQKvWULqi6WkS+E4MCqnLD0lPdKVQWfkbw1GCveiyRvqz5tlZem+Vc/Nq8hoOkggS5sPQKPB/M3T7wQILZQnXoIRLu88AJJDCIHS+mBNnAQ6zP0KYMBpg3IEB1VmV1GONGqgHI0vKYuICD5ndB0qGb9NHsrLG+C3s/wdEHjWQBbUGJ6UCi8dyqNNcOPyZEb5adqhQ0cWG23U6nx5cguorl0pJO+60Mb1NySmdGX52bC6MANxAIL96S5oHnk4MkbgzcAHVKbm4A7w6Cbbgpwm8zKyYVCImxY1v4SKujMFEkTkqSy/5w44IxeesVaKlZg6+kneHgSg0JUNDZZXC2bLYDGTL7m1QqzJZgGi6uosWHsEqM7ZmkjEEi3BVDgW7UhI3VJCioKD8jNXZzgiRVORGydi0VQ42i+56uBMt/7DKOAwPakLd7N6Z0dnZzARjoPXiqUa2E3mvBxI4nmWF2yASRF4bLx2nTh+wRQYmuJCFxuoc/Z3c2z87D9j4ai7I5DqFTtd/Ukp4UldT7nqnPFdF8UDyaRYFKZVtRZRtBqOw6pIrGeXVVckKR6IhK9KHliDlyZil6VTYQjV/OyreldvKhU/3tjY1NTsOYz/NboOMu2hz3fM0yT+NLoa6pxJTpDjkUAy1YHHIB3wSB754S/XpMue3mi/Rwr1e4JRfIVA8ldHvT78ncTBzxziDtr81+O0slGiBY2Ourru/ijnMvsuEU5J7lOxnvrzyVQiHO256OxL9gCv6hBlZyoJx2FoAXyQmPtkLNEH8bvrBvy4T592h0Ls22+P9/UdTyZdfAMEH26UERAWJiiF1HP/ORDpl5gDz8PzHczdGg3GQnAfO9d18mjdgAkkvI5T4EQsJAlAIPDmWoB21E9hDHiPZm+THxSODCUoBVr6EYzm5ElwbOukMqAXjczr9frJcEN0bLioibXSDjoEcYfwN5micmeihoEtp1Ff0HRyj4QxC/+g2xfu1NDc6p576hOoImqgfgHcjFoOLgAMbWYSvAU5J9B+CPzRc2juRB37gKHaalYeeiHgHdkAk6fB2x1LgIolYv3REDDJ9zsmPrsjEmvSfvvyS42XYosUCPbCthQLR5khr+ZFBCqFiAQwhldgqR//HfyjUiiUCo+R6jsPwUyjx8+/UvIb4HSU/EtKgzDQA3e2OS+YBtQnk6lMD4FRhKRKeTSCMfjatOVWZwwQ+Q8W7E9EPNJ1kLdDYFGiMYDy+g3m+o2LuZPM3ceOwFMRgbtT4T4JQmLWzNwx1n7uFPur5UT+477GXF/cRJ24BDInDdz64qbuD+mXUDgBh12CewdcIPSs6ffOaH8kYjkKDZqmI8ePtyXbYcGZxHe9oD+dcYjj652xBm7jEAkXoHzrFlorC35xbkYczpjD05UI99U3eDrjkXCq3nULLIBlZZCvdMbPey9aX4CRgBfcusY9J4DFoGg9KebjV8fP+y4a5tRVdX8ilKi1uUlsbtpzcw0D5XCiJLkTUjyCmYzrL0jk5B/A9LgOulwNzP17xISI7UfQwfTYaQoL3FGJU8xlF0N9DWLtDqBwR8Fh1HdJyZTwCKBl+Lah1lb8AUnmgRAoDoQa1pg6W157pzwY57kxBCU/6JGiPFkov1+nSI6CRd1a1Lzkn0IbUCUjitVufSxv3gbdcdS8Nii8cdXLgaonB3gCxM0RBJhkMSGYADh1A7oL5UFk3GD0wWq46v8QbqgHF3QBfdAFcEK3hEu5"
set "B64=%B64%dS0SiKLzBUYgEwGtVH8iylxgoe1yRNBAZojpFLcEWEX6+AYLJPklSD+JX0AN3W8yNCKHeATt8/D/+JNmrw9I42cYOEH0/foJpH5VV2mQgONwWV4aUBmfCGNhRYVedKYCiZS7MwKunrk7JaB5KMl8YhP9rd2BImxxZRY5NTwsUEn3axCT8ZrPLImXnmBSHIh1lep8yeJieNZEITAGo7ZsSdxizZkgPIWcCU4p7Syq03OgC1rkm8V06nlOi/rRr9liSQpnKb+CxLW0MY6Ks7NQKf6gvHuo+ab9jSWprEY6Z3cAzQ6Rk1tQWKAZR48wjpw7Mc1ugc04tNsJhp+7zv1czGwd+DHXuSURcv2XC6GbvoPNA07XbgfqOIWjqYu4Ga3m4cO7LRd4BAAP2hEDOw4u+bLpge+igVSAuaX/Zl7wYQnc5e4BD960K3amLb6m337OqiPHyHoCAPh70+HPOvvYUWMXQOQz/Qohhu/Ybmdoz1IJME27qMNZ5E/gckSqrRWYgFHhixcPsnpOuHdBaJ4+kFkX1RduFjBdA0V7sAZJp/J22WTwEOGaTmUvAQ3+/+MUe1DiMkUubvAayVjkKkbMN3kMP3AcPqCthQ/gRZkW65sDlf11LrgrRuJZvcMZ1EITk1fe1aaFIM4Pp27U5qG6vIp0Ruf6UhS0b2exrM+zWuQFeSERpc/rEb4X2D9FmW51mmtE68hQnsSiTIik9sEaOuoVvOAf6Sn4I0p/lPljsJqZIQupDK7LT7ewVJB/QSF+eXWdav1kUnVJxFKBqBTwWJzqBXqqTjUeDHbhmq37WNUXGGVrGtDPqg38asm8HAvd+CzhPFpTOK3R86+XQw43B2Y/iasnkN1/g9yaOf4adTRYwg3BfJsMniWwDJqYZA5SNrMH1QtQVCGi4k55q6g8uK8+Xtdrk1llZt1cerGVpbCyMjxnlFrpNpJY9ccN+fWs+upZqfAWSC8KUPeyvC6FzSSwN7e3QE7hQJ7loZ/X3bswKGANpRCl/BoNies8hw7Hu3mIri+rxyRZS7R5GcN9NnCtQVPdgTrbKRZ11c4xs0acLDYeEFjoUS+oRGV5Qxm9qxSGqMQlD+Xk7VnSDlNdOg2WGkIK3nCD7WOGUxE3cBdixw0hOQuRMLC0LSX1CYxOxhIQOLtNRSlmr0NpAMPpGJZh1YVihVTihsnl66/Pd95IwgWedinl+TqaBDsJhPwWBFt0TaRkPRVNGtit6pD7u14pIbnPXP4b9n6AHZc8YtvJQF84coN7TRdv7IgmD8S+tc4BxFqBGpaT9MZNV6yTG1MtlGBBrg037ZFNkEc2HDF7dFPTagSrUiS99sN4h0T86L0O2CKaV2AhuRSUs7dlrA1n5Y9v5Z0tdfppVWpSlZJY46fa0mgHrNMk3IaUaFUkTBj16lFL54m2tho5pUnY9F+iUo27bIToOHO2q+UUf2q2ItjE1s6hMjdRR5l9LqwGUGTljTKdsZiSj29J7avIZE2JdCWsQbXPYlJ55yEvWY8Ja5WZQbbdntA9UTXDBuyaiTpYmxCaLRjnFk1eHFHyL3VzZrW1GXl8iZZr5MILbWmSy2bL44FwAnuXkGmldokHTX0rB4V8Sn6UcVWLSimHvYtFnRTKK+UVbHhgbLh6GySZgg50wmDS199g+X7rB7WY1yp0kI6uroMTd1CnmDy0npU5dAeO0Ud+lGJM6tcA+bH2NYpX45P3d7EDuTGOQQncDknq+Dp11dTiBDaSsLU0qIUZWotNzr0jK2putMkL2wAYRk23h+Th93AuhFXYUZl6Qd0j6l1j"
set "B64=%B64%8XNyDZNATg/q+Wk+xmoRa2a1TYbBDETCgaTmaMx9ZeY2PjqxKmM1gW0dVw/ZTHYqFq9lBEHLIxh8CCPoPhlOJLGO5dE74y0IgzX92jO85TCbQ6MBkwOAUEeUsgGbExT48DZHrBt8CmBluVUjwN7Opxqr2jhZU08OirBM8NGDJNMAuooG0XAjINuumviYFLW9tauzq6WrFZ7iSX5nfe1jG0A91J+KanEJ1Be0AEORj2+pCwwq84/he4zkR4xtgBkBO8YFybBdEHhxwTGNHrjbA32STi+4sTuc6DsuYr0qSdhbAH1eE8eaBL/0XoCVm03/Bnbux8/abAh0w91+RMDMkKZqjjisHn6fYwVHVt6U36E5g2MveVqvB6U4YuM5DToY6JG0M9HEWjp0YO7UrVWcV1p6au/TUbxAIWVfH0qmkT3sRTE9ojAAdrWePXvmLKGhjG6L6Q/tOGwr59O6Nfd5me+ot/lL1giETlwFYWry+o59CdJIUbB0PYzUBlTsUQ2PCfopcOSrvIByzUVx26I6J9Ypq0LofmsEXefELmHVKlucXbe/TcLLGnhdZ+91eJ0NUHBGfB6t/GGIJ8V/+iOmvKJkl0+DD2LN8Li8nOVwmJGOxHoaRKTNEaCgGp96TknRHljCC1jeQ0e9Xp2JFkx5164rEI7wO25ZQjJ6WdXAs4ib+uoVeqbX3PFiifMx+UPq3eldfm0IIqMWF+WV5/LKvDK9TvN75ffwYU5ZXAZcIV/DRjhvMoN0mMTXicWTKkMh7Cy84bYUa782IRCJbahD65lCVGLbZW5IHGC8VeaHZwzcfqmwglVSXg5AEZ/M6r4ZZyNoB5+PEMUOMeS0oL9q8tDYAk+w+KxDhsyyGErjTUCKtwoFml3CAcXMDC8Eg4sXESDNMmUmjQGYUSM/BSYwHIjLiXGC4nO1+JoiGowJJ5/JmTkMTW5PQByrjmYq3z9RHmEpRnkAUcs4VcxMDdYsBCe2oSmKVfShqX9dQiswqpolUfKvcBqUj39Cmo3B4eIEvEWCLmxjUxaJSKMrALJI9kfTpeJT0RCe/YBzhsM5iuKoakVRlbkKhONB8sIjiPz1nFdk+jyIJLJgZTIzaQxHWTG3Fj5NWXgtw99x9swfW8VjQ/ZKW8Mi4BYVz4wRZiN/uLsGGHWmldPZyuJDTf6yZhHQvA81/AznWqUa9mqLrV1iWb5HjlkTI5w3M9Fd79rrCYXt/F+NZ01ca4oq+U/jb6OeZc4q6cnuyNeMbw6bQ5gadstC2D3s1y7rarVQndiTtCJXQx+5w7ipL67fxRf4GkShrqo7zCHhu019FQhevj7zXbvLllqKxzbJLkwR58kkknBTesWLeg9JW4X+gtJrRgicE4RC9gZsg8MGINGuisG1/NZGlvxWrWJixlpMxIGQ8uqPZGPyo0p+A/NOPglm9VMHGA7T2jVJL05+xiAcOlOtpIg0GpxHf0Jl8PyouV6Hw+d8rpl8BE00y+m5SnrUXOIErwXWvkahs2qEDE2ZM84HD2wSb8Rc+J7GCPi6qgrtQNVSi0mvVS9FL/T6CVh3MWwHpH42iI1jPiIqjxdJv3mbPgPRg/Lse3V8BD3A4IjGr1FbfPor6xpC4pC+hWeCiOuL5bVpzcTUjH9GRfxjGS/PGFPlWf0LE9qo45zyuoi9bD7xaxEf89i5aGWt/kiz58hXSOb4AJFI3j59UItzOC60MamjgE56YlkZvcvdthhJr3P23eAMA/tg1BZDST4f9FU9suogGCCtE+/So0WDmyE+PqRX/oRq2QqwyVjwCtzSLl3TkilT"
set "B64=%B64%JbYTXkqppPi33qK352uss5QcMKA2lVwP7rub/u26EZdg69c4ZLj/HrApqVgwFhG7zoXiDVbcPCKx47Q7yI56Te8FhWndqVgwEGmNgv6EoykNE49W9K2vOjYSS0riqZ4oMoNpemQE4bI2fkZWU4xQawIA8mAanr4OKZfvyDFP0+FDOM5qafujhmm6BZZCvfOBck6jYMhv330cB1/TKJQdTH03vr0M0naFTLAhTOJlXQ3X9c9yWbVd1Zm2jio/Bc8EMy5LqBx+8rXK7CNsAHLvIIbfuO4xPrlj9k2aExLOhxsJdeoNfTVEjGILjaWvf4A6BoKEsqFAhl5GUSvN8ql/maSbT2ZiIcD+/RLqcbREIvYXyfoGe+PAGfWciUsJflAggvXY/iT1gc/FXTWU3LTPfjpqCkUlp2Kx+OVA8MpuBzh7eaWRKkb6UwPpft7oiHq+wSokKCIAmAoj9J5z0XAwYOrd2GMfDlq/rmT7NmuoKNdfQyv5al1yNYhxwOF3uhxrt9pIA2tJFzhj6wmRjt4bSYA9Im4CXIy78POp2DUpUd9gPRxUxWgG6SlsS6JH9L1ork+AaHvr0nu5roM1u7mwz8Ebh3phvi16NXaFq0I4apoO1ogsapL7d5qbvMz9jd4p/soEmHniIRRIBdxwkhTlOuYK+rWJ771WBfwRBG/vRUDnCAqgP5Tweb3Ney/m513qk1K9sZDft+daBxZ3LgWCQRxI8h/0HuTVHsf+W7DYAxIX8vOyz94bcLLuEt8Vjvu5BH7uehA42LDnahdfHQji2XuTRVsYDfRJ+yz9W/LPUiIJEuQ/5PHuTcCrficVqM6C5sX6Ghr2hhZg6PH/T687uA/DQaf7wmDALqXACCETtfEEVBtenUXtxbVci+JMzNqjycXPXl4kDJ3WTDHqbkegR4zk19HgdSAFRjieEqPX2m84GdVs/G6MXzv78E44yPBB+h4cyTLbrgOMJiHRI/C5zbv3xJejFh5ixUxLkivL70uFuxDI4UBgMuljpeKKOpqV05vV7WANh6r8sDfVF/msiRFfk0V5rV8yaHTUHJp2ouulAg9dZJrzsC7sQ/qcT0g90nXwWKfRzNWL3RCAAnJ+R/15r/tYwN3d4j558eaRgwMNDtvUNIUXfZ7O/iC4N93sCtbhm28Ssf548rzvoof3kg1Lu7v9Nuhm8JCfaK8R7F3g7WvQT8A8Xf/RohIufH5dcOiZIYXOPnrCxdVvsc3au5oVh2bapgl9dbmBJJG/ttQazI7ngNYLX3j4cxryo6c8euF9TKrn/pzO+ZnxPYC3y5gL868C8MxsXs6N8Uoi/zLB4AecGF1bkzMrlM1rrdfcYy7w8jB+MaD0aYk3erNUblNfT8k8TaKkWJn6IH98ai6x1Ts4bUzjQw7wUHy2znEh+Zvj8H9TFWJWNYykWPOuE7+HKVJ1JnvxSzd+KnzFtdiSuYT75a/NRXbfES9nvLZPrOjsv0ziUu89yJeIKLgGK+wZ7NnWlnNd37Izf2K2uFT0negEECc/lynNbTDuDzSJIm/s59k6FWFqFVEY4ugnkB1aosHrbcR9+pIp5pZbw9RbpCqs/j1RB8TKepsecg5qqiv3c6WtvIPyjspI1vwVVaq8UoGP32ibD6AorI5Kef8Xxu9Cxs4/gSz/q8kYxRl/0iGaGcN5DPoWk4XClgJlNawnW9pO/XtZPlD3v1HSg6z1QQAA"

:MENU
cls
echo ============================================================
echo    湖南大学 校园网自动保活   v1.0.4
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
