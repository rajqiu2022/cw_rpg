"""Fix only the stale ENV immutable expectation and isolate the second output."""
from pathlib import Path
import json,hashlib,copy,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
parent=HERE/'source_input_prewarm_profile29_ROOT_REVIEW.json';old=parent.read_bytes();assert sha(old)=='c6345cccfd311c6c2a1cc93f7ff7b3323e748b9ab7ddce8786f2e9c55dadf9fd'
a=json.loads(old);b=copy.deepcopy(a);pins={r['id']:r for r in b['pinned_inputs']};audit=[];changed=[]
for row in b['nodes']:
    if row['kind'] not in ['space_frozen','space_code']:continue
    pin=pins[row['base_input']];physical=(GAME/pin['path'][6:]).read_bytes();assert sha(physical)==pin['sha256']
    audit.append(dict(node=row['id'],kind=row['kind'],base_input=row['base_input'],pin=pin,old_immutable_sha256=row['immutable_sha256'],equal_before=row['immutable_sha256']==pin['sha256']))
    if row['immutable_sha256']!=pin['sha256']:
        assert row['id']=='ENV_code' and row['immutable_sha256']=='52c70620d8b1e5194b9f2ad492cffdc7d8c537e0c21d9dbe3bc7fda6f8e90df4' and pin['sha256']=='0f223acc26a91a74a5523b87032d1487c0996730d3e8b93ac3c29aba81e5f07b'
        row['immutable_sha256']=pin['sha256'];changed.append(row['id'])
assert changed==['ENV_code'] and len(audit)==4
b['output_root']=S+'outputs/root_prewarm8_profile04_exact29_stage02/'
restored=copy.deepcopy(b)
next(n for n in restored['nodes'] if n['id']=='ENV_code')['immutable_sha256']=next(n for n in a['nodes'] if n['id']=='ENV_code')['immutable_sha256']
restored['output_root']=a['output_root'];assert restored==a
raw=(json.dumps(b,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();assert (json.dumps(restored,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()==old
aa=old.decode().splitlines(keepends=True);bb=raw.decode().splitlines(keepends=True);ds=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':ds.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,rev=old,raw
for d in reversed(ds):
    i=d['old_offset'];x,y=d['old'].encode(),d['new'].encode();assert f[i:i+len(x)]==x;f=f[:i]+y+f[i+len(x):]
    i=d['new_offset'];assert rev[i:i+len(y)]==y;rev=rev[:i]+x+rev[i+len(y):]
assert f==raw and rev==old
dest=HERE/'source_input_prewarm_profile29_residual02_ROOT_REVIEW.json'
with dest.open('xb') as stream:stream.write(raw)
proof=dict(status='EXACT_ENV_IMMUTABLE_INPUT_LITERAL_RESIDUAL_NOT_EXECUTED',parent_input=dict(path=S+parent.name,sha256=sha(old)),candidate_input=dict(path=S+dest.name,sha256=sha(raw)),only_changed_fields=['nodes.ENV_code.immutable_sha256','output_root'],all_four_frozen_code_pin_audit=audit,all_frozen_code_expectations_equal_after=True,driver_unchanged=b['required_generator'],candidate_code_and_parse_unchanged=True,input_byte_hunks=ds,whole_typed_ordered_UTF8_and_byte_forward_inverse=True,original_FAILED_stage01_preserved=True,Stage_executions=0,engine_calls=0,collector_calls=0,canonical_writes=0)
pr=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'prewarm_profile29_residual02_whole_input_inverse_NOT_EXECUTED.json'
with out.open('xb') as stream:stream.write(pr)
print(json.dumps(dict(input=proof['candidate_input'],driver=proof['driver_unchanged'],proof=dict(path=S+out.name,sha256=sha(pr)),frozen_nodes_audited=4,only_ENV_mismatch=True)))
