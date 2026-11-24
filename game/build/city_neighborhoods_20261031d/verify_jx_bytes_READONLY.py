"""Bounded candidate byte proof; no canonical writes, engine or save reads."""
from pathlib import Path
import ast,difflib,hashlib,json
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
scope={}
tree=ast.parse((REPO/'game/build/city_visual_diversity_20261031c/prepare_source_closure.py').read_text(encoding='utf-8-sig'))
for node in tree.body:
 if isinstance(node,ast.FunctionDef) and node.name in ['once','edit','hunks']:exec(compile(ast.Module(body=[node],type_ignores=[]),'<exact inverse helpers>','exec'),globals())
manifest=json.loads((BASE/'jx_manifest_READY.json').read_bytes())
sha=lambda b:hashlib.sha256(b).hexdigest()
facts=[]
for row in manifest['targets']:
 before=(REPO/row['before']).read_bytes();after=(REPO/row['candidate']).read_bytes()
 assert sha(before)==row['old_sha256'] and sha(after)==row['new_sha256']
 replacements=hunks(before,after)
 assert edit(before,[(r['old'],r['new'])for r in replacements])==after
 assert edit(after,[(r['new'],r['old'])for r in reversed(replacements)])==before
 city='jinling'if'jinling' in row['target']else'xiangzhou'
 inverse=''.join(difflib.unified_diff(after.decode().splitlines(True),before.decode().splitlines(True),fromfile='a/'+row['target'],tofile='b/'+row['target'])).encode()
 target=BASE/(city+'_INVERSE.diff')
 if target.exists():assert target.read_bytes()==inverse
 else:
  with target.open('xb')as file:file.write(inverse)
 facts.append({'target':row['target'],'before_sha256':sha(before),'after_sha256':sha(after),'forward_and_inverse_bytes_exact':True,'replacements':replacements,'inverse_sha256':sha(inverse),'forward_path':(BASE/(city+'_FORWARD.diff')).relative_to(REPO).as_posix(),'inverse_path':target.relative_to(REPO).as_posix()})
result={'status':'EXACT_JX_CANDIDATE_BYTE_EDGES_ONLY_NOT_PHYSICS_OR_ART_PASS','targets':facts,'canonical_writes':0,'engine_runs':0,'save_read_APIs':0}
data=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()
target=BASE/'jx_inverse_proof_READY.json'
if target.exists():assert target.read_bytes()==data
else:
 with target.open('xb')as file:file.write(data)
print(json.dumps({'path':target.relative_to(REPO).as_posix(),'sha256':sha(data),'targets':len(facts)}))
