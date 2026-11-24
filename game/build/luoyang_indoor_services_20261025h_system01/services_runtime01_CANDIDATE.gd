extends RefCounted
## Exact four-room services. Parent Scene/layout storage is never mutated.
const FORMAL_READY := false
const SELF := "res://build/luoyang_indoor_services_20261025h_system01/services_runtime01_CANDIDATE.gd"
const AUTHOR := "res://build/luoyang_indoor_services_20261025h_system01/services_author01_CANDIDATE.json"
const AUTHOR_SHA := "347b99a7ed1fd651259e8b8810cd90b89bd8892c3a5ff39633b07547414df0ea"
const G_PATH := "res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const FIELD_PATH := "res://scripts/field/field_walkable_controller.gd"
const ACTION := "indoor_service25h"
const SIZE := Vector2(1536,1024)
const ROOMS := ["luoyang_market_inn_interior_20261015", "luoyang_functional_pawnshop_candidate_20261016", "luoyang_market_market_northeast_rear_frontage_interior_20261015", "luoyang_market_shop_interior_20261015"]
static var _author: Dictionary = {}
static var _verified := false
var _field_ref: WeakRef
var _session: Dictionary = {}
var _pending_shop: Dictionary = {}
var _serial := 0
var _last_result: Dictionary = {}

static func owns(id: StringName) -> bool:
	return String(id) in ROOMS

static func _data(verify: bool = false) -> Dictionary:
	if FileAccess.get_sha256(AUTHOR) != AUTHOR_SHA: return {}
	if _author.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
		if not parsed is Dictionary or parsed.get("schema_version") != 1 or parsed.get("coordinates") != "SOURCE_FEET_1536_1024": return {}
		if parsed.get("fees",{}).get("meal") != 5 or parsed.get("fees",{}).get("rest") != 20 or parsed.get("rooms",{}).size() != 4: return {}
		for id: String in ROOMS:
			var row: Variant = parsed.rooms.get(id)
			if not row is Dictionary or not row.get("foot") is Array or row.foot.size() != 2 or not row.get("approach") is Array or row.approach.size() != 2: return {}
			if String(row.get("npc_id","")).is_empty() or not parsed.source_sha256.has(row.get("sprite_path")) or not parsed.source_sha256.has(row.get("portrait_path")): return {}
			if row.role != "inn" and not parsed.source_sha256.has("res://data/shops/"+String(row.shop_id)+".tres"): return {}
		_author = parsed
	if verify and not _verified:
		for path: String in _author.source_sha256:
			if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path) != _author.source_sha256[path]: return {}
		_verified = true
	return _author

static func source_paths() -> Dictionary:
	var data: Dictionary = _data()
	if data.is_empty(): return {}
	var paths: Dictionary = {SELF:true, AUTHOR:true}
	for path: String in data.source_sha256: paths[path] = true
	return paths

static func project_rows(scene: SceneScript, original: Array) -> Dictionary:
	if scene == null or not owns(scene.scene_id): return {"ok":true,"npcs":original}
	var data: Dictionary = _data(true)
	if not FORMAL_READY or data.is_empty(): return {"ok":false,"error":"INDOOR_SERVICE_SOURCE"}
	var spec: Dictionary = data.rooms[String(scene.scene_id)]
	var result: Array = original.duplicate(true)
	var count := 0
	var target := -1
	for index: int in range(result.size()):
		if not result[index] is Dictionary: return {"ok":false,"error":"INDOOR_SERVICE_ROW_TYPE"}
		if result[index].get("npc_id") == spec.npc_id:
			count += 1
			target = index
	if spec.role == "smith":
		if count != 1: return {"ok":false,"error":"INDOOR_EXISTING_SMITH_NOT_UNIQUE"}
		var old: Dictionary = result[target]
		if old.get("source_foot_px") != Vector2(663,448) or old.get("dialog_id") != "luoyang_distinct_rooms_20261016/smith_daily" or old.get("sprite_path") != spec.sprite_path or old.get("portrait_path") != spec.portrait_path: return {"ok":false,"error":"INDOOR_EXISTING_SMITH_CHANGED"}
	else:
		if count != 0: return {"ok":false,"error":"INDOOR_NEW_KEEPER_COLLISION"}
		target = result.size()
		result.append({})
	var row: Dictionary = result[target].duplicate(true)
	row.merge({"npc_id":spec.npc_id,"npc_name":spec.npc_name,"pos":Vector2(float(spec.foot[0]),float(spec.foot[1]))/SIZE,"source_foot_px":Vector2(float(spec.foot[0]),float(spec.foot[1])),"sprite_path":spec.sprite_path,"portrait_path":spec.portrait_path,"dialog_id":"","interaction_action":ACTION,"movement_mode":"idle","scale":1.0,"indoor_service25h":true},true)
	result[target] = row
	return {"ok":true,"npcs":result,"service_npc_id":spec.npc_id}

