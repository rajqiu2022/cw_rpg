extends Control

## 可行走探索场景（Field Walkable）控制器。
##
## 工作方式：
##   1. 从 SceneRouter 取当前 scene_id
##   2. 加载对应 SceneScript .tres
##   3. 渲染背景图、实例化 Player、NPC、出口
##   4. 玩家用 WASD/方向键移动，走进 NPC 范围按交互键对话
##   5. 走进出口按交互键（或自动）切换场景
##
## 与经典模式（field_controller.gd）的区别：
##   - 没有热点按钮，所有交互由玩家移动+交互键触发
##   - 玩家是自由的 CharacterBody2D，不是静态背景+按钮

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const NPC_SCENE := preload("res://scenes/npc_node.tscn")
const EXIT_SCENE := preload("res://scenes/exit_zone.tscn")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const EQUIPMENT_PANEL_SCENE := preload("res://scenes/ui/character_panel.tscn")
const SKILL_PANEL_SCENE := preload("res://scenes/ui/skill_panel.tscn")
const QUEST_PANEL_SCENE := preload("res://scenes/ui/quest_panel.tscn")
const WORLD_MAP_PANEL_SCENE := preload("res://scenes/ui/world_map_panel.tscn")
const FIELD_PRIMARY_HUD_SCENE := preload("res://scenes/ui/field_primary_hud.tscn")
const WORLD_TRAVEL_MINIMAP := preload("res://scripts/ui/world_travel_minimap.gd")
const SYSTEM_MENU_SCENE := preload("res://scenes/ui/system_menu.tscn")
const FORMAL_CONFIRM_SCENE := preload("res://scenes/ui/formal_confirm_dialog.tscn")
const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const UI_TEXTURE_SKIN := preload("res://scripts/ui/ui_texture_skin.gd")
const UI_LAYER_POLICY := preload("res://scripts/ui/ui_layer_policy.gd")
const INTERACTION_OUTLINE_SHADER := preload("res://shaders/interaction_outline.gdshader")
const ENVIRONMENT_FLAME_SHADER := preload("res://shaders/environment_flame.gdshader")
const ENVIRONMENT_RAIN_SHADER := preload("res://shaders/environment_rain.gdshader")
const INTERACTION_VISUALS := {
	"letter": "res://art/props/interactive/interaction_letter_sealed_v1.png",
	"ledger": "res://art/props/interactive/expansion_v1/manual_diagram_page_v1.png",
	"parcel": "res://art/props/interactive/expansion_v1/clue_sealed_message_tube_v2.png",
	"chest": "res://art/props/interactive/expansion_v1/chest_common_wood_v1.png",
	"stain": "res://art/props/interactive/interaction_water_stain_v1.png",
}
const HUD_ART_DIR := "res://art/ui/field_hud/v1"
const NPC_CATALOG: NPCCatalog = preload("res://data/npcs/npc_catalog.tres")
const CITY_TASKS = preload("res://scripts/city/luoyang_city_tasks_20261016.gd")
const CULTURE_X = preload("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd")
const FUNCTIONAL_INTERIORS = preload("res://scripts/city/luoyang_functional_interiors_20261016.gd")
const ASSEMBLED_ROOMS = preload("res://scripts/city/luoyang_assembled_rooms_20261016b.gd")
const ELEVEN_ROOMS = preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
const ASSEMBLED_FADE = preload("res://scripts/city/luoyang_assembled_low_furniture_fade_20261016.gd")
const ASSEMBLED_CITY_FADE = preload("res://scripts/city/luoyang_city_assembled_fade_20261016b.gd")
const YAMEN_ANNEX_FADE = preload("res://scripts/city/luoyang_yamen_annex_fade_20261016.gd")
const DISTRICT_LIFE = preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const DISTRICT_FADE = preload("res://scripts/city/luoyang_district_life_fade_20261016f.gd")
const TEMPLE_ASSEMBLY = preload("res://scripts/city/luoyang_temple_assembly_20261016.gd")
const TEMPLE_TASKS = preload("res://scripts/city/luoyang_temple_task_adapter_20261016.gd")
const TEMPLE_FADE = preload("res://scripts/city/luoyang_temple_fade_20261016.gd")
const INVENTORY_SHORTCUT_ENABLED := false
const OCCLUSION_SAMPLE_DISTANCE_PX := 8.0
const RETURN_SPAWN_SAMPLE_DISTANCE_PX := 12.0

class City3MotionJob:
	extends RefCounted
	var guard: RefCounted
	var mask: Image
	var visual_objects: Array
	var succeeded := false

	func run() -> void:
		# Exclusive CPU data only: this Callable never captures the Field/SceneTree.
		var result: Variant = guard.call("configure", mask, visual_objects)
		succeeded = typeof(result) == TYPE_BOOL and result == true
		mask = null
		visual_objects.clear()

class V14LateDepthRefresh:
	extends Node
	var field_ref: WeakRef

	func _process(_delta: float) -> void:
		# A weak owner avoids retaining an exited Field through this callback.
		if field_ref == null: return
		var field = field_ref.get_ref()
		if is_instance_valid(field): field.call("_refresh_v14_late_depth", self)


@onready var background: TextureRect = %Background

@onready var world_container: Node2D = %WorldContainer
@onready var hotspots_container: Control = %HotspotsContainer
@onready var scene_title: Label = %SceneTitle
@onready var hud_gold: Label = %GoldLabel
@onready var quest_list: RichTextLabel = %QuestList
@onready var quest_log_btn: Button = %QuestLogBtn
@onready var inventory_btn: Button = %InventoryBtn
@onready var equipment_btn: Button = %EquipmentBtn
@onready var skill_btn: Button = %SkillBtn
@onready var system_btn: Button = %SystemBtn
@onready var hint_bar: Control = %HintBar

@onready var hint_label: Label = %HintLabel
@onready var player_info: Label = %PlayerInfo

var _current_scene: SceneScript = null
var _player: Player = null
var _inventory_panel = null
var _equipment_panel = null
var _panels_ready: bool = false
var _skill_panel = null
var _quest_panel_full = null
var _world_map_panel: WorldMapPanel = null
var _sparring_confirm_dialog: FormalConfirmDialog = null
var _pending_sparring_action: String = ""
var _pending_sparring_npc_id: String = ""
var _hud_canvas_layer: CanvasLayer = null
var _system_ui_canvas_layer: CanvasLayer = null


var _npc_nodes: Array[NPCNode] = []
var _active_dialog_npc: NPCNode = null
var _exit_nodes: Array[ExitZone] = []
var _collision_bodies: Array[StaticBody2D] = []
var _trigger_areas: Array[Area2D] = []
var _trigger_events_in_flight: Dictionary = {}
var _outskirts_discovery_dialog_pending: bool = false
var _outskirts_discovery_dialog_id: StringName = &""
var _scene_refresh_pending: bool = false
var _scene_rebuilding: bool = false
var _field_loading_progress := 0.0
var _field_loading_stage := "正在初始化场景……"
var _field_loading_complete := false
var _field_loading_failed := false
var _scene_object_nodes: Array[Sprite2D] = []
const V14_MODULAR_OVERLAP = preload("res://scripts/world/v14_modular_overlap.gd")
const V15_MODULAR_OVERLAP = preload("res://scripts/world/v15_modular_overlap.gd")
const WORLD_V15_STREAM = preload("res://scripts/world/world_v15_visible_stream_20261018r.gd")
const WORLD_V15_STREAM_OVERLAP = preload("res://scripts/world/world_v15_stream_overlap_20261018r.gd")
var _world_v15_stream: Node
const OUTSKIRTS = preload("res://scripts/world/outskirts_native_contract.gd")
const OUTSKIRTS_OVERLAP = preload("res://scripts/world/outskirts_modular_overlap.gd")
const LUOYANG_V3 = preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const CITY3_MOTION_GUARD = preload("res://scripts/city/luoyang_city3_motion_guard_20261009.gd")
var _city3_motion_guard: RefCounted
var _city3_motion_scene: SceneScript
var _city3_motion_job: City3MotionJob
var _city3_motion_task_id := -1
var _city3_motion_revision := 0
const CITY_ALPHA = preload("res://scripts/city/luoyang_v3_sprite_alpha.gd")
const CITY_OVERLAP = preload("res://scripts/city/luoyang_v3_modular_overlap.gd")
const CITY_ENCLOSURE_OVERLAP = preload("res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd")
const CITY_ENCLOSURE_FADE = preload("res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd")
const GATE_FORTIFICATION = preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const GATE_MOAT_RUNTIME = preload("res://scripts/city/luoyang_gate_moat_runtime_20261013.gd")
const GATE_FORTIFICATION_FADE = preload("res://scripts/city/luoyang_gate_fortification_fade_20261013.gd")
const HARBOUR_LIFE = preload("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd")
const HARBOUR_FADE = preload("res://scripts/city/luoyang_harbour_life_fade_20261016.gd")
var _harbour_gate_visual_scene: SceneScript
var _harbour_crowd_receipt: Dictionary={}
const MARKET_ENRICHMENT = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
const MARKET_ENRICHMENT_FADE = preload("res://scripts/city/luoyang_market_enrichment_fade_20261014.gd")
var _gate_moat_runtime: RefCounted
var _city_alpha: Variant = CITY_ALPHA.new()
var _v14_modular_overlap: RefCounted
var _v14_late_depth_refresh: Node
var _occluder_nodes: Array[DynamicOccluder2D] = []
var _actor_fade_zones: Array[Dictionary] = []
var _animated_prop_nodes: Array[Node2D] = []
var _weather_nodes: Array[Node2D] = []
var _rain_pattern_texture: ImageTexture = null
var _screen_size: Vector2 = Vector2(1920, 1080)
var _viewport_size: Vector2 = Vector2(1920, 1080)
var _world_size: Vector2 = Vector2(1920, 1080)
var _world_origin: Vector2 = Vector2.ZERO
var _camera_scroll_enabled: bool = false
var _camera_zoom: float = 1.0
var _world_camera: Camera2D = null
var _world_background: Sprite2D = null
var _background_streamer: BackgroundChunkStreamer = null
var _visual_layer: Node2D = null
var _collision_layer: Node2D = null
var _interaction_layer: Node2D = null
var _walkability_blocker_footprints: Array[Rect2] = []
var _walkable_mask_image: Image = null
var _walkable_mask_tiles: Array[Dictionary] = []
var _portal_layer: Node2D = null
var _actor_layer: Node2D = null
var _foreground_layer: Node2D = null
var _encounter_distance: float = 0.0
var _last_encounter_position: Vector2 = Vector2.ZERO
var _last_occlusion_sample: Vector2 = Vector2(-10.0, -10.0)
var _last_return_spawn_sample: Vector2 = Vector2(-10.0, -10.0)
var _encounter_locked: bool = false
var _item_toast: RichTextLabel = null
var _item_toast_lines: Array[String] = []
var _item_toast_serial: int = 0
var _zhao_escape_actor: Sprite2D = null

var _hud_btn_normal: StyleBoxFlat
var _hud_btn_hover: StyleBoxFlat
var _primary_hud = null
var _world_travel_minimap: Control = null
var _formal_hud_layer: Control = null
var _formal_portrait: TextureRect = null
var _formal_name_label: Label = null
var _formal_hp_bar: TextureRect = null
var _formal_mp_bar: TextureRect = null
var _formal_gold_label: Label = null
var _formal_scene_label: Label = null
var _formal_hint_label: Label = null
var _resident_parked := false
var _resident_connections: Array[Dictionary] = []
var _resident_world_state: Dictionary = {}
var _resident_dynamic_receipt: Dictionary = {}
var _city_tasks_receipt: Dictionary = {}
var _functional_room_geometry: Dictionary = {}
var _temple_session: RefCounted
var _district_session: RefCounted
var _district_last_receipt: Dictionary={"matched":false}
var _temple_last_receipt: Dictionary={}
var _formal_bottom_bar: TextureRect = null
var _culture_x: RefCounted
var _culture_committing := false
var _field_loading_profile: Dictionary = {}
var _field_loading_ui_profile: Dictionary = {}


