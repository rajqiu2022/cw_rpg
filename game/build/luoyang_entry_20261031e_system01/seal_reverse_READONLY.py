"""Finite patch round-trip plus exact fresh-baseline two-target expectation."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;R=N.parents[2];sha=lambda b:hashlib.sha256(b).hexdigest()
receipt=json.loads((N/'receipt_READY.json').read_bytes());before={r['target']:(R/r['target']).read_bytes()for r in receipt['targets']}
def patch(data,text):
 out=dict(data);target=None;group=[]
 def apply():
  if not group:return
  old=''.join(x[1:]+'\n'for x in group if x[0]in' -').encode();new=''.join(x[1:]+'\n'for x in group if x[0]in' +').encode()
  assert out[target].count(old)==1,(target,'nonunique hunk');out[target]=out[target].replace(old,new,1)
 for line in text.splitlines():
  if line.startswith('*** Update File: '):apply();group=[];target=line[17:]
  elif line=='@@':apply();group=[]
  elif line=='*** End Patch':apply();group=[]
  elif line and line[0]in' +-':group.append(line)
 return out
after=patch(before,(N/'Gate_and_index_FORWARD.apply_patch').read_text());roundtrip=patch(after,(N/'Gate_and_index_INVERSE.apply_patch').read_text());assert roundtrip==before
for row in receipt['targets']:assert sha(before[row['target']])==row['before_sha256']and sha(after[row['target']])==row['after_sha256']and len(after[row['target']])==row['after_bytes']
basepath=R/'game/build/luoyang_entry_20261031e_qa01/baseline_NOW_ACTUAL.json';raw=basepath.read_bytes();base=json.loads(raw);targets={}
for row in receipt['targets']:
 key=(R/row['target']).as_posix();fact=base['facts'][key];assert fact['sha256']==row['before_sha256']and fact['bytes']==row['before_bytes']
 targets[row['target']]={'before_fresh':fact,'after_sha256':row['after_sha256'],'after_bytes':row['after_bytes']}
proof={'status':'FINITE_PATCH_FULL_BYTES_REVERSE_PROVEN_NO_CANONICAL_WRITE','receipt_sha256':sha((N/'receipt_READY.json').read_bytes()),'forward_sha256':sha((N/'Gate_and_index_FORWARD.apply_patch').read_bytes()),'inverse_sha256':sha((N/'Gate_and_index_INVERSE.apply_patch').read_bytes()),'target_count':2,'exact_before_and_after_bytes_checked':True,'full_inverse_bytes_equal':True,'canonical_writes':0,'engine_runs':0}
expected={'status':'ROOT_FINAL_GUARD_EXPECTATION_ONLY_NOT_GUARD_RESULT','baseline':str(basepath),'baseline_sha256':sha(raw),'source_count':base['source_count'],'save_count':base['save_count'],'authorized_targets':targets,'save_fact_policy':'Root finalguard must compare metadata SHA/bytes/exactticks only; this script never opens a save. Existing user historical changes retained.','all_other_baseline_sources_expected_unchanged':True,'layout_Router_EX_Region_Authority_expected_unchanged':True}
print('*** Begin Patch')
for name,value in [('reverse_proof_READY.json',proof),('finalguard_expected2_READY.json',expected)]:
 print('*** Add File: '+(N/name).as_posix())
 for line in json.dumps(value,ensure_ascii=False,indent=2).splitlines():print('+'+line)
print('*** End Patch')
