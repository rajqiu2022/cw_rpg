extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=false
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="0adc31775f84cdc90b547c71f3cb4c48cb2c1a88cc285c3bf272bdbbba3774e6"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
