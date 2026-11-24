"""31b local static proof and exact three-target candidates. Never writes formal paths."""
from pathlib import Path
import json,re,hashlib,difflib
HERE=Path(__file__).resolve().parent
scope={'__file__':str(HERE/'audit_paddy_layout.py')}
exec((HERE/'audit_paddy_layout.py').read_text(encoding='utf-8').split('result=[]\nfor number')[0],scope)
nodes=scope['nodes'];GAME=scope['GAME'];terrain=scope['terrain']
proposal=json.loads((HERE/'proposal_STATIC_01.json').read_text(encoding='utf-8'))
def digest(b):return hashlib.sha256(b).hexdigest()
def emit(name,data):
 p=HERE/name
 if p.exists():
  assert p.read_bytes()==data,p
  return {'path':str(p.relative_to(GAME.parent)).replace('\\','/'),'sha256':digest(data),'bytes':len(data)}
 with p.open('xb') as f:f.write(data)
 return {'path':str(p.relative_to(GAME.parent)).replace('\\','/'),'sha256':digest(data),'bytes':len(data)}
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def inside(p,poly):
 yes=False
 for i,a in enumerate(poly):
  b=poly[i-1]
  if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:yes=not yes
 return yes
def collide(a,b):return any(inside(p,b) for p in a) or any(inside(p,a) for p in b) or any(cross(a[i-1],p,b[j-1])*cross(a[i-1],p,q)<0 and cross(b[j-1],q,a[i-1])*cross(b[j-1],q,p)<0 for i,p in enumerate(a) for j,q in enumerate(b))
old={};new={r['name']:r['new_body_world_polygon'] for r in proposal['rows']};solids={}
for path,node in nodes.items():
 if 'type="CollisionPolygon2D"' not in node['head'] or 'build_mode = 1' in node['raw']:continue
 parent=nodes.get(node['parent'],{})
 if 'type="StaticBody2D"' not in parent.get('head','') or not int(scope['scalar'](parent['raw'],'collision_layer',1))&40:continue
 m=re.search(r'polygon = PackedVector2Array\(([^)]+)\)',node['raw'])
 if not m:continue
 a=[float(v) for v in m[1].split(',')];poly=[[a[i]+node['position'][0],a[i+1]+node['position'][1]] for i in range(0,len(a),2)]
 if re.fullmatch(r'Town/Paddy[1-4]/Body/Outline',path):old[path.split('/')[1]]=poly
 solids[node['parent']]=poly
current=dict(solids)
for name,poly in new.items():current['Town/'+name+'/Body']=poly
def foot(p):return [[p[0]-17.5,p[1]-12.5],[p[0]+17.5,p[1]-12.5],[p[0]+17.5,p[1]+12.5],[p[0]-17.5,p[1]+12.5]]
def hits(p,shapes):return [name for name,poly in shapes.items() if collide(foot(p),poly)]
bunds={'Paddy1':[6600,1440],'Paddy2':[6750,1880],'Paddy3':[6750,2280],'Paddy4':[6500,2880]}
checks=[{'kind':'DECLARED_BUND','name':name,'foot':p,'current_hits':hits(p,current),'inside_L1':inside(p,terrain['platforms'][0]['polygon']) and not inside(p,terrain['platforms'][1]['polygon'])} for name,p in bunds.items()]
for c in checks:assert not c['current_hits'] and c['inside_L1'],c
for p in [[6300,2790],[6750,2790],[6500,2700]]:checks.append({'kind':'RESTORE_SAMPLE','foot':p,'old_hits':hits(p,solids),'new_hits':hits(p,current)})
assert checks[4]['old_hits']==[] and checks[4]['new_hits']==['Town/Paddy4/Body'],checks[4]
assert 'Town/Paddy4/Body' in checks[5]['old_hits'] and checks[6]['new_hits']==[],checks
emit('local_compat_STATIC_READY.json',(json.dumps({'status':'LOCAL_STATIC_ONLY_NOT_ENGINE','foot':[35,25],'checks':checks,'positive_before':[6300,2790],'positive_after':bunds['Paddy4'],'clear_unchanged':[6500,2700],'old_illegal_no_custom_migration':[6750,2790]},ensure_ascii=False,indent=2)+'\n').encode())

