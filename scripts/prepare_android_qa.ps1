param(
 [Parameter(Mandatory=$true)][string]$AndroidSdk,
 [Parameter(Mandatory=$true)][string]$JavaHome,
 [string]$Serial='emulator-5554',
 [string]$Apk
)
$ErrorActionPreference='Stop'
if ($Serial -notmatch '^emulator-\d+$') { throw 'Use a dedicated emulator for this automated scenario.' }
$projectRoot=Split-Path $PSScriptRoot -Parent
if (-not $Apk) { $Apk=Join-Path $projectRoot 'builds/broken-marches-debug.apk' }
$qaRoot=Join-Path $projectRoot 'builds/android-qa'
$classRoot=Join-Path $qaRoot 'classes'
$dexRoot=Join-Path $qaRoot 'dex'
New-Item -ItemType Directory -Force $classRoot,$dexRoot | Out-Null
$env:JAVA_HOME=$JavaHome
$adb=Join-Path $AndroidSdk 'platform-tools/adb.exe'
function Assert-Native([string]$Step) { if ($LASTEXITCODE -ne 0) { throw "$Step failed (exit $LASTEXITCODE)" } }
& (Join-Path $JavaHome 'bin/javac.exe') -classpath (Join-Path $AndroidSdk 'platforms/android-35/android.jar') -d $classRoot (Join-Path $PSScriptRoot 'android/MarchesGesture.java')
Assert-Native 'Gesture helper compilation'
& (Join-Path $AndroidSdk 'build-tools/35.0.1/d8.bat') --min-api 24 --lib (Join-Path $AndroidSdk 'platforms/android-35/android.jar') --output $dexRoot (Join-Path $classRoot 'MarchesGesture.class')
Assert-Native 'Gesture helper conversion'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar=Join-Path $qaRoot ('marches-gesture-'+[guid]::NewGuid().ToString('N')+'.jar')
[IO.Compression.ZipFile]::CreateFromDirectory($dexRoot,$jar)
& $adb -s $Serial wait-for-device
Assert-Native 'Emulator availability'
& $adb -s $Serial install -r $Apk
Assert-Native 'APK installation'
& $adb -s $Serial shell run-as org.brokenmarches.foundation mkdir -p files
Assert-Native 'QA directory creation'
& $adb -s $Serial shell run-as org.brokenmarches.foundation touch files/mobile-qa.enabled
Assert-Native 'Read-only observer opt-in'
& $adb -s $Serial push $jar /data/local/tmp/marches-gesture.jar
Assert-Native 'OS gesture helper deployment'
& $adb -s $Serial shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p org.brokenmarches.foundation
Assert-Native 'Android launcher'
Write-Output 'Dedicated emulator ready. Dismiss the Android full-screen first-launch hint if present, then run android_smoke.py basic, gestures, android_tactical_smoke.py, and android_smoke.py lifecycle.'
