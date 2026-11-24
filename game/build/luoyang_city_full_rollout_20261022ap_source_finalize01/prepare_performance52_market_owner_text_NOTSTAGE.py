"""Prepare only a blocked future51 owner tool; no actual or owner execution."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=(H/'prepare_performance49_estate17_actual_owner_NOTRUN.py').read_bytes();assert sha(old)=='0e1352c12b365c32fba2b45fcef1a7c185982467587d91a8b94d735f1d1c4fa2';t=old.decode();changes=[]
def change(a,b):
    global t
    assert a in t,a;t=t.replace(a,b);changes.append({'old':a,'new':b})
change('Root-only actual17 Estate scalar review and independent owner successor to fixed544819.','Blocked pending actual51: SOURCE_ONLY exact3 independent owner successor to fixed585717.')
change("OUT=S+'performance49_estate17_actual_independent_review/'","OUT=S+'performance52_market_tuple3_actual_independent_review/'")
change("PRIOR=S+'performance43_culture_actual_independent_review/owner_source_maps_READY.json'","PRIOR=S+'performance49_estate17_actual_independent_review/owner_source_maps_READY.json'")
change("PRIOR_SHA='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0'","PRIOR_SHA='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'")
change("PLAN=S+'performance48_estate17_source_recipe/source_input_ROOT_LOCKED.json'","PLAN=S+'performance51_market_tuple3_source_recipe/source_input_ROOT_LOCKED.json'")
change("PLAN_SHA='c16d31254944fc7b8a4fc0c20cc49dfa4b1e2a1ec4e01058240c4fc02db2e03a'","PLAN_SHA='30254627510d38509c900b00402c29c7c5d1e45691b0a704e0544addf4808b0c'")
change("FIXED_RECEIPT_SHA='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'","FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL_51_RECEIPT_SHA'")
change('outputs/root_estate_registry_scalar17_stage01/receipt.json','outputs/root_market_source_only_tuple3_stage01/receipt.json')
change("{'patch_count':6,'copy_count':11,'total':17","{'patch_count':1,'copy_count':2,'total':3")
change('len(targets)==17','len(targets)==3')
change("n['kind']=='estate17_frozen'","n['kind']=='tuple3_frozen'")
a=t.index("    scalar=nodes['estate_final']");b=t.index('    def replace(values):',a)
change(t[a:b],'''    assert len(typed)==2 and len(indices)==1
    admission=read(inputs[c['admission_input']]['path'],inputs[c['admission_input']]['sha256'])
    assert inputs[c['admission_input']]['sha256']=='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4'
    leaves=admission['source_leaves'];assert len(leaves)==2
    assert admission['status']=='ROOT_EXPLICIT_NEW_SOURCE_ONLY_TWO_LEAF_ADMISSION'and admission['approved_by_root']is True
''')
change("            row[field]=replace(original[field]);assert set(row[field])==set(original[field])", "            row[field]=replace(original[field])\n            if row['id']=='ch4_s3_luoyang_market':\n                assert not(set(row[field])&set(leaves));row[field].update(leaves)\n            assert set(row[field])==set(original[field])|(set(leaves)if row['id']=='ch4_s3_luoyang_market'else set())")
change("elif row['id']=='luoyang_estate_riverside_20261021ai':\n            assert len(row['receipt_source_sha256'])==331 and same(scalar['source_sha256'],row['receipt_source_sha256'])", "elif row['id']=='luoyang_estate_riverside_20261021ai':\n            assert len(row['receipt_source_sha256'])==331 and same(nodes['estate_final']['value']['source_sha256'],row['receipt_source_sha256'])\n            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])")
change('FOUR_INDEPENDENT_MAPS_EXACT_FIXED5448_SUCCESSION','FOUR_INDEPENDENT_MAPS_EXACT_FIXED5857_THREE_HEADERS_AND_ONLY_MARKET_TWO_LEAVES')
change('EXACT_INHERITED544819_OLD_VALUE','EXACT_INHERITED585717_OLD_VALUE')
change('unchanged_inherited544819_leaves_not_rehashed','unchanged_inherited585717_leaves_not_rehashed')
change("row['recipe']='Fixed544819 independent complete map plus exact17 existing metadata/header value substitutions only; all source keys, native identity and receipt semantics unchanged. No collector observation.'", "row['recipe']='Fixed585717 independent map plus exact3 current header values; only Market adds the Root39 admitted2 SOURCE_ONLY leaves. Other scene keysets/native/receipt contracts unchanged; no collector observation.'")
change("row['recipe']='Fixed544819 G complete source domain, only existing exact17 header values replaced. Registry and full per-room receipt dictionaries stay byte-equivalent in typed value; no geometry/door/return/source key additions.'", "row['recipe']='Fixed585717 G complete source and per-room receipt dictionaries remain whole unchanged; no Market proof imports are inherited through this API.'\n        assert same(row['source_sha256'],original['source_sha256'])")
change("    assert len(scenes)==8 and len(rooms)==5", "    assert len(scenes)==8 and len(rooms)==5\n    assert {r['id']:len(r['source_sha256'])for r in scenes if r['id'].startswith('ch4_s')and r['id']!='ch4_s4_ancient_temple'}=={'ch4_s0_luoyang_gate':888,'ch4_s1_luoyang_yamen':1239,'ch4_s2_canal_docks':1716,'ch4_s3_luoyang_market':1702}\n    assert all(len(r['source_sha256'])==557 for r in rooms)")
change("'metadata_fields_not_invented':'All544819 scene/layout/worldsize/native identities inherited.17 Estate registry scalar and metadata/header successors only. Quarter/Temple tables, registry and five whole room receipt maps unchanged; no code/native/door/return/source key changes.'", "'metadata_fields_not_invented':'All585717 identity/native/receipt contracts inherited.Only3 existing header values change; Market only gains2 Root39 SOURCE_ONLY leaves.Other3C keysets and all G/Quarter/Estate/Temple maps/registry/roomreceipt remain unchanged except the shared3headers where actually declared.No runtime/import credit.'")
change('INDEPENDENT17_BYTE_TYPED_FIXED544819_ESTATE_SCALAR_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','INDEPENDENT3_BYTE_TYPED_FIXED585717_SOURCE_ONLY_TUPLE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT')
change("'target_count':17","'target_count':3")
new=t.encode();ast.parse(new);inverse=t
for r in reversed(changes):assert r['new']in inverse;inverse=inverse.replace(r['new'],r['old'])
assert inverse.encode()==old
dest=H/'prepare_performance52_market_tuple3_actual_owner_PENDING.py';out=H/'performance52_market_owner_text';assert not dest.exists()and not out.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),t.splitlines(True),fromfile='prepare_performance49_estate17_actual_owner_NOTRUN.py',tofile=dest.name)).encode()
proof={'status':'PENDING_ROOT_ACTUAL51_RECEIPT_SHA_TEXT_ONLY_OWNER_REVIEWER_NOT_RUN','parent_tool_sha256':sha(old),'new_tool_sha256':sha(new),'whole_byte_inverse':True,'replacements':changes,'blocker':'FIXED_RECEIPT_SHA explicitly pending; new actual receipt and Root one-time execution authorization required before a NEW lock successor','fixed_prior_owner_sha256':'585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f','fixed51input_sha256':'30254627510d38509c900b00402c29c7c5d1e45691b0a704e0544addf4808b0c','onlyMarket_adds_admitted2_source_leaves':True,'no_Stage_owner_engine_collector_execution':True}
pb=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();out.mkdir();dest.write_bytes(new);(out/'complete_vs49.diff').write_bytes(diff);(out/'wholebyte_inverse_PENDING.json').write_bytes(pb)
print(json.dumps({'tool_path':S+dest.name,'tool_sha256':sha(new),'diff_sha256':sha(diff),'proof_sha256':sha(pb)}))
