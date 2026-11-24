extends RefCounted
## Exact native contracts, not a schema>=15 fallback. No Autoload dependency.
const V15=preload("res://scripts/world/world_map_v15_contract.gd")
const V16=preload("res://build/world_coast_20261031h_system02/world_v16_contract03.gd")
const CANDIDATE_ID=V16.CANDIDATE_ID
const CANDIDATE_PATH=V16.CANDIDATE_PATH
const WORLD_IDS=[&"world_map_jianghu",&"world_map_jianghu_v15",CANDIDATE_ID]

static func contract_for(scene: SceneScript) -> Variant:
	if V16.is_v16(scene):return V16
	if _modern_declaration_present(scene):return null
	if V15.is_v15(scene):return V15
	return null

static func is_native(scene: SceneScript) -> bool:return contract_for(scene)!=null

static func formal_version() -> int:
	var scene:=load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	if V16.declared_identity(scene):return 16
	# A broken/unknown modern declaration cannot inherit a12/14 fallback and
	# accidentally enter the generic Field route. Router rejects the sentinel.
	if scene==null or _modern_declaration_present(scene):return -1
	if scene.map_layout!=null and scene.map_layout.schema_version not in [12,13,14,15]:return -1
	return V15.formal_version()

static func _modern_declaration_present(scene: SceneScript) -> bool:
	if scene==null:return false
	if scene.scene_id==CANDIDATE_ID or scene.has_meta("coordinate_space_version"):return true
	if scene.map_layout!=null and (scene.map_layout.has_meta("coordinate_space_version") or scene.map_layout.resource_path==V16.LAYOUT_PATH):return true
	return scene.streamed_background!=null and scene.streamed_background.resource_path==V16.STREAM_PATH

static func scene_path(id: StringName) -> String:
	if id==CANDIDATE_ID:return CANDIDATE_PATH
	if id in [&"world_map_jianghu",&"world_map_jianghu_v15"]:return "res://data/scenes/"+String(id)+".tres"
	return ""

static func scene_for(id: StringName) -> SceneScript:
	var path:=scene_path(id)
	return load(path) as SceneScript if not path.is_empty() and ResourceLoader.exists(path) else null

