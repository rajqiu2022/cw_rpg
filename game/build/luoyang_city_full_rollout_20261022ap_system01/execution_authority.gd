extends RefCounted
## A single AP executable-source release, not a "trust the current disk" gate.
## Every accepted historical SHA has a byte-exact inverse path to a frozen
## predecessor. Data/art/geometry resources are NOT executable successors.
const SELF="res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const INDEX="res://scripts/city/luoyang_execution_index_20261022ap.gd"
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const OWNED=[
	"res://scripts/city/luoyang_precomputed_bundle_20261018r.gd",
	"res://scripts/city/luoyang_assembled_interiors_20261016g.gd",
	"res://scripts/city/luoyang_estate_family_20261021am.gd",
	"res://scripts/autoload/scene_router.gd",
	"res://scripts/city/luoyang_harbour_life_runtime_20261016.gd",
	"res://scripts/city/luoyang_district_life_20261016f.gd",
	"res://scripts/city/luoyang_docks_workyard_20261019ac.gd",
	"res://scripts/city/luoyang_city_tasks_20261016.gd",
	"res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd",
	"res://scripts/field/field_walkable_controller.gd",
	"res://scripts/city/luoyang_temple_assembly_20261016.gd"
]
static func hash_string(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for n: int in value.length():
		if value.unicode_at(n) not in [48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102]: return false
	return true
static func bytes_sha(value: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(value);return h.finish().hex_encode()
static func header() -> Dictionary:
	if not FileAccess.file_exists(INDEX): return {}
	var index: Variant=load(INDEX)
	if not index is GDScript or index.resource_path!=INDEX or not index.formal_enabled(): return {}
	var authority: Dictionary=index.entry()
	if authority.size()!=2 or authority.get("path")!=APPROVAL or not hash_string(authority.get("sha256")) or FileAccess.get_sha256(APPROVAL)!=authority.sha256: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(APPROVAL))
	if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("status")!="ROOT_APPROVED_AP_EXACT_EXECUTABLE_SUCCESSION" or not raw.get("owned") is Dictionary or raw.owned.is_empty() or not raw.get("source_sha256") is Dictionary or raw.source_sha256.has(INDEX) or raw.source_sha256.has(APPROVAL): return {}
	if raw.source_sha256.get(SELF)!=FileAccess.get_sha256(SELF): return {}
	for p: String in raw.owned:
		if p not in OWNED or not hash_string(raw.owned[p].get("current_sha256")) or not raw.owned[p].get("edges") is Array or raw.owned[p].edges.is_empty(): return {}
	return raw
static func source_paths() -> Dictionary:
	var data: Dictionary=header()
	if data.is_empty(): return {}
	var result: Dictionary={SELF:true,INDEX:true,APPROVAL:true}
	for p: String in data.source_sha256:
		if not p.begins_with("res://") or ".." in p or not hash_string(data.source_sha256[p]): return {}
		result[p]=true
	return result
static func edge_valid(edge: Dictionary,path: String,current_sha: String,pins: Dictionary) -> bool:
	if edge.get("path")!=path or edge.get("new_sha256")!=current_sha or not hash_string(edge.get("old_sha256")) or not edge.get("old_snapshot") is String or not edge.get("new_snapshot") is String or edge.get("whole_inverse")!=true or not edge.get("replacements") is Array or edge.replacements.is_empty(): return false
	var previous_path: String=edge.old_snapshot;var next_path: String=edge.new_snapshot
	if previous_path==path or next_path!=path and not next_path.begins_with("res://build/luoyang_"): return false
	if pins.get(previous_path)!=edge.old_sha256 or (next_path!=path and pins.get(next_path)!=current_sha): return false
	if FileAccess.get_sha256(previous_path)!=edge.old_sha256 or FileAccess.get_sha256(next_path)!=current_sha: return false
	var old_bytes: PackedByteArray=FileAccess.get_file_as_bytes(previous_path)
	var next: String=FileAccess.get_file_as_string(next_path)
	var inverse: String=next
	for replacement: Variant in edge.replacements:
		if not replacement is Dictionary or replacement.size()!=2 or not replacement.get("old") is String or not replacement.get("new") is String or replacement.old==replacement.new or replacement.new.is_empty() or inverse.count(replacement.new)!=1: return false
		inverse=inverse.replace(replacement.new,replacement.old)
	if inverse.to_utf8_buffer()!=old_bytes: return false
	# Geometry-owning executable changes preserve the entire actual navigation
	# function where the author declares it; no substring/whitespace substitute.
	if edge.has("navigation_source"):
		if not edge.navigation_source is String or edge.navigation_source.is_empty() or next.count(edge.navigation_source)!=1 or old_bytes.get_string_from_utf8().count(edge.navigation_source)!=1: return false
	return true
static func approved(path: String,historical_sha: String) -> bool:
	if path not in OWNED or not hash_string(historical_sha): return false
	var data: Dictionary=header()
	if data.is_empty() or not data.owned.has(path): return false
	var row: Dictionary=data.owned[path];var current: String=row.current_sha256
	if FileAccess.get_sha256(path)!=current: return false
	if current==historical_sha: return true
	var visited: Dictionary={};var frontier: Array[String]=[current]
	for depth: int in range(16):
		if frontier.is_empty(): return false
		var next: Array[String]=[]
		for sha: String in frontier:
			if visited.has(sha): continue
			visited[sha]=true
			for edge: Dictionary in row.edges:
				if edge.get("new_sha256")!=sha: continue
				if not edge_valid(edge,path,sha,data.source_sha256): return false
				if edge.old_sha256==historical_sha: return true
				next.append(String(edge.old_sha256))
		frontier=next
	return false
