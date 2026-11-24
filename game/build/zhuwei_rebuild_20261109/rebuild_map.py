import hashlib
import json
import re
from pathlib import Path
from PIL import Image

GAME = Path("game")
MAP = GAME / "scenes/drafts/four_settlements_20261030e/zhuwei.tscn"
MODULE = GAME / "art/modules/four_settlements_20261030e"
DATA = MODULE / "zhuwei.json"
SHADER = MODULE / "zhuwei_ground.gdshader"
LOCAL = "art/modules/zhuwei_rebuild_20261109/"
ART = {
    "rebuild_inn": LOCAL + "inn.png",
    "rebuild_residence": LOCAL + "residence.png",
    "rebuild_shop": LOCAL + "shop.png",
    "rebuild_smithy": LOCAL + "smithy.png",
    "stone_residence": "art/modules/linxi_house_variety_20261109/stone_hip_roof_home.png",
    "herbal_residence": "art/modules/linxi_house_variety_20261109/herbal_drying_home.png",
    "wide_residence": "art/modules/miao_building_variety_20261029h/wide_hall.png",
    "small_home": "art/modules/miao_building_variety_20261029h/small_cottage.png",
}

# Position, scale, north terrace. The inn uses the authored door axis as origin.
placements = {
    "Inn": ("rebuild_inn", (950,1800), .65, 0, "竹尾客栈"),
    "Smithy": ("rebuild_smithy", (3230,2320), .32, 0, "铁作铺"),
    "Home0": ("rebuild_residence", (930,710), .38, 1, "北巷连翼大宅"),
    "Home1": ("stone_residence", (2110,720), .57, 1, "北巷石墙民房"),
    "Home2": ("small_home", (2925,675), .33, 1, "后山民房"),
    "Home3": ("herbal_residence", (710,2525), .36, 0, "晒药民家"),
    "Home4": ("stone_residence", (3220,2800), .48, 0, "河路石墙民居"),
    "BackHouse0": ("wide_residence", (1530,635), .36, 1, "北巷长屋"),
    "BackHouse1": ("small_home", (2530,690), .33, 1, "北巷小院"),
    "BackHouse2": ("stone_residence", (800,1170), .44, 0, "西巷石屋"),
    "BackHouse3": ("herbal_residence", (3550,1225), .36, 0, "东巷带廊民家"),
    "BackHouse4": ("rebuild_residence", (1560,2820), .35, 0, "南街连翼民宅"),
    "Market1": ("rebuild_shop", (2225,1745), .34, 0, "竹棚药铺"),
    "WestLaneHouse1": ("small_home", (245,1500), .28, 0, "西巷门房"),
    "WestLaneHouse2": ("stone_residence", (265,2000), .32, 0, "西巷工匠宅"),
    "NorthLaneHouse": ("herbal_residence", (2760,475), .34, 1, "北巷晒架小院"),
    "EastLaneHouse": ("wide_residence", (3830,1645), .36, 0, "东巷合院长屋"),
    "SouthLaneHouse1": ("small_home", (1080,2920), .31, 0, "南街门房"),
    "SouthLaneHouse2": ("herbal_residence", (2600,2910), .38, 0, "南街晒竹院"),
}
routes = [
    (110, [(950,1838),(950,2100),(1300,2180)]),
    (80, [(890,850),(1500,850),(2140,850),(2800,850)]),
    (68, [(1010,2730),(1430,2710),(1800,2680),(2100,2700)]),
    (75, [(3500,2130),(3500,1800),(3760,1735)]),
]
scene = MAP.read_text(encoding="utf-8")
layout = json.loads(DATA.read_text(encoding="utf-8"))
assert "rebuild_inn" not in scene
art_defs = "".join(
    f'[ext_resource type="Texture2D" path="res://{path}" id="{key}"]\n'
    for key, path in ART.items() if key != "small_home"
)
scene = scene.replace("[sub_resource", art_defs+"\n[sub_resource", 1)
# Keep the same authored terrain and formal routing. Depth changes follow actual foundations.
scene = scene.replace("metadata/terrain_baked = true", "metadata/terrain_baked = true\nmetadata/sort_projected_feet = true",1)
shader = SHADER.read_text(encoding="utf-8")
def nums(seq):
    return ", ".join(f"{v:.4f}".rstrip("0").rstrip(".") for v in seq)
