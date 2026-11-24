"""Preserve zero-output QA schema mismatch; binding_byte_hunks is exact1 array."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_performance05_dependency2140_readonly_READY.py');raw=p.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='c9ae23449ba78190b1a4df88f3cd4585bcba520d747a56c6b3e92d6518bfb568'
s=raw.decode();old="edit=d['binding_byte_hunks'];assert isinstance(edit,dict) and ob.count(edit['old'].encode())==1";new="assert isinstance(d['binding_byte_hunks'],list) and len(d['binding_byte_hunks'])==1\nedit=d['binding_byte_hunks'][0];assert isinstance(edit,dict) and ob.count(edit['old'].encode())==1"
assert s.count(old)==1;s=s.replace(old,new)
oldout='performance05_dependency2140_independent_whole_inverse_review_READY.json';assert s.count(oldout)==1
s=s.replace(oldout,'performance05_dependency2140_retry1_independent_whole_inverse_review_READY.json')
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__readonly_retry1__'})
