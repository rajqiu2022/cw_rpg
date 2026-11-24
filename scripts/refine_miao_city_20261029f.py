"""Incremental native bank planting, clustered back houses, and matching curved water bodies."""
import hashlib
import json
import math
import re
import shutil
from PIL import Image
from miao_town_20261029f import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT
from build_redrock_town_20261028a import save, sha, vec, poly, fmt

layout=json.loads((STAGE/'layout.json').read_text('utf-8'));p=PROJECT/SCENE;text=p.read_text('utf-8');before=sha(p)
padding=json.loads((STAGE/'padding-verification.json').read_text('utf-8'))
manifest=json.loads((RAW/'manifest.json').read_text('utf-8'))
newext=[]
for key in ['bank_shrub','moss_patch']:
    r=next(x for x in manifest['assets'] if x['key']==key);src=ROOT/r['output'];im=Image.open(src);assert sha(src)==r['sha256']
    w,h=im.size;b=im.getchannel('A').getbbox();px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
    out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
    dst=ROOT/'assets/processed/miao_town_20261029f'/r['kind']/(r['id']+'_padded.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
    nb=out.getchannel('A').getbbox();nw,nh=out.size;margins=[nb[0]/nw,nb[1]/nh,(nw-nb[2])/nw,(nh-nb[3])/nh];assert min(margins)>=.1
    padding['rows'].append({'key':key,'source':r['output'],'output':dst.relative_to(ROOT).as_posix(),'offset':[px,py],'source_sha256':sha(src),'sha256':sha(dst),'source_size':[w,h],'size':[nw,nh],'all_original_RGBA_exact':True,'new_pixels_RGBA_zero':True,'margins':margins,'raw_A1_pass':r['metrics']['margin_10_percent_pass'],'padded_A1_pass':True,'alpha_cleaned_pixels':0})
    bb=im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox();target=PROJECT/ART/(key+'.png');shutil.copyfile(dst,target)
    layout['media'][key]={**r,'processed':dst.relative_to(ROOT).as_posix(),'processed_sha256':sha(dst),'destination':ART+'/'+key+'.png','padding':[px,py],'bbox':list(bb),'native_size':[w,h]}
    newext.append(f'[ext_resource type="Texture2D" path="res://{ART}/{key}.png" id="{key}"]')
    base=(PROJECT/ART/'trees.png.import').read_text('utf-8');base=re.sub(r'^uid=.*\n','',base,flags=re.M)
    old_source=re.search(r'source_file="([^"]+)"',base)[1];old_import=re.search(r'path="([^"]+)"',base)[1];res='res://'+ART+'/'+key+'.png';imp='res://.godot/imported/'+key+'.png-'+hashlib.md5(res.encode()).hexdigest()+'.ctex'
    target.with_suffix('.png.import').write_text(base.replace(old_source,res).replace(old_import,imp),'utf-8')
text=text.replace('[sub_resource','\n\n'.join(newext)+'\n\n[sub_resource',1)
text=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+2),text,count=1)
newnodes=[];added=[];newbodies=[]
def node(name,kind,parent,props):newnodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\n'+props)
def body(name,points):
    node(name,'StaticBody2D','Town','collision_layer = 1\ncollision_mask = 0');node('Outline','CollisionPolygon2D','Town/'+name,'polygon = '+poly(points))
    newbodies.append({'path':'Town/'+name,'polygon':points})
def prop(name,key,foot,height,label,solid=False,ground=False):
    r=layout['media'][key];b=r['bbox'];pad=r['padding'];s=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]];width=(b[2]-b[0])*s
    props='position = '+vec(foot)+'\nmetadata/label = '+json.dumps(label,ensure_ascii=False)+f'\nmetadata/visual_rect = Rect2({fmt(-width/2)}, {fmt(-height)}, {fmt(width)}, {fmt(height)})'
    if ground:props+='\nz_index = -16\nmetadata/ground_cover = true'
    node(name,'Node2D','Town',props)
    node('Art','Sprite2D','Town/'+name,'position = '+vec([-(pivot[0]+pad[0])*s,-(pivot[1]+pad[1])*s])+'\nscale = '+vec([s,s])+f'\ntexture = ExtResource("{key}")\ncentered = false')
    added.append({'name':name,'key':key,'foot':foot,'height':height,'width':width,'scale':s,'pivot':pivot,'parent':'Town','body':None,'label':label})
def clone_home(name,original,foot):
    blocks=[]
    for b in re.split(r'(?=\[node )',text):
        head=b.splitlines()[0] if b else ''
        if (f'name="{original}" type=' in head and 'parent="Town"' in head) or re.search(r'parent="Town/'+original+r'(?:/|")',head):
            if 'parent="Town"' in head:
                b=b.replace('name="'+original+'"','name="'+name+'"',1);b=re.sub(r'^position = Vector2\([^\n]+','position = '+vec(foot),b,count=1,flags=re.M)
            else:b=b.replace('parent="Town/'+original,'parent="Town/'+name)
            blocks.append(b.rstrip())
    assert len(blocks)==4,(name,len(blocks));newnodes.extend(blocks)
    r=next(x for x in layout['objects'] if x['name']==original);added.append(dict(r,name=name,foot=foot))
    for r in [x for x in layout['blockers'] if x['path'].startswith('Town/'+original+'/')]:newbodies.append(dict(r,path=r['path'].replace('/'+original+'/', '/'+name+'/')))
