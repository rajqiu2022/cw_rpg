from pathlib import Path
import hashlib,json,copy
P=Path(__file__).resolve().parent
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(name,b):
 p=P/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return {'path':R+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v):return save(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
b=(P/'storage_residual02/source_storage_projection_NOTRUN.gd').read_bytes()
assert sha(b)=='d281db1f4842bc1d78a42ab5464138d6b4fd399b21493fe36b4628459ca4127a'
old=b'\tvar scene:=SceneScript.new()'
new=b'\tvar walk_area: Rect2=rect(data.walk_rect)\n'+old
assert b.count(old)==1
newb=b.replace(old,new)
assert newb.replace(new,old)==b
projection=save('storage_residual03/source_storage_projection_NOTRUN.gd',newb)
inp=json.loads((P/'storage_residual02/input_NOTREADY.json').read_bytes())
inp['projection']=projection
inp['storage_projection_explanation']='Exact fixed approved compiler storage constructors, with validated image/body/audit/raster paths removed. walk_area retains its original source expression for the native walkable_regions field. One deterministic deck clip remains only to reconstruct already-passed typed metadata; no C.compile, PNG source reads, route tests or raster.'
fixture=dump('storage_residual03/input_NOTREADY.json',inp)
probe=(P/'storage_residual02/complete_storage_NOTREADY.gd').read_bytes()
probe_new=probe.replace(b'storage_residual02/input_NOTREADY.json',b'storage_residual03/input_NOTREADY.json').replace(b'storage_residual02/reports/',b'storage_residual03/reports/')
assert probe_new.replace(b'storage_residual03/input_NOTREADY.json',b'storage_residual02/input_NOTREADY.json').replace(b'storage_residual03/reports/',b'storage_residual02/reports/')==probe
key=save('storage_residual03/complete_storage_NOTREADY.gd',probe_new)
proof=dump('storage_residual03/source_provenance_and_no_replay_NOTRUN.json',{
 'status':'ROOT_REVIEW_REQUIRED_SOURCE_EXPRESSION_STORAGE_COMPLETION',
 'projection':projection,'input':fixture,'key':key,
 'original_fixed_source_provenance':{'path':R+'storage_residual02/exact_projection_expression_provenance_NOTRUN.json','sha256':'03e1951993e37948062da5633ead319a78d80f3d318b13325dcc65a6c3f8dbe1'},
 'projection02_fix_before_any_execution':{'old':old.decode(),'new':new.decode(),'whole_byte_inverse':True,'reason':'Keep original compiler walk_area expression used later by layout.walkable_regions; no mask construction.'},
 'completion_guards':['49 original exact source leaves','four existing native exact byte inputs','source expression Scene and layout complete typed comparison with first-difference path/type/value','no observed field used in expected storage','fixed first-failure route report compared to source cardinalities only, no route rerun','existing child-mask payload read once and D552 hash before missing packet completion','packet ABSENT before write; scene/layout/front/walk never overwritten','20s fixed'],
 'engine':0,'canonical_writes':0})
print(json.dumps({'projection':projection,'input':fixture,'key':key,'proof':proof}))
