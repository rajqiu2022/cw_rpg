"""Retain initial unexecuted candidate; emit its narrow Common-qualified repair."""
from pathlib import Path
import ast,copy,difflib,hashlib,json,sys
BASE=Path(__file__).resolve().parent;REPO=BASE.parents[2]
old=(BASE/'xiangzhou_author_READY.gd').read_bytes()
assert hashlib.sha256(old).hexdigest()=='e0771cf09cf5b35f54af74c6554855148ee5526cec9147cbb55ef2ef65dc2b40'
after=old
for a,b in [(b'var polygon:=rect_polygon(body)',b'var polygon:=Common.rect_polygon(body)'),(b'var layout: WalkableMapLayout=layout()',b'var prior_layout: WalkableMapLayout=layout()'),(b'in layout.walkable_regions:',b'in prior_layout.walkable_regions:')]:
 assert after.count(a)==1,a
 after=after.replace(a,b)
target=BASE/'xiangzhou_author_READY02.gd'
if sys.argv[-1]=='--emit-patch':
 print('*** Begin Patch');print('*** Add File: '+target.as_posix())
 for line in after.decode().splitlines():print('+'+line)
 print('*** End Patch');sys.exit()
if sys.argv[-1]=='--restore-eol-only':
 actual=target.read_bytes();assert actual.replace(b'\r\n',b'\n')==after.replace(b'\r\n',b'\n')
 if actual!=after:target.write_bytes(after)
 print('Exact candidate EOL only.');sys.exit()
assert sys.argv[-1]=='--seal' and target.read_bytes()==after
sha=lambda b:hashlib.sha256(b).hexdigest()
tree=ast.parse((REPO/'game/build/city_visual_diversity_20261031c/prepare_source_closure.py').read_text(encoding='utf-8-sig'))
for node in tree.body:
 if isinstance(node,ast.FunctionDef)and node.name in ['once','edit','hunks']:exec(compile(ast.Module(body=[node],type_ignores=[]),'<exact inverse>','exec'),globals())
manifest=json.loads((BASE/'jx_manifest_READY.json').read_bytes())
row=manifest['targets'][1];assert 'xiangzhou' in row['target']
row['candidate']=target.relative_to(REPO).as_posix();row['new_sha256']=sha(after);row['bytes']=len(after)
manifest['status']='FROZEN_JX02_ROOT_STATIC_QUALIFICATION_FIX_NOT_ENGINE_OR_ART_PASS'
manifest['history']+='; Root static review caught unqualified rect_polygon in X historical-safe clone; initial E077 source/receipts retained unexecuted. This revision qualifies Common and renames local prior_layout.'
(BASE/'jx_manifest_READY02.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='')
facts=[]
for row in manifest['targets']:
 before=(REPO/row['before']).read_bytes();candidate=(REPO/row['candidate']).read_bytes()
 assert sha(before)==row['old_sha256']and sha(candidate)==row['new_sha256']
 changes=hunks(before,candidate)
 assert edit(before,[(x['old'],x['new'])for x in changes])==candidate
 assert edit(candidate,[(x['new'],x['old'])for x in reversed(changes)])==before
 city='jinling'if'jinling' in row['target']else'xiangzhou'
 forward=''.join(difflib.unified_diff(before.decode().splitlines(True),candidate.decode().splitlines(True),fromfile='a/'+row['target'],tofile='b/'+row['target'])).encode()
 inverse=''.join(difflib.unified_diff(candidate.decode().splitlines(True),before.decode().splitlines(True),fromfile='a/'+row['target'],tofile='b/'+row['target'])).encode()
 for suffix,data in [('FORWARD02',forward),('INVERSE02',inverse)]:
  with (BASE/(city+'_'+suffix+'.diff')).open('xb')as f:f.write(data)
 facts.append({'target':row['target'],'before_sha256':sha(before),'after_sha256':sha(candidate),'whole_forward_inverse_exact':True,'replacements':changes})
proof={'status':'JX02_BOUNDED_BYTE_PROOF_ONLY','targets':facts,'engine_runs':0,'canonical_writes':0}
(BASE/'jx_inverse_proof_READY02.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='')
print(json.dumps({'candidate_sha256':sha(after),'manifest_sha256':sha((BASE/'jx_manifest_READY02.json').read_bytes()),'proof_sha256':sha((BASE/'jx_inverse_proof_READY02.json').read_bytes())}))
