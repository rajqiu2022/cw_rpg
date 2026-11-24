"""Explicit Callable for a deliberately RefCounted-typed pure-file worker."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
OUT=ROOT/"exact_market_artisan_resident_candidate02"
OUT.mkdir(exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return "res://"+str(p.relative_to(GAME)).replace("\\","/")
parent=ROOT/"exact_market_artisan_resident_candidate01_retry1/Router_exact_market_artisan_resident_READY.gd"
old=parent.read_bytes();assert sha(old)=="b58e939c2ad70912de3fb86e8cb42a7d50ec62706b0c47dde069939dafb98829"
needle=b'WorkerThreadPool.add_task(job.run,false,"Exact AP Market lease complete source SHA")'
replacement=b'WorkerThreadPool.add_task(Callable(job,"run"),false,"Exact AP Market lease complete source SHA")'
assert old.count(needle)==1
new=old.replace(needle,replacement,1)
assert new.replace(replacement,needle,1)==old
path=OUT/"Router_exact_market_artisan_resident_READY.gd";assert not path.exists();path.write_bytes(new)
receipt={"status":"NEW_BUILD_ONLY_NOT_ENGINE_CHECKED","candidate":{"path":rp(path),"sha256":sha(new),"bytes":len(new)},"parent":{"path":rp(parent),"sha256":sha(old)},"old":needle.decode(),"new":replacement.decode(),"whole_byte_inverse":True,"prior_handoff":{"path":rp(ROOT/"exact_market_artisan_resident_candidate01_retry1/handoff_READY.json"),"sha256":"4db3a365226fd8ac03956d0948d667b636a6c4a526ad54acb86fa346d9a4fb2a"},"lease_unchanged":{"path":rp(ROOT/"exact_market_artisan_resident_candidate01_retry1/Resident_exact_market_artisan_READY.gd"),"sha256":"faf38e53113431c77a85c3a4068437007c07aa85ef44fb37665704a66aa1e9b4"},"reason":"Explicit existing run Callable on RefCounted-typed job; no reliance on a statically undeclared member; no worker implementation change."}
r=OUT/"handoff_READY.json";assert not r.exists();r.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"candidate":receipt["candidate"],"handoff":{"path":rp(r),"sha256":sha(r.read_bytes())}},indent=2))
