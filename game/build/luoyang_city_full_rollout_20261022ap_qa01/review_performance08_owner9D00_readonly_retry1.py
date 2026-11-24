"""Preserve zero-output QA selector failure; identify expected-map nodes exactly."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_performance08_owner9D00_readonly.py')
b=p.read_bytes();assert hashlib.sha256(b).hexdigest()=='f8fb610ad4c53e2ec0f9964d5566adfa7dc5a0368cd3410a9e167be9bdea6a53'
s=b.decode()
old="node=next(n for n in stage['nodes'].values()if isinstance(n.get('value'),dict)and n['value'].get('scene_id')==sid)"
new="node=next(n for ident,n in stage['nodes'].items()if ident.startswith('expected_ch4_')and n['value']['scene_id']==sid)"
assert s.count(old)==1;s=s.replace(old,new)
old='performance08_owner9D00_independent_fixed1292_recipe_review_READY.json';new='performance08_owner9D00_retry1_independent_fixed1292_recipe_review_READY.json'
assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
