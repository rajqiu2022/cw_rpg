from pathlib import Path
import hashlib,json,yaml,sys
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
sys.path.insert(0,str(R/'scripts'))
import gen_assets
tasks=yaml.safe_load((R/'prompts/interior_identity_20261106/women_tasks.yaml').read_text(encoding='utf8'))['tasks']
current=(R/'prompts/tasks.yaml').read_bytes();before=(O/'before/tasks_before_women.yaml').read_bytes()
assert current.startswith(before), 'Shared queue prior byte prefix changed'
registered=yaml.safe_load(current)['tasks'];old=yaml.safe_load(before)['tasks']
assert registered==old+tasks and len(old)==788
reports=[]
for task in tasks:
    path=R/task['prompt_path'];prompt=path.read_text(encoding='utf8')
    variables=dict(task['vars']);variables['asset_prompt']=prompt
    spec=gen_assets.render_template(task['template'],variables,gen_assets.load_yaml(R/'prompts/templates/_shared.yaml'))
    assert task['skip'] is True and spec['prompt']==prompt.strip()
    assert [entry for entry in registered if entry.get('id')==task['id']]==[task]
    ref=R/variables['reference_style'];assert ref.is_file()
    reports.append({'id':task['id'],'backend':'builtin_image_gen','prompt_path':str(path),'prompt_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'references':[str(ref)],'registered_skip':True,'network_calls':0,'generation_calls':0,'spec':spec})
result={'before_count':len(old),'after_count':len(registered),'prior_prefix_exact':True,'before_sha256':hashlib.sha256(before).hexdigest(),'after_sha256':hashlib.sha256(current).hexdigest(),'reports':reports}
(O/'women_dry_run.json').write_text(json.dumps(result,ensure_ascii=False,indent=2,default=str),encoding='utf8')
print(json.dumps({k:v for k,v in result.items() if k!='reports'}))
for r in reports:print(r['id'],r['prompt_path'],r['prompt_sha256'])
