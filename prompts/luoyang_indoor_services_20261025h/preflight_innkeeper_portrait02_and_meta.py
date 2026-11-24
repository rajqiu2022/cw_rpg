"""Read-only source/prompt/image QA; save NEW JSON records only, no image rewrite."""
from pathlib import Path
import hashlib, importlib.util, json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
TASK='luoyang_20261025h_innkeeper_portrait_v2_textonly'
PNG='game/art/characters/portraits/luoyang_services_20261025h/portrait_innkeeper_v1.png'
GENERATED=Path('C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/exec-efb427a1-7c03-4690-965e-8ef0bf8b9718.png')
EXPECTED='c544c5cc1e9d1f3b587eae4d49565c961bc3f6cb2d11a95424b66ccd61f67969'
def sha(b):return hashlib.sha256(b).hexdigest()
def new(path,value):
    path.parent.mkdir(parents=True,exist_ok=True);raw=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
    with path.open('xb') as f:f.write(raw)
    return dict(path=str(path.relative_to(ROOT)).replace('\\','/'),sha256=sha(raw))
spec=importlib.util.spec_from_file_location('inn25h_existing_renderer',ROOT/'scripts/gen_assets.py');gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen)
table=(ROOT/'prompts/tasks.yaml').read_bytes();marker=b'\n  - id: luoyang_20261025h_innkeeper_portrait_v2_textonly';assert table.count(marker)==1
at=table.index(marker);prefix=table[:at];append=table[at:]
assert sha(prefix)=='0d3470b64661e961ea41b23b051653b899e4e89702fd5958cd37175377cbf28c'
queue=gen.load_yaml(ROOT/'prompts/tasks.yaml');tasks=queue['tasks'] if isinstance(queue,dict) else queue
task=[r for r in tasks if r['id']==TASK];assert len(task)==1;task=task[0]
prompt=(ROOT/task['prompt_path']).read_text(encoding='utf-8')
render=gen.render_template(task['template'],{'asset_prompt':prompt},gen.load_yaml(gen.SHARED_FILE))
assert render['prompt']==prompt.strip() and render['background']=='opaque' and not render['reference_images'] and not task['reference_images'] and task['skip'] is True
assert 'reference image' not in prompt.lower() and 'input images:' not in prompt.lower()
dry=new(HERE/'innkeeper_portrait_v2_textonly_dryrun.json',dict(status='TEXTONLY_BUILTIN_DRY_RENDER_PASS_NO_EXTRA_GENERATION',task_id=TASK,prompt_path=task['prompt_path'],prompt_sha256=sha((ROOT/task['prompt_path']).read_bytes()),rendered_prompt=render['prompt'],rendered_prompt_sha256=sha(render['prompt'].encode()),tool_reference_parameters_must_be_omitted=True,opaque=True,requested_square=True,old_v1_task_prefix_sha256=sha(prefix),task_table_sha256=sha(table),append_text=append.decode(),reverse_remove_exact_suffix=append.decode(),exact_append_forward_reverse=(table[:-len(append)]==prefix),generation_calls_by_this_script=0))
png=(ROOT/PNG).read_bytes();assert sha(png)==EXPECTED and GENERATED.read_bytes()==png
before=(ROOT/PNG).stat()
image=Image.open(ROOT/PNG);image.load();rgba=image.convert('RGBA');data=rgba.tobytes();assert image.size[0]==image.size[1] and rgba.getchannel('A').getextrema()==(255,255)
metadata=dict(status='BUILTIN_RAW_IMAGE_ORIGINAL_BYTES_BASIC_QA_LOCAL_ROLE_ADMITTED_NOT_IMPORTED',task_id=TASK,generation_intent='NEW_DESCRIPTIVE_TEXT_ONLY_NOT_EDIT',generation_tool='builtin_image_gen',generation_calls_by_Root=1,model=None,provider=None,cost=None,prompt_path=task['prompt_path'],prompt_sha256=sha((ROOT/task['prompt_path']).read_bytes()),dryrun=dry,generated_path=str(GENERATED),workspace_png='res://'+PNG.removeprefix('game/'),png_sha256=EXPECTED,png_bytes=len(png),source_mode=image.mode,source_size=list(image.size),decoded_RGBA_sha256=sha(data),basic_QA=dict(square=True,opaque_all_pixels=True,alpha_extrema=[255,255],used_rect=list(rgba.getbbox()),source_image_bytes_unchanged=True,no_resize_padding_background_processing=True),visual_review='Single mature black-topknot short-bearded innkeeper; navy cloth and beige apron, friendly face, warm wood interior, no hat/travel cloak/weapon/text. Local role/style approved; no runtime/dialogue/import credit.',builtin_reference_paths_parameter_omitted=True,builtin_num_last_images_parameter_omitted=True,reference_images_used_in_call=[],PNG_edits=0,Godot_calls_by_this_script=0,imports_by_this_script=0)
meta=new(ROOT/'assets/raw/luoyang_indoor_services_20261025h/portrait_innkeeper_v1.meta.json',metadata)
after=(ROOT/PNG).stat();assert (before.st_size,before.st_mtime_ns)==(after.st_size,after.st_mtime_ns) and sha((ROOT/PNG).read_bytes())==EXPECTED
print(json.dumps(dict(passed=True,dryrun=dry,metadata=meta,size=list(image.size),RGBA_sha256=sha(data),png_sha256=EXPECTED,PNG_edits=0)))
