"""Full native PNGs with uniform transforms; all old physical node bytes retained."""
from pathlib import Path
from PIL import Image
import json,re,hashlib,math
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 p=HERE/name
 if p.exists():assert p.read_bytes()==b,p
 else:
  with p.open('xb') as f:f.write(b)
 return {'path':str(p.relative_to(GAME.parent)).replace('\\','/'),'sha256':sha(b),'bytes':len(b)}
def nodes(s):
 for m in re.finditer(r'^\[node name="([^"]+)"[^\n]*\]\n(.*?)(?=^\[node |\Z)',s,re.M|re.S):
  yield {'name':m[1],'head':m[0].split('\n',1)[0],'body':m[2],'block':m[0]}
def values(raw,key):
 m=re.search(key+r' = PackedVector2Array\(([^)]+)',raw);v=[float(n) for n in m[1].split(',')];return list(map(list,zip(v[::2],v[1::2])))
asset_root='res://art/modules/environment_repair_20261031c/'
names=['mountain_stair_12_v2','cliff_front_v1','cliff_left_v1','cliff_right_v1'];textures={};runtime=[]
for name in names:
 uri=asset_root+name+'.png';p=GAME/uri[6:];b=p.read_bytes();im=Image.open(p).convert('RGBA')
 expected={'mountain_stair_12_v2':'4d2ce841311a97888d203e2f1cc88daea9fac3f3e5962d96cd1dc005e873a54d','cliff_front_v1':'305046d3758fcc5a0a1e115781fedbda8ed855ba2d8b6ef59b3c23363edf934e','cliff_left_v1':'c4a5b19a1bb3ac2e2a44bd641b2fec11694e4d2212cc5bc70a7e96e6e4628e70','cliff_right_v1':'055fe5a881cb488866855c3f464a0d7edbd0212fb0a362cd1d9896e753cf7ca5'}[name];assert sha(b)==expected
 textures[uri]={'sha256':sha(b),'size':list(im.size),'alpha8_bbox':list(im.getchannel('A').point(lambda a:255 if a>=8 else 0).getbbox())}
 runtime.append({'path':uri,'sha256':sha(b),'bytes':len(b),'load':'strict Image.load + cached ImageTexture, no import required'})
# Registration uses the actual opaque central source column, not a stretched quad.
cliff_profiles={
 'front':{'texture':asset_root+'cliff_front_v1.png','top':[768,289],'foot':[768,902]},
 'left':{'texture':asset_root+'cliff_left_v1.png','top':[768,309],'foot':[768,858]},
 'right':{'texture':asset_root+'cliff_right_v1.png','top':[768,311],'foot':[768,836]}}
