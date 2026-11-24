"""Build the city-life revision in an exclusive project before publishing."""
import json
import re
import shutil
from pathlib import Path

from build_redrock_town_20261028a import ROOT, save, sha, vec, poly, fmt
from redrock_city_life_20261029a import NAME, D, B, STAGE, RAW, PROJECT, SCENE, ART

SCRIPT = f'scripts/drafts/{NAME}/town_controller.gd'


def block(text, name, parent):
    return re.search(r'\[node name="' + name + r'"[^\n]*parent="' + parent + r'"[^\n]*\][\s\S]*?(?=\[node |\Z)', text)[0]


def rect(x, y, w, h):
    return [[x, y], [x+w, y], [x+w, y+h], [x, y+h]]


def build():
    assert not PROJECT.exists()
    old = ROOT / 'assets/staging' / D / 'town_project'
    PROJECT.mkdir()
    for folder in ['art', 'scripts', 'scenes']:
        shutil.copytree(old / folder, PROJECT / folder)
    shutil.copytree(old / '.godot/imported', PROJECT / '.godot/imported')
    shutil.copyfile(ROOT / 'game' / SCENE, PROJECT / SCENE)
    shutil.copyfile(STAGE / 'scene-before.tscn', PROJECT / 'before-life.tscn')
    config = (old / 'project.godot').read_text('utf-8').replace(D + '_validation', NAME + '_validation')
    config = config.replace('赤岩生活街段规范验证28b', '赤岩街坊生活验证29a')
    (PROJECT / 'project.godot').write_text(config, 'utf-8')
    (PROJECT / 'artifacts').mkdir()
    manifest = json.loads((RAW / 'manifest.json').read_text('utf-8'))
    assert manifest['status'] == 'RAW_CANDIDATE'
    art_dir = PROJECT / ART
    art_dir.mkdir(parents=True)
    shutil.copyfile(ROOT / manifest['output'], art_dir / 'sandstone_paving.png')
    text = (PROJECT / SCENE).read_text('utf-8')
    text = text.replace(f'res://scripts/drafts/{D}/town_controller.gd', 'res://' + SCRIPT, 1)
    text = text.replace(f'res://art/modules/{D}/ground.gdshader', f'res://{ART}/ground.gdshader', 1)
    ext = f'[ext_resource type="Texture2D" path="res://{ART}/sandstone_paving.png" id="life_paving"]\n\n'
    text = text.replace('[sub_resource', ext + '[sub_resource', 1)
    text = text.replace('shader_parameter/rock_tex = ExtResource("rock")', 'shader_parameter/rock_tex = ExtResource("rock")\nshader_parameter/paving_tex = ExtResource("life_paving")', 1)
    for name, foot in [('Dwelling4', [1750, 840]), ('Dwelling5', [2650, 840])]:
        text, n = re.subn(r'(\[node name="' + name + r'"[^\n]*\]\nposition = )Vector2\([^\n]+', lambda m: m[1] + vec(foot), text, count=1)
        assert n == 1
    text = text.replace('阶街民居：门前留巷，室内尚未制作。', '阶街住户：厚石平顶，门前留有行人巷道。')
    text = text.replace('牲口棚：前湾开放；尚未配置牲口。', '驮兽棚：饮水槽与货垛分列棚侧，前湾留给照料与通行。')
    additions, rows = [], []

    def clone(name, original, foot, label):
        pieces = []
        for h in re.split(r'(?=\[node )', text):
            header = h.splitlines()[0] if h else ''
            if (f'name="{original}" type=' in header and 'parent="Town"' in header) or f'parent="Town/{original}"' in header or f'parent="Town/{original}/' in header:
                h = h.replace(f'name="{original}" type=', f'name="{name}" type=', 1) if 'parent="Town"' in header else h
                h = h.replace(f'parent="Town/{original}', f'parent="Town/{name}')
                if 'parent="Town"' in header:
                    h = re.sub(r'^position = Vector2\([^)]+\)', 'position = ' + vec(foot), h, count=1, flags=re.M)
                    h = re.sub(r'^metadata/label = "[^\n]*', 'metadata/label = ' + json.dumps(label, ensure_ascii=False), h, count=1, flags=re.M)
                pieces.append(h.rstrip())
        assert pieces, original
        additions.extend(pieces)
        rows.append({'name': name, 'template': original, 'foot': foot, 'label': label})

    clone('LifeNorthHome', 'Dwelling1', [3550, 840], '阶街住户：主街与屋后巷分开。')
    clone('LifeEastHome', 'Dwelling1', [5100, 1000], '东巷住户：门前砂岩小坪连接望关街。')
    for name, original, foot, label in [
        ('LifeLaneJarsWest', 'WaterJars', [2070,1475], '住户储水罐：加盖存水，放在门侧。'),
        ('LifeLaneJarsEast', 'WaterJars', [2870,1490], '住户储水罐：避开横街，集中放在墙脚。'),
        ('LifeNorthCargo', 'InnCargo', [2250,930], '行旅货包：暂放屋前，后巷保持通畅。'),
        ('LifeNorthJars', 'WaterJars', [3880,930], '台街储水：有盖陶罐靠近住户。'),
        ('LifeEastJars', 'WaterJars', [5400,1060], '东巷陶罐：住户日常储水。'),
        ('LifeWaterJars1', 'WaterJars', [1480,2260], '蓄水院：取水后的陶罐集中放在井棚侧面。'),
        ('LifeWaterJars2', 'WaterJars', [1600,2210], '蓄水院：封盖水罐与取水队列分开。'),
        ('LifeInnJars', 'WaterJars', [1900,3100], '驿舍储水：候行桌边备水。'),
        ('LifeWorkStone', 'OreSample', [4920,2300], '修坊材料：待整形的砂岩石料。'),
        ('LifeWorkBench', 'WheelBench', [4080,2380], '修坊作业台：车轮与轴木靠工作棚放置。'),
        ('LifeWorkCargo', 'InnCargo', [4120,2290], '修坊周转货：包扎木件放在工作台侧。'),
        ('LifeStableCargo', 'InnCargo', [3860,3040], '马院驮包：货物靠棚边，人行口保持开放。'),
        ('LifeGateCargo1', 'InnCargo', [2850,3470], '候行货包：离开关门主路集中堆放。'),
        ('LifeGateCargo2', 'InnCargo', [3010,3470], '候行货包：沿休息点外侧码放。'),
        ('LifeLookoutJars', 'WaterJars', [4650,1040], '望关台储水：随行用水靠台侧存放。'),
    ]:
        clone(name, original, foot, label)

    base = json.loads((ROOT / 'assets/staging' / B / 'layout.json').read_text('utf-8'))
    boxes = {r['key']: r['diagnostic_alpha128_bbox'] for r in base['media']}

    def furniture(name, key, foot, height, body, label):
        b = boxes[key]
        s = height/(b[3]-b[1])
        pivot = [(b[0]+b[2])/2, b[3]]
        visual = [(b[0]-pivot[0])*s, -height, (b[2]-b[0])*s, height]
        additions.extend([
            f'[node name="{name}" type="Node2D" parent="Town"]\nposition = {vec(foot)}\nmetadata/label = {json.dumps(label,ensure_ascii=False)}\nmetadata/visual_rect = Rect2({", ".join(fmt(v) for v in visual)})',
            f'[node name="Art" type="Sprite2D" parent="Town/{name}"]\nposition = {vec([-v*s for v in pivot])}\nscale = {vec([s,s])}\ntexture = ExtResource("{key}")\ncentered = false',
            f'[node name="Body" type="StaticBody2D" parent="Town/{name}"]\ncollision_layer = 1\ncollision_mask = 0',
            f'[node name="Base" type="CollisionPolygon2D" parent="Town/{name}/Body"]\npolygon = {poly(body)}',
        ])
        rows.append({'name': name, 'key': key, 'foot': foot, 'height': height, 'polygon': body, 'label': label})

    for name, key, foot, height, body, label in [
        ('LifeInnTable','table',[1300,3090],80,rect(-59,-27.8,118,27.8),'驿舍候行桌：与前厅入口分开。'),
        ('LifeInnBench','bench',[1300,3160],50,rect(-75,-18,150,18),'候行长凳：桌前留出行人位置。'),
        ('LifeWaterBench','bench',[930,2385],50,rect(-75,-18,150,18),'井院歇脚凳：放在取水路旁。'),
        ('LifeNorthBench','bench',[2100,945],50,rect(-75,-18,150,18),'住户门前长凳：屋前停坐，巷中通行。'),
        ('LifeNorthTable','table',[2940,930],80,rect(-59,-27.8,118,27.8),'台街小桌：住户门前的生活位置。'),
        ('LifeGateBench','bench',[2830,3590],50,rect(-75,-18,150,18),'候关歇脚点：货包与行人主路分开。'),
        ('LifeLookoutBench','bench',[4450,1120],50,rect(-75,-18,150,18),'望关台边长凳：面向关镇，台阶上口留空。'),
    ]:
        furniture(name,key,foot,height,body,label)

    for name, original, route, role in [
        ('LifeStreetTraveller','Merchant',[[2080,970],[2350,970]],'商旅：沿住户前街行走，货包置于屋前。'),
        ('LifeWaterTraveller','Merchant',[[1340,2310],[1340,2360]],'候水商旅：取水处与驮兽饮水分开。'),
        ('LifeWorkHelper','StoneWorker',[[4600,2315],[4600,2395]],'修坊帮工：在工作棚与材料间照料工具。'),
        ('LifeGateTraveller','Merchant',[[2800,3380],[3120,3380]],'候关商旅：在货包边等候同行者。'),
    ]:
        pieces = []
        before = len(additions)
        clone(name,original,route[0],role)
        # Only the cloned actor root carries the route; all body/atlas data remain original.
        additions[before] = re.sub(r'^route = PackedVector2Array\([^\n]+', 'route = '+poly(route), additions[before], count=1, flags=re.M)
        additions[before] += '\nmetadata/life_portrait = "' + ('worker_portrait' if original=='StoneWorker' else 'merchant_portrait') + '"'
        rows[-1]['route'] = route

    text = text.rstrip() + '\n\n' + '\n\n'.join(additions) + '\n'
    (PROJECT / SCENE).write_text(text, 'utf-8')
    # Native paving follows the original circulation. Convex court masks feather into soil.
    shader = (ROOT / f'game/art/modules/{D}/ground.gdshader').read_text('utf-8')
    shader = shader.replace('varying vec2 p;', 'uniform sampler2D paving_tex:source_color,repeat_enable,filter_linear;\nvarying vec2 p;')
    helper = '''float side(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return (v.x*(x.y-a.y)-v.y*(x.x-a.x))/length(v);}
float court(vec2 x,vec2 a,vec2 b,vec2 c,vec2 d){return smoothstep(0.,12.,min(min(side(x,a,b),side(x,b,c)),min(side(x,c,d),side(x,d,a))));}
'''
    shader = shader.replace('void fragment()', helper + 'void fragment()', 1)
    courts = []
    # Match the inside shape of each existing three-sided courtyard, including its open mouth.
    for label, x, y in [('Inn',1550,3220),('Stable',3400,3240),('Water',1100,2450),('Work',4500,2470)]:
        pts = [[x-420,y-295],[x+470,y-295],[x+630,y-110],[x-610,y-110]]
        courts.append({'name':label,'polygon':pts})
    mask = 'float yards=0.;\n'
    for row in courts:
        mask += 'yards=max(yards,court(p,' + ','.join('vec2('+','.join(fmt(v) for v in point)+')' for point in row['polygon']) + '));\n'
    old_tail = 'COLOR=vec4(mix(mix(a,b,.28)*.86,mix(smoothsoil,vec3(.68,.47,.29),.56),path),1.);'
    assert old_tail in shader
    new_tail = '''vec3 base_ground=mix(mix(a,b,.28)*.86,mix(smoothsoil,vec3(.68,.47,.29),.56),path);
''' + mask + '''float town_band=smoothstep(580.,680.,p.y)*(1.-smoothstep(3520.,3700.,p.y));
float paving=max(max(m,l)*town_band,s*.86*town_band);paving=max(paving,yards*.94);
vec3 slabs=texture(paving_tex,fold_uv(p/1024.)).rgb;
COLOR=vec4(mix(base_ground,slabs,paving*.9),1.);'''
    shader = shader.replace(old_tail, new_tail)
    (art_dir / 'ground.gdshader').write_text(shader.rstrip()+'\n', 'utf-8')
    controller = '''extends "res://scripts/drafts/redrock_desert_complete_20261028d/town_controller.gd"

func update_view() -> void:
	super.update_view()
	$UI/Status.text = "折返阶街通关镇　｜　取水、驮运与石作分院"

func examine() -> void:
	if not in_hall:
		for item in $Town.get_children():
			if item.has_meta("life_portrait") and actor.global_position.distance_to(item.global_position)<155.0:
				$UI/Detail/Portrait.texture=load(ART_ROOT+str(item.get_meta("life_portrait"))+".png")
				$UI/Detail/Portrait.visible=true
				$UI/Detail/Text.text=str(item.get_meta("label"))+"\\n\\nEsc关闭后继续行走。"
				show_details=true
				return
	super.examine()
'''
    script_path = PROJECT / SCRIPT
    script_path.parent.mkdir(parents=True)
    script_path.write_text(controller, 'utf-8')
    save(PROJECT/'life-layout.json', {'scene':SCENE, 'script':SCRIPT, 'art':ART,
         'new_objects':rows, 'courtyard_paving':courts, 'moved_homes':{'Dwelling4':[1750,840],'Dwelling5':[2650,840]},
         'native_media_modified':False, 'saved_world_positions':False})
    save(STAGE/'candidate.json', {'scene_before_sha256':sha(STAGE/'scene-before.tscn'),
         'scene_candidate_sha256':sha(PROJECT/SCENE), 'new_objects':len(rows),
         'new_homes':2, 'new_patrols':4, 'new_native_images':1, 'production_written':False})
    print(f'Private candidate: {len(rows)} new objects, 2 moved homes, paving and 4 native patrols')


if __name__ == '__main__':
    build()
