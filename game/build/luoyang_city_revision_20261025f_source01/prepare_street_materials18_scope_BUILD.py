"""Freeze only existing18 parents and a Root backup plan; no successor DAG."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025f_source01/';R='res://build/luoyang_city_revision_20261025f_root01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def resolve(p):
    assert p.startswith('res://') and '..' not in p
    value=(GAME/p[6:]).resolve();assert value.is_relative_to(GAME.resolve());return value
def load(pin):
    raw=resolve(pin['path']).read_bytes();assert sha(raw)==pin['sha256'];return json.loads(raw)
freshpin=dict(path=S+'fresh_current25f02_READONLY.json',sha256='e92b03c9ca2e5e5a95bfc8f8bf1451e8550a5d841a366bc2c1c2c0d738775a22')
fresh=load(freshpin);assert fresh['current_matches24e_guard'] is True and fresh['all_31_plus_ENV_Router_current_SHA_bytes_match_fixed'] is True
stage=load(fresh['current_fixed_stage']);dep=load(fresh['current_fixed_deployment']);assert stage['source_first']==stage['source_final']
fixed={r['target']:r for r in stage['targets']};deployed={r['target']:r for r in dep['targets']};assert len(fixed)==len(deployed)==31
rows=[];E='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
observations={r['target']:r['current'] for r in fresh['all_33_declared_target_checks']}
for proposed in fresh['minimum_ENV_visual_update_plan']['targets']:
    p=proposed['target'];authority=proposed['fixed_current_parent']
    if p!=E:
        assert fixed[p]['candidate_sha256']==deployed[p]['sha256']==authority['sha256'] and fixed[p]['candidate_path']==authority['immutable_candidate']
    else:
        assert authority['sha256']=='0f223acc26a91a74a5523b87032d1487c0996730d3e8b93ac3c29aba81e5f07b' and authority['immutable_candidate']=='res://build/luoyang_city_revision_20261024e_source01/prewarm_profile29_candidates01/ENV_profile04_CANDIDATE.gd'
    original=resolve(authority['immutable_candidate']).read_bytes();assert sha(original)==authority['sha256'] and len(original)==authority['bytes']
    assert observations[p]['sha256']==authority['sha256'] and observations[p]['bytes']==authority['bytes']
    rows.append(dict(target=p,old_sha256=authority['sha256'],old_bytes=authority['bytes'],immutable_old=authority['immutable_candidate'],fresh_observed_ticks=observations[p]['ticks'],fresh_ticks_are_protection_observation_not_functional_authority=True,backup_candidate_path=R+'predeploy18_backup/'+p[6:],direct_dependencies=proposed['direct_dependencies']))
assert len(rows)==18 and sum(r['target'].endswith('.gd') for r in rows)==7
unchanged=[r['target'] for r in fresh['all_33_declared_target_checks'] if r['target'] not in {x['target'] for x in rows}]
doc=dict(status='SOURCE25F_EXACT18_CURRENT_EE47_PARENT_SCOPE_ONLY_NOT_STAGE',namespace=S,source_snapshot_is_not_formal_deployment=True,parent_stage=fresh['current_fixed_stage'],parent_deployment=fresh['current_fixed_deployment'],parent_postguard=fresh['parent24e_postguard'],fresh_observation=freshpin,target_count=18,partition=dict(GD=7,JSON=11),targets=rows,unchanged_fixed_current_targets=unchanged,current_OWNED10_proof162_depth16_unchanged=True,Temple_ENV_binding_no_fixed_SHA_consumer=True,Temple_binding_and_execution_not_targets=True,no_Temple_shortcut=True,old_source_classification_and_worker_four_artifact_facts_preserved=True,no_geometry_mask_NAV_native_room_return_NPC_dialogue_portrait_changes=True,ENV_Router_complement_current_exact=True,backup_plan=dict(status='PLAN_ONLY_NOT_ACTUAL_BACKUP',exclusive_prefix=R+'predeploy18_backup/',Root_must_compare_current_SHA_bytes_to_fixed_old_then_Copy_CreateNew=True,Root_record_exact_source_and_backup_ticks=True,old98_full_backups_keep_all=True,old_failure_and_bad_candidate_epochs_keep_all=True,user_new_save_changes_preserved_no_rollback=True,current_save_start=freshpin,protected_count=2121,save_count=15,admitted_mask_media_paths=6),next_authorization_boundary='Only after Root views the single System overview candidate and approves its immutable final package. No source candidate, Stage driver/input, or closure is constructed by this scope.',future_map_rule='Fixed 8EA2 current independent maps incremental delta with original approved gates; do not re-promote oldest AO Coordinator29E.',new_ordinary_helper_spec_shader_leaf_domain='Pending exact System package and Root approval; do not infer new SHA or pre-fill actuals. No new runtime_authority/OWNED entries.',performance_credit='No25f runtime performance observation; old29 Gate8.812578 is historical only.',Stage_calls=0,collector_calls=0,engine_calls=0,imports=0,canonical_writes=0,save_writes=0,processes_stopped=0)
raw=(json.dumps(doc,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();dest=HERE/'street_materials18_scope_PREPARATION.json';assert not dest.exists();dest.write_bytes(raw)
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw),targets=18,GD=7,JSON=11,Stage_or_candidate_preparation=False)))
