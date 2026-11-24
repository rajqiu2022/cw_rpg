from pathlib import Path
import hashlib,json,yaml,sys
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
sys.path.insert(0,str(R/'scripts'))
import gen_assets
tasks=yaml.safe_load((R/'prompts/npc_hd_20261106_batch03/tasks.yaml').read_text(encoding='utf8'))['tasks']
reports=[]
registered=yaml.safe_load((R/'prompts/tasks.yaml').read_text(encoding='utf8'))['tasks']
for task in tasks:
    prompt=(R/task['prompt_path']).read_text(encoding='utf8')
    variables=dict(task['vars']);variables['asset_prompt']=prompt
    spec=gen_assets.render_template(task['template'],variables,gen_assets.load_yaml(R/'prompts/templates/_shared.yaml'))
    assert task['skip'] is True and spec['prompt']==prompt.strip()
    assert [entry for entry in registered if entry.get('id')==task['id']]==[task]
    refs=[variables['reference_raw'],variables['reference_runtime']]
    assert all((R/path).is_file() for path in refs)
    reports.append({'id':task['id'],'backend':'builtin_image_gen','prompt_path':str(R/task['prompt_path']),'prompt_sha256':hashlib.sha256((R/task['prompt_path']).read_bytes()).hexdigest(),'references':[str(R/path) for path in refs],'registered_skip':True,'registration_scope':'shared queue exact five-row append plus independent batch03 tasks','network_calls':0,'generation_calls':0,'spec':spec})
(O/'dry_run.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2,default=str),encoding='utf8')
print(json.dumps([{k:v for k,v in report.items() if k!='spec'} for report in reports],ensure_ascii=False))
