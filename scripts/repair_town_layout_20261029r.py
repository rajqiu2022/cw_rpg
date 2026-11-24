"""Stage only the reported courtyard/occlusion fixes; preserve published files until review."""
import sys,json,re,shutil,hashlib,subprocess,time
from pathlib import Path
from build_desert_city_rework_20261029o import Scene,SCENES,nums,v
ROOT=Path(__file__).resolve().parents[1];NAME='town_layout_20261029r'
STAGE=ROOT/'assets/staging'/NAME;PROJECT=STAGE/'town_project'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,data):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n','utf-8')
def stage():
    STAGE.mkdir(parents=True,exist_ok=False)
    prior=ROOT/'assets/staging/desert_city_rework_20261029o/town_project'
    shutil.copytree(prior,PROJECT)
    (PROJECT/'review-r').mkdir()
    # Refresh only referenced text/source/image dependencies from the current published scenes.
    pending=list(SCENES.values());seen=set()
    while pending:
        rel=pending.pop()
        if rel in seen:continue
        seen.add(rel);src=ROOT/'game'/rel
        if not src.is_file():continue
        dst=PROJECT/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
        if src.suffix in ['.gd','.tscn','.tres','.json','.gdshader']:
            pending+=re.findall(r'res://([^"\s)]+)',src.read_text('utf-8'))
    saves=json.loads((ROOT/'game/build/three_towns_world_20261029j_qa01/trips_READY.json').read_text('utf-8'))['registered_save_paths']
    protect=[ROOT/'game'/p for p in seen if (ROOT/'game'/p).is_file()]+[Path(p) for p in saves if not p.startswith('user://')]
    save(STAGE/'before.json',[{'path':str(p),'exists':p.is_file(),**({'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} if p.is_file() else {})} for p in protect])
    for rel in SCENES.values():
        dest=STAGE/'backup'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/'game'/rel,dest)
def courtyard():
    s=Scene(SCENES['desert'])
    # A shallow front enclosure has open rear bays against the buildings. The former
    # complete-ring rear and side walls cut directly through those building feet.
    for name in ['CaravanCourt','HomeCourt1','HomeCourt2','HomeCourt3']:
        parent='Town/'+name
        s.remove(parent+'/Art')
        for edge in ['Edge0','Edge1','Edge2']:s.remove(parent+'/'+edge)
        s.prop(parent,'metadata/visual_rect','Rect2(-680, -150, 1360, 154)')
        s.prop(parent,'metadata/label','"门前矮墙：房屋与棚湾保留完整基脚，两侧接街通行。"')
    # The west perimeter also clipped the western dwelling roof after the old native resize.
    for name in ['WestWall0','WestWall1','WestWall2','WestWall3','CornerTower0','CornerTower2']:
        p=nums(s.value('Town/'+name,'position'));p[0]-=350;s.prop('Town/'+name,'position',v(p))
    for source,target in [('NorthWall0','NorthWestClosure'),('SouthWallWest0','SouthWestClosure')]:
        prefix='Town/'+source
        for key in list(s.order):
            if key==prefix or key.startswith(prefix+'/'):
                h,b=s.nodes[key];dest=key.replace(prefix,'Town/'+target,1)
                kind=re.search(r'type="([^"]+)"',h)[1];s.add(dest,kind,b)
        p=nums(s.value('Town/'+target,'position'));p[0]-=350;s.prop('Town/'+target,'position',v(p))
    s.head=s.head.replace('res://scripts/drafts/desert_town_20261029d/town_controller.gd','res://scripts/drafts/'+NAME+'/desert_controller.gd')
    p=PROJECT/SCENES['desert'];p.write_text(s.head+'\n'.join('[node '+s.nodes[k][0]+']\n'+s.nodes[k][1]+'\n' for k in s.order),'utf-8')
    scripts=PROJECT/'scripts/drafts'/NAME;scripts.mkdir(parents=True,exist_ok=True)
    for p in (ROOT/'scripts/templates'/NAME).glob('*'):shutil.copy2(p,scripts/p.name)
def redrock():
    s=Scene(SCENES['redrock'])
    s.head=s.head.replace('res://scripts/drafts/redrock_city_life_20261029a/town_controller.gd','res://scripts/drafts/'+NAME+'/redrock_controller.gd')
    p=PROJECT/SCENES['redrock'];p.write_text(s.head+'\n'.join('[node '+s.nodes[k][0]+']\n'+s.nodes[k][1]+'\n' for k in s.order),'utf-8')
    src=ROOT/'game/scripts/drafts/sect_maps_20261029k/terrain.gd';dst=PROJECT/'scripts/drafts/sect_maps_20261029k/terrain.gd';dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    for p in (ROOT/'scripts/templates'/NAME).glob('*'):shutil.copy2(p,PROJECT/'scripts/drafts'/NAME/p.name)
def run(label):
    exe='F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe'
    assert not (STAGE/(label+'.run.json')).exists()
    with (STAGE/(label+'.stdout.txt')).open('wb') as out,(STAGE/(label+'.stderr.txt')).open('wb') as err:
        start=time.time();p=subprocess.Popen([exe,'--path',str(PROJECT),'--resolution','1920x1080','--script','res://scripts/drafts/'+NAME+'/'+label+'.gd'],stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW)
        save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'RUNNING'});print(p.pid,flush=True)
        try:code=p.wait(timeout=90)
        except subprocess.TimeoutExpired:p.terminate();p.wait();raise
        save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'NATURAL_EXIT','exit':code,'seconds':time.time()-start})
        print('exit',code);sys.exit(code)
if __name__=='__main__':
    if sys.argv[1]=='stage':stage();courtyard()
    elif sys.argv[1]=='courtyard':courtyard()
    elif sys.argv[1]=='redrock':redrock()
    elif sys.argv[1]=='run':run(sys.argv[2])
