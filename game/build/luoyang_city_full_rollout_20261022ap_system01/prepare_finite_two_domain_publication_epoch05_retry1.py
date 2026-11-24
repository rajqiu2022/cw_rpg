"""Preserve preparation FAIL; BASE declaration comes from fixed9AACE map."""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parent
p=root/'prepare_finite_two_domain_publication_epoch05.py'
before=p.read_bytes();text=before.decode('utf-8')
old="    expected=(author['source_sha256'][res(p)] if p==parent_path else report['source_first'][res(p)])"
new="    if p==parent_path:\n        expected=author['source_sha256'][res(p)]\n    elif p==base:\n        declaration=next(r for r in data['declared_stage_maps'] if r['path'].endswith('/ch4_s3_luoyang_market_true.json'))\n        assert sha(path(declaration['path']))==declaration['sha256']\n        expected=load(path(declaration['path']))['source_sha256'][res(p)]\n    else:\n        expected=report['source_first'][res(p)]"
assert text.count(old)==1
text=text.replace(old,new)
old="    'source_algorithm':'Vector2 float32 operations in original expression order, sourceRect.end before source transform; nativeRect.end=derivedlow+size, not center+half.',"
new=old+"\n    'BASE_source_declaration':'Fixed9AACE Market expected map, already exact-pinned inside7B1D input; BASE is not itself a17536 direct source_first leaf. No current observed hash used as expected.',"
assert text.count(old)==1
text=text.replace(old,new)
exec(compile(text,str(p),'exec'),{'__file__':str(Path(__file__)),'__name__':'__main__'})
assert p.read_bytes()==before
