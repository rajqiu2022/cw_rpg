"""Add the final native craft prop without changing previously verified domains."""
import hashlib
import json
import math
import re
import shutil
from PIL import Image
from miao_town_20261029f import ROOT, RAW, STAGE, PROJECT, ART, SCENE
from build_redrock_town_20261028a import save, sha, vec, poly, fmt

layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
assert 'lusheng_rack' not in layout['media']
r=next(x for x in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets'] if x['key']=='lusheng_rack')
src=ROOT/r['output'];im=Image.open(src);assert sha(src)==r['sha256']
w,h=im.size;b=im.getchannel('A').getbbox()
px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1
py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py))
assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
dst=ROOT/'assets/processed/miao_town_20261029f'/r['kind']/(r['id']+'_padded.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
nb=out.getchannel('A').getbbox();nw,nh=out.size;margins=[nb[0]/nw,nb[1]/nh,(nw-nb[2])/nw,(nh-nb[3])/nh];assert min(margins)>=.1
padding=json.loads((STAGE/'padding-verification.json').read_text('utf-8'))
padding['rows'].append({'key':r['key'],'source':r['output'],'output':dst.relative_to(ROOT).as_posix(),'offset':[px,py],'source_sha256':sha(src),'sha256':sha(dst),'source_size':[w,h],'size':[nw,nh],'all_original_RGBA_exact':True,'new_pixels_RGBA_zero':True,'margins':margins,'raw_A1_pass':r['metrics']['margin_10_percent_pass'],'padded_A1_pass':True,'alpha_cleaned_pixels':0})
bb=im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox();target=PROJECT/ART/'lusheng_rack.png';shutil.copyfile(dst,target)
layout['media'][r['key']]={**r,'processed':dst.relative_to(ROOT).as_posix(),'processed_sha256':sha(dst),'destination':ART+'/lusheng_rack.png','padding':[px,py],'bbox':list(bb),'native_size':[w,h]}
base=(PROJECT/ART/'trees.png.import').read_text('utf-8');base=re.sub(r'^uid=.*\n','',base,flags=re.M)
old_source=re.search(r'source_file="([^"]+)"',base)[1];old_import=re.search(r'path="([^"]+)"',base)[1]
res='res://'+ART+'/lusheng_rack.png';imp='res://.godot/imported/lusheng_rack.png-'+hashlib.md5(res.encode()).hexdigest()+'.ctex'
target.with_suffix('.png.import').write_text(base.replace(old_source,res).replace(old_import,imp),'utf-8')
foot=[3400,2480];height=170;s=height/(bb[3]-bb[1]);pivot=[(bb[0]+bb[2])/2,bb[3]];width=(bb[2]-bb[0])*s
rect=[[-width*.44,-30],[width*.44,-30],[width*.44,0],[-width*.44,0]]
p=PROJECT/SCENE;text=p.read_text('utf-8')
text=text.replace('[sub_resource',f'[ext_resource type="Texture2D" path="res://{ART}/lusheng_rack.png" id="lusheng_rack"]\n\n[sub_resource',1)
text=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+1),text,count=1)
text+='\n[node name="LushengCraftRack" type="Node2D" parent="Town"]\nposition = '+vec(foot)+'\nmetadata/label = "芦笙制作架：竹管、制作台与手工工具。"\nmetadata/visual_rect = Rect2('+', '.join(fmt(x) for x in [-width/2,-height,width,height])+')\n'
text+='\n[node name="Art" type="Sprite2D" parent="Town/LushengCraftRack"]\nposition = '+vec([-(pivot[0]+px)*s,-(pivot[1]+py)*s])+'\nscale = '+vec([s,s])+'\ntexture = ExtResource("lusheng_rack")\ncentered = false\n'
text+='\n[node name="Body" type="StaticBody2D" parent="Town/LushengCraftRack"]\ncollision_layer = 1\ncollision_mask = 0\n\n[node name="Outline" type="CollisionPolygon2D" parent="Town/LushengCraftRack/Body"]\npolygon = '+poly(rect)+'\n'
p.write_text(text,'utf-8')
layout['objects'].append({'name':'LushengCraftRack','key':'lusheng_rack','foot':foot,'height':height,'width':width,'scale':s,'pivot':pivot,'parent':'Town','body':rect,'label':'芦笙制作架'})
layout['blockers'].append({'path':'Town/LushengCraftRack/Body','polygon':rect});layout['new_native_images']=26
save(STAGE/'layout.json',layout);save(STAGE/'padding-verification.json',padding)
save(ROOT/'assets/processed/miao_town_20261029f/resource-pack.json',{'status':'PADDED_NATIVE_CANDIDATES','assets':[dict(x,output=x['processed'],sha256=x['processed_sha256']) for x in layout['media'].values()]})
print('Final native craft prop added;26media,23RGBA0padding; originalRGBA retained')
