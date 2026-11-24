param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$AuthorizationSha256,
    [string]$Authorization=(Join-Path $PSScriptRoot 'ROOT_AUTHORIZATION_REVIEW_READY.json'),
    [string]$Capture=(Join-Path $PSScriptRoot 'capture_two_ACTUAL.json'),
    [string]$Output=(Join-Path $PSScriptRoot 'final_guard_two_ACTUAL.json')
)
$ErrorActionPreference='Stop'
$twoGame=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$twoGuard=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../city_navigation_20261101d_guard01'))
if((Get-FileHash -LiteralPath $Authorization -Algorithm SHA256).Hash.ToLowerInvariant() -cne $AuthorizationSha256.ToLowerInvariant()){throw 'ROOT_EXPLICIT_AUTHORIZATION_SHA_REQUIRED'}
$twoAuth=Get-Content -LiteralPath $Authorization -Raw | ConvertFrom-Json
if($twoAuth.schema -ne 'CITY_NAVIGATION_20261101D_TWO_TARGET_AUTHORIZATION_V1' -or $twoAuth.root_approved -ne $true -or @($twoAuth.old_target_deltas).Count -ne 2){throw 'ROOT_APPROVED_EXACT_TWO_AFTER_REQUIRED'}
if((Get-FileHash -LiteralPath $Capture -Algorithm SHA256).Hash.ToLowerInvariant() -cne $twoAuth.supplement_capture_sha256){throw 'EXACT_ROOT_FRESH_TWO_CAPTURE_REQUIRED'}
$twoCapture=Get-Content -LiteralPath $Capture -Raw | ConvertFrom-Json
if($twoCapture.schema -ne 'CITY_NAVIGATION_20261101D_FRESH_TWO_SUPPLEMENT_V1' -or $twoCapture.captured_successfully -ne $true -or $twoCapture.target_count -ne 2 -or $twoCapture.original_source_count -ne 113 -or $twoCapture.original_capture_sha256 -cne $twoAuth.original_capture_sha256){throw 'EXACT113_PLUS_FRESH2_CAPTURE_REQUIRED'}
if((Get-FileHash -LiteralPath $twoCapture.original_capture_path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $twoAuth.original_capture_sha256){throw 'ORIGINAL113_CAPTURE_CHANGED'}
$twoBefore=Get-Content -LiteralPath $twoCapture.original_capture_path -Raw | ConvertFrom-Json
$twoHelpers=Join-Path $twoGuard 'guard_helpers_ROOT_ONLY.ps1'
$twoHelperKey='res://build/city_navigation_20261101d_guard01/guard_helpers_ROOT_ONLY.ps1'
if((Get-FileHash -LiteralPath $twoHelpers -Algorithm SHA256).Hash.ToLowerInvariant() -cne $twoBefore.before_facts.$twoHelperKey.sha256){throw 'ORIGINAL_HELPER_CHANGED'}
. $twoHelpers
$twoOutput=Assert-CityNavNewOutput $Output $PSScriptRoot
$twoExpected=[ordered]@{
 'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'=@('841c9dc0b948326ad249394605a24cf5be6eb5dd2887099e6194a6aee67a9c1e','11583a13e6f0baf3e32f8675398033b49dc58d1314899dfc3d3cfb3e3acce9ec',218285)
 'res://scripts/city/luoyang_quarters_index_20261022ap.gd'=@('ffada93bd159c2f7fd5049219e47d8af9dfe2bb19960db53086a04deea3f9a97','9d534fb69605ed3e4e2e78481ac11549f680637fd46dddc9aa5b62e3e908e1c8',452)
}
$twoReceiptPath=Resolve-CityNavSource $twoAuth.successor_receipt $twoGame
if((Get-CityNavSourceFact $twoReceiptPath).sha256 -cne $twoAuth.successor_receipt_sha256){throw 'EXACT_REVIEWED_SUCCESSOR_RECEIPT_REQUIRED'}
$twoReceipt=Get-Content -LiteralPath $twoReceiptPath -Raw | ConvertFrom-Json
if(@($twoReceipt.targets).Count -ne 2 -or $twoReceipt.only_three_pin_values_changed -ne $true -or $twoReceipt.index_only_MANIFEST_SHA_changed -ne $true -or $twoReceipt.other_1279_pin_values_and_all_other_JSON_exact -ne $true){throw 'FINITE3_PLUS1_SUCCESSOR_REQUIRED'}
$twoErrors=@();$twoFacts=[ordered]@{};$twoProofs=[ordered]@{};$twoBackupFacts=[ordered]@{}
foreach($key in $twoExpected.Keys){
 $rows=@($twoAuth.old_target_deltas|Where-Object {$_.path -ceq $key})
 $receipts=@($twoReceipt.targets|Where-Object {$_.res_path -ceq $key})
 if($rows.Count -ne 1 -or $receipts.Count -ne 1){throw 'EXACT_TWO_TARGET_SET_REQUIRED'}
 $row=$rows[0];$receipt=$receipts[0];$expected=$twoExpected[$key]
 if($row.before_sha256 -cne $expected[0] -or $row.after_sha256 -cne $expected[1] -or $row.before_bytes -ne $expected[2] -or $row.after_bytes -ne $expected[2] -or $receipt.before_sha256 -cne $row.before_sha256 -or $receipt.after_sha256 -cne $row.after_sha256){throw 'EXACT_HASH_ONLY_AFTER_AUTHORITY_REQUIRED'}
 if($null -ne $twoBefore.before_facts.PSObject.Properties[$key]){throw 'DO_NOT_RELAX_ORIGINAL113_STRICT_TARGET'}
 $before=$twoCapture.before_facts.$key;$backup=$twoCapture.full_backups.$key
 if($before.sha256 -cne $row.before_sha256 -or $before.bytes -ne $row.before_bytes){throw 'FRESH2_BEFORE_AUTHORITY_MISMATCH'}
 $backupFact=Get-CityNavSourceFact $backup.path;$twoBackupFacts[$key]=$backupFact
 if(-not(Test-CityNavSourceSame $backup.fact $backupFact) -or -not(Test-CityNavSourceSame $before $backupFact)){$twoErrors+=('FULL_TWO_BACKUP_CHANGED:'+$key)}
 $absolute=Resolve-CityNavSource $key $twoGame
 $fact=Get-CityNavSourceFact $absolute;$twoFacts[$key]=$fact
 if($fact.sha256 -cne $row.after_sha256 -or $fact.bytes -ne $row.after_bytes -or $fact.stable -ne $true){$twoErrors+=('EXACT_TWO_AFTER_MISMATCH:'+$key);continue}
 [byte[]]$afterBytes=[IO.File]::ReadAllBytes($absolute)
 [byte[]]$beforeBytes=[IO.File]::ReadAllBytes($backup.path)
 [byte[]]$inverse=$afterBytes.Clone();[byte[]]$forward=$beforeBytes.Clone()
 foreach($hunk in $receipt.hunks){
   [byte[]]$oldBytes=[Text.UTF8Encoding]::new($false).GetBytes([string]$hunk.old)
   [byte[]]$newBytes=[Text.UTF8Encoding]::new($false).GetBytes([string]$hunk.new)
   $offset=[int]$hunk.byte_offset
   if($oldBytes.Length -ne $newBytes.Length -or $offset -lt 0 -or $offset+$newBytes.Length -gt $afterBytes.Length){throw 'FINITE_EQUAL_LENGTH_BYTE_HUNK_REQUIRED'}
   for($i=0;$i -lt $newBytes.Length;$i++){if($afterBytes[$offset+$i] -ne $newBytes[$i] -or $beforeBytes[$offset+$i] -ne $oldBytes[$i]){throw 'EXACT_ORIGINAL_HUNK_BYTES_REQUIRED'}}
   [Array]::Copy($oldBytes,0,$inverse,$offset,$oldBytes.Length)
   [Array]::Copy($newBytes,0,$forward,$offset,$newBytes.Length)
 }
 $same=([Convert]::ToBase64String($inverse) -ceq [Convert]::ToBase64String($beforeBytes)) -and ([Convert]::ToBase64String($forward) -ceq [Convert]::ToBase64String($afterBytes))
 $twoProofs[$key]=[ordered]@{whole_byte_forward_inverse=$same;hunk_count=@($receipt.hunks).Count}
 if(-not $same){$twoErrors+=('ONLY_APPROVED3_PLUS1_HUNKS_REQUIRED:'+$key)}
}
foreach($property in $twoCapture.original_guard_file_facts.PSObject.Properties){if(-not(Test-CityNavSourceSame $property.Value (Get-CityNavSourceFact (Resolve-CityNavSource $property.Name $twoGame)))){throw 'ORIGINAL_THREE_GUARDS_CHANGED'}}
if(-not(Test-CityNavSourceSame $twoCapture.capture_script_fact (Get-CityNavSourceFact (Join-Path $PSScriptRoot 'capture_two_ROOT_ONLY.ps1')))){throw 'FRESH2_CAPTURE_SCRIPT_CHANGED'}
$twoInherited=$null;$twoInheritedFact=$null;$twoInheritedExit=$null
if($twoErrors.Count -eq 0){
 # Invoke the original unmodified113/96 guard exactly once. It owns the sole
 # final171metadata pass. This wrapper never opens/hashes/deserializes saves.
 $twoInheritedOutput=Assert-CityNavNewOutput (Join-Path $twoGuard 'final_guard_inherited_supplement01_ACTUAL.json') $twoGuard
 $twoOriginalFinal=Join-Path $twoGuard 'final_guard_ROOT_ONLY.ps1'
 $twoShell=(Get-Process -Id $PID).Path
 & $twoShell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $twoOriginalFinal -BeforeSha256 $twoAuth.original_capture_sha256 -CandidateManifestSha256 $twoAuth.candidate_manifest_sha256 -ProjectAfterSha256 $twoAuth.project_after_sha256 -Before $twoCapture.original_capture_path -Output $twoInheritedOutput | Out-Host
 $twoInheritedExit=$LASTEXITCODE
 if(Test-Path -LiteralPath $twoInheritedOutput){$twoInherited=Get-Content -LiteralPath $twoInheritedOutput -Raw|ConvertFrom-Json;$twoInheritedFact=Get-CityNavSourceFact $twoInheritedOutput}
 if($twoInheritedExit -ne 0 -or $null -eq $twoInherited -or $twoInherited.passed -ne $true -or $twoInherited.source_count -ne 113 -or $twoInherited.candidate_leaf_count -ne 96){$twoErrors+='ORIGINAL113_96_FINAL_GUARD_FAILED'}
}
$twoResult=[ordered]@{
 schema='CITY_NAVIGATION_20261101D_SUPPLEMENTED_FINAL_V1';passed=($twoErrors.Count -eq 0);finished_utc=[DateTime]::UtcNow.ToString('o')
 authorization_path=[IO.Path]::GetFullPath($Authorization);authorization_sha256=$AuthorizationSha256.ToLowerInvariant();supplement_capture_path=[IO.Path]::GetFullPath($Capture);supplement_capture_sha256=$twoAuth.supplement_capture_sha256
 original113_capture_path=$twoCapture.original_capture_path;original113_capture_sha256=$twoAuth.original_capture_sha256;original_guard_file_facts=$twoCapture.original_guard_file_facts
 original_source_count=113;supplement_source_count=2;source_count=115;supplement_after_facts=$twoFacts;supplement_backup_facts=$twoBackupFacts;exact_two_hunk_proofs=$twoProofs
 inherited_final=$twoInherited;inherited_final_fact=$twoInheritedFact;inherited_process_exit_code=$twoInheritedExit
 allowed_old_changes=@('res://project.godot')+@($twoExpected.Keys);only_two_quarter_pin_successors_plus_original_single_hook=$true
 candidate_leaf_count=if($null -ne $twoInherited){$twoInherited.candidate_leaf_count}else{96}
 save_facts=if($null -ne $twoInherited){$twoInherited.save_facts}else{$null};save_count=if($null -ne $twoInherited){$twoInherited.save_count}else{0}
 save_metadata_passes_this_wrapper=0;save_metadata_passes_inherited=if($null -ne $twoInherited){$twoInherited.save_metadata_passes_this_script}else{0}
 save_content_reads=0;save_hashes=0;save_writes=0;save_deserializations=0;automatic_restore=$false;original_baseline_or_strict_rewritten=$false;old_guard_edits=0;engine_runs=0;old_source_writes=0;errors=$twoErrors
}
Write-CityNavNewJson $twoOutput $twoResult
[ordered]@{passed=$twoResult.passed;path=$twoOutput;sha256=(Get-CityNavSourceFact $twoOutput).sha256;sources=115;original_strict=113;supplement=2;candidate_leaves=$twoResult.candidate_leaf_count;saves=$twoResult.save_count;errors=$twoErrors}|ConvertTo-Json -Depth 4
if($twoErrors.Count -ne 0){exit 1}
