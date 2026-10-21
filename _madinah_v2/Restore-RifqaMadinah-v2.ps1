param(
  [string]$ProjectRoot = 'C:\Rifqa-main',
  [Parameter(Mandatory = $true)] [string]$BackupFolder
)
$ErrorActionPreference = 'Stop'
foreach ($file in @('madinah_screen.dart','pubspec.yaml')) {
  $source = Join-Path $BackupFolder $file
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "BACKUP MISSING: $source" }
}
Copy-Item -LiteralPath (Join-Path $BackupFolder 'madinah_screen.dart') -Destination (Join-Path $ProjectRoot 'lib\screens\madinah\madinah_screen.dart') -Force
Copy-Item -LiteralPath (Join-Path $BackupFolder 'pubspec.yaml') -Destination (Join-Path $ProjectRoot 'pubspec.yaml') -Force
foreach ($folder in @('lib\screens\madinah\immersive','assets\images\madinah_cinematic','assets\data\madinah_cinematic')) {
  $source = Join-Path $BackupFolder $folder
  if (Test-Path -LiteralPath $source) {
    $target = Join-Path $ProjectRoot $folder
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force
  }
}
Write-Host 'Previous screen and pubspec restored. Existing newer assets have NOT been deleted.' -ForegroundColor Green
Write-Host 'Run flutter clean ; flutter pub get ; flutter analyze'
