extends Node
## Resolve exact source-art defects without changing authored NPC identities or patrols.

const TRUNCATED_WAITER := "res://art/characters/street_expansion_v1/npc_inn_waiter_idle_down_4f.png"
const COMPLETE_WAITER := preload("res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png")
const LEFT_FACING_WALK := "res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"

const SHARED_TEA_GUEST := "res://art/characters/npc_inn_tea_guest_seated_1f.png"
const TRAVELER_DIALOG := "interior_inn_traveler_chatter"
const TEA_GUEST := preload("res://art/modules/qingfeng_inn_20261109/tea_guest.png")
const TRAVELER := preload("res://art/modules/qingfeng_inn_20261109/traveler.png")
const TRAVELER_STRIP := "res://art/modules/qingfeng_inn_20261109/traveler_eat_loop.png"
const EVIDENCE_GLOW := preload("res://shaders/cave_evidence_glow.gdshader")
const STORY_ENEMIES := preload("res://art/characters/story_enemies_20261109/field_sheets.gd")
const SMITH_ANIMATION := preload("res://scripts/field/linxi_smith_animation.gd")
const ZHAO_ESCAPE := preload("res://scripts/field/zhao_escape_animation.gd")
const OLDER_NPC_ART := "res://art/characters/road_story_and_older_npcs_20261112/"
const NPC_IDENTITY_ART := "res://art/characters/npc_identity_20261117/"
const FENG_PORTRAIT := "res://art/characters/portraits/portrait_feng_yanqiu_v1.png"
const MASTER_IDLE := "res://art/characters/npc_xingfantian_v4_idle_down_25d_4f.png"
var _traveler: WeakRef
var _story_actors: Dictionary = {}

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	preload("res://scripts/field/altar_confrontation.gd").install(get_tree())
	EventBus.dialog_started.connect(_restore_traveler_animation)
	EventBus.dialog_ended.connect(_restore_traveler_animation)
	EventBus.dialog_started.connect(_restore_story_animation)
	EventBus.dialog_ended.connect(_restore_story_animation)
	EventBus.field_cutscene_requested.connect(_play_zhao_escape)

func _play_zhao_escape(id: StringName) -> void:
	if id == &"zhao_qinggong_escape":
		ZHAO_ESCAPE.play(get_tree().current_scene)

func _on_node_added(node: Node) -> void:
	if node is Sprite2D and node.name == &"SceneObject_resting_bed":
		_bind_cave_bed.call_deferred(node)
		return
	if node is Area2D and node.name == &"Trigger_bandit_cave_banner":
		_bind_cave_evidence.call_deferred(node)
		return
	if not node is NPCNode:
		return
	if node.npc_id.begins_with("feng_yanqiu_") and node.sprite_path in [FENG_PORTRAIT, "res://art/characters/street_expansion_v1/npc_wulin_examiner_idle_down_4f.png"]:
		_install_identity_idle.call_deferred(weakref(node), "feng_yanqiu")
	elif node.npc_id == "assembly_host" and node.sprite_path == MASTER_IDLE:
		_install_identity_idle.call_deferred(weakref(node), "assembly_registrar")
	elif node.npc_id == "spar_wudang_disciple" and node.sprite_path == "res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png":
		_install_identity_idle.call_deferred(weakref(node), "wudang_disciple")
	if node.npc_id in ["duqingshan", "duqingshan_ready", "duqingshan_after_sword"] and node.sprite_path == "res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png":
		_bind_linxi_smith.call_deferred(node)
	var story: Dictionary = STORY_ENEMIES.FIELD.get(node.npc_id, {})
	if not story.is_empty() and node.sprite_path == story.path and (node.dialog_id == story.dialog or node.npc_id == "bandit_cave_guard"):
		_install_story_animation.call_deferred(weakref(node), story)
	if node.npc_id == "vegetable_vendor" and node.dialog_id == "ch1_s2_vegetable_vendor":
		_install_older_npc.call_deferred(weakref(node), "vegetable_vendor", 488.0)
	elif node.npc_id in ["crying_woman", "crying_woman_waiting"] and node.sprite_path.begins_with(OLDER_NPC_ART):
		_install_older_npc.call_deferred(weakref(node), "anxious_mother", 479.0)
	if node.walk_sprite_path == LEFT_FACING_WALK or node.sprite_path == TRUNCATED_WAITER or _is_inn_diner(node):
		_apply.call_deferred(weakref(node))


