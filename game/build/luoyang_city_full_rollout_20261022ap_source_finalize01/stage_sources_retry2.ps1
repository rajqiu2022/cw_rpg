param(
 [Parameter(Mandatory=$true)][string]$InputPath,
 [string]$InputSha256,
 [switch]$InspectPlan
)
$ErrorActionPreference='Stop'
$runnerPath=Join-Path $PSScriptRoot 'stage_sources_retry2.py'
if($InspectPlan){
 & python -X utf8 $runnerPath $InputPath --inspect-plan
}else{
 if($InputSha256 -cnotmatch '^[0-9a-f]{64}$'){throw 'ROOT_LOCKED_INPUT_EXTERNAL_SHA_REQUIRED'}
 & python -X utf8 $runnerPath $InputPath --input-sha256 $InputSha256
}
if($LASTEXITCODE -ne 0){throw "ROOT_ONLY_SOURCE_STAGE_FAILED:$LASTEXITCODE"}
