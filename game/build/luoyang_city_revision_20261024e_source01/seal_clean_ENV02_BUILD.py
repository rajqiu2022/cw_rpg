"""Only final clean-floor ENV receives the already sealed runtime literals."""
from pathlib import Path
import json,hashlib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024e_source01/';N='res://build/luoyang_city_blocks_20261024e_system01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower();return b
f=json.loads(read(S+'runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad'))
p=N+'ENV_blocks04_clean_base_NOTREADY.gd';h='5213d9eb2cb92da64a396004a0926fd124e466242724a580006179bacf7172a3';before=read(p,h);after=before
ops=[dict(old=N+'market_block_session09_NOTREADY.gd',new=f['runtime']['candidate']['path']),dict(old='8d8b935de6cf9d9a1fdc811644133787c8c965428c7cc2c1b4ddadac6cecf976',new=f['runtime']['candidate']['sha256']),dict(old='const MARKET_SPACE_READY=false',new='const MARKET_SPACE_READY=true')]
for r in ops:
    a,b=r['old'].encode(),r['new'].encode();assert after.count(a)==1;after=after.replace(a,b,1)
v=after
for r in reversed(ops):
    a,b=r['old'].encode(),r['new'].encode();assert v.count(b)==1;v=v.replace(b,a,1)
assert v==before
out=HERE/'clean_ENV02_READY';assert not out.exists();out.mkdir();prefix=S+'clean_ENV02_READY/'
with (out/'ENV_READY.gd').open('xb') as stream:stream.write(after)
report=dict(parent=dict(path=p,sha256=h),candidate=dict(path=prefix+'ENV_READY.gd',sha256=sha(after),bytes=len(after)),hunks=ops,wholebyte_forward_inverse=True,no_new_functionality=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
raw=enc(report)
with (out/'whole_inverse_NOT_STAGE.json').open('xb') as stream:stream.write(raw)
print(json.dumps(dict(proof_path=prefix+'whole_inverse_NOT_STAGE.json',proof_sha256=sha(raw),candidate=report['candidate'])))
