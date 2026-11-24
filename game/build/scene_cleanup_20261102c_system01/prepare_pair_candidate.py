"""One fixed Docks/Garden mouth successor. Does not change canonical files."""
from pathlib import Path
import hashlib,json
HOME=Path(__file__).resolve().parent
GAME=HOME.parents[1]
path='res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd'
original=(GAME/path[6:]).read_bytes()
old=b'"docks_to_garden",Vector2(512,1840),Vector2(616,1840),Vector2(-1,0),[Vector2(512,1840)]'
new=b'"docks_to_garden",Vector2(96,1216),Vector2(200,1216),Vector2(-1,0),[Vector2(512,1840)]'
assert original.count(old)==1
child=original.replace(old,new,1)
assert child.replace(new,old,1)==original
(HOME/'navigation_pairs_READY.gd').write_bytes(child)
plan={'path':path,'before_sha256':hashlib.sha256(original).hexdigest(),'after_sha256':hashlib.sha256(child).hexdigest(),'candidate':'res://build/scene_cleanup_20261102c_system01/navigation_pairs_READY.gd','old':old.decode(),'new':new.decode(),'whole_inverse':True,'changed_endpoint':'docks_garden/a','mouth':[96,1216],'arrival':[200,1216],'retired_original':[512,1840],'GardenB_own_spec_unchanged':True,'GardenB_target_return_derived_from_same_A_arrival':[200,1216],'old_market_exit':[260,1740],'new_distance_to_market_exit':((96-260)**2+(1216-1740)**2)**.5,'source_rows_other21_own_spec_unchanged':True,'status':'CANDIDATE_REQUIRES_ROOT_STATIC_FULL_FOOT_AND_ACTUAL_NEW_PAIR_BOTH_DIRECTIONS'}
(HOME/'pair_successor_READY.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(plan,ensure_ascii=False))
