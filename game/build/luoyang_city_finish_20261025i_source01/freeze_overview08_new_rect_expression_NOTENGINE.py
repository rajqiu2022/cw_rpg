"""Root-approved new-rectangle expression correction and remaining two views.
No Godot, resource decode, geometry replay, canonical or existing-file writes.
"""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def encoded(a):return (json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
parent=(N/'adjacent_courts_projection03_NOTREADY.gd').read_bytes()
assert sha(parent)=='195a3225e9ee61be56a2f4593547d318605a862d60282d343c4e5bbe2001444c'
old='\t\t\tvar low: Vector2=foot+(Vector2(float(raw[0]),float(raw[1]))-anchor)*ratio\n\t\t\tvar high: Vector2=low+Vector2(float(raw[2]),float(raw[3]))*ratio\n\t\t\tpolygons.append(PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]))'
new='\t\t\t# NEW adjacent author uses four raw corners, not the old A2 low+size path.\n\t\t\tvar raw_corners: Array=[Vector2(float(raw[0]),float(raw[1])),Vector2(float(raw[0])+float(raw[2]),float(raw[1])),Vector2(float(raw[0])+float(raw[2]),float(raw[1])+float(raw[3])),Vector2(float(raw[0]),float(raw[1])+float(raw[3]))]\n\t\t\tvar rectangle_polygon: PackedVector2Array=PackedVector2Array()\n\t\t\tfor raw_corner: Vector2 in raw_corners: rectangle_polygon.append(foot+(raw_corner-anchor)*ratio)\n\t\t\tpolygons.append(rectangle_polygon)'
text=parent.decode();assert text.count(old)==1;text=text.replace(old,new)
assert text.replace(new,old).encode()==parent
helper=emit('adjacent_courts_projection04_raw_rect_corners_NOTREADY.gd',text.encode())
input_parent=(N/'overview_eight_fields07_ROOT_READY_input.json').read_bytes()
assert sha(input_parent)=='bfc370b9caad6185efb30bd1766e2559bea13f36852eeafe22cdc2717271441c'
a=json.loads(input_parent);previous_helper=a['adjacent_helper']
assert a['sources'][previous_helper]==sha(parent)
del a['sources'][previous_helper]
a['adjacent_helper']=helper['path'];a['sources'][helper['path']]=helper['sha256']
report=N/'overview_eight_fields07_ROOT_READY/output_ROOT_READY/70160/result.json'
rb=report.read_bytes();r=json.loads(rb)
assert r['errors']==['ADJACENT_SOURCE_DERIVE:luoyang_riverside_garden_20261022ap']
report_path=NS+'overview_eight_fields07_ROOT_READY/output_ROOT_READY/70160/result.json'
a['sources'][report_path]=sha(rb)
estate_id='luoyang_estate_riverside_20261021ai'
png=report.parent/(estate_id+'.png');pb=png.read_bytes();png_path=NS+'overview_eight_fields07_ROOT_READY/output_ROOT_READY/70160/'+png.name
a['sources'][png_path]=sha(pb)
a['inherited_images'][estate_id]={'path':png_path,'sha256':sha(pb),'source':'Root actual70160 complete Estate PNG; wholeFAIL preserved, no repeat render'}
assert len(a['inherited_images'])==6
a['output_absolute']=(N/'overview_eight_fields08_ROOT_READY/output_ROOT_READY').as_posix()
ipin=emit('overview_eight_fields08_ROOT_READY_input.json',encoded(a))
key_parent=(N/'overview_eight_fields07_ROOT_READY.gd').read_bytes()
assert sha(key_parent)=='a60398d13d46909f2a9abdeca3cd6da8997b7f7446666c491eab1611cb293fca'
text=key_parent.decode();hunks=[]
def change(o,n):
 global text
 assert text.count(o)==1;text=text.replace(o,n);hunks.append({'old':o,'new':n})
change('const INPUT: String="'+NS+'overview_eight_fields07_ROOT_READY_input.json"\nconst INPUT_SHA: String="'+sha(input_parent)+'"\nconst SELF: String="'+NS+'overview_eight_fields07_ROOT_READY.gd"','const INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields08_ROOT_READY.gd"')
change('\t\tif index<5:\n\t\t\tvar inherited:', '\t\tif index<6:\n\t\t\tvar inherited:')
inverse=text
for h in reversed(hunks):assert inverse.count(h['new'])==1;inverse=inverse.replace(h['new'],h['old'])
assert inverse.encode()==key_parent
key=emit('overview_eight_fields08_ROOT_READY.gd',text.encode())
proof=emit('overview08_new_rect_expression_full_inverse_READY.json',encoded({'status':'ROOT_APPROVED_NEW_ADJACENT_RECT_EXPRESSION_ONLY_REMAINING_TWO_VIEWS','helper':helper,'helper_parent_sha256':sha(parent),'helper_single_hunk':{'old':old,'new':new},'helper_full_byte_inverse':True,'key':key,'input':ipin,'key_hunks':hunks,'key_full_byte_inverse':True,'new_rectangle_scope':'Only18 new Adjacent placements. Original Artisan A2 low+size formula unchanged. Author geometry and strict Packed compare unchanged.','static_audit_script':NS+'audit_adjacent_source_polygons08_NOTENGINE.py','inherited_six_complete_PNGs':a['inherited_images'],'remaining_render_ids':['luoyang_riverside_garden_20261022ap','ch4_s2_canal_docks'],'explicit_parse_replays':0,'engine_calls':0,'canonical_writes':0}))
print(json.dumps({'key':key,'input':ipin,'helper':helper,'inverse':proof}))
