extends RefCounted
## Read-only service semantics. Never infer services from a label or texture name.
const SELF := "res://build/city_navigation_minimap_20261101d_candidate01/service_semantics.gd"
const AUTHOR := "res://build/luoyang_pawnshop_repair_20261026a_system01/services_author02_CANDIDATE.json"
const AUTHOR_SHA := "44053da474186c16863df81e6c266d21e0815c1af2e6d8d4b1a78d0effe1db1e"
const SERVICE_RUNTIME := "res://build/luoyang_city_finish_20261025i_source01/pawnshop_only_repair01/unified22_READY01/services_runtime_READY.gd"
const SERVICE_RUNTIME_SHA := "4c8371436aac631ea36523626a2696e1871f0a29e9db5fb5e1a64116fcb706e8"
const ROLES := {"herbal":"medicine", "smith":"smith", "inn":"inn", "pawn":"pawn"}
const LABELS := {"medicine":"药", "smith":"匠", "inn":"栈", "pawn":"当"}

static func source_paths() -> Array[String]:
	return [SELF, AUTHOR, SERVICE_RUNTIME]

static func service_rooms() -> Dictionary:
	if FileAccess.get_sha256(AUTHOR) != AUTHOR_SHA or FileAccess.get_sha256(SERVICE_RUNTIME) != SERVICE_RUNTIME_SHA: return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or parsed.get("coordinates") != "SOURCE_FEET_1536_1024": return {}
	var result: Dictionary = {}
	for id: String in parsed.get("rooms", {}):
		var row: Dictionary = parsed.rooms[id]
		var role: String = String(ROLES.get(String(row.get("role", "")), ""))
		if role.is_empty() or String(row.get("npc_id", "")).is_empty(): return {}
		result[id] = {"service":role, "npc_id":String(row.npc_id), "shop_id":String(row.get("shop_id", "")), "evidence":AUTHOR, "evidence_sha256":AUTHOR_SHA}
	return result if result.size() == 4 else {}

static func active_actor_markers(field: Node, world: Node2D, rooms: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null or not rooms.has(String(scene.scene_id)): return result
	# Ask the existing owner for its read-only finalized receipt. Being named an
	# innkeeper or having an unused shop in storage is deliberately insufficient.
	var helper: GDScript = load(SERVICE_RUNTIME) as GDScript
	if helper == null: return result
	var receipt: Dictionary = helper.call("source_receipt", scene, field)
	if receipt.get("matched") != true or receipt.get("finalized") != true: return result
	var spec: Dictionary = rooms[String(scene.scene_id)]
	for value: Variant in field.get("_npc_nodes"):
		var npc := value as NPCNode
		if not is_instance_valid(npc) or not npc.is_inside_tree() or not npc.is_visible_in_tree(): continue
		if npc.npc_id != spec.npc_id or npc.interaction_action != "indoor_service25h": continue
		result.append({"id":"npc:" + npc.npc_id, "kind":"service_npc", "service":spec.service, "foot":world.to_local(npc.global_position), "npc":weakref(npc), "source_scene":String(scene.scene_id), "evidence":AUTHOR, "service_finalized":true})
	return result
