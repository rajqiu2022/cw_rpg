"""Freeze only exact17 old scope and single-scalar inverse, without Stage."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance46_estate_registry_scalar_scope/'
def p(v):return G/v[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s,('PIN',v);return b
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
gp=S+'performance45_estate_registry_scope_READONLY.json';gs='7780bebf9c0aede12eb332b0fec5621fd26e5af412fb818d0c603c25ba978f12';graph=json.loads(fixed(gp,gs))
rows=[{'target':r['target'],'old_sha256':r['candidate_sha256'],'old_snapshot':r['candidate_path'],'kind':'GD'if r['target'].endswith('.gd')else'JSON'}for r in graph['proposed_targets']]
assert len(rows)==17 and sum(r['kind']=='GD'for r in rows)==6
estate='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json';index='res://scripts/city/luoyang_estate_index_20261021am.gd';registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
r=next(r for r in rows if r['target']==estate);before=fixed(r['old_snapshot'],r['old_sha256']);prior=json.loads(before)
cp='res://build/luoyang_city_full_rollout_20261022ap_system01/hall_registry_admission_fix_candidate_epoch01/estate_manifest_registry_scalar_CANDIDATE.json';cs='2410ed000f79c898742106d455f7b79b26fcad7a57acb6d2632e71bc18c521eb';candidate=fixed(cp,cs);data=json.loads(candidate)
old=prior['registry_sha256'];new=prior['source_sha256'][prior['registry_path']]
assert old=='040664f7a2c73087b6c47e5f4d000cb4955648dd61b830d76d2a7ce54cafd95c'and new=='f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28'and prior['registry_path']==registry
expected=copy.deepcopy(prior);expected['registry_sha256']=new
assert js(expected)==candidate and js(prior)==before
restored=copy.deepcopy(data);restored['registry_sha256']=old;assert js(restored)==before
a=('"registry_sha256": "'+old+'"').encode();b=('"registry_sha256": "'+new+'"').encode()
assert before.count(a)==1 and candidate.count(b)==1 and before.replace(a,b,1)==candidate and candidate.replace(b,a,1)==before
ownerpath=S+'performance43_culture_actual_independent_review/owner_source_maps_READY.json';ownersha='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0';owner=json.loads(fixed(ownerpath,ownersha))
declared=owner['core_source_sha256'].get(registry)
sources=[row for row in owner['scenes']+owner['rooms']if row['source_sha256'].get(registry)==new]
assert declared==new or sources
ir=next(r for r in rows if r['target']==index);ib=fixed(ir['old_snapshot'],ir['old_sha256']);assert ib.count(r['old_sha256'].encode())==1
core=p(S+'stage_unified06_04_READY.py').read_text();assert '"registry_sha256"'in core[core.index('    def change('):core.index('    def build_node(')]
proof={'status':'EXACT_ESTATE_SCALAR_ONE_VALUE_TYPED_AND_WHOLE_BYTE_INVERSE_NOT_STAGED','parent':{'path':r['old_snapshot'],'sha256':r['old_sha256']},'candidate':{'path':cp,'sha256':cs},'operation':{'op':'set','pointer':['registry_sha256'],'existed':True,'old':old,'new':new},'new_value_source':'same frozen parent source_sha256[parent.registry_path], independently declared in fixed544819 owner; not observed current file hash','fixed_prior_owner':{'path':ownerpath,'sha256':ownersha},'matching_declared_registry_source':new,'whole_typed_inverse':True,'whole_byte_inverse':True,'original8DE0_encode_exact_candidate_bytes':True,'original8DE0_source_only_registry_sha256_already_supported':True,'all_other_fields_source_maps_geometry_native_unchanged':True,'parent_old_bytes':len(before),'candidate_bytes':len(candidate),'root_cause_sites':['EstateFamily.registry_source:87-90 source_map/scalar mismatch refuses authority','RI.registry:6-7 forwards that empty authority','G.catalogue:110-112 refuses empty authority','G.project_portals:277-278 empty catalogue produces zero appendedroom iterations; old portals returned instead of fail-closed'],'separate_G_failclosed_not_in17':True,'Stage_engine_collector_native_decode_formal_writes':0}
scope={'status':'PROPOSED_EXACT17_EXISTING_METADATA_HEADER_SCOPE_NOT_STAGE_AUTHORIZED','target_count':17,'GD_count':6,'JSON_count':11,'targets':rows,'parent_actual_stage':{'path':S+'outputs/root_culture_C_source_repair_stage01/receipt.json','sha256':'5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e'},'prior_owner':{'path':ownerpath,'sha256':ownersha},'propagation_graph':{'path':gp,'sha256':gs},'scalar_candidate':{'path':cp,'sha256':cs},'old24_excluded_exact7':graph['excluded_from24'],'unchanged_execution_owned_proof_graph':True,'unchanged_registry_G_Family_B_C_DT_Fade_Quarter_Temple_Coordinator_culture':True,'four_T_runtime_authority_classification_preserved':True,'no_new_keys_in_full_collector_or_room_receipt_maps':True,'plan':'Reuse frozen8DE0 core and42 metadata/group/map/strict-LF transport. Current execution authority and registry are frozen nodes, no pass-through runtime code or new execution edges. Estate operation registry_sha256 uses existing source-only allowlist, then fulltyped inverse and exact2410 candidate serialization check; other16 necessary generated metadata/index only explicit old header replacements. New Root17scope/backups/guard required before Stage. G optional failclosed stays separate.','Stage_engine_collector_formal_calls':0}
pb=js(proof);sp=O+'exact17_existing_scope_PROPOSAL.json';sb=js(scope);diff=''.join(difflib.unified_diff(before.decode().splitlines(True),candidate.decode().splitlines(True),fromfile=r['old_snapshot'],tofile=cp)).encode()
handoff={'status':'ESTATE_REGISTRY_SINGLE_SCALAR_EXACT17_PREPARATION_PROPOSAL_NOT_STAGED','scope':{'path':sp,'sha256':sha(sb)},'scalar_inverse':{'path':O+'scalar_whole_inverse_READY.json','sha256':sha(pb)},'complete_scalar_diff':{'path':O+'estate_scalar_complete.diff','sha256':sha(diff)},'dependency_graph':{'path':gp,'sha256':gs},'target_count':17,'GD':6,'JSON':11,'no_new_core_source_only_exception_required':True,'G_optional_separate_not_in_production_scope':True,'Root17_backups_guard_and_Stage_approval_pending':True,'no_runtime_calls':True}
files={sp:sb,O+'scalar_whole_inverse_READY.json':pb,O+'estate_scalar_complete.diff':diff,O+'handoff_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()
for v,b in files.items():p(v).parent.mkdir(parents=True,exist_ok=True);p(v).write_bytes(b)
print(json.dumps({v:sha(b)for v,b in files.items()},indent=2))
