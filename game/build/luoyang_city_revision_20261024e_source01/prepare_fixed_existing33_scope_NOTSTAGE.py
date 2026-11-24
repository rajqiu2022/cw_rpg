"""Existing-target scope from immutable24c declarations only; no live fill."""
from pathlib import Path
import hashlib,json,copy
B=Path(__file__).resolve().parent;G=B.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(p,h):
    raw=(G/p[6:]).read_bytes();assert sha(raw)==h,(p,sha(raw));return json.loads(raw)
tp='res://build/luoyang_city_revision_20261024e_source01/source_successor_template_NOTREADY.json'
template=fixed(tp,'44f333c894cf0906a1e9e67211f7fe6b7d0c25e3985d8e52afb75deb8b4130c3')
sp='res://build/luoyang_city_revision_20261024c_source01/outputs/root_courts_scholar_exact30_stage03/receipt.json'
stage=fixed(sp,'99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce')
ep='res://build/luoyang_city_revision_20261024c_source01/temple_depth_residual02/execution_successor_PREPARATION.json'
execution=fixed(ep,'21b06cb7b0ab393f94fbc51843eccbbee4f468b148321e42ec21259fd7cd53dd')
rows=[]
for item in stage['targets']:
    rows.append(dict(target=item['target'],old_sha256=item['candidate_sha256'],immutable_old=item['candidate_path'],basis=dict(path=sp,sha256='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce',pointer=['targets',len(rows),'candidate_sha256'])))
for target in ['res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd']:
    old=template['fixed_all36_latest_declared_targets'][target]
    rows.append(dict(target=target,old_sha256=old['sha256'],immutable_old=old['path'],basis=old['declaration']))
router='res://scripts/autoload/scene_router.gd';r=execution['owned'][router]
snap=next(e['new_snapshot'] for e in r['edges'] if e['new_sha256']==r['current_sha256'])
rows.append(dict(target=router,old_sha256=r['current_sha256'],immutable_old=snap,basis=dict(path=ep,sha256='21b06cb7b0ab393f94fbc51843eccbbee4f468b148321e42ec21259fd7cd53dd',pointer=['owned',router,'current_sha256'])))
assert len(rows)==len({r['target'] for r in rows})==33
for row in rows:
    data=(G/row['immutable_old'][6:]).read_bytes();assert sha(data)==row['old_sha256'];row['old_bytes']=len(data)
    row['kind']='GD' if row['target'].endswith('.gd') else 'JSON'
    if row['target']==router:
        assert data.count(b'\r')==data.count(b'\r\n')==13
        row['transport']='Only this fixedraw Router before/after normalizedLF shadow through unchanged strict core; Root apply_patch then approved candidate EOL formatter after normalizedLF body exact check. Final target remains raw bytes.'
assert sum(r['kind']=='GD' for r in rows)==18 and sum(r['kind']=='JSON' for r in rows)==15
owned_changed=[p for p in execution['owned'] if p in [
 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd',
 'res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',router,
 'res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd']]
assert len(owned_changed)==7 and len(execution['source_sha256'])==139
value=dict(status='EXACT33_EXISTING_FIXED_24C_PARENT_SCOPE_FOR_ROOT_REVIEW_NOT_STAGE',ready=False,target_count=33,partition=dict(GD18=18,JSON15=15),targets=rows,
 expected_actual_changes='C/DT/Field/G/ENV/Router and ordinary AA/AC/culture/Temple literal successors; existing15metadata+8indices from actual code/data hashes, no noop targets.',
 unchanged=dict(B=True,Fade=True,ground=True,UI=True,Family=True,all_old_native4=True,DP_tasks=True,old_classification64=True),
 ownership=dict(members_unchanged=10,old139_keys_values_frozen=True,changed_existing_members=owned_changed,approval_depth_limit=16,old_Temple17_edges_unchanged=True,new_proof_leaf_count='PENDING exact final snapshots and two literal source proofs; never replace/delete old139'),
 fresh_protection=dict(path='res://build/luoyang_city_revision_20261024e_source01/fresh_24e_current_observation_READONLY.json',sha256='63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85',note='Current15save are current protection start; retain old24c external2save changes, no rollback/zero-drift claim.'),
 pending=['Root exact old33 freshguard+fullbackup+explicit preparation approval','Final READY runtime/import/header/trial exact pins; then new target SHA list and one parse probe','Root Stage authorization separate; no engine or Stage executed here'],
 source_authority='Only frozen Stage99A719/latest declared snapshots/ownedRouter snapshot; current canonical observations were not used to supply expected values.',engine_calls=0,collector_calls=0,media_hashes=0,canonical_writes=0)
p=B/'exact33_existing_old_scope_PREPARATION.json';assert not p.exists();raw=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode();p.write_bytes(raw)
print(json.dumps(dict(path=p.as_posix(),sha256=sha(raw),targets=33,GD=18,JSON=15,owned_changed=7)))
