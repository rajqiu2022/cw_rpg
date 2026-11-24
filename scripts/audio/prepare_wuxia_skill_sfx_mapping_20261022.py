"""Exact active-skill proposal and explicit derived SFX signatures; never applies.

Basic attack is resolved at the actor cue from equipped weapon context, because
the current controller intentionally skips _arm_skill_strike_audio for it.
"""
from pathlib import Path
import argparse, collections, hashlib, json, re
import numpy as np
from scipy.signal import butter,sosfilt
from produce_wuxia_stable_trial import decode
from produce_wuxia_sfx_bank_20261022 import pcm,rec,SR

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/processed/audio/wuxia_voice_sfx_expansion_20261022'
INVENTORY=ROOT/'assets/processed/audio/wuxia_expansion_qa_20261022/skill_audio_bindings_detailed.json'
SIGNATURES={
 'dagger_air_cast':[('jian_thrust_standard',.85,0)],
 'dagger_body_contact':[('fist_contact_standard',.60,0),('dart_throw_standard',.20,.025)],
 'healing_breath':[('qi_gather_standard',.65,0)],
 'guard_breath':[('qi_gather_standard',.6,0),('sleeve_ready_standard',.30,.04)],
 'poison_needle_contact':[('fist_contact_standard',.30,0),('dart_wood_standard',.12,.02)],
 'redirect_sleeve':[('sleeve_ready_standard',.65,0),('qi_gather_standard',.25,.04)],
 'sword_body_contact':[('fist_contact_standard',.65,0),('jian_light_cut_standard',.25,.015)],
 'blade_body_contact':[('kick_contact_standard',.7,0),('dao_chop_standard',.25,.01)],
 'staff_body_contact':[('palm_push_standard',.65,0),('staff_contact_standard',.30,.01)],
 'palm_air_cast':[('sleeve_ready_standard',.65,0),('qi_release_standard',.25,.015)],
}
EQUIPMENT={
 'sword':('jian_light_cut_standard','sword_body_contact'),
 'blade':('dao_chop_standard','blade_body_contact'),
 'staff':('staff_swing_standard','staff_body_contact'),
 'palm':('palm_air_cast','fist_contact_standard'),
 'hidden':('dart_throw_standard','poison_needle_contact'),
 'dagger':('dagger_air_cast','dagger_body_contact'),
}


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def fresh(p,d):
 with p.open('x',encoding='utf-8') as f:json.dump(d,f,ensure_ascii=False,indent=2)


