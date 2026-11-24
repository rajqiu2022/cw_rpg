"""Transform exact ART-authored ground contacts, not roof/alpha rectangles."""
from pathlib import Path
import copy,hashlib,json,struct
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def f(v):return struct.unpack('<f',struct.pack('<f',float(v)))[0]
def read(p,h):
    raw=p.read_bytes();assert sha(raw)==h,str(p)
    return json.loads(raw)
def out(n,v):
    raw=(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    with (HERE/n).open('xb') as stream:stream.write(raw)
    return {'path':NS+n,'sha256':sha(raw),'bytes':len(raw)}
author=read(HERE/'author_artisan_residential_block03_NOTREADY.json','68eb09bdc38150c2785b129303782cb38b998d1d0fb671aa99d9376c0cc43350')
source_path=GAME/'build/luoyang_city_finish_20261025i_art01/manual_ground_contacts02.json'
contacts=read(source_path,'662fffe926e72d4579947e12615e17e5300d2ea05ad823172f5d83213b214576')
modules={r['id']:r for r in contacts['modules']}
all_rows=[]
for slot in author['new_asset_lots']:
    source=modules[slot['source_asset_measured_raw']['id']]
    assert source['raw_sha256']==slot['source_asset_measured_raw']['raw_sha256']
    assert source['threshold_front_anchor_raw']==slot['source_asset_measured_raw']['manual_threshold_front_anchor_raw']
    foot=slot['foot_px'];anchor=source['threshold_front_anchor_raw'];scale=slot['uniform_scale_float64']
    def transform(q):return [f(f(foot[i])+f(f(f(q[i])-f(anchor[i]))*f(scale))) for i in range(2)]
    rows=[]
    for row in source['ground_contacts']:
        q=copy.deepcopy(row);q['source_polygon_raw_px']=q.pop('polygon')
        q['points_world_f32']=[transform(p) for p in q['source_polygon_raw_px']]
        q['owner_id']=slot['asset_id'];q['solid_kind']='SOURCE_AUTHOR_GROUND_POLYGON_NOT_ROOF'
        q['geometry_PIP_Physics_or_pixel_credit']=False
        rows.append(q)
    assert len(rows)==(1 if source['id'].startswith('ordinary') else 6)
    slot['ground_base_author']={'path':'res://build/luoyang_city_finish_20261025i_art01/manual_ground_contacts02.json','sha256':'662fffe926e72d4579947e12615e17e5300d2ea05ad823172f5d83213b214576'}
    slot['source_ground_polygons_raw_px']=[r['polygon'] for r in source['ground_contacts']]
    slot['new_ground_primitive_rows_f32']=rows
    slot['geometry_base_author_status']='EXPLICIT_ART_GROUND_CONTACT_AUTHOR_READY_FOR_INDEPENDENT_QA_NOT_PHYSICS_PASS'
    slot['hidden_rear_corners_policy']='Explicit ART authored inferred ground-parallel corners; not falsely described as opaque pixel evidence'
    if 'protected_open_front_floor_witness_polygon' in source:
        slot['protected_open_front_floor_witness_source_polygon']=source['protected_open_front_floor_witness_polygon']
        slot['protected_open_front_floor_witness_world_f32']=[transform(q) for q in source['protected_open_front_floor_witness_polygon']]
        slot['proposed_front_threshold_world_f32']=foot
        slot['whole_open_bay_may_not_be_filled_as_solid']=True
    all_rows.extend(rows)
author['remaining_new_native_publication_blockers']=[s for s in author['remaining_new_native_publication_blockers'] if not s.startswith('Full source visible ground base')]
author['remaining_new_native_publication_blockers'].append('ART13 actual source polygons: independent new-domain body/route/NPC/open-bay controls still required')
pin=out('author_artisan_residential_block04_ground_NOTREADY.json',author)
geometry=out('three_new_buildings_ground_primitives01_SOURCE_MODEL_NOT_QA.json',{'status':'SOURCE_F32_TRANSFORM_OF_EXPLICIT_ART_GROUND_AUTHOR_NOT_INDEPENDENT_QA_OR_ACTUAL','ready':False,'author':pin,'raw_ground_source':{'path':'res://build/luoyang_city_finish_20261025i_art01/manual_ground_contacts02.json','sha256':'662fffe926e72d4579947e12615e17e5300d2ea05ad823172f5d83213b214576'},'ground_primitive_count':len(all_rows),'rows':all_rows,'all_closed_room_portals_added':0,'no_roof_bbox_solid':True,'no_new_open_bay_blanket_solid':True,'no_processed_PNG_or_import_assumption':True,'engine_calls':0,'collector_calls':0})
print(json.dumps({'author':pin,'ground':geometry},ensure_ascii=False))
