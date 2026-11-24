from pathlib import Path
import hashlib,json

N=Path(__file__).resolve().parent
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b): return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f: f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))

old=(N/'finish8_source_views03_ferry_actual_fields_NOTREADY.gd').read_bytes()
assert sha(old)=='9f61c47f28c6e4c7bd571a08076f751c2fc26febcc62e464308aae14dc4bf53a'
t=old.decode('utf-8'); hunks=[]
def change(a,b):
    global t
    assert t.count(a)==1,(a,t.count(a))
    t=t.replace(a,b);hunks.append(dict(old=a,new=b))
helper='''static func strict_named_packed_solids(rows: Array) -> Array:
	# Fixed Market/Docks geometry artifacts store named rows, not bare polygons.
	# Preserve row order and Packed float32 values; do not reconstruct coordinates.
	var out: Array=[];var seen: Dictionary={}
	for raw: Variant in rows:
		if not raw is Dictionary: return []
		var id: String=String(raw.get("id",""))
		if id=="" or seen.has(id) or not raw.get("points_px") is PackedVector2Array: return []
		var shape: PackedVector2Array=raw.points_px
		if shape.size()<3: return []
		for point: Vector2 in shape:
			if not point.is_finite(): return []
		seen[id]=true;out.append(shape.duplicate())
	return out
'''
change('static func blocker_solids(',helper+'static func blocker_solids(')
change('parent=inputs.market_projection.render;old_solids=inputs.market_geometry',
       'parent=inputs.market_projection.render;old_solids=strict_named_packed_solids(inputs.market_geometry)')
change('parent=docks_parent(native,inputs.docks_projection,inputs.district_author);old_solids=inputs.docks_geometry',
       'parent=docks_parent(native,inputs.docks_projection,inputs.district_author);old_solids=strict_named_packed_solids(inputs.docks_geometry)')
back=t
for h in reversed(hunks):
    assert back.count(h['new'])==1
    back=back.replace(h['new'],h['old'])
assert back.encode('utf-8')==old
view=emit('finish8_source_views04_strict_named_solids_NOTREADY.gd',t.encode('utf-8'))

parent_input=(N/'finish8_publication_input07_ROOT_READY.json').read_bytes()
a=json.loads(parent_input)
assert a['ready'] is True and a['root_run_authorized'] is True
assert a['source_views']==NS+'finish8_source_views03_ferry_actual_fields_NOTREADY.gd'
assert a['sources'][a['source_views']]==sha(old)
a['ready']=False;a['root_run_authorized']=False
a['output_root']=NS+'publication08/output_NOTREADY'
del a['sources'][a['source_views']]
a['source_views']=view['path'];a['sources'][view['path']]=view['sha256']
ip=emit('finish8_publication_input08_NOTREADY.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
key_old=(N/'publish_finish8_components07_ROOT_READY.gd').read_bytes()
key_t=key_old.decode('utf-8');key_hunks=[]
for before,after in [
    ('const READY: bool=true','const READY: bool=false'),
    ('const INPUT: String="'+NS+'finish8_publication_input07_ROOT_READY.json"\nconst INPUT_SHA: String="'+sha(parent_input)+'"',
     'const INPUT: String="'+ip['path']+'"\nconst INPUT_SHA: String="'+ip['sha256']+'"')]:
    assert key_t.count(before)==1
    key_t=key_t.replace(before,after);key_hunks.append(dict(old=before,new=after))
key_back=key_t
for h in reversed(key_hunks): key_back=key_back.replace(h['new'],h['old'])
assert key_back.encode('utf-8')==key_old
key=emit('publish_finish8_components08_NOTREADY.gd',key_t.encode('utf-8'))
proof=emit('publication08_named_geometry_strict_unwrap_inverse_BUILD.json',(json.dumps(dict(
    status='ROOT_APPROVED_EXACT_NAMED_GEOMETRY_TO_PACKED_CONSUMER_SCHEMA_SUCCESSOR',
    entry=key,input=ip,source_views=view,
    view_parent_sha256=sha(old),view_hunks=hunks,key_parent_sha256=sha(key_old),key_hunks=key_hunks,
    whole_byte_inverse=True,expected_coordinates_or_geometry_changed=False,
    payload_builder_unchanged_sha256=a['sources'][a['payload_builder']],
    inherited_first2_unchanged=a['inherited_scenes'],
    diagnostic_reason={'clause':'finish8_payload_builder01_NOTREADY.gd:70-72',
      'actual_source_schema':'Array[Dictionary {id,kind,points_px:PackedVector2Array,...}]',
      'required_payload_schema':'Array[PackedVector2Array]',
      'fixed_source_evidence':'qa_role_new/adjacent_prior03/oracle_NOTREADY.gd:282-288',
      'scope':['docks_geometry','market_geometry'],
      'conversion':'strict unique nonempty ID + Packed type + size>=3 + finite; append Packed duplicate in original row order; zero coordinate arithmetic'},
    source_priors_and_masks_unchanged=True,gate_yamen_raster_replay=False,
    original_FAILs_preserved=True,engine_calls=0,canonical_writes=0,
),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps(dict(entry=key,input=ip,source_views=view,proof=proof)))
