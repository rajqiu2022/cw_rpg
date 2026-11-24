"""Root actual backup + final physical candidates -> one locked Stage input. No Stage."""
from pathlib import Path
import json,hashlib,ast
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return b
cp=dict(path=R+'unified28_candidates01/unified28_all_candidates_and_inverse_NOT_STAGE.json',sha256='db48da89a35c3763748be77b3b71f2a591ed6aff1cda40908090cfaed06e54a9');c=json.loads(read(cp['path'],cp['sha256']))
pins=[]
def pin(i,p,h):pins.append(dict(id=i,path=p,sha256=h));return i
driver=R+'stage_service_garden_exact28_ROOT_ONLY.py';b=(G/driver[6:]).read_bytes();ast.parse(b.decode());pin('driver',driver,sha(b))
pin('candidates',cp['path'],cp['sha256']);pin('scope',c['scope']['path'],c['scope']['sha256']);pin('backup',c['root_backup']['path'],c['root_backup']['sha256']);pin('owned',c['owned_proof']['path'],c['owned_proof']['sha256'])
pin('execution',c['execution']['candidate']['path'],c['execution']['candidate']['sha256']);pin('authority_helper',c['authority_helper']['path'],c['authority_helper']['sha256'])
backup=json.loads(read(c['root_backup']['path'],c['root_backup']['sha256']));assert len(backup['rows'])==28 and backup['passed']is True
gates=[]
for i,r in enumerate(c['old_required_gates']):gates.append(dict(id=r['id'],input=pin('gate_'+str(i),r['pin']['path'],r['pin']['sha256']),pointer=r['pointer'],equals=r['equals']))
# Preserve original permission gate identity, compare actual exact28 backup status;
# all28 rows and full old bytes are checked independently by the Stage constructor.
gates.append(dict(id='root_target_preauthorization',input='backup',pointer=['passed'],equals=True))
gp='res://build/luoyang_garden_river_20261025h_source01/metadata_array04/ROOT_READY/reports/115844/result.json'
pin('garden_actual',gp,sha((G/gp[6:]).read_bytes()))
trial=dict(path='res://build/luoyang_city_revision_20261025h_root01/garden_finite_trial_authorization.json',sha256='2b897810f0bf7f93c155882ada5e4276f6b2a8ff57204622170ee441c07ec52c');pin('garden_trial',trial['path'],trial['sha256'])
bindingpin=dict(path='res://build/luoyang_garden_river_20261025h_source01/runtime02_READY/garden_river_binding_READY.json',sha256='7ecb31c6adde123f7b365ba6596dc1eed3b1e795c3b4a6baa3162992e3bf5cdf');binding=json.loads(read(bindingpin['path'],bindingpin['sha256']))
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=R+'outputs/root_services_garden_exact28_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'])for r in c['targets']],declared_candidates={r['target']:r['candidate']for r in c['targets']},required_gates=gates,garden_declaration=dict(binding_path=bindingpin['path'],binding_sha256=bindingpin['sha256']),garden_scene_paths={key:binding['child'][suffix]['path']for key,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]},source_baseline='Exact current25g C972/7F2A + serviceREADY02 + source-derived Garden publication115844; no old AO baseline promotion or current expected fill.',Root_only_execution=True,no_engine_collector_native_replay_or_canonical_writes=True)
raw=enc(spec);p=P/'source_input_service_garden_exact28_ROOT_REVIEW.json';assert not p.exists()
with p.open('xb')as f:f.write(raw)
assert json.loads(p.read_bytes())==spec
print(json.dumps(dict(input=dict(path=R+p.name,sha256=sha(raw),bytes=len(raw)),driver=dict(path=driver,sha256=sha(b),bytes=len(b)),candidates=cp,root_backup=c['root_backup'],target_count=28,pins=len(pins))))
