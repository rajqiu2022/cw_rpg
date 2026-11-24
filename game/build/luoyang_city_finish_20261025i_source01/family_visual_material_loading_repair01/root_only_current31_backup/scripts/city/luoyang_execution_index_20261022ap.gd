extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=true
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="8b91e0a9d7c0679b261bfe6e581fc79be4644485cdcce3df247963d05ab91a78"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