func _ready() -> void:
	var loading_ui_started: Dictionary = _field_loading_profile_clock()
	_culture_x = CULTURE_X.new()
	_culture_x.attach(self)
	DialogPlayer.text_displayed.connect(_on_culture_x_text_displayed)
	_init_ui_canvas_layers()
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.reputation_changed.connect(_on_reputation_changed)
	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_ended.connect(_on_dialog_ended)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.skill_learned.connect(_on_skill_learned)
	EventBus.companion_joined.connect(_on_companion_joined)
	EventBus.dialog_spar_requested.connect(_on_dialog_spar_requested)
	EventBus.field_cutscene_requested.connect(_on_field_cutscene_requested)
	EventBus.equipment_changed.connect(_on_field_equipment_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.ui_requested.connect(_on_ui_requested)
	EventBus.toast_requested.connect(_show_toast)
	QuestManager.active_quests_changed.connect(_on_active_quests_changed)
	QuestManager.tracked_quest_changed.connect(_on_tracked_quest_changed)
	EventBus.quest_accepted.connect(_on_quest_accepted)
	EventBus.quest_progressed.connect(_on_quest_progressed)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.evidence_acquired.connect(_on_evidence_acquired)
	quest_log_btn.pressed.connect(_on_quest_log_pressed)
	inventory_btn.pressed.connect(_toggle_inventory_panel)
	equipment_btn.pressed.connect(_toggle_equipment_panel)
	skill_btn.pressed.connect(_toggle_skill_panel)
	system_btn.pressed.connect(_open_system_menu)
	_init_m5_panels()
	_init_sparring_confirmation()

	_init_field_ui_styles()

	_init_formal_hud()
	_apply_formal_hud_mode()
	_disable_gameplay_button_focus(self)
	_field_loading_ui_profile = _field_loading_profile_span(loading_ui_started, _field_loading_profile_clock())
	var field_payload := SceneRouter.get_field_payload()
	var scene_id: StringName = field_payload.get("scene_id", &"ch1_s2_qingfeng")
	if scene_id == &"ch1_s2_qingfeng_walkable":
		scene_id = &"ch1_s2_qingfeng"
	var loading: Node = get_node_or_null("/root/LoadingManager")
	var progressive: bool = loading != null and loading.get("_transition_active") == true and (LUOYANG_V3.owns_id(scene_id) or (SceneRouter.is_world_map_scene(scene_id) and SceneRouter.world_version_for_scene(scene_id) == 15))
	if progressive:
		_scene_rebuilding = true
		_field_loading_stage = "正在校验地图来源、道路与入口……"
		await get_tree().process_frame
		if not is_inside_tree(): return
	_current_scene = _load_scene(scene_id)
	if _current_scene == null:
		_field_loading_failed = true
		_field_loading_stage = "地图来源校验失败"
		push_warning("[FieldWalkable] failed to load scene %s" % scene_id)
		return

	await _setup_scene(_current_scene, field_payload.get("player_spawn", null), progressive)
	if not is_inside_tree(): return
	_field_loading_complete = is_instance_valid(_player) and not _scene_rebuilding
	_field_loading_failed = not _field_loading_complete
	if progressive and _field_loading_failed:
		_field_loading_stage = "道路、碰撞或出生点初始化失败"
		return
	_field_loading_progress = 1.0
	_field_loading_stage = "地图与入口已就绪"
	_refresh_gold()
	_refresh_quest_panel()

	# 场景进入事件
	EventBus.scene_entered.emit(scene_id)
	AudioManager.ensure_bgm_for_scene(scene_id)

	# on_enter_dialog
	if _should_play_enter_dialog(_current_scene):
		_mark_enter_dialog_played(_current_scene)
		await get_tree().process_frame
		DialogPlayer.play(_current_scene.on_enter_dialog)
		return

	var pending_action := SceneRouter.take_pending_field_action()
	if pending_action.is_empty() and scene_id == &"ch1_s3_ruin_inner" \
		and _flag_truthy("zhao_wuji_escape_cutscene_pending") \
		and not _flag_truthy("zhao_wuji_wounded_escape"):
		pending_action = "dialog:ch1_s3_ruin_after_boss"
	if not pending_action.is_empty():
		await get_tree().process_frame
		if pending_action == "dialog:ch1_s3_ruin_after_boss":
			_prepare_zhao_escape_actor()
		SceneRouter.resolve_action(pending_action)


func _exit_tree() -> void:
	if _culture_x != null: _culture_x.abort("field_exit")
	if _resident_parked: return # Detached live exterior; explicit discard owns cleanup.
	_release_world_v15_stream()
	if _current_scene!=null and LUOYANG_V3.owns_id(_current_scene.scene_id): LUOYANG_V3.clear_resident_receipt()
	_city3_motion_revision += 1
	_release_temple_session()
	_release_district_session()
	_release_city3_motion()
	_release_gate_moat_runtime()
	_release_city_building_fade()
	_release_world_travel_minimap()


func resident_estimated_bytes() -> int:
	# Conservative texture RGBA estimate + mask/prefix. This is not a VRAM query.
	var seen: Dictionary={}
	var total:=3072*2048*8
	var pending: Array[Node]=[self]
	while not pending.is_empty():
		var node: Node=pending.pop_back()
		for child: Node in node.get_children(): pending.append(child)
		for property: Dictionary in node.get_property_list():
			if property.type!=TYPE_OBJECT: continue
			var value: Variant=node.get(property.name)
			if value is Texture2D and not seen.has(value.get_instance_id()):
				seen[value.get_instance_id()]=true
				total+=int(value.get_width())*int(value.get_height())*6
	return total

func _resident_state_now() -> Dictionary:
	return {"flags":GameState.flags.duplicate(true),"quests":QuestManager.to_dict(),"bounty":BountyManager.to_dict(),"weather":WeatherManager.to_dict()}


func resident_static_identity() -> Dictionary:
	# Object identity of the still-alive Field, not copied resource validation.
	# Only the explicitly nonblocking task mud visual may appear/disappear.
	if _current_scene==null or not LUOYANG_V3.owns_id(_current_scene.scene_id): return {}
	var props: Array=[]
	for sprite: Sprite2D in _scene_object_nodes:
		if not is_instance_valid(sprite): return {}
		if sprite.name=="SceneObject_warehouse_mud_trace": continue
		props.append([sprite.get_instance_id(),sprite.texture.get_instance_id() if sprite.texture!=null else 0])
	var bodies: Array=[]
	for body: StaticBody2D in _collision_bodies:
		if not is_instance_valid(body): return {}
		bodies.append(body.get_instance_id())
	return {"field":get_instance_id(),"scene":_current_scene.get_instance_id(),"props":props,"bodies":bodies,"mask":_walkable_mask_image,"motion":_city3_motion_guard,"district":_district_session,"moat":_gate_moat_runtime,"fade":_v14_modular_overlap,"background":_world_background,"camera":_world_camera,"player":_player,"size":_world_size}


func get_resident_dynamic_refresh_state() -> Dictionary:
	return _resident_dynamic_receipt.duplicate(true)


func _resident_refresh_dynamic() -> bool:
	# Re-project only current gameplay state. Original Scene, navigation/mask,
	# furniture, textures, native bodies and movement index stay alive unchanged.
	var scene: SceneScript=_current_scene
	if scene==null or scene.map_layout==null or not LUOYANG_V3.owns_id(scene.scene_id): return false
	var before: Dictionary=resident_static_identity()
	var state_before: Dictionary=_resident_state_now()
	var objects: Array=scene.map_layout.visual_objects
	var interactions: Array=scene.map_layout.interactions
	var npcs: Array=scene.npcs.duplicate(true)
	var receipt: Dictionary={"matched":false}
	if String(scene.scene_id) in CITY_TASKS.IDS:
		var projected: Dictionary=CITY_TASKS.project(scene,GameState.flags.duplicate(true),QuestManager.states.duplicate(true),interactions)
		if projected.get("ok")!=true or not LUOYANG_V3._equal_value(LUOYANG_V3.object_solids(objects),LUOYANG_V3.object_solids(projected.visual_objects)): return false
		objects=projected.visual_objects; interactions=projected.interactions; npcs=projected.npcs; receipt=projected.receipt.duplicate(true)
	var functional: Dictionary=ELEVEN_ROOMS.project_portals(scene,scene.map_layout.portals) if ELEVEN_ROOMS.enabled() else FUNCTIONAL_INTERIORS.project_portals(scene,scene.map_layout.portals)
	if functional.get("ok")!=true: return false
	# Keep the ambient actors and their actual patrol phases/bodies. Only task /
	# bounty actors are recreated from today's flags, not the parked snapshot.
	if is_instance_valid(_active_dialog_npc): _active_dialog_npc.end_conversation()
	var ambient: Array[NPCNode]=[]
	for npc: NPCNode in _npc_nodes:
		if not is_instance_valid(npc): return false
		if CULTURE_X.requested(scene.scene_id) and npc.npc_id == CULTURE_X.BUYER:
			npc.get_parent().remove_child(npc); npc.free()
			continue
		if npc.npc_id.begins_with("harbour_life_") or npc.npc_id.begins_with("district_life_"):
			ambient.append(npc)
		else:
			npc.get_parent().remove_child(npc); npc.free()
	_npc_nodes=ambient; _active_dialog_npc=null
	for zone: ExitZone in _exit_nodes:
		if is_instance_valid(zone): zone.get_parent().remove_child(zone); zone.free()
	_exit_nodes.clear()
	for area: Area2D in _trigger_areas:
		if is_instance_valid(area):
			_set_interaction_highlight(area,false)
			area.get_parent().remove_child(area); area.free()
	_trigger_areas.clear()
	# Original ordinary cargo remains visible/solid. Only this source-checked
	# evidence sprite is conditional, and it has no physical footprint.
	var mud: Dictionary={}
	for item: Dictionary in objects:
		if String(item.get("id",""))=="warehouse_mud_trace": mud=item
	var mud_sprite: Sprite2D=null
	for sprite: Sprite2D in _scene_object_nodes:
		if is_instance_valid(sprite) and sprite.name=="SceneObject_warehouse_mud_trace": mud_sprite=sprite
	if not mud.is_empty():
		if mud.get("blocking")!=false or not mud.get("solid_polygons_px",[]).is_empty() or LUOYANG_V3._vec(mud.get("collision_size_px"))!=Vector2.ZERO: return false
		if mud_sprite==null: await _spawn_scene_objects([mud],false)
	elif mud_sprite!=null: mud_sprite.visible=false
	if mud_sprite!=null and not mud.is_empty(): mud_sprite.visible=true
	if CULTURE_X.requested(scene.scene_id) and String(scene.scene_id) == CULTURE_X.MARKET and _district_session != null:
		for row: Dictionary in _district_session.npcs():
			if row.get("npc_id") == CULTURE_X.BUYER: npcs.append(row.duplicate(true))
	npcs.append_array(BountyManager.get_scene_npcs(scene.scene_id))
	if CULTURE_X.requested(scene.scene_id):
		var culture: Dictionary = CULTURE_X.project_rows(scene.scene_id, npcs, GameState.flags, QuestManager.states)
		if culture.get("ok") != true: return false
		npcs = culture.npcs
	_spawn_npcs(npcs)
	if CULTURE_X.requested(scene.scene_id) and _culture_x.configure_actors().get("ok") != true: return false
	_spawn_exits(functional.portals)
	_spawn_trigger_zones(interactions)
	_spawn_active_weather(scene)
	_city_tasks_receipt=receipt
	_city_tasks_receipt.merge({"render_applied":true,"original_scene_identity":scene.get_instance_id(),"dynamic_only":true})
	_scene_refresh_pending=false
	_resident_dynamic_receipt={"scene_id":String(scene.scene_id),"dynamic_only":true,"static_objects_preserved":resident_static_identity()==before,"current_flags_applied":state_before==_resident_state_now(),"ambient_preserved":ambient.size(),"npc_count":_npc_nodes.size()}
	return _resident_dynamic_receipt.static_objects_preserved and _resident_dynamic_receipt.current_flags_applied and not _field_loading_failed

func resident_begin_park() -> bool:
	if _resident_parked or not get_field_loading_state().complete or DialogPlayer.is_playing() or _city3_motion_task_id>=0: return false
	if _culture_x != null: _culture_x.abort("field_park")
	_resident_world_state=_resident_state_now()
	_resident_parked=true
	_player.set_can_move(false)
	# process_mode does not stop global signals. Disconnect every singleton
	# connection targeting this subtree, including child UI controllers.
	for emitter: Node in get_tree().root.get_children():
		if emitter==self: continue
		for definition: Dictionary in emitter.get_signal_list():
			var signal_name:=StringName(definition.name)
			for connection: Dictionary in emitter.get_signal_connection_list(signal_name):
				var callback: Callable=connection.callable
				var target: Object=callback.get_object()
				if target is Node and (target==self or is_ancestor_of(target as Node)):
					_resident_connections.append({"emitter":weakref(emitter),"signal":signal_name,"callable":callback,"flags":connection.flags})
					emitter.disconnect(signal_name,callback)
	return true

func resident_abort_park(mode: int) -> void:
	_resident_parked=false
	for connection: Dictionary in _resident_connections:
		var emitter: Object=connection.emitter.get_ref()
		if is_instance_valid(emitter) and connection.callable.is_valid() and not emitter.is_connected(connection["signal"],connection.callable): emitter.connect(connection["signal"],connection.callable,int(connection.flags))
	_resident_connections.clear()
	process_mode=mode
	# The minimap's own _exit_tree restores its shared plaque. If a warm return
	# is cancelled after detaching the source world, rebuild only that HUD widget.
	if _current_scene!=null and SceneRouter.is_world_map_scene(_current_scene.scene_id) and is_inside_tree():
		_release_world_travel_minimap(); _setup_world_travel_minimap(_current_scene)
	if is_instance_valid(_player): _player.set_can_move(true)

func resident_discard() -> void:
	# Also valid outside SceneTree: free() there would not call _exit_tree again.
	if _current_scene!=null and LUOYANG_V3.owns_id(_current_scene.scene_id): LUOYANG_V3.clear_resident_receipt()
	_resident_parked=false; _resident_connections.clear()
	_city3_motion_revision+=1
	_release_district_session()
	_release_city3_motion(); _release_gate_moat_runtime(); _release_city_building_fade(); _release_world_travel_minimap()

func resident_actual_spawn() -> Vector2:
	return _player.position/_world_size if is_instance_valid(_player) and _world_size.x>0 and _world_size.y>0 else Vector2(INF,INF)

func resident_resume(spawn: Vector2) -> bool:
	if not _resident_parked or not is_inside_tree() or _current_scene==null or not LUOYANG_V3.safe_body(_current_scene.scene_id,spawn*LUOYANG_V3.SIZE): return false
	if not _district_position_safe(spawn*_world_size,true): return false
	# Changes inside a room are read from the live managers, never rolled back.
	# Dirty return updates current task state without a second GPU/static setup.
	if _resident_world_state!=_resident_state_now():
		if SceneRouter.RESIDENT_CITY.extended_enabled():
			if not await _resident_refresh_dynamic(): return false
		else:
			await _setup_scene(_current_scene,spawn,true)
		if not is_inside_tree() or not _resident_parked or not get_field_loading_state().complete: return false
	_resident_world_state=_resident_state_now()
	_player.position=spawn*_world_size
	_update_dynamic_occluders(spawn,true); _snap_camera_to_player()
	_refresh_gold(); _refresh_quest_panel()
	_on_field_equipment_changed(Equipment.Slot.WEAPON,&"")
	await get_tree().physics_frame
	if not is_inside_tree() or not _resident_parked or not is_instance_valid(_player): return false
	var shape:=_player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or not shape.shape is RectangleShape2D or (shape.shape as RectangleShape2D).size!=CITY3_MOTION_GUARD.BODY or shape.disabled or not _is_inside_walkable_screen(_player.global_position): return false
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.collision_mask=_player.collision_mask; query.exclude=[_player.get_rid()]
	query.collide_with_areas=false
	return get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()


func _release_world_travel_minimap() -> void:
	if is_instance_valid(_world_travel_minimap):
		_world_travel_minimap.call("release")
		_world_travel_minimap.get_parent().remove_child(_world_travel_minimap)
		_world_travel_minimap.queue_free()
	_world_travel_minimap = null


func _setup_world_travel_minimap(scene: SceneScript) -> void:
	if not SceneRouter.is_world_map_scene(scene.scene_id) or not is_instance_valid(_primary_hud):
		return
	var minimap: Control = WORLD_TRAVEL_MINIMAP.new()
	minimap.name = "WorldTravelMinimap"
	_primary_hud.add_child(minimap)
	if not minimap.call("configure", scene, _player, _world_camera, world_container):
		minimap.queue_free()
		return
	_world_travel_minimap = minimap


func _is_gate_fortification_scene() -> bool:
	if HARBOUR_LIFE.bound(_current_scene): return _harbour_gate_visual_scene!=null and LUOYANG_V3.is_v3(_current_scene)
	return GATE_FORTIFICATION.bound(_current_scene) and LUOYANG_V3.is_v3(_current_scene)

func _is_enclosure_fade_runtime() -> bool:
	return _v14_modular_overlap != null and _v14_modular_overlap.get_script() in [CITY_ENCLOSURE_FADE,GATE_FORTIFICATION_FADE,MARKET_ENRICHMENT_FADE,ASSEMBLED_FADE,ASSEMBLED_CITY_FADE,HARBOUR_FADE,YAMEN_ANNEX_FADE,TEMPLE_FADE,DISTRICT_FADE]

func _release_district_session() -> void:
	if _district_session!=null:
		_district_last_receipt=_district_session.state()
		_district_session.release()
	_district_session=null

func _district_position_safe(foot: Vector2,full: bool=false) -> bool:
	return _current_scene==null or not DISTRICT_LIFE.requested(_current_scene.scene_id) or (_district_session!=null and _district_session.safe_foot(foot,full))

func _district_setup_owned(revision: int,session: RefCounted,scene: SceneScript,loading_token: int) -> bool:
	return is_inside_tree() and revision==_city3_motion_revision and session==_district_session and scene==_current_scene and loading_token==LoadingManager._external_token

func get_district_life_state() -> Dictionary:
	var out: Dictionary=_district_session.state() if _district_session!=null else _district_last_receipt.duplicate(true)
	out["active"]=_district_session!=null; out["npcs"]=[]
	for npc: NPCNode in _npc_nodes:
		if not is_instance_valid(npc) or not npc.npc_id.begins_with("district_life_"): continue
		out.npcs.append({"id":npc.npc_id,"instance_id":npc.get_instance_id(),"position":npc.position,"frame":npc.sprite.frame,"hframes":npc.sprite.hframes,"walk_active":npc._walk_texture!=null and npc.sprite.texture==npc._walk_texture,"ground_anchored":npc._ground_anchored,"movement_mode":npc.movement_mode,"interaction_monitoring":npc.interact_area.monitoring})
	return out

func _release_temple_session() -> void:
	if _temple_session!=null:
		_temple_session.release()
		_temple_last_receipt=_temple_session.state()
	_temple_session=null

func get_temple_assembly_state() -> Dictionary:
	return _temple_session.state() if _temple_session!=null else _temple_last_receipt.duplicate(true)

func _temple_setup_owned(revision: int,session: RefCounted,scene: SceneScript,loading_token: int) -> bool:
	return is_inside_tree() and revision==_city3_motion_revision and session==_temple_session and scene==_current_scene and loading_token==LoadingManager._external_token

func _temple_setup_failed(session: RefCounted) -> void:
	if session!=_temple_session: return
	_field_loading_failed=true; _field_loading_complete=false; _scene_rebuilding=false
	_field_loading_stage="古寺来源或几何校验失败"
	push_error("[Field] Temple assembly refused: "+String(session.error))
	_release_temple_session()

func get_harbour_life_state() -> Dictionary:
	var state: Dictionary={"receipt":_harbour_crowd_receipt.duplicate(true),"npcs":[]}
	for npc: NPCNode in _npc_nodes:
		if not is_instance_valid(npc) or not npc.npc_id.begins_with("harbour_life_"): continue
		state.npcs.append({"id":npc.npc_id,"position":npc.position,"instance_id":npc.get_instance_id(),"frame":npc.sprite.frame,"hframes":npc.sprite.hframes,"walk_active":npc._walk_texture!=null and npc.sprite.texture==npc._walk_texture,"ground_anchored":npc._ground_anchored,"movement_mode":npc.movement_mode,"interaction_monitoring":npc.interact_area.monitoring})
	return state

func _release_gate_moat_runtime() -> void:
	if _gate_moat_runtime != null: _gate_moat_runtime.release()
	_gate_moat_runtime = null

func get_gate_fortification_state() -> Dictionary:
	return _gate_moat_runtime.get_debug_state() if _gate_moat_runtime != null else {"configured":false,"scope":"NO_GATE_MODULE"}

func _release_city_building_fade() -> void:
	# Other city/world overlap implementations retain their original lifecycle.
	if _v14_modular_overlap != null and _is_enclosure_fade_runtime():
		_v14_modular_overlap.call("release")
		_v14_modular_overlap = null


func _on_field_cutscene_requested(cutscene_id: StringName) -> void:
	if cutscene_id == &"zhao_wounded_escape":
		_play_zhao_wounded_escape()


func _prepare_zhao_escape_actor() -> void:
	if _current_scene == null or _current_scene.scene_id != &"ch1_s3_ruin_inner":
		return
	if is_instance_valid(_zhao_escape_actor):
		return
	var path := "res://art/sprites/battle/standard_v2/zhao_wuji/zhao_wuji_hit_02.png"
	if not ResourceLoader.exists(path):
		return
	_zhao_escape_actor = Sprite2D.new()
	_zhao_escape_actor.name = "ZhaoWujiWoundedCutscene"
	_zhao_escape_actor.texture = load(path) as Texture2D
	_zhao_escape_actor.position = _norm_to_screen(Vector2(0.50, 0.51))
	_zhao_escape_actor.scale = Vector2.ONE * 0.44
	_zhao_escape_actor.z_index = 70
	_actor_layer.add_child(_zhao_escape_actor)


func _play_zhao_wounded_escape() -> void:
	if _current_scene == null or _current_scene.scene_id != &"ch1_s3_ruin_inner":
		return
	if not is_instance_valid(_zhao_escape_actor):
		_prepare_zhao_escape_actor()
	if not is_instance_valid(_zhao_escape_actor) or not is_instance_valid(_player):
		SceneRouter.resolve_action("dialog:ch1_s3_ruin_after_escape")
		return
	_player.set_can_move(false)
	var player_start := _player.position
	var strike_target := player_start + Vector2(52.0, -6.0)
	var rush := create_tween()
	rush.tween_property(_zhao_escape_actor, "position", strike_target, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await rush.finished
	_player.sprite.modulate = Color(1.0, 0.46, 0.38, 1.0)
	var knockback := create_tween().set_parallel(true)
	knockback.tween_property(_player, "position", player_start + Vector2(-44.0, 34.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	knockback.tween_property(_player.sprite, "modulate", Color.WHITE, 0.42)
	await knockback.finished
	if GameState.player != null:
		GameState.player.hp = maxi(1, mini(GameState.player.hp, int(round(GameState.player.max_hp * 0.18))))
		GameState.player.mp = maxi(0, mini(GameState.player.mp, int(round(GameState.player.max_mp * 0.35))))
	_refresh_gold()
	var escape_target := _norm_to_screen(Vector2(0.50, 0.34))
	var escape := create_tween().set_parallel(true)
	escape.tween_property(_zhao_escape_actor, "position", escape_target, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	escape.tween_property(_zhao_escape_actor, "modulate:a", 0.0, 0.45).set_delay(0.40)
	await escape.finished
	_zhao_escape_actor.queue_free()
	_zhao_escape_actor = null
	GameState.set_flag(&"zhao_wuji_wounded_escape", true)
	GameState.set_flag(&"lengguyun_severely_wounded_ch1", true)
	GameState.set_flag(&"zhao_wuji_escape_cutscene_pending", false)
	_player.set_can_move(true)
	SceneRouter.resolve_action("dialog:ch1_s3_ruin_after_escape")


func _should_play_enter_dialog(scene: SceneScript) -> bool:
	if scene.on_enter_dialog == null:
		return false
	if not DialogPlayer.can_play_script(scene.on_enter_dialog):
		return false
	var require_flag := String(scene.on_enter_require_flag)
	if require_flag != "" and not _flag_truthy(require_flag):
		return false
	var flag := String(scene.on_enter_once_flag)
	return flag == "" or not _flag_truthy(flag)


func _mark_enter_dialog_played(scene: SceneScript) -> void:
	var flag := String(scene.on_enter_once_flag)
	if flag == "":
		return
	GameState.set_flag(StringName(flag), true)


func _open_system_menu() -> void:
	var existing := _system_ui_canvas_layer.get_node_or_null("SystemMenu") as SystemMenu
	if existing != null:
		if existing.visible:
			existing.close()
		else:
			_on_system_panel_opened()
			existing.open()
		return
	var menu := SYSTEM_MENU_SCENE.instantiate() as SystemMenu
	menu.name = "SystemMenu"
	_system_ui_canvas_layer.add_child(menu)
	menu.closed.connect(_on_system_panel_closed)
	_on_system_panel_opened()
	menu.open()


func _init_ui_canvas_layers() -> void:
	_hud_canvas_layer = UI_LAYER_POLICY.ensure_canvas_layer(
		self,
		&"HudCanvasLayer",
		UI_LAYER_POLICY.HUD_LAYER
	)
	_system_ui_canvas_layer = UI_LAYER_POLICY.ensure_canvas_layer(
		self,
		&"SystemUICanvasLayer",
		UI_LAYER_POLICY.SYSTEM_LAYER
	)
	for node in [
		hotspots_container,
		scene_title,
		system_btn,
		player_info,
		get_node_or_null("HUD"),
		get_node_or_null("QuestPanel"),
		hint_bar,
	]:
		UI_LAYER_POLICY.move_to_canvas(node, _hud_canvas_layer)


func _disable_gameplay_button_focus(root: Node) -> void:
	# Direction keys should move the player, not focus a HUD button that Space
	# can accidentally activate. Mouse clicks remain available with FOCUS_NONE.
	for child in root.get_children():
		if child is BaseButton:
			(child as BaseButton).focus_mode = Control.FOCUS_NONE
		if child.get_child_count() > 0:
			_disable_gameplay_button_focus(child)


func _load_scene(scene_id: StringName) -> SceneScript:
	var validated: Dictionary = SceneRouter.get_validated_field_transition(scene_id)
	if validated.has("scene"):
		return validated.scene if validated.scene is SceneScript else null
	var path: String=SceneRouter.field_scene_resource_path(scene_id)
	if path.is_empty(): return null
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is SceneScript:
			if TEMPLE_ASSEMBLY.requested(scene_id): return res if TEMPLE_ASSEMBLY.is_scene(res) else null
			if LUOYANG_V3.revision_room_known(scene_id): return res if LUOYANG_V3.revision_room_matches(res,scene_id) else null
			return LUOYANG_V3.resolve_scene(OUTSKIRTS.materialize(res))
	push_warning("[FieldWalkable] scene not found: %s" % path)
	return null


func get_field_loading_state() -> Dictionary:
	return {"complete":_field_loading_complete and not _scene_rebuilding and is_instance_valid(_player), "failed":_field_loading_failed, "progress":_field_loading_progress, "stage":_field_loading_stage, "scene_id":String(_current_scene.scene_id) if _current_scene != null else ""}


func get_field_loading_profile() -> Dictionary:
	var result: Dictionary = _field_loading_profile.duplicate(true)
	if result.is_empty(): return result
	result["setup_identity_current"] = _current_scene != null and result.get("scene_instance") == _current_scene.get_instance_id() and result.get("motion_revision") == _city3_motion_revision and result.get("Field_instance") == get_instance_id() and result.get("layout_instance") == (_current_scene.map_layout.get_instance_id() if _current_scene.map_layout != null else 0)
	result["same_live_transition"] = false
	if result.setup_identity_current:
		var live_token: int = SceneRouter.live_field_transition_token(_current_scene.scene_id)
		result["observed_live_transition_token"] = live_token
		result["same_live_transition"] = live_token > 0 and int(result.get("transition_token", 0)) > 0 and live_token == int(result.transition_token)
	result["fresh_source_validation_credit"] = false
	return result


func _field_loading_profile_clock() -> Dictionary:
	return {"usec":Time.get_ticks_usec(), "process_frame":Engine.get_process_frames(), "physics_frame":Engine.get_physics_frames()}


func _field_loading_profile_span(started: Dictionary, finished: Dictionary) -> Dictionary:
	return {"started_usec":started.usec, "finished_usec":finished.usec, "wall_usec":finished.usec-started.usec, "started_process_frame":started.process_frame, "finished_process_frame":finished.process_frame, "process_frames":finished.process_frame-started.process_frame, "started_physics_frame":started.physics_frame, "finished_physics_frame":finished.physics_frame, "physics_frames":finished.physics_frame-started.physics_frame, "wall_time_includes_existing_awaits":true}


func _field_loading_profile_begin(scene: SceneScript, revision: int, token: int, progressive: bool) -> void:
	_field_loading_profile = {"status":"COLLECTING", "profile_origin":"FIELD_SCENE_SETUP_NOT_WARM_RESUME", "records_warm_resume":false, "completed_setup_preserved_when_live_token_zero_not_relabelled_fresh":true, "Field_instance":get_instance_id(), "scene_id":String(scene.scene_id), "scene_instance":scene.get_instance_id(), "layout_instance":scene.map_layout.get_instance_id() if scene.map_layout != null else 0, "motion_revision":revision, "transition_token":token, "progressive":progressive, "setup_started":_field_loading_profile_clock(), "phases":{}, "phase_order":[]}
	if not _field_loading_ui_profile.is_empty():
		_field_loading_profile.phases["ready_ui"] = _field_loading_ui_profile.duplicate(true)
		_field_loading_profile.phase_order.append("ready_ui")
		_field_loading_ui_profile.clear()


func _field_loading_profile_record(label: String, started: Dictionary, revision: int, scene: SceneScript, processed: int = -1) -> void:
	if _field_loading_profile.get("status") != "COLLECTING" or scene == null or scene != _current_scene or revision != _city3_motion_revision or _field_loading_profile.get("motion_revision") != revision or _field_loading_profile.get("scene_instance") != scene.get_instance_id() or _field_loading_profile.get("layout_instance") != (scene.map_layout.get_instance_id() if scene.map_layout != null else 0) or _field_loading_profile.phases.has(label): return
	var row: Dictionary = _field_loading_profile_span(started, _field_loading_profile_clock())
	if processed >= 0: row["processed_objects"] = processed
	_field_loading_profile.phases[label] = row
	_field_loading_profile.phase_order.append(label)


func _setup_scene(scene: SceneScript, player_spawn_override: Variant = null, progressive: bool = false) -> void:
	if _culture_x != null: _culture_x.abort("scene_setup")
	_harbour_gate_visual_scene=null; _harbour_crowd_receipt={}
	if HARBOUR_LIFE.bound(scene) and scene.scene_id==&"ch4_s0_luoyang_gate":
		_harbour_gate_visual_scene=HARBOUR_LIFE.gate_visual_parent(scene)
		if _harbour_gate_visual_scene==null:
			_field_loading_failed=true; _field_loading_complete=false; push_error("[Field] Harbour original Gate visual source rejected"); return
	_functional_room_geometry={}
	if ASSEMBLED_ROOMS.is_room(scene) or FUNCTIONAL_INTERIORS.is_room(scene):
		_functional_room_geometry=ASSEMBLED_ROOMS.geometry_for(scene) if ASSEMBLED_ROOMS.is_room(scene) else FUNCTIONAL_INTERIORS.author_for(scene)
		if _functional_room_geometry.is_empty():
			_field_loading_failed=true; _field_loading_complete=false
			_field_loading_stage="室内来源校验失败"; push_error("[Field] Functional room author rejected"); return
	# Mandatory for this setup even if the Router cancels during an awaited job.
	var source_validation_scene_id: StringName = scene.scene_id
	var source_validation_token: int = SceneRouter.live_field_transition_token(source_validation_scene_id) if progressive else 0
	_release_world_v15_stream()
	_city3_motion_revision += 1
	var motion_revision := _city3_motion_revision
	_field_loading_profile_begin(scene, motion_revision, source_validation_token, progressive)
	_release_temple_session()
	_release_district_session()
	_release_city3_motion()
	_field_loading_complete = false
	_field_loading_failed = false
	_field_loading_progress = 0.0
	_field_loading_stage = "正在布置地图……"
	_scene_rebuilding = true
	_release_world_travel_minimap()
	_release_gate_moat_runtime()
	_release_city_building_fade()
	if is_instance_valid(_active_dialog_npc):
		_active_dialog_npc.end_conversation()
	_active_dialog_npc = null
	if is_instance_valid(_player):
		_player.set_can_move(false)
	_player = null
	var temple_session: RefCounted
	var temple_owner: Callable
	if TEMPLE_ASSEMBLY.is_scene(scene):
		temple_session=TEMPLE_ASSEMBLY.new(); _temple_session=temple_session
		temple_owner=_temple_setup_owned.bind(motion_revision,temple_session,scene,LoadingManager._external_token)
		_field_loading_stage="正在后台核验古寺来源……"
		if not await temple_session.prepare(scene,temple_owner):
			_temple_setup_failed(temple_session); return
		if not temple_owner.call(): return
		_functional_room_geometry=temple_session.data.geometry.duplicate(true)
	## 设置背景
	background.texture = null
	var bp := scene.background_path
	var uses_streamed_background := scene.streamed_background != null \
		and scene.streamed_background.has_chunks(scene.streamed_background.uses_desktop_variant())
	if not uses_streamed_background and bp != "" and ResourceLoader.exists(bp):
		var res: Resource = load(bp)
		if res is Texture2D:
			background.texture = res

	## 可行走地图以底图的原始比例定义世界矩形。设计尺寸只指定期望的
	## 横向范围；绝不能用独立 X/Y 缩放把 3:2 底图硬拉成横向长地图。
	var viewport_size := get_viewport_rect().size
	_viewport_size = viewport_size if viewport_size != Vector2.ZERO else Vector2(1920, 1080)
	_world_size = _resolve_world_size(scene, background.texture)
	if not _functional_room_geometry.is_empty(): _functional_room_geometry=ASSEMBLED_ROOMS.compile_geometry(_functional_room_geometry,_world_size) if ASSEMBLED_ROOMS.is_room(scene) else FUNCTIONAL_INTERIORS.compile_geometry(_functional_room_geometry,_world_size)
	if temple_session!=null and not TEMPLE_ASSEMBLY.anchors_clear(_functional_room_geometry,temple_session.data,_world_size):
		temple_session.error="TEMPLE_ORIGINAL_APPROACH_PORTAL_OR_DEFAULT_FOOT_BLOCKED"; _temple_setup_failed(temple_session); return
	_camera_scroll_enabled = _should_scroll_camera(scene)
	_camera_zoom = maxf(1.0, scene.camera_zoom)
	# Legacy helpers use this as the normalized-coordinate reference. It now
	# represents the full scrollable world rather than the visible viewport.
	_screen_size = _world_size
	# Single-screen maps often have a little extra height after uniform 16:9
	# cover scaling. Keep those maps centered and static; treating that crop as a
	# scrollable world makes vertical walking move the whole background.
	var scaled_world_size: Vector2 = _world_size * _camera_zoom
	if _camera_scroll_enabled:
		# Keep the physics world fixed. Camera2D follows the player below; moving
		# this container used to mix render-frame smoothing with physics children.
		_world_origin = Vector2.ZERO
		world_container.scale = Vector2.ONE
		world_container.position = Vector2.ZERO
	else:
		_world_origin = Vector2(
			(_viewport_size.x - scaled_world_size.x) * 0.5,
			(_viewport_size.y - scaled_world_size.y) * 0.5
		)
		world_container.scale = Vector2.ONE * _camera_zoom
		world_container.position = _world_origin
	background.visible = false

	if scene_title != null:
		scene_title.text = scene.display_name
	if _primary_hud != null:
		_primary_hud.set_scene_info(scene.display_name)

	## 隐藏经典模式的热点容器
	hotspots_container.visible = false

	## 清空世界容器
	for c in world_container.get_children():
		world_container.remove_child(c)
		c.queue_free()
	_world_camera = null
	_npc_nodes.clear()
	_exit_nodes.clear()
	_collision_bodies.clear()
	_trigger_areas.clear()
	_trigger_events_in_flight.clear()
	_outskirts_discovery_dialog_pending = false
	_outskirts_discovery_dialog_id = &""
	_encounter_distance = 0.0
	_encounter_locked = false
	_scene_object_nodes.clear()
	_v14_modular_overlap = null
	_v14_late_depth_refresh = null
	_occluder_nodes.clear()
	_actor_fade_zones.clear()
	_walkable_mask_image = null
	_walkable_mask_tiles.clear()
	_animated_prop_nodes.clear()
	_weather_nodes.clear()
	_walkability_blocker_footprints.clear()
	_create_runtime_layers()
	_spawn_world_background(scene)
	if temple_session!=null and (not temple_session.texture_matches(scene.background_path,background.texture) or not is_instance_valid(_world_background) or not temple_session.texture_matches(scene.background_path,_world_background.texture)):
		temple_session.error="TEMPLE_ACTUAL_GROUND_TEXTURE_CHANGED"; _temple_setup_failed(temple_session); return
	if progressive:
		_field_loading_progress = .1
		_field_loading_stage = "正在建立道路与地图边界……"
		await get_tree().process_frame
		if not is_inside_tree() or motion_revision != _city3_motion_revision: return

	var loading_phase_started: Dictionary = _field_loading_profile_clock()
	var visual_objects: Array = scene.scene_objects
	var blockers: Array = scene.collision_rects
	var interactions: Array = scene.trigger_zones
	var portals: Array = scene.exits
	if scene.map_layout != null:
		visual_objects = scene.map_layout.visual_objects
		blockers = scene.map_layout.blockers
		interactions = scene.map_layout.interactions
		portals = scene.map_layout.portals
		_actor_fade_zones.assign(scene.map_layout.actor_fade_zones)
		if not SceneRouter.WORLD_V15.is_v15(scene):
			_load_walkable_mask(scene.map_layout.walkable_mask_path)
			_load_walkable_mask_tiles(scene.map_layout.walkable_mask_tiles)
		_spawn_walkable_boundaries(scene.map_layout.walkable_regions)
		if interactions.is_empty() and portals.is_empty() and not scene.hotspots.is_empty():
			interactions = _legacy_hotspots_to_interactions(scene.hotspots)
			portals = _legacy_hotspots_to_portals(scene.hotspots)
	if scene.map_layout == null and not scene.hotspots.is_empty():
		interactions = _legacy_hotspots_to_interactions(scene.hotspots)
		portals = _legacy_hotspots_to_portals(scene.hotspots)
	# Keep original source-proven geometry independent of task render gating.
	if temple_session!=null:
		visual_objects=TEMPLE_ASSEMBLY.project_objects(temple_session.data,_world_size)
		if visual_objects.size()!=temple_session.data.placements.size():
			temple_session.error="TEMPLE_COMPONENT_PROJECTION_COUNT"; _temple_setup_failed(temple_session); return
	if ASSEMBLED_ROOMS.is_room(scene):
		visual_objects=ASSEMBLED_ROOMS.project_objects(scene,_world_size)
		if visual_objects.size()!=ASSEMBLED_ROOMS.prop_ids(scene).size() or visual_objects.is_empty():
			_field_loading_failed=true; _scene_rebuilding=false; push_error("[Field] Source-bound furniture projection count refused"); return
	var navigation_objects: Array=visual_objects
	_field_loading_profile_record("mask_and_layout", loading_phase_started, motion_revision, scene)
	loading_phase_started = _field_loading_profile_clock()
	var functional_portals: Dictionary=ELEVEN_ROOMS.project_portals(scene,portals) if ELEVEN_ROOMS.enabled() else FUNCTIONAL_INTERIORS.project_portals(scene,portals)
	if functional_portals.get("ok")!=true:
		_field_loading_failed=true; _scene_rebuilding=false
		push_error("[Field] Functional room exterior portal source rejected"); return
	portals=functional_portals.portals
	_field_loading_profile_record("portal_projection", loading_phase_started, motion_revision, scene)
	loading_phase_started = _field_loading_profile_clock()
	var runtime_npcs: Array=scene.npcs.duplicate(true)
	_city_tasks_receipt={"matched":false,"source_scene_id":String(scene.scene_id)}
	if String(scene.scene_id) in CITY_TASKS.IDS:
		navigation_objects=visual_objects.duplicate(true)
		var projected: Dictionary=TEMPLE_TASKS.project(scene,GameState.flags.duplicate(true),QuestManager.states.duplicate(true),interactions,visual_objects) if temple_session!=null else CITY_TASKS.project(scene,GameState.flags.duplicate(true),QuestManager.states.duplicate(true),interactions)
		if projected.get("ok")!=true:
			_field_loading_failed=true; _field_loading_stage="城市任务来源或摆放校验失败"; _scene_rebuilding=false
			_city_tasks_receipt={"matched":true,"error":String(projected.get("error","TASK_PROJECTION_REFUSED"))}
			push_error("[Field] Task projection refused: "+_city_tasks_receipt.error)
			if temple_session!=null:
				temple_session.error=_city_tasks_receipt.error; _temple_setup_failed(temple_session)
			return
		if LUOYANG_V3.owns_id(scene.scene_id) and not LUOYANG_V3._equal_value(LUOYANG_V3.object_solids(navigation_objects),LUOYANG_V3.object_solids(projected.visual_objects)):
			_field_loading_failed=true; _field_loading_stage="任务投影不得改变原碰撞"; _scene_rebuilding=false
			push_error("[Field] Task projection changed original physical solids"); return
		visual_objects=projected.visual_objects; interactions=projected.interactions; runtime_npcs=projected.npcs
		_city_tasks_receipt=projected.receipt.duplicate(true)
		_city_tasks_receipt["render_applied"]=true
		_city_tasks_receipt["original_scene_identity"]=scene.get_instance_id()
	if HARBOUR_LIFE.bound(scene):
		var crowd: Dictionary=HARBOUR_LIFE.crowd(scene)
		if crowd.get("ok")!=true:
			_field_loading_failed=true; _scene_rebuilding=false; push_error("[Field] Harbour crowd source/navigation rejected"); return
		runtime_npcs.append_array(crowd.npcs)
		_harbour_crowd_receipt=crowd.receipt.duplicate(true)
	_field_loading_profile_record("task_projection", loading_phase_started, motion_revision, scene)
	loading_phase_started = _field_loading_profile_clock()
	if DISTRICT_LIFE.requested(scene.scene_id):
		var district: RefCounted=DISTRICT_LIFE.new(); _district_session=district
		var district_owner: Callable=_district_setup_owned.bind(motion_revision,district,scene,LoadingManager._external_token)
		if not await district.prepare(scene,navigation_objects,district_owner):
			if _district_session!=district: return
			_field_loading_failed=true; _scene_rebuilding=false
			push_error("[Field] District life refused: "+String(district.error)); _release_district_session(); return
		if not district_owner.call(): return
		visual_objects=district.render_objects(visual_objects)
		navigation_objects=district.navigation_objects(navigation_objects)
		if visual_objects.is_empty() or navigation_objects.is_empty():
			_field_loading_failed=true; _scene_rebuilding=false; push_error("[Field] District object projection refused"); _release_district_session(); return
		runtime_npcs.append_array(district.npcs())
	_field_loading_profile_record("district_prepare_and_projection", loading_phase_started, motion_revision, scene)

	## 生成地图边界碰撞（防止走出屏幕）
	_spawn_map_bounds()

	## 生成模块化场景元素
	await _spawn_scene_objects(visual_objects, progressive)
	if not is_inside_tree() or motion_revision != _city3_motion_revision: return
	if WORLD_V15_STREAM.applies(scene) and _field_loading_failed:
		_scene_rebuilding=false; return
	if temple_session!=null and _field_loading_failed:
		if temple_session.error.is_empty(): temple_session.error="TEMPLE_COMPONENT_RUNTIME_REJECTED"
		_temple_setup_failed(temple_session); return
	if HARBOUR_LIFE.bound(scene) and scene.scene_id==&"ch4_s2_canal_docks":
		var water_patch: Sprite2D=HARBOUR_LIFE.WATER.install(_visual_layer,scene,_world_size)
		if water_patch==null:
			_field_loading_failed=true; _scene_rebuilding=false
			push_error("[Field] Same-capture water packet refused"); return
		_scene_object_nodes.append(water_patch)
	if scene.map_layout != null:
		_spawn_dynamic_occluders(scene.map_layout.occluders)
	_rebuild_walkability_collision_entries(blockers, navigation_objects)
	if scene.map_layout != null:
		_spawn_travel_routes(scene.map_layout.travel_routes)
	if _is_gate_fortification_scene():
		if _gate_moat_runtime == null or not _gate_moat_runtime.configure(_visual_layer,navigation_objects):
			_field_loading_failed = true
			_field_loading_stage = "门桥水岸模块初始化失败"
			_scene_rebuilding = false
			_release_gate_moat_runtime()
			push_error("[Field] Gate module rejected; no player created")
			return

	## 生成背景上方的程序化小动画（旗子、炊烟、炉火等）
	_spawn_animated_props(scene.animated_props)
	_spawn_active_weather(scene)

	## 生成 NPC
	runtime_npcs.append_array(BountyManager.get_scene_npcs(scene.scene_id))
	if CULTURE_X.requested(scene.scene_id):
		var culture: Dictionary = CULTURE_X.project_rows(scene.scene_id, runtime_npcs, GameState.flags, QuestManager.states)
		if culture.get("ok") != true:
			_field_loading_failed = true; _scene_rebuilding = false
			push_error("[Field] Cultural resident projection refused: " + String(culture.get("error", "UNKNOWN")))
			return
		runtime_npcs = culture.npcs
	_spawn_npcs(runtime_npcs)
	if CULTURE_X.requested(scene.scene_id):
		var configured: Dictionary = _culture_x.configure_actors()
		if configured.get("ok") != true:
			_field_loading_failed = true; _scene_rebuilding = false
			push_error("[Field] Cultural actor ownership refused: " + String(configured.get("error", "UNKNOWN")))
			return

	## 生成出口
	_spawn_exits(portals)

	## 生成静态障碍和剧情触发区
	_spawn_collision_rects(blockers)
	if _field_loading_failed: _scene_rebuilding=false;return
	_spawn_trigger_zones(interactions)
	if progressive:
		_field_loading_progress = .9
		_field_loading_stage = "正在校验碰撞与出生点……"
		await get_tree().process_frame
		if not is_inside_tree() or motion_revision != _city3_motion_revision: return
	if scene.has_meta("city_enclosure_manifest_sha"):
		var motion_guard: RefCounted
		if LUOYANG_V3.is_v3(scene):
			if progressive: _field_loading_stage = "正在后台建立道路碰撞索引……"
			motion_guard = await _build_city3_motion_guard(_walkable_mask_image, navigation_objects, progressive)
		if not is_inside_tree() or motion_revision != _city3_motion_revision: return
		_city3_motion_guard = motion_guard
		if _city3_motion_guard == null:
			_field_loading_failed = true
			_field_loading_stage = "道路碰撞初始化失败"
			_scene_rebuilding = false
			push_error("[Field] Bound city motion geometry rejected; no player created")
			return
		_city3_motion_scene = scene

	if source_validation_token > 0:
		var loading_final_started: Dictionary = _field_loading_profile_clock()
		_field_loading_stage = "正在后台复核地图来源……"
		var source_verified: bool = await SceneRouter.finalize_field_transition_sources(source_validation_scene_id, source_validation_token)
		if not is_inside_tree() or motion_revision != _city3_motion_revision: return
		if not source_verified:
			_field_loading_failed = true
			_field_loading_stage = "地图来源复核失败"
			_scene_rebuilding = false
			_release_city3_motion()
			push_error("[Field] Final transition source identity rejected; no player created")
			return
		_field_loading_profile_record("complete_source_final_await", loading_final_started, motion_revision, scene)

	if temple_session!=null:
		_field_loading_stage="正在后台复核古寺来源……"
		if not await temple_session.finalize(scene,temple_owner):
			_temple_setup_failed(temple_session); return
		if not temple_owner.call(): return
	if _district_session!=null and not _district_session.finalize(scene):
		_field_loading_failed=true; _scene_rebuilding=false; push_error("[Field] District final source lease refused"); _release_district_session(); return
	if ELEVEN_ROOMS.is_room(scene) and not ELEVEN_ROOMS.finalize_setup(scene):
		_field_loading_failed=true; _scene_rebuilding=false; _field_loading_stage="室内来源末次复核失败"
		push_error("[Field] New assembled room final source/storage refused; no player created"); return
	# One AP-owned, flat source-bound life/street layer; no new NAV or body.
	if String(scene.scene_id) in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s4_ancient_temple","luoyang_estate_riverside_20261021ai","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]:
		var loading_environment_started: Dictionary = _field_loading_profile_clock()
		var ap_environment: Variant=load("res://scripts/city/luoyang_environment_layer_20261022ap.gd")
		var ap_owner: Callable=func() -> bool: return is_inside_tree() and motion_revision==_city3_motion_revision and _current_scene==scene and not _field_loading_failed
		var ap_layer: Dictionary=ap_environment.install(self,scene,world_container,_world_size,ap_owner)
		if ap_layer.get("ok")!=true:
			_field_loading_failed=true;_scene_rebuilding=false;_field_loading_stage="城区环境来源初始化失败"
			push_error("[Field] AP environment refused: "+String(ap_layer.get("error","UNKNOWN")));return
		_field_loading_profile_record("environment_install", loading_environment_started, motion_revision, scene)
	## 生成玩家（最后生成，确保在最上层）
	var spawn: Vector2 = _resolve_player_spawn(scene, player_spawn_override)
	if scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]:
		var family: Variant=load("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
		if not family.matches(scene) or not family.safe_body(scene.scene_id,spawn*_world_size) or not family.validation_finish():
			_field_loading_failed=true;_scene_rebuilding=false;push_error("[Field] AP final whole native/body/source refused; no player created");return
	if not _district_position_safe(spawn*_world_size,true):
		_field_loading_failed=true; _scene_rebuilding=false; push_error("[Field] District additive full-body spawn rejected"); return
	if not _functional_room_geometry.is_empty() and not _interior_safe_position(spawn*_world_size,true):
		_field_loading_failed=true; _scene_rebuilding=false
		push_error("[Field] Functional room full native body spawn rejected"); return
	if LUOYANG_V3.is_v3(scene) and not LUOYANG_V3.safe_body(scene.scene_id, spawn * LUOYANG_V3.SIZE):
		_scene_rebuilding = false
		push_error("[Field] Luoyang ordinary-body spawn rejected; no player created")
		return
	var world_contract: Variant = SceneRouter.layered_world_contract(scene)
	if world_contract != null and not world_contract.safe_foot(scene, spawn):
		# Damaged/missing shipped nav must fail closed, not spawn on an unchecked
		# authored point. Router validates before entry; this is a final safeguard.
		_scene_rebuilding = false
		push_error("[Field] layered world spawn rejected; runtime player creation aborted")
		return
	if OUTSKIRTS.is_native(scene) and not OUTSKIRTS.safe_foot(scene, spawn):
		_scene_rebuilding = false
		push_error("[Field] local outskirts spawn rejected; complete feet clearance unavailable")
		return
	if is_instance_valid(_world_v15_stream):
		_field_loading_stage="正在布置视野内建筑……"
		var stream: Node=_world_v15_stream
		var primed: bool=await stream.call("prime",spawn*_world_size)
		if not is_inside_tree() or motion_revision!=_city3_motion_revision: return
		if stream!=_world_v15_stream or not primed:
			_field_loading_failed=true; _scene_rebuilding=false
			push_error("[Field] World visible window failed closed"); return
	_spawn_player(spawn)
	_setup_world_camera()
	if is_instance_valid(_world_v15_stream): _world_v15_stream.call("bind_view",_player,_world_camera)
	if is_instance_valid(_background_streamer):
		_background_streamer.bind_view(_player, _world_camera, _viewport_size, _camera_zoom)
	_update_dynamic_occluders(spawn, true)
	SceneRouter.set_field_return_spawn(spawn)
	_last_occlusion_sample = spawn
	_last_return_spawn_sample = spawn
	_scene_rebuilding = false
	_snap_camera_to_player()
	_setup_world_travel_minimap(scene)
	_field_loading_complete = is_instance_valid(_player)
	_field_loading_progress = 1.0
	_field_loading_stage = "地图与入口已就绪"
	_field_loading_profile_record("setup_total", _field_loading_profile.setup_started, motion_revision, scene)
	if _field_loading_profile.get("motion_revision") == motion_revision and _field_loading_profile.get("scene_instance") == scene.get_instance_id():
		_field_loading_profile["status"] = "READY" if _field_loading_complete else "INCOMPLETE"


func _build_city3_motion_guard(mask: Image, visual_objects: Array, progressive: bool) -> RefCounted:
	var guard: RefCounted = CITY3_MOTION_GUARD.new()
	if not progressive or OS.has_feature("web"):
		if guard.call("configure", mask, visual_objects): return guard
		guard.call("release")
		return null
	if mask == null: return null
	var job := City3MotionJob.new()
	job.guard = guard
	job.mask = mask.duplicate() as Image
	job.visual_objects = visual_objects.duplicate(true)
	var task_id: int = WorkerThreadPool.add_task(job.run, false, "Luoyang motion prefix")
	if task_id < 0:
		guard.call("release")
		return null
	_city3_motion_job = job
	_city3_motion_task_id = task_id
	while _city3_motion_task_id == task_id and _city3_motion_job == job and not WorkerThreadPool.is_task_completed(task_id):
		await get_tree().process_frame
		if not is_inside_tree(): return null
	if _city3_motion_task_id != task_id or _city3_motion_job != job: return null
	WorkerThreadPool.wait_for_task_completion(task_id)
	_city3_motion_task_id = -1
	_city3_motion_job = null
	if job.succeeded: return guard
	guard.call("release")
	return null


func _release_city3_motion() -> void:
	# Join before releasing exclusive worker data, including rebuild/exit paths.
	if _city3_motion_task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(_city3_motion_task_id)
		_city3_motion_task_id = -1
		if _city3_motion_job != null: _city3_motion_job.guard.call("release")
	_city3_motion_job = null
	if _city3_motion_guard != null: _city3_motion_guard.call("release")
	_city3_motion_guard = null
	_city3_motion_scene = null


func _resolve_player_spawn(scene: SceneScript, player_spawn_override: Variant) -> Vector2:
	var authored_spawn: Vector2 = scene.player_spawn
	var candidate: Vector2 = player_spawn_override as Vector2 if player_spawn_override is Vector2 else authored_spawn
	if TEMPLE_ASSEMBLY.is_scene(scene):
		return candidate if TEMPLE_ASSEMBLY.safe_foot(_functional_room_geometry,candidate*_world_size,_world_size,true) else Vector2(INF,INF)
	if ASSEMBLED_ROOMS.is_room(scene):
		return candidate if ASSEMBLED_ROOMS.safe_foot(_functional_room_geometry,candidate*_world_size,_world_size,true) else Vector2(INF,INF)
	if not _functional_room_geometry.is_empty():
		# New scene defaults/door entries carry source-feet UV; actual remembered
		# room movement remains the legacy origin UV. Never apply +42 twice.
		var room_origin:=FUNCTIONAL_INTERIORS.origin_uv(authored_spawn*FUNCTIONAL_INTERIORS.SOURCE_SIZE,_world_size) if candidate==authored_spawn else candidate
		return room_origin if FUNCTIONAL_INTERIORS.safe_origin(_functional_room_geometry,room_origin*_world_size,_world_size,true) else Vector2(INF,INF)
	if LUOYANG_V3.is_v3(scene):
		var city_repaired: Variant = LUOYANG_V3.repair_spawn(scene.scene_id, candidate)
		return city_repaired if city_repaired is Vector2 else Vector2(INF, INF)
	if OUTSKIRTS.is_native(scene):
		var native_repaired: Variant = OUTSKIRTS.repair_spawn(scene, candidate)
		return native_repaired if native_repaired is Vector2 else Vector2(INF, INF)
	var world_contract: Variant = SceneRouter.layered_world_contract(scene)
	if world_contract != null:
		var safe: Variant = world_contract.repair_spawn(scene, candidate)
		if safe is Vector2:
			return safe
		push_error("[Field] layered world has no complete safe foot position")
		return authored_spawn
	# Migrate stale saves that placed Zhuwei arrivals on the upper-right roof lane.
	if scene.scene_id == &"ch1_s2_qingfeng" and candidate.x > 0.75 and candidate.y < 0.40:
		candidate = authored_spawn
	# Migrate the old South District spawn that was technically passable but
	# visually landed on the roof silhouette of the west-side cottage.
	if scene.scene_id == &"linxi_village_scrollmap" and candidate.x < 0.23 and candidate.y > 0.43 and candidate.y < 0.57:
		candidate = authored_spawn
	if candidate.is_finite() and _spawn_has_foot_clearance(scene, candidate):
		return candidate
	# Authored defaults, old saves and paired portal coordinates all go through
	# the same bounded local safety search. This prevents a scene from spawning
	# the actor on a baked table/roof merely because its single centre pixel was
	# once considered walkable.
	var repaired := _nearest_safe_spawn(scene, candidate if candidate.is_finite() else authored_spawn)
	if _spawn_has_foot_clearance(scene, repaired):
		return repaired
	if authored_spawn != candidate:
		repaired = _nearest_safe_spawn(scene, authored_spawn)
		if _spawn_has_foot_clearance(scene, repaired):
			return repaired
	push_warning("[Field] no safe local spawn found for %s; using authored fallback %s" % [scene.scene_id, authored_spawn])
	return authored_spawn


func _world_map_spawn_has_foot_clearance(scene: SceneScript, point: Vector2) -> bool:
	return _spawn_has_foot_clearance(scene, point)


func _spawn_has_foot_clearance(scene: SceneScript, point: Vector2) -> bool:
	if not _functional_room_geometry.is_empty() and scene==_current_scene:
		return _interior_safe_position(point*_world_size,true)
	if LUOYANG_V3.is_v3(scene): return LUOYANG_V3.safe_body(scene.scene_id, point * LUOYANG_V3.SIZE)
	if OUTSKIRTS.is_native(scene): return OUTSKIRTS.safe_foot(scene, point)
	if not point.is_finite() or point.x < 0.0 or point.y < 0.0 or point.x > 1.0 or point.y > 1.0:
		return false
	if not _is_normalized_spawn_walkable(scene, point):
		return false
	var logical_size := Vector2(scene.map_layout.design_size) if scene.map_layout != null else _screen_size
	if _walkable_mask_image != null:
		logical_size = Vector2(_walkable_mask_image.get_size())
	logical_size.x = maxf(1.0, logical_size.x)
	logical_size.y = maxf(1.0, logical_size.y)
	# The foot collision is deliberately sampled as an ellipse: wider than it is
	# tall, matching the field actor's ground contact instead of its full sprite.
	var clearance_px := Vector2(10.0, 6.0)
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var sample := point + Vector2(cos(angle) * clearance_px.x / logical_size.x, sin(angle) * clearance_px.y / logical_size.y)
		if sample.x < 0.0 or sample.y < 0.0 or sample.x > 1.0 or sample.y > 1.0 or not _is_normalized_spawn_walkable(scene, sample):
			return false
	return true


func _nearest_safe_spawn(scene: SceneScript, candidate: Vector2) -> Vector2:
	var logical_size := Vector2(scene.map_layout.design_size) if scene.map_layout != null else _screen_size
	if _walkable_mask_image != null:
		logical_size = Vector2(_walkable_mask_image.get_size())
	logical_size.x = maxf(1.0, logical_size.x)
	logical_size.y = maxf(1.0, logical_size.y)
	var origin := candidate.clamp(Vector2.ZERO, Vector2.ONE) * logical_size
	# Keep repairs local. A bad doorway must never teleport the player across the
	# map; data validation will still expose an entrance with no nearby safe spot.
	var max_radius := mini(192, int(ceil(maxf(logical_size.x, logical_size.y) * 0.10)))
	for radius in range(4, max_radius + 1, 4):
		var samples := maxi(12, int(ceil(TAU * float(radius) / 6.0)))
		for index in range(samples):
			var point := (origin + Vector2.from_angle(TAU * float(index) / float(samples)) * float(radius)) / logical_size
			if _spawn_has_foot_clearance(scene, point):
				return point
	return candidate


func _nearest_world_map_road_spawn(scene: SceneScript, candidate: Vector2) -> Vector2:
	# Old saves and remembered paired returns contain pre-survey coordinates.
	# Concentric pixel rings keep the arrival near its old location instead of
	# sending the player across the entire world to the default village spawn.
	# This runs once on scene entry, never in the movement/animation hot path.
	var size := Vector2(_walkable_mask_image.get_size())
	var origin := candidate.clamp(Vector2.ZERO, Vector2.ONE) * size
	for radius in range(4, int(size.length()) + 4, 4):
		var samples := maxi(8, int(ceil(TAU * float(radius) / 4.0)))
		for index in range(samples):
			var point := (origin + Vector2.from_angle(TAU * float(index) / float(samples)) * float(radius)) / size
			if _world_map_spawn_has_foot_clearance(scene, point):
				return point
	return scene.player_spawn


func _is_normalized_spawn_walkable(scene: SceneScript, normalized_pos: Vector2) -> bool:
	if scene.map_layout == null:
		return true
	var is_inside := _is_walkable_by_mask(normalized_pos)
	if _walkable_mask_image == null and _walkable_mask_tiles.is_empty():
		for region in scene.map_layout.walkable_regions:
			if Geometry2D.is_point_in_polygon(normalized_pos, region):
				is_inside = true
				break
	if not is_inside:
		return false
	for footprint in _walkability_blocker_footprints:
		if footprint.has_point(normalized_pos):
			return false
	return true


func _legacy_hotspots_to_interactions(hotspots: Array) -> Array:
	var result: Array = []
	for index in hotspots.size():
		var source: Dictionary = hotspots[index]
		var action: String = String(source.get("action", ""))
		if action.is_empty() or action.begins_with("scene:") or action == "world_map":
			continue
		result.append({
			"id": "legacy_hotspot_%d" % index,
			"pos": Vector2(float(source.get("pos_x", 0.5)), float(source.get("pos_y", 0.5))),
			"size": Vector2(0.11, 0.12),
			"action": action,
			"activation": "interact",
			"require_flag": String(source.get("require_flag", "")),
			"hide_flag": String(source.get("hide_flag", "")),
		})
	return result


func _legacy_hotspots_to_portals(hotspots: Array) -> Array:
	var result: Array = []
	for index in hotspots.size():
		var source: Dictionary = hotspots[index]
		var action: String = String(source.get("action", ""))
		if not action.begins_with("scene:") and action != "world_map":
			continue
		var target_scene := action.trim_prefix("scene:") if action.begins_with("scene:") else ""
		if target_scene.is_empty() and action != "world_map":
			continue
		var portal := {
			"id": "legacy_portal_%d" % index,
			"pos": Vector2(float(source.get("pos_x", 0.5)), float(source.get("pos_y", 0.5))),
			"size": Vector2(0.13, 0.14),
			"label": String(source.get("label", "前往下一处")),
			"require_flag": String(source.get("require_flag", "")),
			"hide_flag": String(source.get("hide_flag", "")),
		}
		if action == "world_map":
			portal["action"] = "world_map"
		else:
			portal["target_scene"] = target_scene
			portal["target_pos"] = Vector2(0.12, 0.75)
		result.append(portal)
	return result

	## 操作提示已移除（不用底部提示条）


func _create_runtime_layers() -> void:
	_visual_layer = Node2D.new()
	_visual_layer.name = "VisualLayer"
	_collision_layer = Node2D.new()
	_collision_layer.name = "CollisionLayer"
	_interaction_layer = Node2D.new()
	_interaction_layer.name = "InteractionLayer"
	_portal_layer = Node2D.new()
	_portal_layer.name = "PortalLayer"
	_portal_layer.z_index = 1100 if SceneRouter.WORLD_V15.is_v15(_current_scene) else 500
	_actor_layer = Node2D.new()
	_actor_layer.name = "ActorLayer"
	_actor_layer.z_index = 20
	# Avoid whole-layer Y sorting on every vertical movement tick. Manual depth
	# updates below preserve the same front/back result at much lower cost.
	_actor_layer.y_sort_enabled = false
	_foreground_layer = Node2D.new()
	_foreground_layer.name = "ForegroundLayer"
	_foreground_layer.z_index = 400
	var layers: Array[Node2D] = [_visual_layer, _collision_layer, _interaction_layer, _actor_layer, _portal_layer, _foreground_layer]
	for layer in layers:
		world_container.add_child(layer)


func _spawn_world_background(scene: SceneScript) -> void:
	_world_background = null
	_background_streamer = null
	if scene.streamed_background != null:
		var prefer_desktop := scene.streamed_background.uses_desktop_variant()
		if scene.streamed_background.has_chunks(prefer_desktop):
			_background_streamer = BackgroundChunkStreamer.new()
			_background_streamer.name = "WorldBackgroundChunks"
			_background_streamer.configure(scene.streamed_background, prefer_desktop)
			world_container.add_child(_background_streamer)
			return
	var path := scene.background_path
	if path.is_empty() or not ResourceLoader.exists(path):
		background.visible = true
		return
	var texture := load(path) as Texture2D
	if texture == null:
		background.visible = true
		return
	_world_background = Sprite2D.new()
	_world_background.name = "WorldBackground"
	_world_background.texture = texture
	# Large painted backgrounds scroll at non-integer screen positions under a
	# smoothed Camera2D. Linear filtering prevents nearest-neighbour shimmer;
	# actor sprites keep the project-wide nearest setting.
	_world_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_world_background.centered = false
	_world_background.position = Vector2.ZERO
	_world_background.z_index = -1000
	var uniform_scale := _world_size.x / maxf(1.0, float(texture.get_width()))
	_world_background.scale = Vector2.ONE * uniform_scale
	world_container.add_child(_world_background)


func _resolve_world_size(scene: SceneScript, texture: Texture2D) -> Vector2:
	if scene.streamed_background != null and scene.streamed_background.logical_size.x > 0 and scene.streamed_background.logical_size.y > 0:
		return Vector2(scene.streamed_background.logical_size)
	if texture == null:
		return _viewport_size
	if scene.map_layout != null and scene.map_layout.display_at_native_size and not scene.map_layout.fill_viewport:
		return Vector2(texture.get_width(), texture.get_height())
	var requested_width := _viewport_size.x
	if scene.map_layout != null:
		requested_width = maxf(requested_width, float(scene.map_layout.design_size.x))
	var uniform_scale := requested_width / maxf(1.0, float(texture.get_width()))
	var world_size := Vector2(texture.get_width(), texture.get_height()) * uniform_scale
	if world_size.y < _viewport_size.y:
		uniform_scale = _viewport_size.y / maxf(1.0, float(texture.get_height()))
		world_size = Vector2(texture.get_width(), texture.get_height()) * uniform_scale
	return world_size


func _should_scroll_camera(scene: SceneScript) -> bool:
	if scene.map_layout == null:
		return false
	# A map authored wider/taller than the viewport is a deliberate exploration
	# map. A 1536x1024 single-screen map only gains height from cover scaling and
	# should stay fixed in place.
	var design_size := Vector2(scene.map_layout.design_size)
	return design_size.x > _viewport_size.x * 1.05 or design_size.y > _viewport_size.y * 1.05


func _process(delta: float) -> void:
	if _scene_rebuilding or not is_instance_valid(_player) or not _camera_scroll_enabled or is_instance_valid(_world_camera):
		return
	var target_position := _camera_target_position()
	var smoothing_weight := 1.0 - exp(-18.0 * maxf(delta, 0.0))
	var smoothed := world_container.position.lerp(target_position, smoothing_weight)
	if smoothed.distance_squared_to(target_position) <= 0.25:
		smoothed = target_position
	# Round only the final render transform. Smoothing the physics-step player
	# movement first prevents the former 4-5 pixel camera jumps on large maps.
	var render_position := smoothed.round()
	if world_container.position != render_position:
		world_container.position = render_position


func _camera_target_position() -> Vector2:
	var visible_world_size: Vector2 = _viewport_size / _camera_zoom
	var max_offset := Vector2(
		maxf(0.0, _world_size.x - visible_world_size.x),
		maxf(0.0, _world_size.y - visible_world_size.y)
	)
	var target := _player.position - visible_world_size * 0.5
	var offset := Vector2(
		clampf(target.x, 0.0, max_offset.x),
		clampf(target.y, 0.0, max_offset.y)
	)
	# Keep the large background on whole pixels. Sub-pixel texture movement made
	# vertical camera tracking look noticeably less stable than horizontal motion.
	return _world_origin - (offset * _camera_zoom)


func _snap_camera_to_player() -> void:
	if not _camera_scroll_enabled or not is_instance_valid(_player):
		return
	if is_instance_valid(_world_camera):
		_world_camera.reset_smoothing()
		return
	world_container.position = _camera_target_position().round()


func _setup_world_camera() -> void:
	if not _camera_scroll_enabled or not is_instance_valid(_player):
		return
	var camera := Camera2D.new()
	camera.name = "WorldCamera"
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE * _camera_zoom
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = roundi(_world_size.x)
	camera.limit_bottom = roundi(_world_size.y)
	# Direct tracking avoids compounding player interpolation with camera
	# interpolation, the source of the remaining drag/stutter on long scenes.
	var use_smoothing := false
	camera.limit_smoothed = use_smoothing
	camera.position_smoothing_enabled = use_smoothing
	camera.position_smoothing_speed = 20.0
	_player.add_child(camera)
	camera.make_current()
	_world_camera = camera


func _spawn_walkable_boundaries(regions: Array[PackedVector2Array]) -> void:
	# Player movement is already constrained by _is_inside_walkable_screen(),
	# which correctly evaluates the union of every authored road region. Turning
	# each polygon outline into a physical wall also creates invisible walls where
	# two valid regions touch or overlap, so only actual scene objects/blockers own
	# physics collision.
	for index in regions.size():
		if regions[index].size() < 3:
			push_warning("[FieldWalkable] walkable region %d has fewer than 3 points" % index)



func _spawn_map_bounds() -> void:
	## 在地图四周创建 StaticBody2D 边界，防止玩家走出画面
	var bounds: StaticBody2D = StaticBody2D.new()

	bounds.name = "MapBounds"
	_collision_layer.add_child(bounds)

	var margin: float = 20.0
	var w: float = _screen_size.x
	var h: float = _screen_size.y

	# 上边界
	_collider(bounds, Vector2(w / 2, -margin), Vector2(w + margin * 2, margin * 2))
	# 下边界
	_collider(bounds, Vector2(w / 2, h + margin), Vector2(w + margin * 2, margin * 2))
	# 左边界
	_collider(bounds, Vector2(-margin, h / 2), Vector2(margin * 2, h + margin * 2))
	# 右边界
	_collider(bounds, Vector2(w + margin, h / 2), Vector2(margin * 2, h + margin * 2))


func _collider(parent: Node, pos: Vector2, size: Vector2) -> void:
	var c: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	c.shape = shape
	c.position = pos
	parent.add_child(c)


func _spawn_player(spawn_norm: Vector2) -> void:
	var pos: Vector2 = Vector2(
		spawn_norm.x * _screen_size.x,
		spawn_norm.y * _screen_size.y
	)
	var player_instance: Node = PLAYER_SCENE.instantiate()
	if not player_instance is Player:
		push_error("[Field] 玩家场景根节点必须是 Player")
		if player_instance != null:
			player_instance.queue_free()
		return
	var player: Player = player_instance as Player
	if player == null:
		push_error("[Field] 玩家节点实例化失败")
		player_instance.queue_free()
		return
	if _actor_layer == null or not is_instance_valid(_actor_layer):
		push_error("[Field] 角色层不存在，无法生成玩家")
		player.queue_free()
		return
	player.name = "Player"
	_actor_layer.add_child(player)
	player.position = pos
	_player = player
	if SceneRouter.WORLD_V15.is_v15(_current_scene) or LUOYANG_V3.is_v3(_current_scene):
		for zone: ExitZone in _exit_nodes:
			if zone.has_method("bind_doorway_player"): zone.call("bind_doorway_player", player)
	if _v14_modular_overlap != null:
		_v14_modular_overlap.add_actor(player)
	if _current_scene != null and _current_scene.map_layout != null:
		_player.set_movement_constraint(_is_inside_walkable_screen)

	if not _player.uses_directional_walk_sprites():
		## 旧占位逻辑：没有行走动画的 Player 才使用立绘贴图。
		var pp: String = GameState.player.portrait_path if GameState.player != null else ""

		if pp == "":
			pp = "res://art/characters/protagonist_neutral.png"
		if ResourceLoader.exists(pp):
			var tex: Resource = load(pp)
			if tex is Texture2D and _player.sprite != null:
				_player.sprite.texture = tex
				var origin_size: float = maxf(float(tex.get_width()), float(tex.get_height()))
				_player.sprite.scale = Vector2.ONE * (96.0 / origin_size)

	_player.interacted.connect(_on_player_interacted)
	_player.moved.connect(_on_player_moved)
	if _current_scene != null:
		var visual_multiplier: float = _current_scene.player_visual_scale
		# Exact eight-city visual scope. Body/speed/scene data and foot anchor stay.
		if _current_scene.scene_id in [&"ch4_s0_luoyang_gate",&"ch4_s1_luoyang_yamen",&"ch4_s3_luoyang_market",&"ch4_s2_canal_docks",&"ch4_s4_ancient_temple",&"luoyang_estate_riverside_20261021ai",&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]:
			visual_multiplier *= 1.12
		_player.set_visual_scale_multiplier(visual_multiplier)
		if SceneRouter.is_world_map_scene(_current_scene.scene_id) or OUTSKIRTS.is_native(_current_scene):
			_player.set_world_travel_foot_anchor(true)
		else:
			_player.set_ground_anchored(_current_scene.actor_positions_are_feet)
	_player.set_weapon_style(_current_player_weapon_type())
	# Anchoring and weapon sprites can change the rendered foot offset. Sort only
	# after those visuals are final, including on the first frame after spawn.
	_update_actor_depth(_player)
	_last_encounter_position = _player.position


func _current_player_weapon_type() -> StringName:
	var weapon := Inventory.get_equipped(Equipment.Slot.WEAPON)
	if weapon != null and weapon.weapon_type != &"":
		return weapon.weapon_type
	return GameState.player.weapon_specialty if GameState.player != null else &"sword"


func _on_field_equipment_changed(slot: int, _item_id: StringName) -> void:
	if slot == Equipment.Slot.WEAPON and is_instance_valid(_player):
		_player.set_weapon_style(_current_player_weapon_type())


func _interior_safe_position(position: Vector2,full_samples: bool=false) -> bool:
	if TEMPLE_ASSEMBLY.is_scene(_current_scene): return TEMPLE_ASSEMBLY.safe_foot(_functional_room_geometry,position,_world_size,full_samples)
	return ASSEMBLED_ROOMS.safe_foot(_functional_room_geometry,position,_world_size,full_samples) if ASSEMBLED_ROOMS.is_room(_current_scene) else FUNCTIONAL_INTERIORS.safe_origin(_functional_room_geometry,position,_world_size,full_samples)

func _is_inside_walkable_screen(screen_pos: Vector2) -> bool:
	if is_instance_valid(_world_v15_stream) and not _world_v15_stream.call("visual_ready_for_motion",world_container.to_local(screen_pos)): return false
	if not _functional_room_geometry.is_empty():
		if not is_instance_valid(_player) or _scene_rebuilding: return false
		if TEMPLE_ASSEMBLY.is_scene(_current_scene): return TEMPLE_ASSEMBLY.safe_motion(_functional_room_geometry,_player.position,world_container.to_local(screen_pos),_world_size)
		if ASSEMBLED_ROOMS.is_room(_current_scene): return ASSEMBLED_ROOMS.safe_motion(_functional_room_geometry,_player.position,world_container.to_local(screen_pos),_world_size)
		return FUNCTIONAL_INTERIORS.safe_motion(_functional_room_geometry,_player.position,world_container.to_local(screen_pos),_world_size)
	if _current_scene != null and _current_scene.has_meta("city_enclosure_manifest_sha"):
		# Only the new bound city uses continuous motion. Legacy city3, world and
		# outskirts keep their prior contracts. Missing/stale guard fails closed.
		if not LUOYANG_V3.is_v3(_current_scene) or _city3_motion_scene != _current_scene or _city3_motion_guard == null or not is_instance_valid(_player) or not _player.is_inside_tree() or _player.is_queued_for_deletion() or _scene_rebuilding or not is_instance_valid(world_container) or not world_container.is_inside_tree(): return false
		var shape: CollisionShape2D = _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape == null or not shape.is_inside_tree() or shape.disabled or not shape.shape is RectangleShape2D or (shape.shape as RectangleShape2D).size != CITY3_MOTION_GUARD.BODY: return false
		var world_transform: Transform2D = world_container.global_transform
		var body_transform: Transform2D = shape.global_transform
		if world_transform.x != Vector2.RIGHT or world_transform.y != Vector2.DOWN or body_transform.x != Vector2.RIGHT or body_transform.y != Vector2.DOWN or body_transform.origin != _player.global_position: return false
		var point_clear: Callable = func(p: Vector2) -> bool: return LUOYANG_V3.safe_body(_current_scene.scene_id, p) and _district_position_safe(p)
		return _city3_motion_guard.call("safe_motion", world_container.to_local(_player.global_position), world_container.to_local(screen_pos), point_clear, _player.safe_margin)
	if LUOYANG_V3.is_v3(_current_scene): return LUOYANG_V3.safe_body(_current_scene.scene_id, world_container.to_local(screen_pos))
	if _current_scene == null or _current_scene.map_layout == null:
		return true
	if OUTSKIRTS.is_native(_current_scene):
		return OUTSKIRTS.safe_foot(_current_scene, world_container.to_local(screen_pos) / _world_size)
	var world_contract: Variant = SceneRouter.layered_world_contract(_current_scene)
	if world_contract != null:
		if not screen_pos.is_finite() or _world_size.x <= 0.0 or _world_size.y <= 0.0: return false
		# No clamping: off-map targets must fail rather than become boundary land.
		# New production world movement shares its complete 17-point feet contract
		# with load/spawn/return repair; ordinary maps retain the legacy path below.
		return world_contract.safe_foot(_current_scene, world_container.to_local(screen_pos) / _world_size)
	if _screen_size.x <= 0.0 or _screen_size.y <= 0.0:
		return true
	# Player supplies a global target. Native-size maps may be centered and
	# larger maps may be camera-shifted, so evaluate against world-local pixels.
	var world_pos := world_container.to_local(screen_pos)
	var normalized := Vector2(
		clampf(world_pos.x / _screen_size.x, 0.0, 1.0),
		clampf(world_pos.y / _screen_size.y, 0.0, 1.0)
	)
	if _walkable_mask_image != null or not _walkable_mask_tiles.is_empty():
		return _is_walkable_by_mask(normalized) and not _is_blocked_by_layout(normalized)
	for region in _current_scene.map_layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(normalized, region):
			return not _is_blocked_by_layout(normalized)
	return false


func _load_walkable_mask(path: String) -> void:
	_walkable_mask_image = null
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("[FieldWalkable] navigation mask is not a texture: %s" % path)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_warning("[FieldWalkable] navigation mask could not be read: %s" % path)
		return
	_walkable_mask_image = image


func _load_walkable_mask_tiles(entries: Array[Dictionary]) -> void:
	_walkable_mask_tiles.clear()
	for entry: Dictionary in entries:
		var path := String(entry.get("path", ""))
		var logical_rect: Rect2 = entry.get("logical_rect", Rect2())
		if path.is_empty() or logical_rect.size.x <= 0.0 or logical_rect.size.y <= 0.0:
			continue
		if not ResourceLoader.exists(path):
			# Missing staging terrain must stay impassable. The tile manifest
			# records which cells still await reviewed art and navigation.
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			push_warning("[FieldWalkable] navigation tile is not a texture: %s" % path)
			continue
		var image := texture.get_image()
		if image == null or image.is_empty():
			push_warning("[FieldWalkable] navigation tile could not be read: %s" % path)
			continue
		_walkable_mask_tiles.append({"logical_rect": logical_rect, "image": image})


func _is_walkable_by_mask(normalized_pos: Vector2) -> bool:
	if not _walkable_mask_tiles.is_empty():
		var logical_point := normalized_pos * _world_size
		for entry: Dictionary in _walkable_mask_tiles:
			var rect: Rect2 = entry["logical_rect"]
			if not rect.has_point(logical_point):
				continue
			var image: Image = entry["image"]
			var local := (logical_point - rect.position) / rect.size
			var tile_x := clampi(int(round(local.x * float(image.get_width() - 1))), 0, image.get_width() - 1)
			var tile_y := clampi(int(round(local.y * float(image.get_height() - 1))), 0, image.get_height() - 1)
			var tile_sample := image.get_pixel(tile_x, tile_y)
			return tile_sample.a >= 0.50 and maxf(tile_sample.r, maxf(tile_sample.g, tile_sample.b)) >= 0.50
		return false
	if _walkable_mask_image == null:
		return false
	var x := clampi(int(round(normalized_pos.x * float(_walkable_mask_image.get_width() - 1))), 0, _walkable_mask_image.get_width() - 1)
	var y := clampi(int(round(normalized_pos.y * float(_walkable_mask_image.get_height() - 1))), 0, _walkable_mask_image.get_height() - 1)
	var sample := _walkable_mask_image.get_pixel(x, y)
	return sample.a >= 0.50 and maxf(sample.r, maxf(sample.g, sample.b)) >= 0.50


func _is_blocked_by_layout(normalized_pos: Vector2) -> bool:
	if _current_scene == null or _current_scene.map_layout == null:
		return false
	# Constraint is evaluated at the player origin. Expand authored footprints a
	# little so the sprite cannot visually overlap baked roofs or gate beams.
	for footprint in _walkability_blocker_footprints:
		if footprint.has_point(normalized_pos):
			return true
	return false


func _rebuild_walkability_collision_entries(blockers: Array, visual_objects: Array) -> void:
	if not _functional_room_geometry.is_empty():
		_walkability_blocker_footprints.clear(); return
	if LUOYANG_V3.is_v3(_current_scene):
		# Authoritative city full rectangle + measured WORLD solids uses explicit
		# zero margin; never add the old .004 normalized whole-building grow.
		_walkability_blocker_footprints.clear()
		return
	# Build this once per scene. Player movement calls the constraint every physics
	# frame, so copying the full map layout there causes visible input lag.
	_walkability_blocker_footprints.clear()
	for entry in blockers:
		if entry is Dictionary:
			var blocker: Dictionary = entry as Dictionary
			var pos: Vector2 = blocker.get("pos", Vector2.ZERO)
			var size: Vector2 = blocker.get("size", Vector2.ZERO)
			# Large baked buildings need the default safety inset; small props such
			# as lantern pedestals can author a tighter one so the whole walkway
			# does not become an invisible wall.
			var margin: float = maxf(0.0, float(blocker.get("walkability_margin", 0.014)))
			_walkability_blocker_footprints.append(Rect2(pos - size * 0.5, size).grow(margin))
	for object_entry in visual_objects:
		if not object_entry is Dictionary:
			continue
		var object_data: Dictionary = object_entry as Dictionary
		if not object_data.has("collision_size"):
			continue
		var object_pos: Vector2 = object_data.get("pos", Vector2.ZERO) + object_data.get("collision_offset", Vector2.ZERO)
		var object_size: Vector2 = object_data.get("collision_size", Vector2.ZERO)
		# Visual props use a tight foot shadow footprint. The larger margin is
		# reserved for authored blockers; applying it to chests and interactables
		# made the player stop visibly short of the object.
		var object_margin := 0.0 if OUTSKIRTS.is_native(_current_scene) else 0.004
		_walkability_blocker_footprints.append(Rect2(object_pos - object_size * 0.5, object_size).grow(object_margin))


func _spawn_npcs(npc_data: Array) -> void:
	if _actor_layer == null or not is_instance_valid(_actor_layer):
		push_error("[Field] ActorLayer 不可用，已跳过 NPC 生成")
		return
	for entry in npc_data:
		var d: Dictionary = entry

		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):

			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		if not _quest_gate_passes(d):
			continue

		var npc_instance: Node = NPC_SCENE.instantiate()
		if not npc_instance is NPCNode:
			push_error("[Field] NPC 场景根节点必须是 NPCNode")
			if npc_instance != null:
				npc_instance.queue_free()
			continue
		var npc: NPCNode = npc_instance as NPCNode
		if npc == null:
			continue
		npc.npc_id = String(d.get("npc_id", ""))
		npc.npc_name = String(d.get("npc_name", ""))
		npc.dialog_id = String(d.get("dialog_id", ""))
		npc.interaction_action = String(d.get("interaction_action", ""))
		npc.dialog_variants.assign(d.get("dialog_variants", []))
		npc.portrait_path = String(d.get("portrait_path", ""))
		if d.get("culture_x_pickup_recipient", false): npc.set_meta("culture_x_actual_recipient", true)
		if npc.portrait_path.is_empty():
			npc.portrait_path = _generic_npc_portrait(npc.npc_id)
		npc.sprite_path = String(d.get("sprite_path", ""))
		npc.walk_sprite_path = String(d.get("walk_sprite_path", ""))
		npc.conversation_sprite_paths = d.get("conversation_sprite_paths", {}).duplicate()
		npc.conversation_base_facing = String(d.get("conversation_base_facing", "right"))
		npc.sprite_scale = float(d.get("scale", 0.08))
		npc.movement_mode = String(d.get("movement_mode", "idle"))
		npc.patrol_axis = d.get("patrol_axis", Vector2.RIGHT)
		npc.patrol_distance = float(d.get("patrol_distance", 70.0))
		npc.patrol_speed = float(d.get("patrol_speed", 22.0))
		npc.invert_patrol_facing = bool(d.get("invert_patrol_facing", false))
		npc.idle_frame_seconds = float(d.get("idle_frame_seconds", NPCNode.IDLE_FRAME_SECONDS))
		npc.walk_frame_seconds = float(d.get("walk_frame_seconds", 0.12))
		var profile: NPCProfile = NPC_CATALOG.find(StringName(npc.npc_id), _current_scene.scene_id)
		if (d.get("harbour_life_ground_anchored",false) or d.get("district_life_ground_anchored",false)) and profile!=null:
			npc.queue_free(); _field_loading_failed=true; push_error("[Field] New harbour identity collided with existing NPC catalog"); return
		if profile != null:
			if profile.display_name != "":
				npc.npc_name = profile.display_name
			if profile.default_dialog_id != &"" and not CITY_TASKS.owns_dialog(npc.dialog_id):
				npc.dialog_id = String(profile.default_dialog_id)
			if profile.sprite_path != "":
				npc.sprite_path = profile.sprite_path
			if profile.portrait_path != "":
				npc.portrait_path = profile.portrait_path
			if profile.walk_sprite_path != "":
				npc.walk_sprite_path = profile.walk_sprite_path
			if profile.sprite_scale > 0.0:
				npc.sprite_scale = profile.sprite_scale
			if not d.has("movement_mode"):
				npc.movement_mode = profile.movement_mode
		# Exact existing Luoyang examiner only, after catalog portrait priority.
		# Full1254 canvas is UI-contained; no world sprite or spar payload change.
		if _current_scene.scene_id == &"ch4_s3_luoyang_market" and npc.npc_id == "spar_luoyang_examiner":
			npc.portrait_path = "res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png"
		if _current_scene != null:
			npc.sprite_scale *= _current_scene.npc_visual_scale
		if d.get("harbour_life_ground_anchored",false) or d.get("district_life_ground_anchored",false):
			# New actors only: selected160px runtime cells, existing140px visual
			# normalization, native22.4x28.8 body remains inside audited34x30.
			npc._calibrate_adult_body=true; npc.sprite_scale=1.0
		# Keep the inn cast consistent even while older scene data is still present
		# in saved projects: the keeper is an indoor-only role, while the outdoor
		# actor and the indoor waiter use their own service dialogue and sprite.
		if _current_scene.scene_id == &"ch1_s2_qingfeng" and npc.npc_id == "inn_waiter":
			npc.sprite_path = "res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png"
			npc.portrait_path = "res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png"
			npc.dialog_id = "ch1_s2_inn_waiter"
		if _current_scene.scene_id == &"interior_inn_hall":
			if npc.npc_id == "inn_waiter_inside":
				npc.sprite_path = "res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png"
				npc.portrait_path = "res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png"
				npc.dialog_id = "ch1_s2_inn_waiter"
			if npc.npc_id in ["inn_guest_left", "inn_guest_right"]:
				npc.sprite_path = "res://art/characters/npc_inn_tea_guest_seated_1f.png"
				npc.movement_mode = "seated"
				npc.dialog_id = "interior_inn_guest_chatter"
				if npc.npc_id == "inn_guest_left":
					d["pos"] = Vector2(0.34, 0.705)
				else:
					# Keep the seated sprite anchored on the actual right-hand stool.
					d["pos"] = Vector2(0.800, 0.680)
		var pos: Vector2 = Vector2(
			float(d.get("pos", Vector2.ZERO).x) * _screen_size.x,
			float(d.get("pos", Vector2.ZERO).y) * _screen_size.y
		)
		npc.position = pos
		# NPCNode snapshots its patrol origin in _ready(). Assign the authored
		# world position before add_child() triggers _ready(), otherwise every
		# patrol NPC records (0,0) and is pulled off-screen on the next frame.
		_actor_layer.add_child(npc)
		if _v14_modular_overlap != null:
			_v14_modular_overlap.add_actor(npc)
		_update_actor_depth(npc)
		npc.npc_interacted.connect(_on_npc_interacted)
		npc.npc_action_requested.connect(_on_npc_action_requested)
		_npc_nodes.append(npc)

		## 更新 NPC sprite
		var tex: Resource = null
		if npc.sprite_path != "" and ResourceLoader.exists(npc.sprite_path):
			tex = load(npc.sprite_path)
		if tex is Texture2D and is_instance_valid(npc.sprite):
			var texture: Texture2D = tex
			# NPCNode owns its animation metadata. This also updates its internal
			# frame counter after a scene-level sprite override.
			npc.apply_runtime_idle_texture(texture)
		npc.set_ground_anchored(_current_scene.actor_positions_are_feet)
		if d.get("harbour_life_ground_anchored",false) or d.get("district_life_ground_anchored",false):
			npc.set_ground_anchored(true)
			# Ambient has no authored dialogue/action: do not promise interaction.
			# Keep original StaticBody collision, animation, depth and name label.
			npc.interact_area.monitoring=false; npc.interact_area.monitorable=false
			npc.interact_area.input_pickable=false; npc._in_range=false
			npc.prompt.visible=false; npc._set_interaction_highlight(false)
		if not _functional_room_geometry.is_empty() and d.has("source_foot_px"):
			# NPC visual and body anchors differ from Player's legacy +42. Use its
			# existing calibrated ground mode, never a guessed visual-only offset.
			npc.set_ground_anchored(true)
			npc.position=(d.source_foot_px as Vector2)/FUNCTIONAL_INTERIORS.SOURCE_SIZE*_world_size
		# Field owns pointer dispatch; overlapping physics areas must not each act.
		npc.interact_area.input_pickable = false


func _spawn_exits(exit_data: Array) -> void:
	if _portal_layer == null or not is_instance_valid(_portal_layer):
		push_error("[Field] PortalLayer 不可用，已跳过出口生成")
		return
	for entry in exit_data:
		var d: Dictionary = entry
		if bool(d.get("staging_pending_asset", false)):
			continue

		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		var narrative_locked: bool = (require_flag != "" and not _flag_truthy(require_flag)) or not _quest_gate_passes(d)
		var reveal_only_when_unlocked: bool = bool(d.get("reveal_only_when_unlocked", false))
		if narrative_locked and reveal_only_when_unlocked:
			continue
		var is_locked: bool = narrative_locked
		var locked_label: String = String(d.get("locked_label", "此处暂不接待来客，请少侠改日再访。"))
		var target_scene := String(d.get("target_scene", ""))
		var target_action := String(d.get("action", ""))
		var platform := get_node_or_null("/root/PlatformBridge")
		var blocked_by_trial := platform != null and (
			(not target_scene.is_empty() and not bool(platform.call("is_scene_allowed", target_scene)))
			or (not target_action.is_empty() and not bool(platform.call("is_action_allowed", target_action)))
		)
		if blocked_by_trial:
			is_locked = true
			locked_label = "前路暂不开放，请少侠先在附近历练。"

		if is_locked and locked_label == "":
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue

		var zone_instance: Node = EXIT_SCENE.instantiate()
		if not zone_instance is ExitZone:
			push_error("[Field] 出口场景根节点必须是 ExitZone")
			if zone_instance != null:
				zone_instance.queue_free()
			continue
		var zone: ExitZone = zone_instance as ExitZone
		if zone == null:
			continue
		if SceneRouter.WORLD_V15.is_v15(_current_scene):
			zone.set_script(load("res://scripts/field/world_v15_exit_zone.gd"))
		elif LUOYANG_V3.is_v3(_current_scene):
			zone.set_script(load("res://scripts/field/luoyang_v3_exit_zone.gd"))
		elif OUTSKIRTS.is_native(_current_scene) or d.has("source_spawn_pos"):
			zone.set_script(load("res://scripts/field/outskirts_exit_zone.gd"))
			var center: Vector2 = d.get("pos", Vector2.ZERO)
			var size: Vector2 = d.get("size", Vector2.ZERO)
			zone.call("configure_feet", Rect2(center - size * .5, size), _outskirts_source_player_foot, _outskirts_portal_clearance)
		zone.is_locked = is_locked
		zone.marker_rotation_degrees = float(d.get("marker_rotation_degrees", 0.0))
		zone.always_show_destination = bool(d.get("show_destination_label", false))
		zone.destination_label_side = float(d.get("destination_label_side", 1.0))
		zone.exit_label = locked_label if is_locked else String(d.get("label", "前往"))
		zone.destination_name = String(d.get("destination_name", d.get("label", "前往")))
		zone.target_scene_id = "" if is_locked else target_scene
		zone.action = "" if is_locked else target_action
		var tpos: Vector2 = d.get("target_pos", Vector2(0.5, 0.5))
		zone.target_spawn_pos = tpos

		var pos: Vector2 = Vector2(
			float(d.get("pos", Vector2.ZERO).x) * _screen_size.x,
			float(d.get("pos", Vector2.ZERO).y) * _screen_size.y
		)
		_portal_layer.add_child(zone)
		zone.input_pickable = false
		zone.position = pos
		var source_portal_spawn: Vector2 = d.get("source_spawn_pos", d.get("pos", Vector2(0.5, 0.8)))
		zone.exit_triggered.connect(_on_exit_triggered.bind(source_portal_spawn))
		zone.exit_action_triggered.connect(func(action: String):
			if _uses_enclosure_dispatch_memory() and action == "world_map":
				_remember_interaction_spawn()
			SceneRouter.resolve_action(action)
		)
		zone.exit_locked.connect(func(label: String): _show_toast(label))
		var marker_offset_norm: Vector2 = d.get("marker_offset", Vector2.ZERO)
		if SceneRouter.WORLD_V15.is_v15(_current_scene):
			# V15 pos is the surveyed building doorstep, not the old label gutter.
			marker_offset_norm = Vector2.ZERO
		var marker_offset_px: Vector2 = Vector2(
			marker_offset_norm.x * _screen_size.x,
			marker_offset_norm.y * _screen_size.y
		)
		zone.configure_marker(pos, _screen_size, marker_offset_px)
		if zone.always_show_destination:
			zone.configure_destination_render_scale(_camera_zoom)
		_exit_nodes.append(zone)

		## 调整出口碰撞大小
		var size_norm: Vector2 = d.get("size", Vector2(0.1, 0.3))
		var size_px: Vector2 = Vector2(size_norm.x * _screen_size.x, size_norm.y * _screen_size.y)
		var collider: CollisionShape2D = zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collider != null:
			var shape: RectangleShape2D = RectangleShape2D.new()
			shape.size = size_px
			collider.shape = shape
		var visual: Sprite2D = zone.get_node_or_null("Visual") as Sprite2D
		if visual != null:
			visual.scale = Vector2(size_px.x / 100.0, size_px.y / 200.0)
		if SceneRouter.WORLD_V15.is_v15(_current_scene) or LUOYANG_V3.is_v3(_current_scene):
			var polygon: PackedVector2Array = d.get("interaction_polygon_px", PackedVector2Array())
			if SceneRouter.WORLD_V15.is_v15(_current_scene):
				# Use only this entrance's authored passage, still guarded by safe foot.
				polygon = d.get("passage_polygon_px", PackedVector2Array())
			if polygon.size() < 3:
				push_error("[Field] v15 doorway lacks reviewed interaction polygon: " + String(d.get("id", "")))
				zone.call("configure_doorway", PackedVector2Array(), _player, _is_inside_walkable_screen)
			else:
				zone.call("configure_doorway", polygon, _player, _is_inside_walkable_screen)


func _spawn_collision_rects(collision_data: Array) -> void:
	if _current_scene!=null and _current_scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]:
		var helper: Variant=load("res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd")
		var revision: int=_city3_motion_revision
		var owner: Callable=func() -> bool: return is_inside_tree() and revision==_city3_motion_revision and not _field_loading_failed
		var result: Dictionary=helper.install(self,_current_scene,collision_data,_collision_layer,_world_size,owner)
		if result.get("ok")!=true:
			_field_loading_failed=true;_scene_rebuilding=false;push_error("[Field] AP native bodies rejected: "+String(result.get("error","UNKNOWN")));return
		_collision_bodies.append_array(result.bodies)
		return
	if not _functional_room_geometry.is_empty():
		for entry: Dictionary in collision_data:
			var body:=StaticBody2D.new()
			body.name="Furniture_"+String(entry.id); body.collision_layer=1; body.collision_mask=0
			var shape:=CollisionPolygon2D.new()
			var points:=PackedVector2Array()
			for point: Vector2 in entry.ground_polygon: points.append(point*_world_size)
			shape.polygon=points; body.add_child(shape); _collision_layer.add_child(body); _collision_bodies.append(body)
		return
	for entry in collision_data:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):

			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue

		var body: StaticBody2D = StaticBody2D.new()
		body.name = "Collision_%s" % String(d.get("id", "rect"))
		# Walkable-scene obstacles always live on layer 1; Player explicitly masks it.
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		_collision_layer.add_child(body)
		var offset: Vector2 = _norm_to_screen(d.get("foot_offset", Vector2.ZERO))
		_collider(body, offset, _norm_size_to_screen(d.get("size", Vector2(0.1, 0.1))))
		_collision_bodies.append(body)


func _make_zone_highlight(_size: Vector2) -> Node2D:
	# Baked map details have no silhouette. Use a compact amber exclamation cue
	# rather than exposing an invisible interaction rectangle.
	var root := Node2D.new()
	root.name = "InteractionExclamation"
	root.position = Vector2(0.0, -34.0)
	root.z_index = 45
	root.visible = false
	var cue := Label.new()
	cue.text = "!"
	cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cue.position = Vector2(-14.0, -18.0)
	cue.size = Vector2(28.0, 34.0)
	cue.add_theme_font_size_override("font_size", 30)
	cue.add_theme_color_override("font_color", Color(1.0, 0.69, 0.20, 1.0))
	cue.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.01, 0.96))
	cue.add_theme_constant_override("outline_size", 3)
	root.add_child(cue)
	var tween := root.create_tween().set_loops()
	tween.tween_property(root, "position:y", -44.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root, "position:y", -34.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_sprite_highlight(sprite: Sprite2D) -> void:
	var material := ShaderMaterial.new()
	material.shader = INTERACTION_OUTLINE_SHADER
	material.set_shader_parameter("pulse", 0.0)
	material.set_shader_parameter("base_strength", 0.28)
	sprite.material = material


func _set_interaction_highlight(area: Area2D, active: bool) -> void:
	if not area.has_meta("highlight_node"):
		return
	var target: Variant = area.get_meta("highlight_node")
	# Opening a chest may refresh the scene and queue-free its visual node
	# before Area2D emits its final body-exited callback.
	if target == null or not is_instance_valid(target):
		return
	if LUOYANG_V3.is_v3(_current_scene) and target is Sprite2D and _scene_object_nodes.has(target):
		# A bound native city entity is scenery, not a proximity-only cue.
		# Never hide it on Area exit or overwrite an unrelated authored material.
		if target.material is ShaderMaterial and target.material.shader == INTERACTION_OUTLINE_SHADER:
			(target.material as ShaderMaterial).set_shader_parameter("pulse", 1.0 if active else 0.0)
		return
	if target is Sprite2D and target.material is ShaderMaterial:
		(target.material as ShaderMaterial).set_shader_parameter("pulse", 1.0 if active else 0.0)
	elif target is CanvasItem:
		target.visible = active


func _on_interaction_area_input(_viewport: Node, event: InputEvent, _shape_idx: int, area: Area2D, data: Dictionary) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if not clicked and not tapped:
		return
	if _player == null or not area.overlaps_body(_player):
		return
	_on_trigger_zone_entered(_player, data)


func _spawn_trigger_zones(trigger_data: Array) -> void:
	for entry in trigger_data:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):

			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		if not _quest_gate_passes(d):
			continue

		var area: Area2D = Area2D.new()
		area.name = "Trigger_%s" % String(d.get("id", "zone"))
		# Player is on layer 2.  Area2D defaults to mask 1, which silently
		# prevented every walk-in story trigger from seeing the player.
		area.collision_layer = 4
		area.collision_mask = 2
		area.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		_interaction_layer.add_child(area)
		_collider(area, Vector2.ZERO, _norm_size_to_screen(d.get("size", Vector2(0.1, 0.1))))
		if LUOYANG_V3.is_v3(_current_scene):
			var rectangle: CollisionShape2D = area.get_child(0) as CollisionShape2D
			if rectangle != null: rectangle.disabled = true
			var approach := CollisionPolygon2D.new()
			var polygon: PackedVector2Array = d.get("city_v3_interaction_polygon_px", PackedVector2Array())
			var local := PackedVector2Array()
			for point: Vector2 in polygon: local.append(point - area.position)
			approach.polygon = local
			area.add_child(approach)
		var captured := d.duplicate(true)
		var activation: String = String(captured.get("activation", ""))
		if activation == "":
			activation = "interact" if bool(captured.get("interaction_only", false)) else "enter_once"
		captured["interaction_only"] = activation == "interact"
		area.set_meta("trigger_data", captured)
		var highlight: CanvasItem = null
		if bool(captured.get("interaction_only", false)):
			highlight = _make_trigger_visual(captured, area.position)
			# Baked objects are already visible in the art. Do not replace them
			# with a floating exclamation mark when no separate sprite is needed.
			if highlight == null and not bool(captured.get("visual_baked", false)):
				highlight = _make_zone_highlight(_norm_size_to_screen(captured.get("size", Vector2(0.1, 0.1))))
				area.add_child(highlight)
			area.set_meta("highlight_node", highlight)
			# Most interactions remain keyboard/proximity driven. Explicitly marked
			# world objects (for example a city bounty board) can also be clicked
			# while the player is standing in their interaction footprint.
			area.input_pickable = bool(captured.get("clickable", false))
			area.input_event.connect(_on_interaction_area_input.bind(area, captured))
		area.body_entered.connect(func(body: Node2D):
			if bool(captured.get("interaction_only", false)):
				if body.is_in_group("player"):
					_set_interaction_highlight(area, true)
			else:
				_on_trigger_zone_entered(body, captured)
		)
		area.body_exited.connect(func(body: Node2D):
			if body.is_in_group("player"):
				_set_interaction_highlight(area, false)
			_on_trigger_zone_exited(body, captured)
		)
		_trigger_areas.append(area)


