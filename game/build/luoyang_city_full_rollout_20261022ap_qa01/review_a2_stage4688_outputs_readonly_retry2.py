"""Preserve QA-only zero-output failures; exact $pin and owner-array schema."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_a2_stage4688_outputs_readonly.py')
raw=p.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='a6d04cc52c3a0685fda5f500b3818b5922d2abc79c23024be338c9c17c946429'
s=raw.decode()
changes=[("                ref=r['nodes'][new['$sha']];new=ref['disabled_sha256'] if new.get('variant')=='disabled' else ref['sha256']", "                if set(new)=={'$pin'}:new=pins[new['$pin']]['sha256']\n                else:\n                    ref=r['nodes'][new['$sha']];new=ref['disabled_sha256'] if new.get('variant')=='disabled' else ref['sha256']"), ("    base=oldowner['scenes'][scene]['source_sha256']", "    base=next(x for x in oldowner['scenes'] if x['id']==scene)['source_sha256']"), ('artisan_a2_stage4688_independent_output_inverse_review_READY.json','artisan_a2_stage4688_retry2_independent_output_inverse_review_READY.json')]
for old,new in changes:
    assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry2__'})
