extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=true
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="7d33325105c45f87e2577afa2f86fa98237402b576bcd941c83375494f90284f"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
