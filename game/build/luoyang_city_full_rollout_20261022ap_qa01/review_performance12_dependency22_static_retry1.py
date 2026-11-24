"""Preserve QA zero-output failure; match frozen UTF8 JSON serialization."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_performance12_dependency22_static.py');b=p.read_bytes()
assert hashlib.sha256(b).hexdigest()=='613bb39f1f69d2ac2451e8149f40b11149c3585279cea90f7ca28e1257ec189e'
s=b.decode();old='json.dumps(back,indent=2)';new='json.dumps(back,indent=2,ensure_ascii=False)'
assert s.count(old)==1;s=s.replace(old,new)
old='performance12_Bonly_executionA816_scope22_independent_static_review_READY.json';new='performance12_Bonly_executionA816_scope22_retry1_independent_static_review_READY.json'
assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
