"""Fixed25g guard; Root alone runs after exact final deployment. No collector."""
from pathlib import Path
import argparse, datetime, hashlib, json

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
S = 'res://build/luoyang_city_revision_20261025g_source01/'
R = 'res://build/luoyang_city_revision_20261025g_root01/'
FRESH = dict(path=S+'fresh_current25g_READONLY.json', sha256='4b8b0fbf7a7577ea0119cf1a7a9500cf87844f6ca07df4488266bd8c651a4e55')
SCOPE = dict(path=S+'courtyard45_exact32_scope_PREPARATION.json', sha256='823dcc493006e0a439dc4f4caa1ce8a1ad6b029fb9c3e8f847620731defac4d5')
BACKUP = dict(path=S+'predeploy32_backup_receipt.json', sha256='207a8da07bb9991bcb0f017a482d208da46a8759d082c94b899b2a106fc63a21')
ADMISSION = dict(path=R+'mask_import_admission.json', sha256='10fbd028728cc849e1c8b40b0d3c23dcd76f2c8e37480bfb7f341a6bfb5baa54')

def sha(raw): return hashlib.sha256(raw).hexdigest()
def resolve(path):
    if path.startswith('res://'):
        value=(GAME/path[6:]).resolve()
        assert '..' not in path and value.is_relative_to(GAME.resolve())
        return value
    return Path(path).resolve()
def load(pin):
    raw=resolve(pin['path']).read_bytes()
    assert sha(raw)==pin['sha256'].lower(), pin['path']
    return json.loads(raw)
