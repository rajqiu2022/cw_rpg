"""Fix one owner request selector to actual fixed51 schema; do not run it."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=(H/'prepare_performance53_market_tuple3_actual_owner_NOTRUN.py').read_bytes();assert sha(old)=='23020c11ba5f67e568569b25a6ac33a8fe7f60841b8dc1085c0719e274e96e98';t=old.decode()
changes=[("c['scope_request_input']","c['scope_input']"),("OUT=S+'performance53_market_tuple3_actual_independent_review/'","OUT=S+'performance54_market_tuple3_actual_independent_review/'")]
for a,b in changes:assert t.count(a)==1;t=t.replace(a,b,1)
new=t.encode();ast.parse(new);inverse=t
for a,b in reversed(changes):assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
assert inverse.encode()==old
pb=(H/'performance51_market_tuple3_source_recipe/source_input_ROOT_LOCKED.json').read_bytes();assert sha(pb)=='30254627510d38509c900b00402c29c7c5d1e45691b0a704e0544addf4808b0c';plan=json.loads(pb);c=plan['B_only_contract'];assert c['scope_input']=='tuple3_scope'and 'scope_request_input'not in c
pin=next(r for r in plan['pinned_inputs']if r['id']==c['scope_input']);assert pin['sha256']=='cba12cace9f6ffb44be694ce6a27ccc9152793e460c2e03e79c109b8fa151342'
scope=(H/'performance50_market_autoimport_exact3_pending_scope_READONLY.json').read_bytes();assert sha(scope)==pin['sha256']and json.loads(scope)['target_count']==3
dest=H/'prepare_performance54_market_tuple3_actual_owner_NOTRUN.py';out=H/'performance54_market_owner_selector_fix';assert not dest.exists()and not out.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),t.splitlines(True),fromfile='prepare_performance53_market_tuple3_actual_owner_NOTRUN.py',tofile=dest.name)).encode()
proof={'status':'NEW54_FIXED51_SCHEMA_SELECTOR_AND_OUTPUT_ONLY_NOT_RUN','parent_tool_sha256':sha(old),'new_tool_sha256':sha(new),'whole_byte_inverse':True,'replacements':[{'old':a,'new':b}for a,b in changes],'fixed51_schema_sha256':sha(pb),'actual51_contract_scope_input':'tuple3_scope','selected_scope_sha256':pin['sha256'],'selected_scope_target_count':3,'original53_preserved':'FAIL_CANDIDATE_NOTRUN; no actual execution or actual failure credit','all_other_recipe_body_actual_receipt_owner_pins_unchanged':True,'owner_Stage_engine_collector_calls':0}
data=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();out.mkdir();dest.write_bytes(new);(out/'complete_vs53.diff').write_bytes(diff);(out/'wholebyte_inverse_READY.json').write_bytes(data)
print(json.dumps({'tool_path':S+dest.name,'tool_sha256':sha(new),'diff_sha256':sha(diff),'proof_sha256':sha(data)}))
