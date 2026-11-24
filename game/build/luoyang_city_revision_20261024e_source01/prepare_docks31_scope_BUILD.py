"""Fixed FE154/3A675 parent domain for Docks preparation; no current fill."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261024e_root01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;return json.loads(b)
stage33=load(S+'outputs/root_market_blocks_prewarm_exact33_stage03/receipt.json','ea657a57c4a884cd3f645b6de7f8fb2010c8920b737b2ab6b9f3c998288c2abc')
stagepin=dict(path=S+'outputs/root_prewarm8_profile04_exact29_stage02/receipt.json',sha256='3a67564ee7ef2bb8cc70e2d0b28688eabb54c4a2be53e26cc509f70bfa410e98')
stage=load(stagepin['path'],stagepin['sha256']);deppin=dict(path=R+'prewarm_profile29_deployed_actual.json',sha256='fe1549455424f80f4cdd6325402b6816aad861388b2a2e49b16a9c8c91c6b0bb');dep=load(deppin['path'],deppin['sha256'])
assert dep['stage_sha256']==stagepin['sha256']
rows={r['target']:dict(target=r['target'],old_sha256=r['candidate_sha256'],immutable_old=r['candidate_path']) for r in stage33['targets']}
dr={r['target']:r for r in dep['targets']}
for r in stage['targets']:
    assert dr[r['target']]['sha256']==r['candidate_sha256'];rows[r['target']].update(old_sha256=r['candidate_sha256'],immutable_old=r['candidate_path'])
excluded={'res://scripts/city/luoyang_environment_layer_20261022ap.gd','res://scripts/autoload/scene_router.gd'}
for p in excluded:del rows[p]
for p,r in rows.items():
    b=(GAME/r['immutable_old'][6:]).read_bytes();assert sha(b)==r['old_sha256'];r['old_bytes']=len(b);r['backup_relative_path']=p[6:];r['backup_candidate_path']=R+'docks31_predeploy_backup/'+p[6:]
assert len(rows)==31 and sum(p.endswith('.gd') for p in rows)==16
freeze=dict(path='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/ready_freeze_complete_inverse.json',sha256='6ed8ff6e3503eacb10b0ee3b00fd92f6ee3cef4e7710a372656d73dd9f08bbf5')
load(freeze['path'],freeze['sha256'])
binding=load('res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/binding_READY.json','dffded2e8d3bce09b50e3f127e26a060b6b3ab64ee9122c2ff3fb87184fbd012')
assert binding['ready'] is True and len(binding['required_source_sha256'])==16
helper=dict(path='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/docks_frontage_session_READY.gd',sha256='3340eb04cc790fa346930ae164c577f5c5212da50efa5043fe16a035e263f385')
assert sha((GAME/helper['path'][6:]).read_bytes())==helper['sha256']
doc=dict(status='DOCKS_EXACT31_FIXED_FE154_PARENT_PREPARATION_NOT_STAGE',parent_stage=stagepin,parent_deployment=deppin,functional_READY_package=freeze,target_count=31,partition=dict(GD=16,JSON=15),targets=list(rows.values()),excluded_ENV_Router_unchanged=sorted(excluded),new_helper_ordinary=helper,READY_binding_required16_known=True,no_fake_media_expectations=True,expected_existing_owned_changes=['G','DT','Field','AC','Coordinator','Temple'],owned_count_unchanged=10,old154_proofs_retained=True,new_execution_evidence_roles=['G_snapshot','DT_snapshot','Field_snapshot','AC_snapshot','Coordinator_snapshot','Temple_snapshot','C_Field_contract','Temple_binding'],candidate_total_proof_count_if_only_8=162,no_depth_expansion=True,no_shortcut=True,DT_registry5_source_values_only_no_room_geometry=True,backup_plan=dict(exclusive_prefix=R+'docks31_predeploy_backup/',Root_current_SHA_bytes_compare_before_CreateNew_and_record_exact_ticks=True,previous67_fullbackups_preserved=True),no_packet_mask_PNG_geometry_replay=True,engine_calls=0,Stage_calls=0,collector_calls=0,canonical_writes=0)
out=HERE/'docks31_scope_PREPARATION.json';raw=(json.dumps(doc,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(raw)
print(json.dumps(dict(path=S+out.name,sha256=sha(raw),targets=31,GD=16,JSON=15)))
