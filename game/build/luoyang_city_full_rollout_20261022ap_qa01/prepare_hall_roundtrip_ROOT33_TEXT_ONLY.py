"""Freeze NEW single-hall test text and independent fixed source expectations."""
from pathlib import Path
import copy,difflib,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
SF=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
OUT=QA/'hall_roundtrip_ROOT33_READY'
assert not OUT.exists()
def rp(p):return 'res://'+p.relative_to(GAME).as_posix()
def res(s):return GAME/s.removeprefix('res://')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def pin(p,s):
    assert sha(p)==s.lower(),str(p)
    return {'path':rp(p),'sha256':s.lower()}
facts_path=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/hall_roundtrip_independent_facts_ap15_epoch01/facts_READONLY_NOT_RUNTIME_READY.json'
facts_pin=pin(facts_path,'868B35DF1D2A537FDECEC6CD717AA232B3C7C4D5B16FFE378082F288FA22DB1D');facts=rd(facts_path)
ownerp=res(facts['fixed_metadata']['owner']['path']);ownerpin=pin(ownerp,'544819C110E16409BAA090FF807FB314E221BB9D853C353EF6171090427326C0');owner=rd(ownerp)
regp=res(facts['fixed_metadata']['registry']['path']);regpin=pin(regp,'F5298B913FBAEFDA2C5F3679223C014C219292A54DF412A8C3F2D96E4F082F28');registry=rd(regp)
authorp=res(facts['fixed_metadata']['hall_author']['path']);authorpin=pin(authorp,'B5622DBE1C8717C83DEDD76D591E5F633A187EC828B9430D72EBA00DD98381F9');author=rd(authorp)
basep=QA/'yamen_performance08_ROOT32_FINAL_READY/yamen_performance08_fixture_ROOT32_READY.json'
pin(basep,'1C113244799813688F0C95FA3775E8867486B92BAEBCF8134D4A2313646667F0');base=rd(basep)
postpin=pin(ROOT/'integration32/final_guard.json','2ECD58B5CA647489EB94725AC88BF1AE060677090FFD77D43A05E37AA94B5BF2')
freshpin=pin(ROOT/'integration33/guard_before.json','E045F6CC06FD48C5CB84B20DDA42F98CB51F9BA7A1527764B2639F1A12EC7A8D')
post=rd(res(postpin['path']));fresh=rd(res(freshpin['path']))
assert post['passed']and post['checked']==post['exact_unchanged']==2118 and post['save_count']==15 and post['save_change_count']==post['unexpected_change_count']==post['authorized_change_count']==0
assert fresh['checked']==2118 and fresh['mode']=='before'and fresh['save_count']==15
city=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen')
globalG=owner['rooms'][0]['source_sha256'];assert len(city['source_sha256'])==1239 and len(globalG)==557
assert all(r['source_sha256']==globalG for r in owner['rooms'])
hall='luoyang_yamen_official_hall_20261018t';row=registry['rooms'][hall]
assert len(row['source_sha256'])==247 and all(p in globalG for p in row['source_sha256'])
delta=[p for p,s in row['source_sha256'].items()if globalG[p]!=s]
DT='res://scripts/city/luoyang_district_life_20261016f.gd'
assert delta==[DT]and row['source_sha256'][DT]=='bcd4e401303e97cd65075c86c9bba6d08c4b3d542a36a1ec546f73c949670118'and globalG[DT]=='cfb49f34d0bf68ebb6494b5c2e2a5dc3d98c127940d22c8acccc4c6bd680f0d5'
table=dict(base['source_sha256'])
for p,s in globalG.items():
    assert p not in table or table[p]==s
    table[p]=s
oldfresh=base['authority']['Root32_fresh_before'];assert table.pop(oldfresh['path'])==oldfresh['sha256']
for desc in [postpin,freshpin,facts_pin]:
    assert desc['path']not in table;table[desc['path']]=desc['sha256']
oldancestor='res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_performance07_ROOT30_READY/test_yamen_performance07_ROOT30_READY.gd'
assert table.pop(oldancestor)=='85e3d80b8c97d156a0db71764cb8010a85b0149b6949b0e8f6c3d9065caf3f7e'
qa_pins=[pin(QA/'yamen_performance08_ROOT32_FINAL_READY/test_yamen_performance08_ROOT32_FINAL_READY.gd','01E9E50B94AA4CF9B97D4F224938C5E1A98AD8C4328EA7128D9CCD4174D445B3'),pin(GAME/'tests/helpers/v15_input_driver.gd','A3C59FDE8D9F55D71919276286DC720E177EF3DC046D224204868A24881DE5D7'),pin(GAME/'tests/test_luoyang_city_life_cpu_draft_20261016f.gd','A8D112574BF860FB595C78E34524ABBA1693CBEB6D65F43C23BE50E667EF8895')]
for name in ('old_input_template','old_author_fixture'):
    r=facts['fixed_metadata'][name];qa_pins.append(pin(res(r['path']),r['sha256']))
for desc in qa_pins+[regpin,authorpin,ownerpin]:
    assert desc['path']not in table or table[desc['path']]==desc['sha256'];table[desc['path']]=desc['sha256']
