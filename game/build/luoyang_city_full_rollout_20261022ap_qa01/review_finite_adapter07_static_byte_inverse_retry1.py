"""Keep original read-only assertion FAIL; fix only JSON null error representation."""
from pathlib import Path
import hashlib

path = Path(__file__).with_name("review_finite_adapter07_static_byte_inverse.py")
raw = path.read_bytes()
assert hashlib.sha256(raw).hexdigest() == "5f207b4312867d4e2e590106dd519c853c63ec39010e53f44f2927ba976a5353"
old = b'media["passed"] is True and media["error"] == "" and len(media["copied"]) == 4'
new = b'media["passed"] is True and media["error"] is None and len(media["copied"]) == 4'
assert raw.count(old) == 1
code = raw.replace(old, new, 1)
assert code.replace(new, old, 1) == raw
exec(compile(code, str(path) + "[json-null-only-retry1]", "exec"), {"__file__": str(path), "__name__": "__main__"})
