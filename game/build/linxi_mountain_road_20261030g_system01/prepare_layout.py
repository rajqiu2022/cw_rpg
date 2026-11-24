"""Freeze authored road/landmark coordinates and native reuse geometry. No engine."""
from pathlib import Path
import json
import math
import hashlib

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
SIZE=[4608,3456]
MAIN=[[420,3150],[800,2860],[1200,2650],[1750,2530],[2210,2340],[2670,2450],[3190,2160],[3490,1700],[3650,1180],[3320,920],[3690,600],[4080,470]]
WEST=[[1200,2650],[700,2200],[620,1450],[740,990],[1500,790],[1850,1200],[1850,1720],[1750,2530]]
CAVE=[[2670,2450],[2700,2020],[2400,1740],[2400,1610],[2420,1530]]
HERB=[[3490,1700],[3780,1650],[3790,1440],[3650,1180]]
SOIL="res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
FOREST="res://art/modules/miao_recompose_20261029g/woodland_floor.png"
GRAVEL="res://art/modules/huashan_map_20261029m/granite_ground.png"
CRAG="res://art/modules/huashan_map_20261029m/granite_crag.png"
BAMBOO="res://art/modules/veg/veg_bamboo_cluster_a.png"
def ring(p,r):return [[p[0]+math.cos(i*math.tau/12)*r,p[1]+math.sin(i*math.tau/12)*r] for i in range(12)]
def strip(a,b,w):
 d=math.dist(a,b);n=[-(b[1]-a[1])/d*w*.5,(b[0]-a[0])/d*w*.5]
 return [[a[0]+n[0],a[1]+n[1]],[b[0]+n[0],b[1]+n[1]],[b[0]-n[0],b[1]-n[1]],[a[0]-n[0],a[1]-n[1]]]
roads=[{"id":"folding_mountain_main","points":MAIN,"width":200,"texture":SOIL},{"id":"bamboo_west_loop","points":WEST,"width":124,"texture":SOIL},{"id":"cave_side_approach","points":CAVE,"width":160,"texture":SOIL},{"id":"cliff_herb_loop","points":HERB,"width":116,"texture":SOIL}]
land=[]
for row in roads:
 for a,b in zip(row["points"],row["points"][1:]):land.append(strip(a,b,row["width"]+130))
 for p in row["points"]:land.append(ring(p,(row["width"]+130)*.5))
clearings=[[[900,2420],[1480,2420],[1590,2770],[1100,2910],[850,2730]],[[1830,2110],[2460,2080],[2540,2520],[2050,2670],[1780,2440]],[[2020,1330],[2840,1330],[2920,1770],[2690,1910],[2120,1880],[1900,1640]]]
land.extend(clearings)
ground=[{"id":"wooded_mineral_floor","polygon":[[0,0],[4608,0],[4608,3456],[0,3456]],"texture":FOREST,"period":[640,640],"z":-1200}]
for i,p in enumerate(clearings):ground.append({"id":"shoulder_%02d"%i,"polygon":p,"texture":GRAVEL if i==2 else SOIL,"period":[480,480],"z":-1120,"feather_px":80})
specs=[]
def good(id,tex,p,s,pivot,body,usage):
 x,y,w,h=body
 specs.append({"id":id,"texture":tex,"foot":p,"native_scale":s,"source_foot_px":pivot,"body":[p[0]+(x-pivot[0])*s,p[1]+(y-pivot[1])*s,w*s,h*s],"usage":usage})
for i,(p,s) in enumerate([([1290,1800],.60),([1300,1390],.52),([2790,1250],.55),([4190,2080],.64),([4310,1530],.58),([4420,780],.55),([3280,3150],.70),([260,900],.45),([2320,520],.62)]):
 good("granite_ridge_%02d"%i,CRAG,p,s,[1107,976],[360,535,1460,441],"完整原生灰岩脊/可辨悬崖，非整图裁件；真实山体脚阻挡")
def segment_distance(p,a,b):
 dx=b[0]-a[0];dy=b[1]-a[1];t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy)))
 return math.dist(p,[a[0]+dx*t,a[1]+dy*t])
