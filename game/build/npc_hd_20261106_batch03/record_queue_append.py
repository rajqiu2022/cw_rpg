"""Read-only queue proof; writes only the candidate receipt."""
from pathlib import Path
import hashlib,json,yaml
O=Path(__file__).parent;R=O.parents[2]
before=(O/'before/tasks.yaml').read_bytes()
after=(R/'prompts/tasks.yaml').read_bytes()
assert after.startswith(before), 'Old queue bytes changed'
old=yaml.safe_load(before)['tasks'];new=yaml.safe_load(after)['tasks']
batch=yaml.safe_load((R/'prompts/npc_hd_20261106_batch03/tasks.yaml').read_bytes())['tasks']
assert new[:len(old)]==old and new[len(old):]==batch and len(batch)==5
receipt={'schema':'EXACT_QUEUE_APPEND_PROOF','before_sha256':hashlib.sha256(before).hexdigest(),'after_sha256':hashlib.sha256(after).hexdigest(),'before_bytes':len(before),'after_bytes':len(after),'old_byte_prefix_preserved':True,'inverse_remove_appended_bytes_sha256':hashlib.sha256(after[:len(before)]).hexdigest(),'appended_ids':[x['id'] for x in batch],'all_skip':all(x['skip'] for x in batch),'old_entries':len(old),'new_entries':len(new),'generation_calls':0}
(O/'queue_append_receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
print(json.dumps(receipt))
