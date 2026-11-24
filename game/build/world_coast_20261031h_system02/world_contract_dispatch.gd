extends RefCounted
## Exact native contracts, not a schema>=15 fallback. No Autoload dependency.
const V15=preload("res://scripts/world/world_map_v15_contract.gd")
const V16=preload("res://build/world_coast_20261031h_system02/world_v16_contract.gd")
const CANDIDATE_ID=V16.CANDIDATE_ID
const CANDIDATE_PATH=V16.CANDIDATE_PATH
const WORLD_IDS=[&"world_map_jianghu",&"world_map_jianghu_v15",CANDIDATE_ID]

static func contract_for(scene: SceneScript) -> Variant:
	if V16.is_v16(scene):return V16
	if V15.is_v15(scene):return V15
	return null

static func is_native(scene: SceneScript) -> bool:return contract_for(scene)!=null

static func formal_version() -> int:
	var scene:=load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	return 16 if V16.is_v16(scene) else V15.formal_version()

static func scene_path(id: StringName) -> String:
	if id==CANDIDATE_ID:return CANDIDATE_PATH
	if id in [&"world_map_jianghu",&"world_map_jianghu_v15"]:return "res://data/scenes/"+String(id)+".tres"
	return ""

static func scene_for(id: StringName) -> SceneScript:
	var path:=scene_path(id)
	return load(path) as SceneScript if not path.is_empty() and ResourceLoader.exists(path) else null