scene=GAME/'scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
native=GAME/'build/three_towns_world_20261029j_system01/native_sources.json'
registry=GAME/'build/three_towns_world_20261029j_system01/town_registry.gd'
before={p:p.read_bytes() for p in [scene,native,registry]}
assert digest(before[native])=='0f39017f7f88cdc3f175e1962ee4b0a2882e67be034814df95d5d2b35d2ac8dd'
assert digest(before[registry])=='83cf61babb48ec7ff2cb2a4cd4c18ae724c6c457fb4bb39a32e41ee46f4f1054'
source=before[scene].decode('utf-8');changed=source;scene_newline='\r\n' if b'\r\n' in before[scene] else '\n'
helper=HERE/'paddy_controller.gd';helper_bytes=helper.read_bytes();assert helper_bytes.endswith(b'\n') and not helper_bytes.endswith(b'\n\n')
helper_uri='res://build/lanxi_paddy_passage_20261031b_system01/paddy_controller.gd'
old_uri='res://build/lanxi_boardwalk_edges_20261031a_system01/boardwalk_controller.gd'
assert changed.count('path="'+old_uri+'"')==1
changed=changed.replace('path="'+old_uri+'"','path="'+helper_uri+'"')
def fmt(v):return format(v,'.9f').rstrip('0').rstrip('.') if v else '0'
def vec(v):return 'Vector2('+', '.join(fmt(x) for x in v)+')'
for row in proposal['rows']:
 name=row['name'];root=nodes['Town/'+name];art=nodes['Town/'+name+'/Art'];outline=nodes['Town/'+name+'/Body/Outline'];ratio=row['ratio']
 newroot=root['raw'];newroot=re.sub(r'^position = Vector2\([^\n]+', 'position = '+vec(row['foot']),newroot,flags=re.M)
 m=re.search(r'metadata/visual_rect = Rect2\(([^)]+)\)',newroot);a=[float(v)*ratio for v in m[1].split(',')]
 newroot=newroot.replace(m[0],'metadata/visual_rect = Rect2('+', '.join(fmt(v) for v in a)+')')
 newart=re.sub(r'^position = Vector2\([^\n]+','position = '+vec(row['new_art_local_position']),art['raw'],flags=re.M)
 newart=re.sub(r'^scale = Vector2\([^\n]+','scale = '+vec([row['scale']]*2),newart,flags=re.M)
 poly=[v-row['foot'][i%2] for point in row['new_body_world_polygon'] for i,v in enumerate(point)]
 # Every point subtracts the same authored root. No root/node scaling.
 newoutline=re.sub(r'polygon = PackedVector2Array\([^)]+\)','polygon = PackedVector2Array('+', '.join(fmt(v) for v in poly)+')',outline['raw'])
 for node,raw in [(root,newroot),(art,newart),(outline,newoutline)]:
  oldblock=(node['head']+'\n'+node['raw']).replace('\n',scene_newline);newblock=(node['head']+'\n'+raw).replace('\n',scene_newline)
  assert changed.count(oldblock)==1,node['path'];changed=changed.replace(oldblock,newblock)
after={scene:changed.encode()}
manifest=json.loads(before[native]);old_sources=dict(manifest['sources']);assert len(old_sources)==201
scene_uri='res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
manifest['sources'][scene_uri]=digest(after[scene]);manifest['sources'][helper_uri]=digest(helper_bytes)
assert len(manifest['sources'])==202
assert {k:v for k,v in manifest['sources'].items() if k not in [scene_uri,helper_uri]}=={k:v for k,v in old_sources.items() if k!=scene_uri}
after[native]=(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode()
after[registry]=before[registry].replace(digest(before[native]).encode(),digest(after[native]).encode())
assert after[registry]!=before[registry]
targets=[];hunks=[]
for p,label in [(scene,'miao_town.tscn'),(native,'native_sources.json'),(registry,'town_registry.gd')]:
 b=emit(label+'.BEFORE',before[p]);a=emit(label+'.READY',after[p])
 delta=''.join(difflib.unified_diff(before[p].decode().splitlines(True),after[p].decode().splitlines(True),fromfile=str(p.relative_to(GAME.parent)),tofile=str(p.relative_to(GAME.parent))))
 reverse=''.join(difflib.unified_diff(after[p].decode().splitlines(True),before[p].decode().splitlines(True),fromfile=str(p.relative_to(GAME.parent)),tofile=str(p.relative_to(GAME.parent))))
 emit(label+'.forward.diff',delta.encode());emit(label+'.inverse.diff',reverse.encode())
 targets.append({'target':str(p.relative_to(GAME.parent)).replace('\\','/'),'before':b,'candidate':a,'byte_inverse_verified':after[p].replace(after[p],before[p])==before[p]})
 hunks.append(delta)
emit('combined.forward.diff',''.join(hunks).encode())
receipt={'status':'CANDIDATE_ONLY_NO_ENGINE_NO_FORMAL_WRITE','targets':targets,'new_modules':[{ 'path':str(helper.relative_to(GAME.parent)).replace('\\','/'),'sha256':digest(helper_bytes),'bytes':len(helper_bytes)}],'source_count_before':201,'source_count_after':202,'registry_IDs_unchanged':True,'Router_write':False,'PNG_write':False,'save_access':False,'static_proposal_sha256':digest((HERE/'proposal_STATIC_01.json').read_bytes()),'local_compat_sha256':digest((HERE/'local_compat_STATIC_READY.json').read_bytes()),'unchanged_nodes':'Every non-Paddy node byte-exact; Paddy root only position/visual_rect, Art only position/scale, Outline only polygon. All existing UIDs and roots level1/elevation120 retained.','debug_API':'native_town.get_paddy_passage_debug()','positive_legacy_sample':{'before':[6300,2790],'after':[6500,2880],'level':1,'height':120},'clear_sample':[6500,2700],'old_illegal_sample':[6750,2790]}
fact=emit('replacement_receipt_READY.json',(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode());print(json.dumps({'receipt':fact,'targets':targets,'new_modules':receipt['new_modules'],'local_checks':checks},ensure_ascii=False))
