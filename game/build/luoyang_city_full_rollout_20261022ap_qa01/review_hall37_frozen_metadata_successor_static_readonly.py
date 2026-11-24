"""Validate frozen texts only, no Godot/parse/collector or production writes."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
P=QA/'hall_roundtrip_ROOT34_READY';D=QA/'hall_roundtrip_ROOT37_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return'res://'+p.relative_to(GAME).as_posix()
kp=D/'test_hall_roundtrip_ROOT37_READY.gd';fp=D/'hall_roundtrip_fixture_ROOT37_READY.json'
pk=P/'test_hall_roundtrip_ROOT34_READY.gd';pf=P/'hall_roundtrip_fixture_ROOT34_READY.json'
assert sha(kp)=='7bff48b256b092179ac3a1046f3698f9c24f5813e18f268e9ae3dd0e6bf65976'
assert sha(fp)=='12eafbc445b9480c5230ced6aa644d211964ab098496892e6489acb17306eaec'
key=kp.read_bytes();back=key
for a,b in [(rel(fp),rel(pf)),(sha(fp),sha(pf)),('hall_roundtrip_ROOT37_READY/output/','hall_roundtrip_ROOT34_READY/output/')]:
    assert back.count(a.encode())==1;back=back.replace(a.encode(),b.encode(),1)
assert back==pk.read_bytes()
old,new=rd(pf),rd(fp)
assert new['ready'] is True and new['whole_ms']==60000 and new['entry_ms']==new['room_ms']==20000 and new['return_ms']==10000 and new['max_pictures']==0
op=S/'performance49_estate17_actual_independent_review/owner_source_maps_READY.json'
assert sha(op)=='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'
owner=rd(op);expected_city=next(x for x in owner['scenes']if x['id']=='ch4_s1_luoyang_yamen')['source_sha256']
assert new['expected_city_sources']==expected_city and len(expected_city)==1239
assert new['expected_G_global_sources']==owner['rooms'][0]['source_sha256'] and len(new['expected_G_global_sources'])==557
assert set(new['expected_city_sources'])==set(old['expected_city_sources'])and set(new['expected_G_global_sources'])==set(old['expected_G_global_sources'])
stage=rd(S/'outputs/root_estate_registry_scalar17_stage01/receipt.json');tr={x['target']:x for x in stage['targets']}
assert len(tr)==17 and len(new['source_sha256'])==1308
for path,digest in old['source_sha256'].items():
    assert new['source_sha256'][path]==(tr[path]['candidate_sha256']if path in tr else digest)
for path,row in tr.items():assert new['source_sha256'][path]==row['candidate_sha256']
for table in [new['expected_city_sources'],new['expected_G_global_sources']]:
    assert all(new['source_sha256'][p]==h for p,h in table.items())
assert len(set(new['source_sha256'])-set(old['source_sha256']))==11
assert rel(kp)not in new['source_sha256']and rel(fp)not in new['source_sha256']
for k in old:
    if k not in ['status','source_sha256','expected_city_sources','expected_G_global_sources','authority','guard_derivation','predicate_successor']:
        assert old[k]==new[k]
assert new['hall_row']==old['hall_row']and len(new['hall_row']['source_sha256'])==247
assert new['historical_DT_successor']==old['historical_DT_successor']
for k,v in old['predicate_successor'].items():
    if k not in ['guard_scope','external_tasks']:assert new['predicate_successor'][k]==v
for name,authority in new['authority'].items():
    p=GAME/authority['path'][6:]
    if name!='actual_scalar17_stage':assert sha(p)==authority['sha256']
assert new['authority']['actual_scalar17_stage']['sha256']=='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'
assert new['authority']['formal_Root36_after']['sha256']=='f3fd504e22d186b6196130dd641aa336ef50f8df69d32a43ef599e2d520ce6e8'
assert new['authority']['Root37_before']['sha256']=='9ee556050a801c987ffee6f5781cf2dc5af47f9b114f61ed184847f388d99479'
out=D/'independent_metadata_only_static_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT37_FROZEN_METADATA_ONLY_STATIC_NO_BLOCKER_ROOT_ONLY_ACTUAL_DECISION','key':{'path':rel(kp),'sha256':sha(kp)},'fixture':{'path':rel(fp),'sha256':sha(fp)},'exact_changes':{'key_two_fixture_literals_and_output_directory_only':True,'all_functions_byteidentical_toROOT34':True,'guard1308':True,'all17_deployed_values_explicit_96CA':True,'old1297allkept_only17values_migrated':True,'11new_fixed_provenance_leaves_not_runtimekeys':True,'expected1239_557_fixed5857_whole_equal_no_keychanges':True,'historicalhall247whole_unchanged':True,'Root36actual_and37fresh_bound':True,'no_expected_values_from_livecollector_or_observednodes':True},'scope':{'whole_ms':60000,'entry_ms':20000,'room_ms':20000,'return_hidden_operable_target_ms':10000,'screenshots':0,'one_public_near_setup':True,'real2INPUT2Space':True,'sameWeakRef_objects_park512MiB_resumed_hit_READY_and_exactauthorfoot_unchanged':True,'557only_independentguard_not_sessionFIRSTFINAL':True},'preserved':['hall33/34wholeFAIL/nohallnowverified','35guardFAIL beforewrites no retroactiveauthorization','trueC0000005 exit history'],'operations':{'engine':0,'parse':0,'collector':0,'geometry':0,'Stage':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':rel(out),'sha256':sha(out),'key_lines':len(key.splitlines()),'guard_count':1308}))
