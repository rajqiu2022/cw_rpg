"""Build-only exact G local snapshot and owner-bound Field timing candidates."""
import copy
import difflib
import hashlib
import json
from pathlib import Path

HOME = Path(__file__).resolve().parent
GAME = HOME.parents[1]
S = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT = S + 'portal_clone_field_timing01/'
OWNER = S + 'finite10_yamen_classification/actual_deployment_review/owner_source_maps_ROOT_DEPLOYED_READY.json'
OWNER_SHA = '690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902'
G = 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
FIELD = 'res://scripts/field/field_walkable_controller.gd'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def path(value):
    assert value.startswith('res://') and '..' not in value
    return GAME / value[6:]

def fixed(value, expected):
    raw = path(value).read_bytes()
    assert sha(raw) == expected, ('PIN_CHANGED', value)
    return raw

def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')

owner = json.loads(fixed(OWNER, OWNER_SHA))
gsha = '2e305b0477c2cc0b8f48450377409f88ef38e769e7fe3f827912c81f591d15f9'
fsha = '0c9db5be0536c8438b892b0065a25b1ea352762180524be13da52cef534540cb'
assert owner['core_source_sha256'][G] == gsha and owner['core_source_sha256'][FIELD] == fsha
originals = {
    G: fixed(G, gsha),
    FIELD: fixed(S + 'finite_adapter_production08/Field_TEXT_ONLY_consumer_READY.gd', fsha),
}
assert fixed(FIELD, fsha) == originals[FIELD]
work = {k: v.decode('utf-8') for k, v in originals.items()}
assert all('\r' not in value for value in work.values())
operations = {G: [], FIELD: []}

def change(target, label, old, new):
    assert old != new and work[target].count(old) == 1, ('EXACT_UNIQUE_OLD', target, label, work[target].count(old))
    offset = work[target].index(old)
    operations[target].append({'label': label, 'byte_offset_before_this_change': len(work[target][:offset].encode()), 'old': old, 'new': new})
    work[target] = work[target].replace(old, new, 1)

change(G, 'one_function_local_catalogue_snapshot_and_loop',
       '\tfor id: String in catalogue().get("rooms",{}):\n\t\tvar data: Dictionary=author_for_id(StringName(id)); var row: Dictionary=data.get("room",{});var door_scene_path: String=String(catalogue().rooms[id].scene_path)\n',
       '\tvar config: Dictionary=catalogue()\n\tfor id: String in config.get("rooms",{}):\n\t\tvar data: Dictionary=author_for_id(StringName(id)); var row: Dictionary=data.get("room",{});var door_scene_path: String=String(config.rooms[id].scene_path)\n')
change(G, 'same_local_snapshot_for_prior_mansion_row',
       '\t\t\tvar parent: Dictionary=catalogue().rooms[id].get("am_parent_row",{})\n',
       '\t\t\tvar parent: Dictionary=config.rooms[id].get("am_parent_row",{})\n')

change(FIELD, 'per_field_scalar_profile_storage',
       'var _culture_committing := false\n',
       'var _culture_committing := false\nvar _field_loading_profile: Dictionary = {}\nvar _field_loading_ui_profile: Dictionary = {}\n')
change(FIELD, 'ready_ui_start_only_clock',
       'func _ready() -> void:\n\t_culture_x = CULTURE_X.new()\n',
       'func _ready() -> void:\n\tvar loading_ui_started: Dictionary = _field_loading_profile_clock()\n\t_culture_x = CULTURE_X.new()\n')
change(FIELD, 'ready_ui_finish_only_clock',
       '\t_disable_gameplay_button_focus(self)\n\tvar field_payload := SceneRouter.get_field_payload()\n',
       '\t_disable_gameplay_button_focus(self)\n\t_field_loading_ui_profile = _field_loading_profile_span(loading_ui_started, _field_loading_profile_clock())\n\tvar field_payload := SceneRouter.get_field_payload()\n')

