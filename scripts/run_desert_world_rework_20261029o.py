"""Bounded formal World-only regression of the two changed visual/solid contracts."""
import subprocess,time
from desert_city_rework_20261029o import *
QA=ROOT/'game/build/desert_city_rework_20261029o_qa'
assert not (STAGE/'formal01.run.json').exists()
fixture=json.loads((ROOT/'game/build/three_towns_world_20261029j_qa01/trips_READY.json').read_text('utf-8'))
fixture['legs']=fixture['legs'][:2]
for row,key,node,texture in zip(fixture['legs'],['world_redrock','world_desert'],['Town/TownNorthBank/Native0','Town/WallFront/Art'],['redrock_cliff','adobe_gate']):
    row.update(new_landmark='res://'+ART+'/'+key+'.png',replacement_node=node,replacement_texture='res://'+ART+'/'+texture+'.png')
manifest=json.loads((ROOT/'game/build/three_towns_world_20261029j_system01/native_sources.json').read_text('utf-8'))
paths=list(manifest['sources'])+['res://build/three_towns_world_20261029j_system01/town_registry.gd','res://build/three_towns_world_20261029j_system01/native_sources.json','res://scripts/autoload/scene_router.gd']
fixture['fixed_sources']={p:sha(ROOT/'game'/p[6:]) for p in paths}
save(QA/'fixture01.json',fixture)
args=['F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe','--path',str(ROOT/'game'),'--resolution','1920x1080','--script','res://build/desert_city_rework_20261029o_qa/world01.gd']
with (STAGE/'formal01.stdout.txt').open('wb') as out,(STAGE/'formal01.stderr.txt').open('wb') as err:
    start=time.time();p=subprocess.Popen(args,stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW);save(STAGE/'formal01.run.json',{'state':'RUNNING','pid':p.pid,'args':args});print('Own formal QA',p.pid,flush=True)
    try:code=p.wait(timeout=150)
    except subprocess.TimeoutExpired:
        p.terminate();code=p.wait();save(STAGE/'formal01.run.json',{'state':'TIMEOUT_OWN_PROCESS_TERMINATED','pid':p.pid,'exit_code':code});raise
    save(STAGE/'formal01.run.json',{'state':'NATURAL_EXIT','pid':p.pid,'exit_code':code,'seconds':time.time()-start,'args':args})
print('Exit',code,flush=True);sys.exit(code)
