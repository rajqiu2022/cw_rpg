from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as s:s.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def enc(a):return (json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
oldshader=(N/'city_purpose_surface02_soft_joint_NOTREADY.gdshader').read_bytes();assert sha(oldshader)=='e84bd7aa9cf36c8f739445196ce7dce33e2c64cbe754072971cc18f14e6ef230'
shadertext=oldshader.decode();shaderh=[]
def shaderchange(o,n):
 global shadertext
 assert shadertext.count(o)==1;shadertext=shadertext.replace(o,n);shaderh.append({'old':o,'new':n})
shaderchange('uniform float corner_radius_px=20.0;','uniform float corner_radius_px=20.0;\nvarying vec2 source_world_position;\nvoid vertex(){ source_world_position=VERTEX; }')
shaderchange('vec2 world=bounds_origin_px+UV*bounds_size_px;','vec2 world=source_world_position;')
shader=emit('city_purpose_surface03_vertex_world_NOTREADY.gdshader',shadertext.encode())
oldfactory=(N/'city_purpose_surface02_soft_joint_NOTREADY.gd').read_bytes();assert sha(oldfactory)=='7211d2cd1ab5534b72cbe5828d0cd504948d1e5c81d5d4a6e44c8365d8fc021a'
factorytext=oldfactory.decode();factoryh=[]
def factorychange(o,n):
 global factorytext
 assert factorytext.count(o)==1;factorytext=factorytext.replace(o,n);factoryh.append({'old':o,'new':n})
factorychange('city_purpose_surface02_soft_joint_NOTREADY.gdshader','city_purpose_surface03_vertex_world_NOTREADY.gdshader')
factorychange('var tile: Polygon2D=Polygon2D.new();tile.name=id;tile.material=material','var tile: Polygon2D=Polygon2D.new();tile.name=id;tile.material=material;tile.texture=textures[role]')
factory=emit('city_purpose_surface03_vertex_world_NOTREADY.gd',factorytext.encode())
oldspec=(N/'eight_fields_purpose_surface02_soft_joint_NOTREADY.json').read_bytes();assert sha(oldspec)=='58d67384a6bbc9eb62f80cecfd1022006b255239f4005c957ca08a64073d0c17'
spec=json.loads(oldspec);spec['factory']=factory;spec['shader']=shader
specpin=emit('eight_fields_purpose_surface03_vertex_world_NOTREADY.json',enc(spec))
baseline=json.loads((N/'overview_eight_fields11_ROOT_READY_input.json').read_text(encoding='utf8'))
floor=spec['textures']['court_stone'];road=spec['textures']['road_stone']
inputs={'ready':False,'whole_budget_ms':15000,'output_absolute':(N/'material_sampling_native_probe01_NOTREADY/output_NOTREADY').as_posix(),'sources':{factory['path']:factory['sha256'],shader['path']:shader['sha256'],floor['path']:floor['sha256'],road['path']:road['sha256']},'factory':factory['path'],'shader':shader['path'],'textures':{'court_stone':floor['path'],'road_stone':road['path']},'save_absolute_paths':baseline['save_absolute_paths'],'minimum_unique_RGB_samples':8,'minimum_RGB_channel_range':0.04,'rows':[{'id':'full_floor_actual_sampling','rect_xywh':[0,0,768,512],'texture_role':'court_stone','repeat_period_px':[384,256],'tint_rgba':[1,1,1,1],'contrast':1,'opacity':1,'full_base_coverage':True,'shoulder_px':1,'corner_radius_px':0},{'id':'road_actual_sampling','polyline_px':[[32,640],[736,640]],'width_px':144,'texture_role':'road_stone','repeat_period_px':[220,160],'tint_rgba':[1,1,1,1],'contrast':1,'opacity':1,'shoulder_px':24}],'sample_points':{'floor':[[x,y] for y in [31,79,143,207] for x in [23,71,151,239,319]],'road':[[x,y] for y in [608,640,672] for x in [96,160,224,288,352,416,480,544,608,672]]}}
ipin=emit('material_sampling_native_probe01_NOTREADY_input.json',enc(inputs))
keypath=N/'material_sampling_native_probe01_NOTREADY.gd';keyold=keypath.read_bytes();keytext=keyold.decode();assert keytext.count('PENDING_INPUT_PIN')==1
# Retain the authored template; the pinned successor is a separate file.
keytext=keytext.replace('PENDING_INPUT_PIN',ipin['sha256'])
key=emit('material_sampling_native_probe01_PINNED_NOTREADY.gd',keytext.encode())
for text,old,hunks in [(shadertext,oldshader,shaderh),(factorytext,oldfactory,factoryh)]:
 for h in reversed(hunks):assert text.count(h['new'])==1;text=text.replace(h['new'],h['old'])
 assert text.encode()==old
proof=emit('material_sampling03_vertex_world_full_inverse_BUILD.json',enc({'status':'ROOT_REQUESTED_NATIVE_GPU_PROBE_NOT_YET_EXECUTED','factory':factory,'shader':shader,'material_spec':specpin,'probe':key,'input':ipin,'factory_hunks':factoryh,'shader_hunks':shaderh,'full_byte_inverse_to02':True,'geometry_bounds_period_tint_opacity_rows_unchanged':True,'diagnosis':'Custom sampler does not bind Polygon2D.texture. Avoid Polygon UV normalization dependency: local VERTEX is already authored world pixel coordinates for these origin-zero polygons. Fragment uses interpolated varying world coordinates.','acceptance':'Actual GPU interior RGB diversity and channel range; not just uniform/property existence. Pixel rows and opaque interiors recorded.','engine_calls':0,'canonical_writes':0}))
print(json.dumps({'factory':factory,'shader':shader,'spec':specpin,'probe':key,'input':ipin,'proof':proof}))
