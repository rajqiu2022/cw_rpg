extends SceneTree
## Independent single-inn scope, not a second world/city journey or all-room loop.
const SOURCE_READY := false
const SHARED_MS := 90000
const ARRIVAL_MS := 60000
const RETURN_READY_LIMIT_USEC := 2000000
const SOURCE_PINS: Dictionary = {}
const PLAN := [
	"Suspend own checkpoint saves and record 15 facts before first await; isolate only process state.",
	"One public current-v3 Market legal near-inn birth; explicitly SETUP, not cross-city travel.",
	"Wait actual cold finalized source proof +Loading hidden +can_move; bind prepared record without getter prepare.",
	"Capture trusted live exterior identities/nav/maskImage and actual task-projection baseline.",
	"Normal final short INPUT +Space at legal non-exact inn door stand; actual inn ready/native Physics.",
	"While exterior parked, change approved existing flag +quest state only in isolated live memory.",
	"Normal room INPUT toward actual-world exit, then Space; return hidden+operable strictly <2000000us.",
	"Same exterior Field/mask/guard and exact remembered door feet; Player may rebuild only if dirty contract authorizes.",
	"Actual current flag/quest NPC and interaction projection, not pre-park snapshot; no reward/story-chain credit.",
	"Full875 +17 +continuous34x24 +<=4px path +nativePhysics; PNG and source/save before-after protection.",
	"Reset/release own Field without restoring or touching any real save file."
]
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	push_error("DRAFT_NOT_READY: await SYSTEM lease/dirty API and exact source pins; no runtime credit")
	quit(1)
