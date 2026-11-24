"""Offline final-media selector. No engine, source collector, or new authority."""
from pathlib import Path
import json,re,struct,hashlib
G=Path(__file__).resolve().parents[2]
N=Path(__file__).resolve().parent
load=lambda p:json.loads((G/p[6:]).read_text(encoding='utf8'))
sha=lambda b:hashlib.sha256(b).hexdigest()
I=load('res://build/luoyang_regions_20261027d_source01/terminal_market_residual03_input_NOTREADY.json')
available=I['available_parent_sources']; logical='ch4_s3_luoyang_market'
reader=(G/'build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
scope={'struct':struct};exec(reader[reader.index('class FrozenVariant:'):reader.index('binding_pin=')],scope)
packet_path='res://build/luoyang_city_revision_20261024b_root01/market_detours06_READY/output/packet.bin'
packet_bytes=(G/packet_path[6:]).read_bytes()
assert packet_path in available and sha(packet_bytes)==available[packet_path]
packet=scope['FrozenVariant'](packet_bytes).value()
rows=packet['scene_storage']['fields']['npcs']['array_values']
assert len(rows)==8
rows=[dict(r)for r in rows]
artisan=load('res://data/luoyang_city_tasks_20261016/overlay.json')['market']['artisan']
rows.append({k:artisan[k]for k in ['npc_id','sprite_path','portrait_path']})
dg=(G/'scripts/city/luoyang_district_life_crowd_20261016f.gd').read_text(encoding='utf8')
constants=dict(re.findall(r'const (\w+)="(res://[^"\n]+)"',dg))
idles={'merchant':constants['MERCHANT_IDLE'],'guard':constants['GUARD_IDLE'],'farmer':constants['FARMER'],'waiter':constants['WAITER'],'vendor':constants['VENDOR']}
crowd=load('res://data/maps/luoyang_district_life_20261016f/author.json')['districts'][logical]['crowd']
for r in crowd:
 rows.append({'npc_id':'district_life_'+r['id'],'sprite_path':idles[r['family']],'walk_sprite_path':('GUARD_WALK'if r['family']=='guard'else'MERCHANT_WALK')if r['distance_px']>0 else''})
for r in rows:
 if r.get('walk_sprite_path') in constants:r['walk_sprite_path']=constants[r['walk_sprite_path']]
presentation=load('res://build/luoyang_city_full_rollout_20261022ap_npc01/author.json')
for change in presentation['visual_rows']:
 if change['scene_id']==logical:
  row=next(r for r in rows if r['npc_id']==change['npc_id']);row.update(change['patch'])
# Catalog has no Market native/crowd IDs; assert this instead of assuming no overrides.
catalog=(G/'data/npcs/npc_catalog.tres').read_text(encoding='utf8')
profiles=re.split(r'\[sub_resource[^\n]+\]',catalog)[1:]
for block in profiles:
 ident=re.search(r'npc_id = &"([^"]+)"',block)
 if ident and ident[1] in [r['npc_id']for r in rows]:
  scenes=re.search(r'scene_ids = \[([^\n]+)\]',block)
  assert scenes and logical not in scenes[1],ident[1]
conversation=(G/'build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd').read_text(encoding='utf8')
fallback=dict(re.findall(r'"(res://[^"\n]+\.png)": "(res://[^"\n]+\.png)"',conversation))
for row in rows:
 if not row.get('portrait_path'):row['portrait_path']=fallback.get(row['sprite_path'],'')
 if row['npc_id']=='spar_luoyang_examiner':row['portrait_path']='res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png'
 if row['npc_id']=='luoyang_paper_scholar':
  row['sprite_path']='res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png'
  row['portrait_path']='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png'
visual=load('res://build/luoyang_city_finish_20261025i_system01/ambient18_visual_contract02_NOTREADY.json')
for change in visual['actor_overrides']:
 if change['before']['scene_id']==logical:
  row=next(r for r in rows if r['npc_id']==change['npc_id'])
  for k in ['sprite_path','walk_sprite_path','portrait_path']:
   if k=='portrait_path'or change['walker']:row[k]=change['after'][k]
payload_path=I['bindings'][0]['payload']['path']
payload=scope['FrozenVariant']((G/payload_path[6:]).read_bytes()).value()
assert payload['new_NPCs']==[]
# No bounty location targets Market; future bounty state cannot add a missed media row.
bounty_files=list((G/'data/bounties').glob('*.tres'))
assert all(logical not in p.read_text(encoding='utf8')for p in bounty_files)
history_path='res://build/joint_world_luoyang_20261003_qa/424_luoyang_full_source_inventory_20261009/source_inventory.json'
history=load(history_path)
hist={'res://'+r['project_relative'][5:]:r['sha256'].lower()for r in history['sources']if r.get('project_relative','').startswith('game/')}
media={}
for row in rows:
 for key in ['sprite_path','portrait_path','walk_sprite_path']:
  path=row.get(key,'')
  if path:media.setdefault(path,[]).append(row['npc_id']+'/'+key)
missing=[]
for path,actors in sorted(media.items()):
 side=path+'.import';text=(G/side[6:]).read_text(encoding='utf8');remap=re.search(r'path="(res://[^"\r\n]+\.ctex)"',text)[1]
 absent=[p for p in [path,side,remap]if p not in available]
 if absent:
  missing.append({'png':path,'actors':actors,'missing_stage_leaves':absent,'historical_tuple':{p:hist.get(p)for p in [path,side,remap]},'historical_current_exact':{p:sha((G/p[6:]).read_bytes())==hist[p]if p in hist else None for p in [path,side,remap]}})
print(json.dumps({'scope':'STATIC_MARKET_COMPLETE_8_NATIVE_PLUS_TASK_PLUS_DG_FINAL_MEDIA_NOT_OWNER_CREDIT','actors':[{k:r.get(k,'')for k in ['npc_id','sprite_path','portrait_path','walk_sprite_path']}for r in rows],'unique_media_count':len(media),'missing':missing,'history':{'path':history_path,'sha256':sha((G/history_path[6:]).read_bytes())},'new_NPCs':0,'bounty_market_locations':0,'no_engine':True,'no_current_hash_authority_fill':True},ensure_ascii=True,indent=2))
