"""Source-only local deletion oracle. Reads fixed old artifacts; never writes images/native/canonical."""
from pathlib import Path
import json,hashlib,struct,math
from PIL import Image
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';OUT=N/'docks_gallery_retirement01';P=S+'docks_gallery_retirement01/';ID='finish_i_docks_weighing_gallery';SCENE='ch4_s2_canal_docks'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return b
def pin(p,h):return dict(path=p,sha256=h)
def emit(name,b):
 p=OUT/name
 with p.open('xb')as f:f.write(b)
 return dict(path=P+name,sha256=sha(b),bytes=len(b))
assert not OUT.exists();OUT.mkdir()
# Reuse only the finite binary selector class, never run its earlier audit body.
text=(N/'audit_finish8_render_texture_domains_READONLY.py').read_text();classcode=text[text.index('class FrozenVariant:'):text.index('binding_pin=')];env={'struct':struct};exec(classcode,env);Decoder=env['FrozenVariant']
bindpin=pin(S+'gate_texture_repair01/closure_READY01/finish8_binding_READY.json','5098755c3df66ab173522547692526ad50761835d81a9e1ebfab1ba8aadf04f4');binding=json.loads(read(**dict(p=bindpin['path'],h=bindpin['sha256'])));bound=binding['scenes'][SCENE]
raw=read(bound['payload']['path'],bound['payload']['sha256']);decoder=Decoder(raw);payload=decoder.value();assert decoder.p==len(raw)
priorpin=pin('res://build/luoyang_city_finish_20261025i_system01/qa_role_new/remaining_six_domains04_ROOT_READY/output_ROOT_READY/61996/expected_remaining_geometry_and_RGBA_domains.bin','41991264a93360e3c6cd7d2e27857a87d51b1c99c0fc10ef62f442b745bfb5d2');r=Decoder(read(priorpin['path'],priorpin['sha256']));independent=r.value()['geometry'][SCENE];assert r.p==len(r.b)
oldrows=independent['old_retained'];newrows=independent['new_appended'];retired=[r for r in newrows if r['owner_id']==ID];retained=[r for r in newrows if r['owner_id']!=ID];assert len(oldrows)==35 and len(newrows)==8 and len(retired)==len(retained)==4
assert payload['effective_solids']==[r['points_px']for r in oldrows+newrows]
authorpin=pin(S+'author_adjacent_four_fields07_final_dry_bank_routes_NOTREADY.json','fcbfa06b2347bf89e0c86cb4c7817be6781b6e574e01507e6098446afb419d20');author=json.loads(read(authorpin['path'],authorpin['sha256']));scene=next(r for r in author['scenes']if r['scene_id']==SCENE);placement=next(r for r in scene['placements']if r['id']==ID)
librarypin=pin(S+'adjacent_adopted_asset_library03_SOURCE_ONLY.json','81f24069cfa7d974a189610fea32fa967761db9fff437707041193364575d2d1');library=json.loads(read(librarypin['path'],librarypin['sha256']));asset=library['assets'][placement['asset_id']]
assert placement['asset_id']=='open_gallery'and placement['foot_px']==[1850,1780]and placement['scale']==.36 and asset['source_solid_rects_px']==[[584,766,124,40],[1039,766,116,40],[1465,766,119,40],[1904,766,124,40]]
assert [[list(q)for q in r['points_px']]for r in retired]==placement['source_derived_new_ground_polygons_f32']
supportpin=dict(path='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/publication01/output/78128/walk_overlay.png',sha256='e3128b6a985362d1f884e5b4f6c73e3b1596659bd358734b2db5fb59e74eef3b',RGBA_sha256='0d0a5871dfa2dcd76c12861b238161f23e30f16ddbe71a545b62d2eeb1bb0816')
read(supportpin['path'],supportpin['sha256']);read(bound['mask']['path'],bound['mask']['sha256']);before=Image.open(G/bound['mask']['path'][6:]).convert('RGBA');support=Image.open(G/supportpin['path'][6:]).convert('RGBA');assert before.size==support.size==(3072,2048)and sha(before.tobytes())==bound['mask']['RGBA_sha256']and sha(support.tobytes())==supportpin['RGBA_sha256']
domains=[];visited=changed=0
for row in retired:
 points=row['points_px'];d=[math.floor(min(q[0]for q in points)),math.floor(min(q[1]for q in points)),math.ceil(max(q[0]for q in points)),math.ceil(max(q[1]for q in points))]
 # All four retained NEW bodies lie outside every retired post domain. Original
 # office/native bodies are already encoded in the immutable support, never whitewashed.
 for other in retained:
  p=other['points_px'];box=[min(q[0]for q in p),min(q[1]for q in p),max(q[0]for q in p),max(q[1]for q in p)];assert box[2]<d[0]or box[0]>d[2]or box[3]<d[1]or box[1]>d[3]
 b=bytearray();a=bytearray();count=0
 for y in range(d[1],d[3]+1):
  for x in range(d[0],d[2]+1):
   q=bytes(before.getpixel((x,y)));r=bytes(support.getpixel((x,y)));b.extend(q);a.extend(r);count+=q!=r
 visited+=(d[2]-d[0]+1)*(d[3]-d[1]+1);changed+=count;domains.append(dict(retired_polygon_id=row['id'],closed_xyxy=d,before_RGBA_hex=b.hex(),after_RGBA_hex=a.hex(),before_sha256=sha(b),after_sha256=sha(a),changed_pixels=count,oracle='Immutable original35-body support exactly; retained new4 bboxes proven disjoint'))
