param([string]$ProjectRoot='F:\Code\RPG_GAME')
# PURE NEW formal metadata predicates only, labelled synthetic. No actual formal
# six exists here, no consumer top-level/body executes, and no files are written.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\'); $game=Join-Path $project 'game'
$reader=Join-Path $project 'scripts/qa/read_luoyang_city_only_formal_six_actual_evidence_20261010.ps1'
$readerSHA='C278AE5B757073246747283328A2AA8FB4CF25008A29693D362A2694027C8306'
$core=Join-Path $project 'scripts/qa/prepare_luoyang_city_only_actual_six_approval_draft_retry6_20261010.ps1'
$coreSHA='A4A35BB57B63D7172D3E3527D1E81DFBE1CEFFFFA8DA14155B5DBFEF2F6FBA64'
$selfSHA=(Get-FileHash -LiteralPath $PSCommandPath).Hash
foreach ($pair in @(@($reader,$readerSHA),@($core,$coreSHA))) { if ((Get-FileHash -LiteralPath $pair[0]).Hash -cne $pair[1]) {throw 'Pinned NEW metadata consumer/shared function source differs'} }
function Load-Functions([string]$path,[string[]]$names) {
 $tokens=$null; $errors=$null; $ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
 if ($errors.Count -ne 0) {throw 'Source parse fails before AST function-only load'}
 foreach ($name in $names) {
  $matches=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
  if ($matches.Count -ne 1) {throw "Missing/duplicate actual function $name"}
  # Define in script scope, not a temporary local loader scope.
  $body=$matches[0].Extent.Text -replace ('^function '+[regex]::Escape($name)+'\('),('function script:'+ $name+'(')
  Invoke-Expression $body
 }
 return $ast
}
$coreAst=Load-Functions $core @('Require','Equal','Hash','Read-Record','Source-Path','Evidence-Path','Check-UnknownVersions')
$readerAst=Load-Functions $reader @('SHA-Value','Check-FormalMode','Check-FormalResult','Check-FullCoverage','Check-JournalMetadata','Check-FormalPathSeedRows','Read-FormalPathSeeds','Check-CandidateProvenanceRow')
foreach ($pair in @(@($coreAst,'$entry'),@($coreAst,'$engineSHA'),@($coreAst,'$ids'),@($readerAst,'$legacyScenes'),@($readerAst,'$formalSeedPins'))) {
 $assignments=@($pair[0].FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -ceq $pair[1]},$true))
 if ($assignments.Count -ne 1) {throw 'Missing/duplicate fixed metadata table'}
 Invoke-Expression $assignments[0].Extent.Text
}
$domain=Join-Path $game 'build/joint_world_luoyang_20261003_qa'; $evidence=@{}
$checks=0
function Test([bool]$ok,[string]$label) {$script:checks++; if (-not $ok) {throw "FORMAL PURE FAIL: $label"}}
function Reject([scriptblock]$call,[string]$label) {$rejected=$false;try{& $call|Out-Null}catch{$rejected=$true};Test $rejected $label}
function Clone($value) {return ($value|ConvertTo-Json -Depth 100|ConvertFrom-Json -AsHashtable -Depth 100)}
# This is ONLY an independently constructed CLI metadata fixture, no process.
function Mode-Fixture([string]$phase,[bool]$gpu) {
 $flags=@('--luoyang-city-only-fresh','--fresh-start-only',('--city-qa-phase='+$phase)); if($gpu){$flags+='--qa-gpu-approved'}
 $actual=@('--audio-driver','WASAPI')
 if($gpu){$actual+=@('--rendering-method','gl_compatibility')}else{$actual+=@('--display-driver','headless')}
 $actual+=@('--')+@($flags)
 return @{entry=$entry;gpu=$gpu;requested_audio_driver='WASAPI';user_arguments=$flags;actual_engine_arguments=$actual}
}
foreach ($phase in @('geometry','gameplay','save')) { foreach($gpu in @($false,$true)) {
 $before=Mode-Fixture $phase $gpu
 $mode=Check-FormalMode $before
 Test ($mode.phase -ceq $phase -and $mode.backend -ceq $(if($gpu){'gpu'}else{'headless'})) ('synthetic legal formal mode '+$phase+'/'+$gpu)
 foreach($flag in @('--luoyang-v3-candidate','--luoyang-enclosure-v11-candidate','--candidate-before-cutover','--outskirts-candidate-preview','--qa-phase=release')) {
  $bad=Clone $before; $bad.user_arguments+=@($flag); $bad.actual_engine_arguments+=@($flag)
  Reject {Check-FormalMode $bad} ('candidate/old/mixed flag '+$flag)
 }
 $bad=Clone $before; $bad.actual_engine_arguments=@('--headless')+@($bad.actual_engine_arguments)
 Reject {Check-FormalMode $bad} 'headless shorthand rejected'
 $bad=Clone $before; $bad.requested_audio_driver='Dummy'
 Reject {Check-FormalMode $bad} 'Dummy declaration'
 $bad=Clone $before; $bad.actual_engine_arguments[1]='Dummy'
 Reject {Check-FormalMode $bad} 'actual Dummy request'
 $bad=Clone $before; $bad.user_arguments+=@($bad.user_arguments[0]);$bad.actual_engine_arguments+=@($bad.user_arguments[0])
 Reject {Check-FormalMode $bad} 'duplicate formal flag'
 $bad=Clone $before; $bad.actual_engine_arguments[-1]='different'
 Reject {Check-FormalMode $bad} 'wrapper/actual argument mismatch'
}}
Reject {Check-FormalMode (Mode-Fixture 'source' $false)} 'source cannot fill formal endpoint'
$base=@{scope='LUOYANG_ENCLOSURE_V11_CITY_ONLY_FRESH_ACTUAL';complete=$true;failures=[long]0;checks=[long]1;mode=@{phase='geometry';candidate=$false};world_subject_version=[long]14;historical_compatibility_tested=$false;actual_audio_driver='WASAPI';engine_sha256=$engineSHA;checkpoint_suspension=@{before_any_await=$true;restored_before_exit=$false};source_before=@{synthetic=@{exists=$true;sha256=('1'*64);bytes=[long]1}};source_after=@{synthetic=@{exists=$true;sha256=('1'*64);bytes=[long]1}};stage=@{complete=$true;failures=[long]0;candidate_before_cutover=$false}}
Check-FormalResult $base 'geometry'; Test $true 'synthetic formal result metadata only'
foreach($phase in @('gameplay','save')) {
 $fixture=Clone $base; $fixture.mode.phase=$phase
 if($phase -ceq 'save') {$fixture.stage.new_game=@{candidate_reset_uses_formal_baseline=$false}}
 Check-FormalResult $fixture $phase; Test $true ('synthetic formal metadata '+$phase)
 if($phase -ceq 'save') {$fixture.stage.new_game.candidate_reset_uses_formal_baseline=$true;Reject {Check-FormalResult $fixture 'save'} 'formal NewGame cannot claim candidate baseline'}
}
foreach($key in @('complete','historical_compatibility_tested')) {
 $bad=Clone $base; $bad[$key]=1
 Reject {Check-FormalResult $bad 'geometry'} ('wrongtyped metadata '+$key)
}
foreach($value in @($true,'false',0)) {
 $bad=Clone $base; $bad.mode.candidate=$value
 Reject {Check-FormalResult $bad 'geometry'} 'candidate/wrongtype result'
}
$bad=Clone $base;$bad.stage.candidate_before_cutover=$true
Reject {Check-FormalResult $bad 'geometry'} 'internal candidate selected'
$bad=Clone $base;$bad.complete=$false
Reject {Check-FormalResult $bad 'geometry'} 'partial result'
$bad=Clone $base;$bad.failures=[long]1
Reject {Check-FormalResult $bad 'geometry'} 'actual fail cannot fill endpoint'
$bad=Clone $base;$bad.source_after.synthetic.bytes=[long]2
Reject {Check-FormalResult $bad 'geometry'} 'internal source bytes differ'
$bad=Clone $base;$bad.world_subject_version='14'
Reject {Check-FormalResult $bad 'geometry'} 'string world version'
$bad=Clone $base;$bad.actual_audio_driver='Dummy'
Reject {Check-FormalResult $bad 'geometry'} 'actual Dummy result'
$bad=Clone $base;$bad.checkpoint_suspension.restored_before_exit=$true
Reject {Check-FormalResult $bad 'geometry'} 'checkpoint restored before process exit'
Reject {Check-FormalResult $base 'source'} 'diagnostic result phase'
# Structural counts only. Placeholder arrays are not actual route/Physics proof.
$regions=@();for($n=0;$n -lt 4;$n++){$count=if($n -eq 3){19}else{20};$regions+=@(@{id=$ids[$n];physical_and_current_alpha=@{routes=@(1..5);objects=@(1..$count)}})}
$geometry=@{records=@{regions=$regions}}
Check-FullCoverage $geometry 'geometry';Test $true 'synthetic geometry structural count'
$bad=Clone $geometry;$bad.records.regions[3].id=$ids[0]
Reject {Check-FullCoverage $bad 'geometry'} 'duplicate district'
$bad=Clone $geometry;$bad.records.regions[0].physical_and_current_alpha.objects=@(1..19)
Reject {Check-FullCoverage $bad 'geometry'} 'missing object coverage'
$play=@{records=@{npcs=@(1..30);interactions=@(1..22);portals=@(1..24);bounties=@(1..2);interaction_negatives=@{complete=$true}}}
Check-FullCoverage $play 'gameplay';Test $true 'synthetic gameplay structural count'
foreach($key in @('npcs','interactions','portals','bounties')){$bad=Clone $play;$bad.records[$key]=@($bad.records[$key]|Select-Object -SkipLast 1);Reject {Check-FullCoverage $bad 'gameplay'} ('missing gameplay coverage '+$key)}
$unknown=@();$saveRows=@()
foreach($id in $ids) {
 foreach($version in @([long]2,[long]99,[double]1.5,'3',$true)) {$unknown+=@(@{scene_id=$id;version_domain='local';version=$version;loaded=$false;zero_mutation=$true;before=@{synthetic=[long]1};after=@{synthetic=[long]1}})}
 $birth=@{raw_full_feet_clear=$true;actual_Physics_clear=$true;position_matches_saved=$true}
 $saveRows+=@(@{scene_id=$id;passed=$true;births=@($birth,$birth)})
}
$save=@{scope='LUOYANG_ENCLOSURE_V11_FOUR_CURRENT_SAVE_LOAD_FIELD_BIRTH';records=$saveRows;unknown_records=$unknown;new_game=@{complete=$true};world_coordinate_version=[long]14;city_layout_version=[long]3}
Check-FullCoverage $save 'save';Test $true 'synthetic current-save structural matrix only'
$bad=Clone $save;$bad.unknown_records[0].version=$true
Reject {Check-FullCoverage $bad 'save'} 'typed unknown matrix duplicate/missing number2'
$bad=Clone $save;$bad.unknown_records[0].loaded=$true
Reject {Check-FullCoverage $bad 'save'} 'unknown version actually loaded'
$bad=Clone $save;$bad.records[0].births[0].actual_Physics_clear=$false
Reject {Check-FullCoverage $bad 'save'} 'current-save birth Physics false'
$bad=Clone $save;$bad.new_game.complete=$false
Reject {Check-FullCoverage $bad 'save'} 'NewGame incomplete'
# Journal/approval schema fixture cannot pass actual hash/file/cutover predicates.
$approvalSHA='a'*64;$approvalRes='res://build/luoyang_enclosure_v11_city_only_approval.json'
$approval=@{status='ROOT_APPROVED_FOUR_CITY_FRESH_CANDIDATE';art_current_images_approved=$true;world_subject_version=[long]14;historical_compatibility_tested=$false;source_sha256=@{synthetic=('1'*64)};candidate_sha256=@{};layout_sha256=@{};results=@(1..6)}
$journal=@{schema_version=[long]1;scope='LUOYANG_FOUR_CITY_ONLY_FRESH';state='ACTIVATED_REQUIRES_FRESH_FORMAL_NO_FLAGS_QA';historical_compatibility_tested=$false;formal_no_flags_qa='NOT_RUN';approval_path=$approvalRes;approval_sha256=$approvalSHA;targets=@{};protected_world_outskirts=@{'res://data/scenes/world_map_jianghu.tres'='838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015';'res://data/config/outskirts_native_adoption.json'='203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff'}}
foreach($id in $ids){
 $canonical='res://data/scenes/'+$id+'.tres';$candidate='res://data/scenes/luoyang_enclosure_v11_candidates/'+$id+'.tres';$layout='res://data/maps/luoyang_enclosure_v11_candidates/'+$id+'_layout.tres'
 $approval.candidate_sha256[$candidate]='2'*64;$approval.layout_sha256[$layout]='3'*64
 $journal.targets[$canonical]=@{original_sha256=$legacyScenes[$id];activated_sha256=('2'*64);required_layout_path=$layout;required_layout_sha256=('3'*64)}
}
Check-JournalMetadata $journal $approval $approvalRes $approvalSHA;Test $true 'synthetic journal schema only'
foreach($state in @('PREPARED','ROLLED_BACK','RECOVERY_REQUIRED','ACTIVATED')){$bad=Clone $journal;$bad.state=$state;Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} ('wrong activation state '+$state)}
$bad=Clone $journal;$bad.approval_sha256='b'*64
Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} 'wrong original approval SHA'
$bad=Clone $approval;$bad.status='PENDING_ROOT_ACTUAL_SIX_AND_VISUAL_APPROVAL'
Reject {Check-JournalMetadata $journal $bad $approvalRes $approvalSHA} 'pending candidate not root approved'
$bad=Clone $approval;$bad.art_current_images_approved=$false
Reject {Check-JournalMetadata $journal $bad $approvalRes $approvalSHA} 'visual not approved'
$bad=Clone $approval;$bad.results=@(1..5)
Reject {Check-JournalMetadata $journal $bad $approvalRes $approvalSHA} 'missing candidate six'
foreach($field in @('original_sha256','activated_sha256','required_layout_sha256','required_layout_path')){
 $bad=Clone $journal;$bad.targets['res://data/scenes/ch4_s1_luoyang_yamen.tres'][$field]='wrong'
 Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} ('wrong canonical/layout binding '+$field)
}
$bad=Clone $journal;$bad.targets.Remove('res://data/scenes/ch4_s1_luoyang_yamen.tres')
Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} 'missing canonical target'
$bad=Clone $journal;$bad.protected_world_outskirts['res://data/scenes/world_map_jianghu.tres']='0'*64
Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} 'world altered'
$absent=Join-Path $game ('build/qa_missing_formal_evidence_'+[guid]::NewGuid().ToString('N')+'/journal.json')
Reject {Hash $absent} 'actual absent formal journal file refuses rather than fake approval'

