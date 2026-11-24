"""Offline built-in task dry-run. No credentials, network or image mutations."""
from pathlib import Path
import hashlib,json,yaml,sys
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'scripts'))
import gen_assets
tasks=[]
for spec_file in ['tasks.yaml','next_four_tasks.yaml']:
    tasks.extend(yaml.safe_load((ROOT/'prompts/npc_hd_20261106'/spec_file).read_text(encoding='utf8'))['tasks'])
shared=gen_assets.load_yaml(ROOT/'prompts/templates/_shared.yaml')
registered=yaml.safe_load((ROOT/'prompts/tasks.yaml').read_text(encoding='utf8'))['tasks']
reports=[]
for t in tasks:
    prompt=(ROOT/t['prompt_path']).read_text(encoding='utf8')
    variables=dict(t['vars']); variables['asset_prompt']=prompt
    spec=gen_assets.render_template(t['template'],variables,shared)
    registered_row=[x for x in registered if x.get('id')==t['id']]
    assert len(registered_row)==1 and registered_row[0].get('skip') is True
    assert spec['prompt']==prompt.strip()
    reports.append({'id':t['id'],'backend':'builtin_image_gen','prompt_path':t['prompt_path'],'prompt_sha256':hashlib.sha256(prompt.encode()).hexdigest(),'references':[str(x) for x in spec['reference_images']],'registered_skip':True,'network_calls':0})
out=Path(__file__).parent/'dry_run.json'
out.write_text(json.dumps(reports,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(reports,ensure_ascii=False,indent=2))
