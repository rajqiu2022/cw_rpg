"""Read formal World15 bridges; write only new evidence. No engine/image edits."""
from pathlib import Path
from PIL import Image
import hashlib,json,math,re
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
SOURCE=GAME/'data/maps/world_map_v15_complete_v9c_source.json'
LAYOUT=GAME/'data/maps/world_map_jianghu_layout_v15.tres'
SIZE=(12288,8192)
def path(uri):
 assert uri.startswith('res://') and '..' not in uri
 return GAME/uri[6:]
def fact(p):return {'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mtime_ns':str(p.stat().st_mtime_ns)}
def out(name,value):
 data=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
 with (HERE/name).open('xb') as f:f.write(data)
 return hashlib.sha256(data).hexdigest()
def bounds(points):
 xs=[p[0] for p in points];ys=[p[1] for p in points]
 return [min(xs),min(ys),max(xs)-min(xs),max(ys)-min(ys)]
def union(rects):return bounds([(x,y) for x,y,w,h in rects]+[(x+w,y+h) for x,y,w,h in rects])
def mean(points):return [sum(p[i] for p in points)/len(points) for i in range(2)]
def hull(points):
 points=sorted(set(map(tuple,points)))
 if len(points)<3:return [list(p) for p in points]
 def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
 lower=[];upper=[]
 for p in points:
  while len(lower)>1 and cross(lower[-2],lower[-1],p)<=0:lower.pop()
  lower.append(p)
 for p in reversed(points):
  while len(upper)>1 and cross(upper[-2],upper[-1],p)<=0:upper.pop()
  upper.append(p)
 return [list(p) for p in lower[:-1]+upper[:-1]]
def ground_axis(poly):
 q=poly[:-1] if poly[0]==poly[-1] else poly
 assert len(q)==4
 i=max(range(4),key=lambda i:math.dist(q[i],q[(i+1)%4]))
 return [mean([q[i],q[(i-1)%4]]),mean([q[(i+1)%4],q[(i+2)%4]])]
def distance_segment(p,a,b):
 d=[b[i]-a[i] for i in range(2)];den=sum(v*v for v in d)
 t=max(0,min(1,sum((p[i]-a[i])*d[i] for i in range(2))/den))
 return math.dist(p,[a[i]+t*d[i] for i in range(2)])
source=json.loads(SOURCE.read_bytes())
assert source['world_size']==list(SIZE)
structures=[s for s in source['structures'] if s.get('kind')=='bridge']
rows=[r for r in source['objects'] if re.fullmatch(r'bridge_\d\d_(deck|bridge_(post|rail)\d+)',r.get('id',''))]
assert len(structures)==5 and len(rows)==93
layout_text=LAYOUT.read_text(encoding='utf-8')
layout_ids=re.findall(r'"id":\s*"(bridge_\d\d_(?:deck|bridge_(?:post|rail)\d+))"',layout_text)
assert len(layout_ids)==93 and set(layout_ids)=={r['id'] for r in rows}
file_facts={}
core=[
 'data/scenes/world_map_jianghu.tres','data/maps/world_map_jianghu_layout_v15.tres',
 'data/maps/world_map_v15_complete_v9c_source.json','data/background_sets/world_map_jianghu_v15_streamed.tres',
 'scripts/field/field_walkable_controller.gd','scripts/autoload/scene_router.gd',
 'scripts/world/world_map_v15_contract.gd','scripts/world/world_v15_visible_stream_20261018r.gd',
 'scripts/world/world_v15_stream_overlap_20261018r.gd','scripts/world/v15_modular_overlap.gd',
 'scripts/world/v14_modular_overlap.gd','scripts/world/world_farmland_visual_patch_resolver_20261015.gd',
 'scripts/adventure/adventure_runtime.gd',
 'data/maps/luoyang_full_city_20261022ap/execution_successor.json',
 'build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json']
