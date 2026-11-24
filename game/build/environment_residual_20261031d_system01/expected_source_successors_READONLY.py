from pathlib import Path
import hashlib,json

root=Path('F:/Code/RPG_GAME')
def sha(data):return hashlib.sha256(data).hexdigest()
rows=[]
for path,expected,pairs in [
 ('game/build/three_towns_world_20261029j_system01/world_watcher.gd','89b15bbbb09622e141cf90d3140d1fdc4c659160d3d3db96bedd2cb2ef984d19',[
  (b'const WORLD31C=preload("res://build/world_landmarks_20261031c/refinement.gd")\n',b'const WORLD31C=preload("res://build/world_landmarks_20261031c/refinement.gd")\nconst DEPTH31D=preload("res://build/environment_residual_20261031d_system01/landmark_depth.gd")\n'),
  (b'\t\t\tsprite.z_index=clampi(roundi(float(raw.foot[1])/8.0),-4096,4095)\n',b'\t\t\tsprite.z_index=clampi(roundi(float(raw.foot[1])/8.0),-4096,4095)\n\t\t\tDEPTH31D.align(sprite,world_owner.get("_actor_layer") as Node2D)\n')]),
 ('game/scenes/drafts/huashan_map_20261029m/huashan.tscn','44103dc38beb9472b303c17c8d2fe3aa74d9f2fd5b10a8d2834659b7f10ad4b9',[
  (b'path="res://build/sect_repair_20261031c_system01/huashan_controller.gd"',b'path="res://build/environment_residual_20261031d_system01/huashan_controller.gd"')])]:
 before=(root/path).read_bytes();assert sha(before)==expected,(path,sha(before))
 after=before
 for old,new in pairs:
  assert after.count(old)==1
  after=after.replace(old,new)
 inverse=after
 for old,new in reversed(pairs):
  assert inverse.count(new)==1
  inverse=inverse.replace(new,old)
 assert inverse==before
 rows.append(dict(path=path,before_sha256=sha(before),before_bytes=len(before),after_sha256=sha(after),after_bytes=len(after),exact_inverse=True,replacements=len(pairs),source_writes=0))
print(json.dumps({'status':'PROSPECTIVE_ROOT_APPLY_ONLY','rows':rows,'PNG_writes':0,'engine_runs':0},indent=2))
