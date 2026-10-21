param(
  [string]$ProjectRoot='C:\Rifqa-main',
  [Parameter(Mandatory=$true)][string]$BackupFolder
)
$ErrorActionPreference = 'Stop'
$files = @(
  @('madinah_screen.dart','lib\screens\madinah\madinah_screen.dart'),
  @('pubspec.yaml','pubspec.yaml')
)
foreach ($f in $files) {
  $source = Join-Path $BackupFolder $f[0]
  if (-not (Test-Path -LiteralPath $source)) { throw "Backup missing: $source" }
  Copy-Item -LiteralPath $source -Destination (Join-Path $ProjectRoot $f[1]) -Force
}
Write-Host 'Restored original madinah_screen.dart and pubspec.yaml.' -ForegroundColor Green
Write-Host 'New cinematic folders remain on disk; delete them manually if desired.'
