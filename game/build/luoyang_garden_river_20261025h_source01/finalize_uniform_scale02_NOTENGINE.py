from pathlib import Path
import json, hashlib, copy
P=Path(__file__).resolve().parent
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(name,b):
 p=P/name
 assert not p.exists()
 with p.open('xb') as f:f.write(b)
 return {'path':R+name,'sha256':sha(b),'bytes':len(b)}
old=(P/'garden_river_compiler_NOTREADY.gd').read_bytes()
assert sha(old)=='6076faef77aae73209e4e26b13f3735438d4246ec2c4151781a86c5a7f61f1a9'
a=b'var scale_value: float=float(row.width)/float(asset.used_rect[2])'
b=b'var scale_value: float=float(row.uniform_scale) if row.get("id")=="garden_stone_bridge_walkable_25h" else float(row.width)/float(asset.used_rect[2])'
assert old.count(a)==1
new=old.replace(a,b)
assert new.replace(b,a)==old
c=save('garden_river_compiler02_NOTREADY.gd',new)
raw=(P/'author_river_bridge02_NOTREADY.json').read_bytes()
v=json.loads(raw);before=copy.deepcopy(v)
rows=[x for x in v['scenes'][0]['placements'] if x['id']=='garden_stone_bridge_walkable_25h']
assert len(rows)==1 and rows[0]['uniform_scale']==.7 and rows[0]['width']==1232.7
rows[0]['width']=1761*.7
v['bridge_contract']['width_is_derived_not_uniform_division']='The authoritative .7 scalar is used directly before f32 Vector2 arithmetic; A1 width is its product, never divided back to infer the scalar.'
rev=copy.deepcopy(v)
[x for x in rev['scenes'][0]['placements'] if x['id']=='garden_stone_bridge_walkable_25h'][0]['width']=1232.7
rev['bridge_contract'].pop('width_is_derived_not_uniform_division')
assert rev==before
d=save('author_river_bridge03_NOTREADY.json',(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
p=save('uniform_scale02_exact_inverse_NOT_RUNTIME.json',(json.dumps({'status':'PRE_EXECUTION_EXACT_UNIFORM_SOURCE_DECIMAL_FIX','compiler':c,'author':d,'parent_compiler_sha256':sha(old),'old':a.decode(),'new':b.decode(),'whole_byte_inverse':True,'whole_typed_author_inverse':True,'reason':'1232.7/1761 is not exactly .7 in IEEE double. Consume the explicit admitted uniform .7; do not infer it from rounded display width.','engine':0},indent=2)+'\n').encode())
print(json.dumps({'compiler':c,'author':d,'proof':p}))
