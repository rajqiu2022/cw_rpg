extends Node
## Candidate only. Original layout/NAV/physics remain authoritative and complete.
const PREFETCH := 512.0
const RETAIN := 1024.0
const BIN := 512.0
const REQUEST_LIMIT := 8
const SLICE_USEC := 8000
const RESIDENT_ESTIMATE_BUDGET_BYTES := 256 * 1024 * 1024
const RESIDENT_OBJECTS := 1024
const WORLD_CONTRACT = preload("res://scripts/world/world_map_v15_contract.gd")
const BRIDGE30M = preload("res://build/world_bridges_20261030m_system01/bridge_visual_patch.gd")
const BRIDGE_BINDING_SHA := "9a5a767a8a71c80b25d44d4630e2fa4d714a446141edc4aa8592435ca3f3082e" # Root-approved actual native profiles/imports.
static var _broker: Node
static var _serial := 0

class LoaderBroker:
	extends Node
	var rows: Dictionary = {}
	var serial := 0
	var peak := 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_process(false)

	func request(path: String, owner: Node, epoch: int) -> int:
		if rows.size() >= 8: return 0
		for row: Dictionary in rows.values():
			if row.path == path: return 0 # Includes abandoned, unfinished requests.
		if ResourceLoader.load_threaded_request(path, "Texture2D", true) != OK: return -1
		serial += 1
		rows[serial] = {"path":path,"owner":weakref(owner),"epoch":epoch,"state":0,"resource":null}
		peak = maxi(peak, rows.size())
		set_process(true)
		return serial

	func _valid(row: Dictionary) -> bool:
		var owner: Node = row.owner.get_ref() if row.owner != null else null
		return is_instance_valid(owner) and owner.call("owns_epoch", int(row.epoch))

	func cancel(owner: Node, epoch: int) -> void:
		for ticket: int in rows.keys():
			var row: Dictionary = rows[ticket]
			if row.owner == null or row.owner.get_ref() != owner or int(row.epoch) != epoch: continue
			row.owner = null
			row.resource = null
			if int(row.state) != 0: rows.erase(ticket)
		set_process(not rows.is_empty())

	func take(ticket: int, owner: Node, epoch: int) -> Dictionary:
		if not rows.has(ticket): return {"state":-1}
		var row: Dictionary = rows[ticket]
		if row.owner == null or row.owner.get_ref() != owner or int(row.epoch) != epoch or not _valid(row): return {"state":-1}
		if int(row.state) == 0: return {"state":0}
		var result := {"state":row.state,"resource":row.resource}
		rows.erase(ticket)
		return result

	func _process(_delta: float) -> void:
		var started := Time.get_ticks_usec()
		for ticket: int in rows.keys():
			var row: Dictionary = rows[ticket]
			if not _valid(row):
				row.owner = null
				row.resource = null
				if int(row.state) != 0:
					rows.erase(ticket)
					continue
			if int(row.state) != 0: continue
			var status := ResourceLoader.load_threaded_get_status(row.path)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
			var resource: Resource = ResourceLoader.load_threaded_get(row.path) if status == ResourceLoader.THREAD_LOAD_LOADED else null
			if not _valid(row):
				rows.erase(ticket) # Late completion is consumed and discarded only.
			else:
				row.resource = resource
				row.state = 1 if resource is Texture2D else -1
			if Time.get_ticks_usec() - started >= 8000: break
		set_process(not rows.is_empty())

	func _exit_tree() -> void:
		# Shutdown must not block waiting on Godot's loader workers.
		rows.clear()

static func applies(scene: SceneScript) -> bool:
	return not OS.has_feature("web") and WORLD_CONTRACT.is_v15(scene)

static func broker(tree: SceneTree) -> Node:
	if not is_instance_valid(_broker):
		_broker = LoaderBroker.new()
		_broker.name = "WorldV15VisibleRequestDrain"
		tree.root.add_child(_broker)
	return _broker

static func drain_count() -> int:
	return (_broker.get("rows") as Dictionary).size() if is_instance_valid(_broker) else 0

static func wait_for_drains(tree: SceneTree, owner: Callable) -> bool:
	while drain_count() > 0:
		if not owner.is_valid() or not owner.call(): return false
		await tree.process_frame
	return owner.is_valid() and owner.call()

