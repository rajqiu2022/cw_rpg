"""Use the public template renderer only; bypass queue filtering, not skip registration."""
import hashlib, json, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/sentry_portrait02_OFFLINE_RENDER'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,v):
    with p.open('xb') as f: f.write((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
def main():
    tasks=ROOT/'prompts/tasks.yaml';before=tasks.read_bytes();beforetime=tasks.stat().st_mtime_ns
    sys.path.insert(0,str(ROOT/'scripts'))
    import gen_assets as renderer
    ident='luoyang_20261025i_young_spear_sentry_portrait_v1_edit'
    rows=[r for r in renderer.load_yaml(tasks)['tasks'] if r.get('id')==ident]
    assert len(rows)==1
    task=rows[0]
    assert task['skip'] is True and task['execution_backend']=='builtin_image_gen'
    assert task['attempt_budget']==1 and task['retries_allowed'] is False
    prompt=ROOT/task['prompt_path'];text=prompt.read_text(encoding='utf-8')
    assert sha(prompt)=='2d644db69a7c1cd3a80db5a2e1399e841dbae8c88696b37cee45b814628c3e78'
    shared=renderer.load_yaml(renderer.SHARED_FILE)
    registered=renderer.render_template(task['template'],task['vars'],shared)
    # Existing convention: exact full prompt_path, not the registration shorthand,
    # is the Root builtin prompt. Render that through the SAME public template too.
    expanded=renderer.render_template(task['template'],{**task['vars'],'asset_prompt':text},shared)
    assert registered['prompt']==task['vars']['asset_prompt'].strip()
    assert expanded['prompt']==text.strip()
    assert expanded['background']=='opaque'
    refs=[]
    for s in task['reference_images']:
        p=ROOT/s;assert p.exists()
        refs.append({'path':s,'absolute_path':str(p),'sha256':sha(p)})
    assert len(refs)==1 and refs[0]['sha256']=='6b3f1df48197625bac356e5bbc9df977c5cab713cc38643386417a9519eacf7f'
    assert not registered['reference_images'] and not expanded['reference_images']
    assert tasks.read_bytes()==before and tasks.stat().st_mtime_ns==beforetime
    assert not OUT.exists();OUT.mkdir()
    # Template has no declared refs; task-level edit input must stay explicit.
    metadata={'status':'ACTUAL_PUBLIC_RENDER_TEMPLATE_OFFLINE_PASS_NO_GENERATION','id':ident,'registered_skip_true_retained':True,'root_tasks_sha256':sha(tasks),'root_tasks_bytes':len(before),'renderer_path':'scripts/gen_assets.py','renderer_sha256':sha(ROOT/'scripts/gen_assets.py'),'template_path':str((renderer.TEMPLATES_DIR/(task['template']+'.yaml')).relative_to(ROOT)).replace('\\','/'),'template_sha256':sha(renderer.TEMPLATES_DIR/(task['template']+'.yaml')),'shared_sha256':sha(renderer.SHARED_FILE),'prompt_path':task['prompt_path'],'prompt_sha256':sha(prompt),'registered_render':registered,'expanded_full_prompt_render':expanded,'template_declared_reference_count':0,'task_level_EDIT_targets':refs,'builtin_args':{'prompt':expanded['prompt'],'referenced_image_paths':[refs[0]['absolute_path']],'transparent_background':False},'omit_num_last_images_to_include':True,'prior_cli_attempt':{'evidence':'ROOT_REPORTED_ORIGINAL_OUTPUT_NOT_REPLAYED','command':'python scripts/gen_assets.py --task '+ident+' --dry-run --skip-ping','output':'没有匹配的任务','cause':'skip:true task excluded by public CLI filter; exit0/no-match is not template dry-render success','original_log_modified':False},'model':None,'provider':None,'cost':None,'network_calls':0,'generation_calls':0,'PNG_edits':0,'Godot_calls':0,'root_tasks_changed':False,'old_logs_changed':False}
    dump(OUT/'metadata.json',metadata)
    with (OUT/'expanded_prompt.txt').open('xb') as f: f.write((expanded['prompt']+'\n').encode())
    with (OUT/'registered_shorthand_prompt.txt').open('xb') as f: f.write((registered['prompt']+'\n').encode())
    print(json.dumps({'status':metadata['status'],'metadata_path':str((OUT/'metadata.json').relative_to(ROOT)),'metadata_sha256':sha(OUT/'metadata.json'),'expanded_prompt_sha256':sha(OUT/'expanded_prompt.txt'),'registered_shorthand_sha256':sha(OUT/'registered_shorthand_prompt.txt'),'root_tasks_sha256':sha(tasks),'network_calls':0,'generation_calls':0,'root_tasks_changed':False},ensure_ascii=False))
if __name__=='__main__':main()
