"""Freeze finite wall retirement author/delta recipe; no engine or image decode."""
from pathlib import Path
import json,hashlib,struct,re
ROOT=Path(__file__).resolve().parent;GAME=ROOT.parent.parent
OUT=ROOT/'market_wall_retirement_epoch01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rp(p):return 'res://'+str(p.relative_to(GAME)).replace('\\','/')
def row(p):return {'path':rp(p),'sha256':sha(p),'bytes':p.stat().st_size}
def save(n,data):
 p=OUT/n;assert not p.exists();p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');return row(p)
def png_size(path):
 with path.open('rb') as f: header=f.read(24)
 assert header[:8]==b'\x89PNG\r\n\x1a\n' and header[12:16]==b'IHDR'
 return list(struct.unpack('>II',header[16:24]))
report_path=ROOT/'market_alpha_pin_retry6/publication/17536/result.json'
report=json.loads(report_path.read_text(encoding='utf-8'))
assert report['passed'] is True and report['native_count']==24 and report['district_count']==36
author_path=ROOT/'market_alpha_pin_retry6/market_author.json'
author=json.loads(author_path.read_text(encoding='utf-8'))
assert report['source_first'][rp(author_path)]==sha(author_path) and report['source_final'][rp(author_path)]==sha(author_path)
helper=OUT/'pure_wall_retirement_candidate.gd'
assert sha(helper)=='831b6a705990f74e1e98d5de38c26478326d4d11e41b2cd991da4db18a6ab0c7'
for p,h in report['artifacts'].items():assert sha(GAME/p.removeprefix('res://'))==h
mask=GAME/report['walk_candidate']['future_path'].removeprefix('res://')
assert sha(mask)==report['walk_candidate']['sha256']=='16da1638c1aeb3c9761d0b988da70aa0f761c29e2a9ab8ec3acdf3fffda214ea'
assert report['walk_candidate']['rgba_sha256']=='d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e'
wall=author['layout_successor']['wall'];assert wall['id']=='v13_market_west_plot_wall' and wall['solid']==[35,1408,110,12]
wall_png=GAME/'art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png'
raw=GAME/'art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/raw_walk.png'
assert sha(raw)==report['source_first'][rp(raw)]==report['source_final'][rp(raw)]=='0dc78a4affde8a13d1d2f58385b4ac5da102b1718f8e5b48d12dd066b0dedcfa'
fixture=ROOT.parent/'luoyang_city_full_rollout_20261022ap_qa01/bounded_groups_v5_author_anchors_READY.json'
fixed=json.loads(fixture.read_text(encoding='utf-8'));market=next(s for s in fixed['scenes'] if s['id']=='ch4_s3_luoyang_market')
solid=next(s for s in market['geometry']['solids'] if s['id']=='v13_market_west_plot_wall_poly_0')
assert solid['points_px']==[[35,1408],[145,1408],[145,1420],[35,1420]]
domain=[35,1408,111,13]
def bbox(points):return [min(p[0] for p in points),min(p[1] for p in points),max(p[0] for p in points),max(p[1] for p in points)]
def overlap(a,b):return not (a[2]<b[0] or b[2]<a[0] or a[3]<b[1] or b[3]<a[1])
near=[]
for s in market['geometry']['solids']:
 if s['id']==solid['id']:continue
 points=s.get('points_px')
 if points is None:
  x,y,w,h=s['rect_px'];points=[[x,y],[x+w,y+h]]
 if overlap([35,1408,145,1420],bbox(points)):near.append(s['id'])
assert near==[],near
boxes=report['alpha']['boxes']
def parse_box(identifier):
 match=re.search(r'"'+re.escape(identifier)+r'": Rect2\(([^)]+)\)',boxes)
 assert match;return [float(n.strip()) for n in match.group(1).split(',')]
