"""Observe only the fixed25h guard path list. Keep external changes, never restore."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,subprocess
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
PARENT=GAME/'build/luoyang_city_revision_20261025h_source01/guard_service_garden28_after_Field_READONLY.json'
PARENT_SHA='66d2557bf6078b4b39e87648c37b79bdfbc8523657b275c10686e2d117076146'
def sha(b):return hashlib.sha256(b).hexdigest()
raw=PARENT.read_bytes();assert sha(raw)==PARENT_SHA
parent=json.loads(raw);assert parent['passed'] and len(parent['current_facts'])==2121
cache={}
def fact(p):
    absolute=GAME/p[6:] if p.startswith('res://') else Path(p)
    key=str(absolute.resolve())
    if key in cache:return dict(cache[key],path=p)
    if not absolute.exists():row={'exists':False,'sha256':'ABSENT','bytes':0,'ticks':None}
    else:
        before=absolute.stat();ctx=hashlib.sha256()
        with absolute.open('rb') as stream:
            for data in iter(lambda:stream.read(1024*1024),b''):ctx.update(data)
        after=absolute.stat()
        assert (before.st_size,before.st_mtime_ns)==(after.st_size,after.st_mtime_ns),('CHANGED_DURING_OBSERVATION',p)
        row={'exists':True,'sha256':ctx.hexdigest(),'bytes':after.st_size,'ticks':str(after.st_mtime_ns//100+621355968000000000)}
    cache[key]=row
    return dict(row,path=p)
groups={};differences={}
for name in ['current_facts','saves','current33','backups_current','old_media_current','new_resource_ticks_observed_first_guard']:
    current=[];diff=[]
    for old in parent[name]:
        row=fact(old['path']);current.append(row)
        changes={k:{'old':old.get(k),'observed':row.get(k)} for k in ['exists','sha256','bytes','ticks'] if old.get(k)!=row.get(k)}
        if changes:diff.append({'path':old['path'],'changes':changes,'action':'KEEP_CURRENT_NO_ROLLBACK; not a gameplay expected value'})
    groups[name]=current;differences[name]=diff
cmd="Get-CimInstance Win32_Process | Where-Object { $_.Name -like '*Godot*' } | Select-Object ProcessId,Name,CommandLine | ConvertTo-Json -Compress"
inventory=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',cmd],capture_output=True,encoding='utf-8',errors='replace',check=True)
processes=json.loads(inventory.stdout) if inventory.stdout.strip() else []
if isinstance(processes,dict):processes=[processes]
for row in processes:row['role_observation']='EDITOR_KEEP' if '--editor' in str(row.get('CommandLine','')) else 'USER_OR_OTHER_GAME_KEEP_NO_SIGNAL'
report={'status':'FRESH25I_FIXED_PARENT_GUARD_READONLY_OBSERVATION_NOT_SOURCE_AUTHORITY_OR_ZERO_DRIFT_ASSERTION',
 'parent_guard':{'path':'res://build/luoyang_city_revision_20261025h_source01/'+PARENT.name,'sha256':PARENT_SHA},
 'observed_count':len(groups['current_facts']),'save_count':len(groups['saves']),'backup_count':len(groups['backups_current']),
 'groups':groups,'differences_from25h':differences,'running_Godot_readonly_inventory':processes,
 'no_external_change_reverted':True,'use_observed_saves_as_current_protection_start_only':True,
 'not_used_to_fill_gameplay_source_expectations':True,'canonical_writes':0,'save_writes':0,'engine_calls':0,'collector_calls':0,'processes_stopped':0,
 'finished_utc':datetime.now(timezone.utc).isoformat()}
p=HERE/'fresh25i_protection_observation01.json';data=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
with p.open('xb') as stream:stream.write(data)
print(json.dumps({'path':NS+p.name,'sha256':sha(data),'counts':{k:len(v) for k,v in groups.items()},'difference_counts':{k:len(v) for k,v in differences.items()},'processes':processes},ensure_ascii=False))
