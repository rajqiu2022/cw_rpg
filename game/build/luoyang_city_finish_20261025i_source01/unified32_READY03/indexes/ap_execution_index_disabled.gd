extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=false
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="e9be83b1d82b4d96b68a982610ccc887e8dc73595b957d9dbf571f362e0d221c"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
