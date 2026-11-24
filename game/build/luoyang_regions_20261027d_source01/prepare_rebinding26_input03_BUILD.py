"""Bind only corrected metadata/index DAG and new Stage output; driver unchanged."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_source_rebind_repair02';sha=lambda b:hashlib.sha256(b).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix()
bp=N/'source_rebinding02_BUILD/closure26_META03/source_rebind26_all_candidates_NOT_STAGE.json';br=bp.read_bytes();assert sha(br)=='01811684c804753c8c4b80fee62d7a9a16c51310e9dadbb869c644eaa355c622';bundle=json.loads(br)
parent=O/'source_input_rebind26_ROOT_REVIEW02.json';raw=parent.read_bytes();assert sha(raw)=='6ba60cc89d1fad617dcf2a618a2783164848e296541e077ff43a2e12f75ea6a7';old=json.loads(raw);value=copy.deepcopy(old)
row=next(r for r in value['pinned_inputs']if r['id']=='candidates');row.update(path=res(bp),sha256=sha(br),bytes=len(br))
value['declared_candidates']={r['target']:r['candidate']for r in bundle['targets']}
for row in value['prospective_targets']:
 if row['target']in value['declared_candidates']:
  pin=value['declared_candidates'][row['target']];row.update(candidate_path=pin['path'],sha256=pin['sha256'])
value['output_root']='res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_source_rebind26_stage03/'
back=copy.deepcopy(value)
for key in ['declared_candidates','prospective_targets','output_root']:back[key]=old[key]
next(r for r in back['pinned_inputs']if r['id']=='candidates').update(next(r for r in old['pinned_inputs']if r['id']=='candidates'))
assert back==old
inp=O/'source_input_rebind26_ROOT_REVIEW03.json';assert not inp.exists();inp.write_bytes((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode())
gp=S/'guard_region_source_rebind26_current2121_ROOT_ONLY.py';before=gp.read_bytes();text=before.decode()
edits=[('source_rebinding02_BUILD/closure26/source_rebind26_all_candidates_NOT_STAGE.json','source_rebinding02_BUILD/closure26_META03/source_rebind26_all_candidates_NOT_STAGE.json'),('5b9cabaa211abcf1c1cf1b5a2ddc1115dcb02eb5764983dadfbc74ac7ed0a77e','01811684c804753c8c4b80fee62d7a9a16c51310e9dadbb869c644eaa355c622')]
for a,b in edits:assert text.count(a)==1;text=text.replace(a,b,1)
inv=text
for a,b in reversed(edits):assert inv.count(b)==1;inv=inv.replace(b,a,1)
assert inv.encode()==before;compile(text,'guard_region_source_rebind26_current2121_ROOT_ONLY03.py','exec')
guard=S/'guard_region_source_rebind26_current2121_ROOT_ONLY03.py';assert not guard.exists();guard.write_bytes(text.encode())
print(json.dumps({'input':{'path':res(inp),'sha256':sha(inp.read_bytes()),'bytes':len(inp.read_bytes())},'driver_unchanged':'140f5885e5d7977d5ad930d7a2f01b7cb3024c8fcd4a6108254311cc3d172c0a','guard':{'path':res(guard),'sha256':sha(guard.read_bytes()),'bytes':len(guard.read_bytes())},'input_inverse':True,'guard_whole_UTF8_inverse':True,'Stage_executed':False}))
