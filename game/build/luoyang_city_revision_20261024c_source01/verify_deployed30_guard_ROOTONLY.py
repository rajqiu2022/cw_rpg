"""Root-only post-copy read guard. No engine/collector/source or save mutation."""
from pathlib import Path
import hashlib,json,argparse
GAME=Path(__file__).resolve().parents[2]
R='res://build/luoyang_city_revision_20261024c_root01/'
STAGE='res://build/luoyang_city_revision_20261024c_source01/outputs/root_courts_scholar_exact30_stage03/receipt.json'
STAGE_SHA='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce'
FRESH='res://build/luoyang_city_revision_20261024b_root01/c_start_fresh_observation.json'
FRESH_SHA='18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a'
BACKUP=R+'exact30_old_backup/receipt.json';BACKUP_SHA='f55b46d79bac42868f840232f491569c6dc952c8518a576ddd61d7df3d1114fb'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://') and '..' not in p
    x=(GAME/p[6:]).resolve();assert x.is_relative_to(GAME.resolve());return x
def load(p,h):
    b=res(p).read_bytes();assert sha(b)==h;return json.loads(b)
cache={}
def fact(p):
    p=Path(p).resolve();key=str(p).lower()
    if key in cache:return cache[key]
    if not p.exists():v=dict(exists=False)
    else:
        st=p.stat()
        with p.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
        v=dict(exists=True,sha256=h,bytes=st.st_size,ticks=str(st.st_mtime_ns//100+621355968000000000))
    cache[key]=v;return v
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--deployment-sha256',required=True)
    ap.add_argument('--output-name',choices=['pre_Field30_guard_actual.json','post_Field30_guard_actual.json'],required=True);a=ap.parse_args()
    out=res(R+a.output_name);assert not out.exists(),'NEW_ROOT_GUARD_ONLY'
    s=load(STAGE,STAGE_SHA);fresh=load(FRESH,FRESH_SHA);back=load(BACKUP,BACKUP_SHA)
    dep=load(R+'deployment30_actual.json',a.deployment_sha256)
    assert dep['passed'] is True and dep['target_count']==30 and dep['stage']==dict(path=STAGE,sha256=STAGE_SHA)
    assert s['source_first']==s['source_final'] and s['target_partition']==dict(patch_count=15,copy_count=15,total=30)
    targets={r['target']:r for r in s['targets']};assert len(targets)==30
    target_abs={str(res(p)).lower():r for p,r in targets.items()}
    failures=[];changed=[];now=[]
    assert fresh['checked']==len(fresh['facts'])==2120 and len(fresh['save_paths'])==15
    oldfacts={str(Path(r['path']).resolve()).lower():r for r in fresh['facts']}
    assert set(target_abs)<=set(oldfacts)
    for row in fresh['facts']:
        p=Path(row['path']).resolve();key=str(p).lower();actual=fact(p);now.append(dict(path=str(p),**actual))
        if key in target_abs:
            t=target_abs[key];expected_size=res(t['candidate_path']).stat().st_size
            if not actual.get('exists') or actual['sha256']!=t['candidate_sha256'] or actual['bytes']!=expected_size:failures.append('TARGET_NOT_EXACT:'+str(p))
            if actual.get('sha256')!=row['sha256']:changed.append(t['target'])
        elif any(actual.get(k)!=row.get(k) for k in ['exists','sha256','bytes','ticks']):failures.append('UNAUTHORIZED_PROTECTED_CHANGE:'+str(p))
    if len(changed)!=30:failures.append('EXPECTED_EXACT30_AUTHORIZED_CHANGES')
    # Stage source keys include ordinary new media/helper/binding and all fixed ancestry.
    # Resolve each physical path once across protected and Stage domains, never reuse an old digest.
    source_changed=[]
    for p,old in s['source_first'].items():
        expected=targets[p]['candidate_sha256'] if p in targets else old
        if fact(res(p)).get('sha256')!=expected:failures.append('UNAUTHORIZED_STAGE_SOURCE_CHANGE:'+p)
        if p in targets and expected!=old:source_changed.append(p)
    backups_ok=True
    for row in back['rows']:
        f=fact(row['backup'])
        if not f.get('exists') or f['sha256']!=row['old_sha256'] or f['bytes']!=row['bytes']:backups_ok=False;failures.append('OLD_BACKUP_CHANGED:'+row['target'])
    save_facts=[]
    for p in fresh['save_paths']:
        key=str(Path(p).resolve()).lower();old=oldfacts[key];f=fact(p);save_facts.append(dict(path=p,**f))
        if any(f.get(k)!=old.get(k) for k in ['exists','sha256','bytes','ticks']):failures.append('SAVE_CHANGED:'+p)
    report=dict(status='ROOT_POSTDEPLOY_EXACT30_FULL_SOURCE_AND_SAVE_GUARD',passed=not failures,checked=2120,protected_count=2120,
      stage=dict(path=STAGE,sha256=STAGE_SHA),deployment=dict(path=R+'deployment30_actual.json',sha256=a.deployment_sha256),fresh_parent=dict(path=FRESH,sha256=FRESH_SHA),
      authorized_target_count=30,authorized_changed=changed,unexpected=failures,save_count=15,save_exact=not any(x.startswith('SAVE_CHANGED:') for x in failures),saves=save_facts,
      full_old_backup=dict(path=BACKUP,sha256=BACKUP_SHA),full30_backup_sha_bytes_exact=backups_ok,old_backup_writes=0,
      Stage_source_count=len(s['source_first']),Stage_source_allowed_target_changes=source_changed,Stage_source_first_final_was_equal=True,
      current_facts=now,physical_paths_hashed_once=len(cache),engine_calls=0,collector_calls=0,canonical_writes=0,save_writes=0)
    with out.open('xb') as f:f.write((json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode())
    print(json.dumps(dict(path=R+out.name,sha256=sha(out.read_bytes()),passed=not failures,protected=2120,changes=len(changed),save_count=15,Stage_sources=len(s['source_first']),failures=failures)))
    if failures:raise SystemExit(1)
if __name__=='__main__':main()
