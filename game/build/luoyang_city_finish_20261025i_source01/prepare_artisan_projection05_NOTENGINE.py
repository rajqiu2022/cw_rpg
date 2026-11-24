from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
p=N/'artisan_block_projection04_NOTREADY.gd';old=p.read_bytes();assert hashlib.sha256(old).hexdigest()=='6892c892dea59bde16d34b403780399c605a34e1f23b2f772d06677212c35b2f'
text=old.decode('utf8')
a='\tif migration_ids.size()!=5: return {}\n'
b=a+'''\tif design.get("low_prop_migrations",[]).size()!=2: return {}
\tfor move: Dictionary in design.low_prop_migrations:
\t\tvar count: int=0
\t\tfor placement: Dictionary in next_scene.placements:
\t\t\tif String(placement.id)==String(move.id):
\t\t\t\tif v(placement.foot)!=v(move.old_foot_px): return {}
\t\t\t\tplacement.foot=move.new_foot_px.duplicate();count+=1
\t\tif count!=1: return {}
'''
assert text.count(a)==1;text=text.replace(a,b)
a='\t\trow["raw_BUILD_only_not_clean_imported_or_runtime_bound"]=true\n'
b=a+'''\t\trow["finish_source_size_px"]=measurement.raw_size.duplicate()
\t\trow["finish_source_anchor_px"]=measurement.manual_threshold_front_anchor_raw.duplicate()
\t\trow["finish_source_scale"]=ratio
\t\trow["finish_source_ground_polygons_px"]=lot.source_ground_polygons_raw_px.duplicate(true)
'''
assert text.count(a)==1;text=text.replace(a,b)
raw=text.encode('utf8');out=N/'artisan_block_projection05_NOTREADY.gd'
with out.open('xb') as stream:stream.write(raw)
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+out.name,'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'parent_sha256':hashlib.sha256(old).hexdigest()}))
