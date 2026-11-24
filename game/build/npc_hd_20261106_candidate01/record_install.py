"""Record only the already Root-authorized narrow two-family publication."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
plan=json.loads((O/'publication_plan.json').read_text())
formal=R/'game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd'
assert sha(formal)==plan['candidate_after_sha256']
assert sha(R/plan['backup'])==plan['formal_before_sha256']
assert formal.read_bytes()==(O/'pc_sprite_view_runtime.candidate.gd').read_bytes()
manifest=R/'game/art/characters/pc_hd_20261102c/source.json';actual=json.loads(manifest.read_text())
assert actual==json.loads((O/'source.two.ready_PENDING_FIXTURE.json').read_text()) and actual['approved'] is True and len(actual['mappings'])==2
installed=[]
for t in plan['targets']:
    if t['primary_two_only']:
        assert sha(R/t['target'])==t['sha256']
        installed.append(t)
log=R/'game/build/joint_world_luoyang_20261003_qa/npc_hd06_lease01/stdout.log'
assert '"failed":0' in log.read_text() and 'NPC_HD06_RESULT' in log.read_text()
report={'status':'FORMALLY_INSTALLED_TWO_FAMILIES_AFTER_ROOT_FINITE_FIXTURE','new_family_count':2,'new_texture_mapping_count':2,'existing_farmer_not_new':True,'formal_adapter_sha256':sha(formal),'formal_manifest_sha256':sha(manifest),'backup_before_sha256':sha(R/plan['backup']),'exact_candidate_bytes':True,'restoration_policy':'No auto-restore; exact before bytes retained, current after must match before any authorized reverse.','primary_source_paths_unchanged':True,'fixture_log':log.relative_to(R).as_posix(),'fixture_log_sha256':sha(log),'fixture_result':'Root actual130476 natural0,34 passed 0 failed; old exit warnings retained','new_pngs':installed,'candidate_remaining_families':6,'candidate_remaining_mappings':9,'all_npc_hd_complete':False,'formal_business_edits':0,'engine_launches_by_npc06':0,'real_save_content_access':False,'failed_attempt_retained':'Initial apply_patch numeric unified-hunk rejected without write; supported @@ context patch then applied.'}
report['status']='TWO_FAMILY_FILES_INSTALLED_RUNTIME_TEXTURE_IMPORT_PENDING'
report['runtime_visible_confirmed']=False
report['post_install_visual_failure']='Root visual01 actual106528 natural1: mappings=1, errors=[]; two PNG .import files absent. Preserve failed evidence; isolated import and real formal-load assertion still required.'
if not (O/'formal_install_receipt.json').exists():
    (O/'formal_install_receipt.json').write_text(json.dumps(report,indent=2))
sources=json.loads((O/'fixture_sources.json').read_text())['source_paths']
sources.extend(['game/build/npc_hd_20261106_candidate01/root_hd_visual_fixture.gd','game/build/npc_hd_20261106_candidate01/source.combined.candidate.json',manifest.relative_to(R).as_posix()])
for t in plan['targets']:
    sources.extend([t['candidate'], 'game/'+t['source'][6:]])
    if t['primary_two_only']:sources.append(t['target'])
sources=list(dict.fromkeys(sources))
assert all((R/p).is_file() for p in sources)
(O/'visual_sources.json').write_text(json.dumps({'source_paths':sources},indent=2))
print(json.dumps({'installed_families':2,'installed_mappings':2,'remaining_candidate_families':6,'visual_guard_sources':len(sources)}))
