"""NEW fixes only review guard spelling: actual is 'or scene.scene_id', not 'if'."""
from pathlib import Path
QA=Path(__file__).resolve().parent
P=QA/'review_artisan_a2_runtime_draft03_static.py'
s=P.read_text(encoding='utf-8')
a="assert 'if scene.scene_id!=&\"luoyang_artisan_residential_20261022ap\"' in method(env,'_attach_a2_exact_material')"
b="assert 'or scene.scene_id!=&\"luoyang_artisan_residential_20261022ap\"' in method(env,'_attach_a2_exact_material')"
assert s.count(a)==1
s=s.replace(a,b).replace('artisan_a2_runtime_draft03_independent_semantic_review_READY.json','artisan_a2_runtime_draft03_retry1_independent_semantic_review_READY.json')
exec(compile(s,str(P),'exec'),{'__file__':str(P),'__name__':'static_guard_spelling_retry1'})
