"""Fixed25g parent declaration only. No live expected-value fill or backup execution."""
from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent;G=P.parents[1]
R='res://build/luoyang_city_revision_20261025h_source01/'
S='res://build/luoyang_city_revision_20261025g_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return b
stagepin=dict(path=S+'outputs/root_market_courtyard45_exact32_stage02/receipt.json',sha256='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396')
stage=json.loads(checked(**dict(p=stagepin['path'],h=stagepin['sha256'])))
freshpin=dict(path=R+'fresh_current25h_READONLY.json',sha256='7b26d75eaad7d95b7d7ab33e572d0ab10c52d02e6b5e07f4ecb8609fa6ed1dcb')
fresh=json.loads(checked(freshpin['path'],freshpin['sha256']))
skip=['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd','res://scripts/city/luoyang_docks_district08_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd','res://data/maps/luoyang_estate_rooms_20261021am/registry.json']
rows=[]
for row in stage['targets']:
 if row['target']in skip:continue
 old=checked(row['candidate_path'],row['candidate_sha256'])
 assert checked(row['target'],row['candidate_sha256'])==old
 rows.append(dict(target=row['target'],old_sha256=row['candidate_sha256'],old_bytes=len(old),immutable_old=row['candidate_path'],candidate=None))
for name in ['luoyang_quarters_family_20261022ap.gd','luoyang_quarters_native_geometry_20261022ap.gd']:
 target='res://scripts/city/'+name
 pin=stage['nodes']['expected_ch4_s3_luoyang_market_true']['value']['source_sha256'][target]
 snapshot='res://build/luoyang_garden_river_20261025h_source01/parents/'+name
 old=checked(snapshot,pin);assert checked(target,pin)==old
 rows.append(dict(target=target,old_sha256=pin,old_bytes=len(old),immutable_old=snapshot,candidate=None))
assert len(rows)==28 and sum(r['target'].endswith('.gd')for r in rows)==14
scope=dict(status='EXACT28_CURRENT25G_SERVICE_GARDEN_PREPARATION_NOT_STAGE',ready=False,count=28,partition=dict(GD=14,JSON=14),parent_stage=stagepin,parent_deployment=dict(path='res://build/luoyang_city_revision_20261025g_root01/courtyard45_32_deployed_actual.json',sha256='7f2a7be12b86f3021d87dfc0f74294e2961c3ef376e4c8bb533cc59a74870071'),fresh=freshpin,
 targets=rows,excluded_unchanged=skip,backup_plan=dict(prefix='res://build/luoyang_city_revision_20261025h_root01/exact28_old_backup/',existing148_backups_keep=True,CreateNew_only=True,compare_fixed_old_SHA_bytes_before_copy=True,preserve_exact_ticks_as_facts_no_reset=True),
 invariants=dict(C_AA_AC_DT_ENV_Router_UI_unchanged=True,old12room_registry_and_native_unchanged=True,owned_members=10,old_proofs=170,new_proofs_expected=176,real_owned_members=['G','Field','Coordinator','Temple'],depth_limit=16,old_edges_unchanged=True,no_shortcut=True,source_classification_inherited=True,no_city_or_room_native_replay=True),
 final_candidate_blockers=['Garden Family binding only actual two media and Root finite trial admission are still to be mechanically frozen; pending Field actual is not passed'],
 scoped_service_domains=dict(flat_G='Only final helper + author two ordinary leaves',four_rooms='Independent source receipts8/91/74/104',other8='No service SKU extension'),
 authority='All old target values from fixed25g actual Stage and its independent Market declaration; current reads only verify equality, never define expected.',Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
b=(json.dumps(scope,ensure_ascii=False,indent=2)+'\n').encode();p=P/'service_garden_exact28_scope_PREPARATION.json'
with p.open('xb')as f:f.write(b)
print(json.dumps(dict(path=R+p.name,sha256=sha(b),bytes=len(b),count=28,GD=14,JSON=14)))
