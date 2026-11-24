"""Read-only byte-difference proof into NEW review artifacts; no Stage import."""
import base64,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
old=(H/'stage_unified06_04_READY.py').read_bytes();new=(H/'stage_finite08_READY.py').read_bytes()
assert sha(old)=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
assert sha(new)=='1177be57d7b656f825e695ee8be56e635b7915beaf4ef8b50f44c3422658c11f'
a,b=old.splitlines(keepends=True),new.splitlines(keepends=True);ops=[];forward=[];inverse=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes():
 x,y=b''.join(a[i:j]),b''.join(b[k:l])
 if tag=='equal':assert x==y
 ops.append({'kind':tag,'old_line_span':[i,j],'new_line_span':[k,l],'old_b64':base64.b64encode(x).decode(),'new_b64':base64.b64encode(y).decode()})
 forward.append(y);inverse.append(x)
assert b''.join(forward)==new and b''.join(inverse)==old
proof={'status':'COMPLETE_TOOL_BYTE_DIFFERENCE_PROOF_NOT_EXECUTION','old_sha256':sha(old),'new_sha256':sha(new),'forward_complete_bytes_exact':True,'inverse_complete_bytes_exact':True,'opcodes':ops,'semantic_inheritance':'New FiniteStage subclasses the unchanged SHA-pinned old Stage. Original complete authority/group/metadata/4AO-map guards are used directly; only explicit finite branches and new fixed Root approval/run epoch differ. Mechanical diff is not a claim of semantic equivalence.','canonical_writes':0,'engine_calls':0,'stage_runs':0}
out=H/'finite08_tool_review';assert not out.exists();out.mkdir()
for name,data in [('tool08_vs_frozen06.diff',''.join(difflib.unified_diff(old.decode().splitlines(keepends=True),new.decode().splitlines(keepends=True),fromfile='frozen8DE0',tofile='finite08_1177')).encode()),('complete_tool_byte_inverse_READY.json',(json.dumps(proof,indent=2)+'\n').encode())]:
 with (out/name).open('xb') as f:f.write(data)
 print(name,sha(data))
