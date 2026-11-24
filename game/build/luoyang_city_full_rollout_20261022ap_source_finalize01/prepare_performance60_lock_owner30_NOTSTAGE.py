"""Lock only actual58 receipt and NEW owner output root; do not run owner."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=(H/'prepare_performance59_market_parent30_actual_owner_PENDING.py').read_bytes();assert sha(old)=='77847c7c155ddbcf5cd67015b1558f5acfc44389905d0dd940c5e1b664ce294a';t=old.decode()
changes=[("FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL58_RECEIPT_SHA'","FIXED_RECEIPT_SHA='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f'"),("OUT=S+'performance59_market_parent30_actual_independent_review/'","OUT=S+'performance60_market_parent30_actual_independent_review/'")]
for a,b in changes:assert t.count(a)==1;t=t.replace(a,b,1)
new=t.encode();ast.parse(new);reverse=t
for a,b in reversed(changes):assert reverse.count(b)==1;reverse=reverse.replace(b,a,1)
assert reverse.encode()==old
dest=H/'prepare_performance60_market_parent30_actual_owner_NOTRUN.py';out=H/'performance60_market_parent_owner_lock';assert not dest.exists()and not out.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),t.splitlines(True),fromfile='prepare_performance59_market_parent30_actual_owner_PENDING.py',tofile=dest.name)).encode()
proof={'status':'ACTUAL58_OWNER_LOCK_TWO_LITERAL_ONLY_NOT_RUN','parent_tool_sha256':sha(old),'new_tool_sha256':sha(new),'whole_byte_inverse':True,'replacements':[{'old':a,'new':b}for a,b in changes],'original_body_recipe_and_source_domains_unchanged':True,'actual_receipt':{'path':S+'outputs/root_market_complete_parent30_stage01/receipt.json','sha256':'464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f'},'owner_Stage_engine_collector_execution':0}
pb=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();out.mkdir();dest.write_bytes(new);(out/'complete_vs59.diff').write_bytes(diff);(out/'wholebyte_inverse_READY.json').write_bytes(pb)
print(json.dumps({'tool_path':S+dest.name,'tool_sha256':sha(new),'diff_sha256':sha(diff),'proof_sha256':sha(pb)}))
