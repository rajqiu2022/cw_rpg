extends RefCounted
## 25i: exact sixteen formerly silent outdoor identities, no quest/service effects.
## BUILD only. Root must freeze READY and ordinary source closure before runtime use.
const FORMAL_READY := false
const SELF := "res://build/luoyang_city_finish_20261025i_system01/ambient18_runtime04_NOTREADY.gd"
const VISUAL := "res://build/luoyang_city_finish_20261025i_system01/ambient18_visual_contract02_NOTREADY.json"
const VISUAL_SHA := "0a65ecd3a2a6150c1080eb86cdb31a5657331d948e9d2776bc74db3e4336da25"
const ESTATE := &"luoyang_estate_riverside_20261021ai"
static var _texture_holds: Dictionary = {}
const AUTHOR := "res://build/luoyang_city_finish_20261025i_system01/ambient16_lore_text_author01_NOTREADY.json"
const AUTHOR_SHA := "bd9d81217a126714c5f4681a84fe6a1b0475eb3027c53f37cbe6fb7c6efc2d1f"
const CONTRACT := "res://build/luoyang_city_finish_20261025i_system01/ambient16_actor_contract01_NOTREADY.json"
const CONTRACT_SHA := "6d12e85c431fb29de9355083ce714026a09d7f4c5a9cc22deb0d16353884211b"
const FIELD_PATH := "res://scripts/field/field_walkable_controller.gd"
const CITY := preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const ACTION := "ambient25i_daily"
const IDS := ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]

var _field_ref: WeakRef
var _self_sha: String = ""
var _rows: Dictionary = {}
var _session: Dictionary = {}
var _serial: int = 0
var _last: Dictionary = {}
var _estate_owner: Dictionary = {}

static func requested(scene_id: StringName) -> bool:
	return String(scene_id) in IDS or scene_id == ESTATE

static func source_paths() -> Dictionary:
	if FileAccess.get_sha256(AUTHOR) != AUTHOR_SHA or FileAccess.get_sha256(CONTRACT) != CONTRACT_SHA: return {}
	var sha: String = FileAccess.get_sha256(SELF)
	if sha.length() != 64 or FileAccess.get_sha256(VISUAL) != VISUAL_SHA: return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(VISUAL))
	if not data is Dictionary or not data.get("required_source_sha256") is Dictionary: return {}
	var paths: Dictionary = {SELF:sha,AUTHOR:AUTHOR_SHA,CONTRACT:CONTRACT_SHA,VISUAL:VISUAL_SHA}
	paths.merge(data.required_source_sha256,false)
	return paths

static func source_paths_for(scene_id: StringName) -> Dictionary:
	return source_paths() if requested(scene_id) else {}

static func _read_data() -> Dictionary:
	if source_paths().is_empty(): return {}
	var author: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	var contract: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	if not author is Dictionary or not contract is Dictionary: return {}
	if not author.get("rows") is Array or not contract.get("rows") is Array: return {}
	if author.rows.size() != 16 or contract.rows.size() != 16: return {}
	if contract.get("new_military_families",{}).get("enabled") != false: return {}
	var rows: Dictionary = {}
	for raw: Variant in author.rows:
		if not raw is Dictionary: return {}
		var text: Dictionary = raw
		var id: String = String(text.get("npc_id",""))
		if id.is_empty() or rows.has(id) or not text.get("lines") is Array or text.lines.size() != 2 or text.get("new_voice_available") != false: return {}
		if not text.get("effects") is Dictionary: return {}
		for value: Variant in text.effects.values():
			if value is Array:
				if not value.is_empty(): return {}
			elif value is String:
				if not value.is_empty(): return {}
			elif typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return {}
			elif value != 0: return {}
		var count: int = 0
		var visual: Dictionary = {}
		for entry: Variant in contract.rows:
			if not entry is Dictionary: return {}
			if entry.get("npc_id") == id:
				count += 1
				visual = entry
		if count != 1 or visual.get("scene_id") != text.get("scene_id") or visual.get("npc_name") != text.get("npc_name"): return {}
		if not String(text.get("scene_id","")) in IDS: return {}
		for line: Variant in text.lines:
			if not line is String or line.is_empty(): return {}
		rows[id] = {"text":text.duplicate(true),"visual":visual.duplicate(true)}
	var visual_data: Dictionary = _visual_data()
	if visual_data.is_empty(): return {}
	for change: Dictionary in visual_data.actor_overrides:
		var id: String = String(change.npc_id)
		if not rows.has(id) or rows[id].visual != change.before: return {}
		rows[id].visual = change.after.duplicate(true)
	for extra: Dictionary in visual_data.estate_rows:
		var id: String = String(extra.npc_id)
		if rows.has(id) or String(extra.scene_id) != String(ESTATE) or extra.lines.size() != 2: return {}
		rows[id] = {"text":extra.duplicate(true),"visual":extra.duplicate(true)}
	return rows

