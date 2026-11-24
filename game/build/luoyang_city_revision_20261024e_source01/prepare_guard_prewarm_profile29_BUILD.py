"""Add only the fixed actual29 deployment and29 full backups to prior guard."""
from pathlib import Path
import json,hashlib,ast,difflib
HERE=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
parent=HERE/'guard_deployed33_tuple3_header2_READONLY.py';old=parent.read_bytes();assert sha(old)=='ba0867d570b01c78136cf4902a7253de2d6da0c4019422f2067f6b13e0be6e91'
text=old.decode()
def rep(a,b):
    global text
    assert text.count(a)==1,a;text=text.replace(a,b)
rep("HEADER=R+'finite_AP_header2_deployed_actual.json';HEADER_SHA='d596ef3c7cd7177fc302f25aac3cdba6b7ad2772e1ec0122aaed2afa8549e799'", "HEADER=R+'finite_AP_header2_deployed_actual.json';HEADER_SHA='d596ef3c7cd7177fc302f25aac3cdba6b7ad2772e1ec0122aaed2afa8549e799'\nPREWARM_STAGE=S+'outputs/root_prewarm8_profile04_exact29_stage02/receipt.json';PREWARM_STAGE_SHA='3a67564ee7ef2bb8cc70e2d0b28688eabb54c4a2be53e26cc509f70bfa410e98'\nPREWARM_DEPLOY=R+'prewarm_profile29_deployed_actual.json';PREWARM_DEPLOY_SHA='fe1549455424f80f4cdd6325402b6816aad861388b2a2e49b16a9c8c91c6b0bb'")
rep("out=HERE/('guard_header2_'+a.output_key+'_READONLY.json')", "out=HERE/('guard_prewarm29_'+a.output_key+'_READONLY.json')")
rep("and prior_guard['finite_AP_header_deployment']['sha256']==HEADER_SHA", "and prior_guard['finite_AP_header_deployment']['sha256']==HEADER_SHA and prior_guard['prewarm_profile_stage']['sha256']==PREWARM_STAGE_SHA and prior_guard['prewarm_profile_deployment']['sha256']==PREWARM_DEPLOY_SHA")
rep("    started=datetime.datetime.now(datetime.timezone.utc).isoformat();current={p:fact(Path(p)) for p in parents};errors=[];authorized=[];external=[]", """    prewarm=load(PREWARM_STAGE,PREWARM_STAGE_SHA);prewarm_deployment=load(PREWARM_DEPLOY,PREWARM_DEPLOY_SHA)
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
    started=datetime.datetime.now(datetime.timezone.utc).isoformat();current={p:fact(Path(p)) for p in parents};errors=[];authorized=[];external=[]""")
rep("    assert len(backups)==38", """    assert len(backups)==38
    prewarm_backup=load(R+'prewarm_profile29_backup_receipt.json','a235b1d4fb261b1f61329312b3b051ee7409355c779820c558f9958cbef7f56e')
    assert prewarm_backup['status']=='EXACT29_CURRENT_D596_PARENT_BACKED_UP_NO_CANONICAL_WRITES' and prewarm_backup['count']==len(prewarm_backup['targets'])==29 and prewarm_backup['scope_sha256']=='cd4e04275838a9652617ea62204a2e2fa34c124d422a87a05bb2f97dedb1beca'
    newprefix=resolve(R+'prewarm_profile29_predeploy_backup/');seen29=set()
    for r in prewarm_backup['targets']:
        bp=Path(r['backup']).resolve();assert bp.is_relative_to(newprefix) and r['target'] in need29 and r['target'] not in seen29
        assert r['sha256']==need29[r['target']]['old_sha256'] and r['bytes']==need29[r['target']]['old_bytes'];seen29.add(r['target'])
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],backup_generation='prewarm_profile29_parent_D596',**row))
        if row.get('sha256')!=r['sha256'] or row.get('bytes')!=r['bytes']:errors.append(dict(path=str(bp),reason='PREWARM_PROFILE29_FULL_OLD_BACKUP_CHANGED',current=row))
    assert len(seen29)==29 and len(backups)==67""")
rep("status='ROOT_EXACT33_PLUS_TUPLE3_HEADER2_FIXED_PROTECTION_READONLY_GUARD'", "status='ROOT_FINAL33_WITH_PREWARM_PROFILE29_FIXED_PROTECTION_READONLY_GUARD'")
rep("finite_AP_header_deployment=dict(path=HEADER,sha256=HEADER_SHA),full_backup_count=38", "finite_AP_header_deployment=dict(path=HEADER,sha256=HEADER_SHA),prewarm_profile_stage=dict(path=PREWARM_STAGE,sha256=PREWARM_STAGE_SHA),prewarm_profile_deployment=dict(path=PREWARM_DEPLOY,sha256=PREWARM_DEPLOY_SHA),full_backup_count=67")
raw=text.encode();ast.parse(text);aa=old.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);ds=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':ds.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,b=old,raw
for d in reversed(ds):
    i=d['old_offset'];a,c=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+c+f[i+len(a):]
    i=d['new_offset'];assert b[i:i+len(c)]==c;b=b[:i]+a+b[i+len(c):]
assert f==raw and b==old
dest=HERE/'guard_deployed33_prewarm_profile29_READONLY.py'
with dest.open('xb') as stream:stream.write(raw)
proof=dict(status='FINAL_GUARD_EXACT29_OVERLAY_AND67_BACKUPS_NOT_EXECUTED',parent_sha256=sha(old),candidate=dict(path=str(dest),sha256=sha(raw)),driver_byte_hunks=ds,whole_byte_forward_inverse=True,Python_AST_parse=True,protected_count=2120,UI_extra=1,observed=2121,save15_exact_ticks_unchanged=True,latest29_targets_within_original33=True,total_full_backups=67,guard_executions=0,collector_calls=0,engine_calls=0,canonical_writes=0)
pr=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();pp=HERE/'guard_prewarm_profile29_whole_inverse_NOT_EXECUTED.json'
with pp.open('xb') as stream:stream.write(pr)
print(json.dumps(dict(guard=proof['candidate'],proof=dict(path=str(pp),sha256=sha(pr)),guard_executions=0)))
