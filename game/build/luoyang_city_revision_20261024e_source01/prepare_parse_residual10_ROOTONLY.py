"""Exactly unexecuted/new scripts, inherit only four actual successful rows."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
old=HERE/'parse14_ROOTONLY/input_ROOT_REVIEW.json';oldraw=old.read_bytes();assert sha(oldraw)=='f73f66c9f961149ea298093b86dc088a3a3dc8547c290588677bbb8fe67d6b59';spec=json.loads(oldraw)
actualpath=S+'parse14_ROOTONLY/output/106948/result.json';actualraw=(GAME/actualpath[6:]).read_bytes();actual=json.loads(actualraw)
assert len(actual['rows'])==5 and actual['source_first']==actual['source_final'] and actual['save_first']==actual['save_final'] and actual['rows'][-1]['can_instantiate'] is False
passed={r['path']:r['sha256'] for r in actual['rows'] if r['can_instantiate'] is True};assert len(passed)==4
prpath=S+'Router_receiver_residual02_READY/code_execution_whole_inverse_NOT_STAGE.json';prraw=(GAME/prpath[6:]).read_bytes();assert sha(prraw)=='f9477c1d8f3f4989128b91f95043bc257e4e6647525767aad74d570223f37cc5';p=json.loads(prraw)
replacements={}
for name in ['Router','Coordinator','Temple']:
    r=next(r for r in p['records'].values() if r['name']==name)
    # Old exact candidate map from the original 14 fixture, not runtime data.
    oldr=next(r for r in spec['scripts'] if Path(r['path']).name==name+'_READY.gd' or (name in ['Coordinator','Temple'] and Path(r['path']).name==name+'_CANDIDATE.gd'))
    replacements[oldr['path']]={k:r['candidate'][k] for k in ['path','sha256']}
remaining=[]
for row in spec['scripts']:
    if row['path'] in passed:
        assert passed[row['path']]==row['sha256'];continue
    remaining.append(replacements.get(row['path'],row))
assert len(remaining)==len({r['path'] for r in remaining})==10
for row in remaining:assert sha((GAME/row['path'][6:]).read_bytes())==row['sha256']
out=HERE/'parse_residual10_ROOTONLY';assert not out.exists();prefix=S+'parse_residual10_ROOTONLY/';inp=prefix+'input_ROOT_REVIEW.json'
spec.update(scripts=remaining,output_prefix=prefix+'output/',inherited_actual_four_passed=dict(path=actualpath,sha256=sha(actualraw),scripts=passed),status='ROUTER_RECEIVER_PLUS_UNEXECUTED_PARSE_RESIDUAL_NOT_RUN')
raw=(json.dumps(spec,ensure_ascii=False,indent=2)+'\n').encode();template=(HERE/'parse_all_changed_template_NOTREADY.gd').read_bytes();assert sha(template)=='987352e63aba56751bce6c644753ea3ffe2be07437149a40acc3776df2fd3f9d';key=template
ops=[('const READY=false','const READY=true'),('PENDING_FINAL_PARSE_INPUT_SHA',sha(raw)),('PENDING_FINAL_PARSE_INPUT',inp)]
for a,b in ops:
    a,b=a.encode(),b.encode();assert key.count(a)==1;key=key.replace(a,b,1)
v=key
for a,b in reversed(ops):
    a,b=a.encode(),b.encode();assert v.count(b)==1;v=v.replace(b,a,1)
assert v==template;out.mkdir()
for name,b in [('input_ROOT_REVIEW.json',raw),('parse_ROOT_REVIEW.gd',key)]:
    with (out/name).open('xb') as stream:stream.write(b)
pr=dict(status='EXACT_PARSE_RESIDUAL_TEN_NOT_EXECUTED',key=dict(path=prefix+'parse_ROOT_REVIEW.gd',sha256=sha(key)),input=dict(path=inp,sha256=sha(raw)),old14_wholeFAIL_preserved=True,only_actual_four_rows_inherited=True,template_sha256=sha(template),replacements=[dict(old=a,new=b) for a,b in ops],wholebyte_inverse=True,engine_calls=0)
b=(json.dumps(pr,ensure_ascii=False,indent=2)+'\n').encode()
with (out/'handoff_NOTRUN.json').open('xb') as stream:stream.write(b)
print(json.dumps(dict(handoff_path=prefix+'handoff_NOTRUN.json',handoff_sha256=sha(b),key=pr['key'],input=pr['input'])))
