param(
 [Parameter(Mandatory=$true)][string[]]$WrapperRunDirectories,
 [Parameter(Mandatory=$true)][string]$JournalPath,
 [Parameter(Mandatory=$true)][string]$ExpectedJournalSHA,
 [Parameter(Mandatory=$true)][string]$ApprovalPath,
 [Parameter(Mandatory=$true)][string]$ExpectedApprovalSHA,
 [Parameter(Mandatory=$true)][string]$PathSeedBefore,
 [Parameter(Mandatory=$true)][string]$ReviewedCorePath,
 [Parameter(Mandatory=$true)][string]$ReviewedCoreSHA,
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [string]$ProjectRoot='F:\Code\RPG_GAME',
 [string]$PlayerDirectory='C:\Users\rajqiu\AppData\Roaming\Godot\app_userdata\云影侠传'
)
# POST-CUTOVER READ ONLY consumer, never approval/signature/activation/rollback.
# AST reuses only explicit ROOT-reviewed frozen functions/data. Candidate top-level does NOT
# execute. Formal wrappers must freshly snapshot every seed path after cutover.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$domain=Join-Path $game 'build\joint_world_luoyang_20261003_qa'
$players=[IO.Path]::GetFullPath($PlayerDirectory).TrimEnd('\')
$target=[IO.Path]::GetFullPath($OutputDirectory)
$core=[IO.Path]::GetFullPath($ReviewedCorePath)
$coreSHA=$ReviewedCoreSHA
$selfFirst=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
if ($WrapperRunDirectories.Count -ne 6 -or -not $target.StartsWith($domain+'\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $target)) { throw 'Six formal wrappers and NEW unique QA BUILD output required' }
if (-not $core.StartsWith((Join-Path $project 'scripts\qa')+'\',[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($core) -cnotmatch '^prepare_luoyang_city_only_actual_six_approval_draft_retry[0-9]+_202610(?:09|10)\.ps1$' -or $coreSHA -cnotmatch '^[A-Fa-f0-9]{64}$' -or (Get-FileHash -LiteralPath $core -Algorithm SHA256).Hash -ine $coreSHA) { throw 'Only explicit ROOT-reviewed fixed source path/SHA accepted' }
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($core,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) { throw 'Frozen shared consumer must parse' }
foreach ($definition in @($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$true))) { Invoke-Expression $definition.Extent.Text }

function Select-FixedAssignment($sourceAst,$name) {
 Require ($sourceAst -is [Management.Automation.Language.ScriptBlockAst] -and $name -is [string] -and $name -cin @('$entry','$engineSHA','$ids','$fixed','$warningPins','$sparSpecs','$readingSpecs','$readingPins','$legacyScenes','$formalSeedPins')) 'Only exact typed fixed top-level table names accepted'
 $matches=@($sourceAst.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq $name})
 Require ($matches.Count -eq 1) ('Missing/duplicate top-level fixed table: '+$name)
 return $matches[0]
}
foreach ($name in @('$entry','$engineSHA','$ids','$fixed','$warningPins','$sparSpecs','$readingSpecs','$readingPins')) {
 $assignment=Select-FixedAssignment $ast $name
 Invoke-Expression $assignment.Extent.Text
}
# Source roots have the original TWO intentional top-level assignments: literal
# roots then derived closure. This is not one of the unique fixed tables above.
$roots=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq '$required'})
Require ($roots.Count -eq 2 -and $roots[0].Right.Extent.Text.StartsWith('@(') -and $roots[1].Right.Extent.Text -ceq '@($closure | Sort-Object)') 'Shared literal/derived source roots changed'
Invoke-Expression $roots[0].Extent.Text
$allSources=@{}; $evidence=@{}; $stackSourceCache=@{}; $sourceSHAs=[ordered]@{}
$legacyScenes=@{
 ch4_s0_luoyang_gate='B967C347E745E6F05D51A8F596FDE4744571F5D459279467C706E66D9BE24BD1'
 ch4_s1_luoyang_yamen='7BED5D322D583C9C7BF4E392F3F4C75FFB0577DB24BB9E6237A4AE3AA0808B01'
 ch4_s2_canal_docks='81850AFD0877BBA70E2ED0786FE4E81570FAEE8E06E827561349988F9C4D41A5'
 ch4_s3_luoyang_market='5CD76D0C0A0C54358F50B341186C5EA078A7D20657C97DC15EF15027755661AB'
}
function SHA-Value($value) { return $value -is [string] -and $value -cmatch '^[A-Fa-f0-9]{64}$' }
function Check-FormalMode($before) {
 Require ($before -is [Collections.IDictionary] -and $before.entry -is [string] -and $before.entry -ceq $entry -and $before.gpu -is [bool] -and $before.requested_audio_driver -is [string] -and $before.requested_audio_driver -ceq 'WASAPI' -and $before.user_arguments -is [array] -and $before.actual_engine_arguments -is [array]) 'Wrong formal entry/actual driver/arguments'
 foreach ($argument in $before.actual_engine_arguments) { Require ($argument -is [string]) 'Every actual process argument must be String' }
 foreach ($argument in $before.user_arguments) { Require ($argument -is [string]) 'Every user flag must be String' }
 $userFlags=$before.user_arguments
 $phases=@($userFlags|Where-Object {$_ -is [string] -and $_.StartsWith('--city-qa-phase=',[StringComparison]::Ordinal)})
 Require ($phases.Count -eq 1) 'Exactly one formal phase flag required'
 $phase=$phases[0].Substring('--city-qa-phase='.Length)
 Require ($phase -is [string] -and $phase -cin @('geometry','gameplay','save')) 'Source/diagnostic/unknown phase is not formal six'
 $allowed=@('--luoyang-city-only-fresh','--fresh-start-only',('--city-qa-phase='+$phase))
 if ($before.gpu) { $allowed+='--qa-gpu-approved' }
 Require ($userFlags.Count -eq $allowed.Count -and @($userFlags|Where-Object {$_ -isnot [string] -or $_ -cnotin $allowed}).Count -eq 0 -and @($userFlags|Select-Object -Unique).Count -eq $userFlags.Count) 'Formal candidate/historical/mixed/extra flags refused'
 $actual=$before.actual_engine_arguments; $separator=[array]::IndexOf($actual,'--')
 Require ($separator -ge 0 -and $separator -lt $actual.Count-1 -and (Equal @($actual[($separator+1)..($actual.Count-1)]) $userFlags) -and '--headless' -cnotin $actual) 'Actual process formal flags/display differ'
 $audio=[array]::IndexOf($actual,'--audio-driver')
 Require ($audio -ge 0 -and $audio -lt $actual.Count-1 -and $actual[$audio+1] -ceq 'WASAPI') 'Actual formal process did not request WASAPI'
 if ($before.gpu) { $render=[array]::IndexOf($actual,'--rendering-method'); Require ('--display-driver' -cnotin $actual -and $render -ge 0 -and $render -lt $actual.Count-1 -and $actual[$render+1] -ceq 'gl_compatibility') 'Actual formal hardware GPU request missing' }
 else { $display=[array]::IndexOf($actual,'--display-driver'); Require ($display -ge 0 -and $display -lt $actual.Count-1 -and $actual[$display+1] -ceq 'headless') 'Actual formal headless DISPLAY missing' }
 return @{phase=$phase;backend=$(if ($before.gpu) {'gpu'} else {'headless'})}
}
function Check-FormalResult($r,$phase) {
 Require ($phase -is [string] -and $phase -cin @('geometry','gameplay','save')) 'Only three full formal phases accepted'
 Require ($r -is [Collections.IDictionary] -and $r.scope -is [string] -and $r.scope -ceq 'LUOYANG_ENCLOSURE_V11_CITY_ONLY_FRESH_ACTUAL' -and $r.complete -is [bool] -and $r.complete -and $r.failures -is [long] -and $r.failures -eq 0 -and $r.checks -is [long] -and $r.checks -gt 0 -and $r.mode -is [Collections.IDictionary] -and $r.mode.phase -is [string] -and $r.mode.phase -ceq $phase -and $r.mode.candidate -is [bool] -and -not $r.mode.candidate -and $r.world_subject_version -is [long] -and $r.world_subject_version -eq 14 -and $r.historical_compatibility_tested -is [bool] -and -not $r.historical_compatibility_tested -and $r.actual_audio_driver -is [string] -and $r.actual_audio_driver -ceq 'WASAPI' -and $r.engine_sha256 -is [string] -and $r.engine_sha256 -ieq $engineSHA) 'Not a complete formal no-candidate actual result'
 Require ($r.checkpoint_suspension -is [Collections.IDictionary] -and $r.checkpoint_suspension.before_any_await -is [bool] -and $r.checkpoint_suspension.before_any_await -and $r.checkpoint_suspension.restored_before_exit -is [bool] -and -not $r.checkpoint_suspension.restored_before_exit) 'Formal checkpoint protection missing'
 Require ($r.source_before -is [Collections.IDictionary] -and $r.source_before.Count -gt 0 -and $r.source_after -is [Collections.IDictionary] -and (Equal $r.source_before $r.source_after) -and $r.stage -is [Collections.IDictionary] -and $r.stage.complete -is [bool] -and $r.stage.complete -and $r.stage.failures -is [long] -and $r.stage.failures -eq 0) 'Formal internal source/stage endpoints invalid'
 if ($phase -cin @('geometry','gameplay')) { Require ($r.stage.candidate_before_cutover -is [bool] -and -not $r.stage.candidate_before_cutover) 'Formal phase internally selected candidate' }
 else { Require ($r.stage.candidate_before_cutover -is [bool] -and -not $r.stage.candidate_before_cutover -and $r.stage.new_game.candidate_reset_uses_formal_baseline -is [bool] -and -not $r.stage.new_game.candidate_reset_uses_formal_baseline) 'Formal current save/NewGame internally selected candidate' }
}
function Check-FullCoverage($stage,$phase) {
 Require ($stage -is [Collections.IDictionary] -and $phase -is [string] -and $phase -cin @('geometry','gameplay','save')) 'Only three full coverage phases accepted'
 if ($phase -ceq 'geometry') {
  Require ($stage.records -is [Collections.IDictionary] -and $stage.records.regions -is [array] -and $stage.records.regions.Count -eq 4) 'Geometry four regions missing'
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal); $routes=0; $objects=0
  foreach ($region in $stage.records.regions) { Require ($region -is [Collections.IDictionary] -and $region.id -is [string] -and $region.id -cin $ids -and $seen.Add($region.id) -and $region.physical_and_current_alpha -is [Collections.IDictionary] -and $region.physical_and_current_alpha.routes -is [array] -and $region.physical_and_current_alpha.objects -is [array]) 'Duplicate/wrong geometry region'; $routes+=$region.physical_and_current_alpha.routes.Count; $objects+=$region.physical_and_current_alpha.objects.Count }
  Require ($routes -eq 20 -and $objects -eq 79) 'Full20 routes/79 objects missing'
 } elseif ($phase -ceq 'gameplay') {
  Require ($stage.records -is [Collections.IDictionary] -and $stage.records.npcs -is [array] -and $stage.records.interactions -is [array] -and $stage.records.portals -is [array] -and $stage.records.bounties -is [array] -and $stage.records.interaction_negatives -is [Collections.IDictionary] -and $stage.records.interaction_negatives.complete -is [bool] -and $stage.records.npcs.Count -eq 30 -and $stage.records.interactions.Count -eq 22 -and $stage.records.portals.Count -eq 24 -and $stage.records.bounties.Count -eq 2 -and $stage.records.interaction_negatives.complete -eq $true) 'Full52 inputs/24 portals/2 rewards/negatives missing'
 } else {
  Require ($stage.scope -is [string] -and $stage.scope -ceq 'LUOYANG_ENCLOSURE_V11_FOUR_CURRENT_SAVE_LOAD_FIELD_BIRTH' -and $stage.records -is [array] -and $stage.records.Count -eq 4 -and $stage.unknown_records -is [array] -and $stage.unknown_records.Count -eq 20 -and $stage.new_game -is [Collections.IDictionary] -and $stage.new_game.complete -is [bool] -and $stage.new_game.complete -and $stage.world_coordinate_version -is [long] -and $stage.world_coordinate_version -eq 14 -and $stage.city_layout_version -is [long] -and $stage.city_layout_version -eq 3) 'Formal NewGame/current four/unknown20 missing'
  Check-UnknownVersions $stage.unknown_records
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($case in $stage.records) { Require ($case -is [Collections.IDictionary] -and $case.scene_id -is [string] -and $case.scene_id -cin $ids -and $seen.Add($case.scene_id) -and $case.passed -is [bool] -and $case.passed -and $case.births -is [array] -and $case.births.Count -eq 2) 'Failed/duplicate current save'; foreach ($birth in $case.births) { Require ($birth -is [Collections.IDictionary] -and $birth.raw_full_feet_clear -is [bool] -and $birth.raw_full_feet_clear -and $birth.actual_Physics_clear -is [bool] -and $birth.actual_Physics_clear -and $birth.position_matches_saved -is [bool] -and $birth.position_matches_saved) 'Formal Field birth failed' } }
 }
}
function Check-JournalMetadata($journal,$approval,$approvalRes,$approvalSHA) {
 Require ($approvalRes -is [string] -and (SHA-Value $approvalSHA)) 'Explicit approval origin must be String/path and SHA'
 Require ($journal -is [Collections.IDictionary] -and $journal.schema_version -is [long] -and $journal.schema_version -eq 1 -and $journal.scope -is [string] -and $journal.scope -ceq 'LUOYANG_FOUR_CITY_ONLY_FRESH' -and $journal.state -is [string] -and $journal.state -ceq 'ACTIVATED_REQUIRES_FRESH_FORMAL_NO_FLAGS_QA' -and $journal.historical_compatibility_tested -is [bool] -and -not $journal.historical_compatibility_tested -and $journal.formal_no_flags_qa -is [string] -and $journal.formal_no_flags_qa -ceq 'NOT_RUN' -and $journal.targets -is [Collections.IDictionary] -and $journal.targets.Count -eq 4 -and $journal.approval_path -is [string] -and $journal.approval_path -ceq $approvalRes -and (SHA-Value $journal.approval_sha256) -and $journal.approval_sha256 -ieq $approvalSHA) 'No bound ACTIVATED four-city journal'
 Require ($approval -is [Collections.IDictionary] -and $approval.status -is [string] -and $approval.status -ceq 'ROOT_APPROVED_FOUR_CITY_FRESH_CANDIDATE' -and $approval.art_current_images_approved -is [bool] -and $approval.art_current_images_approved -and $approval.world_subject_version -is [long] -and $approval.world_subject_version -eq 14 -and $approval.historical_compatibility_tested -is [bool] -and -not $approval.historical_compatibility_tested -and $approval.source_sha256 -is [Collections.IDictionary] -and $approval.source_sha256.Count -gt 0 -and $approval.candidate_sha256 -is [Collections.IDictionary] -and $approval.candidate_sha256.Count -eq 4 -and $approval.layout_sha256 -is [Collections.IDictionary] -and $approval.layout_sha256.Count -eq 4 -and $approval.results -is [array] -and $approval.results.Count -eq 6) 'Original actual candidate/root visual approval absent'
 foreach ($id in $ids) {
  $canonical='res://data/scenes/'+$id+'.tres'; $candidate='res://data/scenes/luoyang_enclosure_v11_candidates/'+$id+'.tres'; $layout='res://data/maps/luoyang_enclosure_v11_candidates/'+$id+'_layout.tres'
  $row=$journal.targets[$canonical]
  Require ($row -is [Collections.IDictionary] -and (SHA-Value $row.original_sha256) -and $row.original_sha256 -ieq $legacyScenes[$id] -and (SHA-Value $row.activated_sha256) -and (SHA-Value $approval.candidate_sha256[$candidate]) -and $row.activated_sha256 -ieq $approval.candidate_sha256[$candidate] -and $row.required_layout_path -is [string] -and $row.required_layout_path -ceq $layout -and (SHA-Value $row.required_layout_sha256) -and $row.required_layout_sha256 -ieq $approval.layout_sha256[$layout]) 'Journal canonical/original/candidate/layout identity mismatch'
 }
 $protected=@{'res://data/scenes/world_map_jianghu.tres'='838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015';'res://data/config/outskirts_native_adoption.json'='203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff'}
 Require (Equal $journal.protected_world_outskirts $protected) 'Protected formal world/outskirts journal differs'
}
# Only functions above are exercised with labelled synthetic metadata by unit.
# Every file below must actually exist; missing formal/cutover artifacts refuse.
# These immutable wrapper digests authorize PATHS ONLY. Their old row digests
# never authorize current/formal bytes, which each formal wrapper freshly guards.
$formalSeedPins=@{
 'res://build/joint_world_luoyang_20261003_qa/443_luoyang_native_npc_candidate_geometry_gpu_20261009/before.json'='8851A165B63E10CAFA765B2C9A5FA16B68E7682F40703A4A4CBE282A4DF49016'
 'res://build/joint_world_luoyang_20261003_qa/446_luoyang_original_candidate_gameplay_headless_20261010/before.json'='9358DB6A0696E4B94657D530C235C4C8749EF147EDC692EE24446F437976D95F'
}
function Check-FormalPathSeedRows($seed) {
 Require ($seed -is [Collections.IDictionary] -and $seed.sources -is [array] -and $seed.sources.Count -eq 4622) 'Exactly original4622 typed path rows required'
 $paths=@{}
 foreach ($row in $seed.sources) {
  Require ($row -is [Collections.IDictionary] -and $row.path -is [string] -and (SHA-Value $row.sha256) -and $row.bytes -is [long] -and $row.bytes -ge 0) 'Malformed original path seed row'
  $path=Source-Path $row.path
  Require (-not $paths.ContainsKey($path) -and (Test-Path -LiteralPath $path -PathType Leaf)) 'Duplicate or missing original source path'
  $paths[$path]=$true
 }
 return $paths
}
function Read-FormalPathSeeds($inputPath) {
 Require ($inputPath -is [string]) 'Pathseed input must be String'
 $path=Evidence-Path $inputPath; $matched=@($formalSeedPins.Keys|Where-Object {(Source-Path $_) -ieq $path})
 Require ($matched.Count -eq 1 -and (Hash $path) -ieq $formalSeedPins[$matched[0]]) 'Only unchanged exact original443/446 pathseed files accepted'
 $seed=Read-Record $path; $paths=Check-FormalPathSeedRows $seed
 return @{path=$path;sha256=$formalSeedPins[$matched[0]];paths=$paths;old_row_digest_credit=$false}
}
function Check-CandidateProvenanceRow($row,$slots) {
 Require ($row -is [Collections.IDictionary] -and $row.path -is [string] -and $row.phase -is [string] -and $row.phase -cin @('geometry','gameplay','save') -and $row.backend -is [string] -and $row.backend -cin @('headless','gpu') -and $slots.Add($row.phase+'/'+$row.backend) -and (SHA-Value $row.sha256) -and $row.actual_os_exit -is [long] -and $row.actual_os_exit -eq 0 -and $row.complete_stderr_reviewed -is [bool] -and $row.complete_stderr_reviewed -and $row.exact_utc_ticks_reviewed -is [bool] -and $row.exact_utc_ticks_reviewed -and $row.source_changes -is [array] -and (Equal $row.source_changes @()) -and $row.player_changes -is [array] -and (Equal $row.player_changes @())) 'Original approval six actual candidate provenance differs'
}

