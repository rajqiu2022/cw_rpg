"""Read-only protection baseline and isolated native asset preparation."""
import re,math
from four_settlements_20261030e import *
REUSE={
 'cottage':'art/modules/prop/prop_zhuwei_cottage_25d_v2.png',
 'inn':'art/modules/prop/prop_zhuwei_inn_25d_v2.png',
 'warehouse':'art/maps/luoyang_harbour_life_20261016/harbour_warehouse_v1.png',
 'office':'art/modules/luoyang_docks_office_20261016h/docks_cargo_office_v1.png',
 'ship':'art/maps/luoyang_harbour_life_20261016/cargo_ship_v1.png',
 'fence':'art/modules/linxi_fence_low_v1.png',
 'well':'art/modules/linxi_center_well_depth_prop_v1.png',
 'smithy':'art/modules/building/build_linxi_smithy_front.png',
 'small_home':'art/modules/miao_building_variety_20261029h/small_cottage.png'}
def copy_resource(rel):
 src=ROOT/'game'/rel;dst=PROJECT/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
 p=Path(str(src)+'.import')
 if p.exists():
  shutil.copy2(p,Path(str(dst)+'.import'))
  for leaf in re.findall(r'res://(\.godot/imported/[^"\]]+)',p.read_text('utf-8')):
   if (ROOT/'game'/leaf).exists():shutil.copy2(ROOT/'game'/leaf,PROJECT/leaf)
def baseline():
 paths=set()
 for r in json.loads((ROOT/'assets/staging/sect_completion_20261030a/protected-before-publication.json').read_text('utf-8')):paths.add(Path(r['path']))
 for p in (ROOT/'game/data/scenes').glob('*.tres'):paths.add(p)
 for p in (ROOT/'game/data/maps').glob('*.tres'):paths.add(p)
 for p in [ROOT/'game/scripts/field/field_walkable_controller.gd',ROOT/'game/autoload/scene_router.gd',ROOT/'game/build/three_towns_world_20261029j_system01/town_registry.gd',ROOT/'game/build/three_towns_world_20261029j_system01/native_sources.json']: 
  if p.exists():paths.add(p)
 save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(paths) if p.is_file()])
def prepare():
 assert not PROJECT.exists();baseline();prior=ROOT/'assets/staging/sect_completion_20261030a/town_project';PROJECT.mkdir()
 for folder in ['art','scripts','scenes','.godot/imported']:shutil.copytree(prior/folder,PROJECT/folder)
 (PROJECT/'review').mkdir();(PROJECT/'project.godot').write_text((prior/'project.godot').read_text('utf-8').replace('sect_completion_20261030a/lingyue.tscn',NAME+'/bailu.tscn'),'utf-8')
 media=json.loads((ROOT/'assets/staging/sect_completion_20261030a/media.json').read_text('utf-8'));checks=[]
 for r in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
  if r['kind']!='component':continue
  im=Image.open(ROOT/r['output']);assert im.mode=='RGBA',(r['key'],im.mode);w,h=im.size;a=im.getchannel('A');b=a.getbbox();native=a.point(lambda n:255 if n>=128 else 0).getbbox()
  px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
  out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
  dst=ROOT/'assets/processed'/NAME/(r['key']+'.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
  target=PROJECT/ART/dst.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,target)
  template=(ROOT/'game/art/modules/sect_maps_20261029k/wudang_hall.png.import').read_text('utf-8');rel='res://'+ART+'/'+dst.name;cache=dst.name+'-'+hashlib.md5(rel.encode()).hexdigest()+'.ctex'
  template=re.sub(r'uid="[^"]+"\n','',template).replace('res://art/modules/sect_maps_20261029k/wudang_hall.png',rel);template=re.sub(r'wudang_hall.png-[0-9a-f]+\.ctex',cache,template);Path(str(target)+'.import').write_text(template,'utf-8')
  media[r['key']]={'path':ART+'/'+dst.name,'bbox':[native[0]+px,native[1]+py,native[2]+px,native[3]+py],'padding':[px,py],'size':list(out.size),'raw':r['output'],'processed':dst.relative_to(ROOT).as_posix(),'label':r['label']}
  checks.append({'key':r['key'],'mode':im.mode,'raw_A1_pass':min(b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h)>=.1,'original_RGBA_exact':True,'only_RGBA0_padding':True,'alpha_cleaned_pixels':0,'offset':[px,py],'alpha_bbox':b,'opaque_bbox':native})
  canvas=Image.new('RGBA',out.size,(100,120,140,255));canvas.alpha_composite(out);canvas.thumbnail((750,500));canvas.convert('RGB').save(STAGE/(r['key']+'-review.jpg'))
 for key,rel in REUSE.items():
  if not (ROOT/'game'/rel).exists():
   matches=list((ROOT/'game/art').rglob(Path(rel).name));assert len(matches)==1,(rel,matches);rel=matches[0].relative_to(ROOT/'game').as_posix()
  copy_resource(rel);im=Image.open(PROJECT/rel).convert('RGBA');media[key]={'path':rel,'bbox':list(im.getchannel('A').point(lambda n:255 if n>=128 else 0).getbbox()),'size':list(im.size),'padding':[0,0],'reused':True}
 for r in media.values():
  if not (PROJECT/r['path']).exists():copy_resource(r['path'])
 for rel in ['scripts/drafts/sect_completion_20261030a/controller.gd','scripts/drafts/sect_completion_20261030a/ghost.gd','scripts/drafts/sect_maps_20261029k/terrain.gd']:copy_resource(rel)
 save(STAGE/'media.json',media);save(STAGE/'padding-verification.json',checks);print(json.dumps(checks))
if __name__=='__main__':prepare()
