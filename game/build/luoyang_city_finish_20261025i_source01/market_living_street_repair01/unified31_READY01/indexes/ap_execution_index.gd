extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=true
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="b37e7d1e0e8f74e774bd8432f19f3d5e9103ebb15c1af52ea2f3ddaa6bd92ea3"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
