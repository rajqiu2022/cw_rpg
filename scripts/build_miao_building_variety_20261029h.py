"""Replace repeated architecture with adult-scale wide/tall/low/angled/ancillary structures."""
import hashlib
import json
import math
import re
import shutil
from PIL import Image
from miao_building_variety_20261029h import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT, NAME
from build_redrock_town_20261028a import save, sha, vec, poly, fmt
OLD='miao_recompose_20261029g'
assert not PROJECT.exists();oldstage=ROOT/'assets/staging'/OLD;shutil.copytree(oldstage/'town_project',PROJECT)
(PROJECT/'artifacts-h').mkdir()
config=(PROJECT/'project.godot').read_text('utf-8').replace('res://scenes/drafts/'+OLD+'/miao_town.tscn','res://'+SCENE).replace(OLD+'_validation',NAME+'_validation');(PROJECT/'project.godot').write_text(config,'utf-8')
layout=json.loads((oldstage/'layout.json').read_text('utf-8'));processed=ROOT/'assets/processed'/NAME;media={};padding=[]
for r in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
    src=ROOT/r['output'];im=Image.open(src);assert sha(src)==r['sha256'];w,h=im.size;b=im.getchannel('A').getbbox()
    px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
    out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
    dst=processed/r['kind']/(r['id']+'_padded.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
    bb=out.getchannel('A').getbbox();nw,nh=out.size;margins=[bb[0]/nw,bb[1]/nh,(nw-bb[2])/nw,(nh-bb[3])/nh];assert min(margins)>=.1
    padding.append({'key':r['key'],'source':r['output'],'output':dst.relative_to(ROOT).as_posix(),'offset':[px,py],'source_sha256':sha(src),'sha256':sha(dst),'all_original_RGBA_exact':True,'new_pixels_RGBA_zero':True,'raw_A1_pass':r['metrics']['margin_10_percent_pass'],'margins':margins})
    b=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();target=PROJECT/ART/(r['key']+'.png');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(dst,target)
    media[r['key']]={**r,'processed':dst.relative_to(ROOT).as_posix(),'processed_sha256':sha(dst),'destination':ART+'/'+r['key']+'.png','bbox':list(b),'padding':[px,py],'native_size':[w,h]}
    base=(PROJECT/'art/modules/miao_town_20261029f/trees.png.import').read_text('utf-8');base=re.sub(r'^uid=.*\n','',base,flags=re.M)
    oldsource=re.search(r'source_file="([^"]+)"',base)[1];oldimport=re.search(r'path="([^"]+)"',base)[1];res='res://'+ART+'/'+r['key']+'.png';imp='res://.godot/imported/'+r['key']+'.png-'+hashlib.md5(res.encode()).hexdigest()+'.ctex'
    target.with_suffix('.png.import').write_text(base.replace(oldsource,res).replace(oldimport,imp),'utf-8')
save(STAGE/'padding-verification.json',{'authorization':'ai-rules6.7','rows':padding,'alpha_cleaned_pixels':0})
save(processed/'resource-pack.json',{'status':'PADDED_NATIVE_CANDIDATES','assets':[dict(r,output=r['processed'],sha256=r['processed_sha256']) for r in media.values()]})

# Native ordinary doorway height calibration in source pixels, visually read from generated originals.
# Ancillary grain hatch intentionally has no adult-door contract.
scales={'wide_hall':.82,'narrow_inn':.70,'small_cottage':.50,'angle_workshop':.80,'tiny_granary':200/(media['tiny_granary']['bbox'][3]-media['tiny_granary']['bbox'][1])}
doors={'wide_hall':146,'narrow_inn':170,'small_cottage':210,'angle_workshop':140}
plan=[('PocketHome8','wide_hall',[4430,1900],'公共木厅：宽开间廊厅，外观地标，未新建服务或室内。'),
    ('HighStilt2','narrow_inn',[3900,850],'窄高三层木楼：三层窗格与小侧灶屋。'),
    ('PocketHome16','narrow_inn',[6530,3600],'街尾窄高木楼：收住铺街视线，屋前留院。'),
    ('PocketHome1','small_cottage',[2300,670],'单间小宅：一层一门一窗，成人入口比例。'),
    ('PocketHome4','small_cottage',[5490,590],'单间小宅：低屋檐与附柴棚。'),
    ('PocketHome17','small_cottage',[6900,3290],'单间小宅：与邻楼拉开院落间隔。'),
    ('PocketInfill7','small_cottage',[2750,2630],'小宅接桥边巷，屋前留空。'),
    ('DyeWorkshop','angle_workshop',[2500,1540],'转角染织作坊：低长廊、织机与高储物间。'),
    ('PocketHome14','angle_workshop',[3000,2960],'街坊转角作业棚：开敞长廊，端部有储物间。'),
    ('Granary1','tiny_granary',[6600,1960],'小高脚粮棚：鼠盘支脚、小储粮舱门，非成人房屋。'),
    ('Granary2','tiny_granary',[6970,2320],'小粮棚：粮院附属储物，非可进入民居。'),
    ('PocketHome5','tiny_granary',[6430,870],'山巷附属粮棚：小储藏舱与短木梯。')]
original=(PROJECT/f'scenes/drafts/{OLD}/miao_town.tscn').read_text('utf-8');header,bodytext=original.split('[node ',1);bodytext='[node '+bodytext
header=header.replace('res://scripts/drafts/'+OLD+'/town_controller.gd','res://'+SCRIPT).replace('res://art/modules/'+OLD+'/ground.gdshader','res://'+ART+'/ground.gdshader')
ext=[f'[ext_resource type="Texture2D" path="res://{ART}/{key}.png" id="{key}"]' for key in media];header=header.replace('[sub_resource','\n\n'.join(ext)+'\n\n[sub_resource',1)
names={p[0] for p in plan};kept=[]
for block in re.split(r'(?=\[node )',bodytext):
    h=block.splitlines()[0] if block else '';remove=False
    for name in names:
        if (f'name="{name}" type=' in h and 'parent="Town"' in h) or re.search(r'parent="Town/'+name+r'(?:/|")',h):remove=True;break
    if not remove:kept.append(block.rstrip())
before={r['name']:r for r in layout['objects'] if r['name'] in names};assert len(before)==12
layout['objects']=[r for r in layout['objects'] if r['name'] not in names]
layout['blockers']=[r for r in layout['blockers'] if not any(r['path'].startswith('Town/'+n+'/') for n in names)]
materials=[];newnodes=[];replacements=[]
def node(name,kind,parent,props):newnodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\n'+props)
for name,key,foot,label in plan:
    r=media[key];b=r['bbox'];pad=r['padding'];s=scales[key];pivot=[(b[0]+b[2])/2,b[3]];width=(b[2]-b[0])*s;height=(b[3]-b[1])*s;sid='hfade_'+name
    materials.append(f'[sub_resource type="ShaderMaterial" id="{sid}"]\nshader = ExtResource("occlusion_shader")\nshader_parameter/fade_enabled = 0.0')
    node(name,'Node2D','Town','position = '+vec(foot)+'\nmetadata/label = '+json.dumps(label,ensure_ascii=False)+'\nmetadata/fade = true\nmetadata/building_variant = "'+key+f'"\nmetadata/visual_rect = Rect2({fmt(-width/2)}, {fmt(-height)}, {fmt(width)}, {fmt(height)})')
    node('Art','Sprite2D','Town/'+name,'material = SubResource("'+sid+'")\nposition = '+vec([-(pivot[0]+pad[0])*s,-(pivot[1]+pad[1])*s])+'\nscale = '+vec([s,s])+f'\ntexture = ExtResource("{key}")\ncentered = false')
    depth=min(height*.2,115);points=[[-width*.40,-depth],[width*.40,-depth],[width*.40,0],[-width*.40,0]]
    if key=='angle_workshop':points=[[-width*.43,-height*.17],[width*.05,-height*.17],[width*.05,-height*.3],[width*.43,-height*.3],[width*.43,0],[-width*.43,0]]
    node('Body','StaticBody2D','Town/'+name,'collision_layer = 1\ncollision_mask = 0');node('Outline','CollisionPolygon2D','Town/'+name+'/Body','polygon = '+poly(points))
    nr={'name':name,'key':key,'foot':foot,'height':height,'width':width,'scale':s,'pivot':pivot,'body':points,'adult_door_height':doors.get(key,0)*s,'role':'ancillary_storage' if key=='tiny_granary' else key}
    layout['objects'].append(nr);layout['blockers'].append({'path':'Town/'+name+'/Body','polygon':points});replacements.append({'name':name,'before':before[name],'after':nr})
header=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+len(ext)+len(materials)),header,count=1)
p=PROJECT/SCENE;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(header+'\n\n'.join(materials+kept+newnodes)+'\n','utf-8')
g=(PROJECT/f'art/modules/{OLD}/ground.gdshader').read_text('utf-8')
for row in replacements:
    old=row['before'];new=row['after'];x,y=old['foot'];a,b=new['foot']
    pattern=r'wear=max\(wear,1\.-smoothstep\(\.65,1\.,length\(\(p-vec2\('+re.escape(fmt(x))+','+re.escape(fmt(y+20))+r'\)\)/vec2\([^\n]+'
    value='wear=max(wear,1.-smoothstep(.65,1.,length((p-vec2('+fmt(a)+','+fmt(b+20)+'))/vec2('+fmt(new['width']*.7)+',200.))));'
    g,n=re.subn(pattern,lambda m:value,g,count=1)
    # Original granaries also have aprons; every replacement must have exactly one source apron.
    assert n==1,(old['name'],x,y)
