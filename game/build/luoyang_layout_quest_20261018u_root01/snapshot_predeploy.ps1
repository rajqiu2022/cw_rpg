$ErrorActionPreference='Stop'
$root='F:/Code/RPG_GAME/game/'
$out='F:/Code/RPG_GAME/game/build/luoyang_layout_quest_20261018u_root01/'
$old=Get-Content -Raw ($out+'guard_before.json')|ConvertFrom-Json
$deployment=Get-Content -Raw ($root+'build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/deployment.json')|ConvertFrom-Json
$migration=Get-Content -Raw ($root+'build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/runtime_source_migration.json')|ConvertFrom-Json
$paths=[Collections.Generic.HashSet[string]]::new()
foreach($row in $old.facts){[void]$paths.Add($row.path)}
foreach($row in $deployment.replace_existing){
 $target=$row.target.Replace('res://',$root)
 if((Get-FileHash -LiteralPath $target).Hash -ne $row.before_sha256){throw "Changed target: $target"}
 [void]$paths.Add($target)
}
foreach($prop in $migration.new_input_sha256.PSObject.Properties){
 $path=$prop.Name.Replace('res://',$root)
 $replacement=@($deployment.replace_existing|Where-Object target -eq $prop.Name)
 if($replacement.Count -eq 1){
  if($replacement[0].after_sha256 -ne $prop.Value){throw "Conflicting replacement new input: $path"}
 }elseif((Get-FileHash -LiteralPath $path).Hash -ne $prop.Value){throw "Changed new input: $path"}
 [void]$paths.Add($path)
}
$facts=@(foreach($path in $paths){
 $exists=Test-Path -LiteralPath $path -PathType Leaf
 if($exists){$file=Get-Item -LiteralPath $path;[ordered]@{path=$path;exists=$true;bytes=$file.Length;ticks=$file.LastWriteTimeUtc.Ticks.ToString();sha256=(Get-FileHash -LiteralPath $path).Hash}}
 else{[ordered]@{path=$path;exists=$false;bytes=0;ticks='0';sha256=''}}
})
$snapshot=[ordered]@{status='U_FRESH_PREDEPLOY';observed_at=[DateTimeOffset]::Now.ToString('o');facts=$facts}
$snapshot|ConvertTo-Json -Depth 12|Out-File -LiteralPath ($out+'guard_predeploy.json') -Encoding utf8
$changes=@(foreach($row in $old.facts){$now=$facts|Where-Object path -eq $row.path;if($now.sha256 -ne $row.sha256 -or $now.ticks -ne $row.ticks){$row.path}})
[ordered]@{count=$facts.Count;baseline_changes=$changes;target_count=$deployment.replace_existing.Count;new_inputs=$migration.new_input_sha256.PSObject.Properties.Count}|ConvertTo-Json -Depth 5
