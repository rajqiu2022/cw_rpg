$ErrorActionPreference='Stop'
$dir='F:/Code/RPG_GAME/game/build/gather_actions_20261030l_root01'
$first=Get-Content -LiteralPath ($dir+'/final_guard_ACTUAL.json') -Raw | ConvertFrom-Json -AsHashtable
$baseline=Get-Content -LiteralPath ($dir+'/baseline02_ACTUAL.json') -Raw | ConvertFrom-Json -AsHashtable
$run=Get-Content -LiteralPath ($dir+'/actions02_ACTUAL_process_receipt.json') -Raw | ConvertFrom-Json -AsHashtable
$stamp=$run.started_utc
$began=if($stamp -is [DateTime]){$stamp.ToUniversalTime()}else{[DateTimeOffset]::Parse([string]$stamp).UtcDateTime}
$paths=@('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传/save_0.json','C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传/save_0.json.bak')
$audit=@();$errors=@()
foreach($path in $paths) {
 $item=Get-Item -LiteralPath $path
 $fact=@{exists=$true;bytes=$item.Length;utc_ticks=[string]$item.LastWriteTimeUtc.Ticks;sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
 foreach($key in $fact.Keys){if($fact[$key] -cne $first.facts[$path][$key]){$errors+=('CHANGED_AFTER_FIRST_GUARD:'+ $path+':'+$key)}}
 if($item.LastWriteTimeUtc -ge $began){$errors+=('SAVE_MTIME_NOT_BEFORE_ROOT_FIRST_RUNTIME:'+ $path)}
 $audit+=@{path=$path;before_game_stopped_baseline=$baseline.facts[$path];retained_current=$fact;last_write_utc=$item.LastWriteTimeUtc.ToString('o');first_root_game_runtime_utc=$began.ToString('o');last_write_precedes_first_root_game_runtime=($item.LastWriteTimeUtc -lt $began);save_content_deserialized=$false;file_restored_or_written=$false}
}
foreach($message in $first.errors) {
 $allowed=$false
 foreach($path in $paths){if($message.StartsWith($path+':')){$allowed=$true}}
 if(!$allowed){$errors+=('UNEXPECTED_FIRST_GUARD_DELTA:'+ $message)}
}
$out=@{scoped_source_and_post_user_save_audit_passed=($errors.Count -eq 0);errors=$errors;first_guard_preserved_failed=$true;second_audit_bad_date_reparse_preserved=$true;first_guard_sha256=(Get-FileHash -LiteralPath ($dir+'/final_guard_ACTUAL.json')).Hash;original_250_fact_guard_was_not_whole_pass=$true;unchanged_save_facts=169;pre_runtime_changed_user_save_facts=$audit;old_code_and_non_save_external_deltas=0;save_reads_only_metadata_hash_bytes_ticks=$true;save_write_or_restore_count=0;note='User game PID133212 was running during the baseline, then the user stopped it. Two save0 facts changed before the first Root runtime. Preserve those user updates; never reset them to the earlier running-game snapshot.'}
$out | ConvertTo-Json -Depth 8 | Out-File -LiteralPath ($dir+'/save_metadata_audit03_ACTUAL.json') -Encoding utf8
@{scoped_passed=$out.scoped_source_and_post_user_save_audit_passed;errors=$errors;unchanged_save_facts=169;retained_pre_runtime_save_updates=2;sha256=(Get-FileHash -LiteralPath ($dir+'/save_metadata_audit03_ACTUAL.json')).Hash} | ConvertTo-Json -Depth 4
if($errors.Count -gt 0){exit 1}
