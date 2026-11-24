"""Remove an eager HUD class dependency from the QA harness, without runtime edits."""
import re
from desert_city_rework_20261029o import *
qa=ROOT/'game/build/desert_city_rework_20261029o_qa'
base=(ROOT/'game/build/three_towns_world_20261029j_qa01/trips_READY.gd').read_text('utf-8')
source=(qa/'world01.gd').read_text('utf-8').replace('extends "res://build/three_towns_world_20261029j_qa01/trips_READY.gd"','extends SceneTree').replace('fixture01.json','fixture02.json')
decl=base[base.index('var spec:'):base.index('func _initialize')]
source=source.replace('func _run() -> void:',decl+'\nfunc _initialize() -> void:_run.call_deferred()\nfunc _run() -> void:',1)
for name in ['need','point','active','file_facts','live_state','wait_world','wait_town','held_key','key','release_input']:
    match=re.search(r'^func '+name+r'\(.*?(?=^func |\Z)',base,re.M|re.S)
    assert match,name
    source+='\n'+match[0].rstrip()+'\n'
assert not (qa/'world02.gd').exists();(qa/'world02.gd').write_text(source,'utf-8')
runner=(ROOT/'scripts/run_desert_world_rework_20261029o.py').read_text('utf-8').replace('formal01','formal02').replace('fixture01','fixture02').replace('world01.gd','world02.gd')
(STAGE/'run_formal02.py').write_text(runner,'utf-8')
