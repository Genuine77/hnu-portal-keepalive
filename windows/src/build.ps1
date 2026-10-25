# 把 keepalive.ps1 + menu.template.bat 打包成单文件 HNU-Portal.bat（GBK 编码）
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
#
# 关键约束：cmd.exe 单条命令行上限 8191 字符。
# 因此 base64 必须切成多片、每片只出现在自己那一行，
# 绝不能让任何一行包含"整段 base64 展开后"的内容。
# 构建结束会逐行校验，超限直接报错，避免把这个坑带到发布包里。

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$ps1  = Join-Path $here 'keepalive.ps1'
$tpl  = Join-Path $here 'menu.template.bat'
$out  = Join-Path $here 'HNU-Portal.bat'

$LIMIT = 8191

$bytes = [System.IO.File]::ReadAllBytes($ps1)
# 确保 UTF-8 BOM，避免 PowerShell 5.1 按 ANSI 解码导致中文乱码
if (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) {
    $bom = [byte[]](0xEF,0xBB,0xBF)
    $bytes = $bom + $bytes
}

# gzip 压缩
$ms = New-Object System.IO.MemoryStream
$gz = New-Object System.IO.Compression.GzipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
$gz.Write($bytes, 0, $bytes.Length)
$gz.Close()
$compressed = $ms.ToArray()

$b64 = [Convert]::ToBase64String($compressed)

# 分片：每片 1800 字符，远低于 8191
$chunkSize = 1800
$defs  = New-Object System.Collections.Generic.List[string]
$writes = New-Object System.Collections.Generic.List[string]
$n = 0
for ($i = 0; $i -lt $b64.Length; $i += $chunkSize) {
    $n++
    $len   = [Math]::Min($chunkSize, $b64.Length - $i)
    $chunk = $b64.Substring($i, $len)
    # 定义片：单独一行赋值，便于后面逐行写文件
    $defs.Add("set `"P$n=$chunk`"")
    # 写片：追加到临时文件。base64 字母表只有 A-Za-z0-9+/=，不含 cmd 元字符
    $writes.Add(">>`"%B64F%`" echo %P$n%")
}

$text = [System.IO.File]::ReadAllText($tpl, [System.Text.Encoding]::UTF8)
# cmd.exe 需要 CRLF，先归一化
$text = $text -replace "`r`n", "`n"
$text = $text -replace "`n", "`r`n"
$text = $text.Replace('{{CHUNKS}}', ($defs   -join "`r`n"))
$text = $text.Replace('{{WRITE}}',  ($writes -join "`r`n"))

# 构建前自检：任何一行都不得接近 cmd 上限
$tooLong = @()
$idx = 0
foreach ($ln in ($text -split "`r`n")) {
    $idx++
    if ($ln.Length -ge $LIMIT) { $tooLong += "  第 $idx 行 $($ln.Length) 字符" }
}
if ($tooLong.Count -gt 0) {
    Write-Output "构建失败：以下行超过 cmd 的 $LIMIT 字符上限"
    $tooLong | ForEach-Object { Write-Output $_ }
    exit 1
}

# BAT 必须是 GBK(936)，cmd.exe 在中文 Windows 下才能正确显示中文
$gbk = [System.Text.Encoding]::GetEncoding(936)
[System.IO.File]::WriteAllText($out, $text, $gbk)

Write-Output ("PS1原始字节 = " + $bytes.Length)
Write-Output ("gzip后     = " + $compressed.Length)
Write-Output ("base64长度 = " + $b64.Length + "  分 " + $n + " 片")
Write-Output ("最长一行   = " + (($text -split "`r`n" | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum) + " 字符（上限 " + $LIMIT + "）")
Write-Output ("BAT输出    = " + $out + "  (" + (Get-Item $out).Length + " 字节, GBK)")

# 回环校验：把 BAT 里的分片重新拼起来解压，确认与原 PS1 完全一致
$batText = [System.IO.File]::ReadAllText($out, $gbk)
$m = [regex]::Matches($batText, 'set "P\d+=([A-Za-z0-9+/=]+)"')
$rebuilt = ($m | ForEach-Object { $_.Groups[1].Value }) -join ''
$dec = [Convert]::FromBase64String($rebuilt)
$ms2 = New-Object System.IO.MemoryStream(,$dec)
$gz2 = New-Object System.IO.Compression.GzipStream($ms2, [System.IO.Compression.CompressionMode]::Decompress)
$out2 = New-Object System.IO.MemoryStream
$gz2.CopyTo($out2)
$roundtrip = $out2.ToArray()

$same = ($roundtrip.Length -eq $bytes.Length)
if ($same) {
    for ($i = 0; $i -lt $bytes.Length; $i++) { if ($roundtrip[$i] -ne $bytes[$i]) { $same = $false; break } }
}
Write-Output ("回环校验   = " + $(if ($same) { "通过（" + $roundtrip.Length + " 字节完全一致）" } else { "失败" }))
if (-not $same) { exit 1 }
