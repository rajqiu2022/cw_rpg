extends Node
## One owned visual/audio action. No item grant except the final injected collect.
## Never calls Field's broad modal-close handler, moves an actor, or edits its body.
signal finished(result: Dictionary)
const CONFIG_PATH := "res://scripts/life_skills/gathering_actions_20261030l.json"
const LOCK_META := &"life_gather_action_token_20261030l"
const SHEETS := {"herb":"res://art/sprites/life_skills_20261030l/gather_herb_right_4f_padded.png","ore":"res://art/sprites/life_skills_20261030l/mine_ore_right_4f_padded.png"}
const SOUNDS := {"herb":"res://art/audio/life_skills_20261030l/herb_rustle_pluck.wav","ore":"res://art/audio/life_skills_20261030l/pickaxe_stone_hit.wav"}
var _active := false
var _serial := 0
var _token := ""
var _context: Dictionary = {}
var _profile: Dictionary = {}
var _validate: Callable
var _collect: Callable
var _actor_ref: WeakRef
var _sprite_ref: WeakRef
var _ghost_ref: WeakRef
var _field_ref: WeakRef
var _world_ref: WeakRef
var _root_ref: WeakRef
var _manager_ref: WeakRef
var _original_visible := true
var _ghost_visible := false
var _locked_position := Vector2.ZERO
var _foot_offset := 0.0
var _physical_before: Dictionary = {}
var _constraint_before: Callable
var _visual: Sprite2D
var _audio: AudioStreamPlayer
var _sheet: Texture2D
var _streams: Dictionary = {}
var _elapsed := 0.0
var _duration := 0.0
var _frame_index := -1
var _facing_left := false
var _visual_multiplier := 1.0
var _frames_seen: Array[int] = []
var _cues_played: Array[Dictionary] = []
var _last: Dictionary = {}

func _ready() -> void:
	# Run after native depth/overlap refresh so an idle ghost cannot reappear.
	process_priority=1000
	process_mode=Node.PROCESS_MODE_ALWAYS

static func profile_for(kind: String) -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not raw is Dictionary or int(raw.get("schema_version",0)) != 1:return {}
	var actions: Variant=raw.get("actions",{})
	if not actions is Dictionary:return {}
	var value: Variant = actions.get(kind,{})
	return value.duplicate(true) if value is Dictionary else {}

func is_active() -> bool:
	return _active

func owns_actor(actor: Node) -> bool:
	return _active and is_instance_valid(actor) and _actor_ref != null and _actor_ref.get_ref() == actor and actor.get_meta(LOCK_META,"") == _token

