"""Numeric projection from immutable read-only alpha audit; not engine evidence."""
from pathlib import Path
import hashlib,json
BASE=Path(__file__).resolve().parent
audit=json.loads((BASE/'alpha_bounds_ACTUAL.json').read_bytes())
def target(npc):
 if 'granny' in npc:return 120.0
 if 'herbalist' in npc:return 122.0
 if any(v in npc for v in ['teacher','veteran']) or npc.startswith('xingfantian'):return 124.0
 if any(v in npc for v in ['apprentice','herb_gatherer','shen_qinghe']):return 128.0
 if any(v in npc for v in ['guard','porter','coach','tang_xingzhou']):return 132.0
 return 130.0
rows=[]
for scene in audit['scenes']:
 for npc in scene['npcs']:
  t=target(npc['npc_id']);states=[]
  for state,item in npc['states'].items():
   asset=audit['assets'][item['path']];first=item['first_alpha_height']
   heights=[frame['a_gt_0_height']*t/first for frame in asset['frames']]
   states.append({'state':state,'path':item['path'],'target_first_frame_px':t,'sprite_scale':t/first,'projected_first_frame_px':heights[0],'all_frame_min':min(heights),'all_frame_max':max(heights)})
  rows.append({'scene_id':scene['id'],'npc_id':npc['npc_id'],'target_height_px':t,'old_idle_px':npc['states']['idle']['old_visible_px_first'],'new_idle_first_px':t,'states':states})
result={'status':'MATHEMATICAL_ALPHA_PROJECTION_NOT_GODOT_OR_PHYSICS','hero':audit['hero_reference'],'rows':rows,'row_count':len(rows),'first_frame_targets_all_120_to_132':all(120<=r['new_idle_first_px']<=132 for r in rows),'per_texture_first_frame_height_identity':True,'weapon_pose_note':'Tang practice includes a separate dummy/staff in the same original 256px cell; high staff alpha186..200 projects132..141.94 while human body about180*132/186=127.74px. Conversation132px, not a large-head texture swap. No image is edited.','engine_calls':0,'image_writes':0}
out=BASE/'normalized_projection_ACTUAL.json'
with out.open('xb') as f:f.write((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'rows':len(rows),'all_targets_120_to_132':result['first_frame_targets_all_120_to_132'],'report':str(out),'sha256':hashlib.sha256(out.read_bytes()).hexdigest()},ensure_ascii=False))
