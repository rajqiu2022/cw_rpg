"""Independent source-expression pixel model; no Godot/compiler/packet execution.

Uses explicit float32 vector operation order and integer closed raster domains.
The source-derived output is a proposal requiring Root/QA review, not native proof.
"""
from pathlib import Path
import hashlib,json,math
import numpy as np
from PIL import Image

P=Path(__file__).resolve().parent
G=P.parents[1]
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
ar=(P/'author_river_bridge03_NOTREADY.json').read_bytes()
assert sha(ar)=='06d873797e954a4f7b874a85b421a1b1dda87b2072170d7749eeaaf3ddc77cb6'
a=json.loads(ar);d=a['scenes'][0]
f=np.float32
def v(x):return np.array(x,dtype=np.float32)
def transform(row,asset,rect):
 scalar=f(row['uniform_scale'] if row['id']=='garden_stone_bridge_walkable_25h' else row['width']/asset['used_rect'][2])
 pos=v(v(row['foot'])+v(v(v(rect[:2])-v(asset['ground_anchor']))*scalar))
 size=v(v(rect[2:])*scalar)
 return pos,size,v(pos+size)

mask=np.zeros((2048,3072),dtype=np.bool_)
x,y,w,h=d['walk_rect'];mask[y:y+h,x:x+w]=True
water=v(d['water_polygons'][0])
lo=np.maximum(np.floor(water.min(axis=0)).astype(int),[0,0])
hi=np.minimum(np.ceil(water.max(axis=0)).astype(int),[3071,2047])
xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1,dtype=np.float64),np.arange(lo[1],hi[1]+1,dtype=np.float64))
inside=np.zeros(xx.shape,dtype=np.bool_);boundary=inside.copy()
for i in range(len(water)):
 x1,y1=map(float,water[i]);x2,y2=map(float,water[(i+1)%len(water)])
 cross=(xx-x1)*(y2-y1)-(yy-y1)*(x2-x1)
 boundary|=(cross==0)&(xx>=min(x1,x2))&(xx<=max(x1,x2))&(yy>=min(y1,y2))&(yy<=max(y1,y2))
 if y2!=y1:
  hit=((y1>yy)!=(y2>yy))&(xx<x1+(yy-y1)*(x2-x1)/(y2-y1))
  inside^=hit
water_pixels=inside|boundary
mask[lo[1]:hi[1]+1,lo[0]:hi[0]+1][water_pixels]=False

rectangles=[];deck=None
for row in d['placements']:
 asset=a['assets'][row['asset']]
 assert not asset.get('solid_polygons'),row['id']
 for i,source in enumerate(asset.get('solid_rects',[])):
  pos,size,end=transform(row,asset,source)
  rectangles.append({'id':row['id']+'_base_'+str(i),'position':[float(t) for t in pos],'size':[float(t) for t in size],'end':[float(t) for t in end]})
 for source in asset.get('support_rects',[]):
  assert deck is None
  pos,size,end=transform(row,asset,source);deck=(pos,size,end)
  x0,y0=np.ceil(pos).astype(int);x1,y1=np.floor(end).astype(int)
  mask[y0:y1+1,x0:x1+1]=True
assert deck is not None and float(deck[1][1])-24>=128
for rect in rectangles:
 x0,y0=np.ceil(rect['position']).astype(int);x1,y1=np.floor(rect['end']).astype(int)
 mask[y0:y1+1,x0:x1+1]=False

# Retain unaffected pixels from the current actual Garden; never fill expectations
# from a new publisher or runtime observation.
stp=G/'build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json'
stbytes=stp.read_bytes()
assert sha(stbytes)=='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396'
stage=json.loads(stbytes)
walk='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/luoyang_riverside_garden_20261022ap/walk.png'
wb=(G/walk[6:]).read_bytes()
assert sha(wb)==stage['source_first'][walk]
parent=np.asarray(Image.open(G/walk[6:]).convert('RGBA'))
assert parent.shape==(2048,3072,4)
rgba=np.empty((2048,3072,4),dtype=np.uint8)
rgba[:,:,:3]=np.where(mask[:,:,None],255,0);rgba[:,:,3]=255
# Derive all changed bounding domains from the actual source rectangles; do not
# clip the moved pavilion's highest ground post with a hand-rounded y670 box.
parent_author=json.loads((G/'build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/author_READY.json').read_bytes())
domains=[[899,0,1323,1482]]
for source_author,object_id in [(parent_author,'ap_river_pavilion'),(a,'ap_river_pavilion'),(a,'garden_riverside_tea_house_25h')]:
 row=next(x for x in source_author['scenes'][0]['placements'] if x['id']==object_id)
 asset=source_author['assets'][row['asset']]
 bounds=[transform(row,asset,r) for r in asset['solid_rects']]
 low=np.floor(np.min(np.array([r[0] for r in bounds]),axis=0)).astype(int)-1
 high=np.ceil(np.max(np.array([r[2] for r in bounds]),axis=0)).astype(int)+1
 domains.append([int(low[0]),int(low[1]),int(high[0]-low[0]+1),int(high[1]-low[1]+1)])
