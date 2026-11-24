"""Read-only source extraction + conservative full 35x25 SAT against native polygons."""
from pathlib import Path
import hashlib
import json
import math
import re

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
IDS=["openworld_wudang_gate","openworld_wudang_taiji_court","openworld_huashan_forecourt","openworld_huashan_sword_terrace"]
DATA={"wudang":{"scene":"game/scenes/drafts/sect_maps_20261029k/wudang.tscn","layout":"game/art/modules/sect_maps_20261029k/wudang.json","controller":"game/scripts/drafts/sect_maps_20261029k/controller.gd","terrain":"game/scripts/drafts/sect_maps_20261029k/terrain.gd"},
      "huashan":{"scene":"game/scenes/drafts/huashan_map_20261029m/huashan.tscn","layout":"game/art/modules/huashan_map_20261029m/huashan.json","controller":"game/scripts/drafts/huashan_map_20261029m/controller.gd","terrain":"game/scripts/drafts/huashan_map_20261029m/terrain.gd"}}
WORLD="game/data/maps/world_map_jianghu_layout_v15.tres"

def read(p):return (ROOT/p).read_text(encoding="utf-8-sig")
def fact(p):
    b=(ROOT/p).read_bytes();return {"path":p,"sha256":hashlib.sha256(b).hexdigest(),"bytes":len(b)}
def vectors(s):return [float(n) for n in re.findall(r'[-+]?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?',s)]
def dict_rows(text,key):
    m=re.search(r'^'+key+r'\s*=\s*(?:Array\[Dictionary\]\()?(\[.*?\])\)?\s*$',text,re.M|re.S)
    if not m:return []
    raw=re.sub(r'Vector2\(([^)]*)\)',lambda x:'['+x[1]+']',m[1])
    return json.loads(raw)
def prop(text,key):
    m=re.search(r'^'+key+r'\s*=\s*(.+)$',text,re.M)
    return m[1] if m else None
def pin(point,poly):
    x,y=point;inside=False
    for a,b in zip(poly,poly[1:]+poly[:1]):
        if (a[1]>y)!=(b[1]>y) and x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:inside=not inside
    return inside
def convex(poly):
    signs=[]
    for a,b,c in zip(poly,poly[1:]+poly[:1],poly[2:]+poly[:2]):
        cross=(b[0]-a[0])*(c[1]-b[1])-(b[1]-a[1])*(c[0]-b[0])
        if abs(cross)>1e-7:signs.append(cross>0)
    return all(signs) or not any(signs)
def sat(a,b):
    for poly in [a,b]:
        for p,q in zip(poly,poly[1:]+poly[:1]):
            n=(-(q[1]-p[1]),q[0]-p[0])
            pa=[v[0]*n[0]+v[1]*n[1] for v in a];pb=[v[0]*n[0]+v[1]*n[1] for v in b]
            if max(pa)<min(pb)-1e-8 or max(pb)<min(pa)-1e-8:return False
    return True
def rect(p):
    x,y=p;return [[x-17.5,y-12.5],[x+17.5,y-12.5],[x+17.5,y+12.5],[x-17.5,y+12.5]]
def nodes_from_scene(text):
    nodes={}
    for m in re.finditer(r'^\[node ([^\]]+)\]\r?\n([\s\S]*?)(?=^\[node |\Z)',text,re.M):
        header,body=m[1],m[2]
        name=re.search(r'name="([^"]+)"',header)[1]
        parent=re.search(r'parent="([^"]+)"',header)
        path="" if not parent else (name if parent[1]=="." else parent[1]+"/"+name)
        typ=re.search(r'type="([^"]+)"',header)
        node={"path":path,"type":typ[1] if typ else "instance","text":body,"line":text.count("\n",0,m.start())+1}
        for key,default in [("position",[0,0]),("scale",[1,1])]:
            p=prop(body,key);node[key]=vectors(p)[1:] if p and p.startswith("Vector2") else default
        # Vector2's type digit is stripped by [1:] above.
        node["rotation"]=float(prop(body,"rotation") or 0)
        nodes[path]=node
    return nodes