func _make_trigger_visual(data: Dictionary, world_position: Vector2) -> Sprite2D:
	if LUOYANG_V3.is_v3(_current_scene):
		var expected: String = "SceneObject_" + String(data.get("visual_object_id", ""))
		for node: Node in _scene_object_nodes:
			if node is Sprite2D and String(node.name) == expected:
				var sprite := node as Sprite2D
				if sprite.material == null: _make_sprite_highlight(sprite)
				return sprite
		push_error("[Field] native city interaction has no bound actual entity: " + expected)
		return null
	var kind := _interaction_visual_kind(data)
	var texture_path := String(data.get("visual_texture", INTERACTION_VISUALS.get(kind, "")))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = "TriggerVisual_%s" % String(data.get("id", "object"))
	sprite.texture = texture
	sprite.position = world_position
	var render_size: Vector2 = data.get("visual_render_size_px", _default_interaction_visual_size(kind))
	sprite.scale = Vector2(
		render_size.x / maxf(1.0, float(texture.get_width())),
		render_size.y / maxf(1.0, float(texture.get_height()))
	)
	sprite.z_index = int(data.get("visual_z_index", 18))
	_visual_layer.add_child(sprite)
	_scene_object_nodes.append(sprite)
	_make_sprite_highlight(sprite)
	return sprite


