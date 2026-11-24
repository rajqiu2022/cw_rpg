"""Run only our isolated process, with bounded runtime and immutable logs."""
import subprocess,time
from desert_city_rework_20261029o import *
label=sys.argv[1];assert not (STAGE/(label+'.run.json')).exists()
exe='F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe'
args=[exe,'--path',str(PROJECT)]+sys.argv[2:]
with (STAGE/(label+'.stdout.txt')).open('wb') as out,(STAGE/(label+'.stderr.txt')).open('wb') as err:
    start=__import__('time').time();p=subprocess.Popen(args,stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW)
    save(STAGE/(label+'.run.json'),{'state':'RUNNING','pid':p.pid,'args':args});print('Private Godot',p.pid,flush=True)
    try:code=p.wait(timeout=180)
    except subprocess.TimeoutExpired:
        p.terminate();code=p.wait();save(STAGE/(label+'.run.json'),{'state':'TIMEOUT_OWN_PROCESS_TERMINATED','pid':p.pid,'exit_code':code});raise
    save(STAGE/(label+'.run.json'),{'state':'NATURAL_EXIT','pid':p.pid,'exit_code':code,'seconds':__import__('time').time()-start,'args':args})
print('Exit',code,flush=True)
sys.exit(code)
