"""Nested BUILD tools need one extra GAME parent; preserve first prep refusal."""
from pathlib import Path
import hashlib,json
B=Path(__file__).resolve().parent/'market_mask_import01'
def sha(raw):return hashlib.sha256(raw).hexdigest()
old=(B/'prepare_isolate_NOTENGINE.py').read_bytes();assert sha(old)=='136cb47a398a7fd782b70ebf8d2347cbedbf705db744ba9a6d01b159a6d685d6'
a=b'GAME=HERE.parents[1]';b=b'GAME=HERE.parents[2]'
assert old.count(a)==1
new=old.replace(a,b,1);assert new.replace(b,a,1)==old
p=B/'prepare_isolate02_NOTENGINE.py';assert not p.exists();p.write_bytes(new)
cfg=json.loads((B/'input_ROOT_PREPARE.json').read_bytes());cfg['required_builder_sha256']=sha(new)
ip=B/'input_ROOT_PREPARE02.json';assert not ip.exists();ip.write_bytes((json.dumps(cfg,ensure_ascii=False,indent=2)+'\n').encode())
game=B.parents[2];assert game.name=='game' and (game/'data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import').is_file()
assert (game.parent/'assets/staging/luoyang_market_blocks_mask_20261024e_import01').exists() is False
print(json.dumps(dict(builder=p.as_posix(),builder_sha256=sha(new),input=ip.as_posix(),input_sha256=sha(ip.read_bytes()),GAME=game.as_posix(),wholebyte_inverse=True,preserved_first_preparation='FileNotFound before isolate creation;0engine/0mainwrite')))
