"""Mechanical NEW Root24 one-probe readiness freeze; no engine or native decode."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance22_canonical_probe_retry1/';O=S+'performance23_canonical_ROOT24_READY/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
op=P+'test_typed_packet_full_rejections_PENDING_ROOT.gd';os='a590a0227fae061d3b1f515510f18fab0bd9fd075e0ae0e687c54766e85d3d8c'
of=P+'typed_packet_comparison_fixture_PENDING_ROOT.json';fs='c586fc073e1dff8856593e4a166dcbd16777f75f4b71993a64ac169c03ab2d7e'
old=fixed(op,os);oldfb=fixed(of,fs);original=json.loads(oldfb);fixture=copy.deepcopy(original)
fixture['ready']=True
fixture['status']='ROOT24_READY_ONE_FIXED_TYPED_PROBE_ONLY_NOT_SOURCE_OR_FORMAL_PROMOTION_AUTHORITY'
fixture['blocker']='Remaining execution only: Root may execute this one externally bounded fixed typed probe after QA static admission. Unknown, incomplete-fast-hit or slower outcomes grant no source or formal promotion; no repeat of prior Field or JSON-only tests.'
inverse=copy.deepcopy(fixture)
for name in ['ready','status','blocker']:inverse[name]=copy.deepcopy(original[name])
assert js(inverse)==oldfb and len(fixture['source_sha256'])==4
fb=js(fixture);fp=O+'typed_packet_comparison_fixture_ROOT24_READY.json';kp=O+'test_typed_packet_full_rejections_ROOT24_READY.gd'
hunks=[{'old':'const FIXTURE="'+of+'"','new':'const FIXTURE="'+fp+'"'},
 {'old':'const FIXTURE_SHA="'+fs+'"','new':'const FIXTURE_SHA="'+sha(fb)+'"'},
 {'old':'performance22_canonical_probe_retry1/output/%d_%d','new':'performance23_canonical_ROOT24_READY/output/%d_%d'}]
new=old
for h in hunks:
    a,b=h['old'].encode(),h['new'].encode();assert new.count(a)==1;new=new.replace(a,b,1)
back=new
for h in reversed(hunks):
    a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
assert back==old
kd=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=op,tofile=kp)).encode()
fd=''.join(difflib.unified_diff(oldfb.decode().splitlines(True),fb.decode().splitlines(True),fromfile=of,tofile=fp)).encode()
hand={'status':'ROOT24_ONE_TYPED_PROBE_READY_NOT_EXECUTED_NOT_PROMOTION_AUTHORITY','ready':True,
 'key':{'path':kp,'sha256':sha(new)},'fixture':{'path':fp,'sha256':sha(fb)},
 'parent_key':{'path':op,'sha256':os},'parent_fixture':{'path':of,'sha256':fs},
 'whole_key_byte_inverse_to_a590':True,'whole_fixture_serialized_byte_inverse':True,'key_hunks':hunks,
 'key_diff':{'path':O+'key_vs_a590.diff','sha256':sha(kd)},'fixture_diff':{'path':O+'fixture_vs_c586.diff','sha256':sha(fd)},
 'unchanged_four_source_pins_two_actual_pairs_single_packet_decode_and_full_diagnostic_rule':True,
 'candidate9D5B_unchanged':True,'only_fixed_Root24_one_probe_execution_readiness':True,
 'source_or_formal_promotion_authorized':False,'future_Root_external_wall_bound_required':True,
 'engine_parse_typed_decode_collector_Stage_formal_writes':0,
 'Root_only_command_not_executed':'godot --headless --path F:/Code/RPG_GAME/game --script '+kp}
files={'typed_packet_comparison_fixture_ROOT24_READY.json':fb,'test_typed_packet_full_rejections_ROOT24_READY.gd':new,'key_vs_a590.diff':kd,'fixture_vs_c586.diff':fd,'handoff_ROOT24_READY_NOT_RUN.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
assert fixed(op,os)==old and fixed(of,fs)==oldfb
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
