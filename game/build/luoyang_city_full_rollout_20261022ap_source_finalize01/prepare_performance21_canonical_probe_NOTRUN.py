"""NEW text-only probe finalization; precise decode/failure reporting, no engine."""
import difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance20_canonical_keys_candidate01/';O=S+'performance21_canonical_typed_probe01/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
op=P+'test_typed_packet_full_rejections_PENDING_ROOT.gd';os='496e12b388c179a3026c65352cc80e06e07917067ab535c6a17083079a877945'
of=P+'typed_packet_comparison_fixture_PENDING_ROOT.json';fs='77dc0f4b6f86bdc526a68b2b1810ff2993b1ec2dc56909c7436b742c23f3909b'
old=fixed(op,os);fb=fixed(of,fs);new=old;hunks=[]
fp=O+'typed_packet_comparison_fixture_PENDING_ROOT.json';kp=O+'test_typed_packet_full_rejections_PENDING_ROOT.gd'
def change(a,b):
    global new
    aa,bb=a.encode(),b.encode();assert new.count(aa)==1,(a,new.count(aa));hunks.append({'old':a,'new':b});new=new.replace(aa,bb,1)
change('const FIXTURE="'+of+'"','const FIXTURE="'+fp+'"')
change('var rows: Array=[]\n','var rows: Array=[]\nvar packet_decodes: int=0\n')
change('"binary_packet_decodes":1 if not rows.is_empty() else 0','"binary_packet_decodes":packet_decodes')
change('\tvar packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(fixture.T_packet_path))','\tpacket_decodes+=1\n\tvar packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(fixture.T_packet_path))')
change('"rejection_counts_are_domain_occurrences_not_executed_branch_counts":true','"rejection_counts_are_domain_occurrences_not_executed_branch_counts":true,"key_guard_type_pairs_describe_rejected_key_variant_not_child_values":true')
back=new
for h in reversed(hunks):
    a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
assert back==old
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=op,tofile=kp)).encode()
hand={'status':'BUILD_ONLY_CANON_KEYS_NUMERIC_LEAF_CANDIDATE_AND_UNIQUE_COMPLETE_DOMAIN_PROBE_PENDING_ROOT','ready':False,
 'candidate':{'path':P+'Bundle_canonical_keys_wire_CANDIDATE.gd','sha256':'9d5b9b379f5e7962d91550a95b2b9a12a35b98d7fb4402cdfa5947e7152f9e54'},
 'candidate_inverse_and_math':{'path':P+'whole_byte_inverse_and_design_READY.json','sha256':'4d78458a647d31afdf0953474f14137af4bf7fd8018b74a10a582b86dc1d5134'},
 'candidate_diff':{'path':P+'complete_vs_3F002.diff','sha256':'fb5c9b7546b899bf0d80c082a389bbcfaa9f94298fa5d3e06fe030a0ddfc92fb'},
 'pending_key':{'path':kp,'sha256':sha(new)},'pending_fixture':{'path':fp,'sha256':sha(fb)},
 'probe_parent':{'path':op,'sha256':os},'whole_probe_byte_inverse':True,'hunks':hunks,'probe_diff':{'path':O+'probe_complete_vs_496E.diff','sha256':sha(diff)},
 'one_future_T04F2_packet_decode_and_fixed_B606_JSON_only':True,
 'complete_numeric_and_canonical_rejection_scan':'All unambiguously paired dictionary/array children are visited even after an earlier failure, aggregating each reason+type pair into count and first path/depth; unknown-key or canonical collisions reject without guessing ambiguous children. Structural mismatches are reported at their rejecting container. Key-domain type-pairs refer to the rejected key variant (side is encoded in reason), not the unvisited child value types.',
 'timed_comparisons_exclude_both_diagnostics_and_extra_helper_bool_reads':True,
 'two_actual_pairs_old_wire_must_accept_and_old_7123_new_results_exactly_same':True,
 'fast_hit_bool_separate_from_semantic_pass':True,'no_performance_or_formal_credit':True,
 'external_Root_wall_bound_and_NEW_ready_freeze_required':True,'engine_parse_native_decode_collector_Stage_formal_writes':0}
files={'typed_packet_comparison_fixture_PENDING_ROOT.json':fb,'test_typed_packet_full_rejections_PENDING_ROOT.gd':new,'probe_complete_vs_496E.diff':diff,'handoff_PENDING_ROOT_NOT_RUN.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
