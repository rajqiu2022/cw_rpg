extends RefCounted
## Cold source projection only. Never calls G/Family.matches or prepare/safe_body.
## Static body/route validation belongs to the new Region compiler, not an old lease.
const ESTATE = "luoyang_estate_riverside_20261021ai"
const TEMPLE = "ch4_s4_ancient_temple"
const GARDEN = "luoyang_riverside_garden_20261022ap"
const SIZE = Vector2(3072,2048)
const TEMPLE_SOURCE_SIZE = Vector2(1536,1024)
const QUARTER = "res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
const QUARTER_SHA = "58cd5af08cec55d6d98a261d23269cf220b013c2be39c53d862bbf508b3b6117"
const GARDEN_BINDING = "res://build/luoyang_garden_river_20261025h_source01/runtime02_READY/garden_river_binding_READY.json"
const GARDEN_SHA = "7ecb31c6adde123f7b365ba6596dc1eed3b1e795c3b4a6baa3162992e3bf5cdf"

static func fail(code: String) -> Dictionary:
	return {"ok":false,"error":"PURE_FAMILY_PORTAL_"+code,"portals":[]}

static func v(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2:
		for number: Variant in value:
			if typeof(number) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(number)): return Vector2.INF
		return Vector2(float(value[0]),float(value[1]))
	return Vector2.INF

static func read(path: String, expected: String, pins: Dictionary) -> Dictionary:
	if expected.length()!=64 or FileAccess.get_sha256(path)!=expected: return {}
	if pins.has(path) and pins[path]!=expected: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary: return {}
	pins[path]=expected
	return value

static func _estate(original: Array, pins: Dictionary) -> Dictionary:
	var header: Dictionary=read(QUARTER,QUARTER_SHA,pins)
	var garden: Dictionary=read(GARDEN_BINDING,GARDEN_SHA,pins)
	if header.is_empty() or garden.is_empty() or header.get("status")!="ROOT_ADMITTED_AP_TWO_QUARTERS" or garden.get("ready")!=true or garden.get("scene_id")!=GARDEN: return fail("FIXED_HEADERS")
	if header.get("garden_river_successor")!={"binding_path":GARDEN_BINDING,"binding_sha256":GARDEN_SHA}: return fail("GARDEN_DECLARATION")
	var forward: Array=[]; var reverse: Array=[]
	for row: Dictionary in header.get("connections",[]):
		if row.get("kind")!="PUBLIC_QUARTER_LINK": continue
		if row.get("source")==ESTATE: forward.append(row)
		if row.get("source")==GARDEN and row.get("target")==ESTATE: reverse.append(row)
	# The original G->AP branch appends ONE Estate outbound. The second member
	# of the contract is the Garden return, not a second Estate exit.
	if forward.size()!=1 or reverse.size()!=1: return fail("EXACT_BIDIRECTIONAL_PAIR_COUNT")
	var link: Dictionary=forward[0]; var back: Dictionary=reverse[0]
	if link.get("id")!="estate_to_garden" or link.get("target")!=GARDEN or back.get("id")!="garden_to_estate": return fail("EXACT_PAIR_IDS")
	var foot: Vector2=v(link.get("source_foot")); var target: Vector2=v(link.get("target_foot"))
	if foot!=Vector2(2944,1840) or target!=Vector2(256,1680) or v(back.get("source_foot"))!=target or v(back.get("target_foot"))!=foot: return fail("EXACT_RETURN_CONTRACT")
	var child: Dictionary=garden.get("child",{}).get("scene.res",{})
	var path: String=String(child.get("path","")); var expected: String=String(child.get("sha256",""))
	if not path.begins_with("res://build/luoyang_garden_river_20261025h_source01/") or expected.length()!=64 or header.get("scenes",{}).get(GARDEN,{}).get("scene_path")!=path: return fail("GARDEN_SOURCE_SCENE")
	if garden.get("required_sources",{}).get(path)!=expected or header.get("source_sha256",{}).get(path)!=expected or FileAccess.get_sha256(path)!=expected: return fail("GARDEN_SOURCE_SCENE_PIN")
	pins[path]=expected
	var out: Array=original.duplicate(true)
	for prior: Dictionary in out:
		if prior.get("id")==link.id or prior.get("target_scene")==GARDEN: return fail("DUPLICATE_GARDEN_TARGET")
	# Exact original AP.project_connections append order, scalar expression,
	# activation and ordinary ExitZone polygon. Native prefix stays untouched.
	out.append({"id":link.id,"pos":foot/SIZE,"size":Vector2(40,32)/SIZE,"target_scene":link.target,"target_scene_path":path,"target_pos":target/SIZE,"auto_trigger":false,"label":link.label,"interaction_polygon_px":PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])})
	return {"ok":true,"portals":out,"preserved_return_contract":back.duplicate(true)}