assert visited==2928 and changed==630 and [r['changed_pixels']for r in domains]==[0,0,0,630]
oracle=emit('four_post_domain_source_oracle_NOTREADY.json',enc(dict(status='SOURCE_DERIVED_LOCAL_DELETE_ORACLE_FROM_FIXED_INDEPENDENT_BAC2_ROWS_NOT_NEW_INDEPENDENT_ENGINE_RESULT',scene_id=SCENE,retire_id=ID,inherited_independent_geometry=priorpin,retired_named_rows=retired,retained_new_named_rows=retained,old35_original_support=supportpin,closed_domains=domains,visited_pixels=visited,changed_pixels=changed,new_NAV_count=43,new_solids_count=39,old_NAV_count=44,old_solids_count=43,full_old_87517_or_routes_replayed=False,new_full_RGBA_independent_hash_claim=False,engine_calls=0,PNG_writes=0)))
contract=emit('retirement_source_contract_NOTREADY.json',enc(dict(status='ROOT_AUTHORIZED_ONLY_GALLERY_AND_FOUR_POSTS_RETIREMENT_NOT_ACTUAL',scene_id=SCENE,retire_id=ID,author=authorpin,library=librarypin,placement=placement,asset=asset,retired_polygons_source=placement['source_derived_new_ground_polygons_f32'],closed_domains=[r['closed_xyxy']for r in domains],ferry_contract_only=dict(source_portal_id='canal_world_ferry',old_source_foot_px=[340,1840],new_source_foot_px=[2140,1840],portal_pos_and_polygon_unchanged=True),old_office_warehouse_doors_NPC_routes_cargo_unchanged=True,permission_is_not_result=True)))
sources={p['path']:p['sha256']for p in [bindpin,priorpin,authorpin,librarypin,supportpin,oracle,contract]};sources[bound['payload']['path']]=bound['payload']['sha256'];sources[bound['mask']['path']]=bound['mask']['sha256']
pubpin=pin(S+'publication11/output_ROOT_READY/109200/result.json','f4925d3ff6e57900a0f7ac0c1549b9477fe9ce3ad255882096a3cd956222df66');sources[pubpin['path']]=pubpin['sha256'];publication=json.loads(read(pubpin['path'],pubpin['sha256']));assert publication['passed']and publication['complete']
protect=json.loads((N/'market_ground_texture_repair02/current5D6C_backup25_ROOT_ACTUAL.json').read_bytes())
spec=dict(status='ONLY_DOCKS_GALLERY_RETIREMENT_LOCAL_COMPONENTS_BUILD_NOT_RUNTIME',ready=False,root_run_authorized=False,whole_budget_ms=20000,scene_id=SCENE,retire_id=ID,sources=sources,parent_binding=bindpin,parent_payload=bound['payload'],parent_mask=bound['mask'],support_mask=supportpin,author=authorpin,library=librarypin,independent_geometry=priorpin,local_oracle=oracle,source_contract=contract,inherited_whole_publication=pubpin,save_absolute_paths=list(protect['save15']),output_root=P+'output_NOTREADY/',scope='Only 4 post domains; no Scene/Field/portal movement/geometry recompilation/routes/PNG art/native writes/import.')
ip=emit('input_NOTREADY.json',enc(spec));print(json.dumps(dict(input=ip,oracle=oracle,contract=contract,domains=[r['closed_xyxy']for r in domains],visited=visited,changed=changed)))
