"""Only existing project renderer dry-run; no image/API/import call."""
from pathlib import Path
import hashlib, importlib.util, json

ROOT=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
TASK='luoyang_20261025h_innkeeper_portrait_v1'
def sha(raw): return hashlib.sha256(raw).hexdigest()
spec=importlib.util.spec_from_file_location('portrait25h_existing_renderer',ROOT/'scripts/gen_assets.py')
gen=importlib.util.module_from_spec(spec); spec.loader.exec_module(gen)
raw=(ROOT/'prompts/tasks.yaml').read_bytes()
marker=b'\n  - id: luoyang_20261025h_innkeeper_portrait_v1'
assert raw.count(marker)==1
assert sha(raw[:raw.index(marker)])=='3e349acf6b846484e94cd19e7a0da75fb8b65360ee1130cf99d4d4c650457ea3'
queue=gen.load_yaml(ROOT/'prompts/tasks.yaml')
tasks=queue['tasks'] if isinstance(queue,dict) else queue
rows=[r for r in tasks if r['id']==TASK]; assert len(rows)==1
task=rows[0]
assert task['skip'] is True and task['execution_backend']=='builtin_image_gen' and task['attempt_budget']==1 and task['retries_allowed'] is False and task['cli_fallback_allowed'] is False and task['transparent_background'] is False
prompt=(ROOT/task['prompt_path']).read_text(encoding='utf-8')
rendered=gen.render_template(task['template'],{'asset_prompt':prompt},gen.load_yaml(gen.SHARED_FILE))
assert rendered['prompt']==prompt.strip() and rendered['background']=='opaque' and rendered['size']=='1024x1024'
references={
 'game/art/characters/npc_zhuwei_innkeeper_v1_idle_down_25d_4f.png':'1bcd177ab5bedc88f115438327f93e5ad1a5aaa3ab29c328b5dc11fc7873ac7c',
 'game/art/characters/portraits/portrait_linxi_farmer_v1.png':'a4d9b9aa249007f7608ebc11f5252936c445f5e7b471530263992b30e0d59335',
}
assert [str(p.relative_to(ROOT)).replace('\\','/') for p in rendered['reference_images']]==list(references)
for path,expected in references.items(): assert sha((ROOT/path).read_bytes())==expected
assert not (ROOT/'assets/raw/luoyang_indoor_services_20261025h'/f'{TASK}.png').exists()
report={
 'status':'BUILTIN_ONE_NEW_OPAQUE_PORTRAIT_REGISTERED_AND_DRY_RENDERED_NOT_GENERATED',
 'task_id':TASK,'task_table_sha256':sha(raw),'old_task_prefix_sha256':'3e349acf6b846484e94cd19e7a0da75fb8b65360ee1130cf99d4d4c650457ea3','old_task_prefix_preserved':True,
 'prompt_path':task['prompt_path'],'prompt_file_sha256':sha((ROOT/task['prompt_path']).read_bytes()),'rendered_prompt':rendered['prompt'],'rendered_prompt_sha256':sha(rendered['prompt'].encode()),
 'template_path':f"prompts/templates/{task['template']}.yaml",'template_sha256':sha((gen.TEMPLATES_DIR/f"{task['template']}.yaml").read_bytes()),
 'reference_sha256':references,'reference_roles':['character-and-outfit only, four-frame strip is not output composition','painted portrait style only, not face/clothes identity'],
 'requested_square':True,'requested_opaque':True,'builtin_transparent_background':False,'registration_size_not_tool_actual_dimensions':'1024x1024',
 'planned_raw_png':f'assets/raw/luoyang_indoor_services_20261025h/{TASK}.png','planned_meta':f'assets/raw/luoyang_indoor_services_20261025h/{TASK}.meta.json',
 'model':None,'provider':None,'cost':None,'generation_calls':0,'CLI_calls':0,'API_calls':0,'Godot_calls':0,'PNG_edits':0,'source_images_unchanged':True,
 'Root_sole_builtin_generation':True,'must_update_playbook_when_asset_lands':'NEW template registry reference only; no old prompt/template changed',
}
out=HERE/'innkeeper_portrait_v1_dryrun_meta_plan.json'
encoded=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f: f.write(encoded)
print(json.dumps({'passed':True,'path':str(out),'sha256':sha(encoded),'task_sha256':sha(raw),'prompt_sha256':report['prompt_file_sha256'],'generation_calls':0}))