for i,(old,foot) in enumerate([('Home2',[2220,730]),('Home3',[3160,665]),('Home5',[3880,730]),('Home1',[4630,610]),('Home4',[5200,760]),('Home6',[3280,1380]),
    ('Home11',[2420,1900]),('Home5',[4500,1900]),('Home1',[2660,2490]),('Home3',[5090,2330]),('Home2',[3560,3060]),('Home4',[4450,3040]),
    ('Home1',[3900,3690]),('Home5',[380,900]),('Home1',[620,3100])]):clone_home('ClusterHome'+str(i+1),old,foot)
# Keep original routes/door coordinates; remove the one real bench obstruction and shift a neighboring body away from a drawn lane.
for name,foot in [('LifeProp2',[440,1460]),('Home13',[2360,2580])]:
    text,n=re.subn(r'(\[node name="'+name+r'"[^\n]*parent="Town"[^\n]*\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(foot),text,count=1);assert n==1
    next(x for x in layout['objects'] if x['name']==name)['foot']=foot
def banks(y):
    near=min(max(0,min(1,(abs(y-b['center'][1])-150)/150)) for b in layout['bridges'])
    center=1500+(60*math.sin(y/520)+35*math.sin(y/230))*near
    width=500*(1-near)+(430+30*math.sin(y/400))*near
    return center-width/2,center+width/2
def vertical(a,b):
    ys=sorted(set([a,b]+[float(y) for y in range(math.ceil(a/80)*80,math.floor(b/80)*80+1,80)]))
    return [[banks(y)[0],y] for y in ys]+[[banks(y)[1],y] for y in reversed(ys)]
ys=list(range(100,3751,100))+[3750]
bottom=[[x,4280+35*math.sin(x/370)] for x in range(2300,6751,250)]+[[6750,4280+35*math.sin(6750/370)]]
top=[[x,3970+35*math.sin(x/430)] for x in range(2300,6751,250)]+[[6750,3970+35*math.sin(6750/430)]]
bend=[[banks(3750)[0],3750],[1400,4030],[1640,4250],[2050,4350]]+bottom+list(reversed(top))+[[2050,3900],[banks(3750)[1],3750]]
water=[[banks(y)[0],y] for y in ys]+bend[1:-1]+[[banks(y)[1],y] for y in reversed(ys)]
text,n=re.subn(r'(\[node name="Creek"[^\n]*\]\n[\s\S]*?\npolygon = )[^\n]+',lambda m:m[1]+poly(water),text,count=1);assert n==1
parts=re.split(r'(?=\[node )',text);removed=[];kept=[]
for b in parts:
    head=b.splitlines()[0] if b else ''
    if re.search(r'\[node name="Water[^"]*" type="StaticBody2D" parent="Town"',head) or re.search(r'parent="Town/Water[^/\"]*(?:/|\")',head):removed.append(b)
    else:kept.append(b)
text=''.join(kept);layout['blockers']=[r for r in layout['blockers'] if not r['path'].startswith('Town/Water')]
last=100
for i,b in enumerate(sorted(layout['bridges'],key=lambda r:r['center'][1])):
    lo,hi=b['open_water_y'];body('CurvedWater'+str(i+1),vertical(last,lo));last=hi
body('CurvedWater4',vertical(last,3750));body('CurvedWaterBend',bend)
for i,y in enumerate(range(540,3721,310)):
    if min(abs(y-b['center'][1]) for b in layout['bridges'])<180:continue
    a,b=banks(y)
    for j,x in enumerate([a+45,b-45]):prop('BankCluster'+str(i)+'_'+str(j),'bank_shrub',[x,y],72+(i%3)*10,'溪岸石草丛：水边自然阻挡。')
for i,x in enumerate(range(2300,6581,370)):
    prop('SouthBank'+str(i),'bank_shrub',[x,4005+35*math.sin(x/430)],70+(i%2)*10,'下游石草岸。')
cover=[]
for i,r in enumerate(layout['objects']+added):
    if r['key'] in ['house_front','house_side','house_back','weaving_house','granary']:
        x,y=r['foot'];cover.extend([[x-r['width']*.38,y+12],[x+r['width']*.37,y-8]])
for i,y in enumerate(range(500,4001,260)):
    a,b=banks(y);cover.extend([[a-55,y],[b+65,y]])
for i,foot in enumerate(cover):prop('Moss'+str(i+1),'moss_patch',foot,75+(i%3)*10,'林下苔草地被。',False,True)
text=text.rstrip()+'\n\n'+'\n\n'.join(newnodes)+'\n';p.write_text(text,'utf-8')
layout['objects']+=added;layout['blockers']+=newbodies;layout['new_native_images']=25;layout['curved_water_polygon']=water
layout['refined_new_homes']=15;layout['refinement_new_objects']=[r['name'] for r in added]
save(STAGE/'layout.json',layout);save(STAGE/'padding-verification.json',padding)
save(ROOT/'assets/processed/miao_town_20261029f/resource-pack.json',{'status':'PADDED_NATIVE_CANDIDATES','assets':[dict(r,output=r['processed'],sha256=r['processed_sha256']) for r in layout['media'].values()]})
save(STAGE/'density-bank-refinement.json',{'scene_before':before,'scene_after':sha(p),'new_native_images':2,'new_homes':15,'new_objects':len(added),'removed_old_water_node_blocks':len(removed),'new_water_bodies':5,'PNG_modified':'RGBA0 padding only','first_85_1_FAIL_preserved':True})
print('Refined:15new clustered homes, curved native-textured creek with exact matching water bodies, bank clusters and moss; bench moved')
