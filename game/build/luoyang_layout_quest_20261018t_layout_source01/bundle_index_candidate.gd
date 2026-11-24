extends RefCounted
## Compiler replaces this EMPTY, disabled bootstrap with exact output hashes.
## Not an alternate approved index and never safe to activate as-is.
const FORMAL_ENABLED=false
const ENTRIES={}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
