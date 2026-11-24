extends SceneTree
## Root runs after exact deployment. Read-only admission, not a city/travel replay.
const AUTH := "res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const CULTURE := "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
const PRESENTATION := "res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd"
const ROUTER := "res://scripts/autoload/scene_router.gd"
const HISTORICAL := "d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"
var checks:=0
func _initialize() -> void:call_deferred("_run")
func verify(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:
		push_error("LUOYANG_ADMISSION_FAIL "+label)
		quit(1)
	return ok
func _run() -> void:
	var authority: GDScript=load(AUTH)
	var culture: GDScript=load(CULTURE)
	var presentation: GDScript=load(PRESENTATION)
	if not verify(authority!=null and culture!=null and presentation!=null,"scripts"):return
	var header: Dictionary=authority.header()
	if not verify(not header.is_empty(),"frozen EX index/source header"):return
	var row: Dictionary=header.owned[ROUTER]
	if not verify(row.edges.size()==13,"Router original thirteen edges"):return
	for i: int in range(row.edges.size()):
		var edge: Dictionary=row.edges[i]
		if not verify(authority.edge_valid(edge,ROUTER,edge.new_sha256,header.source_sha256),"Router full byte inverse edge "+str(i)):return
	if not verify(authority.approved(ROUTER,HISTORICAL),"exact historical Router admitted through complete chain"):return
	if not verify(not authority.approved(ROUTER,"0000000000000000000000000000000000000000000000000000000000000000"),"unknown SHA rejected"):return
	var readiness: Dictionary=culture.readiness()
	if not verify(readiness.get("ok")==true,"Cultural original runtime contract readiness "+String(readiness.get("error",""))):return
	if not verify(readiness.contract.source_sha256[ROUTER]==HISTORICAL,"original contract pin unchanged"):return
	var paths: Dictionary=presentation.source_paths()
	if not verify(not paths.is_empty() and paths.has(AUTH),"AP real source_paths authority closure"):return
	print("LUOYANG_ADMISSION_READY checks=",checks," errors=0 input=0 saves=0 scenes=0")
	quit(0)
