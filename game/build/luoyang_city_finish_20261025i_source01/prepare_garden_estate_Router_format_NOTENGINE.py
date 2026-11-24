"""Reuse sole Router13CRLF Root formatter for the exact two-hunk lifecycle candidate; no execution."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';O=N/'garden_estate_exit_repair_20261027c01';sha=lambda b:hashlib.sha256(b).hexdigest()
parent=(N/'docks_gallery_family_repair01/restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py').read_bytes();t=parent.decode('utf8');hs=[]
for a,b in [('build/luoyang_city_finish_20261025i_system01/family_direct_entry01_NOTREADY/Router_family_direct_exactEOL_CANDIDATE.gd','build/luoyang_garden_estate_exit_20261027c_system01/Router_garden_estate_CANDIDATE.gd'),('e983a3b2b8c3cc031262100755c1f9e2f37c03a618d1a0a4cf268f8c6ccd3745','2687a0d72d6bf34654894905b9caf2082c3fdf97e7db4633e518996569d2650c'),('luoyang_city_finish_20261025i_source01/docks_gallery_family_repair01','luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01')]:
 assert t.count(a)==1;t=t.replace(a,b,1);hs.append(dict(old=a,new=b))
f=t
for h in reversed(hs):assert f.count(h['new'])==1;f=f.replace(h['new'],h['old'],1)
assert f.encode()==parent;compile(t,'restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py','exec');dest=O/'restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(t.encode('utf8'))
proof=dict(parent=dict(path=S+'docks_gallery_family_repair01/restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py',sha256=sha(parent)),candidate=dict(path=S+'garden_estate_exit_repair_20261027c01/'+dest.name,sha256=sha(t.encode('utf8'))),hunks=hs,whole_UTF8_inverse=True,format_execution_calls=0,canonical_writes=0)
raw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf8');out=O/'Router_formatter_transport_whole_inverse_NOT_EXECUTED.json';assert not out.exists()
with out.open('xb')as f:f.write(raw)
print(json.dumps(dict(tool=proof['candidate'],proof_sha256=sha(raw))))