func _interaction_visual_kind(data: Dictionary) -> String:
	if bool(data.get("visual_baked", false)):
		return ""
	var explicit := String(data.get("interaction_visual_kind", ""))
	if not explicit.is_empty():
		return explicit
	var semantic := (String(data.get("id", "")) + " " + String(data.get("label", "")) + " " + String(data.get("action", ""))).to_lower()
	if semantic.contains("信") or semantic.contains("笺") or semantic.contains("文书") or semantic.contains("密令"):
		return "letter"
	if semantic.contains("账") or semantic.contains("册") or semantic.contains("卷宗") or semantic.contains("名录"):
		return "ledger"
	if semantic.contains("箱"):
		return "chest"
	if semantic.contains("包裹") or semantic.contains("补给") or semantic.contains("货筒") or semantic.contains("包袱"):
		return "parcel"
	if semantic.contains("水渍") or semantic.contains("水迹") or semantic.contains("血迹") or semantic.contains("脚印") or semantic.contains("痕迹"):
		return "stain"
	return ""


func _default_interaction_visual_size(kind: String) -> Vector2:
	match kind:
		"letter": return Vector2(58.0, 44.0)
		"ledger": return Vector2(64.0, 50.0)
		"parcel": return Vector2(60.0, 50.0)
		"chest": return Vector2(72.0, 58.0)
		"stain": return Vector2(72.0, 45.0)
		_: return Vector2(64.0, 54.0)

