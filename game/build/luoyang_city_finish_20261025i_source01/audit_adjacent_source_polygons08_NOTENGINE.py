"""Implementation static float32 audit of every pending adjacent derive polygon.
No expected values are taken from GPU/current ResourceLoader or independent QA.
"""
from pathlib import Path
import json,struct
N=Path(__file__).resolve().parent
A=json.loads((N/'author_adjacent_four_fields04_actual_actor_id_NOTREADY.json').read_text(encoding='utf8'))
L=json.loads((N/'adjacent_adopted_asset_library03_SOURCE_ONLY.json').read_text(encoding='utf8'))
def f(v):return struct.unpack('<f',struct.pack('<f',v))[0]
def bits(v):return struct.pack('<f',f(v)).hex()
def point(q,foot,anchor,scale):return [f(f(foot[i])+f(f(f(q[i])-f(anchor[i]))*f(scale))) for i in range(2)]
def same(a,b):return [[bits(x) for x in p] for p in a]==[[bits(x) for x in p] for p in b]
rows=[]
for scene in A['scenes']:
 for p in scene.get('placements',[]):
  asset=L['assets'][p['asset_id']];computed=[];fourcorner=[];foot=p['foot_px'];anchor=asset['source_ground_anchor_px'];s=p['scale']
  for r in asset.get('source_solid_rects_px',[]):
   low=point(r[:2],foot,anchor,s);high=[f(low[i]+f(f(r[i+2])*f(s))) for i in range(2)]
   computed.append([low,[high[0],low[1]],high,[low[0],high[1]]])
   raw=[[r[0],r[1]],[r[0]+r[2],r[1]],[r[0]+r[2],r[1]+r[3]],[r[0],r[1]+r[3]]]
   fourcorner.append([point(q,foot,anchor,s) for q in raw])
  for raw in asset.get('source_solid_polygons_px',[]):
   poly=[point(q,foot,anchor,s) for q in raw];computed.append(poly);fourcorner.append(poly)
  for raw in asset.get('donor_ground_polygons_px',[]):
   poly=[point(q,foot,asset['donor_foot_px'],s/asset['donor_scale']) for q in raw];computed.append(poly);fourcorner.append(poly)
  expected=p['source_derived_new_ground_polygons_f32'];low_size_same=len(expected)==len(computed) and all(same(x,y) for x,y in zip(expected,computed))
  source_corners_same=len(expected)==len(fourcorner) and all(same(x,y) for x,y in zip(expected,fourcorner))
  rows.append({'scene':scene['scene_id'],'id':p['id'],'new_polygon_count':len(computed),'declared_count':len(expected),'low_then_size_high_matches':low_size_same,'four_raw_corner_source_expression_matches':source_corners_same})
print(json.dumps({'not_QA_or_Godot':True,'all_rows':rows,'specific_low_size_order_mismatches':[r for r in rows if not r['low_then_size_high_matches']]},indent=2))
