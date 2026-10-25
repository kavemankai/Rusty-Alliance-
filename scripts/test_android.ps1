param(
 [Parameter(Mandatory=$true)][string]$AndroidSdk,
 [Parameter(Mandatory=$true)][string]$JavaHome,
 [Parameter(Mandatory=$true)][string]$Output,
 [string]$Serial='emulator-5554',
 [string]$Apk,
 [string]$Fixture
)
$ErrorActionPreference='Stop'
$adb=Join-Path $AndroidSdk 'platform-tools/adb.exe'
& (Join-Path $PSScriptRoot 'prepare_android_qa.ps1') -AndroidSdk $AndroidSdk -JavaHome $JavaHome -Serial $Serial -Apk $Apk
function Run-QA([string]$Script,[string[]]$Arguments) {
 & python (Join-Path $PSScriptRoot $Script) --adb $adb --serial $Serial --output $Output @Arguments
 if ($LASTEXITCODE -ne 0) { throw "$Script failed; do not deliver this candidate." }
}
Run-QA 'android_smoke.py' @('--scenario','basic')
Run-QA 'android_smoke.py' @('--scenario','gestures')
Run-QA 'android_tactical_smoke.py' @()
Run-QA 'android_smoke.py' @('--scenario','lifecycle')
Run-QA 'android_cutout_smoke.py' @()
if ($Fixture) { Run-QA 'android_scale_smoke.py' @('--fixture',$Fixture) }
Write-Output 'ANDROID QA: all requested emulator scenarios passed.'
