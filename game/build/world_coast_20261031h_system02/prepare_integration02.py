"""NEW candidate02 patch author. Keeps every prepared01 output unchanged."""
from __future__ import annotations
import hashlib,importlib.util,json
from pathlib import Path

OWN=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('coast_integration01_functions',OWN/'prepare_integration.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
module.OUT=OWN/'prepared02'
module.DISPATCH='res://build/world_coast_20261031h_system02/world_contract_dispatch02.gd'
original_router=module.router

def router02():
    original_router()
    path='game/scripts/autoload/scene_router.gd'
    old,candidate=module.changes[path]
    e=module.Edit(path)
    assert e.original==old
    e.text=candidate.decode('utf-8')
    e.replace('func go_field(scene_id: StringName) -> void:',
              'func go_field(scene_id: StringName) -> void:\n\tif String(scene_id).begins_with("world_map_jianghu"):\n\t\tgo_field_smart(scene_id);return')
    signature='func _go_field_smart_prepared(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1, local_spawn_version: int = -1) -> bool:'
    e.replace(signature,signature+'\n\tif String(scene_id).begins_with("world_map_jianghu") and (not is_world_map_scene(scene_id) or world_version_for_scene(scene_id) not in [12,13,14,15,16]):\n\t\tpush_warning("[SceneRouter] 未支持的大地图坐标身份，导航未修改。");return false')
    e.replace('var target_map := _active_world_map_scene',
              'var target_map := _active_world_map_scene\n\tif not is_world_map_scene(target_map) or world_version_for_scene(target_map) not in [12,13,14,15,16]:\n\t\tpush_warning("[SceneRouter] 未支持的大地图坐标身份，导航未修改。");return')
    e.replace('func navigation_coordinate_version_supported(data: Dictionary, target_id: StringName) -> bool:',
              'func navigation_coordinate_version_supported(data: Dictionary, target_id: StringName) -> bool:\n\tif not is_world_map_scene(target_id) or world_version_for_scene(target_id) not in [12,13,14,15,16]:return false')
    e.replace('scene_id = _normalize_field_id(scene_id)\n\tif is_world_map_scene(scene_id):\n\t\tgo_field_smart(scene_id, player_spawn)',
              'scene_id = _normalize_field_id(scene_id)\n\tif String(scene_id).begins_with("world_map_jianghu"):\n\t\tgo_field_smart(scene_id, player_spawn)')
    target='var target: StringName = _active_world_map_scene if scene_id == WORLD_MAP_SCENE and _active_world_map_scene != WORLD_MAP_SCENE else scene_id'
    e.replace(target,target+'\n\tif String(target).begins_with("world_map_jianghu") and (not is_world_map_scene(target) or world_version_for_scene(target) not in [12,13,14,15,16]):return')
    e.finish()

module.router=router02
if __name__=='__main__':
    keep=OWN/'prepared'
    preserved={p.relative_to(keep).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in keep.rglob('*') if p.is_file()}
    module.prepare()
    after={p.relative_to(keep).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in keep.rglob('*') if p.is_file()}
    assert after==preserved,'PREPARED01_BYTES_CHANGED'
    print(json.dumps({'status':'PREPARED02_ONLY_NOT_ADOPTED','prepared01_files_preserved':len(preserved),'manifest02_root_pin':'EMPTY_DENY_UNTIL_ROOT_REVIEWS_ACTUAL_ARTIFACT'}))
