param([string]$Expected='F:/Code/RPG_GAME/game/build/riverside_visual_20261101a_source01/final_expected_REVIEW_ONLY.json',[string]$Output='F:/Code/RPG_GAME/game/build/riverside_visual_20261101a_source01/final_guard_ACTUAL.json')
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $Output){throw 'NEW_FINAL_REPORT_ONLY'}
$started=[DateTime]::UtcNow.ToString('o')
$plan=Get-Content -LiteralPath $Expected -Raw|ConvertFrom-Json
$baseline=Get-Content -LiteralPath $plan.save_before_path -Raw|ConvertFrom-Json
$mini=Get-Content -LiteralPath $plan.minimap_before_path -Raw|ConvertFrom-Json
function Get-Fact([string]$path){
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)){return [ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}}
    $a=Get-Item -LiteralPath $path;$bytes=$a.Length;$ticks=$a.LastWriteTimeUtc.Ticks.ToString()
    $sha=(Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
    $b=Get-Item -LiteralPath $path
    return [ordered]@{exists=$true;bytes=$bytes;utc_ticks=$ticks;sha256=$sha;stable_during_hash=($bytes -eq $b.Length -and $ticks -eq $b.LastWriteTimeUtc.Ticks.ToString())}
}
function Same-Fact($a,$b){return $a.exists -eq $b.exists -and $a.bytes -eq $b.bytes -and $a.utc_ticks -eq $b.utc_ticks -and $a.sha256 -eq $b.sha256 -and $a.stable_during_hash -and $b.stable_during_hash}
$errors=[Collections.Generic.List[string]]::new()
$facts=[ordered]@{};$authorized=@();$saves=[ordered]@{};$proofs=[ordered]@{};$backups=[ordered]@{}
foreach($prop in $plan.authorized_after_sha256.PSObject.Properties){
    $now=Get-Fact $prop.Name;$facts[$prop.Name]=$now
    $old=$baseline.before.PSObject.Properties[$prop.Name].Value
    if($null -eq $old -and $prop.Name -eq $mini.authorized_third_old_target){$old=$mini.before}
    if($null -eq $old){$errors.Add('AUTHORIZED_BEFORE_MISSING:'+ $prop.Name)}
    if(-not $now.stable_during_hash -or $now.sha256 -ne $prop.Value){$errors.Add('AUTHORIZED_AFTER_SHA:'+ $prop.Name)}
    $authorized+=[ordered]@{path=$prop.Name;before=$old;after=$now;expected_sha256=$prop.Value}
}
foreach($prop in $plan.frozen_before_facts.PSObject.Properties){
    $now=Get-Fact $prop.Name;$facts[$prop.Name]=$now
    if(-not(Same-Fact $now $prop.Value)){$errors.Add('FROZEN_SOURCE_METADATA_DIFFERENCE:'+ $prop.Name)}
}
foreach($prop in $baseline.save_facts.PSObject.Properties){
    $now=Get-Fact $prop.Name;$saves[$prop.Name]=$now
    if(-not(Same-Fact $now $prop.Value)){$errors.Add('SAVE_METADATA_DIFFERENCE_NO_RESTORE:'+ $prop.Name)}
}
if($saves.Count -ne 171){$errors.Add('SAVE_EXPECTED171')}
foreach($prop in $plan.new_proof_sha256.PSObject.Properties){
    $now=Get-Fact $prop.Name;$proofs[$prop.Name]=$now
    if(-not $now.stable_during_hash -or $now.sha256 -ne $prop.Value){$errors.Add('NEW_PROOF_SHA:'+ $prop.Name)}
}
foreach($prop in $baseline.backups.PSObject.Properties){
    $now=Get-Fact $prop.Name;$backups[$prop.Name]=$now
    if(-not(Same-Fact $now $prop.Value)){$errors.Add('BACKUP_METADATA_DIFFERENCE:'+ $prop.Name)}
}
$miniBackup=Get-Fact $mini.backup;$backups[$mini.backup]=$miniBackup
if($miniBackup.sha256 -ne $mini.before.sha256){$errors.Add('MINIMAP_BACKUP_SHA')}
$result=[ordered]@{passed=($errors.Count -eq 0);scope='THREE_CURRENT_AUTHORIZED_TARGETS_PLUS_BOUNDED_FROZEN_INPUTS_AND171_FRESH_SAVE_METADATA_NOT_GLOBAL3236_REHASH';started_utc=$started;finished_utc=[DateTime]::UtcNow.ToString('o');expected_path=$Expected;expected_sha256=(Get-Fact $Expected).sha256;authorized_change_count=$authorized.Count;frozen_source_count=@($plan.frozen_before_facts.PSObject.Properties).Count;save_count=$saves.Count;absent_save_count=@($saves.Values|Where-Object{-not $_.exists}).Count;new_proof_count=$proofs.Count;authorized_changes=$authorized;facts=$facts;save_facts=$saves;new_proof_facts=$proofs;backup_facts=$backups;errors=@($errors);retained_user_save_changes_before_capture=$baseline.save_changed_since_prior;prior3236_credit='HISTORICAL_ONLY_NOT_REHASHED';shared_guard_edit_count=0;engine_runs=0;process_control=0;production_writes=0;save_deserializations=0;save_writes=0;automatic_restore=$false}
[IO.File]::WriteAllText($Output,($result|ConvertTo-Json -Depth 16),[Text.UTF8Encoding]::new($false))
[ordered]@{passed=$result.passed;errors=@($errors);authorized_count=$authorized.Count;frozen_count=$result.frozen_source_count;save_count=$saves.Count;absent_save_count=$result.absent_save_count;new_proof_count=$proofs.Count;output=$Output;sha256=(Get-Fact $Output).sha256}|ConvertTo-Json -Depth 4
if($errors.Count){exit 1}
