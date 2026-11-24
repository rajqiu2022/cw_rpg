"""Finite current source proposal; stdout only, no real save content opened."""
from pathlib import Path
import hashlib,json
ROOT=Path('F:/Code/RPG_GAME')
def facts(relative):
    p=ROOT/relative;data=p.read_bytes()
    return {'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)}
paths=[
'game/scripts/city/luoyang_execution_authority_20261022ap.gd',
'game/scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
'game/build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd',
'game/scripts/city/luoyang_execution_index_20261022ap.gd',
'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json',
'game/scripts/autoload/scene_router.gd','game/scripts/field/field_walkable_controller.gd',
'game/build/luoyang_regions_20261027d_source01/region_entry.gd',
'game/build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json',
'game/build/three_towns_world_20261029j_system01/native_sources.json',
'game/build/three_towns_world_20261029j_system01/town_registry.gd',
'game/data/scenes/world_map_jianghu.tres','game/data/scenes/ch4_s0_luoyang_gate.tres',
'game/project.godot']
print(json.dumps({'status':'ROOT_REVIEW_EXPLICIT_SCOPE_NOT_BASELINE','seed':'game/build/world_cities_20261031d_qa01/final_guard_ACTUAL.json','seed_sha256':'1009351d30bf8a45d183067bf729400ec335e3dc688e0953d0e648b68e8baaff','expected_seed_sources':2317,'save_count':171,'absent_count':9,'current_source_pins':{p:facts(p) for p in paths},'allowed_observed_processes':[51856,137072],'user_log':'C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传/logs/godot.log','engine_runs':0,'save_deserializations':0},ensure_ascii=False,indent=2))
