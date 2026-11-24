"""Create a blocked future exact30 owner reviewer; do not execute it."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=(H/'prepare_performance54_market_tuple3_actual_owner_NOTRUN.py').read_bytes();assert sha(old)=='e6387a66f71861e7b2127df75f1dad6b7c0a29e3ecd7af1ba5f8c9cdee406610';t=old.decode();changes=[]
def change(a,b):
    global t
    assert a in t,a;t=t.replace(a,b);changes.append({'old':a,'new':b})
change('Blocked pending actual51: SOURCE_ONLY exact3 independent owner successor to fixed585717.','Blocked pending actual58: exact30 Market complete-parent independent owner successor to fixedFC11.')
change("OUT=S+'performance54_market_tuple3_actual_independent_review/'","OUT=S+'performance59_market_parent30_actual_independent_review/'")
change("PRIOR=S+'performance49_estate17_actual_independent_review/owner_source_maps_READY.json'","PRIOR=S+'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json'")
change("PRIOR_SHA='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'","PRIOR_SHA='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02'")
change("PLAN=S+'performance51_market_tuple3_source_recipe/source_input_ROOT_LOCKED.json'","PLAN=S+'performance58_market_parent30_source_recipe/source_input_ROOT_LOCKED.json'")
change("PLAN_SHA='30254627510d38509c900b00402c29c7c5d1e45691b0a704e0544addf4808b0c'","PLAN_SHA='a29f32c01dcac22c4a1289e5bd5084c4cb76195d7666ee021165d6aba98dd140'")
change("FIXED_RECEIPT_SHA='4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999'","FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL58_RECEIPT_SHA'")
change('outputs/root_market_source_only_tuple3_stage01/receipt.json','outputs/root_market_complete_parent30_stage01/receipt.json')
change("{'patch_count':1,'copy_count':2,'total':3","{'patch_count':15,'copy_count':15,'total':30")
change('len(targets)==3','len(targets)==30')
change("if n['kind']=='metadata':","if n['kind']in ['metadata','repair30_contract_literal']:")
change("n['kind']=='tuple3_frozen'","n['kind']=='repair30_frozen'")
a=t.index('    assert len(typed)==2 and len(indices)==1');b=t.index('    def replace(values):',a)
change(t[a:b],'''    assert len(typed)==14 and len(indices)==8
    hand=read(inputs[c['production_input']]['path'],inputs[c['production_input']]['sha256'])
    assert inputs[c['production_input']]['sha256']=='e12394b9f9f47524f5118c3fb4ddad9a38306d042289eaddbe9f830a7398d953'
    leaves=hand['new_exact10_proof_pins'];assert len(leaves)==10
    code=read(hand['whole_inverse_proof']['path'],hand['whole_inverse_proof']['sha256'])
    for r in code['records'].values():
        before=raw(r['parent']['path'],r['parent']['sha256']);candidate=raw(r['candidate']['path'],r['candidate']['sha256']);forward=before;inverse=candidate
        for h in r['hunks']:
            a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1 and inverse.count(b)==1;forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
        assert forward==candidate and inverse==before
    scalar=nodes['estate_final']['value'];registry_path='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
    assert scalar['registry_path']==registry_path and scalar['registry_sha256']==scalar['source_sha256'][registry_path]==nodes['registry_final']['sha256']
''')
a=t.index('    # Expected maps come only from fixed544819');b=t.index('    oldunion=',a)
change(t[a:b],'''    # Independent declaration-derived consumers, never actual collector fill:
    # C complete maps, both Quarter shared receipts, G fullfamily collectors,
    # Temple consume execution source_paths95; Estate331 and roomreceipts do not.
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    scenes=[]
    for original in old['scenes']:
        row=copy.deepcopy(original);is_estate=row['id']=='luoyang_estate_riverside_20261021ai'
        for field in ['source_sha256','receipt_source_sha256']:
            row[field]=replace(original[field])
            if not is_estate:
                assert not(set(row[field])&set(leaves));row[field].update(leaves)
            assert set(row[field])==set(original[field])|(set()if is_estate else set(leaves))
        if row['id']in maps:
            assert same(maps[row['id']],row['source_sha256']) and same(row['source_sha256'],row['receipt_source_sha256']),('FOUR_COMPLETE_AO_MAPS_FIXED_FC11_PLUS30_AND10',row['id'])
        elif row['id']in nodes['quarter_final']['value']['scenes']:
            native=nodes['quarter_final']['value']['scenes'][row['id']]
            assert same(nodes['quarter_final']['value']['source_sha256'],row['receipt_source_sha256']) and row['scene_path']==native['scene_path']and row['layout_path']==native['layout_path']
            assert len(row['source_sha256'])==304 and len(row['receipt_source_sha256'])==302
        elif is_estate:
            assert len(row['source_sha256'])==333 and len(row['receipt_source_sha256'])==331 and same(scalar['source_sha256'],row['receipt_source_sha256'])
        elif row['id']=='ch4_s4_ancient_temple':
            assert len(row['source_sha256'])==len(row['receipt_source_sha256'])==392
        else:raise AssertionError(('UNKNOWN_SCENE_OWNER',row['id']))
        row['recipe']='FixedFC11 independent fulltable plus exact30 existing-source value substitutions; execution API consumers acquire only the10 approved snapshots. Estate331 keyset/native identity fixed. No collector observation.'
        scenes.append(row)
    registry=nodes['registry_final']['value'];assert len(registry['rooms'])==12;rooms=[];dt='res://scripts/city/luoyang_district_life_20261016f.gd'
    for original in old['rooms']:
        row=copy.deepcopy(original);row['source_sha256']=replace(original['source_sha256']);assert not(set(row['source_sha256'])&set(leaves));row['source_sha256'].update(leaves)
        row['receipt_source_sha256']=replace(original['receipt_source_sha256'])
        assert len(row['source_sha256'])==567 and set(row['source_sha256'])==set(original['source_sha256'])|set(leaves)
        assert set(row['receipt_source_sha256'])==set(original['receipt_source_sha256'])and {path for path in row['receipt_source_sha256']if row['receipt_source_sha256'][path]!=original['receipt_source_sha256'][path]}=={dt}
        assert same(registry['rooms'][row['id']]['source_sha256'],row['receipt_source_sha256'])
        row['recipe']='FixedFC11 G557 complete source API consumes execution95, hence567 with10new snapshotkeys. Per-room receipt has no newkey and only one DT source value successor; original native/return/door fields retained.'
        rooms.append(row)
    assert len(scenes)==8 and len(rooms)==5
    assert {r['id']:len(r['source_sha256'])for r in scenes if r['id']in maps}=={'ch4_s0_luoyang_gate':898,'ch4_s1_luoyang_yamen':1249,'ch4_s2_canal_docks':1726,'ch4_s3_luoyang_market':1712}
    sourceonly={path for path in old['scenes'][3]['source_sha256']if path.endswith('walk.png-eb63fda1eba65c60ad6a24b15599ec76.ctex')}
    for r in scenes+rooms:
        if r['id']!='ch4_s3_luoyang_market':assert not(set(r['source_sha256'])&sourceonly)
''')
change('EXACT_INHERITED585717_OLD_VALUE','EXACT_INHERITEDFC11_OLD_VALUE')
change('unchanged_inherited585717_leaves_not_rehashed','unchanged_inheritedFC11_leaves_not_rehashed')
change("'metadata_fields_not_invented':'All585717 identity/native/receipt contracts inherited.Only3 existing header values change; Market only gains2 Root39 SOURCE_ONLY leaves.Other3C keysets and all G/Quarter/Estate/Temple maps/registry/roomreceipt remain unchanged except the shared3headers where actually declared.No runtime/import credit.'", "'metadata_fields_not_invented':'FixedFC11 identities/native preserved.Exact30 source value successors; execution-source API consumers add only approved10snapshotkeys.Estate331 and five roomreceipt keysets fixed; roomreceipts only DT values migrate.Root39two SOURCE_ONLY leaves remain Market-only; no collector observed expectations.'")
change('INDEPENDENT3_BYTE_TYPED_FIXED585717_SOURCE_ONLY_TUPLE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','INDEPENDENT30_BYTE_TYPED_FIXEDFC11_COMPLETE_PARENT_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT')
change("'target_count':3","'target_count':30")
new=t.encode();ast.parse(new);rev=t
for r in reversed(changes):assert r['new']in rev;rev=rev.replace(r['new'],r['old'])
assert rev.encode()==old
dest=H/'prepare_performance59_market_parent30_actual_owner_PENDING.py';out=H/'performance59_market_parent_owner_text';assert not dest.exists()and not out.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),t.splitlines(True),fromfile='prepare_performance54_market_tuple3_actual_owner_NOTRUN.py',tofile=dest.name)).encode()
proof={'status':'TEXT_ONLY_FUTURE30_OWNER_TOOL_PENDING_ACTUAL58_NOT_RUN','parent_tool_sha256':sha(old),'new_tool_sha256':sha(new),'whole_byte_inverse':True,'replacements':changes,'consumer_key_counts_expected_from_fixed_declarations':{'fourC':[898,1249,1726,1712],'Quarter':[304,302],'Estate':[333,331],'Temple':392,'Gcomplete':567,'roomreceipt':[242,236,239,239,236]},'approved10_sources_only_in_execution_API_domains':True,'no_current_collector_or_sourcehash_Stage_owner_engine_execution':True}
pb=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();out.mkdir();dest.write_bytes(new);(out/'complete_vs54.diff').write_bytes(diff);(out/'wholebyte_inverse_PENDING.json').write_bytes(pb)
print(json.dumps({'tool':S+dest.name,'sha256':sha(new),'diff_sha256':sha(diff),'proof_sha256':sha(pb)}))
