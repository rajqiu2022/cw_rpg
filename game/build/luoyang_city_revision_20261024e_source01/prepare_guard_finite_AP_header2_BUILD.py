"""Mechanical final guard successor, no guard execution."""
from pathlib import Path
import hashlib,json,difflib,ast
HERE=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
parent=HERE/'guard_deployed33_wall_tuple3_READONLY.py';old=parent.read_bytes();assert sha(old)=='9b9ac332e6f9c98f484c28a8719d8cb21e87d21763ce122a0c081cae9de4c9ae'
text=old.decode();edits=[]
def rep(a,b):
    global text
    assert text.count(a)==1,a;text=text.replace(a,b);edits.append(dict(old=a,new=b))
rep("WALL=R+'wall_tuple3_deployed_actual.json';WALL_SHA='3550aa2efa1eedc4ba97a353bb085d992ce8507a306d01923199962312d08d78'", "WALL=R+'wall_tuple3_deployed_actual.json';WALL_SHA='3550aa2efa1eedc4ba97a353bb085d992ce8507a306d01923199962312d08d78'\nHEADER=R+'finite_AP_header2_deployed_actual.json';HEADER_SHA='d596ef3c7cd7177fc302f25aac3cdba6b7ad2772e1ec0122aaed2afa8549e799'")
rep("out=HERE/('guard_wall_tuple3_'+a.output_key+'_READONLY.json')", "out=HERE/('guard_header2_'+a.output_key+'_READONLY.json')")
rep("and prior_guard['wall_tuple_deployment']['sha256']==WALL_SHA", "and prior_guard['wall_tuple_deployment']['sha256']==WALL_SHA and prior_guard['finite_AP_header_deployment']['sha256']==HEADER_SHA")
rep("    started=datetime.datetime.now(datetime.timezone.utc).isoformat();current={p:fact(Path(p)) for p in parents};errors=[];authorized=[];external=[]", """    header=load(HEADER,HEADER_SHA)
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
    started=datetime.datetime.now(datetime.timezone.utc).isoformat();current={p:fact(Path(p)) for p in parents};errors=[];authorized=[];external=[]""")
rep("    assert len(backups)==36", """    assert len(backups)==36
    headerprefix=resolve(header['backups']);assert header['backups']==R+'finite_AP_header2_predeploy_backup/'
    for r in header['targets']:
        bp=(headerprefix/r['target'][6:]).resolve();assert bp.is_relative_to(headerprefix)
        row=fact(bp);backups.append(dict(path=str(bp),target=r['target'],backup_generation='finite_AP_header2_parent_tuple3',**row))
        if row.get('sha256')!=r['old_sha256'] or row.get('bytes')!=r['old_bytes']:errors.append(dict(path=str(bp),reason='FINITE_AP_HEADER2_FULL_PARENT_BACKUP_CHANGED',current=row))
    assert len(backups)==38""")
rep("status='ROOT_EXACT33_PLUS_WALL_TUPLE3_FIXED_PROTECTION_READONLY_GUARD'", "status='ROOT_EXACT33_PLUS_TUPLE3_HEADER2_FIXED_PROTECTION_READONLY_GUARD'")
rep("wall_tuple_deployment=dict(path=WALL,sha256=WALL_SHA),full_backup_count=36", "wall_tuple_deployment=dict(path=WALL,sha256=WALL_SHA),finite_AP_header_deployment=dict(path=HEADER,sha256=HEADER_SHA),full_backup_count=38")
raw=text.encode();ast.parse(text);aa=old.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);ds=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':ds.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,b=old,raw
for d in reversed(ds):
    i=d['old_offset'];x,y=d['old'].encode(),d['new'].encode();assert f[i:i+len(x)]==x;f=f[:i]+y+f[i+len(x):]
    i=d['new_offset'];assert b[i:i+len(y)]==y;b=b[:i]+x+b[i+len(y):]
assert f==raw and b==old
dest=HERE/'guard_deployed33_tuple3_header2_READONLY.py'
with dest.open('xb') as stream:stream.write(raw)
proof=dict(status='MECHANICAL_HEADER2_GUARD_NOT_EXECUTED',parent_sha256=sha(old),candidate=dict(path=str(dest),sha256=sha(raw)),hunks=ds,whole_byte_forward_inverse=True,Python_AST_parse=True,guard_executions=0,collector_calls=0,canonical_writes=0)
pr=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();pp=HERE/'guard_header2_whole_inverse_NOT_EXECUTED.json'
with pp.open('xb') as stream:stream.write(pr)
print(json.dumps(dict(candidate=proof['candidate'],proof=dict(path=str(pp),sha256=sha(pr)))))
