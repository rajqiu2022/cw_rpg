"""Exact fixed-current29 old domain for Root predeployment backup only."""
from pathlib import Path
import json,hashlib,copy
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261024e_root01/'
raw=(HERE/'prewarm8_profile29_consumer_depth_PROSPECT_READONLY.json').read_bytes();assert hashlib.sha256(raw).hexdigest()=='6038691407cc81f6e6d36162cc3ee87a42ecf444139ea5a0c075dd269ed4644e'
p=json.loads(raw);rows=copy.deepcopy(p['targets']);rows.append(copy.deepcopy(p['conditional_profile_batch']['new_existing_target']))
for row in rows:
    b=(GAME/row['immutable_old'][6:]).read_bytes();assert hashlib.sha256(b).hexdigest()==row['old_sha256'];row['old_bytes']=len(b)
    row['backup_relative_path']=row['target'][6:]
    row['backup_candidate_path']=R+'prewarm_profile29_predeploy_backup/'+row['target'][6:]
assert len(rows)==len({r['target'] for r in rows})==29
assert sum(r['target'].endswith('.gd') for r in rows)==15
doc=dict(status='ROOT_APPROVED_EXACT29_OLD_DOMAIN_FOR_PREPARATION_NOT_STAGE',parent_final_deployment=dict(path=R+'finite_AP_header2_deployed_actual.json',sha256='d596ef3c7cd7177fc302f25aac3cdba6b7ad2772e1ec0122aaed2afa8549e799'),prior_main_stage=p['fixed_parent_stage'],prior_deployments=p['subsequent_fixed_metadata_deployments'],target_count=29,partition=dict(GD=15,JSON=14),targets=rows,backup_plan=dict(exclusive_new_directory=R+'prewarm_profile29_predeploy_backup/',Root_must_compare_current_SHA_bytes_then_copy_and_record_exact_ticks=True,no_restore_or_overwrite_prior_backups=True,previous_33_plus3_plus2_backups_preserved=38),new_helper_ordinary=p['helper'],no_Stage_or_deployment_authorization=True,old148_proofs_preserved=True,owned_count=10,real_owned_new_edges=4,new_proof_roles=p['proposed_new_execution_proof_roles'],proposed_proof_count=154,Temple_shortcut_needed=False,Temple_actual_requested_max_depth_after_new_edge=3,depth_limit_unchanged=16,geometry_native_registry_DT_G_Router_UI_frozen=True,collector_calls=0,engine_calls=0,canonical_writes=0)
out=HERE/'prewarm_profile29_scope_PREPARATION.json';b=(json.dumps(doc,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(b)
print(json.dumps(dict(path=S+out.name,sha256=hashlib.sha256(b).hexdigest(),targets=29,GD=15,JSON=14)))
