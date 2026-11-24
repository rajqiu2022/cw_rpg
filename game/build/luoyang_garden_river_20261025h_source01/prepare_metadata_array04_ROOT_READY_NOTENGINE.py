from pathlib import Path
import json,copy,hashlib
P=Path(__file__).resolve().parent
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(name,b):
 p=P/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return {'path':R+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v):return save(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
old=b'\tif id==IDS[1]:\n\t\tscene.set_meta("ap_garden_river25h",{"polygon":waters[0].duplicate(),"physics_pieces":water_pieces.duplicate(true),'
new=b'\tif id==IDS[1]:\n\t\tvar water_metadata_pieces: Array=[]\n\t\tfor piece: PackedVector2Array in water_pieces: water_metadata_pieces.append(piece.duplicate())\n\t\tscene.set_meta("ap_garden_river25h",{"polygon":waters[0].duplicate(),"physics_pieces":water_metadata_pieces,'
cb=(P/'garden_river_compiler02_NOTREADY.gd').read_bytes()
assert sha(cb)=='fcd389cdd701de07145d3248d9a9c26fb20ae2b571e2a74be554ab7aa49f4258' and cb.count(old)==1
nc=cb.replace(old,new);assert nc.replace(new,old)==cb
compiler=save('metadata_array04/garden_river_compiler03_NOTREADY.gd',nc)
pb=(P/'storage_residual03/source_storage_projection_NOTRUN.gd').read_bytes()
assert sha(pb)=='a0da018851c8057dcc7be1211949fdb1889fcf11ea345ef5c9fb9c98423ac2a9' and pb.count(old)==1
project=pb.replace(old,new).replace(b'extends "'+(R+'garden_river_compiler02_NOTREADY.gd').encode()+b'"',b'extends "'+compiler['path'].encode()+b'"')
assert project.replace(new,old).replace(compiler['path'].encode(),(R+'garden_river_compiler02_NOTREADY.gd').encode())==pb
projection=save('metadata_array04/source_storage_projection_NOTRUN.gd',project)
key_old=(P/'storage_residual03/ROOT_READY/complete_storage_READY.gd').read_bytes()
assert sha(key_old)=='230234e1a83cb08cfc868e7d88689b7801447e01d3243ee60470397ffab829f3'
hunks=[
 (b'storage_residual03/ROOT_READY/input_READY.json',b'metadata_array04/ROOT_READY/input_READY.json'),
 (b'storage_residual03/ROOT_READY/reports/',b'metadata_array04/ROOT_READY/reports/'),
 (b'errors.append({"error":label,"detail":detail})',b'errors.append({"error":label,"detail":detail.duplicate(true) if detail is Dictionary or detail is Array else detail})'),
 (b'\tfor path: String in input.fixed_original_sources:',b'\tif not fixed(input.representation_compiler.path,input.representation_compiler.sha256): return {}\n\tfor path: String in input.fixed_original_sources:')]
key_new=key_old
for a,b in hunks:assert key_new.count(a)==1;key_new=key_new.replace(a,b)
back=key_new
for a,b in reversed(hunks):assert back.count(b)==1;back=back.replace(b,a)
assert back==key_old
key=save('metadata_array04/ROOT_READY/complete_storage_READY.gd',key_new)
ib=(P/'storage_residual03/ROOT_READY/input_READY.json').read_bytes()
assert sha(ib)=='642e2048506a3948531308e053a412a252fe91ef2e3f573f16d96d79d89c243d'
v=json.loads(ib);before=copy.deepcopy(v)
v['projection']=projection;v['completion_script']=key;v['representation_compiler']=compiler
v['metadata_representation_contract']='Only metadata.physics_pieces Array element container is explicitly untyped to preserve binary ResourceSaver serialization. Exactly two per-item duplicated PackedVector2Array values/order remain; actual solids and geometry use the unchanged original typed water_pieces. No old native resource file is modified.'
rev=copy.deepcopy(v);rev['projection']=before['projection'];rev['completion_script']=before['completion_script'];rev.pop('representation_compiler');rev.pop('metadata_representation_contract');assert rev==before
inp=dump('metadata_array04/ROOT_READY/input_READY.json',v)
proof=dump('metadata_array04/exact_metadata_representation_and_diagnostic_inverse_ROOT_READY.json',{
 'status':'ROOT_APPROVED_EXACT_UNTYPED_METADATA_CONTAINER_ONLY_NO_GEOMETRY_REPLAY',
 'compiler':compiler,'projection':projection,'key':key,'input':inp,
 'same_one_semantic_hunk_in_compiler_and_projection':{'old':old.decode(),'new':new.decode()},
 'compiler_whole_byte_inverse':True,'projection_whole_byte_inverse_plus_base_path_only':True,
 'completion_diagnostic_and_path_hunks':[{'old':a.decode(),'new':b.decode()}for a,b in hunks],
 'completion_whole_byte_inverse':True,'input_whole_typed_inverse':True,
 'two_PackedVector2Array_elements_and_values_and_order_unchanged':True,
 'native_layout_all_typed_already_passed_Root121476':True,'old_native4_untouched':True,
 'C_compile':0,'bridge_pixel_retest':0,'routes_rerun':0,'mask_raster':0,'engine':0,'canonical_writes':0})
print(json.dumps({'compiler':compiler,'projection':projection,'key':key,'input':inp,'proof':proof}))