Require ((SHA-Value $ExpectedJournalSHA) -and (SHA-Value $ExpectedApprovalSHA)) 'Explicit root-provided evidence SHA required'
$journalPath=Source-Path $JournalPath; $approvalPath=Source-Path $ApprovalPath
$recovery=Join-Path $game 'build\luoyang_enclosure_v11_city_only_cutover'
Require ($journalPath.StartsWith($recovery+'\',[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($journalPath) -ceq 'journal.json' -and $approvalPath -ieq (Join-Path $game 'build\luoyang_enclosure_v11_city_only_approval.json')) 'Exact retained journal/approval domains required'
Require ((Hash $journalPath) -ieq $ExpectedJournalSHA -and (Hash $approvalPath) -ieq $ExpectedApprovalSHA) 'Actual journal/approval current SHA differs'
$journal=Read-Record $journalPath; $approval=Read-Record $approvalPath
$approvalRes='res://build/luoyang_enclosure_v11_city_only_approval.json'
Check-JournalMetadata $journal $approval $approvalRes $ExpectedApprovalSHA
# Original six candidate evidence bound by approved rows; no formal report may
# feed activation and no diagnostic result can replace an approved endpoint.
$candidateSlots=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($row in $approval.results) {
 Check-CandidateProvenanceRow $row $candidateSlots
 $path=Evidence-Path $row.path; Require ((Hash $path) -ieq $row.sha256) 'Original candidate result changed'
 $candidate=Read-Record $path
 Require ($candidate -is [Collections.IDictionary] -and $candidate.scope -is [string] -and $candidate.scope -ceq 'LUOYANG_ENCLOSURE_V11_CITY_ONLY_FRESH_ACTUAL' -and $candidate.complete -is [bool] -and $candidate.complete -and $candidate.failures -is [long] -and $candidate.failures -eq 0 -and $candidate.mode -is [Collections.IDictionary] -and $candidate.mode.candidate -is [bool] -and $candidate.mode.candidate -and $candidate.mode.phase -is [string] -and $candidate.mode.phase -ceq $row.phase -and $candidate.actual_audio_driver -is [string] -and $candidate.actual_audio_driver -ceq 'WASAPI') 'Original approval points at non-candidate/partial evidence'
}
$canonicalSHAs=[ordered]@{}; $layoutSHAs=[ordered]@{}
$journalDirectory=[IO.Path]::GetDirectoryName($journalPath)
foreach ($id in $ids) {
 $canonical='res://data/scenes/'+$id+'.tres'; $row=$journal.targets[$canonical]
 Require ($row.backup_path -is [string] -and $row.staged_path -is [string]) 'Recovery paths must be String'
 $backup=Source-Path $row.backup_path; $staged=Source-Path $row.staged_path
 Require ($backup -ieq (Join-Path $journalDirectory ('original_'+$id+'.tres')) -and $staged -ieq (Join-Path $journalDirectory ('new_'+$id+'.tres')) -and (Hash $backup) -ieq $row.original_sha256 -and (Hash $staged) -ieq $row.activated_sha256) 'Recovery exact bytes/paths unavailable'
 Require ((Hash (Source-Path $canonical)) -ieq $row.activated_sha256 -and (Hash (Source-Path $row.required_layout_path)) -ieq $row.required_layout_sha256) 'Current canonical/layout differ from actual activated bytes'
 $canonicalSHAs[$canonical]=$row.activated_sha256; $layoutSHAs[$row.required_layout_path]=$row.required_layout_sha256
 $evidence[$backup]=Hash $backup; $evidence[$staged]=Hash $staged
}
foreach ($res in $journal.protected_world_outskirts.Keys) { Require ((Hash (Source-Path $res)) -ieq $journal.protected_world_outskirts[$res]) 'World/outskirts changed after cutover' }
$seedBinding=Read-FormalPathSeeds $PathSeedBefore; $seedPath=$seedBinding.path; $seedPaths=$seedBinding.paths
# Independently visited current literal .gd closure, no historical JSON crawling.
$closure=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal); $queue=[Collections.Generic.Queue[string]]::new()
foreach ($key in $required) {$queue.Enqueue($key)}
while ($queue.Count -gt 0) {
 $key=$queue.Dequeue(); if (-not $closure.Add($key)) {continue}; $path=Source-Path ('res://'+$key)
 Require (Test-Path -LiteralPath $path -PathType Leaf) 'Current critical closure file absent'
 foreach ($match in [regex]::Matches([IO.File]::ReadAllText($path),'res://([^"''\r\n]+\.gd)(?=["''\r\n])')) { if ($match.Groups[1].Value -cne 'scripts/dev/activate_luoyang_enclosure_v11_city_only.gd') {$queue.Enqueue($match.Groups[1].Value)} }
}
$required=@($closure|Sort-Object)
$seenRuns=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase); $seenResults=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase); $slots=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$rows=[Collections.Generic.List[object]]::new(); $provenance=[Collections.Generic.List[object]]::new(); $playerChecks=[Collections.Generic.List[object]]::new()
foreach ($run in $WrapperRunDirectories) {
 $directory=Evidence-Path $run; Require ($seenRuns.Add($directory) -and (Test-Path -LiteralPath $directory -PathType Container) -and -not (Test-Path -LiteralPath (Join-Path $directory 'known_failure_abort.json'))) 'Missing/reused/aborted formal wrapper'
 $beforePath=Join-Path $directory 'before.json'; $afterPath=Join-Path $directory 'after.json'; $stdoutPath=Join-Path $directory 'stdout.log'; $stderrPath=Join-Path $directory 'stderr.log'
 $before=Read-Record $beforePath; $after=Read-Record $afterPath; $mode=Check-FormalMode $before
 Require ($slots.Add($mode.phase+'/'+$mode.backend)) 'Duplicate formal phase/backend'
 Require ($after -is [Collections.IDictionary] -and $before.started_utc -is [string] -and $after.after_utc -is [string] -and $after.source_changes -is [array] -and $after.player_file_changes -is [array] -and $after.actual_os_exit -is [long] -and $after.actual_os_exit -eq 0 -and (Equal $after.source_changes @()) -and (Equal $after.player_file_changes @()) -and [DateTimeOffset]::Parse($before.started_utc) -gt (Get-Item -LiteralPath $journalPath).LastWriteTimeUtc -and [DateTimeOffset]::Parse($after.after_utc) -gt [DateTimeOffset]::Parse($before.started_utc)) 'Formal process/source/player/timestamp failed or predates activated journal'
 $map=@{}; $duplicates=0
 Require ($before.sources -is [array] -and $before.sources.Count -gt 0) 'Fresh formal firstguard absent'
 foreach ($row in $before.sources) { if (Add-Source $row $map) {$duplicates++} }
 foreach ($path in $seedPaths.Keys) { Require ($map.ContainsKey($path)) 'Formal firstguard missing bounded path seed; old digest cannot authorize it' }
 foreach ($res in @($canonicalSHAs.Keys)+@($layoutSHAs.Keys)+@($approval.source_sha256.Keys)) {
  Bound-Leaf $res $map
  $sha=if ($canonicalSHAs.Contains($res)) {$canonicalSHAs[$res]} elseif ($layoutSHAs.Contains($res)) {$layoutSHAs[$res]} else {$approval.source_sha256[$res]}
  Require ((SHA-Value $sha) -and $map[(Source-Path $res)].sha256 -ieq $sha) 'Formal canonical/layout/approved source firstguard mismatch'
 }
 foreach ($key in $required) { $res='res://'+$key; Bound-Leaf $res $map; Require ($approval.source_sha256.Contains($res)) 'Current critical source not in original approved closure'; $sourceSHAs[$res]=$map[(Source-Path $res)].sha256 }
 $stdout=[IO.File]::ReadAllText($stdoutPath); $stderr=[IO.File]::ReadAllText($stderrPath); $evidence[$stdoutPath]=Hash $stdoutPath; $evidence[$stderrPath]=Hash $stderrPath
 Require ($stdout -notmatch '(?m)^(?:ERROR:|SCRIPT ERROR:)' -and $stderr -notmatch '(?m)^(?:ERROR:|SCRIPT ERROR:)') 'Formal complete logs contain error'
 $gpu=@([regex]::Matches($stdout,'(?m)^OpenGL API [^\r\n]+ - Compatibility - Using Device: [^\r\n]+'))
 if ($before.gpu) { Require ($gpu.Count -eq 1 -and $gpu[0].Value -notmatch '(?i)llvmpipe|softpipe|software|basic render') 'Actual formal hardware OpenGL stdout unavailable' }
 $marker=@([regex]::Matches($stdout,'(?m)^CITY_ONLY_RESULT (res://build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_[0-9_]+/result\.json) checks=([0-9]+) failures=0\s*$'))
 Require ($marker.Count -eq 1) 'Single completed formal result marker required'
 $resultPath=Evidence-Path $marker[0].Groups[1].Value; Require ($seenResults.Add($resultPath)) 'Formal result reused'
 $result=Read-Record $resultPath; Check-FormalResult $result $mode.phase
 Require ($result.checks -eq [long]$marker[0].Groups[2].Value) 'Formal completed stdout/report count differs'
 Check-FullCoverage $result.stage $mode.phase; Check-Players $before.player_files $result
 $playerChecks.Add(@{before=$before.player_files;result=$result})
 foreach ($key in $result.source_before.Keys) { $inner=$result.source_before[$key]; Require ($inner -is [Collections.IDictionary] -and $inner.exists -is [bool]) 'Actually consumed file presence must be Bool'; if ($inner.exists) { $path=Source-Path $key; Require ((SHA-Value $inner.sha256) -and $inner.bytes -is [long] -and $inner.bytes -ge 0 -and $map.ContainsKey($path) -and $map[$path].sha256 -ieq $inner.sha256 -and $map[$path].bytes -eq $inner.bytes) 'Actually consumed formal file lacked fresh outer firstguard' } }
 $warningReview=Check-FullStderr $stderr $map $result
 $rows.Add(@{path=$marker[0].Groups[1].Value;sha256=$evidence[$resultPath];phase=$mode.phase;backend=$mode.backend;actual_os_exit=0;candidate=$false;complete=$true;known_warning_review=$warningReview})
 $provenance.Add(@{wrapper_directory=$directory;before_sha256=$evidence[$beforePath];after_sha256=$evidence[$afterPath];stdout_sha256=$evidence[$stdoutPath];stderr_sha256=$evidence[$stderrPath];fresh_source_count=$map.Count;raw_record_count=$before.sources.Count;identical_duplicate_count=$duplicates;firstguard_use='CURRENT_POST_CUTOVER_SHA_BYTES_NOT_OLD_SEED_DIGESTS';actual_engine_arguments=$before.actual_engine_arguments})
}
Require ($slots.Count -eq 6) 'All three formal phases on BOTH displays mandatory'
foreach ($path in $allSources.Keys) { Require ((Hash $path) -ieq $allSources[$path].sha256 -and (Get-Item -LiteralPath $path).Length -eq $allSources[$path].bytes) 'Formal source changed during six/result read' }
foreach ($path in $evidence.Keys) { Require ((Hash $path) -ceq $evidence[$path]) 'Formal/approval/journal/evidence changed during read' }
foreach ($check in $playerChecks) { Check-Players $check.before $check.result }
Require ((Hash $core) -ieq $coreSHA) 'Read-only shared consumer changed'
Require ((Hash $PSCommandPath) -ceq $selfFirst) 'Formal consumer source changed during evidence read'
$report=[ordered]@{schema=1;scope='POST_CUTOVER_FOUR_CITY_FORMAL_SIX_ACTUAL_EVIDENCE_NOT_SIGNATURE';complete=$true;candidate=$false;world_subject_version=14;historical_compatibility_tested=$false;formal_approved=$false;signature_created=$false;journal_modified=$false;activation_executed=$false;root_independent_actual_and_visual_review_pending=$true;journal_path=$journalPath;journal_sha256=$ExpectedJournalSHA;original_candidate_approval_path=$approvalPath;original_candidate_approval_sha256=$ExpectedApprovalSHA;canonical_sha256=$canonicalSHAs;layout_sha256=$layoutSHAs;source_sha256=$sourceSHAs;results=$rows.ToArray();wrapper_provenance=$provenance.ToArray();path_seed_before=$seedPath;path_seed_file_sha256=$evidence[$seedPath];old_seed_digest_credit=$false;builder_path=$PSCommandPath;builder_sha256=(Hash $PSCommandPath);shared_core_path=$core;shared_core_sha256=$coreSHA;limitations=@('Six formal complete actual endpoints only; ROOT independent actual/current-image judgment still required','No activation/signature/approval/journal mutation; candidate approval is retained input, not new authorization','Path seeds are not old digest credit or independent dynamic-closure approval','Known source-bound warnings retained/not clean; no keyboard/readerfocus/cancel/direct UI capture credit')}
New-Item -ItemType Directory -Path $target|Out-Null
$output=Join-Path $target 'formal_six_actual_evidence_NOT_SIGNATURE.json'
[IO.File]::WriteAllText($output,($report|ConvertTo-Json -Depth 64),[Text.UTF8Encoding]::new($false))
$readback=Get-Content -LiteralPath $output -Raw|ConvertFrom-Json -AsHashtable -Depth 64
Require ($readback.scope -ceq $report.scope -and $readback.results.Count -eq 6 -and $readback.candidate -eq $false -and $readback.formal_approved -eq $false) 'Formal read-only report readback failed'
[pscustomobject]@{path=$output;sha256=(Hash $output);scope=$report.scope;complete=$true;approval_credit=$false;activation_executed=$false}
