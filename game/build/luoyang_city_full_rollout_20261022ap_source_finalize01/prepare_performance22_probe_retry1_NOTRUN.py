"""NEW diagnostic-only successor: exclude bad/ambiguous keys, scan valid siblings."""
import difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance21_canonical_typed_probe01/';O=S+'performance22_canonical_probe_retry1/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
op=P+'test_typed_packet_full_rejections_PENDING_ROOT.gd';os='e7c394f207f397965a7e14e00f0f1bba9fa391b2845b3535e1b50cde0f561bf8'
of=P+'typed_packet_comparison_fixture_PENDING_ROOT.json';fs='77dc0f4b6f86bdc526a68b2b1810ff2993b1ec2dc56909c7436b742c23f3909b'
old=fixed(op,os);fixture=json.loads(fixed(of,fs))
fixture['diagnostic_rule']='Outside timers, dictionary key errors/collisions do not hide other unique canonical-key intersections. Exclude each unsupported key value and both sides of ambiguous canonical names; scan all remaining unambiguous child pairs even when parent already rejected. Numeric rejected-key labels use str(k), never String(k). Array shape rejection remains at its container.'
fp=O+'typed_packet_comparison_fixture_PENDING_ROOT.json';fb=js(fixture);key=old.decode()
key=key.replace('const FIXTURE="'+of+'"','const FIXTURE="'+fp+'"',1).replace('const FIXTURE_SHA="'+fs+'"','const FIXTURE_SHA="'+sha(fb)+'"',1)
assert key.count('path+[String(k)]')==4
key=key.replace('path+[String(k)]','path+[str(k)]')
old_shape='\tif left is Dictionary:\n\t\tif left.size()!=right.size(): return rejection(out,"DICTIONARY_SIZE",left,right,path,depth)\n\t\tvar ok: bool=true\n'
new_shape='\tif left is Dictionary:\n\t\tvar ok: bool=true\n\t\tif left.size()!=right.size():\n\t\t\trejection(out,"DICTIONARY_SIZE",left,right,path,depth);ok=false\n'
assert key.count(old_shape)==1;key=key.replace(old_shape,new_shape,1)
start=key.index('\t\tvar li: Dictionary={};var ri: Dictionary={}\n',key.index('func diagnose('))
end=key.index('\tif left is Array:\n',start)
key=key[:start]+'''\t\tvar li: Dictionary={};var ri: Dictionary={};var left_seen: Dictionary={};var right_seen: Dictionary={};var ambiguous: Dictionary={}
		for k: Variant in left:
			if typeof(k) not in [TYPE_STRING,TYPE_STRING_NAME]:
				rejection(out,"LEFT_UNSUPPORTED_KEY_TYPE",k,k,path+[str(k)],depth);ok=false;continue
			var c: String=String(k) # Only allowed types reach this canonical conversion.
			if left_seen.has(c):
				rejection(out,"LEFT_CANON_KEY_COLLISION",left,right,path+[c],depth);ambiguous[c]=true;li.erase(c);ok=false
			else: left_seen[c]=true;li[c]=left[k]
		for k: Variant in right:
			if typeof(k) not in [TYPE_STRING,TYPE_STRING_NAME]:
				rejection(out,"RIGHT_UNSUPPORTED_KEY_TYPE",k,k,path+[str(k)],depth);ok=false;continue
			var c: String=String(k)
			if right_seen.has(c):
				rejection(out,"RIGHT_CANON_KEY_COLLISION",left,right,path+[c],depth);ambiguous[c]=true;ri.erase(c);ok=false
			else: right_seen[c]=true;ri[c]=right[k]
		return scan_unique_canonical_children(old,li,ri,ambiguous,out,path,depth,ok)
'''+key[end:]
anchor='func compare_case(old: Variant,candidate: Variant,label: String,left: Variant,right: Variant) -> void:\n'
helper='''func scan_unique_canonical_children(old: Variant,li: Dictionary,ri: Dictionary,ambiguous: Dictionary,out: Dictionary,path: Array,depth: int,parent_ok: bool) -> bool:
	var ok: bool=parent_ok
	for c: String in ambiguous:
		li.erase(c);ri.erase(c);ok=false # Exclude BOTH sides, never choose a colliding value.
	if li.size()!=ri.size():
		rejection(out,"CANON_KEYSET_SIZE",li,ri,path,depth);ok=false
	for c: String in li:
		if not ri.has(c): rejection(out,"MISSING_RIGHT_CANON_KEY",li,ri,path+[c],depth);ok=false
		else:
			var child_ok: bool=diagnose(old,li[c],ri[c],true,out,path+[c],depth+1)
			ok=child_ok and ok # Child scan already executed regardless of prior failure.
	for c: String in ri:
		if not li.has(c): rejection(out,"MISSING_LEFT_CANON_KEY",li,ri,path+[c],depth);ok=false
	return ok
func has_rejection(out: Dictionary,reason: String,first_path: Array) -> bool:
	for row: Dictionary in out.values():
		if row.reason==reason and row.first_path==first_path: return true
	return false
'''
assert key.count(anchor)==1;key=key.replace(anchor,helper+anchor,1)
tiny_anchor='\tcompare_case(old,candidate,"tiny integer versus float",{"a":4},{"a":4.0})\n'
tiny='''\tvar mixed: Dictionary={"good":Vector2(1,2),42:0}
	var mixed_numeric: Dictionary={};var mixed_canonical: Dictionary={}
	check(not diagnose(old,mixed,mixed.duplicate(true),false,mixed_numeric),"Mixed badkey numeric diagnostic rejects")
	check(not diagnose(old,mixed,mixed.duplicate(true),true,mixed_canonical),"Mixed badkey canonical diagnostic rejects")
	check(has_rejection(mixed_numeric,"RIGHT_NONSTRING_KEY",["42"]) and has_rejection(mixed_numeric,"UNSUPPORTED_VARIANT",["good"]),"Numeric scanner retains both badkey and valid sibling Vector rejection")
	check(has_rejection(mixed_canonical,"RIGHT_UNSUPPORTED_KEY_TYPE",["42"]) and has_rejection(mixed_canonical,"UNSUPPORTED_VARIANT",["good"]),"Canonical scanner retains both badkey and valid sibling Vector rejection")
	rows.append({"label":"mixed badkey and valid Vector subtree coverage","numeric_rejections":mixed_numeric,"canonical_rejections":mixed_canonical,"diagnostic_only_not_candidate_timing":true})
	compare_case(old,candidate,"tiny mixed badkey and valid Vector sibling",mixed,mixed.duplicate(true))
	var excluded: Dictionary={}
	var exclusion_ok: bool=scan_unique_canonical_children(old,{"dup":Vector2(3,4),"good":Vector2(1,2)},{"dup":Vector2(9,9),"good":Vector2(1,2)},{"dup":true},excluded,[],0,false)
	check(not exclusion_ok and has_rejection(excluded,"UNSUPPORTED_VARIANT",["good"]) and not has_rejection(excluded,"UNSUPPORTED_VARIANT",["dup"]),"Ambiguous canonical-name exclusion skips both dup values and still scans unique good sibling")
	rows.append({"label":"synthetic canonical-index collision exclusion helper coverage","rejections":excluded,"synthetic_index_unit_only_not_actual_Dictionary_collision_credit":true})
'''
assert key.count(tiny_anchor)==1;key=key.replace(tiny_anchor,tiny+tiny_anchor,1)
key=key.replace('performance20_canonical_keys_candidate01/output/%d_%d','performance22_canonical_probe_retry1/output/%d_%d')
new=key.encode();kp=O+'test_typed_packet_full_rejections_PENDING_ROOT.gd'
aa,bb=old.decode().splitlines(True),key.splitlines(True);hunks=[]
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':hunks.append({'old_byte_start':len(''.join(aa[:i]).encode()),'old_byte_end':len(''.join(aa[:j]).encode()),'new_byte_start':len(''.join(bb[:k]).encode()),'new_byte_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
forward=old;inverse=new
for h in reversed(hunks):forward=forward[:h['old_byte_start']]+h['new'].encode()+forward[h['old_byte_end']:]
for h in reversed(hunks):inverse=inverse[:h['new_byte_start']]+h['old'].encode()+inverse[h['new_byte_end']:]
assert forward==new and inverse==old
assert 'path+[String(k)]' not in key
diff=''.join(difflib.unified_diff(aa,bb,fromfile=op,tofile=kp)).encode()
hand={'status':'NEW_PROBE_ONLY_REJECTION_SIBLING_SCAN_FIX_PENDING_ROOT_NOT_RUN','ready':False,
 'candidate_unchanged':{'path':S+'performance20_canonical_keys_candidate01/Bundle_canonical_keys_wire_CANDIDATE.gd','sha256':'9d5b9b379f5e7962d91550a95b2b9a12a35b98d7fb4402cdfa5947e7152f9e54'},
 'candidate_inverse_math':{'path':S+'performance20_canonical_keys_candidate01/whole_byte_inverse_and_design_READY.json','sha256':'4d78458a647d31afdf0953474f14137af4bf7fd8018b74a10a582b86dc1d5134'},
 'pending_key':{'path':kp,'sha256':sha(new)},'pending_fixture':{'path':fp,'sha256':sha(fb)},
 'parent_probe':{'path':op,'sha256':os},'whole_probe_byte_inverse':True,'hunks':hunks,'complete_diff':{'path':O+'complete_vs_E7C3.diff','sha256':sha(diff)},
 'changes':['Only diagnostics: exclude bad key values and both indexes for each ambiguous canonical name; continue every remaining unique key intersection even after key/count failures. Track left/right seen names separately so a third duplicate cannot reenter the index.',
 'All unknown raw-key diagnostic labels use str(k); String(k) survives only after explicit String/StringName type guards.',
 'Add tiny mixed integer badkey plus valid Vector subtree assertions for both numeric/canonical scanners, and a clearly synthetic canonical-index exclusion unit showing ambiguous dup values unpaired while good sibling still diagnosed. Do not claim unconstructible ordinary-Dictionary collision runtime coverage.',
 'Candidate9D5B, timed comparison bodies, fixed04F2/B606 records, single decode limit and no Field/collector/native/geometry source scope remain unchanged. New output epoch only.'],
 'engine_parse_typed_decode_collector_Stage_formal_writes':0}
files={'typed_packet_comparison_fixture_PENDING_ROOT.json':fb,'test_typed_packet_full_rejections_PENDING_ROOT.gd':new,'complete_vs_E7C3.diff':diff,'handoff_PENDING_ROOT_NOT_RUN.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
