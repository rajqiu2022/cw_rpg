"""Finite declared consumer closure only; no save files or engine, stdout only."""
from pathlib import Path
import hashlib,json,re,sys
ROOT=Path('F:/Code/RPG_GAME');GAME=ROOT/'game'
old=json.loads((ROOT/'game/build/lanxi_terrace_banks_20261031b_qa01/source_scope_READY.json').read_text(encoding='utf-8-sig'))
critical=set(old['current_source_pins'])
critical.update('game/'+s for s in [
 'build/lanxi_paddy_passage_20261031b_system01/paddy_controller.gd',
 'build/sect_adoption_20261030n_system01/adoption_contract.gd',
 'build/sect_adoption_20261030n_system01/router_entry.gd',
 'build/sect_adoption_20261030n_system01/sect_adoption_field.gd',
 'build/sect_adoption_20261030n_system01/sect_adoption_field.tscn',
 'build/sect_adoption_20261030n_system01/adoption_data.json',
 'scenes/drafts/sect_maps_20261029k/wudang.tscn',
 'scenes/drafts/huashan_map_20261029m/huashan.tscn',
 'build/three_settlements_20261030e_system01/settlement_registry.gd',
 'build/three_settlements_20261030e_system01/settlement_field.gd',
 'build/three_settlements_20261030e_system01/settlement_field.tscn',
 'build/three_settlements_20261030e_system01/common_author.gd',
 'build/three_settlements_20261030e_system01/xiangzhou_author.gd',
 'build/three_settlements_20261030e_qinghe01/qinghe_author.gd',
 'build/three_settlements_20261030e_yanmen01/yanmen_author.gd',
 'build/three_settlements_20261030e_system01/city_minimap.gd',
 'build/three_settlements_20261030e_system01/minimap_layout_snapshot.gd',
 'scripts/world/world_v15_visible_stream_20261018r.gd',
 'scripts/world/world_v14_modular_overlap.gd',
 'scripts/field/field_walkable_controller.gd',
 'scripts/field/world_v15_exit_zone.gd','scripts/field/exit_zone.gd',
 'data/scenes/world_map_jianghu.tres',
 'data/scenes/openworld_xiangzhou_city.tres',
 'data/scenes/openworld_qinghe_town.tres','data/scenes/openworld_yanmen_pass.tres'])
# Only declared resources of these selected consumers, not a library traversal.
pending=[ROOT/p for p in critical if (ROOT/p).is_file()]
adoption=json.loads((ROOT/'game/build/sect_adoption_20261030n_system01/closure_receipt_READY.json').read_text(encoding='utf-8-sig'))
pending += [GAME/p[6:] for p in adoption['immutable_required_inputs'] if p.startswith('res://')]
found=set();missing=[]
while pending:
 p=pending.pop()
 if p in found:continue
 if not p.is_file():missing.append(str(p));continue
 found.add(p)
 metadata_only=p.name in {'scene_router.gd','field_walkable_controller.gd','world_v15_visible_stream_20261018r.gd','world_v14_modular_overlap.gd'} or 'world_map' in p.name
 if not metadata_only and p.suffix.lower() in {'.gd','.tscn','.tres','.json','.gdshader'}:
  for uri in re.findall(r'res://[^\s\"\'<>]+',p.read_text(encoding='utf-8-sig')):
   q=GAME/uri[6:]
   if q.is_file():pending.append(q)
 # Protect already imported exact same-URI companion files, no import action.
 imp=Path(str(p)+'.import')
 if imp.is_file() and imp not in found:
  found.add(imp)
  for uri in re.findall(r'res://[^\s\"\'<>]+',imp.read_text(encoding='utf-8-sig')):
   q=GAME/uri[6:]
   if q.is_file():found.add(q)
out={
 'schema_version':1,'status':'PRE31C_SOURCE_PATH_SCOPE_NOT_SAVE_BASELINE',
 'seed_report':'game/build/lanxi_terrace_banks_20261031b_qa01/final_guard_ACTUAL.json',
 'seed_sha256':'38429886e3a20ed4582484d0d212d8ced65c636803c4da0a7e32c4486ee87ea9',
 'seed_use':'986 source/171 save paths +9 absent; old metadata values never used as NOW',
 'expected_native_keys':202,
 'current_source_pins':{p:{'sha256':hashlib.sha256((ROOT/p).read_bytes()).hexdigest(),'bytes':(ROOT/p).stat().st_size} for p in sorted(critical) if (ROOT/p).is_file()},
 'additional_source_paths':sorted(str(p).replace('\\','/') for p in found),
 'missing_declared_roots':missing,
 'closure_scope':'Exact consumer resource references only: World+five bridges, W/H drafts/adoption30n, three official settlements; not full repo',
 'only_editor_pid':51856,'save_content_reads':0,'engine_runs':0
}
if '--summary' in sys.argv:
 out['declared_consumer_closure_count']=len(out.pop('additional_source_paths'))
 out['closure_generator']='game/build/world_sects_cities_20261031c_qa01/prepare_scope_READONLY.py'
print(json.dumps(out,ensure_ascii=False,separators=(',',':')))
