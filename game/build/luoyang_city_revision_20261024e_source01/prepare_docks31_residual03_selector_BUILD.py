"""Pre-handoff static selector correction; residual02 was never executed."""
from pathlib import Path
import json,hashlib,ast
HERE=Path(__file__).resolve().parent;S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
dp=HERE/'stage_docks_frontages31_residual02_NOTREADY.py';a=dp.read_bytes();assert sha(a)=='53d41702e3c23b74aa95a8469c2c123f33aa3afd099a6bab737d996349859be2'
x=b"maps=[r for r in self.spec['nodes'] if r['kind']=='map']";y=b"maps=[r for r in self.spec['nodes'] if r['kind']=='docks_incremental_map']";assert a.count(x)==1;b=a.replace(x,y);assert b.replace(y,x)==a;ast.parse(b.decode())
driver=HERE/'stage_docks_frontages31_residual03_NOTREADY.py';assert not driver.exists();driver.write_bytes(b)
ip=HERE/'source_input_docks31_residual02_ROOT_REVIEW.json';raw=ip.read_bytes();assert sha(raw)=='08f87550f23806f1e0fee0074e1d4e8ec902f27cc81bb316f71941d8959fb938';spec=json.loads(raw)
oldgen=spec['required_generator'];oldroot=spec['output_root'];newgen=dict(path=S+driver.name,sha256=sha(b));newroot=S+'outputs/root_docks_frontages_exact31_stage03/'
c=raw
for old,new in [(oldgen['path'],newgen['path']),(oldgen['sha256'],newgen['sha256']),(oldroot,newroot)]:
    assert c.count(old.encode())==1;c=c.replace(old.encode(),new.encode())
value=json.loads(c);spec['required_generator']=newgen;spec['output_root']=newroot;assert value==spec
inverse=c
for old,new in reversed([(oldgen['path'],newgen['path']),(oldgen['sha256'],newgen['sha256']),(oldroot,newroot)]):
    assert inverse.count(new.encode())==1;inverse=inverse.replace(new.encode(),old.encode())
assert inverse==raw;inp=HERE/'source_input_docks31_residual03_ROOT_REVIEW.json';assert not inp.exists();inp.write_bytes(c)
proof=dict(status='PREHANDOFF_INCREMENTAL_MAP_SELECTOR_CORRECTION_NOT_EXECUTED',driver=newgen,input=dict(path=S+inp.name,sha256=sha(c)),parent_driver=dict(path=S+dp.name,sha256=sha(a)),parent_input=dict(path=S+ip.name,sha256=sha(raw)),driver_exact_hunk=dict(old=x.decode(),new=y.decode()),input_only_generator_and_outputroot=True,input_exact_replacements=[dict(old=o,new=n) for o,n in [(oldgen['path'],newgen['path']),(oldgen['sha256'],newgen['sha256']),(oldroot,newroot)]],whole_byte_forward_inverse=True,residual02_NOTRUN=True,original_map_equality_proof=dict(path=S+'docks31_residual02_whole_inverse_NOT_EXECUTED.json',sha256='add36839b2c90bc733e2275d11750713f8f64f98458443b6ae161894588f1e1f'),Stage_calls=0)
p=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'docks31_residual03_selector_whole_inverse_NOT_EXECUTED.json';assert not out.exists();out.write_bytes(p)
print(json.dumps(dict(driver=newgen,input=proof['input'],proof=dict(path=S+out.name,sha256=sha(p)))))
