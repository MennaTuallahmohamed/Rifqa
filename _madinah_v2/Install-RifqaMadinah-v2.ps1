param(
  [string]$ProjectRoot = 'C:\Rifqa-main',
  [switch]$Preview
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ReadText([string]$Path) { [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) }
function WriteText([string]$Path, [string]$Value) {
  [IO.File]::WriteAllText($Path, $Value, (New-Object Text.UTF8Encoding($false)))
}
function AssertFile([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "FILE MISSING: $Path" }
}
function AssertJpeg([string]$Path) {
  AssertFile $Path
  $bytes = [IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -lt 3000 -or $bytes[0] -ne 255 -or $bytes[1] -ne 216 -or
      $bytes[$bytes.Length - 2] -ne 255 -or $bytes[$bytes.Length - 1] -ne 217) {
    throw "IMAGE INVALID: $Path"
  }
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  throw "PROJECT NOT FOUND: $ProjectRoot"
}
$screen = Join-Path $ProjectRoot 'lib\screens\madinah\madinah_screen.dart'
$yaml = Join-Path $ProjectRoot 'pubspec.yaml'
$source = $PSScriptRoot
$storyPath = Join-Path $source 'assets\data\madinah_cinematic\stories.json'
AssertFile $screen
AssertFile $yaml
AssertFile $storyPath

$requiredDart = @(
  'cinematic_theme.dart', 'cinematic_hub.dart', 'cinematic_tour.dart',
  'seerah_museum.dart', 'cinematic_salawat.dart'
)
foreach ($name in $requiredDart) {
  AssertFile (Join-Path $source "lib\screens\madinah\immersive\$name")
}
$stories = @((ReadText $storyPath | ConvertFrom-Json))
if ($stories.Count -ne 50) { throw "EXPECTED 50 STORIES, FOUND $($stories.Count)" }
foreach ($s in $stories) {
  if ([string]::IsNullOrWhiteSpace($s.title) -or [string]::IsNullOrWhiteSpace($s.source)) {
    throw 'Invalid story record - missing title or source'
  }
  $path = Join-Path $source ($s.cover.Replace('/', '\'))
  AssertJpeg $path
}
$sceneDir = Join-Path $source 'assets\images\madinah_cinematic\scenes'
$sceneImages = @(Get-ChildItem -LiteralPath $sceneDir -Filter '*.jpg' -File)
if ($sceneImages.Count -ne 7) { throw "EXPECTED 7 SCENE IMAGES, FOUND $($sceneImages.Count)" }
foreach ($f in $sceneImages) { AssertJpeg $f.FullName }

$original = ReadText $screen
$pubspec = ReadText $yaml
if ([regex]::Matches($pubspec, '(?m)^  assets:[ \t]*\r?$').Count -ne 1) {
  throw "pubspec.yaml MUST HAVE EXACTLY ONE '  assets:' ENTRY"
}
$methods = [ordered]@{
  '_openVirtualTour' = @'
  void _openVirtualTour() {
    _openPage(const MadinahImmersiveHub());
  }
'@
  '_openRawdah' = @'
  void _openRawdah() {
    _openPage(const CinematicTourScreen(kind: CinematicJourneyKind.rawdah));
  }
'@
  '_openStories' = @'
  void _openStories() {
    _openPage(const SeerahMuseumScreen());
  }
'@
  '_openSalawat' = @'
  void _openSalawat() {
    _openPage(const CinematicSalawatScreen());
  }
'@
}
foreach ($method in $methods.Keys) {
  $pattern = '(?ms)^  void ' + [regex]::Escape($method) + '\(\)\s*\{.*?^  \}'
  if ([regex]::Matches($original, $pattern).Count -ne 1) {
    throw "ROUTE ANCHOR CHANGED: $method. Nothing was installed."
  }
}
if (-not $original.Contains("import 'madinah_ui.dart';")) {
  throw 'Madinah import anchor missing; no files modified.'
}

Write-Host "Rifqa Cinematic v2 preflight passed - 50 stories + 57 images" -ForegroundColor Green
Write-Host "Project: $ProjectRoot"
Write-Host 'Patches ONLY: madinah_screen.dart, pubspec.yaml. Adds 5 Dart files and offline assets.'
if ($Preview) { Write-Host 'PREVIEW ONLY - no changes made.' -ForegroundColor Cyan; exit 0 }

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path $env:USERPROFILE "Rifqa-Backups\madinah-v2-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item -LiteralPath $screen -Destination (Join-Path $backup 'madinah_screen.dart')
Copy-Item -LiteralPath $yaml -Destination (Join-Path $backup 'pubspec.yaml')
$folders = @('lib\screens\madinah\immersive',
  'assets\images\madinah_cinematic', 'assets\data\madinah_cinematic')
foreach ($folder in $folders) {
  $from = Join-Path $source $folder
  $to = Join-Path $ProjectRoot $folder
  if (Test-Path -LiteralPath $to) {
    $backupTo = Join-Path $backup $folder
    New-Item -ItemType Directory -Force -Path (Split-Path $backupTo -Parent) | Out-Null
    Copy-Item -LiteralPath $to -Destination $backupTo -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $to | Out-Null
  Copy-Item -Path (Join-Path $from '*') -Destination $to -Recurse -Force
}

$imports = @(
  "import 'immersive/cinematic_hub.dart';",
  "import 'immersive/cinematic_tour.dart';",
  "import 'immersive/seerah_museum.dart';",
  "import 'immersive/cinematic_salawat.dart';"
)
foreach ($item in $imports) {
  if (-not $original.Contains($item)) {
    $original = $original.Replace("import 'madinah_ui.dart';", "import 'madinah_ui.dart';`r`n$item")
  }
}
foreach ($method in $methods.Keys) {
  $pattern = '(?ms)^  void ' + [regex]::Escape($method) + '\(\)\s*\{.*?^  \}'
  $original = ([regex]::new($pattern)).Replace($original, $methods[$method].TrimEnd(), 1)
}
# These imports have no remaining references once route handlers are replaced.
$oldImports = @(
  "import 'madinah_gate_experience.dart';",
  "import 'mosque/madinah_mosque_gallery.dart';",
  "import '../rawdah/rawdah_screen.dart';",
  "import 'stories/prophetic_stories_screen.dart';",
  "import 'salawat/salawat_library_screen.dart';",
  "import '../../models/madinah/prophetic_story.dart';"
)
foreach ($item in $oldImports) {
  $original = $original.Replace("$item`r`n", '').Replace("$item`n", '')
}
WriteText $screen $original

$assetsToAdd = @('    - assets/images/madinah_cinematic/',
                '    - assets/data/madinah_cinematic/')
$add = @($assetsToAdd | Where-Object { -not $pubspec.Contains($_.Trim()) })
if ($add.Count -gt 0) {
  $start = $pubspec.IndexOf('  assets:')
  $end = $pubspec.IndexOf("`n", $start)
  if ($end -lt 0) { throw 'pubspec assets line must have a newline' }
  $pubspec = $pubspec.Insert($end + 1, (($add -join "`r`n") + "`r`n"))
  WriteText $yaml $pubspec
}

$projectImages = Join-Path $ProjectRoot 'assets\images\madinah_cinematic'
$copied = @(Get-ChildItem -LiteralPath $projectImages -Recurse -File -Filter '*.jpg')
if ($copied.Count -lt 57) { throw "COPY FAILED: expected at least 57 images, found $($copied.Count)" }
foreach ($file in $copied) { AssertJpeg $file.FullName }
Write-Host 'SUCCESS - Images, 50 stories, routes and salawat installed.' -ForegroundColor Green
Write-Host "BACKUP: $backup" -ForegroundColor Cyan
Write-Host 'REQUIRED NEXT: flutter clean ; flutter pub get ; flutter analyze ; flutter run'
