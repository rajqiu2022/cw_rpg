"""One final syntax-only source closure, preserving all previous BUILD attempts."""
from pathlib import Path
import json,hashlib,runpy,copy
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/';N='res://build/luoyang_city_blocks_20261024e_system01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),(p,sha(b));return b
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1;return b.replace(a,c,1)
def derived(filename,parent,mapping):
    raw=(HERE/parent).read_bytes();text=raw.decode();ops=[]
    for a,b in mapping:
        count=text.count(a);assert count>0,(parent,a);text=text.replace(a,b);ops.append(dict(old=a,new=b,occurrences=count))
    back=text
    for r in reversed(ops):assert back.count(r['new'])==r['occurrences'];back=back.replace(r['new'],r['old'])
    assert back.encode()==raw;compile(text,filename,'exec');dest=HERE/filename;assert not dest.exists()
    with dest.open('xb') as stream:stream.write(text.encode())
    runpy.run_path(str(dest),run_name='__main__')
    return dict(path=S+filename,sha256=sha(text.encode()),parent_sha256=sha(raw),replacements=ops,wholebyte_inverse=True)
def main():
    oldfreeze=json.loads(read(S+'runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad'))
    sessionproof=json.loads(read(N+'session10_explicit_delta_whole_inverse_BUILD.json','4f1fe1e50ee73e3d3ea93f67d0ac22b3088478302660edf1cb46b9f17c02cc54'))
    source=N+'market_block_session10_explicit_delta_CANDIDATE.gd';sb=read(source,'77dddba3e11a7eae141c0f331560f25f13c0e4ce06c4cf1eee9ad7d953e4dc27');oldruntime=oldfreeze['runtime']['candidate']
    # Only SELF must move to the new immutable implementation. Existing BIND
    # is unchanged and deliberately reused, avoiding any self-hash cycle.
    out=HERE/'runtime_ready03';assert not out.exists();prefix=S+'runtime_ready03/';selfpath=prefix+'market_block_session_READY.gd';runtime=exact(sb,oldruntime['path'],selfpath);rh=sha(runtime);assert exact(runtime,selfpath,oldruntime['path'])==sb
    prepared=[('market_block_session_READY.gd',runtime)];rows=[]
    for r in oldfreeze['codes']:
        kind=r['kind'];parent=r['candidate'];raw=read(parent['path'],parent['sha256']);ops=[]
        if kind=='ENV':
            p=json.loads(read(S+'clean_ENV02_READY/whole_inverse_NOT_STAGE.json','ef8f18da6267c0e542c4e288310ae15c9675756ce22cb394b4461b94b5f1e04f'));parent=p['candidate'];raw=read(parent['path'],parent['sha256'])
        after=raw
        if kind=='Router':
            parent=dict(path=N+'Router_default_only04_dynamic_receiver_rawEOL_CANDIDATE.gd',sha256='908f2254539010557b7ebfdc1cb77f86f6a05b068d1386741268b39a9cadeb51');after=read(parent['path'],parent['sha256']);raw=after
        else:
            for a,b in [(oldruntime['path'],selfpath),(oldruntime['sha256'],rh)]:after=exact(after,a,b);ops.append(dict(old=a,new=b))
        back=after
        for h in reversed(ops):back=exact(back,h['new'],h['old'])
        assert back==raw and after.count(b'\r')==raw.count(b'\r')
        name=kind+'_READY.gd';prepared.append((name,after));rows.append(dict(kind=kind,parent=parent,candidate=dict(path=prefix+name,sha256=sha(after),bytes=len(after)),mechanical_replacements=ops,wholebyte_inverse=True))
    freeze=dict(status='SYNTAX_RESIDUAL_READY_FREEZE_NOT_STAGED',binding=copy.deepcopy(oldfreeze['binding']),runtime=dict(parent=dict(path=source,sha256=sha(sb)),candidate=dict(path=selfpath,sha256=rh,bytes=len(runtime)),replacements=[dict(old=oldruntime['path'],new=selfpath)],wholebyte_inverse=True,explicit_delta_proof=dict(path=N+'session10_explicit_delta_whole_inverse_BUILD.json',sha256='4f1fe1e50ee73e3d3ea93f67d0ac22b3088478302660edf1cb46b9f17c02cc54')),codes=rows,whole_street_Field_ART_pending=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
    fr=enc(freeze);prepared.append(('mechanical_ready_whole_inverse_NOT_STAGE.json',fr));envrow=next(r for r in rows if r['kind']=='ENV');er=enc(dict(parent=envrow['parent'],candidate=envrow['candidate'],hunks=envrow['mechanical_replacements'],wholebyte_forward_inverse=True,no_new_functionality=True));prepared.append(('ENV_whole_inverse_NOT_STAGE.json',er))
    out.mkdir()
    for name,b in prepared:
        with (out/name).open('xb') as stream:stream.write(b)
        assert (out/name).read_bytes()==b
    ordinary_generator=derived('prepare_ordinary_outer03_BUILD.py','prepare_ordinary_outer01_BUILD.py',[
        ('runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json'),('ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad',sha(fr)),('ordinary_outer01_READY','ordinary_outer03_READY')])
    ordinaryraw=(HERE/'ordinary_outer03_READY/whole_inverse_NOT_STAGE.json').read_bytes();ordinarysha=sha(ordinaryraw)
    dependency_generator=derived('prepare_dependencies_execution33_session03_BUILD.py','prepare_dependencies_execution33_BUILD.py',[
        ('runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json'),('ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad',sha(fr)),('ordinary_outer01_READY/whole_inverse_NOT_STAGE.json','ordinary_outer03_READY/whole_inverse_NOT_STAGE.json'),('26f9cd34b9c0aea9b782e267e3cf00ac279cea70cfe785a5055c331581d15618',ordinarysha),('clean_ENV02_READY/whole_inverse_NOT_STAGE.json','runtime_ready03/ENV_whole_inverse_NOT_STAGE.json'),('ef8f18da6267c0e542c4e288310ae15c9675756ce22cb394b4461b94b5f1e04f',sha(er)),('dependencies33_READY','dependencies33_session03_READY')])
    depsraw=(HERE/'dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json').read_bytes();depssha=sha(depsraw)
    # Run the same static recipe builder against the original fixed24c parent,
    # never the source-only Stage01. The compiler stays exactly4FA7.
    import sys
    oldargv=sys.argv;sys.argv=['prepare_stage33_session03_input_BUILD.py','--preparation-path','res://build/luoyang_city_revision_20261024e_root01/source_preparation33_authorization.json','--preparation-sha','0afc4fa309a352594177b80235c542c7278f90f7548913f8a12303a8245e8b50']
    try:
        input_generator=derived('prepare_stage33_session03_input_BUILD.py','prepare_stage33_input_BUILD.py',[
            ('dependencies33_READY/code_execution_whole_inverse_NOT_STAGE.json','dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json'),('d6b4c0afcaac7f8f29ca8c15b7412abafa90ad7418c4106a8d113622c715913e',depssha),('runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json'),('ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad',sha(fr)),('outputs/root_market_blocks_prewarm_exact33_stage01/','outputs/root_market_blocks_prewarm_exact33_stage03/'),('source_input_market_blocks33_ROOT_REVIEW.json','source_input_market_blocks33_session03_ROOT_REVIEW.json'),('stage33_input_full_byte_patch_BUILD.json','stage33_session03_input_full_byte_patch_BUILD.json'),('stage33_package_review_BUILD.json','stage33_session03_package_review_BUILD.json')])
    finally:sys.argv=oldargv
    report=enc(dict(status='FINAL_SESSION_EXPLICIT_TYPE_AND_ROUTER_RECEIVER_SOURCE_RESIDUAL_NOT_STAGED',freeze=dict(path=prefix+'mechanical_ready_whole_inverse_NOT_STAGE.json',sha256=sha(fr)),runtime=freeze['runtime']['candidate'],code_inverse=dict(path=S+'dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json',sha256=depssha),derived_generators=[ordinary_generator,dependency_generator,input_generator],original139_all_exact=True,formal24c_only_parent=True,all_old_FAIL_and_source_only_stages_preserved=True,engine_calls=0,Stage_calls=0,canonical_writes=0))
    dest=HERE/'session03_final_build_handoff_NOT_STAGE.json'
    with dest.open('xb') as stream:stream.write(report)
    print(json.dumps(dict(handoff_path=S+dest.name,handoff_sha256=sha(report),freeze_sha256=sha(fr),runtime_sha256=rh,code_inverse_sha256=depssha)))
if __name__=='__main__':main()
