extends RefCounted
## Exact business definitions for REGION_27D, not a legacy Field owner.
## Original immutable Coordinator supplies only read_state and pure builders;
## its readiness/_owned/attach/open/finish are never invoked here.
const SELF = "res://build/luoyang_city_rectification_20261027d_system01/culture_definition.gd"
const DATA = "res://build/luoyang_city_rectification_20261027d_system01/culture_definition_contract01_BUILD.json"
const DATA_SHA = "04e1887e396f0dab71a12e2238ac3b20d62feaca3e722b998903b6ed6845c59a"
const Business = preload("res://build/luoyang_regions_20261027d_source01/culture_business_snapshot01.gd")
const W = preload("res://scripts/city/luoyang_cultural_sidequests_candidate_20261019w.gd")
const IDS = Business.IDS
const LETTER = Business.LETTER
const BUYER = Business.BUYER
const DOCKS = Business.DOCKS

static func fail(why: String) -> Dictionary:
	return {"ok":false,"error":"REGION_CULTURE_DEFINITION_"+why}

static func _definition() -> Dictionary:
	if FileAccess.get_sha256(DATA)!=DATA_SHA: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not raw is Dictionary or raw.get("schema")!="REGION_27D_CULTURE_BUSINESS_DEFINITION_V1" or raw.get("status")!="FIXED_BUSINESS_DEFINITION_NOT_LEGACY_FIELD_OWNER": return {}
	if not raw.get("contract") is Dictionary or not raw.get("source_sha256") is Dictionary or not raw.get("reducer_source_sha256") is Dictionary: return {}
	return raw

static func dependency_paths() -> Array[String]:
	var definition: Dictionary=_definition()
	if definition.is_empty(): return []
	var paths: Array[String]=[SELF,DATA]
	for path: String in definition.source_sha256: paths.append(path)
	return paths

static func source_declarations() -> Dictionary:
	# New code SELF is pinned by the caller's module table, never current-filled.
	var definition: Dictionary=_definition()
	if definition.is_empty(): return {}
	var paths: Dictionary=definition.source_sha256.duplicate(true)
	paths[DATA]=DATA_SHA
	return paths

static func readiness() -> Dictionary:
	var definition: Dictionary=_definition()
	if definition.is_empty(): return fail("FIXED_CONTRACT")
	for path: String in definition.source_sha256:
		var expected: Variant=definition.source_sha256[path]
		if not path.begins_with("res://") or ".." in path or not expected is String or expected.length()!=64 or FileAccess.get_sha256(path)!=expected: return fail("SOURCE_CHANGED:"+path)
	# W is the original frozen three-quest reducer/24 resources. It contains no
	# Field/Router owner or canonical Coordinator contract dependency.
	var ready: Dictionary=W.readiness()
	if ready.get("ok")!=true: return ready
	if ready.get("sources")!=definition.reducer_source_sha256: return fail("ORIGINAL_W_COMPLETE_SOURCE_SET")
	var contract: Dictionary=definition.contract
	if contract.get("schema_version")!=1 or contract.get("status")!="READY_EXACT_RUNTIME_SOURCES" or not contract.get("canonical_quests") is Dictionary or contract.canonical_quests.size()!=3: return fail("BUSINESS_CONTRACT_SCHEMA")
	var text_path: String=String(contract.get("text_path",""))
	if not definition.source_sha256.has(text_path): return fail("TEXT_SOURCE_DECLARATION")
	var text: Variant=JSON.parse_string(FileAccess.get_file_as_string(text_path))
	if not text is Dictionary or text.get("schema_version")!=1 or not text.get("quests") is Array or text.quests.size()!=3: return fail("TEXT_CONTRACT")
	var text_by_id: Dictionary={}
	for row: Dictionary in text.quests:
		var id: String=String(row.get("quest_id",""))
		if id.is_empty() or text_by_id.has(id): return fail("TEXT_QUEST_ID")
		text_by_id[id]=row
	for id: String in ready.quests:
		if not contract.canonical_quests.has(id) or not text_by_id.has(id): return fail("ORIGINAL_QUEST_SOURCE_SET")
		var path: String=String(contract.canonical_quests[id])
		if not definition.source_sha256.has(path): return fail("QUEST_SOURCE_DECLARATION")
		var quest: QuestDef=ResourceLoader.load(path) as QuestDef
		if quest==null or String(quest.quest_id)!=id or quest.kind!=QuestDef.Kind.SIDE or not quest.completion_triggers.is_empty() or not quest.auto_accept_triggers.is_empty() or quest.reward_gold!=0 or quest.reward_exp!=0 or not quest.reward_items.is_empty() or not quest.reward_skills.is_empty() or not quest.reward_skills_by_faction.is_empty() or not quest.reward_skills_by_flag.is_empty(): return fail("ORIGINAL_ZERO_REWARD_NO_AUTOCOMPLETE_QUEST")
	return {"ok":true,"contract":contract.duplicate(true),"quests":ready.quests,"text":text,"text_by_id":text_by_id,"definition_sources":source_declarations(),"legacy_owner_authority":false}

static func read_state(qid: String, flags: Dictionary, quests: Dictionary) -> Dictionary:
	# This original pure method uses only W's state schema and original flag/QM
	# semantics. It does not call the snapshot's legacy readiness or owner gates.
	return Business.read_state(qid,flags,quests)