helpers = '''func get_field_loading_profile() -> Dictionary:
	var result: Dictionary = _field_loading_profile.duplicate(true)
	if result.is_empty(): return result
	result["owner_current"] = _current_scene != null and result.get("scene_instance") == _current_scene.get_instance_id() and result.get("motion_revision") == _city3_motion_revision and result.get("Field_instance") == get_instance_id()
	return result


func _field_loading_profile_clock() -> Dictionary:
	return {"usec":Time.get_ticks_usec(), "process_frame":Engine.get_process_frames(), "physics_frame":Engine.get_physics_frames()}


func _field_loading_profile_span(started: Dictionary, finished: Dictionary) -> Dictionary:
	return {"started_usec":started.usec, "finished_usec":finished.usec, "wall_usec":finished.usec-started.usec, "started_process_frame":started.process_frame, "finished_process_frame":finished.process_frame, "process_frames":finished.process_frame-started.process_frame, "started_physics_frame":started.physics_frame, "finished_physics_frame":finished.physics_frame, "physics_frames":finished.physics_frame-started.physics_frame, "wall_time_includes_existing_awaits":true}


func _field_loading_profile_begin(scene: SceneScript, revision: int, token: int, progressive: bool) -> void:
	_field_loading_profile = {"status":"COLLECTING", "Field_instance":get_instance_id(), "scene_id":String(scene.scene_id), "scene_instance":scene.get_instance_id(), "layout_instance":scene.map_layout.get_instance_id() if scene.map_layout != null else 0, "motion_revision":revision, "transition_token":token, "progressive":progressive, "setup_started":_field_loading_profile_clock(), "phases":{}, "phase_order":[]}
	if not _field_loading_ui_profile.is_empty():
		_field_loading_profile.phases["ready_ui"] = _field_loading_ui_profile.duplicate(true)
		_field_loading_profile.phase_order.append("ready_ui")
		_field_loading_ui_profile.clear()


func _field_loading_profile_record(label: String, started: Dictionary, revision: int, scene: SceneScript, processed: int = -1) -> void:
	if _field_loading_profile.get("status") != "COLLECTING" or scene == null or scene != _current_scene or revision != _city3_motion_revision or _field_loading_profile.get("motion_revision") != revision or _field_loading_profile.get("scene_instance") != scene.get_instance_id() or _field_loading_profile.phases.has(label): return
	var row: Dictionary = _field_loading_profile_span(started, _field_loading_profile_clock())
	if processed >= 0: row["processed_objects"] = processed
	_field_loading_profile.phases[label] = row
	_field_loading_profile.phase_order.append(label)


'''
change(FIELD, 'readonly_getter_and_scalar_helpers_before_existing_setup',
       'func _setup_scene(scene: SceneScript, player_spawn_override: Variant = null, progressive: bool = false) -> void:\n',
       helpers + 'func _setup_scene(scene: SceneScript, player_spawn_override: Variant = null, progressive: bool = false) -> void:\n')
change(FIELD, 'bind_profile_to_current_setup_owner',
       '\tvar motion_revision := _city3_motion_revision\n\t_release_temple_session()\n',
       '\tvar motion_revision := _city3_motion_revision\n\t_field_loading_profile_begin(scene, motion_revision, source_validation_token, progressive)\n\t_release_temple_session()\n')
change(FIELD, 'mask_layout_phase_start',
       '\tvar visual_objects: Array = scene.scene_objects\n',
       '\tvar loading_phase_started: Dictionary = _field_loading_profile_clock()\n\tvar visual_objects: Array = scene.scene_objects\n')
change(FIELD, 'mask_finish_portal_start',
       '\tvar functional_portals: Dictionary=ELEVEN_ROOMS.project_portals(scene,portals) if ELEVEN_ROOMS.enabled() else FUNCTIONAL_INTERIORS.project_portals(scene,portals)\n',
       '\t_field_loading_profile_record("mask_and_layout", loading_phase_started, motion_revision, scene)\n\tloading_phase_started = _field_loading_profile_clock()\n\tvar functional_portals: Dictionary=ELEVEN_ROOMS.project_portals(scene,portals) if ELEVEN_ROOMS.enabled() else FUNCTIONAL_INTERIORS.project_portals(scene,portals)\n')
change(FIELD, 'portal_finish_task_start',
       '\tportals=functional_portals.portals\n\tvar runtime_npcs: Array=scene.npcs.duplicate(true)\n',
       '\tportals=functional_portals.portals\n\t_field_loading_profile_record("portal_projection", loading_phase_started, motion_revision, scene)\n\tloading_phase_started = _field_loading_profile_clock()\n\tvar runtime_npcs: Array=scene.npcs.duplicate(true)\n')
