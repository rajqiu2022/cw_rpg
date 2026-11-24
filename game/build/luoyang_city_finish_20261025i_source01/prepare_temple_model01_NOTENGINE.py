"""Independent source-expression model for the new Temple author. No engine."""
from pathlib import Path
import base64,copy,difflib,hashlib,json,struct
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def f(v):return struct.unpack('<f',struct.pack('<f',float(v)))[0]
def read(p,h):
    raw=p.read_bytes();assert sha(raw)==h,str(p)
    return raw,json.loads(raw)
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def put(name,data):
    with (HERE/name).open('xb') as stream:stream.write(data)
    return {'path':NS+name,'sha256':sha(data),'bytes':len(data)}
parent_path=GAME/'data/maps/luoyang_temple_assembly_20261016/author.json'
old_raw,parent=read(parent_path,'d03aa28b5eec9ad91296b8d3cc1d6aeb6782bde8be69b268d81f05550b63410a')
_,design=read(HERE/'author_temple_courts_loop02_NOTREADY.json','577d8100ca3e691848533585e89c823f10db7c5b195f04cb2273e4609066bcae')
_,library=read(HERE/'reuse_asset_library01_SOURCE_ONLY.json','17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d')
out=copy.deepcopy(parent)
def at(rows,id):
    found=[i for i,r in enumerate(rows) if r['id']==id];assert len(found)==1,id
    return found[0]
def move_point(q,old_foot,new_foot,ratio):
    return [f(f(new_foot[i])+f(f(f(q[i])-f(old_foot[i]))*f(ratio))) for i in range(2)]
retired=[];replacements=[];added=[]
for move in design['same_object_migrations']:
    i=at(out['placements'],move['id']);b=at(out['geometry']['furniture_bases'],move['id'])
    assert out['placements'][i]['foot_px']==move['old_foot_px'] and out['placements'][i]['scale']==move['old_scale']
    out['placements'][i]['foot_px']=move['new_foot_px'];out['placements'][i]['scale']=move['new_scale']
    before=copy.deepcopy(out['geometry']['furniture_bases'][b]);retired.append(before)
    after=copy.deepcopy(before)
    after['ground_polygon_px']=[move_point(q,move['old_foot_px'],move['new_foot_px'],move['new_scale']/move['old_scale']) for q in before['ground_polygon_px']]
    out['geometry']['furniture_bases'][b]=after;replacements.append(after)
wing=library['assets']['plain_wing']
wing_asset={'id':'finish_i_plain_wing','texture':wing['texture'],'size_px':wing['source_size_px'],'source_ground_anchor_px':wing['source_ground_anchor_px'],'source_sha256':wing['source_sha256']}
assert not any(r['id']==wing_asset['id'] for r in out['assets'])
out['assets'].append(wing_asset);out['texture_count']=len(out['assets'])
for placement in design['placements']:
    assert placement['asset_id']=='plain_wing' and placement['scale']==.33
    out['placements'].append({'id':placement['id'],'asset_id':wing_asset['id'],'foot_px':placement['foot_px'],'scale':placement['scale'],'fade_allowed':False,'role':placement['purpose']})
    for ordinal,(x,y,w,h) in enumerate(wing['source_solid_rects_px']):
        points=[move_point(q,wing['source_ground_anchor_px'],placement['foot_px'],placement['scale']) for q in [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]]
        row={'id':placement['id']+'_base_'+str(ordinal),'blocking':True,'ground_polygon_px':points,'owner_id':placement['id']}
        out['geometry']['furniture_bases'].append(row);added.append(row)
i=at(out['interaction_relocations'],'legacy_hotspot_5')
assert out['interaction_relocations'][i]['new_foot_px']==[1320,670]
out['interaction_relocations'][i]['new_foot_px']=[1320,620]
out['interaction_relocations'][i]['new_pos_uv']=[f(f(1320)/f(1536)),f(f(620)/f(1024))]
route_delta={
 'default_to_herb_shaded_boundary_stone':[[768,737.28],[730,940],[170,940],[170,740]],
 'ambush_to_real_bell_front':[[920,620],[1080,620],[1320,620]],
 'default_to_market_return':[[768,737.28],[768,960],[170,960],[170,980]],
 'default_to_docks_return':[[768,737.28],[768,960],[1380,960],[1380,980]]}
