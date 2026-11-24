extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=true
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="65a9042ad2571820f13ae1a5fdfeb6fd3b6f987a0980dfaa08d70e1f7c4e511b"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
