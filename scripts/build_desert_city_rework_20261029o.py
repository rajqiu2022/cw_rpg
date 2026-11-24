"""Versioned native assets and exact scene mutations in an isolated project."""
import math,re,sys
from PIL import Image
from desert_city_rework_20261029o import *

SCENES={'redrock':'scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn','desert':'scenes/drafts/desert_town_20261029d/desert_town.tscn'}
def v(p):return 'Vector2('+', '.join(f'{x:.9f}' for x in p)+')'
def poly(p):return 'PackedVector2Array('+', '.join(f'{x:.9f}' for q in p for x in q)+')'
def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]
def nums(s):return [float(x) for x in re.findall(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?',s.split('(',1)[-1])]
class Scene:
    def __init__(self,path):
        self.path=path;self.text=(ROOT/'game'/path).read_text('utf-8');self.head=self.text[:self.text.index('[node ')];self.nodes={};self.order=[]
        for m in re.finditer(r'^\[node ([^\n]+)\]\n(.*?)(?=^\[node |\Z)',self.text,re.M|re.S):
            h,b=m.groups();a=dict(re.findall(r'(\w+)="([^"]+)"',h));parent=a.get('parent','');key='.' if not parent else (a['name'] if parent=='.' else parent+'/'+a['name'])
            self.nodes[key]=[h,b.strip()];self.order.append(key)
    def prop(self,key,name,value):
        h,b=self.nodes[key];b=re.sub(r'^'+re.escape(name)+r' = .*\n?','',b,flags=re.M);self.nodes[key]=[h,b.rstrip()+'\n'+name+' = '+value]
    def value(self,key,name):return re.search(r'^'+re.escape(name)+r' = (.*)$',self.nodes[key][1],re.M)[1]
    def remove(self,key):
        for x in list(self.nodes):
            if x==key or x.startswith(key+'/'):del self.nodes[x];self.order.remove(x)
    def add(self,key,kind,body):
        assert key not in self.nodes
        parent,name=key.rsplit('/',1) if '/' in key else ('.',key)
        self.nodes[key]=[f'name="{name}" type="{kind}" parent="{parent}"',body];self.order.append(key)
    def texture(self,key,path):
        row=f'[ext_resource type="Texture2D" path="res://{path}" id="r_{key}"]\n\n'
        at=self.head.find('[sub_resource ')
        if at<0:self.head+=row
        else:self.head=self.head[:at]+row+self.head[at:]
    def sprite(self,key,tex,pos,scale=(1,1),material='',z=None):
        s='position = '+v(pos)+'\nscale = '+v(scale)+f'\ntexture = ExtResource("{tex}")\ncentered = false'
        if material:s+='\nmaterial = SubResource("'+material+'")'
        if z is not None:s+='\nz_index = '+str(z)
        self.add(key,'Sprite2D',s)
    def body(self,key,points):
        self.add(key,'StaticBody2D','collision_layer = 1\ncollision_mask = 0');self.add(key+'/Outline','CollisionPolygon2D','polygon = '+poly(points))
    def write(self):
        # Appended subtrees follow their parents; existing native scene order is retained.
        target=PROJECT/self.path;target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(self.head+'\n'.join('[node '+self.nodes[k][0]+']\n'+self.nodes[k][1]+'\n' for k in self.order),'utf-8')

def prepare():
    assert not PROJECT.exists()
    prior=ROOT/'assets/staging/desert_town_20261029d/town_project'
    PROJECT.mkdir()
    for folder in ['art','scripts','scenes','.godot/imported']:shutil.copytree(prior/folder,PROJECT/folder)
    config=(prior/'project.godot').read_text('utf-8').replace('desert_town_20261029d_validation',NAME+'_validation')
    (PROJECT/'project.godot').write_text(config,'utf-8');(PROJECT/'review').mkdir()
    pending=list(SCENES.values());seen=set()
    while pending:
        rel=pending.pop()
        if rel in seen:continue
        seen.add(rel);src=ROOT/'game'/rel
        if not src.is_file():continue
        dst=PROJECT/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
        if src.suffix in ['.tscn','.gd','.gdshader','.tres']:
            for dep in re.findall(r'res://[^"\s<>\\]+',src.read_text('utf-8')):
                if (ROOT/'game'/dep[6:]).is_file():pending.append(dep[6:])
        if src.suffix=='.png':
            imp=Path(str(src)+'.import')
            if imp.exists():
                shutil.copyfile(imp,Path(str(dst)+'.import'))
                for dep in re.findall(r'res://(\.godot/imported/[^"\]]+)',imp.read_text('utf-8')):
                    shutil.copyfile(ROOT/'game'/dep,PROJECT/dep)
    save(STAGE/'copied-current-dependencies.json',sorted(seen))
    media={};checks=[]
    for row in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
        assert row['status']=='RAW_CANDIDATE';src=ROOT/row['output'];im=Image.open(src);assert im.mode=='RGBA';a=im.getchannel('A');assert a.getextrema()[0]==0
        w,h=im.size;b=a.getbbox();native=a.point(lambda q:255 if q>=128 else 0).getbbox()
        px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
        out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
        path=ROOT/'assets/processed'/NAME/(row['key']+'.png');path.parent.mkdir(parents=True,exist_ok=True);out.save(path)
        dest=PROJECT/ART/path.name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,dest)
        template=(ROOT/'game/art/modules/desert_town_20261029d/court_wall.png.import').read_text('utf-8')
        rel='res://'+ART+'/'+path.name;cache=path.name+'-'+hashlib.md5(rel.encode()).hexdigest()+'.ctex'
        template=re.sub(r'uid="[^"]+"\n','',template).replace('res://art/modules/desert_town_20261029d/court_wall.png',rel)
        template=template.replace('court_wall.png-211e8e4885b9f94672745613c23f7d2b.ctex',cache)
        Path(str(dest)+'.import').write_text(template,'utf-8')
        media[row['key']]={'path':ART+'/'+path.name,'padding':[px,py],'bbox':[native[0]+px,native[1]+py,native[2]+px,native[3]+py],'raw_size':[w,h],'size':list(out.size),'raw':row['output'],'processed':path.relative_to(ROOT).as_posix(),'label':row['label']}
        checks.append({'key':row['key'],'only_RGBA0_padding':True,'original_RGBA_exact':True,'alpha_cleaned_pixels':0,'raw_A1_pass':min(b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h)>=.1,'offset':[px,py]})
    save(STAGE/'media.json',media);save(STAGE/'padding-verification.json',checks)

def build():
    media=json.loads((STAGE/'media.json').read_text('utf-8'));audit=json.loads((ROOT/'assets/staging/desert_city_pixel_audit_20261029n/audit.json').read_text('utf-8'))
    s=Scene(SCENES['redrock']);s.texture('redrock_cliff',media['redrock_cliff']['path'])
    # Shrink the connected gate assembly around its existing doorway, including all bodies.
    f=1/1.2;s.prop('Town/Gate','scale',v([f,f]));s.prop('Town/Gate','position',v([2250-2650*f,4055.6-30.6*f]))
    # Existing long side-source images now repeat at native density, with actual outer body narrowed.
    for key,tex,inner,side,start,end in [('TownWestBank','d_west_bank',187,-1,256,4000),('TownEastBank','d_east_bank',5570.6,1,456,4200),('ApproachWestBank','d_west_bank',681.3,-1,4332,7500),('ApproachEastBank','d_east_bank',4582.8,1,4332,7500)]:
        parent='Town/'+key;foot=nums(s.value(parent,'position'));row=next(r for r in audit['scenes']['redrock']['sprite_rows'] if r['node']==parent+'/Art');b=row['alpha128_bbox'];sc=.95;height=(b[3]-b[1])*sc;width=(b[2]-b[0])*sc
        s.remove(parent+'/Art');n=math.ceil((end-start)/(height*.83));centers=[start+height+(end-start-height)*i/max(1,n-1) for i in range(n)]
        # Meet the old inner edge; outward collision follows the actual native-width bank.
        left=inner-width if side<0 else inner
        for i,y in enumerate(centers):s.sprite(parent+'/Native'+str(i),tex,[left-b[0]*sc-foot[0],y-b[3]*sc-foot[1]],[sc,sc])
        s.prop(parent+'/Body/Rock','polygon',poly(rect(left-foot[0]+15,start-foot[1],width-30,end-start)))
    # North rim: four overlapping native short faces replace one 2.58x panorama.
    parent='Town/TownNorthBank';s.remove(parent+'/Art');b=media['redrock_cliff']['bbox'];sc=.95;width=(b[2]-b[0])*sc
    left=-2758;span=5516;n=math.ceil(span/(width*.82))
    for i in range(n):
        x=left+(span-width)*i/(n-1)
        s.sprite(parent+'/Native'+str(i),'r_redrock_cliff',[x-b[0]*sc,-b[3]*sc],[sc,sc])
    # Close the changed native-width bank corners and shortened gate wing junction.
    s.remove('Town/EastGateShoulder')
    for name,foot,sc in [('EastGateShoulder',[4970,4150],.9),('NorthWestJoin',[200,450],.5),('NorthEastJoin',[5550,520],.5)]:
        k='Town/'+name;width=(b[2]-b[0])*sc;cx=(b[0]+b[2])/2
        s.add(k,'Node2D','position = '+v(foot));s.sprite(k+'/Art','r_redrock_cliff',[-cx*sc,-b[3]*sc],[sc,sc]);s.body(k+'/Body',rect(-width/2,-110,width,110))
    s.prop('Town/SouthWestJoin','position',v([1150,7480]))
    s.prop('Town/ApproachSouthRidge/Art','scale',v([1,1]))
    s.write()

    s=Scene(SCENES['desert'])
    for key,m in media.items():
        if key.startswith('adobe_'):s.texture(key,m['path'])
    s.remove('Town/WallRear');s.remove('Town/WallFront/Art')
    for i in range(5):s.remove('Town/WallBody'+str(i))
    s.prop('Town/WallFront','position',v([2560,4290]));s.prop('Town/WallFront','metadata/label','"沙漠城门：独立原生城门与分段土坯城墙。"')
    gate=media['adobe_gate'];pad=gate['padding'];sc=.8;anchor=[750+pad[0],944+pad[1]]
    s.sprite('Town/WallFront/Art','r_adobe_gate',[-anchor[0]*sc,-anchor[1]*sc],[sc,sc],'foreground_mat')
    s.body('Town/WallFront/WestPier',rect((48-750)*sc,(850-944)*sc,(550-48)*sc,(944-850)*sc))
    s.body('Town/WallFront/EastPier',rect((945-750)*sc,(850-944)*sc,(1485-945)*sc,(944-850)*sc))
    # Straight wall runs overlap flush pillar ends; four round towers cover orientation joins.
    seams=[]
    def front_run(name,left,right,y):
        m=media['adobe_wall'];b=m['bbox'];sc=.88;width=(b[2]-b[0])*sc;count=math.ceil((right-left)/(width-80));step=(right-left-width)/max(1,count-1)
        for i in range(count):
            x=left+i*step;key='Town/'+name+str(i);s.add(key,'Node2D','position = '+v([0,y]))
            s.sprite(key+'/Art','r_adobe_wall',[x-b[0]*sc,-b[3]*sc],[sc,sc],'foreground_mat')
            s.body(key+'/Body',rect(x,-32,width,32))
            if i:seams.append({'kind':'front_wall','foot':[x+40,y],'overlap':width-step})
    front_run('NorthWall',1120,7775,2010)
    front_run('SouthWallWest',550,2040,4290)
    front_run('SouthWallEast',3100,8400,4290)
    def side_run(name,key,a,z,anchors):
        m=media[key];pad=m['padding'];p0,p1=anchors
        # Authored equal-height ends. Only contract the x/y axes; never magnify texture texels.
        count=4;delta=[(z[j]-a[j])/count for j in range(2)]
        scales=[abs(delta[0]/(p1[0]-p0[0])),abs(delta[1]/(p1[1]-p0[1]))]
        assert max(scales)<=1
        for i in range(count):
            start=[a[j]+i*delta[j] for j in range(2)];end=[start[j]+delta[j] for j in range(2)]
            node='Town/'+name+str(i);s.add(node,'Node2D','position = '+v(end))
            origin=[start[j]-(p0[j]+pad[j])*scales[j]-end[j] for j in range(2)]
            s.sprite(node+'/Art','r_'+key,origin,scales,'foreground_mat')
            # Solid strip follows the actual ground edge; ends meet exactly at the authored feet.
            q=[[start[0]-end[0]-32,start[1]-end[1]-25],[32,-25],[32,12],[start[0]-end[0]-32,start[1]-end[1]+12]]
            s.body(node+'/Body',q);seams.append({'kind':'side_wall','foot':end,'source_anchors':anchors,'scale':scales})
    side_run('WestWall','adobe_side_west',[1190,2010],[550,4290],[[987,552],[90,1360]])
    side_run('EastWall','adobe_side_east',[7700,2010],[8400,4290],[[58,564],[972,1491]])
    for i,p in enumerate([[1190,2010],[7700,2010],[550,4290],[8400,4290]]):
        m=media['adobe_tower'];b=m['bbox'];sc=.43;cx=(b[0]+b[2])/2;k='Town/CornerTower'+str(i)
        s.add(k,'Node2D','position = '+v(p));s.sprite(k+'/Art','r_adobe_tower',[-cx*sc,-b[3]*sc],[sc,sc],'foreground_mat');s.body(k+'/Body',rect(-150,-60,300,60))
    # Shrink each courtyard as one coherent subtree, including its solid edges and metadata.
    for parent in ['Town/CaravanCourt','Town/WaterCourt','Town/HomeCourt1','Town/HomeCourt2','Town/HomeCourt3']:
        old=nums(s.value(parent+'/Art','scale'))[0];f=1/old
        for key in list(s.nodes):
            if key!=parent and not key.startswith(parent+'/'):continue
            h,body=s.nodes[key]
            for prop in ['position','scale','polygon','metadata/visual_rect']:
                if key==parent and prop=='position':continue
                match=re.search(r'^'+re.escape(prop)+r' = (.*)$',body,re.M)
                if not match:continue
                value=match[1];n=nums(value);new=value.split('(')[0]+'('+', '.join(f'{q*f:.9f}' for q in n)+')'
                body=body.replace(match[0],prop+' = '+new)
            s.nodes[key]=[h,body]
    # Dunes are now small native repetitions at the original scenery-only outer positions.
    for i in range(1,7):
        parent='Town/OuterDune'+str(i);row=next(r for r in audit['scenes']['desert']['sprite_rows'] if r['node']==parent+'/Art');span=row['visible_logical_span'][0];b=row['alpha128_bbox'];sc=.9;width=(b[2]-b[0])*sc;n=math.ceil(span/(width*.78));s.remove(parent+'/Art')
        for j in range(n):
            x=-span/2+(span-width)*j/max(1,n-1);s.sprite(parent+'/Native'+str(j),'dune',[x-b[0]*sc,-b[3]*sc],[sc,sc])
    s.write();save(STAGE/'new-seams.json',seams)

if __name__=='__main__':{'prepare':prepare,'build':build}[sys.argv[1]]()