static func _visual_data() -> Dictionary:
	if FileAccess.get_sha256(VISUAL) != VISUAL_SHA: return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(VISUAL))
	if not data is Dictionary or not data.get("textures") is Array or data.textures.size() != 4 or not data.get("actor_overrides") is Array or data.actor_overrides.size() != 7 or not data.get("estate_rows") is Array or data.estate_rows.size() != 2: return {}
	return data

static func _register_core_rects() -> bool:
	var data: Dictionary = _visual_data()
	if data.is_empty(): return false
	for path: String in data.required_source_sha256:
		if FileAccess.get_sha256(path) != String(data.required_source_sha256[path]): return false
	var staged: Array = []
	for row: Dictionary in data.textures:
		var texture: Texture2D = load(String(row.path)) as Texture2D
		if texture == null or texture.resource_path != row.path or texture.get_width() != int(row.size[0]) or texture.get_height() != int(row.size[1]): return false
		var r: Array = row.core_rect_xywh
		var rect := Rect2i(int(r[0]),int(r[1]),int(r[2]),int(r[3]))
		if not Rect2i(0,0,160,160).encloses(rect) or rect.size.x <= 0 or rect.size.y <= 0: return false
		staged.append({"texture":texture,"rect":rect})
	# Validate all four first. Strong references prevent stale instance-ID reuse.
	for row: Dictionary in staged:
		var texture: Texture2D = row.texture
		NPCNode._visible_bounds_cache[texture.get_instance_id()] = row.rect
		_texture_holds[texture.resource_path] = texture
	return true

func project_actor(scene: SceneScript,actor: NPCNode) -> Dictionary:
	if scene == null or actor == null: return {"ok":false}
	var data: Dictionary = _visual_data()
	if data.is_empty(): return {"ok":false}
	for change: Dictionary in data.actor_overrides:
		if actor.npc_id != change.npc_id or String(scene.scene_id) != change.before.scene_id: continue
		var old: Dictionary = change.before
		if actor.npc_name != old.npc_name or actor.sprite_path != old.sprite_path or actor.walk_sprite_path != old.walk_sprite_path or actor.portrait_path != old.portrait_path or actor.movement_mode != old.movement_mode: return {"ok":false}
		if not actor.dialog_id.is_empty() or not actor.interaction_action.is_empty() or not actor.dialog_variants.is_empty(): return {"ok":false}
		if change.walker:
			if actor.sprite_scale != 1.0 or not actor._calibrate_adult_body or actor.walk_frame_seconds != 0.12: return {"ok":false}
			actor.sprite_path = change.after.sprite_path
			actor.walk_sprite_path = change.after.walk_sprite_path
			actor.conversation_base_facing = "front"
		actor.portrait_path = change.after.portrait_path
		return {"ok":true,"matched":true}
	return {"ok":true,"matched":false}

func attach(field: Node,self_sha: String) -> bool:
	if not FORMAL_READY or not is_instance_valid(field) or field.get_script().resource_path != FIELD_PATH or FileAccess.get_sha256(SELF) != self_sha: return false
	var rows: Dictionary = _read_data()
	if rows.size() != 18 or not _register_core_rects(): return false
	var scene: SceneScript = field.get("_current_scene")
	if scene != null and scene.scene_id == ESTATE:
		var family: Variant = load("res://scripts/city/luoyang_estate_family_20261021am.gd")
		if family == null or not family.matches(scene): return false
		var receipt: Dictionary = family.validation_receipt()
		if receipt.is_empty() or not receipt.has("serial") or not receipt.has("key"): return false
		_estate_owner = {"scene":weakref(scene),"layout":weakref(scene.map_layout),"serial":receipt.serial,"key":receipt.key}
	_field_ref = weakref(field)
	_self_sha = self_sha
	_rows = rows
	if not EventBus.battle_started.is_connected(_on_battle_started): EventBus.battle_started.connect(_on_battle_started)
	return true

