"""Preserve first review failure; only add missing declared $pin value decoding."""
from pathlib import Path
p=Path(__file__).with_name('review_finite09_stage02_actual_readonly.py')
raw=p.read_text(encoding='utf-8')
old='    return x\n'
new="    if isinstance(x,dict) and set(x)=={'$pin'}:return pins[x['$pin']]['sha256']\n"+old
assert raw.count(old)==1 and new not in raw
patched=raw.replace(old,new)
assert patched.replace(new,old)==raw
exec(compile(patched,str(p),'exec'),{'__file__':str(p),'__name__':'__main__'})
