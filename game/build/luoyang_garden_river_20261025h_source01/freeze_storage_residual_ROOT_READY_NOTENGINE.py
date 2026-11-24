from pathlib import Path
import json,copy,hashlib
P=Path(__file__).resolve().parent
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(name,b):
 p=P/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return {'path':R+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v):return save(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
raw=(P/'storage_residual03/complete_storage_NOTREADY.gd').read_bytes()
assert sha(raw)=='87cafa6346177827cf21e7f3a22c3f69e138b667faf9435a69d95d22ba91356a'
hunks=[
 (b'storage_residual03/input_NOTREADY.json',b'storage_residual03/ROOT_READY/input_READY.json'),
 (b'storage_residual03/reports/',b'storage_residual03/ROOT_READY/reports/'),
 (b'\tif not fixed(input.fixed_failure.path,input.fixed_failure.sha256)',b'\tif not need(get_script().resource_path==input.completion_script.path,"FIXED_COMPLETION_SCRIPT_PATH") or not fixed(input.completion_script.path,input.completion_script.sha256): return {}\n\tif not fixed(input.fixed_failure.path,input.fixed_failure.sha256)')]
new=raw
for a,b in hunks:assert new.count(a)==1;new=new.replace(a,b)
reverse=new
for a,b in reversed(hunks):assert reverse.count(b)==1;reverse=reverse.replace(b,a)
assert reverse==raw
key=save('storage_residual03/ROOT_READY/complete_storage_READY.gd',new)
ib=(P/'storage_residual03/input_NOTREADY.json').read_bytes()
assert sha(ib)=='e04cec63c6fccd9a334502ecfd757b360c1be0d878474355a8dca44be52881a6'
v=json.loads(ib);parent=copy.deepcopy(v)
v['status']='ROOT_READY_GARDEN_STORAGE_ONLY_COMPLETION';v['ready']=True;v['completion_script']=key
rev=copy.deepcopy(v);rev.pop('completion_script');rev['ready']=False;rev['status']=parent['status'];assert rev==parent
inp=dump('storage_residual03/ROOT_READY/input_READY.json',v)
proof=dump('storage_residual03/ROOT_READY/mechanical_freeze_inverse.json',{
 'status':'ROOT_APPROVED_STORAGE_EXPECTATIONS_MECHANICAL_READY_ONLY_NOT_EXECUTED','key':key,'input':inp,
 'key_hunks':[{'old':a.decode(),'new':b.decode()}for a,b in hunks],'whole_byte_key_inverse':True,
 'input_only_readiness_status_and_completion_self_pin':True,'whole_typed_input_inverse':True,
 'original49_sources_and_fixed4_native_and_missing_packet_output_unchanged':True,
 'source_projection_A0DA_and_no_images_routes_raster_or_C_compile_unchanged':True,'engine':0,'canonical_writes':0})
print(json.dumps({'key':key,'input':inp,'proof':proof}))
