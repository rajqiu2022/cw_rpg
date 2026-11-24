"""NEW oracle text-only safety successor: no Dictionary method/key ambiguity."""
from pathlib import Path
import json,hashlib,copy,difflib
Q=Path(__file__).resolve().parent
old=Q/'market_mask_prior26_final_source_NOTREADY'
new=Q/'market_mask_prior26_explicit_keys_NOTREADY'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def emit(p,v):
    assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes((json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode())
    return sha(p)
keyold=old/'oracle_NOTREADY.gd';fxold=old/'fixture_NOTREADY.json'
assert sha(keyold)=='8f67a8b4d50090bd7da9f4daa147df80378557ecddab23fb8413e508f0774393'
assert sha(fxold)=='0a76d13511739ae2060e9f289ff2ca843f4e7ec65c14afaa757eacfb168762f8'
fx=json.loads(fxold.read_bytes());original=copy.deepcopy(fx)
new.mkdir(parents=True,exist_ok=True)
project=new/'project.godot';project.write_bytes((old/'project.godot').read_bytes())
assert fx['source_sha256'].pop((old/'project.godot').as_posix())==sha(project)
fx['source_sha256'][project.as_posix()]=sha(project)
fxsha=emit(new/'fixture_NOTREADY.json',fx)
restored=copy.deepcopy(fx);restored['source_sha256'].pop(project.as_posix());restored['source_sha256'][(old/'project.godot').as_posix()]=sha(project)
assert restored==original
source=keyold.read_bytes()
ops=[
 ((old/'fixture_NOTREADY.json').as_posix().encode(),(new/'fixture_NOTREADY.json').as_posix().encode()),
 (sha(fxold).encode(),fxsha.encode()),
 ((old/'output_NOTREADY').as_posix().encode(),(new/'output_NOTREADY').as_posix().encode()),
 (b'row.size',b'row["size"]'),
 (b'not negative.clear',b'negative.get("clear")==false'),
 (b'positive.clear',b'positive.get("clear")==true')]
counts=[]
for before,after in ops:
    count=source.count(before);assert count>0
    counts.append(count);source=source.replace(before,after)
inverse=source
for (before,after),count in zip(reversed(ops),reversed(counts)):
    assert inverse.count(after)==count
    inverse=inverse.replace(after,before)
assert inverse==keyold.read_bytes()
key=new/'oracle_NOTREADY.gd';key.write_bytes(source)
diff=new/'complete_vs_final_source_NOTREADY.diff';diff.write_bytes(''.join(difflib.unified_diff(keyold.read_text().splitlines(True),source.decode().splitlines(True),fromfile=str(keyold),tofile=str(key))).encode())
proof={'status':'HARDFALSE_ORACLE_EXPLICIT_DICTIONARY_KEYS_NOT_RUN','key_sha256':sha(key),'fixture_sha256':fxsha,'project_sha256':sha(project),'source_author_28B2_input3933_modelF484_and_all_pixel_expectations_unchanged':True,'exact6replacementgroups_counts':counts,'wholebyte_inverse_to_8F67':True,'fixture_only_samebytes_project_guard_path':True,'semantic_intent':'Explicit dictionary size key lookup and clear boolean .get avoids collisions with builtin Dictionary.size/clear methods; no algebra/PIP/points/source/threshold/budget changes. First3 groups are paths/SHA/output. All old candidates preserved.','native_or_Python_PIP_or_PNG_execution':0}
print('KEY',sha(key),'FIXTURE',fxsha,'PROJECT',sha(project),'PROOF',emit(new/'explicit_keys_inverse_NOTREADY.json',proof))
