$ErrorActionPreference='Stop'
$root='F:/Code/RPG_GAME/game/build/riverside_visual_20261101a_source01'
$original=Join-Path $root 'before_ACTUAL.json'
$data=Get-Content -LiteralPath $original -Raw | ConvertFrom-Json
$prior=Get-Content -LiteralPath $data.prior_guard_path -Raw | ConvertFrom-Json
$changes=@()
foreach($prop in $data.save_facts.PSObject.Properties) {
    $old=$prior.facts.($prop.Name);$now=$prop.Value
    if($now.exists -ne $old.exists -or $now.bytes -ne $old.bytes -or $now.utc_ticks -ne $old.utc_ticks -or $now.sha256 -ne $old.sha256){$changes+=$prop.Name}
    if(-not $now.exists){
        $prop.Value=[pscustomobject][ordered]@{exists=$false;bytes=$null;utc_ticks=$null;sha256=$null;stable_during_hash=$true}
    }
}
$data.save_changed_since_prior=$changes
$data | Add-Member -NotePropertyName original_capture_path -NotePropertyValue $original
$data | Add-Member -NotePropertyName original_capture_sha256 -NotePropertyValue (Get-FileHash -Algorithm SHA256 -LiteralPath $original).Hash.ToLowerInvariant()
$data | Add-Member -NotePropertyName correction -NotePropertyValue 'No recapture and no backup overwrite. Compare metadata fields; original report counted9absent shape-only differences. Actual historical changes2 user save0/bak preserved.'
[IO.File]::WriteAllText((Join-Path $root 'before02_ACTUAL.json'),($data|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
[ordered]@{save_count=$data.save_count;actual_historical_save_changes=$changes;original_preserved=$true;output=(Join-Path $root 'before02_ACTUAL.json')} | ConvertTo-Json -Depth 3
