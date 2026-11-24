"""Fixed 25f final whitelist observation. No rollback/current-derived source approval."""
from pathlib import Path
import json,hashlib,datetime,subprocess,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025g_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def resolve(p):return (GAME/p[6:]).resolve() if p.startswith('res://') else Path(p).resolve()
def load(pin):
    raw=resolve(pin['path']).read_bytes();assert sha(raw)==pin['sha256'];return json.loads(raw)
def stat(p):
    if not p.exists():return dict(exists=False)
    s=p.stat();return dict(exists=True,bytes=s.st_size,ticks=str(s.st_mtime_ns//100+621355968000000000))
def fact(p):
    row=stat(p)
    if row['exists']:
        with p.open('rb') as f:row['sha256']=hashlib.file_digest(f,'sha256').hexdigest()
    return row
def sig(row):return {k:row.get(k) for k in ['exists','sha256','bytes','ticks']}
guardpin=dict(path='res://build/luoyang_city_revision_20261025f_qa01/guard18_after_Field_READONLY.json',sha256='4e7131ac0a1b99a55b11028c3b3073e524f5ab96623c139ce7517999575ce5c0')
stagepin=dict(path='res://build/luoyang_city_revision_20261025f_source01/outputs/root_street_materials_exact18_stage01/receipt.json',sha256='9876e1cc4bab5e292d9d15052b7758c7d4f1ce5e98fecfb49fda4b6f45feff67')
deppin=dict(path='res://build/luoyang_city_revision_20261025f_root01/street_materials18_deployed_actual.json',sha256='9154c72b8240aff417c3af7c910f3b78659b83814ee06cf681aed644d8caf734')
seedpin=dict(path='res://build/luoyang_city_revision_20261025f_source01/fresh_current25f02_READONLY.json',sha256='e92b03c9ca2e5e5a95bfc8f8bf1451e8550a5d841a366bc2c1c2c0d738775a22')
guard=load(guardpin);stage=load(stagepin);dep=load(deppin);seed=load(seedpin)
assert guard['passed'] is True and guard['observed_count']==2121 and guard['full_backup_count']==116 and guard['save_count']==15 and guard['all_new_mask_media_count']==6
assert dep['stage_sha256']==stagepin['sha256'] and len(stage['targets'])==len(dep['targets'])==18 and stage['source_first']==stage['source_final']
expected={r['target']:dict(r['expected_from_fixed_deployment_or_immutable']) for r in seed['all_33_declared_target_checks']}
deployment={r['target']:r for r in dep['targets']}
for row in stage['targets']:
    p=row['target'];assert expected[p]['sha256']==row['old_sha256'] and deployment[p]['sha256']==row['candidate_sha256']
    expected[p]=dict(sha256=row['candidate_sha256'],bytes=deployment[p]['bytes'],immutable_candidate=row['candidate_path'])
assert len(expected)==33
started=datetime.datetime.now(datetime.timezone.utc).isoformat();old={r['path']:r for r in guard['current_facts']};assert len(old)==2121
current={p:fact(resolve(p)) for p in old};savepaths={r['path'] for r in guard['saves']};targetpaths={str(resolve(p)) for p in expected}
changes=[]
for p,row in old.items():
    if sig(row)!=sig(current[p]):changes.append(dict(path=p,kind='PREEXISTING_USER_SAVE_CHANGE_PRESERVE_LATEST' if p in savepaths else ('PREEXISTING_DECLARED_TARGET_DRIFT_NOT_FUNCTIONALLY_APPROVED' if p in targetpaths else 'PREEXISTING_OTHER_CHANGE_PRESERVE'),before=sig(row),current=sig(current[p])))
targetchecks=[]
for p,pin in expected.items():
    row=current[str(resolve(p))];targetchecks.append(dict(target=p,fixed_expected=pin,current=row,exact_SHA_bytes=row.get('sha256')==pin['sha256'] and row.get('bytes')==pin['bytes']))
backups=[];backupchanges=[];media=[];mediachanges=[]
for rows,out,delta in [(guard['backups_current'],backups,backupchanges),(guard['new_media_current'],media,mediachanges)]:
    for before in rows:
        now=dict(path=before['path'],**fact(resolve(before['path'])));out.append(now)
        if sig(now)!=sig(before):delta.append(dict(path=before['path'],before=sig(before),current=sig(now)))
assert len(backups)==116 and len(media)==6 and len(savepaths)==15
unstable=[p for p,v in current.items() if stat(resolve(p))!={k:v[k] for k in ['exists','bytes','ticks'] if k in v}]
ps="@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^Godot.*\\.exe$' } | ForEach-Object { [pscustomobject]@{ pid=$_.ProcessId; name=$_.Name; executable=$_.ExecutablePath; command_line=$_.CommandLine } }) | ConvertTo-Json -Depth 3 -Compress"
process_result=subprocess.run(['powershell','-NoProfile','-Command',ps],capture_output=True,text=True,check=True);processes=json.loads(process_result.stdout) if process_result.stdout.strip() else []
if isinstance(processes,dict):processes=[processes]
for row in processes:row['role_observation']='EDITOR_KEEP' if re.search(r'(^|\s)(--editor|-e)(\s|$)',row.get('command_line') or '') else 'USER_OR_OTHER_GODOT_KEEP_DO_NOT_STOP'
doc=dict(status='SOURCE25G_FIXED25F_CURRENT_PROTECTION_READONLY_OBSERVATION_NOT_STAGE',namespace=S,parent_final_guard=guardpin,current_deployment=deppin,current_stage=stagepin,started_utc=started,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),observed_count=2121,protected_count=2120,UI_extra_count=1,save_count=15,full_backup_count=116,mask_media_count=6,current33_fixed_SHA_bytes_match=all(r['exact_SHA_bytes'] for r in targetchecks),current_matches25f_guard=not changes and not backupchanges and not mediachanges,capture_stable=not unstable,changes_since25f_guard=changes,save_changes=[r for r in changes if r['path'] in savepaths],existing_target_drift=[r for r in changes if r['path'] in targetpaths],other_changes=[r for r in changes if r['path'] not in savepaths|targetpaths],backup_changes=backupchanges,media_changes=mediachanges,unstable_during_capture=unstable,current_facts=[dict(path=p,**v) for p,v in current.items()],current_save_protection_start=[dict(path=p,**current[p]) for p in sorted(savepaths)],backups_current=backups,new_media_current=media,all33_fixed_target_checks=targetchecks,running_Godot_readonly_inventory=processes,no_process_action=True,all_existing_user_changes_preserved_no_rollback=True,functional_authority_not_current_hash_fill=True,current_OWNED10_proof162_depth16_unchanged=True,old8_812578_is_not25g_performance=True,Stage_calls=0,collector_calls=0,engine_calls=0,imports=0,canonical_writes=0,save_writes=0,processes_stopped=0)
raw=(json.dumps(doc,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();dest=HERE/'fresh_current25g_READONLY.json';assert not dest.exists();dest.write_bytes(raw)
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw),source_changes=len(changes),save_changes=len(doc['save_changes']),backup_changes=len(backupchanges),media_changes=len(mediachanges),current33_match=doc['current33_fixed_SHA_bytes_match'],unstable=len(unstable),Godot=[dict(pid=r['pid'],role=r['role_observation']) for r in processes])))
