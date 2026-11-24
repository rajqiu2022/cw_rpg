extends SceneTree
# Metadata-only, no autoload/Field/Texture/NAV loading. Root is the sole executor.
const SCENE_PATH := "res://data/scenes/world_map_jianghu.tres"
const LAYOUT_PATH := "res://data/maps/world_map_jianghu_layout_v15.tres"
const SOURCE_PATHS := [
 "res://data/scenes/world_map_jianghu.tres",
 "res://data/maps/world_map_jianghu_layout_v15.tres",
 "res://data/background_sets/world_map_jianghu_v15_streamed.tres",
 "res://data/dialogs/ch7_route_choice.tres",
 "res://scripts/domain/scene_script.gd",
 "res://scripts/domain/walkable_map_layout.gd",
 "res://scripts/domain/streamed_background_set.gd",
 "res://scripts/domain/dialog_script.gd",
 "res://scripts/domain/dialog_node.gd",
]
var report: Dictionary = {}
var out_dir := ""
var started := 0
var failed := false

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 started = Time.get_ticks_usec()
 var mode := "layout"
 var binary := ""
 var expected := ""
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
  if arg.begins_with("--binary="): binary = arg.trim_prefix("--binary=")
  if arg.begins_with("--expected="): expected = arg.trim_prefix("--expected=")
 out_dir = "res://outputs/%s_%s_%s" % [mode, OS.get_process_id(), started]
 if DirAccess.dir_exists_absolute(out_dir):
  push_error("Output must be absent")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(out_dir)
 report = {"mode":mode,"engine":Engine.get_version_info(),"process_cold_only":true,
  "os_disk_cache_cold":false,"no_autoload":true,"no_field":true,
  "errors":[],"output_dir":out_dir,"timings_ms":{}}
 if not _check(mode in ["scene","layout","binary","repeat_scene"], "Unknown mode"):
  _finish()
  return
 var target := binary if mode == "binary" else (SCENE_PATH if mode in ["scene","repeat_scene"] else LAYOUT_PATH)
 if mode == "binary" and not _check(binary.begins_with("res://outputs/") and binary.ends_with("/layout.res"), "Binary target must be prior NEW output"):
  _finish()
  return
 if not _check(not ResourceLoader.has_cached(SCENE_PATH), "Scene already cached before timer"):
  _finish()
  return
 if not _check(not ResourceLoader.has_cached(LAYOUT_PATH), "Layout already cached before timer"):
  _finish()
  return
 if not _check(not target.is_empty() and FileAccess.file_exists(target), "Target missing"):
  _finish()
  return
 if not _check(not ResourceLoader.has_cached(target), "Target already cached before timer"):
  _finish()
  return
 report["cached_before"] = {"scene":false,"layout":false,"target":false}
 if mode == "repeat_scene":
  _repeat_scene()
  _finish()
  return
 # File size only. No SHA/file-content reads before measured load.
 var file := FileAccess.open(target, FileAccess.READ)
 report["target_bytes"] = file.get_length()
 file.close()
 var t := Time.get_ticks_usec()
 var loaded: Resource = ResourceLoader.load(target, "", ResourceLoader.CACHE_MODE_REUSE)
 report.timings_ms["cold_load"] = _ms(t)
 if not _check(loaded != null, "Resource load failed"):
  _finish()
  return
 var layout: Resource = loaded.get("map_layout") if mode == "scene" else loaded
 if not _check(layout != null, "Layout absent"):
  _finish()
  return
 report["loaded_path"] = loaded.resource_path
 report["layout_path"] = layout.resource_path
 report["layout_facts"] = _facts(layout)
 report["cached_after"] = {"scene":ResourceLoader.has_cached(SCENE_PATH),"layout":ResourceLoader.has_cached(LAYOUT_PATH)}
 if not _check(int(layout.get("schema_version")) == 15, "Schema not 15"):
  _finish()
  return
 t = Time.get_ticks_usec()
 var original := _snapshot(layout)
 report.timings_ms["storage_snapshot"] = _ms(t)
 if failed:
  _finish()
  return
 _write_bytes(out_dir + "/storage_snapshot.bin", var_to_bytes(original))
 report["storage_snapshot_sha256"] = _sha_bytes(var_to_bytes(original))
 report["storage_properties"] = _snapshot_summary(original)
 if mode == "layout":
  var logical_path := layout.resource_path
  var res_path := out_dir + "/layout.res"
  if not _check(not FileAccess.file_exists(res_path), "Binary output already exists"):
   _finish()
   return
  t = Time.get_ticks_usec()
  var save_error := ResourceSaver.save(layout, res_path, ResourceSaver.FLAG_COMPRESS)
  report.timings_ms["save_binary"] = _ms(t)
  report["save_error"] = save_error
  if not _check(save_error == OK, "ResourceSaver failed"):
   _finish()
   return
  if not _check(layout.resource_path == logical_path, "Save changed original logical path"):
   _finish()
   return
  t = Time.get_ticks_usec()
  var reloaded: Resource = ResourceLoader.load(res_path, "", ResourceLoader.CACHE_MODE_IGNORE)
  report.timings_ms["same_process_binary_load"] = _ms(t)
  if not _check(reloaded != null, "Saved binary reload failed"):
   _finish()
   return
  t = Time.get_ticks_usec()
  var second := _snapshot(reloaded)
  report.timings_ms["binary_storage_snapshot"] = _ms(t)
  report["all_storage_equal"] = _same_snapshot(original, second)
  report["binary_path"] = res_path
  report["binary_sha256"] = FileAccess.get_sha256(res_path)
  var saved := FileAccess.open(res_path, FileAccess.READ)
  report["binary_bytes"] = saved.get_length()
  saved.close()
  report["binary_logical_path"] = reloaded.resource_path
  report["same_process_binary_not_cold"] = true
  _check(bool(report.all_storage_equal), "Native STORAGE differs after save/reload")
 elif mode == "binary":
  if not _check(expected.begins_with("res://outputs/") and FileAccess.file_exists(expected), "Expected snapshot must be prior NEW output"):
   _finish()
   return
  var expected_file := FileAccess.open(expected, FileAccess.READ)
  # bytes_to_var cannot instantiate objects; all object storage is explicit script descriptor.
  var prior: Variant = bytes_to_var(expected_file.get_buffer(expected_file.get_length()))
  expected_file.close()
  if not _check(prior is Array, "Expected snapshot invalid"):
   _finish()
   return
  report["all_storage_equal"] = _same_snapshot(prior, original)
  _check(bool(report.all_storage_equal), "Cold binary differs from prior native snapshot")
 # Hash only nine metadata leaves AFTER the measured load. No art/NAV content reads.
 t = Time.get_ticks_usec()
 var sources := []
 for path in SOURCE_PATHS:
  sources.append({"path":path,"sha256":FileAccess.get_sha256(path)})
 report["sources_after_load"] = sources
 report.timings_ms["metadata_hashes_after_load"] = _ms(t)
 _finish()

