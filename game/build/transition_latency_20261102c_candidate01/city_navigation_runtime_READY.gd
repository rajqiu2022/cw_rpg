extends Node
## Independent finite view/route owner. Original Scene/NAV/bins/receipts stay intact.
const HOME := "res://build/city_navigation_20261101d_candidate01/"
const SELF := HOME + "city_navigation_runtime.gd"
const MANIFEST := HOME + "source_pins_READY.json"
const Pair = preload("res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd")
const Geo = preload("res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd")
const Mouth = preload("res://build/city_navigation_20261101d_candidate01/mouth_visual.gd")
const REGION_PATH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const ART := "res://build/luoyang_temple_adult_20261101d_art01/live_art_view.gd"
const MINI := "res://build/city_navigation_minimap_20261101d_candidate01/mini_marker_overlay.gd"
var _router: Node
var _loading: Node
var _dialog: Node
var _pins: Dictionary = {}
var _manifest_sha := ""
var _ready_sources := false
var _states: Dictionary = {}
var _clock := 0.0
var _pending: Dictionary = {}
var _local_adventure := false
var _local_adventure_field: WeakRef
var _last_error := ""
var _history: Array[Dictionary] = []
const ScreenBarrier = preload("res://build/transition_latency_20261102c_candidate01/loading_screen_barrier.gd")
const ScreenScene = preload("res://scenes/ui/loading_screen.tscn")
const ScreenBase = preload("res://scripts/ui/loading_screen.gd")
var _preparing_travel := false
var _barrier_field: WeakRef
var _barrier_actor: WeakRef
var _barrier_can_move := false
var _source_thread: Thread
var _last_source_job: Dictionary = {}
var _latency_history: Array[Dictionary] = []
var _screen_barrier_installed := false

func _ready() -> void:
	_router=get_node_or_null("/root/SceneRouter"); _loading=get_node_or_null("/root/LoadingManager"); _dialog=get_node_or_null("/root/DialogPlayer")
	if _router==null or _loading==null or _dialog==null: _reject("ORIGINAL_AUTOLOADS_NOT_READY"); set_process(false); return
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not value is Dictionary or value.get("schema")!="CITY_NAVIGATION_20261101D_FROZEN_V1" or value.get("ready")!=true:
		_reject("ROOT_SOURCE_FREEZE_REQUIRED"); set_process(false); return
	_pins=value.get("source_pins",{}).duplicate(true)
	for required: String in [SELF,Pair.SELF,Geo.SELF,Mouth.SELF,ART,MINI,REGION_PATH,Pair.MAIN_FIELD,Pair.REGION_FIELD]:
		if not _pins.has(required): _reject("FROZEN_REQUIRED_DEPENDENCY:"+required); set_process(false); return
	_manifest_sha=FileAccess.get_sha256(MANIFEST)
	_ready_sources=_sources_match() and Geo.load_fixed()
	if not _ready_sources: _reject("EXACT_FROZEN_SOURCES_OR_GEOMETRY"); set_process(false)
	else:
		_screen_barrier_installed = _install_loading_screen()
		if not _screen_barrier_installed: _reject("LOADING_VIEW_CONSTRUCTED_BEFORE_ADAPTER"); set_process(false)

func _sources_match() -> bool:
	if _pins.is_empty() or FileAccess.get_sha256(MANIFEST)!=_manifest_sha: return false
	if ProjectSettings.get_setting("autoload/CityNavigationRuntime","")!="*"+SELF: return false
	for path: String in _pins:
		if path=="res://project.godot": continue
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=_pins[path]: return false
	return true

func _reject(reason: String) -> void:
	_last_error=reason; push_error("[CityNavigation11d] "+reason)

func _scene(field: Node) -> SceneScript:
	return field.get("_current_scene") as SceneScript if is_instance_valid(field) else null

func _key(field: Node) -> String:
	var scene: SceneScript=_scene(field)
	return str(field.get_instance_id())+":"+str(scene.get_instance_id()) if scene!=null else ""

