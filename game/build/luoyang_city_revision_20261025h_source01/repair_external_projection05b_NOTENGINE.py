"""Preserve failed05 preparation; finite AP-header was already classified legacy."""
from pathlib import Path
parent=Path(__file__).with_name('repair_external_projection05_NOTENGINE.py')
text=parent.read_text(encoding='utf-8')
assert text.count('external_projection_residual05')==2
text=text.replace('external_projection_residual05','external_projection_residual05b')
old="c=changes[market];assert value['runtime_authority_sha256'].get(market)==c['old']['sha256'];value['runtime_authority_sha256'][market]=c['new']['sha256']"
new="c=changes[market];assert value['legacy_source_sha256'].get(market)==c['old']['sha256'] and market not in value['runtime_authority_sha256'];value['legacy_source_sha256'][market]=c['new']['sha256']"
assert text.count(old)==1;text=text.replace(old,new)
old="row=next(c for c in r['changes']if c['pointer']==['runtime_authority_sha256',market])"
new="row=next(c for c in r['changes']if c['pointer']==['legacy_source_sha256',market])"
assert text.count(old)==1;text=text.replace(old,new)
exec(compile(text,str(parent),'exec'),dict(__file__=str(parent),__name__='__main__'))