change(FIELD, 'task_finish_district_start',
       '\tif DISTRICT_LIFE.requested(scene.scene_id):\n\t\tvar district: RefCounted=DISTRICT_LIFE.new(); _district_session=district\n',
       '\t_field_loading_profile_record("task_projection", loading_phase_started, motion_revision, scene)\n\tloading_phase_started = _field_loading_profile_clock()\n\tif DISTRICT_LIFE.requested(scene.scene_id):\n\t\tvar district: RefCounted=DISTRICT_LIFE.new(); _district_session=district\n')
change(FIELD, 'district_finish_before_map_bounds',
       '\t\truntime_npcs.append_array(district.npcs())\n\n\t## 生成地图边界碰撞（防止走出屏幕）\n',
       '\t\truntime_npcs.append_array(district.npcs())\n\t_field_loading_profile_record("district_prepare_and_projection", loading_phase_started, motion_revision, scene)\n\n\t## 生成地图边界碰撞（防止走出屏幕）\n')
change(FIELD, 'C_final_await_begin',
       '\tif source_validation_token > 0:\n\t\t_field_loading_stage = "正在后台复核地图来源……"\n',
       '\tif source_validation_token > 0:\n\t\tvar loading_final_started: Dictionary = _field_loading_profile_clock()\n\t\t_field_loading_stage = "正在后台复核地图来源……"\n')
change(FIELD, 'C_final_await_finish',
       '\t\t\tpush_error("[Field] Final transition source identity rejected; no player created")\n\t\t\treturn\n\n\tif temple_session!=null:\n',
       '\t\t\tpush_error("[Field] Final transition source identity rejected; no player created")\n\t\t\treturn\n\t\t_field_loading_profile_record("complete_source_final_await", loading_final_started, motion_revision, scene)\n\n\tif temple_session!=null:\n')
change(FIELD, 'ENV_install_begin',
       '\t\tvar ap_environment: Variant=load("res://scripts/city/luoyang_environment_layer_20261022ap.gd")\n',
       '\t\tvar loading_environment_started: Dictionary = _field_loading_profile_clock()\n\t\tvar ap_environment: Variant=load("res://scripts/city/luoyang_environment_layer_20261022ap.gd")\n')
change(FIELD, 'ENV_install_finish',
       '\t\t\tpush_error("[Field] AP environment refused: "+String(ap_layer.get("error","UNKNOWN")));return\n\t## 生成玩家（最后生成，确保在最上层）\n',
       '\t\t\tpush_error("[Field] AP environment refused: "+String(ap_layer.get("error","UNKNOWN")));return\n\t\t_field_loading_profile_record("environment_install", loading_environment_started, motion_revision, scene)\n\t## 生成玩家（最后生成，确保在最上层）\n')
change(FIELD, 'setup_total_end_status_only',
       '\t_field_loading_stage = "地图与入口已就绪"\n\n\nfunc _build_city3_motion_guard',
       '\t_field_loading_stage = "地图与入口已就绪"\n\t_field_loading_profile_record("setup_total", _field_loading_profile.setup_started, motion_revision, scene)\n\t_field_loading_profile["status"] = "READY" if _field_loading_complete else "INCOMPLETE"\n\n\nfunc _build_city3_motion_guard')
change(FIELD, 'fade_bootstrap_start_only_clock',
       'func _spawn_scene_objects(scene_objects: Array, progressive: bool = false) -> void:\n',
       'func _spawn_scene_objects(scene_objects: Array, progressive: bool = false) -> void:\n\tvar loading_fade_started: Dictionary = _field_loading_profile_clock()\n')
change(FIELD, 'fade_finish_first_batch_start',
       '\tvar batch_started := Time.get_ticks_usec()\n\tvar processed := 0\n\tfor entry in scene_objects:\n',
       '\t_field_loading_profile_record("depth_fade_bootstrap", loading_fade_started, _city3_motion_revision, _current_scene)\n\tvar loading_first_batch_started: Dictionary = _field_loading_profile_clock()\n\tvar loading_first_batch_recorded: bool = false\n\tvar batch_started := Time.get_ticks_usec()\n\tvar processed := 0\n\tfor entry in scene_objects:\n')
