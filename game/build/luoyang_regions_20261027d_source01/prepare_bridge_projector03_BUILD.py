"""Mechanical business-bridge dependency successor, not an engine operation."""
from pathlib import Path
import hashlib,json,difflib
N=Path(__file__).resolve().parent;G=N.parents[1]
P=G/'build/luoyang_city_rectification_20261027d_system01'
sha=lambda raw:hashlib.sha256(raw).hexdigest()
parent=P/'logical_context_bridge.gd';before=parent.read_bytes()
assert sha(before)=='9ea4fd4ee8fde845d6d346a7c95e2bdceb1379513e0482c1b8225157afc4cdbf'
old=b'res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector.gd'
new=b'res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector03_market_task_space.gd'
assert before.count(old)==2
intermediate=before.replace(old,new)
destination=N/'logical_context_bridge_projector03_SELF_BUILD.gd'
old_self=b'const SELF="res://build/luoyang_city_rectification_20261027d_system01/logical_context_bridge.gd"'
new_self=('const SELF="res://'+destination.relative_to(G).as_posix()+'"').encode()
assert intermediate.count(old_self)==1
after=intermediate.replace(old_self,new_self)
assert after.replace(new_self,old_self).replace(new,old)==before
assert sha((P/'logical_terminal_projector03_market_task_space.gd').read_bytes())=='819ecab34a6e5d4c57f4a5de562fcf710b63563aa22f85615a49bd779fae1d90'
assert not destination.exists()
destination.write_bytes(after)
proof={'status':'BUILD_MECHANICAL_SELF_AND_DEPENDENCY_PATH_ONLY_NOT_RUNTIME','parent':{'path':'res://'+parent.relative_to(G).as_posix(),'sha256':sha(before)},'candidate':{'path':'res://'+destination.relative_to(G).as_posix(),'sha256':sha(after)},'replacement_count':3,'whole_reverse_equal':after.replace(new_self,old_self).replace(new,old)==before,'diff':list(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True)))}
out=N/'bridge_projector03_SELF_dependency_inverse_BUILD02.json';assert not out.exists()
out.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
print(json.dumps(proof['candidate']))
