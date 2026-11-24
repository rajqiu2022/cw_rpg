"""New-file-only Redrock town authoring and independent project validation."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import re
import shutil
import sys
from pathlib import Path

import numpy as np
import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAME = "redrock_town_20261028a"
RAW = ROOT / "assets/raw" / NAME
STAGE = ROOT / "assets/staging" / NAME
PROJECT = STAGE / "town_project"
QUEUE = STAGE / "production/prompts"
ART = f"art/modules/{NAME}"
SCENE = f"scenes/drafts/{NAME}/redrock_town.tscn"
SCRIPT = f"scripts/drafts/{NAME}/town_controller.gd"
REFS = ["assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png", "assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_inn_v1.png"]
COMMON = """Use case: stylized-concept
Asset type: ONE isolated transparent native map module for an elevated orthographic 2.5D wuxia RPG canyon town. Image1 is the user-approved red sandstone canyon-town plan: reference for dry stepped town life only, do NOT crop or reproduce the whole scene. Image2 is our existing town inn: STRICT matching reference for reddish matte masonry, small blocks, aged dark timber, restrained painted texture, upper-left warm daylight, horizontal front base/courses and visible TOP and restrained RIGHT depth face. NEW subject, not the inn. No perspective lens, horizon, dome, European roof, Chinese curved/tiled eaves, flags, logos, lettering, UI, arrows or people/animals. One coherent grounded component with every end fully visible. Actual transparent alpha0 surroundings, no floor rectangle, backdrop, mist, glow or detached dust/shadow. Keep ALL alpha>0 including thin branches/shade within the central60% of BOTH canvas dimensions: at least20% genuinely transparent margin all4 sides. No clipping, separate variants or kit sheet. No broad ground island. Tight attached contact shading only.
"""
ART_ITEMS = {
    "dwelling": ("building", "赤岩·阶街平顶民居", """ONE modest SINGLE-STOREY two-room red sandstone dwelling, asymmetrical low flat roof with thick low parapet and a small rear storage volume set back. Weathered pale clay plaster patches on a few walls, one plain closed adult-size timber entrance near FRONT CENTER, two narrow dark window shutters, short projecting straight ceiling beams. Door opening height around half the masonry body height; readable adult proportions, broad low silhouette, less grand and narrower than the inn. Three small stone steps at the front door, a shallow stone foundation only. No external stair to roof, outer yard wall, gates, courtyard or detached props. Entire FRONT facade reads horizontally with only a short right depth wall. Landscape canvas with large empty transparent border."""),
    "stable": ("building", "赤岩·商旅牲口棚", """ONE long open-front pack-animal STABLE shelter, same sandstone/timber world. A FLAT rough plank and reed roof on substantial dark straight posts, thick low sandstone back wall and short side return; three open front bays, two short timber bay dividers only at the rear, simple timber hay rack against rear wall, no front fence or rails across the entrance. No horse/camel or person. Front bays open down to the ground with true transparency. Simple rough cloth wind screen rolled up at one end. No curved eaves, tiles, peaked roof, courtyard, trough outside or floor island. The whole shelter around2.5 times wider than high, all footings and roof ends inside20% transparent margins. Landscape canvas."""),
    "terrace": ("landform", "赤岩·层台岩坎立面", """ONE long low horizontal RED SANDSTONE TERRACE RISER / cliff ledge module. Natural stratified canyon rock frontal face, broad roughly level irregular top lip and a short shallow visible rocky top surface, dark recesses and eroded blocky strata, no masonry/coping. Long continuous rock volume about5 times as wide as high. Both ends taper naturally into small low outcrops rather than exposing a rectangular cut or abruptly clipped pillar, all ends complete. Front foot lies along an almost horizontal baseline with small natural irregularity. Top lip simple enough to sit below a separate flat game ground polygon. No tall butte, boulders scattered in front, stairs, road, vegetation, buildings, wall or giant ground island. Not a scene: only one continuous low rock cliff front on actual transparent background. Landscape canvas; object fits comfortably inside central60% both dimensions."""),
}


def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def save(p, value):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", "utf-8")


def prepare():
    assert not (RAW / "manifest.json").exists()
    (QUEUE / "templates").mkdir(parents=True)
    sys.path.insert(0, str(ROOT / "scripts"))
    import gen_assets as renderer
    renderer.TEMPLATES_DIR = QUEUE / "templates"
    refs = [str(ROOT / p) for p in REFS]
    template = "redrock_town_module_20261028a"
    (QUEUE / "templates" / (template + ".yaml")).write_text(yaml.safe_dump({"name": template, "prompt_template": "{asset_prompt}", "size": "1536x1024", "quality": "high", "background": "transparent", "reference_images": refs, "require_reference_images": True}, allow_unicode=True, sort_keys=False), "utf-8")
    rows, tasks = [], []
    for key, (kind, label, detail) in ART_ITEMS.items():
        prompt = COMMON + "\nRequested subject:\n" + detail
        ident = NAME + "_" + key + "_v1"
        path = QUEUE / (ident + ".txt")
        path.write_text(prompt, "utf-8")
        assert renderer.render_template(template, {"asset_prompt": prompt}, {})["prompt"] == prompt.strip()
        rows.append({"key": key, "id": ident, "kind": kind, "label": label, "prompt": path.relative_to(ROOT).as_posix(), "prompt_sha256": sha(path), "references": REFS, "reference_sha256": {p: sha(ROOT/p) for p in REFS}, "calls": 0, "status": "REGISTERED"})
        tasks.append({"id": ident, "template": template, "skip": True, "execution_backend": "builtin_image_gen", "attempt_budget": 1, "retries_allowed": False, "cli_fallback_allowed": False, "transparent_background": True, "reference_images": refs, "vars": {"asset_prompt": prompt}})
    (QUEUE / "tasks.yaml").write_text(yaml.safe_dump({"tasks": tasks}, allow_unicode=True, sort_keys=False), "utf-8")
    save(RAW / "manifest.json", {"status": "REGISTERED", "assets": rows, "formal_enabled": False, "backend": "builtin_image_gen", "model": None, "cost": None})
    protected = [ROOT/"game/project.godot", ROOT/"prompts/tasks.yaml", ROOT/"scripts/gen_assets.py"]
    protected += list((ROOT/"game/scripts/autoload").glob("*.gd"))
    protected += list((ROOT/"game/scripts/field").glob("*.gd"))
    for rel in ("game/art/modules/redrock_joint_editor_20261023f", "game/scenes/drafts/redrock_joint_editor_20261023f", "game/scripts/drafts/redrock_joint_editor_20261023f"):
        protected += [p for p in (ROOT/rel).rglob("*") if p.is_file()]
    protected += [p for p in (Path(os.environ["APPDATA"])/"Godot/app_userdata/云影侠传").rglob("save*") if p.is_file()]
    save(STAGE/"protected-before.json", [{"path":str(p),"sha256":sha(p),"bytes":p.stat().st_size,"mtime_ns":p.stat().st_mtime_ns} for p in sorted(set(protected))])
    save(STAGE/"preflight.json", {"rendered":3,"passed":True,"queue_isolated":True,"root_queue_written":False,"read_write_namespace":NAME})
    print("Registered 3 isolated art tasks; captured protected sources")


def start(key):
    m=json.loads((RAW/"manifest.json").read_text("utf-8"));r=next(r for r in m["assets"] if r["key"]==key)
    assert r["calls"]==0 and r["status"]=="REGISTERED"
    assert sha(ROOT/r["prompt"])==r["prompt_sha256"]
    assert all(sha(ROOT/p)==d for p,d in r["reference_sha256"].items())
    r.update(calls=1,status="DISPATCHED");save(RAW/"manifest.json",m)
    print((ROOT/r["prompt"]).read_text("utf-8"))


def record(key,source):
    m=json.loads((RAW/"manifest.json").read_text("utf-8"));r=next(r for r in m["assets"] if r["key"]==key)
    assert r["status"]=="DISPATCHED"
    out=RAW/r["kind"]/(r["id"]+".png");assert not out.exists();out.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(source,out)
    with Image.open(out) as im:
        assert im.mode=="RGBA"
        bbox=im.getchannel("A").getbbox();w,h=im.size
        margins=[bbox[0]/w,bbox[1]/h,(w-bbox[2])/w,(h-bbox[3])/h]
        r.update(size=[w,h],mode=im.mode,metrics={"full_alpha_bbox":list(bbox),"margins":margins,"margin_10_percent_pass":min(margins)>=.1})
    r.update(output=out.relative_to(ROOT).as_posix(),sha256=sha(out),status="RAW_CANDIDATE",transparent=True,fallback_used=False,source_path=source,review_note="赤岩六区布局用原生候选；原像素保持，完整留白状态单列，未获正式世界准入。")
    assert sha(out)==sha(Path(source))
    save(RAW/"manifest.json",m);save(out.with_suffix(".meta.json"),{**r,"model":None,"provider":None,"cost":None})
    save(RAW/"resource-pack.json",{"status":"EDITOR_LAYOUT_CANDIDATES","assets":[r for r in m["assets"] if r.get("output")]})
    print(json.dumps({"key":key,"size":r["size"],"margin_pass":r["metrics"]["margin_10_percent_pass"]}))


START = [2250, 4480]
ZONES = [
    {"key":"gate","name":"峡口关门","focus":[2250,3910],"arrival":[2250,4310]},
    {"key":"lanes","name":"阶街民巷","focus":[2500,1240],"arrival":[2500,1560]},
    {"key":"inn","name":"驿舍马院","focus":[2380,2860],"arrival":[2250,3170]},
    {"key":"workshop","name":"石作修坊","focus":[4540,2210],"arrival":[4470,2400]},
    {"key":"water","name":"蓄水小院","focus":[1100,2180],"arrival":[1150,2390]},
    {"key":"lookout","name":"高台望关","focus":[4350,850],"arrival":[4300,1010]},
]
ROUTES = {
    "main": [[2250,4480],[2250,3380],[3650,3380],[3650,2720],[2350,2720],[2350,2100],[3700,2100],[3700,1010],[4300,1010]],
    "water": [[2350,2720],[1750,2720],[1750,2390],[1150,2390]],
    "workshop": [[3650,2720],[3650,2400],[4470,2400]],
    "lanes": [[3700,2100],[3700,1560],[1300,1560],[1300,1020],[3500,1020],[3700,1150]],
    "inn_front": [[2250,3380],[2250,3170],[1650,3170]],
    "stable_front": [[2250,3170],[3050,3170],[3650,3170]],
}
BOUNDARY = [[600,400],[4300,300],[5200,600],[5600,1600],[5540,3250],[5100,4150],[3000,4250],[2750,4900],[1800,4900],[1650,4200],[300,4080],[180,2700],[300,1100]]


def fmt(value): return format(float(value), ".9g")
def vec(p): return "Vector2(" + ", ".join(fmt(v) for v in p) + ")"
def poly(points): return "PackedVector2Array(" + ", ".join(fmt(v) for p in points for v in p) + ")"


def build(revise=False):
    assert not (STAGE/'publication.json').exists(), "Published project is frozen"
    if revise:
        assert (PROJECT/'artifacts/verification.json').is_file()
        archive=STAGE/'initial-failed-run';assert not archive.exists();archive.mkdir()
        for p in (PROJECT/'artifacts').iterdir():
            if p.is_file():shutil.copyfile(p,archive/p.name)
        for name in ('verify.stdout.log','verify.stderr.log','town_layout.json'):
            shutil.copyfile(PROJECT/name,archive/name)
        save(archive/'revision-reason.json',{"original_failed":2,"reason":"LanesLedge过宽放大致碰撞顶侵入民巷，修两短等比段；新增六侧巷民居与路面可读性。原52成功组件继承，残余只核新段/新屋/民巷与新实图。"})
    else:
        assert not PROJECT.exists(), "Use explicit revise for unpublished owned project"
    rows = json.loads((RAW/"resource-pack.json").read_text("utf-8"))["assets"]
    assert len(rows)==3
    sources={r["key"]:r["output"] for r in rows}
    life=json.loads((ROOT/"assets/raw/redrock_desert_life_20261025a/resource-pack.json").read_text("utf-8"))["assets"]
    sources.update({r["key"]:r["output"] for r in life})
    for key in ("core","left","right","guard","earth"):
        sources[key]=f"game/art/modules/redrock_joint_editor_20261023f/{key}.png"
    old=json.loads((ROOT/"assets/processed/redrock_gate_20261023b/resource-pack.json").read_text("utf-8"))["assets"]
    for key in ("tower","trough","cargo"):
        sources[key]=next(r["output"] for r in old if r["key"]==key)
    sources["rock"]="assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_rock_v1.png"
    media=[];bbox={}
    for key,source in sources.items():
        dest=PROJECT/ART/(key+".png");dest.parent.mkdir(parents=True,exist_ok=True)
        if dest.exists():assert sha(dest)==sha(ROOT/source)
        else:shutil.copyfile(ROOT/source,dest)
        with Image.open(dest) as im:
            if "A" in im.getbands():
                a=np.asarray(im.getchannel("A"));yy,xx=np.where(a>=128);bb=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
            else:bb=[0,0,im.width,im.height]
            bbox[key]=bb
        media.append({"key":key,"source":source,"destination":f"{ART}/{key}.png","sha256":sha(dest),"diagnostic_alpha128_bbox":bb,"original_pixels_changed":False})
    scene=['[gd_scene format=3]',f'[ext_resource type="Script" path="res://{SCRIPT}" id="controller"]',f'[ext_resource type="Shader" path="res://{ART}/ground.gdshader" id="ground_shader"]']
    scene += [f'[ext_resource type="Texture2D" path="res://{ART}/{key}.png" id="{key}"]' for key in sources]
    scene += ['[sub_resource type="RectangleShape2D" id="actor_body"]\nsize = Vector2(35, 25)', '[sub_resource type="SystemFont" id="font"]\nfont_names = PackedStringArray("Microsoft YaHei", "Noto Sans CJK SC")', '[sub_resource type="StyleBoxFlat" id="panel"]\nbg_color = Color(0.10, 0.065, 0.04, 0.90)\ncorner_radius_top_left = 8\ncorner_radius_top_right = 8\ncorner_radius_bottom_left = 8\ncorner_radius_bottom_right = 8', '[sub_resource type="ShaderMaterial" id="ground_material"]\nshader = ExtResource("ground_shader")\nshader_parameter/earth_tex = ExtResource("earth")\nshader_parameter/rock_tex = ExtResource("rock")', '[node name="RedrockTown" type="Node2D"]\nscript = ExtResource("controller")\nmetadata/status = "赤岩六区可编辑布局草案；非正式世界入口"', '[node name="Ground" type="Polygon2D" parent="."]\nz_index = -20\nmaterial = SubResource("ground_material")\npolygon = '+poly(BOUNDARY), '[node name="Town" type="Node2D" parent="."]\ny_sort_enabled = true']
    instances=[]

    def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]
    def instance(name,key,foot,scale,body=None,note="",height=None):
        b=bbox[key]
        if height is not None:scale=height/(b[3]-b[1])
        pivot=[(b[0]+b[2])/2,b[3]]
        visible=[(b[0]-pivot[0])*scale,(b[1]-pivot[1])*scale,(b[2]-b[0])*scale,(b[3]-b[1])*scale]
        scene.append(f'[node name="{name}" type="Node2D" parent="Town"]\nposition = {vec(foot)}\nmetadata/label = "{note}"\nmetadata/visual_rect = Rect2({", ".join(fmt(v) for v in visible)})')
        scene.append(f'[node name="Art" type="Sprite2D" parent="Town/{name}"]\nposition = {vec([-p*scale for p in pivot])}\nscale = {vec([scale,scale])}\ntexture = ExtResource("{key}")\ncentered = false')
        if body:
            scene.append(f'[node name="Body" type="StaticBody2D" parent="Town/{name}"]\ncollision_layer = 1\ncollision_mask = 0')
            for i,points in enumerate(body):scene.append(f'[node name="Footprint{i}" type="CollisionPolygon2D" parent="Town/{name}/Body"]\npolygon = '+poly(points))
        instances.append({"name":name,"key":key,"foot":foot,"scale":scale,"source_pivot":pivot,"visual_rect":visible,"footprints":body or [],"note":note})

    # Reuse the CONNECTED gate, preserving all three relative transforms and feet.
    scene += ['[node name="Gate" type="Node2D" parent="Town"]\nposition = Vector2(-400, 4025)', '[node name="Body" type="StaticBody2D" parent="Town/Gate"]\ncollision_layer = 1\ncollision_mask = 0']
    old_scene=(ROOT/"game/scenes/drafts/redrock_joint_editor_20261023f/redrock_joint.tscn").read_text("utf-8")
    for node,key in (("LeftWing","left"),("Core","core"),("RightWing","right")):
        block=re.search(r'\[node name="'+node+r'"[^\]]*\](.*?)(?=\[node|\Z)',old_scene,re.S)[1]
        pos=[float(v) for v in re.search(r'position = Vector2\(([^)]+)\)',block)[1].split(',')];pos[1]-=1325
        scale=re.search(r'scale = (Vector2\([^)]+\))',block)[1]
        scene.append(f'[node name="{node}" type="Sprite2D" parent="Town/Gate"]\nposition = {vec(pos)}\nscale = {scale}\ntexture = ExtResource("{key}")\ncentered = false')
    gate_polygons={}
    for match in re.finditer(r'\[node name="([^"]+)" type="CollisionPolygon2D" parent="Collision"\](.*?)(?=\[node|\Z)',old_scene,re.S):
        if match[1]=="GroundBoundary":continue
        values=[float(v) for v in re.search(r'polygon = PackedVector2Array\(([^)]+)\)',match[2])[1].split(',')]
        points=[[values[i],values[i+1]-1325] for i in range(0,len(values),2)]
        scene.append(f'[node name="{match[1]}" type="CollisionPolygon2D" parent="Town/Gate/Body"]\npolygon = '+poly(points))
        gate_polygons[match[1]]=[[x-400,y+4025] for x,y in points]

    instance("Inn","inn",[1650,3000],.82,[rect(-430,-115,850,100)],"驿舍：平顶接待楼，本轮仅外观与院场。")
    instance("Stable","stable",[2950,3040],.65,[rect(-510,-120,1000,34)]+[rect(x,-22,38,26) for x in (-495,-165,145,458)],"牲口棚：前湾开放；尚未配置牲口。")
    instance("Workshop","repair_shed",[4350,2300],.80,[rect(-470,-115,930,30)]+[rect(x,-28,40,30) for x in (-450,-210,370)],"修车棚：开放工作湾与后墙，物件可调查。")
    instance("WaterWell","cistern",[1100,2280],.70,[rect(-130,-125,260,125)],"蓄水井棚：展示取水设施，未绑定正式饮水服务。")
    for i,(x,y,s) in enumerate(((1700,1450,.65),(2550,1390,.65),(3230,1450,.61),(2030,850,.60),(2920,850,.60),(870,1260,.50),(850,800,.50),(4300,1770,.65),(5100,1800,.52),(4600,3040,.60),(1180,3180,.50))):
        w=(bbox['dwelling'][2]-bbox['dwelling'][0])*s
        instance(f"Dwelling{i+1}","dwelling",[x,y],s,[rect(-w*.48,-110,w*.96,92)],"阶街民居：门前留巷，室内尚未制作。")
    instance("Lookout","tower",[4350,850],1,[rect(-270,-130,540,128)],"望关台：远眺外观地标；本轮没有登楼内景。",height=600)
    # Terrace fronts stay outside routes, with full vertical-face exclusion footprints.
    for name,x,y,width in (("LowLeft",1110,3600,1400),("LowRight",4700,3600,1500),("WaterLedge",995,2800,1350),("WorkLedge",4730,2800,1420),("LanesLedgeWest",1375,2050,1650),("LanesLedgeEast",2760,2050,1470),("LookoutLedge",4450,1320,950)):
        s=width/(bbox['terrace'][2]-bbox['terrace'][0]);h=(bbox['terrace'][3]-bbox['terrace'][1])*s
        instance(name,"terrace",[x,y],s,[rect(-width*.48,-h*.72,width*.96,h*.72)],"")
    for name,key,foot,height,body,note in (
        ("WheelBench","wheelbench",[4930,2370],150,[rect(-80,-45,160,45)],"修车工作台：车轮、轴木与木槌；不发任务奖励。"),
        ("WaterJars","water_jars",[760,2340],115,[rect(-58,-38,116,38)],"储水罐：可放置场景实体。"),
        ("InnCargo","cargo",[2100,3000],95,[rect(-60,-45,120,45)],"商队货垛：候检与驿舍周转物。"),
        ("StableTrough","trough",[3400,3090],70,[rect(-150,-35,300,35)],"饮水槽：靠棚侧放置，通道保持开放。"),
        ("OreSample","ore_cluster",[5180,2350],145,[rect(-95,-50,190,50)],"岩矿调查点：仅视觉调查，无新增掉落或Item ID。"),
        ("WaterTree","dry_tree",[470,2270],350,[rect(-24,-30,48,30)],""),
        ("InnTree","dry_tree",[790,2990],290,[rect(-22,-28,44,28)],""),
    ):instance(name,key,foot,1,body,note,height=height)
    for i,(x,y,h) in enumerate(((650,3650,85),(1690,3830,76),(5050,3820,83),(5200,3030,74),(420,2640,82),(510,1740,72),(5400,2100,77),(4100,560,64),(1060,900,80))):
        instance(f"Shrub{i+1}","dry_shrub",[x,y],1,None,"",height=h)
    instance("GateSentinel","guard",[2470,4190],1,None,"关门查看员：旧匿名待机精灵；没有新增NPC身份或行走动画。",height=112)
    scene += ['[node name="Inspector" type="CharacterBody2D" parent="Town"]\nposition = '+vec(START)+'\ncollision_layer = 2\ncollision_mask = 1\nmotion_mode = 1','[node name="Foot" type="CollisionShape2D" parent="Town/Inspector"]\nshape = SubResource("actor_body")']
    b=bbox['guard'];s=112/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]]
    scene.append('[node name="Art" type="Sprite2D" parent="Town/Inspector"]\nposition = '+vec([-p*s for p in pivot])+'\nscale = '+vec([s,s])+'\ntexture = ExtResource("guard")\ncentered = false')
    scene += ['[node name="Boundary" type="StaticBody2D" parent="."]\ncollision_layer = 1\ncollision_mask = 0','[node name="Outline" type="CollisionPolygon2D" parent="Boundary"]\nbuild_mode = 1\npolygon = '+poly(BOUNDARY),'[node name="Camera" type="Camera2D" parent="."]\nposition = Vector2(2870,2600)\nzoom = Vector2(0.205,0.205)','[node name="UI" type="CanvasLayer" parent="."]']
    scene += ['[node name="TopPanel" type="Panel" parent="UI"]\noffset_left = 22.0\noffset_top = 18.0\noffset_right = 1000.0\noffset_bottom = 110.0\ntheme_override_styles/panel = SubResource("panel")']
    for name,text,x,y,size in (("Title","赤岩关镇 · 峡谷阶街",42,28,28),("Status","六区连通布局草案 · 关门—驿舍—修坊—水院—民巷—望台",44,72,19),("Hint","WASD / 方向键移动　Shift快走　Tab全景/跟随　1—6查看分区　R回关外　空格查看物件　Esc关闭说明",30,1034,19)):
        scene.append(f'[node name="{name}" type="Label" parent="UI"]\noffset_left = {x}.0\noffset_top = {y}.0\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = {size}\ntext = "{text}"')
    scene += ['[node name="Detail" type="Panel" parent="UI"]\nvisible = false\noffset_left = 1120.0\noffset_top = 28.0\noffset_right = 1895.0\noffset_bottom = 210.0\ntheme_override_styles/panel = SubResource("panel")','[node name="Text" type="Label" parent="UI/Detail"]\noffset_left = 22.0\noffset_top = 20.0\noffset_right = 748.0\noffset_bottom = 150.0\nautowrap_mode = 2\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = 22']
    path=PROJECT/SCENE;path.parent.mkdir(parents=True,exist_ok=True);path.write_text('\n\n'.join(scene)+'\n','utf-8')
    target=PROJECT/SCRIPT;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(STAGE/'source/town_controller.gd',target)
    save(PROJECT/'town_layout.json',{"zones":ZONES,"routes":ROUTES,"boundary":BOUNDARY,"start":START,"instances":instances,"media":media,"gate_polygons":gate_polygons,"scene":SCENE,"formal_world_entry":False})
    (PROJECT/'project.godot').write_text('config_version=5\n[application]\nconfig/name="赤岩独立布局验证20261028a"\nrun/main_scene="res://'+SCENE+'"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="redrock_town_20261028a_validation"\nconfig/features=PackedStringArray("4.6", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\nenvironment/defaults/default_clear_color=Color(0.16,0.10,0.065,1)\n','utf-8')
    # Asset-based world-space material blending, not a painted map/background.
    shader='shader_type canvas_item;\nrender_mode unshaded;\nuniform sampler2D earth_tex : source_color, repeat_enable, filter_linear;\nuniform sampler2D rock_tex : source_color, repeat_enable, filter_linear;\nvarying vec2 world_pos;\nvoid vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}\nfloat distseg(vec2 p,vec2 a,vec2 b){vec2 ab=b-a;return length(p-a-ab*clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0));}\nvoid fragment(){vec2 p=world_pos;float d=99999.0;\n'
    for points in ROUTES.values():
        for a,b in zip(points,points[1:]):shader+=f'd=min(d,distseg(p,vec2({fmt(a[0])},{fmt(a[1])}),vec2({fmt(b[0])},{fmt(b[1])})));\n'
    shader+='vec3 dirt=texture(earth_tex,p/1450.0).rgb; vec3 stone=texture(rock_tex,p/1850.0).rgb; float road=1.0-smoothstep(125.0,230.0,d); vec3 smoothdirt=(dirt+texture(earth_tex,p/1450.0+vec2(.31,.27)).rgb)*0.5; vec3 path=mix(smoothdirt,vec3(0.68,0.47,0.29),0.56); COLOR=vec4(mix(mix(dirt,stone,0.28)*0.86,path,road),1.0);}\n'
    (PROJECT/ART/'ground.gdshader').write_text(shader,'utf-8')
    # A technical layout diagram, explicitly not new concept art or a playable background.
    svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1100" viewBox="0 0 6000 5500"><rect width="6000" height="5500" fill="#241b16"/><g fill="#514130" stroke="#c49b65" stroke-width="10"><polygon points="'+" ".join(f'{x},{y}' for x,y in BOUNDARY)+'"/></g><g fill="none" stroke="#efd0a0" stroke-width="110" stroke-linejoin="round" stroke-linecap="round">']
    svg += ['<polyline points="'+" ".join(f'{x},{y}' for x,y in points)+'"/>' for points in ROUTES.values()]
    svg += ['</g><g font-family="Microsoft YaHei" font-size="100" fill="#fff3da">']
    for z in ZONES:svg += [f'<text x="{z["focus"][0]-220}" y="{z["focus"][1]-80}">{z["name"]}</text>']
    svg += ['<text x="350" y="5250" font-size="76">赤岩六区技术平面｜用于节点与动线定位，不替代已确认美术总规</text></g></svg>']
    (STAGE/'layout-plan.svg').write_text(''.join(svg),'utf-8')
    save(STAGE/'layout.json',json.loads((PROJECT/'town_layout.json').read_text('utf-8')))
    print(json.dumps({"scene":SCENE,"media":len(media),"instances":len(instances),"routes":len(ROUTES),"zones":len(ZONES)}))


def configure_imports():
    count=0
    for p in (PROJECT/ART).glob('*.png.import'):
        text=p.read_text('utf-8').replace('process/fix_alpha_border=true','process/fix_alpha_border=false').replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
        p.write_text(text,'utf-8');count+=1
    assert count==len(json.loads((STAGE/'layout.json').read_text('utf-8'))['media'])
    print('Configured lossless unmodified RGBA imports:',count)


def publish():
    assert not (STAGE/'publication.json').exists()
    proof=json.loads((PROJECT/'artifacts/verification-remaining.json').read_text('utf-8'))
    visual=json.loads((PROJECT/'artifacts/final-visual.json').read_text('utf-8'))
    assert proof['passed'] and visual['passed']
    layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
    files=[]
    for row in layout['media']:
        side=row['destination']+'.import'
        text=(PROJECT/side).read_text('utf-8')
        assert 'process/fix_alpha_border=false' in text and 'compress/mode=0' in text
        ctex=re.search(r'(?m)^path="res://([^"]+\.ctex)"',text)[1]
        files += [ctex,ctex[:-5]+'.md5',side]
        assert sha(ROOT/row['source'])==row['sha256']==sha(PROJECT/row['destination'])
    files += [SCRIPT,SCRIPT+'.uid',ART+'/ground.gdshader',ART+'/ground.gdshader.uid']
    files += [r['destination'] for r in layout['media']]
    files += [SCENE]
    for rel in files:
        assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
    copied=[]
    for rel in files:
        dest=ROOT/'game'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,dest)
        assert sha(dest)==sha(PROJECT/rel)
        copied.append({'path':'game/'+rel,'sha256':sha(dest),'bytes':dest.stat().st_size})
    kinds={'guard':'npc_sprite','earth':'ground','rock':'ground','left':'landform','right':'landform','terrace':'landform','water_jars':'scene_prop','wheelbench':'scene_prop','ore_cluster':'scene_prop','cargo':'scene_prop','trough':'scene_prop','dry_tree':'vegetation','dry_shrub':'vegetation'}
    labels={r['key']:r['label'] for r in json.loads((RAW/'resource-pack.json').read_text('utf-8'))['assets']}
    labels.update({r['key']:r['label'] for r in json.loads((ROOT/'assets/raw/redrock_desert_life_20261025a/resource-pack.json').read_text('utf-8'))['assets']})
    labels.update({'guard':'赤岩·查看员待机','earth':'赤岩·夯土材质','rock':'赤岩·裸岩材质','core':'赤岩·连体关楼核心','left':'赤岩·左墙岩肩','right':'赤岩·右转墙岩肩','tower':'赤岩·望关台','cargo':'赤岩·商队货垛','trough':'赤岩·牲口饮水槽'})
    assets=[{**r,'kind':kinds.get(r['key'],'building'),'label':labels[r['key']],'output':'game/'+r['destination'],'scene':'res://'+SCENE,'review_note':'六区编辑布局草案采用；原PNG字节保持，非正式世界或美术终验。'} for r in layout['media']]
    pack={'status':'SIX_ZONE_EDITOR_LAYOUT_NOT_FORMAL_WORLD','scene':'res://'+SCENE,'validated_image_count':20,'resource_status_label':'六区编辑草案 · 已装配','assets':assets,'raw_alpha_admission_changed':False}
    save(ROOT/'game'/ART/'resource-pack.json',pack)
    save(STAGE/'publication.json',{'status':pack['status'],'files':copied,'media':20,'instances':40,'zones':6,'new_import_leaves':60,'scene':'game/'+SCENE,'production_import_invoked':False,'shared_router_changed':False,'user_editor_controlled':False})
    before=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
    for row in before:
        p=Path(row['path'])
        if not p.is_file() or sha(p)!=row['sha256'] or p.stat().st_size!=row['bytes'] or p.stat().st_mtime_ns!=row['mtime_ns']:
            changes.append({'path':row['path'],'before':row,'after':{'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} if p.is_file() else None})
    save(STAGE/'protected-after.json',{'checked':len(before),'changes':changes,'save_files_checked':sum('app_userdata' in r['path'] for r in before),'all_equal':not changes,'interpretation':'共享窗口差异原样记录，不回退其它对话变更；本批写域仅新增赤岩目录。'})
    print(json.dumps({'published':len(copied)+1,'protected':len(before),'changed':len(changes),'scene':'game/'+SCENE},ensure_ascii=False))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=("prepare","start","record","build","revise","configure-imports","publish"));p.add_argument("--key");p.add_argument("--source");a=p.parse_args()
    if a.action=="prepare":prepare()
    elif a.action=="start":start(a.key)
    elif a.action=="record":record(a.key,a.source)
    elif a.action=="build":build()
    elif a.action=="revise":build(revise=True)
    elif a.action=="publish":publish()
    else:configure_imports()