## Pure transaction plan; no state mutation, signals, files or room bypass.
static func plan_party(service: String, rows: Array, gold: int) -> Dictionary:
	if service not in ["meal","rest"] or rows.is_empty() or gold < 0: return {"ok":false,"reason":"invalid"}
	var effects: Array = []
	var all_full := true
	for raw: Variant in rows:
		if not raw is Dictionary: return {"ok":false,"reason":"invalid"}
		for key: String in ["hp","mp","max_hp","max_mp"]:
			if not raw.get(key) is int: return {"ok":false,"reason":"invalid"}
		var hp: int = raw.hp
		var mp: int = raw.mp
		var max_hp: int = raw.max_hp
		var max_mp: int = raw.max_mp
		if max_hp < 1 or max_mp < 0 or hp < 0 or hp > max_hp or mp < 0 or mp > max_mp: return {"ok":false,"reason":"invalid"}
		all_full = all_full and hp == max_hp and mp == max_mp
		effects.append({"hp":max_hp if service == "rest" else mini(max_hp,hp+maxi(1,floori(float(max_hp)*.25))),"mp":max_mp if service == "rest" else mini(max_mp,mp+maxi(1,floori(float(max_mp)*.25)))})
	if all_full: return {"ok":false,"reason":"full","cost":0}
	var cost: int = 20 if service == "rest" else 5
	if gold < cost: return {"ok":false,"reason":"insufficient","cost":cost}
	return {"ok":true,"reason":"ready","cost":cost,"effects":effects}

func attach(field: Node) -> bool:
	if not FORMAL_READY or not is_instance_valid(field) or field.get_script().resource_path != FIELD_PATH: return false
	_field_ref = weakref(field)
	if not EventBus.battle_started.is_connected(_on_battle_started): EventBus.battle_started.connect(_on_battle_started)
	return true

func detach() -> void:
	abort("field_exit")
	if EventBus.battle_started.is_connected(_on_battle_started): EventBus.battle_started.disconnect(_on_battle_started)
	_field_ref = null

func _on_battle_started(_enemy_id: StringName) -> void:
	abort("battle_started")

func abort(reason: String) -> void:
	_session.clear()
	_pending_shop.clear()
	_last_result = {"ok":false,"reason":reason,"committed":false}

func _field() -> Node:
	return _field_ref.get_ref() if _field_ref != null else null

func _owned(lease: Dictionary = {}) -> bool:
	var field: Node = _field()
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_tree().current_scene != field or field.get_script().resource_path != FIELD_PATH: return false
	if field.get("_resident_parked") or field.get("_scene_rebuilding") or LoadingManager._transition_active or LoadingManager._external_active: return false
	var scene: SceneScript = field.get("_current_scene")
	var player: Node2D = field.get("_player")
	var loading: Dictionary = field.get_field_loading_state()
	if scene == null or not owns(scene.scene_id) or scene.map_layout == null or not is_instance_valid(player) or not player.is_inside_tree() or not player.is_visible_in_tree(): return false
	if SceneRouter.get_current_field_id() != scene.scene_id or loading.get("complete") != true or loading.get("failed") != false: return false
	var rooms: Variant = load(G_PATH)
	if not rooms.is_room(scene) or not rooms.matches(scene,scene.scene_id): return false
	if lease.is_empty(): return true
	if lease.scene.get_ref() != scene or lease.layout.get_ref() != scene.map_layout or lease.player.get_ref() != player or lease.revision != field.get("_city3_motion_revision"): return false
	var actor: NPCNode = lease.actor.get_ref() as NPCNode
	if not is_instance_valid(actor) or actor not in field.get("_npc_nodes") or not actor.is_inside_tree() or not actor.is_visible_in_tree() or actor.get_parent() != field.get("_actor_layer"): return false
	var spec: Dictionary = _data().rooms[String(scene.scene_id)]
	var expected_foot: Vector2 = Vector2(float(spec.foot[0]),float(spec.foot[1]))/SIZE*field.get("_world_size")
	return actor.npc_id == spec.npc_id and actor.interaction_action == ACTION and actor.sprite_path == spec.sprite_path and actor.portrait_path == spec.portrait_path and actor.position == expected_foot and actor.global_position.distance_to(player.global_position) <= 118.0