func _process(delta: float) -> void:
	_clock+=delta
	if _clock<.25: return
	_clock=fmod(_clock,.25)
	if _barrier_field != null and _barrier_field.get_ref() != get_tree().current_scene: cancel_loading_barrier(_barrier_field.get_ref() as Node)
	if _preparing_travel or _barrier_field != null: return
	var field: Node=get_tree().current_scene
	if not is_instance_valid(field) or field.get_script()==null or field.get_script().resource_path not in [Pair.MAIN_FIELD,Pair.REGION_FIELD]: return
	var scene: SceneScript=_scene(field)
	if scene==null or field.get("_field_loading_complete")!=true or field.get("_field_loading_failed")==true or field.get("_scene_rebuilding")==true: return
	if _loading.get("_transition_active")==true or _loading.get("_external_active")==true: return
	_advance_pending(field,scene)
	var id: String=String(scene.scene_id)
	if id not in Pair.area_ids() and id not in Pair.room_ids(): return
	var key: String=_key(field)
	if not _states.has(key) or not _state_alive(_states[key],field):
		var screen: Node = _loading.get("_screen") as Node
		if screen == null or not screen.has_method("prepare_new_field") or not screen.call("prepare_new_field",field): _reject("REAL_LOADING_VIEW_BARRIER_UNAVAILABLE")
		return
	if not _states.has(key): return
	var state: Dictionary=_states[key]
	if id=="luoyang_temple_region_27d": _retire_scroll(field,state)
	var mini: Node=field.get("_world_travel_minimap") as Node
	var context: String=String(mini.get("_context_id")) if is_instance_valid(mini) else ""
	if state.get("mini_context","")!=context or state.get("mini_ok",false)!=true:
		_attach_mini(field,state)
	for old_key: String in _states.keys():
		var reference: WeakRef=_states[old_key].get("field") as WeakRef
		if reference==null or reference.get_ref()==null: _states.erase(old_key)

func _state_alive(state: Dictionary, field: Node) -> bool:
	if state.get("field") == null or state.field.get_ref()!=field: return false
	var exits: Array=field.get("_exit_nodes")
	for zone: ExitZone in state.get("zones",[]):
		if not is_instance_valid(zone) or zone.is_queued_for_deletion() or not exits.has(zone): return false
	return true

func _world_origin_active() -> bool:
	var adventure: Node=get_node_or_null("/root/AdventureRuntime")
	var links: Node=adventure.get_node_or_null("AdventureWorldLinks31f") if adventure!=null else null
	return links!=null and not (links.call("validated_origin",Geo.ADVENTURE) as Dictionary).is_empty()