# Type negatives use same String contents wrapped in an Array, not just wrong
# values: PowerShell comparison truthiness must not authorize metadata arrays.
$modeBase=Mode-Fixture 'geometry' $false
foreach ($key in @('entry','requested_audio_driver')) {
 foreach ($value in @(@{v=@($modeBase[$key])},@{v=[long]1},@{v=$null})) {
  $bad=Clone $modeBase; $bad[$key]=$value.v
  Reject {Check-FormalMode $bad} ('strict String mode '+$key)
 }
}
$bad=Clone $modeBase;$bad.gpu=[long]0;Reject {Check-FormalMode $bad} 'GPU Bool only'
for($i=0;$i -lt $modeBase.actual_engine_arguments.Count;$i++) {
 foreach($wrong in @(@{v=@($modeBase.actual_engine_arguments[$i])},@{v=$null},@{v=[long]1})) {
  $bad=Clone $modeBase;$bad.actual_engine_arguments[$i]=$wrong.v
  Reject {Check-FormalMode $bad} ('actual argument String at '+$i)
 }
}
for($i=0;$i -lt $modeBase.user_arguments.Count;$i++) {
 foreach($wrong in @(@{v=@($modeBase.user_arguments[$i])},@{v=$null},@{v=[long]1})) {
  $bad=Clone $modeBase;$bad.user_arguments[$i]=$wrong.v
  Reject {Check-FormalMode $bad} ('user argument String at '+$i)
 }
}
foreach($key in @('scope','actual_audio_driver','engine_sha256')) {
 $bad=Clone $base;$bad[$key]=@($base[$key])
 Reject {Check-FormalResult $bad 'geometry'} ('strict String result '+$key)
}
$bad=Clone $base;$bad.mode.phase=@('geometry');Reject {Check-FormalResult $bad 'geometry'} 'phase String only'
Reject {Check-FormalResult $base @('geometry')} 'explicit phase argument String only'
foreach($key in @('checks','failures','world_subject_version')) {
 foreach($value in @(@{v=[double]$base[$key]},@{v=[string]$base[$key]},@{v=$false})) {
  $bad=Clone $base;$bad[$key]=$value.v;Reject {Check-FormalResult $bad 'geometry'} ('result Int64 '+$key)
 }
}
foreach($key in @('before_any_await','restored_before_exit')) {
 $bad=Clone $base;$bad.checkpoint_suspension[$key]=[long]0
 Reject {Check-FormalResult $bad 'geometry'} ('checkpoint Bool '+$key)
}
$bad=Clone $base;$bad.stage.failures=[double]0;Reject {Check-FormalResult $bad 'geometry'} 'stage failure Int64'
$bad=Clone $base;$bad.stage.complete=1;Reject {Check-FormalResult $bad 'geometry'} 'stage complete Bool'
$bad=Clone $base;$bad.stage.candidate_before_cutover=0;Reject {Check-FormalResult $bad 'geometry'} 'internal candidate Bool'
$bad=Clone $geometry;$bad.records.regions[0].id=@($ids[0]);Reject {Check-FullCoverage $bad 'geometry'} 'geometry id String only'
$bad=Clone $play;$bad.records.interaction_negatives.complete=1;Reject {Check-FullCoverage $bad 'gameplay'} 'negatives Bool only'
$bad=Clone $save;$bad.scope=@($save.scope);Reject {Check-FullCoverage $bad 'save'} 'save scope String only'
foreach($key in @('world_coordinate_version','city_layout_version')) {
 $bad=Clone $save;$bad[$key]=[string]$save[$key];Reject {Check-FullCoverage $bad 'save'} ('save Int64 '+$key)
}
$bad=Clone $save;$bad.records[0].scene_id=@($ids[0]);Reject {Check-FullCoverage $bad 'save'} 'save scene String only'
$bad=Clone $save;$bad.records[0].passed=1;Reject {Check-FullCoverage $bad 'save'} 'save passed Bool only'
$bad=Clone $save;$bad.new_game.complete=1;Reject {Check-FullCoverage $bad 'save'} 'NewGame Bool only'
foreach($key in @('raw_full_feet_clear','actual_Physics_clear','position_matches_saved')) {
 $bad=Clone $save;$bad.records[0].births[0][$key]=1;Reject {Check-FullCoverage $bad 'save'} ('birth Bool '+$key)
}
foreach($key in @('scope','state','formal_no_flags_qa','approval_path','approval_sha256')) {
 $bad=Clone $journal;$bad[$key]=@($journal[$key])
 Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} ('journal String '+$key)
}
$bad=Clone $journal;$bad.schema_version=[double]1;Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} 'journal schema Int64'
$bad=Clone $approval;$bad.status=@($approval.status);Reject {Check-JournalMetadata $journal $bad $approvalRes $approvalSHA} 'approval status String'
$bad=Clone $approval;$bad.world_subject_version='14';Reject {Check-JournalMetadata $journal $bad $approvalRes $approvalSHA} 'approval version Int64'
foreach($key in @('historical_compatibility_tested','art_current_images_approved')) {
 $bad=Clone $approval;$bad[$key]=[long]0;Reject {Check-JournalMetadata $journal $bad $approvalRes $approvalSHA} ('approval Bool '+$key)
}
$bad=Clone $journal;$bad.historical_compatibility_tested=0;Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} 'journal historical Bool'
foreach($key in @('candidate_sha256','layout_sha256')) {
 $bad=Clone $approval;$first=@($bad[$key].Keys)[0];$bad[$key][$first]=@($bad[$key][$first])
 Reject {Check-JournalMetadata $journal $bad $approvalRes $approvalSHA} ('approval SHA String '+$key)
}
Reject {Check-JournalMetadata $journal $approval @($approvalRes) $approvalSHA} 'explicit approval origin String'
Reject {Check-JournalMetadata $journal $approval $approvalRes @($approvalSHA)} 'explicit approval SHA String'
foreach($field in @('original_sha256','activated_sha256','required_layout_sha256','required_layout_path')) {
 $bad=Clone $journal;$row=$bad.targets['res://data/scenes/ch4_s1_luoyang_yamen.tres'];$row[$field]=@($row[$field])
 Reject {Check-JournalMetadata $bad $approval $approvalRes $approvalSHA} ('journal target String '+$field)
}
$candidateRow=@{path='res://build/joint_world_luoyang_20261003_qa/synthetic/result.json';phase='geometry';backend='headless';sha256=('1'*64);actual_os_exit=[long]0;complete_stderr_reviewed=$true;exact_utc_ticks_reviewed=$true;source_changes=@();player_changes=@()}
Check-CandidateProvenanceRow $candidateRow ([Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal));Test $true 'synthetic candidate row metadata only'
foreach($key in @('path','phase','backend','sha256')) {
 $bad=Clone $candidateRow;$bad[$key]=@($candidateRow[$key])
 Reject {Check-CandidateProvenanceRow $bad ([Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal))} ('candidate row String '+$key)
}
foreach($key in @('complete_stderr_reviewed','exact_utc_ticks_reviewed')) {
 $bad=Clone $candidateRow;$bad[$key]=1
 Reject {Check-CandidateProvenanceRow $bad ([Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal))} ('candidate receipt Bool '+$key)
}
$bad=Clone $candidateRow;$bad.actual_os_exit=[double]0;Reject {Check-CandidateProvenanceRow $bad ([Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal))} 'actual OS Int64 only'
# Known immutable seed JSONs are consumed read-only by the REAL private reader.
# This grants only PATH schema/identity credit, never old digests or formal QA.
foreach($res in $formalSeedPins.Keys) {
 $binding=Read-FormalPathSeeds $res
 Test ($binding.paths.Count -eq 4622 -and $binding.old_row_digest_credit -is [bool] -and -not $binding.old_row_digest_credit) 'actual fixed original seed PATHS ONLY'
}
$seedRes=@($formalSeedPins.Keys|Sort-Object)[0];$seed=Read-Record (Evidence-Path $seedRes)
$seedFixture=@{sources=@($seed.sources)}
foreach($key in @('path','sha256','bytes')) {
 foreach($mutation in @('missing','array','wrongtype')) {
  $bad=@{sources=@($seed.sources)};$row=@{};foreach($field in $seed.sources[0].Keys){$row[$field]=$seed.sources[0][$field]};$bad.sources[0]=$row
  if($mutation -ceq 'missing'){$row.Remove($key)}
  elseif($mutation -ceq 'array'){$row[$key]=@($row[$key])}
  else{$row[$key]=if($key -ceq 'bytes'){[string]$row[$key]}else{[long]1}}
  Reject {Check-FormalPathSeedRows $bad} ('actual seed schema '+$key+'/'+$mutation)
 }
}
$bad=@{sources=@($seed.sources)};$bad.sources[1]=$seed.sources[0];Reject {Check-FormalPathSeedRows $bad} 'duplicate original seed path'
$bad=@{sources=@($seed.sources|Select-Object -SkipLast 1)};Reject {Check-FormalPathSeedRows $bad} 'wrong original seed count'
$bad=@{sources=@($seed.sources)};$bad.sources[0]=@{path=$absent;sha256=('1'*64);bytes=[long]0};Reject {Check-FormalPathSeedRows $bad} 'missing original source file'
Reject {Read-FormalPathSeeds $absent} 'unknown seed path even if caller supplies a path'
Reject {Read-FormalPathSeeds @($seedRes)} 'seed path String only'
$originalSeedPin=$formalSeedPins[$seedRes];try {
 $formalSeedPins[$seedRes]='0'*64
 Reject {Read-FormalPathSeeds $seedRes} 'real fixed seed current SHA differs from required pin'
} finally {$formalSeedPins[$seedRes]=$originalSeedPin}
foreach($path in $evidence.Keys){Test ((Hash $path) -ceq $evidence[$path]) 'consumed actual seed JSON unchanged'}

Test ((Get-FileHash $reader).Hash -ceq $readerSHA -and (Get-FileHash $core).Hash -ceq $coreSHA -and (Get-FileHash $PSCommandPath).Hash -ceq $selfSHA) 'all three read-only sources unchanged'
[ordered]@{scope='PURE_SYNTHETIC_FORMAL_METADATA_SCHEMA_NOT_ACTUAL_FORMAL_OR_CUTOVER';checks=$checks;failures=0;reader_sha256=$readerSHA;shared_pure_source_sha256=$coreSHA;actual_formal_six_executed=$false;actual_journal_positive_consumed=$false;actual_fixed_seed_path_schema_consumed=$true;old_seed_digest_credit=$false;actual_field_credit=$false;approval_credit=$false;signature_created=$false;files_written=$false}|ConvertTo-Json -Depth 5

