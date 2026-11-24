"""Three source-authored detours around fixed existing bodies; geometry untouched."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
p=N/'author_gate_yamen_axis04_route_detours_NOTREADY.json';oldraw=p.read_bytes();assert sha(oldraw)=='378bdea3d24c076dd1b59cee235171b6f87000adf80b537bd2a9bd617fed9671'
old=json.loads(oldraw);new=copy.deepcopy(old);gate=new['scenes'][0];assert gate['scene_id']=='ch4_s0_luoyang_gate'
changes={
 'west_gallery_clear_side_to_front':[[650,1390],[650,1430],[300,1430],[300,1772],[650,1772]]}
journal=[]
for i,row in enumerate(gate['new_source_routes']):
 if row['id'] in changes:
  journal.append({'pointer':['scenes',0,'new_source_routes',i,'points_px'],'old':row['points_px'],'new':changes[row['id']]});row['points_px']=changes[row['id']]
loop=[[1536,1390],[900,1390],[900,1430],[300,1430],[300,1480],[900,1480],[900,1530],[1536,1530],[1536,1490],[2030,1490],[2030,1320],[2660,1320],[2660,1490],[2030,1490],[1536,1490],[1536,1390]]
for i,row in enumerate(gate['affected_old_route_replacements']):
 if row['id']=='public_loop':
  journal.append({'pointer':['scenes',0,'affected_old_route_replacements',i,'new_points_px'],'old':row['new_points_px'],'new':loop});row['new_points_px']=loop
assert len(journal)==2
back=copy.deepcopy(new)
for row in reversed(journal):
 node=back
 for key in row['pointer'][:-1]:node=node[key]
 assert node[row['pointer'][-1]]==row['new'];node[row['pointer'][-1]]=row['old']
assert back==old
assert (json.dumps(back,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()==oldraw
newraw=(json.dumps(new,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
np=N/'author_gate_yamen_axis05_source_prechecked_routes_NOTREADY.json'
if np.exists():assert np.read_bytes()==newraw
else:
 with np.open('xb') as stream:stream.write(newraw)
prefix=0
while prefix<min(len(oldraw),len(newraw)) and oldraw[prefix]==newraw[prefix]:prefix+=1
tail=0
while tail<min(len(oldraw),len(newraw))-prefix and oldraw[len(oldraw)-1-tail]==newraw[len(newraw)-1-tail]:tail+=1
segments=[{'old_offset':prefix,'new_offset':prefix,'old_hex':oldraw[prefix:len(oldraw)-tail].hex(),'new_hex':newraw[prefix:len(newraw)-tail].hex()}]
forward=oldraw
for r in reversed(segments):
 a=r['old_offset'];o=bytes.fromhex(r['old_hex']);assert forward[a:a+len(o)]==o;forward=forward[:a]+bytes.fromhex(r['new_hex'])+forward[a+len(o):]
assert forward==newraw
inverse=newraw
for r in reversed(segments):
 a=r['new_offset'];o=bytes.fromhex(r['new_hex']);assert inverse[a:a+len(o)]==o;inverse=inverse[:a]+bytes.fromhex(r['old_hex'])+inverse[a+len(o):]
assert inverse==oldraw
proof={'status':'TWO_ROUTES_ONLY_EXACT_TYPED_AND_WHOLE_BYTE_INVERSE_NOT_NEW_RUNTIME_PASS','old':{'path':NS+p.name,'sha256':sha(oldraw),'bytes':len(oldraw)},'new':{'path':NS+np.name,'sha256':sha(newraw),'bytes':len(newraw)},'typed_journal':journal,'byte_segments':segments,'whole_forward_inverse_verified':True,'all_geometry_domains_primitives_NPC_and_other_routes_identical':True,'blocker_source_ids':['district_luoyang_gate_stock_crate_1','v13_gate_provision_stall','district_luoyang_gate_stock_tree_0'],'inherit_Gate_prior_components_only_not_failed_whole':True,'Yamen_first_domain_prior_pending':True}
pb=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();pp=N/'axis_route_residual05_whole_inverse_BUILD.json'
with pp.open('xb') as stream:stream.write(pb)
print(json.dumps({'author':proof['new'],'proof':{'path':NS+pp.name,'sha256':sha(pb),'bytes':len(pb)}}))

