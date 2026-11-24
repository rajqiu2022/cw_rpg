"""Four paddy-local proposal checks only; no game/PNG writes, no engine."""
from pathlib import Path
import hashlib,json,math,re
import numpy as np
HERE=Path(__file__).resolve().parent
scope={'__file__':str(HERE/'audit_paddy_layout.py')}
exec((HERE/'audit_paddy_layout.py').read_text(encoding='utf-8').split('result=[]\nfor number')[0],scope)
nodes=scope['nodes'];banks=scope['banks'];terrain=scope['terrain'];GAME=scope['GAME'];sprite=scope['sprite']
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def inside_many(x,y,poly):
 yes=np.zeros(x.shape,dtype=bool)
 for i,a in enumerate(poly):
  b=poly[i-1]
  if b[1]==a[1]:continue
  yes^=((a[1]>y)!=(b[1]>y))&(x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])
 return yes
proposed={1:([6600,1380],.45),2:([6750,1820],.45),3:([6750,2220],.45),4:([6500,2820],.55)}
rows=[];new_shapes={}
for number,(foot,scale) in proposed.items():
 root=nodes[f'Town/Paddy{number}'];art=sprite(root['path']+'/Art',root['z']);ratio=scale/art['scale'][0]
 local=[art['position'][i]-root['position'][i] for i in [0,1]]
 offset=[local[0]*ratio,(local[1]+120)*ratio-120]
 alpha=np.asarray(art['_alpha']);sy,sx=np.nonzero(alpha>=8)
 x=foot[0]+offset[0]+(sx+.5)*scale;y=foot[1]+offset[1]+(sy+.5)*scale
 valid=inside_many(x,y+120,terrain['platforms'][0]['polygon'])&~inside_many(x,y+120,terrain['platforms'][1]['polygon'])
 outside=int((~valid).sum());overlaps=[]
 for bank in banks:
  u=(x-bank['origin'][0])/bank['scale'][0];v=(y-bank['origin'][1])/bank['scale'][1]
  ix=np.floor(u).astype(np.int32);iy=np.floor(v).astype(np.int32)
  ok=(ix>=0)&(iy>=0)&(ix+1<bank['size'][0])&(iy+1<bank['size'][1])
  if not ok.any():continue
  ba=np.asarray(bank['_alpha']);ii=ix[ok];jj=iy[ok]
  # Conservative four-neighbour source alpha support for linear sampling.
  hit=(np.maximum.reduce([ba[jj,ii],ba[jj+1,ii],ba[jj,ii+1],ba[jj+1,ii+1]])>=8)
  if hit.any():overlaps.append({'bank':bank['path'],'source_pixels':int(hit.sum()),'z':bank['z']})
 body=nodes[root['path']+'/Body/Outline'];m=re.search(r'polygon = PackedVector2Array\(([^)]+)\)',body['raw']);values=[float(n) for n in m[1].split(',')]
 poly=[[foot[0]+values[i]*ratio,foot[1]+values[i+1]*ratio] for i in range(0,len(values),2)]
 new_shapes[root['path']+'/Body']=poly
 rows.append({'name':root['name'],'old_foot':root['position'],'foot':foot,'old_scale':art['scale'][0],'scale':scale,'ratio':ratio,'new_art_local_position':offset,'new_body_world_polygon':poly,'visible_alpha8_source_pixels_checked':int(x.size),'alpha8_points_outside_projected_L1':outside,'native_bank_alpha8_overlaps':overlaps,'alpha8_projected_world_bbox':[float(x.min()),float(y.min()),float(x.max()),float(y.max())]})

# Exact polygon tests for only proposed new bodies and a single westward leg.
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def segment(a,b,c,d):return cross(a,b,c)*cross(a,b,d)<0 and cross(c,d,a)*cross(c,d,b)<0
def inside(p,poly):return bool(inside_many(np.asarray([p[0]]),np.asarray([p[1]]),poly)[0])
def collision(a,b):
 return any(inside(p,b) for p in a) or any(inside(p,a) for p in b) or any(segment(a[i-1],p,b[j-1],q) for i,p in enumerate(a) for j,q in enumerate(b))
solids=[]
for path,node in nodes.items():
 if 'type="CollisionPolygon2D"' not in node['head']:continue
 parent=nodes.get(node['parent'],{})
 if 'type="StaticBody2D"' not in parent.get('head',''):continue
 if 'build_mode = 1' in node['raw']:continue
 layer=int(scope['scalar'](parent['raw'],'collision_layer',1))
 if not layer&40:continue
 m=re.search(r'polygon = PackedVector2Array\(([^)]+)\)',node['raw'])
 if not m:continue
 a=[float(n) for n in m[1].split(',')]
 poly=new_shapes.get(node['parent'],[[a[i]+node['position'][0],a[i+1]+node['position'][1]] for i in range(0,len(a),2)])
 solids.append((node['parent'],poly))
for row in rows:
 own='Town/'+row['name']+'/Body'
 row['new_body_overlaps_other_static']=[name for name,p in solids if name!=own and collision(row['new_body_world_polygon'],p)]
path_rows=[]
for x in range(6890,6099,-5):
 y=2700;foot=[[x-17.5,y-12.5],[x+17.5,y-12.5],[x+17.5,y+12.5],[x-17.5,y+12.5]]
 hits=[name for name,p in solids if collision(foot,p)]
 if hits:path_rows.append({'foot':[x,y],'hits':hits})
result={'status':'LOCAL_STATIC_ONLY_NOT_ENGINE','rows':rows,'west_path':{'start':[6890,2700],'end':[6100,2700],'height':120,'mask':40,'foot':[35,25],'step':5,'samples':159,'failures':path_rows},'source_scene_sha256':scope['sha'](scope['SCENE']),'PNG_writes':0,'engine_runs':0,'save_access':False}
data=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'proposal_STATIC_01.json';assert not out.exists()
with out.open('xb') as f:f.write(data)
print(json.dumps({'sha256':sha(out),'rows':rows,'west_path_failures':path_rows},ensure_ascii=False))