func _spawn_travel_routes(routes: Array[Dictionary]) -> void:
	if routes.is_empty() or _visual_layer == null:
		return
	for entry: Dictionary in routes:
		if SceneRouter.layered_world_contract(_current_scene) != null and bool(entry.get("baked_into_terrain", false)):
			continue
		var points_value: Variant = entry.get("points", PackedVector2Array())
		if not points_value is PackedVector2Array:
			continue
		var normalized_points: PackedVector2Array = points_value as PackedVector2Array
		if normalized_points.size() < 2:
			continue
		var route_id: String = String(entry.get("id", "unnamed"))
		var safe := true
		var blocked_foot := Vector2.ZERO
		for index in range(normalized_points.size() - 1):
			var from_point: Vector2 = normalized_points[index]
			var to_point: Vector2 = normalized_points[index + 1]
			var length_px := ((to_point - from_point) * _world_size).length()
			var samples := maxi(1, int(ceil(length_px / 24.0)))
			for sample_index in range(samples + 1):
				var foot: Vector2 = from_point.lerp(to_point, float(sample_index) / float(samples))
				if not _is_walkable_by_mask(foot) or _is_blocked_by_layout(foot):
					safe = false
					blocked_foot = foot
					break
			if not safe:
				break
		if not safe:
			push_warning("[FieldWalkable] staged travel route crosses blocked ground: %s at %s (mask=%s blocker=%s)" % [route_id, blocked_foot, _is_walkable_by_mask(blocked_foot), _is_blocked_by_layout(blocked_foot)])
			continue
		var texture_path: String = String(entry.get("texture", ""))
		if texture_path == "" or not ResourceLoader.exists(texture_path):
			push_warning("[FieldWalkable] staged travel route texture missing: %s" % route_id)
			continue
		var road_texture: Resource = load(texture_path)
		if not road_texture is Texture2D:
			continue
		var line := Line2D.new()
		line.name = "TravelRoute_%s" % route_id
		line.width = maxf(12.0, float(entry.get("width_px", 64.0)))
		line.texture = road_texture as Texture2D
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.antialiased = true
		# A travel surface sits above terrain but below bridge decks, seam rocks,
		# landmarks and all actors. A route must never paint over a city wall.
		line.z_index = int(entry.get("z_index", -1))
		for point: Vector2 in normalized_points:
			line.add_point(_norm_to_screen(point))
		_visual_layer.add_child(line)



## World15-only candidate: full physical metadata first; visual residency is separate.
func _spawn_world_v15_stream(objects: Array, progressive: bool) -> void:
	_v14_modular_overlap=WORLD_V15_STREAM_OVERLAP.new()
	var depth_count:=0
	for data: Dictionary in objects:
		if bool(data.get("sort_by_feet",false)): depth_count+=1
	_v14_modular_overlap.call("configure_stream",world_container,depth_count)
	_create_v14_late_depth_refresh()
	var session: Node=WORLD_V15_STREAM.new()
	session.name="WorldV15VisibleObjects"
	world_container.add_child(session)
	_world_v15_stream=session
	if not session.call("configure",self,_current_scene,_city3_motion_revision,objects,_world_size,_viewport_size,_camera_zoom):
		_field_loading_failed=true; push_error("[Field] World metadata index refused"); return
	var started:=Time.get_ticks_usec()
	var body_started:=started
	var body_count:=0
	var revision:=_city3_motion_revision
	for entry: Dictionary in objects:
		# Exact original world-body branches. No texture existence/load/readback
		# is required to construct authoritative complete physical geometry.
		var object_pos: Vector2=_norm_to_screen(entry.get("pos",Vector2.ZERO))
		if entry.has("solid_polygons_px"):
			body_count+=1
			var body:=StaticBody2D.new()
			body.name="ObjectCollision_%s"%String(entry.get("id","object"))
			body.collision_layer=1; body.collision_mask=0; body.position=object_pos
			_collision_layer.add_child(body)
			for authored: PackedVector2Array in entry.solid_polygons_px:
				var polygon:=CollisionPolygon2D.new()
				var local:=PackedVector2Array()
				for point: Vector2 in authored: local.append(point-object_pos)
				polygon.polygon=local
				body.add_child(polygon)
			_collision_bodies.append(body)
		elif entry.has("collision_size"):
			body_count+=1
			var body:=StaticBody2D.new()
			body.name="ObjectCollision_%s"%String(entry.get("id","object"))
			body.collision_layer=1; body.collision_mask=0; body.position=object_pos
			_collision_layer.add_child(body)
			_collider(body,_norm_to_screen(entry.get("collision_offset",Vector2.ZERO)),_norm_size_to_screen(entry.get("collision_size",Vector2(0.05,0.05))))
			_collision_bodies.append(body)
		if progressive and Time.get_ticks_usec()-started>=8000:
			await get_tree().process_frame
			if not _owns_world_v15_stream(session,_current_scene,revision): return
			started=Time.get_ticks_usec()
	session.call("record_body_stats",body_count,Time.get_ticks_usec()-body_started)

func _owns_world_v15_stream(session: Node, scene: SceneScript, revision: int) -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and _world_v15_stream==session and _current_scene==scene and _city3_motion_revision==revision

func _attach_world_v15_visual(data: Dictionary, texture: Texture2D, ordinal: int) -> Sprite2D:
	if not is_instance_valid(_world_v15_stream) or not WORLD_V15_STREAM.applies(_current_scene) or texture==null: return null
	var sprite:=Sprite2D.new()
	sprite.name="SceneObject_%s"%String(data.get("id","object"))
	sprite.texture=texture
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered=bool(data.get("centered",true))
	sprite.position=_norm_to_screen(data.get("pos",Vector2.ZERO))
	var render_size: Vector2=data.render_size_px
	sprite.scale=Vector2(render_size.x/maxf(1.0,float(texture.get_width())),render_size.y/maxf(1.0,float(texture.get_height())))
	sprite.rotation_degrees=float(data.get("rotation",0.0))
	sprite.z_index=int(data.get("z_index",0))
	if data.has("modulate") and data.modulate is Color: sprite.modulate=data.modulate
	var sorted:=bool(data.get("sort_by_feet",false))
	var layer: Node2D=_actor_layer if sorted else (_foreground_layer if String(data.get("render_layer",""))=="foreground" else _visual_layer)
	if sorted:
		var foot_y:=clampf(float(data.get("depth_sort_foot_y",sprite.position.y/_world_size.y)),0.0,1.0)
		var global_y:=world_container.to_global(Vector2(0.0,foot_y*_world_size.y)).y
		sprite.z_index=clampi(int(floor(global_y/8.0)),0,_scene_depth_band_max())
	layer.add_child(sprite)
	if sorted and not _v14_modular_overlap.call("add_stream_prop",sprite,String(data.id),float(data.depth_sort_foot_y)*_world_size.y,ordinal):
		layer.remove_child(sprite); sprite.queue_free(); return null
	_scene_object_nodes.append(sprite)
	return sprite

func _detach_world_v15_visual(sprite: Sprite2D) -> void:
	if not is_instance_valid(sprite): return
	if _v14_modular_overlap!=null and _v14_modular_overlap.get_script()==WORLD_V15_STREAM_OVERLAP:
		_v14_modular_overlap.call("remove_stream_prop",sprite)
	_scene_object_nodes.erase(sprite)
	sprite.visible=false
	if sprite.get_parent()!=null: sprite.get_parent().remove_child(sprite)
	sprite.texture=null
	sprite.queue_free()

func _release_world_v15_stream() -> void:
	if is_instance_valid(_world_v15_stream):
		_world_v15_stream.call("release")
		if _world_v15_stream.get_parent()!=null: _world_v15_stream.get_parent().remove_child(_world_v15_stream)
		_world_v15_stream.queue_free()
	_world_v15_stream=null
	if _v14_modular_overlap!=null and _v14_modular_overlap.get_script()==WORLD_V15_STREAM_OVERLAP:
		_v14_modular_overlap.call("release_stream")
		_v14_modular_overlap=null

func _suspend_world_v15_stream() -> void:
	if is_instance_valid(_world_v15_stream): _world_v15_stream.call("suspend")

func _resume_world_v15_stream() -> void:
	if is_instance_valid(_world_v15_stream): _world_v15_stream.call("resume")

func _world_v15_stream_failed(session: Node, reason: String) -> void:
	if not _owns_world_v15_stream(session,_current_scene,_city3_motion_revision): return
	_field_loading_failed=true; _field_loading_complete=false
	if is_instance_valid(_player): _player.set_can_move(false)
	session.call("suspend")
	push_error("[Field] World visible stream failed: "+reason)
	var spawn: Vector2=_player.position/_world_size if is_instance_valid(_player) else _current_scene.player_spawn
	LoadingManager.show_world_stream_failure(self,_current_scene.scene_id,spawn)

func get_world_v15_stream_debug() -> Dictionary:
	return _world_v15_stream.call("debug_state") if is_instance_valid(_world_v15_stream) else {}

func _spawn_scene_objects(scene_objects: Array, progressive: bool = false) -> void:
	var loading_spawn_revision: int = _city3_motion_revision
	var loading_spawn_scene: SceneScript = _current_scene
	var loading_fade_started: Dictionary = _field_loading_profile_clock()
	if WORLD_V15_STREAM.applies(_current_scene):
		await _spawn_world_v15_stream(scene_objects,progressive)
		return
	if TEMPLE_ASSEMBLY.is_scene(_current_scene) and _v14_modular_overlap==null:
		var temple_fade:=TEMPLE_FADE.new()
		if _temple_session==null or not temple_fade.configure_temple(world_container,_current_scene,_temple_session.data):
			temple_fade.release(); _field_loading_failed=true; push_error("[Field] Temple furniture scope rejected"); return
		_v14_modular_overlap=temple_fade; _create_v14_late_depth_refresh()
	if ASSEMBLED_ROOMS.is_room(_current_scene) and _v14_modular_overlap==null:
		var assembled:=ASSEMBLED_FADE.new()
		if not assembled.configure_assembly(world_container,_current_scene.scene_id,ASSEMBLED_ROOMS.prop_ids(_current_scene),ASSEMBLED_ROOMS.fade_ids(_current_scene)):
			assembled.release(); _field_loading_failed=true; push_error("[Field] Furniture source scope rejected"); return
		_v14_modular_overlap=assembled; _create_v14_late_depth_refresh()
	if _district_session!=null and _v14_modular_overlap==null:
		var district_fade:=DISTRICT_FADE.new()
		if not district_fade.configure_district(world_container,_current_scene,_district_session.parent_render,_district_session.projected):
			district_fade.release(); _field_loading_failed=true; push_error("[Field] District parent fade whitelist rejected"); return
		_v14_modular_overlap=district_fade; _create_v14_late_depth_refresh()
	if _is_gate_fortification_scene():
		_gate_moat_runtime = GATE_MOAT_RUNTIME.new()
		if not _gate_moat_runtime.prepare(_harbour_gate_visual_scene if HARBOUR_LIFE.bound(_current_scene) else _current_scene):
			_release_gate_moat_runtime()
			push_error("[Field] Gate bound runtime preparation rejected")
			return
	if _current_scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"] and _v14_modular_overlap==null:
		var family: Variant=load("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
		if not family.matches(_current_scene): _field_loading_failed=true;push_error("[Field] AP native depth owner rejected");return
		_v14_modular_overlap=V14_MODULAR_OVERLAP.new();_v14_modular_overlap.configure(world_container);_create_v14_late_depth_refresh()
	if (SceneRouter.layered_world_contract(_current_scene) != null or OUTSKIRTS.is_native(_current_scene) or LUOYANG_V3.is_v3(_current_scene)) and _v14_modular_overlap == null:
		var enclosure: bool = LUOYANG_V3.is_v3(_current_scene) and _current_scene.has_meta("city_enclosure_manifest_sha")
		if enclosure:
			var harbour: bool=HARBOUR_LIFE.bound(_current_scene)
			var annex: bool=LUOYANG_V3.annex_bound(_current_scene)
			var revised_market: bool=_current_scene.scene_id==MARKET_ENRICHMENT.ID and LUOYANG_V3.revision_bound(_current_scene)
			var assembled_city: bool=annex or LUOYANG_V3.assembled_bound(_current_scene)
			var helper: RefCounted = YAMEN_ANNEX_FADE.new() if annex else (HARBOUR_FADE.new() if harbour else (ASSEMBLED_CITY_FADE.new() if assembled_city else (GATE_FORTIFICATION_FADE.new() if _is_gate_fortification_scene() else (MARKET_ENRICHMENT_FADE.new() if MARKET_ENRICHMENT.bound(_current_scene) or revised_market else CITY_ENCLOSURE_FADE.new()))))
			var configured: bool=helper.configure_harbour_scene(world_container,_current_scene,scene_objects) if harbour else (helper.configure_assembled_scene(world_container,_current_scene,scene_objects) if assembled_city else helper.configure_scene(world_container, String(_current_scene.scene_id)))
			if not configured:
				helper.release()
				push_error("[FieldWalkable] enclosure building fade configuration rejected")
				return
			_v14_modular_overlap = helper
		elif LUOYANG_V3.is_v3(_current_scene):
			_v14_modular_overlap = CITY_OVERLAP.new()
		elif OUTSKIRTS.is_native(_current_scene):
			_v14_modular_overlap = OUTSKIRTS_OVERLAP.new()
		else:
			_v14_modular_overlap = V15_MODULAR_OVERLAP.new() if SceneRouter.WORLD_V15.is_v15(_current_scene) else V14_MODULAR_OVERLAP.new()
		if not enclosure: _v14_modular_overlap.configure(world_container)
		_create_v14_late_depth_refresh()
	_field_loading_profile_record("depth_fade_bootstrap", loading_fade_started, loading_spawn_revision, loading_spawn_scene)
	var loading_first_batch_started: Dictionary = _field_loading_profile_clock()
	var loading_first_batch_recorded: bool = false
	var batch_started := Time.get_ticks_usec()
	var processed := 0
	for entry in scene_objects:
		if progressive and Time.get_ticks_usec() - batch_started >= 8000:
			if not loading_first_batch_recorded:
				_field_loading_profile_record("object_first_batch", loading_first_batch_started, loading_spawn_revision, loading_spawn_scene, processed)
				loading_first_batch_recorded = true
			_field_loading_progress = .1 + .7 * float(processed) / maxi(1, scene_objects.size())
			_field_loading_stage = "正在布置建筑与碰撞……"
			await get_tree().process_frame
			if not is_inside_tree(): return
			batch_started = Time.get_ticks_usec()
		processed += 1
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		if not _quest_gate_passes(d):
			continue
		var texture_path: Variant = String(d.get("texture", ""))
		var gate_object: bool = _is_gate_fortification_scene() and d.get("gate_module_object",false) == true
		if texture_path == "" or (not gate_object and not ResourceLoader.exists(texture_path)):
			push_warning("[FieldWalkable] scene object texture missing: %s" % texture_path)
			continue
		var tex: Resource = _gate_moat_runtime.texture_for(d) if gate_object and _gate_moat_runtime != null else load(texture_path)
		if not tex is Texture2D:
			push_warning("[FieldWalkable] scene object is not Texture2D: %s" % texture_path)
			continue
		var texture: Texture2D = tex as Texture2D
		if _district_session!=null and not _district_session.texture_matches(String(texture_path),texture):
			_field_loading_failed=true; push_error("[Field] District actual prop texture identity changed"); return
		if TEMPLE_ASSEMBLY.is_scene(_current_scene) and (_temple_session==null or not _temple_session.texture_matches(String(texture_path),texture)):
			_field_loading_failed=true
			if _temple_session!=null: _temple_session.error="TEMPLE_ACTUAL_PROP_TEXTURE_CHANGED:"+String(texture_path)
			return
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "SceneObject_%s" % String(d.get("id", "object"))
		sprite.texture = texture
		if gate_object and d.get("gate_hidden",false) == true: sprite.visible = false
		# Native rendered world props are not pixel art. Camera magnification and
		# non-integral authored sizes must not inherit the project nearest filter.
		# Keep all ordinary scene sprites (and the player) unchanged.
		if SceneRouter.layered_world_contract(_current_scene) != null or OUTSKIRTS.is_native(_current_scene) or LUOYANG_V3.is_v3(_current_scene) or ASSEMBLED_ROOMS.is_room(_current_scene) or TEMPLE_ASSEMBLY.is_scene(_current_scene) or _current_scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]:
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered = bool(d.get("centered", true))
		sprite.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		var render_size_value: Variant = d.get("render_size_px", null)
		if render_size_value is Vector2:
			var render_size: Vector2 = render_size_value as Vector2
			sprite.scale = Vector2(
				render_size.x / maxf(1.0, float(texture.get_width())),
				render_size.y / maxf(1.0, float(texture.get_height()))
			)
		else:
			sprite.scale = _scale_value(d.get("scale", Vector2.ONE))
		sprite.rotation_degrees = float(d.get("rotation", 0.0))
		sprite.z_index = int(d.get("z_index", 0))
		if d.has("modulate") and d["modulate"] is Color:
			sprite.modulate = d["modulate"]
		# A separate transparent prop can share the actor depth ladder. This is
		# fundamentally different from a prop baked into the background, which
		# still needs an authored foreground polygon. The visual, foot collision,
		# and depth line all live in one object entry.
		var depth_sorted := bool(d.get("sort_by_feet", false))
		var render_layer: Node2D = _actor_layer if depth_sorted else (_foreground_layer if String(d.get("render_layer", "")) == "foreground" else _visual_layer)
		var shadow_size_value: Variant = d.get("ground_shadow_size_px", null)
		if shadow_size_value is Vector2:
			var shadow_size: Vector2 = shadow_size_value as Vector2
			if shadow_size.x > 0.0 and shadow_size.y > 0.0:
				var foot_normalized: Vector2 = d.get("pos", Vector2.ZERO) + d.get("collision_offset", Vector2.ZERO)
				var shadow := Sprite2D.new()
				shadow.name = "GroundShadow_%s" % String(d.get("id", "object"))
				shadow.texture = _make_prop_contact_shadow_texture()
				shadow.position = _norm_to_screen(foot_normalized) + Vector2(0.0, -3.0)
				shadow.scale = shadow_size / Vector2(shadow.texture.get_size())
				_visual_layer.add_child(shadow)
				_scene_object_nodes.append(shadow)
		if depth_sorted:
			if not d.has("depth_sort_foot_y"):
				push_warning("[FieldWalkable] depth-sorted object needs depth_sort_foot_y: %s" % sprite.name)
			var foot_y: float = clampf(float(d.get("depth_sort_foot_y", (sprite.position.y / _world_size.y))), 0.0, 1.0)
			var foot_global_y: float = world_container.to_global(Vector2(0.0, foot_y * _world_size.y)).y
			sprite.z_index = clampi(int(floor(foot_global_y / 8.0)), 0, _scene_depth_band_max())
		render_layer.add_child(sprite)
		if depth_sorted and _v14_modular_overlap != null:
			if LUOYANG_V3.is_v3(_current_scene) and d.get("role", "") == "water_decoration":
				# CITY.prepare validates the exact dock/boat identity and no support,
				# geometry or interaction. Keep precise ordinary Y ordering, not ghost.
				_v14_modular_overlap.call("add_non_occluding_prop", sprite, String(d.id), float(d.depth_sort_foot_y) * _world_size.y)
			else:
				_v14_modular_overlap.add_prop(sprite, String(d.get("id", "object")), float(d["depth_sort_foot_y"]) * _world_size.y)
		_scene_object_nodes.append(sprite)

		var object_pos: Vector2 = sprite.position
		if LUOYANG_V3.is_v3(_current_scene):
			if bool(d.get("blocking", false)):
				var city_body := StaticBody2D.new()
				city_body.name = "CityV3Physical_%s" % String(d.get("id", "object"))
				city_body.collision_layer = 1
				city_body.collision_mask = 0
				# Parent identity keeps declared WORLD geometry unchanged.
				_collision_layer.add_child(city_body)
				for raw: Variant in d.get("city_v3_solid_polygons_px", []):
					var polygon := CollisionPolygon2D.new()
					polygon.polygon = LUOYANG_V3._polygon(raw)
					city_body.add_child(polygon)
				var box_size: Vector2 = LUOYANG_V3._vec(d.get("collision_size_px"))
				if box_size.x > 0 and box_size.y > 0: _collider(city_body, LUOYANG_V3._vec(d.physical_center_px), box_size)
				city_body.set_meta("authoring_id", String(d.id))
				_collision_bodies.append(city_body)
		elif SceneRouter.WORLD_V15.is_v15(_current_scene) and d.has("solid_polygons_px"):
			# The authored world-pixel solids surround a real open doorway.
			# Never add the legacy whole-compound rectangle over that passage.
			var body := StaticBody2D.new()
			body.name = "ObjectCollision_%s" % String(d.get("id", "object"))
			body.collision_layer = 1
			body.collision_mask = 0
			body.position = object_pos
			_collision_layer.add_child(body)
			for authored: PackedVector2Array in d.solid_polygons_px:
				var polygon := CollisionPolygon2D.new()
				var local := PackedVector2Array()
				for point: Vector2 in authored: local.append(point - object_pos)
				polygon.polygon = local
				body.add_child(polygon)
			_collision_bodies.append(body)
		elif d.has("collision_size"):
			var body: StaticBody2D = StaticBody2D.new()
			body.name = "ObjectCollision_%s" % String(d.get("id", "object"))
			body.collision_layer = 1
			body.collision_mask = 0
			body.position = object_pos
			_collision_layer.add_child(body)
			_collider(
				body,
				_norm_to_screen(d.get("collision_offset", Vector2.ZERO)),
				_norm_size_to_screen(d.get("collision_size", Vector2(0.05, 0.05)))
			)
			_collision_bodies.append(body)

		var interaction_action: String = String(d.get("interaction_action", ""))
		if interaction_action != "":
			_make_sprite_highlight(sprite)
			_spawn_scene_object_interaction(d, object_pos, interaction_action, sprite)
	if not loading_first_batch_recorded:
		_field_loading_profile_record("object_first_batch", loading_first_batch_started, loading_spawn_revision, loading_spawn_scene, processed)


func _create_v14_late_depth_refresh() -> void:
	if is_instance_valid(_v14_late_depth_refresh): return
	var refresher := V14LateDepthRefresh.new()
	refresher.name = "V14LateDepthRefresh"
	# Player animation is advanced in physics; normal NPC/Field idle priority
	# is 0. Run after their idle movement, but before native frame rendering.
	refresher.process_priority = 100
	refresher.field_ref = weakref(self)
	_v14_late_depth_refresh = refresher
	world_container.add_child(refresher)


func _refresh_v14_late_depth(refresher: Node) -> void:
	if refresher != _v14_late_depth_refresh or _scene_rebuilding or _v14_modular_overlap == null: return
	if not is_instance_valid(_player):
		if _is_enclosure_fade_runtime():
			_v14_modular_overlap.refresh(null)
		return
	_v14_modular_overlap.refresh(_player)


