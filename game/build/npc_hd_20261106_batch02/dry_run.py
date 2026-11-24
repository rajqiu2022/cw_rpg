from pathlib import Path
import hashlib,json,yaml,sys
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
sys.path.insert(0,str(R/'scripts'))
import gen_assets
task=yaml.safe_load((R/'prompts/npc_hd_20261106_batch02/tasks.yaml').read_text(encoding='utf8'))['tasks'][0]
prompt=(R/task['prompt_path']).read_text(encoding='utf8');v=dict(task['vars']);v['asset_prompt']=prompt
spec=gen_assets.render_template(task['template'],v,gen_assets.load_yaml(R/'prompts/templates/_shared.yaml'))
registered=yaml.safe_load((R/'prompts/tasks.yaml').read_text(encoding='utf8'))['tasks']
matches=[t for t in registered if t.get('id')==task['id']]
assert len(matches)==1 and matches[0]==task and task['skip'] is True
assert spec['prompt']==prompt.strip()
refs=[v['reference_raw'],v['reference_runtime']]
assert all((R/p).is_file() for p in refs)
report={'id':task['id'],'backend':'builtin_image_gen','prompt_path':str(R/task['prompt_path']),'prompt_sha256':hashlib.sha256((R/task['prompt_path']).read_bytes()).hexdigest(),'references':[str(R/p) for p in refs],'registered_skip':True,'network_calls':0,'generation_calls':0,'spec':spec}
(O/'dry_run.json').write_text(json.dumps(report,ensure_ascii=False,indent=2,default=str),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='spec'},ensure_ascii=False))
