"""Finite source design aid for four new short routes, not independent QA.
Only fixed small Packed geometry Arrays and the retained old mask are read.
"""
from pathlib import Path
import hashlib,json,math,struct
from PIL import Image
N=Path(__file__).resolve().parent;G=N.parents[1]
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p):return json.loads(p.read_text(encoding='utf8'))
def path(p):return G/p[6:]
class SmallVariant:
 def __init__(self,b):self.b=b;self.p=0
 def take(self,fmt):
  size=struct.calcsize(fmt);r=struct.unpack_from(fmt,self.b,self.p);self.p+=size;return r
 def value(self):
  header=self.take('<I')[0];t=header&65535;wide=header&65536
  if t==0:return None
  if t==1:return bool(self.take('<I')[0])
  if t==2:return self.take('<q' if wide else '<i')[0]
  if t==3:return self.take('<d' if wide else '<f')[0]
  if t==4:
   size=self.take('<I')[0];r=self.b[self.p:self.p+size].rstrip(b'\0').decode();self.p+=(size+3)//4*4;return r
  if t==5:return list(self.take('<dd' if wide else '<ff'))
  if t==27:
   count=self.take('<I')[0]&0x7fffffff;out={}
   for _ in range(count):key=self.value();out[key]=self.value()
   return out
  if t==28:return [self.value() for _ in range(self.take('<I')[0]&0x7fffffff)]
  if t==35:return [list(self.take('<dd' if wide else '<ff')) for _ in range(self.take('<I')[0])]
  raise ValueError((t,self.p))
def source_geometry(pin):
 b=path(pin['path']).read_bytes();assert sha(b)==pin['sha256'];r=SmallVariant(b);a=r.value();assert r.p==len(b) and isinstance(a,list);return a
def rawpoint(q,foot,anchor,scale):return [f(f(foot[i])+f(f(f(q[i])-f(anchor[i]))*f(scale))) for i in range(2)]
def newpolys(scene):
 out=[]
 for p in scene['placements']:
  asset=library['assets'][p['asset_id']];polys=[]
  for r in asset.get('source_solid_rects_px',[]):
   raw=[[r[0],r[1]],[r[0]+r[2],r[1]],[r[0]+r[2],r[1]+r[3]],[r[0],r[1]+r[3]]]
   polys.append([rawpoint(q,p['foot_px'],asset['source_ground_anchor_px'],p['scale']) for q in raw])
  for raw in asset.get('source_solid_polygons_px',[]):polys.append([rawpoint(q,p['foot_px'],asset['source_ground_anchor_px'],p['scale']) for q in raw])
  for raw in asset.get('donor_ground_polygons_px',[]):polys.append([rawpoint(q,p['foot_px'],asset['donor_foot_px'],p['scale']/asset['donor_scale']) for q in raw])
  for i,poly in enumerate(polys):out.append({'id':p['id']+'_poly_'+str(i),'points_px':poly})
 return out
def contains(poly,p):
 hit=False
 for a,b in zip(poly,poly[1:]+poly[:1]):
  cross=(b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0])
  if cross==0 and min(a[0],b[0])<=p[0]<=max(a[0],b[0]) and min(a[1],b[1])<=p[1]<=max(a[1],b[1]):return True
  if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:hit=not hit
 return hit
cfg=load(G/'build/luoyang_city_finish_20261025i_system01/qa_role_new/adjacent_prior04_ROOT_READY/input_ROOT_READY.json')
author=load(N/'author_adjacent_four_fields05_routes_NOTREADY.json');library=load(N/'adjacent_adopted_asset_library03_SOURCE_ONLY.json')
if __name__=='__main__':
 for scene_id,foot in [('ch4_s3_luoyang_market',[700,840]),('luoyang_riverside_garden_20261022ap',[800,1310]),('ch4_s2_canal_docks',[1430,1463.58862304688]),('ch4_s2_canal_docks',[2216,1910])]:
  scene=next(s for s in author['scenes'] if s['scene_id']==scene_id);source=cfg['sources'][scene_id];rows=newpolys(scene)
  if 'geometry' in source:rows=source_geometry(source['geometry'])+rows
  elif 'geometry_source' in source:
   old=load(path(source['geometry_source']['path']))
   for r in old['new_non_water_rectangles']:
    lo=r['position'];hi=r['end'];rows.append({'id':r['id'],'points_px':[lo,[hi[0],lo[1]],hi,[lo[0],hi[1]]]})
  near=[]
  for row in rows:
   poly=row.get('points_px',row.get('polygon',[]))
   if not poly:continue
   low=[min(p[i] for p in poly) for i in range(2)];high=[max(p[i] for p in poly) for i in range(2)]
   if low[0]<=foot[0]+17 and high[0]>=foot[0]-17 and low[1]<=foot[1]+12 and high[1]>=foot[1]-12:near.append({'id':row.get('id'),'bbox':[low,high]})
  print(json.dumps({'scene':scene_id,'source_route_failure_foot':foot,'source_body_overlap_candidates':near}))
