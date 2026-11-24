"""Only extend the existing fixed guard with actual31, 31 old backups, Docks mask3."""
from pathlib import Path
import json,hashlib,ast,difflib
HERE=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
parent=HERE/'guard_deployed33_prewarm_profile29_READONLY.py';old=parent.read_bytes();assert sha(old)=='184322d36ea3537fd9bd50188eedb3d43fac4a1ca7e03b516a257d8a19cf9d78';text=old.decode()
def rep(a,b):
    global text
    assert text.count(a)==1,a;text=text.replace(a,b)
rep("PREWARM_DEPLOY=R+'prewarm_profile29_deployed_actual.json';PREWARM_DEPLOY_SHA='fe1549455424f80f4cdd6325402b6816aad861388b2a2e49b16a9c8c91c6b0bb'", "PREWARM_DEPLOY=R+'prewarm_profile29_deployed_actual.json';PREWARM_DEPLOY_SHA='fe1549455424f80f4cdd6325402b6816aad861388b2a2e49b16a9c8c91c6b0bb'\nDOCKS_STAGE=S+'outputs/root_docks_frontages_exact31_stage03/receipt.json';DOCKS_STAGE_SHA='8ea2ed3e987510ace0ef772e4f683468b714e77c6648f7c086e234520f9bd826'\nDOCKS_DEPLOY=R+'docks31_deployed_actual.json';DOCKS_DEPLOY_SHA='ee47ad85fadce157fb805a039f734b8fcd1d4eb05d54a6d197ab539a93c20f89'")
rep("out=HERE/('guard_prewarm29_'+a.output_key+'_READONLY.json')","out=HERE/('guard_docks31_'+a.output_key+'_READONLY.json')")
rep("and prior_guard['prewarm_profile_deployment']['sha256']==PREWARM_DEPLOY_SHA", "and prior_guard['prewarm_profile_deployment']['sha256']==PREWARM_DEPLOY_SHA and prior_guard['docks_stage']['sha256']==DOCKS_STAGE_SHA and prior_guard['docks_deployment']['sha256']==DOCKS_DEPLOY_SHA")
rep("    started=datetime.datetime.now(datetime.timezone.utc).isoformat();current={p:fact(Path(p)) for p in parents};errors=[];authorized=[];external=[]", """    docks=load(DOCKS_STAGE,DOCKS_STAGE_SHA);docks_deployment=load(DOCKS_DEPLOY,DOCKS_DEPLOY_SHA)
    docks_scope=load(S+'docks31_scope_PREPARATION.json','b641239df4f2f3828d37bf3372051d8f1b7b4971ab14c81a3a8dda28be43a092')
    need31={r['target']:r for r in docks_scope['targets']}
    assert docks['status']=='DOCKS_FRONTAGES_EXACT31_STAGED_NOT_DEPLOYED' and docks['target_partition']==dict(patch_count=16,copy_count=15,total=31) and docks['source_first']==docks['source_final']
    assert docks_deployment['status']=='EXACT31_DOCKS_FRONTAGES_DEPLOYED_FOR_LIMITED_RUNTIME_TRIAL' and docks_deployment['stage_sha256'].lower()==DOCKS_STAGE_SHA and docks_deployment['GD_apply_patch']==16 and docks_deployment['JSON_exact_copy']==15
    deployed31={r['target']:r for r in docks_deployment['targets']}
    assert len(need31)==len(deployed31)==len(docks['targets'])==31 and set(deployed31)==set(need31)
    for r in docks['targets']:
        p=str(resolve(r['target']));row=targetrows[p];scope_row=need31[r['target']]
        assert row['candidate_sha256']==r['old_sha256']==scope_row['old_sha256'] and resolve(row['candidate_path']).stat().st_size==scope_row['old_bytes']
        assert deployed31[r['target']]['sha256']==r['candidate_sha256'] and deployed31[r['target']]['bytes']==resolve(r['candidate_path']).stat().st_size
        row['prior_FE154_candidate_sha256']=row['candidate_sha256'];row['candidate_path']=r['candidate_path'];row['candidate_sha256']=r['candidate_sha256']
        assert sha(resolve(row['candidate_path']).read_bytes())==row['candidate_sha256']
    assert len(targetrows)==33
    started=datetime.datetime.now(datetime.timezone.utc).isoformat();current={p:fact(Path(p)) for p in parents};errors=[];authorized=[];external=[]""")
