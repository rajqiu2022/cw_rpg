extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=false
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="ef273de8406d7126e28a3e00408472771b6aff5662fce98dfd9fd44a4dacc701"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