def native(key):
    spec=DATA[key];layout=json.loads(read(spec["layout"]));nodes=nodes_from_scene(read(spec["scene"]))
    platforms=layout["terrain"]["platforms"]
    def level(p):return max([int(r["level"]) for r in platforms if pin(p,r["polygon"])]+[0])
    def offset(path):
        p=[0.,0.]
        while path in nodes:
            n=nodes[path];assert n["scale"]==[1,1] and n["rotation"]==0,(path,n["scale"])
            p=[p[0]+n["position"][0],p[1]+n["position"][1]]
            if not path:break
            path=path.rsplit("/",1)[0] if "/" in path else ""
        return p
    colliders=[]
    for path,node in nodes.items():
        if node["type"]!="CollisionPolygon2D":continue
        parent=path.rsplit("/",1)[0];body=nodes.get(parent)
        if body is None or body["type"]!="StaticBody2D":continue
        nums=vectors(prop(node["text"],"polygon") or "")[1:]
        poly=[[nums[i],nums[i+1]] for i in range(0,len(nums),2)]
        shift=offset(path);poly=[[p[0]+shift[0],p[1]+shift[1]] for p in poly]
        assert convex(poly),(key,path)
        layer=int(prop(body["text"],"collision_layer") or "1")
        if parent.startswith("Town/"):
            layer=8 if prop(body["text"],"metadata/common_layer")=="true" or parent.split("/")[-1].startswith("Water") else 16<<level(offset(parent))
        colliders.append({"path":parent,"shape_path":path,"layer":layer,"polygon":poly,"line":node["line"]})
    assert len(colliders)==sum(n["type"]=="StaticBody2D" for n in nodes.values())
    return {**spec,"layout_data":layout,"nodes":nodes,"colliders":colliders,"level":level}

def check(model,p,mask=None):
    level=model["level"](p);body=rect(p)
    if mask is None:mask=8|(16<<level)
    hits=[r["path"] for r in model["colliders"] if r["layer"]&mask and sat(body,r["polygon"])]
    base=model["layout_data"]["terrain"].get("base_outline")
    inside=not base or all(pin(v,base) for v in body)
    return {"foot":p,"level":level,"height":model["layout_data"]["terrain"]["heights"][level],
            "projected_foot":[p[0],p[1]-model["layout_data"]["terrain"]["heights"][level]],
            "full35x25_clear":not hits and inside,"hits":hits,"inside_base_outline":inside}

FILES=[WORLD,"game/scripts/field/field_walkable_controller.gd","game/scripts/field/player.gd","game/scenes/player.tscn","game/scripts/autoload/bounty_manager.gd","game/data/npcs/npc_catalog.tres","game/data/dialogs/openworld_wudang_gate_disciple.tres"]
original=[]
for id in IDS:
    path=f"game/data/scenes/{id}.tres";text=read(path)
    layout="game/"+re.search(r'path="res://(data/maps/[^"]+)"',text)[1]
    FILES.extend([path,layout])
    original.append({"id":id,"scene":path,"layout":layout,"display_name":prop(text,"display_name"),
                     "spawn_uv":vectors(prop(text,"player_spawn"))[1:],"actor_positions_are_feet":prop(text,"actor_positions_are_feet"),
                     "player_visual_scale":prop(text,"player_visual_scale"),"native_size":prop(read(layout),"display_at_native_size"),
                     "design_size":vectors(prop(read(layout),"design_size"))[1:],"npc_rows":dict_rows(text,"npcs"),
                     "portals":dict_rows(read(layout),"portals"),"interactions":dict_rows(read(layout),"interactions"),
                     "hotspots":dict_rows(text,"hotspots"),"trigger_zones":dict_rows(text,"trigger_zones")})
for spec in DATA.values():FILES.extend(spec.values())
before={p:fact(p) for p in FILES}
models={key:native(key) for key in DATA}
points={"wudang":{"arrival":[1700,4100],"leave_arrow":[1700,4200],"inner_arrow":[2500,2620],"inner_return":[2500,2700],"wudang_gate_disciple":[1900,3900],"disciple_approach":[1900,3990]},
        "huashan":{"arrival":[2780,4420],"leave_arrow":[2780,4520],"inner_arrow":[2700,2500],"inner_return":[2700,2580]}}
point_checks={key:{name:check(models[key],p) for name,p in rows.items()} for key,rows in points.items()}
for key,rows in point_checks.items():
    for name,result in rows.items():assert result["full35x25_clear"],(key,name,result)
routes={"wudang":[[1700,4200],[1700,4100],[1700,3500],[2400,3250],[2400,3070],[2400,2860],[2400,2700],[2500,2700],[2500,2620]],
        "huashan":[[2780,4520],[2780,4420],[2770,4050],[2640,3560],[2700,3200],[2700,3030],[2700,2760],[2700,2580],[2700,2500]]}
