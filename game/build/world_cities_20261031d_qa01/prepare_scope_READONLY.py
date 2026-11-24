"""Finite path/pin proposal, stdout only. Never opens save content or runs an engine."""
from pathlib import Path
import hashlib,json
ROOT=Path('F:/Code/RPG_GAME')
PREV=ROOT/'game/build/world_sects_cities_20261031c_qa01'
manifest=json.loads((PREV/'expected_FINAL_ROOT_REVIEW.json').read_text(encoding='utf-8-sig'))
def canon(path):
    if path.startswith('res://'):return ROOT/'game'/path[6:]
    p=Path(path)
    return p if p.is_absolute() else ROOT/p
def pin(path):
    p=canon(path);data=p.read_bytes()
    return {'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)}
critical=set(manifest['allowed_old_targets'])|set(manifest['historical_authorized_targets'])|set(manifest['new_runtime_pins'])
critical.add(manifest['unseeded_authorized_old']['path'])
critical.update([
 'game/build/three_towns_world_20261029j_system01/world_spec.json',
 'game/build/three_towns_world_20261029j_system01/town_field.gd',
 'game/build/luoyang_regions_20261027d_source01/region_entry.gd',
 'game/build/city_visual_diversity_20261031c/district_patches.json',
 'game/build/city_visual_diversity_20261031c/district_visuals.gd',
 'game/build/city_visual_diversity_20261031c/district_ground_edge.gdshader',
 'game/scripts/field/player.gd','game/scripts/field/field_walkable_controller.gd',
 'game/project.godot'])
missing=[p for p in critical if not canon(p).is_file()]
# The old exact entry may have a dated name. Never guess a nonexistent source.
critical={p for p in critical if canon(p).is_file()}
out={
 'schema_version':1,'status':'ROOT_REVIEW_PATHS_AND_CURRENT_PINS_NOT_A_FRESH_BASELINE',
 'seed_report':'game/build/world_sects_cities_20261031c_qa01/final_guard_ACTUAL.json',
 'seed_sha256':'a163eb02fccd5db1f6cdae29b99bc574a869b8b01b446e226d53fce9104e1341',
 'seed_use':'Path/evidence only; all SHA/bytes/UTCticks sampled anew by Root capture.',
 'previous_scope_manifest':'game/build/world_sects_cities_20261031c_qa01/expected_FINAL_ROOT_REVIEW.json',
 'previous_scope_manifest_sha256':'7740e24fa4d73f6c64c6c90de937b34bdb663ac999011a0165e3b4a3cdb30628',
 'native_manifest':'game/build/three_towns_world_20261029j_system01/native_sources.json',
 'native_count':221,
 'region_manifest':'game/build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json',
 'region_runtime_count':565,
 'critical_current_pins':{p:pin(p) for p in sorted(critical)},
 'previous20_formal_targets_plus_tasks_count':21,
 'previous_ten_unseeded_now_explicit':[manifest['unseeded_authorized_old']['path']]+sorted(manifest['historical_authorized_targets']),
 'optional_guessed_missing_not_declared':missing,
 'only_editor_pid':51856,'save_count':171,'absent_save_count':9,
 'source_writes':0,'save_content_reads':0,'engine_runs':0}
print(json.dumps(out,ensure_ascii=False,indent=2))
