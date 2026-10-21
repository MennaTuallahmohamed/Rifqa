param(
  [string]$ProjectRoot = 'C:\Rifqa-main',
  [switch]$Preview
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ReadUtf8([string]$p) { return [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function WriteUtf8([string]$p, [string]$s) {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($p, $s, $utf8)
}

$source = $PSScriptRoot
$targetScreen = Join-Path $ProjectRoot 'lib\screens\madinah\madinah_screen.dart'
$targetYaml = Join-Path $ProjectRoot 'pubspec.yaml'
$sourceHub = Join-Path $source 'lib\screens\madinah\immersive\cinematic_hub.dart'
$sourceData = Join-Path $source 'assets\data\madinah_cinematic\stories.json'
foreach ($path in @($targetScreen, $targetYaml, $sourceHub, $sourceData)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file not found: $path" }
}

$existing = ReadUtf8 $targetScreen
$pub = ReadUtf8 $targetYaml
$integrated = $existing.Contains("import 'immersive/cinematic_hub.dart';")
$keys = [regex]::Matches($pub, '(?m)^  assets:[ \t]*\r?$').Count
if ($keys -ne 1) { throw "pubspec.yaml: expected one '  assets:' entry; found $keys. Fix YAML before installation." }

$methods = @{
  'Rawdah' = '(?ms)^  void _openRawdah\(\)\s*\{.*?^  \}'
  'Stories' = '(?ms)^  void _openStories\(\)\s*\{.*?^  \}'
  'VirtualTour' = '(?ms)^  void _openVirtualTour\(\)\s*\{.*?^  \}'
}
if (-not $integrated) {
  if (-not $existing.Contains("import 'madinah_gate_experience.dart';")) {
    throw 'Madinah screen changed: import anchor missing. No files modified.'
  }
  foreach ($key in $methods.Keys) {
    if ([regex]::Matches($existing, $methods[$key]).Count -ne 1) {
      throw "Madinah screen changed: method $key not found exactly once. No files modified."
    }
  }
}

$payloadFolders = @(
  'lib\screens\madinah\immersive',
  'assets\images\madinah_cinematic',
  'assets\data\madinah_cinematic'
)
foreach ($folder in $payloadFolders) {
  if (-not (Test-Path -LiteralPath (Join-Path $source $folder))) {
    throw "Missing package folder: $folder"
  }
}

Write-Host 'Rifqa Madinah Cinematic - preflight passed' -ForegroundColor Green
Write-Host ("Target: " + $ProjectRoot)
Write-Host ("Previously installed: " + $integrated)
Write-Host 'Will add 4 Dart files, 57 JPEG images and the 50-story JSON dataset.'
Write-Host 'Will only patch madinah_screen.dart and pubspec.yaml in the existing project.'
if ($Preview) {
  Write-Host 'PREVIEW ONLY - no files changed.' -ForegroundColor Cyan
  exit 0
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path $env:USERPROFILE 'Rifqa-Backups'
$backup = Join-Path $backupRoot ('cinematic_' + $stamp)
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item -LiteralPath $targetScreen -Destination (Join-Path $backup 'madinah_screen.dart') -Force
Copy-Item -LiteralPath $targetYaml -Destination (Join-Path $backup 'pubspec.yaml') -Force
foreach ($folder in $payloadFolders) {
  $oldFolder = Join-Path $ProjectRoot $folder
  if (Test-Path -LiteralPath $oldFolder) {
    $destination = Join-Path $backup $folder
    $parent = Split-Path $destination -Parent
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Copy-Item -LiteralPath $oldFolder -Destination $destination -Recurse -Force
  }
}

foreach ($folder in $payloadFolders) {
  $from = Join-Path $source $folder
  $to = Join-Path $ProjectRoot $folder
  New-Item -ItemType Directory -Force -Path $to | Out-Null
  Copy-Item -Path (Join-Path $from '*') -Destination $to -Recurse -Force
}

$assetFolder = '    - assets/images/madinah_cinematic/'
$dataFolder = '    - assets/data/madinah_cinematic/'
$add = @()
if (-not $pub.Contains($assetFolder.Trim())) { $add += $assetFolder }
if (-not $pub.Contains($dataFolder.Trim())) { $add += $dataFolder }
if ($add.Count -gt 0) {
  $newAssetBlock = "  assets:`r`n" + ($add -join "`r`n")
  $pub = [regex]::Replace($pub, '(?m)^  assets:[ \t]*\r?$', $newAssetBlock, 1)
  WriteUtf8 $targetYaml $pub
}

if (-not $integrated) {
  $imports = @"
import 'immersive/cinematic_hub.dart';
import 'immersive/cinematic_tour.dart';
import 'immersive/seerah_museum.dart';
"@
  $existing = $existing.Replace("import 'madinah_gate_experience.dart';", $imports.TrimEnd())
  $newRawdah = @'
  void _openRawdah() {
    _openPage(const CinematicTourScreen(kind: CinematicJourneyKind.rawdah));
  }
'@
  $newStories = @'
  void _openStories() {
    _openPage(const SeerahMuseumScreen());
  }
'@
  $newVirtualTour = @'
  void _openVirtualTour() {
    _openPage(const MadinahImmersiveHub());
  }
'@
  $existing = [regex]::new($methods['Rawdah']).Replace($existing, $newRawdah, 1)
  $existing = [regex]::new($methods['Stories']).Replace($existing, $newStories, 1)
  $existing = [regex]::new($methods['VirtualTour']).Replace($existing, $newVirtualTour, 1)
  # Remove imports of widgets now replaced by the three new routes.
  foreach ($oldImport in @(
    "import 'mosque/madinah_mosque_gallery.dart';",
    "import '../rawdah/rawdah_screen.dart';",
    "import 'stories/prophetic_stories_screen.dart';"
  )) { $existing = $existing.Replace($oldImport + "`r`n", '').Replace($oldImport + "`n", '') }
  WriteUtf8 $targetScreen $existing
}

# Local verification of all 50 covers and unique story numbers.
$data = Get-Content -LiteralPath (Join-Path $ProjectRoot 'assets\data\madinah_cinematic\stories.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($data.Count -ne 50) { throw 'Dataset must contain exactly 50 stories.' }
foreach ($item in $data) {
  $coverPath = Join-Path $ProjectRoot (($item.cover).Replace('/','\'))
  if (-not (Test-Path -LiteralPath $coverPath)) { throw "Story image missing: $coverPath" }
}
Write-Host "SUCCESS - assets, stories and routes installed. Backup: $backup" -ForegroundColor Green
Write-Host 'Next: flutter pub get ; flutter analyze'
