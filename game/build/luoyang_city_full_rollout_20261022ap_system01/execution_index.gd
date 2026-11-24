extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=false
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="PENDING_FINAL_OWNED_CODE_AND_BEFORE_BYTES"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
