extends SceneTree
## State-only controlled fixture; no true source mutation, real disk forgery, or city travel.
const SOURCE_READY := false
const SHARED_MS := 60000
const SOURCE_PINS: Dictionary = {}
const PLAN := [
	"Only controlled fresh fixture/live objects; no production scene/import/source writes and no save restore.",
	"Trusted legitimate value duplicate remains accepted; forged live Scene/mask/proof identity rejects.",
	"Normal length/mtime metadata change invalidates authorized lease; seconds precision is not hostile forgery protection.",
	"Single slot and <=512MiB estimated limit; second different city evicts old lease and frees old parked nodes.",
	"Cancel prepare owned token: join jobs, restore original Field/nav/foot/process state; old token cannot alter successor.",
	"newgame reset releases lease and clears its trusted receipt; do not assume reset deletes current active Field.",
	"Re-entry after newgame/metadata invalidation cannot claim old warm hit; no stale flag/quest projection.",
	"Source-first/final cold receipt vs live warm receipt explicitly distinguished; source/save facts retained."
]
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	push_error("DRAFT_NOT_READY: fixture needs frozen production state API; no state or runtime credit")
	quit(1)
