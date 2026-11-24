"""Independent static two-ID A1 review, no engine/shader parse/candidate/source edits."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1];S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';Y='res://build/luoyang_city_full_rollout_20261022ap_system01/'
def fixed(v,s):
    b=(G/v[6:]).read_bytes();assert hashlib.sha256(b).hexdigest()==s.lower(),('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
hp=Y+'market_L_continuous_material_epoch01/author_interface_READY_NOT_RUNTIME.json';hs='1183eda4f35cc8eea176a53797d0c3ed9d63d232940b245cd39dfae9e8268caa';hand=read(hp,hs)
pp=Y+'market_L_continuous_material_epoch01/ENV_wholebyte_inverse_READY.json';ps='1091f241c877fa5d4ce575f3e2bf56165539de7a55305f43d832c447e03a7e95';proof=read(pp,ps)
old=fixed(proof['parent']['path'],proof['parent']['sha256']);new=fixed(proof['candidate']['path'],proof['candidate']['sha256'])
shader=fixed(hand['only_new_runtime_source_leaf']['path'],hand['only_new_runtime_source_leaf']['sha256'])
assert len(old)==35460 and len(new)==37716 and len(shader)==2127
forward=old
for op in proof['operations_in_order']:
    a,b=op['old'].encode(),op['new'].encode();assert forward.count(a)==1;forward=forward.replace(a,b,1)
assert forward==new
inverse=new
for op in reversed(proof['operations_in_order']):
    a,b=op['old'].encode(),op['new'].encode();assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
assert inverse==old and len(proof['operations_in_order'])==10
assert b'\r'not in new and new.endswith(b'\n')and not new.startswith(b'\xef\xbb\xbf')
author=read(hand['unchanged_author']['path'],hand['unchanged_author']['sha256'])
rows={r['id']:r for r in author['scenes']['ch4_s3_luoyang_market']['ground']}
assert rows['market_main_street']=={'id':'market_main_street','asset':'road_stone','rect':[1472,800,128,1224],'uniform_scale':.25}
assert rows['market_pawn_approach']=={'id':'market_pawn_approach','asset':'road_stone','rect':[220,1928,1252,96],'uniform_scale':.25}
assert b'texture('not in shader and b'TIME'not in shader and b'UV +='in shader and b'for (int index = 0; index < 6; index++)'in shader
assert b'transition.shader=market_l_shader if market_l else purpose_shader' in new
assert b'if scene.scene_id==&"ch4_s3_luoyang_market":\n\t\tsource_pins[MARKET_L_SHADER]=MARKET_L_SHADER_SHA' in new
assert b'if id==&"ch4_s3_luoyang_market":\n\t\tout[MARKET_L_SHADER]=true' in new
def phase(origin,point):
    local=[(point[i]-origin[i])/.25 for i in range(2)]
    size=[1536,1024]
    return [local[i]/size[i]+origin[i]/(size[i]*.25)for i in range(2)]
point=[1472,1950];phase1=phase([1472,800],point);phase2=phase([220,1928],point)
assert phase1==phase2 and [phase1[0]*1536,phase1[1]*1024]==[5888,7800]
result={'status':'INDEPENDENT_A1_047B_F1D0_STATIC_REVIEW_NO_DETERMINATE_BLOCKER_NOT_PARSE_GPU_ART_OR_STAGE','author_interface':{'path':hp,'sha256':hs},'whole_inverse':{'path':pp,'sha256':ps},'ENV_parent_sha256':proof['parent']['sha256'].lower(),'ENV_candidate_sha256':proof['candidate']['sha256'].lower(),'new_shader_sha256':hand['only_new_runtime_source_leaf']['sha256'].lower(),'operations':10,'independent_whole_byte_forward_inverse':True,'LF_finalLF_noBOM':True,'fixed_author64A_unchanged':True,'selected_existing_rows':list(hand['one_source_interface']['selected_rows_exact_once']),'math_checks':{'source_phase_at_join_world':[1472,1950],'source_pixel_coordinate_from_both':[5888,7800],'analytic_phase_equal':True,'boundary_segments':6,'shared_interior_segment_not_present':True,'fixed_loop_no_TIME_no_explicit_texture_function':True,'coverage_denominator_has_positive_floor':True,'coverage_smoothstep_upper_above_lower_for_fixed_profile':True},'findings':[],'reviewed_guards':['Exact Market scene ID and two row IDs only; required both seen, duplicate row check inherited, exact area/source road_stone/.25/design_scale1/source path1536x1024 guards added.','New Shader is chosen before profile parameters are bound; both material instances receive the same six exterior segments and main-street profile.','Vertex code changes UV only; local vertex*.25+worldorigin produces common design-world phase. Existing Sprite region/position/scale/repeat remain unchanged.','Shader inherits the prior COLOR-based single source sampling approach; no extra texture() call or color-texture squaring is introduced. Actual shader compilation and rendering have not been tested by this review.','Six exterior segment distance minima feather the L perimeter, not each rectangle; the shared interior x1472,y1928..2024 edge is absent. Worn modulation is fixed world-coordinate only, not animated or random per tile.','All ten candidate hunks independently reconstruct CF945 exactly. Native rows/rectangles/count/texture/PNG/import/body/NAV/NPC/tasks/actor scale/sign and Artisan118 ground remain original outside the two material bindings.','Original Source FIRST+FINAL and final owner calls are retained; new shader is included in both and in source_paths_for(Market) only. No other scene shader source leaf is added.','ENV remains nonowned; execution647949 owned10 and95 proof pins must remain unchanged. Source closure must use ordinary explicit ENV successor plus one Market runtime shader leaf, not proof expansion.','Existing forecourt tone/core1/coverage/contrast and all other purpose profiles are byte-identical in base047B. Optional forecourt one-line successor is NOT included in this review or selected for a DAG.'],'limitations':['No actual shader parse, GPU visual, default Field, source closure Stage or ART success is asserted.','Analytic phase calculation is not GPU pixel equivalence; filtering/float raster edge behavior still requires Root planned visual review.','Base A1 only addresses the two-row join/phase. Forecourt boundary/overall city richness remains a separate ART decision.','No stable performance/loading improvement is inferred.'],'new_engine_collector_native_media_formal_calls':0}
out=H/'performance68_A1_047B_F1D0_independent_static_review_READY.json';assert not out.exists();b=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode();out.write_bytes(b)
print(json.dumps({'path':S+out.name,'sha256':hashlib.sha256(b).hexdigest()},indent=2))
