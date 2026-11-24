"""Mechanical native scene/data derivation. New directory only; never runs Godot."""
from pathlib import Path
import hashlib
import json
import math
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
RES="res://build/linxi_scale_access_20261030f_system01/"
SCENE="game/scenes/drafts/four_settlements_20261030e/linxi_master.tscn"
LAYOUT="game/art/modules/four_settlements_20261030e/linxi_master.json"
SHADER="game/art/modules/four_settlements_20261030e/linxi_master_ground.gdshader"
LOC="game/build/four_settlements_20261030e_system01/locations.json"
LOC_GD="game/build/four_settlements_20261030e_system01/locations.gd"
FILES=[SCENE,LAYOUT,SHADER,LOC,LOC_GD,"game/build/three_towns_world_20261029j_system01/town_registry.gd","game/build/three_towns_world_20261029j_system01/native_sources.json"]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before={k:{"sha256":sha(ROOT/k),"bytes":(ROOT/k).stat().st_size,"mtime_ns":str((ROOT/k).stat().st_mtime_ns)} for k in FILES}
assert before[SCENE]["sha256"]=="7166b58c3382d6534fa3411ed1f0b62e0256cfe44e40087c69379883434496bb"
assert before[LAYOUT]["sha256"]=="084b9da254d66127491b746d2d97d5186317d9417bba212a2b37f78bc70b32d6"
if (HERE/"before").exists():
    assert all(sha(HERE/"before"/key)==value["sha256"] for key,value in before.items()),"Do not replace original snapshots"
else:
    for key in FILES:
        out=HERE/"before"/key
        out.parent.mkdir(parents=True,exist_ok=True)
        out.write_bytes((ROOT/key).read_bytes())
    (HERE/"source_before.json").write_text(json.dumps(before,indent=2)+"\n",encoding="utf-8")
if (HERE/"linxi_master.tscn").exists():
    history=HERE/"history";history.mkdir(exist_ok=True)
    previous=HERE/"linxi_master.tscn";frozen=history/(sha(previous)+".tscn.txt")
    if not frozen.exists():frozen.write_bytes(previous.read_bytes())
data=json.loads((ROOT/LAYOUT).read_text(encoding="utf-8"))
old=json.loads((ROOT/LAYOUT).read_text(encoding="utf-8"))
text=(ROOT/SCENE).read_text(encoding="utf-8")
parts=re.split(r'(?=^\[node )',text,flags=re.M)
headers=[]
for part in parts:
    match=re.match(r'\[node name="([^"]+)"[^\n]*?(?:parent="([^"]+)")?[^\n]*\]\n',part)
    headers.append((match.group(1),re.search(r'parent="([^"]+)"',match[0]).group(1) if 'parent="' in match[0] else "") if match else ("",""))

def fmt(n):return f"{float(n):.14g}"
def vec(p):return "Vector2("+", ".join(fmt(n) for n in p)+")"
def poly(points):return "PackedVector2Array("+", ".join(fmt(n) for p in points for n in p)+")"
def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]
def field(block,key,value):
    pattern=r'^'+re.escape(key)+r' = .*?(?=\n\w|\nmetadata/|\n\[|\n\n|\Z)'
    if re.search(pattern,block,re.M|re.S):return re.sub(pattern,key+" = "+value,block,count=1,flags=re.M|re.S)
    return block.rstrip()+"\n"+key+" = "+value+"\n\n"

# Source-box contracts use existing original PNGs; no resample or new imports.
media={"office":([22,239,1515,783],[768.5,783]),"small_home":([548,327,1491,974],[1019.5,974])}
changes={
 "MasterHall":{"key":"office","foot":[1119.7851102941176,780],"scale":.72,"depth":170},
 "Bedroom":{"key":"small_home","foot":[2060.312944369064,820],"scale":.64,"depth":150},
 "Kitchen":{"key":"small_home","foot":[650,1660],"scale":.64,"depth":150},
}
objects={r["name"]:r for r in data["objects"]}
raised_groves={r["name"] for r in data["objects"] if r["name"].startswith("Grove") and 110<=r["foot"][0]<=2790 and 110<=r["foot"][1]<350 or r["name"] in ["Grove0","Grove6"]}
for name,row in changes.items():
    bbox,pivot=media[row["key"]]
    row["width"]=(bbox[2]-bbox[0])*row["scale"]
    row["height"]=(bbox[3]-bbox[1])*row["scale"]
    objects[name].update({k:row[k] for k in ["key","foot","scale","width","height"]})
    for blocker in data["blockers"]:
        if blocker["path"]==f"Town/{name}/Body":blocker["polygon"]=rect(-row["width"]*.42,-row["depth"],row["width"]*.84,row["depth"])
