"""Bounded hidden private Godot runs; never control the user's editor."""
import sys,subprocess,time
from sect_completion_20261030a import *
EXE=Path('F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe')
label=sys.argv[1];assert not (STAGE/(label+'.run.json')).exists()
args=[str(EXE),'--path',str(PROJECT)]+sys.argv[2:]
with (STAGE/(label+'.stdout.txt')).open('wb') as out,(STAGE/(label+'.stderr.txt')).open('wb') as err:
    start=time.time();p=subprocess.Popen(args,stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW)
    save(STAGE/(label+'.run.json'),{'pid':p.pid,'args':args,'state':'RUNNING'})
    print('Started private Godot',p.pid,flush=True)
    try:code=p.wait(timeout=150)
    except subprocess.TimeoutExpired:
        p.terminate();code=p.wait();save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'TIMEOUT_OWN_PROCESS_TERMINATED','exit_code':code});raise
    save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'NATURAL_EXIT','exit_code':code,'seconds':round(time.time()-start,3),'args':args})
    print('Natural exit',code,flush=True)
sys.exit(code)