change(FIELD, 'first_batch_record_before_original_yield',
       '\t\tif progressive and Time.get_ticks_usec() - batch_started >= 8000:\n\t\t\t_field_loading_progress = .1 + .7 * float(processed) / maxi(1, scene_objects.size())\n',
       '\t\tif progressive and Time.get_ticks_usec() - batch_started >= 8000:\n\t\t\tif not loading_first_batch_recorded:\n\t\t\t\t_field_loading_profile_record("object_first_batch", loading_first_batch_started, _city3_motion_revision, _current_scene, processed)\n\t\t\t\tloading_first_batch_recorded = true\n\t\t\t_field_loading_progress = .1 + .7 * float(processed) / maxi(1, scene_objects.size())\n')
change(FIELD, 'first_batch_short_loop_finish',
       '\t\t\t_spawn_scene_object_interaction(d, object_pos, interaction_action, sprite)\n\n\nfunc _create_v14_late_depth_refresh()',
       '\t\t\t_spawn_scene_object_interaction(d, object_pos, interaction_action, sprite)\n\tif not loading_first_batch_recorded:\n\t\t_field_loading_profile_record("object_first_batch", loading_first_batch_started, _city3_motion_revision, _current_scene, processed)\n\n\nfunc _create_v14_late_depth_refresh()')

outputs = {}
descriptors = []
for target in [G, FIELD]:
    candidate = work[target].encode('utf-8')
    inverse = work[target]
    for row in reversed(operations[target]):
        assert inverse.count(row['new']) == 1, ('UNIQUE_REVERSE', row['label'])
        inverse = inverse.replace(row['new'], row['old'], 1)
    assert inverse.encode('utf-8') == originals[target]
    name = 'G_local_catalogue_READY.gd' if target == G else 'Field_loading_scalar_profile_READY.gd'
    candidate_path = OUT + name
    parent_path = OUT + ('G_parent_2E305.gd' if target == G else 'Field_parent_0C9DB.gd')
    outputs[candidate_path] = candidate
    outputs[parent_path] = originals[target]
    diff = ''.join(difflib.unified_diff(originals[target].decode().splitlines(True), work[target].splitlines(True), fromfile=target, tofile=candidate_path, n=5))
    outputs[OUT + name + '.diff'] = diff.encode()
    descriptors.append({'target': target, 'parent': {'path': parent_path, 'sha256': sha(originals[target])}, 'candidate': {'path': candidate_path, 'sha256': sha(candidate), 'bytes': len(candidate)}, 'operations': operations[target], 'complete_byte_inverse': True, 'LF_EOL_unchanged': True})

# Static semantic checks do not execute or parse GDScript.
original_g_scope = originals[G].decode().split('static func project_portals(', 1)[1].split('static func _door_polygon(', 1)[0]
new_g_scope = work[G].split('static func project_portals(', 1)[1].split('static func _door_polygon(', 1)[0]
assert original_g_scope.count('catalogue()') == 3 and new_g_scope.count('catalogue()') == 1
assert new_g_scope.count('author_for_id(StringName(id))') == original_g_scope.count('author_for_id(StringName(id))') == 1
for token in ['await ', 'WorkerThreadPool.', 'FileAccess.', 'ResourceLoader.', 'load(', 'preload(']:
    assert work[FIELD].count(token) == originals[FIELD].decode().count(token), ('FORBIDDEN_NEW_SEMANTIC_CALL', token)
assert work[FIELD].count('>= 8000') == originals[FIELD].decode().count('>= 8000') == 1
assert work[FIELD].count('SceneRouter.finalize_field_transition_sources(source_validation_scene_id, source_validation_token)') == 1
phase_names = ['mask_and_layout', 'portal_projection', 'task_projection', 'district_prepare_and_projection', 'depth_fade_bootstrap', 'object_first_batch', 'complete_source_final_await', 'environment_install', 'ready_ui', 'setup_total']
consumers = []
for row in owner['scenes'] + owner['rooms']:
    consumers.append({'id': row['id'], 'owner': row['owner'], 'has_G': G in row['source_sha256'], 'has_Field': FIELD in row['source_sha256'], 'collector_count': len(row['source_sha256']), 'receipt_count': len(row['receipt_source_sha256'])})

