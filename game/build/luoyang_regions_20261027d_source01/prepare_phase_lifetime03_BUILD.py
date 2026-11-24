"""Keep the actual phase Callable owner alive; no phase/business changes."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];O=N/'phase_lifetime03_BUILD';sha=lambda b:hashlib.sha256(b).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix()
parent=N/'region_field.gd';raw=parent.read_bytes();assert sha(raw)=='c8930e13dba3073343c6c013a10b1776a844b5fef16572049b576ec79cf19d11'
edits=[('var _region_phase_projector: Callable\n','var _region_phase_projector: Callable\nvar _region_phase_owner: RefCounted\n'),('\tif not _region.is_empty() or not compiled.get("ok", false) or not phase_projector.is_valid(): return false\n','\tif not _region.is_empty() or not compiled.get("ok", false) or not phase_projector.is_valid(): return false\n\tvar phase_owner: RefCounted = phase_projector.get_object() as RefCounted\n\tif phase_owner == null or phase_owner.get_script() == null or phase_owner.get_script().resource_path != "res://build/luoyang_regions_20261027d_source01/region_phase_scope.gd" or phase_projector.get_method() != &"project": return false\n'),('\t_region = compiled.duplicate(true); _region_sources = declared_sources.duplicate(true); _region_entry = entry; _region_phase_projector = phase_projector\n','\t_region = compiled.duplicate(true); _region_sources = declared_sources.duplicate(true); _region_entry = entry; _region_phase_projector = phase_projector\n\t_region_phase_owner = phase_owner\n')]
text=raw.decode()
for a,b in edits:assert text.count(a)==1;text=text.replace(a,b,1)
back=text
for a,b in reversed(edits):assert back.count(b)==1;back=back.replace(b,a,1)
assert back.encode()==raw
assert not O.exists();O.mkdir();candidate=O/'region_field_phase_owner_CANDIDATE.gd';candidate.write_bytes(text.encode())
manifest_path=N/'region_runtime_manifest_BUILD.json';mr=manifest_path.read_bytes();assert sha(mr)=='77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff'
m=json.loads(mr);assert m['runtime_modules'][res(parent)]==sha(raw);m['runtime_modules'][res(parent)]=sha(text.encode());mc=O/'region_runtime_manifest_candidate.json';mc.write_bytes((json.dumps(m,ensure_ascii=False,indent=2)+'\n').encode())
old_router=G/'scripts/autoload/scene_router.gd';rr=old_router.read_bytes();assert sha(rr)=='8c70847f2827137615b6e5c0f1d30b6b91a8f2cb5c663d0a0725b6a856959202'
assert rr.count(sha(mr).encode())==1;rc=O/'Router_phase_manifest_CANDIDATE.gd';rc.write_bytes(rr.replace(sha(mr).encode(),sha(mc.read_bytes()).encode(),1));assert rc.read_bytes().count(b'\r\n')==13
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
proof=dict(status='ACTUAL102304_PHASE_REFCOUNT_LIFETIME_REPAIR_NOT_ENGINE',Field=dict(parent=pin(parent),candidate=pin(candidate),target=res(parent),hunks=[dict(old=a,new=b)for a,b in edits],whole_UTF8_inverse=True),manifest=dict(parent=pin(manifest_path),candidate=pin(mc),target=res(manifest_path),only_runtime_modules_RegionField_SHA=True),Router=dict(parent=pin(old_router),candidate=pin(rc),only_manifest_SHA_literal=True,crlf13_preserved=True),phase_business_unchanged=True,compiled_nine_and_terminals_unchanged=True,canonical_writes=0,engine_calls=0)
out=O/'phase_owner_strong_reference_whole_inverse_BUILD.json';out.write_bytes((json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode());print(json.dumps(dict(proof=pin(out),Field=pin(candidate),manifest=pin(mc),Router=pin(rc))))
