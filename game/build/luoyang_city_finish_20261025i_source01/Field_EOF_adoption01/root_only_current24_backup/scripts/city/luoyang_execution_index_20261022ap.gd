extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=true
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="523bdcdd31d3b926e1c0e4b9a71b627d1ad57563a877f890aa2ed0a498ce1f9e"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
