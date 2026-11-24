"""Record the Root-authorized exact ten-target install; no engine/save access."""
from pathlib import Path
import json,hashlib
O=Path(__file__).resolve().parent; R=O.parents[2]
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
p=read(O/'formal_install_plan.json')
assert sha(Path(p['adapter_frozen']['path']))==p['adapter_frozen']['sha256']
for row in p['targets']:
    assert sha(Path(row['target']))==row['after_sha256'],row['target']
    if row['before']!='ABSENT':assert sha(Path(row['backup']))==row['before']
before=read(O/'before/source.json');after=read(R/'game/art/characters/pc_hd_20261102c/source.json')
assert all(after['mappings'][k]==v for k,v in before['mappings'].items())
assert len(before['mappings'])==15 and len(after['mappings'])==18
receipt={'status':'INSTALLED_PENDING_FORMAL3_CONSUMER_CHECK','exact_targets':10,'new_atlases':3,'new_families':2,'old_15_mappings_exact':True,'adapter_frozen':True,'all_target_sha_exact':True,'manifest_sha256':sha(R/'game/art/characters/pc_hd_20261102c/source.json'),'candidate_visual':'Root visual02 actual110248 natural0,53/0,13 frames both flips; three first-frame identities/proportion/clarity ART finite accepted','new_scene_art_claim':False,'whole_npc_complete':False,'engine_launches_by_agent':0,'real_save_content_access':False,'runner_privacy':'system02 metadata-only; old batch01 shared runner did hash save bytes, historical claims corrected','preserved_failures':['visual01 actual139764 timeout from absent NameLabel fixture','apply_patch terminal newline caused initial exact-after SHA mismatch; only terminal CRLF formatting removed, exact approved bytes now match'],'old_exit_errors_retained':'3 RID/null RenderingServer errors on visual02, not clean'}
(O/'formal_after_receipt.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
paths=['game/project.godot','game/scripts/autoload/platform_bridge.gd','game/scripts/autoload/save_manager.gd','game/scripts/field/npc_node.gd','game/scenes/npc_node.tscn','game/shaders/interaction_outline.gdshader','game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd','game/build/npc_hd_20261106_batch02/root_formal3_fixture.gd']
paths.extend(Path(x['target']).relative_to(R).as_posix() for x in p['targets'])
paths.extend('game/'+k[6:] for k in read(O/'source.batch02.candidate.json')['mappings'])
assert len(paths)==len(set(paths)) and all((R/x).is_file() for x in paths)
(O/'formal_sources.json').write_text(json.dumps({'source_paths':paths},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'targets':10,'manifest':18,'sources':len(paths),'old_mapping_exact':True}))
