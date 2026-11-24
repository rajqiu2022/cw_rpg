extends RefCounted
## Cold compiler projection for the two civic logical districts only.
## Source declarations replace legacy ownership, never C.prepare/G.matches.
const SIZE=Vector2(3072,2048)
const ROOM_SIZE=Vector2(1536,1024)
const MARKET="ch4_s3_luoyang_market"
const YAMEN="ch4_s1_luoyang_yamen"
const MANSION="luoyang_functional_mansion_candidate_20261016"
const ESTATE="luoyang_estate_riverside_20261021ai"
const ARTISAN="luoyang_artisan_residential_20261022ap"
const REGISTRY="res://data/maps/luoyang_estate_rooms_20261021am/registry.json"
const REGISTRY_SHA="d9d96af91d7f877863425d0184fa358cfaf08e723338b88b1a89a65510e8ce9e"
const SPACE="res://build/luoyang_city_space_20261024b_source01/runtime_READY02/market_space_binding_READY.json"
const SPACE_SHA="003ec7f690ed9494f315132a4f3f6e16263ad3ca38ccb34392913ae07c5f4cdb"
const BLOCK="res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json"
const BLOCK_SHA="de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95"
const ESTATE_HEADER="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const ESTATE_SHA="0857b25b28aede38410d4c952d169dfea5cac70efc16f36a12c9bba589da64bb"
const QUARTER="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
const QUARTER_SHA="58cd5af08cec55d6d98a261d23269cf220b013c2be39c53d862bbf508b3b6117"
static func fail(code: String) -> Dictionary: return {"ok":false,"error":"PURE_PORTAL_"+code,"portals":[]}
static func v(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(float(value[0]),float(value[1])) if value is Array and value.size()==2 else Vector2(INF,INF)
static func read(path: String,sha: String,pins: Dictionary) -> Dictionary:
	if sha.length()!=64 or FileAccess.get_sha256(path)!=sha: return {}
	if pins.has(path) and pins[path]!=sha: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary: return {}
	pins[path]=sha
	return value
static func polygon(foot: Vector2) -> PackedVector2Array:
	return PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])
static func count_target(rows: Array,id: String) -> int:
	var count: int=0
	for row: Dictionary in rows:
		if String(row.get("target_scene",""))==id: count+=1
	return count
static func _rooms(source: SceneScript,raw: Dictionary,out: Array,config: Dictionary,space: Dictionary,pins: Dictionary) -> Dictionary:
	for id: String in config.rooms:
		var declaration: Dictionary=config.rooms[id]
		var data: Dictionary=read(String(declaration.author_path),String(declaration.author_sha256),pins)
		if data.is_empty(): return fail("ROOM_AUTHOR:"+id)
		var room: Dictionary=data.get("room",{});var path: String=String(declaration.scene_path)
		if source.scene_id==StringName(MARKET) and id==MANSION:
			var parent: Dictionary=declaration.get("am_parent_row",{})
			data=read(String(parent.get("author_path","")),String(parent.get("author_sha256","")),pins)
			if data.is_empty() or data.room.city_id!=MARKET: return fail("PRIOR_MANSION_AUTHOR")
			room=data.room;path=String(parent.scene_path)
		if room.get("city_id")!=String(source.scene_id): continue
		var special: Dictionary=space.get("room_returns",{}).get(id,{}) if source.scene_id==StringName(MARKET) else {}
		if not special.is_empty():
			if v(room.get("return_foot_px"))!=v(special.get("old_return_px")) or read(String(special.author_path),String(special.author_sha256),pins).is_empty(): return fail("SPACE_ROOM_RETURN:"+id)
			room=room.duplicate(true);room.return_foot_px=special.new_return_px.duplicate(true)
		var raw_foot: Array=room.get("return_foot_px",[])
		if raw_foot.size()!=2: return fail("ROOM_RETURN_PAIR:"+id)
		# Same scalar division -> Vector2 cast as G, not rounded decimal UV.
		var position:=Vector2(float(raw_foot[0])/3072.0,float(raw_foot[1])/2048.0)
		var threshold: Vector2=v(special.new_threshold_px)/SIZE if not special.is_empty() else position
		var count: int=0
		for portal: Dictionary in out:
			if String(portal.get("target_scene",""))!=id: continue
			count+=1
			if portal.get("pos")!=threshold or portal.get("size")!=Vector2(40.0/3072.0,32.0/2048.0) or portal.get("auto_trigger")!=false: return fail("NATIVE_ROOM_THRESHOLD:"+id)
			portal.target_scene_path=path;portal.target_pos=v(data.geometry.spawn_foot_px)/ROOM_SIZE;portal.label="进入"+String(data.display_name);portal.interaction_polygon_px=polygon(threshold*SIZE)
		if count>1 or not special.is_empty() and count!=1: return fail("ROOM_COUNT:"+id)
		if count==0:
			var buildings: int=0
			for item: Dictionary in raw.finish_payload.parent_navigation:
				if String(item.get("id",""))==String(room.building_id): buildings+=1
			if buildings!=1: return fail("ROOM_BUILDING_SOURCE:"+id)
			out.append({"id":"t_enter_"+String(room.building_id)+"_"+String(data.type_id),"pos":position,"size":Vector2(40.0/3072.0,32.0/2048.0),"target_scene":id,"target_scene_path":path,"target_pos":v(data.geometry.spawn_foot_px)/ROOM_SIZE,"auto_trigger":false,"label":"进入"+String(data.display_name),"interaction_polygon_px":polygon(position*SIZE)})
	return {"ok":true,"portals":out}