route_checks={}
for key,polyline in routes.items():
    model=models[key];samples=[];fail=[];active=-1;level=0
    for a,b in zip(polyline,polyline[1:]):
        distance=math.dist(a,b);count=math.ceil(distance/4)
        for n in range(count+1):
            p=[a[j]+(b[j]-a[j])*n/count for j in [0,1]]
            if active<0:
                for index,ramp in enumerate(model["layout_data"]["terrain"]["ramps"]):
                    if abs(p[0]-ramp["top"][0])<=model["layout_data"]["terrain"]["portal_half_width"]-20 and ramp["top"][1]-25<=p[1]<=ramp["bottom"][1]+25 and level in [ramp["low"],ramp["high"]]:
                        active=index;break
            mask=8|(16<<level)
            if active>=0:
                r=model["layout_data"]["terrain"]["ramps"][active]
                mask=8|(16<<r["low"])|(16<<r["high"])
                if p[1]<r["top"][1]-1:level=r["high"];active=-1
                elif p[1]>r["bottom"][1]+1 and b[1]>a[1]:level=r["low"];active=-1
            result=check(model,p,mask)
            if not result["full35x25_clear"]:fail.append(result)
            samples.append(p)
    route_checks[key]={"polyline":polyline,"sample_step_max_px":4,"sample_count":len(samples),"failures":fail,"static_only_not_engine":True}

world_lines=read(WORLD).splitlines();world={}
for key in DATA:
    for i,line in enumerate(world_lines):
        if line.strip()==f'"id": "{key}",':
            start=i
            while start>0 and world_lines[start].strip()!="}, {":start-=1
            end=i
            while end<len(world_lines)-1 and world_lines[end].strip()!="}, {":end+=1
            block="\n".join(world_lines[start+1:end])
            world[key]={"start_line":start+2,"raw_portal_block":block,
                        "literal_pos":re.search(r'"pos": (Vector2\([^)]*\))',block)[1],
                        "literal_target_pos":re.search(r'"target_pos": (Vector2\([^)]*\))',block)[1],
                        "door_foot_px":json.loads(re.search(r'"door_foot_px": (\[[^\]]*\])',block)[1]),
                        "target_scene":re.search(r'"target_scene": "([^"]+)"',block)[1]}
            break
negatives={key:check(model,([2700,900] if key=="wudang" else [2770,1000])) for key,model in models.items()}
assert all(not value["full35x25_clear"] for value in negatives.values())
assert before=={p:fact(p) for p in FILES}
report={"schema_version":1,"status":"READ_ONLY_BUSINESS_AND_STATIC_CANDIDATES_NOT_ENGINE_OR_PHYSICS",
        "original_scenes":original,"world_size":[12288,8192],"world_landmarks":world,
        "native_points":point_checks,"routes":route_checks,"house_body_negative_controls":negatives,
        "native_static_collision_counts":{k:len(m["colliders"]) for k,m in models.items()},
        "native_collider_polygons":{k:m["colliders"] for k,m in models.items()},
        "native_topology":{k:m["layout_data"]["terrain"] for k,m in models.items()},
        "draft_character_nodes":{k:[p for p,n in m["nodes"].items() if n["type"]=="CharacterBody2D"] for k,m in models.items()},
        "source_inventory":list(before.values()),"all_sources_sha_bytes_unchanged":True,
        "foot_test_basis":"Centered35x25 conservatively exceeds realPlayer34x24 at ground anchor0; all actual baked static CollisionPolygon2D transformed with literal source scene positions and exact collision layers, runtime Town layer assignment mirrored. Convex SAT fullfoot, base-outline full corners. Routes sample<=4px with ramp dual-layer mask; no movement/input/physics engine.",
        "warnings":["No claim legacy UV can be scaled into5200/5800 native map; only original legal old UV may migrate to explicit arrival, firstinner origin maps explicitly to inner_return.","Original NPC inventory only1 ordinaryWudang guard/no quest NPC in these4Scenes. No Bounty locations target these IDs; keep generic runtime append contract for future.","Drafts have Player only, no decorative NPC to remove. Preserve real static buildings/labels; inheritedSectField calls examine but controllers implement inlineSpace only, adapter required."]}
target=OUT/"business_geometry_READY.json";assert not target.exists()
target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"path":str(target),"sha256":hashlib.sha256(target.read_bytes()).hexdigest(),"points":point_checks,"routes":{k:{"samples":v["sample_count"],"failures":v["failures"][:4],"failure_count":len(v["failures"])} for k,v in route_checks.items()},"sources":len(before)}))
