"""Generate NEW future canonical-B owner recipe text; never execute that recipe."""
import difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance26_owner_tool_preparation/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
op=S+'prepare_performance15_B_only_actual_owner_NOTRUN.py';os='6e38ab289df09e30ec91d699a295b0c6a050c4c7776b3adc450c525a4df9a3ec'
old=fixed(op,os);text=old.decode()
changes=[
 ('performance15_B_only_actual_independent_review/','performance26_canonical_B_actual_independent_review/'),
 ('performance08_actual_independent_review/owner_source_maps_READY.json','performance15_B_only_actual_independent_review/owner_source_maps_READY.json'),
 ('9d004ac904f42807af3bc5dda757430200f7bebbdaa1ef29487911417e282551','5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e'),
 ('performance14_B_only_source_recipe/source_input_ROOT_LOCKED.json','performance25_canonical_B_source_recipe/source_input_ROOT_LOCKED.json'),
 ('231b66e6beaebdf7c72966e2ce1a19ee56bb3a643f254fbbe20efbcc6f713697','706c58929266d6e0a9cf58a6b94f959383b5d34133acf059cc424251634473bd'),
 ('performance12_B_only_dependencies/handoff_PRODUCTION_PROPOSAL.json','performance24_canonical_B_dependencies/handoff_PRODUCTION_PROPOSAL.json'),
 ('0b475ef75769431cb02b46a2a6e3daab6312ab3a7289b837d361ad2bdedfb79c','3a6200e99bd2a9c2e9ce19aa47eb06f4bb84ba15099e2058bd21de2117f2ce7d'),
 ('outputs/root_B_only_symmetric_wire_stage01/receipt.json','outputs/root_B_canonical_keys_stage01/receipt.json'),
 ('Fixed9D004','Fixed5050'),('fixed9D004','fixed5050'),('INHERITED9D004','INHERITED5050'),('inherited9D004','inherited5050'),('all9D004','all5050'),('All9D004','All5050'),('FIXED9D004','FIXED5050'),('fixed9D004','fixed5050'),
 ('actualD058 metadata','actualAP13_7912 metadata'),('69 execution-proof','71 execution-proof'),('actual22 review and source-only owner successor to fixed9D004','actual22 review and source-only owner successor to fixed5050')]
applied=[]
for a,b in changes:
    if a in text:text=text.replace(a,b);applied.append({'old':a,'new':b})
new=text.encode();kp=S+'prepare_performance26_canonical_B_actual_owner_NOTRUN.py'
back=text
for h in reversed(applied):back=back.replace(h['new'],h['old'])
# Repeated human-readable substrings can overlap; preserve exact offset proof.
aa,bb=old.decode().splitlines(True),text.splitlines(True);hs=[]
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':hs.append({'old_byte_start':len(''.join(aa[:i]).encode()),'old_byte_end':len(''.join(aa[:j]).encode()),'new_byte_start':len(''.join(bb[:k]).encode()),'new_byte_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
fwd=old;inv=new
for h in reversed(hs):fwd=fwd[:h['old_byte_start']]+h['new'].encode()+fwd[h['old_byte_end']:]
for h in reversed(hs):inv=inv[:h['new_byte_start']]+h['old'].encode()+inv[h['new_byte_end']:]
assert fwd==new and inv==old
diff=''.join(difflib.unified_diff(aa,bb,fromfile=op,tofile=kp)).encode()
proof={'status':'FUTURE_ACTUAL_OWNER_TOOL_TEXT_PREPARED_NOT_EXECUTED','tool':{'path':kp,'sha256':sha(new)},'parent_tool':{'path':op,'sha256':os},'whole_tool_byte_inverse':True,'hunks':hs,
 'fixed_prior_owner5050_and_plan706C_and_handoff3A62':True,'actual_future_receipt_sha256':None,'actual_receipt_is_required_external_Root_argument':True,
 'recipe':'Inherit5050 full8scene/5room expectations; four city maps come only from the frozen AO->AP13->new22 source recipe, Quarter/Estate/header source groups from staged candidates, Temple and G full collectors from exact22 value deltas plus2 declared new proof leaves; room receipt maps unchanged via frozen registry040664. No current collector or media crawl.',
 'execute_owner_engine_collector_Stage_calls':0,'diff':{'path':O+'owner_tool_vs_6E38.diff','sha256':sha(diff)}}
assert not p(O).exists()and not p(kp).exists();p(O).mkdir()
p(kp).write_bytes(new);p(O+'owner_tool_vs_6E38.diff').write_bytes(diff);p(O+'owner_tool_whole_inverse_NOT_RUN.json').write_bytes(js(proof))
print(json.dumps({'tool':{'path':kp,'sha256':sha(new)},'proof':{'path':O+'owner_tool_whole_inverse_NOT_RUN.json','sha256':sha(js(proof))},'diff_sha256':sha(diff),'owner_recipe_executed':False},indent=2))
