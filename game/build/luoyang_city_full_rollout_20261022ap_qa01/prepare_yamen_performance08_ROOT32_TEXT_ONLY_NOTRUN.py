"""NEW08 text freezer; requires real post-deployment authorities supplied by Root.
No Stage, Godot, collector, native or image operations. Do not run before Root31
deployment and Root32 fresh-before have actually completed.
"""
import argparse
import copy
import difflib
import hashlib
import json
from pathlib import Path

GAME=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
SF=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
OUT=QA/'yamen_performance08_ROOT32_READY'
def rp(p):return 'res://'+p.relative_to(GAME).as_posix()
def res(s):return GAME/s.removeprefix('res://')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def fixed(p,digest):
    assert sha(p)==digest.lower(),str(p)
    return {'path':rp(p),'sha256':digest.lower()}
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--final-guard-sha',required=True)
    ap.add_argument('--copy-sha',required=True)
    ap.add_argument('--fresh-before-sha',required=True)
    ap.add_argument('--formal-revision',required=True)
    args=ap.parse_args()
    assert not OUT.exists()
    oldkey=QA/'yamen_performance07_ROOT30_READY/test_yamen_performance07_ROOT30_READY.gd'
    oldfixture=QA/'yamen_performance07_ROOT30_READY/yamen_performance07_fixture_ROOT30_READY.json'
    parentkey=fixed(oldkey,'85e3d80b8c97d156a0db71764cb8010a85b0149b6949b0e8f6c3d9065caf3f7e')
    fixed(oldfixture,'2359b30bd2be613830fea3ac5a27dddc786e55f8e74b4f95c25ac7b423d0a5e5')
    ownerfile=SF/'performance43_culture_actual_independent_review/owner_source_maps_READY.json'
    ownerdesc=fixed(ownerfile,'544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0')
    stagefile=SF/'outputs/root_culture_C_source_repair_stage01/receipt.json'
    stagedesc=fixed(stagefile,'5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e')
    guarddesc=fixed(ROOT/'integration31/final_guard.json',args.final_guard_sha)
    copydesc=fixed(ROOT/'integration31/generated_JSON_deployment_actual.json',args.copy_sha)
    freshdesc=fixed(ROOT/'integration32/guard_before.json',args.fresh_before_sha)
    owner,stage=read(ownerfile),read(stagefile)
    guard,copies=read(res(guarddesc['path'])),read(res(copydesc['path']))
    fresh=read(res(freshdesc['path']))
    assert guard['passed']and guard['checked']==2118 and guard['authorized_change_count']==24 and guard['exact_unchanged']==2094 and guard['save_count']==15 and guard['save_change_count']==guard['unexpected_change_count']==0
    assert fresh['mode']=='before' and fresh['checked']==2118 and fresh['save_count']==15
    assert copies['GD_copied']==0 and copies['native_or_save_writes']==0 and len(copies['rows'])==14
    assert owner['actual_stage_receipt']==stagedesc and owner['fixed_prior_owner_sha256']=='b2858260460afe9c655fdd0eca0b2408f11267e1aa313d23b0ee4ccbee0a1d0c'
    targets={r['target']:r for r in stage['targets']};assert len(targets)==24
    for path,row in targets.items():
        assert sha(res(path))==row['candidate_sha256'] and res(path).stat().st_size==res(row['candidate_path']).stat().st_size
    yamen=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen')
    assert len(yamen['source_sha256'])==1239 and yamen['source_sha256']==yamen['receipt_source_sha256']
    old=read(oldfixture);fixture=copy.deepcopy(old);table=dict(old['source_sha256'])
    for path,value in owner['core_source_sha256'].items():
        if path in table:table[path]=value
    table.update(yamen['source_sha256'])
    oldauth=old['authority']
    authority_replacements=[(oldauth['independent_owner'],ownerdesc),(oldauth['actual_source_stage'],stagedesc),(oldauth['actual_Root_deployment_guard'],guarddesc),(oldauth['actual_Root_deployment_copy'],copydesc),(oldauth['Root30_fresh_before'],freshdesc)]
    for a,b in authority_replacements:
        assert table.pop(a['path'])==a['sha256'] and b['path']not in table
        table[b['path']]=b['sha256']
    oldancestor=SF/'performance28_yamen_light06_ROOT26/test_yamen_performance06_ROOT26_READY.gd'
    assert table.pop(rp(oldancestor))=='6b5989d7401425ad138a8bdbc9b0fd7d8ce7b6e07b225a2566cae3d32ec053d5'
    assert parentkey['path']not in table;table[parentkey['path']]=parentkey['sha256']
    fixture.update(status=args.formal_revision+'_ROOT32_PERFORMANCE08_ONE_DEFAULT_YAMEN_SAME_SIX_DT_CHILDREN_READY_NOT_RUN',ready=True,blockers=[],pending_authority_not_in_source_guard_until_real_freeze=False,source_sha256=table,expected_city_source_sha256=dict(yamen['source_sha256']),owner_path=ownerdesc['path'])
    fixture['authority']={'fixed_prior_owner':oldauth['independent_owner'],'independent_owner':ownerdesc,'actual_source_stage':stagedesc,'actual_Root_deployment_guard':{**guarddesc,'pending':False},'actual_Root_deployment_copy':{**copydesc,'pending':False},'Root32_fresh_before':freshdesc,'formal_revision':args.formal_revision,'guard_count_boundary':'Root31 checked2118:24 authorized source-only targets+2094 exact unchanged;15save exactticks0. No inherited2117 label reinterpretation.'}
    fixture['expected_source_count_recipe']={'fixedB285':1234,'five_new_declared_proof_leaves':5,'expected_count':1239,'actual_independent_owner_count_confirmed':1239,'not_actual_collector_observation':True}
    fixture['guard_derivation']='Fixed07 guarded table; explicit5448 core replacement only on existing keys plus all1239 independent Yamen source values. Replace five authority leaves with actual5448/5B455/Root31guard-copy/Root32before and06QAancestor with immutable07parent. No current-source hashes used to generate runtime expectations.'
    assert fixture['whole_ms']==60000 and fixture['public_requests']==1 and fixture['max_pictures']==0
    assert fixture['required_DT_projection_children']==old['required_DT_projection_children']and len(fixture['required_DT_projection_children'])==6
    assert fixture['scene_path']==yamen['scene_path']and fixture['layout_path']==yamen['layout_path']
    keypath=OUT/'test_yamen_performance08_ROOT32_READY.gd';fixturepath=OUT/'yamen_performance08_fixture_ROOT32_READY.json'
    fb=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode();fs=hashlib.sha256(fb).hexdigest()
    text=oldkey.read_bytes().decode();hunks=[]
    def change(a,b):
        nonlocal text
        assert text.count(a)==1,a
        text=text.replace(a,b,1);hunks.append({'old':a,'new':b})
    change('const FIXTURE="'+rp(oldfixture)+'"','const FIXTURE="'+rp(fixturepath)+'"')
    change('const FIXTURE_SHA="'+sha(oldfixture)+'"','const FIXTURE_SHA="'+fs+'"')
    change('fixture.expected_city_source_sha256.size()==1234','fixture.expected_city_source_sha256.size()==1239')
    change('Fixed60s/0pictures/one default public entry/source1234','Fixed60s/0pictures/one default public entry/source1239')
    change('Natural full1234 source map equals independent merged AP15 owner','Natural full1239 source map equals independent culture-source repaired owner')
    change('res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_performance07_ROOT30_READY/output/%d_%d','res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_performance08_ROOT32_READY/output/%d_%d')
    text=text.replace('PERF07','PERF08')
    inverse=text.replace('PERF08','PERF07')
    for h in reversed(hunks):
        assert inverse.count(h['new'])==1
        inverse=inverse.replace(h['new'],h['old'],1)
    assert inverse.encode()==oldkey.read_bytes()
    kb=text.encode();assert kb.count(b'district.call("loading_timing_state")')==1 and kb.count(b'go_field_smart')==1 and b'const WHOLE_MS=60000'in kb
    # No observed source values, no engine, no preflight sourcecollector.
    assert all(table[p]==v for p,v in yamen['source_sha256'].items())
    assert not OUT.exists();OUT.mkdir()
    fixturepath.write_bytes(fb);keypath.write_bytes(kb)
    kd=OUT/'complete_key_vs07.diff';fd=OUT/'complete_fixture_vs07.diff'
    kd.write_text(''.join(difflib.unified_diff(oldkey.read_text(encoding='utf-8').splitlines(keepends=True),text.splitlines(keepends=True),fromfile=rp(oldkey),tofile=rp(keypath))),encoding='utf-8',newline='')
    fd.write_text(''.join(difflib.unified_diff(oldfixture.read_text(encoding='utf-8').splitlines(keepends=True),fb.decode().splitlines(keepends=True),fromfile=rp(oldfixture),tofile=rp(fixturepath))),encoding='utf-8',newline='')
    hand={'status':'ROOT32_PERFORMANCE08_READY_NOT_RUN_NOT_PARSE_PASS','key':{'path':rp(keypath),'sha256':sha(keypath)},'fixture':{'path':rp(fixturepath),'sha256':sha(fixturepath)},'parent07':parentkey,'whole_byte_reverse_to07':True,'only_hunks_before_PERF07_to08_label_change':hunks,'owner_expected1239':ownerdesc,'actual_stage':stagedesc,'guard_count':len(table),'authority_replacements':authority_replacements,'Root31_guard':guarddesc,'Root31_copy':copydesc,'Root32_before':freshdesc,'fixed_body_cadence_single_DTgetter_six_children_60s_noINPUT_image_geometry_collector':True,'source_expectations_only_independent_recipe_not_currentfill':True,'formal24_current_SHA_bytes_exact':True,'preserve07_failure_and_true_C0000005':True,'diffs':{'key':{'path':rp(kd),'sha256':sha(kd)},'fixture':{'path':rp(fd),'sha256':sha(fd)}},'engine_parse_Stage_collector_native_decode_formal_writes':0}
    hp=OUT/'handoff_ROOT32_READY_NOT_RUN.json';hp.write_text(json.dumps(hand,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'key':hand['key'],'fixture':hand['fixture'],'handoff':{'path':rp(hp),'sha256':sha(hp)},'guard_count':len(table)}))
if __name__=='__main__':main()