authored_exclusions=[p for row in roads for p in row["points"]]+[[1120,2670],[2230,2380],[2400,1610],[2420,1530],[2460,1670],[1830,2570],[1720,2450],[3910,1510]]
plant_candidates=[]
for line,side_base in [(MAIN,300),(WEST,245),(CAVE,270),(HERB,240)]:
 for i,p in enumerate(line[1:-1]):
  a=line[i];b=line[i+2];length=math.dist(a,b);nx=-(b[1]-a[1])/length;ny=(b[0]-a[0])/length
  for sign in [-1,1]:
   offset=side_base+[0,53,-22,88][i%4];plant_candidates.append(([p[0]+nx*offset*sign+17*(i%3),p[1]+ny*offset*sign-21*(i%2)],.65+.06*(i%5)))
for i,(p,s) in enumerate(plant_candidates):
 if not(130<p[0]<4470 and 180<p[1]<3320):continue
 # Offline layout exclusion only. No runtime/old-save nearest-foot projection.
 if any(segment_distance(p,a,b)<210 for row in roads for a,b in zip(row["points"],row["points"][1:])):continue
 if any(math.dist(p,q)<200 for q in authored_exclusions):continue
 good("bamboo_grove_%02d"%i,BAMBOO,p,s,[292,439],[90,385,410,54],"林间竹丛，完整原生比例；竹根保真实阻挡")
good("cold_brazier","res://art/modules/prop/linxi_brazier_forge_v1.png",[2600,1580],.32,[187.5,292],[50,220,275,72],"原洞口冷灶的实体外观，不增加新互动/奖励")
data={"id":"ch1_s1_road","size":SIZE,"version":3003,"arrival":[420,3150],"zhuwei_arrival":[4080,470],"cave_entry":[2420,1530],"cave_return":[2400,1610],"roads":roads,"land_regions":[[[80,80],[4528,80],[4528,3376],[80,3376]]],"authored_route_shoulders":land,"ground":ground,"specs":specs,"business":{"portal_positions":{"return_to_linxi":[420,3150],"exit_to_zhuwei_blocked":[4080,470],"exit_to_zhuwei_intro":[4080,470],"exit_to_zhuwei":[4080,470],"bandit_cave_entry":[2420,1530]},"interaction_positions":{"road_stone_read":[1120,2670],"road_stone_rubbing":[1120,2670],"road_corpse":[2230,2380],"road_cold_brazier":[2460,1670]},"visual_feet":{"road_stone_tablet_visual":[1120,2610],"road_corpse_visual":[2230,2320],"road_supply_box_closed":[1720,2450],"road_cliff_herb_visual":[3910,1450]},"caravan_foot":[1830,2570]},"cave_module":{"status":"ROOT_SINGLE_NATIVE_MODULE_PENDING","target_texture":"res://art/modules/linxi_mountain_road_20261030g/cave_mouth.png","foot":[2420,1460],"native_scale":.65},"design_note":"自然折返主道/竹林西环/洞侧坪/临崖草药岔路；林间空隙开放、真正树根/山体阻挡而非隐形窄走廊，无新剧情名称/假高程/旧背景裁件，洞门继续原山寨洞窟业务。"}
data["business"]["visual_feet"]["road_stone_tablet_visual"]=[1050,2720]
data["business"]["visual_feet"]["road_cliff_herb_visual"]=[3790,1440]
data["business"]["visual_feet"]["road_supply_box_closed"]=[1600,2480]
data["business"]["interaction_positions"]["road_cold_brazier"]=[2600,1670]
binding_path=HERE/"cave_native_binding.json"
if binding_path.exists():
 binding=json.loads(binding_path.read_text(encoding="utf-8"));source=ROOT/'game'/binding['cave_module']['spec']['texture'][6:]
 assert hashlib.sha256(source.read_bytes()).hexdigest()==binding['png_sha256']
 data['cave_module']=binding['cave_module']
 anchor=binding['source_threshold_px'];foot=data['cave_module']['spec']['foot'];scale=data['cave_module']['spec']['native_scale']
 data['solids']=[[[foot[0]+(p[0]-anchor[0])*scale,foot[1]+(p[1]-anchor[1])*scale] for p in polygon] for polygon in binding['source_solids']]
(HERE/"road_layout.json").write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"size":SIZE,"static_specs":len(specs),"road_rows":len(roads),"land_regions":len(data["land_regions"]),"authored_route_shoulders":len(land),"layout_sha256":hashlib.sha256((HERE/"road_layout.json").read_bytes()).hexdigest(),"cave_pending":data['cave_module']['status']!='ROOT_NATIVE_READY'},ensure_ascii=False))