func _attach(field: Node,scene: SceneScript,key: String) -> void:
	var id: String=String(scene.scene_id)
	var endpoints: Array[Dictionary]=Pair.endpoints(id)
	if not endpoints.is_empty() and not Geo.live(field,true): _reject("ORIGINAL_LIVE_OWNER:"+id); return
	# World31f alone owns the old adventure return when World-origin is present.
	if id==Geo.ADVENTURE and (not _local_adventure or _local_adventure_field==null or _local_adventure_field.get_ref()!=field or _world_origin_active()): endpoints.clear()
	var before_compiled: PackedByteArray=var_to_bytes(field.get("_region")) if field.get_script().resource_path==Pair.REGION_FIELD else PackedByteArray()
	var state: Dictionary={"field":weakref(field),"scene_id":id,"zones":[],"retired":[],"metadata":{},"mini_ok":false,"mini_context":""}
	var exits: Array=field.get("_exit_nodes")
	state["original_exits"]=exits.duplicate()
	var layer: Node=field.get("_portal_layer") as Node
	if layer==null: _reject("ORIGINAL_PORTAL_LAYER"); return
	var prepared: Array[Dictionary]=[]
	# Validate the complete finite replacement before retiring any original node.
	for endpoint: Dictionary in endpoints:
		if not Geo.safe_segment(id,endpoint.arrival,endpoint.mouth): _reject("EXACT_MOUTH_STATIC_ROUTE:"+endpoint.id); return
		var matches: Array[ExitZone]=[]
		for old: ExitZone in exits:
			if not is_instance_valid(old) or old.has_meta("citynav_endpoint"): continue
			if old.target_scene_id!=String(endpoint.target.logical_id) and not (endpoint.pair_id=="gate_civic" and old.target_scene_id=="ch4_s0_luoyang_gate"): continue
			for foot: Vector2 in endpoint.retired_feet:
				if old.position.distance_to(foot)<.5: matches.append(old); break
		var new_connector: bool=endpoint.source_portal=="luoyang_temple_riverside_connector"
		if matches.size()!=(0 if new_connector else endpoint.retired_feet.size()): _reject("EXACT_ORIGINAL_EXIT_IDENTITY:"+endpoint.id+":"+str(matches.size())); return
		prepared.append({"endpoint":endpoint,"matches":matches})
	# The art helper validates/commits its own atomic overlay before any door swap.
	if id in ["luoyang_temple_region_27d","luoyang_civic_market_region_27d"]:
		var art: GDScript=load(ART) as GDScript
		var result: Dictionary=art.call("attach",field) if art!=null else {"ok":false,"error":"ART_SCRIPT"}
		state["art"]=result
		if result.get("ok")!=true: _reject("ART_VIEW:"+String(result.get("error"))); return
	for item: Dictionary in prepared:
		var endpoint: Dictionary=item.endpoint
		var matches: Array=item.matches
		var locked:=false
		for old: ExitZone in matches:
			locked=locked or old.is_locked
			state.retired.append({"node":weakref(old),"position":old.position,"target":old.target_scene_id,"locked":old.is_locked,"visible":old.visible,"monitoring":old.monitoring,"monitorable":old.monitorable})
			exits.erase(old); old.hide(); old.set_deferred("monitoring",false); old.set_deferred("monitorable",false)
		var zone: ExitZone=(load("res://scenes/exit_zone.tscn") as PackedScene).instantiate() as ExitZone
		zone.set_script(load(HOME+"pair_exit_zone.gd"))
		zone.name="CityNavigation_"+endpoint.pair_id
		zone.call("configure",field,endpoint,Callable(self,"_contact").bind(field,endpoint))
		zone.is_locked=locked
		zone.exit_triggered.connect(Callable(self,"_travel").bind(field,endpoint))
		var field_ref: WeakRef=weakref(field)
		zone.exit_locked.connect(func(text: String) -> void:
			var active: Node=field_ref.get_ref() as Node
			if is_instance_valid(active): active.call("_show_toast",text)
		)
		layer.add_child(zone); exits.append(zone); state.zones.append(zone)
	_states[key]=state
	if id=="luoyang_temple_region_27d": _retire_scroll(field,state)
	var metadata: Dictionary=_metadata(field,scene,endpoints)
	state.metadata=metadata
	var mouth_result: Dictionary=Mouth.attach(field,metadata)
	if mouth_result.get("ok")!=true: _rollback_navigation(field,state,key); _reject("MOUTH_VIEW:"+String(mouth_result.get("error"))); return
	state["mouth_visual"]=mouth_result
	var mini: Node=field.get("_world_travel_minimap") as Node
	if is_instance_valid(mini) and mini.has_method("_build_plan"):
		if id=="luoyang_temple_region_27d":
			var art: GDScript=load(ART) as GDScript
			mini.set("_compiled",art.call("mini_compiled_copy",field.get("_region")))
		mini.call("_build_plan")
	_attach_mini(field,state)
	if not before_compiled.is_empty() and var_to_bytes(field.get("_region"))!=before_compiled: _rollback_navigation(field,state,key); _reject("ORIGINAL_COMPILED_MUTATED"); return
	field.set_meta("city_navigation11d",{"ok":true,"scene_id":id,"pairs":endpoints.size(),"original_compiled_unchanged":true})
	print("[CityNavigation11d] attached ",id," mouths=",endpoints.size())

