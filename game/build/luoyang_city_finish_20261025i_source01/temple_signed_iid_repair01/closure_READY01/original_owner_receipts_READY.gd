extends RefCounted
# Boundary adapter only. It does not run a collector, start/finalize a parent,
# create a token, hash current files into expectations, or grant an owner.
const C_PATH: String="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const QUARTER_PATH: String="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
const ESTATE_PATH: String="res://scripts/city/luoyang_estate_family_20261021am.gd"
const TEMPLE_PATH: String="res://scripts/city/luoyang_temple_assembly_20261016.gd"
const C_IDS: Array=[&"ch4_s0_luoyang_gate",&"ch4_s1_luoyang_yamen",&"ch4_s2_canal_docks",&"ch4_s3_luoyang_market"]
const QUARTER_IDS: Array=[&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]

static func _common(scene: SceneScript,kind: String,key: String,token: int,first: Dictionary,last: Dictionary,finalized: bool) -> Dictionary:
	if scene==null or scene.map_layout==null or kind=="" or key=="" or (token==0 if kind=="TEMPLE_OWN_FIELD_ORIGINAL" and scene.scene_id==&"ch4_s4_ancient_temple" else token<=0) or first.is_empty(): return {}
	if finalized and (last.is_empty() or first!=last): return {}
	return {"owner_kind":kind,"owner_key":key,"token":token,"scene_instance":scene.get_instance_id(),"layout_instance":scene.map_layout.get_instance_id(),"cold_storage_validated":true,"source_first":first.duplicate(true),"source_final":last.duplicate(true),"finalized":finalized}

static func _plain_storage_value(raw: Variant) -> Variant:
	if raw is Dictionary:
		if raw.size()==4 and raw.has_all(["array_values","typed_builtin","typed_class_name","typed_script_path"]):
			if not raw.array_values is Array or String(raw.typed_script_path)!="": return null
			var items: Array=[]
			for item: Variant in raw.array_values: items.append(_plain_storage_value(item))
			return Array(items,int(raw.typed_builtin),StringName(raw.typed_class_name),null)
		var result: Dictionary={}
		for key: Variant in raw: result[key]=_plain_storage_value(raw[key])
		return result
	return raw

static func _with_original_arrays(result: Dictionary,blockers: Variant,native_rows: Variant) -> Dictionary:
	if result.is_empty() or not blockers is Array or not native_rows is Array: return {}
	result.original_parent_blockers=blockers.duplicate(true)
	result.original_native_navigation=native_rows.duplicate(true)
	result.original_arrays_expected_from="Original fully validated layout storage, not observed-current values"
	return result

static func _city_receipt(scene: SceneScript,need_final: bool,c: Variant) -> Dictionary:
	var chosen: Dictionary={}
	# A real current transition is preferred; a parked resident keeps its original
	# token rather than adopting another scene's later global transition token.
	for candidate: Dictionary in [c._transition_validation,c._resident_ready]:
		if candidate.get("scene")==scene and candidate.get("id")==scene.scene_id:
			if need_final and candidate.get("sources_finalized")!=true: continue
			chosen=candidate;break
	if chosen.is_empty() or int(chosen.get("token",0))<=0: return {}
	var record: Variant=c._records.get(String(scene.scene_id))
	if not record is Dictionary or not c._equal_value(chosen.get("record"),record): return {}
	# Only cold / final boundaries call this. Per-motion consumers use Weak leases.
	if not c._equal_value(c._transition_storage(scene),chosen.get("output")) or not c._equal_value(c._transition_storage(scene.map_layout),chosen.get("output_layout")): return {}
	if not c._equal_value(c._solids.get(String(scene.scene_id)),chosen.get("solids")): return {}
	var first: Variant=chosen.get("sources")
	if not first is Dictionary or first.is_empty(): return {}
	var finalized: bool=chosen.get("sources_finalized")==true
	if need_final and not finalized: return {}
	var last: Dictionary=first.duplicate(true) if finalized else {}
	# This exact copy is justified only by ORIGINAL finalize_live_transition_sources:
	# sources_finalized is set after actual complete FINAL == sources, never here.
	var key: String="C_ORIGINAL:"+String(scene.scene_id)+":"+str(int(chosen.token))+":"+str(scene.get_instance_id())+":"+str(scene.map_layout.get_instance_id())
	return _with_original_arrays(_common(scene,"C_COMPLETE_ORIGINAL",key,int(chosen.token),first,last,finalized),chosen.output_layout.get("blockers"),chosen.output_layout.get("visual_objects"))

