"""Mechanical READY freeze only; immutable System package plus approved trial doc."""
from pathlib import Path
import argparse,hashlib,json,copy
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024e_source01/'
N='res://build/luoyang_city_blocks_20261024e_system01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),(p,sha(b));assert b'tokens truncated' not in b;return b
def replace(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a,b.count(a));return b.replace(a,c,1)
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--trial-path',required=True);ap.add_argument('--trial-sha',required=True);args=ap.parse_args()
    trial=json.loads(read(args.trial_path,args.trial_sha))
    assert isinstance(trial,dict) and args.trial_sha.isascii() and len(args.trial_sha)==64
    package=json.loads(read(N+'final_functional_package09_NOTREADY.json','385df258a4f9a4a0f7a1679fe7bb7a90648e1c1f914df59edb26bb6dbaa8fe56'))
    out=HERE/'runtime_ready01';assert not out.exists();prefix=S+'runtime_ready01/'
    binding_parent=read(package['binding']['path'],package['binding']['sha256']);old=json.loads(binding_parent);b=copy.deepcopy(old)
    assert b['ready'] is False and b['local_art']['admitted'] is False and len(b['required_source_sha256'])==26
    b['ready']=True;b['local_art']['admitted']=True;b['local_art']['path']=args.trial_path;b['local_art']['sha256']=args.trial_sha.lower()
    # This remains a limited source/asset/layout Field trial, never completed GPU ART.
    assert b['local_art']['scope']=='SOURCE_ASSET_AND_AUTHORED_LAYOUT_FIELD_TRIAL_ONLY' and b['local_art']['actual_Field_ART_pending'] is True
    b['required_source_sha256'][args.trial_path]=args.trial_sha.lower();b['pending_only']=[]
    inverse=copy.deepcopy(b);inverse['ready']=False;inverse['local_art']=copy.deepcopy(old['local_art']);inverse['pending_only']=copy.deepcopy(old['pending_only']);del inverse['required_source_sha256'][args.trial_path]
    assert inverse==old and enc(inverse)==binding_parent
    binding_bytes=enc(b);binding_path=prefix+'binding_READY.json';binding_sha=sha(binding_bytes)
    runtime=package['candidates'][0];runtime_parent=read(runtime['path'],runtime['sha256']);runtime_path=prefix+'market_block_session_READY.gd'
    runtime_ops=[('const READY=false','const READY=true'),(runtime['path'],runtime_path),(package['binding']['path'],binding_path),(package['binding']['sha256'].lower(),binding_sha)]
    runtime_bytes=runtime_parent
    for a,c in runtime_ops:runtime_bytes=replace(runtime_bytes,a,c)
    inverse_bytes=runtime_bytes
    for a,c in reversed(runtime_ops):inverse_bytes=replace(inverse_bytes,c,a)
    assert inverse_bytes==runtime_parent
    runtime_sha=sha(runtime_bytes)
    merge=json.loads(read(S+'merged_layout_perf06_NOTREADY/merge_whole_inverse_NOTRUN.json','0faa87b27d025d96d358e7074032576176d5bb9242a6d2d60a92e74862e0ae59'))
    prepared=[('binding_READY.json',binding_bytes),('market_block_session_READY.gd',runtime_bytes)];rows=[]
    for kind in ['C','DT','Field','G','ENV','Router']:
        r=next(r for r in package['candidates'] if Path(r['path']).name.startswith({'C':'C_blocks','DT':'DT_blocks','Field':'Field_blocks','G':'G_blocks','ENV':'ENV_blocks','Router':'Router_default'}[kind]))
        if kind in ['C','Field']:
            m=next(x for x in merge['entries'] if x['target'].endswith('luoyang_enclosure_v11_candidate_contract.gd' if kind=='C' else 'field_walkable_controller.gd'))
            parent=dict(path='res://'+Path(m['candidate_path']).relative_to(GAME).as_posix(),sha256=m['candidate_sha256'])
        else:parent=r
        raw=read(parent['path'],parent['sha256']);result=raw;ops=[]
        if kind!='Router':
            for a,c in [(runtime['path'],runtime_path),(runtime['sha256'].lower(),runtime_sha)]:
                result=replace(result,a,c);ops.append(dict(old=a,new=c))
        if kind=='ENV':
            result=replace(result,'const MARKET_SPACE_READY=false','const MARKET_SPACE_READY=true');ops.append(dict(old='const MARKET_SPACE_READY=false',new='const MARKET_SPACE_READY=true'))
        check=result
        for h in reversed(ops):check=replace(check,h['new'],h['old'])
        assert check==raw and result.count(b'\r')==raw.count(b'\r')
        name=kind+'_READY.gd';prepared.append((name,result));rows.append(dict(kind=kind,parent=parent,candidate=dict(path=prefix+name,sha256=sha(result),bytes=len(result)),mechanical_replacements=ops,wholebyte_inverse=True))
    proof=dict(status='MECHANICAL_READY_FREEZE_NOT_PARSED_NOT_STAGED',trial=dict(path=args.trial_path,sha256=args.trial_sha.lower()),binding=dict(parent=package['binding'],candidate=dict(path=binding_path,sha256=binding_sha,bytes=len(binding_bytes)),typed_and_serialized_inverse=True),runtime=dict(parent=runtime,candidate=dict(path=runtime_path,sha256=runtime_sha,bytes=len(runtime_bytes)),replacements=[dict(old=a,new=c) for a,c in runtime_ops],wholebyte_inverse=True),codes=rows,whole_street_Field_ART_pending=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
    prepared.append(('mechanical_ready_whole_inverse_NOT_STAGE.json',enc(proof)))
    out.mkdir()
    for name,data in prepared:
        with (out/name).open('xb') as f:f.write(data)
        assert (out/name).read_bytes()==data
    print(json.dumps(dict(proof_path=prefix+'mechanical_ready_whole_inverse_NOT_STAGE.json',proof_sha256=sha(prepared[-1][1]),runtime_sha256=runtime_sha,binding_sha256=binding_sha,codes=rows)))
if __name__=='__main__':main()
