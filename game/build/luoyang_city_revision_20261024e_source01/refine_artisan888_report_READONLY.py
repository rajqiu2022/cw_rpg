"""One wording-only report successor, no repeated PNG or geometry work."""
from pathlib import Path
import hashlib
B=Path(__file__).resolve().parent
old=B/'paper_artisan888_local_model_READONLY.json'
raw=old.read_bytes();assert hashlib.sha256(raw).hexdigest()=='ba74402293173da95190ccce2d960cbca885fa6ea6cd943a42edd9706bccb3ea'
a=b'all raw/native4 artifacts and147? no new raster';b=b'all raw/native4 artifacts; no new raster'
assert raw.count(a)==1
new=raw.replace(a,b,1);assert new.replace(b,a,1)==raw
out=B/'paper_artisan888_local_model02_READONLY.json';assert not out.exists();out.write_bytes(new)
print(str(out));print(hashlib.sha256(new).hexdigest())
