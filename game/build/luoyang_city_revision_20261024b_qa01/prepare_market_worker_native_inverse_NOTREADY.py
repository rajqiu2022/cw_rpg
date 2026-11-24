"""Text-only fixed fixture/key preparation. Never reads either packet payload."""
from pathlib import Path
import hashlib
import json

GAME=Path(__file__).resolve().parents[2]
OUT=GAME/'build/luoyang_city_revision_20261024b_qa01/market_worker_native_inverse_NOTREADY'
RES='res://build/luoyang_city_revision_20261024b_qa01/market_worker_native_inverse_NOTREADY/'
def file(res):
    assert res.startswith('res://') and '..' not in res
    return GAME/res[6:]
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
S='res://build/luoyang_city_space_20261024b_source01/'
runtime=S+'runtime_READY02/market_space_runtime_READY.gd'
binding=S+'runtime_READY02/market_space_binding_READY.json'
map_path=S+'outputs/root_market_dialogue_exact36_stage02/maps/ch4_s3_luoyang_market_true.json'
fixed={
 runtime:'077101d2c4f45b7d4ab02767260de2ae931f84a6c0d6066966f38f814d64aac9',
 binding:'003ec7f690ed9494f315132a4f3f6e16263ad3ca38ccb34392913ae07c5f4cdb',
 map_path:'9459ef7888614c08b465fbd11f072977fbec0ba64f6217d21bc70411a2897c70',
 S+'market_replan_geometry_interaction_successor03_CANDIDATE.gd':'25be67db002ceb1db1990cde55b5b237bcec0bbfbee70aea7e4d7c4b193744ec',
 S+'author_space_delta_interaction_successor03_NOTREADY.json':'cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467',
 S+'author_space_delta_route_detours_successor06_NOTREADY.json':'7e1f6b1dc4dd4d693438bd0f672657063b3f42c0092ad50028f3aa632b03d31f',
 'res://build/luoyang_city_full_rollout_20261022ap_system01/market_wall_retirement_epoch01/pure_wall_retirement_candidate.gd':'831b6a705990f74e1e98d5de38c26478326d4d11e41b2cd991da4db18a6ab0c7',
 'res://build/luoyang_city_revision_20261024b_root01/local_two_asset_admission.json':'317023fa18a840ae053d4e8fef2978d51d383fd7e997d620fec713d7cd96fd39',
 'res://build/luoyang_city_revision_20261024b_root01/market_detours06_READY/input_READY.json':'788a7a067fb1672f448756f28cb545e8c52c937319faf6542b6d7ffd58127367',
 'res://build/luoyang_city_revision_20261024b_root01/market_detours06_READY/output/publication_result.json':'86edae530049c0d5daa a256eba5ae7ae24b71cb92733f875581b86796404e92e'.replace(' ',''),
}
for res,sha in fixed.items(): assert digest(file(res))==sha,(res,sha)
base='res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd'
fixed[base]=digest(file(base))
b=json.loads(file(binding).read_text(encoding='utf-8-sig'))
source_map=json.loads(file(map_path).read_text(encoding='utf-8-sig'))
assert len(source_map['source_sha256'])==1797 and source_map['scene_id']=='ch4_s3_luoyang_market'
assert source_map['source_sha256'][runtime]==fixed[runtime]
for p,sha in b['source_sha256'].items(): assert source_map['source_sha256'][p]==sha,p
assert source_map['source_sha256'][binding]==fixed[binding]
parent=b['old_finite_packet'].copy()
child=b['artifacts']['packet.bin'].copy()
assert parent['sha256']=='81e9f0a7cf7d006514ac4dccf00e8eefdd31bbef53f5c3a479b423c5ae0ad9a2'
assert child['sha256']=='5852b1710144964f2e8a9b321c16fb4c3a4b6e8b123bfc4c0ebabab0a4e1116d'
for row in [parent,child]: row['bytes']=file(row['path']).stat().st_size
fixture={
 'status':'NOTREADY_ROOT_REVIEW_TWO_PACKET_ONLY','ready':False,
 'blockers':['Root must read and mechanically freeze this exact diagnostic before execution'],
 'whole_ms':15000,'runtime':{'path':runtime,'sha256':fixed[runtime]},
 'expected_map':{'path':map_path,'sha256':fixed[map_path],'source_count':1797},
 'small_sources':fixed,'parent_packet':parent,'child_packet':child,
 'scope':{'native_packet_decode_count':2,'original_prepare_context_calls':1,
          'original_validate_child_calls':1,'failure_diagnostic':'first original predicate in original order, strict original _same; first difference depth48',
          'Scene_resource_loads':0,'PNG_decodes':0,'Field_requests':0,'collectors':0,
          'explicit_main_project_autoloads_not_absent':True,'source_table_is_fixed_argument_not_FIRST_FINAL':True,
          'packet_payload_read_by_preparer':False,'whole_budget_ms':15000,
          'packet_final_stat_only':'full SHA is from the sole initial read; Root external guard separate'},
}
fixture_path=OUT/'fixture_NOTREADY.json'
assert not fixture_path.exists()
fixture_path.write_bytes((json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode())
key=OUT/'probe_NOTREADY.gd'
raw=key.read_bytes()
before=raw
for old,new in [('PENDING_FIXED_FIXTURE_PATH',RES+'fixture_NOTREADY.json'),('PENDING_FIXED_FIXTURE_SHA',digest(fixture_path))]:
    assert raw.count(old.encode())==1
    raw=raw.replace(old.encode(),new.encode())
key.write_bytes(raw)
assert b'const PROBE_READY=false' in raw
handoff={'status':'ROOT_REVIEW_NOT_EXECUTED','key':{'path':RES+key.name,'sha256':digest(key)},
 'fixture':{'path':RES+fixture_path.name,'sha256':digest(fixture_path)},
 'parent_packet':parent,'child_packet':child,'small_source_count':len(fixed),
 'text_preparation_only':True,'packet_payload_reads':0,'engine_calls':0,
 'diagnostic_fallback_does_not_change_original_result':True,
 'preserved':['A0FA public-coordinate FAIL','F223 missing-adapter-facts FAIL'],
 'packet_and_helper_scope':'old0771 validate_child_worker only; not full adapter/new4facts/C FIRST FINAL or Field'}
(OUT/'handoff_NOTREADY.json').write_bytes((json.dumps(handoff,indent=2)+'\n').encode())
print(json.dumps(handoff,indent=2))
