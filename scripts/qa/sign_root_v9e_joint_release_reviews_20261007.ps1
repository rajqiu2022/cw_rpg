<#
SOURCE-ONLY preparation; executing without both explicit ROOT confirmations refuses.
Run only AFTER the real candidate headless/GPU RELEASE processes and ROOT's
current world/city/outskirts PNG + complete stdout/stderr/warnings review:
  powershell -NoProfile -File scripts/qa/sign_root_v9e_joint_release_reviews_20261007.ps1 `
    -DraftDirectory 'F:/Code/RPG_GAME/game/build/joint_world_luoyang_20261003_qa/v9e_joint_release_review_drafts_ACTUAL/' `
    -ExpectedTechnicalDraftSha256 ACTUAL_64_HEX -ExpectedVisualDraftSha256 ACTUAL_64_HEX `
    -RootReviewer 'ROOT producer actual review identity' `
    -ConfirmRootReviewedCurrentPngAndCompleteLogs -ConfirmRootIndependentTechnicalReleaseReview
Pure synthetic schema/promotion units, no file reads/writes or approval:
  powershell -NoProfile -File scripts/qa/sign_root_v9e_joint_release_reviews_20261007.ps1 -RunPureUnitTests
Syntax only:
  powershell -NoProfile -File scripts/qa/sign_root_v9e_joint_release_reviews_20261007.ps1 -ValidateSourceOnly

