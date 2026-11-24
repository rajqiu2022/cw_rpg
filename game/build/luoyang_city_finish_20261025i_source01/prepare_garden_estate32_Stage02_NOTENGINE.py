"""Two strict Stage expectation sets add the already-declared Router pin; no source head or Stage execution."""
from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'garden_estate_exit_repair_20261027c01/';O=N/'garden_estate_exit_repair_20261027c01';sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
parent=N/'stage_garden_estate32_ROOT_ONLY.py';old=parent.read_bytes();assert sha(old)=='7f7e608c79d385f732cc36311e206e49c33bc765d9a36bfc1ebe5761bd04d453';t=old.decode('utf8');hs=[]
for a,b in [
 ("need(set(contract['changes'])=={'res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'},'ONLY_CT_FIELD_C_TWO_LITERALS')","need(set(contract['changes'])=={'res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/autoload/scene_router.gd'},'ONLY_CT_FIELD_C_ROUTER_THREE_LITERALS')"),
 ("need(set(temple['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'},'TEMPLE_ONLY_C_FIELD_CT_COORDINATOR_SOURCE_VALUES')","need(set(temple['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/autoload/scene_router.gd'},'TEMPLE_ONLY_C_FIELD_CT_COORDINATOR_ROUTER_FIVE_SOURCE_VALUES')")]:
 assert t.count(a)==1;t=t.replace(a,b,1);hs.append(dict(old=a,new=b))
f=t
for h in reversed(hs):assert f.count(h['new'])==1;f=f.replace(h['new'],h['old'],1)
assert f.encode()==old;compile(t,'stage_garden_estate32_ROOT_ONLY02.py','exec')
dest=N/'stage_garden_estate32_ROOT_ONLY02.py';assert not dest.exists()
with dest.open('xb')as f:f.write(t.encode('utf8'))
driver=dict(path=S+dest.name,sha256=sha(t.encode('utf8')),bytes=len(t.encode('utf8')))
ip=O/'source_input_garden_estate32_ROOT_REVIEW.json';ib=ip.read_bytes();assert sha(ib)=='fb7ade263825e785eeb21351a1a1194c6b0025b09407a155295411a773e08c71';spec=json.loads(ib)
previous=next(r for r in spec['pinned_inputs']if r['id']=='driver');previous.update(driver);spec['output_root']=S+'outputs/root_garden_estate_exact32_stage02/'
new=enc(spec);np=O/'source_input_garden_estate32_ROOT_REVIEW02.json';assert not np.exists()
with np.open('xb')as f:f.write(new)
proof=dict(parent=dict(path=S+parent.name,sha256=sha(old),bytes=len(old)),candidate=driver,hunks=hs,whole_UTF8_forward_inverse=True,input_parent=dict(path=P+ip.name,sha256=sha(ib)),input_candidate=dict(path=P+np.name,sha256=sha(new)),input_changed_fields=['pinned_inputs.driver.path','pinned_inputs.driver.sha256','pinned_inputs.driver.bytes','output_root'],production_candidates_unchanged=True,Stage_calls=0,engine_calls=0)
raw=enc(proof);pp=O/'Stage02_two_expected_sets_transport_inverse_NOT_STAGE.json';assert not pp.exists()
with pp.open('xb')as f:f.write(raw)
print(json.dumps(dict(driver=driver,input=proof['input_candidate'],proof=dict(path=P+pp.name,sha256=sha(raw)),scope_and_all_candidates_unchanged=True)))
