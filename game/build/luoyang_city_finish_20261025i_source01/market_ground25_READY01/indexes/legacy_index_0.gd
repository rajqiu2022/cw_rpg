extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=true
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="da607ee25b60d74d0866b3672c8fd1d4d4cafc96ad48e2f9b7aaf1c0e3b563c6"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
