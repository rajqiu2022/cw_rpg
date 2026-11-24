"""Preserve zero-output QA false assignment match on ==; narrow token test."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_B_DT_performance04_independent_static_READY.py');raw=p.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='adc7319bb9c990b66647e78956187c1fc620de12e64a0580a4dd028a687ccba3'
s=raw.decode();old="'scene.map_layout=' not in pre";new="re.search(r'scene\\.map_layout\\s*=(?!=)',pre) is None"
assert s.count(old)==1;s=s.replace(old,new)
oldout='B77DFC_DT39242C_performance04_independent_static_review_READY.json';assert s.count(oldout)==1
s=s.replace(oldout,'B77DFC_DT39242C_performance04_retry1_independent_static_review_READY.json')
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__readonly_retry1__'})
