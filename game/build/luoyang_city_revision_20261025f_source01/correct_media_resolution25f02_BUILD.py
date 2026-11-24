"""Correct only res:// media path observation; retain first report, no recrawl."""
from pathlib import Path
import json,hashlib,datetime
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025f_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def resolve(p):return (GAME/p[6:]).resolve() if p.startswith('res://') else Path(p).resolve()
def stat(p):
    if not p.exists():return dict(exists=False)
    s=p.stat();return dict(exists=True,bytes=s.st_size,ticks=str(s.st_mtime_ns//100+621355968000000000))
def fact(p):
    row=stat(p)
    if row['exists']:
        with p.open('rb') as f:row['sha256']=hashlib.file_digest(f,'sha256').hexdigest()
    return row
def sig(row):return {k:row.get(k) for k in ['exists','sha256','bytes','ticks']}
raw=(HERE/'fresh_current25f_READONLY.json').read_bytes();assert sha(raw)=='e17abc61c6b91ead01923a6485d190ea092068d68ad563f50ea089b27f5c7bab';doc=json.loads(raw)
assert len(doc['media_changes'])==6 and all(r['current']['exists'] is False and r['path'].startswith('res://') for r in doc['media_changes'])
priorpin=doc['parent24e_postguard'];priorraw=resolve(priorpin['path']).read_bytes();assert sha(priorraw)==priorpin['sha256'];prior=json.loads(priorraw)
before={r['path']:r for r in prior['new_media_current']};media=[];changes=[]
for p,row in before.items():
    current=dict(path=p,**fact(resolve(p)));media.append(current)
    if sig(row)!=sig(current):changes.append(dict(path=p,before=sig(row),current=sig(current)))
unchanged_stat=[r['path'] for r in doc['current_facts'] if stat(resolve(r['path']))!={k:r[k] for k in ['exists','bytes','ticks'] if k in r}]
assert not unchanged_stat,'Parent current facts changed; do not rehash/autoauthorize'
doc['media_facts']=media;doc['media_changes']=changes
doc['current_matches24e_guard']=not doc['changes_since24e_guard'] and not doc['backup_changes'] and not changes
doc['media_resolution_correction']=dict(parent_observation=dict(path=S+'fresh_current25f_READONLY.json',sha256=sha(raw)),cause='Only media list uses res:// paths; initial Path(res_path) observation falsely reported six ABSENT. NEW resolution uses fixed GAME/res-relative. Initial report preserved, not real source drift.',scope='Only six media rehashed; 2121 original facts were not rehashed; exact exists/bytes/ticks restat unchanged.',followup_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),no_original_functional_expectations_changed=True)
out=(json.dumps(doc,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();dest=HERE/'fresh_current25f02_READONLY.json';assert not dest.exists();dest.write_bytes(out)
assert (HERE/'fresh_current25f_READONLY.json').read_bytes()==raw
print(json.dumps(dict(path=S+dest.name,sha256=sha(out),bytes=len(out),current_matches24e=doc['current_matches24e_guard'],source_differences=len(doc['changes_since24e_guard']),save_differences=len(doc['preexisting_save_changes']),backup_differences=len(doc['backup_changes']),media_differences=len(changes),protected2121_rehashed=False,ENV_prospect18=True)))