for p in core:file_facts['res://'+p]=fact(GAME/p)
images={}
for row in rows:
 uri=row['texture'];p=path(uri);im=Image.open(p).convert('RGBA')
 assert list(im.size)==row['render_size_px'] and not row.get('rotation',0)
 w,h=im.size;cx,cy=row['pos'][0]*SIZE[0],row['pos'][1]*SIZE[1]
 origin=[cx-w/2,cy-h/2] if row.get('centered',True) else [cx,cy]
 alpha=im.getchannel('A');bbox0=alpha.getbbox();mask=alpha.point(lambda v:255 if v>=8 else 0)
 bbox=mask.getbbox();assert bbox is not None
 pixels=mask.load();points=[]
 for y in range(bbox[1],bbox[3]):
  xs=[x for x in range(bbox[0],bbox[2]) if pixels[x,y]]
  if xs:points.extend([(origin[0]+xs[0],origin[1]+y),(origin[0]+xs[-1]+1,origin[1]+y+1)])
 images[row['id']]={'render_rect_px':origin+[w,h],'alpha_gt0_rect_px':[origin[0]+bbox0[0],origin[1]+bbox0[1],bbox0[2]-bbox0[0],bbox0[3]-bbox0[1]],'visible_alpha_ge8_rect_px':[origin[0]+bbox[0],origin[1]+bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1]],'visible_alpha_ge8_convex_hull_world_px':hull(points)}
 for key in ['texture','metadata_path','actual_draw_geometry_path']:
  if row.get(key) and path(row[key]).exists():file_facts[row[key]]=fact(path(row[key]))
 import_path=Path(str(p)+'.import')
 if import_path.exists():
  file_facts[uri+'.import']=fact(import_path)
  match=re.search(r'^path="(res://\.godot/imported/[^\"]+\.ctex)"',import_path.read_text(),re.M)
  if match and path(match.group(1)).exists():file_facts[match.group(1)]=fact(path(match.group(1)))
inventory=[]
for structure in structures:
 id=structure['id'];group=[r for r in rows if r['id'].startswith(id+'_')]
 deck=next(r for r in group if r['role']=='bridge_deck')
 rails=[r for r in group if r['role']=='bridge_rail'];assert len(rails)==2
 # 'Near' is the source's larger mean projected foot Y, not a guessed screen axis.
 near=max(rails,key=lambda r:r['depth_sort_foot_y']);far=next(r for r in rails if r is not near)
 near_axis=ground_axis(near['solid_polygons_px'][0]);far_axis=ground_axis(far['solid_polygons_px'][0])
 near_posts=[]
 for r in group:
  if r['role']!='bridge_post':continue
  q=r['solid_polygons_px'][0];foot=mean(q[:-1] if q[0]==q[-1] else q)
  if distance_segment(foot,*near_axis)<=distance_segment(foot,*far_axis):near_posts.append(r)
 near_components=[near]+near_posts
 foreground_hull=hull([p for r in near_components for p in images[r['id']]['visible_alpha_ge8_convex_hull_world_px']])
 deck_quad=structure['projected_deck_polygon_px']
 deck_axis=[mean([deck_quad[0],deck_quad[3]]),mean([deck_quad[1],deck_quad[2]])]
 delta=[deck_axis[1][i]-deck_axis[0][i] for i in range(2)]
 angle=math.degrees(math.atan2(delta[1],delta[0]))
 route=next(r for r in source['routes'] if r['id']==structure['route_id'])
 route_points=route['points_px']
 joins=[]
 for end in structure['projected_passage_px']:
  closest=min(range(len(route_points)),key=lambda i:math.dist(route_points[i],end))
  joins.append({'passage_end_world_px':end,'nearest_original_route_index':closest,'nearest_original_route_point_world_px':route_points[closest],'nearest_route_distance_px':math.dist(route_points[closest],end),'source_route_neighbors_world_px':route_points[max(0,closest-1):min(len(route_points),closest+2)]})
 render_union=union([images[r['id']]['render_rect_px'] for r in group])
 alpha_union=union([images[r['id']]['alpha_gt0_rect_px'] for r in group])
 visible_union=union([images[r['id']]['visible_alpha_ge8_rect_px'] for r in group])
 inventory.append({'id':id,'river_id':structure['river_id'],'route_id':structure['route_id'],'original_route_width_px':route['width_px'],'visual_row_count':len(group),'visual_ids':[r['id'] for r in group],'roles':{role:sum(r['role']==role for r in group) for role in ['bridge_deck','bridge_post','bridge_rail']},'orientation_degrees_screen_clockwise':angle,'variant':'oblique_east_west' if abs(delta[0])>abs(delta[1]) else ('near_north_south' if abs(delta[0])<5 else 'oblique_north_south'),'union_canvas_rect_world_px':render_union,'union_alpha_gt0_rect_world_px':alpha_union,'union_alpha_ge8_rect_world_px':visible_union,'deck_object_id':deck['id'],'deck_native_texture_px':deck['render_size_px'],'deck_render_rect_world_px':images[deck['id']]['render_rect_px'],'deck_quad_world_px':deck_quad,'deck_surface_bank_centers_world_px':deck_axis,'deck_surface_span_px':math.dist(*deck_axis),'deck_surface_width_px':(math.dist(deck_quad[0],deck_quad[3])+math.dist(deck_quad[1],deck_quad[2]))/2,'outer_passage_endpoints_world_px':structure['projected_passage_px'],'outer_passage_span_px':math.dist(*structure['projected_passage_px']),'road_joins':joins,'nearrail_id':near['id'],'nearrail_ground_solid_polygons_world_px':near['solid_polygons_px'],'nearrail_visual_alpha_ge8_hull_world_px':images[near['id']]['visible_alpha_ge8_convex_hull_world_px'],'nearside_post_ids':[r['id'] for r in near_posts],'old_nearside_foreground_envelope_world_px':foreground_hull,'near_components_alpha_hulls_world_px':{r['id']:images[r['id']]['visible_alpha_ge8_convex_hull_world_px'] for r in near_components},'farrail_id':far['id'],'farrail_ground_solid_polygons_world_px':far['solid_polygons_px'],'original_solid_objects':[r['id'] for r in group if r.get('solid_polygons_px') or r.get('collision_size')],'native_art_prompt_canvas_min_px':[math.ceil(visible_union[2]+64),math.ceil(visible_union[3]+64)],'source_camera':'orthographic camera pitch45deg, screen X=world X; bridge slope follows frozen projected quad; no isometric45deg X-axis rotation','foreground_selector_note':'Old source reference only. Convex envelope contains deck gaps; never use the envelope as a final opaque cover. New asset needs its own reviewed precise rail/post source polygons, sampled from the same whole PNG without editing pixels.'})
