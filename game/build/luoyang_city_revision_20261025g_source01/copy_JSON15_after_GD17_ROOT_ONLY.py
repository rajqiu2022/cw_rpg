"""Root-only exact mechanical JSON copy after Root's17-GD apply_patch. Never runs engine."""
from pathlib import Path
import argparse,hashlib,json,datetime
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025g_source01/'
R='res://build/luoyang_city_revision_20261025g_root01/'
STAGE=dict(path=S+'outputs/root_market_courtyard45_exact32_stage02/receipt.json',sha256='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396')
BACKUP=dict(path=S+'predeploy32_backup_receipt.json',sha256='207a8da07bb9991bcb0f017a482d208da46a8759d082c94b899b2a106fc63a21')
FRESH=dict(path=S+'fresh_current25g_READONLY.json',sha256='4b8b0fbf7a7577ea0119cf1a7a9500cf87844f6ca07df4488266bd8c651a4e55')
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return (GAME/p[6:]).resolve() if p.startswith('res://') else Path(p).resolve()
def read(pin):
    raw=res(pin['path']).read_bytes();assert sha(raw)==pin['sha256'],pin['path'];return raw
def load(pin):return json.loads(read(pin))
def facts(p):
    path=res(p)
    if not path.exists():return dict(exists=False)
    before=path.stat()
    with path.open('rb') as stream:h=hashlib.file_digest(stream,'sha256').hexdigest()
    after=path.stat();assert before.st_size==after.st_size and before.st_mtime_ns==after.st_mtime_ns,('SOURCE_CHANGED_DURING_READ',p)
    return dict(exists=True,sha256=h,bytes=after.st_size,ticks=str(after.st_mtime_ns//100+621355968000000000))
def sig(row):return {k:row[k] for k in ['exists','sha256','bytes','ticks'] if k in row}
def write_new(path,value):
    raw=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    with path.open('xb') as out:out.write(raw)
    return sha(raw)
def run(apply):
    started=datetime.datetime.now(datetime.timezone.utc).isoformat();stage=load(STAGE);backup=load(BACKUP);fresh=load(FRESH)
    assert stage['status']=='MARKET_COURTYARD45_EXACT32_STAGED_NOT_DEPLOYED'
    assert stage['source_first']==stage['source_final']
    assert stage['target_partition']==dict(patch_count=17,copy_count=15,total=32)
    assert backup['passed'] is True and backup['count']==32
    copy_plan=load(stage['byte_copy_plan']);assert stage['byte_copy_plan']['target_count']==len(copy_plan['rows'])==15
    assert copy_plan['patch_copy_disjoint'] and copy_plan['union_exact_targets'] and copy_plan['no_GD_copy_or_native_write']
    targets={r['target']:r for r in stage['targets']};backups={r['target']:r for r in backup['targets']}
    assert len(targets)==32 and set(targets)==set(backups)
    gd=[p for p in targets if p.endswith('.gd')];js=[p for p in targets if p.endswith('.json')]
    assert len(gd)==17 and len(js)==15 and {r['target'] for r in copy_plan['rows']}==set(js)
    candidate={};before={};backup_facts={}
    for p,row in targets.items():
        assert row['old_sha256']==backups[p]['sha256'] and row['old_sha256']!=row['candidate_sha256']
        raw=read(dict(path=row['candidate_path'],sha256=row['candidate_sha256']));candidate[p]=raw;before[p]=facts(p)
        if p in gd:assert before[p]['sha256']==row['candidate_sha256'] and before[p]['bytes']==len(raw),('ROOT_MUST_APPLY_EXACT_GD17_FIRST',p)
        else:
            assert before[p]['sha256']==row['old_sha256'] and before[p]['bytes']==backups[p]['bytes'],('JSON_MUST_STILL_BE_FIXED_OLD',p)
            json.loads(raw)
            copies=[r for r in copy_plan['rows'] if r['target']==p];assert len(copies)==1 and copies[0]['candidate_bytes']==len(raw)
            assert copies[0]['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'
            node=copies[0]['inverse_proof'];assert stage['proofs'][node]['whole_typed_inverse'] is True
        bp=backups[p]['backup'];b=facts(bp);assert b['sha256']==backups[p]['sha256'] and b['bytes']==backups[p]['bytes'] and b['ticks']==backups[p]['backup_ticks'],('OLD_BACKUP_NOT_EXACT',p);backup_facts[bp]=b
    unchanged33={p:row for p,row in backup['current33_before'].items() if p not in targets}
    assert len(unchanged33)==1 and list(unchanged33)[0]=='res://scripts/autoload/scene_router.gd'
    protected={**unchanged33,**backup['UI_after'],**backup['saves15_after']}
    assert len(backup['saves15_after'])==15 and len(backup['UI_after'])==1
    media={r['path']:sig(r) for r in fresh['new_media_current']};media.update(backup['new_mask_two_media_after']);assert len(media)==8
    for p,row in {**protected,**media}.items():assert facts(p)==sig(row),('CURRENT_PROTECTION_OR_MEDIA_DRIFT_PRESERVE_NOT_OVERWRITE',p)
    dest=res(R+('courtyard45_32_deployed_actual.json' if apply else 'courtyard45_copy15_preflight_actual.json'))
    assert not dest.exists(),'NEW_RECEIPT_ONLY'
    changed=[]
    if apply:
        for p in js:
            assert facts(p)==before[p],('JSON_CHANGED_SINCE_PREFLIGHT',p)
            # Pure transport of already fully checked candidate bytes; no source/model construction.
            with res(p).open('wb') as out:out.write(candidate[p])
            after=facts(p);assert after['sha256']==targets[p]['candidate_sha256'] and after['bytes']==len(candidate[p])
            changed.append(p)
    current={p:facts(p) for p in targets}
    for p in targets:
        expected=targets[p]['candidate_sha256'] if apply or p in gd else targets[p]['old_sha256']
        assert current[p]['sha256']==expected
    for p,row in {**protected,**media,**backup_facts}.items():assert facts(p)==sig(row),('PROTECTED_CHANGED_DURING_COPY',p)
    report=dict(status='ROOT_EXACT32_DEPLOYED_GD17_PATCH_JSON15_EXACTCOPY' if apply else 'ROOT_GD17_NEW_JSON15_OLD_PREFLIGHT_ONLY',passed=True,stage=STAGE,stage_sha256=STAGE['sha256'],backup=BACKUP,full_backup_count=148,backup_scope32_preserved=True,older116_preserved_not_rewritten=True,target_count=32,target_partition=stage['target_partition'],targets=[dict(target=p,sha256=current[p]['sha256'],bytes=current[p]['bytes'],ticks=current[p]['ticks'],old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'],backup=backups[p]['backup']) for p in targets],JSON15_written=changed,GD_writes=0,copy_plan=stage['byte_copy_plan'],preflight_target_facts=before,unchanged33_Router_UI_save15_exactticks=True,media8_exactticks=True,new_source_still_needs_finite_Field_acceptance=True,started_utc=started,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),engine_calls=0,collector_calls=0,no_automatic_rollback=True)
    digest=write_new(dest,report);print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=digest,passed=True,mode='apply' if apply else 'preflight',JSON_written=len(changed),target_count=32)))
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root-authorized-apply',action='store_true');args=parser.parse_args();run(args.root_authorized_apply)
