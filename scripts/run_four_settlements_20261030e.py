"""Own, hidden, bounded process only. No user editor control."""
import subprocess,time
from four_settlements_20261030e import *
label=sys.argv[1];mode=sys.argv[2] if len(sys.argv)>2 else 'private'
exe='F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe'
project=ROOT/'game' if mode=='formal' else PROJECT
args=['--headless','--editor','--quit'] if mode=='import' else ['--resolution','1600x1000','--script',('res://build/four_settlements_20261030e_qa/' if mode=='formal' else 'res://')+label+'.gd']
assert not (STAGE/(label+'.run.json')).exists()
with (STAGE/(label+'.stdout.txt')).open('wb') as out,(STAGE/(label+'.stderr.txt')).open('wb') as err:
 t=time.time();p=subprocess.Popen([exe,'--path',str(project)]+args,stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW)
 save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'RUNNING'});print(p.pid,flush=True)
 try:code=p.wait(timeout=150)
 except subprocess.TimeoutExpired:p.terminate();p.wait();save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'WATCHDOG_TIMEOUT'});raise
 save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'NATURAL_EXIT','exit':code,'seconds':time.time()-t});print('exit',code);sys.exit(code)
