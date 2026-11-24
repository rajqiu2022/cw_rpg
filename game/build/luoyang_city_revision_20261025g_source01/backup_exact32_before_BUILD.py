"""Root-authorized CreateNew backup only; preserve all canonical/source times and user state."""
from pathlib import Path
import datetime
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025g_source01/'

def sha(raw): return hashlib.sha256(raw).hexdigest()
def resolve(path): return (GAME/path[6:]).resolve() if path.startswith('res://') else Path(path).resolve()
def pinned(path,h):
    raw=resolve(path).read_bytes()
    assert sha(raw)==h
    return json.loads(raw)
def fact(path):
    p=resolve(path)
    if not p.exists():return dict(exists=False)
    before=p.stat()
    with p.open('rb') as stream: h=hashlib.file_digest(stream,'sha256').hexdigest()
    after=p.stat()
    assert (before.st_size,before.st_mtime_ns)==(after.st_size,after.st_mtime_ns),path
    return dict(exists=True,sha256=h,bytes=after.st_size,ticks=str(after.st_mtime_ns//100+621355968000000000))
def sig(row):return {k:row[k] for k in ['exists','sha256','bytes','ticks'] if k in row}
def put(name,value):
    raw=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    p=HERE/name
    with p.open('xb') as stream:stream.write(raw)
    assert json.loads(p.read_bytes())==value
    return dict(path=S+name,sha256=sha(raw),bytes=len(raw))

freshpin=dict(path=S+'fresh_current25g_READONLY.json',sha256='4b8b0fbf7a7577ea0119cf1a7a9500cf87844f6ca07df4488266bd8c651a4e55')
draftpin=dict(path=S+'courtyard45_source_domain_DRAFT_NOTREADY.json',sha256='64728a809d86f5fe473d62d55deba59f2aa93a969c298f161a3507d9b250aa59')
reviewpin=dict(path=S+'runtime45_static_review_and_incremental_scope_READONLY.json',sha256='9c4019133eabc356ecfbf2e72c0c4ef6994bc16871eb48a73742875d0c2eaee3')
fresh=pinned(**dict(path=freshpin['path'],h=freshpin['sha256']))
draft=pinned(**dict(path=draftpin['path'],h=draftpin['sha256']))
review=pinned(**dict(path=reviewpin['path'],h=reviewpin['sha256']))
targets=draft['targets']
assert len(targets)==32 and len({r['target'] for r in targets})==32
assert sum(r['target'].endswith('.gd') for r in targets)==17
prefix=HERE/'predeploy32_old_backup'
receipt=HERE/'predeploy32_backup_receipt.json'
assert not prefix.exists() and not receipt.exists() and not (HERE/'courtyard45_exact32_scope_PREPARATION.json').exists()
start=datetime.datetime.now(datetime.timezone.utc).isoformat()
all33={r['target']:r for r in fresh['all33_fixed_target_checks']}
first33={p:fact(p) for p in all33}
assert all(v['sha256']==all33[p]['fixed_expected']['sha256'] and v['bytes']==all33[p]['fixed_expected']['bytes'] for p,v in first33.items())
saves={r['path']:r for r in fresh['current_save_protection_start']}
oldfacts={r['path']:r for r in fresh['current_facts']}
ui=[p for p in oldfacts if p.replace('\\','/').endswith('/scripts/ui/dialog_box.gd')]
assert len(ui)==1
firstsave={p:fact(p) for p in saves}
firstui={p:fact(p) for p in ui}
media_doc_path='res://build/luoyang_city_revision_20261025g_root01/mask_import_admission.json'
media_raw=resolve(media_doc_path).read_bytes()
media_doc=json.loads(media_raw)
assert media_doc['scope']=='ONLY_TWO_NEW_ABSENT_MASK_MEDIA_LEAVES' and len(media_doc['promoted'])==2
newmedia={p:fact(p) for p in media_doc['promoted']}
assert all(v['sha256']==media_doc['promoted'][p] for p,v in newmedia.items())
rows=[]
for row in targets:
    p=row['target'];source=resolve(p);before=first33[p]
    immutable=resolve(row['immutable_old']).read_bytes()
    raw=source.read_bytes()
    assert raw==immutable and sha(raw)==row['old_sha256'] and len(raw)==row['old_bytes']
    dest=prefix/p[6:]
    assert dest.is_relative_to(prefix) and not dest.exists()
    dest.parent.mkdir(parents=True,exist_ok=True)
    with dest.open('xb') as stream:stream.write(raw)
    after=fact(p);back=fact(str(dest))
    assert after==before and back['sha256']==row['old_sha256'] and back['bytes']==row['old_bytes']
    rows.append(dict(target=p,path=str(source),sha256=back['sha256'],bytes=back['bytes'],source_ticks=before['ticks'],backup=str(dest),backup_ticks=back['ticks'],immutable_old=row['immutable_old']))
after33={p:fact(p) for p in all33};aftersave={p:fact(p) for p in saves};afterui={p:fact(p) for p in ui};aftermedia={p:fact(p) for p in newmedia}
assert first33==after33 and firstsave==aftersave and firstui==afterui and newmedia==aftermedia
scope=dict(status='EXACT32_CURRENT9876_PARENT_SOURCE_PREPARATION_NOT_STAGE',ready=False,parent_stage=fresh['current_stage'],parent_deployment=fresh['current_deployment'],fresh=freshpin,static_review=reviewpin,count=32,partition=dict(GD=17,JSON=15),targets=[{k:r[k] for k in ['target','old_sha256','old_bytes','immutable_old']} for r in targets],no_new_members=True,OWNED=10,old_proof_count=162,depth_limit=16,no_shortcut=True,Router_unchanged=draft['unchanged_Router'],final_candidate_must_differ_from_old=True,extra_backup_superset_preserved_if_final_scope_removes_noop=True,source_rule='Fixed9876 current maps incremental; no live collector/current expected fill. Class64 and all old history retained.',pending=['System unique finalREADY consumers/helper/binding','exact new edges and proof leaves','Root final Stage input/driver review'])
scopepin=put('courtyard45_exact32_scope_PREPARATION.json',scope)
value=dict(status='EXACT32_CURRENT9876_PARENT_BACKED_UP_NO_CANONICAL_WRITES',passed=True,count=32,scope_sha256=scopepin['sha256'],scope=scopepin,fresh=freshpin,parent_stage=fresh['current_stage'],parent_deployment=fresh['current_deployment'],started_utc=start,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),targets=rows,old116_backups_preserved_not_rewritten=True,full_backup_total_after=148,current33_before=first33,current33_after=after33,UI_before=firstui,UI_after=afterui,saves15_before=firstsave,saves15_after=aftersave,preexisting_save_changes_since_fresh=[dict(path=p,before=sig(saves[p]),current=firstsave[p]) for p in saves if sig(saves[p])!=firstsave[p]],new_mask_two_media_admission=dict(path=media_doc_path,sha256=sha(media_raw)),new_mask_two_media_before=newmedia,new_mask_two_media_after=aftermedia,new_two_outside_original2121_protection_separately_recorded=True,protection2121_inherited_not_recrawled=True,all_source_save_UI_media_exactticks_unchanged_during_backup=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0,save_writes=0,source_timestamp_writes=0)
pin=put(receipt.name,value)
print(json.dumps(dict(scope=scopepin,backup=pin,count=32,total_preserved_backups=148,preexisting_save_changes=len(value['preexisting_save_changes_since_fresh']))))
