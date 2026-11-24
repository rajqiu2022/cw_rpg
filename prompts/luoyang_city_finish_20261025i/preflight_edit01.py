"""Offline one approved ironwork edit prompt and append-only registration proposal."""
from pathlib import Path
import hashlib, importlib.util, json
ROOT=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b): return hashlib.sha256(b).hexdigest()
def new(p,b):
    with p.open('xb') as f: f.write(b)
    return dict(path=str(p.relative_to(ROOT)).replace('\\','/'),sha256=sha(b),bytes=len(b))
spec=importlib.util.spec_from_file_location('renderer_iron_edit25i',ROOT/'scripts/gen_assets.py')
gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen)
table=(ROOT/'prompts/tasks.yaml').read_bytes()
old=gen.load_yaml(ROOT/'prompts/tasks.yaml')['tasks']
candidate=HERE/'ironwork_v2_edit_task_candidate.yaml'
task=gen.load_yaml(candidate)[0]
assert all(r['id']!=task['id'] for r in old)
assert task['skip'] is True and task['attempt_budget']==1 and task['retries_allowed'] is False
assert task['execution_backend']=='builtin_image_gen' and task['cli_fallback_allowed'] is False
assert task['model'] is None and task['provider'] is None and task['cost'] is None
ref=task['reference_images'];assert len(ref)==1
refb=(ROOT/ref[0]).read_bytes()
assert sha(refb)=='9e6bc9235eb9bfe067f4b9d0b1e7fd1b8f71c8741a02049404d76d20c2e11d7a'
prompt=(ROOT/task['prompt_path']).read_text(encoding='utf-8')
render=gen.render_template(task['template'],{'asset_prompt':prompt},gen.load_yaml(gen.SHARED_FILE))
assert render['prompt']==prompt.strip() and render['background']=='transparent'
suffix='\n'+candidate.read_text(encoding='utf-8').strip('\n')+'\n'
after=table+suffix.encode();assert after[:-len(suffix.encode())]==table
last=table.decode().rstrip('\n').splitlines()[-1]
patch='*** Begin Patch\n*** Update File: F:/Code/RPG_GAME/prompts/tasks.yaml\n@@\n '+last+'\n'+''.join('+'+r+'\n' for r in suffix.splitlines())+'*** End Patch\n'
pp=new(OUT/'ironwork_v2_edit01_dryrun.apply_patch',patch.encode())
report=dict(status='APPROVED_SINGLE_BUILTIN_EDIT_OFFLINE_PASS_NOT_REGISTERED_NOT_CALLED',passed=True,task_id=task['id'],prompt_path=task['prompt_path'],prompt_sha256=sha((ROOT/task['prompt_path']).read_bytes()),rendered_prompt=render['prompt'],reference_images=[dict(path=ref[0],sha256=sha(refb))],tool_call=dict(transparent_background=True,referenced_image_paths=[str(ROOT/ref[0])],num_last_images_to_include_must_be_omitted=True),task_table_before_sha256=sha(table),task_table_before_bytes=len(table),proposed_after_sha256=sha(after),suffix=suffix,exact_inverse=True,append_patch=pp,model=None,provider=None,cost=None,generation_calls=0,local_image_processing=0)
rp=new(OUT/'ironwork_v2_edit01_dryrun.json',(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
assert (ROOT/'prompts/tasks.yaml').read_bytes()==table and (ROOT/ref[0]).read_bytes()==refb
print(json.dumps(dict(passed=True,report=rp,patch=pp,prompt_sha256=report['prompt_sha256'])))