def plan():
 inventory=json.loads(INVENTORY.read_text(encoding='utf-8'));rows=[];passives=[]
 for r in inventory['skills']:
  p=ROOT/r['file'];source=p.read_text(encoding='utf-8')
  if r['passive']:passives.append({'id':r['id'],'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p),'reason':'Passive resource, no active cast/impact emission invented'});continue
  sid=r['id'];kind=int(r['kind_authored']) if r['kind_authored'].isdigit() else 0
  effect=re.sub(r'[^a-z_]','',r['active_effect_type_authored'])
  family=r['weapon'] or r['martial_category'];reason='explicit weapon, then authored martial_category'
  if sid=='basic_attack':
   cast=None;impact=None;family='equipment_context';reason='actual actor attack cue; current skill-arm intentionally skips basic_attack'
  elif sid in ['heavy_swing','gufeng_kaishan_yidao']:
   family='blade';cast,impact=EQUIPMENT[family];reason='read actual description: dao chopping skill despite empty required_weapon_type'
  elif sid=='wolf_rending_bite':
   family='animal_source_pending';cast=None;impact=None;reason='Wolf bite needs species-appropriate source. Human robe/shoe/kick events are not approved substitutes; retain existing runtime handling until separate source is available.'
  elif sid=='defend':
   family='guard';cast='sleeve_ready_standard';impact=None;reason='stance activation, not proof of a weapon collision/parry'
  elif kind==1 or effect in ['heal','heal_guard']:
   family='healing';cast='healing_breath';impact=None;reason='heal/guard support, no damaging contact sound'
  elif effect in ['burst','initiative']:
   family='lightness';cast='lightstep_dash_textured';impact=None;reason='mobility/initiative stance, no damaging contact sound'
  elif effect=='redirect':
   family='redirect';cast='redirect_sleeve';impact=None;reason='redirect preparation; eventual redirected strike keeps actual incoming weapon semantics'
  elif kind==2:
   family='internal_guard' if sid in ['cold_ridge_guard_breath','gufeng_jingang_buhuai','wudang_xuanwu_ge'] else 'internal_focus'
   cast='guard_breath' if family=='internal_guard' else 'qi_gather_textured';impact=None;reason='read active buff/inner-art semantics, not generic palm damage'
  elif family=='dagger':cast,impact=EQUIPMENT['dagger']
  elif family=='hidden':
   cast='needles_release_standard' if sid in ['blood_shadow_scattering_darts','ch8_su_teapot_meridian_rain','mingwu_wuyin_sanshi'] else 'dart_throw_standard'
   impact='poison_needle_contact';reason='hidden/ranged projectile cue, not fist fallback; poison indication is an explicitly designed contact'
  elif family in EQUIPMENT:
   cast,impact=EQUIPMENT[family]
   if family=='sword':cast='jian_thrust_standard' if sid in ['shadow_swallow_piercing_sword','huashan_poyun','qinghe_swallow_sword'] else 'jian_heavy_cut_textured' if 'kind = 0' in source and r['quality_authored']=='4' else 'jian_light_cut_standard'
   if family=='blade':cast='dao_sweep_textured' if r['target_authored']=='1' else 'dao_chop_standard'
   if family=='staff':cast='spear_thrust_standard' if sid=='lingyue_lingbo_yizhi' else 'staff_swing_textured'
   if family=='palm':cast='qi_release_textured' if r['damage_type_authored']=='1' else 'palm_air_cast'
  else:raise ValueError('Unclassified active skill: '+sid)
  rows.append({'skill_id':sid,'display_name':r['name'],'skill_path':p.relative_to(ROOT).as_posix(),'skill_sha256':sha(p),
   'required_weapon_type':r['weapon'],'martial_category':r['martial_category'],'kind':r['kind_authored'],'target':r['target_authored'],'delivery':r['delivery_authored'],'active_effect_type':r['active_effect_type_authored'],
   'proposed_family':family,'cast_asset_id':cast,'impact_asset_id':impact,'rationale':reason,'existing_cast_path':r['cast_explicit'],'existing_impact_path':r['impact_explicit'],
   'application':'UNAPPLIED catalog or per-skill override; basic_attack requires actual actor equipment hook',
   'impact_gate':'Only confirmed damaging contact, no clang on generic body contact and no impact on miss/support activation'})
 if len(rows)!=57 or len(passives)!=10:raise ValueError('Actual skill inventory cardinality changed')
 sharing=collections.defaultdict(list)
 for r in rows:
  for key in ['cast_asset_id','impact_asset_id']:
   if r[key]:sharing[r[key]].append({'skill_id':r['skill_id'],'cue':key})
 doc={'status':'PROPOSED_NOT_APPLIED_ASSETS_PENDING','skills':rows,'passives_not_given_active_sounds':passives,
  'basic_attack_equipment_families':{k:{'cast_asset_id':v[0],'impact_asset_id':v[1]} for k,v in EQUIPMENT.items()},
  'shared_assets':dict(sharing),'derived_signature_recipes':SIGNATURES,'inventory':rec(INVENTORY),
  'reserved_collision_only':['steel_parry_standard','wooden_guard_standard','arm_guard_standard'],
  'notes':['No basic_attack.cast_sfx_path-only patch: it is bypassed by actual skill-arm.',
   'Future actor attack cue must use the current ally/enemy unit and equipped normalized weapon; preserve explicit enemy-owned cues.',
   'required dagger wins over martial_category hidden; other hidden skills use projectile semantics.',
   'Guard activation is sleeve movement, not a successful parry. Parry/collision cues stay reserved until an actual collision hook exists.',
   'All proposed integration must recheck source hashes and asset hashes; this file changes no current gameplay.']}
 doc['supersedes_proposal_sha256']=sha(OUT/'skill_sfx_mapping_proposed.json')
 doc['animal_unmapped_pending']=['wolf_rending_bite']
 doc['script']=rec(Path(__file__))
 fresh(OUT/'skill_sfx_mapping_reviewed.json',doc)
 print('SKILL_MAPPING',len(rows),'active',len(passives),'passive',len(sharing),'shared assets',flush=True)


def signatures():
 manifest=json.loads((OUT/'sfx/manifest.json').read_text(encoding='utf-8'))
 sources={v['id']:v['output'] for b in manifest['sources'] for v in b['variants']};outputs=[]
 for sid,recipe in SIGNATURES.items():
  layers=[];total=0;records=[]
  for key,gain,delay in recipe:
   source=ROOT/sources[key]['path']
   if sha(source)!=sources[key]['sha256']:raise ValueError('Source changed')
   x=decode(source).astype(np.float32);offset=round(delay*SR);layers.append((x*gain,offset));total=max(total,x.shape[1]+offset)
   records.append({'source':rec(source),'gain':gain,'offset_frames':offset})
  y=np.zeros((2,total),dtype=np.float32)
  for x,offset in layers:y[:,offset:offset+x.shape[1]]+=x
  if sid in ['healing_breath','guard_breath']:
   y=sosfilt(butter(2,[180,2200],btype='bandpass',fs=SR,output='sos'),y,axis=1).astype(np.float32)
   fade=min(round(.12*SR),total//3);y[:,:fade]*=np.linspace(0,1,fade);y[:,-fade:]*=np.linspace(1,0,fade)
  info,_=pcm(OUT/'sfx/signatures'/(sid+'.wav'),y)
  outputs.append({'id':sid,'method':'transparent deterministic mix of named generated events, not an independent model take','layers':records,'filter':'2nd-order bandpass 180..2200 Hz and120ms envelope' if sid in ['healing_breath','guard_breath'] else None,**info})
 copy=[]
 all_assets=[{'id':v['id'],'record':v['output']} for b in manifest['sources'] for v in b['variants']]+[{'id':r['id'],'record':r['output']} for r in outputs]
 for r in all_assets:copy.append({'id':r['id'],'source':r['record'],'target':'game/art/audio/sfx/wuxia_20261022/'+r['id']+'.wav','precondition':'TARGET_ABSENT and SHA_MATCH before future copy','applied':False})
 fresh(OUT/'sfx/signature_manifest.json',{'status':'GENERATED_CANDIDATE_NOT_APPLIED','independent_model_takes':24,'event_variants':48,'derived_signatures':len(outputs),'sources':outputs,'copy_plan':copy,'script':rec(Path(__file__))})
 print('SIGNATURES',len(outputs),'COPY_ASSETS',len(copy),flush=True)


if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--mode',choices=['plan','signatures'],required=True);a=ap.parse_args()
 if a.mode=='plan':plan()
 else:signatures()
