"""Offline publication preparation only. No formal writes/import/engine/save access."""
from pathlib import Path
import json,hashlib,difflib,shutil
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
formal=R/'game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd'
candidate=O/'pc_sprite_view_runtime.candidate.gd'
assert sha(formal)=='e240d6f0f28492f19b646018db57ed738bac2def0affc774595307a72f2f6b94'
assert sha(candidate)=='28db6f070c6495aac88e9c215d09c760bf98a682e0ac09ba5662262f12410a33'
assert not (R/'game/art/characters/pc_hd_20261102c/source.json').exists()
backup=O/'before_formal_adapter.bin'
if not backup.exists():shutil.copy2(formal,backup)
assert backup.read_bytes()==formal.read_bytes()
primary=json.loads((O/'source.candidate.json').read_text())
reuse=json.loads((O/'source.reuse.candidate.json').read_text())
assert not set(primary['mappings'])&set(reuse['mappings'])
combined=dict(primary,mappings={**primary['mappings'],**reuse['mappings']})
assert combined['approved'] is False and len(combined['mappings'])==11
targets=[]
for source,row in combined['mappings'].items():
    source_file=R/'game'/source[6:]
    assert sha(source_file)==row['source_sha256']
    target=R/'game'/row['atlas'][6:]
    if source in primary['mappings']:
        prepared=O/('waiter_idle_down.png' if 'waiter' in source else 'vendor_idle_down.png')
    else:prepared=O/(target.name.replace('_native_20261106.png','_native_candidate.png'))
    assert sha(prepared)==row['atlas_sha256'] and row['body_height']>=320
    assert not target.exists()
    targets.append({'source':source,'candidate':prepared.relative_to(R).as_posix(),'target':target.relative_to(R).as_posix(),'sha256':sha(prepared),'primary_two_only':source in primary['mappings']})
(O/'source.combined.candidate.json').write_text(json.dumps(combined,indent=2))
# Ready candidate is separate from the unapproved combined file. Publishing it
# remains gated on Root's finite fixture plus explicit formal admission.
ready=dict(primary,approved=True)
(O/'source.two.ready_PENDING_FIXTURE.json').write_text(json.dumps(ready,indent=2))
lines=list(difflib.unified_diff(formal.read_text().splitlines(True),candidate.read_text().splitlines(True),fromfile='a/'+formal.relative_to(R).as_posix(),tofile='b/'+formal.relative_to(R).as_posix()))
(O/'adapter_exact_candidate.diff').write_text(''.join(lines))
plan={'status':'PREPARED_ONLY_PENDING_ROOT_FIXTURE','formal_before_sha256':sha(formal),'candidate_after_sha256':sha(candidate),'backup':backup.relative_to(R).as_posix(),'inverse':'Full byte backup; require formal current SHA equals candidate before restoring. No automatic restoration.','diff':'adapter_exact_candidate.diff','primary_ready_manifest':'source.two.ready_PENDING_FIXTURE.json','combined_unapproved_manifest':'source.combined.candidate.json','initial_allowed_new_png_count':2,'candidate_mapping_count':11,'candidate_family_count':8,'targets':targets,'formal_writes':0,'engine_launches':0,'no_real_save_content_access':True}
(O/'publication_plan.json').write_text(json.dumps(plan,indent=2))
assert sha(formal)==plan['formal_before_sha256']
print(json.dumps({'candidate_families':8,'candidate_mappings':11,'formal_writes':0,'backup_exact':True,'initial_new_pngs':2}))
