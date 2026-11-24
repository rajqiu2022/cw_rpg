"""Keep zero-output QA token false-match; distinguish label from API use."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_numeric_leaf3F00_typedkeyC716_static.py');b=p.read_bytes()
assert hashlib.sha256(b).hexdigest()=='7f28495549f1d119174eaafbFad60086619a973245c4e6af22bb2d4ad561acd5'.lower()
s=b.decode();old="['ResourceLoader','SceneScript','go_field'";new="['ResourceLoader.','SceneScript','go_field'"
assert s.count(old)==1;s=s.replace(old,new)
old='numeric_leaf3F00_typedkeyC716_independent_static_review_READY.json';new='numeric_leaf3F00_typedkeyC716_retry1_independent_static_review_READY.json'
assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