func _make_prop_contact_shadow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_offsets(PackedFloat32Array([0.0, 0.48, 1.0]))
	gradient.set_colors(PackedColorArray([
		Color(0.04, 0.035, 0.025, 0.38),
		Color(0.04, 0.035, 0.025, 0.18),
		Color(0.04, 0.035, 0.025, 0.0),
	]))
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func _spawn_dynamic_occluders(occluder_data: Array) -> void:
	if _foreground_layer == null or not is_instance_valid(_foreground_layer):
		return
	if _world_background == null or _world_background.texture == null:
		return
	for entry in occluder_data:
		if not entry is Dictionary:
			continue
		var data: Dictionary = entry as Dictionary
		var require_flag := String(data.get("require_flag", ""))
		var hide_flag := String(data.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var occluder := DynamicOccluder2D.new()
		occluder.name = "DynamicOccluder_%s" % String(data.get("id", "foreground"))
		if not occluder.configure(data, _world_background.texture, _world_size):
			push_warning("[FieldWalkable] invalid dynamic occluder: %s" % String(data.get("id", "")))
			occluder.queue_free()
			continue
		_foreground_layer.add_child(occluder)
		_occluder_nodes.append(occluder)


func _update_dynamic_occluders(normalized_foot_position: Vector2, immediate: bool = false) -> void:
	if _v14_modular_overlap != null and _is_enclosure_fade_runtime() and not is_instance_valid(_player):
		_v14_modular_overlap.refresh(null, immediate)
		return
	if _v14_modular_overlap != null and is_instance_valid(_player):
		_v14_modular_overlap.refresh(_player, immediate)
		return
	var player_is_under_building := false
	var player_faded_alpha := 1.0
	var overlap_mask_payload: Dictionary = {}
	# Legacy scene coordinates may address the actor node/torso rather than its
	# rendered feet. Free-standing props must use the same visual foot coordinate
	# as Player.refresh_depth_sort(), otherwise the foreground remains above an
	# actor who is visibly standing in front of the prop.
	var normalized_visual_foot := normalized_foot_position
	if is_instance_valid(_player) and _world_size.y > 0.0 and _player.has_method("get_depth_sort_y"):
		var global_visual_foot := Vector2(_player.global_position.x, float(_player.call("get_depth_sort_y")))
		var local_visual_foot := world_container.to_local(global_visual_foot)
		normalized_visual_foot.y = clampf(local_visual_foot.y / _world_size.y, 0.0, 1.0)
	for occluder in _occluder_nodes:
		if is_instance_valid(occluder):
			occluder.update_player_position(normalized_visual_foot if occluder.uses_foot_depth_sort() else normalized_foot_position, immediate)
			if occluder.contains_fade_point(normalized_foot_position):
				player_is_under_building = true
				var candidate_alpha := occluder.get_player_faded_alpha()
				if candidate_alpha <= player_faded_alpha:
					player_faded_alpha = candidate_alpha
					overlap_mask_payload = occluder.get_actor_overlap_mask_payload()
	if is_instance_valid(_player):
		_player.set_building_overlap(player_is_under_building, player_faded_alpha, immediate, overlap_mask_payload)
	var player_is_over_baked_building := false
	var baked_faded_alpha := 1.0
	for raw_zone: Variant in _actor_fade_zones:
		if not raw_zone is Dictionary:
			continue
		var zone: Dictionary = raw_zone as Dictionary
		var require_flag := String(zone.get("require_flag", ""))
		var hide_flag := String(zone.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var region: PackedVector2Array = zone.get("region", PackedVector2Array())
		if region.size() < 3 or not Geometry2D.is_point_in_polygon(normalized_foot_position, region):
			continue
		player_is_over_baked_building = true
		baked_faded_alpha = minf(
			baked_faded_alpha,
			clampf(float(zone.get("actor_faded_alpha", 0.46)), 0.15, 0.90)
		)
	if is_instance_valid(_player):
		_player.set_baked_map_overlap(player_is_over_baked_building, baked_faded_alpha, immediate)


func get_v14_modular_overlap_debug() -> Dictionary:
	return _v14_modular_overlap.get_debug_state() if _v14_modular_overlap != null else {"active": false, "pixels": 0, "prop_hits": {}}

func get_v14_depth_order_debug() -> Array[Dictionary]:
	return _v14_modular_overlap.get_depth_order_state() if _v14_modular_overlap != null else []


func get_city_building_fade_debug() -> Dictionary:
	if _v14_modular_overlap != null and _is_enclosure_fade_runtime():
		var state: Dictionary = _v14_modular_overlap.call("get_fade_runtime_state")
		var arguments: PackedStringArray = OS.get_cmdline_user_args()
		state.candidate_flags_present = LUOYANG_V3.CANDIDATE_FLAG in arguments and "--luoyang-v3-candidate" in arguments
		return state
	return {"runtime_hooked":false,"production_hooked":false,"scope":"NOT_LUOYANG_ENCLOSURE"}


func _spawn_scene_object_interaction(d: Dictionary, object_pos: Vector2, action: String, sprite: Sprite2D) -> void:
	var area: Area2D = Area2D.new()
	area.name = "ObjectInteraction_%s" % String(d.get("id", "object"))
	area.collision_layer = 4
	area.collision_mask = 2
	area.position = object_pos + _norm_to_screen(d.get("interaction_offset", Vector2.ZERO))
	_interaction_layer.add_child(area)
	_collider(area, Vector2.ZERO, _norm_size_to_screen(d.get("interaction_size", Vector2(0.10, 0.10))))

	var trigger_data: Dictionary = {
		"id": String(d.get("id", "object")),
		"action": action,
		"interaction_only": true,
		"require_flag": String(d.get("require_flag", "")),
		"hide_flag": String(d.get("hide_flag", "")),
		"require_quest_active": String(d.get("require_quest_active", "")),
		"require_quest_completed": String(d.get("require_quest_completed", "")),
	}
	area.set_meta("trigger_data", trigger_data)
	area.set_meta("highlight_node", sprite)
	area.input_pickable = false
	area.input_event.connect(_on_interaction_area_input.bind(area, trigger_data))

	area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			_set_interaction_highlight(area, true)
	)
	area.body_exited.connect(func(body: Node2D):
		if body.is_in_group("player"):
			_set_interaction_highlight(area, false)
			_on_trigger_zone_exited(body, trigger_data)
	)
	_trigger_areas.append(area)


func _spawn_animated_props(animated_props: Array) -> void:
	for entry in animated_props:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var prop_type: Variant = String(d.get("type", "")).to_lower()
		var node: Node2D = null
		match prop_type:
			"banner":
				node = _make_banner_prop(d)
			"texture_sway":
				node = _make_texture_sway_prop(d)
			"hammer":
				node = _make_hammer_prop(d)
			"flame":
				node = _make_flame_prop(d)
			"smoke":
				node = _make_smoke_prop(d)
			"mist_drift":
				node = _make_mist_drift_prop(d)
			"water_shimmer":
				node = _make_water_shimmer_prop(d)
			"snow_drift":
				node = _make_snow_drift_prop(d)
			"rain_field":
				node = _make_rain_field_prop(d)
			"rain_splash":
				node = _make_rain_splash_prop(d)
			"glow":
				node = _make_glow_prop(d)
			_:
				push_warning("[FieldWalkable] unknown animated prop type: %s" % prop_type)
		if node == null:
			continue
		node.name = "AnimatedProp_%s" % String(d.get("id", prop_type))
		node.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		node.z_index = int(d.get("z_index", 22))
		_visual_layer.add_child(node)
		_animated_prop_nodes.append(node)


func _spawn_active_weather(scene: SceneScript) -> void:
	_clear_active_weather()
	var weather_manager := get_node_or_null("/root/WeatherManager")
	if weather_manager == null or not bool(weather_manager.call("is_weather_visible", scene)):
		return
	for entry: Dictionary in weather_manager.call("get_visual_props"):
		var prop_type := String(entry.get("type", ""))
		var node: Node2D = null
		match prop_type:
			"rain_field":
				node = _make_rain_field_prop(entry)
			"rain_splash":
				node = _make_rain_splash_prop(entry)
		if node == null:
			continue
		node.name = "Weather_%s" % String(entry.get("id", prop_type))
		node.position = _norm_to_screen(entry.get("pos", Vector2.ZERO))
		node.z_index = int(entry.get("z_index", 72))
		_visual_layer.add_child(node)
		_weather_nodes.append(node)


func _clear_active_weather() -> void:
	for node in _weather_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_weather_nodes.clear()


func _on_weather_changed(_weather_id: StringName, _strength: float) -> void:
	if _current_scene == null or _visual_layer == null or _scene_rebuilding:
		return
	_spawn_active_weather(_current_scene)


func _make_banner_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.04, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#b72f24")), Color(0.72, 0.18, 0.13, 0.92))
	var pole: Line2D = Line2D.new()
	pole.width = maxf(2.0, size_px.x * 0.08)
	pole.default_color = Color(0.18, 0.12, 0.08, 0.85)
	pole.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, size_px.y)])
	root.add_child(pole)
	var cloth: Polygon2D = Polygon2D.new()
	cloth.color = color
	cloth.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(size_px.x, size_px.y * 0.16),
		Vector2(size_px.x * 0.82, size_px.y * 0.55),
		Vector2(0.0, size_px.y * 0.44),
	])
	cloth.position = Vector2(0.0, size_px.y * 0.10)
	root.add_child(cloth)
	var tween := root.create_tween().set_loops()
	tween.tween_property(cloth, "scale:x", 0.82, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cloth, "scale:x", 1.08, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_texture_sway_prop(d: Dictionary) -> Node2D:
	var texture_path: Variant = String(d.get("texture", ""))
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[FieldWalkable] animated prop texture missing: %s" % texture_path)
		return null
	var tex: Resource = load(texture_path)
	if not tex is Texture2D:
		push_warning("[FieldWalkable] animated prop is not Texture2D: %s" % texture_path)
		return null
	var texture: Texture2D = tex as Texture2D
	var root: Node2D = Node2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.04, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2(size_px.x / texture.get_width(), size_px.y / texture.get_height())
	root.add_child(sprite)
	var tween := root.create_tween().set_loops()
	tween.tween_property(sprite, "skew", deg_to_rad(-4.0), 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale:x", sprite.scale.x * 0.92, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "skew", deg_to_rad(4.0), 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale:x", sprite.scale.x * 1.06, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_hammer_prop(d: Dictionary) -> Node2D:
	var texture_path: Variant = String(d.get("texture", ""))
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[FieldWalkable] hammer prop texture missing: %s" % texture_path)
		return null
	var tex: Resource = load(texture_path)
	if not tex is Texture2D:
		push_warning("[FieldWalkable] hammer prop is not Texture2D: %s" % texture_path)
		return null
	var texture: Texture2D = tex as Texture2D
	var root: Node2D = Node2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.035, 0.06)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2.ZERO
	sprite.position = Vector2(0.0, -size_px.y * 0.65)
	sprite.scale = Vector2(size_px.x / texture.get_width(), size_px.y / texture.get_height())
	root.add_child(sprite)
	var tween := root.create_tween().set_loops()
	tween.tween_property(sprite, "rotation_degrees", -42.0, 0.22 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation_degrees", 24.0, 0.10 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.18 / speed)
	return root


func _make_flame_prop(d: Dictionary) -> Node2D:
	## Stylized environmental fire rendered as a small procedural shader plus a
	## few rising embers. It remains visual-only: no collision, light occluder or
	## per-frame script work. Position is the base of the painted brazier/torch.
	var root := Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.026, 0.060)))
	var speed := maxf(0.1, float(d.get("speed", 1.0)))
	var outer_color: Color = _parse_html_color(String(d.get("color", "#ff7a1a")), Color(1.0, 0.42, 0.08, 0.88))
	var core_color: Color = _parse_html_color(String(d.get("core_color", "#ffe08a")), Color(1.0, 0.86, 0.48, 0.96))
	var middle_color := outer_color.lerp(core_color, 0.42)
	var glow := Sprite2D.new()
	glow.texture = _make_radial_texture(128, Color(outer_color.r, outer_color.g, outer_color.b, 0.44), Color(outer_color.r, outer_color.g, outer_color.b, 0.0))
	glow.position = Vector2(0.0, -size_px.y * 0.38)
	glow.scale = Vector2(size_px.x / 42.0, size_px.y / 58.0)
	glow.modulate.a = 0.34
	root.add_child(glow)
	var glow_tween := glow.create_tween().set_loops()
	glow_tween.tween_property(glow, "modulate:a", 0.22, 0.36 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.parallel().tween_property(glow, "scale", glow.scale * Vector2(0.94, 1.08), 0.36 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(glow, "modulate:a", 0.40, 0.42 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.parallel().tween_property(glow, "scale", glow.scale, 0.42 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var flame_quad := ColorRect.new()
	flame_quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flame_quad.position = Vector2(-size_px.x * 0.82, -size_px.y * 1.08)
	flame_quad.size = Vector2(size_px.x * 1.64, size_px.y * 1.12)
	var flame_material := ShaderMaterial.new()
	flame_material.shader = ENVIRONMENT_FLAME_SHADER
	flame_material.set_shader_parameter("outer_color", outer_color)
	flame_material.set_shader_parameter("middle_color", middle_color)
	flame_material.set_shader_parameter("core_color", core_color)
	flame_material.set_shader_parameter("speed", speed)
	flame_material.set_shader_parameter("phase", float(abs(hash(d.get("id", "flame"))) % 1000) / 97.0)
	flame_material.set_shader_parameter("opacity", 0.94)
	flame_quad.material = flame_material
	root.add_child(flame_quad)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "flame_embers"))
	var ember_texture := _make_radial_texture(24, Color(core_color.r, core_color.g, core_color.b, 0.95), Color(outer_color.r, outer_color.g, outer_color.b, 0.0))
	var ember_count := maxi(2, roundi(4.0 * _ambient_animation_density()))
	for index in range(ember_count):
		var ember := Sprite2D.new()
		ember.texture = ember_texture
		ember.centered = true
		root.add_child(ember)
		_loop_flame_ember(ember, size_px, speed, rng.randf_range(0.0, 0.75 / speed), rng)
	return root


func _loop_flame_ember(ember: Sprite2D, size_px: Vector2, speed: float, delay: float, rng: RandomNumberGenerator) -> void:
	var start_x := rng.randf_range(-size_px.x * 0.30, size_px.x * 0.30)
	var end_x := start_x + rng.randf_range(-size_px.x * 0.42, size_px.x * 0.42)
	var end_y := -size_px.y * rng.randf_range(0.72, 1.32)
	var life := rng.randf_range(0.52, 0.88) / speed
	var start_scale := rng.randf_range(0.065, 0.12) * maxf(0.65, size_px.x / 32.0)
	ember.position = Vector2(start_x, -size_px.y * rng.randf_range(0.08, 0.24))
	ember.scale = Vector2.ONE * start_scale
	ember.modulate.a = rng.randf_range(0.54, 0.90)
	var tween := ember.create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		if is_instance_valid(ember):
			ember.position = Vector2(start_x, -size_px.y * 0.12)
			ember.scale = Vector2.ONE * start_scale
			ember.modulate.a = 0.82
	)
	tween.tween_property(ember, "position", Vector2(end_x, end_y), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ember, "scale", Vector2.ONE * start_scale * 0.34, life)
	tween.parallel().tween_property(ember, "modulate:a", 0.0, life)
	tween.tween_interval(rng.randf_range(0.10, 0.36) / speed)


func _make_smoke_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.06, 0.12)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#d8d8cf")), Color(0.78, 0.78, 0.72, 0.22))
	var tex := _make_radial_texture(64, color, Color(color.r, color.g, color.b, 0.0))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "smoke"))
	var smoke_puff_count := maxi(2, roundi(6.0 * _ambient_animation_density()))
	for i in range(smoke_puff_count):
		var puff: Sprite2D = Sprite2D.new()
		puff.texture = tex
		puff.centered = true
		var ox: float = size_px.x * (rng.randf_range(-0.06, 0.06))
		var oy := -size_px.y * rng.randf_range(0.0, 0.10)
		puff.position = Vector2(ox, oy)
		var s := rng.randf_range(0.04, 0.10)
		puff.scale = Vector2.ONE * s
		puff.modulate.a = 0.0
		root.add_child(puff)
		_loop_smoke_puff(puff, size_px, speed, rng.randf_range(0.0, 1.0), rng)
	return root


func _loop_smoke_puff(puff: Sprite2D, size_px: Vector2, speed: float, delay: float, rng: RandomNumberGenerator) -> void:
	var base_pos := puff.position
	var base_scale := puff.scale
	var drift_x := size_px.x * rng.randf_range(-0.03, 0.05)
	var rise_y := -size_px.y * rng.randf_range(0.20, 0.40)
	var grow := rng.randf_range(1.3, 2.0)
	var life := rng.randf_range(1.5, 2.8) / speed
	var tween := puff.create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		if is_instance_valid(puff):
			puff.position = base_pos
			puff.scale = base_scale
			puff.modulate.a = 0.0
	)
	tween.tween_property(puff, "modulate:a", 0.22, life * 0.25)
	tween.parallel().tween_property(puff, "position", base_pos + Vector2(drift_x, rise_y), life)
	tween.parallel().tween_property(puff, "scale", base_scale * grow, life)
	tween.tween_property(puff, "modulate:a", 0.0, life * 0.35)


func _make_mist_drift_prop(d: Dictionary) -> Node2D:
	## Broad low-opacity mist for forests, mountain gates, water edges and cold
	## interiors. A handful of tweened sprites share one radial texture; there is
	## no collision, shader readback or per-frame script update.
	var root := Node2D.new()
	var region_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.45, 0.16)))
	var speed := maxf(0.1, float(d.get("speed", 0.55)))
	var opacity := clampf(float(d.get("opacity", 0.14)), 0.02, 0.30)
	var direction := -1.0 if float(d.get("direction", 1.0)) < 0.0 else 1.0
	var puff_count := clampi(roundi(int(d.get("count", 4)) * _ambient_animation_density()), 1, 6)
	var color: Color = _parse_html_color(String(d.get("color", "#d6e2df")), Color(0.82, 0.88, 0.86, opacity))
	var texture := _make_radial_texture(128, Color(color.r, color.g, color.b, opacity), Color(color.r, color.g, color.b, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "mist_drift"))
	for index in range(puff_count):
		var puff := Sprite2D.new()
		puff.texture = texture
		puff.centered = true
		puff.modulate.a = 0.0
		root.add_child(puff)
		var width_scale := region_px.x / 128.0 * rng.randf_range(0.34, 0.58)
		var height_scale := region_px.y / 128.0 * rng.randf_range(0.42, 0.78)
		puff.scale = Vector2(width_scale, height_scale)
		var start_x := -region_px.x * 0.58 * direction
		var end_x := region_px.x * 0.58 * direction
		var base_y := rng.randf_range(-region_px.y * 0.32, region_px.y * 0.32)
		var life := rng.randf_range(6.0, 9.0) / speed
		var delay := (float(index) / float(puff_count)) * life * 0.65
		var tween := puff.create_tween().set_loops()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(puff):
				puff.position = Vector2(start_x, base_y)
				puff.modulate.a = 0.0
		)
		tween.tween_property(puff, "modulate:a", opacity, life * 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(puff, "position", Vector2(end_x, base_y - region_px.y * 0.08), life).set_trans(Tween.TRANS_SINE)
		tween.tween_property(puff, "modulate:a", 0.0, life * 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_water_shimmer_prop(d: Dictionary) -> Node2D:
	## Sparse reflected streaks for clearly visible rivers, canals and pools.
	## This is not a water simulation: it adds no physics and never distorts the
	## complete baked background.
	var root := Node2D.new()
	var region_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.36, 0.12)))
	var speed := maxf(0.1, float(d.get("speed", 0.65)))
	var opacity := clampf(float(d.get("opacity", 0.18)), 0.04, 0.32)
	var streak_count := clampi(roundi(int(d.get("count", 5)) * _ambient_animation_density()), 1, 8)
	var color: Color = _parse_html_color(String(d.get("color", "#b9e3ef")), Color(0.72, 0.88, 0.94, opacity))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "water_shimmer"))
	for index in range(streak_count):
		var streak := Line2D.new()
		var half_width := region_px.x * rng.randf_range(0.035, 0.080)
		var wave := rng.randf_range(1.0, 3.0)
		streak.points = PackedVector2Array([Vector2(-half_width, 0.0), Vector2(0.0, -wave), Vector2(half_width, 0.0)])
		streak.width = rng.randf_range(1.2, 2.4)
		streak.default_color = Color(color.r, color.g, color.b, 1.0)
		streak.modulate.a = 0.0
		var base_position := Vector2(rng.randf_range(-region_px.x * 0.44, region_px.x * 0.44), rng.randf_range(-region_px.y * 0.40, region_px.y * 0.40))
		streak.position = base_position
		root.add_child(streak)
		var life := rng.randf_range(2.4, 4.2) / speed
		var delay := (float(index) / float(streak_count)) * life * 0.55
		var drift := Vector2(region_px.x * rng.randf_range(0.018, 0.045), region_px.y * rng.randf_range(-0.03, 0.03))
		var tween := streak.create_tween().set_loops()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(streak):
				streak.position = base_position
				streak.modulate.a = 0.0
		)
		tween.tween_property(streak, "modulate:a", opacity, life * 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(streak, "position", base_position + drift, life).set_trans(Tween.TRANS_SINE)
		tween.tween_property(streak, "modulate:a", 0.0, life * 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_snow_drift_prop(d: Dictionary) -> Node2D:
	## One shared flake texture with a bounded number of tweened sprites. Snow is
	## reserved for authored snow scenes; it does not alter navigation or camera.
	var root := Node2D.new()
	var region_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.90, 0.70)))
	var speed := maxf(0.1, float(d.get("speed", 0.75)))
	var opacity := clampf(float(d.get("opacity", 0.42)), 0.08, 0.70)
	var flake_count := clampi(roundi(int(d.get("count", 14)) * _ambient_animation_density()), 4, 18)
	var wind_x := clampf(float(d.get("wind_x", 0.24)), -0.75, 0.75)
	var color: Color = _parse_html_color(String(d.get("color", "#eef5f4")), Color(0.93, 0.97, 0.96, opacity))
	var texture := _make_radial_texture(32, Color(color.r, color.g, color.b, opacity), Color(color.r, color.g, color.b, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "snow_drift"))
	for index in range(flake_count):
		var flake := Sprite2D.new()
		flake.texture = texture
		flake.centered = true
		var flake_scale := rng.randf_range(0.08, 0.18)
		flake.scale = Vector2.ONE * flake_scale
		flake.modulate.a = 0.0
		root.add_child(flake)
		var start := Vector2(rng.randf_range(-region_px.x * 0.50, region_px.x * 0.50), -region_px.y * rng.randf_range(0.45, 0.62))
		var end := Vector2(start.x + region_px.x * wind_x * rng.randf_range(0.72, 1.20), region_px.y * rng.randf_range(0.48, 0.66))
		var life := rng.randf_range(4.6, 7.4) / speed
		var delay := (float(index) / float(flake_count)) * life * 0.72
		var tween := flake.create_tween().set_loops()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(flake):
				flake.position = start
				flake.modulate.a = 0.0
		)
		tween.tween_property(flake, "modulate:a", opacity, life * 0.12)
		tween.parallel().tween_property(flake, "position", end, life).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(flake, "rotation", rng.randf_range(-1.2, 1.2), life)
		tween.tween_property(flake, "modulate:a", 0.0, life * 0.16)
	return root


func _make_rain_field_prop(d: Dictionary) -> Node2D:
	## A camera-safe rain sheet with two procedural depth layers. The cold tint
	## sits behind actors while streaks pass in front, so characters remain clear.
	var root := Node2D.new()
	var region_px := _norm_size_to_screen(d.get("size", Vector2(1.04, 1.04)))
	var speed := maxf(0.1, float(d.get("speed", 1.0)))
	var intensity := clampf(float(d.get("intensity", 0.62)), 0.08, 1.0)
	var opacity := clampf(float(d.get("opacity", 0.52)), 0.08, 0.78)
	var wind_x := clampf(float(d.get("wind_x", 0.18)), -0.80, 0.80)
	var rain_color := _parse_html_color(String(d.get("color", "#aed1dc")), Color(0.68, 0.82, 0.87, 0.92))
	var tint_color := _parse_html_color(String(d.get("tint_color", "#18303d")), Color(0.08, 0.16, 0.21, 0.90))

	var tint := Polygon2D.new()
	tint.name = "RainColdTint"
	tint.z_index = -51
	tint.polygon = PackedVector2Array([
		region_px * Vector2(-0.5, -0.5),
		region_px * Vector2(0.5, -0.5),
		region_px * Vector2(0.5, 0.5),
		region_px * Vector2(-0.5, 0.5),
	])
	tint.color = Color(tint_color.r, tint_color.g, tint_color.b, clampf(float(d.get("tint_opacity", 0.16)), 0.0, 0.30))
	root.add_child(tint)

	var rain_quad := ColorRect.new()
	rain_quad.name = "RainStreaks"
	rain_quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rain_quad.position = region_px * -0.5
	rain_quad.size = region_px
	var rain_material := ShaderMaterial.new()
	rain_material.shader = ENVIRONMENT_RAIN_SHADER
	rain_material.set_shader_parameter("rain_color", rain_color)
	rain_material.set_shader_parameter("rain_pattern", _get_rain_pattern_texture())
	rain_material.set_shader_parameter("intensity", intensity * _ambient_animation_density())
	rain_material.set_shader_parameter("speed", speed)
	rain_material.set_shader_parameter("slant", wind_x)
	rain_material.set_shader_parameter("aspect_ratio", region_px.x / maxf(region_px.y, 1.0))
	rain_material.set_shader_parameter("phase", float(abs(hash(d.get("id", "rain_field"))) % 7919) / 79.19)
	rain_quad.material = rain_material
	rain_quad.modulate.a = opacity
	root.add_child(rain_quad)
	return root


func _get_rain_pattern_texture() -> ImageTexture:
	## Build one tiny sparse tile when the first rainy scene is entered. The old
	## shader generated several hashes per 1080P pixel every frame; sampling this
	## cached tile twice gives the same near/far depth read at a fraction of that
	## cost. The texture is retained across weather rebuilds in this field.
	if _rain_pattern_texture != null:
		return _rain_pattern_texture
	const PATTERN_SIZE := 128
	var image := Image.create(PATTERN_SIZE, PATTERN_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5241494E
	for _index in range(18):
		var start_x := rng.randi_range(2, PATTERN_SIZE - 4)
		var start_y := rng.randi_range(0, PATTERN_SIZE - 1)
		var length := rng.randi_range(8, 22)
		var alpha := rng.randf_range(0.46, 0.90)
		for step in range(length):
			var x := posmod(start_x + roundi(float(step) * 0.18), PATTERN_SIZE)
			var y := posmod(start_y + step, PATTERN_SIZE)
			var edge_fade := minf(1.0, minf(float(step + 1), float(length - step)) / 3.0)
			var value := alpha * edge_fade
			var previous := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, maxf(previous.a, value)))
			if step % 3 != 0:
				var soft_x := posmod(x + 1, PATTERN_SIZE)
				var soft_previous := image.get_pixel(soft_x, y)
				image.set_pixel(soft_x, y, Color(1.0, 1.0, 1.0, maxf(soft_previous.a, value * 0.24)))
	_rain_pattern_texture = ImageTexture.create_from_image(image)
	return _rain_pattern_texture


func _make_rain_splash_prop(d: Dictionary) -> Node2D:
	## Sparse ground response. Each reusable crown redraws at a new random point
	## every loop; count is capped so large scrolling maps do not pay per-pixel cost.
	var root := Node2D.new()
	var region_px := _norm_size_to_screen(d.get("size", Vector2(0.72, 0.18)))
	var speed := maxf(0.1, float(d.get("speed", 1.0)))
	var opacity := clampf(float(d.get("opacity", 0.46)), 0.08, 0.70)
	var splash_count := clampi(roundi(int(d.get("count", 8)) * _ambient_animation_density()), 3, 12)
	var color := _parse_html_color(String(d.get("color", "#c6e4e9")), Color(0.78, 0.90, 0.92, opacity))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "rain_splash"))
	for index in range(splash_count):
		var splash := Node2D.new()
		splash.name = "Splash_%02d" % index
		splash.modulate.a = 0.0
		root.add_child(splash)
		var crown := Line2D.new()
		crown.width = rng.randf_range(1.0, 1.7)
		crown.default_color = Color(color.r, color.g, color.b, 1.0)
		crown.antialiased = true
		crown.points = PackedVector2Array([Vector2(-7.0, 1.0), Vector2(-2.2, -3.8), Vector2(0.0, 0.0), Vector2(2.4, -3.5), Vector2(7.0, 1.0)])
		splash.add_child(crown)
		var ring := Line2D.new()
		ring.width = 1.0
		ring.default_color = Color(color.r, color.g, color.b, 0.72)
		ring.antialiased = true
		var ring_points := PackedVector2Array()
		for point_index in range(13):
			var angle := TAU * float(point_index) / 12.0
			ring_points.append(Vector2(cos(angle) * 7.5, sin(angle) * 2.2 + 1.6))
		ring.points = ring_points
		splash.add_child(ring)
		_loop_rain_splash(splash, region_px, speed, opacity, rng.randf_range(0.0, 1.1 / speed), rng)
	return root


