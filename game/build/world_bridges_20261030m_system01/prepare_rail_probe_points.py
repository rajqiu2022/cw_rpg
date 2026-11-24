"""Read-only alpha/mask sample facts, not Physics/GPU execution evidence."""
from pathlib import Path
from PIL import Image
import argparse,hashlib,json,math
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def inside(p,poly):
 result=False
 for i,a in enumerate(poly):
  b=poly[i-1]
  if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:result=not result
 return result
def world(p,row):
 a=math.radians(row['rotation_degrees']);s=row['scale'];o=row['origin_world_px']
 return [o[0]+s*(p[0]*math.cos(a)-p[1]*math.sin(a)),o[1]+s*(p[0]*math.sin(a)+p[1]*math.cos(a))]
ap=argparse.ArgumentParser();ap.add_argument('--profiles',required=True);ap.add_argument('--out',required=True);args=ap.parse_args()
profiles=Path(args.profiles);data=json.loads(profiles.read_text(encoding='utf-8-sig'))
inv=json.loads((HERE/'bridge_inventory_READY.json').read_text(encoding='utf-8-sig'))
originals={r['id']:r for r in json.loads((HERE/'bridge_source_rows_READY.json').read_text(encoding='utf-8-sig'))['rows']}
rows=[]
for row in data['bridges']:
 old=next(r for r in inv['bridges'] if r['id']==row['id'])
 image=Image.open(GAME/row['resource']['path'][6:]).convert('RGBA');alpha=image.getchannel('A')
 parts=sorted(row['foreground_parts'],key=lambda p:originals[p['source_component_id']]['depth_sort_foot_y'])
 samples=[]
 for n,part in enumerate(parts):
  poly=part['source_polygons_px'][0]
  center=[sum(p[k] for p in poly)/len(poly) for k in [0,1]]
  candidates=[]
  for y in range(max(0,int(min(p[1] for p in poly))),min(image.height,int(max(p[1] for p in poly))+1),2):
   for x in range(max(0,int(min(p[0] for p in poly))),min(image.width,int(max(p[0] for p in poly))+1),2):
    if alpha.getpixel((x,y))<200 or not inside([x+.5,y+.5],poly):continue
    # Highest priority wins exactly as GPU/CPU helper, even along mask joins.
    winner=-1
    for i,p in enumerate(parts):
     if any(inside([x+.5,y+.5],q) for q in p['source_polygons_px']):winner=i
    if winner==n:candidates.append(((x-center[0])**2+(y-center[1])**2,x,y))
  assert candidates,'NO_VISIBLE_NEW_RAIL_PIXEL:'+part['source_component_id']
  _,x,y=min(candidates)
  pixel=[x+.5,y+.5]
  samples.append({'node_name':'SceneObject_'+part['source_component_id'],'source_component_id':part['source_component_id'],'part_index_after_depth_sort':n,'source_pixel_center_px':pixel,'source_alpha_u8':alpha.getpixel((x,y)),'world_pixel_center_px':world(pixel,row),'source_pixel_visible_expected_on_owner':True,'source_pixel_visible_expected_on_base':False,'original_depth_foot_world_y':originals[part['source_component_id']]['depth_sort_foot_y']*8192})
 rail=originals[old['nearrail_id']]
 poly=rail['solid_polygons_px'][0]
 if poly[0]==poly[-1]:poly=poly[:-1]
 contact=[sum(p[k] for p in poly)/len(poly) for k in [0,1]]
 rows.append({'id':row['id'],'base_node_name':'SceneObject_'+old['deck_object_id'],'texture':row['resource']['path'],'texture_sha256':sha(GAME/row['resource']['path'][6:]),'samples':samples,'original_physics_nearrail_id':old['nearrail_id'],'original_rail_solid_polygon_px':rail['solid_polygons_px'][0],'original_rail_contact_probe_world_px':contact,'physics_shape':'World Player CircleShape2D radius5; actual engine query still required','source_uncertainty':'Art hand-measured masks +/-20sourcepx; pixel alpha exact, not Physics proof'})
result={'status':'STATIC_ALPHA_MASK_FACTS_NOT_GPU_NOT_PHYSICS','profiles_sha256':sha(profiles),'bridges':rows,'source_or_game_png_writes':0,'engine_runs':0,'save_access':False}
out=(HERE/args.out).resolve();assert out.parent==HERE and not out.exists()
b=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(b)
print(json.dumps({'path':str(out),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'bridges':len(rows),'newrail_visible_pixel_samples':sum(len(r['samples']) for r in rows)}))
