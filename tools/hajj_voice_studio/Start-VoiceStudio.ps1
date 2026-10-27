#requires -Version 5.1
# Offline localhost web server to give Chromium microphone & directory permissions.
param([int]$Port=8765)
$ErrorActionPreference='Stop'
$path=Join-Path $PSScriptRoot 'voice_studio.html'
if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing $path"}
$listener=[System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback,$Port)
$listener.Start()
$url="http://127.0.0.1:$Port/voice_studio.html"
Write-Host "Voice Studio: $url" -ForegroundColor Green
Write-Host 'No data is sent to the internet. Press Ctrl+C to stop this local server.'
Start-Process $url
try{
 while($true){
  $client=$listener.AcceptTcpClient()
  try {
   $client.ReceiveTimeout=5000
   $stream=$client.GetStream()
   $reader=New-Object System.IO.StreamReader($stream,[Text.Encoding]::ASCII,$false,1024,$true)
   $line=$reader.ReadLine()
   while(($h=$reader.ReadLine()) -ne $null -and $h -ne ''){}
   $valid=$line -match '^GET\s+/voice_studio\.html(?:\?[^\s]*)?\s+HTTP/' -or $line -match '^GET\s+/\s+HTTP/'
   if($valid){
    $body=[IO.File]::ReadAllBytes($path)
    $head="HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`nCache-Control: no-store`r`n`r`n"
   } else {
    $body=[Text.Encoding]::UTF8.GetBytes('Not found')
    $head="HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
   }
   $headerBytes=[Text.Encoding]::ASCII.GetBytes($head)
   $stream.Write($headerBytes,0,$headerBytes.Length)
   $stream.Write($body,0,$body.Length)
   $stream.Flush()
  } catch { Write-Host "Request skipped: $($_.Exception.Message)" -ForegroundColor DarkYellow }
  finally {$client.Close()}
 }
} finally {$listener.Stop()}
