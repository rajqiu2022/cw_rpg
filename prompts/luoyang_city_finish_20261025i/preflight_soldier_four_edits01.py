"""Offline four actual identity-preserving edit requests. No generation or queue edits."""
from pathlib import Path
import hashlib,importlib.util,json
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
def new(p,b):
    with p.open('xb') as f:f.write(b)
    return dict(path=str(p.relative_to(ROOT)).replace('\\','/'),sha256=sha(b),bytes=len(b))
spec=importlib.util.spec_from_file_location('renderer_soldier_edits25i',ROOT/'scripts/gen_assets.py');gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen)
table=(ROOT/'prompts/tasks.yaml').read_bytes();old=gen.load_yaml(ROOT/'prompts/tasks.yaml')['tasks']
candidate=HERE/'soldier_four_identity_edits_tasks_candidate.yaml';tasks=gen.load_yaml(candidate);assert len(tasks)==4
assert {r['id'] for r in tasks}.isdisjoint({r['id'] for r in old})
expected={'guard_young_bluegrey_walk4_v1.png':'012a7e75e954ca8d48d02f4ac04ae6282758623fc361c13441aeb17ad8fca5d7','guard_veteran_ochre_walk4_v1.png':'823cb3d18541f9fec36d87e4a75c8c4d073a63394d6d2fbe7242d088d27d35e9'}
rows=[]
for task in tasks:
    assert task['execution_backend']=='builtin_image_gen' and task['skip'] is True and task['attempt_budget']==1
    assert task['retries_allowed'] is False and task['cli_fallback_allowed'] is False
    assert task['model'] is None and task['provider'] is None and task['cost'] is None
    assert len(task['reference_images'])==1
    ref=ROOT/task['reference_images'][0];assert sha(ref.read_bytes())==expected[ref.name]
    p=ROOT/task['prompt_path'];prompt=p.read_text(encoding='utf-8')
    r=gen.render_template(task['template'],{'asset_prompt':prompt},gen.load_yaml(gen.SHARED_FILE))
    assert r['prompt']==prompt.strip() and r['background']==('transparent' if task['transparent_background'] else 'opaque')
    rows.append(dict(id=task['id'],prompt_path=task['prompt_path'],prompt_sha256=sha(p.read_bytes()),rendered_prompt=r['prompt'],reference=task['reference_images'][0],reference_sha256=expected[ref.name],tool_mode='TRUE_IDENTITY_PRESERVING_IMAGE_EDIT_NOT_BRAND_NEW_TEXT_ONLY',transparent_background=task['transparent_background'],referenced_image_paths=[str(ref)],num_last_images_to_include_must_be_omitted=True))
suffix='\n'+candidate.read_text(encoding='utf-8').strip('\n')+'\n';after=table+suffix.encode();assert after[:-len(suffix.encode())]==table
last=table.decode().rstrip('\n').splitlines()[-1]
patch='*** Begin Patch\n*** Update File: F:/Code/RPG_GAME/prompts/tasks.yaml\n@@\n '+last+'\n'+''.join('+'+r+'\n' for r in suffix.splitlines())+'*** End Patch\n'
pp=new(OUT/'soldier_four_identity_edits01_dryrun.apply_patch',patch.encode())
report=dict(status='FOUR_TRUE_IDENTITY_EDITS_OFFLINE_PASS_NOT_REGISTERED_NOT_CALLED',passed=True,task_table_before_sha256=sha(table),task_table_before_bytes=len(table),proposed_after_sha256=sha(after),append_suffix=suffix,exact_inverse=True,prompts=rows,append_patch=pp,generation_calls=0,root_task_edits=0,PNG_edits=0,Godot_calls=0)
rp=new(OUT/'soldier_four_identity_edits01_dryrun.json',(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode());assert (ROOT/'prompts/tasks.yaml').read_bytes()==table
print(json.dumps(dict(passed=True,report=rp,patch=pp,prompts=[dict(id=r['id'],sha256=r['prompt_sha256']) for r in rows])))
