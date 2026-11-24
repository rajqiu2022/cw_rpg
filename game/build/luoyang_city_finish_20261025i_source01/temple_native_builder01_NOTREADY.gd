extends RefCounted
# New Temple-only native layout. No old geometry compilation or route replay.
const SIZE: Vector2=Vector2(1536,1024)
const EXPECTED_OLD_PORTALS: Dictionary={"to_market":Vector2(240,850),"to_canal_docks":Vector2(1296,850)}

static func v(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)

static func polygon(raw: Variant,ratio: Vector2=Vector2.ONE) -> PackedVector2Array:
	var result: PackedVector2Array=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return result
	for point: Variant in raw:
		var p: Vector2=v(point)*ratio
		if not p.is_finite(): return PackedVector2Array()
		result.append(p)
	return result

static func build(parent: SceneScript,old_author: Dictionary,next_author: Dictionary) -> Dictionary:
	if parent==null or parent.scene_id!=&"ch4_s4_ancient_temple" or parent.map_layout==null: return {}
	if old_author.get("placements",[]).size()!=21 or next_author.get("placements",[]).size()!=23 or next_author.get("geometry",{}).get("furniture_bases",[]).size()!=25: return {}
	var parent_layout: WalkableMapLayout=parent.map_layout
	if parent_layout.visual_objects.size()!=21 or parent_layout.portals.size()!=2: return {}
	# Parent native row order and source texture/anchor/native-scale are all checked.
	for i: int in range(old_author.placements.size()):
		var placement: Dictionary=old_author.placements[i]
		var row: Dictionary=parent_layout.visual_objects[i]
		var asset: Dictionary={}
		for candidate: Dictionary in old_author.assets:
			if String(candidate.id)==String(placement.asset_id): asset=candidate
		if asset.is_empty() or String(row.id)!=String(placement.id) or String(row.texture)!=String(asset.texture): return {}
		if v(row.source_ground_anchor_px)!=v(asset.source_ground_anchor_px) or v(row.placement_foot_px)!=v(placement.foot_px) or v(row.native_scale)!=Vector2.ONE*float(placement.scale): return {}
	var scene: SceneScript=parent.duplicate(true) as SceneScript
	var layout: WalkableMapLayout=parent_layout.duplicate(true) as WalkableMapLayout
	if scene==null or layout==null: return {}
	layout.visual_objects.clear();layout.blockers.clear()
	for placement: Dictionary in next_author.placements:
		var asset: Dictionary={}
		for candidate: Dictionary in next_author.assets:
			if String(candidate.id)==String(placement.asset_id): asset=candidate
		if asset.is_empty(): return {}
		layout.visual_objects.append({"id":placement.id,"texture":asset.texture,"source_ground_anchor_px":v(asset.source_ground_anchor_px),"placement_foot_px":v(placement.foot_px),"native_scale":Vector2.ONE*float(placement.scale)})
	for base: Dictionary in next_author.geometry.furniture_bases:
		if base.get("blocking")!=true: return {}
		var points: PackedVector2Array=polygon(base.ground_polygon_px,Vector2.ONE/SIZE)
		if points.size()<3: return {}
		layout.blockers.append({"id":base.id,"ground_polygon":points,"walkability_margin":0.0})
	# Exact inherited portal fields other than the approved source-local positions remain intact.
	var migrations: Array=next_author.finish_i_effective_portal_local_migrations
	if migrations.size()!=2: return {}
	for migration: Dictionary in migrations:
		var count: int=0
		for portal: Dictionary in layout.portals:
			if String(portal.id)==String(migration.id):
				if v(portal.pos)!=v(migration.old_local_source_foot_px)/SIZE: return {}
				portal.pos=v(migration.new_local_source_foot_px)/SIZE;count+=1
		if count!=1: return {}
	# Both old bell/cave hotspots were intentionally retired by the current two-monk
	# quest interface. Keep that live policy; do not recreate a historical hotspot.
	for interaction: Dictionary in layout.interactions:
		if String(interaction.get("id","")) in ["legacy_hotspot_4","legacy_hotspot_5"]: return {}
	var hotspot_changes: int=0
	for hotspot: Dictionary in scene.hotspots:
		var action: String=String(hotspot.get("action",""))
		if action in ["dialog:ch4_longmen_mystery","dialog:ch4_baima_bell"]: return {}
		var old_foot: Vector2
		var next_foot: Vector2
		if action=="scene:ch4_s3_luoyang_market": old_foot=Vector2(240,850);next_foot=Vector2(170,980)
		elif action=="scene:ch4_s2_canal_docks": old_foot=Vector2(1296,850);next_foot=Vector2(1380,980)
		else: continue
		if Vector2(float(hotspot.pos_x),float(hotspot.pos_y))!=old_foot/SIZE: return {}
		hotspot.pos_x=next_foot.x/SIZE.x;hotspot.pos_y=next_foot.y/SIZE.y
		hotspot_changes+=1
	if hotspot_changes!=2: return {}
	scene.map_layout=layout
	return {"ok":true,"scene":scene,"layout":layout,"old_scene":parent,"old_layout":parent_layout,
	 "scene_NPC_task_default_camera_and_effects_unchanged":true,"new_geometry_compiled_here":false}
