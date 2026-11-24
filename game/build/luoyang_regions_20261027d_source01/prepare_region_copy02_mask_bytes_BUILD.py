"""Single real-schema repair: Gate mask length from fixed Root backup media fact."""
from pathlib import Path
import hashlib, json
G=Path(__file__).resolve().parents[2];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_integration_20261027d01'
sha=lambda b:hashlib.sha256(b).hexdigest()
parent=S/'copy_region_integration32_JSON14_after_GD18_ROOT_ONLY.py';raw=parent.read_bytes()
assert sha(raw)=='4dbc207fbed9d7dc5cc68a730deaadd1a1e74a5cd128e3dd5cf8361df22dc920'
old="publication=load(GATE_PUBLICATION,stage['source_first'][GATE_PUBLICATION]);m=publication['mask'];f=fact(m['path']);assert f['sha256']==m['sha256']and f['bytes']==m['bytes'];protect(m['path'],f);adopted_media_facts.append(dict(path=m['path'],**f))"
new="publication=load(GATE_PUBLICATION,stage['source_first'][GATE_PUBLICATION]);m=publication['mask'];mf=[r for r in backup['media_facts']if r['path']==m['path']];assert len(mf)==1 and mf[0]['sha256']==m['sha256'];f=fact(m['path']);assert f['sha256']==m['sha256']and f['bytes']==mf[0]['bytes'];protect(m['path'],f);adopted_media_facts.append(dict(path=m['path'],**f))"
text=raw.decode();assert text.count(old)==1;text=text.replace(old,new,1)
assert text.count(new)==1 and text.replace(new,old,1).encode()==raw
compile(text,'copy_region_integration32_JSON14_after_GD18_ROOT_ONLY02.py','exec')
dest=S/'copy_region_integration32_JSON14_after_GD18_ROOT_ONLY02.py';assert not dest.exists();dest.write_bytes(text.encode())
proof={'parent':{'path':'res://'+parent.relative_to(G).as_posix(),'sha256':sha(raw)},'candidate':{'path':'res://'+dest.relative_to(G).as_posix(),'sha256':sha(dest.read_bytes()),'bytes':len(dest.read_bytes())},'hunks':[{'old':old,'new':new}],'whole_UTF8_inverse':True,'fixed_backup_Gate_mask_bytes':30959,'Stage_or_canonical_execution':False}
out=O/'copy02_mask_bytes_transport_whole_inverse_NOT_EXECUTED.json';assert not out.exists();out.write_bytes((json.dumps(proof,indent=2)+'\n').encode())
print(json.dumps({'tool':proof['candidate'],'proof':{'path':'res://'+out.relative_to(G).as_posix(),'sha256':sha(out.read_bytes())}}))
