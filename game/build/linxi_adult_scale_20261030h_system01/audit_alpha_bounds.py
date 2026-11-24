"""Read existing PNG alpha only; no image edits, no engine and no save access."""
from pathlib import Path
import hashlib,json,re
from PIL import Image
BASE=Path(__file__).resolve().parent;GAME=BASE.parents[1]
IDS=['linxi_tutorial','linxi_village_center','linxi_village_scrollmap']
SMALL=['npc_zhuwei_gate_guard_','npc_zhuwei_inn_waiter_','npc_escort_guard_','npc_linxi_martial_hall_master_']
def sha(b):return hashlib.sha256(b).hexdigest()
def array(text,key):
 start=text.index('[',text.index(key+' ='))
 level=0;quoted=False;escape=False
 for i in range(start,len(text)):
  c=text[i]
  if escape:escape=False;continue
  if c=='\\' and quoted:escape=True;continue
  if c=='"':quoted=not quoted
  if quoted:continue
  if c=='[':level+=1
  if c==']':
   level-=1
   if level==0:return text[start:i+1]
 raise ValueError(key)
def rows(text):
 raw=array(text,'npcs');raw=re.sub(r'Vector2\(([^)]*)\)',r'[\1]',raw);raw=raw.replace('&"','"')
 raw=re.sub(r',\s*([}\]])',r'\1',raw)
 return json.loads(raw)
def exists(path):return path.startswith('res://') and (GAME/path[6:]).is_file()
def directional(npc,facing):
 explicit=npc.get('conversation_sprite_paths',{}).get(facing,'')
 if exists(explicit):return explicit
 authored={'left':'right','right':'left'}.get(facing,facing)
 candidates=[]
 for source in [npc.get('sprite_path',''),npc.get('walk_sprite_path','')]:
  direction=next((d for d in ['down','up','left','right'] if '_'+d+'_' in source),'')
  if not direction:continue
  path=source.replace('_'+direction+'_','_'+authored+'_')
  variants=[path]+[path.replace('_v%d_'%v,'_') for v in range(2,10) if '_v%d_'%v in path]
  for variant in variants:
   candidates.extend([variant,variant.replace('_idle_','_walk_')] if '_idle_' in variant else [variant.replace('_walk_','_idle_'),variant])
 return next((p for p in candidates if exists(p)),None)
cache={}
def bounds(path):
 if path in cache:return cache[path]
 full=GAME/path[6:];raw=full.read_bytes();im=Image.open(full).convert('RGBA');w,h=im.size
 frames=max(1,w//h) if w>h and h>0 else 1
 cell_w=w//frames;out=[]
 for i in range(frames):
  alpha=im.crop((i*cell_w,0,(i+1)*cell_w,h)).getchannel('A')
  b=alpha.getbbox();b8=alpha.point(lambda x:255 if x>8 else 0).getbbox()
  out.append({'frame':i,'a_gt_0_bbox':b,'a_gt_0_height':b[3]-b[1] if b else 0,'a_gt_8_height':b8[3]-b8[1] if b8 else 0})
 value={'path':path,'sha256':sha(raw),'size':[w,h],'hframes':frames,'frames':out,'node_calibrator_first_frame_height':out[0]['a_gt_0_height']}
 cache[path]=value;return value
catalog=(GAME/'data/npcs/npc_catalog.tres').read_text(encoding='utf-8')
catalog_ids=re.findall(r'^npc_id = &"([^"]+)"',catalog,re.M)
scenes=[]
for scene in IDS:
 path=GAME/'data/scenes'/f'{scene}.tres';raw=path.read_bytes();text=raw.decode();nodes=rows(text)
 match=re.search(r'^npc_visual_scale = ([0-9.]+)',text,re.M);visual=float(match.group(1)) if match else 1.0
 records=[]
 for npc in nodes:
  scale=float(npc.get('scale',.08))*visual
  calibrated=any(Path(npc['sprite_path']).name.startswith(prefix) for prefix in SMALL) and npc.get('movement_mode','idle')!='seated'
  states={'idle':npc['sprite_path']}
  if exists(npc.get('walk_sprite_path','')):states['walk']=npc['walk_sprite_path']
  for facing in ['down','up','left','right']:
   found=directional(npc,facing)
   if found:states['conversation_'+facing]=found
  measurements={}
  for state,asset in states.items():
   b=bounds(asset);first=b['node_calibrator_first_frame_height']
   heights=[f['a_gt_0_height'] for f in b['frames']]
   old_factor=scale*(140/first if calibrated and first else 1)
   measurements[state]={'path':asset,'first_alpha_height':first,'frame_alpha_min':min(heights),'frame_alpha_max':max(heights),'old_visible_px_first':first*old_factor,'normalized_frame_variation_ratio':max(heights)/first if first else None}
  records.append({'npc_id':npc['npc_id'],'npc_name':npc.get('npc_name',''),'row_scale':npc.get('scale',.08),'scene_npc_visual_scale':visual,'old_effective_sprite_scale':scale,'catalog_profile_matches':npc['npc_id'] in catalog_ids,'old_auto_calibrated_family':calibrated,'movement_mode':npc.get('movement_mode','idle'),'states':measurements})
 scenes.append({'id':scene,'source_sha256':sha(raw),'npc_visual_scale':visual,'npcs':records})
hero='res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down.png'
if not exists(hero):
 hero=next('res://'+p.relative_to(GAME).as_posix() for p in (GAME/'art/characters/weapon_variants/lengguyun/v7_idle_stable').rglob('*.png') if 'sword' in str(p) and 'idle_down' in p.name)
hb=bounds(hero);hero_height=hb['frames'][0]['a_gt_0_height']*.945
result={'status':'PNG_ALPHA_READ_ONLY_NOT_RUNTIME_OR_ART','hero_reference':{'path':hero,'first_alpha_height':hb['frames'][0]['a_gt_0_height'],'visual_scale':.945,'visible_height_px':hero_height},'scenes':scenes,'assets':cache,'engine_calls':0,'image_writes':0,'save_reads':0,'original_source_writes':0}
out=BASE/'alpha_bounds_ACTUAL.json'
with out.open('xb') as f:f.write((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'report':str(out),'sha256':sha(out.read_bytes()),'scenes':len(scenes),'npc_rows':sum(len(x['npcs']) for x in scenes),'assets':len(cache),'hero_height':hero_height,'south':[{'id':x['npc_id'],'idle_px':x['states']['idle']['old_visible_px_first'],'conversation_px':[round(v['old_visible_px_first'],2) for k,v in x['states'].items() if k.startswith('conversation_')]} for x in scenes[-1]['npcs']]},ensure_ascii=False))