def poly(vals):
    return "PackedVector2Array(" + nums([x for pair in vals for x in pair]) + ")"

for name, (key, (x,y), scale, level, label) in placements.items():
    im = Image.open(GAME / ART[key]).convert("RGBA")
    x0,y0,x1,y1=im.getchannel("A").point(lambda a: 255 if a>=128 else 0).getbbox()
    w,h=(x1-x0)*scale,(y1-y0)*scale
    pivot_x=(x0+x1)/2 if name!="Inn" else 817
    left=(x0-pivot_x)*scale
    solid_h=round(h*.24,1)
    l=round(left+w*.12,1)
    r=round(left+w*.91,1)
    if name=="Inn":
        polygon=[(l,-solid_h),(r,-solid_h),(r,-33),(320,-26),(320,0),(-264,0),(-264,-25),(l,-44)]
    else:
        polygon=[(l,-solid_h),(r,-solid_h),(r,-h*.08),(l+w*.08,0)]
    z=round((y-60*level)/4)
    block=f'''[node name="{name}" type="Node2D" parent="Town"]
z_index = {z}
z_as_relative = false
position = Vector2({x}, {y})
metadata/label = "{label}"
metadata/visual_rect = Rect2({nums((left,-h,w,h))})
metadata/fade = true
metadata/terrain_level = {level}
metadata/elevation = {60*level}.0

[node name="Art" type="Sprite2D" parent="Town/{name}"]
position = Vector2({nums((-pivot_x*scale,-y1*scale-60*level))})
scale = Vector2({scale}, {scale})
texture = ExtResource("{key}")
centered = false

[node name="Body" type="StaticBody2D" parent="Town/{name}"]
collision_layer = {16<<level}
collision_mask = 0

[node name="Shape" type="CollisionPolygon2D" parent="Town/{name}/Body"]
polygon = {poly(polygon)}
metadata/sort_front_edge = true

'''
    pattern=rf'\[node name="{name}" type="Node2D" parent="Town"[^\n]*\n.*?(?=\[node name="[^"]+"[^\n]*parent="(?:Town|\.)")'
    scene,count=re.subn(pattern,lambda _:block,scene,count=1,flags=re.S)
    if not count:
        i=scene.index('[node name="Terrain"')
        scene=scene[:i]+block+scene[i:]
    obj={"name":name,"key":key,"foot":[x,y],"height":round(h,4),"width":round(w,4),"scale":scale,"label":label}
    body={"path":f"Town/{name}/Body","polygon":[[round(a,4),round(b,4)] for a,b in polygon]}
    for field,val,identity in [("objects",obj,"name"),("blockers",body,"path")]:
        rows=layout[field]
        pos=next((i for i,row in enumerate(rows) if row[identity]==val[identity]),len(rows))
        rows[pos:pos+1]=[val]

layout["title"]="竹尾村 · 客栈街与北巷"
layout["subtitle"]="客栈前街 · 竹棚药铺 · 北巷民宅 · 武馆与铁作"
for width,points in routes:
    layout["roads"].append({"points":points,"width":width})
    lines=[]
    for a,b in zip(points,points[1:]):
        lines.append(f"path=max(path,1.-smoothstep({width*.62:.2f},{width:.2f},segment(p,vec2({a[0]}.0,{a[1]}.0),vec2({b[0]}.0,{b[1]}.0))));")
    shader=shader.replace("vec3 grass=","\n".join(lines)+"\nvec3 grass=",1)
assert len(layout["objects"])==45
MAP.write_text(scene,encoding="utf-8")
DATA.write_text(json.dumps(layout,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
SHADER.write_text(shader,encoding="utf-8")