static func _market_links(out: Array,estate: Dictionary,quarter: Dictionary,pins: Dictionary) -> Dictionary:
	var without_mansion: Array=[];var removed: int=0
	for row: Dictionary in out:
		if row.get("target_scene")==ESTATE or row.get("id")=="am_market_estate_alley": return fail("DUPLICATE_ESTATE_LINK")
		if row.get("target_scene")==MANSION:
			if row.get("pos")!=Vector2(2820.8/3072.0,1704.0/2048.0) or row.get("size")!=Vector2(40.0/3072.0,32.0/2048.0) or row.get("auto_trigger")!=false: return fail("ORIGINAL_MANSION_THRESHOLD")
			removed+=1
		else: without_mansion.append(row)
	if removed!=1: return fail("ONE_PRIOR_MANSION_REQUIRED")
	var foot: Vector2=v(estate.market_foot_px)
	without_mansion.append({"id":"am_market_estate_alley","pos":foot/SIZE,"size":Vector2(40,32)/SIZE,"auto_trigger":false,"target_scene":ESTATE,"target_scene_path":"res://data/maps/luoyang_estate_courtyard_20261021am/scene.res","target_pos":Vector2(1536,1840)/SIZE,"label":"前往宅园","interaction_polygon_px":polygon(foot)})
	var declaration: Dictionary=quarter.get("artisan_life_successor",{})
	var life: Dictionary=read(String(declaration.get("binding_path","")),String(declaration.get("binding_sha256","")),pins)
	if life.is_empty(): return fail("ARTISAN_LIFE_BINDING")
	for link: Dictionary in quarter.connections:
		if link.get("source")!=MARKET or link.get("target")!=ARTISAN or link.get("kind")!="PUBLIC_QUARTER_LINK": continue
		if count_target(without_mansion,ARTISAN)!=0: return fail("DUPLICATE_ARTISAN_LINK")
		foot=v(link.source_foot)
		without_mansion.append({"id":link.id,"pos":foot/SIZE,"size":Vector2(40,32)/SIZE,"target_scene":link.target,"target_scene_path":life.child["scene.res"].path,"target_pos":v(link.target_foot)/SIZE,"auto_trigger":false,"label":link.label,"interaction_polygon_px":polygon(foot)})
	return {"ok":true,"portals":without_mansion}