func _node(script: DialogScript, id: String, text: String, speaker: String, portrait: String) -> DialogNode:
	var node := DialogNode.new()
	node.node_id = StringName(id)
	node.text = text
	node.speaker = speaker
	node.portrait_path = portrait
	node.on_end = "end"
	script.nodes.append(node)
	return node

func _script(spec: Dictionary, dialog_id: String) -> DialogScript:
	var script := DialogScript.new()
	script.dialog_id = StringName(dialog_id)
	script.entry_node_id = &"hero"
	var hero: DialogNode = _node(script,"hero","掌柜，请问这里有什么方便？" if spec.role == "inn" else "请问这里有什么货品？",GameState.player.display_name,"res://art/characters/protagonist_portrait.png")
	hero.on_end = "next:menu"
	var menu: DialogNode = _node(script,"menu",String(spec.greeting),String(spec.npc_name),String(spec.portrait_path))
	if spec.role == "inn":
		menu.choices.assign([{"text":"打尖 · 5金（全队生命、内力各恢复上限25%）","next":"meal_confirm"},{"text":"住宿 · 20金（全队生命、内力全部恢复）","next":"rest_confirm"},{"text":"先不打扰了","next":"leave"}])
		for service: String in ["meal","rest"]:
			var price: int = 5 if service == "meal" else 20
			var effect: String = "全队各恢复生命、内力上限的25%（向下取整，至少1，不超过上限）" if service == "meal" else "全队生命、内力恢复至各自当前上限"
			var confirm: DialogNode = _node(script,service+"_confirm","%s需%d金，%s。全队已满则不收费。确定吗？" % ["打尖" if service == "meal" else "住宿",price,effect],String(spec.npc_name),String(spec.portrait_path))
			confirm.choices.assign([{"text":"确定，按此办理","next":service+"_commit"},{"text":"还是算了","next":"leave"}])
			_node(script,service+"_commit","好，待我核过人数与账钱，便为各位安排。",String(spec.npc_name),String(spec.portrait_path))
	else:
		menu.choices.assign([{"text":"看看货品 / 出售旧物","next":"shop"},{"text":"告辞","next":"leave"}])
		_node(script,"shop","货价与回收价都在账上，客官请看。",String(spec.npc_name),String(spec.portrait_path))
	_node(script,"leave","客官慢走，需要时再来。",String(spec.npc_name),String(spec.portrait_path))
	return script

func open(npc_id: String) -> Dictionary:
	if not _owned() or DialogPlayer.is_playing() or _data(true).is_empty() or GameState.player == null: return {"ok":false}
	var field: Node = _field()
	var scene: SceneScript = field.get("_current_scene")
	var spec: Dictionary = _data().rooms[String(scene.scene_id)]
	if npc_id != spec.npc_id: return {"ok":false}
	var actor: NPCNode
	var count := 0
	for candidate: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(candidate) and candidate.npc_id == npc_id:
			actor = candidate
			count += 1
	if count != 1: return {"ok":false}
	abort("new_menu")
	_serial += 1
	var id: String = "luoyang_service25h_%d_%d" % [field.get_instance_id(),_serial]
	var script: DialogScript = _script(spec,id)
	var player: Node2D = field.get("_player")
	_session = {"serial":_serial,"dialog_id":id,"script":script,"scene":weakref(scene),"layout":weakref(scene.map_layout),"player":weakref(player),"actor":weakref(actor),"revision":field.get("_city3_motion_revision"),"npc_id":npc_id,"last_node":"","confirmed":"","rejected":false}
	if not _owned(_session):
		abort("actor_owner_changed")
		return {"ok":false}
	return {"ok":true,"npc":actor,"script":script}

