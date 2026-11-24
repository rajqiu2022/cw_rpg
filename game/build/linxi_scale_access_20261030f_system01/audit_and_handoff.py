"""Read-only source/geometry audit and mechanical handoff manifest. No engine."""
from pathlib import Path
import hashlib
import json
import math
import re
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
data=json.loads((HERE/"linxi_master.json").read_text(encoding="utf-8"))
old=json.loads((HERE/"before/game/art/modules/four_settlements_20261030e/linxi_master.json").read_text(encoding="utf-8"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
baseline=json.loads((HERE/"source_before.json").read_text())
assert all(sha(ROOT/k)==row["sha256"] for k,row in baseline.items())
assert data["business"]==old["business"]
locations=json.loads((HERE/"locations_READY.json").read_text(encoding="utf-8"))
oldloc=json.loads((ROOT/"game/build/four_settlements_20261030e_system01/locations.json").read_text(encoding="utf-8"))
assert locations["linxi_tutorial"]["returns"]==oldloc["linxi_tutorial"]["returns"]
assert all(row==oldloc[key] for key,row in locations.items() if key!="linxi_tutorial")

def polygons(layout):
    objects={r["name"]:r["foot"] for r in layout["objects"]}
    result=[]
    for row in layout["blockers"]:
        path=row["path"];p=objects.get(path.split("/")[1],[0,0]) if path.startswith("Town/") and path.endswith("/Body") else [0,0]
        result.append((path,[(x+p[0],y+p[1]) for x,y in row["polygon"]]))
    return result

def inside(point,polygon):
    x,y=point;value=False
    for a,b in zip(polygon,polygon[1:]+polygon[:1]):
        if (a[1]>y)!=(b[1]>y) and x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:value=not value
    return value

def blocked(foot,layout):
    x,y=foot
    if x-17<110 or x+17>2790 or y-12<110 or y+12>2290:return "outer_boundary"
    # Full convex SAT, including slanted native rail ground contacts.
    player=[(x-17,y-12),(x+17,y-12),(x+17,y+12),(x-17,y+12)]
    for name,polygon in polygons(layout):
        separated=False
        for shape in [player,polygon]:
            for a,b in zip(shape,shape[1:]+shape[:1]):
                axis=(a[1]-b[1],b[0]-a[0]);p=[u*axis[0]+v*axis[1] for u,v in player];q=[u*axis[0]+v*axis[1] for u,v in polygon]
                if max(p)<min(q) or max(q)<min(p):separated=True;break
            if separated:break
        if not separated:return name
    return None

positives={"hall_old_return":[1249.3851102941176,818],"bedroom_old_return":[2069.592944369064,858],"kitchen_migration":[650,1740],"bedroom_stair_entry":[2050,1290],"hall_stair_entry":[1150,1290]}
for name,p in positives.items():assert blocked(p,data) is None,(name,blocked(p,data))
routes={"back_grass_north_cross_old_y350":[[1700,460],[1700,220]],"back_grass_cross_old_x500":[[420,950],[620,950]],"bedroom_central_ramp":[[2050,1300],[2050,1000]],"hall_central_ramp":[[1150,1300],[1150,1000]]}
route_counts={}
for name,points in routes.items():
    a,b=points;n=math.ceil(math.dist(a,b)/4)
    for i in range(n+1):
        p=[a[j]+(b[j]-a[j])*i/n for j in range(2)];assert blocked(p,data) is None,(name,p,blocked(p,data))
    route_counts[name]=n+1
negative={"house_hall":[1130,730],"house_bedroom":[2100,760],"house_kitchen":[650,1600],"tree_root_preserved":[1250,290],"bedroom_left_real_wall":[1900,1210],"bedroom_right_real_wall":[2220,1210]}
for name,p in negative.items():assert blocked(p,data) is not None,name
growth_cases={"hall":[1500,750],"bedroom":[2280,780],"kitchen":[890,1600],"bedroom_left_rail":[1900,1210]}
for name,p in growth_cases.items():assert blocked(p,old) is None and blocked(p,data) is not None,name
hero=ROOT/"game/art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down_25d_4f.png"
image=Image.open(hero).convert("RGBA");bbox=image.crop((0,0,160,160)).getchannel("A").getbbox();adult=(bbox[3]-bbox[1])*.945
houses={r["name"]:{"visible_width":r["width"],"visible_height":r["height"],"native_scale":r["scale"],"height_per_adult":r["height"]/adult} for r in data["objects"] if r["name"] in ["MasterHall","Bedroom","Kitchen"]}
assert all(2.5<=row["height_per_adult"]<=3.5 and row["native_scale"]<=1 for row in houses.values())
scene=(HERE/"linxi_master.tscn").read_text(encoding="utf-8")
for path in re.findall(r'path="(res://[^"\n]+)"',scene):assert (ROOT/"game"/path[6:]).exists(),path
report={"status":"STATIC_ONLY_NEW_DOMAIN_CLEAR_NOT_ENGINE_PHYSICS_OR_ART","old_sources_exact":True,"other6_ids_typed_exact":True,"old11_room_business_semantics_untouched":True,"linxi_two_returns_exact":True,"positive_foot_checks":positives,"negative_foot_checks":negative,"old_legal_new_contact_cases":growth_cases,"routes_samples_every_le4px":route_counts,"geometry_method":"Convex SAT independent of Godot; exact source-declared Rect/Polygon footprint34x24. Does not simulate elevation/input/runtime.","hero_reference":{"path":hero.relative_to(ROOT).as_posix(),"sha256":sha(hero),"direction":"down","frame":0,"alpha_bbox":bbox,"native_scale":.945,"visible_height":adult},"houses":houses,"manual_door_source_windows":{"office":{"y":[537,745],"height_scaled":208*.72},"small_home":{"y":[642,878],"height_scaled":236*.64},"note":"Pixel windows manually identified from original images, not automatic alpha segmentation. Root normal-camera adult/door ART remains required."},"engine_calls":0}
(HERE/"static_audit_ACTUAL.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
targets=[]
for target,candidate in [("game/build/four_settlements_20261030e_system01/locations.json","locations_READY.json"),("game/build/four_settlements_20261030e_system01/locations.gd","locations_READY.gd")]:
    p=HERE/candidate;targets.append({"target":target,"candidate":p.relative_to(ROOT).as_posix(),"old_sha256":baseline[target]["sha256"],"new_sha256":sha(p),"bytes":p.stat().st_size})
modules={}
for name in ["linxi_master.tscn","linxi_master.json","linxi_master_ground.gdshader","restore.gd","before/game/art/modules/four_settlements_20261030e/linxi_master.json"]:
    p=HERE/name;modules[p.relative_to(ROOT).as_posix()]={"sha256":sha(p),"bytes":p.stat().st_size}
manifest={"status":"ROOT_ONLY_MINIMAL_TWO_EXISTING_TARGETS_PLUS_FIVE_NEW_RUNTIME_SOURCES","targets":targets,"new_modules":modules,"old_native_source_count":125,"old_native_source_sha256":baseline["game/build/three_towns_world_20261029j_system01/native_sources.json"]["sha256"],"old_keys_must_remain":True,"original_native_scene_layout_shader_immutable":True,"source_closure_owner":"xiangzhou30e","engine_calls":0}
(HERE/"target_manifest_READY.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"status":report["status"],"routes":route_counts,"houses":houses,"target_manifest_sha256":sha(HERE/"target_manifest_READY.json")},ensure_ascii=False))
