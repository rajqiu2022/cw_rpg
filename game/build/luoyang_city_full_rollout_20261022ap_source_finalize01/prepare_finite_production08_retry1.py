"""Preserve first buffered-only FAIL; constrain binding replacement to named leaf."""
from pathlib import Path
import hashlib
base=Path(__file__).with_name('prepare_finite_production08.py')
raw=base.read_bytes()
text=raw.decode()
old="bindhs=[{'old':bind0['source_delta'][p],'new':s} for p,s in bindupdates.items()]"
new="bindhs=[{'old':json.dumps(p)+': '+json.dumps(bind0['source_delta'][p]),'new':json.dumps(p)+': '+json.dumps(s)} for p,s in bindupdates.items()]"
assert text.count(old)==1
text=text.replace(old,new)
exec(compile(text,str(base)+'#retry1-named-source-delta-only','exec'))