func observe_node() -> void:
	if _session.is_empty(): return
	if DialogPlayer._current_script != _session.script or not _owned(_session):
		_session.rejected = true
		return
	var node: DialogNode = DialogPlayer._current_node
	if node == null or node != _session.script.find_node_by_id(node.node_id):
		_session.rejected = true
		return
	var id: String = String(node.node_id)
	var previous: String = _session.last_node
	var allowed: Dictionary = {"hero":[""],"menu":["hero"],"meal_confirm":["menu"],"rest_confirm":["menu"],"meal_commit":["meal_confirm"],"rest_commit":["rest_confirm"],"shop":["menu"],"leave":["menu","meal_confirm","rest_confirm"]}
	if not allowed.has(id) or previous not in allowed[id]:
		_session.rejected = true
		return
	_session.last_node = id
	if id in ["meal_commit","rest_commit","shop"]: _session.confirmed = id

func _current_party() -> Dictionary:
	if GameState.player == null or GameState.party.is_empty(): return {"ok":false}
	var members: Array = []
	var rows: Array = []
	var seen: Dictionary = {}
	for member: CharacterStats in GameState.party:
		if not is_instance_valid(member) or seen.has(member.get_instance_id()): return {"ok":false}
		seen[member.get_instance_id()] = true
		members.append(member)
		rows.append({"hp":member.hp,"mp":member.mp,"max_hp":member.max_hp,"max_mp":member.max_mp})
	if GameState.player not in members: return {"ok":false}
	return {"ok":true,"members":members,"rows":rows}

func finish(dialog_id: StringName) -> Dictionary:
	if _session.is_empty() or String(dialog_id) != _session.dialog_id: return {"matched":false}
	var lease: Dictionary = _session
	_session = {} # Consume exactly this request before any state mutation/signals.
	var result: Dictionary = {"matched":true,"ok":false,"committed":false,"serial":lease.serial}
	if lease.rejected or not _owned(lease) or DialogPlayer.is_playing():
		result.reason = "stale_owner_or_dialog"
	elif lease.confirmed == "shop" and lease.last_node == "shop":
		_pending_shop = lease
		result.merge({"ok":true,"shop_ticket":lease.serial},true)
	elif lease.confirmed in ["meal_commit","rest_commit"] and lease.last_node == lease.confirmed:
		var party: Dictionary = _current_party() # Fresh current Stats/maxima, never an open-menu HP snapshot.
		if not party.get("ok",false):
			result.reason = "invalid_party"
		else:
			var service: String = "meal" if lease.confirmed == "meal_commit" else "rest"
			var plan: Dictionary = plan_party(service,party.rows,GameState.gold)
			if not plan.ok:
				result.reason = plan.reason
				result.feedback = "各位已精神饱满，无需花钱。" if plan.reason == "full" else ("现有金钱不足，本次未扣费。" if plan.reason == "insufficient" else "本次无法核实队伍，本次未扣费。")
			else:
				# No await/callback between fresh validation and writing every target.
				for index: int in range(party.members.size()):
					var member: CharacterStats = party.members[index]
					member.hp = plan.effects[index].hp
					member.mp = plan.effects[index].mp
				GameState.add_gold(-int(plan.cost))
				GameState.player_changed.emit()
				GameState.party_changed.emit()
				result.merge({"ok":true,"committed":true,"service":service,"cost":plan.cost,"effects":plan.effects,"feedback":"已付%d金。%s" % [plan.cost,"全队生命、内力已恢复至上限。" if service == "rest" else "全队已用过饭食，生命、内力得到恢复。"]},true)
	else:
		result.merge({"ok":true,"reason":"declined","cost":0},true)
	_last_result = result.duplicate(true)
	return result

func dispatch_shop(ticket: int) -> void:
	if _pending_shop.is_empty() or _pending_shop.serial != ticket: return
	var lease: Dictionary = _pending_shop
	_pending_shop = {}
	if not _owned(lease) or DialogPlayer.is_playing(): return
	var scene: SceneScript = lease.scene.get_ref() as SceneScript
	var spec: Dictionary = _data().rooms[String(scene.scene_id)]
	var id: String = spec.shop_id
	var path: String = "res://data/shops/"+id+".tres"
	if id.is_empty() or FileAccess.get_sha256(path) != _data().source_sha256.get(path): return
	SceneRouter.go_shop(StringName(id))

func debug_state() -> Dictionary:
	return {"active":not _session.is_empty(),"serial":_serial,"dialog_id":_session.get("dialog_id",""),"npc_id":_session.get("npc_id",""),"last_node":_session.get("last_node",""),"confirmed":_session.get("confirmed",""),"last_result":_last_result.duplicate(true),"pending_shop":_pending_shop.get("serial",0)}
