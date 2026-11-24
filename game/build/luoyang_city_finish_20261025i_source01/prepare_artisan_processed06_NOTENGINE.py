from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
p=N/'artisan_block_projection05_NOTREADY.gd';old=p.read_bytes();assert hashlib.sha256(old).hexdigest()=='b0dc87f796eca022df1889afcb35541eefa1d2ea2c222ce8e96a3fdd795072dd'
t=old.decode('utf8')
t=t.replace('design: Dictionary) -> Dictionary:','design: Dictionary,processed: Dictionary) -> Dictionary:')
a='\t\tvar row: Dictionary=render_row(String(lot.asset_id),asset,foot,ratio,polygons)\n'
b='''\t\tvar admitted: Dictionary={}
\t\tfor source: Dictionary in processed.get("rows",[]):
\t\t\tif String(source.raw_sha256)==String(measurement.raw_sha256): admitted=source
\t\tif admitted.is_empty() or v(admitted.raw_threshold_anchor_xy)!=v(measurement.manual_threshold_front_anchor_raw): return {}
\t\tif admitted.uniform_scale_numerator_denominator!=[lot.uniform_source_expression.numerator,lot.uniform_source_expression.denominator]: return {}
\t\tif v(admitted.padded_threshold_anchor_xy)!=v(admitted.raw_threshold_anchor_xy)+v(admitted.old_canvas_offset_xy): return {}
\t\tasset={"texture":admitted.texture,"source_size":admitted.source_size,"ground_anchor":admitted.padded_threshold_anchor_xy}
\t\tvar row: Dictionary=render_row(String(lot.asset_id),asset,foot,ratio,polygons)
'''
assert t.count(a)==1;t=t.replace(a,b)
t=t.replace('row["raw_BUILD_only_not_clean_imported_or_runtime_bound"]=true','row["processed_whole_source_texture_no_canvas_refit"]=true')
t=t.replace('row["finish_source_size_px"]=measurement.raw_size.duplicate()','row["finish_source_size_px"]=admitted.source_size.duplicate()')
t=t.replace('row["finish_source_anchor_px"]=measurement.manual_threshold_front_anchor_raw.duplicate()','row["finish_source_anchor_px"]=admitted.padded_threshold_anchor_xy.duplicate()')
t=t.replace('row["finish_source_ground_polygons_px"]=lot.source_ground_polygons_raw_px.duplicate(true)','''row["finish_source_ground_polygons_px"]=[]
\t\tfor raw_polygon: Variant in lot.source_ground_polygons_raw_px:
\t\t\tvar padded: Array=[]
\t\t\tfor raw_point: Variant in raw_polygon:
\t\t\t\tvar p: Vector2=v(raw_point)+v(admitted.old_canvas_offset_xy);padded.append([float(p.x),float(p.y)])
\t\t\trow.finish_source_ground_polygons_px.append(padded)''')
t=t.replace('"raw_3_BUILD_only":true','"processed_three_imported_whole_textures":true')
data=t.encode();out=N/'artisan_block_projection06_processed_NOTREADY.gd'
with out.open('xb') as stream:stream.write(data)
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+out.name,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)}))
