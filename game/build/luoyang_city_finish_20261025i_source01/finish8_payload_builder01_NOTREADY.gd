extends RefCounted
# Pure assembly of SOURCE-derived terminal views, not an observed-Field capture.
# The publisher independently compares full effective geometry to frozen QA rows.
const C_IDS: Array=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
static func _fingerprint(value: Variant) -> String:
	var h: HashingContext=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(var_to_bytes(value));return h.finish().hex_encode()
static func _rows(rows: Array) -> Dictionary:
	var out: Dictionary={}
	for raw: Variant in rows:
		if not raw is Dictionary: return {}
		var id: String=String(raw.get("id",""))
		if id=="" or out.has(id): return {}
		out[id]=raw
	return out
static func patches(before: Array,after: Array) -> Dictionary:
	var old: Dictionary=_rows(before);var next: Dictionary=_rows(after)
	if old.size()!=before.size() or next.size()!=after.size(): return {}
	var changed: Array=[];var added: Array=[];var retired: Array=[];var order: Array=[]
	for row: Dictionary in before:
		var id: String=String(row.id);order.append(id)
		if not next.has(id): retired.append({"id":id,"before":row.duplicate(true)})
		elif var_to_bytes(row)!=var_to_bytes(next[id]): changed.append({"id":id,"before":row.duplicate(true),"after":next[id].duplicate(true)})
	for row: Dictionary in after:
		if not old.has(String(row.id)): added.append(row.duplicate(true))
	var restored: Dictionary=next.duplicate(true)
	for row: Dictionary in added: restored.erase(String(row.id))
	for row: Dictionary in changed: restored[String(row.id)]=row.before.duplicate(true)
	for row: Dictionary in retired: restored[String(row.id)]=row.before.duplicate(true)
	# Preserve the parent's Array element typing as well as order and values.
	var inverse: Array=before.duplicate(true);inverse.clear()
	for id: String in order:
		if not restored.has(id): return {}
		inverse.append(restored[id])
	if restored.size()!=old.size() or var_to_bytes(inverse)!=var_to_bytes(before): return {}
	return {"visual_patches":changed,"visual_additions":added,"visual_retired":retired,"parent_ordered_ids":order,"whole_typed_inverse_verified":true}

static func retain_old_properties(before: Array,derived: Array) -> Array:
	# Rebuilt source rows retain all unrelated original flags/provenance fields.
	# Only keys explicitly emitted by the new source expression are overwritten.
	var old: Dictionary=_rows(before)
	if old.size()!=before.size(): return []
	var out: Array=[];var seen: Dictionary={}
	for row: Dictionary in derived:
		var id: String=String(row.get("id",""))
		if id=="" or seen.has(id): return []
		seen[id]=true
		var value: Dictionary=old[id].duplicate(true) if old.has(id) else {}
		value.merge(row.duplicate(true),true);out.append(value)
	return out

static func source_NPC_rows(author_rows: Array,size: Vector2) -> Array:
	var out: Array=[];var seen: Dictionary={}
	for row: Dictionary in author_rows:
		var id: String=String(row.get("npc_id",""))
		if id=="" or seen.has(id) or not row.get("foot_px") is Array or row.foot_px.size()!=2: return []
		seen[id]=true
		var foot: Vector2=Vector2(float(row.foot_px[0]),float(row.foot_px[1]))
		if not foot.is_finite(): return []
		# Root chose exactly one Hero-first graph in ambient18.configure_actor.
		# Candidate lore TRES remain provenance, never a second live dialogue.
		out.append({"npc_id":id,"npc_name":String(row.npc_name),"pos":foot/size,"sprite_path":String(row.sprite_path),"portrait_path":String(row.portrait_path),"walk_sprite_path":"","scale":1.0,"movement_mode":"idle","patrol_axis":Vector2.RIGHT,"patrol_distance":0.0,"patrol_speed":22.0,"dialog_id":"","interaction_action":"","dialog_variants":[],"idle_frame_seconds":0.28,"walk_frame_seconds":0.12,"district_life_ground_anchored":true})
	return out

static func build(scene_id: String,world_size: Vector2,parent_native: Array,parent_navigation: Array,parent_blockers: Array,parent_solids: Array,effective_navigation: Array,effective_solids: Array,portal_before: Array,portal_after: Array,interaction_patches: Array,npc_migrations: Array,new_NPCs: Array,effective_walkable_polygons: Array=[]) -> Dictionary:
	if scene_id=="" or not world_size.is_finite() or world_size.x<=0 or world_size.y<=0 or parent_native.is_empty() or parent_navigation.is_empty() or effective_navigation.is_empty() or effective_solids.is_empty(): return {}
	for group: Array in [parent_solids,effective_solids,effective_walkable_polygons]:
		for shape: Variant in group:
			if not shape is PackedVector2Array or shape.size()<3: return {}
			for point: Vector2 in shape:
				if not point.is_finite(): return {}
	if scene_id=="ch4_s4_ancient_temple" and effective_walkable_polygons.is_empty(): return {}
	var diff: Dictionary=patches(parent_navigation,effective_navigation)
	if diff.is_empty(): return {}
	var old_portals: Dictionary=_rows(portal_before);var next_portals: Dictionary=_rows(portal_after)
	if old_portals.size()!=portal_before.size() or next_portals.size()!=portal_after.size(): return {}
	for id: String in old_portals:
		if not next_portals.has(id): return {}
	for patch: Dictionary in interaction_patches:
		if not patch.get("before") is Dictionary or not patch.get("after") is Dictionary or String(patch.before.get("id",""))!=String(patch.get("id","")) or String(patch.after.get("id",""))!=String(patch.get("id","")): return {}
	var payload: Dictionary={"scene_id":scene_id,"world_size_px":world_size,"parent_native_navigation":parent_native.duplicate(true),"parent_navigation":parent_navigation.duplicate(true),"effective_navigation":effective_navigation.duplicate(true),"parent_solids":parent_solids.duplicate(true),"effective_solids":effective_solids.duplicate(true),"visual_patches":diff.visual_patches,"visual_additions":diff.visual_additions,"visual_retired":diff.visual_retired,"portal_before":portal_before.duplicate(true),"portal_after":portal_after.duplicate(true),"interaction_patches":interaction_patches.duplicate(true),"npc_migrations":npc_migrations.duplicate(true),"new_NPCs":new_NPCs.duplicate(true),"effective_walkable_polygons":effective_walkable_polygons.duplicate(true),"restore_contract":{"whole_typed_inverse_verified":true,"parent_ordered_ids":diff.parent_ordered_ids,"inverse_source":"All parent rows retained from immutable source inputs; exact old row flags and field types, never an actual Field observation."}}
	if scene_id in C_IDS: payload.parent_blockers_ref={"kind":"ORIGINAL_COMPLETE_RECEIPT_LAYOUT_BLOCKERS"}
	else: payload.parent_blockers=parent_blockers.duplicate(true)
	var fingerprints: Dictionary={}
	for key: String in payload:
		if payload[key] is Array or key=="parent_blockers_ref": fingerprints[key]=_fingerprint(payload[key])
	return {"ok":true,"payload":payload,"fingerprints":fingerprints,"whole_typed_inverse_verified":true,"actual_Field_observations_used":false}
