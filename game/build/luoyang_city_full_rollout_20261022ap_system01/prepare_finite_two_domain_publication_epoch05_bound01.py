"""Bind Root1DC99 approval to already source-derived05; Root still must run."""
from pathlib import Path
import copy,hashlib,json
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
OLD=ROOT/'finite_two_domain_publication_epoch05'
ORIGINAL=ROOT/'finite_two_domain_publication_epoch04'
NEW=ROOT/'finite_two_domain_publication_epoch05_bound01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
def pin(p):return {'path':res(p),'sha256':sha(p),'bytes':p.stat().st_size}
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def save(p,data):
    assert not p.exists(),p
    p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    return pin(p)
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
assert sha(OLD/'input_READY.json')=='46ad042c4ee1e8f7d69407a95da74d32202245db1bc8c4edac2258cd2f4f8bd3'
assert sha(OLD/'publisher_READY.gd')=='87d424cf5af74e6b5d4bb4a0a77921c489d9799a063bd5d99b67fb0f27abb540'
proof_path=OLD/'source_expression_correction_READY.json'
assert sha(proof_path)=='ee85e0112a1b0053393420926c1d13498c0bc2d76bbf7daa5138bf5becefb155'
approval=ROOT.parent/'luoyang_city_full_rollout_20261022ap_root01/two_domain_source_arithmetic_correction_authorization_READY.json'
assert sha(approval)=='1dc99ef19c3591093c8d89eaa9c61690be4f8c5b3feb9231ba0a7ac72ea07931'
authorized=load(approval);proof=load(proof_path)
assert authorized['old_input_sha256']=='7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2'
assert authorized['constraints']['no_epsilon_or_numeric_tolerance'] is True
for component in proof['only_four_component_changes']:
    row=next(r for r in authorized['changes'] if r['id']==component['id'])
    assert component['vertex'] in row['vertices'] and component['axis']==row['axis'] and component['old']==row['old'] and component['new']==row['new']
NEW.mkdir(exist_ok=False)
data=load(OLD/'input_READY.json');original=load(ORIGINAL/'input_READY.json')
data['output_prefix']=data['output_prefix'].replace('epoch05/','epoch05_bound01/')
data['arithmetic_correction_authorization']=pin(approval)
data['source_pins'][res(approval)]=sha(approval)
data['source_pin_lineage'].append({'path':res(approval),'sha256':sha(approval),'declared_by':{'Root_explicit_approval':'Only the two independently source-derived oracle rows, newOUT and exact provenance; no expected coordinate derives from this approval or actual packet.'}})
inverse=copy.deepcopy(data)
inverse.pop('arithmetic_correction_authorization')
inverse['output_prefix']=original['output_prefix']
for hunk in proof['only_two_row_hunks']:
    row=next(r for r in inverse['market']['raw_geometry']['solids'] if r['id']==hunk['row_id'])
    assert same(row['points_px'],hunk['new'])
    row['points_px']=copy.deepcopy(hunk['old'])
inverse['source_pins']=copy.deepcopy(original['source_pins'])
inverse['source_pin_lineage']=copy.deepcopy(original['source_pin_lineage'])
assert same(inverse,original)
assert (json.dumps(inverse,ensure_ascii=False,indent=2)+'\n').encode()==(ORIGINAL/'input_READY.json').read_bytes()
input_pin=save(NEW/'input_READY.json',data)
old_ready=(OLD/'publisher_READY.gd').read_bytes()
ready_bytes=old_ready.replace(b'finite_two_domain_publication_epoch05/',b'finite_two_domain_publication_epoch05_bound01/').replace(b'46ad042c4ee1e8f7d69407a95da74d32202245db1bc8c4edac2258cd2f4f8bd3',input_pin['sha256'].encode(),1)
ready=NEW/'publisher_READY.gd';ready.write_bytes(ready_bytes)
assert ready_bytes.replace(input_pin['sha256'].encode(),b'7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2',1).replace(b'finite_two_domain_publication_epoch05_bound01/',b'finite_two_domain_publication_epoch04/')==(ORIGINAL/'publisher_READY.gd').read_bytes()
template=NEW/'publisher_template_NOTEXEC.gd'
template.write_bytes(ready_bytes.replace(b'const READY=true',b'const READY=false',1).replace(input_pin['sha256'].encode(),b'@INPUT_SHA@',1))
assert not (NEW/'output').exists()
handoff={'status':'ROOT_REVIEW_UNIQUE_AUTHORIZED05_BOUND01_FINITE_CPU_READY_NOT_RUN',
    'publisher':pin(ready),'input':input_pin,'template':pin(template),'preparation_builder':pin(Path(__file__)),
    'Root_arithmetic_authorization':pin(approval),'source_expression_proof':pin(proof_path),
    'parent_actual04_input':pin(ORIGINAL/'input_READY.json'),'parent_actual04_publisher':pin(ORIGINAL/'publisher_READY.gd'),
    'whole_typed_and_serialized_byte_input_inverse_to04':True,
    'input_allowed_differences':['Exactly two source-derived raw-oracle points_px arrays (4 float components)','Original5 source-file declarations plus new derivation-proof leaf, explicitRoot approval leaf and their provenance rows','New absent output prefix only'],
    'publisher_exact_whole_byte_inverse_to_actual04':True,
    'publisher_only_changes':['INPUT path04->05_bound01','INPUT_SHA7B1D->new fixed SHA','OUT path04->05_bound01'],
    'publisher_behavior_changed':False,'source_pin_count':len(data['source_pins']),
    'Root_relevant_prior_permissions':data['preparation_approval'],'Root_exact_route1135_permission':data['route_amendment'],
    'finite_domains':{'Market':{'pixels':1443,'native_visuals':[24,23],'native_solids':[31,30],'DG_solids':13,'combined_solids':[44,43],'new_witnesses':2},'Yamen':{'pixels':7622,'native_visuals':[24,27],'native_solids':[29,32],'DG_solids':10,'combined_solids':[39,42],'changed_route_points':4,'changed_connections':5,'inherited_near_tangent_segments':[5,6],'DG_NPC_complete_lanes':6,'native_source_NPC_anchor_checks':3}},
    'expected_coordinate_construction':'Only B11/0F824/EAC and originalC/BASE expression; not112732native diagnosis, not current hash backfill, no epsilon.',
    'geometry_PNG_resource_or_Field_runs_in_preparation':0,'canonical_writes':0,'output_folder_exists':False,
    'pending':'Root must inspect then execute this one publisher once. Native/route/mask validation not yet passed; imported media/originalalpha limitedGPU/runtime consumers remain separately pending.'}
print(json.dumps(save(NEW/'handoff_READY.json',handoff)))
