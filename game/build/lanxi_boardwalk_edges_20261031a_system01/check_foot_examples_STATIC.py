"""Small pure polygon foot checks for QA seed coordinates; not engine/Physics."""
from pathlib import Path
import hashlib,json,math,re
HERE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def colliders(p):
 text=p.read_text(encoding='utf-8-sig');nodes={}
 for m in re.finditer(r'^\[node name="([^"]+)"[^\n]*\]\n(.*?)(?=^\[node |\Z)',text,re.M|re.S):
  head=m[0].split('\n',1)[0];parent=re.search(r'parent="([^"]+)"',head)
  parent=parent[1] if parent else '';key=(parent+'/' if parent not in ['', '.'] else '')+m[1]
  position=re.search(r'^position = Vector2\(([^,]+), ([^)]+)\)',m[2],re.M)
  pos=[float(position[1]),float(position[2])] if position else [0,0]
  if parent not in ['', '.']:
   q=nodes[parent]['pos'];pos=[q[0]+pos[0],q[1]+pos[1]]
  layer=re.search(r'^collision_layer = (\d+)',m[2],re.M)
  nodes[key]={'head':head,'pos':pos,'layer':int(layer[1]) if layer else 1,'parent':parent,'body':m[2]}
 result=[]
 for path,node in nodes.items():
  if 'type="CollisionPolygon2D"' not in node['head']:continue
  parent=nodes.get(node['parent'],{})
  if 'type="StaticBody2D"' not in parent.get('head',''):continue
  match=re.search(r'^polygon = PackedVector2Array\(([^)]+)\)',node['body'],re.M)
  if not match:continue
  n=[float(v.strip()) for v in match[1].split(',')]
  pts=[[n[i]+node['pos'][0],n[i+1]+node['pos'][1]] for i in range(0,len(n),2)]
  result.append({'path':node['parent'],'layer':parent['layer'],'points':pts,'segments_only':bool(re.search(r'^build_mode = 1$',node['body'],re.M))})
 return result
def inside(p,poly):
 out=False
 for i,a in enumerate(poly):
  b=poly[i-1]
  if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:out=not out
 return out
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def segments(a,b,c,d):
 q=[cross(a,b,c),cross(a,b,d),cross(c,d,a),cross(c,d,b)]
 if q[0]*q[1]<0 and q[2]*q[3]<0:return True
 for v,p,x,y in [(q[0],c,a,b),(q[1],d,a,b),(q[2],a,c,d),(q[3],b,c,d)]:
  if v==0 and min(x[0],y[0])<=p[0]<=max(x[0],y[0]) and min(x[1],y[1])<=p[1]<=max(x[1],y[1]):return True
 return False
def intersects(a,b):
 if any(inside(p,b) for p in a) or any(inside(p,a) for p in b):return True
 return any(segments(a[i-1],p,b[j-1],q) for i,p in enumerate(a) for j,q in enumerate(b))
def hits(rows,foot):
 x,y=foot;body=[[x-17.5,y-12.5],[x+17.5,y-12.5],[x+17.5,y+12.5],[x-17.5,y+12.5]]
 out=[]
 for r in rows:
  if not r['layer']&24:continue
  if r['segments_only']:
   collision=any(segments(body[i-1],p,r['points'][j-1],q) for i,p in enumerate(body) for j,q in enumerate(r['points']))
  else:collision=intersects(body,r['points'])
  if collision:out.append(r['path'])
 return out
old_path=HERE/'miao_town.tscn.BEFORE';new_path=HERE/'miao_town_READY.tscn'
old=colliders(old_path);new=colliders(new_path)
examples={'board3_front_legacy_positive':[3650,3586],'board4_front_legacy_positive':[6740,3956],'board3_far_support_ground':[3650,3660],'board4_far_support_ground':[6740,4030],'board3_right_inside':[4190,3560],'board3_right_outside':[4260,3560],'board4_left_outside':[6120,3930],'board4_right_outside':[7360,3930],'board4_back_extension_legacy_positive':[7270,3902],'board4_old_back_invalid':[6740,3902],'board3_inherited_water_tip':[3075.8,3560]}
rows=[{'id':key,'foot':point,'old_static_hits':hits(old,point),'new_static_hits':hits(new,point)} for key,point in examples.items()]
# Check only new side coverage and originally dry endpoint examples, not town routes.
assert not rows[0]['old_static_hits'] and 'Town/RaisedMarket3/FrontRail' in rows[0]['new_static_hits']
assert not rows[1]['old_static_hits'] and 'Town/RaisedMarket4/FrontRail' in rows[1]['new_static_hits']
result={'status':'STATIC_POLYGON_FULL35x25_ONLY_NOT_ENGINE_OR_DYNAMIC_NPC_PROOF','source_old_sha256':sha(old_path),'source_new_sha256':sha(new_path),'rows':rows,'engine_runs':0,'save_access':False}
b=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'foot_examples_STATIC_02_READY.json';assert not out.exists()
with out.open('xb') as f:f.write(b)
print(json.dumps({'sha256':sha(out),'bytes':len(b),'rows':rows},ensure_ascii=False))
