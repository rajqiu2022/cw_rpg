extends SceneTree
## Root-only new Router pin admission; no old edge/travel matrix replay.
const AUTH := "res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const CULTURE := "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
const ROUTER := "res://scripts/autoload/scene_router.gd"
const HISTORICAL := "d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var authority: GDScript=load(AUTH)
	var culture: GDScript=load(CULTURE)
	if authority==null or culture==null:push_error("YIHONG_ADMISSION_SCRIPTS");quit(1);return
	if not authority.approved(ROUTER,HISTORICAL):push_error("YIHONG_ADMISSION_HISTORICAL_REJECTED");quit(1);return
	if authority.approved(ROUTER,"0000000000000000000000000000000000000000000000000000000000000000"):push_error("YIHONG_ADMISSION_UNKNOWN_ACCEPTED");quit(1);return
	var ready: Dictionary=culture.readiness()
	if ready.get("ok")!=true or ready.get("contract",{}).get("source_sha256",{}).get(ROUTER)!=HISTORICAL:push_error("YIHONG_ADMISSION_CULTURE:"+str(ready.get("error","")));quit(1);return
	print("YIHONG_ADMISSION_MINIMAL checks=3 errors=0 input=0 scenes=0 saves=0")
	quit(0)
