param(
 [Parameter(Mandatory=$true)][string]$Godot,
 [ValidateSet('All','Core','UI')][string]$Group='All'
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$evidenceDir=Join-Path $projectRoot 'builds/pc-qa'
New-Item -ItemType Directory -Force $evidenceDir | Out-Null
$suites=@(
 @('run','test-results.json','Core'),@('extended','extended-results.json','Core'),
 @('skills','skills-test-results.json','Core'),@('greywake','greywake-test-results.json','Core'),
 @('opening_flow','opening-flow-results.json','Core'),@('greywake_island','island-test-results.json','Core'),
 @('greywake_dockside','dockside-test-results.json','Core'),@('assets','asset-test-results.json','Core'),
 @('battle_ui','battle-ui-results.json','Core'),@('tavern_selection','tavern-selection-results.json','Core'),@('desktop_settings','desktop-settings-results.json','Core'),@('pc_camera','pc-camera-results.json','Core'),
 @('ui_smoke','ui-test-results.json','UI'),@('skills_ui','skills-ui-results.json','UI'),
 @('greywake_ui','greywake-ui-results.json','UI'),@('opening_ui','opening-ui-results.json','UI'),
 @('scene_art_ui','scene-art-ui-results.json','UI'),@('pc_vertical_slice','pc-vertical-slice-results.json','UI'),
 @('pc_render_benchmark','pc-render-benchmark-results.json','UI'),@('pc_native_probe','pc-native-probe-results.json','UI')
)
$records=@()
Push-Location $projectRoot
try {
 foreach($suite in $suites){
  if($Group -ne 'All' -and $suite[2] -ne $Group){continue}
  $name=$suite[0];$log=Join-Path $evidenceDir ($name+'.log')
  $arguments=@('--path',$projectRoot)
  if($suite[2] -eq 'Core'){$arguments+='--headless'}
  if($name -eq 'pc_native_probe'){$arguments+='tests/pc_native_probe.tscn'}else{$arguments+=@('--script',('tests/'+$name+'.gd'))}
  & $Godot @arguments *> $log
  $code=$LASTEXITCODE
  $body=Get-Content -Raw $log
  if($code -ne 0 -or $body -match '(?m)(SCRIPT ERROR:|^ERROR:)'){throw "$name failed with exit $code; inspect $log"}
  $report=Get-Content -Raw $suite[1] | ConvertFrom-Json
  if($name -eq 'pc_native_probe'){
   if(-not $report.normal_scene_mainloop -or $report.frames -ne 120){throw 'Native probe incomplete'}
  }elseif($null -eq $report.failed -or $report.failed -ne 0){throw "$name assertions failed"}
  $records+=@{suite=$name;exit_code=$code;failed=0;report=$suite[1];log=('builds/pc-qa/'+$name+'.log');checked_at=(Get-Date).ToString('o')}
  Write-Output "$name : exit 0, zero errors/failures"
 }
 $records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidenceDir ($Group.ToLower()+'-runs.json'))
} finally {Pop-Location}