func _rollback_navigation(field: Node,state: Dictionary,key: String) -> void:
	var exits: Array=field.get("_exit_nodes")
	for zone: ExitZone in state.get("zones",[]):
		if is_instance_valid(zone):
			exits.erase(zone)
			if zone.get_parent()!=null: zone.get_parent().remove_child(zone)
			zone.queue_free()
	for row: Dictionary in state.get("retired",[]):
		var old: ExitZone=row.node.get_ref() as ExitZone
		if not is_instance_valid(old): continue
		old.visible=row.visible
		old.set_deferred("monitoring",row.monitoring); old.set_deferred("monitorable",row.monitorable)
	field.set("_exit_nodes",state.original_exits)
	var visuals: Node=field.get("_visual_layer") as Node
	var mouth: Node=visuals.get_node_or_null("CityNavigationRoadMouths11d") if visuals!=null else null
	if is_instance_valid(mouth): visuals.remove_child(mouth); mouth.queue_free()
	if field.has_meta(Mouth.META): field.remove_meta(Mouth.META)
	if state.has("scroll_before"):
		var adventure: Node=get_node_or_null("/root/AdventureRuntime")
		if adventure!=null and adventure.get("_owner")==field and adventure.get("_logical")=="ch4_s4_ancient_temple":
			var features: Dictionary=adventure.get("_features")
			var feature_id: String="entry_"+Geo.ADVENTURE
			if not features.has(feature_id): features[feature_id]=state.scroll_before
			var node: Node2D=state.scroll_before.get("node") as Node2D
			if is_instance_valid(node): node.visible=bool(state.get("scroll_visible",true))
	_states.erase(key)

func _metadata(field: Node,scene: SceneScript,endpoints: Array[Dictionary]) -> Dictionary:
	var rows: Array[Dictionary]=[]
	var exits: Array=field.get("_exit_nodes")
	var regional: Dictionary=field.get("_region_portals") if field.get_script().resource_path==Pair.REGION_FIELD else {}
	for zone: ExitZone in exits:
		if not is_instance_valid(zone) or zone.is_queued_for_deletion(): continue
		if zone.has_meta("citynav_endpoint"):
			var endpoint: Dictionary=zone.get_meta("citynav_endpoint")
			rows.append({"id":endpoint.id,"foot":endpoint.mouth,"target_scene":endpoint.target.logical_id,"kind":"area_exit","locked":zone.is_locked,"pair_id":endpoint.pair_id,"source_scene":String(scene.scene_id),"source_portal":endpoint.source_portal,"target_portal":endpoint.target.source_portal,"data":endpoint.duplicate(true)})
		else:
			var original: Dictionary=regional.get(zone.get_instance_id(),{})
			var id: String=String(original.get("key",String(scene.scene_id)+"/"+String(zone.name)))
			var kind: String="area_exit" if zone.target_scene_id in Pair.area_ids() or zone.action=="world_map" else "building_door"
			rows.append({"id":id,"foot":zone.position,"target_scene":zone.target_scene_id,"kind":kind,"locked":zone.is_locked,"pair_id":"","source_scene":String(scene.scene_id),"source_portal":String(original.get("id",zone.name)),"target_portal":"","data":original.get("data",{}).duplicate(true)})
	return {"ok":true,"schema":Pair.SCHEMA,"scene_id":String(scene.scene_id),"context_id":String(_router.call("get_current_field_id")),"portals":rows,"mouths":endpoints.duplicate(true)}

func _attach_mini(field: Node,state: Dictionary) -> void:
	var mini: Node=field.get("_world_travel_minimap") as Node
	if not is_instance_valid(mini): return
	var script: GDScript=load(MINI) as GDScript
	var result: Dictionary=script.call("attach",field,state.metadata) if script!=null else {"ok":false}
	state.mini_ok=result.get("ok",false)
	state.mini_context=String(mini.get("_context_id"))
	state["mini_result"]=result.get("state",{})

func _retire_scroll(field: Node,state: Dictionary) -> void:
	var adventure: Node=get_node_or_null("/root/AdventureRuntime")
	if adventure==null or adventure.get("_owner")!=field or adventure.get("_logical")!="ch4_s4_ancient_temple": return
	var features: Dictionary=adventure.get("_features")
	var key: String="entry_"+Geo.ADVENTURE
	if not features.has(key): return
	var feature: Dictionary=features[key]
	if feature.get("kind")!="connector" or feature.get("target_scene")!=Geo.ADVENTURE or feature.get("foot")!=Vector2(900,3560): _reject("ORIGINAL_LOCAL_CONNECTOR_IDENTITY"); return
	var node: Node2D=feature.get("node") as Node2D
	state["scroll_before"]=feature.duplicate()
	state["scroll_visible"]=node.visible if is_instance_valid(node) else false
	if is_instance_valid(node): node.hide()
	features.erase(key)
	state["original_G_scroll_retired"]=true

