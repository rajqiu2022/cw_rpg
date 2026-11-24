"""Observe fixed25g guard only; retain external user changes, never authorize from current hashes."""
from pathlib import Path
import hashlib,json,datetime,subprocess,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return (GAME/p[6:]).resolve() if p.startswith('res://') else Path(p).resolve()
def load(pin):
    raw=res(pin['path']).read_bytes();assert sha(raw)==pin['sha256'];return json.loads(raw)
def stat(p):
    if not p.exists():return dict(exists=False)
    s=p.stat();return dict(exists=True,bytes=s.st_size,ticks=str(s.st_mtime_ns//100+621355968000000000))
def fact(p):
    before=stat(p);out=dict(before)
    if before['exists']:
        with p.open('rb') as stream:out['sha256']=hashlib.file_digest(stream,'sha256').hexdigest()
    return out,stat(p)==before
def sig(r):return {k:r[k] for k in ['exists','sha256','bytes','ticks'] if k in r}
gp=dict(path='res://build/luoyang_city_revision_20261025g_qa01/guard32_after_Field_READONLY.json',sha256='6e8df772da1be3efc3bd2cfea1c8f7f0242fdaa9cab5e64289b0ff0ab8146a73')
sp=dict(path='res://build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json',sha256='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396')
dp=dict(path='res://build/luoyang_city_revision_20261025g_root01/courtyard45_32_deployed_actual.json',sha256='7f2a7be12b86f3021d87dfc0f74294e2961c3ef376e4c8bb533cc59a74870071')
fp=dict(path='res://build/luoyang_city_revision_20261025g_source01/fresh_current25g_READONLY.json',sha256='4b8b0fbf7a7577ea0119cf1a7a9500cf87844f6ca07df4488266bd8c651a4e55')
guard=load(gp);stage=load(sp);dep=load(dp);priorfresh=load(fp)
assert guard['passed'] is True and guard['observed_count']==2121 and guard['full_backup_count']==148 and guard['all_admitted_media_count']==8 and guard['save_count']==15
assert dep['stage_sha256']==sp['sha256'] and stage['source_first']==stage['source_final']
expected={r['target']:dict(r['fixed_expected']) for r in priorfresh['all33_fixed_target_checks']};deployed={r['target']:r for r in dep['targets']}
assert len(expected)==33 and len(deployed)==32
for r in stage['targets']:
    assert expected[r['target']]['sha256']==r['old_sha256'] and deployed[r['target']]['sha256']==r['candidate_sha256']
    expected[r['target']]=dict(sha256=r['candidate_sha256'],bytes=deployed[r['target']]['bytes'],immutable_candidate=r['candidate_path'])
started=datetime.datetime.now(datetime.timezone.utc).isoformat();unstable=[]
def observe(rows):
    out=[];changes=[]
    for before in rows:
        now,stable=fact(res(before['path']));row=dict(path=before['path'],**now);out.append(row)
        if not stable:unstable.append(before['path'])
        if sig(before)!=sig(now):changes.append(dict(path=before['path'],before=sig(before),current=sig(now)))
    return out,changes
current,changes=observe(guard['current_facts']);backups,backupchanges=observe(guard['backups_current']);media,mediachanges=observe(guard['new_media_current'])
by_path={r['path']:r for r in current};savepaths={r['path'] for r in guard['saves']};targets_abs={str(res(p)) for p in expected}
checks=[]
for p,pin in expected.items():
    now=by_path[str(res(p))];checks.append(dict(target=p,fixed_expected=pin,current=now,exact_SHA_bytes=now.get('sha256')==pin['sha256'] and now.get('bytes')==pin['bytes']))
ps="@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^Godot.*\\.exe$' } | ForEach-Object { [pscustomobject]@{ pid=$_.ProcessId; name=$_.Name; executable=$_.ExecutablePath; command_line=$_.CommandLine } }) | ConvertTo-Json -Depth 3 -Compress"
pr=subprocess.run(['powershell','-NoProfile','-Command',ps],capture_output=True,text=True,check=True);processes=json.loads(pr.stdout) if pr.stdout.strip() else []
if isinstance(processes,dict):processes=[processes]
for p in processes:p['role_observation']='EDITOR_KEEP' if re.search(r'(^|\s)(--editor|-e)(\s|$)',p.get('command_line') or '') else 'USER_OR_OTHER_GODOT_KEEP_DO_NOT_STOP'
value=dict(status='SOURCE25H_FIXED25G_CURRENT_PROTECTION_FRESH_READONLY',namespace=S,parent_guard=gp,current_stage=sp,current_deployment=dp,started_utc=started,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),observed_count=2121,protected_count=2120,UI_extra_count=1,save_count=15,full_backup_count=148,media_count=8,current33_fixed_target_checks=checks,current32_and_Router_fixed_SHA_bytes_match=all(r['exact_SHA_bytes'] for r in checks),current_facts=current,current_save_protection_start15=[by_path[p] for p in sorted(savepaths)],backups_current148=backups,new_media_current8=media,changes_since25g_guard=changes,save_changes=[r for r in changes if r['path'] in savepaths],existing_target_drift=[r for r in changes if r['path'] in targets_abs],other_changes=[r for r in changes if r['path'] not in savepaths|targets_abs],backup_changes=backupchanges,media_changes=mediachanges,unstable_during_read=unstable,baseline_same=not changes and not backupchanges and not mediachanges and not unstable,running_Godot_readonly_inventory=processes,preexisting_external_changes_preserved_no_rollback=True,functional_authority_not_current_hash_fill=True,OWNED=10,proof_count=170,depth_limit=16,old25g_component_or24e_loading_not25h_measurement=True,Stage_calls=0,engine_calls=0,collector_calls=0,imports=0,canonical_writes=0,save_writes=0,processes_stopped=0)
raw=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();dest=HERE/'fresh_current25h_READONLY.json'
with dest.open('xb') as out:out.write(raw)
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw),baseline_same=value['baseline_same'],source_changes=len(changes),save_changes=len(value['save_changes']),backup_changes=len(backupchanges),media_changes=len(mediachanges),current33_match=value['current32_and_Router_fixed_SHA_bytes_match'],Godot=[dict(pid=p['pid'],role=p['role_observation']) for p in processes])))
