"""NEW canonical String/StringName-key candidate and full-domain probe DRAFT."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance18_numeric_leaf_candidate01/';K=S+'performance19_typed_pair_key01/';O=S+'performance20_canonical_keys_candidate01/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
oldpath=P+'Bundle_numeric_leaf_wire_CANDIDATE.gd';oldsha='3f002b679ad2855b91a14d23eb0451e64848666a18b3e0c559bd18d04c9578a1'
old=fixed(oldpath,oldsha);new=old;hunks=[]
def replace(a,b):
    global new
    aa,bb=a.encode(),b.encode();assert new.count(aa)==1;hunks.append({'old':a,'new':b});new=new.replace(aa,bb,1)
anchor='static func _symmetric_record_wire_equal(left: Variant,right: Variant) -> bool:\n'
helper='''static func _canonical_keys_record_wire_success(left: Variant,right: Variant,depth: int=0) -> bool:
	if depth>=64: return false
	var left_type: int=typeof(left);var right_type: int=typeof(right)
	if left_type in [TYPE_INT,TYPE_FLOAT] and right_type in [TYPE_INT,TYPE_FLOAT]:
		if (left_type==TYPE_FLOAT and not is_finite(left)) or (right_type==TYPE_FLOAT and not is_finite(right)): return false
		if left_type==right_type and left==right: return true
		return equal(_wire(left),_wire(right))
	if left_type in [TYPE_STRING,TYPE_STRING_NAME] and right_type in [TYPE_STRING,TYPE_STRING_NAME]:
		if left_type==right_type and left==right: return true
		# Restricted StringName scalar contract is checked by the old leaf codec.
		return equal(_wire(left),_wire(right))
	if left_type!=right_type: return false
	if left is Dictionary:
		if left.size()!=right.size(): return false
		var all_string: bool=true
		for key: Variant in left:
			if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME]: return false
			if typeof(key)!=TYPE_STRING: all_string=false
		for key: Variant in right:
			if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME]: return false
			if typeof(key)!=TYPE_STRING: all_string=false
		if all_string:
			# Keep the original all-String path free of canonical-index allocation.
			for key: String in left:
				if not right.has(key) or not _canonical_keys_record_wire_success(left[key],right[key],depth+1): return false
			return true
		var left_index: Dictionary={};var right_index: Dictionary={}
		for key: Variant in left:
			var canonical: String=String(key)
			if left_index.has(canonical): return false
			left_index[canonical]=left[key]
		for key: Variant in right:
			var canonical: String=String(key)
			if right_index.has(canonical): return false
			right_index[canonical]=right[key]
		if left_index.size()!=right_index.size(): return false
		for key: String in left_index:
			if not right_index.has(key) or not _canonical_keys_record_wire_success(left_index[key],right_index[key],depth+1): return false
		return true
	if left is Array:
		if left.size()!=right.size(): return false
		for index: int in left.size():
			if not _canonical_keys_record_wire_success(left[index],right[index],depth+1): return false
		return true
	match left_type:
		TYPE_NIL,TYPE_BOOL: return left==right
	return false
'''
replace(anchor,helper+anchor)
replace('if _numeric_leaf_record_wire_success(left,right): return true\n\treturn equal(_wire(left),_wire(right))','if _canonical_keys_record_wire_success(left,right): return true\n\treturn equal(_wire(left),_wire(right))')
back=new
for h in reversed(hunks):
    a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
assert back==old
numericproof=json.loads(fixed(P+'whole_byte_inverse_and_design_READY.json','18a5354be846ebd5cbad787b81e8352c7c7d92332e792328f19974f798dee47d'))
strict_back=back
for h in reversed(numericproof['hunks']):
    a,b=h['old'].encode(),h['new'].encode();assert strict_back.count(b)==1;strict_back=strict_back.replace(b,a,1)
assert sha(strict_back)=='71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57'
candidate=O+'Bundle_canonical_keys_wire_CANDIDATE.gd'
fixture=json.loads(fixed(K+'typed_packet_comparison_fixture_PENDING_ROOT.json','e84ce87487ce2c298e70b8ed8757aa430ed6bc87d66b5d0efc8909fdad95ee13'))
del fixture['source_sha256'][oldpath];fixture['source_sha256'][candidate]=sha(new);fixture['candidate_path']=candidate
fixture.update(status='PENDING_ROOT_ONE_TYPED_PACKET_CANON_KEYS_AND_FULL_REJECTION_DIAGNOSIS',ready=False,
 blocker='Root and QA must approve a NEW ready freeze and one externally bounded run. Unknown/non-hit/slower results forbid source promotion; no Field05 or old JSON-only replay.',
 diagnostic_rule='Outside timed predicates, scan every unambiguously paired container child even after earlier rejection. Aggregate each helper rejection reason+left/right type with total count and first path/depth; do not cap total counters or relabel them as executed branch counters.',
 scalar_contract='Only finite numbers and String/StringName scalar leaf old-wire checks; no Vector/Packed/Object expansion. String/StringName keys canonicalize with String(key), collision per side refuses fast success.')
fp=O+'typed_packet_comparison_fixture_PENDING_ROOT.json';fb=js(fixture)
oldkeypath=K+'test_typed_packet_comparison_PENDING_ROOT.gd';oldkeysha='c7161b354d5f95b7c6103ecb20d68cbcf79586d13f64b33e22b220d2c684e1dc'
oldkey=fixed(oldkeypath,oldkeysha);key=oldkey.decode()
key=key.replace('const FIXTURE="'+K+'typed_packet_comparison_fixture_PENDING_ROOT.json"','const FIXTURE="'+fp+'"',1)
key=key.replace('const FIXTURE_SHA="e84ce87487ce2c298e70b8ed8757aa430ed6bc87d66b5d0efc8909fdad95ee13"','const FIXTURE_SHA="'+sha(fb)+'"',1)
start=key.index('func compare_case(');end=key.index('func nested(',start)
diagnostic='''func rejection(out: Dictionary,reason: String,left: Variant,right: Variant,path: Array,depth: int) -> bool:
	var id: String=reason+":"+str(typeof(left))+":"+str(typeof(right))
	if not out.has(id): out[id]={"reason":reason,"left_type":typeof(left),"right_type":typeof(right),"count":0,"first_path":path.duplicate(),"first_depth":depth}
	out[id].count+=1
	return false
func diagnose(old: Variant,left: Variant,right: Variant,canonical_mode: bool,out: Dictionary,path: Array=[],depth: int=0) -> bool:
	if depth>=64: return rejection(out,"DEPTH_LIMIT",left,right,path,depth)
	var lt: int=typeof(left);var rt: int=typeof(right)
	if lt in [TYPE_INT,TYPE_FLOAT] and rt in [TYPE_INT,TYPE_FLOAT]:
		if (lt==TYPE_FLOAT and not is_finite(left)) or (rt==TYPE_FLOAT and not is_finite(right)): return rejection(out,"NONFINITE_NUMBER",left,right,path,depth)
		if lt==rt and left==right: return true
		return true if old.equal(old._wire(left),old._wire(right)) else rejection(out,"FINITE_NUMBER_OLD_LEAF_WIRE_UNEQUAL",left,right,path,depth)
	if canonical_mode and lt in [TYPE_STRING,TYPE_STRING_NAME] and rt in [TYPE_STRING,TYPE_STRING_NAME]:
		if lt==rt and left==right: return true
		return true if old.equal(old._wire(left),old._wire(right)) else rejection(out,"STRING_NAME_OLD_LEAF_WIRE_UNEQUAL",left,right,path,depth)
	if lt!=rt: return rejection(out,"TYPE_MISMATCH",left,right,path,depth)
	if left is Dictionary:
		if left.size()!=right.size(): return rejection(out,"DICTIONARY_SIZE",left,right,path,depth)
		var ok: bool=true
		if not canonical_mode:
			for k: Variant in right:
				if typeof(k)!=TYPE_STRING:
					rejection(out,"RIGHT_NONSTRING_KEY",k,k,path+[String(k)],depth);ok=false
			for k: Variant in left:
				if typeof(k)!=TYPE_STRING:
					rejection(out,"LEFT_NONSTRING_KEY",k,k,path+[String(k)],depth);ok=false
				if not right.has(k):
					rejection(out,"MISSING_RAW_KEY",left,right,path+[String(k)],depth);ok=false
				else:
					var child_ok: bool=diagnose(old,left[k],right[k],false,out,path+[String(k)],depth+1)
					ok=child_ok and ok
			return ok
		var li: Dictionary={};var ri: Dictionary={}
		for k: Variant in left:
			if typeof(k) not in [TYPE_STRING,TYPE_STRING_NAME]:
				rejection(out,"LEFT_UNSUPPORTED_KEY_TYPE",k,k,path,depth);ok=false;continue
			var c: String=String(k)
			if li.has(c): rejection(out,"LEFT_CANON_KEY_COLLISION",left,right,path+[c],depth);ok=false
			else: li[c]=left[k]
		for k: Variant in right:
			if typeof(k) not in [TYPE_STRING,TYPE_STRING_NAME]:
				rejection(out,"RIGHT_UNSUPPORTED_KEY_TYPE",k,k,path,depth);ok=false;continue
			var c: String=String(k)
			if ri.has(c): rejection(out,"RIGHT_CANON_KEY_COLLISION",left,right,path+[c],depth);ok=false
			else: ri[c]=right[k]
		if not ok: return false # Ambiguous/unsupported key correspondence is never guessed.
		if li.size()!=ri.size(): return rejection(out,"CANON_KEYSET_SIZE",left,right,path,depth)
		for c: String in li:
			if not ri.has(c): rejection(out,"MISSING_CANON_KEY",left,right,path+[c],depth);ok=false
			else:
				var child_ok: bool=diagnose(old,li[c],ri[c],true,out,path+[c],depth+1)
				ok=child_ok and ok
		return ok
	if left is Array:
		if left.size()!=right.size(): return rejection(out,"ARRAY_SIZE",left,right,path,depth)
		var ok: bool=true
		for index: int in left.size():
			var child_ok: bool=diagnose(old,left[index],right[index],canonical_mode,out,path+[index],depth+1)
			ok=child_ok and ok
		return ok
	if lt in [TYPE_NIL,TYPE_BOOL,TYPE_STRING]:
		return true if left==right else rejection(out,"STRICT_SCALAR_VALUE",left,right,path,depth)
	return rejection(out,"UNSUPPORTED_VARIANT",left,right,path,depth)
func compare_case(old: Variant,candidate: Variant,label: String,left: Variant,right: Variant) -> void:
	var before: int=Time.get_ticks_usec()
	var baseline: bool=old.equal(old._wire(left),old._wire(right))
	var baseline_usec: int=Time.get_ticks_usec()-before
	before=Time.get_ticks_usec()
	var deployed: bool=old._symmetric_record_wire_equal(left,right)
	var deployed_usec: int=Time.get_ticks_usec()-before
	before=Time.get_ticks_usec()
	var proposed: bool=candidate._symmetric_record_wire_equal(left,right)
	var proposed_usec: int=Time.get_ticks_usec()-before
	# All domain diagnostics and duplicate success reads below are OUTSIDE timers.
	var strict: bool=old._strict_record_json_equal(left,right)
	var numeric: bool=candidate._numeric_leaf_record_wire_success(left,right)
	var canonical: bool=candidate._canonical_keys_record_wire_success(left,right)
	var first_strict: Dictionary=strict_first_rejection(old,left,right)
	var numeric_rejections: Dictionary={};var canonical_rejections: Dictionary={}
	var numeric_diagnosed: bool=diagnose(old,left,right,false,numeric_rejections)
	var canonical_diagnosed: bool=diagnose(old,left,right,true,canonical_rejections)
	check(baseline==deployed and baseline==proposed,label+": old-wire/deployed7123/canonical results exactly same")
	check(strict==first_strict.is_empty(),label+": old first-strict diagnosis matches")
	check(numeric==numeric_diagnosed and canonical==canonical_diagnosed,label+": full rejection scans match helper bools")
	if label.begins_with("actual pair"):
		check(baseline,label+": independently reconstructed old complete inverse must accept")
	rows.append({"label":label,"old_wire":baseline,"deployed7123":deployed,"canonical_candidate":proposed,"deployed_strict_success":strict,"numeric_leaf_whole_success":numeric,"canonical_keys_whole_success":canonical,"first_deployed_strict_rejection":first_strict,"numeric_full_rejection_domains":numeric_rejections,"canonical_full_rejection_domains":canonical_rejections,"diagnostic_scans_excluded_from_timed_wall":true,"rejection_counts_are_domain_occurrences_not_executed_branch_counts":true,"old_wire_wall_usec":baseline_usec,"deployed_wall_usec":deployed_usec,"canonical_candidate_wall_usec":proposed_usec})
'''
key=key[:start]+diagnostic+key[end:]
key=key.replace('performance18_numeric_leaf_candidate01/output/%d_%d','performance20_canonical_keys_candidate01/output/%d_%d')
key=key.replace('ONE_TYPED_T_PACKET_TWO_SYMMETRIC_PAIRS_NOT_FIELD_OR_LOADING_CREDIT','ONE_TYPED_T_PACKET_CANON_KEYS_FULL_REJECTION_SCANS_NOT_FIELD_OR_LOADING_CREDIT')
anchor2='\tcompare_case(old,candidate,"tiny integer versus float",{"a":4},{"a":4.0})\n'
assert key.count(anchor2)==1
key=key.replace(anchor2,'''\tcompare_case(old,candidate,"tiny StringName key versus String",{&"name":4},{"name":4})
	compare_case(old,candidate,"tiny StringName scalar versus String",{"name":&"value"},{"name":"value"})
	compare_case(old,candidate,"tiny different StringName scalar",{"name":&"value"},{"name":"other"})
	var collision: Dictionary={};collision["dup"]=1;collision[&"dup"]=2
	if collision.size()==2:
		check(not candidate._canonical_keys_record_wire_success(collision,collision),"Constructible canonical-key collision refuses fast success")
		compare_case(old,candidate,"tiny constructible canonical collision",collision,collision)
	else:
		rows.append({"label":"canonical collision construction boundary","ordinary_Dictionary_merged_String_StringName_keys":true,"collision_runtime_coverage_claim":false})
'''+anchor2)
key=key.replace('check(not candidate._numeric_leaf_record_wire_success(nested(64),nested(64)),"Depth64 remains old full fallback")','check(not candidate._numeric_leaf_record_wire_success(nested(64),nested(64)) and not candidate._canonical_keys_record_wire_success(nested(64),nested(64)),"Both helpers depth64 remain old full fallback")')
key=key.encode();keypath=O+'test_typed_packet_full_rejections_PENDING_ROOT.gd'
def patch_hunks(a,b):
    aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
    for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
        if tag!='equal':hs.append({'old_byte_start':len(''.join(aa[:i]).encode()),'old_byte_end':len(''.join(aa[:j]).encode()),'new_byte_start':len(''.join(bb[:k]).encode()),'new_byte_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
    forward=a;inverse=b
    for h in reversed(hs):forward=forward[:h['old_byte_start']]+h['new'].encode()+forward[h['old_byte_end']:]
    for h in reversed(hs):inverse=inverse[:h['new_byte_start']]+h['old'].encode()+inverse[h['new_byte_end']:]
    assert forward==b and inverse==a;return hs
keyhs=patch_hunks(oldkey,key)
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=oldpath,tofile=candidate)).encode()
keydiff=''.join(difflib.unified_diff(oldkey.decode().splitlines(True),key.decode().splitlines(True),fromfile=oldkeypath,tofile=keypath)).encode()
proof={'status':'BUILD_ONLY_CANONICAL_KEYS_SYMMETRIC_SUCCESS_NOT_PARSED_OR_RUN','parent_numeric':{'path':oldpath,'sha256':oldsha},'parent_strict':{'path':numericproof['parent']['path'],'sha256':numericproof['parent']['sha256']},'candidate':{'path':candidate,'sha256':sha(new)},'whole_byte_inverse_to3F002':True,'whole_chained_byte_inverse_to7123':True,'hunks':hunks,
 'numeric_parent_inverse':{'path':P+'whole_byte_inverse_and_design_READY.json','sha256':'18a5354be846ebd5cbad787b81e8352c7c7d92332e792328f19974f798dee47d'},
 'math_boundary':['Canonical keys are only String or StringName and String(key) without Unicode/case normalization. Each side must be injective under canonicalization; any collision or unsupported key fails to unchanged original full fallback.',
 'Both canonical keysets and all array slots match; corresponding original values recurse. StringName scalar comparisons are limited to String/StringName and checked by the old two-sided leaf wire predicate unless same typed/value.',
 'Finite numbers use existing exact old leaf JSON writer/parser semantics when strict typed equality does not already suffice. Equal leaves compose equal parsed JSON trees; no epsilon or native geometry normalization.',
 'Only all-String dictionary pairs use the no-index path; StringName-key dictionaries build ephemeral local canonical indexes referencing original values, never clone or cache scene/native records.',
 'Depth>=64, nonfinite, Object, Vector, packed values, shape mismatch and unknown leaves reject fast success. The old complete equal(_wire(left),_wire(right)) fallback is unchanged, including all prior accepted/rejected cases.',
 'DT one-sided wire, source-FIRST/FINAL, owner/whole inverse, all copies and all production APIs remain unchanged. Both older helpers remain intact for independent rejection diagnosis.',
 'No complete-hit or speed claim. Pending unique typed-packet run must expose both helpers full rejection domains; fast false or slower actual big records is not a promotion basis.'],
 'test':{'key':{'path':keypath,'sha256':sha(key)},'fixture':{'path':fp,'sha256':sha(fb)},'ready':False,'key_parent':{'path':oldkeypath,'sha256':oldkeysha},'key_whole_byte_inverse':True,'key_hunks':keyhs},
 'engine_parse_native_decode_Stage_collector_formal_writes':0}
files={'Bundle_canonical_keys_wire_CANDIDATE.gd':new,'complete_vs_3F002.diff':diff,'typed_packet_comparison_fixture_PENDING_ROOT.json':fb,'test_typed_packet_full_rejections_PENDING_ROOT.gd':key,'key_complete_vs_C716.diff':keydiff,'whole_byte_inverse_and_design_READY.json':js(proof)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
