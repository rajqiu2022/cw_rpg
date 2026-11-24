"""One original ENV stamp center only; fixed parent whole-byte inverse."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];OUT=N/'cart_ruts_center_visual01_BUILD'
assert not OUT.exists(),'NEW output only'
def sha(b):return hashlib.sha256(b).hexdigest()
parent_path=G/'data/maps/luoyang_full_city_20261022ap/environment.json'
parent=parent_path.read_bytes();assert sha(parent)=='64a7efc81a2d37c588c4d63b302324ff9b2eb90cea932de543e85177e8a4afd2'
old=b'"id": "artisan_service_cart_ruts",\n          "asset": "cart_ruts",\n          "center": [\n            610,\n            1535\n          ],'
new=old.replace(b'610,\n            1535',b'1180,\n            1810')
assert parent.count(old)==1 and parent.count(new)==0
candidate=parent.replace(old,new);assert candidate.count(new)==1 and candidate.replace(new,old)==parent
before=json.loads(parent);after=json.loads(candidate)
old_row=before['scenes']['luoyang_artisan_residential_20261022ap']['ground'][0]
new_row=after['scenes']['luoyang_artisan_residential_20261022ap']['ground'][0]
assert old_row=={'id':'artisan_service_cart_ruts','asset':'cart_ruts','center':[610,1535],'uniform_scale':.16}
expected=json.loads(parent);expected['scenes']['luoyang_artisan_residential_20261022ap']['ground'][0]['center']=[1180,1810]
assert expected==after
restored=json.loads(candidate);restored['scenes']['luoyang_artisan_residential_20261022ap']['ground'][0]['center']=[610,1535]
assert restored==before
OUT.mkdir()
with (OUT/'environment_cart_ruts_center_only_CANDIDATE.json').open('xb') as f:f.write(candidate)
pin=lambda p,b:{'path':'res://'+str(p.relative_to(G)).replace('\\','/'),'sha256':sha(b),'bytes':len(b)}
proof={'status':'BUILD_VISUAL_ONLY_ONE_EXISTING_STAMP_CENTER_NOT_DEPLOYED','parent':pin(parent_path,parent),'candidate':pin(OUT/'environment_cart_ruts_center_only_CANDIDATE.json',candidate),'pointer':['scenes','luoyang_artisan_residential_20261022ap','ground',0,'center'],'before':old_row,'after':new_row,'one_raw_hunk':{'old_utf8':old.decode(),'new_utf8':new.decode()},'whole_typed_inverse':restored==before,'whole_byte_inverse':candidate.replace(new,old)==parent,'full_parent_fields_except_center_identical':after==expected,'existing_texture':'res://art/modules/luoyang_shore_market_20261020ae/decal_docks_cart_ruts_horizontal_v1.png','existing_texture_sha256':'3f4013006fb3fd285cd0ca9306a1028d27e0f6f378ef55c1a25e85f5116e2043','Sprite_centered':True,'uniform_scale_unchanged':.16,'existing_layer_z_unchanged':-4,'centered_complete_A1_world_f32':[1043.3599853515625,1744.320068359375,1317.760009765625,1880.9600830078125],'foot_and_A1_relationship_source_report':{'path':'res://build/luoyang_city_finish_20261025i_source01/street_edges04_BUILD01/cart_ruts11801810_source_relationship_READONLY.json','sha256':'b17256b251ddb88e808e37e2e3a13a96e26044891ef540bd0b7ef93ec5f8eb50'},'ground_count_unchanged':True,'PNG_import_NAV_body_portal_NPC_changes':False,'engine_Stage_collector_calls':0,'canonical_writes':0,'Root_authorization_before_closure_or_deploy':True}
raw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf8')
with (OUT/'center_only_whole_byte_inverse_BUILD.json').open('xb') as f:f.write(raw)
print(json.dumps({'candidate':proof['candidate'],'proof':pin(OUT/'center_only_whole_byte_inverse_BUILD.json',raw)}))
