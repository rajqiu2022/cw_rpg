"""Preserve02 buffered inverse-helper failure; exact recorded byte offsets fix it."""
import hashlib
from pathlib import Path

old_path = Path(__file__).with_name('prepare_portal_clone_and_field_timing02_owner_capture.py')
raw = old_path.read_bytes()
assert hashlib.sha256(raw).hexdigest() == '3a824e757d91b6bde9c469e5179a7fee879a586b73db3cda2d8076585711d0b7'
old = """for row in reversed(operations):
    assert inverse.count(row['new'])==1,row['label']
    inverse=inverse.replace(row['new'],row['old'],1)
assert inverse.encode()==parent
"""
new = """for row in reversed(operations):
    raw_inverse = inverse.encode()
    offset = row['byte_offset_before_this_change']
    newer, older = row['new'].encode(), row['old'].encode()
    assert raw_inverse[offset:offset+len(newer)] == newer, row['label']
    inverse = (raw_inverse[:offset]+older+raw_inverse[offset+len(newer):]).decode()
assert inverse.encode()==parent
"""
source = raw.decode()
assert source.count(old) == 1
source = source.replace(old, new, 1)
assert source.replace(new, old, 1).encode() == raw
exec(compile(source, str(old_path), 'exec'), {'__file__': str(old_path), '__name__': '__main__'})
