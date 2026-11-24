"""NEW exact Root backup-schema adapter and QA pin; text only, never Stage."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance42_culture24_source_recipe/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s,('PIN',v);return b
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
tp=S+'stage_performance41_culture24_READY.py';ts='0f93d4750086ae1d97f528130c4c5e86cfa32b47e7613233669c99fd7af5ff00'
ip=S+'performance41_culture24_source_recipe/source_input_ROOT_LOCKED.json';iss='2b6a82c9e3837f548eaa2a03abc6845571dd2ca0af78af786bae01f82138a6fd'
oldtool=fixed(tp,ts);oldinput=fixed(ip,iss);tool=oldtool.decode();spec=json.loads(oldinput)
replacements=[
    ("backups.get('count')==24", "backups.get('target_count')==24 and len(backups.get('targets',[]))==24"),
    ("        need(len(self.oldtargets)==24 and [r['target']for r in request['targets']]==spec['root_target_allowlist'] and {r['target']:r['old_sha256']for r in backups['targets']}==self.oldtargets,'EXACT24_ORDERED_OLD_VALUES')\n        for r in backups['targets']:\n            backup=Path(r['backup_path']).resolve();need(backup.is_relative_to(M.ROOT),'ROOT_BACKUP_GAME_DOMAIN')\n            need(self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['old_sha256'])==self.read(r['target'],r['old_sha256']),'ALL24_OLD_BYTES_BACKED_UP')",
     "        backup_targets={}\n        for r in backups['targets']:\n            target_path=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve()\n            need(target_path.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'ROOT_BACKUP_GAME_DOMAIN')\n            target='res://'+target_path.relative_to(M.ROOT).as_posix()\n            need(target not in backup_targets,'UNIQUE_ROOT_BACKUP_TARGET')\n            backup_targets[target]=r['sha256']\n            saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);current=self.read(target,r['sha256'])\n            need(saved==current and len(saved)==r['bytes'],'ALL24_OLD_BYTES_BACKED_UP')\n        need(len(self.oldtargets)==24 and [r['target']for r in request['targets']]==spec['root_target_allowlist'] and backup_targets==self.oldtargets,'EXACT24_ORDERED_OLD_VALUES')")]
for a,b in replacements:
    assert tool.count(a)==1;tool=tool.replace(a,b,1)
newtool=tool.encode();ast.parse(newtool)
back=newtool.decode()
for a,b in reversed(replacements):assert back.count(b)==1;back=back.replace(b,a,1)
assert back.encode()==oldtool
nt=S+'stage_performance42_culture24_READY.py';spec['required_generator']={'path':nt,'sha256':sha(newtool)}
review='res://build/luoyang_city_full_rollout_20261022ap_qa01/culture40_24scope_BF043_independent_static_dependency_review_READY.json'
reviews='1fb6968b3f142784bc8ebdbd2d468b2365be825be85ac31064480e9cb93bee2e'
fixed(review,reviews)
spec['pinned_inputs'].append({'id':'culture_dependency_independent_review','path':review,'sha256':reviews})
spec['B_only_contract']['independent_dependency_review_input']='culture_dependency_independent_review'
restored=copy.deepcopy(spec);restored['required_generator']=json.loads(oldinput)['required_generator'];del restored['B_only_contract']['independent_dependency_review_input'];assert restored['pinned_inputs'].pop()=={'id':'culture_dependency_independent_review','path':review,'sha256':reviews};assert js(restored)==oldinput
# Pure static schema projection of the fixed Root document; no Stage import/run.
backup_pin=next(r for r in spec['pinned_inputs']if r['id']=='culture_old_backups')
backup=json.loads(fixed(backup_pin['path'],backup_pin['sha256']))
request_pin=next(r for r in spec['pinned_inputs']if r['id']=='B_only_scope_request')
request=json.loads(fixed(request_pin['path'],request_pin['sha256']))
assert backup['target_count']==len(backup['targets'])==24
projection={}
for r in backup['targets']:
    q=Path(r['path']).resolve();assert q.is_relative_to(G)
    target='res://'+q.relative_to(G).as_posix();assert target not in projection;projection[target]=r['sha256']
assert projection=={r['target']:r['old_sha256']for r in request['targets']}
proof={'status':'EXACT_ROOT31_BACKUP_SCHEMA_ADAPTER_AND_QA_PIN_ONLY_NOT_STAGED','parent_driver':{'path':tp,'sha256':ts},'new_driver':{'path':nt,'sha256':sha(newtool)},'driver_unique_replacements':[{'old':a,'new':b}for a,b in replacements],'whole_driver_byte_inverse':True,'parent_input':{'path':ip,'sha256':iss},'whole_input_typed_and_serialized_UTF8_inverse':True,'input_delta_exactly':['required_generator','one independent QA pinned input','B_only_contract independent_dependency_review_input'],'fixed_root_backup_schema_target_count_path_sha256_projected_exact24':True,'no_Root_document_changes':True,'other_source_nodes_groups_targets_authority_output_root_whole_unchanged':True,'Stage_engine_collector_formal_calls':0}
nb=js(spec);np=O+'source_input_ROOT_LOCKED.json';pb=js(proof)
diff=''.join(difflib.unified_diff(oldtool.decode().splitlines(True),newtool.decode().splitlines(True),fromfile=tp,tofile=nt)).encode()
idiff=''.join(difflib.unified_diff(oldinput.decode().splitlines(True),nb.decode().splitlines(True),fromfile=ip,tofile=np)).encode()
handoff={'status':'ROOT31_CULTURE24_FINAL_SCHEMA_CORRECT_DRIVER_INPUT_NOT_STAGED','driver':{'path':nt,'sha256':sha(newtool)},'input':{'path':np,'sha256':sha(nb)},'schema_adapter_inverse':{'path':O+'schema_adapter_and_input_inverse_READY.json','sha256':sha(pb)},'original_complete_driver_and_DAG_inverse':{'path':S+'performance41_culture24_source_recipe/driver_and_input_whole_inverse_READY.json','sha256':'8eb09eec4a3690d0e46269ed26ae1c27195513c6db113bc4c138ca85ac37fbef'},'original_complete_driver_diff':{'path':S+'performance41_culture24_source_recipe/driver_complete_vs71C6.diff','sha256':'0403ed106095a8ea3dd63de288d4f48f9827730ff8cd81ff45e1ae32b73c9807'},'driver_schema_diff':{'path':O+'driver_complete_vs41.diff','sha256':sha(diff)},'input_complete_diff':{'path':O+'input_complete_vs41.diff','sha256':sha(idiff)},'targets':24,'GD':10,'JSON':14,'QA_dependency_review':{'path':review,'sha256':reviews},'no_Stage_engine_formal_calls':True,'Root_only_NOT_EXECUTED_command':'python '+str(p(nt))+' '+str(p(np))+' --input-sha256 '+sha(nb)}
files={nt:newtool,np:nb,O+'schema_adapter_and_input_inverse_READY.json':pb,O+'driver_complete_vs41.diff':diff,O+'input_complete_vs41.diff':idiff,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(nt).exists()
for v,b in files.items():p(v).parent.mkdir(parents=True,exist_ok=True);p(v).write_bytes(b)
print(json.dumps({v:sha(b)for v,b in files.items()},indent=2))
