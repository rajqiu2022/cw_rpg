from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
p=N/'adjacent_courts_projection01_NOTREADY.gd';old=p.read_bytes();text=old.decode('utf8')
text=text.replace('"luoyang_riverside_garden_20261022ap":46','"luoyang_riverside_garden_20261022ap":56')
a='before: Array,new_kitchen: Dictionary={}) -> Dictionary:\n\tif not COUNTS.has(scene_id) or before.size()!=int(COUNTS[scene_id]): return {}'
b='''before: Array,new_kitchen: Dictionary={},navigation_before: Array=[]) -> Dictionary:
\tif not COUNTS.has(scene_id): return {}
\tif scene_id=="ch4_s2_canal_docks":
\t\t# Fixed NAV39 is distinct from visual rows after the original task policy.
\t\tif navigation_before.size()!=39: return {}
\t\tfor target: String in ["north_canal_warehouse","harbour_rope_shop","harbour_quay_supply_shop"]:
\t\t\tvar nav_matches: int=0;var visual_matches: int=0
\t\t\tfor old_nav: Dictionary in navigation_before:
\t\t\t\tif String(old_nav.get("id",""))==target: nav_matches+=1
\t\t\tfor old_visual: Dictionary in before:
\t\t\t\tif String(old_visual.get("id",""))==target: visual_matches+=1
\t\t\tif nav_matches!=1 or visual_matches!=1: return {}
\telif before.size()!=int(COUNTS[scene_id]): return {}'''
assert text.count(a)==1;text=text.replace(a,b)
text=text.replace('"old_passed_components_not_rebuilt":true}', '"old_passed_components_not_rebuilt":true,"Docks_NAV39_not_a_visual_count_gate":true,"old_navigation":navigation_before.duplicate(true)}')
raw=text.encode('utf8');out=N/'adjacent_courts_projection03_NOTREADY.gd'
with out.open('xb') as stream:stream.write(raw)
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+out.name,'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'parent_sha256':hashlib.sha256(old).hexdigest(),'Garden_expected_native_visuals':56,'Docks_NAV_and_visual_separated':True}))
