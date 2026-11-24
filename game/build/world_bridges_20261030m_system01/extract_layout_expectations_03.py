"""Canonical existing TRES literals -> strict bridge row expectation evidence.

Pure read-only lexer for the authored Variant text; never evaluates GDScript,
runs Godot, changes original layout/geometry, or loosens an equality check.
"""
from pathlib import Path
import hashlib,json,re,struct
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
layout=GAME/'data/maps/world_map_jianghu_layout_v15.tres'
original=HERE/'bridge_source_rows_READY.json'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(layout)=='aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072'
assert sha(original)=='03fd46ccba6f268079810d9d94a0904cd1ad336e965069102e5c48ddf04a9df0'
data=json.loads(original.read_text(encoding='utf-8-sig'))
text=layout.read_text(encoding='utf-8-sig')
start=text.index('visual_objects =')
brace=0;quote=False;escape=False;row_start=None;objects={}
for i in range(start,len(text)):
 c=text[i]
 if quote:
  if escape:escape=False
  elif c=='\\':escape=True
  elif c=='"':quote=False
  continue
 if c=='"':quote=True;continue
 if c=='{':
  if brace==0:row_start=i
  brace+=1
 elif c=='}':
  brace-=1
  if brace==0 and row_start is not None:
   raw=text[row_start:i+1]
   match=re.search(r'"id":\s*("bridge_[^"]+")',raw)
   if match:
    key=json.loads(match.group(1));assert key not in objects
    objects[key]=raw
   row_start=None
 elif brace==0 and c==']' and row_start is None and len(objects)==93:break
assert len(objects)==93

def fields(raw):
 # Split only on top-level dictionary commas, retaining exact value literals.
 chunks=[];begin=1;depth=0;quoted=False;escaped=False
 for i,c in enumerate(raw[1:-1],1):
  if quoted:
   if escaped:escaped=False
   elif c=='\\':escaped=True
   elif c=='"':quoted=False
   continue
  if c=='"':quoted=True
  elif c in '([{':depth+=1
  elif c in ')]}':depth-=1
  elif c==',' and depth==0:chunks.append(raw[begin:i]);begin=i+1
 chunks.append(raw[begin:-1])
 result={}
 for chunk in chunks:
  match=re.fullmatch(r'\s*("(?:[^"\\]|\\.)*")\s*:\s*(.*?)\s*',chunk,re.S)
  assert match,chunk[:100]
  key=json.loads(match.group(1));assert key not in result
  result[key]=match.group(2)
 return result
def f32(x):return struct.unpack('<f',struct.pack('<f',float(x)))[0]
def vector(literal):
 m=re.fullmatch(r'Vector2\(([^,]+),\s*([^\)]+)\)',literal)
 assert m,literal
 return [f32(m[1]),f32(m[2])]
def polygons(literal):
 assert literal.startswith('Array[PackedVector2Array](')
 out=[]
 for match in re.finditer(r'PackedVector2Array\(([^)]*)\)',literal):
  numbers=[f32(n.strip()) for n in match[1].split(',') if n.strip()]
  assert len(numbers)%2==0
  out.append([numbers[i:i+2] for i in range(0,len(numbers),2)])
 assert out
 return out
def norm_source(v,kind):
 if kind=='vec':return [f32(n) for n in v]
 if kind=='polys':return [[[f32(n) for n in p] for p in poly] for poly in v]
 return v
changes=[];checked=0
for row in data['rows']:
 actual=fields(objects[row['id']])
 checks=[('id','str',''),('role','str',''),('texture','str',''),('pos','vec',None),('render_size_px','vec',None),('sort_by_feet','bool',False),('centered','bool',True),('rotation','float',0),('z_index','float',0),('depth_sort_foot_y','float',0),('collision_size','vec',None),('collision_offset','vec',None),('walkability_margin_px','vec',None),('solid_polygons_px','polys',None)]
 for key,kind,default in checks:
  checked+=1
  if key in actual:
   literal=actual[key]
   value=vector(literal) if kind=='vec' else polygons(literal) if kind=='polys' else float(literal) if kind=='float' else json.loads(literal)
  else:literal='<absent>';value=default
  expected=norm_source(row[key],kind) if key in row else default
  presence_diff=kind in ['vec','polys'] and ((key in actual)!=(key in row))
  if expected!=value or presence_diff:
   changes.append({'id':row['id'],'field':key,'original_JSON_value':row.get(key),'canonical_TRES_literal':literal,'canonical_runtime_value':value,'difference_kind':'EXACT_AUTHORED_FLOAT64_SERIALIZATION' if kind=='float' else 'EXACT_AUTHORED_VARIANT','numeric_delta':value-float(row.get(key,default)) if kind=='float' else None})
   if key in actual:row[key]=value
   else:row.pop(key,None)
data['canonical_expectation_basis']={'source':'EXISTING_UNMODIFIED_TRES_TYPED_LITERALS','layout_path':'res://data/maps/world_map_jianghu_layout_v15.tres','layout_sha256':sha(layout),'original_JSON_evidence_path':original.name,'original_JSON_evidence_sha256':sha(original),'rows':93,'checked_guard_fields':checked,'changes':changes,'no_epsilon_or_guard_relaxation':True,'engine_runs':0,'canonical_writes':0,'geometry_changes':0}
out=HERE/'bridge_source_rows_LAYOUT_TYPED_03_READY.json';assert not out.exists()
b=(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(b)
print(json.dumps({'path':str(out),'sha256':sha(out),'bytes':len(b),'checked_guard_fields':checked,'changes':changes},ensure_ascii=False))
