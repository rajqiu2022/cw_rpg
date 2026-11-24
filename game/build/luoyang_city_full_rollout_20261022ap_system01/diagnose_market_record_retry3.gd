extends SceneTree
## Diagnostic only: immutable AO packet + frozen AP author, no raster/Scene/physics.
const AP=preload("res://build/luoyang_city_full_rollout_20261022ap_system01/market_execution_retry3/market_transform.gd")
const OUT="res://build/luoyang_city_full_rollout_20261022ap_system01/record_diagnostic/"
var rows: Array=[]
var first_reject: String=""
func gate(ok: bool,label: String,actual: Variant=null,expected: Variant=null) -> void:
	rows.append({"ok":ok,"label":label,"actual_typed":var_to_str(actual),"expected_typed":var_to_str(expected)})
	if not ok and first_reject.is_empty(): first_reject=label
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge!=null: bridge.call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec()
	var spec: Dictionary=AP.author()
	if spec.is_empty(): quit(1);return
	var first: Dictionary={AP.AUTHOR:FileAccess.get_sha256(AP.AUTHOR)}
	var module_path: String="res://build/luoyang_city_full_rollout_20261022ap_system01/market_execution_retry3/market_transform.gd"
	first[module_path]=FileAccess.get_sha256(module_path)
	first[get_script().resource_path]=FileAccess.get_sha256(get_script().resource_path)
	first[spec.parent_packet_path]=FileAccess.get_sha256(spec.parent_packet_path)
	gate(first[spec.parent_packet_path]==spec.parent_packet_sha256,"IMMUTABLE_AO_PACKET_SHA",first[spec.parent_packet_path],spec.parent_packet_sha256)
	var raw: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	if not raw is Dictionary or not raw.get("record") is Dictionary: quit(1);return
	var parent: Dictionary=raw.record
	gate(parent.get("canonical_scene_id")==String(AP.ID),"RECORD_CITY",parent.get("canonical_scene_id"),String(AP.ID))
	gate(parent.get("objects",[]).size()==24,"RECORD_24",parent.get("objects",[]).size(),24)
	for replacement: Dictionary in spec.new_objects:
		var count: int=0
		for row: Dictionary in parent.objects:
			if row.id==replacement.id: count+=1
		gate(count==1,"REPLACEMENT_UNIQUE:"+replacement.id,count,1)
	for move: Dictionary in spec.layout_successor.native_moves:
		var current: Dictionary=AP.find(parent.objects,move.id)
		gate(not current.is_empty() and AP.v(current.get("world_foot_px",[INF,INF]))==AP.v(move.old_foot),"NATIVE_OLD_FOOT:"+move.id,current.get("world_foot_px"),AP.v(move.old_foot))
	var wall: Dictionary=AP.find(parent.objects,spec.layout_successor.wall.id)
	gate(not wall.is_empty() and AP.v(wall.get("world_foot_px",[INF,INF]))==AP.v(spec.layout_successor.wall.old_foot),"WALL_OLD_FOOT",wall.get("world_foot_px"),AP.v(spec.layout_successor.wall.old_foot))
	var moved: Array=AP.relocate_native_record(parent.objects,spec)
	gate(moved.size()==24,"NATIVE_RELOCATION_RESULT",moved.size(),24)
	for old: Dictionary in spec.retired_routes:
		var current: Dictionary=AP.find(parent.routes,old.id)
		gate(not current.is_empty(),"RETIRE_EXISTS:"+old.id,current.get("id"),old.id)
		if not current.is_empty():
			gate(AP.same(AP.wire(current.points_px),AP.wire(old.points_px)),"RETIRE_EXACT_WIRE:"+old.id,current.points_px,old.points_px)
	for change: Dictionary in spec.route_replacements:
		var current: Dictionary=AP.find(parent.routes,change.id)
		gate(not current.is_empty(),"REPLACE_ROUTE_EXISTS:"+change.id,current.get("id"),change.id)
		if not current.is_empty(): gate(AP.same(AP.wire(current.points_px),AP.wire(change.old_points_px)),"REPLACE_ROUTE_EXACT_WIRE:"+change.id,current.points_px,change.old_points_px)
	for added: Dictionary in spec.additional_routes:
		gate(AP.find(parent.routes,added.id).is_empty(),"NEW_ROUTE_NOT_EXISTING:"+added.id)
	var counts: Array[int]=[0,0,0,0,0]
	for portal: Dictionary in parent.gameplay_slots.portals:
		var matches: Array=[]
		for index: int in 5:
			if AP.v(portal.foot_px)==AP.v(spec.room_moves[index].old_return): counts[index]+=1;matches.append(index)
		gate(matches.size()<=1,"PORTAL_UNIQUE_MATCH",portal.foot_px,matches)
	gate(counts==AP.NATIVE_COUNTS,"EXACT_FIVE_NATIVE_PORTAL_COUNTS",counts,AP.NATIVE_COUNTS)
	var child: Dictionary=AP._record(parent,spec,AP.ROOT+String(AP.ID)+"/walk.png")
	gate(not child.is_empty(),"_RECORD_NONEMPTY")
	if not child.is_empty(): gate(AP.same(AP.inverse_record(child,parent,spec),parent),"COMPLETE_PARENT_INVERSE")
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		gate(final[path]==first[path],"SOURCE_FINAL:"+path)
	var result: Dictionary={"diagnostic_completed":true,"original_rejection_reproduced":not first_reject.is_empty(),"first_reject":first_reject,"gates":rows,"source_first":first,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"geometry_or_raster_or_scene_loaded":false,"scope":"PINNED_PARENT_TYPED_RECORD_REJECTION_DIAGNOSTIC_NOT_GEOMETRY_PASS"}
	var path: String=OUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: quit(1);return
	var stream: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if stream==null: quit(1);return
	stream.store_string(JSON.stringify(result,"\t",true,true));stream.close();print(JSON.stringify({"path":path,"first_reject":first_reject,"diagnostic_completed":true}));quit(0)
