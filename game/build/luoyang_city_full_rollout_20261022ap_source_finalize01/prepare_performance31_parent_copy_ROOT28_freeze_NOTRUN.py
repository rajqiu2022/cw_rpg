"""NEW mechanical Root28 one-pure-copy-key freeze, no packet decode/engine."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance30_domain_parent_copy_candidate01/';O=S+'performance31_domain_parent_copy_ROOT28_READY/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
kp=P+'test_domain_parent_copy_PENDING_ROOT.gd';ks='ba32347503d26ca67638af5c73f9c19b01f600c8b4e7f8128d609d487ff8d966'
fp=P+'parent_copy_comparison_fixture_PENDING_ROOT.json';fs='767c8d920a31adf02120f8154b4eec98984f1e13051a5f492319116c0a3eac46'
key=fixed(kp,ks);fixture=json.loads(fixed(fp,fs));pending=copy.deepcopy(fixture)
assert fixture['ready']is False and len(fixture['source_sha256'])==5
fixture.update(status='ROOT28_SINGLE_FIXED_TYPED_RECORD_PURE_COPY_TEST_READY_NOT_EXECUTED_NOT_PROMOTION',ready=True,blockers=[])
inverse=copy.deepcopy(fixture)
for field in ['status','ready','blockers']:inverse[field]=copy.deepcopy(pending[field])
assert js(inverse)==fixed(fp,fs)
newfp=O+'parent_copy_comparison_fixture_ROOT28_READY.json';newfb=js(fixture)
hunks=[
 {'old':'const FIXTURE="'+fp+'"','new':'const FIXTURE="'+newfp+'"'},
 {'old':'const FIXTURE_SHA="'+fs+'"','new':'const FIXTURE_SHA="'+sha(newfb)+'"'},
 {'old':'"'+P+'output/%d_%d"','new':'"'+O+'output/%d_%d"'}]
newkey=key
for h in hunks:
    a,b=h['old'].encode(),h['new'].encode();assert newkey.count(a)==1;newkey=newkey.replace(a,b,1)
back=newkey
for h in reversed(hunks):
    a,b=h['new'].encode(),h['old'].encode();assert back.count(a)==1;back=back.replace(a,b,1)
assert back==key
assert newkey.count(b'bytes_to_var(')==1 and newkey.count(b'candidate._copy_parent_pair(')==3
assert b'load(fixture.old_adapter_path)'in newkey and b'load(fixture.candidate_adapter_path)'in newkey
assert b'candidate_bundle'in newkey or 'candidate_bundle'not in fixture # B is a SHA leaf, not a loaded fixture interface.
assert b'_map_parent('not in newkey and b'restore_parent_record('not in newkey
newkp=O+'test_domain_parent_copy_ROOT28_READY.gd'
def diff(a,b,ap,bp):return ''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile=ap,tofile=bp)).encode()
files={'test_domain_parent_copy_ROOT28_READY.gd':newkey,'parent_copy_comparison_fixture_ROOT28_READY.json':newfb,
 'key_complete_vsBA3234.diff':diff(key,newkey,kp,newkp),'fixture_complete_vs767C.diff':diff(fixed(fp,fs),newfb,fp,newfp)}
hand={'status':'ROOT28_ONE_FIXED_TYPED_RECORD_COPY_READY_FREEZE_NOT_RUN_NOT_FORMAL_SOURCE_OR_PROMOTION',
 'ready':True,'key':{'path':newkp,'sha256':sha(newkey)},'fixture':{'path':newfp,'sha256':sha(newfb)},
 'parent_key':{'path':kp,'sha256':ks},'parent_fixture':{'path':fp,'sha256':fs},
 'mechanical_key_hunks':hunks,'whole_parent_key_byte_inverse':True,'whole_parent_fixture_three_field_serialized_byte_inverse':True,
 'same_five_source_pins':fixture['source_sha256']==pending['source_sha256'],
 'B00AA_evidence_limit':'B00AA candidate and formal B are SHA-declared guard leaves only. Neither is loaded or called by this key. Deferred-child branch reasoning is static proof, NOT restore_parent_record runtime evidence.',
 'adapter_evidence_limit':'Only pure _copy_parent_pair and read-only _same are called, never _map_parent or forged session/state. Both scripts load without instances.',
 'fixed_packet_rule':'Future single04F2 bytes_to_var decode remains exactly once; this freeze has zero packet decoding.',
 'timing_and_controls':'Unchanged old four independent copies versus new two independent copies; whole comparisons, SHA, read/decode and nested mutation controls remain outside timers. One Yamen large record, Market tiny only. No Field, stable speed or whole Market-domain claim.',
 'fresh_guard_rule':'Root28 fresh guard and external bounded launcher are Root-owned preexecution gates; not invented or replaced by this mechanical readiness flag.',
 'diffs':{n:{'path':O+n,'sha256':sha(b)}for n,b in files.items()if n.endswith('.diff')},
 'engine_parse_packet_decode_collector_sourceStage_formal_writes':0,
 'Root_only_command_NOT_EXECUTED':'godot --headless --path F:/Code/RPG_GAME/game --script '+newkp}
files['handoff_ROOT28_READY_NOT_RUN.json']=js(hand)
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
assert fixed(kp,ks)==key and fixed(fp,fs)==js(pending)
print(json.dumps({n:sha(b)for n,b in files.items()},indent=2))
