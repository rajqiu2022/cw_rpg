extends SceneTree
## Pure tests call the actual activator predicates, not a reconstructed oracle.
## No dispatch/activation/rollback, no file writes, no candidate/Field credit.
const A = preload("res://scripts/dev/activate_luoyang_enclosure_v11_city_only.gd")
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("_run_unit")
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)
func _run_unit() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Public checkpoint guard")
	_check(not C._hash(A.APPROVAL_SHA),"Independent approval must remain PENDING")
	_check(C.LEGACY_SHAS.size()==4,"Exactly four canonical city signatures")
	var journal: String=A.RECOVERY_ROOT+"synthetic_predicate_only/journal.json"
	var new_sha: String="synthetic candidate bytes".sha256_text()
	var unrelated_sha: String="unrelated user edits".sha256_text()
	for id: String in C.LEGACY_SHAS:
		var original: Variant=C.LEGACY_SHAS[id]
		_check(original is Dictionary and original.has("scene") and original.has("layout"),"Real legacy value is scene/layout dictionary")
		_check(not C._hash(original),"Dictionary cannot masquerade as scene SHA")
		var scene_sha: String=original.scene
		_check(A._scene_signature_matches(id,scene_sha),"Exact original .scene SHA")
		_check(A._scene_signature_matches(id,FileAccess.get_sha256("res://data/scenes/"+id+".tres")),"Actual original canonical bytes bind .scene")
		for bad: Variant in [original,original.layout,null,"",true,42,unrelated_sha]:
			_check(not A._scene_signature_matches(id,bad),"Wrong dictionary/layout/type/bytes scene signature rejected")
		var entry := {"original_sha256":scene_sha,"backup_path":journal.get_base_dir()+"/original_"+id+".tres","activated_sha256":new_sha,"required_layout_path":C.layout_path(StringName(id)),"required_layout_sha256":"not-written-in-pure-unit"}
		var before: PackedByteArray=var_to_bytes(entry)
		_check(A._rollback_entry_error(id,journal,entry,scene_sha,scene_sha).is_empty(),"Untouched original accepts rollback schema")
		_check(A._rollback_entry_error(id,journal,entry,new_sha,scene_sha).is_empty(),"Known activated bytes accept rollback schema")
		_check(not A._rollback_entry_error(id,journal,entry,unrelated_sha,scene_sha).is_empty(),"Unrelated canonical edits preserve refusal")
		_check(not A._rollback_entry_error(id,journal,entry,new_sha,unrelated_sha).is_empty(),"Changed backup refuses rollback")
		for mutation: Dictionary in [{"original_sha256":original},{"original_sha256":original.layout},{"original_sha256":unrelated_sha},{"backup_path":"res://data/scenes/"+id+".tres"},{"backup_path":journal.get_base_dir()+"/original_wrong_city.tres"},{"activated_sha256":null},{"activated_sha256":true},{"activated_sha256":""}]:
			var changed: Dictionary=entry.duplicate(true); changed.merge(mutation,true)
			_check(not A._rollback_entry_error(id,journal,changed,new_sha,scene_sha).is_empty(),"Mutation rejects exact rollback schema")
		for bad: Variant in [null,[],true,"entry"]:
			_check(not A._rollback_entry_error(id,journal,bad,new_sha,scene_sha).is_empty(),"Wrong rollback entry type refuses")
		for path: String in ["res://data/scenes/journal.json",A.RECOVERY_ROOT+"../journal.json",journal+".other"]:
			_check(not A._rollback_entry_error(id,path,entry,new_sha,scene_sha).is_empty(),"Recovery outside exact scope refuses")
		_check(var_to_bytes(entry)==before,"Actual pure predicates leave input unchanged")
	_check(not A._scene_signature_matches("world_map_jianghu",new_sha),"World scene excluded from four-city signature")
	_check(not A._rollback_entry_error("world_map_jianghu",journal,{},new_sha,new_sha).is_empty(),"World rollback target excluded")
	for path: String in A.PROTECTED:
		_check(FileAccess.get_sha256(path)==A.PROTECTED[path],"Protected actual world14/outskirts bytes unchanged")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Public checkpoint remains suspended through quit")
	print("LUOYANG_CITY_ONLY_ACTIVATION_SCHEMA_PURE checks="+str(checks)+" failures="+str(failures)+" formal_writes=0")
	quit(0 if failures==0 else 1)
