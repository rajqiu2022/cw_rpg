"""Own bounded Linxi entrance investigation; never operates a user editor/game."""
import json,hashlib,subprocess,sys,time,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'assets/staging/linxi_entry_repair_20261029q'
QA=ROOT/'game/build/linxi_entry_repair_20261029q'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n','utf-8')
def fact(p):return {'path':str(p),'exists':p.is_file(),**({'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} if p.is_file() else {})}
if __name__=='__main__' and sys.argv[1]=='prepare':
    assert not STAGE.exists();STAGE.mkdir(parents=True)
    paths=[ROOT/'game/data/scenes/linxi_farmer_cottage.tres',ROOT/'game/data/maps/linxi_farmer_cottage_layout_v1.tres',ROOT/'game/data/maps/linxi_village_center_layout_v1.tres']
    paths += [ROOT/'game/scripts/autoload/scene_router.gd',ROOT/'game/scripts/field/field_walkable_controller.gd',ROOT/'game/project.godot']
    paths += [Path(r) for r in json.loads((ROOT/'game/build/three_towns_world_20261029j_qa01/trips_READY.json').read_text('utf-8'))['registered_save_paths'] if not r.startswith('user://')]
    save(STAGE/'before.json',[fact(p) for p in paths])
    for p in paths[:6]:
        dest=STAGE/'backup'/p.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
elif __name__=='__main__' and sys.argv[1]=='run':
    label=sys.argv[2];assert not (STAGE/(label+'.run.json')).exists()
    args=['F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe','--path',str(ROOT/'game'),'--resolution','1920x1080','--script','res://build/linxi_entry_repair_20261029q/'+label+'.gd']
    with (STAGE/(label+'.stdout.txt')).open('wb') as out,(STAGE/(label+'.stderr.txt')).open('wb') as err:
        start=time.time();p=subprocess.Popen(args,stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW);save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'RUNNING'});print('Own Linxi QA',p.pid,flush=True)
        try:code=p.wait(timeout=90)
        except subprocess.TimeoutExpired:
            p.terminate();code=p.wait();save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'TIMEOUT_OWN_PROCESS_TERMINATED','exit':code});raise
        save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'NATURAL_EXIT','exit':code,'seconds':time.time()-start})
    print('Exit',code,flush=True);sys.exit(code)
