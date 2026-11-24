"""Correct prior 'registry unchanged' scope assumption; exact five DT leaves."""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,s):
 b=(G/p[6:]).read_bytes();assert sha(b)==s;return json.loads(b)
oldscope=read(S+'finite_adapter_production08_scope/scope_request_READY.json','15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672')
stagepin={'path':S+'outputs/root_unified06_numeric_stage03/receipt.json','sha256':'9aacef0735bced81c6f8b0601165b931a9cfe2f54aef682635490619319965b8'}
stage=read(stagepin['path'],stagepin['sha256']);registry=stage['nodes']['registry_final']
plan=read(S+'finite08_input01_ROOT_LOCKED.json','18fd1b4f97de05a28612fa206c402e84dc0ede6deec9b7b9c60ca74e5aca850e')
n=next(r for r in plan['nodes'] if r['id']=='registry_final');assert len(n['operations'])==5
dt='res://scripts/city/luoyang_district_life_20261016f.gd'
for op in n['operations']:
 assert op['pointer'][0]=='rooms' and op['pointer'][2:]==['source_sha256',dt]
 assert op['old']=='d274d1fcd8f846e6fe8250092d4f83d720b632b174889cfcb1a3b9bacc5752d5' and op['new']=='185b51ff7b9256657424ba0681660d6d335f890f6c919260b3f467384d03ac16'
target='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
assert sha((G/target[6:]).read_bytes())==registry['sha256']=='69602933f93d6c0ede6feb2a8e3c1f355a224017bb59c638440135e42e7634f6'
value=copy.deepcopy(oldscope);value['status']='REQUEST_ROOT_EXACT29_SCOPE_REGISTRY_FIVE_DT_SOURCE_SUCCESSORS_NOT_STAGE_OR_DEPLOY_PERMISSION'
value['target_count']=29
value['targets'].append({'target':target,'old_sha256':registry['sha256'],'old_snapshot':registry['path'],'basis_actual_receipt':stagepin,'only_required_source_operations':n['operations'],'no_native_or_room_geometry_change':True})
value['unchanged_registry_ENV_author_ENVindex_not_targets']=False
value['unchanged_ENV_author_ENVindex_not_targets']=True
value['registry_required_successor']='Five AP-return room source maps consume the changed DT code. Retain necessary exact five migrations and deploy the new registry; original28 scope assumption was false and is preserved unexecuted.'
p=H/'finite_adapter_production09_scope/scope_request_READY.json';assert not p.exists();p.parent.mkdir()
b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
with p.open('xb') as f:f.write(b)
print(json.dumps({'path':S+'finite_adapter_production09_scope/scope_request_READY.json','sha256':sha(b),'targets':29,'registry_old_sha256':registry['sha256']}))
