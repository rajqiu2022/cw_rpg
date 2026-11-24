extends RefCounted
## Separate activation authority; Root alone promotes after source/art admission.
const FORMAL_ENABLED := false
static func formal_enabled() -> bool:
	return FORMAL_ENABLED
