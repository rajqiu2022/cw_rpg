"""Root-authorized single success-tail line; old paired memory semantics retained."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent;GAME=ROOT.parent.parent
OUT=ROOT/'exact_market_artisan_resident_candidate05';OUT.mkdir(exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return 'res://'+str(p.relative_to(GAME)).replace('\\','/')
parent=ROOT/'exact_market_artisan_resident_candidate04_retry1/Router_exact_market_artisan_resident_READY.gd'
old=parent.read_bytes();assert sha(old)=='7c65d2d1e7eee99b9f0d2f9418428382545ed49c9fc13f883ae0beb376acab2d'
before=b'\troom.call("resident_discard"); room.free()\n'
assert old.count(before)==1
after=b'\tif _resident_city.excursion_kind=="ap_artisan": _portal_return_spawns[_portal_route_key(context.target,context.source_id)]=context.source_spawn\n'+before
new=old.replace(before,after,1);assert new.replace(after,before,1)==old
p=OUT/'Router_exact_market_artisan_resident_READY.gd';assert not p.exists();p.write_bytes(new)
receipt={'status':'NEW_BUILD_ONLY_ROOT_PREAUTHORIZED_ONE_SUCCESS_TAIL_LINE','candidate':{'path':rp(p),'sha256':sha(new),'bytes':len(new)},'parent':{'path':rp(parent),'sha256':sha(old)},'whole_byte_inverse':True,'old':before.decode(),'new':after.decode(),'root_approved_scope':'Only new ap_artisan successful warm tail writes original bound author source_spawn2816,1740 to Market->Artisan paired memory; never actual off-center feet; room/world branch untouched. Original7C65/84CEE/FEF approval preserved as predecessor. No earlier function reparse claim.','prior_handoff':{'path':rp(ROOT/'unified_runtime_visual_finish_candidates_v2_READY.json'),'sha256':'84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee'}}
r=OUT/'handoff_READY.json';assert not r.exists();r.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'candidate':receipt['candidate'],'receipt':{'path':rp(r),'sha256':sha(r.read_bytes())}},indent=2))
