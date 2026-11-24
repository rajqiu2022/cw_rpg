from pathlib import Path
import json,copy,hashlib
P=Path(__file__).resolve().parent
G=P.parents[1]
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(name,b):
 p=P/name;assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return {'path':R+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v):return save(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
raw=(P/'publish_garden_river_NOTREADY.gd').read_bytes()
assert sha(raw)=='1ab668fa9c09f62f4302ad0dcfa6b7c9fd3dc02b2fd612e7fcf8e7d1fd213220'
old=b'BASE+"publication_input_NOTREADY.json"'
new=b'BASE+"ROOT_READY/publication_input_ROOT_READY.json"'
assert raw.count(old)==1
ready=raw.replace(old,new);assert ready.replace(new,old)==raw
publisher=save('ROOT_READY/publish_garden_river_ROOT_READY.gd',ready)
ib=(P/'publication_input_NOTREADY.json').read_bytes()
assert sha(ib)=='4d45fc4cce4684a1ca677ce09783ab5867db7f2586b8a7db44740078294bea68'
v=json.loads(ib);parent=copy.deepcopy(v)
old_publisher=copy.deepcopy(v['publisher'])
v['ready']=True;v['status']='ROOT_READY_GARDEN_NATIVE_PUBLICATION_ONLY'
v['publisher']=publisher
assert v['sources'].pop(old_publisher['path'])==old_publisher['sha256']
v['sources'][publisher['path']]=publisher['sha256']
inverse=copy.deepcopy(v)
inverse['ready']=False;inverse['status']=parent['status'];inverse['publisher']=old_publisher
inverse['sources'].pop(publisher['path']);inverse['sources'][old_publisher['path']]=old_publisher['sha256']
assert inverse==parent
input_doc=dump('ROOT_READY/publication_input_ROOT_READY.json',v)
rows=[v['compiler'],publisher]
for p in ['res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://scripts/domain/scene_script.gd','res://scripts/domain/walkable_map_layout.gd','res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.gd']:
 rows.append({'path':p,'sha256':v['sources'][p]})
fixture=dump('ROOT_READY/parse_input_ROOT_READY.json',{'status':'ROOT_READY_LOAD_ONLY_GARDEN_COMPILER_PUBLISHER_AND_DIRECT_SCRIPT_DEPENDENCIES','ready':True,'rows':rows,'publication_input':input_doc,'limit_ms':20000,'instantiate_objects':False,'execute_candidate_methods':False})
probe='''extends SceneTree
const FIXTURE="__FIXTURE__"
const FIXTURE_SHA="__SHA__"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	var first: Dictionary={};var final: Dictionary={};var rows: Array=[];var errors: Array=[]
	var began: int=Time.get_ticks_msec()
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if FileAccess.get_sha256(FIXTURE)!=FIXTURE_SHA or not value is Dictionary or value.get("ready")!=true or not value.get("rows") is Array:
		push_error("GARDEN_PARSE_FIXED_FIXTURE");quit(1);return
	for row: Dictionary in value.rows:
		var actual: String=FileAccess.get_sha256(row.path)
		first[row.path]=actual
		if actual!=row.sha256:
			errors.append({"path":row.path,"error":"SOURCE_SHA"});continue
		var script: Variant=load(row.path)
		var ok: bool=script is GDScript and script.can_instantiate()
		rows.append({"path":row.path,"sha256":actual,"loaded_script":script is GDScript,"can_instantiate":ok,"instantiated":false,"methods_called":0})
		if not ok: errors.append({"path":row.path,"error":"LOAD_OR_CAN_INSTANTIATE"})
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		if final[path]!=first[path]: errors.append({"path":path,"error":"SOURCE_FINAL"})
	if Time.get_ticks_msec()-began>20000: errors.append({"error":"FIXED_20S_LIMIT"})
	var passed: bool=errors.is_empty() and rows.size()==value.rows.size()
	var result: Dictionary={"status":"GARDEN_COMPILER_PUBLISHER_LOAD_ONLY_NOT_EXECUTED","passed":passed,"rows":rows,"errors":errors,"source_first":first,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":20000,"candidate_instances":0,"candidate_method_calls":0,"Field":0,"geometry":0,"PNG":0,"collector":0}
	var output: String="res://build/luoyang_garden_river_20261025h_source01/ROOT_READY/parse_output/"+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(output) or DirAccess.make_dir_recursive_absolute(output.get_base_dir())!=OK: quit(1);return
	var file: FileAccess=FileAccess.open(output,FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(result,"\\t",true,true));file.close()
	print(JSON.stringify({"path":output,"passed":passed,"rows":rows.size(),"errors":errors}));quit(0 if passed else 1)
'''.replace('__FIXTURE__',fixture['path']).replace('__SHA__',fixture['sha256'])
key=save('ROOT_READY/parse_garden_ROOT_READY.gd',probe.encode())
proof=dump('ROOT_READY/mechanical_readiness_and_publisher_default_inverse.json',{
 'status':'ROOT_APPROVED_MECHANICAL_READINESS_FREEZE_NO_CANDIDATE_EXECUTION',
 'publisher':publisher,'input':input_doc,'parse_key':key,'parse_fixture':fixture,
 'publisher_delta':{'old':old.decode(),'new':new.decode(),'whole_byte_inverse':True},
 'input_delta':{'only_readiness_fields':['ready','status'],'mechanical_publisher_path_SHA_bytes_and_self_source_pin':True,'whole_typed_inverse':True,'all_other_49_sources_and_output_root_unchanged':True},
 'native_output_root':v['output_root'],'engine':0,'Stage':0,'canonical_writes':0})
print(json.dumps({'publisher':publisher,'input':input_doc,'parse_key':key,'parse_fixture':fixture,'proof':proof}))