func _install_identity_idle(reference: WeakRef, identity: String) -> void:
	var npc := reference.get_ref() as NPCNode
	if not is_instance_valid(npc) or npc.is_queued_for_deletion() or npc.sprite == null or npc.sprite.texture == null:
		return
	var texture := load(NPC_IDENTITY_ART + identity + "_idle.png") as Texture2D
	if texture == null:
		return
	var old_height := npc._visible_bounds(npc.sprite.texture).size.y
	var new_height := npc._visible_bounds(texture).size.y
	if old_height <= 0 or new_height <= 0:
		return
	# Preserve the previous on-screen body height and the collision already
	# created by NPCNode. Only replace the visual and conversation portrait.
	npc.sprite_scale = npc.sprite.scale.y * float(old_height) / float(new_height)
	npc._calibrate_adult_body = false
	npc.apply_runtime_idle_texture(texture)
	npc.idle_frame_seconds = 0.68
	npc.conversation_base_facing = "right"
	if identity == "assembly_registrar":
		npc.portrait_path = NPC_IDENTITY_ART + "assembly_registrar_portrait.tres"

func _bind_cave_bed(bed: Sprite2D) -> void:
	if not is_instance_valid(bed) or bed.is_queued_for_deletion() or SceneRouter.get_current_field_id() != &"interior_bandit_cave":
		return
	var depth := Node.new()
	depth.set_script(load("res://scripts/field/cave_bed_depth.gd"))
	bed.add_child(depth)

func _install_older_npc(reference: WeakRef, family: String, visible_height: float) -> void:
	var npc := reference.get_ref() as NPCNode
	if not is_instance_valid(npc) or npc.is_queued_for_deletion():
		return
	var frames: Array[Texture2D] = []
	for index in range(4):
		frames.append(load(OLDER_NPC_ART + "%s/frame_%d.tres" % [family, index]) as Texture2D)
	npc.sprite_path = frames[0].resource_path
	npc.sprite_scale = 130.0 / visible_height
	npc.conversation_base_facing = "left"
	npc.apply_runtime_idle_texture(frames[0])
	var idle := Timer.new()
	idle.name = "OlderNpcIdle"
	idle.wait_time = 0.36
	npc.add_child(idle)
	idle.timeout.connect(func() -> void:
		var current := frames.find(npc.sprite.texture)
		if current == -1:
			return
		var frame := frames[(current + 1) % frames.size()]
		npc._idle_texture = frame
		npc.sprite.texture = frame
	)
	idle.start()

func _install_story_animation(reference: WeakRef, story: Dictionary) -> void:
	var npc := reference.get_ref() as NPCNode
	if not is_instance_valid(npc) or npc.is_queued_for_deletion():
		return
	var texture := npc.sprite.texture
	if texture == null or texture.resource_path != story.path or texture.get_size() != story.size:
		return
	_story_actors[story.dialog] = reference
	npc.sprite_scale = float(story.height) / float(story.visible_height)
	npc.idle_frame_seconds = 0.24
	npc.apply_runtime_idle_texture(texture)
	_configure_story_frames(npc, story)

func _restore_story_animation(dialog_id: StringName) -> void:
	var reference := _story_actors.get(String(dialog_id)) as WeakRef
	if reference == null:
		return
	var npc := reference.get_ref() as NPCNode
	if not is_instance_valid(npc) or npc.is_queued_for_deletion():
		return
	_configure_story_frames.call_deferred(npc, STORY_ENEMIES.FIELD[npc.npc_id])

func _configure_story_frames(npc: NPCNode, story: Dictionary) -> void:
	if not is_instance_valid(npc) or npc.is_queued_for_deletion():
		return
	if npc.sprite.texture == null or npc.sprite.texture.resource_path != story.path:
		return
	npc._hframes = 4
	npc.sprite.hframes = 4
	npc.sprite.position.y = (story.size.y * 0.5 - float(story.sole)) * npc.sprite.scale.y
	npc.refresh_depth_sort()