func _contact(foot: Vector2,field: Node,endpoint: Dictionary) -> bool:
	if _preparing_travel or _barrier_field != null: return false
	if not Geo.live(field) or _dialog.call("is_playing") or field.get("_system_panel_open")==true: return false
	if _loading.get("_transition_active")==true or _loading.get("_external_active")==true or not _pending.is_empty(): return false
	var scene: SceneScript=_scene(field)
	return scene!=null and String(scene.scene_id)==endpoint.scene_id and Geo.safe_segment(endpoint.scene_id,foot,endpoint.mouth) and Geo.physics_clear(field,foot)

func _travel(_target: String,_uv: Vector2,field: Node,endpoint: Dictionary) -> void:
	var actor: Player=field.get("_player") as Player
	if actor==null or not _contact(actor.position,field,endpoint): return
	var rect:=Rect2(endpoint.mouth-endpoint.activation_size*.5,endpoint.activation_size)
	if not rect.has_point(actor.position): return
	var destination: Dictionary=endpoint.target
	var source_ref: WeakRef=weakref(field)
	var source_actor: WeakRef=weakref(actor)
	var source_scene: SceneScript=_scene(field)
	var source_foot: Vector2=actor.position
	var source_can_move: bool=actor.can_move
	var external_token: int=int(_loading.get("_external_token"))
	var started_usec: int=Time.get_ticks_usec()
	_preparing_travel=true
	actor.set_can_move(false)
	var screen: Node=_loading.get("_screen") as Node
	if screen==null or not _screen_barrier_installed:
		_preparing_travel=false; actor.set_can_move(source_can_move); _reject("DRAW_FIRST_SCREEN_NOT_INSTALLED"); return
	screen.call("configure",_loading.call("_choose_card",&"field"),"前往"+Pair.destination_name(String(destination.logical_id)))
	screen.call("set_progress",0.0,"正在准备道路与入口……")
	screen.call("show_screen",true)
	await RenderingServer.frame_post_draw
	var first_draw_usec: int=Time.get_ticks_usec()
	var current: Node=source_ref.get_ref() as Node
	if current!=field or get_tree().current_scene!=field or not is_instance_valid(actor) or _loading.get("_transition_active")==true or _loading.get("_external_active")==true or int(_loading.get("_external_token"))!=external_token:
		_preparing_travel=false; _restore_preparing_actor(source_ref,source_actor,source_can_move); return
	# Hash file bytes off-thread, then verify the genuine live owner on the
	# main thread AFTER the await. A refresh cannot reuse an earlier lease check.
	var sources_valid: bool=await _fresh_sources_match()
	var context_valid: bool=is_instance_valid(actor) and source_ref.get_ref()==get_tree().current_scene and _scene(field)==source_scene and field.get("_player")==actor and actor.position==source_foot and not _dialog.call("is_playing") and field.get("_system_panel_open")!=true and int(_loading.get("_external_token"))==external_token
	var owner_valid: bool=context_valid and Geo.live(field,true)
	if not owner_valid or not sources_valid:
		_preparing_travel=false; _restore_preparing_actor(source_ref,source_actor,source_can_move)
		if int(_loading.get("_external_token"))==external_token and not _loading.get("_transition_active") and not _loading.get("_external_active"): screen.call("hide_screen")
		_reject("DRAW_FIRST_SOURCE_OR_CONTEXT_REJECTED"); return
	if not Geo.safe_segment(destination.scene_id,destination.arrival,destination.mouth):
		_preparing_travel=false; _restore_preparing_actor(source_ref,source_actor,source_can_move); screen.call("hide_screen"); _reject("TARGET_DECLARED_ROUTE_NOT_SAFE"); return
	var world_links: Node
	if endpoint.pair_id=="temple_riverside" and endpoint.side=="a":
		var adventure: Node=get_node_or_null("/root/AdventureRuntime")
		world_links=adventure.get_node_or_null("AdventureWorldLinks31f") if adventure!=null else null
		if world_links==null:
			_preparing_travel=false; _restore_preparing_actor(source_ref,source_actor,source_can_move); screen.call("hide_screen"); _reject("ORIGINAL_WORLD_ORIGIN_TRANSACTION_MISSING"); return
		world_links.call("local_connector_requested",field,Geo.ADVENTURE)
	# Restore precisely our movement hold before ORIGINAL dispatch takes over.
	_restore_preparing_actor(source_ref,source_actor,source_can_move)
	var accepted:=false
	var region_dispatch: GDScript=load(REGION_PATH) as GDScript
	if region_dispatch.Entry.requested(StringName(destination.logical_id)):
		var compiled: Dictionary=Geo.region_for(destination.scene_id)
		var extension: Dictionary={"region_id":destination.scene_id,"revision":compiled.revision,"logical_id":destination.logical_id,"global_foot_px":[destination.arrival.x,destination.arrival.y]}
		var legacy: Vector2=compiled.districts[destination.logical_id].save_fallback_uv
		var public_state: Dictionary=_router.call("get_public_city_preparation_state")
		if not public_state.get("active",false):
			accepted=region_dispatch.start(_router,StringName(destination.logical_id),legacy,"",3,extension)
	else:
		accepted=_router.call("go_field_smart",StringName(destination.logical_id),destination.arrival/Geo.size_for(destination.scene_id),"",int(_router.call("world_version_for_scene",_router.call("get_active_world_map_scene"))),3)
	_preparing_travel=false
	_latency_history.append({"phase":"DRAW_FIRST_ORIGINAL_PAIR_DISPATCH","pair_id":endpoint.pair_id,"start_usec":started_usec,"loading_draw_usec":first_draw_usec,"original_dispatch_return_usec":Time.get_ticks_usec(),"source_hash_job":_last_source_job.duplicate(true),"accepted":accepted,"private_loading_flags_or_tokens_written":false})
	if _latency_history.size()>12: _latency_history.pop_front()
	if not accepted:
		if not _loading.get("_transition_active") and not _loading.get("_external_active"): screen.call("hide_screen")
		_reject("ORIGINAL_TARGET_REQUEST_REFUSED:"+endpoint.id); return
	_pending={"source":source_ref,"pair_id":endpoint.pair_id,"source_side":endpoint.side,"source_scene":endpoint.scene_id,"source_activation_foot":source_foot,"source_declared_return":endpoint.arrival,"target_scene":destination.scene_id,"target_logical":destination.logical_id,"target_foot":destination.arrival,"started_msec":Time.get_ticks_msec()}