for id,points in route_delta.items():out['required_routes'][at(out['required_routes'],id)]['points_px']=points
for negative in out['negative_points']:
    for move in design['same_object_migrations']:
        if negative['prop_id']==move['id']:
            negative['foot_px']=move_point(negative['foot_px'],move['old_foot_px'],move['new_foot_px'],move['new_scale']/move['old_scale'])
out['finish_i_effective_portal_local_migrations']=design['portal_local_position_migrations']
out['finish_i_incoming_target_migrations']=design['incoming_target_migrations']
out['finish_i_ready']=False
out['finish_i_no_new_room_or_task']=True
assert len(out['placements'])==23 and len(out['geometry']['furniture_bases'])==25 and len(added)==4
journal=[]
for key,value in out.items():
    if key not in parent:journal.append({'kind':'ADD_FIELD','key':key,'new':value})
    elif parent[key]!=value:journal.append({'kind':'REPLACE_FIELD','key':key,'old':parent[key],'new':value})
back=copy.deepcopy(out)
for change in reversed(journal):
    assert back[change['key']]==change['new']
    if change['kind']=='ADD_FIELD':del back[change['key']]
    else:back[change['key']]=change['old']
assert back==parent and encode(back)==encode(parent)
# Protect every original field/row not expressly changed, including all quest
# actions, old animation delta, main hall source geometry and original routes.
assert out['placements'][0]==parent['placements'][0]
for r in parent['required_routes']:
    if r['id'] not in route_delta:assert out['required_routes'][at(out['required_routes'],r['id'])]==r
new_raw=encode(out)
segments=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,old_raw,new_raw,autojunk=False).get_opcodes():
    if tag=='equal':continue
    segments.append({'old_offset':i,'new_offset':k,'old_base64':base64.b64encode(old_raw[i:j]).decode(),'new_base64':base64.b64encode(new_raw[k:l]).decode()})
def apply(data,reverse):
    result=data
    for row in reversed(segments):
        a='new' if reverse else 'old';b='old' if reverse else 'new'
        offset=row[a+'_offset'];before=base64.b64decode(row[a+'_base64']);after=base64.b64decode(row[b+'_base64'])
        assert result[offset:offset+len(before)]==before
        result=result[:offset]+after+result[offset+len(before):]
    return result
assert apply(old_raw,False)==new_raw and apply(new_raw,True)==old_raw
candidate=put('author_temple_source_compiled01_NOTREADY.json',new_raw)
patch=put('temple_author01_exact_byte_patch_BUILD.json',encode({'status':'PHYSICAL_EXACT_BYTE_FORWARD_INVERSE_NOT_ENGINE','parent_path':'res://data/maps/luoyang_temple_assembly_20261016/author.json','parent_sha256':sha(old_raw),'candidate':candidate,'segments':segments}))
proof=put('temple_compiler01_independent_source_model_BUILD.json',encode({'status':'INDEPENDENT_PYTHON_SOURCE_F32_EXPECTED_MODEL_NOT_GODOT_ACTUAL','ready':False,'candidate':candidate,'byte_patch':patch,
 'pure_compiler':{'path':NS+'temple_source_compiler01_NOTREADY.gd','sha256':sha((HERE/'temple_source_compiler01_NOTREADY.gd').read_bytes())},
 'parent':{'path':'res://data/maps/luoyang_temple_assembly_20261016/author.json','sha256':sha(old_raw),'bytes':len(old_raw)},
 'journal':journal,'retired_bases':retired,'replacement_bases':replacements,'added_bases':added,'changed_route_ids':list(route_delta),
 'old_remaining_route_rows_exact':True,'parent_full_typed_inverse':True,'physical_whole_byte_forward_inverse':True,
 'model_new_visuals':23,'model_new_bases':25,'new_domain_PIP_mask_or_Physics_pass':False,'no_old_room_bridge_or_service_replay':True,'engine_calls':0,'collector_calls':0}))
print(json.dumps({'candidate':candidate,'patch':patch,'proof':proof},ensure_ascii=False))
