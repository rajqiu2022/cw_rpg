"""Prepare guards/parameters from fixed Root evidence; never collect live sources."""
from pathlib import Path
import json,hashlib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
OUT='res://build/luoyang_city_revision_20261024c_source01/'
B='res://build/luoyang_city_revision_20261024b_root01/'
S='res://build/luoyang_city_space_20261024b_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return json.loads(b)
fresh=dict(path=B+'c_start_fresh_observation.json',sha256='18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a')
v=load(fresh['path'],fresh['sha256']);assert v['checked']==len(v['facts'])==2120 and len(v['save_paths'])==15 and v['user_changes_preserved']
baseline=dict(path=OUT+'current24b_formal_target_declarations_READONLY.json',sha256='4b591c8043820fd4ccc0d614a33dce6b3c9a53ae28f30de6937751e9e38c7fb7')
base=load(baseline['path'],baseline['sha256'])
def norm(p):return str(Path(p).resolve()).lower()
facts={norm(r['path']):r for r in v['facts']};assert len(facts)==2120
matched=[];outside=[]
for row in base['targets']:
    p=norm(GAME/row['target'][6:]);r=facts.get(p)
    if r is None:outside.append(row['target']);continue
    assert r['exists'] and r['sha256'].lower()==row['old_sha256']
    matched.append(row['target'])
assert len(matched)==35 and outside==['res://scripts/ui/dialog_box.gd']
ui=next(r for r in base['targets'] if r['target']==outside[0]);assert ui['old_sha256']=='fe8165682670f7bcc5689d963b456f5d9503ba7f6abece575ad4f04e82c9c337'
params=dict(status='24C_PROTECTION_AND_NEXT_STAGE_PARAMETERS_NOTREADY',ready=False,Root_start_fresh=fresh,
    protection_definition=dict(source_document_status=v['status'],facts_pointer=['facts'],fact_fields=['path','exists','sha256','bytes','ticks'],path_count=2120,save_paths_pointer=['save_paths'],save_count=15,save_semantics='Use this capture as the current starting point. Do not restore or overwrite user saves/tasks. Root reported zero new save differences from latest667A; the two earlier external save changes remain historical, not new24c differences.',original_prior=dict(path=v['prior_path'],sha256=v['prior_sha256']),original_prior_difference_count=38,original_prior_difference_explanation='Root reported35 authorized existing target changes plus historical tasks1 and earlier external save2; not38 new24c changes.',fresh_observation_is_not_functional_expectation=True),
    fixed_target_domain_crosscheck=dict(baseline=baseline,fixed_declared_targets=36,guard_present_exact35=matched,guard_absent_existing_UI=outside,UI_fixed_sha256=ui['old_sha256'],UI_policy='Keep unchanged and do not enlarge2120 merely to restate it. Only add as explicit preauthorized existing target if a real future UI change is requested; none is currently planned.',canonical_files_read_for_this_check=0),
    processes=dict(Root_reported_editor_PID=51856,Root_reported_game_count=0,Source_process_operations=0,policy='Never close editor or user processes. Root solely controls any future engine scheduling.'),
    finalizer_parameters=dict(namespace=OUT,core=dict(path='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py',sha256='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'),base_input=dict(path=S+'source_input_ENV_texture_union18_residual02_ROOT_READY.json',sha256='be6595a374369182fe615cf8ab78f6cbb449f2001a3e41c2b40c3a73a6c60fcd'),parent_complete_maps=base['four_complete_maps'],existing_authority=dict(path='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json',immutable_snapshot=S+'packed_closure27/execution_successor_PREPARATION.json',sha256='812a6f8e297242541a37dcbe59792ea986f4968b56a948933b01bb3a32afaced',owned_members=10,prior_source_pins=132),source_old_values='Lookup only from the fixed36 latest declarations for affected existing targets; final set must be locked with Root full old-byte backup before a ready recipe is built.',Root_backup_schema='PENDING_ACTUAL_DOCUMENT_DO_NOT_ASSUME_OLD_SCHEMA',scope='PENDING_SYSTEM_FINAL_OVERLAY_CONSUMER_LIST',functional_expected_sources='Fixed parent full maps plus admitted explicit source/header/asset differences; never fresh.facts, runtime snapshots or a collector',planned_output_root=OUT+'outputs/root_yamen_scholar_source_stage01/',output_not_created=True,command_not_executable_until_Root_lock=True),
    new_media_protection=dict(scholar_portrait='PENDING_ROOT_DEDICATED_OPAQUE_PNG_AND_IMPORT_CTEX_FACTS',local_Yamen_mask='PENDING_SYSTEM_EXACT_CLOSED_DOMAIN_OUTPUT_IF_NEEDED',rule='Root exclusively admits/promotes precise new leaves; preserve old imports/native. Do not count pending leaves as present or invent their hashes.'),
    mandatory_preservation=['24b worker four-artifact facts','finite Packed duplicate decoder and original Array fallback','ENV fixed used-asset union','Root64 ordinary/runtime-authority classification','all prior failure records and116 full backups','Yamen original native4 under approved overlay design','Market25 and original main-hall portal/return'],
    remaining_blockers=['Frozen System overlay/helper/binding and real consumer boundary','Root dedicated portrait/import triple','Root final exact target backups and preparation authorization','Root later explicit Stage/engine/deployment authorization'],
    actual_execution=dict(Stage=0,engine=0,collector=0,canonical_writes=0,save_writes=0,media_scan=0))
b=(json.dumps(params,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=HERE/'24c_protection_and_finalizer_parameters_NOTREADY.json'
with p.open('xb') as f:f.write(b)
assert json.loads(p.read_bytes())==params
print(json.dumps(dict(path=OUT+p.name,sha256=sha(b),bytes=len(b),fixed_declaration_matches=35,UI_unchanged_outside2120=True,ready=False)))
