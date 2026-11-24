"""NEW narrowly corrected preparation; preserve failed original script.

Only owned Field/Router require the runtime String inverse domain. All six
System candidates still require exact offset-coordinate whole-byte inversion.
No canonical writes, engine, collector or stager.
"""
from pathlib import Path
import hashlib

original = Path(__file__).with_name("prepare_unified_finish_dependencies01.py")
raw = original.read_bytes()
assert hashlib.sha256(raw).hexdigest() == "2a0715a9d4f17b4ea636f17d629b18ec14b01aa51568504dfeb6f94e53fe8ae5"
old = '''    inverse = after.decode("utf-8")
    for hunk in reversed(pieces):
        assert hunk["new"] and inverse.count(hunk["new"]) == 1, ("RUNTIME_UNIQUE_NEW_HUNK", row["canonical"])
        inverse = inverse.replace(hunk["new"], hunk["old"])
    assert inverse.encode("utf-8") == before
    return list(reversed(pieces))'''
new = '''    inverse_bytes = after
    for hunk in reversed(row["offset_byte_hunks"]):
        n = hunk["new_offset"]
        old_bytes = base64.b64decode(hunk["old_b64"])
        new_bytes = base64.b64decode(hunk["new_b64"])
        assert inverse_bytes[n:n + len(new_bytes)] == new_bytes
        inverse_bytes = inverse_bytes[:n] + old_bytes + inverse_bytes[n + len(new_bytes):]
    assert inverse_bytes == before
    if row["canonical"] in [FIELD, ROUTER]:
        inverse = after.decode("utf-8")
        for hunk in reversed(pieces):
            assert hunk["new"] and inverse.count(hunk["new"]) == 1, ("RUNTIME_UNIQUE_NEW_HUNK", row["canonical"])
            inverse = inverse.replace(hunk["new"], hunk["old"])
        assert inverse.encode("utf-8") == before
    return list(reversed(pieces))'''
text = raw.decode("utf-8")
assert text.count(old) == 1
successor = text.replace(old, new)
assert successor.replace(new, old).encode("utf-8") == raw
exec(compile(successor, str(original) + "#retry1", "exec"))