static func view_rect(point: Vector2, viewport: Vector2, zoom: float, size: Vector2) -> Rect2:
	var visible := viewport / maxf(1.0, zoom)
	var half := visible * .5
	var center := point.clamp(half.min(size * .5), (size - half).max(size * .5))
	return Rect2(center - half, visible)

static func render_bounds(data: Dictionary, size: Vector2) -> Rect2:
	if not data.get("pos") is Vector2 or not data.get("render_size_px") is Vector2: return Rect2()
	var extent: Vector2 = data.render_size_px
	var origin: Vector2 = data.pos * size
	var angle := deg_to_rad(float(data.get("rotation",0.0)))
	if not origin.is_finite() or not extent.is_finite() or not is_finite(angle) or extent.x <= 0 or extent.y <= 0: return Rect2()
	var offset := -extent*.5 if bool(data.get("centered",true)) else Vector2.ZERO
	var corners := [offset, offset+Vector2(extent.x,0), offset+extent, offset+Vector2(0,extent.y)]
	var bounds := Rect2(origin+(corners[0] as Vector2).rotated(angle),Vector2.ZERO)
	for corner: Vector2 in corners: bounds=bounds.expand(origin+corner.rotated(angle))
	return bounds

static func make_index(objects: Array, size: Vector2) -> Dictionary:
	for raw: Variant in objects:
		if not raw is Dictionary:return {"ok":false,"error":"OBJECT_TYPE"}
	var bridge: Dictionary=BRIDGE30M.prepare(objects,BRIDGE_BINDING_SHA)
	if not bridge.get("ok",false):return bridge
	var entries: Array[Dictionary]=[]
	var bins: Dictionary={}
	var ids: Dictionary={}
	var depth_ordinal:=0
	var bridge_visual_count:=0
	for ordinal in range(objects.size()):
		var source: Dictionary=objects[ordinal]
		var id:=String(source.get("id",""))
		var source_path:=String(source.get("texture",""))
		var source_bounds:=render_bounds(source,size)
		if id.is_empty() or ids.has(id) or source_path.is_empty() or not source_bounds.has_area():return {"ok":false,"error":"OBJECT_BOUNDS_OR_ID"}
		for key: String in ["require_flag","hide_flag","require_quest_active","require_quest_completed","interaction_action","ground_shadow_size_px"]:
			if source.has(key):return {"ok":false,"error":"UNSUPPORTED_WORLD_SEMANTIC:"+key}
		if bool(source.get("sort_by_feet",false)) and (not source.has("depth_sort_foot_y") or not is_finite(float(source.depth_sort_foot_y))):return {"ok":false,"error":"OBJECT_FOOT"}
		ids[id]=true
		# Count original depth slots even when their old visual is retired.
		var original_depth_ordinal: int=depth_ordinal
		if bool(source.get("sort_by_feet",false)):depth_ordinal+=1
		var data: Dictionary=BRIDGE30M.project(source,bridge)
		if data.is_empty():continue
		var path:=String(data.get("texture",""))
		var bounds:=render_bounds(data,size)
		if path.is_empty() or not bounds.has_area():return {"ok":false,"error":"BRIDGE_PRESENTATION_BOUNDS"}
		if data.get("_bridge_native30m",false):bridge_visual_count+=1
		# Sparse presentation array indices are not original source ordinals.
		var entry_index: int=entries.size()
		entries.append({"data":data,"bounds":bounds,"ordinal":ordinal,"depth_ordinal":original_depth_ordinal,"id":id,"path":path})
		for y in range(int(floor(bounds.position.y/BIN)),int(floor(bounds.end.y/BIN))+1):
			for x in range(int(floor(bounds.position.x/BIN)),int(floor(bounds.end.x/BIN))+1):
				var cell:=Vector2i(x,y)
				if not bins.has(cell):bins[cell]=[]
				bins[cell].append(entry_index)
	return {"ok":true,"entries":entries,"bins":bins,"depth_count":depth_ordinal,"bridge_visual_count":bridge_visual_count,"bridge_native_images":5,"bridge_original_visuals":93,"bridge_original_physics_unchanged":true}

