from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as s:s.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def enc(a):return (json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
shader_old=(N/'city_purpose_surface03_vertex_world_NOTREADY.gdshader').read_bytes();assert sha(shader_old)=='3925abf7251b38c3dba5ec1b952ace678da150657cf34af33966b6a845fb6c66'
old='texture(source_material,world/repeat_period_px)';new='texture(source_material,fract(world/repeat_period_px))'
st=shader_old.decode();assert st.count(old)==1;st=st.replace(old,new);assert st.replace(new,old).encode()==shader_old
shader=emit('city_purpose_surface04_explicit_repeat_NOTREADY.gdshader',st.encode())
factory_old=(N/'city_purpose_surface03_vertex_world_NOTREADY.gd').read_bytes();assert sha(factory_old)=='68a70f09a3e802e2493d2dcf267ad2d5566d05dcd8bd9b1967a96220514ccbad'
ft=factory_old.decode();fh=[]
for oldpart,newpart in [('city_purpose_surface03_vertex_world_NOTREADY.gdshader','city_purpose_surface04_explicit_repeat_NOTREADY.gdshader'),('tile.material=material;tile.texture=textures[role]','tile.material=material;tile.texture=textures[role];tile.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED')]:
 assert ft.count(oldpart)==1;ft=ft.replace(oldpart,newpart);fh.append({'old':oldpart,'new':newpart})
back=ft
for h in reversed(fh):back=back.replace(h['new'],h['old'])
assert back.encode()==factory_old
factory=emit('city_purpose_surface04_explicit_repeat_NOTREADY.gd',ft.encode())
spec_old=(N/'eight_fields_purpose_surface03_vertex_world_NOTREADY.json').read_bytes();assert sha(spec_old)=='63fe3117d3aeffd9853ca08ff9a6e004e9b72aa68b05799efb7892748f2500c0'
spec=json.loads(spec_old);spec['factory']=factory;spec['shader']=shader
specpin=emit('eight_fields_purpose_surface04_explicit_repeat_NOTREADY.json',enc(spec))
input_old=(N/'material_sampling_native_probe02_ROOT_READY_input.json').read_bytes();assert sha(input_old)=='dc676ab26feb86ea3b940287ec477402e32c6e9d85cb35b6b0492e96359c3b0f'
a=json.loads(input_old)
for field,pin in [('factory',factory),('shader',shader)]:a['sources'].pop(a[field]);a[field]=pin['path'];a['sources'][pin['path']]=pin['sha256']
report=N/'material_sampling_native_probe02_ROOT_READY/output_ROOT_READY/53100/result.json';rb=report.read_bytes();r=json.loads(rb)
assert r['errors']==['road_ACTUAL_TEXTURE_RGB_VARIATION']
assert r['actual_GPU_samples']['floor']['unique_RGB']==20 and max(r['actual_GPU_samples']['floor']['channel_range'])>=0.30
floor_points=a['sample_points']['floor'];assert all(0<=p[0]<384 and 0<=p[1]<256 for p in floor_points)
rp=NS+'material_sampling_native_probe02_ROOT_READY/output_ROOT_READY/53100/result.json'
a['sources'][rp]=sha(rb)
a['inherited_floor_component']={'path':rp,'sha256':sha(rb),'actual_unique_RGB':20,'scope':'Only actual floor component inherited; original road wholeFAIL retained. For all20 source sample points0<=world/period<1, explicitfract leaves original source coordinate identical. No new floor draw or claimed new observed pixels.'}
a['rows']=[row for row in a['rows'] if row['id']=='road_actual_sampling'];assert len(a['rows'])==1
del a['sample_points']['floor'];a['output_absolute']=(N/'material_sampling_native_probe03_road_ROOT_READY/output_ROOT_READY').as_posix()
ipin=emit('material_sampling_native_probe03_road_ROOT_READY_input.json',enc(a))
key_old=(N/'material_sampling_native_probe02_ROOT_READY.gd').read_bytes();assert sha(key_old)=='4a522d4b80682d3f8e9f4545bd45877f15a1e1feb31844f3a84c0e86c0f97903'
text=key_old.decode();kh=[]
for o,n in [('const INPUT: String="'+NS+'material_sampling_native_probe02_ROOT_READY_input.json"\nconst INPUT_SHA: String="'+sha(input_old)+'"','const INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"'),('out+"floor_and_road_native_probe.png"','out+"road_only_native_probe.png"')]:
 assert text.count(o)==1;text=text.replace(o,n);kh.append({'old':o,'new':n})
back=text
for h in reversed(kh):back=back.replace(h['new'],h['old'])
assert back.encode()==key_old
key=emit('material_sampling_native_probe03_road_ROOT_READY.gd',text.encode())
proof=emit('material04_repeat_road_residual_whole_inverse_READY.json',enc({'status':'ROOT_APPROVED_EXPLICIT_REPEAT_ONLY_ROAD_RESIDUAL','factory':factory,'shader':shader,'spec':specpin,'probe':key,'input':ipin,'shader_single_hunk':{'old':old,'new':new},'factory_hunks':fh,'key_hunks':kh,'all_GD_shader_full_byte_inverse':True,'source_geometry_bounds_period_tint_probe_thresholds_unchanged':True,'inherited_floor':a['inherited_floor_component'],'old_full_eight_views_or_floor_not_replayed':True,'engine_calls':0,'canonical_writes':0}))
print(json.dumps({'factory':factory,'shader':shader,'spec':specpin,'probe':key,'input':ipin,'proof':proof}))
