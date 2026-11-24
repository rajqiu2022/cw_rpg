from pathlib import Path
import importlib.util, json, hashlib
ROOT=Path('F:/Code/RPG_GAME')
spec=importlib.util.spec_from_file_location('project_image_renderer',ROOT/'scripts/gen_assets.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
base=ROOT/'assets/staging/gather_actions_20261030l/production'
module.TEMPLATES_DIR=base/'templates'
tasks=module.load_yaml(base/'prompts/tasks.yaml')['tasks']
rows=[]
for task in tasks:
    result=module.render_template(task['template'],task['vars'],{})
    assert len(result['reference_images'])==2 and len(result['prompt'])>2000
    out=ROOT/'game/build/gather_actions_20261030l_root01'/f"{task['id']}_prompt_READY.txt"
    out.write_text(result['prompt']+'\n',encoding='utf-8')
    rows.append({'id':task['id'],'dry_run':True,'backend':'builtin_image_gen','api_calls':0,'prompt':str(out),'prompt_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'refs':[str(p) for p in result['reference_images']],'requested_size':result['size'],'size_is_not_builtin_tool_argument':True})
(ROOT/'game/build/gather_actions_20261030l_root01/art_preflight_ACTUAL.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'tasks':len(rows),'dry_run':True,'api_calls':0}))