func start(context: Dictionary, profile: Dictionary, validate: Callable, collect: Callable) -> Dictionary:
	if _active:return {"ok":false,"message":"正在采集，请稍候。","pending":false}
	if not validate.is_valid() or not collect.is_valid():return {"ok":false,"message":"采集校验不可用。","pending":false}
	var initial: Dictionary = validate.call()
	if initial.get("ok") != true:return initial
	var kind: String = String(context.get("kind",""))
	var prepared: Dictionary = _prepare_profile(kind,profile)
	if prepared.get("ok") != true:return prepared
	var actor: Player = context.get("actor") as Player
	var field: Node = context.get("field") as Node
	var world: Node2D = context.get("world") as Node2D
	var site_root: Node2D = context.get("site_root") as Node2D
	var manager: Node = context.get("manager") as Node
	if not is_instance_valid(actor) or not is_instance_valid(actor.sprite) or not actor.sprite.visible or not actor.can_move or actor.has_meta(LOCK_META):return {"ok":false,"message":"当前不能采集。","pending":false}
	if not is_instance_valid(field) or not is_instance_valid(world) or not is_instance_valid(site_root) or not is_instance_valid(manager):return {"ok":false,"message":"采集场景已变化。","pending":false}
	_actor_ref=weakref(actor);_sprite_ref=weakref(actor.sprite);_field_ref=weakref(field);_world_ref=weakref(world);_root_ref=weakref(site_root);_manager_ref=weakref(manager)
	var ghost: Sprite2D = actor.get("_overlap_ghost") as Sprite2D
	_ghost_ref=weakref(ghost) if is_instance_valid(ghost) else null
	_original_visible=actor.sprite.visible;_ghost_visible=ghost.visible if is_instance_valid(ghost) else false
	_locked_position=actor.global_position;_foot_offset=float(actor.call("_visual_foot_offset"))
	_physical_before=_physical_state(actor)
	_constraint_before=actor.movement_constraint
	_context={"site_id":String(context.get("site_id","")),"field_id":String(context.get("field_id","")),"kind":kind,"resource_foot":context.get("resource_foot",Vector2.ZERO)}
	_profile=profile.duplicate(true);_validate=validate;_collect=collect;_sheet=prepared.sheet;_streams=prepared.streams
	_duration=1.2 if kind=="herb" else 1.5;_elapsed=0.0;_frame_index=-1;_frames_seen.clear();_cues_played.clear()
	_serial+=1;_token="%d:%d" % [get_instance_id(),_serial]
	var resource_foot: Vector2 = _context.resource_foot
	var dx: float = resource_foot.x-world.to_local(actor.global_position).x
	_facing_left=dx<0 if absf(dx)>.01 else String(actor.get("_direction"))=="left"
	_visual_multiplier=float(actor.get("_visual_scale_multiplier"))
	_active=true;actor.set_meta(LOCK_META,_token);actor.sprite.set_meta(LOCK_META,_token)
	actor.set_can_move(false);actor.sprite.hide()
	if is_instance_valid(ghost):ghost.hide()
	_visual=Sprite2D.new();_visual.name="GatherActionVisual";_visual.texture=_sheet
	_visual.hframes=4;_visual.vframes=1;_visual.centered=false;_visual.flip_h=false
	_visual.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;actor.add_child(_visual)
	_audio=AudioStreamPlayer.new();_audio.name="GatherActionAudio";_audio.bus=&"SFX" if AudioServer.get_bus_index("SFX")>=0 else &"Master";add_child(_audio)
	_apply_frame(0)
	return {"ok":true,"pending":true,"message":"正在采药。" if kind=="herb" else "正在采矿。","site_id":_context.site_id,"token":_token,"duration":_duration}

func _prepare_profile(kind: String, profile: Dictionary) -> Dictionary:
	var bad: Dictionary={"ok":false,"pending":false,"message":"采集动作资源尚未就绪。"}
	if not SHEETS.has(kind) or String(profile.get("sheet",""))!=String(SHEETS[kind]):return bad
	var duration: float=1.2 if kind=="herb" else 1.5
	if absf(float(profile.get("duration",0))-duration)>.001:return bad
	var frames: Variant=profile.get("frames",[])
	if not frames is Array or frames.size()!=4 or not ResourceLoader.exists(String(profile.sheet)):return bad
	var sheet: Texture2D=load(String(profile.sheet)) as Texture2D
	if sheet==null or sheet.get_width()%4!=0:return bad
	var width: int=sheet.get_width()/4
	var height: int=sheet.get_height()
	for i: int in range(4):
		if not frames[i] is Dictionary:return bad
		var row: Dictionary=frames[i]
		var rect: Variant=row.get("rect",[]);var foot: Variant=row.get("source_foot",[])
		if not rect is Array or rect.size()!=4 or not foot is Array or foot.size()!=2:return bad
		if int(rect[0])!=i*width or int(rect[1])!=0 or int(rect[2])!=width or int(rect[3])!=height:return bad
		var scale_factor: float=float(row.get("scale",0))
		if not is_finite(scale_factor) or scale_factor<=0 or scale_factor>1:return bad
		if not is_finite(float(foot[0])) or not is_finite(float(foot[1])) or float(foot[0])<0 or float(foot[0])>width or float(foot[1])<0 or float(foot[1])>height:return bad
	var cues: Variant=profile.get("cues",[])
	if not cues is Array or cues.size()!=1 or not cues[0] is Dictionary:return bad
	var cue: Dictionary=cues[0]
	if int(cue.get("frame",-1))!=2 or String(cue.get("path",""))!=String(SOUNDS[kind]) or not ResourceLoader.exists(String(cue.path)):return bad
	var stream: AudioStream=load(String(cue.path)) as AudioStream
	if stream==null:return bad
	return {"ok":true,"sheet":sheet,"streams":{String(cue.path):stream}}

