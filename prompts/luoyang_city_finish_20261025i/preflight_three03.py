"""Offline three approved independent builtin requests; no queue edits or generation."""
from pathlib import Path
import hashlib, importlib.util, json
ROOT=Path(__file__).resolve().parents[2]; HERE=Path(__file__).resolve().parent
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
def new(p,b):
    with p.open('xb') as f:f.write(b)
    return dict(path=str(p.relative_to(ROOT)).replace('\\','/'),sha256=sha(b),bytes=len(b))
spec=importlib.util.spec_from_file_location('existing_renderer_batch25i',ROOT/'scripts/gen_assets.py')
gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen)
table=(ROOT/'prompts/tasks.yaml').read_bytes(); old=gen.load_yaml(ROOT/'prompts/tasks.yaml')['tasks']
candidate=HERE/'buildings_three03_tasks_candidate.yaml'; taskrows=gen.load_yaml(candidate)
assert len(taskrows)==3
assert {r['id'] for r in taskrows}.isdisjoint({r['id'] for r in old})
rows=[]
for task in taskrows:
    assert task['execution_backend']=='builtin_image_gen' and task['skip'] is True and task['attempt_budget']==1
    assert task['retries_allowed'] is False and task['cli_fallback_allowed'] is False
    assert task['model'] is None and task['provider'] is None and task['cost'] is None and task['transparent_background'] is True
    p=ROOT/task['prompt_path']; prompt=p.read_text(encoding='utf-8')
    r=gen.render_template(task['template'],{'asset_prompt':prompt},gen.load_yaml(gen.SHARED_FILE))
    assert r['prompt']==prompt.strip() and r['background']=='transparent'
    refs=[]
    for ref in task['reference_images']:
        raw=(ROOT/ref).read_bytes();assert sha(raw)=='9e6bc9235eb9bfe067f4b9d0b1e7fd1b8f71c8741a02049404d76d20c2e11d7a'
        refs.append(dict(path=ref,sha256=sha(raw)))
    assert len(refs)==(1 if task['id'].endswith('_edit') else 0)
    rows.append(dict(id=task['id'],prompt_path=task['prompt_path'],prompt_sha256=sha(p.read_bytes()),rendered_prompt=r['prompt'],references=refs,new_call_omit_both_references=not refs))
suffix='\n'+candidate.read_text(encoding='utf-8').strip('\n')+'\n';after=table+suffix.encode()
assert after[:-len(suffix.encode())]==table
last=table.decode().rstrip('\n').splitlines()[-1]
patch='*** Begin Patch\n*** Update File: F:/Code/RPG_GAME/prompts/tasks.yaml\n@@\n '+last+'\n'+''.join('+'+r+'\n' for r in suffix.splitlines())+'*** End Patch\n'
pp=new(OUT/'buildings_three03_dryrun.apply_patch',patch.encode())
report=dict(status='THREE_APPROVED_BUILTIN_REQUESTS_OFFLINE_PASS_NOT_REGISTERED_NOT_CALLED',passed=True,task_table_before_sha256=sha(table),task_table_before_bytes=len(table),proposed_after_sha256=sha(after),append_suffix=suffix,exact_inverse=True,prompts=rows,append_patch=pp,generation_calls=0,network_calls=0,root_task_edits=0,Godot_calls=0,local_image_processing=0)
rp=new(OUT/'buildings_three03_dryrun.json',(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
assert (ROOT/'prompts/tasks.yaml').read_bytes()==table
print(json.dumps(dict(passed=True,report=rp,patch=pp,prompts=[dict(id=r['id'],sha256=r['prompt_sha256']) for r in rows])))
