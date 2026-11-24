"""Preserve original preparation failure; use exact receipt nodes Dictionary API."""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parent
original=root/'prepare_finite_two_domain_publication_epoch02.py'
before=original.read_bytes()
assert hashlib.sha256(before).hexdigest()=='5081891c9b7de22b7a92d269739ecd137b8960a86d9a0d8da02c14b3442a42ea'
text=before.decode('utf-8')
old="    assert res(p) in declared_stage['source_final'] or any(res(p)==r.get('path') for r in declared_stage.get('nodes',[])) or p.exists()"
new="    declared_node=declared_stage['nodes']['expected_'+scene+'_true']\n    assert declared_node['path']==res(p) and declared_node['sha256']==sha(p)\n    assert declared_node['value']==load(p)"
assert text.count(old)==1
text=text.replace(old,new)
exec(compile(text,str(original),'exec'),{'__file__':str(original),'__name__':'__main__'})
assert original.read_bytes()==before
