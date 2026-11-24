"""Root-only fixed protection guard, no source collector/engine/canonical writes."""
from pathlib import Path
import argparse,json,hashlib,datetime
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261024e_root01/'
STAGE=S+'outputs/root_market_blocks_prewarm_exact33_stage03/receipt.json';STAGE_SHA='ea657a57c4a884cd3f645b6de7f8fb2010c8920b737b2ab6b9f3c998288c2abc'
DEPLOY=R+'deployment33_actual.json';DEPLOY_SHA='d5aa84d441ff733332d77cc702631c776bf4863b3b9aa6f601f4fdb46e83f087'
WALL=R+'wall_tuple3_deployed_actual.json';WALL_SHA='3550aa2efa1eedc4ba97a353bb085d992ce8507a306d01923199962312d08d78'
HEADER=R+'finite_AP_header2_deployed_actual.json';HEADER_SHA='d596ef3c7cd7177fc302f25aac3cdba6b7ad2772e1ec0122aaed2afa8549e799'
PREWARM_STAGE=S+'outputs/root_prewarm8_profile04_exact29_stage02/receipt.json';PREWARM_STAGE_SHA='3a67564ee7ef2bb8cc70e2d0b28688eabb54c4a2be53e26cc509f70bfa410e98'
PREWARM_DEPLOY=R+'prewarm_profile29_deployed_actual.json';PREWARM_DEPLOY_SHA='fe1549455424f80f4cdd6325402b6816aad861388b2a2e49b16a9c8c91c6b0bb'
def sha(b):return hashlib.sha256(b).hexdigest()
def resolve(p):
    if p.startswith('res://'):
        assert '..' not in p;x=(GAME/p[6:]).resolve();assert x.is_relative_to(GAME.resolve());return x
    return Path(p).resolve()
def load(p,h):
    raw=resolve(p).read_bytes();assert sha(raw)==h.lower(),(p,sha(raw));return json.loads(raw)
