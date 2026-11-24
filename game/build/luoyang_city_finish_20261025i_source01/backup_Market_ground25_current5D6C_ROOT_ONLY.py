"""Root-only CreateNew25 full backup; keep all current user changes, never rollback."""
from pathlib import Path
import argparse,json,hashlib,datetime
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';PLAN=S+'market_ground_texture_repair02/current5D6C_protection_backup25_ROOT_PLAN.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return G/p[6:]if p.startswith('res://')else Path(p)
def fact(p):
 p=res(p)
 if not p.exists():return dict(exists=False)
 a=p.stat();b=p.read_bytes();c=p.stat();assert(a.st_size,a.st_mtime_ns)==(c.st_size,c.st_mtime_ns)
 return dict(exists=True,sha256=sha(b),bytes=len(b),ticks=str(c.st_mtime_ns//100+621355968000000000))
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);ap.add_argument('--output',required=True);ap.add_argument('--root-authorized-backup25',action='store_true');a=ap.parse_args();raw=res(PLAN).read_bytes();assert sha(raw)==a.plan_sha256;plan=json.loads(raw)
 dest=res(a.output).resolve();assert dest.is_relative_to(N.resolve())and not dest.exists()
 observed={p:fact(p)for p in plan['frozen2121_expected']};assert len(observed)==2121
 differences=[dict(path=p,expected=f,current=observed[p],disposition='PRESERVED_NO_ROLLBACK')for p,f in plan['frozen2121_expected'].items()if observed[p]!=f]
 current32=[]
 for r in plan['current32']:
  f=fact(r['target']);assert f['sha256']==r['sha256']and f['bytes']==r['bytes'],('CURRENT32_CODE_DRIFT_KEEP_NO_BACKUP',r['target']);current32.append(dict(**{k:v for k,v in r.items()if k!='current'},current=f))
 saves={p:fact(p)for p in plan['save15_expected']};savechanges=[dict(path=p,old=plan['save15_expected'][p],current=f)for p,f in saves.items()if f!=plan['save15_expected'][p]]
 protected=plan['old240_backup_facts']+plan['media113']+[plan['ui']]
 for r in protected:assert fact(r['path'])=={k:v for k,v in r.items()if k in ['exists','sha256','bytes','ticks']},('PROTECTED_DRIFT_KEEP_AND_STOP',r['path'])
 rows=[];prefix=res(plan['Root_only_backup_prefix']).resolve();assert prefix.is_relative_to(N.resolve())and prefix!=N.resolve()
 if a.root_authorized_backup25:
  assert not savechanges,'CURRENT_SAVE_FACTS_CHANGED_KEEP_CURRENT_STOP'
  for r in plan['current25']:assert res(r['backup']).resolve().is_relative_to(prefix)and not res(r['backup']).exists(),('NEW25_BACKUP_MUST_BE_ABSENT',r['backup'])
  for r in plan['current25']:
   before=fact(r['target']);raw=res(r['target']).read_bytes();immutable=res(r['immutable_old']).read_bytes();assert raw==immutable and sha(raw)==r['old_sha256']and len(raw)==r['old_bytes']
   p=res(r['backup']);p.parent.mkdir(parents=True,exist_ok=True)
   with p.open('xb')as f:f.write(raw)
   after=fact(r['backup']);assert fact(r['target'])==before and after['sha256']==r['old_sha256']and after['bytes']==r['old_bytes'];rows.append(dict(target=r['target'],backup=r['backup'],sha256=after['sha256'],bytes=after['bytes'],source_ticks=before['ticks'],backup_ticks=after['ticks']))
 for p,f in saves.items():assert fact(p)==f,('SAVE_CHANGED_DURING_BACKUP_KEEP_CURRENT',p)
 for r in protected:assert fact(r['path'])=={k:v for k,v in r.items()if k in ['exists','sha256','bytes','ticks']}
 report=dict(status='ROOT_CURRENT5D6C_FULL25_BACKUP_AND_FRESH_OBSERVATION'if a.root_authorized_backup25 else'ROOT_CURRENT5D6C_FRESH_OBSERVATION_ONLY',passed=not savechanges,scope=plan['scope'],plan=dict(path=PLAN,sha256=a.plan_sha256),parent_deployment=plan['parent_deployment'],current32=current32,current25=plan['current25'],frozen2121_current_facts=[dict(path=p,**f)for p,f in observed.items()],differences=differences,save15=saves,external_save_changes=savechanges,old240_backup_facts=plan['old240_backup_facts'],new_backups=rows,total_backups=240+len(rows),media_facts=plan['media113'],ui=plan['ui'],canonical_writes=0,engine_calls=0,collector_calls=0,save_writes=0,processes_stopped=0,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(G).as_posix(),sha256=sha(raw),new_backups=len(rows),savechanges=len(savechanges),externaldifferences=len(differences))))
if __name__=='__main__':main()
