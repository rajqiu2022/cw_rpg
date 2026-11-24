from repair_town_layout_20261029r import *
label=sys.argv[1] if len(sys.argv)>1 else 'formal05';exe='F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe'
assert not (STAGE/(label+'.run.json')).exists()
with (STAGE/(label+'.stdout.txt')).open('wb') as out,(STAGE/(label+'.stderr.txt')).open('wb') as err:
    t=time.time();p=subprocess.Popen([exe,'--path',str(ROOT/'game'),'--resolution','1920x1080','--script','res://build/town_layout_20261029r_qa/'+label+'.gd'],stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW)
    save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'RUNNING'});print(p.pid,flush=True)
    try:code=p.wait(timeout=75)
    except subprocess.TimeoutExpired:p.terminate();p.wait();raise
    save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'NATURAL_EXIT','exit':code,'seconds':time.time()-t});print('exit',code);sys.exit(code)