static func _family_receipt(scene: SceneScript,need_final: bool,family: Variant,kind: String) -> Dictionary:
	# The original matches establishes the native whole-storage weak session.
	# No new Scene/layout/view is accepted in place of that original storage.
	if not family.matches(scene): return {}
	var original: Dictionary=family.original_receipt_for(scene)
	var token: int=int(original.get("serial",0))
	var key: String=String(original.get("key",""))
	var first: Variant=original.get("source_first")
	var last: Variant=original.get("source_final",{})
	if token<=0 or key=="" or not first is Dictionary or not last is Dictionary: return {}
	var finalized: bool=original.get("finalized")==true and int(original.get("full_source_hash_passes",0))==2
	if need_final and not finalized: return {}
	if not finalized and not last.is_empty(): return {}
	var packet: Dictionary=family.packet(scene.scene_id) if kind=="QUARTER_ORIGINAL" else family.packet()
	var stored: Dictionary=packet.get("layout_storage",{}).get("fields",{})
	return _with_original_arrays(_common(scene,kind,key,token,first,last,finalized),_plain_storage_value(stored.get("blockers")),_plain_storage_value(stored.get("visual_objects")))

static func _temple_receipt(scene: SceneScript,session: Variant,need_final: bool,c: Variant) -> Dictionary:
	# Temple has no original Router FIRST. Only its already-prepared real Field
	# instance can grant this receipt. Never create a fake pre-arrival session.
	if not session is RefCounted or session.get_script()==null or session.get_script().resource_path!=TEMPLE_PATH: return {}
	if session._scene!=scene or session._released: return {}
	var state: Dictionary=session.state()
	if state.get("released")!=false or state.get("scene_instance")!=scene.get_instance_id() or String(state.get("error",""))!="": return {}
	if not c._equal_value(session._scene_storage,c._transition_storage(scene)) or not c._equal_value(session._layout_storage,c._transition_storage(scene.map_layout)): return {}
	var first: Variant=state.get("source_first")
	var last: Variant=state.get("source_final",{})
	if not first is Dictionary or not last is Dictionary: return {}
	var finalized: bool=state.get("finalized")==true
	if need_final and not finalized: return {}
	var token: int=session.get_instance_id()
	var key: String="TEMPLE_ORIGINAL_INSTANCE:"+str(token)+":"+str(scene.get_instance_id())+":"+str(scene.map_layout.get_instance_id())
	return _with_original_arrays(_common(scene,"TEMPLE_OWN_FIELD_ORIGINAL",key,token,first,last,finalized),session._layout_storage.get("blockers"),session._layout_storage.get("visual_objects"))

static func receipt(scene: SceneScript,temple_session: Variant=null,final: bool=false) -> Dictionary:
	if scene==null or scene.map_layout==null: return {}
	var c: Variant=load(C_PATH)
	if not c is GDScript or c.resource_path!=C_PATH: return {}
	if scene.scene_id in C_IDS: return _city_receipt(scene,final,c)
	if scene.scene_id in QUARTER_IDS:
		var quarter: Variant=load(QUARTER_PATH)
		return _family_receipt(scene,final,quarter,"QUARTER_ORIGINAL") if quarter is GDScript and quarter.resource_path==QUARTER_PATH else {}
	if scene.scene_id==&"luoyang_estate_riverside_20261021ai":
		var estate: Variant=load(ESTATE_PATH)
		return _family_receipt(scene,final,estate,"ESTATE_ORIGINAL") if estate is GDScript and estate.resource_path==ESTATE_PATH else {}
	if scene.scene_id==&"ch4_s4_ancient_temple": return _temple_receipt(scene,temple_session,final,c)
	return {}