func _physical_state(actor: Player) -> Dictionary:
	var shape: CollisionShape2D=actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var resource: Shape2D=shape.shape if is_instance_valid(shape) else null
	return {"actor":actor.get_instance_id(),"transform":actor.transform,"layer":actor.collision_layer,"mask":actor.collision_mask,"ground_anchored":actor.get("_ground_anchored"),"shape_node":shape.get_instance_id() if is_instance_valid(shape) else 0,"shape_resource":resource.get_instance_id() if resource!=null else 0,"shape_transform":shape.transform if is_instance_valid(shape) else Transform2D.IDENTITY,"shape_disabled":shape.disabled if is_instance_valid(shape) else true,"shape_size":resource.size if resource is RectangleShape2D else Vector2.ZERO,"shape_radius":resource.radius if resource is CircleShape2D else 0.0,"constraint_hash":actor.movement_constraint.hash()}

func _context_failure() -> String:
	var actor: Player=_actor_ref.get_ref() as Player if _actor_ref!=null else null
	var field: Node=_field_ref.get_ref() as Node if _field_ref!=null else null
	var world: Node2D=_world_ref.get_ref() as Node2D if _world_ref!=null else null
	var site_root: Node2D=_root_ref.get_ref() as Node2D if _root_ref!=null else null
	var manager: Node=_manager_ref.get_ref() as Node if _manager_ref!=null else null
	if not is_instance_valid(actor) or not is_instance_valid(field) or not is_instance_valid(world) or not is_instance_valid(site_root) or not is_instance_valid(manager):return "OWNER_GONE"
	if actor.is_queued_for_deletion() or field.is_queued_for_deletion() or site_root.is_queued_for_deletion():return "OWNER_EXIT"
	if get_tree().current_scene!=field or field.get("_player")!=actor or field.get("world_container")!=world:return "FIELD_CHANGED"
	if manager.get("_field")!=field or manager.get("_site_root")!=site_root or manager.get("_world")!=world or site_root.get_parent()!=world:return "SITE_ROOT_CHANGED"
	if String(SceneRouter.get_current_field_id())!=String(_context.field_id) or String(manager.get("_field_id"))!=String(_context.field_id):return "LOGICAL_ID_CHANGED"
	if DialogPlayer.is_playing():return "DIALOG"
	if get_tree().paused:return "PAUSED"
	if bool(field.get("_system_panel_open")) or is_instance_valid(manager.get("_panel")):return "FOREIGN_MODAL"
	if bool(field.get("_scene_rebuilding")) or bool(field.get("_field_loading_failed")):return "REBUILD"
	if bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active")):return "TRANSITION"
	if not owns_actor(actor):return "LOCK_REPLACED"
	if actor.can_move:return "LOCK_LOST"
	if actor.global_position.distance_to(_locked_position)>.25:return "ACTOR_MOVED"
	if actor.movement_constraint!=_constraint_before:return "CONSTRAINT_CHANGED"
	if var_to_bytes(_physical_state(actor))!=var_to_bytes(_physical_before):return "PHYSICAL_STATE_CHANGED"
	return ""