func _loop_rain_splash(splash: Node2D, region_px: Vector2, speed: float, opacity: float, delay: float, rng: RandomNumberGenerator) -> void:
	var life := rng.randf_range(0.24, 0.38) / speed
	var pause := rng.randf_range(0.38, 0.92) / speed
	var tween := splash.create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		if is_instance_valid(splash):
			splash.position = Vector2(rng.randf_range(-region_px.x * 0.48, region_px.x * 0.48), rng.randf_range(-region_px.y * 0.46, region_px.y * 0.46))
			splash.scale = Vector2(0.38, 0.26)
			splash.modulate.a = 0.0
	)
	tween.tween_property(splash, "modulate:a", opacity, life * 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(splash, "scale", Vector2(1.10, 0.82), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(splash, "modulate:a", 0.0, life * 0.76).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(pause)


func _make_glow_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.08, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#ff8a22")), Color(1.0, 0.45, 0.12, 0.55))
	var glow: Sprite2D = Sprite2D.new()
	glow.texture = _make_radial_texture(256, color, Color(color.r, color.g, color.b, 0.0))
	glow.centered = true
	glow.scale = Vector2(size_px.x / 128.0, size_px.y / 128.0)
	glow.modulate.a = 0.45
	root.add_child(glow)
	var tween := root.create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.18, 0.65 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", 0.52, 0.65 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_radial_texture(size: int, inner: Color, outer: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var r: float = size / 2.0
	for y in range(size):
		for x in range(size):
			var dist: float = sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
			var t: float = clampf(dist, 0.0, 1.0)
			var c: Color = inner.lerp(outer, t)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _scale_value(v: Variant) -> Vector2:
	if v is Vector2:
		return v
	if v is float or v is int:
		return Vector2(float(v), float(v))
	return Vector2.ONE


func _ambient_animation_density() -> float:
	if not is_inside_tree():
		return 1.0
	var platform := get_node_or_null("/root/PlatformBridge")
	if platform != null and platform.has_method("ambient_animation_density"):
		return clampf(float(platform.call("ambient_animation_density")), 0.40, 1.0)
	return 1.0


func _parse_html_color(hex_str: String, fallback: Color) -> Color:
	var s := hex_str.strip_edges()
	if s.begins_with("#"):
		s = s.substr(1)
	if s.length() == 6:
		return Color(
			float(("0x" + s.substr(0, 2)).hex_to_int()) / 255.0,
			float(("0x" + s.substr(2, 2)).hex_to_int()) / 255.0,
			float(("0x" + s.substr(4, 2)).hex_to_int()) / 255.0,
			0.9
		)
	return fallback



func _norm_to_screen(value: Variant) -> Vector2:
	var v: Vector2 = value if value is Vector2 else Vector2.ZERO
	return Vector2(v.x * _screen_size.x, v.y * _screen_size.y)


func _norm_size_to_screen(value: Variant) -> Vector2:
	var v: Vector2 = value if value is Vector2 else Vector2(0.1, 0.1)
	return Vector2(v.x * _screen_size.x, v.y * _screen_size.y)


func _on_trigger_zone_entered(body: Node2D, data: Dictionary) -> void:
	if _resident_parked: return
	if not body.is_in_group("player"):
		return
	if LUOYANG_V3.is_v3(_current_scene):
		var foot: Vector2 = world_container.to_local(body.global_position)
		var polygon: PackedVector2Array = data.get("city_v3_interaction_polygon_px", PackedVector2Array())
		if polygon.size() < 3 or not LUOYANG_V3.safe_body(_current_scene.scene_id, foot) or not Geometry2D.is_point_in_polygon(foot, polygon): return
	if DialogPlayer.is_playing():
		return
	var trigger_id: String = String(data.get("id", ""))
	if trigger_id != "" and _trigger_events_in_flight.get(trigger_id, false):
		return
	var require_flag: String = String(data.get("require_flag", ""))
	var hide_flag: String = String(data.get("hide_flag", ""))

	if require_flag != "" and not _flag_truthy(require_flag):
		return
	if hide_flag != "" and _flag_truthy(hide_flag):
		return
	if not _quest_gate_passes(data):
		return
	var action: String = String(data.get("action", ""))

	if action != "":
		if not _city_task_action_allowed(action): return
		if trigger_id != "":
			_trigger_events_in_flight[trigger_id] = true
		# Only an explicitly activated native discovery may retry in place after
		# its real dialogue ends (including the ordinary full-bag fallback).
		var outskirts_biome: String = OUTSKIRTS.biome_for(_current_scene.scene_id) if _current_scene != null else ""
		var native_discovery: bool = not outskirts_biome.is_empty() and trigger_id == "discovery_cache" and bool(data.get("interaction_only", false)) and action == "dialog:outskirts_%s_discovery" % outskirts_biome
		if native_discovery:
			_outskirts_discovery_dialog_pending = true
		_resolve_field_action(action)
		if native_discovery:
			_outskirts_discovery_dialog_pending = false


func _on_trigger_zone_exited(body: Node2D, data: Dictionary) -> void:
	if _resident_parked: return
	if not body.is_in_group("player"):
		return
	var trigger_id: String = String(data.get("id", ""))
	if trigger_id != "":
		_trigger_events_in_flight.erase(trigger_id)


func _on_player_interacted() -> void:
	if DialogPlayer.is_playing():
		return
	if not _uses_enclosure_dispatch_memory():
		_remember_interaction_spawn()
	## 优先检测 NPC 交互
	for npc in _npc_nodes:
		if npc.try_interact():
			return
	## 其次检测出口交互
	for zone in _exit_nodes:
		if zone.try_interact():
			return
	## Finally inspect nearby scene objects. Interaction-only areas are never
	## allowed to interrupt movement on entry; they require the explicit action.
	for area in _trigger_areas:
		if not is_instance_valid(area) or not area.overlaps_body(_player):
			continue
		var trigger_data: Variant = area.get_meta("trigger_data", {})
		if trigger_data is Dictionary and bool(trigger_data.get("interaction_only", false)):
			_on_trigger_zone_entered(_player, trigger_data)
			return


func _on_player_moved(_global_pos: Vector2) -> void:
	if _scene_rebuilding or not is_instance_valid(_player) or _current_scene == null:
		return
	_update_actor_depth(_player)
	var player_spawn := _current_player_spawn()
	# Occlusion polygons and return-payload writes do not need physics-tick
	# precision. Sampling them by travelled pixels removes repeated polygon tests
	# and Dictionary mutations while keeping doorway returns visually exact.
	if (not _occluder_nodes.is_empty() or not _actor_fade_zones.is_empty()) and _sample_moved_enough(_last_occlusion_sample, player_spawn, OCCLUSION_SAMPLE_DISTANCE_PX):
		_update_dynamic_occluders(player_spawn)
		_last_occlusion_sample = player_spawn
	if _sample_moved_enough(_last_return_spawn_sample, player_spawn, RETURN_SPAWN_SAMPLE_DISTANCE_PX):
		SceneRouter.set_field_return_spawn(player_spawn)
		_last_return_spawn_sample = player_spawn
	if _encounter_locked:
		return
	# 城市、村落与安全据点只允许剧情显式发起战斗，绝不滚随机遭遇。
	if _current_scene.is_settlement:
		return
	if (_current_scene.encounter_enemy_ids.is_empty() and _current_scene.encounter_groups.is_empty()) or _current_scene.encounter_step_distance <= 0.0:
		return
	if DialogPlayer.is_playing() or not _player.can_move:
		_last_encounter_position = _player.position
		return
	var required_flag := String(_current_scene.encounter_require_flag)
	if required_flag != "" and not _flag_truthy(required_flag):
		_last_encounter_position = _player.position
		return
	_encounter_distance += _player.position.distance_to(_last_encounter_position)
	_last_encounter_position = _player.position
	if _encounter_distance < _current_scene.encounter_step_distance:
		return
	_encounter_distance = 0.0
	if randf() > clampf(_current_scene.encounter_chance, 0.0, 1.0):
		return
	_encounter_locked = true
	_player.set_can_move(false)
	var enemy_ids := _pick_random_encounter_group()
	if enemy_ids.is_empty():
		_encounter_locked = false
		_player.set_can_move(true)
		return
	_show_toast("敌影逼近！")
	await get_tree().create_timer(0.45).timeout
	SceneRouter.start_encounter(enemy_ids, _current_scene.scene_id, _current_player_spawn())


func _sample_moved_enough(previous: Vector2, current: Vector2, pixel_distance: float) -> bool:
	var pixel_delta := (current - previous) * _screen_size
	return pixel_delta.length_squared() >= pixel_distance * pixel_distance


func _pick_random_encounter_group() -> Array[StringName]:
	var result: Array[StringName] = []
	if _current_scene == null:
		return result
	if not _current_scene.encounter_groups.is_empty():
		var total_weight: float = 0.0
		for group in _current_scene.encounter_groups:
			total_weight += maxf(0.0, float(group.get("weight", 1.0)))
		var roll: float = randf() * total_weight if total_weight > 0.0 else 0.0
		for group in _current_scene.encounter_groups:
			roll -= maxf(0.0, float(group.get("weight", 1.0)))
			if roll <= 0.0:
				var raw_ids: Variant = group.get("enemy_ids", [])
				if raw_ids is Array or raw_ids is PackedStringArray:
					for raw_id in raw_ids:
						var enemy_id := StringName(raw_id)
						if String(enemy_id) != "":
							result.append(enemy_id)
				return result
	if not _current_scene.encounter_enemy_ids.is_empty():
		result.append(StringName(_current_scene.encounter_enemy_ids.pick_random()))
	return result


func get_city_task_projection_state() -> Dictionary:
	return _city_tasks_receipt.duplicate(true)

func _city_task_dialog_allowed(id: String) -> bool:
	if ELEVEN_ROOMS.is_room(_current_scene): return not _resident_parked and ELEVEN_ROOMS.dialog_allowed(_current_scene,id)
	if FUNCTIONAL_INTERIORS.owns_dialog(id): return not _resident_parked and FUNCTIONAL_INTERIORS.dialog_allowed(_current_scene,id)
	if not CITY_TASKS.owns_dialog(id): return true
	return not _resident_parked and CITY_TASKS.authorize_dialog(id,GameState.flags.duplicate(true),QuestManager.states.duplicate(true))

func _city_task_action_allowed(action: String) -> bool:
	return _city_task_dialog_allowed(action.trim_prefix("dialog:")) if action.begins_with("dialog:") else true

func _resolve_field_action(action: String) -> void:
	if not _city_task_action_allowed(action): return
	# Movement retains its low-frequency return cache. An explicit action must
	# capture the final feet, including the last <3px before a spar/other modal.
	_remember_interaction_spawn()
	if action.begins_with("outskirts_entry:"):
		var biome := action.trim_prefix("outskirts_entry:")
		if not OUTSKIRTS.ENTRIES.has(biome) or _current_scene == null: return
		var entry: Dictionary = OUTSKIRTS.ENTRIES[biome]
		if _current_scene.scene_id != entry.source: return
		var data: Dictionary = OUTSKIRTS.authoring_contract(biome)
		if data.is_empty(): return
		if not is_instance_valid(_player) or not _spawn_has_foot_clearance(_current_scene, _outskirts_source_player_foot()): return
		for zone: ExitZone in _exit_nodes:
			if is_instance_valid(zone) and zone.target_scene_id == String(entry.scene):
				zone.try_interact()
				break
		return
	## Preserve the exact exploration position when a local event starts battle.
	if action.begins_with("battle:"):
		var enemy_id := action.trim_prefix("battle:")
		if not enemy_id.is_empty() and _current_scene != null:
			SceneRouter.start_battle(enemy_id, _current_scene.scene_id, _current_player_spawn())
		return
	if action.begins_with("battle_solo:"):
		var enemy_id := action.trim_prefix("battle_solo:")
		if not enemy_id.is_empty() and _current_scene != null:
			SceneRouter.start_solo_battle(enemy_id, _current_scene.scene_id, _current_player_spawn())
		return
	if action.begins_with("battle_group:"):
		var enemy_csv := action.trim_prefix("battle_group:")
		if not enemy_csv.is_empty() and _current_scene != null:
			SceneRouter.start_encounter_csv(enemy_csv, _current_scene.scene_id, _current_player_spawn())
		return
	if action.begins_with("battle_group_then:"):
		var parts := action.split(":", true, 2)
		var enemy_csv := parts[1] if parts.size() > 1 else ""
		var dialog_id := parts[2] if parts.size() > 2 else ""
		if not enemy_csv.is_empty() and _current_scene != null:
			var victory_action := "dialog:%s" % dialog_id if not dialog_id.is_empty() else ""
			SceneRouter.start_encounter_csv(enemy_csv, _current_scene.scene_id, _current_player_spawn(), victory_action)
		return
	if action.begins_with("battle_solo_then:"):
		var parts := action.split(":", true, 2)
		var enemy_id := parts[1] if parts.size() > 1 else ""
		var dialog_id := parts[2] if parts.size() > 2 else ""
		if not enemy_id.is_empty() and _current_scene != null:
			var victory_action := "dialog:%s" % dialog_id if not dialog_id.is_empty() else ""
			SceneRouter.start_solo_battle(enemy_id, _current_scene.scene_id, _current_player_spawn(), victory_action)
		return
	SceneRouter.resolve_action(action)


func _update_actor_depth(actor: Node2D) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	actor.set_meta("depth_band_max", _scene_depth_band_max())
	if actor.has_method("refresh_depth_sort"):
		actor.call("refresh_depth_sort")
		return
	# Eight-pixel bands keep nearby feet in the correct front/back order while
	# still avoiding a z-index rebuild for every single movement pixel.
	var depth_y := actor.global_position.y
	if actor.has_method("get_depth_sort_y"):
		depth_y = float(actor.call("get_depth_sort_y"))
	var depth_band := clampi(int(floor(depth_y / 8.0)), 0, _scene_depth_band_max())
	if actor.z_index != depth_band:
		actor.z_index = depth_band


func _scene_depth_band_max() -> int:
	if SceneRouter.WORLD_V15.is_v15(_current_scene): return 1024
	return 512 if SceneRouter.WORLD_V14.is_v14(_current_scene) else 255


func _uses_enclosure_dispatch_memory() -> bool:
	return _current_scene != null and _current_scene.scene_id in [
		&"ch4_s0_luoyang_gate", &"ch4_s1_luoyang_yamen",
		&"ch4_s2_canal_docks", &"ch4_s3_luoyang_market",
	] and _current_scene.has_meta("city_enclosure_manifest_sha") and LUOYANG_V3.is_v3(_current_scene)


func _remember_interaction_spawn() -> void:
	if _scene_rebuilding or _current_scene == null or not is_instance_valid(_player):
		return
	var exact_spawn := _current_player_spawn()
	SceneRouter.set_field_return_spawn(exact_spawn)
	_last_return_spawn_sample = exact_spawn


func _current_player_spawn() -> Vector2:
	if not is_instance_valid(_player) or _screen_size.x <= 0.0 or _screen_size.y <= 0.0:
		return _current_scene.player_spawn if _current_scene != null else Vector2(0.5, 0.8)
	return Vector2(
		clampf(_player.position.x / _screen_size.x, 0.0, 1.0),
		clampf(_player.position.y / _screen_size.y, 0.0, 1.0)
	)


func _on_npc_interacted(_npc_id: String, dialog_id: String) -> void:
	if _culture_x != null and _culture_x.handles(_npc_id):
		_open_culture_x_menu(_npc_id)
		return
	_on_npc_primary_dialog(_npc_id, dialog_id)


func _on_npc_primary_dialog(_npc_id: String, dialog_id: String) -> void:
	if not _city_task_dialog_allowed(dialog_id): return
	if dialog_id == "":
		return
	var path := "res://data/dialogs/%s.tres" % dialog_id
	if not ResourceLoader.exists(path):
		push_warning("[FieldWalkable] dialog not found: %s" % path)
		return
	var script: Resource = load(path)
	if script is DialogScript:
		_remember_interaction_spawn()
		var playable_script := _build_active_side_quest_followup(script as DialogScript)
		_player.set_can_move(false)
		# 传递 NPC 头像给对话系统
		for npc in _npc_nodes:
			if npc.npc_id == _npc_id:
				_active_dialog_npc = npc
				npc.begin_conversation(_player.global_position)
				_player.set_walk_direction(npc.global_position - _player.global_position, false)
				DialogPlayer.set_default_portrait(npc.portrait_path)
				DialogPlayer.set_default_speaker(npc.npc_name)
				break
		DialogPlayer.play(playable_script)
		EventBus.npc_talked_to.emit(StringName(_npc_id))


func _build_active_side_quest_followup(original: DialogScript) -> DialogScript:
	## 数据已配置专属进行中对话时不会走到这里；这个兜底负责尚未补齐
	## variant 的支线NPC，避免玩家反复看到“是否接受”的初次邀约。
	if original == null:
		return original
	for node: DialogNode in original.nodes:
		if node == null or node.accept_quest == &"":
			continue
		var qid := node.accept_quest
		var quest := QuestManager.load_def(qid)
		if quest == null or quest.kind != QuestDef.Kind.SIDE or not QuestManager.is_active(qid):
			continue
		if _dialog_completes_quest(original, qid):
			continue
		if node.on_end.begins_with("battle:") or node.on_end.begins_with("battle_solo:") or node.on_end.begins_with("battle_group:") or node.on_end.begins_with("battle_group_then:") or node.on_end.begins_with("battle_solo_then:") or node.on_end.begins_with("spar:"):
			continue
		var followup := DialogScript.new()
		followup.dialog_id = StringName("runtime_followup_%s" % String(qid))
		followup.entry_node_id = &"start"
		var npc_line := DialogNode.new()
		npc_line.node_id = &"start"
		npc_line.text = "“%s”有进展了吗？" % quest.title
		npc_line.on_end = "next:reply"
		var player_line := DialogNode.new()
		player_line.node_id = &"reply"
		player_line.speaker = "冷孤云"
		player_line.portrait_path = "res://art/characters/protagonist_portrait.png"
		player_line.text = "还在查找。等有了结果，我会回来告诉你。"
		player_line.on_end = "end"
		followup.nodes.assign([npc_line, player_line])
		return followup
	return original


func _dialog_completes_quest(script: DialogScript, qid: StringName) -> bool:
	for node: DialogNode in script.nodes:
		if node != null and node.complete_quest == qid:
			return true
	return false


func _on_npc_action_requested(npc_id: String, action: String) -> void:
	if action == "culture_x_menu":
		_open_culture_x_menu(npc_id)
		return
	_on_npc_primary_action(npc_id, action)


func _on_npc_primary_action(npc_id: String, action: String) -> void:
	if action.is_empty() or DialogPlayer.is_playing():
		return
	if not _city_task_action_allowed(action): return
	if action.begins_with("spar:"):
		_play_sparring_preface(npc_id, action)
		return
	EventBus.npc_talked_to.emit(StringName(npc_id))
	_resolve_field_action(action)


func _play_sparring_preface(npc_id: String, action: String) -> void:
	# These are the existing confirmation acceptance gates. Capture once before
	# either the normal invitation locks movement or the no-NPC modal fallback.
	if _uses_enclosure_dispatch_memory() and action.begins_with("spar:") and action.split(":", false).size() >= 6 and _sparring_confirm_dialog != null:
		_remember_interaction_spawn()
	var npc: NPCNode = null
	for candidate in _npc_nodes:
		if candidate != null and candidate.npc_id == npc_id:
			npc = candidate
			break
	if npc == null:
		_show_sparring_confirmation(npc_id, action)
		return
	_active_dialog_npc = npc
	npc.begin_conversation(_player.global_position)
	_player.set_walk_direction(npc.global_position - _player.global_position, false)
	_player.set_can_move(false)
	DialogPlayer.set_default_portrait(npc.portrait_path)
	DialogPlayer.set_default_speaker(npc.npc_name)
	_pending_sparring_npc_id = npc_id
	var opponent_name := _sparring_opponent_name(action, npc.npc_name)
	var preface := DialogScript.new()
	preface.dialog_id = StringName("runtime_spar_preface_%s" % npc_id)
	preface.entry_node_id = &"invite"
	var invite := DialogNode.new()
	invite.node_id = &"invite"
	invite.text = "江湖路远，招式贵在印证。%s抱拳一礼：若不嫌弃，可与我点到为止，彼此看看手上功夫。" % opponent_name
	invite.choices = [
		{"text": "请赐教", "next": "ready"},
		{"text": "今日先不打扰", "next": "end"},
	]
	var ready := DialogNode.new()
	ready.node_id = &"ready"
	ready.text = "好。刀兵无眼，心里有数便好。摆开架势吧。"
	ready.on_end = action
	preface.nodes.assign([invite, ready])
	DialogPlayer.play(preface)


func _sparring_opponent_name(action: String, fallback: String) -> String:
	var parts := action.split(":", false)
	return String(parts[3]) if parts.size() > 3 and not String(parts[3]).is_empty() else fallback


func _on_dialog_spar_requested(action_payload: String) -> void:
	var npc_id := _pending_sparring_npc_id
	if npc_id.is_empty() and is_instance_valid(_active_dialog_npc):
		npc_id = _active_dialog_npc.npc_id
	_show_sparring_confirmation(npc_id, "spar:" + action_payload)


func _init_sparring_confirmation() -> void:
	_sparring_confirm_dialog = FORMAL_CONFIRM_SCENE.instantiate() as FormalConfirmDialog
	_sparring_confirm_dialog.name = "SparringConfirmation"
	_sparring_confirm_dialog.confirmed.connect(_confirm_sparring)
	_sparring_confirm_dialog.cancelled.connect(_cancel_sparring_confirmation)
	_system_ui_canvas_layer.add_child(_sparring_confirm_dialog)


func _show_sparring_confirmation(npc_id: String, action: String) -> void:
	var parts := action.split(":", false)
	if parts.size() < 6 or _sparring_confirm_dialog == null:
		push_warning("[FieldWalkable] invalid sparring action: %s" % action)
		return
	var spar_id := String(parts[1])
	var opponent_name := String(parts[3])
	var win_reward := maxi(0, int(parts[4]))
	var loss_reward := maxi(0, int(parts[5]))
	var record: Dictionary = GameState.sparring_records.get(spar_id, {})
	var reward_note: String
	if bool(record.get("won", false)):
		reward_note = "[color=#92a8aa]你已取得首胜，本次复战没有阅历、经验、金钱或掉落，仅供试招。[/color]"
	elif bool(record.get("loss_reward_claimed", false)):
		reward_note = "[color=#e5c47b]首胜可得阅历 %d。[/color]\n首次败北奖励已领取，再次落败没有奖励。" % win_reward
	else:
		reward_note = "[color=#e5c47b]首次胜利：阅历 %d[/color]\n首次落败：阅历 %d（仅一次，且不影响之后领取首胜奖励）" % [win_reward, loss_reward]
	_pending_sparring_action = action
	_pending_sparring_npc_id = npc_id
	if _player != null:
		_player.set_can_move(false)
	_sparring_confirm_dialog.show_confirm(
		"与%s切磋" % opponent_name,
		"[center]%s\n\n切磋点到为止，战后恢复到切磋前的气血与内力。[/center]" % reward_note,
		"开始切磋",
		"暂不"
	)


func _confirm_sparring() -> void:
	var action := _pending_sparring_action
	var npc_id := _pending_sparring_npc_id
	_pending_sparring_action = ""
	_pending_sparring_npc_id = ""
	if action.is_empty():
		_restore_player_after_sparring_prompt()
		return
	EventBus.npc_talked_to.emit(StringName(npc_id))
	_resolve_field_action(action)


func _cancel_sparring_confirmation() -> void:
	_pending_sparring_action = ""
	_pending_sparring_npc_id = ""
	_restore_player_after_sparring_prompt()


func _restore_player_after_sparring_prompt() -> void:
	if _player != null and not DialogPlayer.is_playing() and not _system_panel_open:
		_player.set_can_move(true)


func _generic_npc_portrait(npc_id: String) -> String:
	# Non-critical NPCs use a small reusable portrait set. Important characters
	# keep their authored portrait_path in scene data and never enter this branch.
	var id := npc_id.to_lower()
	if id.contains("woman") or id.contains("妇") or id.contains("guest"):
		return "res://art/characters/portraits/generic/portrait_generic_young_woman_v1.png"
	if id.contains("old") or id.contains("elder") or id.contains("keeper") or id.contains("掌柜"):
		return "res://art/characters/portraits/generic/portrait_generic_older_man_v1.png"
	if id.contains("vendor") or id.contains("wife"):
		return "res://art/characters/portraits/generic/portrait_generic_older_woman_v1.png"
	return "res://art/characters/portraits/generic/portrait_generic_young_man_v1.png"


func _on_exit_triggered(target_scene: String, target_pos: Vector2, source_portal_spawn: Vector2) -> void:
	# Interior excursions remember the real safe feet used for Space, not just
	# the fixed doorway marker. The room's authored exit remains separately bound.
	if _current_scene!=null and _current_scene.scene_id in FUNCTIONAL_INTERIORS.CITIES and LUOYANG_V3.revision_room_known(StringName(target_scene)):
		var actual:=resident_actual_spawn()
		if not LUOYANG_V3.safe_body(_current_scene.scene_id,actual*LUOYANG_V3.SIZE): return
		source_portal_spawn=actual
	var outskirts_biome := OUTSKIRTS.biome_for(StringName(target_scene))
	if not outskirts_biome.is_empty():
		var entry: Dictionary = OUTSKIRTS.ENTRIES[outskirts_biome]
		if _current_scene == null or _current_scene.scene_id != entry.source or OUTSKIRTS.authoring_contract(outskirts_biome).is_empty(): return
		if not _spawn_has_foot_clearance(_current_scene, entry.source_pos) or not _spawn_has_foot_clearance(_current_scene, _outskirts_source_player_foot()): return
	if StringName(target_scene) == SceneRouter.WORLD_MAP_SCENE:
		if _uses_enclosure_dispatch_memory():
			_remember_interaction_spawn()
		SceneRouter.go_world_map(target_pos)
	else:
		# Remember the authored door anchor, not the last movement sample. The
		# latter may be outside the doorway (mouse interaction radius) or stale by
		# several pixels, which caused room exits to return at unrelated locations.
		SceneRouter.go_field_from_portal(StringName(target_scene), target_pos, source_portal_spawn)

func _outskirts_source_player_foot() -> Vector2:
	if not is_instance_valid(_player): return Vector2(INF, INF)
	return (_player.position + Vector2(0, float(_player.call("_visual_foot_offset")))) / _world_size

func _outskirts_portal_clearance(point: Vector2) -> bool:
	return _current_scene != null and _spawn_has_foot_clearance(_current_scene, point)


func _flag_truthy(key: String) -> bool:
	var v: Variant = GameState.flags.get(key, null)
	if v == null: return false
	if typeof(v) == TYPE_BOOL: return v
	if typeof(v) == TYPE_INT: return v != 0
	if typeof(v) == TYPE_STRING: return v != ""
	return true


# --- UI 样式（与 field_controller.gd 保持一致）---

func _init_field_ui_styles() -> void:
	_hud_btn_normal = _make_hud_style(Color(0.040, 0.058, 0.074, 0.94))
	_hud_btn_hover = _make_hud_style(Color(0.055, 0.145, 0.145, 0.98))
	for b in [inventory_btn, equipment_btn, skill_btn, quest_log_btn]:
		_style_hud_button(b)
	UI_THEME.style_label(scene_title, 24, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(player_info, 18, UI_THEME.TEXT, false)
	UI_THEME.style_label(hud_gold, 18, UI_THEME.GOLD, false)
	UI_THEME.style_rich_text(quest_list, 15)
	quest_list.visible = false
	quest_log_btn.visible = false
	UI_THEME.style_label(hint_label, 13, Color(0.78, 0.88, 0.90, 0.86), false)


func _make_hud_style(c: Color) -> StyleBoxFlat:
	var s := UI_THEME.button_style(c, UI_THEME.BLUE_STEEL, 8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _hud_asset(name: String) -> String:
	return HUD_ART_DIR + "/hud_" + name + ".png"


func _make_tex_rect(node_name: String, asset_name: String, pos: Vector2, sz: Vector2) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.name = node_name
	r.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset(asset_name))
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = sz
	return r


func _init_formal_hud() -> void:
	_primary_hud = FIELD_PRIMARY_HUD_SCENE.instantiate()
	_primary_hud.name = "FieldPrimaryHud"
	_hud_canvas_layer.add_child(_primary_hud)
	_formal_hud_layer = _primary_hud
	_primary_hud.inventory_pressed.connect(_toggle_inventory_panel)
	_primary_hud.equipment_pressed.connect(_toggle_equipment_panel)
	_primary_hud.skill_pressed.connect(_toggle_skill_panel)
	_primary_hud.quest_pressed.connect(_toggle_quest_log_panel)
	_primary_hud.system_pressed.connect(_open_system_menu)


func _apply_formal_hud_mode() -> void:
	if scene_title != null:
		scene_title.visible = false
	if player_info != null:
		player_info.visible = false
	if hud_gold != null:
		hud_gold.visible = false
	if quest_list != null:
		quest_list.visible = false
	if hint_bar != null:
		hint_bar.visible = false
	if inventory_btn != null:
		inventory_btn.visible = false
	if equipment_btn != null:
		equipment_btn.visible = false
	if skill_btn != null:
		skill_btn.visible = false
	if quest_log_btn != null:
		quest_log_btn.visible = false
	# The formal HUD owns the textured system button. Keep the legacy plain
	# Button wired for compatibility, but never show two menu controls.
	if system_btn != null:
		system_btn.visible = false


func _build_player_info_panel() -> void:
	var panel := _make_tex_rect("PlayerPanel", "player_panel", Vector2(10, 10), Vector2(340, 98))
	_formal_hud_layer.add_child(panel)

	var portrait: TextureRect = TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = Vector2(22, 22)
	portrait.size = Vector2(44, 44)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var pp: String = GameState.player.portrait_path if GameState.player != null else ""
	if pp == "":
		pp = "res://art/characters/protagonist_neutral.png"
	if ResourceLoader.exists(pp):
		portrait.texture = load(pp)
	_formal_hud_layer.add_child(portrait)
	_formal_portrait = portrait

	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(76, 14)
	name_label.size = Vector2(180, 18)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", UI_THEME.TEXT)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	_formal_hud_layer.add_child(name_label)
	_formal_name_label = name_label

	var hp_label: Label = Label.new()
	hp_label.name = "HpLabel"
	hp_label.position = Vector2(76, 40)
	hp_label.size = Vector2(30, 14)
	hp_label.text = "生命"
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82, 0.85))
	_formal_hud_layer.add_child(hp_label)

	var hp_bg: TextureRect = TextureRect.new()
	hp_bg.name = "HpBg"
	hp_bg.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("hp_bg"))
	hp_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_bg.stretch_mode = TextureRect.STRETCH_SCALE
	hp_bg.position = Vector2(108, 40)
	hp_bg.size = Vector2(160, 14)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(hp_bg)

	var hp_fill: TextureRect = TextureRect.new()
	hp_fill.name = "HpFill"
	hp_fill.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("hp_fill"))
	hp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	hp_fill.position = Vector2(108, 40)
	hp_fill.size = Vector2(160, 14)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(hp_fill)
	_formal_hp_bar = hp_fill

	var mp_label: Label = Label.new()
	mp_label.name = "MpLabel"
	mp_label.position = Vector2(76, 60)
	mp_label.size = Vector2(30, 14)
	mp_label.text = "内力"
	mp_label.add_theme_font_size_override("font_size", 11)
	mp_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82, 0.85))
	_formal_hud_layer.add_child(mp_label)

	var mp_bg: TextureRect = TextureRect.new()
	mp_bg.name = "MpBg"
	mp_bg.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("mp_bg"))
	mp_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mp_bg.stretch_mode = TextureRect.STRETCH_SCALE
	mp_bg.position = Vector2(108, 60)
	mp_bg.size = Vector2(160, 14)
	mp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(mp_bg)

	var mp_fill: TextureRect = TextureRect.new()
	mp_fill.name = "MpFill"
	mp_fill.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("mp_fill"))
	mp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	mp_fill.position = Vector2(108, 60)
	mp_fill.size = Vector2(160, 14)
	mp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(mp_fill)
	_formal_mp_bar = mp_fill

	var gold_label: Label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.position = Vector2(76, 78)
	gold_label.size = Vector2(180, 16)
	gold_label.add_theme_font_size_override("font_size", 13)
	gold_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.50, 0.94))
	gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))
	gold_label.add_theme_constant_override("shadow_offset_x", 1)
	gold_label.add_theme_constant_override("shadow_offset_y", 1)
	_formal_hud_layer.add_child(gold_label)
	_formal_gold_label = gold_label