(PROJECT/ART/'ground.gdshader').write_text(g,'utf-8')
code=(PROJECT/f'scripts/drafts/{OLD}/town_controller.gd').read_text('utf-8').replace('溪谷斜穿 / 吊脚栈街','溪谷木寨 / 楼舍错落')
sp=PROJECT/SCRIPT;sp.parent.mkdir(parents=True,exist_ok=True);sp.write_text(code,'utf-8')
layout.update(scene=SCENE,script=SCRIPT,art=ART,media=media,previous_new_media=layout['media'],building_replacements=replacements,formal_world_enabled=False)
save(STAGE/'layout.json',layout)
save(STAGE/'massing-contract.json',{'replaced_buildings':12,'native_types':5,'source_uniform_scales':scales,'adult_source_door_height_px':doors,
    'runtime_adult_door_heights':{k:scales[k]*v for k,v in doors.items()},'smallest_ancillary_height':200,'building_dimensions':[{k:r['after'][k] for k in ['name','key','width','height','adult_door_height']} for r in replacements],
    'PNG_processing':'RGBA0 padding only; no local crop/stretch/recolor','public_hall_and_new_lodgings_have_no_new_business_or_interior':True})
print('Replaced12buildings with5native silhouettes; door heights',[round(scales[k]*v,1) for k,v in doors.items()]);print('Largest/smallest heights',max(r['after']['height'] for r in replacements),min(r['after']['height'] for r in replacements))
