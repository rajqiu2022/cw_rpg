extends SceneTree
## Root-only. Load new leaf scripts without instantiating any field or old city.
const LEAVES: Array[String]=[
	"res://build/three_settlements_20261030e_system01/common_author.gd",
	"res://build/three_settlements_20261030e_system01/settlement_registry.gd",
	"res://build/three_settlements_20261030e_system01/minimap_layout_snapshot.gd",
	"res://build/three_settlements_20261030e_system01/city_minimap.gd",
	"res://build/three_settlements_20261030e_system01/settlement_field.gd",
	"res://build/three_settlements_20261030e_system01/xiangzhou_author.gd",
	"res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd",
	"res://build/three_settlements_20261030e_yanmen01/yanmen_author.gd"
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failed:=0
	for path: String in LEAVES:
		var leaf:=load(path) as Script
		var okay: bool=leaf!=null and leaf.can_instantiate()
		print("PARSE30E ","PASS" if okay else "FAIL"," ",path," SHA256=",FileAccess.get_sha256(path))
		if not okay:failed+=1
	if failed==0:
		for path: String in LEAVES:
			if not path.ends_with("_author.gd") or path.ends_with("common_author.gd"):continue
			var a: Variant=load(path)
			var positive: bool=a.safe_foot(a.SOUTH_ARRIVAL/a.SIZE) and a.safe_foot(a.SOUTH_EXIT/a.SIZE)
			var buildings: Array[Dictionary]=a.building_specs()
			var body: Rect2=buildings[0].body
			var negative: bool=not a.safe_foot(body.get_center()/a.SIZE,false)
			var native:=true
			for row: Dictionary in buildings:
				if float(row.native_scale)>1.0 or float(row.native_scale)<=0 or not ResourceLoader.exists(row.texture):native=false
			var original: SceneScript=load("res://data/scenes/"+String(a.ID)+".tres") as SceneScript
			var candidate: SceneScript=a.scene()
			var original_ids: Array[String]=[]
			for npc: Dictionary in candidate.npcs:original_ids.append(String(npc.get("npc_id","")))
			var business: bool=candidate.is_settlement==original.is_settlement and var_to_bytes(candidate.encounter_groups)==var_to_bytes(original.encounter_groups)
			for npc: Dictionary in original.npcs:
				if not original_ids.has(String(npc.get("npc_id",""))):business=false
			print("GEOMETRY30E ",a.ID," positive_arrival_exit=",positive," negative_body=",negative," native_modules=",native," original_business=",business," buildings=",buildings.size()," npcs=",candidate.npcs.size())
			if not positive or not negative or not native or not business:failed+=1
	print("PARSE30E_RESULT scripts=",LEAVES.size()," failed=",failed," no_field_instances=true")
	quit(1 if failed>0 else 0)