func _process(delta: float) -> void:
	if not _active:return
	var failure: String=_context_failure()
	if not failure.is_empty():cancel(failure);return
	if Input.get_vector("move_left","move_right","move_up","move_down")!=Vector2.ZERO:cancel("MOVE_INPUT");return
	var original: Sprite2D=_sprite_ref.get_ref() as Sprite2D
	if not is_instance_valid(original):cancel("SPRITE_GONE");return
	original.hide()
	var ghost: Sprite2D=_ghost_ref.get_ref() as Sprite2D if _ghost_ref!=null else null
	if is_instance_valid(ghost):ghost.hide()
	# Clamp only delayed ticks: every authored pose must survive a real process
	# turn, rather than assigning several frames then claiming all were visible.
	_elapsed=minf(_duration,_elapsed+minf(maxf(0.0,delta),_duration/8.0))
	var wanted: int=mini(3,int(floor(_elapsed/_duration*4.0)))
	if wanted!=_frame_index:_apply_frame(wanted)
	if _elapsed<_duration:return
	var validation: Dictionary=_validate.call() if _validate.is_valid() else {"ok":false,"message":"采集场景已变化。"}
	if validation.get("ok")!=true:
		validation["cancel_reason"]="FINAL_VALIDATION";_finish(validation,false);return
	failure=_context_failure()
	if not failure.is_empty():cancel(failure);return
	var result: Dictionary=_collect.call() if _collect.is_valid() else {"ok":false,"message":"采集事务不可用。"}
	_finish(result,result.get("ok")==true)

func _apply_frame(index: int) -> void:
	if not is_instance_valid(_visual):return
	_frame_index=index;_frames_seen.append(index)
	var frame: Dictionary=_profile.frames[index]
	var foot:=Vector2(float(frame.source_foot[0]),float(frame.source_foot[1]))
	_visual.frame=index;_visual.position=Vector2(0,_foot_offset);_visual.offset=-foot
	# Mirror only this visual around the authored foot itself. Signed child scale
	# avoids Sprite2D.flip_h/offset conventions; neither actor nor body is scaled.
	var size_factor: float=float(frame.scale)*_visual_multiplier
	_visual.scale=Vector2(-size_factor if _facing_left else size_factor,size_factor)
	for cue: Dictionary in _profile.cues:
		if int(cue.frame)!=index:continue
		_audio.stream=_streams[String(cue.path)]
		_audio.volume_db=linear_to_db(maxf(.0001,AudioManager.sfx_volume))+clampf(float(cue.get("volume_db",0)),-24,0)
		_audio.play()
		_cues_played.append({"frame":index,"elapsed":_elapsed,"path":String(cue.path),"tick_usec":Time.get_ticks_usec()})

func _input(event: InputEvent) -> void:
	if not _active:return
	if event.is_action_pressed("ui_cancel"):
		var foreign: bool=not _context_failure().is_empty()
		cancel("ESCAPE")
		if not foreign:get_viewport().set_input_as_handled()
		return
	for action: String in ["move_left","move_right","move_up","move_down"]:
		if event.is_action_pressed(action):cancel("MOVE_INPUT");return
	if event is InputEventKey and event.pressed and event.keycode==KEY_F:get_viewport().set_input_as_handled()

func cancel(reason: String="CANCELLED") -> Dictionary:
	if not _active:return {"ok":false,"pending":false,"message":"没有进行中的采集。"}
	var result: Dictionary={"ok":false,"pending":false,"message":"已取消采集。","cancel_reason":reason}
	_finish(result,false)
	return result

func _safe_to_restore_move(actor: Player, field: Node, manager: Node) -> bool:
	return is_instance_valid(field) and is_instance_valid(manager) and not get_tree().paused and field==get_tree().current_scene and field.get("_player")==actor and not field.is_queued_for_deletion() and not bool(field.get("_system_panel_open")) and not bool(field.get("_scene_rebuilding")) and not bool(field.get("_field_loading_failed")) and not is_instance_valid(manager.get("_panel")) and not DialogPlayer.is_playing() and not bool(LoadingManager.get("_transition_active")) and not bool(LoadingManager.get("_external_active")) and String(SceneRouter.get_current_field_id())==String(_context.field_id)

