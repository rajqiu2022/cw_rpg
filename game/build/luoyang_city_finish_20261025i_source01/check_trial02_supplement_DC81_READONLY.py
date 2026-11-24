"""Additional authorization gate for the existing DC81 Stage, not a Stage replay."""
from pathlib import Path
import hashlib,json,copy
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
B=S+'visible_doors_boundaries33_repair01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def read(pin):
    b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'].lower(),pin
    return b
def load(pin):return json.loads(read(pin))
checks=[]
def need(ok,name):
    assert ok,name
    checks.append(name)
stagepin=dict(path=S+'outputs/root_visible_doors_boundaries_exact33_stage01/receipt.json',sha256='dc811f8f114769cad5f7c60369aa47cfd3197f30b11a529154daf4bdaf0c1f11')
stage=load(stagepin)
inputpin=dict(path=B+'source_input_visible_doors_boundaries33_ROOT_REVIEW.json',sha256='153303211b6dc360ecace5b9d5dd081aaa2b57311af99591f63d7b87d1d5c2af')
inp=load(inputpin)
descriptorpin=dict(path=B+'unified33_READY02/unified33_ROOT_BACKUP_FIXED_NOT_STAGE.json',sha256='86282dad5be672f76cb54f383e32a2c4e2a12fe3aad2377c65eade7c59e6e4c9')
descriptor=load(descriptorpin);seal=load(descriptor['seal']);binding=load(seal['binding'])
old_binding=load(seal['binding_inverse']['parent'])
trialpin=dict(path=S+'finish8_ROOT_TRIAL_PERMISSION02.json',sha256='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a')
trial=load(trialpin)
need(stage['source_first']==stage['source_final'] and len(stage['source_first'])==3554,'ORIGINAL_DC81_3554_FIRST_FINAL_SAME')
need(stage['source_first'].get(trialpin['path'])==trialpin['sha256'],'NEW02_HASHED_IN_ACTUAL_DC81_FIRST_AND_FINAL')
need(stage['target_partition']==dict(patch_count=18,copy_count=15,total=33),'ORIGINAL_DC81_EXACT33_RETAINED')
stage_targets={r['target']:r for r in stage['targets']}
need(set(stage_targets)=={r['target']for r in descriptor['targets']},'ACTUAL_STAGE_DECLARED_TARGET_DOMAIN')
for r in descriptor['targets']:
    t=stage_targets[r['target']]
    need(t['candidate_sha256']==r['candidate']['sha256'] and t['candidate_path']==r['candidate']['path'],'ACTUAL_STAGE_CANDIDATE:'+r['target'])
