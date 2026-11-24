"""Freeze fixed30 promotion plan. Read-only media and all fixed proofs; no copies."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
ISO=OUT/'ten_media_isolate_ROOT_PREPARED';GAME=ROOT/'game'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def obj(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def fact(p):
    if not p.exists():return {'exists':False}
    s=p.stat();return {'exists':True,'sha256':sha(p),'bytes':s.st_size,'ticks':str(s.st_mtime_ns//100+621355968000000000)}
inputs=[
 (OUT/'ten_media_ingress01_CANDIDATE.json','a94d4cbb8d14cd6921be335e42c74b6a27ad0325ff9d6c11b0ee3dbe466ccffc'),
 (ISO/'prepared_READY.json','061081ea928e7d195cd2196b589f1bf974f91a3bae46c30b5f0123600a55f960'),
 (ISO/'ten_media_import_result_104068.json','8bd65246c0818432da0e6cd6f234abe260aa7647d81e4699b7efdf9c4b26d8d4'),
 (OUT/'ten_media_import_logs_ROOT_ONLY/external_import_actual_process_receipt.json','fe5cf975af85d2caa92cd7eb9f97f5dd30e87e2af4b058bafd0da1a1f3f8b681'),
 (OUT/'ten_media_import_logs_ROOT_ONLY/external_verify_actual_process_receipt.json','5b7b004cfba1d9e23db5421ac7b4ce7349f6c3802437b5418dee3d3e9c70d3d5')]
for p,pin in inputs:assert sha(p)==pin
ingress=obj(inputs[0][0]);spec=obj(inputs[1][0]);actual=obj(inputs[2][0])
assert actual['passed'] and not actual['failures'] and actual['source_first']==actual['source_final'] and len(actual['rows'])==10
assert len(spec['textures'])==10
leaves=[]
for item,row in zip(ingress['textures'],actual['rows']):
    assert item['domain']==row['domain'] and item['png_sha256']==row['png_sha256'] and item['decoded_RGBA_sha256']==row['decoded_RGBA_sha256']
    assert row['full_RGBA_exact'] and row['params23'] and row['mipmaps']==0 and row['detect_3d_compress_to']==0
    for kind in ['png','sidecar','compiled']:
        res=row[kind];assert res==item[kind] and res.startswith('res://') and '..' not in res
        source=ISO/res[6:];target=GAME/res[6:];pin=row[kind+'_sha256']
        assert sha(source)==pin and not target.exists()
        leaves.append({'domain':row['domain'],'kind':kind,'res':res,'source':str(source.resolve()),'target':str(target.resolve()),'sha256':pin,'bytes':source.stat().st_size})
assert len(leaves)==30 and len({r['target'] for r in leaves})==30
builder=OUT/'promote_ten_media30_ROOT_ONLY.ps1'
old=ROOT/'game/build/luoyang_garden_river_20261025h_source01/promote_garden_walk_two_NOTRUN.ps1'
assert sha(old)=='f68538f5d884e8056292188b1edd6996fc823f9ad2707d9a4d4bb1b7d2d9a6f9'
protected={}
def keep(p):protected[str(p.resolve())]=fact(p)
for p,pin in inputs:keep(p)
keep(builder);keep(old)
for p in spec['protected_main_sources']:keep(Path(p))
for r in ingress['raw_originals_11']:
    p=ROOT/r['path'];assert sha(p)==r['fixed_original_sha256'];keep(p)
for r in leaves:keep(Path(r['source']))
for p in spec['save_paths']:keep(Path(p))
for key,v in actual['source_first'].items():
    p=ISO/key[6:] if key.startswith('res://') else Path(key)
    f=fact(p);assert f['exists'] and f['sha256']==v['sha256'] and f['bytes']==v['bytes'];keep(p)
for phase in ['import','verify']:
    receipt=obj(OUT/f'ten_media_import_logs_ROOT_ONLY/external_{phase}_actual_process_receipt.json')
    assert receipt['actual_natural_console_exit_code']==0 and receipt['retained_process_WaitForExit'] and not receipt['stopped_by_tool']
    for stream in ['stdout','stderr']:
        p=OUT/f'ten_media_import_logs_ROOT_ONLY/external_{phase}_actual_{stream}.log';assert sha(p)==receipt[stream+'_sha256'];keep(p)
oldtext=old.read_text(encoding='utf-8');newtext=builder.read_text(encoding='utf-8')
oldstart=oldtext.index(' [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($leaf.target))')
oldend=oldtext.index('\n}',oldstart)
oldloop=oldtext[oldstart:oldend]
# New try wrapper adds one indentation character only; original CreateNew copy+hash+receiptrow retained.
assert oldloop.replace('\n ','\n  ').strip() in newtext
plan={'status':'TEN_NEW_MEDIA30_MECHANICAL_PROMOTION_CANDIDATE_NOT_EXECUTED','builder_sha256':sha(builder),'fixed_inputs':[{'path':str(p.resolve()),'sha256':pin} for p,pin in inputs],'leaves':leaves,'protected_before':protected,'template':{'path':old.relative_to(ROOT).as_posix(),'sha256':sha(old),'mature_copy_loop_identical_except_indentation':True},'scope':'Only exact10PNG+10sidecar+10ctex, CreateNew, all30ABSENT. No existing overwrite/delete/mainimport/functionalGDJSON/activeindex/runtimebinding.','source_and_15save_exactticks_snapshot':True,'warnings':'Retain10rawImage warnings from successful verifier; not clean import claim.','ART_executions':0,'ART_copies':0,'engine_calls':0}
out=OUT/'ten_media30_promotion_plan01_CANDIDATE.json';assert not out.exists()
with out.open('xb') as f:f.write((json.dumps(plan,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'plan_path':out.relative_to(ROOT).as_posix(),'plan_sha256':sha(out),'builder_sha256':sha(builder),'leaves':30,'protected':len(protected),'save_paths':len(spec['save_paths']),'copies':0,'engine':0}))
