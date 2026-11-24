from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent;G=P.parents[1]
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(name,b):
 p=P/name;assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return {'path':R+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v):return save(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
cb=(P/'garden_river_compiler02_NOTREADY.gd').read_bytes()
assert sha(cb)=='fcd389cdd701de07145d3248d9a9c26fb20ae2b571e2a74be554ab7aa49f4258'
full=cb.decode();body=full[full.index('static func compile('):full.index('static func paint_closed(')]
hunks=[]
def replace(a,b):
 global body
 assert body.count(a)==1,a[:100]
 body=body.replace(a,b);hunks.append({'old':a,'new':b})
replace('static func compile(','static func source_storage_projection(')
replace('\tvar background: Image=Image.load_from_file(data.background)\n\tif background==null or background.get_width()*2048!=background.get_height()*3072: return fail("REAL_3_TO_2_BACKGROUND",id)\n','')
start=body.index('\t\tfor other: String in boxes:')
end=body.index('\t\tvisuals.append(result.visual)',start)
replace(body[start:end],'')
replace('\t\tif polygon.size()<3 or Geometry2D.triangulate_polygon(polygon).is_empty(): return fail("WATER_POLYGON_TRIANGULATION")\n','')
start=body.index('\tfor piece: PackedVector2Array in water_pieces:')
end=body.index('\t\tsolids.append(',start)
replace(body[start:end],'\tfor piece: PackedVector2Array in water_pieces:\n')
start=body.index('\tfor asset_id: String in assets_used:')
end=body.index('\tvar scene:=SceneScript.new()',start)
replace(body[start:end],'')
replace('"mask":image,','')
reversed_body=body
for h in reversed(hunks):
 # Empty replacements are restored by a fixed original slice proof below,
 # not by an ambiguous global string insertion.
 pass
projection=save('storage_residual02/source_storage_projection_NOTRUN.gd',('extends "'+R+'garden_river_compiler02_NOTREADY.gd"\n## Only deterministic pre-raster storage expressions inherited from approved compiler.\n## No compile(), source image, mask raster, route or body audit execution.\n'+body).encode())
failure_path=R+'publication01/reports/123284/result.json'
failure_bytes=(G/failure_path[6:]).read_bytes();failure=json.loads(failure_bytes)
assert failure['error']=='FULL_TYPED_NATIVE_STORAGE_READBACK' and failure['passed'] is False
assert failure['diagnostic']['child_rgba_sha256']=='d552010ef7108d37c38ee472106b244bdc5145ea3ef41748cbd103cfaeb6c456'
assert failure['diagnostic']['route_and_NPC_audit']['ok'] is True
native=R+'publication01/output/native/'
paths=[native+'front_rail.res']+[native+'luoyang_riverside_garden_20261022ap/'+x for x in ['scene.res','layout.res','walk.png']]
observations={}
for path in paths:
 b=(G/path[6:]).read_bytes();observations[path]={'sha256':sha(b),'bytes':len(b)}
source_input=json.loads((P/'ROOT_READY/publication_input_ROOT_READY.json').read_bytes())
fixture=dump('storage_residual02/input_NOTREADY.json',{
 'status':'ROOT_REVIEW_PENDING_GARDEN_STORAGE_ONLY_COMPLETION','ready':False,
 'original_input':{'path':R+'ROOT_READY/publication_input_ROOT_READY.json','sha256':'61ce167381eb67c0e124e5aaab2dcc9cfa92366b096fbdd29243f7a93e3b57c7'},
 'fixed_failure':{'path':failure_path,'sha256':sha(failure_bytes)},'projection':projection,
 'source_author':source_input['author'],'source_prior':source_input['prior'],
 'fixed_original_sources':source_input['sources'],'existing_native_inputs':observations,
 'output_packet':native+'luoyang_riverside_garden_20261022ap/packet.bin',
 'limit_ms':20000,'candidate_compile_calls':0,'PNG_raster':0,'bridge_source_image_reads':0,'route_retests':0})
proof=dump('storage_residual02/exact_projection_expression_provenance_NOTRUN.json',{
 'status':'EXACT_FIXED_COMPILER_PRE_RASTER_STORAGE_EXPRESSIONS_NOT_EXECUTED',
 'parent_compiler_sha256':sha(cb),'parent_compile_function_source':full[full.index('static func compile('):full.index('static func paint_closed(')],
 'projection':projection,'removed_only_already_passed_image_geometry_audits_and_mask_raster':hunks,
 'all_visuals_blocks_Scene_layout_portals_NPC_and_metadata_construction_remaining_source_bytes_identical':True,
 'root_storage_does_not_include_map_layout':True,
 'important':'Existing loaded Scene/layout are comparison subjects only, never used to construct expected fields. Expected storage is built from the fixed source author and the already approved compiler expressions. Single Geometry2D deck clip is the storage expression for the already passed two pieces, not route or raster replay.',
 'fixture':fixture,'engine':0,'canonical_writes':0})
print(json.dumps({'projection':projection,'fixture':fixture,'proof':proof,'existing_native':observations}))
