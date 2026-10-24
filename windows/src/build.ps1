# 把 keepalive.ps1 + menu.template.bat 打包成单文件 HNU-Portal.bat（GBK 编码）
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$ps1  = Join-Path $here 'keepalive.ps1'
$tpl  = Join-Path $here 'menu.template.bat'
$out  = Join-Path $here 'HNU-Portal.bat'

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

# 分块，兼容 BAT 的 8191 字符行/变量长度限制
$chunkSize = 1800
$lines = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $b64.Length; $i += $chunkSize) {
    $len = [Math]::Min($chunkSize, $b64.Length - $i)
    $chunk = $b64.Substring($i, $len)
    if ($i -eq 0) { $lines.Add("set `"B64=$chunk`"") }
    else          { $lines.Add("set `"B64=%B64%$chunk`"") }
}

$text = [System.IO.File]::ReadAllText($tpl, [System.Text.Encoding]::UTF8)
# cmd.exe 需要 CRLF，先归一化
$text = $text -replace "`r`n", "`n"
$text = $text -replace "`n", "`r`n"
$text = $text.Replace('{{CHUNKS}}', ($lines -join "`r`n"))

# BAT 必须是 GBK(936)，cmd.exe 在中文 Windows 下才能正确显示中文
$gbk = [System.Text.Encoding]::GetEncoding(936)
[System.IO.File]::WriteAllText($out, $text, $gbk)

Write-Output ("PS1原始字节 = " + $bytes.Length)
Write-Output ("gzip后     = " + $compressed.Length)
Write-Output ("base64长度 = " + $b64.Length + "  分 " + $lines.Count + " 行")
Write-Output ("BAT输出    = " + $out + "  (" + (Get-Item $out).Length + " 字节, GBK)")

# 回环校验：把 BAT 里的 B64 取出来解压，确认与原 PS1 完全一致
$batText = [System.IO.File]::ReadAllText($out, $gbk)
$m = [regex]::Matches($batText, 'set "B64=(?:%B64%)?([A-Za-z0-9+/=]+)"')
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
