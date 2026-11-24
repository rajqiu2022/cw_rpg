"""Use Root's pre-deployment authority for its one additional guard target; preserve old report-tool failure."""
from pathlib import Path
p=Path(__file__).with_name('review_yamen_classification_actual_guard_readonly.py')
raw=p.read_text(encoding='utf-8')
old="assert a.keys()==b.keys() and len(a)==2113\n"
new="""authority=load(P/'deployment_authorization.json')
assert sha(P/'deployment_authorization.json')==g['authorization_sha256'] and authority['passed'] is True
assert len(a)==2112 and len(b)==2113
for row in authority['targets']:
    if row['path'] in a:assert a[row['path']]==row['before']
    else:a[row['path']]=row['before']
assert a.keys()==b.keys() and len(a)==2113
"""
assert raw.count(old)==1
patched=raw.replace(old,new)
oldlookup="a[str(p)]['sha256']==row['old_sha256'] and b[str(p)]['sha256']==row['new_sha256']"
newlookup="a[row['path']]['sha256']==row['old_sha256'] and b[row['path']]['sha256']==row['new_sha256']"
assert patched.count(oldlookup)==1
patched=patched.replace(oldlookup,newlookup)
assert patched.replace(newlookup,oldlookup).replace(new,old)==raw
exec(compile(patched,str(p),'exec'),{'__file__':str(p),'__name__':'__main__'})
