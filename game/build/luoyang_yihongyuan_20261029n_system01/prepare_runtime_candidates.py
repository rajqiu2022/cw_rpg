"""Mechanical candidates only; twelve canonical targets remain untouched."""
from pathlib import Path
import hashlib,json,difflib
GAME=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
PREFIX='res://build/luoyang_yihongyuan_20261029n_system01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def once(b,o,n):
 o=o.encode();n=n.encode()
 assert b.count(o)==1,(o[:100],b.count(o))
 return b.replace(o,n,1)
fieldpath='res://build/luoyang_regions_20261027d_source01/region_field.gd'
entrypath='res://build/luoyang_regions_20261027d_source01/region_entry.gd'
before={p:(GAME/p[6:]).read_bytes()for p in [fieldpath,entrypath]}
field=before[fieldpath]
changes=[
 ('var _region: Dictionary = {}','const YihongLayers = preload("'+PREFIX+'native_layers.gd")\nconst YihongDaily = preload("'+PREFIX+'ambient_conversation.gd")\nvar _yihong_daily: RefCounted = YihongDaily.new()\nvar _region: Dictionary = {}'),
 ('func _draw_room_enclosure() -> bool:\n\tif _region.get("navigation_kind") != "AUTHORED_INTERIOR": return true','func _draw_room_enclosure() -> bool:\n\tif _region.get("navigation_kind") != "AUTHORED_INTERIOR": return true\n\tif _region.get("id") == "yihongyuan27n_interior": return YihongLayers.complete_room_enclosure(self, _region_owner, _region)'),
 ('if not RegionChildren.install(self, _region_owner, row, sprite): _region_fail("SOURCE_DOOR_DEPTH_CHILD:" + key); return','if not RegionChildren.install(self, _region_owner, row, sprite): _region_fail("SOURCE_DOOR_DEPTH_CHILD:" + key); return\n\t\t\t\tif not YihongLayers.install(self, _region_owner, row, sprite): _region_fail("YIHONG_NATIVE_DEPTH:" + key); return'),
 ('\tvar dispatch: Variant = _region_logic.call("open", actor, "dialog", dialog_id)','\tif actor is NPCNode and _yihong_daily.handles(_region, actor):\n\t\tvar daily: Dictionary = _yihong_daily.open(self, actor)\n\t\tif daily.get("ok") != true: _region_fail("YIHONG_DAILY_SOURCE"); return\n\t\t_play_region_dispatch(daily); return\n\tvar dispatch: Variant = _region_logic.call("open", actor, "dialog", dialog_id)'),
 ('func _on_dialog_ended(id: StringName) -> void:\n','func _on_dialog_ended(id: StringName) -> void:\n\t_yihong_daily.finish(id)\n')]
for o,n in changes:field=once(field,o,n)
entry=before[entrypath]
entrychanges=[]
for marker,new in [
 ('const ALIASES := {','const ALIASES := {"yihongyuan27n_interior": "yihongyuan27n_interior", '),
 ('const SCENE_RESOURCES := {','const SCENE_RESOURCES := {"yihongyuan27n_interior": "res://data/scenes/yihongyuan27n_interior.tres", ')]:
 entry=once(entry,marker,new);entrychanges.append((marker,new))
targets=[]
for path,name,after,replacements in [(fieldpath,'region_field_READY.gd',field,changes),(entrypath,'region_entry_READY.gd',entry,entrychanges)]:
 inverse=after
 for o,n in reversed(replacements):inverse=once(inverse,n,o)
 assert inverse==before[path]
 target=OUT/name
 with target.open('xb')as f:f.write(after)
 targets.append({'target':'game/'+path[6:],'candidate':str(target.relative_to(GAME.parent)).replace('\\','/'),'old_sha256':sha(before[path]),'new_sha256':sha(after),'replacements':[{'old':o,'new':n}for o,n in replacements]})
modules={fieldpath:PREFIX+'region_field_READY.gd',entrypath:PREFIX+'region_entry_READY.gd','res://data/scenes/yihongyuan27n_interior.tres':PREFIX+'yihongyuan27n_interior.tres'}
for name in ['native_layers.gd','ambient_conversation.gd','room_factory.gd']:modules[PREFIX+name]=PREFIX+name
for name,value in [('runtime_modules_CANDIDATE.json',modules),('runtime_hunks_READY.json',{'canonical_writes':0,'targets':targets})]:
 with (OUT/name).open('xb')as f:f.write((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'candidate_targets':targets,'canonical_writes':0},ensure_ascii=False))