wall_a1=parse_box(wall['id']);pawn_a1=parse_box('market_west_ward_frontage')
assert wall_a1==[35,1302,110,121]
candidate={
 'schema_version':1,'status':'BUILD_ONLY_NOT_PUBLISHED_NOT_RUNTIME_ADMITTED','scene_id':'ch4_s3_luoyang_market','change_id':'MARKET_ORPHAN_WALL_RETIREMENT_NEW_EPOCH01',
 'decision':'REMOVE_EXACT_ONE_ORPHAN_VISUAL_AND_ITS_ONE_GROUND_SOLID; do not translate110px panel into roof seam.',
 'geometry_parent':{'actual_report':row(report_path),'actual_author':row(author_path),'native_artifacts':report['artifacts'],'walk_png':row(mask),'walk_rgba_sha256':report['walk_candidate']['rgba_sha256'],'raw_ground':row(raw)},
 'asset_dimensions':{'unchanged_wall_png':row(wall_png),'png_IHDR_size':png_size(wall_png),'retained_Atlas':row(GAME/wall['texture'].removeprefix('res://')),'Atlas_region_xywh':wall['source_crop'],'world_render_size':[110,123],'actual17536_A_greater_than_zero_rect':wall_a1,'pawn_A_greater_than_zero_rect':pawn_a1,'horizontal_gap_at_corner_only':pawn_a1[0]-(wall_a1[0]+wall_a1[2]),'join_rejected_reason':'Only16.448px corner gap and21.8047px vertical A1 overlap with pawn roof. Closing it sticks panel to eave, not a courtyard boundary; it loses a usable side passage. A meaningful enclosing wall needs additional separately planned segments, not this orphan.', 'png_bytes_unchanged':True},
 'record_delta':{'remove_object_ids':[wall['id']],'old_native_count':24,'new_native_count':23,'change_fields_only':['objects (remove matching one ordinal)','walk_path (new candidate PNG path after Root authorizes publication)'],'old_record_row_author':'Final AP market_alpha_pin_retry6 wall_record(spec), not older layout_successor2 author as a new expected packet.','whole_inverse_rule':'Insert exact removed Dictionary at recorded original ordinal, restore old walk_path; compare whole typed record.'},
 'visual_delta':{'remove_ids':[wall['id']],'remove_name':'SceneObject_v13_market_west_plot_wall','world_foot':[90,1420],'native_pos_before':[90/3072,1361.5/2048],'render_size':[110,123],'whole_inverse_rule':'Insert exact removed native visual Dictionary at original ordinal; all other23 entries byte/value original.'},
 'solid_delta':{'remove_ids':[solid['id']],'polygon_px':solid['points_px'],'expected_native_solid_count_delta':-1,'no_other_solid_envelope_intersects_removed_polygon':near,'independent_geometry_fixture':row(fixture),'district_spec_additions_unchanged':12,'combined_render_count_before':36,'combined_render_count_after':35,'not_36_after_removal':True},
 'mask_delta_recipe':{'local_pixel_envelope_xywh':domain,'candidate_pixels_only':1443,'output':'future_publication/walk.png (does not exist yet)','algorithm':'Start from exact parent D161 RGBA bytes. Visit only111x13 integer pixels. For each, reproduce original C._raster_walk_cpu raw-ground pixel, border24px, remaining native polygon membership and ceil-half-open rectangle raster. Validate parent pixel equals same original rule WITH wall first; if not, refuse. Child desired pixel is original RAW value unless another native solid blocks it. Never paint blind-white or use last-run observed mask as expected.','native_and_DG_separate':'Parent native mask never incorporates DG delta bodies; keep original12DG projection/solids/prefix untouched. Confirm same frozen domain has no other native/DGsolid envelope here.','full_inverse':'Only changed pixel RGBA overwritten back from parent byte buffer; reconstructed full25MiB array must equal original, proving every other byte unchanged.','no_full_raster_rebuild':True,'no_image_decode_or_processing_executed_by_this_builder':True},
 'door_and_path_preservation':{'room_moves':author['room_moves'],'adult_door_measurements_inherit_17536':report['asset_measurements']['rows'],'all_existing_portals_and_targets_unchanged':True,'all_NPC_definitions_positions_primary_culture_dialogues_unchanged':True,'protected_task_feet_px':author['protected_task_feet_px'],'affected_old_paths_selection':'Read only fixed ED... parent packet.record.routes and gameplay_slots + frozen DG crowd lanes. Segments whose34x30 conservative sweep envelope intersects removed111x13 domain get exact original875+17/fullbody check; outside inherit17536, not full rerun. pure helper returns selected IDs/segments only, no acceptance claim.','new_finite_witnesses':[{'id':'former_wall_crossing','points_px':[[90,1388],[90,1440]],'max_step_px':4},{'id':'former_wall_stand','foot_px':[90,1414],'old_expected':'blocked by original wall','candidate_expected':'must pass original full34x24+875+17 only after local recompute; not yet verified'}],'do_not_replay':['all city collectors','five room native returns','original437 geometry samples','other23native/12DG alpha batches','A/C full functional groups']},
 'pure_transform_helper':row(helper),'not_ready':['Godot parse','actual source-first/final finite native transform','local mask bytes and raw pixel checks','changed-area fullbody/875+17 witness','single native/ordinary-camera visual','sourceonly publication and future narrow ownership successor'],'not_in_existing_epoch':'No old29 targets, pending23 source fix targets, ENV/HUD/hero/portrait/resident code or metadata modified; this future geometry epoch is separate.'}
author_row=save('author_delta_READY.json',candidate)
stage=ROOT.parent/'luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_unified_visual_resident_stage01/receipt.json'
stage_data=json.loads(stage.read_text(encoding='utf-8'))
observed=[]
for path in [GAME/'data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json',GAME/'scripts/city/luoyang_precomputed_bundle_20261018r.gd',GAME/'scripts/city/luoyang_enclosure_v11_candidate_contract.gd']:
 target=next((t for t in stage_data['targets'] if t['target']==rp(path)),None)
 declared=target['candidate_sha256'] if target else stage_data['source_final'].get(rp(path))
 observed.append({'source':row(path),'Root29_declared_sha256':declared,'matches_Root29_declaration':sha(path)==declared,'not_new_expected_admission_from_actual':True})
handoff={'status':'NEW_GEOMETRY_EPOCH_BUILD_ONLY_NOT_OLD29_OR_PENDING23_SCOPE','author_delta':author_row,'helper':row(helper),'parent_actual17536':row(report_path),'Root29_source_DAG_historical_receipt':row(stage),'source_DAG_readonly_observation':observed,'runtime06_note':'Parent source DAG may be superseded by Root pending Router06 source-only23targets. Do not edit those candidates; before future geometry execution Root must explicitly freeze the then-final source DAG. Geometry/native17536 pins remain independent and unchanged.','pure_steps':['remove_record','remove_visuals','native_solids/expected1solid delta','local_mask_delta1443pixels only','affected_path_segments selection only'],'no_execution_or_canonical_or_PNG_write':True}
hand=save('handoff_READY.json',handoff)
print(json.dumps({'author_delta':author_row,'helper':row(helper),'handoff':hand},indent=2))
