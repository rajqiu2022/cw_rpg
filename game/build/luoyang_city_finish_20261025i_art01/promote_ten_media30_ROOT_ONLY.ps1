param(
 [Parameter(Mandatory=$true)][string]$PlanSha256,
 [string]$ExecuteReviewedScriptSha256
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$game='F:/Code/RPG_GAME/game'
$isolate='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/ten_media_isolate_ROOT_PREPARED'
$taskRoot='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01'
$planPath="$taskRoot/ten_media30_promotion_plan01_CANDIDATE.json"
$receiptPath="$taskRoot/ten_media30_promotion_ROOT_EXECUTED.json"
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Within([string]$p,[string]$parent){[IO.Path]::GetFullPath($p).StartsWith([IO.Path]::GetFullPath($parent)+'\',[StringComparison]::OrdinalIgnoreCase)}
function Fact([string]$p){
 if(!(Test-Path -LiteralPath $p)){return @{exists=$false}}
 $s=Get-Item -LiteralPath $p
 return @{exists=$true;sha256=(Sha $p);bytes=$s.Length;ticks=[string]$s.LastWriteTimeUtc.Ticks}
}
function SameFact($a,$b){
 if($a.exists -ne $b.exists){return $false}
 if(!$a.exists){return $true}
 return $a.sha256 -ceq $b.sha256 -and $a.bytes -eq $b.bytes -and $a.ticks -ceq $b.ticks
}
if((Sha $planPath) -cne $PlanSha256.ToLowerInvariant()){throw 'ROOT_REVIEWED_FIXED_PLAN_REQUIRED'}
$plan=Get-Content -LiteralPath $planPath -Raw|ConvertFrom-Json -AsHashtable
$selfPath=$MyInvocation.MyCommand.Path
if($plan.status -cne 'TEN_NEW_MEDIA30_MECHANICAL_PROMOTION_CANDIDATE_NOT_EXECUTED' -or $plan.builder_sha256 -cne (Sha $selfPath) -or $plan.leaves.Count -ne 30){throw 'FIXED_THIRTY_NEW_MEDIA_PLAN_ONLY'}
if($ExecuteReviewedScriptSha256 -and $ExecuteReviewedScriptSha256.ToLowerInvariant() -cne (Sha $selfPath)){throw 'ROOT_REVIEWED_PROMOTER_SHA_REQUIRED'}
foreach($inputRow in $plan.fixed_inputs){if((Sha $inputRow.path) -cne $inputRow.sha256){throw 'FROZEN_RESULT_PREPARED_INGRESS_PROCESS_CHANGED'}}
$r=Get-Content -LiteralPath "$isolate/ten_media_import_result_104068.json" -Raw|ConvertFrom-Json -AsHashtable
if(!$r.passed -or $r.failures.Count -ne 0 -or $r.rows.Count -ne 10 -or $r.scope -cne 'ONLY_TEN_FIXED_MIXED_ALPHA_LUOYANG_MEDIA_ISOLATED_FULL_RGBA_NOT_RUNTIME' -or $r.prepared_sha256 -cne '061081ea928e7d195cd2196b589f1bf974f91a3bae46c30b5f0123600a55f960'){throw 'EXACT_TEN_MEDIA_FULL_RGBA_PASS_REQUIRED'}
foreach($processName in @('external_import_actual_process_receipt.json','external_verify_actual_process_receipt.json')){
 $p=Get-Content -LiteralPath "$taskRoot/ten_media_import_logs_ROOT_ONLY/$processName" -Raw|ConvertFrom-Json -AsHashtable
 if($p.actual_natural_console_exit_code -ne 0 -or !$p.retained_process_WaitForExit -or $p.stopped_by_tool -or $p.main_promotion){throw 'BOTH_REAL_NATURAL_PROCESS_EXITS_REQUIRED'}
}
foreach($p in $plan.protected_before.Keys){if(!(SameFact (Fact $p) $plan.protected_before[$p])){throw "PROTECTED_SOURCE_BYTES_TICKS_CHANGED: $p"}}
if(Test-Path -LiteralPath $receiptPath){throw 'PRESERVE_PRIOR_PROMOTION_RECEIPT'}
$targets=@()
foreach($leaf in $plan.leaves){
 if(!(Within $leaf.source $isolate) -or !(Within $leaf.target $game) -or (Test-Path -LiteralPath $leaf.target)){throw 'NEW_EXACT_THIRTY_MAIN_LEAVES_ABSENT_REQUIRED'}
 if((Sha $leaf.source) -cne $leaf.sha256 -or (Get-Item -LiteralPath $leaf.source).Length -ne $leaf.bytes){throw 'FIXED_ISOLATE_BYTES_CHANGED'}
 $targets+=,$leaf.target
}
if(@($targets|Select-Object -Unique).Count -ne 30){throw 'EXACT_THIRTY_UNIQUE_ORDERED_TARGETS'}
if(!$ExecuteReviewedScriptSha256){@{status='ROOT_ONLY_THIRTY_PROMOTION_DRY_NO_COPY';leaves=30;all_targets_ABSENT=$true;plan_sha256=(Sha $planPath);builder_sha256=(Sha $selfPath);engine_calls=0;copies=0}|ConvertTo-Json -Compress;exit 0}
# The copy loop is the mature25h CreateNew stream copy: never overwrite/delete.
$written=@();$failure=$null;$protectedAfter=@{};$protectedUnchanged=$true
try{
 foreach($leaf in $plan.leaves){
  [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($leaf.target))
  $inputStream=[IO.File]::OpenRead($leaf.source)
  try{$outputStream=[IO.File]::Open($leaf.target,[IO.FileMode]::CreateNew);try{$inputStream.CopyTo($outputStream)}finally{$outputStream.Dispose()}}finally{$inputStream.Dispose()}
  if((Sha $leaf.target) -cne $leaf.sha256 -or (Get-Item -LiteralPath $leaf.target).Length -ne $leaf.bytes){throw 'STOP_PARTIAL_NEW_COPY_NO_OVERWRITE_OR_DELETE'}
  $written+=,@{path=$leaf.target;sha256=$leaf.sha256;bytes=$leaf.bytes;ticks=[string](Get-Item -LiteralPath $leaf.target).LastWriteTimeUtc.Ticks}
 }
}catch{$failure=$_.Exception.Message}
foreach($p in $plan.protected_before.Keys){$protectedAfter[$p]=Fact $p;if(!(SameFact $protectedAfter[$p] $plan.protected_before[$p])){$protectedUnchanged=$false}}
$passed=$null -eq $failure -and $written.Count -eq 30 -and $protectedUnchanged
$receipt=@{passed=$passed;status=$(if($passed){'THIRTY_NEW_MEDIA_LEAVES_PROMOTED_NOT_RUNTIME_BOUND'}else{'PARTIAL_OR_PROTECTION_FAILURE_RETAIN_ALL_NEW_FILES_DO_NOT_OVERWRITE_OR_DELETE'});failure=$failure;plan_sha256=(Sha $planPath);builder_sha256=(Sha $selfPath);fixed_inputs=$plan.fixed_inputs;written=$written;protected_first=$plan.protected_before;protected_final=$protectedAfter;all_protected_SHA_bytes_exactticks_unchanged=$protectedUnchanged;old_sources_overwritten=0;source_files_deleted=0;main_project_import=$false;engine_calls=0;functional_GD_JSON_active_index_changed=$false;pixel_edits=0;runtime_adoption=$false;retained_import_raw_image_warnings=10;import_verify_not_claimed_clean=$true}
$stream=[IO.File]::Open($receiptPath,[IO.FileMode]::CreateNew);$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($receipt|ConvertTo-Json -Depth 20)+"`n")}finally{$writer.Dispose()}
@{receipt=$receiptPath;sha256=(Sha $receiptPath);new_leaves=$written.Count;passed=$passed}|ConvertTo-Json -Compress
if(!$passed){throw 'PROMOTION_FAILED_RETAIN_PARTIAL_NEW_LEAVES_AND_PRECISE_RECEIPT_NO_RETRY'}