data["terrain"]["platforms"][0]["polygon"]=[[110,110],[2790,110],[2790,1100],[110,1100]]
data["roads"].append({"points":[[480,1000],[480,240],[2470,240],[2470,1000],[1700,1000]],"width":75})
assert data["business"]==old["business"]

# Update only matching native node blocks. Every other object remains exact.
for i,(name,parent) in enumerate(headers):
    block=parts[i]
    if parent=="Town" and name in changes:
        r=changes[name];block=field(block,"position",vec(r["foot"]))
        block=field(block,"metadata/visual_rect",f'Rect2({fmt(-r["width"]/2)}, {fmt(-r["height"])}, {fmt(r["width"])}, {fmt(r["height"])})')
    elif parent=="Town" and name in raised_groves:
        block=field(block,"metadata/terrain_level","1");block=field(block,"metadata/elevation","60.0")
    elif name=="Art" and parent.startswith("Town/") and parent.split("/")[1] in changes:
        r=changes[parent.split("/")[1]];pivot=media[r["key"]][1];elevation=60 if parent!="Town/Kitchen" else 0
        block=field(block,"position",vec([-pivot[0]*r["scale"],-pivot[1]*r["scale"]-elevation]))
        block=field(block,"scale",vec([r["scale"],r["scale"]]));block=field(block,"texture",f'ExtResource("{r["key"]}")')
    elif name=="Shape" and parent in [f"Town/{n}/Body" for n in changes]:
        r=changes[parent.split("/")[1]];block=field(block,"polygon",poly(rect(-r["width"]*.42,-r["depth"],r["width"]*.84,r["depth"])))
    elif name=="Art" and parent in ["Town/"+n for n in raised_groves]:
        # These two trees acquire the now-open upper grass level; collision roots stay.
        match=re.search(r'position = Vector2\(([^,]+), ([^)]+)\)',block);x,y=map(float,match.groups());block=field(block,"position",vec([x,y-60]))
    elif name=="Body" and parent in ["Town/"+n for n in raised_groves]:block=field(block,"collision_layer","32")
    elif name=="Platform1" and parent=="Terrain":block=field(block,"polygon",poly(data["terrain"]["platforms"][0]["polygon"]))
    elif parent.startswith("Terrain/Cliff"):
        cliff=parent.split("/")[-1]
        if cliff=="Cliff0":block=field(block,"polygon",poly(rect(110,105,2680,10)))
        elif cliff=="Cliff1":block=field(block,"polygon",poly(rect(2785,110,10,990)))
        elif cliff=="Cliff5":block=field(block,"polygon",poly(rect(105,110,10,990)))
        elif cliff=="Cliff2":block=field(block,"polygon",poly(rect(2115,1095,675,10)))
        elif cliff=="Cliff4":block=field(block,"polygon",poly(rect(110,1095,975,10)))
    parts[i]=block

def ground_y(source_y):
    return 1100+(source_y-358)*76.5/(780-358) if source_y<=780 else 1176.5+(source_y-780)*.35

def clip_y(points,cut,keep_above):
    output=[]
    for a,b in zip(points,points[1:]+points[:1]):
        ia=a[1]>=cut if keep_above else a[1]<=cut
        ib=b[1]>=cut if keep_above else b[1]<=cut
        if ia:output.append(a)
        if ia!=ib:
            t=(cut-a[1])/(b[1]-a[1]);output.append([a[0]+(b[0]-a[0])*t,cut])
    return output

side_sources=[[[0,0],[500,0],[500,358],[410,780],[410,1024],[0,1024]],[[1040,0],[1536,0],[1536,1024],[1125,1024],[1125,780],[1040,358]]]
contact_sources=[[[0,358],[500,358],[410,780],[410,1024],[0,1024]],[[1040,358],[1536,358],[1536,1024],[1125,1024],[1125,780]]]
extra=[]
for index,ramp in enumerate(data["terrain"]["ramps"]):
    ident=ramp["id"];center=ramp["top"][0]
    for side,source in enumerate(contact_sources):
        data["blockers"].append({"path":f"Terrain/RampRail{index}"+("-1" if side==0 else "1"),"polygon":[[center+(x-768)*.35,ground_y(y)] for x,y in source]})
    for j,(name,parent) in enumerate(headers):
        if parent=="Terrain/"+ident and 'z_index = 300' in parts[j]:parts[j]=""
        if parent==f"Terrain/RampRail{index}-1" or parent==f"Terrain/RampRail{index}1":
            side=0 if parent.endswith("-1") else 1
            points=[[center+(x-768)*.35,ground_y(y)] for x,y in contact_sources[side]]
            parts[j]=field(parts[j],"polygon",poly(points))
    for side,source in enumerate(side_sources):
        # Native source slices preserve every UV pixel; assign each strip's true
        # ground-foot depth, rather than one front-depth value for the whole wall.
        cuts=[0,358,440,520,600,680,740,780,860,940,1024]
        for band,(lo,hi) in enumerate(zip(cuts,cuts[1:])):
            clipped=clip_y(clip_y(source,lo,True),hi,False)
            points=[[(x-768)*.35,(y-780)*.35] for x,y in clipped]
            uv=[[x+194,y+89] for x,y in clipped]
            depth=math.floor(ground_y(max(358,hi))/4+.5)
            extra.append(f'[node name="{ident}Rail{side}Band{band}" type="Polygon2D" parent="Terrain/{ident}"]\nz_index = {depth}\nz_as_relative = false\ntexture = ExtResource("20_ybuvq")\npolygon = '+poly(points)+'\nuv = '+poly(uv)+'\n\n')
