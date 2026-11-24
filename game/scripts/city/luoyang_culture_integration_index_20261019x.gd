extends RefCounted
## Activation authority is separate from the frozen coordinator implementation.
const FORMAL_ENABLED := true
static func formal_enabled() -> bool:
	return FORMAL_ENABLED
