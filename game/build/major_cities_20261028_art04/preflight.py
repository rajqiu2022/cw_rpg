from pathlib import Path
import importlib.util
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'scripts'))
spec = importlib.util.spec_from_file_location('bz_art04_renderer', ROOT / 'scripts/gen_assets.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.TEMPLATES_DIR = HERE / 'production/prompts/templates'
tasks = module.load_yaml(HERE / 'production/prompts/tasks.yaml')['tasks']
out = HERE / 'production/prompts/rendered'
out.mkdir(parents=True, exist_ok=True)
root_tasks = ROOT / 'prompts/tasks.yaml'
before = hashlib.sha256(root_tasks.read_bytes()).hexdigest()
rows = []
for task in tasks:
    rendered = module.render_template(task['template'], task['vars'], {})
    assert '{asset_prompt}' not in rendered['prompt']
    assert task['skip'] and task['attempt_budget'] == 1
    assert not task['retries_allowed'] and not task['cli_fallback_allowed']
    ref_count = 0 if task['id'].endswith('earth_tile_v1') else (2 if task['id'].endswith('v2_edit') else 1)
    assert len(rendered['reference_images']) == ref_count
    path = out / (task['id'] + '.txt')
    path.write_text(rendered['prompt'] + '\n', encoding='utf-8')
    rows.append({'id':task['id'], 'prompt':str(path.relative_to(ROOT)),
                 'prompt_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                 'references':[str(p.relative_to(ROOT)) for p in rendered['reference_images']],
                 'reference_sha256':[hashlib.sha256(p.read_bytes()).hexdigest() for p in rendered['reference_images']],
                 'background':rendered['background'], 'calls':0})
assert before == hashlib.sha256(root_tasks.read_bytes()).hexdigest()
report = {'status':'PASS_DRYRUN_ONLY', 'actual_renderer':'scripts/gen_assets.py:render_template',
          'backend':'builtin_image_gen', 'generation_calls':0, 'cli_calls':0,
          'root_tasks_sha256_before_after':before, 'tasks':rows}
(HERE/'preflight.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
