from pathlib import Path
import hashlib,json
root=Path('F:/Code/RPG_GAME')
def sha(data):return hashlib.sha256(data).hexdigest()
watch_path='game/build/three_towns_world_20261029j_system01/world_watcher.gd'
current=(root/watch_path).read_bytes()
assert sha(current)=='c131ea0bc134f1f74c14280ea73e80dcb833ac10166ab961e44b8034a3b3b9ac'
inverse=current
for added in [b'const DEPTH31D=preload("res://build/environment_residual_20261031d_system01/landmark_depth.gd")\n',b'\t\t\tDEPTH31D.align(sprite,world_owner.get("_actor_layer") as Node2D)\n']:
 assert inverse.count(added)==1
 inverse=inverse.replace(added,b'')
assert sha(inverse)=='89b15bbbb09622e141cf90d3140d1fdc4c659160d3d3db96bedd2cb2ef984d19'
source_path='game/build/sect_repair_20261031c_system01/huashan_READY.tscn'
source=(root/source_path).read_bytes()
assert sha(source)=='44103dc38beb9472b303c17c8d2fe3aa74d9f2fd5b10a8d2834659b7f10ad4b9'
old=b'path="res://build/sect_repair_20261031c_system01/huashan_controller.gd"'
new=b'path="res://build/environment_residual_20261031d_system01/huashan_controller.gd"'
assert source.count(old)==1
candidate=source.replace(old,new)
assert candidate.replace(new,old)==source
print(json.dumps(dict(watcher=dict(path=watch_path,current_sha256=sha(current),inverse_sha256=sha(inverse),inverse_exact=True),huashan=dict(before_snapshot=source_path,before_sha256=sha(source),before_bytes=len(source),prospective_sha256=sha(candidate),prospective_bytes=len(candidate),source_path_replacements=1,all_other_bytes_exact=True),engine_runs=0,production_writes=0,PNG_writes=0),indent=2))
