"""Root-approved last3 body substitutions; ART trueground author, not QA or deployment."""
from pathlib import Path
import hashlib,json,math
import numpy as np
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
PARENT=ROOT/'game/build/luoyang_city_finish_20261025i_source01/author_gate_yamen_axis03_exact_domains_NOTREADY.json'
LIB=ROOT/'game/build/luoyang_city_finish_20261025i_source01/reuse_asset_library01_SOURCE_ONLY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def obj(p):return json.loads(p.read_text(encoding='utf-8-sig'))
assert sha(PARENT)=='0652fabb2ec0ca6a9c40fa0b96ec366f2422f7f77d15386811acc4204eff9785'
assert sha(LIB)=='17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d'
parent=obj(PARENT);library=obj(LIB)
specs=[
 ('ch4_s1_luoyang_yamen','finish_i_yamen_west_archive','ordinary_kitchen_rear_body_v2',[540,620],[145,294],'后勤灶房；保留西前侧楼承担原书办/档案职责'),
 ('ch4_s1_luoyang_yamen','finish_i_yamen_east_runner_house','plain_wing',[2530,620],[41,100],'差役兵房完整后体'),
 ('ch4_s0_luoyang_gate','finish_i_gate_east_supply','plain_wing',[2380,1300],[41,100],'军需短仓/供役完整后体，与西候检官屋区别')]
kitchen=obj(OUT/'three_buildings_processed_source_declarations01_CANDIDATE.json')['rows'][2]
assert kitchen['id']=='ordinary_kitchen_rear_body_v2'
ground_path=OUT/'manual_ground_contacts02.json'
grounds=obj(ground_path)
print('GROUND_KEYS',list(grounds))
def project(points,anchor,foot,scale):
    p=np.array(points,dtype=np.float32);a=np.array(anchor,dtype=np.float32);f=np.array(foot,dtype=np.float32)
    return (f+(p-a)*np.float32(scale)).astype(np.float32).tolist()
rows=[]
for scene,ident,asset,foot,ratio,purpose in specs:
    scene_row=next(s for s in parent['scenes'] if s['scene_id']==scene)
    old=next(s for s in scene_row['placements'] if s['id']==ident)
    if asset=='plain_wing':
        donor=library['assets'][asset];anchor=donor['source_ground_anchor_px'];texture=donor['texture'];pin=donor['source_sha256'];size=donor['source_size_px']
        a1=donor['alpha_bbox_xywh'];a1=[a1[0],a1[1],a1[0]+a1[2],a1[1]+a1[3]]
        polygons=[]
        for x,y,w,h in donor['source_solid_rects_px']:polygons.append([[x,y],[x+w,y],[x+w,y+h],[x,y+h]])
        raw=dict(path=texture,sha256=pin,source_polygons='UnmodifiedC210wholewingtwoactualclosedsidebase rectangles, NOT wholeA1roof')
        door_height=355
    else:
        texture=kitchen['texture'];pin=kitchen['source_PNG_sha256'];size=kitchen['source_size'];anchor=kitchen['padded_threshold_anchor_xy'];a1=kitchen['padded_subject_A1_xyxy']
        pad=kitchen['old_canvas_offset_xy']
        # Frozen ART closed house ground footprint, not alpha or roof rectangle.
        rawpolygon=[[263,831],[1079,888],[1345,794],[529,737]]
        polygons=[[[x+pad[0],y+pad[1]] for x,y in rawpolygon]]
        raw=dict(path=kitchen['raw_path'],sha256=kitchen['raw_sha256'],ground_contract=ground_path.relative_to(ROOT).as_posix(),ground_contract_sha256=sha(ground_path),hidden_rear_corners='Explicitground-parallelARTauthorinference, not opaque-pixel evidence',source_polygons='Kitchencompleteactualbase; exact64x32padtranslationsameasimage')
        door_height=294
    canonical=ROOT/('game/'+texture[6:]);assert sha(canonical)==pin
    scale=np.float32(ratio[0])/np.float32(ratio[1])
    worldpolys=[project(p,anchor,foot,scale) for p in polygons]
    a1corners=project([[a1[0],a1[1]],[a1[2],a1[3]]],anchor,foot,scale)
    vertices=[v for poly in worldpolys for v in poly]
    priorold=[v for poly in old['source_derived_new_ground_polygons_f32'] for v in poly]
    xs=[v[0] for v in vertices+priorold];ys=[v[1] for v in vertices+priorold]
    budget=[math.floor(min(xs))-1,math.floor(min(ys))-1,math.ceil(max(xs))+1,math.ceil(max(ys))+1]
    new={'id':ident,'asset_id':asset,'texture':texture,'PNG_sha256':pin,'source_size_px':size,'source_ground_anchor_px':anchor,'foot_px':foot,'uniform_source_expression':{'numerator':ratio[0],'denominator':ratio[1]},'uniform_f32':float(scale),'purpose':purpose,'source_ground_polygons_px':polygons,'source_ground_polygons_world_f32_ART_model':worldpolys,'source_complete_A1_xyxy':a1,'complete_A1_world_f32_ART_model':a1corners,'door_visible_height_world_f32_ART_model':float(np.float32(door_height)*scale),'source_origin':raw,'enters_new_room':False,'door_registry_change':False,'NPC_change':False,'source_model_not_QA_or_render':True}
    rows.append({'scene_id':scene,'id':ident,'old_complete_placement':old,'new_complete_placement':new,'conservative_old_new_ground_union_closed_domain_xyxy_ART_model':budget,'Source_must_rederive_f32_and_exactunion':True,'whole_inverse':'replace new_complete_placement with old_complete_placement by exact ID in immutable03author; every other rowunchanged','affected_routes_policy':'Independent testONLYnewdomains/affectedshortlegs andNPC34x30+48approach. No inheriting49/44or replayfulloldroomcomponents.'})
artifact={'status':'ROOT_APPROVED_LAST_THREE_BODY_SUBSTITUTION_TRUE_GROUND_AUTHOR_NOT_DEPLOYED','Root_approval_source':'Parentdirectmessage20261025: last3shapechanges approved;noadditionalgeneration; syncSource localnewdomains','parent_author_path':PARENT.relative_to(ROOT).as_posix(),'parent_author_sha256':sha(PARENT),'donor_library_sha256':sha(LIB),'rows':rows,'preserve':['twoexistingYamenfrontannexes','mainhallandoriginalNPCs/portals/roomIDs/returns','Gatewalltowersbridge/mainaxis/originalNPCbodylanes','oldfailureand49/44priorcreditnotreusedfornewgeometry'],'negative_credit':['doorheight sourcef32isnotPhysics','A1isnotground','SourceauthorisnotindependentQA','styleproposalnotwholecitypass'],'engine':0,'PNG_write':0,'formal_write':0}
p=OUT/'three_final_body_substitutions_ground03_ROOT_APPROVED_NOT_QA.json';assert not p.exists()
with p.open('xb') as f:f.write((json.dumps(artifact,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p),'rows':[{k:r[k] for k in ['scene_id','id','conservative_old_new_ground_union_closed_domain_xyxy_ART_model']} for r in rows],'engine':0}))
