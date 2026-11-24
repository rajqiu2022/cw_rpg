"""Archive independent finite portrait review; no image/source mutations."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):
    with p.open('xb') as f:f.write((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
raw=ROOT/'assets/raw/luoyang_city_finish_20261025i/young_spear_sentry_portrait_v1.png'
before=raw.read_bytes();stamp=raw.stat().st_mtime_ns
assert sha(raw)=='6c62528350aca92de039e2eabd901519f0ad7f0da5f122536552472c05c3372e'
with Image.open(raw) as image:
    mode=image.mode;rgba=image.convert('RGBA');size=list(rgba.size);alpha=list(rgba.getchannel('A').getextrema());pixels=hashlib.sha256(rgba.tobytes()).hexdigest()
assert size==[1254,1254] and alpha==[255,255]
parent=OUT/'ambient16_portrait_identity01_READONLY.json'
old=json.loads(parent.read_bytes());sentry_ids=['harbour_life_gate_check_assistant','district_life_yamen_guard']
sprite=ROOT/'game/art/characters/luoyang_soldier_diversity_20261019y/npc_escort_guard_luoyang_young_gate_sentry_idle_down_1f_y1_runtime.png'
assert sha(sprite)=='6b3f1df48197625bac356e5bbc9df977c5cab713cc38643386417a9519eacf7f'
prompt=ROOT/'prompts/luoyang_city_finish_20261025i/young_spear_sentry_portrait_v1_edit.txt'
metadata={'status':'BUILTIN_RAW_EDIT_FINITE_ART_PASS_NOT_IMPORTED_OR_BOUND','task_id':'luoyang_20261025i_young_spear_sentry_portrait_v1_edit','generation_tool':'builtin_image_gen','actual_call_count_Root_reported':1,'model':None,'provider':None,'cost':None,'tool_return_fields_Root_reported':['image_url','output_hint'],'original_builtin_output_path':'C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/exec-fce42b19-02d4-4ae8-b2b2-9c163733331d.png','original_output_retained_Root_reported':True,'raw_path':raw.relative_to(ROOT).as_posix(),'raw_sha256':sha(raw),'raw_bytes':len(before),'raw_mode':mode,'raw_size':size,'raw_RGBA_sha256':pixels,'alpha_extrema':alpha,'prompt':{'path':prompt.relative_to(ROOT).as_posix(),'sha256':sha(prompt)},'edit_target':{'path':sprite.relative_to(ROOT).as_posix(),'sha256':sha(sprite),'role':'Exact existing160 whole-body spear sentry transformed to dialogue portrait; not newwaistdao youth'},'intended_npc_ids':sentry_ids,'independent_ART_view':{'raw_personally_viewed':True,'finite_approval':True,'observed':'One complete dark fitted cloth cap, naturally young face without idol ornament, greyblue robe/collar, weathered dull brown-grey lamellar chest/shoulders, existing spear at edge, opaque defocused gate backdrop. No UI frame, text, extra person or borrowed protagonist face.','identity_limit':'160 source does not prove microscopic facial identity; acceptance is same existing costume/weapon/age family, not biometric equality. Face is naturally clear young skin, not evidence of a separate celebrity identity.','crop_limit':'Head and cap complete, shoulders/chest intentionally portrait-framed; opaque portrait has no transparent10percent requirement.'},'local_image_processing':0,'PNG_edits':0,'Godot_calls':0,'imports':0,'formal_enabled':False}
meta=OUT/'four_identity_meta_ARCHIVE/young_spear_sentry_portrait_v1.meta.json';save(meta,metadata)
successor=json.loads(parent.read_bytes())
successor.update(status='READONLY_RESOURCE_IDENTITY02_WITH_NEW_SHARED_SPEAR_SENTRY_CANDIDATE_NOT_RUNTIME',parent_path=parent.relative_to(ROOT).as_posix(),parent_sha256=sha(parent),actual_fullbody_portrait_bugs_still_formal=2,actual_fullbody_portrait_bugs=2,new_sentry_portrait_assets_required=0,new_sentry_portrait_candidate_count=1,new_sentry_portrait_candidate_consumers=2,formal_bindings_changed=0)
successor['limits'].append('The two formal full-body portrait paths remain bugs until Root imports/binds this exact shared candidate; availability is not adoption.')
for row in successor['rows']:
    if row['npc_id'] in sentry_ids:
        row.update(status='NEW_SHARED_SAME_FAMILY_SPEAR_SENTRY_PORTRAIT_CANDIDATE_NOT_BOUND',candidate_path=raw.relative_to(ROOT).as_posix(),candidate_sha256=sha(raw),candidate_meta_path=meta.relative_to(ROOT).as_posix(),candidate_meta_sha256=sha(meta))
        row['previous_actual_portrait_is_fullbody_sprite']=True
assert raw.read_bytes()==before and raw.stat().st_mtime_ns==stamp
mapping=OUT/'ambient16_portrait_identity02_READONLY.json';save(mapping,successor)
print(json.dumps({'metadata':meta.relative_to(ROOT).as_posix(),'metadata_sha256':sha(meta),'mapping':mapping.relative_to(ROOT).as_posix(),'mapping_sha256':sha(mapping),'raw_RGBA_sha256':pixels,'alpha_extrema':alpha,'root_tasks_sha256':sha(ROOT/'prompts/tasks.yaml'),'no_PNG_changes':True}))