func _restore_preparing_actor(field_ref: WeakRef,actor_ref: WeakRef,enabled: bool) -> void:
	var field: Node=field_ref.get_ref() as Node if field_ref!=null else null
	var actor: Player=actor_ref.get_ref() as Player if actor_ref!=null else null
	if is_instance_valid(field) and field==get_tree().current_scene and is_instance_valid(actor) and field.get("_player")==actor and not _dialog.call("is_playing") and field.get("_system_panel_open")!=true:
		actor.set_can_move(enabled)

func _advance_pending(field: Node,scene: SceneScript) -> void:
	if _pending.is_empty(): return
	if Time.get_ticks_msec()-int(_pending.started_msec)>60000: _reject("PAIR_REQUEST_TIMEOUT"); _pending.clear(); return
	var source: Node=_pending.source.get_ref() as Node
	if field==source: return
	if String(scene.scene_id)!=_pending.target_scene: _pending.clear(); return
	var actor: Player=field.get("_player") as Player
	if actor==null or actor.position.distance_to(_pending.target_foot)>.02 or not Geo.physics_clear(field,actor.position): _reject("ORIGINAL_TARGET_FINAL_FOOT_DIFFERS"); _pending.clear(); return
	var completed: Dictionary=_pending.duplicate(true)
	completed.erase("source"); completed["actual_arrival"]=actor.position; completed["completed_msec"]=Time.get_ticks_msec()
	_history.append(completed)
	if _history.size()>24: _history.pop_front()
	if _pending.pair_id=="temple_riverside":
		_local_adventure=String(scene.scene_id)==Geo.ADVENTURE
		_local_adventure_field=weakref(field) if _local_adventure else null
	_pending.clear()