func _build_scene_name_badge() -> void:
	var badge := _make_tex_rect("SceneBadgeBg", "scene_badge", Vector2(1730, 10), Vector2(180, 26))
	_formal_hud_layer.add_child(badge)
	var label: Label = Label.new()
	label.name = "FormalSceneLabel"
	label.position = badge.position
	label.size = badge.size
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.94, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formal_hud_layer.add_child(label)
	_formal_scene_label = label


func _build_quest_display() -> void:
	var panel := _make_tex_rect("QuestPanel", "quest_panel", Vector2(1600, 46), Vector2(300, 100))
	_formal_hud_layer.add_child(panel)


func _build_bottom_bar() -> void:
	var bar := _make_tex_rect("BottomBar", "bottom_bar", Vector2(0, 937), Vector2(1920, 143))
	_formal_hud_layer.add_child(bar)
	_formal_bottom_bar = bar
	var label: Label = Label.new()
	label.name = "FormalHintLabel"
	label.position = Vector2(0, 955)
	label.size = Vector2(1920, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.94, 0.90))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formal_hud_layer.add_child(label)
	_formal_hint_label = label


func _init_hud_right_buttons() -> void:
	var btn_keys := ["inventory", "equipment", "skill", "quest", "system"]
	var positions := [
		Vector2(1670, 120),
		Vector2(1670, 218),
		Vector2(1670, 316),
		Vector2(1670, 414),
		Vector2(1670, 512),
	]
	for i in range(btn_keys.size()):
		var key: String = btn_keys[i]
		var tex_normal := UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_normal"))
		if tex_normal == null:
			continue
		var btn: TextureButton = TextureButton.new()
		btn.name = "FormalBtn_" + key.capitalize()
		btn.texture_normal = tex_normal
		btn.texture_hover = UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_hover"))
		btn.texture_pressed = UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_pressed"))
		btn.position = positions[i]
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		_formal_hud_layer.add_child(btn)
		match key:
			"inventory": btn.pressed.connect(_toggle_inventory_panel)
			"equipment": btn.pressed.connect(_toggle_equipment_panel)
			"skill": btn.pressed.connect(_toggle_skill_panel)
			"quest": btn.pressed.connect(_toggle_quest_log_panel)
func _style_hud_button(btn: Button) -> void:
	UI_THEME.style_button(btn, 16, UI_THEME.BLUE_STEEL)
	btn.add_theme_stylebox_override("normal", _hud_btn_normal)
	btn.add_theme_stylebox_override("hover", _hud_btn_hover)
	btn.add_theme_stylebox_override("pressed", _hud_btn_hover)
	btn.add_theme_stylebox_override("focus", _hud_btn_hover)
	btn.add_theme_color_override("font_color", UI_THEME.TEXT)


# --- 信号回调 ---

func _on_flag_set(_flag: StringName, _v: Variant) -> void:
	if _culture_committing:
		_scene_refresh_pending = true
		return
	## flag 变化可能解锁/隐藏 NPC/出口/触发区，重新生成场景元素。
	## 对话中重建会把玩家原地放进新的 Area2D，造成同一对话再次触发。
	if DialogPlayer.is_playing():
		_scene_refresh_pending = true
		return
	_refresh_scene_preserving_player()


func _on_active_quests_changed() -> void:
	_refresh_quest_panel()
	if _culture_committing:
		_scene_refresh_pending = true
		return
	# 采集物、任务宝箱等场景元素以任务状态为显示条件。接受或完成
	# 任务后必须重建当前场景，不能等玩家切图后才看到变化。
	if DialogPlayer.is_playing():
		_scene_refresh_pending = true
		return
	_refresh_scene_preserving_player()


func _quest_gate_passes(data: Dictionary) -> bool:
	var active_qid := StringName(String(data.get("require_quest_active", "")))
	if active_qid != &"" and not QuestManager.is_active(active_qid):
		return false
	var completed_qid := StringName(String(data.get("require_quest_completed", "")))
	if completed_qid != &"" and not QuestManager.is_completed(completed_qid):
		return false
	return true


func _refresh_scene_preserving_player() -> void:
	if _current_scene == null or _scene_rebuilding:
		return
	if SceneRouter.RESIDENT_CITY.extended_enabled() and LUOYANG_V3.owns_id(_current_scene.scene_id) and not LUOYANG_V3.resident_receipt(_current_scene).is_empty():
		_scene_rebuilding=true
		if is_instance_valid(_player): _player.set_can_move(false)
		# Flag changes may originate in a physics callback. Mutate bodies outside
		# that flushing query and coalesce multiple same-frame quest signals.
		await get_tree().process_frame
		if not is_inside_tree() or _resident_parked: _scene_rebuilding=false; return
		var refreshed: bool=await _resident_refresh_dynamic()
		_scene_rebuilding=false
		if not refreshed:
			_field_loading_failed=true; _field_loading_complete=false; _field_loading_stage="城市动态投影失败"
		elif is_instance_valid(_player) and not DialogPlayer.is_playing(): _player.set_can_move(true)
		return
	var spawn := _current_scene.player_spawn
	if is_instance_valid(_player) and _screen_size.x > 0.0 and _screen_size.y > 0.0:
		spawn = Vector2(
			clampf(_player.position.x / _screen_size.x, 0.0, 1.0),
			clampf(_player.position.y / _screen_size.y, 0.0, 1.0)
		)
	_setup_scene(_current_scene, spawn)


func _apply_pending_scene_refresh() -> void:
	if not _scene_refresh_pending:
		return
	_scene_refresh_pending = false
	_refresh_scene_preserving_player()


func _on_gold_changed(_n: int) -> void:
	_refresh_gold()


func _on_reputation_changed(_value: int, _title: String) -> void:
	_refresh_gold()


func _on_dialog_started(_id: StringName) -> void:
	if _outskirts_discovery_dialog_pending and OUTSKIRTS.is_native(_current_scene):
		_outskirts_discovery_dialog_id = _id
		_outskirts_discovery_dialog_pending = false
	if is_instance_valid(_player):
		_player.set_can_move(false)
	if _primary_hud != null:
		_primary_hud.set_hint_visible(false)
	if _formal_bottom_bar != null:
		_formal_bottom_bar.visible = false
	if _formal_hint_label != null:
		_formal_hint_label.visible = false

func _on_dialog_ended(_id: StringName) -> void:
	var culture_primary: Dictionary = {}
	if _culture_x != null:
		_culture_committing = true
		var culture: Dictionary = _culture_x.finish(_id)
		_culture_committing = false
		if culture.get("ignore_stale_dialog_end", false): return
		if culture.get("ok") != true:
			_show_toast("本次核对未能确认，进度未变。")
		elif culture.get("primary") is Dictionary:
			culture_primary = culture
		elif culture.get("feedback") is DialogScript:
			if is_instance_valid(_active_dialog_npc):
				DialogPlayer.set_default_portrait(_active_dialog_npc.portrait_path)
				DialogPlayer.set_default_speaker(_active_dialog_npc.npc_name)
			DialogPlayer.play(culture.feedback)
			return
	if OUTSKIRTS.is_native(_current_scene) and _outskirts_discovery_dialog_id != &"" and _id == _outskirts_discovery_dialog_id:
		_trigger_events_in_flight.erase("discovery_cache")
		_outskirts_discovery_dialog_id = &""
	if is_instance_valid(_active_dialog_npc):
		_active_dialog_npc.end_conversation()
	_active_dialog_npc = null
	if is_instance_valid(_player) and not _scene_rebuilding and not (_sparring_confirm_dialog != null and _sparring_confirm_dialog.visible):
		_player.set_can_move(true)
	if _primary_hud != null:
		_primary_hud.set_hint_visible(true)
	if _formal_bottom_bar != null:
		_formal_bottom_bar.visible = true
	if _formal_hint_label != null:
		_formal_hint_label.visible = true
	if _scene_refresh_pending:
		call_deferred("_apply_pending_scene_refresh")
	if not culture_primary.is_empty(): call_deferred("_play_culture_x_primary", culture_primary)


func _on_culture_x_text_displayed(_speaker: String, _text: String, _choices: bool, _portrait: String) -> void:
	if _culture_x != null: _culture_x.observe_node()


func _open_culture_x_menu(npc_id: String) -> void:
	if _culture_x == null or DialogPlayer.is_playing() or _resident_parked or _scene_rebuilding: return
	var opened: Dictionary = _culture_x.open(npc_id)
	if opened.get("ok") != true:
		_show_toast("先靠近当事人，再核对这件事。")
		return
	_remember_interaction_spawn()
	_active_dialog_npc = opened.npc
	_active_dialog_npc.begin_conversation(_player.global_position)
	_player.set_walk_direction(_active_dialog_npc.global_position - _player.global_position, false)
	_player.set_can_move(false)
	DialogPlayer.set_default_portrait(_active_dialog_npc.portrait_path)
	DialogPlayer.set_default_speaker(_active_dialog_npc.npc_name)
	DialogPlayer.play(opened.script)


func _play_culture_x_primary(result: Dictionary) -> void:
	if _culture_x == null or not _culture_x.handles(String(result.get("npc_id", ""))) or DialogPlayer.is_playing(): return
	for npc: NPCNode in _npc_nodes:
		if is_instance_valid(npc) and npc.npc_id == result.npc_id and npc.global_position.distance_to(_player.global_position) <= 118.0:
			var primary: Dictionary = result.primary
			if not String(primary.get("interaction_action", "")).is_empty(): _on_npc_primary_action(npc.npc_id, primary.interaction_action)
			elif not String(primary.get("dialog_id", "")).is_empty(): _on_npc_primary_dialog(npc.npc_id, primary.dialog_id)
			return


func get_culture_integration_state() -> Dictionary:
	return _culture_x.debug_state() if _culture_x != null else {"enabled": false, "session_active": false}


func _refresh_gold() -> void:
	var p: CharacterStats = GameState.player
	if p != null:
		if player_info != null:
			player_info.text = "%s  Lv.%d  生命 %d/%d  内力 %d/%d" % [p.display_name, p.level, p.hp, p.max_hp, p.mp, p.max_mp]
		if _formal_name_label != null:
			_formal_name_label.text = "%s  Lv.%d" % [p.display_name, p.level]
		if _formal_hp_bar != null:
			_formal_hp_bar.size.x = 160.0 * clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
		if _formal_mp_bar != null:
			_formal_mp_bar.size.x = 160.0 * clampf(float(p.mp) / float(p.max_mp), 0.0, 1.0)
		if _primary_hud != null:
			_primary_hud.set_player_stats(p, GameState.gold)
	if hud_gold != null:
		hud_gold.text = "金 %d · 声望 %d" % [GameState.gold, GameState.reputation]
	if _formal_gold_label != null:
		_formal_gold_label.text = "金 %d" % GameState.gold
	if _primary_hud != null and p == null:
		_primary_hud.set_hint_text("WASD 移动   空格/Enter 交互   C 角色   K 武学   J 任务   Esc 关闭")


func _refresh_quest_panel() -> void:
	if quest_list == null:
		return
	var actives := QuestManager.get_active_quests()
	if actives.is_empty():
		quest_list.text = "[i]暂无任务[/i]"
		if _primary_hud != null:
			_primary_hud.set_quest_tracker("", "", "", "")
		return
	var lines: Array[String] = []
	for q in actives:
		var prefix: String = "[color=#e3a64a]●[/color] " if (q as QuestDef).kind == QuestDef.Kind.MAIN else "[color=#88aabb]○[/color] "
		lines.append("%s[b]%s[/b]\n  %s" % [prefix, (q as QuestDef).title, (q as QuestDef).desc_in_progress])
	quest_list.text = "\n\n".join(lines)
	if _primary_hud != null:
		var main_quest := QuestManager.get_current_main_quest()
		var tracked_side := QuestManager.get_tracked_side_quest()
		_primary_hud.set_quest_tracker(
			main_quest.title if main_quest != null else "",
			main_quest.get_tracker_hint() if main_quest != null else "",
			tracked_side.title if tracked_side != null else "",
			tracked_side.get_tracker_hint() if tracked_side != null else ""
		)


func _on_tracked_quest_changed(_qid: StringName) -> void:
	_refresh_quest_panel()


func _on_quest_accepted(qid: StringName) -> void:
	var def: QuestDef = QuestManager.load_def(qid)
	if def == null:
		return
	_item_toast_lines.append("[color=#72d2a6]接收任务：[/color][color=#f0d8ad]%s[/color]" % def.title)
	_show_item_toast()


func _on_quest_progressed(qid: StringName) -> void:
	var def := QuestManager.load_def(qid)
	if def == null:
		return
	var records := QuestManager.get_progress_record_texts(qid)
	var latest := records[-1] if not records.is_empty() else "发现了新的调查进展"
	_item_toast_lines.append("[color=#e3a64a]任务推进：[/color][color=#f0d8ad]%s[/color]\n[color=#9fd3d0]%s[/color]" % [def.title, latest])
	_show_item_toast()


func _on_evidence_acquired(evidence_id: StringName) -> void:
	var evidence := InvestigationState.load_evidence_def(evidence_id)
	if evidence == null:
		return
	_item_toast_lines.append("[color=#e3a64a]获得线索：[/color][color=#72d2c9]%s[/color]" % evidence.display_name)
	_show_item_toast()


func _on_companion_joined(_companion_id: StringName, display_name: String) -> void:
	_item_toast_lines.append("[color=#e3a64a]队友加入：[/color][color=#72d2a6]%s[/color]" % display_name)
	_show_item_toast()


func _on_quest_completed(qid: StringName) -> void:
	var def: QuestDef = QuestManager.load_def(qid)
	if def != null:
		print("[FieldWalkable] quest completed → %s（gold +%d, exp +%d）" % [def.title, def.reward_gold, def.reward_exp])
		_item_toast_lines.append("[color=#e3a64a]完成任务：[/color][color=#f0d8ad]%s[/color]" % def.title)
		_show_item_toast()


func _on_item_picked_up(item_id: StringName, count: int) -> void:
	var item := Inventory.load_item_by_id(item_id)
	var display_name := String(item_id)
	var q_color: String = "#c0c8d0"
	if item != null:
		display_name = item.display_name
		if item.category == Item.Category.CONSUMABLE:
			q_color = "#e3a64a"
		else:
			q_color = _quality_color(item.quality)
	_item_toast_lines.append("[color=#8899aa]获得[/color] [color=%s]%s[/color] × %d" % [q_color, display_name, count])
	if item_id == &"linxi_iron_sword" and not bool(GameState.flags.get("seen_linxi_sword_equip_tip", false)):
		_item_toast_lines.append("[color=#e3a64a]提示：[/color][color=#9fd3d0]装备剑后，方可使用林西剑法。[/color]")
		GameState.set_flag(&"seen_linxi_sword_equip_tip", true)
	_show_item_toast()


func _on_skill_learned(skill_id: StringName, display_name: String) -> void:
	var skill_path := "res://data/skills/%s.tres" % String(skill_id)
	var skill := load(skill_path) as Skill if ResourceLoader.exists(skill_path) else null
	var quality_color := _quality_color(skill.quality) if skill != null else "#c0c8d0"
	var learned_type := "心法" if skill != null and skill.is_internal_art else "招式"
	_item_toast_lines.append("[color=#e3a64a]学会%s：[/color][color=%s]%s[/color]" % [learned_type, quality_color, display_name])
	_show_item_toast()


func _quality_color(q: int) -> String:
	match q:
		1: return "#1eff00"
		2: return "#0070dd"
		3: return "#a335ee"
		4: return "#ff8000"
		_: return "#c0c8d0"


func _show_item_toast() -> void:
	if _item_toast == null or not is_instance_valid(_item_toast):
		_item_toast = RichTextLabel.new()
		_item_toast.bbcode_enabled = true
		_item_toast.fit_content = true
		_item_toast.position = Vector2(_viewport_size.x / 2 - 190, _viewport_size.y * 0.22)
		_item_toast.custom_minimum_size = Vector2(380, 44)
		_item_toast.add_theme_font_size_override("normal_font_size", 20)
		_item_toast.add_theme_color_override("default_color", Color(0.88, 0.92, 0.96, 1.0))
		_item_toast.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.98))
		_item_toast.add_theme_constant_override("outline_size", 5)
		_item_toast.add_theme_constant_override("line_spacing", 4)
		_hud_canvas_layer.add_child(_item_toast)
	_item_toast.text = "\n".join(_item_toast_lines)
	_item_toast_serial += 1
	var serial := _item_toast_serial
	await get_tree().create_timer(2.5).timeout
	if serial != _item_toast_serial or not is_instance_valid(_item_toast):
		return
	_item_toast_lines.clear()
	_item_toast.queue_free()
	_item_toast = null


func _show_toast(text: String) -> void:
	var toast: Label = Label.new()
	toast.text = text
	toast.position = Vector2(_viewport_size.x / 2 - 150, _viewport_size.y * 0.25)
	toast.custom_minimum_size = Vector2(300, 40)
	toast.add_theme_color_override("font_color", Color(0.98, 0.92, 0.62, 1))
	toast.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.98))
	toast.add_theme_constant_override("outline_size", 5)
	toast.add_theme_font_size_override("font_size", 20)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_canvas_layer.add_child(toast)
	var expiry := toast.create_tween()
	expiry.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	expiry.tween_interval(2.5)
	expiry.tween_callback(toast.queue_free)


func _on_quest_log_pressed() -> void:
	_toggle_quest_log_panel()


func _open_quest_log_panel() -> void:
	if _quest_panel_full == null:
		return
	if _inventory_panel != null:
		var d: ColorRect = _inventory_panel.get_node_or_null("Dim")
		if d: d.visible = true
		_inventory_panel.visible = false
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	_quest_panel_full.open()
	_on_system_panel_opened()

func _toggle_quest_log_panel() -> void:
	if _quest_panel_full == null:
		return
	if _quest_panel_full.visible:
		_quest_panel_full.close()
	else:
		_open_quest_log_panel()


func _on_ui_requested(panel_id: StringName) -> void:
	if DialogPlayer.is_playing():
		return
	if not _panels_ready:
		return
	match panel_id:
		&"inventory":
			_open_inventory_panel()
		&"world_map":
			_open_world_map_panel()
		&"close_equipment":
			if _equipment_panel:
				_equipment_panel.visible = false
		&"equipment":
			_open_equipment_panel()
		&"skills":
			_open_skill_panel()
		&"quest_log":
			_open_quest_log_panel()


func _open_world_map_panel() -> void:
	if _world_map_panel == null:
		_world_map_panel = WORLD_MAP_PANEL_SCENE.instantiate() as WorldMapPanel
		_system_ui_canvas_layer.add_child(_world_map_panel)
		_world_map_panel.closed.connect(_on_system_panel_closed)
	_world_map_panel.open()
	_on_system_panel_opened()


func _init_m5_panels() -> void:
	_inventory_panel = INVENTORY_PANEL_SCENE.instantiate()
	_equipment_panel = EQUIPMENT_PANEL_SCENE.instantiate()
	_skill_panel = SKILL_PANEL_SCENE.instantiate()
	_quest_panel_full = QUEST_PANEL_SCENE.instantiate()
	_system_ui_canvas_layer.add_child(_inventory_panel)
	_inventory_panel.visible = false
	_system_ui_canvas_layer.add_child(_equipment_panel)
	_equipment_panel.visible = false
	_system_ui_canvas_layer.add_child(_skill_panel)
	_skill_panel.visible = false
	_system_ui_canvas_layer.add_child(_quest_panel_full)
	# 面板自行关闭时（ESC/关闭按钮），也要恢复主 HUD
	_inventory_panel.closed.connect(_on_system_panel_closed)
	_equipment_panel.closed.connect(_on_system_panel_closed)
	_panels_ready = true
	_skill_panel.closed.connect(_on_system_panel_closed)
	_quest_panel_full.closed.connect(_on_system_panel_closed)


func _open_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	# Restore MainPanel center
	var mp: Control = _inventory_panel.get_node_or_null("MainPanel")
	if mp:
		mp.offset_left = -640
		mp.offset_right = 640
		mp.offset_top = -360
		mp.offset_bottom = 360
	var dim: ColorRect = _inventory_panel.get_node_or_null("Dim")
	if dim:
		dim.visible = true
	# Reset to "all" tab when opening via I (not via equipment)
	_inventory_panel.call("_set_filter_internal", "all", false)
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_inventory_panel.open()
	_on_system_panel_opened()

func _toggle_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	# If equipment is open, close both
	if _equipment_panel != null and _equipment_panel.visible:
		_close_all_system_panels()
		return
	if _inventory_panel.visible:
		_inventory_panel.close()
	else:
		_open_inventory_panel()


func _open_equipment_panel() -> void:
	if _equipment_panel == null:
		_init_m5_panels()
	if _equipment_panel == null:
		return
	if _inventory_panel != null:
		_inventory_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_equipment_panel.open()
	_on_system_panel_opened()

func _toggle_equipment_panel() -> void:
	if _equipment_panel == null:
		return
	if _equipment_panel.visible:
		_equipment_panel.close()
	else:
		_open_equipment_panel()


func _open_skill_panel() -> void:
	if _skill_panel == null:
		return
	if _inventory_panel != null:
		var d: ColorRect = _inventory_panel.get_node_or_null("Dim")
		if d: d.visible = true
		_inventory_panel.visible = false
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_skill_panel.open()
	_on_system_panel_opened()

func _toggle_skill_panel() -> void:
	if _skill_panel == null:
		return
	if _skill_panel.visible:
		_skill_panel.close()
	else:
		_open_skill_panel()


var _system_panel_open: bool = false


func _pointer_hits_sprite(sprite: Sprite2D, viewport_point: Vector2, padding: float = 0.0) -> bool:
	if LUOYANG_V3.is_v3(_current_scene) and sprite != null and String(sprite.name) != "MarkerVisual": return _city_alpha.hits(sprite, viewport_point)
	if sprite == null or sprite.texture == null or not sprite.is_visible_in_tree():
		return false
	var transform := sprite.get_global_transform_with_canvas()
	var local_point := transform.affine_inverse() * viewport_point
	# Padding is in viewport pixels, independent of camera zoom / sprite scale.
	var scale_min := maxf(0.001, minf(transform.x.length(), transform.y.length()))
	return sprite.get_rect().grow(padding / scale_min).has_point(local_point)


func _pointer_hits_area(area: Area2D, viewport_point: Vector2) -> bool:
	if not is_instance_valid(area) or not area.is_visible_in_tree():
		return false
	for child in area.get_children():
		if (area.has_method("configure_doorway") or LUOYANG_V3.is_v3(_current_scene)) and child is CollisionPolygon2D and not child.disabled:
			var polygon_point: Vector2 = child.get_global_transform_with_canvas().affine_inverse() * viewport_point
			if Geometry2D.is_point_in_polygon(polygon_point, child.polygon): return true
		if not child is CollisionShape2D or child.disabled or child.shape == null:
			continue
		var point: Vector2 = child.get_global_transform_with_canvas().affine_inverse() * viewport_point
		if child.shape is RectangleShape2D and Rect2(-child.shape.size * 0.5, child.shape.size).has_point(point):
			return true
		if child.shape is CircleShape2D and point.length_squared() <= child.shape.radius * child.shape.radius:
			return true
	return false


func _dispatch_pointer_interaction(viewport_point: Vector2) -> bool:
	if _scene_rebuilding or _system_panel_open or _encounter_locked or DialogPlayer.is_playing():
		return false
	if not is_instance_valid(_player) or not _player.can_move:
		return false
	if not _uses_enclosure_dispatch_memory():
		_remember_interaction_spawn()
	# Click the drawn arrow, not its distant ground trigger. Marker > NPC >
	# prop > bare exit ground. Nearest marker wins; authored order breaks ties.
	var picked_exit: ExitZone = null
	var nearest := INF
	for zone in _exit_nodes:
		if not is_instance_valid(zone) or not _pointer_hits_sprite(zone.marker_visual, viewport_point, 9.0):
			continue
		var distance: float = (zone.marker_visual.get_global_transform_with_canvas().origin - viewport_point).length_squared()
		if distance < nearest:
			picked_exit = zone
			nearest = distance
	if picked_exit != null:
		if not picked_exit.try_interact():
			_show_toast("请靠近出口后再点击")
		return true
	var picked_npc: NPCNode = null
	var front_y := -INF
	for npc in _npc_nodes:
		if is_instance_valid(npc) and _pointer_hits_sprite(npc.sprite, viewport_point):
			var depth: float = npc.get_depth_sort_y()
			if depth > front_y:
				picked_npc = npc
				front_y = depth
	if picked_npc != null:
		if not picked_npc.try_interact():
			_show_toast("请靠近后再交谈")
		return true
	for area in _trigger_areas:
		if not is_instance_valid(area):
			continue
		var data: Dictionary = area.get_meta("trigger_data", {})
		if not bool(data.get("interaction_only", false)):
			continue
		var visual: Variant = area.get_meta("highlight_node") if area.has_meta("highlight_node") else null
		var visual_hit := is_instance_valid(visual) and visual is Sprite2D and _pointer_hits_sprite(visual, viewport_point)
		if visual_hit or (not LUOYANG_V3.is_v3(_current_scene) and _pointer_hits_area(area, viewport_point)):
			if area.overlaps_body(_player):
				_on_trigger_zone_entered(_player, data)
			else:
				_show_toast("请靠近后再查看")
			return true
	for zone in _exit_nodes:
		if _pointer_hits_area(zone, viewport_point):
			if not zone.try_interact():
				_show_toast("请靠近出口后再点击")
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	# A pointer may synchronously replace/remove this Field (e.g. a bounty
	# board). Preserve the actual live Viewport before dispatching that action.
	var input_viewport := get_viewport()
	if not is_instance_valid(input_viewport):
		return
	# The project deliberately emulates both touch -> mouse and mouse -> touch
	# for GUI buttons. World interactions accept only the original device;
	# consume its synthetic twin before modal guards / physics picking.
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.device < 0:
		input_viewport.set_input_as_handled()
		return
	if DialogPlayer.is_playing():
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		if _dispatch_pointer_interaction(event.position):
			if is_instance_valid(input_viewport):
				input_viewport.set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC — 关闭系统面板 或 切换右侧菜单
		if event.keycode == KEY_ESCAPE:
			if _system_panel_open:
				_close_all_system_panels()
			else:
				if _primary_hud != null:
					_primary_hud.toggle_right_menu()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_J:
			_on_quest_log_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I:
			# Inventory/character entry is temporarily disabled. Consume I so the
			# hidden legacy panel cannot still be opened from the keyboard.
			if INVENTORY_SHORTCUT_ENABLED:
				_toggle_inventory_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			_toggle_equipment_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_K:
			_toggle_skill_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			get_viewport().set_input_as_handled()
			EventBus.ui_requested.emit(&"world_map")

		elif event.keycode == KEY_F5:
			_open_system_menu()
			get_viewport().set_input_as_handled()

func _on_system_panel_opened() -> void:
	_system_panel_open = true
	if _primary_hud != null:
		_primary_hud.hide_for_system_ui()
	if _player != null:
		_player.set_can_move(false)



func _on_system_panel_closed() -> void:
	if _inventory_panel != null:
		# Restore MainPanel center
		var mp: Control = _inventory_panel.get_node_or_null("MainPanel")
		if mp:
			mp.offset_left = -640
			mp.offset_right = 640
			mp.offset_top = -360
			mp.offset_bottom = 360
		var dim: ColorRect = _inventory_panel.get_node_or_null("Dim")
		if dim:
			dim.visible = true
		_inventory_panel.visible = false
	if _equipment_panel != null and _equipment_panel.visible:
		_equipment_panel.visible = false
		_equipment_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		# Restore Container position
		var ctr: Control = _equipment_panel.get_node_or_null("Container")
		if ctr and ctr.offset_left != 0:
			for child in ctr.get_children():
				if child is Control:
					child.offset_left += 1280
					child.offset_right += 1280
			ctr.offset_left = 0
			ctr.offset_right = 640
	_system_panel_open = false
	if _primary_hud != null:
		_primary_hud.show_after_system_ui()
	if _player != null:
		_player.set_can_move(true)


func _close_all_system_panels() -> void:
	if _inventory_panel != null and _inventory_panel.visible:
		_inventory_panel.close()
	if _equipment_panel != null and _equipment_panel.visible:
		_equipment_panel.close()
	if _skill_panel != null and _skill_panel.visible:
		_skill_panel.close()
	if _quest_panel_full != null and _quest_panel_full.visible:
		_quest_panel_full.close()
	var system_menu := _system_ui_canvas_layer.get_node_or_null("SystemMenu") as SystemMenu
	if system_menu != null and system_menu.visible:
		system_menu.close()
	_on_system_panel_closed()


func _open_save_slot_panel() -> void:
	if DialogPlayer.is_playing():
		return
	const SAVE_SLOT_PANEL_SCENE := preload("res://scenes/ui/save_slot_panel.tscn")
	var panel: Control = SAVE_SLOT_PANEL_SCENE.instantiate()
	_system_ui_canvas_layer.add_child(panel)
	panel.open(SaveSlotPanel.Mode.SAVE)
	_on_system_panel_opened()
	panel.closed.connect(_on_system_panel_closed)