def stat(p):
    if not p.exists():return dict(exists=False)
    s=p.stat();return dict(exists=True,bytes=s.st_size,ticks=str(s.st_mtime_ns//100+621355968000000000))
def fact(p):
    d=stat(p)
    if d['exists']:
        with p.open('rb') as stream:d['sha256']=hashlib.file_digest(stream,'sha256').hexdigest()
    return d
def signature(r):return {k:r.get(k) for k in ['exists','sha256','bytes','ticks']}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output-key',required=True);ap.add_argument('--before-guard');ap.add_argument('--before-sha');a=ap.parse_args()
    assert a.output_key.isascii() and a.output_key.replace('_','').isalnum() and len(a.output_key)<70
    out=HERE/('guard_prewarm29_'+a.output_key+'_READONLY.json');assert not out.exists(),'PRESERVE_ALL_GUARD_EPOCHS'
    source=load(S+'fresh_24e_current_observation_READONLY.json','63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85');stage=load(STAGE,STAGE_SHA);dep=load(DEPLOY,DEPLOY_SHA)
    assert len(stage['targets'])==33 and stage['target_partition']==dict(patch_count=18,copy_count=15,total=33) and stage['source_first']==stage['source_final']
    assert dep['status']=='EXACT33_DEPLOYED_FOR_RUNTIME_TRIAL_NOT_FINAL_ADMISSION' and len(dep['targets'])==33 and dep['stage_sha256'].lower()==STAGE_SHA
    parents={r['path']:r for r in source['facts']};assert len(parents)==2120
    ui=source['UI_extra'];uip=str(resolve(ui['path']));assert uip not in parents;parents[uip]=dict(path=uip,**ui['current']);assert len(parents)==2121
    mode='pre_Field_from_fixed_current24e_start';prior_guard=None
    if a.before_guard:
        assert a.before_sha;prior_guard=load(a.before_guard,a.before_sha);assert prior_guard['passed'] is True and prior_guard['stage']['sha256']==STAGE_SHA and prior_guard['wall_tuple_deployment']['sha256']==WALL_SHA and prior_guard['finite_AP_header_deployment']['sha256']==HEADER_SHA and prior_guard['prewarm_profile_stage']['sha256']==PREWARM_STAGE_SHA and prior_guard['prewarm_profile_deployment']['sha256']==PREWARM_DEPLOY_SHA
        before={r['path']:r for r in prior_guard['current_facts']};assert set(before)==set(parents);parents=before;mode='after_Field_exact_previous_guard'
    saves={r['path'] for r in source['current_save_protection_start']};assert len(saves)==15 and saves<=set(parents)
    targetrows={str(resolve(r['target'])):dict(r) for r in stage['targets']};assert len(targetrows)==33 and set(targetrows)<=set(parents)
    wall=load(WALL,WALL_SHA)
    scope=load(S+'wall_tuple3_candidate01/scope_exact3_NOT_STAGE.json','169977910700189d46a6b0146368357bc2b0416e64daaf8f5dee10e1fb2281b4')
    assert wall['status']=='ROOT_APPROVED_EXACT3_EXISTING_MEDIA_TUPLE_METADATA_DEPLOYED_NOT_FINAL_RUNTIME_ADMISSION'
    assert wall['targets']==scope['targets'] and len(wall['targets'])==3 and wall['new_imports']==wall['new_geometry']==0
    assert wall['scope_sha256']=='169977910700189d46a6b0146368357bc2b0416e64daaf8f5dee10e1fb2281b4'
    for r in wall['targets']:
        p=str(resolve(r['target']));row=targetrows[p]
        assert row['candidate_sha256']==r['old_sha256'] and resolve(row['candidate_path']).stat().st_size==r['old_bytes']
        row['prior_stage_candidate_sha256']=row['candidate_sha256']
        row['candidate_path']=r['candidate']['path'];row['candidate_sha256']=r['candidate']['sha256']
        assert sha(resolve(row['candidate_path']).read_bytes())==row['candidate_sha256'] and resolve(row['candidate_path']).stat().st_size==r['candidate']['bytes']
    header=load(HEADER,HEADER_SHA)
    scope2=load(S+'finite_AP_header2_candidate02/scope_exact2_NOT_DEPLOYED.json','6cbcfebc9501d259f4f224dc416c6db6279d85e23c9cf5506a04e530a73d7efe')
    assert header['status']=='ROOT_APPROVED_EXACT2_EXISTING_AP_HEADER_EDGE_DEPLOYED_NOT_FINAL_RUNTIME_ADMISSION'
    assert header['targets']==scope2['targets'] and len(header['targets'])==2 and header['new_imports']==header['new_geometry']==0 and header['classification_unchanged'] is True
    assert header['scope_sha256']=='6cbcfebc9501d259f4f224dc416c6db6279d85e23c9cf5506a04e530a73d7efe'
    for r in header['targets']:
        row=targetrows[str(resolve(r['target']))]
        assert row['candidate_sha256']==r['old_sha256'] and resolve(row['candidate_path']).stat().st_size==r['old_bytes']
        row['prior_tuple3_candidate_sha256']=row['candidate_sha256']
        row['candidate_path']=r['candidate']['path'];row['candidate_sha256']=r['candidate']['sha256']
        assert sha(resolve(row['candidate_path']).read_bytes())==row['candidate_sha256'] and resolve(row['candidate_path']).stat().st_size==r['candidate']['bytes']
    prewarm=load(PREWARM_STAGE,PREWARM_STAGE_SHA);prewarm_deployment=load(PREWARM_DEPLOY,PREWARM_DEPLOY_SHA)
    prewarm_scope=load(S+'prewarm_profile29_scope_PREPARATION.json','cd4e04275838a9652617ea62204a2e2fa34c124d422a87a05bb2f97dedb1beca')
    need29={r['target']:r for r in prewarm_scope['targets']}
    assert prewarm['status']=='PREWARM8_PROFILE04_EXACT29_STAGED_NOT_DEPLOYED' and prewarm['target_partition']==dict(patch_count=15,copy_count=14,total=29) and prewarm['source_first']==prewarm['source_final']
    assert prewarm_deployment['status']=='EXACT29_PREWARM8_PROFILE04_DEPLOYED_FOR_MEASURED_TRIAL' and prewarm_deployment['stage_sha256']==PREWARM_STAGE_SHA and prewarm_deployment['GD_apply_patch']==15 and prewarm_deployment['JSON_exact_copy']==14
    deployed29={r['target']:r for r in prewarm_deployment['targets']}
    assert len(need29)==len(deployed29)==len(prewarm['targets'])==29 and set(deployed29)==set(need29)
    for r in prewarm['targets']:
        p=str(resolve(r['target']));row=targetrows[p];scope_row=need29[r['target']]
        assert row['candidate_sha256']==r['old_sha256']==scope_row['old_sha256'] and resolve(row['candidate_path']).stat().st_size==scope_row['old_bytes']
        assert deployed29[r['target']]['sha256']==r['candidate_sha256'] and deployed29[r['target']]['bytes']==resolve(r['candidate_path']).stat().st_size
        row['prior_header2_candidate_sha256']=row['candidate_sha256']
        row['candidate_path']=r['candidate_path'];row['candidate_sha256']=r['candidate_sha256']
        assert sha(resolve(row['candidate_path']).read_bytes())==row['candidate_sha256']
    assert len(targetrows)==33
    started=datetime.datetime.now(datetime.timezone.utc).isoformat();current={p:fact(Path(p)) for p in parents};errors=[];authorized=[];external=[]
    for p,old in parents.items():
        now=current[p]
        if p in targetrows:
            row=targetrows[p];candidate=resolve(row['candidate_path']);expected_size=candidate.stat().st_size
            if now.get('sha256')!=row['candidate_sha256'] or now.get('bytes')!=expected_size:errors.append(dict(path=p,reason='DEPLOYED_TARGET_CANDIDATE_SHA_OR_BYTES_DIFFERS',current=now,expected_sha256=row['candidate_sha256'],expected_bytes=expected_size))
            if signature(now)!=signature(old):
                if prior_guard:errors.append(dict(path=p,reason='TARGET_CHANGED_AFTER_PRE_FIELD',before=signature(old),current=now))
                else:authorized.append(dict(path=p,target=row['target'],old_sha256=row['old_sha256'],candidate_sha256=row['candidate_sha256'],current=now))
        elif signature(now)!=signature(old):
            r=dict(path=p,kind='external_save_change' if p in saves else 'unexpected_other_change',before=signature(old),current=now);external.append(r);errors.append(r)
    unstable=[p for p in current if stat(Path(p))!={k:current[p][k] for k in ['exists','bytes','ticks'] if k in current[p]}]
    for p in unstable:errors.append(dict(path=p,reason='CHANGED_DURING_CAPTURE'))
    backup=load(R+'predeploy33_backup_receipt.json','d09fc312a82a3e90eb4ba681b3b666c757502e42a57dc517377e48d6bed99f6f');assert backup['count']==len(backup['targets'])==33
    backups=[];prefix=resolve(R+'predeploy33_backup/')
    for r in backup['targets']:
        p=resolve(r['target']);bp=Path(r['backup']).resolve();assert bp.is_relative_to(prefix) and str(p) in targetrows and targetrows[str(p)]['old_sha256']==r['sha256'].lower()
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],**row))
        if row.get('sha256')!=r['sha256'].lower() or row.get('bytes')!=r['bytes']:errors.append(dict(path=str(bp),reason='FULL_OLD_BACKUP_CHANGED',current=row))
    wallprefix=resolve(wall['backups']);assert wall['backups']==R+'wall_tuple3_predeploy_backup/'
    for r in wall['targets']:
        bp=(wallprefix/r['target'][6:]).resolve();assert bp.is_relative_to(wallprefix)
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],backup_generation='wall_tuple3_parent_deployed33',**row))
        if row.get('sha256')!=r['old_sha256'] or row.get('bytes')!=r['old_bytes']:errors.append(dict(path=str(bp),reason='WALL_TUPLE3_FULL_PARENT_BACKUP_CHANGED',current=row))
    assert len(backups)==36
    headerprefix=resolve(header['backups']);assert header['backups']==R+'finite_AP_header2_predeploy_backup/'
    for r in header['targets']:
        bp=(headerprefix/r['target'][6:]).resolve();assert bp.is_relative_to(headerprefix)
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],backup_generation='finite_AP_header2_parent_tuple3',**row))
        if row.get('sha256')!=r['old_sha256'] or row.get('bytes')!=r['old_bytes']:errors.append(dict(path=str(bp),reason='FINITE_AP_HEADER2_FULL_PARENT_BACKUP_CHANGED',current=row))
    assert len(backups)==38
    prewarm_backup=load(R+'prewarm_profile29_backup_receipt.json','a235b1d4fb261b1f61329312b3b051ee7409355c779820c558f9958cbef7f56e')
    assert prewarm_backup['status']=='EXACT29_CURRENT_D596_PARENT_BACKED_UP_NO_CANONICAL_WRITES' and prewarm_backup['count']==len(prewarm_backup['targets'])==29 and prewarm_backup['scope_sha256']=='cd4e04275838a9652617ea62204a2e2fa34c124d422a87a05bb2f97dedb1beca'
    newprefix=resolve(R+'prewarm_profile29_predeploy_backup/');seen29=set()
    for r in prewarm_backup['targets']:
        bp=Path(r['backup']).resolve();assert bp.is_relative_to(newprefix) and r['target'] in need29 and r['target'] not in seen29
        assert r['sha256']==need29[r['target']]['old_sha256'] and r['bytes']==need29[r['target']]['old_bytes'];seen29.add(r['target'])
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],backup_generation='prewarm_profile29_parent_D596',**row))
        if row.get('sha256')!=r['sha256'] or row.get('bytes')!=r['bytes']:errors.append(dict(path=str(bp),reason='PREWARM_PROFILE29_FULL_OLD_BACKUP_CHANGED',current=row))
    assert len(seen29)==29 and len(backups)==67
    if prior_guard:
        oldb={r['path']:signature(r) for r in prior_guard['backups_current']}
        for r in backups:
            if oldb.get(r['path'])!=signature(r):errors.append(dict(path=r['path'],reason='BACKUP_CHANGED_SINCE_PRE_FIELD'))
    media={
      'res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/walk_overlay.png':'051ac64ff157f1cc7ae4ab2abb4b03f650d8da74bd15bf5ff528164d5bfdc9d4',
      'res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/walk_overlay.png.import':'ea3c3d1e7315ce4531ac2fa1a78bdb2c3d5c2b59daa7376e00bd7f449433227d',
      'res://.godot/imported/walk_overlay.png-1cfdb6323348c5898501d8f62989d39b.ctex':'2da462ca9dc2a6750e67cee14c2e393be7b285437fb5a501333307080abaeaeb'}
    mediafacts=[]
    for p,h in media.items():
        r=dict(path=p,**fact(resolve(p)));mediafacts.append(r)
        if r.get('sha256')!=h:errors.append(dict(path=p,reason='FIXED_ADMITTED_NEW_MEDIA_DIFFERS',current=r,expected_sha256=h))
    if prior_guard:
        oldm={r['path']:signature(r) for r in prior_guard['new_media_current']}
        for r in mediafacts:
            if oldm.get(r['path'])!=signature(r):errors.append(dict(path=r['path'],reason='NEW_MEDIA_CHANGED_SINCE_PRE_FIELD'))
    result=dict(status='ROOT_FINAL33_WITH_PREWARM_PROFILE29_FIXED_PROTECTION_READONLY_GUARD',passed=not errors,mode=mode,started_utc=started,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),stage=dict(path=STAGE,sha256=STAGE_SHA),deployment=dict(path=DEPLOY,sha256=DEPLOY_SHA),wall_tuple_deployment=dict(path=WALL,sha256=WALL_SHA),finite_AP_header_deployment=dict(path=HEADER,sha256=HEADER_SHA),prewarm_profile_stage=dict(path=PREWARM_STAGE,sha256=PREWARM_STAGE_SHA),prewarm_profile_deployment=dict(path=PREWARM_DEPLOY,sha256=PREWARM_DEPLOY_SHA),full_backup_count=67,protected_count=2120,extra_UI_count=1,observed_count=2121,save_count=15,save_first_final_exact_ticks=not any(r.get('path') in saves for r in errors),authorized_target_count=33,authorized_changes=authorized,external_changes=external,errors=errors,current_facts=[dict(path=p,**d) for p,d in current.items()],saves=[dict(path=p,**current[p]) for p in sorted(saves)],backups_current=backups,new_media_current=mediafacts,source_capture_stable=not unstable,current_start_external24c_save_changes_preserved=source['save_changes_since_24c'],note='Fixed2120 original protection list plus one separately protected UI =2121 observed; no unapproved extra list invented. No rollback; external differences are reported and retained.',previous_guard=dict(path=a.before_guard,sha256=a.before_sha) if a.before_guard else None,collector_calls=0,engine_calls=0,PNG_or_native_decodes=0,canonical_writes=0,save_writes=0,processes_stopped=0)
    raw=(json.dumps(result,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    with out.open('xb') as stream:stream.write(raw)
    print(json.dumps(dict(path=S+out.name,sha256=sha(raw),passed=result['passed'],errors=len(errors),protected=2120,UI=1,observed=2121,saves=15,targets=33,authorized_changes=len(authorized),external=len(external))))
if __name__=='__main__':main()
