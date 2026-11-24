"""Physical full driver byte inverse and final input static handoff; no Stage."""
from pathlib import Path
import json,hashlib,difflib,ast
HERE=Path(__file__).resolve().parent;S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=(HERE/'stage_market_blocks33_Estate1_NOTREADY.py').read_bytes();assert sha(old)=='4fa7f49701bb25ea6d7818fde17406d3d5d27fbb348fa72ef9a3302c6ecf4f5b'
new=(HERE/'stage_prewarm_profile29_NOTREADY.py').read_bytes();assert sha(new)=='b0b6ad4fd5e6db7120c77446a8f9e72af44b7ecac48096cca7f51c269bd40761';ast.parse(new.decode())
aa=old.decode().splitlines(keepends=True);bb=new.decode().splitlines(keepends=True);ds=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':ds.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,b=old,new
for d in reversed(ds):
    i=d['old_offset'];a,c=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+c+f[i+len(a):]
    i=d['new_offset'];assert b[i:i+len(c)]==c;b=b[:i]+a+b[i+len(c):]
assert f==new and b==old
ir=(HERE/'source_input_prewarm_profile29_ROOT_REVIEW.json').read_bytes();assert sha(ir)=='c6345cccfd311c6c2a1cc93f7ff7b3323e748b9ab7ddce8786f2e9c55dadf9fd';spec=json.loads(ir)
assert spec['required_generator']==dict(path=S+'stage_prewarm_profile29_NOTREADY.py',sha256=sha(new))
AP='res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json'
finite=next(n for n in spec['nodes'] if n['id']=='finite08_market')
assert any(op['pointer']==['legacy_source_sha256',AP] and op['old']=='f0df3f05a7f9382507ca92d3174c62bc1358187d50374050f975c347f8f89165' and op['new']=={'$sha':'market_final'} for op in finite['operations'])
assert len(spec['pass_through_targets'])==8 and len(spec['root_target_allowlist'])==29 and spec['prewarm_contract']['root_input_freeze_pending'] is False
alljson=[HERE/'prewarm_profile29_candidates01'/n for n in ['code_execution_whole_inverse_NOT_STAGE.json','execution_successor_prewarm8_profile04_PREPARATION.json','runtime_contract_C_Field_prewarm8_CANDIDATE.json','Temple_binding_prewarm8_profile04_CANDIDATE.json','C_to_fixed24c_proof_READY.json','AA_to_fixed24c_proof_READY.json']]
for path in alljson:
    raw=path.read_bytes();assert b'tokens truncated' not in raw;json.loads(raw)
report=dict(status='EXACT29_FINAL_DRIVER_INPUT_PHYSICAL_INVERSE_NOT_EXECUTED',driver=dict(path=S+'stage_prewarm_profile29_NOTREADY.py',sha256=sha(new)),parent_driver=dict(path=S+'stage_market_blocks33_Estate1_NOTREADY.py',sha256=sha(old)),driver_byte_hunks=ds,whole_driver_byte_forward_inverse=True,Python_AST_parse=True,input=dict(path=S+'source_input_prewarm_profile29_ROOT_REVIEW.json',sha256=sha(ir)),input_inverse=dict(path=S+'prewarm_profile29_driver_input_whole_inverse_NOT_EXECUTED.json',sha256='e9ba92e324f80be148bf44c16efa83e490b8b16646dc721a28e438313a68b78a'),physical_JSONs_strictly_parsed=6,Market_AP_parent_header_edge_explicitly_updated=True,Root_backup_pin='a235b1d4fb261b1f61329312b3b051ee7409355c779820c558f9958cbef7f56e',Root_preparation_pin='1aa419947f6f712f26d56a46125df22a07d7aee15def920b56ce5c29caaeb0aa',core8DE0_unchanged=True,Stage_executions=0,engine_calls=0,collector_calls=0,canonical_writes=0)
raw=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'prewarm_profile29_driver_byte_inverse_NOT_EXECUTED.json'
with out.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(driver=report['driver'],input=report['input'],proof=dict(path=S+out.name,sha256=sha(raw),bytes=len(raw)))))
