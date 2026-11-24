"""Generate the Root-only independent fixed5448 + actual17 owner reviewer."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=(H/'prepare_performance43_culture_actual_owner_NOTRUN.py').read_bytes();assert sha(old)=='2f62b0c655ca6b1a4789a4d993609b637e70dd023b87e57d359877bf57bd59bf';t=old.decode()
replacements=[]
def change(a,b):
    global t
    assert a in t,a;t=t.replace(a,b);replacements.append({'old':a,'new':b})
change('Future actual24 culture repair review and source-only owner successor to fixedB285.','Root-only actual17 Estate scalar review and independent owner successor to fixed544819.')
change("OUT=S+'performance43_culture_actual_independent_review/'","OUT=S+'performance49_estate17_actual_independent_review/'")
change("PRIOR=S+'performance39_merged_EOF_actual_independent_review/owner_source_maps_READY.json'","PRIOR=S+'performance43_culture_actual_independent_review/owner_source_maps_READY.json'")
change("PRIOR_SHA='b2858260460afe9c655fdd0eca0b2408f11267e1aa313d23b0ee4ccbee0a1d0c'","PRIOR_SHA='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0'")
change("PLAN=S+'performance42_culture24_source_recipe/source_input_ROOT_LOCKED.json'","PLAN=S+'performance48_estate17_source_recipe/source_input_ROOT_LOCKED.json'")
change("PLAN_SHA='decabd917e9a3526c561cdcd0ed3f91e12406696d1a30ae72cad281597b8f277'","PLAN_SHA='c16d31254944fc7b8a4fc0c20cc49dfa4b1e2a1ec4e01058240c4fc02db2e03a'")
change("HAND=S+'performance40_culture_C_source_repair/handoff_EXECUTION_AND_SCOPE_PROPOSAL.json'\nHAND_SHA='7b42c338f2f33e08b9d38b27cc4318ef4be0add9e72b2ae40e9d055c7154cda8'", "FIXED_RECEIPT_SHA='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'")
change('outputs/root_culture_C_source_repair_stage01/receipt.json','outputs/root_estate_registry_scalar17_stage01/receipt.json')
change("    actual=read(args.receipt,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA);hand=read(HAND,HAND_SHA)","    assert args.sha256==FIXED_RECEIPT_SHA\n    actual=read(args.receipt,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA)")
change("{'patch_count':10,'copy_count':14,'total':24","{'patch_count':6,'copy_count':11,'total':17")
change('len(targets)==24','len(targets)==17')
change("if n['kind']in ['metadata','culture_contract_literal']:","if n['kind']=='metadata':")
change("n['kind']=='culture_frozen_node'","n['kind']=='estate17_frozen'")
start=t.index("    code=read(hand['inverse_proof']");end=t.index('    def replace(values):',start)
change(t[start:end],'''    scalar=nodes['estate_final']['value'];registry_path='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
    assert scalar['registry_path']==registry_path and scalar['registry_sha256']==scalar['source_sha256'][registry_path]=='f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28'
    assert len(typed)==11 and len(indices)==6
''')
start=t.index("    previous={r['id']:r for r in old['scenes']}");end=t.index('    assert len(scenes)==8 and len(rooms)==5',start)
change(t[start:end],'''    # Expected maps come only from fixed544819 plus the exact17 approved target
    # values. The Stage's four independent AO maps are verification, not input.
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    scenes=[]
    for original in old['scenes']:
        row=copy.deepcopy(original)
        for field in ['source_sha256','receipt_source_sha256']:
            row[field]=replace(original[field]);assert set(row[field])==set(original[field])
        if row['id']in maps:
            assert same(maps[row['id']],row['source_sha256']) and same(row['receipt_source_sha256'],row['source_sha256']),('FOUR_INDEPENDENT_MAPS_EXACT_FIXED5448_SUCCESSION',row['id'])
        elif row['id']in nodes['quarter_final']['value']['scenes']:
            native=nodes['quarter_final']['value']['scenes'][row['id']]
            assert same(nodes['quarter_final']['value']['source_sha256'],row['receipt_source_sha256']) and row['scene_path']==native['scene_path'] and row['layout_path']==native['layout_path']
            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        elif row['id']=='luoyang_estate_riverside_20261021ai':
            assert len(row['receipt_source_sha256'])==331 and same(scalar['source_sha256'],row['receipt_source_sha256'])
        elif row['id']=='ch4_s4_ancient_temple':
            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        else:raise AssertionError(('UNKNOWN_OWNER_SCENE',row['id']))
        row['recipe']='Fixed544819 independent complete map plus exact17 existing metadata/header value substitutions only; all source keys, native identity and receipt semantics unchanged. No collector observation.'
        scenes.append(row)
    registry=nodes['registry_final']['value'];rooms=[]
    for original in old['rooms']:
        row=copy.deepcopy(original);row['source_sha256']=replace(original['source_sha256'])
        assert set(row['source_sha256'])==set(original['source_sha256'])
        assert same(registry['rooms'][row['id']]['source_sha256'],original['receipt_source_sha256'])
        assert same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        row['recipe']='Fixed544819 G complete source domain, only existing exact17 header values replaced. Registry and full per-room receipt dictionaries stay byte-equivalent in typed value; no geometry/door/return/source key additions.'
        rooms.append(row)
''')
change('EXACT_INHERITEDB285_OLD_VALUE','EXACT_INHERITED544819_OLD_VALUE')
change('unchanged_inheritedB285_leaves_not_rehashed','unchanged_inherited544819_leaves_not_rehashed')
change("'metadata_fields_not_invented':'AllB285 scene/layout/worldsize/native identities inherited.24 culture-source successors only; registry and five whole room receipts unchanged. Contract C pin, Coordinator literal and Temple binding2/189; all gameplay/native unchanged.'", "'metadata_fields_not_invented':'All544819 scene/layout/worldsize/native identities inherited.17 Estate registry scalar and metadata/header successors only. Quarter/Temple tables, registry and five whole room receipt maps unchanged; no code/native/door/return/source key changes.'")
change('INDEPENDENT24_BYTE_TYPED_FIXEDB285_CULTURE_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','INDEPENDENT17_BYTE_TYPED_FIXED544819_ESTATE_SCALAR_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT')
change("'target_count':24","'target_count':17")
new=t.encode();ast.parse(new);reverse=t
for r in reversed(replacements):assert r['new']in reverse;reverse=reverse.replace(r['new'],r['old'])
assert reverse.encode()==old
dest=H/'prepare_performance49_estate17_actual_owner_NOTRUN.py';out=H/'performance49_estate17_owner_text';assert not dest.exists()and not out.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),t.splitlines(True),fromfile='prepare_performance43_culture_actual_owner_NOTRUN.py',tofile=dest.name)).encode()
proof={'status':'FUTURE_ROOT_ONLY_ACTUAL96CA_OWNER_REVIEWER_TEXT_NOT_RUN','parent_tool_sha256':sha(old),'new_tool_sha256':sha(new),'whole_byte_inverse':True,'replacements':replacements,'fixed_actual_receipt_sha256':'96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7','fixed_prior_owner_sha256':'544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0','fixed48input_sha256':'c16d31254944fc7b8a4fc0c20cc49dfa4b1e2a1ec4e01058240c4fc02db2e03a','no_collector_currentcrawl_sourcehash_or_owner_execution':True}
out.mkdir();dest.write_bytes(new);(out/'complete_vs43.diff').write_bytes(diff);pb=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();(out/'wholebyte_inverse_READY.json').write_bytes(pb)
print(json.dumps({'tool_path':S+dest.name,'tool_sha256':sha(new),'complete_diff_sha256':sha(diff),'proof_sha256':sha(pb)}))
