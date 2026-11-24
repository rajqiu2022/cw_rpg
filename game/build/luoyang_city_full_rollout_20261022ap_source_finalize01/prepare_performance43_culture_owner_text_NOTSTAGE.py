"""Generate only the future actual-receipt owner reviewer. Does not run it."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
oldpath=H/'prepare_performance39_merged_EOF_actual_owner_NOTRUN.py'
old=oldpath.read_bytes();assert sha(old)=='e8e35e0f67625035f9dad47b8a41c909e221bb411ae0b6637e6f9a588fb3dcb1'
t=old.decode()
changes=[
('Future actual29 review and source-only owner successor to fixed65BE.','Future actual24 culture repair review and source-only owner successor to fixedB285.'),
("OUT=S+'performance39_merged_EOF_actual_independent_review/'","OUT=S+'performance43_culture_actual_independent_review/'"),
("PRIOR=S+'performance26_canonical_B_actual_independent_review/owner_source_maps_READY.json'","PRIOR=S+'performance39_merged_EOF_actual_independent_review/owner_source_maps_READY.json'"),
("PRIOR_SHA='65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be'","PRIOR_SHA='b2858260460afe9c655fdd0eca0b2408f11267e1aa313d23b0ee4ccbee0a1d0c'"),
("PLAN=S+'performance38_exact_EOF_transport_recipe/source_input_ROOT_LOCKED.json'","PLAN=S+'performance42_culture24_source_recipe/source_input_ROOT_LOCKED.json'"),
("PLAN_SHA='077ee41741b8037c016b32d267dae03d8237b760677b486c16ba26c09908d8a8'","PLAN_SHA='decabd917e9a3526c561cdcd0ed3f91e12406696d1a30ae72cad281597b8f277'"),
("HAND=S+'performance34_merged_DT_subspan_dependencies/handoff_EXECUTION_AND_SCOPE_PROPOSAL.json'","HAND=S+'performance40_culture_C_source_repair/handoff_EXECUTION_AND_SCOPE_PROPOSAL.json'"),
("HAND_SHA='32eef713b78b4bc1595e5b29637b67ee71cecc437303bfcb44b830c831e1283f'","HAND_SHA='7b42c338f2f33e08b9d38b27cc4318ef4be0add9e72b2ae40e9d055c7154cda8'"),
('outputs/root_merged_G_parentcopy_DT_source_stage02/receipt.json','outputs/root_culture_C_source_repair_stage01/receipt.json'),
("{'patch_count':15,'copy_count':14,'total':29","{'patch_count':10,'copy_count':14,'total':24"),
('len(targets)==29','len(targets)==24'),
("if n['kind']=='metadata':","if n['kind']in ['metadata','culture_contract_literal']:"),
("n['kind']=='B_only_frozen_node'","n['kind']=='culture_frozen_node'"),
("hand['whole_inverse_proof']","hand['inverse_proof']"),
("hand['new_proof_sources_exact9']","hand['new_exact5_proof_pins']"),
("# Existing E43B binding remains an execution-history source. NEW binding\n    # enters exactly through the nine final execution-proof declarations.","# Existing A5FA binding remains an execution-history source. NEW binding\n    # enters exactly through the five final execution-proof declarations."),
("assert same(receipt,replace(row['receipt_source_sha256'])),('REGISTRY_FIVE_DT_ONLY_RECEIPT_SUCCESSION',row['id'])","assert same(receipt,row['receipt_source_sha256']),('FROZEN_REGISTRY_WHOLE_ROOM_RECEIPT',row['id'])"),
("'target_count':29","'target_count':24"),
("'metadata_fields_not_invented':'All65BE scene/layout/worldsize/native identities inherited.29-source successor only,5room DT declarations and new registry header, C-only Temple binding; hash/Family/ENV/Field/Router/Coordinator unchanged.'","'metadata_fields_not_invented':'AllB285 scene/layout/worldsize/native identities inherited.24 culture-source successors only; registry and five whole room receipts unchanged. Contract C pin, Coordinator literal and Temple binding2/189; all gameplay/native unchanged.'"),
("recipe='Fixed65BE G-family full collector with exact29 target/header and9 proof leaves; per-room receipt only DT source value successor, no native/return mutation.'","recipe='FixedB285 G-family full collector with exact24 target/header and5 proof leaves; per-room receipt and registry whole unchanged, no native/return mutation.'"),
("recipe='Original frozen AO independent map through unchanged validators; actualAP14_35FF plus exact29 merged target/header succession and9 declared proof leaves. Never collector-derived.'","recipe='Original frozen AO independent map through unchanged validators; formalAP15_EB875 plus exact24 culture-source header succession and5 declared proof leaves. Never collector-derived.'"),
("recipe='Fixed65BE Quarter identity/native plus merged source and80 execution-proof/header successor; receipt domain excludes collector header.'","recipe='FixedB285 Quarter identity/native plus culture-source and85 execution-proof/header successor; receipt domain excludes collector header.'"),
("recipe='Fixed331 Estate keyset only necessary target values and new registry header; native unchanged; no shared new proof group.'","recipe='Fixed331 Estate keyset only necessary culture-source target/header values; registry/native unchanged; no shared new proof group.'"),
("recipe='Fixed65BE complete Temple source domain plus necessary target/header replacements and9 execution proof leaves including NEW C-only binding; native/other188 binding source values unchanged.'","recipe='FixedB285 complete Temple source domain plus necessary target/header replacements and5 execution proof leaves including NEW culture binding; native/other187 binding source values unchanged.'"),
('unchanged_inherited65BE_leaves_not_rehashed','unchanged_inheritedB285_leaves_not_rehashed'),
('EXACT_INHERITED65BE_OLD_VALUE','EXACT_INHERITEDB285_OLD_VALUE'),
('INDEPENDENT29_BYTE_TYPED_FIXED65BE_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','INDEPENDENT24_BYTE_TYPED_FIXEDB285_CULTURE_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT')]
for a,b in changes:
    assert a in t,a;t=t.replace(a,b)
new=t.encode();ast.parse(new)
reverse=t
for a,b in reversed(changes):assert b in reverse;reverse=reverse.replace(b,a)
assert reverse.encode()==old
dest=H/'prepare_performance43_culture_actual_owner_NOTRUN.py';assert not dest.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),t.splitlines(True),fromfile=oldpath.name,tofile=dest.name)).encode()
out=H/'performance43_culture_owner_text';assert not out.exists();out.mkdir()
dest.write_bytes(new);(out/'complete_vs39.diff').write_bytes(diff)
proof={'status':'TEXT_ONLY_FUTURE_CULTURE24_ACTUAL_OWNER_TOOL_NOT_RUN','parent_path':S+oldpath.name,'parent_sha256':sha(old),'new_path':S+dest.name,'new_sha256':sha(new),'whole_byte_inverse':True,'replacements':[{'old':a,'new':b}for a,b in changes],'requires_Root_future_actual_receipt_path_and_sha256':True,'fixed_prior_owner':'B285','fixed_plan':'DECABD','no_actual_receipt_SHA_prefilled':True,'all_five_room_receipts_and_registry_whole_frozen':True,'no_tool_Stage_engine_collector_or_packet_decode_execution':True}
(out/'wholebyte_inverse_READY.json').write_bytes((json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'owner_tool':sha(new),'diff':sha(diff),'proof':sha((out/'wholebyte_inverse_READY.json').read_bytes())}))