func audit_relations() -> Dictionary:
	var rows: Array[Dictionary]=[]; var ok:=_ready_sources
	for pair: Dictionary in Pair.relations():
		for side: String in ["a","b"]:
			var endpoint: Dictionary=pair[side]
			var safe: bool=Geo.safe_segment(endpoint.scene_id,endpoint.arrival,endpoint.mouth)
			ok=ok and safe
			rows.append({"pair_id":pair.pair_id,"side":side,"scene_id":endpoint.scene_id,"source_portal":endpoint.source_portal,"mouth":endpoint.mouth,"arrival":endpoint.arrival,"outward":endpoint.outward,"activation_size":endpoint.activation_size,"full_body_route_safe":safe})
	return {"ok":ok,"pair_count":11,"end_count":rows.size(),"rows":rows,"original_geometry_mutations":0}

func get_debug_state() -> Dictionary:
	var field: Node=get_tree().current_scene
	var state: Dictionary=_states.get(_key(field),{}) if is_instance_valid(field) else {}
	var pending: Dictionary=_pending.duplicate(true); pending.erase("source")
	return {"ready":_ready_sources,"last_error":_last_error,"attached_scene":state.get("scene_id",""),"metadata":state.get("metadata",{}).duplicate(true),"pending":pending,"route_history":_history.duplicate(true),"mini_ok":state.get("mini_ok",false),"art":state.get("art",{}),"source_manifest_sha256":_manifest_sha,"local_adventure":_local_adventure,"shared_source_writes":0,"save_API_calls":0,"screen_barrier_installed":_screen_barrier_installed,"preparing_travel":_preparing_travel,"view_barrier_active":_barrier_field!=null,"latency_history":_latency_history.duplicate(true)}


func _install_loading_screen() -> bool:
	var existing: Node=_loading.get("_screen") as Node
	if is_instance_valid(existing): return existing.get_script()==ScreenBarrier
	var screen: Node=ScreenScene.instantiate()
	if screen.get_script()!=ScreenBase:
		screen.free(); return false
	screen.set_script(ScreenBarrier)
	_loading.add_child(screen)
	_loading.set("_screen",screen)
	return _loading.get("_screen")==screen

func _hash_sources_worker(pins: Dictionary,manifest: String,expected: String) -> Dictionary:
	# Worker performs file I/O only: no Nodes, resources, images or global state.
	var started: int=Time.get_ticks_usec()
	if FileAccess.get_sha256(manifest)!=expected: return {"ok":false,"reason":"MANIFEST","count":0}
	var count:=0
	for path: String in pins:
		if path=="res://project.godot": continue
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=pins[path]:
			return {"ok":false,"reason":"SOURCE:"+path,"count":count,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0}
		count+=1
	return {"ok":FileAccess.get_sha256(manifest)==expected,"count":count,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"fresh_full_hash":true}

func _fresh_sources_match() -> bool:
	if _pins.is_empty() or ProjectSettings.get_setting("autoload/CityNavigationRuntime","")!="*"+SELF or _source_thread!=null: return false
	_source_thread=Thread.new()
	var error: Error=_source_thread.start(_hash_sources_worker.bind(_pins.duplicate(true),MANIFEST,_manifest_sha))
	if error!=OK:
		_source_thread=null
		_last_source_job={"ok":_sources_match(),"thread_error":error,"synchronous_fallback":true}
		return _last_source_job.ok
	while _source_thread.is_alive():
		await get_tree().process_frame
	var result: Variant=_source_thread.wait_to_finish()
	_source_thread=null
	_last_source_job=result if result is Dictionary else {"ok":false,"reason":"WORKER_RESULT"}
	return _last_source_job.get("ok")==true

