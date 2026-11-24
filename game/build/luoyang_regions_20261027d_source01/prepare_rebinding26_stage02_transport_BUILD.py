"""Fix only the manifest parent's scope-row shape for checked_candidate."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_source_rebind_repair02';sha=lambda b:hashlib.sha256(b).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix()
parent=S/'stage_region_source_rebind26_ROOT_ONLY.py';raw=parent.read_bytes();assert sha(raw)=='0571a9ef46fe14238c7ad661d21b41bfe23bf0803490697de51de9666a7c5dc1'
old="self.checked_candidate(manifest_target,{'parent':self.parents[manifest_target],'candidate':rebind['manifest_candidate']})"
new="self.checked_candidate(manifest_target,{'parent':{'path':self.parents[manifest_target]['immutable_old'],'sha256':self.parents[manifest_target]['old_sha256'],'bytes':self.parents[manifest_target]['old_bytes']},'candidate':rebind['manifest_candidate']})"
text=raw.decode();assert text.count(old)==1;text=text.replace(old,new,1);assert text.replace(new,old,1).encode()==raw;compile(text,'stage_region_source_rebind26_ROOT_ONLY02.py','exec')
driver=S/'stage_region_source_rebind26_ROOT_ONLY02.py';assert not driver.exists();driver.write_bytes(text.encode())
ip=O/'source_input_rebind26_ROOT_REVIEW.json';before=ip.read_bytes();assert sha(before)=='f4b85265eced2e5574fa1f65fc45bb8220c0c1ae6989af627d1e7c9c4326d864'
value=json.loads(before);old_driver=next(r for r in value['pinned_inputs']if r['id']=='driver').copy();row=next(r for r in value['pinned_inputs']if r['id']=='driver');row.update(path=res(driver),sha256=sha(text.encode()),bytes=len(text.encode()));old_output=value['output_root'];value['output_root']='res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_source_rebind26_stage02/'
inp=O/'source_input_rebind26_ROOT_REVIEW02.json';assert not inp.exists();inp.write_bytes((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode())
back=json.loads(inp.read_bytes());next(r for r in back['pinned_inputs']if r['id']=='driver').update(old_driver);back['output_root']=old_output;assert back==json.loads(before)
proof=O/'Stage02_parent_shape_transport_inverse_NOT_EXECUTED.json';proof.write_bytes((json.dumps(dict(parent_driver_sha256=sha(raw),candidate_driver_sha256=sha(driver.read_bytes()),hunks=[dict(old=old,new=new)],whole_UTF8_inverse=True,input_only_driver_and_output_changed=True,Stage_executed=False),indent=2)+'\n').encode())
print(json.dumps(dict(driver=dict(path=res(driver),sha256=sha(driver.read_bytes()),bytes=len(driver.read_bytes())),input=dict(path=res(inp),sha256=sha(inp.read_bytes()),bytes=len(inp.read_bytes())),inverse=dict(path=res(proof),sha256=sha(proof.read_bytes())))))
