"""Mechanical63pending ->64 actualreceipt lock; do not execute owner/Stage."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent
oldp=H/'prepare_performance63_ground8_actual_owner_PENDING.py'
newp=H/'prepare_performance64_ground8_actual_owner_NOTRUN.py'
old=oldp.read_bytes();assert hashlib.sha256(old).hexdigest()=='9a0acfbfbfb76cc4075b88e3dad6e002d9de1d77695c72686b3c6dbb8961b83d'
replacements=[(b"OUT=S+'performance63_ground8_actual_independent_review_PENDING/'",b"OUT=S+'performance64_ground8_actual_independent_review/'"),(b"FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL62_RECEIPT_SHA_DO_NOT_RUN'",b"FIXED_RECEIPT_SHA='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe'")]
new=old
for a,b in replacements:assert new.count(a)==1;new=new.replace(a,b,1)
inverse=new
for a,b in reversed(replacements):assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
assert inverse==old;ast.parse(new)
out=H/'performance64_ground8_owner_lock';assert not out.exists()and not newp.exists()
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=oldp.name,tofile=newp.name)).encode()
proof={'status':'MECHANICAL_ROOT_ACTUAL62_OWNER_FREEZE_NOT_EXECUTED','parent_sha256':hashlib.sha256(old).hexdigest(),'candidate_sha256':hashlib.sha256(new).hexdigest(),'whole_byte_inverse':True,'only_replacements':[{'old':a.decode(),'new':b.decode()}for a,b in replacements],'owner_body_unchanged':True,'actual_receipt_sha256':'1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe','Stage_owner_engine_calls':0}
pb=(json.dumps(proof,indent=2)+'\n').encode();out.mkdir();newp.write_bytes(new)
(out/'mechanical_freeze_complete.diff').write_bytes(diff);(out/'wholebyte_inverse_READY.json').write_bytes(pb)
print(json.dumps({'owner_tool':{'path':str(newp),'sha256':hashlib.sha256(new).hexdigest()},'diff_sha256':hashlib.sha256(diff).hexdigest(),'inverse_sha256':hashlib.sha256(pb).hexdigest()},indent=2))
