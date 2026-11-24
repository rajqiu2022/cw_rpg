"""NEW pending typed-pair key successor: independently require old actual pairs true."""
import difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance18_numeric_leaf_candidate01/';O=S+'performance19_typed_pair_key01/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
oldkey=P+'test_typed_packet_comparison_PENDING_ROOT.gd';oldsha='73914c0f1516f164d5199cd514c0f161cb5eb1302f6a28bb334b0f4f8a069db0'
oldfixture=P+'typed_packet_comparison_fixture_PENDING_ROOT.json';fixturesha='e84ce87487ce2c298e70b8ed8757aa430ed6bc87d66b5d0efc8909fdad95ee13'
kb=fixed(oldkey,oldsha);fb=fixed(oldfixture,fixturesha)
fp=O+'typed_packet_comparison_fixture_PENDING_ROOT.json';kp=O+'test_typed_packet_comparison_PENDING_ROOT.gd'
hunks=[{'old':'const FIXTURE="'+oldfixture+'"','new':'const FIXTURE="'+fp+'"'},
 {'old':'\tcheck(baseline==deployed and baseline==proposed,label+": old-wire/deployed7123/numeric results exactly same")\n',
  'new':'\tcheck(baseline==deployed and baseline==proposed,label+": old-wire/deployed7123/numeric results exactly same")\n\tif label.begins_with("actual pair"):\n\t\tcheck(baseline,label+": independently reconstructed old complete inverse must accept")\n'}]
new=kb
for h in hunks:
    a,b=h['old'].encode(),h['new'].encode();assert new.count(a)==1;new=new.replace(a,b,1)
back=new
for h in reversed(hunks):assert back.count(h['new'].encode())==1;back=back.replace(h['new'].encode(),h['old'].encode(),1)
assert back==kb
diff=''.join(difflib.unified_diff(kb.decode().splitlines(True),new.decode().splitlines(True),fromfile=oldkey,tofile=kp)).encode()
hand={'status':'BUILD_ONLY_NUMERIC_LEAF_CANDIDATE_AND_UNIQUE_TYPED_PACKET_KEY_NOT_APPROVED_OR_RUN','ready':False,
 'candidate':{'path':P+'Bundle_numeric_leaf_wire_CANDIDATE.gd','sha256':'3f002b679ad2855b91a14d23eb0451e64848666a18b3e0c559bd18d04c9578a1'},
 'candidate_inverse_and_design':{'path':P+'whole_byte_inverse_and_design_READY.json','sha256':'18a5354be846ebd5cbad787b81e8352c7c7d92332e792328f19974f798dee47d'},
 'candidate_complete_diff':{'path':P+'complete_vs_7123.diff','sha256':'027eb015eed17cd3a83b3199511d8482cdd54329fbcdcfebc4f66c1b26f80e41'},
 'pending_key':{'path':kp,'sha256':sha(new)},'pending_fixture':{'path':fp,'sha256':sha(fb)},
 'key_parent':{'path':oldkey,'sha256':oldsha},'whole_pending_key_byte_inverse':True,'hunks':hunks,
 'key_diff':{'path':O+'key_successor_complete.diff','sha256':sha(diff)},
 'independent_actual_pair_expectations':'Both native-T clone pair and native t_parent_record versus frozen84632 JSON pair must be accepted by the old full-wire predicate, not merely all three implementations agree false. The first strict rejection path/type/depth is reported; unobserved or unsupported leaves never imply fast success.',
 'one_fixed_native_T_packet_decode_future_only':{'path':'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/packet.bin','sha256':'04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df'},
 'root_future_external_wall_bound_required':True,'engine_parse_Stage_collector_formal_writes':0,'no_Vector_Packed_object_domain_expansion':True}
files={'typed_packet_comparison_fixture_PENDING_ROOT.json':fb,'test_typed_packet_comparison_PENDING_ROOT.gd':new,'key_successor_complete.diff':diff,'handoff_PENDING_ROOT_NOT_RUN.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
