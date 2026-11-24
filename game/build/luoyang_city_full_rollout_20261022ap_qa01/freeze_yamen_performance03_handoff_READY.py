"""Static freeze, no Godot parse or execution."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
key=ROOT/'tests/test_luoyang_ap_yamen_performance03_LIGHT_ROOT16_READY_20261023.gd'
fixture=QA/'yamen_performance03_fixture_ROOT16_READY.json'
raw=key.read_bytes();fraw=fixture.read_bytes();spec=json.loads(fraw);text=raw.decode()
assert sha(fraw)=='a488ba0536d9df8da4b1130a0ea0f4a11626d8bcc0ff7c88a6f744ef6a02c036'
assert len(spec['source_sha256'])==1237 and len(spec['expected_city_source_sha256'])==1217
for forbidden in ['C.resident_receipt(', 'C.resident_matches(', 'C._transition_sources(', 'C.resolve_scene(', 'C.finalize_live_transition_sources(', 'Input.action_', 'save_png(', 'get_pixel(', 'intersect_shape(', 'compile_geometry(', 'get_image(']:assert forbidden not in text,forbidden
assert text.count('call("go_field_smart",ID,null)')==1
assert 'C._resident_ready' in text and 'C.transition_validation_state()' in text
assert 'const WHOLE_MS=60000' in text
assert text.index('ready_fact=clock_fact()')<text.index('var state: Dictionary=C.transition_validation_state()')
function=text[text.index('func post_draw_readonly()'):text.index('func natural_receipt_only()')]
assert 'draw_fact=clock_fact()' in function and 'duplicate(' not in function and 'get_sha256' not in function
output=QA/'yamen_performance03_LIGHT_ROOT16_READY_handoff.json'
handoff={'status':'READY_FIXED_ROOT16_ONE_YAMEN_DEFAULT_PERFORMANCE_DIAGNOSTIC_NOT_EXECUTED','script':{'path':res(key),'sha256':sha(raw),'lines':len(text.splitlines()),'Root_external_full_hash_required':True},'fixture':{'path':res(fixture),'sha256':sha(fraw),'expected_city_sources':1217,'source_first_last_guard_count':1237,'source_guard_own_fixture_tracked_additionally':True},'scope':{'whole_including_QA_precheck_and_finish_ms':60000,'ordinary_default_public_null_requests':1,'INPUT_moves':0,'inspection_teleports':0,'pictures':0,'geometry_Physics_routes_NPC_furniture_or_room_tests':0,'collector_or_validation_calls':0,'saves_guarded':15},'receipt_read':'Selective existing C._resident_ready fields +existing sources only; resident_receipt() deliberately not called because it invokes matches/collector. Compare fixed independent1292 Yamen1217. No new proof construction.','timing':'First ready/draw scalars before copied receipts/hashes. Same live positive token+scene bounds C joined scalar snapshot; finalized last matching snapshot retained if observed. Field profile setup identity and LM same-id only; missing stays missing. Nested wall times not added; no extra polling worker/yield.','result_semantics':'complete means functional default entry, natural owner and15save/source guard within60s. first_under10s is a separate literal-threshold observed metric, not claimed from complete=true; a slow metric remains a performance FAIL and never prompts automatic replay. No allcity/SSD-cold/repeated-entry/art credit.','actual_authorities':spec['authority'],'prepared_without_parse_engine':True,'QA_fixture_preparation_failure_retained':'Original data preparer expected scene_path on a CITY source-owner row; KeyError before output. NEW retry1 uses immutable89216 Yamen native paths already exact source leaves in1292, not actual Field observations.','Root_command':'Ordinary GUI project --path F:/Code/RPG_GAME/game --script res://tests/test_luoyang_ap_yamen_performance03_LIGHT_ROOT16_READY_20261023.gd; no user args; preserve retained Process.WaitForExit actual code.'}
assert not output.exists();output.write_text(json.dumps(handoff,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'path':res(output),'sha256':sha(output.read_bytes()),'script_sha256':sha(raw),'script_lines':len(text.splitlines()),'fixture_sha256':sha(fraw)}))
