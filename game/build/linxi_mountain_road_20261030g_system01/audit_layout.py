"""Independent frozen road footprint audit. No Godot or gameplay execution."""
from pathlib import Path
import hashlib,json,math,sys
from collections import Counter
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
data=json.loads((HERE/"road_layout.json").read_text(encoding="utf-8"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def inside(p,polygon):
 x,y=p;v=False
 for a,b in zip(polygon,polygon[1:]+polygon[:1]):
  if (a[1]>y)!=(b[1]>y) and x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:v=not v
 return v
solids=[(r["id"],r["body"]) for r in data["specs"] if "body" in r]
for name,key,w,h in [("original_stone","road_stone_tablet_visual",72,44),("original_box","road_supply_box_closed",78,38)]:
 p=data["business"]["visual_feet"][key];solids.append((name,[p[0]-w*.5,p[1]-h,w,h]))
solids.append(("conditional_Fan",[1819.696,2556.752,20.608,26.496]))
if data["cave_module"]["status"]=="ROOT_NATIVE_READY" and "body" in data["cave_module"]["spec"]:solids.append(("cave",data["cave_module"]["spec"]["body"]))
def hit(p):
 x,y=p
 for dx,dy in [(-17,-12),(17,-12),(17,12),(-17,12)]:
  if not any(inside([x+dx,y+dy],poly) for poly in data["land_regions"]):return "outside_land"
 for name,(a,b,w,h) in solids:
  if x+17>=a and x-17<=a+w and y+12>=b and y-12<=b+h:return name
 player=[[x-17,y-12],[x+17,y-12],[x+17,y+12],[x-17,y+12]]
 for index,polygon in enumerate(data.get('solids',[])):
  separated=False
  for shape in [player,polygon]:
   for a,b in zip(shape,shape[1:]+shape[:1]):
    axis=[a[1]-b[1],b[0]-a[0]];pa=[u*axis[0]+v*axis[1] for u,v in player];pb=[u*axis[0]+v*axis[1] for u,v in polygon]
    if max(pa)<min(pb) or max(pb)<min(pa):separated=True;break
   if separated:break
  if not separated:return 'cave_source_polygon_%d'%index
 return None
routes={r["id"]:r["points"] for r in data["roads"]}
if len(sys.argv)>1:routes={key:value for key,value in routes.items() if key in sys.argv[1:]}
report={}
for name,points in routes.items():
 bad=[];samples=0
 for a,b in zip(points,points[1:]):
  n=math.ceil(math.dist(a,b)/6)
  for i in range(n+1):
   p=[a[k]+(b[k]-a[k])*i/n for k in range(2)];value=hit(p);samples+=1
   if value:bad.append({"foot":p,"solid":value})
 report[name]={"samples":samples,"blocked":len(bad),"blocked_by":dict(Counter(r["solid"] for r in bad)),"first_hits":bad[:4]}
probes={"linxi":data["arrival"],"zhuwei":data["zhuwei_arrival"],"cave":data["cave_entry"],"cave_return":data["cave_return"],**data["business"]["interaction_positions"]}
probe_hits={name:hit(p) for name,p in probes.items()}
negative={"granite_mass":[1290,1700],"bamboo_root":next(r["foot"] for r in data["specs"] if r["id"].startswith("bamboo_grove"))}
assert all(hit(p) for p in negative.values())
assert max(r["native_scale"] for r in data["specs"])<=1
source_keys=["game/data/scenes/ch1_s1_road.tres","game/data/maps/ch1_s1_road_layout_v5.tres","game/scripts/field/field_walkable_controller.gd","game/scenes/field_walkable.tscn","game/build/three_towns_world_20261029j_system01/town_registry.gd","game/build/three_towns_world_20261029j_system01/native_sources.json"]
if not (HERE/"before").exists():
 for key in source_keys:
  p=HERE/"before"/key;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes((ROOT/key).read_bytes())
 source={key:{"sha256":sha(ROOT/key),"bytes":(ROOT/key).stat().st_size,"mtime_ns":str((ROOT/key).stat().st_mtime_ns)} for key in source_keys}
 (HERE/"source_before.json").write_text(json.dumps(source,indent=2)+"\n",encoding="utf-8")
else:
 source=json.loads((HERE/"source_before.json").read_text());assert all(sha(ROOT/key)==r["sha256"] for key,r in source.items())
index=1
while (HERE/f"geometry_attempt{index:02d}.json").exists():index+=1
result={"status":"FAIL" if any(r["blocked"] for r in report.values()) or any(probe_hits.values()) else "STATIC_GEOMETRY_PASS_CAVE_MODULE_PENDING" if data["cave_module"]["status"]!="ROOT_NATIVE_READY" else "STATIC_GEOMETRY_PASS_NOT_ENGINE_PHYSICS_OR_ART","routes":report,"probe_hits":probe_hits,"negative_physical_checks":negative,"static_specs":len(data["specs"]),"native_scale_max":max(r["native_scale"] for r in data["specs"]),"cave_module_status":data["cave_module"]["status"],"method":"Full34x24 rectangle independent intersection vs frozen author geometry; <=6px line samples. Conditional Fan included conservatively. Not an engine/encounter/ART test.","layout_sha256":sha(HERE/"road_layout.json"),"engine_calls":0}
(HERE/f"geometry_attempt{index:02d}.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps(result,ensure_ascii=False))
raise SystemExit(1 if result["status"]=="FAIL" else 0)
