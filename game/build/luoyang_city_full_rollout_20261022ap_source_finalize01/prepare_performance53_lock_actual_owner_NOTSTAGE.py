"""Mechanical NEW actual51 owner lock only, never owner execution."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=(H/'prepare_performance52_market_tuple3_actual_owner_PENDING.py').read_bytes();assert sha(old)=='7616626a88c81c2e487fa8297105666832b4a6b2faa492034222ec07e3f2b6b4';t=old.decode()
changes=[("FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL_51_RECEIPT_SHA'","FIXED_RECEIPT_SHA='4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999'"),("OUT=S+'performance52_market_tuple3_actual_independent_review/'","OUT=S+'performance53_market_tuple3_actual_independent_review/'")]
for a,b in changes:assert t.count(a)==1;t=t.replace(a,b,1)
new=t.encode();ast.parse(new);rev=t
for a,b in reversed(changes):assert rev.count(b)==1;rev=rev.replace(b,a,1)
assert rev.encode()==old
dest=H/'prepare_performance53_market_tuple3_actual_owner_NOTRUN.py';out=H/'performance53_market_owner_actual_lock';assert not dest.exists()and not out.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),t.splitlines(True),fromfile='prepare_performance52_market_tuple3_actual_owner_PENDING.py',tofile=dest.name)).encode()
proof={'status':'ROOT_ACTUAL51_OWNER_RECEIPT_SHA_AND_NEW_OUTPUT_ONLY_LOCK_NOT_RUN','parent_tool_sha256':sha(old),'new_tool_sha256':sha(new),'whole_byte_inverse':True,'replacements':[{'old':a,'new':b}for a,b in changes],'no_other_body_or_recipe_change':True,'actual_receipt_path':S+'outputs/root_market_source_only_tuple3_stage01/receipt.json','actual_receipt_sha256':'4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999','owner_Stage_collector_engine_calls':0}
pb=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();dest.write_bytes(new);out.mkdir();(out/'complete_vs52.diff').write_bytes(diff);(out/'wholebyte_inverse_READY.json').write_bytes(pb)
print(json.dumps({'tool_path':S+dest.name,'tool_sha256':sha(new),'diff_sha256':sha(diff),'proof_sha256':sha(pb)}))
