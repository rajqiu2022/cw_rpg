"""Source-math only. Proposed cleanup has NOT been executed or admitted here."""
from pathlib import Path
import hashlib,json,struct
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
REPO=GAME.parent
NS='res://build/luoyang_city_finish_20261025i_source01/'
def f(v):return struct.unpack('<f',struct.pack('<f',float(v)))[0]
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    raw=p.read_bytes();assert sha(raw)==h,(str(p),'SHA_MISMATCH')
    return json.loads(raw)
artp=GAME/'build/luoyang_city_finish_20261025i_art01/manual_building_measurements01.json'
art=load(artp,'0cee5e32ad7a81dfaf56806a08767222d3448b3576b85a81004198d47407d8b6')
parentp=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_workyards_epoch01/author_CANDIDATE_NOT_APPROVED.json'
parent=load(parentp,'1dd5a3949e36ecbada0b4a73f2c109cc1561572b64e3cd8a3e49fa4e2c21df09')
def point(foot,q,anchor,scale):return [f(f(foot[i])+f(f(f(q[i])-f(anchor[i]))*f(scale))) for i in range(2)]
def envelope(box,anchor,foot,scale):return point(foot,box[:2],anchor,scale)+point(foot,box[2:],anchor,scale)
specs=[('chinese_open_ironwork_v2',[480,1840],[128,1420,884,600],760/1487,145,170),
       ('pottery_kiln_house_v2',[2190,1840],[1880,1420,880,600],170/297,145,170),
       ('ordinary_kitchen_rear_body_v2',[1536,410],[1196,16,720,584],145/294,145,0)]
results=[]
for id,foot,lot,scale,minheight,minwidth in specs:
    row=next(r for r in art['rows'] if r['id']==id)
    raw=(REPO/row['raw_path']).read_bytes()
    assert sha(raw)==row['raw_sha256']
    box=envelope(row['raw_coordinates_A1_after_proposed_cleanup'],row['manual_threshold_front_anchor_raw'],foot,scale)
    opening=row.get('conservative_visible_workbay_size',row.get('conservative_closed_door_size'))
    # A visual source length is scalar*double, Sprite scale is float32. The
    # exact source-f32 model is separately recorded; no epsilon admission.
    actual_open=[f(f(opening[i])*f(scale)) for i in range(2)]
    result={'id':id,'source_measurement_path':str(artp),'source_measurement_sha256':sha(artp.read_bytes()),
            'raw_path':row['raw_path'],'raw_sha256':row['raw_sha256'],'proposed_foot_px':foot,
            'lot_xywh':lot,'uniform_source_expression':{'numerator':760 if id.startswith('chinese') else 170 if id.startswith('pottery') else 145,'denominator':1487 if id.startswith('chinese') else 297 if id.startswith('pottery') else 294},
            'uniform_float64':scale,'uniform_as_Vector2_scalar_f32':f(scale),
            'cleaned_subject_A1_world_xyxy_f32':box,'opening_world_size_f32':actual_open,
            'A1_inside_reserved_lot':box[0]>=lot[0] and box[1]>=lot[1] and box[2]<=lot[0]+lot[2] and box[3]<=lot[1]+lot[3],
            'visible_opening_height_min':minheight,'visible_opening_width_min':minwidth,
            'opening_height_comparison_exact':actual_open[1]>=minheight,'opening_width_comparison_exact':actual_open[0]>=minwidth,
            'source_door_not_transparent_hole':True,'physical_base_authority':'MISSING_MUST_BE_SOURCE_AUTHORED_NOT_ROOF_A1',
            'actual_processed_A1_or_pixel_admission':False}
    assert result['A1_inside_reserved_lot']
    results.append(result)
# Preserve original existing module image scale, not whole canvas resize.
assets=parent['assets']
oldrows={r['id']:r for r in parent['scenes'][0]['placements']}
existing=[]
for id,foot in [('ap_courtyard_home_west',[590,480]),('ap_courtyard_home_east',[2460,480]),('ap_carpentry_general_shop_south',[1536,900])]:
    old=oldrows[id];a=assets[old['asset']]
    # A2 author's source image size/alpha/anchor keys are explicit, never
    # silently substitute full-canvas bounds if this schema changes.
    x,y,w,h=a['used_rect']
    bounds=envelope([x,y,x+w,y+h],a['ground_anchor'],foot,float(old['width'])/float(w))
    existing.append({'id':id,'source_asset':old['asset'],'foot_px':foot,'width':old['width'],'asset':a,'A1_world_xyxy_f32':bounds})
report={'status':'THREE_RAW_MODULES_SOURCE_F32_FIT_PROPOSAL_NOT_RUNTIME_OR_PIXEL_ADMISSION','ready':False,
        'measurement_pin':{'path':str(artp),'sha256':sha(artp.read_bytes())},'rows':results,
        'existing_north_neighbors_source_rows':existing,
        'pottery_right_A1_to_east_entry_lane_x2784_gap_f32':f(2784-results[1]['cleaned_subject_A1_world_xyxy_f32'][2]),
        'main_street_south_edge_y1410_to_pottery_A1_top':f(results[1]['cleaned_subject_A1_world_xyxy_f32'][1]-1410),
        'kitchen_to_north_west_home_A1_gap_x':f(results[2]['cleaned_subject_A1_world_xyxy_f32'][0]-existing[0]['A1_world_xyxy_f32'][2]),
        'kitchen_to_north_east_home_A1_gap_x':f(existing[1]['A1_world_xyxy_f32'][0]-results[2]['cleaned_subject_A1_world_xyxy_f32'][2]),
        'kitchen_to_middle_carpentry_A1_gap_y':f(existing[2]['A1_world_xyxy_f32'][1]-results[2]['cleaned_subject_A1_world_xyxy_f32'][3]),
        'cleanup_authorization_and_execution_pending':True,'new_mask_PIP_Physics_or_NPC_credit':False,'engine_calls':0,'collector_calls':0}
p=HERE/'three_new_modules_fit01_SOURCE_ONLY.json'
raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
with p.open('xb') as stream:stream.write(raw)
print(json.dumps({'path':NS+p.name,'sha256':sha(raw),'rows':results},ensure_ascii=False))
