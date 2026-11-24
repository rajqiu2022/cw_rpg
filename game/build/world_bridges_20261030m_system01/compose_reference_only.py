"""Root-requested existing RGBA composition, not new bridge art or GPU capture.
Read original93 textures only; retain floating source placement, LINEAR sampling,
native size1, source scene layer/depth order. Never edit any source image.
"""
from pathlib import Path
from PIL import Image
import hashlib,json,math
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
OUT=HERE/'reference_only'
inventory=json.loads((HERE/'bridge_inventory_READY.json').read_bytes())
data=json.loads((HERE/'bridge_source_rows_READY.json').read_bytes())
rows=data['rows'];bounds=data['derived_native_image_bounds']
def sha(b):return hashlib.sha256(b).hexdigest()
def put(p,b):
 p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb') as f:f.write(b)
records=[]
for bridge in inventory['bridges']:
 x,y,w,h=bridge['union_canvas_rect_world_px']
 origin=[math.floor(x)-20,math.floor(y)-20]
 size=[math.ceil(x+w)-origin[0]+20,math.ceil(y+h)-origin[1]+20]
 selected=[(i,r) for i,r in enumerate(rows) if r['id'] in bridge['visual_ids']]
 def order(pair):
  i,r=pair
  if r.get('sort_by_feet',False):
   foot=float(r['depth_sort_foot_y'])*8192
   return (20+max(0,min(1024,math.floor(foot/8))),foot,i)
  return (400+int(r.get('z_index',0)) if r.get('render_layer')=='foreground' else int(r.get('z_index',0)),0,i)
 selected.sort(key=order)
 canvas=Image.new('RGBA',tuple(size),(0,0,0,0))
 placements=[]
 for ordinal,row in selected:
  source=GAME/row['texture'][6:]
  im=Image.open(source).convert('RGBA')
  assert list(im.size)==row['render_size_px'] and not row.get('rotation',0)
  bx,by,bw,bh=bounds[row['id']]['render_rect_px']
  offset=[bx-origin[0],by-origin[1]]
  # Premultiplied-alpha bilinear fractional placement approximates the existing
  # 2D renderer, without scaling/repainting any input or filling alpha holes.
  shifted=im.convert('RGBa').transform(tuple(size),Image.Transform.AFFINE,(1,0,-offset[0],0,1,-offset[1]),resample=Image.Resampling.BILINEAR).convert('RGBA')
  canvas=Image.alpha_composite(canvas,shifted)
  placements.append({'id':row['id'],'path':row['texture'],'source_sha256':sha(source.read_bytes()),'world_render_rect_px':[bx,by,bw,bh],'reference_offset_px':offset,'draw_order':list(order((ordinal,row))),'source_size_unchanged':True})
 target=OUT/(bridge['id']+'_original_composite_REFERENCE_ONLY.png')
 target.parent.mkdir(parents=True,exist_ok=True)
 with target.open('xb') as f:canvas.save(f,format='PNG')
 records.append({'id':bridge['id'],'reference_only':True,'not_new_art':True,'not_GPU_capture':True,'path':target.relative_to(GAME.parent).as_posix(),'sha256':sha(target.read_bytes()),'size_px':size,'world_origin_px':origin,'world_to_reference_scale':1.0,'padding_px':20,'deck_quad_reference_px':[[p[0]-origin[0],p[1]-origin[1]] for p in bridge['deck_quad_world_px']],'deck_bank_centers_reference_px':[[p[0]-origin[0],p[1]-origin[1]] for p in bridge['deck_surface_bank_centers_world_px']],'near_foreground_envelope_reference_px':[[p[0]-origin[0],p[1]-origin[1]] for p in bridge['old_nearside_foreground_envelope_world_px']],'source_placements':placements})
result={'status':'REFERENCE_ONLY_EXISTING_RGBA_COMPOSITION_NO_ART_ACCEPTANCE','renderer':'PIL premultiplied RGBA bilinear fractional translation + alpha over; no rotation present in93 source rows; native size1; existing layer/depth ordering','records':records,'formal_PNG_writes':0,'engine_runs':0,'save_access':False}
encoded=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()
put(OUT/'reference_manifest.json',encoded)
print(json.dumps({'manifest_sha256':sha(encoded),'records':[{'id':r['id'],'size_px':r['size_px'],'path':r['path'],'sha256':r['sha256']} for r in records]}))
