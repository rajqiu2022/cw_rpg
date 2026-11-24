"""Prepare review-only candidate copies and a deterministic patch; never apply it.

Run from any directory: python prepare_integration.py --prepare
Only this system02/prepared directory is writable. Geometry need not exist yet.
No engine, source-closure approval, canonical Scene, or player saves are touched.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
import json
from pathlib import Path

OWN = Path(__file__).resolve().parent
REPO = OWN.parents[2]
OUT = OWN / "prepared"
DISPATCH = 'res://build/world_coast_20261031h_system02/world_contract_dispatch.gd'
changes: dict[str, tuple[bytes, bytes]] = {}


def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


class Edit:
    def __init__(self, path: str):
        self.path = path
        self.original = (REPO / path).read_bytes()
        self.text = self.original.decode("utf-8")

    def replace(self, old: str, new: str, count: int = 1):
        # Preserve the original surrounding and replacement-line EOLs. No whole
        # source normalization: historical mixed CRLF/LF is not our authority.
        options = [old] if "\n" not in old else [old, old.replace("\n", "\r\n")]
        matches = [(needle, self.text.count(needle)) for needle in options]
        total = sum(number for _, number in matches)
        if total != count:
            raise RuntimeError(f"{self.path}: expected {count}, got {total}: {old[:100]!r}")
        for needle, number in matches:
            if not number:
                continue
            pos = self.text.index(needle)
            end = self.text.find("\n", pos + len(needle))
            eol = "\r\n" if "\r\n" in needle or (end > 0 and self.text[end-1:end] == "\r") else "\n"
            self.text = self.text.replace(needle, new.replace("\n", eol))
        return self

    def finish(self):
        result = self.text.encode("utf-8")
        if result == self.original:
            raise RuntimeError("No change: " + self.path)
        changes[self.path] = (self.original, result)


def router():
    e = Edit('game/scripts/autoload/scene_router.gd')
    e.replace('const WORLD_V15 = preload("res://scripts/world/world_map_v15_contract.gd")',
              'const WORLD_V15 = preload("res://scripts/world/world_map_v15_contract.gd")\nconst WORLD_NATIVE = preload("'+DISPATCH+'")\nconst WORLD_MAP_V16_SCENE := &"world_map_jianghu_v16"')
    e.replace('world_version not in [-1,12,13,14,15]', 'world_version not in [-1,12,13,14,15,16]')
    e.replace('world_version_for_scene(scene_id) == 15', 'world_version_for_scene(scene_id) in [15,16]', 2)
    e.replace('not WORLD_V15.is_v15(_load_field_scene_def(scene_id))', 'not WORLD_NATIVE.is_native(_load_field_scene_def(scene_id))')
    e.replace('world_version_for_scene(source) == 15', 'world_version_for_scene(source) in [15,16]')
    e.replace('world_version_for_scene(target) == 15', 'world_version_for_scene(target) in [15,16]')
    e.replace('target_map in [WORLD_MAP_STAGING_SCENE, WORLD_MAP_V14_SCENE, WORLD_MAP_V15_SCENE] or WORLD_V15.formal_version() in [14, 15]',
              'target_map in [WORLD_MAP_STAGING_SCENE, WORLD_MAP_V14_SCENE, WORLD_MAP_V15_SCENE, WORLD_MAP_V16_SCENE] or WORLD_NATIVE.formal_version() in [14,15,16]')
    e.replace('world_scene_id in [WORLD_MAP_SCENE,WORLD_MAP_V15_SCENE] and world_version_for_scene(world_scene_id)==15',
              'world_scene_id in WORLD_NATIVE.WORLD_IDS and world_version_for_scene(world_scene_id) in [15,16]')
    e.replace('_world_map_version = WORLD_V15.formal_version()', '_world_map_version = WORLD_NATIVE.formal_version()')
    e.replace('if world_map_upgrade_target == WORLD_MAP_V15_SCENE or (world_map_upgrade_target == &"" and WORLD_V15.formal_version() == 15):\n\t\t_restore_v15_navigation(data, fallback_field, WORLD_MAP_V15_SCENE if world_map_upgrade_target == WORLD_MAP_V15_SCENE else WORLD_MAP_SCENE)',
              'if world_map_upgrade_target in [WORLD_MAP_V15_SCENE,WORLD_MAP_V16_SCENE] or (world_map_upgrade_target == &"" and WORLD_NATIVE.formal_version() in [15,16]):\n\t\t_restore_v15_navigation(data, fallback_field, world_map_upgrade_target if world_map_upgrade_target in [WORLD_MAP_V15_SCENE,WORLD_MAP_V16_SCENE] else WORLD_MAP_SCENE)')
    e.replace('return scene_id in [WORLD_MAP_SCENE, WORLD_MAP_STAGING_SCENE, WORLD_MAP_V14_SCENE, WORLD_MAP_V15_SCENE]',
              'return scene_id in [WORLD_MAP_SCENE, WORLD_MAP_STAGING_SCENE, WORLD_MAP_V14_SCENE, WORLD_MAP_V15_SCENE, WORLD_MAP_V16_SCENE]')
    e.replace('func world_version_for_scene(scene_id: StringName) -> int:',
              'func world_version_for_scene(scene_id: StringName) -> int:\n\tif scene_id == WORLD_MAP_V16_SCENE: return 16')
    e.replace('return WORLD_V15.formal_version()', 'return WORLD_NATIVE.formal_version()')
    e.replace('if WORLD_V15.is_v15(scene): return WORLD_V15',
              'var native_contract: Variant=WORLD_NATIVE.contract_for(scene)\n\tif native_contract!=null:return native_contract')
    e.replace('if source_version == 15 and world_version_for_scene(target_id) < 15:',
              'if source_version in [15,16] and world_version_for_scene(target_id) < source_version:')
    e.replace('var inferred: int = 15 if saved_id == WORLD_MAP_V15_SCENE else',
              'var inferred: int = 16 if saved_id == WORLD_MAP_V16_SCENE else (15 if saved_id == WORLD_MAP_V15_SCENE else')
    e.replace('(13 if saved_id == WORLD_MAP_STAGING_SCENE else 12))', '(13 if saved_id == WORLD_MAP_STAGING_SCENE else 12)))')
    e.replace('float(raw) not in [12.0, 13.0, 14.0, 15.0]', 'float(raw) not in [12.0, 13.0, 14.0, 15.0, 16.0]')
    e.replace('if not WORLD_V15.is_v15(target):', 'var native_contract: Variant=WORLD_NATIVE.contract_for(target)\n\tif native_contract==null:')
    e.replace('WORLD_V15.source_scene(old_version)', 'native_contract.source_scene(old_version)')
    e.replace('WORLD_V15.migrate_spawn(spawn if spawn is Vector2 else target.player_spawn, old_version if spawn is Vector2 else 15, target)',
              'native_contract.migrate_spawn(spawn if spawn is Vector2 else target.player_spawn, old_version if spawn is Vector2 else int(native_contract.VERSION), target)')
    e.replace('WORLD_V15.migrate_spawn(point, old_version, target)', 'native_contract.migrate_spawn(point, old_version, target)')
    e.replace('if parts.size() != 2 or not point is Vector2: continue\n\t\t\tif is_world_map_scene(StringName(parts[1])):\n\t\t\t\tpoint = native_contract.migrate_spawn(point, old_version, target)',
              'if parts.size()!=2:return {}\n\t\t\tfor part: String in parts:\n\t\t\t\tif part.begins_with("world_map_jianghu") and not is_world_map_scene(StringName(part)):return {}\n\t\t\tif not point is Vector2:\n\t\t\t\tif is_world_map_scene(StringName(parts[0])) or is_world_map_scene(StringName(parts[1])):return {}\n\t\t\t\tcontinue\n\t\t\tif is_world_map_scene(StringName(parts[1])):\n\t\t\t\tpoint = native_contract.migrate_spawn(point, old_version, target)')
    e.replace('"world_map_version": 15, "local_layout_versions":', '"world_map_version": int(native_contract.VERSION), "local_layout_versions":')
    e.replace('if prepared.get("world_map_version") != 15 or not prepared.get("active_world_map_scene") in [WORLD_MAP_SCENE, WORLD_MAP_V15_SCENE]:',
              'if prepared.get("world_map_version") not in [15,16] or not prepared.get("active_world_map_scene") in WORLD_NATIVE.WORLD_IDS or prepared.get("world_map_version")!=world_version_for_scene(StringName(prepared.get("active_world_map_scene",""))):')
    e.replace('_world_map_version = 15\n\t_local_layout_versions = prepared.get',
              '_world_map_version = int(prepared.world_map_version)\n\t_local_layout_versions = prepared.get')
    e.replace('func field_scene_resource_path(scene_id: StringName) -> String:',
              'func field_scene_resource_path(scene_id: StringName) -> String:\n\tif scene_id==WORLD_MAP_V16_SCENE:return WORLD_NATIVE.CANDIDATE_PATH')
    e.replace('var scene_path := FIELD_SCENE_DIR + String(scene_id) + ".tres"',
              'var scene_path := field_scene_resource_path(scene_id)')
    e.replace('[SceneRouter] 完整v15地图尚未发布，导航未修改。',
              '[SceneRouter] 新版原生地图尚未发布，导航未修改。')
    e.replace('var saved_id: StringName = _normalize_field_id(StringName(data.get("current_field", fallback)))',
              'var saved_id: StringName = _normalize_field_id(StringName(data.get("current_field", fallback)))\n\tif String(saved_id).begins_with("world_map_jianghu") and not is_world_map_scene(saved_id):return -1')
    e.finish()


def save():
    e=Edit('game/scripts/autoload/save_manager.gd')
    e.replace('var v15_target: StringName = SceneRouter.WORLD_MAP_V15_SCENE if world_map_upgrade_target == SceneRouter.WORLD_MAP_V15_SCENE else SceneRouter.WORLD_MAP_SCENE',
              'var v15_target: StringName = world_map_upgrade_target if world_map_upgrade_target in [SceneRouter.WORLD_MAP_V15_SCENE,SceneRouter.WORLD_MAP_V16_SCENE] else SceneRouter.WORLD_MAP_SCENE')
    e.replace('if world_map_upgrade_target == SceneRouter.WORLD_MAP_V15_SCENE or (world_map_upgrade_target == &"" and SceneRouter.WORLD_V15.formal_version() == 15):',
              'if world_map_upgrade_target in [SceneRouter.WORLD_MAP_V15_SCENE,SceneRouter.WORLD_MAP_V16_SCENE] or (world_map_upgrade_target == &"" and SceneRouter.WORLD_NATIVE.formal_version() in [15,16]):')
    e.replace('if world_map_upgrade_target == SceneRouter.WORLD_MAP_V15_SCENE and SceneRouter.is_world_map_scene(saved_field):',
              'if world_map_upgrade_target in [SceneRouter.WORLD_MAP_V15_SCENE,SceneRouter.WORLD_MAP_V16_SCENE] and SceneRouter.is_world_map_scene(saved_field):')
    e.replace('return SceneRouter.WORLD_MAP_V15_SCENE', 'return world_map_upgrade_target')
    e.replace('SceneRouter.WORLD_V15.formal_version() == 15', 'SceneRouter.WORLD_NATIVE.formal_version() in [15,16]')
    e.replace('var migrated: String = String(FIELD_ID_MIGRATIONS.get(String(scene_id), String(scene_id)))',
              'var migrated: String = String(FIELD_ID_MIGRATIONS.get(String(scene_id), String(scene_id)))\n\t# This declared private World must never fall back to a chapter entry.\n\tif migrated==String(SceneRouter.WORLD_MAP_V16_SCENE):\n\t\tvar private_path: String=SceneRouter.field_scene_resource_path(SceneRouter.WORLD_MAP_V16_SCENE)\n\t\treturn SceneRouter.WORLD_MAP_V16_SCENE if ResourceLoader.exists(private_path) else &""')
    e.finish()


def field_and_stream():
    e=Edit('game/scripts/field/field_walkable_controller.gd')
    e.replace('const WORLD_V15_STREAM = preload("res://scripts/world/world_v15_visible_stream_20261018r.gd")',
              'const WORLD_V15_STREAM = preload("res://scripts/world/world_v15_visible_stream_20261018r.gd")\nconst WORLD_NATIVE = preload("'+DISPATCH+'")')
    e.replace('SceneRouter.WORLD_V15.is_v15(', 'WORLD_NATIVE.is_native(', 10)
    e.replace('SceneRouter.world_version_for_scene(scene_id) == 15', 'SceneRouter.world_version_for_scene(scene_id) in [15,16]', 2)
    e.finish()
    e=Edit('game/scripts/world/world_v15_visible_stream_20261018r.gd')
    e.replace('const WORLD_CONTRACT = preload("res://scripts/world/world_map_v15_contract.gd")',
              'const WORLD_CONTRACT = preload("res://scripts/world/world_map_v15_contract.gd")\nconst WORLD_NATIVE = preload("'+DISPATCH+'")')
    e.replace('not OS.has_feature("web") and WORLD_CONTRACT.is_v15(scene)', 'not OS.has_feature("web") and WORLD_NATIVE.is_native(scene)')
    e.finish()


def maps_and_towns():
    e=Edit('game/scripts/ui/world_map_panel.gd')
    e.replace('load("res://data/scenes/%s.tres" % world_id)', 'load(SceneRouter.field_scene_resource_path(world_id))')
    e.finish()
    e=Edit('game/scripts/ui/world_travel_minimap.gd')
    e.replace('const WORLD_IDS := [&"world_map_jianghu", &"world_map_jianghu_v15"]',
              'const WORLD_IDS := [&"world_map_jianghu", &"world_map_jianghu_v15", &"world_map_jianghu_v16"]\nconst WORLD_NATIVE = preload("'+DISPATCH+'")')
    e.replace('if scene.map_layout.schema_version != 15 or scene.background_path != OVERVIEW_PATH:',
              'if not WORLD_NATIVE.is_native(scene):')
    e.replace('_effective_overview_path = WORLD_VISUAL_PATCH.overview_path(scene)',
              '_effective_overview_path = scene.background_path if WORLD_NATIVE.V16.is_v16(scene) else WORLD_VISUAL_PATCH.overview_path(scene)')
    e.replace('if _effective_overview == null:\n\t\t_effective_overview = OVERVIEW',
              'if _effective_overview == null and WORLD_NATIVE.V16.is_v16(scene):\n\t\trelease();return false\n\tif _effective_overview == null:\n\t\t_effective_overview = OVERVIEW')
    e.finish()
    e=Edit('game/build/three_towns_world_20261029j_system01/town_registry.gd')
    e.replace('const WORLDS := [&"world_map_jianghu",&"world_map_jianghu_v15"]',
              'const WORLDS := [&"world_map_jianghu",&"world_map_jianghu_v15",&"world_map_jianghu_v16"]')
    e.replace('row.target_pos,"",15,VERSION)', 'row.target_pos,"",SceneRouter.world_version_for_scene(source_id),VERSION)')
    e.replace('world_id,foot,"",15,-1)', 'world_id,foot,"",SceneRouter.world_version_for_scene(world_id),-1)')
    e.replace('WORLDS.has(id) and SceneRouter.world_version_for_scene(id)==15',
              'WORLDS.has(id) and SceneRouter.layered_world_contract(field.get("_current_scene") as SceneScript)!=null and SceneRouter.world_version_for_scene(id) in [15,16]')
    e.finish()
    e=Edit('game/build/sect_repair_20261031c_system01/router_entry.gd')
    e.replace('source in [&"world_map_jianghu",&"world_map_jianghu_v15"]',
              'source in [&"world_map_jianghu",&"world_map_jianghu_v15",&"world_map_jianghu_v16"]')
    e.finish()
    e=Edit('game/build/sect_repair_20261031c_system01/adoption_contract.gd')
    e.replace('source in [&"world_map_jianghu",&"world_map_jianghu_v15"]',
              'source in [&"world_map_jianghu",&"world_map_jianghu_v15",&"world_map_jianghu_v16"]')
    e.finish()


def adventure():
    e=Edit('game/build/adventure_world_20261031f_system01/world_links.gd')
    e.replace('const WORLDS := [&"world_map_jianghu",&"world_map_jianghu_v15"]',
              'const WORLDS := [&"world_map_jianghu",&"world_map_jianghu_v15",&"world_map_jianghu_v16"]\nconst WORLD_NATIVE = preload("'+DISPATCH+'")')
    e.replace('SceneRouter.world_version_for_scene(scene.scene_id)==15', 'WORLD_NATIVE.is_native(scene)')
    e.replace('Vector2(.5,.9),"",15,-1)', 'Vector2(.5,.9),"",SceneRouter.world_version_for_scene(world_id),-1)')
    e.replace('"source_foot":[foot.x,foot.y]}', '"source_foot":[foot.x,foot.y],"world_version":SceneRouter.world_version_for_scene(world_id)}')
    e.replace('value.size()!=3', 'value.size() not in [3,4]')
    e.replace('if row.is_empty() or not WORLDS.has(world_id) or SceneRouter.world_version_for_scene(world_id)!=15:return {}',
              'if row.is_empty() or not WORLDS.has(world_id):return {}\n\tvar source_version: Variant=value.get("world_version",15)\n\tif typeof(source_version) not in [TYPE_INT,TYPE_FLOAT] or source_version not in [15,16]:return {}\n\tif value.size()==4 and not value.has("world_version"):return {}\n\tif world_id==&"world_map_jianghu_v16" and source_version!=16:return {}\n\tif world_id==&"world_map_jianghu_v15" and source_version!=15:return {}\n\tif int(source_version)>SceneRouter.world_version_for_scene(world_id):return {}')
    e.replace('var scene: SceneScript=load("res://data/scenes/"+String(world_id)+".tres") as SceneScript',
              'var source_scene: SceneScript=WORLD_NATIVE.V16.source_scene(int(source_version))\n\tvar source_contract: Variant=WORLD_NATIVE.contract_for(source_scene)\n\tif source_contract==null or not source_contract.safe_foot(source_scene,foot/WORLD_SIZE):return {}\n\tvar active: StringName=SceneRouter.get_active_world_map_scene()\n\tif WORLDS.has(active) and SceneRouter.world_version_for_scene(active)==16:world_id=active\n\tvar scene: SceneScript=WORLD_NATIVE.scene_for(world_id)')
    e.replace('origin.foot/WORLD_SIZE,"",15,-1)', 'origin.foot/WORLD_SIZE,"",SceneRouter.world_version_for_scene(origin.world_id),-1)')
    e.finish()


def ferry_text():
    original='这条接驳线沿内河行船，转水路到对岸。替船上照看一程货，便不收你船钱；江面水急，不要自行涉水。'
    rows={
        'game/data/dialogs/openworld_bailu_ferry_boat.tres':'东海埠在离岸的岛上，陆路到不了。替船上照看一程货，便不收你船钱；海上风浪急，不要自行涉水。',
        'game/data/dialogs/openworld_east_sea_port_boat.tres':'返航的船驶回大陆白鹿渡。替船上照看一程货，便不收你船钱；海上风浪急，不要自行涉水。',
    }
    for path,text in rows.items():
        e=Edit(path)
        e.replace(original,text)
        e.finish()


def prepare():
    router();save();field_and_stream();maps_and_towns();adventure();ferry_text()
    OUT.mkdir(exist_ok=True)
    patch=['*** Begin Patch\n']
    records=[]
    for path, (before,after) in sorted(changes.items()):
        target=OUT/'copies'/path
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(after)
        delta=list(difflib.unified_diff(before.decode('utf-8').splitlines(),after.decode('utf-8').splitlines(),n=3,lineterm=''))
        patch.append('*** Update File: '+path+'\n')
        for line in delta[2:]:
            patch.append(('@@' if line.startswith('@@') else line)+'\n')
        records.append({'path':path,'before_sha256':digest(before),'candidate_sha256':digest(after),'before_bytes':len(before),'candidate_bytes':len(after)})
    patch.append('*** End Patch\n')
    value=''.join(patch).encode('utf-8')
    (OUT/'integration_REVIEW_ONLY.patch').write_bytes(value)
    report={'status':'CANDIDATE_ONLY_NOT_APPLIED_NOT_ENGINE_PARSED','coordinate_version':16,'canonical_scene_changed':False,'geometry_ready_required':True,'production_approval':False,'source_closures_updated':False,'patch_sha256':digest(value),'targets':records,'required_followup':['Root fresh actual source-closure collector and exact approved successors','Root isolated engine parse and transition/restore/foot tests','Do not apply stale candidate if any before hash changes']}
    (OUT/'receipt_REVIEW_ONLY.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'targets':len(records),'patch':str(OUT/'integration_REVIEW_ONLY.patch'),'status':report['status']}))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare',action='store_true',required=True)
    parser.parse_args()
    prepare()
