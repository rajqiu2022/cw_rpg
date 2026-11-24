param([string]$Workspace='F:\Code\RPG_GAME')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# Root executes; no Godot/ResourceLoader/image/import/canonical/save operation.
$taskWorkspace=[IO.Path]::GetFullPath($Workspace)
$taskGame=Join-Path $taskWorkspace 'game'
$taskOutput=Join-Path $taskWorkspace ('game/build/luoyang_city_completion_20261021ai_qa01/life_dialog_exclusions_residual_'+$PID+'.json')
$priorPath=Join-Path $taskWorkspace 'game/build/luoyang_city_completion_20261021ai_qa01/dialog_loader_119464/result.json'
$priorSHA='0bb9cbdd83613cfe71a4ea2c6b9e06bc8157fb264b2c33a72c04a2c37ae94df6'
$candidateURI='res://build/luoyang_city_completion_20261021ai_lore01/manifest.json'
$cultureURI='res://data/luoyang_culture_candidates_20261019w/manifest.json'
$carrierURI='res://data/luoyang_docks_roles_20261019ad/manifest.json'
if(Test-Path -LiteralPath $taskOutput){throw 'PRESERVE_EXISTING_RESIDUAL_REPORT'}
$script:checks=0;$script:failed=@()
function Check([bool]$value,[string]$label){$script:checks++;if(!$value){$script:failed+=,$label}}
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
function Local([string]$uri){if(!$uri.StartsWith('res://') -or $uri.Contains('..')){throw 'FIXED_RES_URI_REQUIRED'};return Join-Path $taskGame $uri.Substring(6)}
function Fact([string]$path){
 if(!(Test-Path -LiteralPath $path)){return @{path=$path;exists=$false;sha256='ABSENT';bytes=0;ticks='0';mtime_seconds_string='0'}}
 $item=Get-Item -LiteralPath $path
 if($item.PSIsContainer){throw 'SOURCE_IS_DIRECTORY'}
 return @{path=$path;exists=$true;sha256=(Sha $path);bytes=[long]$item.Length;ticks=[string]$item.LastWriteTimeUtc.Ticks;mtime_seconds_string=[string]([DateTimeOffset]::new($item.LastWriteTimeUtc).ToUnixTimeSeconds())}
}
function SameTree($left,$right){
 if($null -eq $left -or $null -eq $right){return $null -eq $left -and $null -eq $right}
 if($left -is [Collections.IDictionary]){
  if($right -isnot [Collections.IDictionary] -or $left.Count -ne $right.Count){return $false}
  foreach($key in $left.Keys){if(!$right.Contains($key) -or !(SameTree $left[$key] $right[$key])){return $false}}
  return $true
 }
 if($left -is [Collections.IList]){
  if($right -isnot [Collections.IList] -or $left.Count -ne $right.Count){return $false}
  for($index=0;$index -lt $left.Count;$index++){if(!(SameTree $left[$index] $right[$index])){return $false}}
  return $true
 }
 return [object]::Equals($left,$right)
}
if((Sha $priorPath) -cne $priorSHA){throw 'PINNED_ORIGINAL_WHOLE_FAIL_CHANGED'}
$prior=Get-Content -LiteralPath $priorPath -Raw|ConvertFrom-Json -AsHashtable
Check ($prior.complete -is [bool] -and !$prior.complete -and $prior.checks -eq 573 -and $prior.failures -eq 2) 'Original573/2 wholeFAIL remains false, not rewritten'
$wantedFailures=@('Current five cultural identities read without coordinator execution','Culture5 plus existing carrier3 kept outside candidate selection')
Check ($prior.failure_details.Count -eq 2 -and (SameTree @($prior.failure_details|ForEach-Object {$_.label}) $wantedFailures)) 'Only two known count assertions failed; other571 checks completed'
Check ($prior.loaded_dialog_count -eq 12 -and $prior.loaded_node_count -eq 24 -and $prior.records.Count -eq 12 -and $prior.checkpoint_suspended -eq $true) 'Inherited actual12Script24Node/suspended checkpoint component'
Check ($prior.elapsed_ms -eq 24 -and $prior.elapsed_ms -lt $prior.budget_ms) 'Original24ms resource-only component within original budget'
Check ($prior.source_first.Count -eq 26 -and (SameTree $prior.source_first $prior.source_final)) 'Original26 source facts whole first/final same'
Check ($prior.saves_first.Count -eq 15 -and (SameTree $prior.saves_first $prior.saves_final)) 'Original15save present/absent first/final same'
Check (SameTree $prior.state_first $prior.state_final) 'Originalactual flags/QM/inventory first/final same, not a new engine state claim'
$first=@{};$paths=@($priorPath,$PSCommandPath)
foreach($uri in $prior.source_first.Keys){$paths+=,(Local $uri)}
foreach($saveURI in $prior.saves_first.Keys){
 if($saveURI -cnotmatch '^user://save_[0-4]\.json(\.bak|\.tmp)?$'){throw 'ORIGINAL_EXACT_SAVE_SLOT_DOMAIN'}
 $paths+=,(Join-Path ([IO.Path]::Combine([Environment]::GetFolderPath('ApplicationData'),'Godot/app_userdata/云影侠传')) $saveURI.Substring(7))
}
foreach($path in $paths){if($first.ContainsKey($path)){throw 'DUPLICATE_FIXED_SOURCE_PATH'};$first[$path]=Fact $path}
foreach($uri in $prior.source_first.Keys){
 $now=$first[(Local $uri)];$old=$prior.source_first[$uri]
 Check ($now.exists -eq $old.exists -and $now.sha256 -ceq $old.sha256 -and $now.bytes -eq $old.bytes -and $now.mtime_seconds_string -ceq $old.mtime_seconds_string) ('Original completed component current source still exact '+$uri)
}
$candidate=Get-Content -LiteralPath (Local $candidateURI) -Raw|ConvertFrom-Json -AsHashtable
$culture=Get-Content -LiteralPath (Local $cultureURI) -Raw|ConvertFrom-Json -AsHashtable
$carrier=Get-Content -LiteralPath (Local $carrierURI) -Raw|ConvertFrom-Json -AsHashtable
$expectedCulture=@{
 'district_life_yamen_petitioner'='ch4_s1_luoyang_yamen'
 'district_life_yamen_clerk'='ch4_s1_luoyang_yamen'
 'harbour_life_gate_supply_attendant'='ch4_s0_luoyang_gate'
 'luoyang_paper_scholar'='ch4_s3_luoyang_market'
 'harbour_life_docks_booking_attendant'='ch4_s2_canal_docks'
 'district_life_market_buyer'='ch4_s3_luoyang_market'
}
$cultureActors=@{}
foreach($quest in $culture.quests){foreach($actor in $quest.actors){
 Check ($actor.npc_id -is [string] -and $expectedCulture.ContainsKey($actor.npc_id) -and $actor.scene_id -ceq $expectedCulture[$actor.npc_id]) ('Exact authored culture actor identity and scene '+$actor.npc_id)
 if($cultureActors.ContainsKey($actor.npc_id)){Check ($cultureActors[$actor.npc_id] -ceq $actor.scene_id) 'Repeated cross-quest actor retains same scene'}
 $cultureActors[$actor.npc_id]=$actor.scene_id
}}
Check ($cultureActors.Count -eq 6 -and (SameTree $cultureActors $expectedCulture)) 'Six exact unique current cultural actors, not five'
$expectedCarrier=@('harbour_life_docks_rope_carrier','harbour_life_docks_southern_carrier','harbour_life_docks_west_carrier')
$carrierIDs=@($carrier.roles|ForEach-Object {$_.npc_id})
Check ($carrierIDs.Count -eq 3 -and (SameTree @($carrierIDs|Sort-Object) @($expectedCarrier|Sort-Object))) 'Three exact existing carrier IDs'
$excluded=@{}
foreach($id in $cultureActors.Keys){$excluded[$id]=$true}
foreach($id in $carrierIDs){Check (!$excluded.ContainsKey($id)) ('Carrier does not collide with culture actor '+$id);$excluded[$id]=$true}
Check ($excluded.Count -eq 9) 'Sixculture plus3carrier exactnine exclusions'
Check ($candidate.status -ceq 'CANDIDATE_TEXT_ONLY_NOT_BOUND' -and $candidate.formal_enabled -eq $false -and $candidate.rows.Count -eq 12) 'Only twelve unbound candidate daily resources'
$policy=$candidate.topic_policy
Check ($policy.kind -ceq 'secondary_daily_life' -and $policy.label -ceq '聊聊日常' -and $policy.preserve_primary -eq $true -and $policy.preserve_culture -eq $true -and $policy.no_runtime_hook -eq $true -and $policy.priority -ceq 'primary and culture before secondary daily life') 'Secondary policy preserves actual primary/culture; no integration credit'
$seen=@{}
foreach($row in $candidate.rows){
 Check (!$excluded.ContainsKey($row.npc_id) -and !$seen.ContainsKey($row.npc_id)) ('Unique candidate excludes allnine existing topics '+$row.npc_id)
 $seen[$row.npc_id]=$true
 $oldRows=@($prior.records|Where-Object {$_.npc_id -ceq $row.npc_id})
 Check ($oldRows.Count -eq 1 -and $oldRows[0].scene_id -ceq $row.scene_id -and $oldRows[0].dialog_path -ceq $row.dialog_path -and $oldRows[0].dialog_id -ceq $row.dialog_id -and $oldRows[0].nodes.Count -eq 2 -and $oldRows[0].nodes[0].speaker -ceq $row.npc_name -and $oldRows[0].nodes[1].speaker -ceq $row.npc_name) ('Inherited exact typed resource/speaker record '+$row.npc_id)
}
$final=@{}
foreach($path in $paths){$final[$path]=Fact $path}
Check (SameTree $first $final) 'All residual source/save exactSHA bytes ticks unchanged; no restore'
$passed=$script:failed.Count -eq 0
$result=@{
 scope='RESIDUAL_EXACT_SIX_CULTURE_THREE_CARRIER_EXCLUSIONS_PLUS_PINNED571_RESOURCE_COMPONENT_ONLY'
 passed=$passed;checks=$script:checks;failures=$script:failed.Count;failure_details=$script:failed
 prior_report_path=$priorPath;prior_report_sha256=$priorSHA;prior_whole_complete_remains_false=$true
 inherited_completed_checks=571;inherited_dialogs=12;inherited_nodes=24
 original_actual_child_exit_code=$null;original_child_exit_code_verified=$false
 culture_exact_six=$cultureActors;carrier_exact_three=$carrierIDs;excluded_exact_nine=@($excluded.Keys|Sort-Object)
 source_first=$first;source_final=$final
 no_ResourceLoader_or_engine_or_save_write=$true;formal_or_Field_or_topic_runtime_credit=$false
 precision='Residual currentSHA bytes and exactUTCticks; prior Godot source/save facts are seconds String, not full Windows ticks'
}
$stream=[IO.File]::Open($taskOutput,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
try{$writer.Write(($result|ConvertTo-Json -Depth 16)+"`n")}finally{$writer.Dispose()}
@{report=$taskOutput;sha256=(Sha $taskOutput);passed=$passed;checks=$script:checks;failures=$script:failed.Count;inherited_completed_checks=571}|ConvertTo-Json -Depth 5
if(!$passed){exit 1}