def stat(path):
    if not path.exists(): return dict(exists=False)
    s=path.stat()
    return dict(exists=True,bytes=s.st_size,ticks=str(s.st_mtime_ns//100+621355968000000000))
def fact(path):
    row=stat(path)
    if row['exists']:
        with path.open('rb') as stream: row['sha256']=hashlib.file_digest(stream,'sha256').hexdigest()
    return row
def sig(row): return {k:row.get(k) for k in ['exists','sha256','bytes','ticks']}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--fixture',required=True); ap.add_argument('--fixture-sha',required=True)
    ap.add_argument('--output-key',required=True)
    ap.add_argument('--before-guard'); ap.add_argument('--before-sha')
    a=ap.parse_args()
    assert a.output_key.isascii() and a.output_key.replace('_','').isalnum() and len(a.output_key)<70
    out=HERE/('guard32_'+a.output_key+'_READONLY.json')
    assert not out.exists(), 'PRESERVE_ALL_GUARD_EPOCHS'
    fixturepin=dict(path=a.fixture,sha256=a.fixture_sha.lower()); fixture=load(fixturepin)
    assert fixture['ready'] is True and fixture['formal_deployed'] is True
    assert fixture['fresh']==FRESH and fixture['scope']==SCOPE and fixture['backup32']==BACKUP and fixture['mask_admission']==ADMISSION
    fresh=load(FRESH); scope=load(SCOPE); backup=load(BACKUP); admission=load(ADMISSION)
    assert fresh['current_matches25f_guard'] is True and fresh['capture_stable'] is True
    assert fresh['observed_count']==2121 and fresh['save_count']==15 and fresh['full_backup_count']==116 and fresh['mask_media_count']==6
    baseline={str(resolve(row['path'])):row for row in fresh['current_facts']}; assert len(baseline)==2121
    saves={str(resolve(row['path'])) for row in fresh['current_save_protection_start']}; assert len(saves)==15 and saves<=set(baseline)
    declared={row['target']:dict(row['fixed_expected']) for row in fresh['all33_fixed_target_checks']}
    assert len(declared)==33 and all(row['exact_SHA_bytes'] is True for row in fresh['all33_fixed_target_checks'])
    need={row['target']:row for row in scope['targets']}; assert len(need)==32 and set(need)<=set(declared)
    assert scope['count']==32 and scope['partition']==dict(GD=17,JSON=15) and scope['extra_backup_superset_preserved_if_final_scope_removes_noop'] is True
    stage=load(fixture['stage']); deploy=load(fixture['deployment'])
    assert stage['status']=='MARKET_COURTYARD45_EXACT32_STAGED_NOT_DEPLOYED'
    assert stage['target_partition']==dict(patch_count=17,copy_count=15,total=32)
    assert stage['source_first']==stage['source_final']
    assert deploy['stage_sha256'].lower()==fixture['stage']['sha256'] and deploy['GD_apply_patch']==17 and deploy['JSON_exact_copy']==15
    staged={row['target']:row for row in stage['targets']}; deployed={row['target']:row for row in deploy['targets']}
    assert len(staged)==len(deployed)==32 and set(staged)==set(deployed)==set(need)
    for path,row in staged.items():
        old=declared[path]; required=need[path]
        assert row['old_sha256'].lower()==old['sha256']==required['old_sha256'] and old['bytes']==required['old_bytes']
        candidate_raw=resolve(row['candidate_path']).read_bytes()
        assert sha(candidate_raw)==row['candidate_sha256'].lower() and row['old_sha256'].lower()!=row['candidate_sha256'].lower()
        assert deployed[path]['sha256'].lower()==row['candidate_sha256'].lower() and deployed[path]['bytes']==len(candidate_raw)
        declared[path]=dict(sha256=row['candidate_sha256'].lower(),bytes=len(candidate_raw),immutable_candidate=row['candidate_path'])
    expected={str(resolve(path)):row for path,row in declared.items()}; assert len(expected)==33 and set(expected)<=set(baseline)
    authorized_paths={str(resolve(path)) for path in need}
    prior=None
    if a.before_guard:
        assert a.before_sha
        prior=load(dict(path=a.before_guard,sha256=a.before_sha.lower()))
        assert prior['passed'] is True and prior['fixture']==fixturepin
        previous={str(resolve(row['path'])):row for row in prior['current_facts']}
        assert set(previous)==set(baseline); baseline=previous
    started=datetime.datetime.now(datetime.timezone.utc).isoformat()
    now={path:fact(Path(path)) for path in baseline}; errors=[]; authorized=[]; external=[]
    for path,before in baseline.items():
        current=now[path]
        if path in expected:
            required=expected[path]
            if current.get('sha256')!=required['sha256'] or current.get('bytes')!=required['bytes']:
                errors.append(dict(path=path,reason='FINAL_FIXED33_SHA_BYTES_DIFFERS',expected=required,current=current))
        if sig(current)!=sig(before):
            if prior or path not in authorized_paths:
                row=dict(path=path,reason='EXTERNAL_SAVE_CHANGE_KEEP_LATEST' if path in saves else 'UNAUTHORIZED_OR_POST_GUARD_CHANGE',before=sig(before),current=sig(current))
                errors.append(row); external.append(row)
            else: authorized.append(dict(path=path,before=sig(before),current=sig(current)))
    assert backup['passed'] is True and backup['count']==len(backup['targets'])==32 and backup['scope_sha256'].lower()==SCOPE['sha256'] and backup['fresh']==FRESH
    assert backup['old116_backups_preserved_not_rewritten'] is True and backup['full_backup_total_after']==148 and backup['all_source_save_UI_media_exactticks_unchanged_during_backup'] is True
    backup_expected={str(resolve(row['path'])):row for row in fresh['backups_current']}; assert len(backup_expected)==116
    prefix=resolve(S+'predeploy32_old_backup/'); seen=set()
    for row in backup['targets']:
        path=row['target']; bp=resolve(row['backup']); assert path in need and path not in seen and bp.is_relative_to(prefix)
        assert row['sha256'].lower()==need[path]['old_sha256'] and row['bytes']==need[path]['old_bytes']
        seen.add(path); key=str(bp); assert key not in backup_expected
        backup_expected[key]=dict(exists=True,sha256=row['sha256'].lower(),bytes=row['bytes'],ticks=str(row['backup_ticks']))
    assert len(seen)==32 and len(backup_expected)==148
    media_expected={str(resolve(row['path'])):row for row in fresh['new_media_current']}; assert len(media_expected)==6
    assert admission['scope']=='ONLY_TWO_NEW_ABSENT_MASK_MEDIA_LEAVES' and admission['main_project_imports']==0 and admission['PNG_or_md5_promotion']==0 and admission['reused_asset_reimports']==0
    assert admission['import_process']['actual_natural_exit']==0 and admission['verify']['actual_natural_exit']==0 and admission['verify']['checks']==82 and admission['verify']['failures']==0
    promoted={str(resolve(path)):value.lower() for path,value in admission['promoted'].items()}
    assert len(promoted)==2
    for path,row in backup['new_mask_two_media_after'].items():
        key=str(resolve(path)); assert key not in media_expected and promoted[key]==row['sha256'].lower() and key not in baseline
        media_expected[key]=row
    assert len(media_expected)==8
    backups=[]; media=[]
    for required_rows,output,kind in [(backup_expected,backups,'FULL_BACKUP_CHANGED'),(media_expected,media,'ADMITTED_MEDIA_CHANGED')]:
        for path,before in required_rows.items():
            current=dict(path=path,**fact(Path(path))); output.append(current)
            if sig(current)!=sig(before): errors.append(dict(path=path,reason=kind,before=sig(before),current=sig(current)))
    if prior:
        for key,rows in [('backups_current',backups),('new_media_current',media)]:
            before={str(resolve(row['path'])):row for row in prior[key]}
            assert set(before)=={row['path'] for row in rows}
            for row in rows:
                if sig(row)!=sig(before[row['path']]): errors.append(dict(path=row['path'],reason='CHANGED_SINCE_PRE_FIELD_GUARD'))
    unstable=[path for path,row in now.items() if stat(Path(path))!={k:row[k] for k in ['exists','bytes','ticks'] if k in row}]
    for path in unstable: errors.append(dict(path=path,reason='CHANGED_DURING_CAPTURE'))
    result=dict(status='ROOT25G_EXACT32_FIXED_PROTECTION_READONLY_GUARD',passed=not errors,fixture=fixturepin,started_utc=started,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),mode='after_Field_exact_previous_guard' if prior else 'post_deploy_from_fresh_4B8B',observed_count=2121,protected_count=2120,extra_UI_count=1,save_count=15,authorized_target_count=32,fixed_current_target_count=33,full_backup_count=148,all_admitted_media_count=8,two_new_media_outside_original2121=True,save_first_final_exact_ticks=not any(row.get('path') in saves for row in errors),current_facts=[dict(path=path,**row) for path,row in now.items()],saves=[dict(path=path,**now[path]) for path in sorted(saves)],backups_current=backups,new_media_current=media,authorized_changes=authorized,external_changes=external,errors=errors,source_capture_stable=not unstable,collector_calls=0,engine_calls=0,canonical_writes=0,save_writes=0,processes_stopped=0)
    raw=(json.dumps(result,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    with out.open('xb') as stream: stream.write(raw)
    print(json.dumps(dict(path='res://build/luoyang_city_revision_20261025g_qa01/'+out.name,sha256=sha(raw),passed=result['passed'],errors=len(errors),authorized=len(authorized),observed=2121,saves=15,backups=148,media=8,fixed_targets=33)))

if __name__=='__main__': main()
