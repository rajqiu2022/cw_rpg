"""Root-only text preparation. Requires real exact18 Stage AND deployment.
No engine, Stage constructor, collector, native/media reads, or current fill.
"""
from pathlib import Path
import argparse, copy, hashlib, json, re, difflib

Q=Path(__file__).resolve().parent
GAME=Q.parent.parent
OLD=Q/'root_market_journey27_packed_READY'
OLD_KEY_SHA='88cdd5db084d1f061ba02a128ca2da75788adaa0e03f7d529899161ca84a1a7f'
OLD_FIXTURE_SHA='1b01bc527ae77f585faf61c3187ab1b9e237da87bd7239ed60fb2b00185ea317'

def need(value,reason):
    if not value: raise ValueError(reason)
def sha(raw): return hashlib.sha256(raw).hexdigest()
def encoded(value): return (json.dumps(value,ensure_ascii=True,indent=2)+'\n').encode('ascii')
def resolve(p):
    result=(GAME/p[6:] if p.startswith('res://') else Path(p)).resolve()
    need(result.is_relative_to(GAME.resolve()),'ONLY_PINNED_INPUT_INSIDE_GAME');return result
def res(p): return 'res://'+p.resolve().relative_to(GAME.resolve()).as_posix()
def fixed(p,h):
    need(type(h) is str and re.fullmatch('[0-9a-fA-F]{64}',h),'REAL_FULL_SHA_REQUIRED')
    p=resolve(p);raw=p.read_bytes();need(sha(raw)==h.lower(),'EXACT_FIXED_INPUT:'+str(p))
    return p,raw,json.loads(raw)

