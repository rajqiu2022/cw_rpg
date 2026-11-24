"""Reuse the actually-run non-early-return parse probe; never invokes Godot."""
from pathlib import Path
import json,hashlib,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return b
proofpin=dict(path=S+'prewarm_profile29_candidates01/code_execution_whole_inverse_NOT_STAGE.json',sha256='a32ab44edd0a8d3e72409f40ae89a118691b73398cf184761e59f0cf103e6982')
proof=json.loads(read(proofpin['path'],proofpin['sha256']))
oldpath=S+'parse_collect_remaining4_ROOTONLY/parse_ROOT_REVIEW.gd';old=read(oldpath,'052e871137ccd4c19009aa9982d8ee059b17b9878f6b81654bb3d6ab08142241')
prior=json.loads(read(S+'parse_collect_remaining4_ROOTONLY/input_ROOT_REVIEW.json','14df7fb667d43186aaa503f4f8ba7731a83e78641eb0949456313d05bf935837'))
rows=[dict(path=r['candidate']['path'],sha256=r['candidate']['sha256']) for r in proof['records'].values()]
rows.append(dict(path=proof['helper']['path'],sha256=proof['helper']['sha256']))
rows.extend(dict(path=p,sha256=h) for p,h in proof['purpose_ordinary_sources'].items() if p.endswith('.gd'))
assert len(rows)==len({r['path'] for r in rows})==9
for r in rows:read(r['path'],r['sha256'])
out=HERE/'prewarm_profile_parse9_NOTREADY';prefix=S+out.name+'/'
fixture=dict(ready=False,status='EXACT9_SOURCE_HEADER_HELPER_PROFILE_PARSE_ONLY_NOTREADY',scripts=rows,save_paths=prior['save_paths'],output_prefix=prefix+'output/',no_candidate_method_execution=True,no_new_instance_execution=True,no_Stage=True,profile_overview_admission_pending=True,source_proof=proofpin,no_inherited_parse_pass_for_these_new_SHA=True)
fr=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode();text=old.decode()
for a,b in [('const READY=true','const READY=false'),(S+'parse_collect_remaining4_ROOTONLY/input_ROOT_REVIEW.json',prefix+'input_NOTREADY.json'),('14df7fb667d43186aaa503f4f8ba7731a83e78641eb0949456313d05bf935837',sha(fr))]:
    assert text.count(a)==1;text=text.replace(a,b)
kr=text.encode();al=old.decode().splitlines(keepends=True);bl=text.splitlines(keepends=True);deltas=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_opcodes():
    if tag!='equal':deltas.append(dict(old_offset=len(''.join(al[:i]).encode()),new_offset=len(''.join(bl[:k]).encode()),old=''.join(al[i:j]),new=''.join(bl[k:l])))
f,rev=old,kr
for d in reversed(deltas):
    i=d['old_offset'];a,b=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+b+f[i+len(a):]
    i=d['new_offset'];assert rev[i:i+len(b)]==b;rev=rev[:i]+a+rev[i+len(b):]
assert f==kr and rev==old
assert not out.exists();out.mkdir()
for name,b in [('input_NOTREADY.json',fr),('parse_NOTREADY.gd',kr)]:
    with (out/name).open('xb') as stream:stream.write(b)
handoff=dict(status='EXACT9_PARSE_ONLY_ROOT_FREEZE_PENDING_NOT_EXECUTED',key=dict(path=prefix+'parse_NOTREADY.gd',sha256=sha(kr)),fixture=dict(path=prefix+'input_NOTREADY.json',sha256=sha(fr)),exact_GD_count=9,non_early_return=True,parent_key=dict(path=oldpath,sha256=sha(old)),key_whole_byte_forward_inverse=True,key_byte_hunks=deltas,ready=False,Root_runs_only=True,engine_calls=0,Stage_calls=0)
hr=(json.dumps(handoff,ensure_ascii=False,indent=2)+'\n').encode()
with (out/'handoff_NOTRUN.json').open('xb') as stream:stream.write(hr)
print(json.dumps(dict(key=handoff['key'],fixture=handoff['fixture'],handoff_sha256=sha(hr),scripts=9)))
