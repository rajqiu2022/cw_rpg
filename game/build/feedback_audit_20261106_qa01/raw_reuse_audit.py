from pathlib import Path
from PIL import Image
import json, hashlib
root=Path("F:/Code/RPG_GAME")
rows=[
("miao_man","assets/raw/miao_town_20261029f/npc_walk/miao_town_20261029f_man_walk_v1.png",4,4),
("miao_woman","assets/raw/miao_town_20261029f/npc_walk/miao_town_20261029f_woman_walk_v1.png",4,4),
("miao_side","assets/raw/miao_town_20261029f/npc_walk/miao_town_20261029f_side_stride_v2.png",4,2),
("redrock_merchant","assets/raw/redrock_desert_complete_20261028d/npc_walk/redrock_desert_complete_20261028d_merchant_walk_v1.png",4,4),
("redrock_worker","assets/raw/redrock_desert_complete_20261028d/npc_walk/redrock_desert_complete_20261028d_worker_walk_v1.png",4,4),
("young_guard_idle","assets/raw/luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1.png",1,1),
("young_guard_walk","assets/raw/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1.png",2,2),
("redrock_keeper","assets/raw/redrock_luoyang_standard_20261028b/npc_sprite/redrock_luoyang_standard_20261028b_keeper_sprite_v1.png",1,1),
("redrock_guard","assets/raw/redrock_ground_resources_20261023b/npc_walk/redrock_20261023b_guard_footfix_v1.png",1,1)]
out=[]
for name,rel,cols,rows_n in rows:
 p=root/rel
 if not p.exists(): out.append(dict(name=name,path=rel,missing=True));continue
 im=Image.open(p);alpha=im.getchannel("A") if "A" in im.getbands() else None
 heights=[];boxes=[]
 rects=[]
 if name in ('redrock_merchant','redrock_worker'):
  config=json.loads((root/'game/art/modules/redrock_desert_complete_20261028d/atlases.json').read_text(encoding='utf-8-sig'))
  for row in config[name.removeprefix('redrock_')+'_walk']['rows']:
   for frame in row:
    x,y,w,h=frame['region'];rects.append((x,y,x+w,y+h))
 else:
  for row in range(rows_n):
   for col in range(cols):
    rects.append((round(col*im.width/cols),round(row*im.height/rows_n),round((col+1)*im.width/cols),round((row+1)*im.height/rows_n)))
 if alpha:
  for rect in rects:
   cell=alpha.crop(rect).point(lambda a:255 if a>=24 else 0)
   box=cell.getbbox();boxes.append(box);heights.append(box[3]-box[1] if box else 0)
 out.append(dict(name=name,path=rel,size=im.size,mode=im.mode,grid_assumption=[cols,rows_n],alpha_extrema=alpha.getextrema() if alpha else None,alpha24_heights=heights,alpha24_boxes=boxes,min320=bool(heights) and min(heights)>=320,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
print(json.dumps(out,ensure_ascii=False,indent=2))
