"""Exact existing domains: index $pin and the four specific historical T leaves."""
from pathlib import Path
import hashlib
p=Path(__file__).with_name('review_culture42_final_driver_input_static_readonly.py')
assert hashlib.sha256(p.read_bytes()).hexdigest()=='d43f32b8cbd2ff9347b143ca60540b003addbd0ab490df2e4aedea3b35339d2a'
t=p.read_text(encoding='utf-8')
t=t.replace("set(h['new'])=={'$sha'}","set(h['new']) in ({'$sha'},{'$pin'})",1)
t=t.replace('==1for h in row', '==1 for h in row')
old="four=[k for k in rt if k.startswith(T)]\nck(len(four)==4 and not any(k.startswith(T)for k in lg),'all4T native/header leaves remain runtimeauthority')"
new="four=[T+'ch4_s1_luoyang_yamen/'+leaf for leaf in ('layout.res','packet.bin','scene.res','manifest.json')]\nck(all(k in rt and k not in lg for k in four) and not any(k.startswith(T)for k in lg),'all4T native/header leaves remain runtimeauthority')"
assert t.count(old)==1
t=t.replace(old,new,1)
exec(compile(t,str(__file__)+'::audit_only','exec'))