union=np.zeros(mask.shape,dtype=np.bool_)
for x,y,w,h in domains:union[y:y+h,x:x+w]=True
different=np.any(parent!=rgba,axis=2)
outside=int(np.count_nonzero(different&~union))
assert outside==0,('OUTSIDE_DECLARED_FINITE_DOMAINS',outside)

probes=[]
def body(foot):
 px,py=map(float,foot)
 for off_y in range(-12,13):
  for off_x in range(-17,18):
   ix=math.floor(px+off_x+.5);iy=math.floor(py+off_y+.5)
   if ix<0 or ix>=3072 or iy<0 or iy>=2048 or not mask[iy,ix]:return False
 for rect in rectangles:
  low=rect['position'];high=rect['end']
  if px+17>=low[0] and px-17<=high[0] and py+12>=low[1] and py-12<=high[1]:return False
 return True
for route in d['routes']:
 n=0
 for first,last in zip(route['points'],route['points'][1:]):
  steps=max(1,math.ceil(math.dist(first,last)/4))
  for i in range(steps+1):
   foot=v(v(first)+v(v(v(last)-v(first))*f(i/steps)))
   assert body(foot),('MODEL_ROUTE_BODY_FAILED',route['id'],[float(t) for t in foot])
   n+=1
 probes.append({'id':route['id'],'full_integer_body_875_mask_and_closed_rect_samples':n})
feet=[d['spawn']]+[r['foot'] for r in d['portals']]
for foot in feet:
 for dy in [0,10,24]:assert body([foot[0],foot[1]+dy]),('PORTAL',foot,dy)
people=json.loads((G/'build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json').read_bytes())
for row in people['people']:
 if row['scene_id']!=d['scene_id']:continue
 for dy in [-3,0,3]:assert body([row['foot_px'][0],row['foot_px'][1]+dy]),('NPC',row['npc_id'],dy)
 assert body(row['approach_px']),('NPC_APPROACH',row['npc_id'])

value={'status':'SOURCE_EXPRESSION_GARDEN_PIXEL_PRIOR_PROPOSAL_NOT_NATIVE_OR_ART_ADMISSION',
 'author':{'path':R+'author_river_bridge03_NOTREADY.json','sha256':sha(ar)},
 'parent_walk':{'path':walk,'sha256':sha(wb),'rgba_sha256':sha(parent.tobytes())},
 'expected_child_rgba_sha256':sha(rgba.tobytes()),
 'changed_pixels':int(np.count_nonzero(different)),
 'union_visited_pixels':int(np.count_nonzero(union)),
 'closed_rect_domains_xywh':domains,'outside_domains_changed_pixels':outside,
 'whole_inverse_parent_rgba_sha256':sha(np.where(different[:,:,None],parent,rgba).astype(np.uint8).tobytes()),
 'new_non_water_rectangles':rectangles,
 'deck_rect_f32':{'position':deck[0].tolist(),'size':deck[1].tolist(),'end':deck[2].tolist()},
 'raster_semantics':'Closed integer-center water polygon minus measured noninteger deck, then exact original-scalar/f32 native source rectangles; original walk rectangle is half-open. No Godot/compiler/packet execution.',
 'routes_source_model':probes,'root_native_Geometry2D_Physics_GPU_credit':False,
 'engine':0,'packet_decodes':0,'PNG_writes':0,'canonical_writes':0}
dest=P/'independent_source_pixel_model02_PRIOR_PROPOSAL.json';assert not dest.exists()
blob=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
with dest.open('xb')as out:out.write(blob)
print(json.dumps({'path':R+dest.name,'sha256':sha(blob),'expected_child_RGBA':value['expected_child_rgba_sha256'],'changed':value['changed_pixels'],'union':value['union_visited_pixels']}))
