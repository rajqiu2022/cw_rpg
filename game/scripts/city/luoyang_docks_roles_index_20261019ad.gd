extends RefCounted
## Root-owned authority; no formal hook is installed by creating this file.
const FORMAL_ENABLED := true
const MANIFEST_SHA := "d9d88a52373d779c33aba2a1280593b03ff128abe4f1e770751b73a7b750bb84"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func manifest_sha256() -> String: return MANIFEST_SHA