result={'status':'READ_ONLY_CURRENT_WORLD_EVIDENCE_NOT_ENGINE_OR_ART_ACCEPTANCE','world_scene':'res://data/scenes/world_map_jianghu.tres','world_size_px':list(SIZE),'schema_version':15,'bridges_total':len(inventory),'bridge_visual_rows_total':len(rows),'bridge_physical_objects':sum(bool(r.get('solid_polygons_px') or r.get('collision_size')) for r in rows),'current_desktop_visual_consumer':'MainField._spawn_world_v15_stream → WorldV15VisibleStream → MainField._attach_world_v15_visual','current_web_fallback':'WorldV15VisibleStream.applies returns false on web; MainField._spawn_scene_objects handles original layout rows','bridges':inventory,'source_layout_bridge_ids_exact_match':True,'source_layout_sha256':file_facts['res://data/maps/world_map_jianghu_layout_v15.tres']['sha256'],'source_json_sha256':file_facts['res://data/maps/world_map_v15_complete_v9c_source.json']['sha256'],'PNG_writes':0,'engine_runs':0,'old_source_writes':0,'save_access':False}
hashes={}
hashes['bridge_inventory_READY.json']=out('bridge_inventory_READY.json',result)
hashes['bridge_source_rows_READY.json']=out('bridge_source_rows_READY.json',{'rows':rows,'derived_native_image_bounds':images,'complete_original_body_and_visual_rows_retained':True})
hashes['pipeline_sources_BEFORE.json']=out('pipeline_sources_BEFORE.json',{'status':'READ_ONLY_BASELINE_SOURCE_NOT_SAVE','files':file_facts,'save_access':False,'engine_runs':0})
print(json.dumps({'hashes':hashes,'bridges':[{'id':r['id'],'union':r['union_canvas_rect_world_px'],'alpha_union':r['union_alpha_ge8_rect_world_px'],'surface_span':r['deck_surface_span_px'],'surface_width':r['deck_surface_width_px'],'angle':r['orientation_degrees_screen_clockwise'],'rows':r['visual_row_count'],'nearrail':r['nearrail_id']} for r in inventory]},ensure_ascii=False))
