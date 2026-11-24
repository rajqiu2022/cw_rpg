"""Root-authorized mechanical READY only. This never starts the CPU key."""
from pathlib import Path
import copy,difflib,hashlib,json,struct
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
base=N/'docks_loading08_local01_NOTREADY';out=base/'ROOT_READY01'
P=S+'docks_loading08_local01_NOTREADY/';R=P+'ROOT_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
old_code=(base/'publish_loading_delta_NOTREADY.gd').read_bytes()
old_input=(base/'input_NOTREADY.json').read_bytes()
assert sha(old_code)=='460719570d305afcb3f1b90e3b56d21c81f6c1fce965713d5a4de1694f6eb4ad'
assert sha(old_input)=='90f2cb8a11c7178b9baf11a3927adcf51122e761efabe9dee4046f680ba42cb3'
old=json.loads(old_input);new=copy.deepcopy(old)
assert not new['ready'] and not new['root_run_authorized']
new['ready']=True;new['root_run_authorized']=True;new['output_root']=R+'output_ROOT_READY/'
new_input=enc(new);new_code=old_code
changes=[('const READY: bool=false','const READY: bool=true'),('const INPUT: String="'+P+'input_NOTREADY.json"','const INPUT: String="'+R+'input_ROOT_READY.json"'),('const INPUT_SHA: String="'+sha(old_input)+'"','const INPUT_SHA: String="'+sha(new_input)+'"'),('const SELF: String="'+P+'publish_loading_delta_NOTREADY.gd"','const SELF: String="'+R+'publish_loading_delta_ROOT_READY.gd"')]
for a,b in changes:
 assert new_code.count(a.encode())==1;new_code=new_code.replace(a.encode(),b.encode(),1)
back=new_code
for a,b in reversed(changes):assert back.count(b.encode())==1;back=back.replace(b.encode(),a.encode(),1)
assert back==old_code
restore=copy.deepcopy(new);restore['ready']=old['ready'];restore['root_run_authorized']=old['root_run_authorized'];restore['output_root']=old['output_root'];assert enc(restore)==old_input
binding=json.loads((N/'docks_gallery_family_repair01/closure_READY01/finish8_binding_READY.json').read_bytes())
row=binding['scenes']['ch4_s2_canal_docks'];pin=row['payload'];payload=(G/pin['path'][6:]).read_bytes();assert sha(payload)==pin['sha256']=='76577ebe4246926124973aba0adcd014226f4a1c2f3afede6837294ab969154d'
t=(N/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf-8');scope={'struct':struct};exec(t[t.index('class FrozenVariant:'):t.index('binding_pin=')],scope)
v=scope['FrozenVariant'](payload);d=v.value();assert v.p==len(payload)
assert len(d['new_route_contracts'])==1
contract=d['new_route_contracts'][0]
assert contract['source_portal_id']=='canal_world_ferry' and contract['source_foot_px']==(2140.0,1840.0)
assert all(k not in contract for k in ['route_id','points_px','new_source_routes'])
assert 'packing_attendant_approach' not in json.dumps(d['new_route_contracts'])
evidence=dict(status='READONLY_FIXED_DOCKS_PAYLOAD_ROUTE_CONTRACT_RANGE_NOT_ACTUAL_NEW_CPU',parent_payload=pin,selector='$.new_route_contracts[0] (the entire sole row)',row_count=1,inherited_native_var_sha256=row['fingerprints']['new_route_contracts'],row=contract,packing_not_present_anywhere_in_this_array=True,packing_source_selector='author08.scenes[3].new_source_routes[1]',packing_source_points=new['author'],packing_points_px=[[1430,1910],[1940,1910],[1940,1888]],reason='Runtime new_route_contracts is only cross-scene authored arrival; packing is an independent source-author local body route read and checked directly by this CPU key. It is not silently left at2060 in a runtime route table.',engine_calls=0,collector_calls=0,canonical_writes=0)
proof=dict(status='ROOT_AUTHORIZED_LOADING08_MECHANICAL_READY_WHOLE_BYTE_INVERSE_NOT_EXECUTED',parent_code=dict(path=P+'publish_loading_delta_NOTREADY.gd',sha256=sha(old_code)),candidate_code=dict(path=R+'publish_loading_delta_ROOT_READY.gd',sha256=sha(new_code),bytes=len(new_code)),parent_input=dict(path=P+'input_NOTREADY.json',sha256=sha(old_input)),candidate_input=dict(path=R+'input_ROOT_READY.json',sha256=sha(new_input),bytes=len(new_input)),code_exact_four_header_changes=[dict(old=a,new=b)for a,b in changes],input_changes=['ready false->true','root_run_authorized false->true','output_root NEW ROOT_READY01'],source_geometry_body_mask_threshold_and20s_unchanged=True,code_and_input_whole_byte_inverse=True,engine_calls=0,canonical_writes=0)
assert not out.exists();out.mkdir()
files={'publish_loading_delta_ROOT_READY.gd':new_code,'input_ROOT_READY.json':new_input,'project.godot':(base/'project.godot').read_bytes(),'mechanical_READY_whole_inverse.json':enc(proof),'route_contract_range_READONLY.json':enc(evidence)}
for name,b in files.items():
 with(out/name).open('xb')as stream:stream.write(b)
print(json.dumps({name:{'path':R+name,'sha256':sha(b),'bytes':len(b)}for name,b in files.items()}))
