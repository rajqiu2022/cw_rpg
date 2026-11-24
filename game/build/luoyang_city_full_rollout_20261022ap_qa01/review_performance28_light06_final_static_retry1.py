"""Preserve old-copy-schema zero-output failure; bind actual D39A receipt."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_performance28_light06_final_static.py');b=p.read_bytes()
assert hashlib.sha256(b).hexdigest()=='b1b8422679e025f3d666b0a75af5213e7265c651303253a74f443fefbddc39fa'
s=b.decode();old="assert cp['all22_exact']and cp['JSON_exact_copy_count']==13 and cp['GD_apply_patch_count']==9"
new="""assert cp['status']=='ROOT_ACTUAL_EXACT13_GENERATED_JSON_BYTE_COPIES_AFTER9_GD_APPLY_PATCH'and cp['copy_count']==13 and cp['GD_apply_patch_count']==9 and cp['normalization']is False and cp['native_or_save_or_media_writes']==0
staged={row['target']:row for row in stage['targets']}
assert len(cp['copies'])==13
for row in cp['copies']:
    target='res://'+Path(row['path']).relative_to(ROOT).as_posix()
    assert target.endswith('.json')and row['sha256']==staged[target]['candidate_sha256']and row['bytes']==res(staged[target]['candidate_path']).stat().st_size"""
assert s.count(old)==1;s=s.replace(old,new)
old='performance28_light06_ROOT26_independent_final_static_admission_READY.json';new='performance28_light06_ROOT26_retry1_independent_final_static_admission_READY.json'
assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
