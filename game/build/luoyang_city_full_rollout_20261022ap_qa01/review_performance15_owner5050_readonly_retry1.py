"""Preserve zero-output typo failure; use Root's exact 64hex review pin."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_performance15_owner5050_readonly.py');b=p.read_bytes()
assert hashlib.sha256(b).hexdigest()=='259dccad113e248c1896eb213a7cfd49cf2239d78ee186a8046138a330ec805e'
s=b.decode();old='4909d6c71a05c35030951366d725dbbb070cdaae55b4b34beba9b681efd829ebc';new='4909d6c71a05c35030951366d725dbb070cdaae55b4b34beba9b681efd829ebc'
assert s.count(old)==2;s=s.replace(old,new)
old='performance15_owner5050_independent_fixed9D004_recipe_review_READY.json';new='performance15_owner5050_retry1_independent_fixed9D004_recipe_review_READY.json'
assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
