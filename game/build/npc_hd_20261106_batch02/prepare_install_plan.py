"""Prepare exact ten-object proposal and source inventory; no formal writes."""
from pathlib import Path
import json,hashlib,shutil
O=Path(__file__).resolve().parent;R=O.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
records=json.loads((O/'mipmap_import_plan.json').read_text())['records']
manifest=R/'game/art/characters/pc_hd_20261102c/source.json'
adapter=R/'game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd'
before=json.loads((O/'mapping_plan.json').read_text())
assert sha(manifest)==before['formal_manifest_before_sha256']
targets=[]
for rec in records:
 for key,target in [('png',R/'game'/rec['res'][6:]),('import',R/'game'/(rec['res'][6:]+'.import')),('ctex',R/'game/.godot/imported'/Path(rec['ctex']).name)]:
  src=Path(rec[key]);assert src.is_file();assert not target.exists(),target
  targets.append({'candidate':str(src),'target':str(target),'before':'ABSENT','after_sha256':sha(src),'kind':key})
backup=O/'before/source.json';backup.parent.mkdir(exist_ok=True)
if backup.exists():assert sha(backup)==sha(manifest)
else:shutil.copyfile(manifest,backup)
targets.append({'candidate':str(O/'source.merged18.candidate.json'),'target':str(manifest),'before':sha(manifest),'backup':str(backup),'after_sha256':sha(O/'source.merged18.candidate.json'),'kind':'json_apply_patch'})
plan={'status':'PROPOSED_NOT_INSTALLED','write_count':10,'old_mappings_preserved':15,'new_mappings':3,'new_families':2,'adapter_frozen':{'path':str(adapter),'sha256':sha(adapter)},'targets':targets}
(O/'formal_install_plan.json').write_text(json.dumps(plan,indent=2))
paths=['game/project.godot','game/scripts/autoload/platform_bridge.gd','game/scripts/autoload/save_manager.gd','game/scripts/field/npc_node.gd','game/scenes/npc_node.tscn','game/shaders/interaction_outline.gdshader',str(adapter.relative_to(R)).replace('\\','/'),str(manifest.relative_to(R)).replace('\\','/')]
for name in ['root_batch02_fixture.gd','source.batch02.candidate.json','mipmap_import_plan.json','formal_install_plan.json']:
 paths.append(str((O/name).relative_to(R)).replace('\\','/'))
for rec in records:
 paths.append('game/'+rec['source'][6:])
 for key in ['png','import','ctex']:paths.append(str(Path(rec[key]).relative_to(R)).replace('\\','/'))
assert all((R/p).is_file() for p in paths)
(O/'visual_sources.json').write_text(json.dumps({'source_paths':list(dict.fromkeys(paths))},indent=2))
print(json.dumps({'target_count':len(targets),'source_count':len(paths),'formal_writes':0,'adapter_frozen':sha(adapter)}))