binding={'schema_version':1,'textures':textures,'slot_shader_sha256':sha((HERE/'cliff_stair_slots.gdshader').read_bytes()),'stair_rails':{'left':[[0,0],[450,0],[365,180],[330,300],[220,680],[180,800],[180,860],[60,970],[0,970]],'right':[[1085,0],[1536,0],[1536,970],[1475,970],[1360,860],[1360,800],[1320,680],[1220,300],[1165,180]]},'towns':{}}
proof=[];all_retired={}
for key,path in [('wudang','sect_maps_20261029k/wudang'),('huashan','huashan_map_20261029m/huashan')]:
 before=(HERE/(key+'.tscn.BEFORE')).read_bytes();business=(HERE/(key+'_BUSINESS_01.tscn')).read_bytes();newline='\r\n' if b'\r\n' in business else '\n'
 original=before.decode().replace('\r\n','\n');s=business.decode().replace('\r\n','\n');blocks=list(nodes(s));retired=[];groups=[]
 for node in blocks:
  if 'type="Polygon2D"' not in node['head'] or 'texture = ExtResource' not in node['body'] or 'parent="Terrain' not in node['head']:continue
  retired.append(node)
  if 'parent="Terrain"' not in node['head']:continue # Three old stair render layers per ramp.
  p=values(node['body'],'polygon');outer=node['name'].startswith('RidgeFace');a,b=(p[0],p[1]) if outer else (p[3],p[2]);height=240.0 if outer else p[3][1]-p[0][1]
  depth_offset=int(re.search(r'^z_index = (-?\d+)',node['body'],re.M)[1])-round((a[1]+b[1])/8)
  if groups and groups[-1]['outer']==outer and math.dist(groups[-1]['b'],a)<.03:
   previous=groups[-1];u=previous['a'];v=previous['b'];cross=(v[0]-u[0])*(b[1]-u[1])-(v[1]-u[1])*(b[0]-u[0])
   if abs(cross)<1.0:previous['b']=b;previous['retired'].append(node['name']);continue
  groups.append({'a':a,'b':b,'height':height,'outer':outer,'depth_offset':depth_offset,'retired':[node['name']]})
 expected=31 if key=='wudang' else 83;assert len(retired)==expected,(key,len(retired))
 for node in retired:assert s.count(node['block'])==1;s=s.replace(node['block'],'')
 current_nodes={n['head']:n['block'] for n in nodes(s)};physical=0
 for node in nodes(original):
  if any(t in node['head'] for t in ['type="StaticBody2D"','type="CollisionPolygon2D"','type="CollisionShape2D"']):
   assert current_nodes.get(node['head'])==node['block'],node['head'];physical+=1
 layout=json.loads((GAME/('art/modules/'+path+'.json')).read_text(encoding='utf-8-sig'))
 clips=[];stairs=[]
 for ramp in layout['terrain']['ramps']:
  high=layout['terrain']['heights'][ramp['high']];low=layout['terrain']['heights'][ramp['low']]
  top=[ramp['top'][0],ramp['top'][1]-high];bottom=[ramp['bottom'][0],ramp['bottom'][1]-low];span=bottom[1]-top[1];scale=span/700.0;half=layout['terrain']['portal_half_width']
  clips.append([top[0]-half,top[1]-24,top[0]+half,bottom[1]+32])
  stairs.append({'id':ramp['id'],'texture':asset_root+'mountain_stair_12_v2.png','projected_bottom':bottom,'projected_top':top,'source_foot':[768,920],'source_top':[768,220],'scale':scale,'source_registration_span':700,'world_registration_span':span,'rail_z':round((ramp['bottom'][1]+24)/4),'physical_half_width':half,'source_upper_landing_clear_x_REFERENCE_ONLY':[360,1165]})
 cliffs=[]
 for group in groups:
  a,b=group['a'],group['b'];dx=b[0]-a[0];dy=b[1]-a[1]
  slope=dy/dx if abs(dx)>.001 else (1e6 if dy>=0 else -1e6)
  variant='front' if abs(slope)<.12 else ('right' if slope>0 else 'left');profile=cliff_profiles[variant]
  scale=group['height']/(profile['foot'][1]-profile['top'][1]);meta=textures[profile['texture']];width=(meta['alpha8_bbox'][2]-meta['alpha8_bbox'][0])*scale
  count=max(1,math.ceil(math.dist(a,b)/(width*.62)))
  for i in range(count):
   t=(i+.5)/count;center=[a[j]+(b[j]-a[j])*t for j in [0,1]]
   if group['outer']:center[1]+=240 # One native240-high outer drop; never the rejected470.
   position=[center[j]-profile['foot'][j]*scale for j in [0,1]]
   cliffs.append({'id':'CliffNative'+str(len(cliffs)),'texture':profile['texture'],'position':position,'scale':scale,'z':-21 if group['outer'] else round(center[1]/4)+group['depth_offset'],'registration_foot':center,'source_foot':profile['foot'],'source_top':profile['top'],'registration_height':group['height'],'outer':group['outer'],'original_group':group['retired']})
 binding['towns'][key]={'cliffs':cliffs,'stairs':stairs,'slots':clips}
 final=s.replace('\n',newline).encode();fact=emit(key+'_READY.tscn',final)
 all_retired[key]=[n['head'] for n in retired]
 proof.append({'town':key,'candidate':fact,'original_physical_nodes_byte_exact':physical,'old_textured_polygons_retired':len(retired),'old_slope_count':len(stairs),'whole_native_stair_count':len(stairs),'whole_native_cliff_count':len(cliffs),'cliff_scale_max':max(r['scale'] for r in cliffs),'all_scales_uniform_and_le1':all(0<r['scale']<=1 for r in cliffs+stairs),'outer_drop_registration_height':240 if key=='huashan' else None,'PNG_writes':0})
profile_fact=emit('visual_profiles.json',(json.dumps(binding,ensure_ascii=False,indent=2)+'\n').encode())
result={'status':'VISUAL_STATIC_READY_NOT_ENGINE','towns':proof,'runtime_inputs':runtime,'profile':profile_fact,'source_anchor_disclaimer':'Cliff central-column alpha240 registration is exact image sampling, not a Physics body. Stair floor/rail source contours are manual reference approximately8px. Real body/side barriers remain original.','retired_render_nodes':all_retired,'fixed_stair_slots':'Cliff-only static slots reproduce original4/5 physical stair corridors; no hero/camera uniforms, RGB shear or architectural fade. GhostCPU respects exactly the same slots.','new_image_import_required':False,'PNG_writes':0,'engine_runs':0,'save_access':False}
print(json.dumps(emit('visual_READY.json',(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()),ensure_ascii=False));print(json.dumps(proof,ensure_ascii=False))