static func _finish(original: Array, payload: Dictionary) -> Dictionary:
	var before: Dictionary={}; var after: Dictionary={}; var seen: Dictionary={}; var out: Array=[]
	if not payload.get("portal_before") is Array or not payload.get("portal_after") is Array: return fail("FINISH_ARRAYS")
	for row: Dictionary in payload.portal_before:
		var id: String=String(row.get("id",""))
		if id.is_empty() or before.has(id): return fail("FINISH_BEFORE_ID")
		before[id]=row
	for row: Dictionary in payload.portal_after:
		var id: String=String(row.get("id",""))
		if id.is_empty() or after.has(id): return fail("FINISH_AFTER_ID")
		after[id]=row
	for id: String in before:
		if not after.has(id): return fail("FINISH_DROPPED_ID")
	for row: Dictionary in original:
		var id: String=String(row.get("id",""))
		if id.is_empty() or seen.has(id): return fail("NATIVE_PORTAL_ID")
		seen[id]=true
		if before.has(id):
			if var_to_bytes(row)!=var_to_bytes(before[id]): return fail("FINISH_TYPED_BEFORE:"+id)
			out.append(after[id].duplicate(true))
		else:
			if after.has(id): return fail("FINISH_NEW_COLLISION:"+id)
			out.append(row.duplicate(true))
	for id: String in before:
		if not seen.has(id): return fail("FINISH_BEFORE_MISSING:"+id)
	for row: Dictionary in payload.portal_after:
		if not before.has(String(row.id)): out.append(row.duplicate(true))
	return {"ok":true,"portals":out}

static func _temple_contract(before: Array, after: Array) -> bool:
	if before.size()!=2 or after.size()!=2: return false
	var expected: Dictionary={"legacy_portal_6":{"target":"ch4_s3_luoyang_market","old":Vector2(240,850),"new":Vector2(170,926)},"legacy_portal_7":{"target":"ch4_s2_canal_docks","old":Vector2(1296,850),"new":Vector2(1380,926)}}
	var seen: Dictionary={}
	for i: int in before.size():
		var old: Dictionary=before[i]; var next: Dictionary=after[i]
		var id: String=String(old.get("id",""))
		if not expected.has(id) or seen.has(id) or next.get("id")!=id or old.get("target_scene")!=expected[id].target: return false
		if old.get("pos")!=expected[id].old/TEMPLE_SOURCE_SIZE or next.get("pos")!=expected[id].new/TEMPLE_SOURCE_SIZE or old.get("target_pos")!=Vector2(.12,.75): return false
		var unchanged: Dictionary=old.duplicate(true); unchanged.pos=next.pos
		if var_to_bytes(unchanged)!=var_to_bytes(next): return false
		seen[id]=true
	return seen.size()==2

static func project(source: SceneScript, raw_terminal: Dictionary) -> Dictionary:
	if source==null or source.map_layout==null or String(source.scene_id) not in [ESTATE,TEMPLE] or raw_terminal.get("logical_id")!=String(source.scene_id) or not raw_terminal.get("finish_payload") is Dictionary: return fail("SOURCE_CONTEXT")
	var payload: Dictionary=raw_terminal.finish_payload
	if payload.get("scene_id")!=String(source.scene_id): return fail("PAYLOAD_IDENTITY")
	var saved: PackedByteArray=var_to_bytes(source.map_layout.portals)
	var pins: Dictionary={}; var prior: Dictionary={"ok":true,"portals":source.map_layout.portals.duplicate(true)}
	if source.scene_id==StringName(ESTATE):
		prior=_estate(prior.portals,pins)
		if prior.get("ok")!=true: return prior
	var final: Dictionary=_finish(prior.portals,payload)
	if final.get("ok")!=true: return final
	if source.scene_id==StringName(TEMPLE) and not _temple_contract(prior.portals,final.portals): return fail("TEMPLE_VISIBLE_PAIR_OR_NONPOSITION_DELTA")
	if var_to_bytes(source.map_layout.portals)!=saved: return fail("SOURCE_MUTATED")
	final["source_sha256"]=pins
	final["source_resource_unmodified"]=true
	final["legacy_owner_prepared"]=false
	if prior.has("preserved_return_contract"): final["preserved_return_contract"]=prior.preserved_return_contract
	return final