Not a renderer, test runner, GATE predicate replacement or cutover. ROOT-selected
drafts come from prepare_joint_v9e_joint_release_review_drafts_20261007.gd, which
already validates the complete GATE.snapshot and all unchanged RELEASE predicates.
This helper preserves that exact snapshot/actual_runs, rehashes every supplied
snapshot path and run evidence, and signs ONLY two fixed review JSON paths.
Existing reviews are NEVER overwritten. Unique BUILD receipt retains exact draft
bytes and records partial writes on failure; there is no automatic rollback/delete.
The final production GATE must independently accept both reviews before activation.
#>
[CmdletBinding()]
param(
  [string]$DraftDirectory = '',
  [string]$ExpectedTechnicalDraftSha256 = '',
  [string]$ExpectedVisualDraftSha256 = '',
  [string]$RootReviewer = '',
  [switch]$ConfirmRootReviewedCurrentPngAndCompleteLogs,
  [switch]$ConfirmRootIndependentTechnicalReleaseReview,
  [switch]$RunPureUnitTests,
  [switch]$ValidateSourceOnly,
  [switch]$FreshStartOnly,
  [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
if ($RunPureUnitTests -and $ValidateSourceOnly) { throw 'Choose one source-only mode' }
if (!$RunPureUnitTests -and !$ValidateSourceOnly) {
  if (!$ConfirmRootReviewedCurrentPngAndCompleteLogs -or !$ConfirmRootIndependentTechnicalReleaseReview) { throw 'Both explicit ROOT current-PNG/complete-log and independent technical review confirmations are required' }
  if (!$DraftDirectory -or !$ExpectedTechnicalDraftSha256 -or !$ExpectedVisualDraftSha256 -or !$RootReviewer.Trim()) { throw 'Explicit draft directory, both expected draft hashes and ROOT reviewer identity are required' }
}
$taskWorkspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$signProgram = @'
import argparse, copy, datetime, hashlib, json, math, pathlib, re, sys, uuid

QA_DOMAIN = 'res://build/joint_world_luoyang_20261003_qa/'
GATE = 'res://scripts/dev/joint_world_city_v15_release_acceptance.gd'
PREPARER = 'res://tests/helpers/prepare_joint_v9e_joint_release_review_drafts_20261007.gd'
ENTRY = 'res://tests/test_joint_world_luoyang_v15_release_20261005.gd'
SELECTION = QA_DOMAIN+'release_selection_root234_20261005_01/representative_selection.json'
SELECTION_SHA = '34a6ffd4b6da7adfc953c7339e1398c5a77e6f112399e4361350050246c4704f'
PHASE = 'JOINT_RELEASE_RISK_STRATIFIED_ACTUAL_FIELD_INPUT'
SCOPE = 'JOINT_RELEASE_RISK_STRATIFIED_NORMAL_GAMEPLAY_NOT_EXHAUSTIVE_FULL'
FRESH_PHASE = 'JOINT_FRESH_START_CURRENT_FORMAT_ACTUAL_FIELD_INPUT'
FRESH_FROZEN_SCOPE = 'JOINT_FROZEN_FRESH_START_CURRENT_FORMAT_INPUTS'
EXCLUDED_HISTORY = {'world':[12,13,14],'local':[1]}
FRESH_START = False
OUTPUTS = {'technical':'res://data/maps/joint_world_city_v15_release_technical_review.json',
           'visual':'res://data/maps/joint_world_city_v15_release_visual_review.json'}
METHODS = {'technical':'independent_risk_stratified_release_normal_gameplay_field_input',
           'visual':'actual_world_city_outskirts_png_individual_review'}
PENDING = {'technical':'PENDING_ROOT_INDEPENDENT_TECHNICAL_REVIEW',
           'visual':'PENDING_ROOT_ACTUAL_PNG_INDIVIDUAL_REVIEW'}

def configure_mode(fresh_start):
    global FRESH_START, PHASE, SCOPE
    FRESH_START = fresh_start
    PHASE = FRESH_PHASE if fresh_start else 'JOINT_RELEASE_RISK_STRATIFIED_ACTUAL_FIELD_INPUT'
    SCOPE = FRESH_PHASE if fresh_start else 'JOINT_RELEASE_RISK_STRATIFIED_NORMAL_GAMEPLAY_NOT_EXHAUSTIVE_FULL'

def mode_fields():
    return {'fresh_start_only':True,'historical_compatibility_tested':False,
      'excluded_historical_versions':copy.deepcopy(EXCLUDED_HISTORY),
      'excluded_world_source_versions':[12,13,14],'excluded_local_source_versions':[1]} if FRESH_START else {}

def validate_mode(row, scope=None):
    if not FRESH_START:
        need(row.get('fresh_start_only') is None or row.get('fresh_start_only') is False,'Fresh-start evidence requires explicit fresh-start signer mode')
        return
    for key,value in mode_fields().items():
        actual=row.get(key)
        need(type(actual) is type(value) and actual==value,'Exact fresh-start metadata: '+key)
    for key,expected in [('excluded_world_source_versions',[12,13,14]),('excluded_local_source_versions',[1])]:
        actual=row[key]
        need(len(actual)==len(expected) and all(number(a,b) for a,b in zip(actual,expected)),'Exact numeric excluded versions: '+key)
    excluded=row['excluded_historical_versions']
    need(set(excluded)=={'world','local'} and all(isinstance(excluded[k],list) and len(excluded[k])==len(EXCLUDED_HISTORY[k]) and all(number(a,b) for a,b in zip(excluded[k],EXCLUDED_HISTORY[k])) for k in ('world','local')),'Exact numeric nested excluded historical versions')
    if scope is not None: need(row.get('scope')==scope,'Exact fresh-start scope')

def need(ok, label):
    if not ok: raise ValueError(label)

def sha(value):
    return isinstance(value,str) and re.fullmatch('[0-9a-fA-F]{64}',value) is not None

def number(value, expected):
    return type(value) in (int,float) and math.isfinite(value) and value == expected

def strict_json(data):
    def pairs(rows):
        result = {}
        for key, value in rows:
            need(key not in result,'Duplicate JSON key: '+key)
            result[key] = value
        return result
    return json.loads(data.decode('utf-8-sig'),object_pairs_hook=pairs,
      parse_constant=lambda s: (_ for _ in ()).throw(ValueError('Nonfinite JSON: '+s)))

def encode(value):
    return (json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')

def validate_pair(technical, visual):
    for kind, draft in (('technical',technical),('visual',visual)):
        need(isinstance(draft,dict),'Typed '+kind+' draft')
        validate_mode(draft,SCOPE if FRESH_START else None)
        if FRESH_START: need(draft.get('phase')==PHASE,'Fresh-start review phase')
        need(number(draft.get('schema_version'),1) and number(draft.get('world_coordinate_version'),15) and number(draft.get('city_layout_version'),3),'Exact review versions')
        need(draft.get('status')=='DRAFT_NOT_APPROVED' and draft.get('approved') is False and draft.get('production_approved') is False and draft.get('root_signature_present') is False,'Only unapproved original drafts accepted')
        need(draft.get('reviewer_role')=='producer/root' and draft.get('reviewer')=='','Draft ROOT identity must still be unsigned')
        need(draft.get('legacy_full_executed') is False and draft.get('exhaustive_2687_normal_input_executed') is False,'Legacy/exhaustive false must remain explicit')
        need(draft.get('manual_complete_logs_and_actual_png_review_required') is True,'Explicit manual review requirement')
        need(draft.get('review_method')==PENDING[kind] and draft.get('required_review_method')==METHODS[kind],'Exact pending/final review method')
        need(draft.get(kind+'_approved') is False,'Specific approval must still be false')
        for key,value in draft.items():
            if key=='approved' or key.endswith('_approved'): need(value is False,'No inherited approval: '+key)
        assets = draft.get('asset_sha256')
        need(isinstance(assets,dict) and assets and all(isinstance(p,str) and sha(h) and h==h.lower() for p,h in assets.items()),'Exact nonempty lowercase snapshot bindings')
        need(all(p in assets for p in (GATE,ENTRY,SELECTION)) and assets[SELECTION]==SELECTION_SHA,'Current GATE/entry/immutable selection must be snapshot-bound')
        need(isinstance(draft.get('frozen_inputs_path'),str) and draft['frozen_inputs_path'].startswith(QA_DOMAIN) and sha(draft.get('frozen_inputs_sha256')),'Exact frozen input binding')
        runs = draft.get('actual_runs')
        need(isinstance(runs,dict) and set(runs)=={'headless','gpu'},'Two separate actual modes')
        for mode,run in runs.items():
            need(isinstance(run,dict) and number(run.get('actual_os_exit_code'),0) and run.get('manual_complete_stderr_and_exit_warning_review_required') is True,'Actual OS0/manual full warnings review: '+mode)
            for role in ('result','stdout','stderr','wrapper_before','wrapper_after'):
                evidence = run.get(role)
                need(isinstance(evidence,dict) and set(evidence)=={'path','sha256'} and isinstance(evidence.get('path'),str) and evidence['path'].startswith(QA_DOMAIN) and sha(evidence.get('sha256')),'Bound exact actual evidence: '+mode+'/'+role)
        for role in ('result','stdout','stderr','wrapper_before','wrapper_after'):
            need(runs['headless'][role]['path']!=runs['gpu'][role]['path'],'One process/evidence cannot serve both modes: '+role)
    need(technical['release_complete'] is True and technical['phase']==PHASE and technical['selection_path']==SELECTION and technical['selection_sha256']==SELECTION_SHA,'Exact RELEASE scope/selection')
    need(visual.get('actual_png_individual_review_performed') is False,'Visual draft must still be unreviewed')
    for key in ('asset_sha256','actual_runs','frozen_inputs_path','frozen_inputs_sha256'):
        need(technical[key]==visual[key],'Two drafts must bind identical actual inputs: '+key)

def promote(draft, kind, reviewer, signature):
    output = copy.deepcopy(draft)
    output.update({'status':'ROOT_REVIEW_SIGNED_PENDING_FINAL_GATE_NOT_CUTOVER',
      'approved':True,kind+'_approved':True,'production_approved':False,
      'root_signature_present':True,'reviewer_role':'producer/root','reviewer':reviewer,
      'review_method':METHODS[kind],'scope':SCOPE,'release_complete':True,
      'phase':PHASE,'selection_path':SELECTION,'selection_sha256':SELECTION_SHA,
      'legacy_full_executed':False,'exhaustive_2687_normal_input_executed':False,
      'root_signature':copy.deepcopy(signature)})
    output.update(mode_fields())
    if kind=='visual': output['actual_png_individual_review_performed']=True
    need(output['asset_sha256']==draft['asset_sha256'] and output['actual_runs']==draft['actual_runs'],'Signing may not modify snapshot or actual evidence')
    return output

def pure_units(fresh_start=False):
    configure_mode(fresh_start)
    h='a'*64
    runs={mode:{'actual_os_exit_code':0,'manual_complete_stderr_and_exit_warning_review_required':True,
      **{role:{'path':QA_DOMAIN+'SYNTHETIC_NEVER_EXECUTED/'+mode+'/'+role+'.json','sha256':h}
         for role in ('result','stdout','stderr','wrapper_before','wrapper_after')}} for mode in ('headless','gpu')}
    common={'schema_version':1,'world_coordinate_version':15,'city_layout_version':3,
      'status':'DRAFT_NOT_APPROVED','approved':False,'production_approved':False,
      'root_signature_present':False,'reviewer_role':'producer/root','reviewer':'',
      'legacy_full_executed':False,'exhaustive_2687_normal_input_executed':False,
      'manual_complete_logs_and_actual_png_review_required':True,'asset_sha256':{GATE:h,ENTRY:h,SELECTION:SELECTION_SHA},
      'frozen_inputs_path':QA_DOMAIN+'SYNTHETIC_NEVER_EXECUTED/frozen.json','frozen_inputs_sha256':h,'actual_runs':runs}
    common.update(mode_fields())
    if FRESH_START: common.update({'scope':SCOPE,'phase':PHASE})
    technical=copy.deepcopy(common); visual=copy.deepcopy(common)
    technical.update({'technical_approved':False,'release_complete':True,'phase':PHASE,'selection_path':SELECTION,'selection_sha256':SELECTION_SHA,'review_method':PENDING['technical'],'required_review_method':METHODS['technical']})
    visual.update({'visual_approved':False,'actual_png_individual_review_performed':False,'review_method':PENDING['visual'],'required_review_method':METHODS['visual']})
    validate_pair(technical,visual)
    count=1
    mutations=[('approved',True),('production_approved',True),('root_signature_present',True),('status','APPROVED'),('reviewer','pretend-root'),('reviewer_role','art'),('schema_version',True),('world_coordinate_version',14),('legacy_full_executed',True),('exhaustive_2687_normal_input_executed',True),('review_method',METHODS['technical']),('asset_sha256',{}),('actual_runs',{}),('technical_approved',True),('release_complete',False),('selection_sha256','0'*64),('fresh_start_only',not fresh_start)]
    if FRESH_START:
        mutations += [('historical_compatibility_tested',True),('excluded_historical_versions',{'world':[12,14],'local':[1]}),('excluded_world_source_versions',[12,14]),('excluded_local_source_versions',[]),('scope','JOINT_RELEASE_RISK_STRATIFIED_NORMAL_GAMEPLAY_NOT_EXHAUSTIVE_FULL'),('phase','JOINT_RELEASE_RISK_STRATIFIED_ACTUAL_FIELD_INPUT')]
    for key,value in mutations:
        changed=copy.deepcopy(technical); changed[key]=value
        rejected=False
        try: validate_pair(changed,visual)
        except (ValueError,KeyError,TypeError): rejected=True
        need(rejected,'Synthetic negative accepted: '+key); count+=1
    for kind,draft in (('technical',technical),('visual',visual)):
        before=copy.deepcopy(draft)
        signed=promote(draft,kind,'SYNTHETIC_UNIT_NOT_ROOT_APPROVAL',{'unit_only':True})
        need(draft==before and signed[kind+'_approved'] is True and signed['production_approved'] is False and signed['legacy_full_executed'] is False and signed['exhaustive_2687_normal_input_executed'] is False and signed['review_method']==METHODS[kind],'Pure promotion preservation')
        count+=1
    for role in ('result','stdout','stderr','wrapper_before','wrapper_after'):
        changed=copy.deepcopy(technical)
        changed['actual_runs']['gpu'][role]=copy.deepcopy(changed['actual_runs']['headless'][role])
        rejected=False
        try: validate_pair(changed,visual)
        except ValueError: rejected=True
        need(rejected,'Duplicated two-mode actual evidence accepted: '+role); count+=1
    for key,value in [('actual_png_individual_review_performed',True),('visual_approved',True),('required_review_method','invented'),('frozen_inputs_sha256','0'*64)]:
        changed=copy.deepcopy(visual); changed[key]=value
        rejected=False
        try: validate_pair(technical,changed)
        except ValueError: rejected=True
        need(rejected,'Visual/pair-binding mutation accepted: '+key); count+=1
    rejected=False
    try: strict_json(b'{"a":1,"a":2}')
    except ValueError: rejected=True
    need(rejected,'Duplicate JSON accepted'); count+=1
    print(json.dumps({'scope':'PURE_SYNTHETIC_SIGNER_SCHEMA_UNITS_NOT_APPROVAL_OR_ACTUAL_EVIDENCE','fresh_start_only':fresh_start,'checks':count,'failures':0,'files_read':False,'files_written':False,'engine_executed':False}))

def main(args):
    need(args.confirm_images_logs and args.confirm_technical,'Both explicit ROOT confirmations required')
    need(isinstance(args.reviewer,str) and args.reviewer.strip(),'Explicit ROOT reviewer required')
    need(sha(args.technical_sha) and sha(args.visual_sha),'Both ROOT-selected expected draft SHA256 required')
    root=pathlib.Path(args.root).resolve(); game=(root/'game').resolve()
    domain=(game/'build/joint_world_luoyang_20261003_qa').resolve()
    def disk(path):
        need(isinstance(path,str) and path.startswith('res://') and '..' not in path and '\\' not in path,'Canonical resource path required: '+str(path))
        result=(game/path[6:]).resolve()
        need(result.is_relative_to(game),'Resource escapes workspace')
        return result
    def hash_file(path):
        with path.open('rb') as stream: return hashlib.file_digest(stream,'sha256').hexdigest()
    def read_file(path,expected=None):
        data=path.read_bytes(); digest=hashlib.sha256(data).hexdigest()
        need(expected is None or digest==expected.lower(),'Changed actual bytes: '+str(path))
        return data,digest
    directory=pathlib.Path(args.draft_dir).resolve()
    need(directory.parent==domain and directory.name.startswith('v9e_joint_release_review_drafts_'),'Explicit unique real DRAFT directory in fixed QA domain required')
    draft_bytes={}; drafts={}; draft_hashes={}
    for kind,expected in (('technical',args.technical_sha),('visual',args.visual_sha)):
        path=directory/(kind+'_review_DRAFT.json')
        data,digest=read_file(path,expected)
        draft_bytes[kind]=data; draft_hashes[kind]=digest; drafts[kind]=strict_json(data)
    validate_pair(drafts['technical'],drafts['visual'])
    output_paths={kind:disk(path) for kind,path in OUTPUTS.items()}
    need(all(not p.exists() for p in output_paths.values()),'Existing joint review must never be overwritten')
    current=drafts['technical']['asset_sha256']
    # This is exact rehashing of the ROOT-selected, GATE-prepared snapshot,
    # not a smaller independently invented whitelist or a GATE reimplementation.
    stats={}
    for path,expected in current.items():
        actual=disk(path); before=actual.stat()
        need(hash_file(actual)==expected,'Current actual snapshot changed: '+path)
        after=actual.stat(); signature=(after.st_size,after.st_mtime_ns)
        need((before.st_size,before.st_mtime_ns)==signature,'Snapshot changed while hashing: '+path)
        stats[path]=signature
    gate_text=disk(GATE).read_text(encoding='utf-8-sig')
    phase_constant='FRESH_START_PHASE' if FRESH_START else 'RELEASE_PHASE'
    for key,value in [('VISUAL_REVIEW',OUTPUTS['visual']),('TECHNICAL_REVIEW',OUTPUTS['technical']),('RELEASE_ENTRY',ENTRY),(phase_constant,PHASE),('RELEASE_SELECTION_PATH',SELECTION),('RELEASE_SELECTION_SHA',SELECTION_SHA)]:
        need(re.search(r'(?m)^const '+key+r'\s*:?=\s*"'+re.escape(value)+r'"\s*$',gate_text) is not None,'Current final GATE constant changed: '+key)
    frozen_path=drafts['technical']['frozen_inputs_path']; frozen_sha=drafts['technical']['frozen_inputs_sha256']
    frozen_bytes,_=read_file(disk(frozen_path),frozen_sha); frozen=strict_json(frozen_bytes)
    need(number(frozen.get('schema'),1) and frozen.get('scope')==(FRESH_FROZEN_SCOPE if FRESH_START else 'JOINT_FROZEN_CANDIDATE_INPUTS'),'Actual frozen candidate input scope')
    validate_mode(frozen,FRESH_FROZEN_SCOPE if FRESH_START else None)
    bound={frozen_path:frozen_sha}; wrappers=[]
    for mode,run in drafts['technical']['actual_runs'].items():
        evidence={}
        for role in ('result','stdout','stderr','wrapper_before','wrapper_after'):
            row=run[role]; evidence[role],_=read_file(disk(row['path']),row['sha256']); bound[row['path']]=row['sha256']
        wrapper=run['wrapper_before']['path'].rsplit('/',1)[0]+'/'
        need(run['wrapper_before']['path']==wrapper+'before.json' and run['wrapper_after']['path']==wrapper+'after.json' and run['stdout']['path']==wrapper+'stdout.log' and run['stderr']['path']==wrapper+'stderr.log','Exact common actual wrapper directory')
        before=strict_json(evidence['wrapper_before']); after=strict_json(evidence['wrapper_after']); report=strict_json(evidence['result'])
        need(before.get('entry')==ENTRY and before.get('gpu') is (mode=='gpu'),'Actual wrapper executor and mode')
        need(number(after.get('actual_os_exit'),0) and type(after.get('actual_wrapper_pid')) is int and after['actual_wrapper_pid']>0,'Actual wrapper natural completed OS0')
        need(after.get('source_changes')==[] and after.get('player_file_changes')==[] and isinstance(before.get('player_files'),list) and len(before['player_files'])==15,'Actual source/all15 player preservation')
        wrappers.append(after['actual_wrapper_pid'])
        argv=before.get('user_arguments')
        need(isinstance(argv,list) and '--candidate-before-cutover' in argv and '--qa-frozen-inputs='+frozen_path in argv and (mode!='gpu' or '--qa-gpu-approved' in argv),'Actual candidate/frozen/render invocation')
        need(argv.count('--fresh-start-only')==(1 if FRESH_START else 0),'Actual explicit fresh-start mode cannot mix with old invocation')
        validate_mode(report,SCOPE if FRESH_START else None)
        need(report.get('scope')==SCOPE and report.get('phase')==PHASE and report.get('requested_phase')=='release' and report.get('mode')==mode and report.get('completed') is True and report.get('candidate_before_cutover') is True and report.get('dry_run') is False and report.get('source_complete') is False,'Actual complete candidate RELEASE; not source/unit/partial/formal')
        need(report.get('release_complete') is True and report.get('legacy_full_executed') is False and report.get('exhaustive_2687_normal_input_executed') is False and number(report.get('failed'),0) and number(report.get('failures'),0) and report.get('unfinished_categories')==[],'Actual nonexhaustive RELEASE completion/zero failures')
        need(report.get('frozen_inputs_path')==frozen_path and report.get('frozen_inputs_sha256')==frozen_sha and report.get('frozen_inputs_sha256_before')==frozen_sha and report.get('source_sha256')==current and report.get('executing_script_path')==ENTRY and report.get('executing_script_sha256','').lower()==current[ENTRY],'Actual exact frozen/current snapshot/executor')
        result_directory=run['result']['path'].rsplit('/',1)[0]+'/'
        for name in ('all_actual_sources_before.json','all_actual_sources_after.json'):
            path=result_directory+name; data,digest=read_file(disk(path)); bound[path]=digest
            need(strict_json(data)==current,'Actual retained complete snapshot differs: '+path)
        for role in ('stdout','stderr'):
            text=evidence[role].decode('utf-8-sig')
            need(not any(line.strip().startswith(('ERROR:','SCRIPT ERROR:','Parse Error:','SHADER ERROR:')) for line in text.splitlines()),'Existing GATE error-log predicate failed: '+mode+'/'+role)
        pattern=r'^JOINT_WORLD_CITY_QA: [0-9]+ checks / 0 failures; phase='+PHASE+r'; Field=true GPU='+('true' if mode=='gpu' else 'false')+r'; complete=true visual=NOT_REVIEWED; output='+re.escape(result_directory)+r'\r?$'
        need(len(re.findall(pattern,evidence['stdout'].decode('utf-8-sig'),re.M))==1,'Actual complete stdout must bind exact result directory once')
    need(len(set(wrappers))==2,'Actual headless/GPU wrapper processes must be distinct')
    # Retain exact drafts before signatures. No source, snapshot, art, capture,
    # candidate, production scene, save or activation journal is modified.
    signed_at=datetime.datetime.now(datetime.timezone.utc).isoformat()
    receipt_dir=domain/('v9e_joint_release_review_signature_'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'_'+uuid.uuid4().hex[:8])
    receipt_dir.mkdir()
    signature={'signed_utc':signed_at,'reviewer_role':'producer/root','reviewer':args.reviewer.strip(),
      'signing_script_path':str(pathlib.Path(args.script).resolve()),'signing_script_sha256':hash_file(pathlib.Path(args.script)),
      'draft_directory':str(directory),'expected_draft_sha256':draft_hashes,
      'root_confirmed_current_world_city_outskirts_png_review':True,
      'root_confirmed_complete_actual_headless_GPU_stdout_stderr_and_exit_warning_review':True,
      'root_confirmed_independent_risk_stratified_RELEASE_technical_review':True,
      'current_gate_path':GATE,'current_gate_sha256':current[GATE],
      'preparation_helper_path':PREPARER,'preparation_helper_current_sha256':hash_file(disk(PREPARER)),
      'receipt_directory':str(receipt_dir),'GATE_predicates_reexecuted_by_signer':False,
      'final_GATE_validation_still_required':True,'formal_activation_performed':False,
      'scope_limit':'Risk-stratified RELEASE, not legacy FULL or exhaustive 2687 per-object normal input.'}
    if FRESH_START:
        signature.update(mode_fields())
        signature['scope_limit']='Fresh-start/current-format normal gameplay only; world12/13/14 and local1 compatibility not tested. Not legacy FULL or exhaustive 2687 per-object input.'
    receipt={'scope':'ROOT_EXPLICIT_JOINT_RELEASE_REVIEW_WRITING_RECEIPT_NOT_ACTIVATION','signature':signature,
      'retained_drafts':{},'actual_run_evidence_sha256':bound,'snapshot_path_count':len(current),
      'snapshot_authority':'EXACT_ROOT_SHA_SELECTED_GATE_VALIDATED_DRAFT_SNAPSHOT_REHASHED_NOT_INDEPENDENTLY_REBUILT',
      'status':'PREPARED_NOT_WRITTEN','writes':[]}
    for kind,data in draft_bytes.items():
        retained=receipt_dir/(kind+'_review_DRAFT.json')
        with retained.open('xb') as stream: stream.write(data)
        need(hash_file(retained)==draft_hashes[kind],'Exact draft retention readback')
        receipt['retained_drafts'][kind]={'path':str(retained),'sha256':draft_hashes[kind]}
    receipt_path=receipt_dir/'writing_receipt.json'
    try:
        for path,expected in bound.items(): need(hash_file(disk(path))==expected,'Actual run evidence changed before signature: '+path)
        for kind in drafts: need(hash_file(directory/(kind+'_review_DRAFT.json'))==draft_hashes[kind],'Selected draft changed before signature')
        for path,expected in stats.items():
            stat=disk(path).stat(); need((stat.st_size,stat.st_mtime_ns)==expected,'Snapshot stat changed since exact hashing: '+path)
        need(all(not p.exists() for p in output_paths.values()),'Existing joint review appeared before signature')
        for kind in ('technical','visual'):
            data=encode(promote(drafts[kind],kind,args.reviewer.strip(),signature))
            with output_paths[kind].open('xb') as stream: stream.write(data); stream.flush()
            digest=hashlib.sha256(data).hexdigest()
            receipt['writes'].append({'kind':kind,'path':OUTPUTS[kind],'sha256':digest,'readback_sha256':hash_file(output_paths[kind])})
            need(receipt['writes'][-1]['readback_sha256']==digest,'Signed review exact readback failed')
        receipt['status']='TWO_ROOT_REVIEWS_SIGNED_FINAL_GATE_AND_ACTIVATION_NOT_EXECUTED'
    except Exception as error:
        receipt['status']='FAILED_PARTIAL_OUTPUT_RETAINED_NO_OVERWRITE_OR_AUTO_DELETE'
        receipt['error']=str(error)
        raise
    finally:
        with receipt_path.open('xb') as stream: stream.write(encode(receipt))
        print(json.dumps({'receipt_path':str(receipt_path),'receipt_sha256':hash_file(receipt_path),'status':receipt['status'],'writes':receipt['writes'],'final_GATE_still_required':True,'formal_activation_performed':False},indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('root'); parser.add_argument('script')
    parser.add_argument('--pure-units',action='store_true')
    parser.add_argument('--fresh-start-only',action='store_true')
    parser.add_argument('--draft-dir'); parser.add_argument('--technical-sha'); parser.add_argument('--visual-sha'); parser.add_argument('--reviewer')
    parser.add_argument('--confirm-images-logs',action='store_true'); parser.add_argument('--confirm-technical',action='store_true')
    args=parser.parse_args()
    try:
        if args.pure_units:
            pure_units(False)
            pure_units(True)
        else:
            configure_mode(args.fresh_start_only)
            main(args)
    except Exception as error:
        print('ROOT_JOINT_RELEASE_SIGNATURE_REFUSED: '+str(error),file=sys.stderr)
        sys.exit(1)
'@
if ($ValidateSourceOnly) {
  $signProgram | & $Python -c 'import sys; compile(sys.stdin.read(), ''embedded'', ''exec''); print(''Signer syntax valid; no file reads/writes, approvals or engine'')'
} elseif ($RunPureUnitTests) {
  $signProgram | & $Python - $taskWorkspace $PSCommandPath --pure-units
} else {
  $signArguments = @('-', $taskWorkspace, $PSCommandPath, '--draft-dir', $DraftDirectory, '--technical-sha', $ExpectedTechnicalDraftSha256, '--visual-sha', $ExpectedVisualDraftSha256, '--reviewer', $RootReviewer, '--confirm-images-logs', '--confirm-technical')
  if ($FreshStartOnly) { $signArguments += '--fresh-start-only' }
  $signProgram | & $Python @signArguments
}
if ($LASTEXITCODE -ne 0) { throw ('Explicit ROOT signer refused; Python exit ' + $LASTEXITCODE) }
