"""Mechanical parse-only key/fixture. Root alone starts Godot."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
d=load(S+'dependencies33_READY/code_execution_whole_inverse_NOT_STAGE.json','d6b4c0afcaac7f8f29ca8c15b7412abafa90ad7418c4106a8d113622c715913e')
f=load(S+'runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad')
b=load(f['binding']['candidate']['path'],f['binding']['candidate']['sha256'])
protection=load(S+'fresh_24e_current_observation_READONLY.json','63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85')
scripts=[{k:r['candidate'][k] for k in ['path','sha256']} for r in d['records'].values()]
scripts.append({k:f['runtime']['candidate'][k] for k in ['path','sha256']})
scripts.append(dict(path=b['pure_path'],sha256=b['pure_sha256']))
scripts.append(dict(path='res://build/luoyang_city_blocks_20261024e_system01/market_purpose_layer03_clean_base_NOTREADY.gd',sha256='f6b636b4f395c3c35ce10315174e5539a3ea81cedcf665f6accddfc463779f2e'))
scripts.append(dict(path='res://build/luoyang_loading_20261024e_perf01/candidate03/gate_source_prewarm02.gd',sha256='03dec03dbfdd572042e566848d3231de56c1c45583fac4644cfccd99b3a81ed8'))
assert len(scripts)==len({r['path'] for r in scripts})==14
for r in scripts:assert sha((GAME/r['path'][6:]).read_bytes())==r['sha256']
out=HERE/'parse14_ROOTONLY';assert not out.exists();prefix=S+'parse14_ROOTONLY/';inputpath=prefix+'input_ROOT_REVIEW.json'
spec=dict(ready=True,status='ROOT_REQUESTED_PARSE_ONLY_SOURCE_PREPARED_NOT_EXECUTED',scripts=scripts,save_paths=[r['path'] for r in protection['current_save_protection_start']],output_prefix=prefix+'output/',no_candidate_method_execution=True,no_new_instance_execution=True,no_Stage=True)
raw=(json.dumps(spec,ensure_ascii=False,indent=2)+'\n').encode();template=(HERE/'parse_all_changed_template_NOTREADY.gd').read_bytes();assert sha(template)=='987352e63aba56751bce6c644753ea3ffe2be07437149a40acc3776df2fd3f9d'
key=template;ops=[('const READY=false','const READY=true'),('PENDING_FINAL_PARSE_INPUT',inputpath),('PENDING_FINAL_PARSE_INPUT_SHA',sha(raw))]
# Replace the longer SHA placeholder before its path substring.
ops=[ops[0],ops[2],ops[1]]
for a,c in ops:
    a,c=a.encode(),c.encode();assert key.count(a)==1;key=key.replace(a,c,1)
back=key
for a,c in reversed(ops):
    a,c=a.encode(),c.encode();assert back.count(c)==1;back=back.replace(c,a,1)
assert back==template
out.mkdir()
for name,data in [('input_ROOT_REVIEW.json',raw),('parse_ROOT_REVIEW.gd',key)]:
    with (out/name).open('xb') as stream:stream.write(data)
proof=dict(status='PARSE14_PREPARED_NOT_EXECUTED',input=dict(path=inputpath,sha256=sha(raw)),key=dict(path=prefix+'parse_ROOT_REVIEW.gd',sha256=sha(key)),template_sha256=sha(template),replacements=[dict(old=a,new=c) for a,c in ops],wholebyte_inverse=True,scripts_count=14,root_only=True,engine_calls=0)
praw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode()
with (out/'handoff_NOTRUN.json').open('xb') as stream:stream.write(praw)
print(json.dumps(dict(handoff=prefix+'handoff_NOTRUN.json',sha256=sha(praw),input=proof['input'],key=proof['key'])))