func _finish(result: Dictionary, completed: bool) -> void:
	result["completed"]=completed;result["pending"]=false;result["site_id"]=_context.get("site_id","")
	_last=get_debug_state();_last["completed"]=completed;_last["cancel_reason"]=String(result.get("cancel_reason",""));_last["result"]=result.duplicate(true)
	var actor: Player=_actor_ref.get_ref() as Player if _actor_ref!=null else null
	var field: Node=_field_ref.get_ref() as Node if _field_ref!=null else null
	var manager: Node=_manager_ref.get_ref() as Node if _manager_ref!=null else null
	var original: Sprite2D=_sprite_ref.get_ref() as Sprite2D if _sprite_ref!=null else null
	if is_instance_valid(_audio):_audio.stop();_audio.queue_free()
	_audio=null
	if is_instance_valid(_visual):_visual.queue_free()
	_visual=null
	if is_instance_valid(original) and original.get_meta(LOCK_META,"")==_token:
		original.visible=_original_visible;original.remove_meta(LOCK_META)
	var ghost: Sprite2D=_ghost_ref.get_ref() as Sprite2D if _ghost_ref!=null else null
	if is_instance_valid(ghost):ghost.visible=_ghost_visible
	if is_instance_valid(actor) and actor.get_meta(LOCK_META,"")==_token:
		actor.remove_meta(LOCK_META)
		if _safe_to_restore_move(actor,field,manager):actor.set_can_move(true)
	_last["original_sprite_restored"]=is_instance_valid(original) and original.visible==_original_visible
	_last["audio_stopped"]=true
	_last["actor_can_move_after_cleanup"]=actor.can_move if is_instance_valid(actor) else false
	_last["own_lock_remaining"]=is_instance_valid(actor) and actor.get_meta(LOCK_META,"")==_token
	_last["physical_after_cleanup"]=_physical_state(actor) if is_instance_valid(actor) else {}
	_active=false;_validate=Callable();_collect=Callable();_streams.clear();_sheet=null
	finished.emit(result)

func get_debug_state() -> Dictionary:
	if not _active:
		var ended: Dictionary=_last.duplicate(true)
		ended["active"]=false;ended["start_serial"]=_serial;ended["audio_playing"]=false
		ended["audio_node_path"]="";ended["visual_node_path"]="";ended["visual_node_id"]=0
		var idle_sprite: Sprite2D=_sprite_ref.get_ref() as Sprite2D if _sprite_ref!=null else null
		ended["original_sprite_visible"]=idle_sprite.visible if is_instance_valid(idle_sprite) else false
		return ended
	var actor: Player=_actor_ref.get_ref() as Player
	var original: Sprite2D=_sprite_ref.get_ref() as Sprite2D
	return {"active":true,"token":_token,"start_serial":_serial,"site_id":_context.site_id,"field_id":_context.field_id,"kind":_context.kind,"duration":_duration,"elapsed":_elapsed,"frame_index":_frame_index,"frame_count":4,"frames_seen":_frames_seen.duplicate(),"facing":"left" if _facing_left else "right","actor_id":actor.get_instance_id() if is_instance_valid(actor) else 0,"actor_position":actor.global_position if is_instance_valid(actor) else Vector2.ZERO,"original_sprite_id":original.get_instance_id() if is_instance_valid(original) else 0,"original_sprite_visible":original.visible if is_instance_valid(original) else false,"visual_node_path":String(_visual.get_path()) if is_instance_valid(_visual) else "","visual_node_id":_visual.get_instance_id() if is_instance_valid(_visual) else 0,"visual_frame":_visual.frame if is_instance_valid(_visual) else -1,"visual_offset":_visual.offset if is_instance_valid(_visual) else Vector2.ZERO,"visual_scale":_visual.scale if is_instance_valid(_visual) else Vector2.ZERO,"audio_node_path":String(_audio.get_path()) if is_instance_valid(_audio) else "","audio_stream_path":_audio.stream.resource_path if is_instance_valid(_audio) and _audio.stream!=null else "","audio_playing":_audio.playing if is_instance_valid(_audio) else false,"audio_playback_position":_audio.get_playback_position() if is_instance_valid(_audio) else 0.0,"audio_cues":_cues_played.duplicate(true),"physical_before":_physical_before.duplicate(true),"physical_current":_physical_state(actor) if is_instance_valid(actor) else {},"completed":false,"cancel_reason":""}

func _exit_tree() -> void:
	if _active:cancel("HELPER_EXIT")