static func query(index: Dictionary, rect: Rect2) -> Array[int]:
	var found: Dictionary={}
	for y in range(int(floor(rect.position.y/BIN)),int(floor(rect.end.y/BIN))+1):
		for x in range(int(floor(rect.position.x/BIN)),int(floor(rect.end.x/BIN))+1):
			for ordinal: int in index.bins.get(Vector2i(x,y),[]):
				if index.entries[ordinal].bounds.intersects(rect,true): found[ordinal]=true
	var result: Array[int]=[]
	for ordinal: int in found: result.append(ordinal)
	result.sort()
	return result

static func initial_selection(scene: SceneScript, spawn: Vector2, viewport: Vector2) -> Dictionary:
	if not applies(scene) or scene.map_layout==null: return {"ok":false,"error":"WORLD_SCOPE"}
	var size:=Vector2(scene.map_layout.design_size)
	var index:=make_index(scene.map_layout.visual_objects,size)
	if not index.ok: return index
	var paths: Dictionary={}
	var selected:=query(index,view_rect(spawn*size,viewport,scene.camera_zoom,size).grow(PREFETCH))
	for ordinal: int in selected: paths[index.entries[ordinal].path]=true
	return {"ok":true,"paths":paths,"total":index.entries.size(),"selected":selected.size()}

var _field: WeakRef
var _scene: SceneScript
var _revision:=0
var _epoch:=0
var _alive:=false
var _suspended:=false
var _index: Dictionary={}
var _size:=Vector2.ZERO
var _viewport:=Vector2.ZERO
var _zoom:=1.0
var _focus: WeakRef
var _camera: WeakRef
var _loaded: Dictionary={}
var _tickets: Dictionary={}
var _wanted: Dictionary={}
var _bytes:=0
var _bridge_texture_refs: Dictionary={}
var _bridge_texture_costs: Dictionary={}
var _last_rect:=Rect2()
var error:=""
var metrics: Dictionary={"prime_usec":0,"index_usec":0,"body_build_wall_usec":0,"physical_object_count":0,"attach_usec":0,"attach_peak_usec":0,"attached_total":0,"detached_total":0,"loaded_peak":0,"estimated_bytes_peak":0,"index_count":0,"visual_motion_waits":0}

func configure(field: Node, scene: SceneScript, revision: int, objects: Array, size: Vector2, viewport: Vector2, zoom: float) -> bool:
	var started:=Time.get_ticks_usec()
	_index=make_index(objects,size)
	metrics.index_usec=Time.get_ticks_usec()-started
	if not _index.ok:
		error=String(_index.error); return false
	_serial+=1; _epoch=_serial
	_field=weakref(field); _scene=scene; _revision=revision
	_size=size; _viewport=viewport; _zoom=zoom; _alive=true
	metrics.index_count=_index.entries.size()
	metrics.bridge_visual_count=int(_index.bridge_visual_count)
	metrics.bridge_native_images=5;metrics.bridge_original_visuals=93;metrics.bridge_original_physics_unchanged=true
	process_priority=50 # Before the existing priority100 alpha/depth refresh.
	set_process(false)
	broker(get_tree())
	return true

func owns_epoch(epoch: int) -> bool:
	if not _alive or _suspended or epoch!=_epoch or not is_inside_tree() or is_queued_for_deletion(): return false
	var field: Node=_field.get_ref() if _field!=null else null
	return is_instance_valid(field) and field.is_inside_tree() and not field.is_queued_for_deletion() and field.call("_owns_world_v15_stream",self,_scene,_revision)

func prime(point: Vector2) -> bool:
	var started:=Time.get_ticks_usec()
	var rect:=view_rect(point,_viewport,_zoom,_size)
	_set_wanted(rect)
	while owns_epoch(_epoch) and error.is_empty():
		_tick(rect)
		if _ready_set(_wanted):
			metrics.prime_usec=Time.get_ticks_usec()-started
			return true
		await get_tree().process_frame
	if _alive and not error.is_empty(): suspend()
	return false

func bind_view(focus: Node2D, camera: Camera2D) -> void:
	_focus=weakref(focus)
	_camera=weakref(camera) if is_instance_valid(camera) else null
	set_process(true)

