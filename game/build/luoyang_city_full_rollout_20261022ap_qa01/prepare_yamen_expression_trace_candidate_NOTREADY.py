"""Prepare QA-only exact-expression/clock-trace successor. NOT executable admission."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def key(p):return 'res://'+p.relative_to(ROOT).as_posix()
op=QA/'yamen_three_low_props_classification_fixture_READY.json'
os=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_CLASSIFIED_READY_20261023.gd'
assert sha(op)=='d56db8c66e2024a3ac991ca7a3a20fd0cbd85c4630164ea3a5c649832d142414'
assert sha(os)=='4cd7481e1a0fbb0a662547db06c2ee6bd41c8074527c6bf329f3e438613e98a7'
oracle=ROOT/'tests/helpers/yamen_low_props_source_expression_oracle_PREPARATION_ONLY_20261023.gd'
assert sha(oracle)=='36fd26d605b88a311e40ec187d0e0e5073dc8a98e4b8aab58e60d3fc52c4711a'
fp=QA/'yamen_expression_trace_fixture_CANDIDATE_NOTREADY.json'
sp=ROOT/'tests/test_luoyang_ap_yamen_EXPRESSION_TRACE_CANDIDATE_NOTREADY_20261023.gd'
hp=QA/'yamen_expression_trace_handoff_CANDIDATE_NOTREADY.json'
assert not any(p.exists() for p in [fp,sp,hp])
fixture=json.loads(op.read_bytes());fixture['ready']=False
for row in fixture['props']:
    del row['native_scale'];del row['sprite_origin_px']
fixture['source_sha256'][key(oracle)]=sha(oracle)
fixture['source_transform_author']={'path':'res://build/luoyang_city_full_rollout_20261022ap_qa01/wall_yamen_independent_recipe07_BOUND05_SOURCE_FROZEN_RETRY1_NOT_ACTUAL.json','sha256':'448c148ed5a15aaf4b1acbf6472afd6f94fe1ea2bdb654717dd59a5a56b4f947'}
fixture['source_transform_oracle']={'path':key(oracle),'sha256':sha(oracle)}
fixture['read_only_trace_scope']='Existing _observe cadence after super; only public preparation and Field loading stage changes; no extra yield, validator, worker, collector, resource or travel.'
fp.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
body=os.read_text(encoding='utf-8')
changes=[]
def replace(old,new):
    global body
    assert body.count(old)==1,(old[:120],body.count(old))
    body=body.replace(old,new);changes.append({'old':old,'new':new})
replace('const FINAL_OWNER_READY: bool = true','const FINAL_OWNER_READY: bool = false')
replace(key(op),key(fp));replace(sha(op),sha(fp))
replace('yamen_three_low_props_classified/%d_%d','yamen_three_low_props_expression_trace_candidate/%d_%d')
replace('const ENDPOINT_TOLERANCE:', 'const SOURCE_TRANSFORM := preload("'+key(oracle)+'")\nconst ENDPOINT_TOLERANCE:')
replace('var npc_initial: Dictionary = {}\n', '''var npc_initial: Dictionary = {}
var source_author_rows: Dictionary = {}
var trace_signature: String = ""
var stage_trace_events: int = 0

func _observe_readonly() -> void:
	super._observe_readonly()
	if requested_usec <= 0 or stage_trace_events >= 96: return
	var public_state: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
	if public_state.get("scene_id") != String(YAMEN): return
	var field_state: Dictionary = {}
	var field_instance: int = 0
	if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state"):
		field_state = current_scene.call("get_field_loading_state")
		field_instance = current_scene.get_instance_id()
	var signature: String = JSON.stringify([public_state.get("request_generation"),public_state.get("token"),public_state.get("phase"),field_instance,field_state.get("scene_id"),field_state.get("stage"),field_state.get("complete"),field_state.get("failed")])
	if signature == trace_signature: return
	trace_signature = signature; stage_trace_events += 1
	var clock: Dictionary = _clock_fact()
	clock["elapsed_usec"] = int(clock.usec) - requested_usec
	records.append({"kind":"READONLY_STAGE_CHANGE_CLOCK","clock":clock,"public":public_state.duplicate(true),"Field_instance":field_instance,"Field_loading_state":field_state.duplicate(true),"no_extra_yield_or_worker":true})
''')
replace('\tfor path: String in contract.source_sha256:\n', '''	var author: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(contract.source_transform_author.path))
	for authored: Dictionary in author.Yamen.independent_new_visuals:
		if not check(not source_author_rows.has(authored.id), "Unique independent author prop row"): return false
		source_author_rows[authored.id] = authored.duplicate(true)
	if not check(source_author_rows.size() == 3, "Only frozen three source-expression rows"): return false
	for path: String in contract.source_sha256:
''')
old='\t\tif not check(sprite.texture.resource_path == row.texture_path and sprite.texture.get_size() == Vector2(1536,1024) and sprite.scale == _point(row.native_scale) and sprite.position == _point(row.sprite_origin_px), "Full original canvas/uniform native transform " + row.id): return false\n'
new='''		var expected_transform: Dictionary = SOURCE_TRANSFORM.expected_sprite(source_author_rows[String(row.id)])
		var actual_transform: Dictionary = {"texture_path":sprite.texture.resource_path,"texture_size":sprite.texture.get_size(),"native_scale":sprite.scale,"field_position":sprite.position}
		records.append({"kind":"EXACT_NATIVE_TRANSFORM_ACTUAL_AND_INDEPENDENT_SOURCE_EXPRESSION","id":row.id,"actual":actual_transform,"expected":expected_transform.duplicate(true),"expected_not_from_actual":true})
		if not check(not expected_transform.is_empty(), "Exact frozen-author native expression exists " + row.id): return false
		if not check(sprite.texture.resource_path == expected_transform.texture_path and row.texture_path == expected_transform.texture_path, "Exact original texture path " + row.id, actual_transform): return false
		if not check(sprite.texture.get_size() == expected_transform.texture_size, "Exact full original canvas size " + row.id, actual_transform): return false
		if not check(sprite.scale == expected_transform.native_scale, "Exact source-expression native scale, no epsilon " + row.id, {"actual":actual_transform,"expected":expected_transform}): return false
		if not check(sprite.position == expected_transform.field_position, "Exact source-expression normalized Field position " + row.id, {"actual":actual_transform,"expected":expected_transform}): return false
'''
replace(old,new)
back=body
for row in reversed(changes):assert back.count(row['new'])==1;back=back.replace(row['new'],row['old'])
assert back.encode()==os.read_bytes()
sp.write_text(body,encoding='utf-8',newline='\n')
h={'status':'QA_SOURCE_EXPRESSION_AND_READONLY_CLOCK_CANDIDATE_NOTREADY','script':{'path':key(sp),'sha256':sha(sp),'lines':len(body.splitlines())},'fixture':{'path':key(fp),'sha256':sha(fp)},'oracle':{'path':key(oracle),'sha256':sha(oracle)},'whole_byte_inverse_to4CD':True,'exact_replacements':changes,'production_source_map_1211_full_equal':fixture['expected_city_source_sha256']==json.loads(op.read_bytes())['expected_city_source_sha256'],'geometry_polygons_NPC_routes_budgets_and_two_pictures_unchanged':True,'source_transform_expected_only_from_fixed448C_native_expression':True,'clock_trace_only_original_poll_cadence_no_new_yield_or_resource':True,'awaiting_Source_readonly_loading_review_and_Root_final_freeze':True,'old113324_whole_FAIL_and16_517877_loading_retained':True,'Root_actual_OS_exit_uncollected_not_inferred_from_result':True,'engine_runs':0,'parse_runs':0,'canonical_writes':0}
hp.write_text(json.dumps(h,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'script':h['script'],'fixture':h['fixture'],'handoff_sha256':sha(hp)}))
