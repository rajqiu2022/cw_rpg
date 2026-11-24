"""Freeze finite route proposals and exact old body/mask provenance for independent QA.
No route result is inferred here; no PNG/packet/resource decoding.
"""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,value):
 b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
raw=(N/'author_adjacent_four_fields04_actual_actor_id_NOTREADY.json').read_bytes();assert sha(raw)=='599be0fec8ed3f39f6a509a6d2c0136d0e98a755e64bef95deb773b11608bd47'
old=json.loads(raw);a=copy.deepcopy(old)
routes={
 'ch4_s3_luoyang_market':[('inn_work_court_to_traveller_approach',[[560,880],[560,800],[700,800],[700,848],[760,848]])],
 'luoyang_estate_riverside_20261021ai':[('ancestral_keeper_approach',[[1150,1880],[1150,1920],[650,1920],[650,1908]]),('wash_court_worker_approach',[[2190,1820],[2520,1820],[2520,1828]])],
 'luoyang_riverside_garden_20261022ap':[('west_bank_soft_path',[[520,1520],[640,1520],[640,1420],[740,1360],[860,1260],[860,1160]]),('east_bank_soft_path',[[2280,1120],[2440,1180],[2680,1340],[2780,1520]])],
 'ch4_s2_canal_docks':[('booking_to_cargo_lane',[[1180,1348],[1430,1348],[1430,1910]]),('packing_attendant_approach',[[1430,1910],[2060,1910],[2060,1888]]),('short_storage_front',[[2060,1910],[2800,1910],[2800,1728],[2490,1728]])],
}
for s in a['scenes']:
 s['new_source_routes']=[{'id':id,'points_px':points,'player_body_px':[34,24],'maximum_source_step_px':4,'scope':'New courtyard/actor approach proposal only, independent mask/body/NPC result pending; no old passed route replay'} for id,points in routes[s['scene_id']]]
 if s['scene_id']=='luoyang_riverside_garden_20261022ap':
  # Source design correction: old line to1000,1160 entered the protected river,
  # and the diagonal to760,1420 cut the newly placed flower bed800,1450.
  s['new_soft_path_source_override']={'west_polyline_px':routes[s['scene_id']][0][1],'reason':'Stay on west bank, route around added8001450 flowerbed; no bridge/water/source primitive or NPC change','not_yet_NAV_or_ART_pass':True}
pin=emit('author_adjacent_four_fields05_routes_NOTREADY.json',a)
sources={
 'ch4_s3_luoyang_market':{'mask':{'path':'res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/walk_overlay.png','sha256':'b59f79c8b408a326f1571a6918aeaa029328ae3e45083b47d60a7813c47790da','RGBA_sha256':'ea4be52c5a599d2078d10946ea43b78068c7631c26cb1b19859a53264cca2ba1'},'geometry':{'path':'res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/geometry.bin','sha256':'3bdcf42cecf24bb6a17f7ab95ce0064666360fbbbd2bfab1fe8d6670ea9e3f0e'},'layer_note':'45 is render count, not inferred solid count. Full prior geometry Packed artifact is authority.'},
 'ch4_s2_canal_docks':{'mask':{'path':'res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/publication01/output/78128/walk_overlay.png','sha256':'e3128b6a985362d1f884e5b4f6c73e3b1596659bd358734b2db5fb59e74eef3b','RGBA_sha256':'0d0a5871dfa2dcd76c12861b238161f23e30f16ddbe71a545b62d2eeb1bb0816'},'geometry':{'path':'res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/publication01/output/78128/geometry.bin','sha256':'de7dbc154f52d519550c84d6ee7357f8ab8b0d0b226fca82bf12219f9d7e2835'},'layer_note':'39 NAV rows /35 physical solids; visual count controlled by original task policy.'},
 'luoyang_estate_riverside_20261021ai':{'mask':{'path':'res://data/maps/luoyang_estate_courtyard_20261021am/walk.png','sha256':'5c0babe9a449c95b13ce16ece6a35b39b41fd6e5dca266ed46c1f9f1951b78f2'},'geometry':{'path':'res://build/luoyang_estate_courtyard_20261021an_system01/revision4_route_domain_retry2/geometry/16580/result.json','sha256':'0d590a001eadf2a3dd5348be7a69c2f72b40c52fa69dc7164e6bae7b44638d26','selector':['geometry','all_solids'],'rect_count':48,'rect_expression':'source floats -> Vector2f32 low and size; high=low+size; do not reinterpret as roof'},'layer_note':'Current111 visuals;48 ground rectangles source in retained production geometry receipt.'},
 'luoyang_riverside_garden_20261022ap':{'mask':{'path':'res://build/luoyang_garden_river_20261025h_source01/publication01/output/native/luoyang_riverside_garden_20261022ap/walk.png','sha256':'4cc4fb19ce0df4500e4da12a446b5900cc84b33bf8a0f5aeb1aaa78e59bc7656','RGBA_sha256':'d552010ef7108d37c38ee472106b244bdc5145ea3ef41748cbd103cfaeb6c456'},'geometry_source':{'path':'res://build/luoyang_garden_river_20261025h_source01/independent_source_pixel_model02_PRIOR_PROPOSAL.json','sha256':'315df3719cde0adccb4a1d226ce7c73ec657ecc71f868c18b9f2d04428d1319d','selector':['new_non_water_rectangles'],'non_water_rect_count':14},'river_source':{'path':'res://build/luoyang_garden_river_20261025h_source01/author_river_bridge03_NOTREADY.json','sha256':'06d873797e954a4f7b874a85b421a1b1dda87b2072170d7749eeaaf3ddc77cb6','selector':['scenes',0,'water_polygons',0],'policy':'For local points reject water except exact fixed deck_rect_f32 from prior; no clip/oldwaterpixel/oldbridge route replay needed'},'layer_note':'Formal binding7ECB says56 visuals/16 solids (14 non-water rectangles +2 physical water pieces). Do not conflate old46 layer or NAV row count with current physical count.'}}
for s in sources.values():
 for value in s.values():
  if isinstance(value,dict) and 'path' in value:
   assert sha((G/value['path'][6:]).read_bytes())==value['sha256'],value['path']
handoff=emit('adjacent_old_geometry_and_new_route_scope05_NOTREADY.json',{'status':'FIXED_PARENT_BODY_MASK_SOURCE_AND_NEW_SHORT_ROUTES_PENDING_INDEPENDENT_QA','author':pin,'asset_library':{'path':NS+'adjacent_adopted_asset_library03_SOURCE_ONLY.json','sha256':'81f24069cfa7d974a189610fea32fa967761db9fff437707041193364575d2d1'},'sources':sources,'new_masks_add_only':'All static new props append, no old physical retire/move in these4. Parent RGBA AND NOT new ground union within exact new domains; outside whole bytes preserved. NPC moves are dynamic guards, not raster holes.','old_packet_decode_calls':0,'engine_calls':0,'collector_calls':0,'new_routes_are_not_PASSED':True})
print(json.dumps({'author':pin,'oldsource_and_route_handoff':handoff}))