func _apply(reference: WeakRef) -> void:
	var npc := reference.get_ref() as NPCNode
	if not is_instance_valid(npc) or not npc.is_inside_tree() or npc.is_queued_for_deletion():
		return
	# The legacy name says "right", but both its original and HD art face left.
	# NPCNode flips from patrol phase; negative authored axes reverse that phase.
	if npc.walk_sprite_path == LEFT_FACING_WALK and absf(npc.patrol_axis.x) > absf(npc.patrol_axis.y):
		npc.invert_patrol_facing = npc.patrol_axis.x > 0.0
	# Keep the original source key (including portrait lookup) and actor contract.
	if npc.sprite_path == TRUNCATED_WAITER and npc._idle_texture != null and npc._idle_texture.resource_path == TRUNCATED_WAITER:
		var showing_idle := npc.sprite.texture == npc._idle_texture
		if showing_idle:
			npc.apply_runtime_idle_texture(COMPLETE_WAITER)
		else:
			npc._idle_texture = COMPLETE_WAITER

	if _is_inn_diner(npc):
		var tea := npc.npc_id == "inn_guest_left"
		if not tea:
			npc.dialog_id = TRAVELER_DIALOG
		var texture := TEA_GUEST if tea else TRAVELER
		var old_seat := Vector2(0.340, 0.705) if tea else Vector2(0.800, 0.680)
		var new_seat := Vector2(0.254, 0.657) if tea else Vector2(0.755, 0.657)
		npc.position = npc.position / old_seat * new_seat
		# Each sprite has a distinct, measured opaque height and boot baseline.
		npc.sprite_scale = 104.0 / (1374.0 if tea else 1261.0)
		npc.apply_runtime_idle_texture(texture)
		npc.sprite.position.y = (texture.get_height() * 0.5 - (1397.0 if tea else 1370.0)) * npc.sprite.scale.y
		npc.sprite.position.x = -6.0 if tea else 6.0
		npc.refresh_depth_sort()
		if not tea and ResourceLoader.exists(TRAVELER_STRIP):
			var strip := load(TRAVELER_STRIP) as Texture2D
			if strip != null and strip.get_size() == Vector2(2172, 724):
				_traveler = weakref(npc)
				npc.sprite_scale = 104.0 / 700.0
				npc.idle_frame_seconds = 0.36
				npc.apply_runtime_idle_texture(strip)
				_configure_traveler_animation(npc)

func _restore_traveler_animation(dialog_id: StringName) -> void:
	if dialog_id == StringName(TRAVELER_DIALOG) and _traveler != null:
		_configure_traveler_animation.call_deferred(_traveler.get_ref())

func _configure_traveler_animation(npc: NPCNode) -> void:
	if not is_instance_valid(npc) or npc.is_queued_for_deletion():
		return
	if npc.sprite.texture == null or npc.sprite.texture.resource_path != TRAVELER_STRIP:
		return
	# The sheet cells are portrait rectangles. Auto-detection assumes squares.
	npc._hframes = 4
	npc.sprite.hframes = 4
	npc.sprite.flip_h = false
	npc.sprite.position.y = (362.0 - 715.0) * npc.sprite.scale.y
	npc.refresh_depth_sort()

func _is_inn_diner(npc: NPCNode) -> bool:
	return npc.npc_id in ["inn_guest_left", "inn_guest_right"] and npc.sprite_path == SHARED_TEA_GUEST and npc.dialog_id == "interior_inn_guest_chatter"

func _bind_linxi_smith(npc: NPCNode) -> void:
	if not is_instance_valid(npc) or npc.is_queued_for_deletion() or SceneRouter.get_current_field_id() != &"linxi_tutorial":
		return
	var animation := SMITH_ANIMATION.new()
	if animation.install(npc):
		npc.add_child(animation)
	else:
		animation.free()

func _bind_cave_evidence(area: Area2D) -> void:
	if not is_instance_valid(area) or not area.is_inside_tree() or area.is_queued_for_deletion():
		return
	var trigger: Dictionary = area.get_meta("trigger_data", {})
	if trigger.get("action") != "dialog:interior_bandit_cave_banner":
		return
	var field := area.get_parent()
	while field != null and not field.has_method("get_field_loading_state"):
		field = field.get_parent()
	if field == null:
		return
	var prop := field.find_child("SceneObject_banner_and_goods", true, false) as Sprite2D
	if prop == null or (prop.material != null and (not prop.material is ShaderMaterial or prop.material.shader != EVIDENCE_GLOW)):
		return
	var glow := ShaderMaterial.new()
	glow.shader = EVIDENCE_GLOW
	glow.set_shader_parameter("pulse", 1.0 if area.get_overlapping_bodies().any(func(body: Node2D) -> bool: return body.is_in_group("player")) else 0.0)
	prop.material = glow
	area.set_meta("highlight_node", prop)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			glow.set_shader_parameter("pulse", 1.0)
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			glow.set_shader_parameter("pulse", 0.0)
	)
	area.tree_exiting.connect(func() -> void:
		if is_instance_valid(prop) and prop.material == glow:
			prop.material = null
	)
