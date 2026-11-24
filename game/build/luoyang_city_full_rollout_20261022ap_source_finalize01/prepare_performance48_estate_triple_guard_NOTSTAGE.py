"""NEW exact semantic triple guard; no Stage execution."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance48_estate17_source_recipe/'
def sha(b):return hashlib.sha256(b).hexdigest()
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
old=(H/'stage_performance47_estate17_READY.py').read_bytes();assert sha(old)=='497dd020f32809a74653e24de24796b34580a3909d077a4412839461fcdcac60'
t=old.decode();a="            need(self.proofs[row['id']].get('whole_typed_inverse') is True and self.outputs[value['path']]==candidate,'ORIGINAL_METADATA_INVERSE_AND_ENCODE_EXACT2410')"
b=a+"\n            config=value['value'];registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'\n            need(config.get('registry_path')==registry and config.get('registry_sha256')==config.get('source_sha256',{}).get(registry)=='f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28','FIXED_REGISTRY_PATH_SCALAR_DECLARED_SOURCE_TRIPLE_EQUALITY')"
assert t.count(a)==1;t=t.replace(a,b,1);new=t.encode();assert t.replace(b,a,1).encode()==old;ast.parse(new)
ip=H/'performance47_estate17_source_recipe/source_input_ROOT_LOCKED.json';ib=ip.read_bytes();assert sha(ib)=='baaa5b3c1161283443d1949a6e9fd574b3996672db8dbde5fda6cb26ef28a6da';v=json.loads(ib);original=copy.deepcopy(v['required_generator'])
nt=S+'stage_performance48_estate17_READY.py';v['required_generator']={'path':nt,'sha256':sha(new)};nb=js(v);rev=copy.deepcopy(v);rev['required_generator']=original;assert js(rev)==ib
root=H/'stage_performance42_culture24_READY.py';base=root.read_bytes();diff=''.join(difflib.unified_diff(base.decode().splitlines(True),t.splitlines(True),fromfile=S+root.name,tofile=nt)).encode()
proof={'status':'EXACT17_SINGLE_TRIPLE_SEMANTIC_GUARD_ONLY_NOT_STAGED','parent_driver_sha256':sha(old),'new_driver_sha256':sha(new),'whole_byte_inverse':True,'one_hunk':{'old':a,'new':b},'input_parent_sha256':sha(ib),'input_only_required_generator_change_whole_serialized_inverse':True,'all_nodes_groups_targets_gates_pins_output_epoch_unchanged':True,'no_Stage_engine_formal_calls':True}
pb=js(proof);handoff={'status':'ROOT35_FINAL_EXACT17_SCALAR_AND_TRIPLE_GUARD_READY_NOT_STAGED','driver':{'path':nt,'sha256':sha(new)},'input':{'path':O+'source_input_ROOT_LOCKED.json','sha256':sha(nb)},'complete_driver_vs42':{'path':O+'driver_complete_vs42.diff','sha256':sha(diff)},'original47_whole_DAG_input_inverse':{'path':S+'performance47_estate17_source_recipe/driver_input_whole_inverse_READY.json','sha256':'e22da4835617ae6eb00effdcde49f09245d50200fc36e17e214bd8600655c648'},'one_semantic_hunk_inverse':{'path':O+'triple_guard_whole_inverse_READY.json','sha256':sha(pb)},'targets':17,'GD':6,'JSON':11,'original8DE0_metadata_validator_unchanged':True,'Root_only_NOT_EXECUTED_command':'python '+str(H/'stage_performance48_estate17_READY.py')+' '+str(H/'performance48_estate17_source_recipe/source_input_ROOT_LOCKED.json')+' --input-sha256 '+sha(nb)}
files={nt:new,O+'source_input_ROOT_LOCKED.json':nb,O+'driver_complete_vs42.diff':diff,O+'triple_guard_whole_inverse_READY.json':pb,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
for path in files:
    dest=H/path.removeprefix(S);assert not dest.exists()
for path,data in files.items():dest=H/path.removeprefix(S);dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
print(json.dumps({path:sha(data)for path,data in files.items()},indent=2))
