from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
p=G/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json'
raw=p.read_bytes();assert sha(raw)=='ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'
r=json.loads(raw);authority={}
for key,node in r['nodes'].items():
    if not key.startswith('expected_') or not isinstance(node.get('value'),dict):continue
    for target,h in node['value'].get('source_sha256',{}).items():
        assert target not in authority or authority[target]==h;authority[target]=h
for row in r['targets']:authority[row['target']]=row['candidate_sha256']
targets={row['target'] for row in r['targets']}
unchanged='res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd'
assert unchanged in targets;targets.remove(unchanged)
for name in ['luoyang_enclosure_v11_candidate_contract.gd','luoyang_docks_district08_20261019aa.gd','luoyang_docks_workyard_20261019ac.gd','luoyang_environment_layer_20261022ap.gd','luoyang_estate_family_20261021am.gd']:
    target='res://scripts/city/'+name
    assert target not in targets;targets.add(target)
assert len(targets)==32
rows=[];prepared={}
for target in sorted(targets):
    h=authority[target];b=(G/target.removeprefix('res://')).read_bytes();assert sha(b)==h,(target,h,sha(b))
    name='immutable_current32/'+target.removeprefix('res://');prepared[name]=b
    rows.append(dict(target=target,old_sha256=h,old_bytes=len(b),immutable_old=NS+name,kind='GD' if target.endswith('.gd') else 'JSON'))
assert sum(x['kind']=='GD' for x in rows)==18
snapshot=dict(status='FINITE_EXISTING_TARGET_SCOPE_PREPARATION_NOT_STAGE_NOT_BACKUP_NOT_DEPLOYMENT',count=32,partition=dict(GD=18,JSON=14),
    parent_stage=dict(path='res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json',sha256=sha(raw)),
    parent_deployment=dict(path='res://build/luoyang_city_revision_20261025h_root01/service_garden28_deployed_actual.json',sha256='7761350ba5a49ebeb94789fcc104d7310c204f28674a499bd9f6b4d2f9ad98ac'),
    targets=rows,expected_changed_owned=['res://scripts/city/'+x for x in ['luoyang_assembled_interiors_20261016g.gd','luoyang_docks_workyard_20261019ac.gd','luoyang_cultural_sidequests_coordinator_20261019x.gd','luoyang_temple_assembly_20261016.gd']]+['res://scripts/field/field_walkable_controller.gd'],
    owned_count_unchanged=10,old_proof_key_values_preserved=176,history_depth_unchanged=16,no_shortcut=True,
    ordinary_not_owned=['C','AA','QuarterFamily','EstateFamily','ENV'],
    functional_noop_exclusions=['DT','NativeGeometry','Router','UI','original12roomregistry_and_native'],
    independent_authority='Pinned25h Stage expected map values plus exact deployed target overrides; current bytes read only to compare, never used to choose expected hashes.',
    backup_plan=dict(executor='Root only',mechanism='Exact32 old SHA/bytes compare then CreateNew full copies and exact source ticks facts; preserve all176 older backups; this preparation snapshot is not a backup receipt.'),
    final_target_noop_recheck_required=True,engine_calls=0,collector_calls=0,canonical_writes=0)
prepared['finish8_existing_target_scope32_PREPARATION.json']=(json.dumps(snapshot,ensure_ascii=False,indent=2)+'\n').encode('utf-8')
for name,b in prepared.items():
    dest=N/name;assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True)
    with dest.open('xb') as f:f.write(b)
b=prepared['finish8_existing_target_scope32_PREPARATION.json']
print(json.dumps(dict(path=NS+'finish8_existing_target_scope32_PREPARATION.json',sha256=sha(b),bytes=len(b),count=32,GD=18,JSON=14)))
