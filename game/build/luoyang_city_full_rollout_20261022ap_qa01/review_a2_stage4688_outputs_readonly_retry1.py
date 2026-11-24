"""Retain zero-output reviewer KeyError; add exact $pin index decoding only."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_a2_stage4688_outputs_readonly.py')
raw=p.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='a6d04cc52c3a0685fda5f500b3818b5922d2abc79c23024be338c9c17c946429'
old="                ref=r['nodes'][new['$sha']];new=ref['disabled_sha256'] if new.get('variant')=='disabled' else ref['sha256']"
new="                if set(new)=={'$pin'}:new=pins[new['$pin']]['sha256']\n                else:\n                    ref=r['nodes'][new['$sha']];new=ref['disabled_sha256'] if new.get('variant')=='disabled' else ref['sha256']"
s=raw.decode();assert s.count(old)==1;s=s.replace(old,new)
oldout='artisan_a2_stage4688_independent_output_inverse_review_READY.json'
assert s.count(oldout)==1
s=s.replace(oldout,'artisan_a2_stage4688_retry1_independent_output_inverse_review_READY.json')
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
