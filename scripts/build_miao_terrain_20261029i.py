"""A new isolated successor: shared XY/Z terrain data, native art and required ramps."""
import json
import re
import shutil
from pathlib import Path
from build_redrock_town_20261028a import ROOT, save, sha

NAME = 'miao_terrain_20261029i'
OLD = 'miao_building_variety_20261029h'
STAGE = ROOT/'assets/staging'/NAME
PROJECT = STAGE/'town_project'
SCENE = f'scenes/drafts/{NAME}/miao_town.tscn'
SCRIPT = f'scripts/drafts/{NAME}/town_controller.gd'
ART = f'art/modules/{NAME}'

def build():
    assert not STAGE.exists()
    STAGE.mkdir(parents=True)
    prior = ROOT/'assets/staging'/OLD
    paths = {Path(r['path']) for r in json.loads((prior/'protected-before.json').read_text('utf-8'))}
    paths.update(ROOT/r['path'] for r in json.loads((prior/'publication.json').read_text('utf-8'))['files'])
    save(STAGE/'protected-before.json', [{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(paths)])
    shutil.copytree(prior/'town_project', PROJECT)
    (PROJECT/'artifacts-i').mkdir()
    config=(PROJECT/'project.godot').read_text('utf-8').replace(f'scenes/drafts/{OLD}/miao_town.tscn', SCENE)
    (PROJECT/'project.godot').write_text(config,'utf-8')
    data = {
        'heights':[0,120,240],
        'platforms':[
            {'level':1,'label':'街坊台地','polygon':[[2050,1550],[2180,650],[3000,280],[4400,220],[5900,440],[6850,900],[7250,1600],[7380,2500],[7080,2960],[6100,3090],[5050,3070],[4500,3000],[3850,3000],[3250,2860],[3000,2600],[2850,2450],[2350,2450],[2180,2240]]},
            {'level':2,'label':'上层民巷','polygon':[[2920,1150],[3100,550],[3820,410],[4800,500],[5600,820],[6030,1260],[6020,1630],[5730,1870],[5050,1870],[4820,1740],[4400,1740],[4100,1850],[3500,1850],[3180,1640]]}
        ],
        'ramps':[
            {'id':'PlazaStair','label':'溪市—芦笙坪','low':0,'high':1,'top':[4200,3000]},
            {'id':'WorkshopStair','label':'桥巷—绣坊台地','low':0,'high':1,'top':[2680,2450]},
            {'id':'UpperLaneStair','label':'芦笙坪—上层民巷','low':1,'high':2,'top':[3800,1850]},
            {'id':'GrainStair','label':'粮院—上层民巷','low':1,'high':2,'top':[5400,1870]}
        ],
        'source_stair_scale':440/844,
        'source_stair_pivot':[768,780],
        'source_stair_top_y':390,
        'portal_half_width':120,
        'facade_opening_half_width':190,
        'physical_common_layer':8,
        'physical_level_layers':[16,32,64],
        'object_moves':{'PocketInfill7':[2740,3080],'Forest178':[2160,2550]},
        'scene':'res://'+SCENE,
        'formal_world_enabled':False,
    }
    run=(780-390)*data['source_stair_scale']-120
    assert run>0
    for r in data['ramps']:
        r.update(bottom=[r['top'][0],r['top'][1]+run],rise=120,ground_run=run)
    # The same geometry drives rendering, blockers, residents and actor level changes.
    save(STAGE/'terrain.json',data)
    out=PROJECT/ART;out.mkdir(parents=True)
    save(out/'terrain.json',data)
    src=(PROJECT/f'scenes/drafts/{OLD}/miao_town.tscn').read_text('utf-8')
    src=src.replace(f'scripts/drafts/{OLD}/town_controller.gd', SCRIPT)
    src=src.replace('scripts/drafts/miao_town_20261029f/resident.gd', f'scripts/drafts/{NAME}/resident.gd')
    src=src.replace(f'art/modules/{OLD}/ground.gdshader', ART+'/ground.gdshader')
    # Remove the four cosmetic stairs and nineteen scattered substitute cliff pieces.
    blocks=re.split(r'(?=\[node )',src)
    gone=[];keep=[]
    for block in blocks:
        first=block.splitlines()[0] if block else ''
        if re.search(r'(?:name="|parent="Town/)(?:Stairs[1-4]|RockLedge\d+|HighRock\d+)(?:"|/)',first):
            gone.append(first)
        else:keep.append(block)
    src=''.join(keep)
    p=PROJECT/SCENE;p.parent.mkdir(parents=True);p.write_text(src,'utf-8')
    base=(PROJECT/f'art/modules/{OLD}/ground.gdshader').read_text('utf-8')
    # Replace the obsolete flat-world path graph; all ramp landings are explicit.
    base=re.sub(r'path=max\(path,.*?\n','',base)
    routes=[[[3200,3350],[4200,3180],[4200,3000]], [[2420,2770],[2680,2620],[2680,2450]],
            [[2680,2450],[2680,2170],[3000,2170],[3600,2390],[4200,2480],[4200,3000]],
            [[4200,2480],[3800,2150],[3800,1850]], [[4200,2480],[5400,2200],[5400,1870]],
            [[3800,1850],[3800,1610],[4100,1610],[4600,1580],[5400,1650],[5400,1870]],
            [[5400,2200],[6100,2150],[6750,2510]], [[1750,1845],[2100,2050],[2100,2450],[2420,2770]],
            [[1610,4070],[1610,3650],[2000,3350],[3300,3350],[4060,3880],[4520,3880],[5350,4160],[5900,4160]],
            [[2420,2770],[1260,2770],[1260,2120],[1050,2000],[1700,2000]]]
    lines=[]
    for route in routes:
        for a,b in zip(route,route[1:]):lines.append(f'path=max(path,1.-smoothstep(48.,105.,segment(p,vec2({a[0]}.,{a[1]}.),vec2({b[0]}.,{b[1]}.))));')
    base=base.replace('varying vec2 p;','uniform float surface_elevation=0.;\nvarying vec2 p;').replace('p=VERTEX;','p=VERTEX+vec2(0.,surface_elevation);')
    base=base.replace('void fragment(){float path=0.;','void fragment(){float path=0.;\n'+'\n'.join(lines))
    (out/'ground.gdshader').write_text(base,'utf-8')
    # Save source templates separately, copy without touching inherited source files.
    for name in ['town_controller.gd','resident.gd','terrain.gd']:
        target=PROJECT/f'scripts/drafts/{NAME}'/name;target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/'scripts/templates/miao_terrain_20261029i'/name,target)
    layout=json.loads((prior/'layout.json').read_text('utf-8'))
    layout.update(scene=SCENE,script=SCRIPT,terrain=data,removed_cosmetic_nodes=gone)
    save(STAGE/'layout.json',layout)
    print('Prepared isolated terrain project; protected',len(paths),'native PNG writes0; removed',len(gone),'old cosmetic node blocks')

if __name__=='__main__':build()
