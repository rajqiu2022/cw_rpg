"""Root-authorized readiness/path freeze, no Godot invocation."""
from pathlib import Path
import json,hashlib,copy,difflib
HERE=Path(__file__).resolve().parent;P='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
oldroot=HERE/'prewarm_profile_parse9_NOTREADY';newroot=HERE/'prewarm_profile_parse9_ROOT_READY';prefix=P+newroot.name+'/'
kr=(oldroot/'parse_NOTREADY.gd').read_bytes();fr=(oldroot/'input_NOTREADY.json').read_bytes()
assert sha(kr)=='3dca7216951c46987d010c1a8cb8b716f4a1fa851e7aa82894f80405a3902d99'
assert sha(fr)=='188c03c7d666470de8a68b68371afe0e0e4be040ff961e2f42b24f835e2535ec'
v=json.loads(fr);new=copy.deepcopy(v);new['ready']=True;new['output_prefix']=prefix+'output/'
nr=(json.dumps(new,ensure_ascii=False,indent=2)+'\n').encode();text=kr.decode()
for a,b in [('const READY=false','const READY=true'),(P+oldroot.name+'/input_NOTREADY.json',prefix+'input_ROOT_READY.json'),(sha(fr),sha(nr))]:
    assert text.count(a)==1;text=text.replace(a,b)
nk=text.encode();aa=kr.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);ds=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':ds.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,b=kr,nk
for d in reversed(ds):
    i=d['old_offset'];a,c=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+c+f[i+len(a):]
    i=d['new_offset'];assert b[i:i+len(c)]==c;b=b[:i]+a+b[i+len(c):]
assert f==nk and b==kr
restored=copy.deepcopy(new);restored['ready']=v['ready'];restored['output_prefix']=v['output_prefix'];assert restored==v
assert not newroot.exists();newroot.mkdir()
for name,data in [('parse_ROOT_READY.gd',nk),('input_ROOT_READY.json',nr)]:
    with (newroot/name).open('xb') as stream:stream.write(data)
proof=dict(status='ROOT_AUTHORIZED_EXACT9_PARSE_READY_NOT_EXECUTED',key=dict(path=prefix+'parse_ROOT_READY.gd',sha256=sha(nk)),input=dict(path=prefix+'input_ROOT_READY.json',sha256=sha(nr)),old_key_sha256=sha(kr),old_input_sha256=sha(fr),key_byte_hunks=ds,whole_byte_forward_inverse=True,input_only_ready_and_output_prefix=True,scripts_9_same=True,non_early_return_body_same=True,budget_20s_same=True,save_source_guard_same=True,engine_calls=0,Stage_calls=0)
pr=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode()
with (newroot/'whole_inverse_NOT_EXECUTED.json').open('xb') as stream:stream.write(pr)
print(json.dumps(dict(key=proof['key'],input=proof['input'],proof_sha256=sha(pr))))