handoff = {
    'status': 'BUILD_ONLY_TWO_PERFORMANCE_CANDIDATES_NOT_PARSED_NOT_DEPLOYED',
    'baseline_owner': {'path': OWNER, 'sha256': OWNER_SHA},
    'current_ED4C_DB9D_and_885A_inherited_not_reverted': True,
    'candidates': descriptors,
    'G_semantics': {'only_project_portals_changes': True, 'one_local_snapshot_replaces_loop_scene_path_am_parent_row_catalogue_calls': True, 'author_for_id_and_all_source_door_body_checks_unchanged': True, 'no_cross_call_cache_added': True, 'at_least_twelve_repeated_cached_registry_clones_avoided_per_twelve_room_projection': True},
    'Field_semantics': {'phase_names': phase_names, 'all_times_are_wall_usec_including_original_awaits_not_main_CPU': True, 'frames_and_processed_counts_separate': True, 'setup_total_overlaps_child_phases_not_summable': True, 'ready_UI_precedes_setup_total_and_bound_to_first_actual_setup_only': True, 'same_Field_scene_layout_revision_and_transition_token_identity': True, 'no_new_yield_worker_task_hash_source_geometry_load_or_gameplay_call': True, 'original8ms_budget_unchanged': True, 'C_FINAL_ENV_original_checks_not_removed': True, 'no_lazy_UI_or_motion_overlap': True, 'failed_or_cancelled_incomplete_phases_absent_not_zero': True, 'getter_is_read_only_deep_copy': True},
    'owner_membership_from_fixed690F_not_actual_collector': consumers,
    'source_closure_plan': {
        'not_a_locked_target_scope': True,
        'direct_candidates': [G, FIELD],
        'required_owned_dependency_successors': ['runtime_contract one existing Field source value', 'Coordinator sole contract SHA literal', 'Temple binding exact existing source values for changed G/Field/Coordinator where present, preserving historical rows', 'Temple sole binding path/SHA literals', 'Execution append exact inverse edges only for changed existing OWNED rows, preserve OWNED11 and all old edges/pins', 'Execution index one approval SHA literal'],
        'required_source_only_consumers': ['Five-room registry only changed existing source code values', 'Estate manifest/index only actual consumed changed code or registry headers', 'Current finite Market/Yamen manifests (Yamen parent ED4C, four authority-class parent leaves retained)', 'Quarter shared manifest/index', 'AP Market manifest and consumed ordinary source metadata/index successors', 'APINDEX current DB9D exact header successor', 'Independent eight-scene/five-room collector and receipt maps inherited from690F with explicit source-only deltas'],
        'not_required_for_this_pair': ['ENV helper/author/index/shaders', 'B/C/DT/Fade/Router logic', 'native scene/layout/packet/mask/geometry/door/NPC data', 'finite adapter/binding CPU89216 proof'],
        'A2_merge': 'Wait fixed A2 native and Root ART/source authority; combine DAG source successors once if approved, do not merge A1 or invent A2 hashes now.',
        'no_full29_replay': 'Compute exact changed metadata/index closure and remove no-ops; byte-prove old parents against885A plus formalED4C/DB9D. Count and final hashes pending dependency authorization.'
    },
    'proof_boundary': 'Static byte inverse and token/call-count review only; GDScript parse/runtime/timing benefit pending Root unique approved checks.',
    'engine_collector_stage_or_canonical_writes': 0,
}
outputs[OUT + 'handoff_CANDIDATES_NOT_DEPLOYED.json'] = encoded(handoff)
assert not path(OUT).exists()
for name, raw in outputs.items():
    path(name).parent.mkdir(parents=True, exist_ok=True)
    with path(name).open('xb') as handle:
        handle.write(raw)
print(json.dumps({'handoff': {'path': OUT+'handoff_CANDIDATES_NOT_DEPLOYED.json', 'sha256': sha(encoded(handoff))}, 'candidates': [{'target': r['target'], **r['candidate']} for r in descriptors], 'canonical_writes': 0}))