func _process(_delta: float) -> void:
	if not owns_epoch(_epoch): release(); return
	var focus: Node2D=_focus.get_ref() if _focus!=null else null
	if not is_instance_valid(focus): return
	_viewport=get_viewport().get_visible_rect().size
	var rect:=view_rect(focus.position,_viewport,_zoom,_size)
	var camera: Camera2D=_camera.get_ref() if _camera!=null else null
	if is_instance_valid(camera):
		# This field uses no Camera2D smoothing, but cover both actual and target
		# views so viewport changes/first camera update cannot expose an empty roof.
		_zoom=maxf(1.0,camera.zoom.x)
		rect=rect.merge(view_rect(camera.get_screen_center_position(),_viewport,_zoom,_size))
	_set_wanted(rect)
	_tick(rect)
	if not error.is_empty():
		var field: Node=_field.get_ref()
		if is_instance_valid(field): field.call("_world_v15_stream_failed",self,error)
		set_process(false)

func _set_wanted(rect: Rect2) -> void:
	if rect==_last_rect and not _wanted.is_empty(): return
	_last_rect=rect
	_wanted.clear()
	for ordinal: int in query(_index,rect.grow(PREFETCH)): _wanted[ordinal]=true

func _ready_set(wanted: Dictionary) -> bool:
	for ordinal: int in wanted:
		if not _loaded.has(ordinal): return false
	return true

func visual_ready_for_motion(point: Vector2) -> bool:
	if not owns_epoch(_epoch) or not error.is_empty(): return false
	# This is a temporary I/O readiness gate, not a relaxed/nav replacement.
	# At SPEED480, ordinary physics steps remain well within the512px halo.
	for ordinal: int in query(_index,view_rect(point,_viewport,_zoom,_size).grow(2.0)):
		if not _loaded.has(ordinal):
			metrics.visual_motion_waits+=1
			return false
	return true

func _tick(rect: Rect2) -> void:
	if not owns_epoch(_epoch) or not error.is_empty(): return
	var started:=Time.get_ticks_usec()
	var loader: Node=broker(get_tree())
	# Evict outside hysteresis first, then pressure-evict non-wanted residents.
	var retain:=rect.grow(RETAIN)
	for ordinal: int in _loaded.keys():
		if not _index.entries[ordinal].bounds.intersects(retain,true): _detach(ordinal)
		if Time.get_ticks_usec()-started>=SLICE_USEC: return
	for ordinal: int in _tickets.keys():
		var result: Dictionary=loader.call("take",int(_tickets[ordinal]),self,_epoch)
		if int(result.state)==0: continue
		_tickets.erase(ordinal)
		if int(result.state)!=1:
			error="WORLD_VISUAL_LOAD_FAILED:"+String(_index.entries[ordinal].path); return
		if not _wanted.has(ordinal): continue
		var texture: Texture2D=result.resource as Texture2D
		# ESTIMATE_NOT_VRAM: 12B/base-pixel covers current8-bit PNG RGBA GPU/CPU
		# with mip allowance. It is not a measured/global memory cap and excludes
		# pending loader resources, background/NAV/player and other scene users.
		var shared_bridge: String=_index.entries[ordinal].path if _index.entries[ordinal].data.get("_bridge_native30m",false) else ""
		var native_cost:=texture.get_width()*texture.get_height()*12
		var cost: int=0 if not shared_bridge.is_empty() and _bridge_texture_refs.has(shared_bridge) else native_cost
		for old: int in _loaded.keys():
			if _bytes+cost<=RESIDENT_ESTIMATE_BUDGET_BYTES and _loaded.size()<RESIDENT_OBJECTS: break
			if not _wanted.has(old): _detach(old)
		if _bytes+cost>RESIDENT_ESTIMATE_BUDGET_BYTES or _loaded.size()>=RESIDENT_OBJECTS:
			error="WORLD_VISIBLE_RESIDENCY_BUDGET"; return
		var field: Node=_field.get_ref()
		var attach_started:=Time.get_ticks_usec()
		var node: Sprite2D=field.call("_attach_world_v15_visual",_index.entries[ordinal].data,texture,int(_index.entries[ordinal].depth_ordinal)) as Sprite2D
		if node==null:
			error="WORLD_VISUAL_ATTACH_FAILED"; return
		if not BRIDGE30M.attach(node,_index.entries[ordinal].data):
			field.call("_detach_world_v15_visual",node);error="WORLD_BRIDGE_NATIVE_ATTACH_FAILED";return
		_loaded[ordinal]={"node":node,"bytes":cost,"shared_bridge":shared_bridge}
		if not shared_bridge.is_empty():
			_bridge_texture_refs[shared_bridge]=int(_bridge_texture_refs.get(shared_bridge,0))+1
			_bridge_texture_costs[shared_bridge]=native_cost
		_bytes+=cost
		var elapsed:=Time.get_ticks_usec()-attach_started
		metrics.attach_usec+=elapsed
		metrics.attach_peak_usec=maxi(int(metrics.attach_peak_usec),elapsed)
		metrics.attached_total+=1
		metrics.loaded_peak=maxi(int(metrics.loaded_peak),_loaded.size())
		metrics.estimated_bytes_peak=maxi(int(metrics.estimated_bytes_peak),_bytes)
		if Time.get_ticks_usec()-started>=SLICE_USEC: return
	# All same-path requests share one owner; no blocking get/synchronous fallback.
	for ordinal: int in _wanted:
		if _loaded.has(ordinal) or _tickets.has(ordinal): continue
		if (loader.get("rows") as Dictionary).size()>=REQUEST_LIMIT: break
		var ticket: int=loader.call("request",_index.entries[ordinal].path,self,_epoch)
		if ticket<0:
			error="WORLD_VISUAL_REQUEST_FAILED:"+String(_index.entries[ordinal].path); return
		if ticket>0: _tickets[ordinal]=ticket
		if Time.get_ticks_usec()-started>=SLICE_USEC: break

