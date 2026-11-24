from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent
p=N/'author_artisan_residential_block05_routes_props_NOTREADY.json';raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()=='c8891094cc151c716bb3a507b9398fb42d6576496bdcecee972cf780c6f0f6c5'
old=json.loads(raw);new=copy.deepcopy(old)
new['threshold_short_cross_controls']=[{'id':'forge_threshold_north8','points_px':[[480,1840],[480,1832]],'source_raw_inside_point_expression':[560,'789-8/(760/1487)'],'player_body_px':[34,24]}, {'id':'pottery_threshold_north8','points_px':[[2190,1840],[2190,1832]],'source_raw_inside_point_expression':[590,'844-8/(170/297)'],'player_body_px':[34,24]}]
new['threshold_short_cross_scope']='Root-approved eight-pixel threshold crossing only; 8 < player half-depth12, not a claim that the whole body is inside or the whole floor witness is open NAV.'
assert {k:v for k,v in new.items() if k not in ['threshold_short_cross_controls','threshold_short_cross_scope']}==old
out=N/'author_artisan_residential_block06_threshold_short_cross_NOTREADY.json';b=(json.dumps(new,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as stream:stream.write(b)
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+out.name,'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'parent_sha256':hashlib.sha256(raw).hexdigest(),'new_fields_only':True,'original_routes11_and_geometry_exact':True}))
