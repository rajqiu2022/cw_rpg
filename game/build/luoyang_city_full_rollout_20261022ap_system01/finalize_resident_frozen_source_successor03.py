"""Frozen Market source uses its original pure authored-door foot contract."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent; GAME=ROOT.parent.parent
OUT=ROOT/"exact_market_artisan_resident_candidate03";OUT.mkdir(exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return "res://"+str(p.relative_to(GAME)).replace("\\","/")
parent=ROOT/"exact_market_artisan_resident_candidate02/Router_exact_market_artisan_resident_READY.gd"
old=parent.read_bytes();assert sha(old)=="ce3c26fe6ccd702c703e9a84dd2246e2da577f3766928efb625a8aa3d5d1dabd"
before='''\t\t\tif zone.get("target_spawn_pos")!=expected_target or zone.get("position")!=(expected_pos/LUOYANG_V3.SIZE)*LUOYANG_V3.SIZE or zone.get("is_locked")!=false or zone.get("action")!="" or zone.get("_in_range")!=true: return false
\t\t\tif not zone is Area2D or not (zone as Area2D).get_overlapping_bodies().has(field.get("_player")): return false'''.encode()
after='''\t\t\tif zone.get("target_spawn_pos")!=expected_target or zone.get("position")!=(expected_pos/LUOYANG_V3.SIZE)*LUOYANG_V3.SIZE or zone.get("is_locked")!=false or zone.get("action")!="": return false
\t\t\tif source==AP_LEASE_MARKET:
\t\t\t\t# LoadingManager freezes this source before park. REMOVE-mode physics
\t\t\t\t# overlap can be empty then; use the original exact doorway polygon,
\t\t\t\t# actual player foot and original safe-foot callable, with no radius.
\t\t\t\tif zone.get_script().resource_path!="res://scripts/field/luoyang_v3_exit_zone.gd" or not zone.has_method("can_enter") or not zone.call("can_enter"): return false
\t\t\telse:
\t\t\t\t# Artisan return is checked before LoadingManager freezes the field.
\t\t\t\tif zone.get("_in_range")!=true or not zone is Area2D or not (zone as Area2D).get_overlapping_bodies().has(field.get("_player")): return false'''.encode()
assert old.count(before)==1
new=old.replace(before,after,1);assert new.replace(after,before,1)==old
p=OUT/"Router_exact_market_artisan_resident_READY.gd";assert not p.exists();p.write_bytes(new)
receipt={"status":"NEW_BUILD_ONLY_NO_ENGINE_OR_DEPLOY","candidate":{"path":rp(p),"sha256":sha(new),"bytes":len(new)},"parent":{"path":rp(parent),"sha256":sha(old)},"whole_byte_inverse":True,"old":before.decode(),"new":after.decode(),"cause":"LoadingManager._hold_source_field disables source before async preloads; REMOVE physics invalidates cached overlaps. Only frozen Market source uses its existing v3 can_enter pure geometric doorway+actual-foot+safe-guard method. Artisan return remains live overlap before freeze.","original_contract_sources":[{"path":"res://scripts/field/world_v15_exit_zone.gd","sha256":sha((GAME/"scripts/field/world_v15_exit_zone.gd").read_bytes())},{"path":"res://scripts/field/luoyang_v3_exit_zone.gd","sha256":sha((GAME/"scripts/field/luoyang_v3_exit_zone.gd").read_bytes())},{"path":"res://scripts/autoload/loading_manager.gd","sha256":sha((GAME/"scripts/autoload/loading_manager.gd").read_bytes())}],"prior_handoffs":[{"path":rp(ROOT/"exact_market_artisan_resident_candidate01_retry1/handoff_READY.json"),"sha256":"4db3a365226fd8ac03956d0948d667b636a6c4a526ad54acb86fa346d9a4fb2a"},{"path":rp(ROOT/"exact_market_artisan_resident_candidate02/handoff_READY.json"),"sha256":"832796a68257c991d842efcb40fb208cee5e38561dd1af70212f3eb757c00d25"}],"lease_unchanged":{"path":rp(ROOT/"exact_market_artisan_resident_candidate01_retry1/Resident_exact_market_artisan_READY.gd"),"sha256":"faf38e53113431c77a85c3a4068437007c07aa85ef44fb37665704a66aa1e9b4"}}
r=OUT/"handoff_READY.json";assert not r.exists();r.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"candidate":receipt["candidate"],"receipt":{"path":rp(r),"sha256":sha(r.read_bytes())}},indent=2))
