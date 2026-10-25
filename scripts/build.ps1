param(
 [string]$Godot = 'godot',
 [string]$AndroidSdk = $env:ANDROID_HOME,
 [string]$JavaHome = $env:JAVA_HOME,
 [switch]$SkipUi
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$buildRoot = Join-Path $projectRoot 'builds'
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
function Invoke-GodotChecked([string[]]$GodotArguments) {
 $captured = & $Godot @GodotArguments 2>&1
 $code = $LASTEXITCODE
 $captured | Out-Host
 if ($code -ne 0 -or ($captured | Select-String 'SCRIPT ERROR:|^ERROR:|FAIL:')) {
  throw "Godot validation failed (exit $code)."
 }
}
$version = & $Godot --version
if ($version -notmatch '^4\.6\.2\.stable' -or $version -match 'mono') {
 throw 'Use the standard Godot 4.6.2 executable, with its matching Android export template.'
}
if (-not $AndroidSdk -or -not $JavaHome) {
 $editorSettings = Join-Path $env:APPDATA 'Godot/editor_settings-4.6.tres'
 if (Test-Path -LiteralPath $editorSettings) {
  $settingsText = Get-Content -LiteralPath $editorSettings -Raw
  if (-not $AndroidSdk -and $settingsText -match 'export/android/android_sdk_path = "([^"]+)"') { $AndroidSdk = $Matches[1] }
  if (-not $JavaHome -and $settingsText -match 'export/android/java_sdk_path = "([^"]+)"') { $JavaHome = $Matches[1] }
 }
}
if (-not $AndroidSdk -or -not $JavaHome) { throw 'Supply AndroidSdk and JavaHome or configure Godot editor Android settings.' }
$env:JAVA_HOME = $JavaHome
$env:Path = (Join-Path $JavaHome 'bin') + [IO.Path]::PathSeparator + $env:Path
Invoke-GodotChecked @('--headless','--path',$projectRoot,'--editor','--import','--quit')
Invoke-GodotChecked @('--headless','--path',$projectRoot,'--script','tests/run.gd')
Invoke-GodotChecked @('--headless','--path',$projectRoot,'--script','tests/extended.gd')
if (-not $SkipUi) { Invoke-GodotChecked @('--path',$projectRoot,'--script','tests/ui_smoke.gd') }
Invoke-GodotChecked @('--headless','--path',$projectRoot,'--export-debug','Android','builds/broken-marches-debug.apk')
$signer = Join-Path $AndroidSdk 'build-tools/35.0.1/apksigner.bat'
& $signer verify --verbose (Join-Path $buildRoot 'broken-marches-debug.apk')
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $buildRoot 'broken-marches-debug.apk')