additionalG=sorted(set(globalG)-set(city['source_sha256']));assert len(additionalG)==22
fixture={'status':'ROOT33_ONE_EXPLICIT_NEAR_HALL_TRUE_RESIDENT_ROUNDTRIP_READY_NOT_RUN','ready':True,'whole_ms':60000,'entry_ms':20000,'room_ms':20000,'return_ms':10000,'max_pictures':0,'source_sha256':table,'expected_city_sources':copy.deepcopy(city['source_sha256']),'expected_G_global_sources':copy.deepcopy(globalG),'hall_row':copy.deepcopy(row),'hall_author':author,'city_scene_path':base['scene_path'],'city_layout_path':base['layout_path'],'room_display_name':facts['minimal_public_actions']['room_display_name'],'setup_uv':[.5,716/2048],'street_input':[[1536,716],[1536,660]],'enter_zone_world':[1536,660],'room_spawn_uv':[.5,840/1024],'room_input':[[960,1050],[960,1142.5]],'exit_zone_world':[960,1142.5],'author_return_world':[1536,660],'author_return_uv':[.5,660/2048],'historical_DT_successor':facts['hall_receipt_and_identity']['historical_value_difference'],'authority':{'owner':ownerpin,'facts':facts_pin,'registry':regpin,'hall_author':authorpin,'Root32_after':postpin,'Root33_before':freshpin,'formal_Root31_after':base['authority']['actual_Root_deployment_guard'],'formal_Root31_copy':base['authority']['actual_Root_deployment_copy']},'scope':{'public_near_setup_not_default_world_travel':True,'real_INPUT_and_Space_two_directions_only':True,'no_menu_save_reset_or_private_reposition':True,'no_manual_collector_validator_or_Gfinalize':True,'globalG_guard557_not_session_FIRSTFINAL':True,'additionalG_not_in_C_city_count':22,'additionalG_paths_from_fixed_owner_only':additionalG,'historical247_not_rewritten_to_current':True,'body':'Actual complete34x24 native PhysicsShapeQuery plus17 already-loaded mask samples where present; no source875 route geometry replay','no_new_geometry_or_native_publication':True,'native_foot_input_tolerance_px':.3,'return_foot_exact_author_not_actual_departure':True,'same_Field_Player_Scene_layout_weakrefs':True,'park_limit_bytes':536870912,'warm_return_source_basis':'SAME_LIVE_OBJECTS_AND_EDITOR_METADATA','warm_return_fresh_SHA':False,'no_cold_or_room_under10_claim':True},'budget_note':'60s whole includes precheck, both20s max arrivals, real INPUT, warm<10s and source postcheck; per-leg caps are not additive permissions. Approx42s is only planning, not guarantee; any whole/arrival/return budget exhaustion remains FAIL with no extension.','guard_derivation':'Fixed08guard+all557 independent G values;22 additional paths, not a fictitious subset of1239. Replace Root32fresh with33fresh, add real32after and fixed facts/QA helper sources, swap07 ancestry for08. Source expected values exclusively5448/explicit fixed pins; no observed collector backfill.'}
assert all(table[p]==s for p,s in city['source_sha256'].items())and all(table[p]==s for p,s in globalG.items())
template=QA/'hall_roundtrip_ROOT33_TEMPLATE_NOT_RUN.gd';templatepin=pin(template,'6B13D2D96518BAA318F88766972FD9AB2A01AA09BCE40A24245AC508BD73ECAF')
keypath=OUT/'test_hall_roundtrip_ROOT33_READY.gd';fp=OUT/'hall_roundtrip_fixture_ROOT33_READY.json'
fb=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode();fs=hashlib.sha256(fb).hexdigest()
text=template.read_bytes().decode();hunks=[('const FIXTURE_READY=false','const FIXTURE_READY=true'),('PENDING_ROOT33_HALL_FIXTURE_SHA',fs),('PENDING_ROOT33_HALL_FIXTURE',rp(fp)),('PENDING_ROOT33_HALL_OUTPUT',rp(OUT/'output'))]
for a,b in hunks:assert text.count(a)==1;text=text.replace(a,b,1)
inverse=text
for a,b in reversed(hunks):assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
assert inverse.encode()==template.read_bytes()
assert not OUT.exists();OUT.mkdir();fp.write_bytes(fb);keypath.write_bytes(text.encode())
diffp=OUT/'complete_key_vs_template.diff';diffp.write_text(''.join(difflib.unified_diff(template.read_text(encoding='utf-8').splitlines(keepends=True),text.splitlines(keepends=True),fromfile=rp(template),tofile=rp(keypath))),encoding='utf-8',newline='')
hand={'status':'ROOT33_HALL_READY_NOT_EXECUTED_NOT_PARSE_PASS','key':{'path':rp(keypath),'sha256':sha(keypath)},'fixture':{'path':rp(fp),'sha256':sha(fp)},'template':templatepin,'whole_byte_reverse_to_template':True,'literal_hunks':[{'old':a,'new':b}for a,b in hunks],'diff':{'path':rp(diffp),'sha256':sha(diffp)},'sourceguard_count':len(table),'city1239_Gglobal557_hallhistorical247_separate':True,'G_extra22_fromfixedowner_not_Csubset':True,'scope':'one public near1536,716 then INPUT716to660 Spacehall /INPUT1050to1142.5 Spaceback; same retained exterior author1536,660; 60s whole20/20/<10 return;0pictures/no manualcollector/no geometry publication','historical_u_template_only_no_old_whole_test_bootstrap':facts['fixed_metadata']['old_input_template'],'ROOTfacts':facts_pin,'Root33before':freshpin,'Root32after':postpin,'notes':['Only naturally created G session with real weakrefs/author/finalized; no nonexistent session.sources','All557 source guard first/final, not G natural FIRSTFINAL receipt','Memory refusal/cold fallback/identity/source drift/late draw are actual FAIL, never bypassed'],'engine_parse_Stage_collector_or_formal_calls':0}
hp=OUT/'handoff_ROOT33_READY_NOT_RUN.json';hp.write_text(json.dumps(hand,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'key':hand['key'],'fixture':hand['fixture'],'handoff':{'path':rp(hp),'sha256':sha(hp)},'sourceguard':len(table)}))
