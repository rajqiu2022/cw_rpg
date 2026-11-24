"""Never executed diagnostic draft: missing retained sources is not a source diff."""
from pathlib import Path
import difflib,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
P=QA/'market_pawn_single_visual_ROOT38_READY/test_market_pawn_single_visual_ROOT38_READY.gd'
D=QA/'market_existing_source_failure_snapshot_DRAFT_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(P)=='08e9da3acd99281f2196ffd6060a1c5eb0383953a2b274f106d837b174554274'
old=P.read_text(encoding='utf-8')
needle='\t\t\trecords.append({"kind":"MARKET_PUBLIC_FAILURE","public":public_state,"C_errors":C.errors()})\n'
assert old.count(needle)==1
helper='''func _existing_failure_sources_only(public_state: Dictionary) -> void:
	# Inspect only a main-thread proof already published by production.
	# This known configure-failure gate publishes no proof: do not invent a diff.
	var proof: Dictionary=C._transition_validation
	var same_attempt: bool=int(proof.get("token",0))==int(public_state.get("token",-1)) and String(proof.get("id",&""))==String(CITY)
	var candidate: Variant=proof.get("sources",null)
	var available: bool=same_attempt and candidate is Dictionary and not candidate.is_empty()
	if not available:
		records.append({"kind":"MARKET_EXISTING_SOURCE_SNAPSHOT_UNAVAILABLE","same_attempt":same_attempt,"proof_token":proof.get("token",0),"proof_id":String(proof.get("id",&"")),"proof_has_sources_field":proof.has("sources"),"full_actual_dictionary_available":false,"difference_not_computed":true,"empty_not_treated_as_actual_missing1700":true,"no_collector_validator_or_running_worker_read":true})
		return
	var actual: Dictionary=candidate.duplicate()
	for path: Variant in actual:
		if not path is String or not actual[path] is String:
			records.append({"kind":"MARKET_EXISTING_SOURCE_SNAPSHOT_INVALID_TYPES","difference_not_computed":true})
			return
	var extra: Array[String]=[]
	var missing: Array[String]=[]
	var mismatched: Array[Dictionary]=[]
	for path: String in actual:
		if not fixture.expected_sources.has(path): extra.append(path)
		elif actual[path]!=fixture.expected_sources[path]: mismatched.append({"path":path,"fixed_expected":fixture.expected_sources[path],"observed_actual":actual[path]})
	for path: String in fixture.expected_sources:
		if not actual.has(path): missing.append(path)
	extra.sort();missing.sort()
	records.append({"kind":"MARKET_EXISTING_SAME_TOKEN_SOURCE_DIFFERENCE_ONLY","token":proof.token,"scene_id":String(proof.id),"actual_count":actual.size(),"fixed_expected_count":fixture.expected_sources.size(),"actual_sources":actual,"extra":extra,"missing":missing,"value_mismatches":mismatched,"observed_never_used_to_change_fixture":true,"comparison_not_a_new_validation_or_pass":true})

'''
new=old.replace('const FIXTURE_READY=true','const FIXTURE_READY=false',1)
new=new.replace(needle,needle+'\t\t\t_existing_failure_sources_only(public_state)\n',1)
assert new.count('func _loading_hidden()')==1
new=new.replace('func _loading_hidden()',helper+'func _loading_hidden()',1)
back=new.replace('const FIXTURE_READY=false','const FIXTURE_READY=true',1).replace(needle+'\t\t\t_existing_failure_sources_only(public_state)\n',needle,1).replace(helper,'',1)
assert back==old
def emit(name,b):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
    return{'path':'res://'+p.relative_to(GAME).as_posix(),'sha256':sha(p)}
key=emit('test_market_existing_failure_sources_DRAFT_NOTREADY.gd',new.encode())
diff=emit('complete_key_vs_ROOT38.diff',''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='ROOT38',tofile='DRAFT_NOTREADY')).encode())
handoff={'status':'DRAFT_READY_FALSE_NO_RETAINED_SOURCE_AT_KNOWN_GATE_DO_NOT_RUN','key':key,'diff':diff,'whole_byte_inverse_original_ROOT38':True,'original_fixture_source_expectation_untouched':True,'no_new_fixture':True,'mainthread_proof_fields_only':'C._transition_validation.token/id/sources, shallow copyString→String table only with exactsamepublictoken/id. No _resident_ready borrowing/runningjob reads.','known_gate_blocker':'C450 clears proof; C685 joins then discards _live_source_job and returns hashes only as local sources. B348-349 configure describe rejection never stores sources; C525 releasesjob/returns before C551-554 proof publication. Existing actual source dictionary therefore unavailable at this failure branch. Missing proof is NOT observed empty source set.','proposal':'Do not execute this known-uninformative draft. Prefer System fixedJSON dependency simulation. Any actual full-source retention hook or collector would require new explicit scope, not smuggled into this key.','success_path':'Original1700natural FINAL/input/camera assertions unchanged; never accepts a failure or modifies expected fixture.','source_lines':{'C':'450,457-462,523-525,551-554,672-689','B':'328-349'},'operations':{'engine':0,'parse':0,'collector':0,'validator':0,'Stage':0,'canonical_write':0}}
desc=emit('handoff_DRAFT_NOTREADY_DO_NOT_RUN.json',(json.dumps(handoff,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'key':key,'handoff':desc,'known_gate_no_retained_sources':True}))
