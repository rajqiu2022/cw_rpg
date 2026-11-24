extends SceneTree
## Root-only residual: four moved Xiangzhou NPC feet. Original 1200 successes inherited.
const ORIGINAL := "res://build/three_settlements_20261030e_qa01/geometry_ROOT_ACTUAL.json"
const OUT := "res://build/three_settlements_20261030e_qa01/geometry02_ROOT_ACTUAL.json"
const AUTHOR := "res://build/three_settlements_20261030e_system01/xiangzhou_author.gd"
const OLD_SHA := "f957d627f1a0ed14ef25d1d391636d892ba1587de7caf2248b41b2b3e08ec130"
const NEW_SHA := "212ba133fa4eceb3fb493a15adef4c8d1983a0c634d953052748b95982c6278c"
const MOVES: Array[Dictionary]=[
	{"id":"xiangzhou_life_01","before":"[\"南门值卒\",Vector2(2630,3840)","after":"[\"南门值卒\",Vector2(2630,3740)","foot":Vector2(2630,3740)},
	{"id":"xiangzhou_life_02","before":"[\"南门老卒\",Vector2(3010,3840)","after":"[\"南门老卒\",Vector2(3010,3740)","foot":Vector2(3010,3740)},
	{"id":"xiangzhou_life_09","before":"[\"修械匠\",Vector2(650,2380)","after":"[\"修械匠\",Vector2(650,2470)","foot":Vector2(650,2470)},
	{"id":"xiangzhou_life_14","before":"[\"赶集买客\",Vector2(5040,2380)","after":"[\"赶集买客\",Vector2(5040,2480)","foot":Vector2(5040,2480)}]
var checks: int=0
var errors: Array[String]=[]
var records: Array=[]
func _initialize() -> void:_run.call_deferred()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("30E_FOUR_FEET_FAIL ",label)
	return ok
func _run() -> void:
	if FileAccess.file_exists(OUT):push_error("IMMUTABLE_RESIDUAL_EXISTS");quit(2);return
	var original: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORIGINAL))
	var expected: Array=[]
	for move: Dictionary in MOVES:expected.append("NPC_COMPLETE_BODY_CLEAR:openworld_xiangzhou_city:"+String(move.id))
	if not need(original is Dictionary and original.get("passed")==false and original.get("checks")==1204 and original.get("errors")==expected,"ORIGINAL1204_FOURFAIL_EXACT_NOT_REWRITTEN"):finish();return
	if not need(FileAccess.get_sha256(AUTHOR)==NEW_SHA,"EXACT_FOUR_FEET_AUTHOR_SUCCESSOR"):finish();return
	var reversed: String=FileAccess.get_file_as_string(AUTHOR)
	for move: Dictionary in MOVES:
		if not need(reversed.count(String(move.after))==1,"ONE_EXACT_POSITION_ONLY:"+String(move.id)):finish();return
		reversed=reversed.replace(String(move.after),String(move.before))
	if not need(reversed.sha256_text()==OLD_SHA,"WHOLE_AUTHOR_REVERSE_FOUR_POSITIONS_EQUALS_ORIGINAL_SHA"):finish();return
	for row: Dictionary in original.records:
		if String(row.id)=="openworld_xiangzhou_city":continue
		var path: String="res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd" if String(row.id)=="openworld_qinghe_town" else "res://build/three_settlements_20261030e_yanmen01/yanmen_author.gd"
		if not need(FileAccess.get_sha256(path)==String(row.author_sha256),"OTHER_AUTHOR_UNCHANGED_SUCCESS_INHERITED:"+String(row.id)):finish();return
	var author: Variant=load(AUTHOR)
	var rows: Array=author.npc_rows()
	for move: Dictionary in MOVES:
		var matches: Array=[]
		for npc: Dictionary in rows:
			if String(npc.npc_id)==String(move.id):matches.append(npc)
		var okay: bool=matches.size()==1
		if okay:okay=(matches[0].pos*author.SIZE).distance_to(move.foot)<.001 and author.safe_foot(matches[0].pos,false)
		need(okay,"ONLY_MOVED_NPC_COMPLETE_BODY_CLEAR:"+String(move.id))
		records.append({"id":move.id,"new_foot":move.foot,"safe_full34x24_body":okay})
	finish()
func finish() -> void:
	var file:=FileAccess.open(OUT,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"original_report":ORIGINAL,"original_report_sha256":FileAccess.get_sha256(ORIGINAL),"original_whole_run_status":"FAIL_RETAINED","original_checks":1204,"inherited_successes":1200,"new_body_tests":4,"author_path":AUTHOR,"old_author_sha256":OLD_SHA,"new_author_sha256":NEW_SHA,"proof":"Whole-file inverse of exactly four NPC positions equals original geometry Author SHA; other two Authors unchanged","old_bridge_water_business_matrix_replayed":false,"field_instances":0,"gpu_claim":false,"save_writes":0,"production_writes":0},"\t"));file.close()
	print("30E_FOUR_FEET_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