oldgate=next(r for r in inp['pinned_inputs']if r['id']=='trial')
need(oldgate['path']==S+'finish8_ROOT_TRIAL_PERMISSION01.json' and oldgate['sha256']=='e4da07475a77c31b4bcee99c75dfa226eca5baaf4723bd4f3530b1979b8065cb','ACKNOWLEDGE_OLD_STAGE_GLOBAL_TRIAL_GATE_NOT_NEW02')
need(len(inp['required_gates'])==5,'ORIGINAL_FIVE_GATES_NOT_REPLACED')
need(trial['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT' and trial['authorized_by']=='root' and trial['admitted'] is True and trial['actual_Field_pass'] is False and trial['whole_city_ART_pass'] is False and trial['loading_target_pass'] is False,'EXPLICIT_ROOT02_PERMISSION_NOT_RESULT')
expected_scenes={'ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market','ch4_s4_ancient_temple','luoyang_estate_riverside_20261021ai','luoyang_artisan_residential_20261022ap'}
need(set(trial['scene_ids'])==expected_scenes and len(trial['scene_ids'])==6,'ROOT02_EXACT_SIX_SCOPES')
need(seal['Root_trial']==trialpin,'SEALED_CODE_EXPLICIT_ROOT02_BASIS')
changed=set(trial['exact_new_payload_sha256'])
need(changed=={'ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market','ch4_s4_ancient_temple'},'ROOT02_EXACT_FOUR_PAYLOAD_SCOPES')
for id in changed:
    row=binding['scenes'][id]
    need(row['trial']=={**trialpin,'admitted':True,'permission_kind':'TRIAL_PERMISSION_NOT_RESULT','actual_Field_pass':False},'LIVE_BINDING_ROOT02_ROW:'+id)
    need(row['required_source_sha256'].get(trialpin['path'])==trialpin['sha256'],'LIVE_BINDING_ROOT02_REQUIRED_SOURCE:'+id)
    need(row['payload']['sha256']==trial['exact_new_payload_sha256'][id],'ROOT02_FIXED_PAYLOAD:'+id)
for id in set(binding['scenes'])-changed:
    need(binding['scenes'][id]==old_binding['scenes'][id],'OTHER_FOUR_OLD_BINDING_ROWS_WHOLE_TYPED_SAME:'+id)
need(seal['wing_helper_parent']['sha256']==trial['reviewed_executable_candidates']['shared_child_and_bell_helper'],'ROOT02_REVIEWED_HELPER')
need(seal['Field_functional_parent']['sha256']==trial['reviewed_executable_candidates']['Field'],'ROOT02_REVIEWED_FIELD')
need(seal['runtime_seal']['parent']['sha256']==trial['reviewed_executable_candidates']['runtime_arrival_only'],'ROOT02_REVIEWED_RUNTIME')
need(seal['functional_proofs'][0]['sha256']==trial['reviewed_executable_candidates']['shared_child_Field_whole_inverse'],'ROOT02_REVIEWED_FUNCTIONAL_WHOLE_INVERSE')
for name in ['wing_helper_seal','runtime_seal','material_helper_seal']:
    r=seal[name];old=read(r['parent']);new=read(r['candidate']);f,back=old,new
    for h in r['hunks']:
        a,b=h['old'].encode(),h['new'].encode();need(f.count(a)==1,'UNIQUE_SEAL_FORWARD:'+name);f=f.replace(a,b,1)
    for h in reversed(r['hunks']):
        a,b=h['old'].encode(),h['new'].encode();need(back.count(b)==1,'UNIQUE_SEAL_INVERSE:'+name);back=back.replace(b,a,1)
    need(f==new and back==old,'FULL_BYTES_MECHANICAL_SEAL_INVERSE:'+name)
fp=seal['Field_functional_parent'];field=read(fp)
# Only known SELF/BIND propagation follows the approved Field candidate. Its
# two helper call sites deliberately share one exact pinned helper instance.
parent_descriptor=load(descriptor['code_proof'])['parent_descriptor']
parent_bundle=load(parent_descriptor);parent_seal=load(parent_bundle['seal'])
for a,b,count in [(parent_seal['runtime']['path'],seal['runtime']['path'],1),(parent_seal['runtime']['sha256'],seal['runtime']['sha256'],1),(seal['wing_helper_parent']['path'],seal['wing_helper']['path'],2),(seal['wing_helper_parent']['sha256'],seal['wing_helper']['sha256'],2)]:
    need(field.count(a.encode())==count,'EXACT_FIELD_HEADER_OCCURRENCES:'+a)
    field=field.replace(a.encode(),b.encode())
need(field==read(seal['Field']),'FIELD_ONLY_KNOWN_MECHANICAL_PROPAGATION_FROM_ROOT_REVIEWED_930F')
cart=next(r for r in descriptor['targets']if r['target']=='res://data/maps/luoyang_full_city_20261022ap/environment.json')
need(cart['candidate']['sha256']==trial['cart_environment_center_only_sha256'],'ROOT02_EXACT_CART_AUTHOR')
helper=read(seal['wing_helper']).decode()
need('const ELDER_PAIR_ADOPTED: bool=false' in helper and 'const MONK_VISUAL_READY: bool=true' in helper,'ELDER_PAIR_EXCLUDED_BELL_ADOPTED')
need(trial['bell_portrait_raw_sha256']=='db102e07a46e1115b78358636aeb1bf135f78bbc501a89c18124a5aa7d6a9108' and trial['bell_portrait_raw_sha256']in helper,'ROOT02_EXACT_BELL_MEDIA')
need('cave_keeper_elder_portrait_v1.png'not in helper,'NO_ELDER_PORTRAIT_ADOPTION')
for pin in trial['finite_prior_actuals'].values():read(pin)
report=dict(status='ADDITIONAL_ROOT02_AUTHORIZATION_GATE_FOR_EXISTING_DC81_STAGE_READONLY',passed=True,stage=stagepin,unchanged_frozen_input=inputpin,candidates=descriptorpin,new_authorization_basis=trialpin,old_five_gates_preserved_not_relabelled_as_new_permission=True,old_global_trial_gate=oldgate,acknowledged_initial_gate_selection_error=True,checks=len(checks),check_names=checks,Root02_six_scopes=sorted(expected_scenes),four_new_live_binding_rows=sorted(changed),other_four_binding_rows_unchanged=True,all_reviewed_code_seals_whole_byte_inverse=True,no_new_Stage_output_or_metadata_seal=True,Stage_calls=0,collector_calls=0,engine_calls=0,canonical_writes=0,actual_Field_pass=False,whole_city_ART_pass=False,loading_target_pass=False,adoption_decision='Root may adopt the original DC81 Stage together with this independent new02 gate; original receipt/input/output remain untouched.')
dest=N/'visible_doors_boundaries33_repair01/additional_trial02_gate_for_DC81_READONLY.json';assert not dest.exists();raw=enc(report)
with dest.open('xb')as stream:stream.write(raw)
print(json.dumps(dict(path=S+dest.relative_to(N).as_posix(),sha256=sha(raw),checks=len(checks),passed=True,Stage_calls=0)))
