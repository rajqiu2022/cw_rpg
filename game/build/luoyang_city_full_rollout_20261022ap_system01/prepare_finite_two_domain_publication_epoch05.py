"""Source-derived exact two-row oracle correction, no native/PNG decode or engine.

Expected coordinates use only fixedB11 author, fixedEAC parent declaration,
and original AP/C/BASE float32 expression order. The actual112732 diagnosis
is not opened or consumed by this builder.
"""
from pathlib import Path
import copy,hashlib,json,struct
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
OLD=ROOT/'finite_two_domain_publication_epoch04'
NEW=ROOT/'finite_two_domain_publication_epoch05'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
def path(p):return GAME/p.removeprefix('res://')
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def pin(p):return {'path':res(p),'sha256':sha(p),'bytes':p.stat().st_size}
def save(p,obj):
    assert not p.exists(),p
    p.write_bytes((json.dumps(obj,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    return pin(p)
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def f(v):return struct.unpack('<f',struct.pack('<f',v))[0]
def add(a,b):return [f(f(a[i])+f(b[i])) for i in range(2)]
def sub(a,b):return [f(f(a[i])-f(b[i])) for i in range(2)]
def mul(a,s):return [f(f(n)*s) for n in a]
def rect_corners(low,size):
    high=add(low,size)
    return [low,[high[0],low[1]],high,[low[0],high[1]]]

assert sha(OLD/'input_READY.json')=='7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2'
assert sha(OLD/'publisher_READY.gd')=='396fe184a196b6034909e75bffa9e988ad3f94f097c84cbce48b98723ef7fd1e'
data=load(OLD/'input_READY.json');parent=copy.deepcopy(data)
report_path=ROOT/'market_alpha_pin_retry6/publication/17536/result.json'
assert data['source_pins'][res(report_path)]==sha(report_path)
report=load(report_path)
assert report['passed'] is True and report['source_first']==report['source_final']
author_path=ROOT/'market_alpha_pin_retry6/market_author.json'
assert sha(author_path)==report['source_first'][res(author_path)]=='b11f48b8249ab27784aef1dc5b960e9ede7430e381a923c389c6461d95ca7a2e'
author=load(author_path)
transform_path=ROOT/'market_alpha_pin_retry6/market_transform.gd'
contract=GAME/'scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
base=GAME/'scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd'
parent_path=GAME/'build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s3_luoyang_market/manifest.json'
assert sha(parent_path)==author['source_sha256'][res(parent_path)]=='eac64463aa3bc00835114b0856e6e00a98d57c38d0fd6e8de472f329cd28bd13'
source_paths=[author_path,transform_path,contract,base,parent_path]
source_pins={}
for p in source_paths:
    expected=(author['source_sha256'][res(p)] if p==parent_path else report['source_first'][res(p)])
    assert sha(p)==expected,p
    source_pins[res(p)]=expected
transform=transform_path.read_text(encoding='utf-8')
assert 'points.append(foot+(point-anchor)*scale_value)' in transform
assert 'row.physical_center_px=v(row.physical_center_px)+delta' in transform
c=contract.read_text(encoding='utf-8')
assert 'BASE._rect_polygon(Rect2(_vec(object.physical_center_px) - size * .5, size))' in c
b=base.read_text(encoding='utf-8')
assert 'return PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])' in b
NEW.mkdir(exist_ok=False)
old_solids=parent['market']['raw_geometry']['solids']
new_solids=data['market']['raw_geometry']['solids']
derived=[]
for index,key in enumerate(['pawn','tailor']):
    asset=author['assets'][key]
    obj=author['new_objects'][index]
    for ordinal,rectangle in enumerate(asset['solid_rects']):
        identifier=obj['id']+'_solid_'+str(ordinal)
        old=next(r for r in old_solids if r['id']==identifier)
        low=[f(rectangle[0]),f(rectangle[1])];size=[f(rectangle[2]),f(rectangle[3])]
        # Rect2 source corner first; each vertex separately transformed exactly
        # as the frozen project_spec code. Never transformed-low+scaled-size.
        corners=rect_corners(low,size)
        foot=[f(n) for n in obj['world_foot_px']]
        anchor=[f(n) for n in asset['source_ground_anchor_px']]
        points=[add(foot,mul(sub(p,anchor),asset['scale'])) for p in corners]
        derived.append({'id':identifier,'source_rect':rectangle,'source_foot':obj['world_foot_px'],'source_anchor':asset['source_ground_anchor_px'],'source_scale':asset['scale'],'exact_source_expression':points,'old_points':old['points_px']})
        next(r for r in new_solids if r['id']==identifier)['points_px']=points

fixed_parent=load(parent_path)
tree=next(r for r in fixed_parent['record']['objects'] if r['id']=='assembled_market_tree_group_a')
move=next(r for r in author['layout_successor']['native_moves'] if r['id']==tree['id'])
assert tree['world_foot_px']==move['old_foot']==[820,1750] and move['new_foot']==[720,980]
delta=sub(move['new_foot'],move['old_foot'])
center=add(tree['physical_center_px'],delta)
size=[f(n) for n in tree['collision_size_px']]
low=sub(center,mul(size,.5))
# C.object_solids builds Rect2(center-size*.5,size); BASE uses rect.end=low+size.
tree_points=rect_corners(low,size)
tree_id=tree['id']+'_rect'
tree_old=next(r for r in old_solids if r['id']==tree_id)
next(r for r in new_solids if r['id']==tree_id)['points_px']=tree_points
derived.append({'id':tree_id,'immutable_parent_object_pointer':'/record/objects/'+str(fixed_parent['record']['objects'].index(tree)),'parent_physical_center':tree['physical_center_px'],'unchanged_collision_size':tree['collision_size_px'],'approved_native_move':move,'derived_center_after_original_Vector2_add':center,'derived_Rect2_low':low,'exact_source_expression':tree_points,'old_points':tree_old['points_px']})
hunks=[]
components=[]
for ordinal,(old,new) in enumerate(zip(old_solids,new_solids)):
    if same(old,new):continue
    assert old['id']==new['id'] and same(dict(new,points_px=old['points_px']),old)
    hunks.append({'pointer':'/market/raw_geometry/solids/'+str(ordinal)+'/points_px','row_id':old['id'],'old':old['points_px'],'new':new['points_px']})
    for vertex,(a,z) in enumerate(zip(old['points_px'],new['points_px'])):
        for axis in range(2):
            if a[axis]!=z[axis]:components.append({'id':old['id'],'vertex':vertex,'axis':axis,'old':a[axis],'new':z[axis]})
assert len(hunks)==2 and {h['row_id'] for h in hunks}=={'market_west_ward_frontage_solid_2','assembled_market_tree_group_a_rect'}
assert len(components)==4
proof={'status':'SOURCE_EXPRESSION_EXACT_TWO_ORACLE_ROWS_CORRECTION_NOT_GEOMETRY_OR_NATIVE_OBSERVATION',
    'parent_input':pin(OLD/'input_READY.json'),'immutable_17536_report':pin(report_path),
    'source_first':source_pins,'source_final':{res(p):sha(p) for p in source_paths},
    'source_algorithm':'Vector2 float32 operations in original expression order, sourceRect.end before source transform; nativeRect.end=derivedlow+size, not center+half.',
    'all_eight_AP_source_rect_checks_plus_one_tree_source_check':derived,'only_two_row_hunks':hunks,'only_four_component_changes':components,
    'no_epsilon_or_rounded_comparison':True,'source_values_not_observed_packet_or_diagnostic':True,
    'actual_diagnostic_read_by_builder':False,'native_variant_decodes':0,'PNG_decodes':0,'engine_runs':0,
    'old_56AF_oracle_and_38992_FAILURE_not_modified':True}
assert proof['source_first']==proof['source_final']
proof_pin=save(NEW/'source_expression_correction_READY.json',proof)
data['output_prefix']=data['output_prefix'].replace('epoch04/','epoch05/')
for p,h in source_pins.items():
    assert p not in data['source_pins'] or data['source_pins'][p]==h
    data['source_pins'][p]=h
    data['source_pin_lineage'].append({'path':p,'sha256':h,'declared_by':{'source_expression_proof':proof_pin['path'],'source':'B11/17536/EAC immutable declarations, never actual diagnostic coordinates'}})
data['source_pins'][proof_pin['path']]=proof_pin['sha256']
data['source_pin_lineage'].append({'path':proof_pin['path'],'sha256':proof_pin['sha256'],'declared_by':{'producer':'NEW source-only expression derivation; no native or image data read'}})
inverse=copy.deepcopy(data)
inverse['output_prefix']=parent['output_prefix']
inverse['market']['raw_geometry']['solids']=copy.deepcopy(parent['market']['raw_geometry']['solids'])
inverse['source_pins']=copy.deepcopy(parent['source_pins'])
inverse['source_pin_lineage']=copy.deepcopy(parent['source_pin_lineage'])
assert same(inverse,parent)
assert (json.dumps(inverse,ensure_ascii=False,indent=2)+'\n').encode()==(OLD/'input_READY.json').read_bytes()
input_pin=save(NEW/'input_READY.json',data)
old_handoff=load(OLD/'handoff_READY.json')
assert sha(path(old_handoff['template']['path']))==old_handoff['template']['sha256']
template=path(old_handoff['template']['path']).read_bytes()
assert template.count(b'finite_two_domain_publication_epoch04')==2
new_template=template.replace(b'finite_two_domain_publication_epoch04',b'finite_two_domain_publication_epoch05')
template_path=NEW/'publisher_template_NOTEXEC.gd';template_path.write_bytes(new_template)
ready_bytes=new_template.replace(b'const READY=false',b'const READY=true',1).replace(b'@INPUT_SHA@',input_pin['sha256'].encode(),1)
ready=NEW/'publisher_READY.gd';ready.write_bytes(ready_bytes)
old_ready=(OLD/'publisher_READY.gd').read_bytes()
assert ready_bytes.replace(input_pin['sha256'].encode(),b'7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2',1).replace(b'finite_two_domain_publication_epoch05',b'finite_two_domain_publication_epoch04')==old_ready
handoff=copy.deepcopy(old_handoff)
handoff.update({'publisher':pin(ready),'input':input_pin,'template':pin(template_path),'preparation_builder':pin(Path(__file__)),
    'source_expression_correction_proof':proof_pin,'source_pin_count':len(data['source_pins']),
    'prior_actual04_failure_retained':'res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch04/output/runs/38992_1718/result.json',
    'new_source_expected_not_actual_backfill':True,'whole_typed_input_inverse_to04':True,'whole_byte_input_inverse_after_declared_changes':True,
    'only_behavioral_delta':'No publisher behavior change. Only two fixed-oracle rows independently derived from original source expression (4 float components) plus explicit proof/source pins and absentNEW05 output prefix.',
    'publisher_exact_whole_text_inverse_to_actual04':True,'publisher_exact_byte_inverse_to_actual04':True,
    'publisher_only_header_changes':['INPUT path04->05','INPUT_SHA7B1D->new fixed input','OUT path04->05'],
    'input_delta_from04':'Exactly two raw-oracle points_px arrays,5 source declarations+NEW proof leaf, source-lineage rows, and newOUT; every other original input typed and byte inverse exact.',
    'actual_source_coordinates_consumed':False,'engine_runs':0,'native_variant_decodes':0,'PNG_decodes':0,'canonical_writes':0})
handoff.pop('supersedes_unexecuted03_handoff',None)
print(json.dumps(save(NEW/'handoff_READY.json',handoff)))