func _field() -> Node:
	return _field_ref.get_ref() if _field_ref != null else null

func configure_actor(scene: SceneScript,actor: NPCNode) -> Dictionary:
	if not is_instance_valid(actor) or scene == null or not _rows.has(actor.npc_id): return {"matched":false,"ok":true}
	var row: Dictionary = _rows[actor.npc_id]
	if String(scene.scene_id) != row.visual.scene_id: return {"matched":false,"ok":true}
	if actor.npc_name != row.visual.npc_name or actor.sprite_path != row.visual.sprite_path or actor.walk_sprite_path != row.visual.walk_sprite_path or actor.movement_mode != row.visual.movement_mode or actor.portrait_path != row.visual.portrait_path: return {"matched":true,"ok":false}
	if not actor.dialog_id.is_empty() or not actor.interaction_action.is_empty() or not actor.dialog_variants.is_empty(): return {"matched":true,"ok":false}
	actor.interaction_action = ACTION
	actor.set_meta("ambient25i_exact_identity",true)
	actor.interact_area.monitoring = true
	actor.interact_area.monitorable = true
	# Field remains sole pointer dispatcher; no new physics/input consumer.
	actor.interact_area.input_pickable = false
	return {"matched":true,"ok":true}

func _owned(lease: Dictionary = {}) -> bool:
	var field: Node = _field()
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_tree().current_scene != field or field.get_script().resource_path != FIELD_PATH: return false
	if field.get("_scene_rebuilding") != false or field.get("_resident_parked") != false or LoadingManager._transition_active or LoadingManager._external_active: return false
	var scene: SceneScript = field.get("_current_scene")
	var player: Node2D = field.get("_player")
	var loading: Dictionary = field.get_field_loading_state()
	if scene == null or not requested(scene.scene_id) or scene.map_layout == null or not is_instance_valid(player) or not player.is_inside_tree() or not player.is_visible_in_tree(): return false
	if SceneRouter.get_current_field_id() != scene.scene_id or loading.get("complete") != true or loading.get("failed") != false: return false
	if scene.scene_id == ESTATE:
		var estate_family: Variant = load("res://scripts/city/luoyang_estate_family_20261021am.gd")
		if estate_family == null or _estate_owner.is_empty() or _estate_owner.scene.get_ref() != scene or _estate_owner.layout.get_ref() != scene.map_layout: return false
		var receipt: Dictionary = estate_family.validation_receipt()
		if receipt.get("finalized") != true or receipt.get("full_source_hash_passes") != 2 or receipt.get("serial") != _estate_owner.serial or receipt.get("key") != _estate_owner.key: return false
	elif not CITY.is_v3(scene): return false
	if lease.is_empty(): return true
	if lease.scene.get_ref() != scene or lease.layout.get_ref() != scene.map_layout or lease.player.get_ref() != player or lease.revision != field.get("_city3_motion_revision") or lease.token != LoadingManager._external_token: return false
	var actor: NPCNode = lease.actor.get_ref() as NPCNode
	if not is_instance_valid(actor) or actor not in field.get("_npc_nodes") or not actor.is_inside_tree() or not actor.is_visible_in_tree() or actor.get_parent() != field.get("_actor_layer"): return false
	if not _rows.has(actor.npc_id): return false
	var visual: Dictionary = _rows[actor.npc_id].visual
	return actor.get_meta("ambient25i_exact_identity",false) == true and String(scene.scene_id) == visual.scene_id and actor.npc_name == visual.npc_name and actor.interaction_action == ACTION and actor.dialog_id.is_empty() and actor.dialog_variants.is_empty() and actor.sprite_path == visual.sprite_path and actor.walk_sprite_path == visual.walk_sprite_path and actor.portrait_path == visual.portrait_path and actor.movement_mode == visual.movement_mode and actor.global_position.distance_to(player.global_position) <= 118.0

