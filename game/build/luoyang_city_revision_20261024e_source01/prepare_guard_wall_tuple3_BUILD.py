"""Mechanical successor of the reviewed guard; does not run the guard."""
from pathlib import Path
import hashlib,json,difflib,ast
HERE=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
parent=HERE/'guard_deployed33_READONLY.py';old=parent.read_bytes()
assert sha(old)=='6846595734669064c9bc64f22b9478a7a6c88e18da02ce704d7c9e976209befd'
text=old.decode('utf8');edits=[]
def replace(a,b):
    global text
    assert text.count(a)==1,a
    text=text.replace(a,b);edits.append(dict(old=a,new=b))
replace("DEPLOY=R+'deployment33_actual.json';DEPLOY_SHA='d5aa84d441ff733332d77cc702631c776bf4863b3b9aa6f601f4fdb46e83f087'", "DEPLOY=R+'deployment33_actual.json';DEPLOY_SHA='d5aa84d441ff733332d77cc702631c776bf4863b3b9aa6f601f4fdb46e83f087'\nWALL=R+'wall_tuple3_deployed_actual.json';WALL_SHA='3550aa2efa1eedc4ba97a353bb085d992ce8507a306d01923199962312d08d78'")
replace("out=HERE/('guard_'+a.output_key+'_READONLY.json')", "out=HERE/('guard_wall_tuple3_'+a.output_key+'_READONLY.json')")
replace("assert prior_guard['passed'] is True and prior_guard['stage']['sha256']==STAGE_SHA", "assert prior_guard['passed'] is True and prior_guard['stage']['sha256']==STAGE_SHA and prior_guard['wall_tuple_deployment']['sha256']==WALL_SHA")
replace("targetrows={str(resolve(r['target'])):r for r in stage['targets']};assert len(targetrows)==33 and set(targetrows)<=set(parents)", """targetrows={str(resolve(r['target'])):dict(r) for r in stage['targets']};assert len(targetrows)==33 and set(targetrows)<=set(parents)
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
        assert sha(resolve(row['candidate_path']).read_bytes())==row['candidate_sha256'] and resolve(row['candidate_path']).stat().st_size==r['candidate']['bytes']""")
replace("    if prior_guard:\n        oldb={r['path']:signature(r) for r in prior_guard['backups_current']}", """    wallprefix=resolve(wall['backups']);assert wall['backups']==R+'wall_tuple3_predeploy_backup/'
    for r in wall['targets']:
        bp=(wallprefix/r['target'][6:]).resolve();assert bp.is_relative_to(wallprefix)
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],backup_generation='wall_tuple3_parent_deployed33',**row))
        if row.get('sha256')!=r['old_sha256'] or row.get('bytes')!=r['old_bytes']:errors.append(dict(path=str(bp),reason='WALL_TUPLE3_FULL_PARENT_BACKUP_CHANGED',current=row))
    assert len(backups)==36
    if prior_guard:
        oldb={r['path']:signature(r) for r in prior_guard['backups_current']}""")
replace("status='ROOT_EXACT33_FIXED_PROTECTION_READONLY_GUARD'", "status='ROOT_EXACT33_PLUS_WALL_TUPLE3_FIXED_PROTECTION_READONLY_GUARD'")
replace("deployment=dict(path=DEPLOY,sha256=DEPLOY_SHA),protected_count=2120", "deployment=dict(path=DEPLOY,sha256=DEPLOY_SHA),wall_tuple_deployment=dict(path=WALL,sha256=WALL_SHA),full_backup_count=36,protected_count=2120")
new=text.encode('utf8');ast.parse(text)
# Full physical forward/inverse byte patch, stored as small line hunks.
aa=old.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);patch=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':patch.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,b=old,new
for d in reversed(patch):
    i=d['old_offset'];x,y=d['old'].encode(),d['new'].encode();assert f[i:i+len(x)]==x;f=f[:i]+y+f[i+len(x):]
    i=d['new_offset'];assert b[i:i+len(y)]==y;b=b[:i]+x+b[i+len(y):]
assert f==new and b==old
dest=HERE/'guard_deployed33_wall_tuple3_READONLY.py'
with dest.open('xb') as stream:stream.write(new)
result=dict(status='GUARD_MECHANICAL_SUCCESSOR_NOT_EXECUTED',parent=dict(path=str(parent),sha256=sha(old)),candidate=dict(path=str(dest),sha256=sha(new)),hunks=patch,whole_byte_forward_inverse=True,Python_AST_parse=True,guard_executions=0,engine_calls=0,collector_calls=0,canonical_writes=0)
proof=HERE/'guard_wall_tuple3_whole_inverse_NOT_EXECUTED.json';raw=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()
with proof.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(candidate=result['candidate'],proof=dict(path=str(proof),sha256=sha(raw)),guard_executions=0)))
