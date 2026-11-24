from pathlib import Path
import hashlib,json
p=Path('F:/Code/RPG_GAME/game/build/three_towns_world_20261029j_system01/world_watcher.gd')
data=p.read_bytes()
replacements=[
 (b'const WORLD31C=preload("res://build/world_landmarks_20261031c/refinement.gd")\n',b''),
 (b'\toverlay_root.set_meta("foreground_name_count",WORLD31C.raise_names(field))\n',b''),
 (b'\t\tresult.roads.append({"width":raw.width_px,"points":raw.points_px,"source_id":raw.id})\n',b'\t\tresult.roads.append({"width":raw.width_px,"points":raw.points_px})\n'),
 (b'\t\tfor sprite: Dictionary in WORLD31C.sprites(raw):\n',b'\t\tfor sprite: Dictionary in raw.sprites:\n'),
 (b'\t\tvar path: PackedVector2Array=WORLD31C.route(raw)\n',b'\t\tvar path:=PackedVector2Array()\n\t\tfor p: Array in raw.points:path.append(Vector2(p[0],p[1]))\n'),
 (b'\t\t\tWORLD31C.blend_path(ground,raw,path)\n',b''),
 (b'\t\t\tsprite.texture=WORLD31C.texture(raw.path)\n',b'\t\t\tsprite.texture=load(raw.path)\n')]
old=data
for new,prior in replacements:
    assert old.count(new)==1,new
    old=old.replace(new,prior)
digest=hashlib.sha256(old).hexdigest()
assert digest=='4039dc896fa152890bc828761d748a9d1da8e94bc73b1abe9170f213d1a48986'
assert len(old)==8312
print(json.dumps(dict(current_sha256=hashlib.sha256(data).hexdigest(),inverse_sha256=digest,inverse_bytes=len(old),matches_historical_auth_FINAL=True,fresh_baseline_included_world_watcher=False,old_mtime_not_claimed=True,source_writes=0)))