func _node(graph: DialogScript,id: String,text: String,speaker: String,portrait: String,next: String) -> void:
	var node := DialogNode.new()
	node.node_id = StringName(id)
	node.text = text
	node.speaker = speaker
	node.portrait_path = portrait
	node.voice_emotion = "normal"
	node.on_end = next
	graph.nodes.append(node)

func open(npc_id: String) -> Dictionary:
	if not _owned() or DialogPlayer.is_playing() or not _session.is_empty() or not _rows.has(npc_id): return {"ok":false}
	if FileAccess.get_sha256(SELF) != _self_sha or source_paths().is_empty(): return {"ok":false}
	var field: Node = _field()
	var actor: NPCNode
	var count: int = 0
	for candidate: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(candidate) and candidate.npc_id == npc_id:
			actor = candidate
			count += 1
	if count != 1: return {"ok":false}
	var scene: SceneScript = field.get("_current_scene")
	var lease: Dictionary = {"scene":weakref(scene),"layout":weakref(scene.map_layout),"player":weakref(field.get("_player")),"actor":weakref(actor),"revision":field.get("_city3_motion_revision"),"token":LoadingManager._external_token}
	if not _owned(lease): return {"ok":false}
	var text: Dictionary = _rows[npc_id].text
	var graph := DialogScript.new()
	_serial += 1
	graph.dialog_id = StringName(String(text.dialog_id)+"_session_"+str(_serial))
	graph.entry_node_id = &"hero"
	var hero: String = GameState.player.display_name if GameState.player != null else "冷孤云"
	_node(graph,"hero",String(text.get("hero_opening_line","劳驾，近来街坊有什么新鲜事？")),hero,"res://art/characters/protagonist_portrait.png","next:start")
	_node(graph,"start",text.lines[0],actor.npc_name,actor.portrait_path,"next:reply")
	_node(graph,"reply",text.lines[1],actor.npc_name,actor.portrait_path,"end")
	lease.script = graph
	_session = lease
	_last = {"ok":true,"npc_id":npc_id,"dialog_id":String(graph.dialog_id),"field_instance":field.get_instance_id(),"scene_instance":scene.get_instance_id(),"actor_instance":actor.get_instance_id(),"revision":lease.revision,"token":lease.token,"no_new_audio":true}
	return {"ok":true,"npc":actor,"script":graph}

func observe_node() -> void:
	if _session.is_empty(): return
	if DialogPlayer._current_script != _session.script or not _owned(_session): abort("stale_owner_or_script")

func finish(id: StringName) -> Dictionary:
	if _session.is_empty() or (_session.script as DialogScript).dialog_id != id: return {"matched":false}
	var valid: bool = not DialogPlayer.is_playing() and DialogPlayer._current_script == null and _owned(_session)
	_session.clear()
	_last["completed"] = valid
	return {"matched":true,"ok":valid}

func abort(reason: String) -> void:
	var graph: DialogScript = _session.get("script") as DialogScript
	var actor_ref: WeakRef = _session.get("actor") as WeakRef
	_session.clear()
	_last = {"ok":false,"reason":reason,"effects_applied":false}
	if actor_ref != null:
		var actor: Variant = actor_ref.get_ref()
		if is_instance_valid(actor): actor.end_conversation()
	# No global cancel: only our exact generated script, after lease consumption.
	if graph != null and DialogPlayer.is_playing() and DialogPlayer._current_script == graph: DialogPlayer._end_dialog()

func _on_battle_started(_enemy_id: StringName) -> void:
	abort("battle_started")

func detach() -> void:
	abort("field_exit")
	if EventBus.battle_started.is_connected(_on_battle_started): EventBus.battle_started.disconnect(_on_battle_started)
	_field_ref = null
	_rows.clear()
	_estate_owner.clear()

func debug_state() -> Dictionary:
	var state: Dictionary = _last.duplicate(true)
	state["active"] = not _session.is_empty()
	state["configured_rows"] = _rows.size()
	return state
