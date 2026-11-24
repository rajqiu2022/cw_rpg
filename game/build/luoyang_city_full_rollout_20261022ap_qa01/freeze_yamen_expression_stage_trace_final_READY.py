"""Only NEW final header freeze after Root review; candidate remains false."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def key(p):return 'res://'+p.relative_to(ROOT).as_posix()
op=QA/'yamen_expression_stage_trace_fixture_CANDIDATE_NOTREADY.json'
os=ROOT/'tests/test_luoyang_ap_yamen_EXPRESSION_STAGE_TRACE_CANDIDATE_NOTREADY_20261023.gd'
assert sha(op)=='065940d353e3d525503610d54b3b102c6e7b9452055dd0323055cd8fecec05af'
assert sha(os)=='15f8955e20ebd9629641635398d64bba0caa4e3b973db96f3f3cdf0b45622bf2'
doc=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen113324_loading_source_diagnosis01_NOT_IMPLEMENTATION.json'
assert sha(doc)=='073e02f3915270366b56ae56f19091a54c20fb81a28e56e63d7881979bebd46d'
fp=QA/'yamen_expression_stage_trace_final_fixture_READY.json'
sp=ROOT/'tests/test_luoyang_ap_yamen_EXPRESSION_STAGE_TRACE_READY_20261023.gd'
hp=QA/'yamen_expression_stage_trace_final_handoff_READY.json'
assert not any(p.exists() for p in [fp,sp,hp])
fixture=json.loads(op.read_bytes());assert fixture['ready'] is False;fixture['ready']=True
fixture['source_sha256'][key(doc)]=sha(doc)
assert fixture['independent_owner_sha256']=='690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902'
prod=fixture['expected_city_source_sha256'];assert len(prod)==1211
assert prod['res://scripts/city/luoyang_full_city_index_20261022ap.gd']=='db9d5e277d7e86e58e799804822d83959833c3700d24444f5fe48d359d9bd088'
assert prod['res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/runtime_yamen_manifest_READY.json']=='ed4cee9e730f96af624354dd08ad6d8875259ba38827fc96df0c493da44c1794'
fp.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
body=os.read_text(encoding='utf-8')
changes=[('const FINAL_OWNER_READY: bool = false','const FINAL_OWNER_READY: bool = true'),(key(op),key(fp)),(sha(op),sha(fp)),('yamen_three_low_props_expression_stage_trace_candidate/%d_%d','yamen_three_low_props_expression_stage_trace_final/%d_%d')]
for a,b in changes:assert body.count(a)==1;body=body.replace(a,b)
back=body
for a,b in reversed(changes):assert back.count(b)==1;back=back.replace(b,a)
assert back.encode()==os.read_bytes()
sp.write_text(body,encoding='utf-8',newline='\n')
h={'status':'ROOT_REVIEWED_NEW_FINITE_REMAINING_YAMEN_READY_NOT_EXECUTED','script':{'path':key(sp),'sha256':sha(sp),'lines':len(body.splitlines())},'fixture':{'path':key(fp),'sha256':sha(fp)},'parent_metrics_unchanged_sha256':'586911fb01e365c661f9ec195963160febcf6a07bb243186047e6c53caa80b55','candidate15F8_kept_false':True,'only_four_header_changes_whole_byte_inverse_to15F8':True,'exact_header_changes':[{'old':a,'new':b} for a,b in changes],'same1211_owner_ED4C_DB9D':True,'same_original_poly_seven_INPUT_routes_six_NPC_60sec_two_pictures':True,'Root_external_script_fixture_SHA_check_required':True,'old113324_FAIL_firstdraw16_517877_and_missing_OS_exit_retained':True,'pure_ABI_result_sha256':'30ead6851fdbf09c24bbcc8111e5a6d84cf5a6b3fa2d618a65ce48889b1b033c','loading_diagnostic_source_sha256':sha(doc),'engine_or_parse_runs':0,'canonical_writes':0}
hp.write_text(json.dumps(h,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'script':h['script'],'fixture':h['fixture'],'handoff_sha256':sha(hp)}))
