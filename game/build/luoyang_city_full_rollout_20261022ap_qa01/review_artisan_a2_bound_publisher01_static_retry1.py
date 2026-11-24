"""NEW retry only corrects the reviewer's three literal placeholder names."""
from pathlib import Path
QA=Path(__file__).resolve().parent
P=QA/'review_artisan_a2_bound_publisher01_static.py'
s=P.read_text(encoding='utf-8')
a="expected_final=template.read_bytes().replace(b'const READY=false',b'const READY=true').replace(b'__INPUT_SHA__',sha(inp).encode())"
b="expected_final=template.read_bytes().replace(b'const READY=false',b'const READY=true').replace(b'const INPUT=\"PENDING_INPUT\"',b'const INPUT=\"res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/input_READY.json\"').replace(b'const INPUT_SHA=\"PENDING_SHA\"',b'const INPUT_SHA=\"'+sha(inp).encode()+b'\"')"
assert s.count(a)==1
s=s.replace(a,b).replace('artisan_a2_bound_publisher01_independent_static_review_READY.json','artisan_a2_bound_publisher01_retry1_independent_static_review_READY.json')
exec(compile(s,str(P),'exec'),{'__file__':str(P),'__name__':'retry1_static_review'})