for name,x0,x1 in [("WestFrontBank",110,500),("EastFrontBank",2400,2790)]:
    extra.append(f'[node name="{name}" type="Polygon2D" parent="Terrain"]\nz_index = 273\nz_as_relative = false\ntexture = ExtResource("19_6afsi")\npolygon = '+poly([[x1,1040],[x0,1040],[x0,1100],[x1,1100]])+'\nuv = '+poly([[493,397],[493+(x1-x0)/.7,397],[493+(x1-x0)/.7,547],[493,547]])+'\n\n')
for name,box in [("Cliff0",[110,105,2680,10]),("Cliff1",[2785,110,10,990]),("Cliff2",[2115,1095,675,10]),("Cliff3",[1215,1095,770,10]),("Cliff4",[110,1095,975,10]),("Cliff5",[105,110,10,990])]:
    data["blockers"].append({"path":"Terrain/"+name,"polygon":rect(*box)})
candidate="".join(parts)+"".join(extra)
candidate=candidate.replace('layout_path = "res://art/modules/four_settlements_20261030e/linxi_master.json"','layout_path = "'+RES+'linxi_master.json"')
candidate=candidate.replace('path="res://art/modules/four_settlements_20261030e/linxi_master_ground.gdshader"','path="'+RES+'linxi_master_ground.gdshader"')
shader=(ROOT/SHADER).read_text(encoding="utf-8")
insert=""
for a,b in zip(data["roads"][-1]["points"],data["roads"][-1]["points"][1:]):
    insert+=f'path=max(path,1.-smoothstep(45.,75.,segment(p,vec2({a[0]}.,{a[1]}.),vec2({b[0]}.,{b[1]}.))));\n'
shader=shader.replace("vec3 grass=",insert+"vec3 grass=")
locations=json.loads((ROOT/LOC).read_text(encoding="utf-8"))
locations["linxi_tutorial"]["scene"]=RES+"linxi_master.tscn"
locations["linxi_tutorial"]["layout_version"]=3002
for key in locations:
    if key!="linxi_tutorial":assert locations[key]==json.loads((ROOT/LOC).read_text(encoding="utf-8"))[key]
assert locations["linxi_tutorial"]["returns"]==json.loads((ROOT/LOC).read_text(encoding="utf-8"))["linxi_tutorial"]["returns"]
if not (HERE/"linxi_master_ground.gdshader").exists():
    (HERE/"linxi_master_ground.gdshader").write_text(shader.rstrip()+"\n",encoding="utf-8")
else:
    assert (HERE/"linxi_master_ground.gdshader").read_text(encoding="utf-8")==shader.rstrip()+"\n","Shader source edits must use apply_patch, never overwritten by generator"
for filename,value in [("linxi_master.tscn",candidate),("linxi_master.json",json.dumps(data,ensure_ascii=False,indent=2)+"\n"),("locations_READY.json",json.dumps(locations,ensure_ascii=False,indent=2)+"\n")]:
    (HERE/filename).write_text(value.rstrip()+"\n",encoding="utf-8")
facts={"status":"CANDIDATE_ONLY_NO_ENGINE", "before":before,"rooms_returns_exact":True,"other_locations_exact":True,"original_business_exact":True,"buildings":changes,"original_cliff_bounds":[500,350,2400,1100],"new_cliff_bounds":[110,110,2790,1100],"native_scale_max":.72,"new_wall_source_slices":40,"engine_calls":0,"old_source_writes":0}
(HERE/"candidate_facts.json").write_text(json.dumps(facts,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
assert all(sha(ROOT/key)==value["sha256"] for key,value in before.items())
print(json.dumps({"status":facts["status"],"house_scales":{key:value["scale"] for key,value in changes.items()},"new_scene_sha256":sha(HERE/"linxi_master.tscn"),"old_sources_exact":True}))
