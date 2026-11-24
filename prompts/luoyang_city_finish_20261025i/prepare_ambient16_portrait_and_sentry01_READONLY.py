"""Freeze only review artifacts; never generate images or edit root tasks."""
import hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def resolved(p): return ROOT/('game/'+p[6:] if p.startswith('res://') else p)
contract=ROOT/'game/build/luoyang_city_finish_20261025i_system01/ambient16_actor_contract01_NOTREADY.json'
data=json.loads(contract.read_text(encoding='utf-8-sig'))
rows=[]
young={'harbour_life_gate_patrol_west','harbour_life_gate_patrol_east','district_life_market_patrol'}
old={'harbour_life_docks_quay_patrol','district_life_yamen_west_patrol'}
sentries={'harbour_life_gate_check_assistant','district_life_yamen_guard'}
for r in data['rows']:
    q={k:r[k] for k in ('npc_id','npc_name','scene_id','sprite_path','walk_sprite_path','portrait_path')}
    q['sprite_sha256']=sha(resolved(r['sprite_path']))
    if r['npc_id'] in young|old:
        family='young_bluegrey' if r['npc_id'] in young else 'veteran_ochre'
        q.update(status='NEW_SAME_PERSON_PORTRAIT_CANDIDATE_NOT_BOUND',candidate_path='assets/raw/luoyang_city_finish_20261025i/guard_'+family+'_portrait_v1.png')
        q['candidate_sha256']=sha(resolved(q['candidate_path']))
    elif r['npc_id'] in sentries:
        assert r['sprite_path']==r['portrait_path']
        q.update(status='BUG_FULL_BODY_SPRITE_IS_NOT_A_DIALOGUE_PORTRAIT',candidate_path=None,shared_missing_portrait_family='young_spear_sentry_19y')
    else:
        q.update(status='EXISTING_MATURE_SAME_FAMILY_PORTRAIT_REUSABLE',portrait_sha256=sha(resolved(r['portrait_path'])))
    rows.append(q)
ss=[r for r in rows if r['npc_id'] in sentries]
assert len({r['sprite_sha256'] for r in ss})==1
report={'status':'READONLY_RESOURCE_IDENTITY_NOT_RUNTIME_OR_GENERATION_APPROVAL','contract_path':str(contract.relative_to(ROOT)),'contract_sha256':sha(contract),'existing_mature_matching_count':9,'new_walk_family_portrait_candidates':5,'actual_fullbody_portrait_bugs':2,'new_sentry_portrait_assets_required':1,'rows':rows,'limits':['Two sentry consumers share exact sprite SHA; one new same-person portrait only.','No generic young protagonist fallback.','Merchant/farmer reuse is same art family, not sixteen distinct faces.','Five new portraits are not adopted simply because files exist.']}
out=OUT/'ambient16_portrait_identity01_READONLY.json'
assert not out.exists()
out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
prompt=ROOT/'prompts/luoyang_city_finish_20261025i/young_spear_sentry_portrait_v1_edit.txt'
root_tasks=ROOT/'prompts/tasks.yaml'
text=root_tasks.read_text(encoding='utf-8-sig')
anchor=text.splitlines()[-1]
entry='''

  - id: luoyang_20261025i_young_spear_sentry_portrait_v1_edit
    template: luoyang_innkeeper_portrait_text_20261025h
    execution_backend: builtin_image_gen
    skip: true
    attempt_budget: 1
    retries_allowed: false
    cli_fallback_allowed: false
    model: null
    provider: null
    cost: null
    transparent_background: false
    prompt_path: prompts/luoyang_city_finish_20261025i/young_spear_sentry_portrait_v1_edit.txt
    reference_images: [game/art/characters/luoyang_soldier_diversity_20261019y/npc_escort_guard_luoyang_young_gate_sentry_idle_down_1f_y1_runtime.png]
    vars:
      asset_prompt: "IDENTITY-PRESERVE EDIT the existing19y young spear sentry into ONE opaque square ordinary head/chest portrait. Keep source cap/bluegrey uniform/dull lamellar armor and modest ordinary face, not newwaistdao soldier. One exact same sprite family servesGatecheck/Yamenguard. No beautification/UI/text/fullbody. Root view raw first; use referenced_image_paths only, omit num_last_images_to_include."
'''
patch='*** Begin Patch\n*** Update File: F:/Code/RPG_GAME/prompts/tasks.yaml\n@@\n '+anchor+'\n'+''.join('+'+s+'\n' for s in entry.splitlines())+'*** End Patch\n'
patchpath=OUT/'sentry_portrait01_ROOT_ONLY.apply_patch'
assert not patchpath.exists()
patchpath.write_text(patch,encoding='utf-8')
dry={'status':'TASK_APPEND_CANDIDATE_ONLY_NOT_APPLIED_NOT_GENERATED','root_tasks_sha256':sha(root_tasks),'root_tasks_bytes':root_tasks.stat().st_size,'exact_EOF_anchor_count':text.count(anchor),'template_present':'luoyang_innkeeper_portrait_text_20261025h' in text,'task_id_already_present':'luoyang_20261025i_young_spear_sentry_portrait_v1_edit' in text,'prompt_path':str(prompt.relative_to(ROOT)),'prompt_sha256':sha(prompt),'edit_target_path':str(resolved(ss[0]['sprite_path']).relative_to(ROOT)),'edit_target_sha256':ss[0]['sprite_sha256'],'patch_sha256':sha(patchpath),'builtin_args':{'transparent_background':False,'referenced_image_paths':[str(resolved(ss[0]['sprite_path']))]},'omit_num_last_images_to_include':True,'save_new_raw_only':'assets/raw/luoyang_city_finish_20261025i/young_spear_sentry_portrait_v1.png','model':None,'provider':None,'cost':None,'calls_by_this_agent':0,'same_family_two_IDs':list(sentries)}
assert dry['exact_EOF_anchor_count']==1 and dry['template_present'] and not dry['task_id_already_present']
(OUT/'sentry_portrait01_TASK_DRYRUN.json').write_text(json.dumps(dry,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'identity_sha256':sha(out),'prompt_sha256':sha(prompt),'patch_sha256':sha(patchpath),'dryrun':dry},ensure_ascii=False))
