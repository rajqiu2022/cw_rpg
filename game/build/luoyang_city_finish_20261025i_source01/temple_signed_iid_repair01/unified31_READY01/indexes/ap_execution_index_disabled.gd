extends RefCounted
## External single-release authority: not pinned back into its own approval.
const FORMAL_ENABLED=false
const APPROVAL="res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
const APPROVAL_SHA="2e4b27fab85a6a56e97d0ca2ca377a0ca4b278f7d1f603513a3edd2dd57be607"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":APPROVAL,"sha256":APPROVAL_SHA}
