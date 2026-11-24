"""After REAL isolated import only: freeze proof, approval candidate and54 plan.
Never runs engine, copies media, activates resolver or changes canonical files.
"""
from pathlib import Path
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04'
ISOLATE=OUT/'isolate_ROOT_PREPARED'
MANIFEST=OUT/'world18_joint_ingress_CANDIDATE.json';MSHA='392e3f5e567f50bfd2c48867bc91f315d2177dc62ab4cef670c613fea32612c4'
CAPTURE=OUT/'actual_joint_export_compact_receipt.json';CSHA='6afe7ad022eda99286ed76d1c687c1d9a3cd2ad45b33deec26eec02c4cdc1ffd'
PROMOTER=OUT/'promote_world18_media54_ROOT_ONLY.ps1';PSHA='a836f90cb39b989c1c749a3076e349ea02c671dd7624a2e67e364a6dca2c33e8'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def new(p,b):
    assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as h:h.write(b)
def fact(p):
    if not p.exists():return {'exists':False}
    s=p.stat();return {'exists':True,'sha256':sha(p),'bytes':s.st_size,'ticks':str(s.st_mtime_ns//100+621355968000000000)}
def res(p):return 'res://'+p.relative_to(ROOT/'game').as_posix()
def freeze(p,pin):
    p=Path(p).resolve();assert len(pin)==64 and sha(p)==pin.lower(),p
    return p,{'path':str(p),'sha256':pin.lower()}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--import-result');ap.add_argument('--import-result-sha256');ap.add_argument('--prepared-sha256');ap.add_argument('--import-process-receipt');ap.add_argument('--import-process-sha256');ap.add_argument('--verify-process-receipt');ap.add_argument('--verify-process-sha256');a=ap.parse_args()
    assert sha(MANIFEST)==MSHA and sha(CAPTURE)==CSHA and sha(PROMOTER)==PSHA
    if not a.import_result:
        print(json.dumps({'status':'FINALIZER_STATIC_CANDIDATE_REQUIRES_REAL_IMPORT_AND_TWO_NATURAL_PROCESS_RECEIPTS','builder_sha256':sha(SELF),'media18':True,'leaves54':True,'canonical_copy':0,'engine':0}));return
    resultpath,resultpin=freeze(a.import_result,a.import_result_sha256);assert resultpath.is_relative_to(ISOLATE)
    preparedpath,preparedpin=freeze(ISOLATE/'prepared_READY.json',a.prepared_sha256)
    importpath,importpin=freeze(a.import_process_receipt,a.import_process_sha256);verifypath,verifypin=freeze(a.verify_process_receipt,a.verify_process_sha256)
    processpins=[importpin,verifypin]
    for p in [importpath,verifypath]:
        r=read(p);assert r['actual_natural_console_exit_code']==0 and r['retained_process_WaitForExit'] is True and r['stopped_by_tool'] is False and r['main_promotion'] is False
        assert r['all15_save_exists_SHA_bytes_exactticks_unchanged'] is True and r['original_absent_saves_still_absent_after'] is True
    prep=read(preparedpath);preparation=read(ISOLATE/'preparation_receipt.json')
    assert preparation['prepared_sha256']==a.prepared_sha256.lower() and sha(ISOLATE/'verify_READY.gd')==preparation['verifier_sha256']
    result=read(resultpath);ingress=read(MANIFEST)
    assert result['passed'] is True and not result['failures'] and result['elapsed_ms']<30000 and result['prepared_sha256']==a.prepared_sha256.lower()
    assert result['scope']=='EXACT_JOINT18_NATIVE_WORLD_EXPORTS_ISOLATED_FULL_RGBA_NOT_RUNTIME' and len(result['rows'])==18
    assert prep['status']=='EXACT_JOINT_WORLD18_ISOLATED_IMPORT_PREPARED' and prep['textures']==ingress['textures']
    expected={r['png']:r for r in ingress['textures']};seen=set();normalized=[];leaves=[]
    for r in result['rows']:
        p=r['png'];assert p in expected and p not in seen;seen.add(p);e=expected[p]
        assert r['png_sha256']==e['png_sha256'] and r['decoded_RGBA_sha256']==e['decoded_RGBA_sha256'] and r['size']==e['source_size']
        assert r['full_RGBA_exact'] is True and r['mipmaps']==0 and r['params23'] is True and r['detect_3d_compress_to']==0
        assert r['sidecar']==e['sidecar'] and r['compiled']==e['compiled']
        for k,pin in [('png',r['png_sha256']),('sidecar',r['sidecar_sha256']),('compiled',r['compiled_sha256'])]:
            src=ISOLATE/e[k][6:];dst=ROOT/('game/'+e[k][6:])
            assert sha(src)==pin and not dst.exists(),dst
            leaves.append({'kind':k,'source':str(src.resolve()),'target':str(dst.resolve()),'sha256':pin,'bytes':src.stat().st_size})
        normalized.append({'path':p,'source_sha256':r['png_sha256'],'size':r['size'],'full_RGBA_exact':True,'mipmap_count':0,'import_path':r['sidecar'],'import_sha256':r['sidecar_sha256'],'compiled_path':r['compiled'],'compiled_sha256':r['compiled_sha256'],'decoded_RGBA_sha256':r['decoded_RGBA_sha256'],'native_verifier_row_domain':r['domain']})
    assert len(seen)==18 and len(leaves)==54 and len({r['target'] for r in leaves})==54
    proof={'passed':True,'scope':'ACTUAL_JOINT18_LOSSLESS_FULL_RGBA_IMPORT_NOT_RUNTIME','coherent_export_receipt_sha256':CSHA,'actual_import_result':{'path':res(resultpath),'sha256':sha(resultpath)},'actual_import_process_receipts':processpins,'prepared_sha256':a.prepared_sha256.lower(),'rows':normalized,'promotion_or_runtime_credit':False}
    proofpath=OUT/'actual_joint18_import_compact_proof.json';new(proofpath,enc(proof))
    schema=read(OUT.parent/'approved_visual_manifest_SCHEMA_NOTREADY.json')
    schema['coherent_export_receipt']={'path':res(CAPTURE),'sha256':CSHA};schema['import_proof']={'path':res(proofpath),'sha256':sha(proofpath)}
    for entry in schema['entries']:
        entry['sha256']=expected[entry['path']]['png_sha256'];entry['status']='ACTUAL_NATIVE_MEMBER_AND_LOSSLESS_IMPORT_VERIFIED_ROOT_ACTIVATION_PENDING'
    schema['chunk']['sha256']=expected[schema['chunk']['path']]['png_sha256'];assert schema['chunk']['sha256']=='bf90b660f27990f206b86b351b78da3a4171af1123f3912542f8bb7758d94a00'
    schema['approved']=False;schema['approved_by']=None;schema['root_activation_pending']=True
    approval=OUT/'approved_visual_manifest_CANDIDATE.json';new(approval,enc(schema))
    protected=dict(prep['protected_main_sources'])
    protected.update(prep['all15_save_facts'])
    inputs=[MANIFEST,CAPTURE,PROMOTER,SELF,preparedpath,ISOLATE/'preparation_receipt.json',ISOLATE/'verify_READY.gd',resultpath,importpath,verifypath,proofpath,approval]
    for p in inputs:protected[str(p.resolve())]=fact(p)
    for p,v in protected.items():assert fact(Path(p))==v,p
    fixed=[{'path':str(p.resolve()),'sha256':sha(p)} for p in inputs]
    plan={'status':'WORLD18_NEW_MEDIA54_MECHANICAL_PROMOTION_CANDIDATE_NOT_EXECUTED','builder_sha256':PSHA,'plan_builder_sha256':sha(SELF),'prepared_sha256':a.prepared_sha256.lower(),'ingress_manifest_sha256':MSHA,'import_result_path':str(resultpath),'import_result_sha256':sha(resultpath),'process_receipts':processpins,'fixed_inputs':fixed,'leaves':leaves,'protected_before':protected,'canonical_functional_GD_JSON_active_index_mutations':0,'runtime_activation':False,'all54_targets_ABSENT':True,'Root_only':True}
    planpath=OUT/'world18_media54_promotion_plan_CANDIDATE.json';new(planpath,enc(plan))
    print(json.dumps({'status':plan['status'],'plan_sha256':sha(planpath),'import_proof_sha256':sha(proofpath),'approval_candidate_sha256':sha(approval),'promoter_sha256':PSHA,'leaf_count':54,'engine':0,'media_copy':0,'formal_write':0,'approved':False}))
if __name__=='__main__':main()