static func _market_blocks(out: Array,author: Dictionary) -> Dictionary:
	for migration: Dictionary in author.room_migrations:
		var count: int=0
		for portal: Dictionary in out:
			if String(portal.get("target_scene",""))!=migration.room_id: continue
			count+=1
			var old: Vector2=v(migration.old_return_foot_px)
			if migration.building_id=="market_northeast_rear_frontage": old=Vector2(1690,1596)
			elif migration.building_id=="market_east_ward_frontage": old=Vector2(2610,1596)
			if portal.get("pos")!=old/SIZE or portal.get("size")!=Vector2(40,32)/SIZE or portal.get("auto_trigger")!=false: return fail("BLOCK_ROOM_BEFORE:"+String(migration.room_id))
			var foot: Vector2=v(migration.threshold_px) if migration.building_id in ["market_northeast_rear_frontage","market_east_ward_frontage"] else v(migration.return_foot_px)
			portal.pos=foot/SIZE;portal.interaction_polygon_px=polygon(foot)
		if count!=1: return fail("BLOCK_ROOM_COUNT:"+String(migration.room_id))
	for migration: Dictionary in author.external_portal_migrations:
		var count: int=0
		for portal: Dictionary in out:
			if portal.get("id")!=migration.id: continue
			count+=1
			if portal.get("pos")!=v(migration.old_foot_px)/SIZE: return fail("EXTERNAL_BEFORE:"+String(migration.id))
			var foot: Vector2=v(migration.foot_px);portal.pos=foot/SIZE
			if portal.has("interaction_polygon_px"):
				var points: PackedVector2Array=portal.interaction_polygon_px.duplicate();var delta: Vector2=foot-v(migration.old_foot_px)
				for i: int in points.size(): points[i]+=delta
				portal.interaction_polygon_px=points
		if count!=1: return fail("EXTERNAL_COUNT:"+String(migration.id))
	return {"ok":true,"portals":out}
static func _finish(out: Array,payload: Dictionary) -> Dictionary:
	var before: Dictionary={};var after: Dictionary={};var seen: Dictionary={};var result: Array=[]
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
	for row: Dictionary in out:
		var id: String=String(row.get("id",""))
		if id.is_empty() or seen.has(id): return fail("ORIGINAL_PORTAL_ID")
		seen[id]=true
		if before.has(id):
			if var_to_bytes(row)!=var_to_bytes(before[id]): return fail("FINISH_TYPED_BEFORE:"+id)
			result.append(after[id].duplicate(true))
		else:
			if after.has(id): return fail("FINISH_NEW_COLLISION:"+id)
			result.append(row)
	for id: String in before:
		if not seen.has(id): return fail("FINISH_BEFORE_MISSING:"+id)
	for row: Dictionary in payload.portal_after:
		if not before.has(String(row.id)): result.append(row.duplicate(true))
	return {"ok":true,"portals":result}
static func project(source: SceneScript,raw_terminal: Dictionary) -> Dictionary:
	if source==null or source.map_layout==null or String(source.scene_id) not in [MARKET,YAMEN] or raw_terminal.get("logical_id")!=String(source.scene_id) or not raw_terminal.get("finish_payload") is Dictionary: return fail("SOURCE_CONTEXT")
	var untouched: PackedByteArray=var_to_bytes(source.map_layout.portals)
	var pins: Dictionary={};var config: Dictionary=read(REGISTRY,REGISTRY_SHA,pins)
	var space: Dictionary=read(SPACE,SPACE_SHA,pins)
	if config.is_empty() or config.get("rooms",{}).size()!=12 or space.is_empty(): return fail("FIXED_ROOM_DECLARATIONS")
	var prior: Dictionary=_rooms(source,raw_terminal,source.map_layout.portals.duplicate(true),config,space,pins)
	if prior.get("ok")!=true: return prior
	if source.scene_id==StringName(MARKET):
		var estate: Dictionary=read(ESTATE_HEADER,ESTATE_SHA,pins);var quarter: Dictionary=read(QUARTER,QUARTER_SHA,pins);var block: Dictionary=read(BLOCK,BLOCK_SHA,pins)
		if estate.is_empty() or quarter.is_empty() or block.is_empty(): return fail("FIXED_MARKET_DECLARATIONS")
		prior=_market_links(prior.portals,estate,quarter,pins)
		if prior.get("ok")!=true: return prior
		prior=_market_blocks(prior.portals,block)
		if prior.get("ok")!=true: return prior
	var final: Dictionary=_finish(prior.portals,raw_terminal.finish_payload)
	if final.get("ok")!=true: return final
	if var_to_bytes(source.map_layout.portals)!=untouched: return fail("SOURCE_MUTATED")
	final["source_sha256"]=pins
	final["source_resource_unmodified"]=true
	final["legacy_owner_prepared"]=false
	return final