def freeze(args):
    out=resolve(args.output_directory)
    need(out.is_relative_to(Q.resolve()) and out!=Q.resolve() and not out.exists(),'NEW_QA_DIRECTORY_ONLY')
    sp,sraw,stage=fixed(args.stage_receipt_path,args.stage_receipt_sha256)
    dp,draw,deploy=fixed(args.deployment_receipt_path,args.deployment_receipt_sha256)
    need(stage.get('status')=='MARKET_DIALOGUE_EXACT18_STAGED_NOT_DEPLOYED','REAL_EXACT18_STAGE_STATUS')
    need(stage.get('target_partition')=={'patch_count':7,'copy_count':11,'total':18},'EXACT18_7GD11JSON')
    need(stage.get('source_first') and stage['source_first']==stage.get('source_final'),'STAGE_DECLARED_FIRST_FINAL_SAME_NO_RESCAN')
    targets=stage.get('targets',[]);need(len(targets)==18,'STAGE18_TARGETS')
    need(deploy.get('passed') is True and deploy.get('status')=='ROOT_EXACT18_DEPLOYED_FIRST_FINAL_VERIFIED','REAL_DEPLOYMENT_REQUIRED_BEFORE_ANY_OUTPUT')
    bound=deploy.get('stage',{})
    need(resolve(bound.get('path',''))==sp and bound.get('sha256')==sha(sraw),'DEPLOYMENT_BINDS_EXACT_STAGE')
    need(deploy.get('target_count')==18 and deploy.get('partition')=={'apply_patch_GD':7,'exact_copy_JSON':11},'REAL18_PARTITION')
    approved={row['target']:row for row in targets};seen=set()
    need(len(approved)==18 and len(deploy.get('targets',[]))==18,'NO_DUPLICATE_OR_MISSING_TARGET')
    for row in deploy['targets']:
        need(set(row)=={'target','old_sha256','candidate_path','candidate_sha256','actual_sha256','bytes'},'EXACT_RETAINED_TARGET_SCHEMA')
        target=row['target'];need(target in approved and target not in seen,'EXACT_UNIQUE_DEPLOYED_TARGET');seen.add(target)
        old=approved[target]
        need(row['old_sha256']==old['old_sha256'] and resolve(row['candidate_path'])==resolve(old['candidate_path']) and row['candidate_sha256']==row['actual_sha256']==old['candidate_sha256'],'ACTUAL_TARGET_EXACT_STAGE_CANDIDATE')
        need(type(row['bytes']) is int and row['bytes']>0,'REAL_TARGET_BYTE_COUNT')
    need(seen==set(approved),'EXACT18_TARGET_SET')
    node=stage['nodes']['expected_ch4_s3_luoyang_market_true']
    mp,mraw,declared=fixed(node['path'],node['sha256'])
    need(declared==node['value'] and declared.get('scene_id')=='ch4_s3_luoyang_market','FIXED_STAGE_MAP_VALUE')
    sources=declared.get('source_sha256');need(type(sources) is dict and len(sources)>0,'FIXED_INDEPENDENT_SOURCE_MAP')
    need(all(type(p) is str and p.startswith('res://') and '..' not in p and type(h) is str and re.fullmatch('[0-9a-f]{64}',h) for p,h in sources.items()),'DECLARED_PATH_SHA_DOMAIN')
    _,_,original=fixed(res(OLD/'fixture_READY.json'),OLD_FIXTURE_SHA)
    need(original['expected_city_count']==1813 and len(original['expected_city_sources'])==1813,'LATEST1813_FIXTURE_NOT_OLD1808')
    need((original['whole_ms'],original['entry_ms'],original['max_pictures'])==(60000,20000,3),'ORIGINAL60_20_3PNG')
    fixture=copy.deepcopy(original)
    fixture.update(expected_city_sources=copy.deepcopy(sources),expected_city_count=len(sources),
        independent_owner={'path':res(mp),'sha256':sha(mraw),'kind':'ACTUAL_SOURCE_STAGE_INDEPENDENT_MAP_NOT_COLLECTOR'},
        stage_receipt={'path':res(sp),'sha256':sha(sraw)},deployment_actual={'path':res(dp),'sha256':sha(draw)},
        previous_fixture_provenance={'path':res(OLD/'fixture_READY.json'),'sha256':OLD_FIXTURE_SHA,'expected_city_count':1813,
          'key_path':res(OLD/'test_READY.gd'),'key_sha256':OLD_KEY_SHA,'parent_provenance':original['previous_fixture_provenance'],'prior_failures_preserved':True})
    delta={}
    for p,h in list(fixture['source_sha256'].items()):
        if p in sources and sources[p]!=h:
            delta[p]={'old':h,'new':sources[p]};fixture['source_sha256'][p]=sources[p]
    extra={res(sp):sha(sraw),res(dp):sha(draw),res(mp):sha(mraw)}
    for p,h in extra.items():
        need(p not in fixture['source_sha256'],'NEW_RECEIPT_GUARD_ONLY');fixture['source_sha256'][p]=h
    restored=copy.deepcopy(fixture)
    for p in extra: del restored['source_sha256'][p]
    for p,row in delta.items(): restored['source_sha256'][p]=row['old']
    for field in ['expected_city_sources','expected_city_count','independent_owner','stage_receipt','deployment_actual','previous_fixture_provenance']: restored[field]=original[field]
    need(restored==original and encoded(restored)==encoded(original),'FULL_FIXTURE_TYPED_AND_SERIALIZED_INVERSE')
    oldkey=(OLD/'test_READY.gd').read_bytes();need(sha(oldkey)==OLD_KEY_SHA,'EXACT88CDD_KEY')
    need(b'"",-1,C.VERSION)' in oldkey,'CURRENT_COORDINATE_VERSION_RETAINED')
    fx=encoded(fixture)
    ops=[(res(OLD/'fixture_READY.json').encode(),res(out/'fixture_READY.json').encode()),(OLD_FIXTURE_SHA.encode(),sha(fx).encode()),(res(OLD/'output_READY').encode(),res(out/'output_READY').encode())]
    key=oldkey
    for before,after in ops:
        need(key.count(before)==1,'EXACT_THREE_LITERALS');key=key.replace(before,after,1)
    inverse=key
    for before,after in reversed(ops):
        need(inverse.count(after)==1,'EXACT_THREE_LITERAL_INVERSE');inverse=inverse.replace(after,before,1)
    need(inverse==oldkey,'WHOLE_KEY_BYTES_AND_EOF_UNCHANGED_OUTSIDE3LITERALS')
    proof={'status':'EXACT18_RECEIPTS_LATEST1813_JOURNEY_MECHANICAL_FREEZE_NOT_RUN','key_sha256':sha(key),'fixture_sha256':sha(fx),
      'expected_city_count':len(sources),'source_guard_count':len(fixture['source_sha256']),'key_three_literal_wholebyte_inverse_including_EOF':True,
      'fixture_wholetyped_serialized_inverse':True,'guard_existing_value_delta':delta,'new_receipt_guards':extra,
      'routes_Task_decline_60s_20s_3PNG_functions_unchanged':True,'C_VERSION_retained':True,'current_fill_collector_engine_Stage_media_reads':False}
    outputs={'test_READY.gd':key,'fixture_READY.json':fx,'freeze_inverse_READY_NOTRUN.json':encoded(proof),
      'complete_vs_88CDD.diff':''.join(difflib.unified_diff(oldkey.decode().splitlines(True),key.decode().splitlines(True),fromfile=res(OLD/'test_READY.gd'),tofile=res(out/'test_READY.gd'))).encode()}
    out.mkdir()
    for name,raw in outputs.items():
        with (out/name).open('xb') as stream: stream.write(raw)
    print(json.dumps({'output':res(out),'key_sha256':sha(key),'fixture_sha256':sha(fx),'proof_sha256':sha(outputs['freeze_inverse_READY_NOTRUN.json']),'expected_city_count':len(sources)}))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    for name in ['stage-receipt-path','stage-receipt-sha256','deployment-receipt-path','deployment-receipt-sha256','output-directory']: parser.add_argument('--'+name,required=True)
    freeze(parser.parse_args())