func _detach(ordinal: int) -> void:
	if not _loaded.has(ordinal): return
	var row: Dictionary=_loaded[ordinal]
	var field: Node=_field.get_ref() if _field!=null else null
	if is_instance_valid(field): field.call("_detach_world_v15_visual",row.node)
	var shared_bridge: String=String(row.get("shared_bridge",""))
	if shared_bridge.is_empty():_bytes-=int(row.bytes)
	else:
		_bridge_texture_refs[shared_bridge]=int(_bridge_texture_refs[shared_bridge])-1
		if int(_bridge_texture_refs[shared_bridge])==0:
			_bytes-=int(_bridge_texture_costs[shared_bridge]);_bridge_texture_refs.erase(shared_bridge);_bridge_texture_costs.erase(shared_bridge)
	_loaded.erase(ordinal)
	metrics.detached_total+=1

func debug_state() -> Dictionary:
	var result:=metrics.duplicate(true)
	result.bridge_shared_texture_refs=_bridge_texture_refs.duplicate();result.bridge_binding_sha=BRIDGE_BINDING_SHA
	result.bridge_scope="DESKTOP_ONLY_ALL5_ORIGINAL_WORLD15_PHYSICS"
	result.merge({"epoch":_epoch,"loaded":_loaded.size(),"pending":_tickets.size(),"wanted":_wanted.size(),"resident_estimated_bytes":_bytes,"accounting":"ESTIMATE_NOT_VRAM_12_BYTES_PER_BASE_PIXEL_CURRENT_8BIT_PNG","pending_excluded_from_resident_estimate":true,"estimate_budget_bytes":RESIDENT_ESTIMATE_BUDGET_BYTES,"error":error,"broker_outstanding":drain_count()},true)
	return result

func record_body_stats(count: int, elapsed_wall_usec: int) -> void:
	metrics.physical_object_count=count
	metrics.body_build_wall_usec=elapsed_wall_usec

func suspend() -> void:
	if not _alive or _suspended: return
	_suspended=true
	if is_instance_valid(_broker): _broker.call("cancel",self,_epoch)
	_tickets.clear()
	# The inherited source Field process mode owns pause/resume. Keep this Node
	# processing-enabled so rollback can resume without recreating visual state.

func resume() -> void:
	if not _alive or not _suspended: return
	_serial+=1; _epoch=_serial
	_suspended=false

func release() -> void:
	if not _alive: return
	_alive=false
	set_process(false)
	if is_instance_valid(_broker): _broker.call("cancel",self,_epoch)
	for ordinal: int in _loaded.keys(): _detach(ordinal)
	_tickets.clear(); _wanted.clear(); _index.clear()
	_bridge_texture_refs.clear();_bridge_texture_costs.clear()
	_focus=null; _camera=null; _scene=null; _field=null

func _exit_tree() -> void:
	release()
