"""Finite wholebyte proof for the new Art02 candidate; no engine/old writes."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
old=ROOT/'game/build/luoyang_temple_adult_20261101d_art01/live_art_view.gd'
new=HERE/'live_art_view.gd'
a=old.read_bytes();b=new.read_bytes()
sha=lambda v:hashlib.sha256(v).hexdigest()
assert sha(a)=='e261426562db34f3edeb400b1c85e05e5a496ffb09995dd0e25bd2922a05f394'
pairs=[
 (b'## New independent runtime presentation/physics overlay. Root must source-pin',b'## Art02 successor: use the original parent-relative Region depth basis.\n## New independent runtime presentation/physics overlay. Root must source-pin'),
 (b'const SELF := HOME + "live_art_view.gd"',b'const SELF := "res://build/luoyang_temple_adult_20261101d_art02/live_art_view.gd"'),
 (b'_quad.z_as_relative=false;_quad.z_index=int(floor(FRONT/8.0));',b'_quad.z_as_relative=true;_quad.z_index=int(floor(FRONT/8.0));')
]
forward=a;inverse=b
for before,after in pairs:
    assert forward.count(before)==1 and inverse.count(after)==1
    forward=forward.replace(before,after,1);inverse=inverse.replace(after,before,1)
assert forward==b and inverse==a
report={'status':'EXACT_ART02_CANDIDATE_NOT_ADOPTED_NOT_RUNTIME_TESTED','parent_path':old.relative_to(ROOT).as_posix(),'parent_sha256':sha(a),'candidate_path':new.relative_to(ROOT).as_posix(),'candidate_sha256':sha(b),'wholebyte_forward_inverse':True,'only_behavior_change':'new quad z_as_relative false to true; same365local basis as other Region visuals under WorldContainer-100','other_changes':['candidate SELF path','explanatory comment'],'root_rejected_evidence':'game/build/city_navigation_20261101d_visual05/actual/91216/temple_scripture_hall_adult_scale_normal.png','source_cause':'base_field_scene_snapshot01.tscn WorldContainerz=-100; absolute quad365 bypassed parent while actor relative footbands were reduced100','expected_depths_not_actual_observation':{'quad_local':365,'quad_effective':265,'player_front2990_effective_approx':273,'monk_front2950_effective_approx':268},'physics_geometry_media_actor_z_or_opacity_changes':0,'old_source_writes':0,'engine_runs':0,'production96_refreeze':False}
p=HERE/'successor_proof_READY.json'
with p.open('x',encoding='utf-8',newline='\n') as f:f.write(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report))