func _temporary_scene_facts() -> Dictionary:
 var t := Time.get_ticks_usec()
 var scene: Resource = ResourceLoader.load(SCENE_PATH, "", ResourceLoader.CACHE_MODE_REUSE)
 var row := {"load_ms":_ms(t),"scene_valid":scene != null}
 if scene != null:
  row["instance_id"] = scene.get_instance_id()
  row["facts"] = _facts(scene.get("map_layout"))
 # Neither scene nor layout is returned; returned facts contain no resources.
 return row

func _repeat_scene() -> void:
 var rows := []
 for i in 3:
  if _ms(started) > 12000.0:
   report["repeat_skipped_for_budget"] = true
   break
  var row := _temporary_scene_facts()
  row["cached_after_scope"] = {"scene":ResourceLoader.has_cached(SCENE_PATH),"layout":ResourceLoader.has_cached(LAYOUT_PATH)}
  rows.append(row)
  _check(bool(row.scene_valid), "Temporary Scene load failed")
 report["temporary_scene_loads"] = rows
 if _ms(started) > 12000.0:
  report["strong_hold_control_skipped_for_budget"] = true
  return
 var t := Time.get_ticks_usec()
 var held: Resource = ResourceLoader.load(SCENE_PATH, "", ResourceLoader.CACHE_MODE_REUSE)
 report["strong_hold_initial_load_ms"] = _ms(t)
 if not _check(held != null, "Strong hold load failed"): return
 var held_id := held.get_instance_id()
 var repeats := []
 for i in 3:
  t = Time.get_ticks_usec()
  var again: Resource = ResourceLoader.load(SCENE_PATH, "", ResourceLoader.CACHE_MODE_REUSE)
  var elapsed := _ms(t)
  var same := again == held
  repeats.append({"load_ms":elapsed,"same_instance":same,"instance_id":again.get_instance_id() if again != null else 0})
  _check(same, "CACHE_REUSE failed while original Scene strongly held")
 report["held_scene_id"] = held_id
 report["strong_hold_repeats"] = repeats

