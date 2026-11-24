"""Finite source-path closure only; no save contents or fresh save hashing here."""
from pathlib import Path
import hashlib,json,re
ROOT=Path('F:/Code/RPG_GAME')
PREVIOUS=ROOT/'game/build/world_bridges_20261030m_qa01/final_guard03_ACTUAL.json'
NATIVE=ROOT/'game/build/three_towns_world_20261029j_system01/native_sources.json'
REGISTRY=ROOT/'game/build/three_towns_world_20261029j_system01/town_registry.gd'
DRAFTS=['game/scenes/drafts/sect_maps_20261029k/wudang.tscn','game/scenes/drafts/huashan_map_20261029m/huashan.tscn']
IDS=['openworld_wudang_gate','openworld_wudang_taiji_court','openworld_wudang_purple_cloud_court','openworld_huashan_forecourt','openworld_huashan_sword_terrace','openworld_huashan_waterfall_terrace']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
relative=lambda p:p.relative_to(ROOT).as_posix()
native=json.loads(NATIVE.read_text(encoding='utf-8-sig'))
assert len(native['sources'])==166
registry=REGISTRY.read_text(encoding='utf-8-sig')
old_ids=re.findall(r'&"([^"]+)"',re.search(r'const IDS\s*:=\s*\[([^\]]+)\]',registry).group(1))
assert len(old_ids)==14
queue=[ROOT/p for p in DRAFTS]+[ROOT/'game/data/scenes'/f'{id}.tres' for id in IDS]
for folder in ['dialogs','quests']:
    for word in ['wudang','huashan']:
        queue.extend(sorted((ROOT/'game/data'/folder).glob('*'+word+'*.tres')))
seen=set();paths=set();missing=[]
while queue:
    path=queue.pop(0)
    if path in seen:continue
    seen.add(path);paths.add(path)
    if not path.is_file():missing.append(relative(path));continue
    if path.suffix not in ['.tres','.tscn']:continue
    assert len(seen)<100,'Finite sect resource closure unexpectedly wide'
    text=path.read_text(encoding='utf-8-sig')
    for value in re.findall(r'"(res://[^"\r\n]+)"',text):
        child=ROOT/'game'/value.removeprefix('res://');paths.add(child)
        if child.suffix in ['.tres','.tscn'] and child not in seen:queue.append(child)
        if not child.is_file():missing.append(relative(child))
for path in list(paths):
    config=Path(str(path)+'.import')
    if not config.is_file():continue
    paths.add(config)
    remap=next((line.split(chr(34))[1] for line in config.read_text(encoding='utf-8-sig').splitlines() if line.startswith('path=')),None)
    if remap:
        compiled=ROOT/'game'/remap.removeprefix('res://');paths.add(compiled)
        md5=compiled.with_suffix('.md5')
        if md5.is_file():paths.add(md5)
for name in ['scene_router','game_state','inventory','dialog_player','quest_manager','platform_bridge','save_manager','event_bus']:
    path=ROOT/'game/scripts/autoload'/f'{name}.gd'
    if path.is_file():paths.add(path)
for relative_path in ['game/scripts/domain/scene_script.gd','game/scripts/domain/walkable_map_layout.gd','game/scripts/field/field_walkable_controller.gd','game/scripts/field/exit_zone.gd','game/scripts/field/npc.gd','game/build/sect_completion_20261030a_system01/sect_field.gd','game/build/sect_completion_20261030a_system01/sect_field.tscn']:
    path=ROOT/relative_path
    if path.is_file():paths.add(path)
assert not missing,missing
pins={relative(path):sha(path) for path in [PREVIOUS,NATIVE,REGISTRY]+[ROOT/path for path in DRAFTS]}
print(json.dumps({'status':'PATH_SEEDS_ONLY_ROOT_FRESH_CAPTURE_REQUIRED','repo_root':ROOT.as_posix(),'previous_report':relative(PREVIOUS),'previous_report_sha256':sha(PREVIOUS),'native_manifest':relative(NATIVE),'source_pins':pins,'expected_base_sources':600,'expected_save_paths':171,'expected_absent_save_paths':9,'expected_native_sources':166,'expected_original_registry_ID_count':14,'original_registry_IDs':old_ids,'original_sect_scene_IDs':IDS,'two_original_drafts':DRAFTS,'additional_source_paths':[path.as_posix() for path in sorted(paths)],'allowed_editor_pid':51856,'no_save_content_reads':True,'engine_runs':0,'source_writes':0},ensure_ascii=True,separators=(',',':')))
