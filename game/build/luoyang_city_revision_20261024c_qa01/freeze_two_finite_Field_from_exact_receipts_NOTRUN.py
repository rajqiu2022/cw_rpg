"""Mechanical finalizer, no engine. Requires actual fixed Stage/deployment/fresh files.

Only reads text and hashes small fixed documents/scripts. Never reads target files
or media to construct expected values. Two maps are taken from pinned Stage nodes.
"""
import argparse,copy,hashlib,json,re
from pathlib import Path
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
OLD=BASE/'finite_Field_NOTREADY'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def resolve(value):
    return GAME/value[6:] if value.startswith('res://') else Path(value)
def res(p):return 'res://'+p.resolve().relative_to(GAME.resolve()).as_posix()
def load(value,expected):
    p=resolve(value);assert sha(p)==expected.lower(),(str(p),sha(p),expected)
    return p,json.loads(p.read_text(encoding='utf-8'))
def serial(v):return (json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode()
def hexsha(v):return isinstance(v,str) and re.fullmatch('[a-f0-9]{64}',v) is not None
def main():
    ap=argparse.ArgumentParser()
    for name in ['stage','stage-sha','stage-status','deployment','deployment-sha','deployment-status','fresh','fresh-sha','out']:
        ap.add_argument('--'+name,required=True)
    args=ap.parse_args()
    sp,s=load(args.stage,args.stage_sha);dp,d=load(args.deployment,args.deployment_sha);fp,f=load(args.fresh,args.fresh_sha)
    assert s['status']==args.stage_status and d['status']==args.deployment_status and d['passed'] is True
    assert len(s['targets'])==d['target_count']==30
    assert s['target_partition']==dict(patch_count=15,copy_count=15,total=30)
    assert d['partition']==dict(apply_patch_GD=15,exact_copy_JSON=15)
    assert resolve(d['stage']['path']).resolve()==sp.resolve() and d['stage']['sha256']==args.stage_sha.lower()
    st={r['target']:r for r in s['targets']};dt={r['target']:r for r in d['targets']}
    assert len(st)==len(dt)==30 and st.keys()==dt.keys()
    for target,row in st.items():
        actual=dt[target]
        assert row['old_sha256']==actual['old_sha256'] and row['candidate_sha256']==actual['candidate_sha256']==actual['actual_sha256']
        assert resolve(row['candidate_path']).resolve()==resolve(actual['candidate_path']).resolve()
        assert hexsha(row['candidate_sha256']) and actual['bytes']>0
    # A real fresh guard must be successful; no null/header-only placeholder.
    assert f.get('passed') is True or f.get('ok') is True,f.keys()
    out=resolve(args.out);assert not out.exists(),out
    out.resolve().relative_to(BASE.resolve())
    docs=[(res(sp),args.stage_sha.lower()),(res(dp),args.deployment_sha.lower()),(res(fp),args.fresh_sha.lower())]
    results=[];buffered=[]
    runtime='res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/courts_session_READY.gd'
    binding='res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/binding_READY.json'
    bp,b=load(binding,'60c3a2d949599ca269df1e22dd85d3d620f04e6d1d3ccacb48d27f5373e4676a')
    assert b['ready'] is True and b['scene_id']=='ch4_s1_luoyang_yamen'
    for stem,scene,token,fixture_pin,script_pin,ready_const,fixture_const,hash_const,output_const in [
        ('yamen_courts','ch4_s1_luoyang_yamen','expected_ch4_s1_luoyang_yamen_true','2b5293f8a7c016ac619212552c333805310eaa285906d58fccbfb98b2d994600','2403b6eaed45686e776df9502c95a596422f2a22915d42152d727d6b6bc301d7','COURTS_READY','COURTS_FIXTURE','COURTS_FIXTURE_SHA','COURTS_OUTPUT'),
        ('scholar_portrait','ch4_s3_luoyang_market','expected_ch4_s3_luoyang_market_true','bb137efa196dec3c6a28675f2ea95c8b14395dd2b24df1b52e35202c9154d0d7','de18bd519c019d781f9d2c71f6f89bee4d961535a5fc79d6e7f4042070eb3e54','SCHOLAR_READY','SCHOLAR_FIXTURE','SCHOLAR_FIXTURE_SHA','SCHOLAR_OUTPUT')]:
        old_name='yamen_fixture_NOTREADY.json' if stem=='yamen_courts' else 'scholar_fixture_NOTREADY.json'
        oldp,old=load(str(OLD/old_name),fixture_pin)
        keyp=OLD/(stem+'_NOTREADY.gd');assert sha(keyp)==script_pin
        row=s['nodes'][token];mp,m=load(row['path'],row['sha256'])
        assert m==row['value'] and m['scene_id']==scene and isinstance(m['source_sha256'],dict) and m['source_sha256']
        expected=m['source_sha256'];assert all(hexsha(v) for v in expected.values())
        new=copy.deepcopy(old);new.update(ready=True,formal_deployed=True,status='ROOT_APPROVED_FINITE_24C_FIELD_READY',blockers=[],
            expected_city_count=len(expected),expected_city_sources=expected,
            stage=dict(path=res(sp),sha256=args.stage_sha.lower()),deployment=dict(path=res(dp),sha256=args.deployment_sha.lower()),fresh_guard=dict(path=res(fp),sha256=args.fresh_sha.lower()))
        new['source_sha256'].update(dict(docs));new['source_sha256'][res(mp)]=row['sha256']
        # Literal canonical identities come from Stage declarations, never disk/current.
        for target in ['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd']:
            new['source_sha256'][target]=st[target]['candidate_sha256']
            assert expected[target]==st[target]['candidate_sha256']
        if stem=='yamen_courts':
            assert expected[runtime]=='791ae73e97623e71c0a0445f7a60cd14b6bf8f17453e7fa77dd9d0a89a873c4a' and expected[binding]==sha(bp)
            new['courts_runtime_path']=runtime;new['effective_mask_path']=b['mask']['path']
            for p in [runtime,binding]:new['source_sha256'][p]=expected[p]
        else:
            portrait=new['scholar_portrait']
            assert expected[portrait]=='ebd60b64edbcc061401a0fc1219d1f120a4f5d4e98db1ab1d129c81f845c2a74'
            new['source_sha256'][portrait]=expected[portrait]
        # All other false fixture values, paths, geometry, NPCs and scope stay exact.
        restored=copy.deepcopy(new)
        for field in ['ready','formal_deployed','status','blockers','expected_city_count','expected_city_sources','stage','deployment','fresh_guard','source_sha256']:
            restored[field]=old[field]
        if stem=='yamen_courts':
            restored['courts_runtime_path']=old['courts_runtime_path'];restored['effective_mask_path']=old['effective_mask_path']
        assert restored==old and serial(restored)==oldp.read_bytes()
        folder=out/stem;fixture_path=folder/'fixture_READY.json';key_path=folder/'test_READY.gd'
        fixture_bytes=serial(new);fixture_sha=hashlib.sha256(fixture_bytes).hexdigest()
        text=keyp.read_bytes();original=text
        replacements=[(f'const {ready_const}=false',f'const {ready_const}=true'),
            (f'const {fixture_const}="res://build/luoyang_city_revision_20261024c_qa01/finite_Field_NOTREADY/{old_name}"',f'const {fixture_const}="{res(fixture_path)}"'),
            (f'const {hash_const}="PENDING_FINAL_SOURCE_MAP_AND_FORMAL_DEPLOYMENT"',f'const {hash_const}="{fixture_sha}"'),
            (f'const {output_const}="res://build/luoyang_city_revision_20261024c_qa01/finite_Field_NOTREADY/{"yamen" if stem=="yamen_courts" else "scholar"}_output_NOTREADY"',f'const {output_const}="{res(folder/"output_READY")}"')]
        for before,after in replacements:
            assert text.count(before.encode())==1,before
            text=text.replace(before.encode(),after.encode())
        inverse=text
        for before,after in reversed(replacements):
            assert inverse.count(after.encode())==1
            inverse=inverse.replace(after.encode(),before.encode())
        assert inverse==original and text.endswith(b'\n')==original.endswith(b'\n')
        buffered.extend([(fixture_path,fixture_bytes),(key_path,text)])
        results.append(dict(scene_id=scene,map=dict(path=res(mp),sha256=row['sha256'],count=len(expected)),fixture=dict(path=res(fixture_path),sha256=fixture_sha),key=dict(path=res(key_path),sha256=hashlib.sha256(text).hexdigest()),four_literal_full_byte_inverse=True,fixture_limited_typed_and_serialized_inverse=True))
    # Only after ALL assertions pass do NEW QA outputs get written.
    for p,data in buffered:p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    receipt=dict(status='MECHANICALLY_FROZEN_TWO_FINITE_24C_KEYS_NOT_RUN',stage=docs[0],deployment=docs[1],fresh=docs[2],outputs=results,engine=0,current_target_reads_for_expectations=0,collector=0,production_writes=0)
    rp=out/'freeze_review_READY_NOTRUN.json';rp.write_bytes(serial(receipt))
    print(json.dumps(dict(receipt=dict(path=res(rp),sha256=sha(rp)),outputs=results)))

if __name__=='__main__':main()