func _snapshot(resource: Resource) -> Array:
 var rows := []
 for property in resource.get_property_list():
  if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
  var name := String(property.name)
  var value: Variant = resource.get(name)
  var bytes := PackedByteArray()
  if name == "script":
   if not _check(value is Script, "Storage script not Script"): return []
   bytes = var_to_bytes([value.resource_path, FileAccess.get_sha256(value.resource_path)])
  else:
   if not _check(_object_free(value), "Unexpected object in STORAGE " + name): return []
   bytes = var_to_bytes(value)
  # Preserve property order, exact type, usage and native typed collection bytes.
  rows.append({"name":name,"type":int(property.type),"usage":int(property.usage),"bytes":bytes})
 var metadata := {}
 for key in resource.get_meta_list(): metadata[key] = resource.get_meta(key)
 if not _check(_object_free(metadata), "Unexpected object in metadata"): return []
 rows.append({"name":"__resource_metadata__","type":TYPE_DICTIONARY,"usage":0,"bytes":var_to_bytes(metadata)})
 return rows

func _object_free(value: Variant) -> bool:
 if typeof(value) == TYPE_OBJECT: return value == null
 if value is Array:
  for item in value:
   if not _object_free(item): return false
 elif value is Dictionary:
  for key in value:
   if not _object_free(key) or not _object_free(value[key]): return false
 return true

func _same_snapshot(a: Array, b: Array) -> bool:
 if a.size() != b.size(): return false
 for i in a.size():
  if a[i].name != b[i].name or a[i].type != b[i].type or a[i].usage != b[i].usage or a[i].bytes != b[i].bytes: return false
 return true

func _snapshot_summary(rows: Array) -> Array:
 var result := []
 for row in rows:
  result.append({"name":row.name,"type":row.type,"usage":row.usage,"byte_count":row.bytes.size(),"sha256":_sha_bytes(row.bytes)})
 return result

func _facts(resource: Resource) -> Dictionary:
 var result := {"schema_version":resource.get("schema_version"),"design_size":str(resource.get("design_size"))}
 for name in ["visual_objects","blockers","portals","walkable_mask_tiles","walkable_regions","interactions","tiles","occluders","actor_fade_zones","walkable_probes","blocked_probes","seam_crossing_probes"]:
  var value: Variant = resource.get(name)
  result[name] = value.size() if value is Array else -1
 return result

func _sha_bytes(bytes: PackedByteArray) -> String:
 var ctx := HashingContext.new()
 ctx.start(HashingContext.HASH_SHA256)
 ctx.update(bytes)
 return ctx.finish().hex_encode()

func _write_bytes(path: String, bytes: PackedByteArray) -> void:
 var file := FileAccess.open(path, FileAccess.WRITE)
 if file == null:
  _check(false, "Output write failed " + path)
  return
 file.store_buffer(bytes)
 file.close()

func _ms(t: int) -> float:
 return float(Time.get_ticks_usec() - t) / 1000.0

func _check(condition: bool, message: String) -> bool:
 if not condition:
  failed = true
  report.errors.append(message)
  push_error(message)
 return condition

func _finish() -> void:
 report["elapsed_ms"] = _ms(started)
 report["within_20s_observed"] = float(report.elapsed_ms) < 20000.0
 report["passed"] = not failed
 var file := FileAccess.open(out_dir + "/result.json", FileAccess.WRITE)
 if file != null:
  file.store_string(JSON.stringify(report, "  "))
  file.close()
 print("WORLD_LAYOUT_PARSE_PROBE ", JSON.stringify({"passed":not failed,"output":out_dir,"timings_ms":report.get("timings_ms",{}),"elapsed_ms":report.elapsed_ms}))
 quit(1 if failed else 0)

