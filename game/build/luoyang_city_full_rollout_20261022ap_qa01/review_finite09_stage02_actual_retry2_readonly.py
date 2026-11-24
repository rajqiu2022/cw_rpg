"""Preserve both prior report-tool failures; decode $pin and select the four declared map nodes only."""
from pathlib import Path
p=Path(__file__).with_name('review_finite09_stage02_actual_readonly.py')
raw=p.read_text(encoding='utf-8')
changes=[('    return x\n',"    if isinstance(x,dict) and set(x)=={'$pin'}:return pins[x['$pin']]['sha256']\n    return x\n"),
 ("    if scene['id'].startswith('ch4_s'):\n","    if 'expected_'+scene['id']+'_true' in nodes:\n")]
patched=raw
for old,new in changes:
    assert patched.count(old)==1;patched=patched.replace(old,new)
back=patched
for old,new in reversed(changes):back=back.replace(new,old)
assert back==raw
exec(compile(patched,str(p),'exec'),{'__file__':str(p),'__name__':'__main__'})