func loading_barrier_required(field: Node) -> bool:
	if not _ready_sources or not is_instance_valid(field) or field.get_script()==null or field.get_script().resource_path not in [Pair.MAIN_FIELD,Pair.REGION_FIELD]: return false
	var scene: SceneScript=_scene(field)
	if scene==null or String(scene.scene_id) not in Pair.area_ids()+Pair.room_ids(): return false
	var key: String=_key(field)
	return not _states.has(key) or not _state_alive(_states[key],field) or _states[key].get("mini_ok")!=true

func view_preparation_busy() -> bool:
	return _preparing_travel or _barrier_field!=null

func begin_loading_barrier(field: Node) -> bool:
	if _barrier_field!=null or not loading_barrier_required(field) or field!=get_tree().current_scene: return false
	var actor: Player=field.get("_player") as Player
	if actor==null: return false
	_barrier_field=weakref(field); _barrier_actor=weakref(actor); _barrier_can_move=actor.can_move
	actor.set_can_move(false)
	return true

func prepare_field_for_loading(field: Node) -> bool:
	if _barrier_field==null or _barrier_field.get_ref()!=field or field!=get_tree().current_scene: return false
	if _loading.get("_transition_active")==true or _loading.get("_external_active")==true: return false
	var started: int=Time.get_ticks_usec()
	var scene: SceneScript=_scene(field)
	var scene_id: int=scene.get_instance_id() if scene!=null else 0
	if scene==null: return false
	var fresh: bool=await _fresh_sources_match()
	if not fresh: _reject("LIVE_FROZEN_SOURCE_CHANGED"); return false
	if field!=get_tree().current_scene or _scene(field)==null or _scene(field).get_instance_id()!=scene_id: return false
	var key: String=_key(field)
	if not _states.has(key) or not _state_alive(_states[key],field): _attach(field,scene,key)
	if not _states.has(key): return false
	var state: Dictionary=_states[key]
	if state.get("mini_ok")!=true: _attach_mini(field,state)
	var icons: Node=get_node_or_null("/root/MapIconRuntime")
	# Real one-shot render completion is part of the barrier, not first-play work.
	for frame: int in range(180):
		if field!=get_tree().current_scene or field.get("_field_loading_failed")==true: return false
		var mini: Node=field.get("_world_travel_minimap") as Node
		var cache: Node=mini.get("_visual_cache") as Node if is_instance_valid(mini) else null
		if state.get("mini_ok")==true and (cache==null or cache.get("capture_ready")==true):
			var icons_ready := true
			if icons!=null and icons.has_method("prepare_field_for_loading"):
				icons_ready=bool(await icons.call("prepare_field_for_loading",field))
			if field!=get_tree().current_scene: return false
			# A just-created one-shot cache can be ready one frame before its
			# plan.visible refresh. This is pending, not a source/identity failure.
			if icons_ready:
				await RenderingServer.frame_post_draw
				if field!=get_tree().current_scene or field.get("_field_loading_failed")==true: return false
				_advance_pending(field,scene)
				_latency_history.append({"phase":"REAL_FIELD_VIEW_BARRIER","scene_id":String(scene.scene_id),"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"source_hash_job":_last_source_job.duplicate(true),"mini_render_ready":true,"icon_runtime_ready":true,"original_loading_flags_reset_before_legacy_owner_check":true})
				if _latency_history.size()>12: _latency_history.pop_front()
				return true
		await RenderingServer.frame_post_draw
	_reject("MINIMAP_RENDER_BARRIER_TIMEOUT"); return false

func finish_loading_barrier(field: Node,hidden: bool) -> void:
	if not hidden or _barrier_field==null or _barrier_field.get_ref()!=field: return
	_restore_preparing_actor(_barrier_field,_barrier_actor,_barrier_can_move)
	_barrier_field=null; _barrier_actor=null; _barrier_can_move=false

func cancel_loading_barrier(field: Node) -> void:
	if _barrier_field==null or _barrier_field.get_ref()!=field: return
	_restore_preparing_actor(_barrier_field,_barrier_actor,_barrier_can_move)
	_barrier_field=null; _barrier_actor=null; _barrier_can_move=false

func _exit_tree() -> void:
	if _source_thread!=null:
		_source_thread.wait_to_finish()
		_source_thread=null