rep("    if prior_guard:\n        oldb={r['path']:signature(r) for r in prior_guard['backups_current']}", """    docks_backup=load(R+'docks31_backup_receipt.json','745e2338d43d888ce6cb83b3a5fdb28ed152776785cbd2df016a700f0d8e7632')
    assert docks_backup['status']=='EXACT31_CURRENT_FE154_PARENT_BACKED_UP_NO_CANONICAL_WRITES' and docks_backup['count']==len(docks_backup['targets'])==31 and docks_backup['scope_sha256']=='b641239df4f2f3828d37bf3372051d8f1b7b4971ab14c81a3a8dda28be43a092'
    docksprefix=resolve(R+'docks31_predeploy_backup/');seen31=set()
    for r in docks_backup['targets']:
        bp=Path(r['backup']).resolve();assert bp.is_relative_to(docksprefix) and r['target'] in need31 and r['target'] not in seen31
        assert r['sha256']==need31[r['target']]['old_sha256'] and r['bytes']==need31[r['target']]['old_bytes'];seen31.add(r['target'])
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],backup_generation='docks31_parent_FE154',**row))
        if row.get('sha256')!=r['sha256'] or row.get('bytes')!=r['bytes']:errors.append(dict(path=str(bp),reason='DOCKS31_FULL_OLD_BACKUP_CHANGED',current=row))
    assert len(seen31)==31 and len(backups)==98
    if prior_guard:
        oldb={r['path']:signature(r) for r in prior_guard['backups_current']}""")
rep("    mediafacts=[]", """    docks_binding=load('res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/binding_READY.json','dffded2e8d3bce09b50e3f127e26a060b6b3ab64ee9122c2ff3fb87184fbd012')
    docks_media={docks_binding['mask'][k]:docks_binding['required_source_sha256'][docks_binding['mask'][k]] for k in ['path','import_path','compiled_path']}
    assert len(docks_media)==3 and not set(media)&set(docks_media)
    media.update(docks_media)
    mediafacts=[]""")
rep("status='ROOT_FINAL33_WITH_PREWARM_PROFILE29_FIXED_PROTECTION_READONLY_GUARD'", "status='ROOT_FINAL33_WITH_PREWARM29_AND_DOCKS31_FIXED_PROTECTION_READONLY_GUARD'")
rep("prewarm_profile_deployment=dict(path=PREWARM_DEPLOY,sha256=PREWARM_DEPLOY_SHA),full_backup_count=67", "prewarm_profile_deployment=dict(path=PREWARM_DEPLOY,sha256=PREWARM_DEPLOY_SHA),docks_stage=dict(path=DOCKS_STAGE,sha256=DOCKS_STAGE_SHA),docks_deployment=dict(path=DOCKS_DEPLOY,sha256=DOCKS_DEPLOY_SHA),docks_mask_media_count=3,all_new_mask_media_count=6,full_backup_count=98")
raw=text.encode();ast.parse(text);aa=old.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);patch=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':patch.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,v=old,raw
for d in reversed(patch):
    x,y=d['old'].encode(),d['new'].encode();i,j=d['old_offset'],d['new_offset'];assert f[i:i+len(x)]==x and v[j:j+len(y)]==y;f=f[:i]+y+f[i+len(x):];v=v[:j]+x+v[j+len(y):]
assert f==raw and v==old
dest=HERE/'guard_deployed33_docks31_READONLY.py';assert not dest.exists();dest.write_bytes(raw)
proof=dict(status='FINAL_GUARD_ACTUAL31_AND98_BACKUPS_NOT_EXECUTED',parent_sha256=sha(old),guard=dict(path=str(dest),sha256=sha(raw)),offset_byte_patch=patch,whole_byte_forward_inverse=True,Python_AST_only=True,original2120_plus_UI1=2121,save15_exact_SHA_bytes_ticks=True,total_full_backups=98,latest31_within33=True,Docks_admitted_mask_media3_plus_Market_existing3=6,no_invented_fourth_media=True,guard_calls=0,collector_calls=0,engine_calls=0,canonical_writes=0)
pb=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();pp=HERE/'guard_docks31_whole_inverse_NOT_EXECUTED.json';assert not pp.exists();pp.write_bytes(pb)
print(json.dumps(dict(guard=proof['guard'],proof=dict(path=str(pp),sha256=sha(pb)),guard_calls=0)))
