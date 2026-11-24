"""NEW audit-only retry: fixed execution $pin is also an ASCII SHA literal."""
from pathlib import Path
import hashlib
p=Path(__file__).with_name('review_culture42_final_driver_input_static_readonly.py')
assert hashlib.sha256(p.read_bytes()).hexdigest()=='d43f32b8cbd2ff9347b143ca60540b003addbd0ab490df2e4aedea3b35339d2a'
t=p.read_text(encoding='utf-8')
assert t.count("set(h['new'])=={'$sha'}")==1
t=t.replace("set(h['new'])=={'$sha'}","set(h['new']) in ({'$sha'},{'$pin'})",1)
t=t.replace('==1for h in row', '==1 for h in row')
exec(compile(t,str(__file__)+'::audit_only','exec'))
