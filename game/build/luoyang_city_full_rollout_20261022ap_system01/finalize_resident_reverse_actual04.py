"""Keep authored source argument; independently validate actual Artisan feet."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent;GAME=ROOT.parent.parent
OUT=ROOT/'exact_market_artisan_resident_candidate04';OUT.mkdir(exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return 'res://'+str(p.relative_to(GAME)).replace('\\','/')
parent=ROOT/'exact_market_artisan_resident_candidate03/Router_exact_market_artisan_resident_READY.gd'
old=parent.read_bytes();assert sha(old)=='9d80b90198fa4b0a3a78c1f81e44e46d06a8e97503819cb2b39895398aecd1e3'
before=b'\t\tvar expected_source: Vector2=Vector2(2816,1740)/LUOYANG_V3.SIZE\n'
after=before+b'\t\tvar actual_source: Vector2=source_node.call("resident_actual_spawn") if is_instance_valid(source_node) else Vector2(INF,INF)\n\t\tif not actual_source.is_finite() or not AP_QUARTERS.safe_body(AP_LEASE_ARTISAN,actual_source*LUOYANG_V3.SIZE): _resident_city.release("AP_ARTISAN_ACTUAL_FEET_UNSAFE");return false\n'
assert old.count(before)==1
new=old.replace(before,after,1);assert new.replace(after,before,1)==old
p=OUT/'Router_exact_market_artisan_resident_READY.gd';assert not p.exists();p.write_bytes(new)
receipt={'status':'NEW_BUILD_ONLY_NO_ENGINE_OR_DEPLOY','candidate':{'path':rp(p),'sha256':sha(new),'bytes':len(new)},'parent':{'path':rp(parent),'sha256':sha(old)},'whole_byte_inverse':True,'old':before.decode(),'new':after.decode(),'contract':'Author-bound source_portal_spawn stays2816,1740 UV; actual Artisan player feet separately finite/AP safe/live Area overlap. Legal off-center2816,1744 supported, return Market1100,1860 unchanged. Field A148 unchanged.','original_sources':[{'path':'res://scripts/field/field_walkable_controller.gd','sha256':sha((GAME/'scripts/field/field_walkable_controller.gd').read_bytes()),'lines':'1950-1951 author bind;3843-3863 only revision-room actual override'}],'parent_handoff':{'path':rp(ROOT/'exact_market_artisan_resident_candidate03/handoff_READY.json'),'sha256':'4c3794e19f339fb7829a46bead0ade09e7198278c9302c525f4362068df0b231'}}
r=OUT/'handoff_READY.json';assert not r.exists();r.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'candidate':receipt['candidate'],'receipt':{'path':rp(r),'sha256':sha(r.read_bytes())}},indent=2))
