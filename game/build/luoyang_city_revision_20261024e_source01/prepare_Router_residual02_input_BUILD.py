"""Keep33 Stage compiler/body; only Router syntax-dependent pin values change."""
from pathlib import Path
import json,hashlib,copy,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return b
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
oldpath=S+'source_input_market_blocks33_ROOT_REVIEW.json';oldsha='e354855c35fc8a0c5faa3485f397ae1c2183076ae785dce8c96b9edd2a522c0c';oldraw=read(oldpath,oldsha);original=json.loads(oldraw);spec=copy.deepcopy(original)
proofpath=S+'Router_receiver_residual02_READY/code_execution_whole_inverse_NOT_STAGE.json';proofsha='f9477c1d8f3f4989128b91f95043bc257e4e6647525767aad74d570223f37cc5';proof=json.loads(read(proofpath,proofsha))
oldproof=json.loads(read(S+'dependencies33_READY/code_execution_whole_inverse_NOT_STAGE.json','d6b4c0afcaac7f8f29ca8c15b7412abafa90ad7418c4106a8d113622c715913e'))
pinmap={x['id']:x for x in spec['pinned_inputs']}
def pin(i,r):pinmap[i].update(path=r['path'],sha256=r['sha256'])
pin('space_code_inverse',dict(path=proofpath,sha256=proofsha));pin('execution_approval',proof['execution']['candidate']);pin('space_contract_literal',proof['contract']['candidate']);pin('space_temple_binding',proof['temple_binding']['candidate'])
for i,(p,r) in enumerate(proof['records'].items()):
    assert p==list(oldproof['records'])[i]
    pin('blocks_code_'+str(i),r['candidate'])
spec['pinned_inputs'].append(dict(id='Router_parse_receiver_inverse',**proof['residual_router_inverse']))
spec['space_contract']['Router_parse_receiver_inverse_input']='Router_parse_receiver_inverse'
for rows in [spec['pass_through_targets'],spec['prospective_targets']]:
    for row in rows:
        p=row['target'];r=proof['records'][p]['candidate'] if p in proof['records'] else proof['execution']['candidate'];row['candidate_path']=r['path']
        row['candidate_sha256' if 'candidate_sha256' in row else 'sha256']=r['sha256']
router=proof['records']['res://scripts/autoload/scene_router.gd'];raw=read(router['candidate']['path'],router['candidate']['sha256']);shadow=raw.replace(b'\r\n',b'\n')
spec['space_contract']['Router_exact_EOL_transport'].update(candidate_sha256=router['candidate']['sha256'],LF_shadow_sha256=sha(shadow),LF_shadow_bytes=len(shadow))
spec['output_root']=S+'outputs/root_market_blocks_prewarm_exact33_stage02/'
spec['source_baseline']=original['source_baseline']+' Residual02 only Router static-Script.call compile repair to a Variant receiver, and its exact contract/Coordinator/Temple/execution SHA closure. Original Stage01 remains source-only, never a deployed parent.'
assert spec['required_generator']==original['required_generator'] and spec['nodes']==original['nodes'] and spec['source_groups']==original['source_groups'] and spec['root_target_allowlist']==original['root_target_allowlist']
out=HERE/'Router_receiver_residual02_READY';dest=out/'source_input_market_blocks33_residual02_ROOT_REVIEW.json';assert not dest.exists();raw=enc(spec)
with dest.open('xb') as stream:stream.write(raw)
delta=[];al,bl=oldraw.decode().splitlines(keepends=True),raw.decode().splitlines(keepends=True)
for tag,i,j,k,l in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_opcodes():
    if tag!='equal':delta.append(dict(old_offset=sum(len(x.encode()) for x in al[:i]),new_offset=sum(len(x.encode()) for x in bl[:k]),old=''.join(al[i:j]),new=''.join(bl[k:l])))
f,b=oldraw,raw
for d in reversed(delta):i=d['old_offset'];a,c=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+c+f[i+len(a):]
for d in reversed(delta):i=d['new_offset'];a,c=d['old'].encode(),d['new'].encode();assert b[i:i+len(c)]==c;b=b[:i]+a+b[i+len(c):]
assert f==raw and b==oldraw
proofout=enc(dict(status='ROUTER_RECEIVER_INPUT_RESIDUAL_NOT_RUN',parent=dict(path=oldpath,sha256=oldsha),candidate=dict(path=S+'Router_receiver_residual02_READY/'+dest.name,sha256=sha(raw)),segments=delta,wholebyte_forward_inverse=True,unchanged_driver=spec['required_generator'],nodes_groups_targets_unchanged=True,old_Stage01_not_deployed=True,formal_parent24c_unchanged=True,engine_calls=0,Stage_calls=0,canonical_writes=0))
pp=out/'input_physical_byte_inverse_NOT_STAGE.json'
with pp.open('xb') as stream:stream.write(proofout)
print(json.dumps(dict(input_path=S+'Router_receiver_residual02_READY/'+dest.name,input_sha256=sha(raw),inverse_path=S+'Router_receiver_residual02_READY/'+pp.name,inverse_sha256=sha(proofout),byte_segments=len(delta),driver=spec['required_generator'])))
