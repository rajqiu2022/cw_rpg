"""No engine/network/image-write/source-write preflight. Not visual acceptance."""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HOME = ROOT / "game/build/city_navigation_minimap_20261101d_candidate01"

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

checks = []
def check(label, condition):
    checks.append({"check": label, "passed": bool(condition)})
    if not condition:
        raise AssertionError(label)

author_path = ROOT / "game/build/luoyang_pawnshop_repair_20261026a_system01/services_author02_CANDIDATE.json"
runtime_path = ROOT / "game/build/luoyang_city_finish_20261025i_source01/pawnshop_only_repair01/unified22_READY01/services_runtime_READY.gd"
check("CURRENT_SERVICE_AUTHOR_EXACT", sha(author_path) == "44053da474186c16863df81e6c266d21e0815c1af2e6d8d4b1a78d0effe1db1e")
check("CURRENT_SERVICE_RUNTIME_EXACT", sha(runtime_path) == "4c8371436aac631ea36523626a2696e1871f0a29e9db5fb5e1a64116fcb706e8")
author = json.loads(author_path.read_text(encoding="utf-8-sig"))
check("FOUR_REAL_SERVICE_ROLES", sorted(row["role"] for row in author["rooms"].values()) == ["herbal", "inn", "pawn", "smith"])
check("ACTUAL_INN_MEAL_REST", author["fees"] == {"meal": 5, "rest": 20})
media = []
for relative, expected_size in [
    ("art/ui/inventory/icons/icon_potion_sm.png", (64, 64)),
    ("art/props/blacksmith_hammer.png", (128, 128)),
    ("art/ui/inventory/icons/icon_suwusheng_teapot_sm.png", (64, 64)),
    ("art/ui/field_hud/portal_arrow_jade_v1.png", (300, 375)),
]:
    path = ROOT / "game" / relative
    im = Image.open(path)
    check("IMAGE_SIZE:" + relative, im.size == expected_size)
    import_path = Path(str(path) + ".import")
    match = re.search(r'path="(res://[^"\r\n]+\.ctex)"', import_path.read_text(encoding="utf-8-sig"))
    check("IMPORTED_GPU_EXISTS:" + relative, match is not None and (ROOT / "game" / match.group(1)[6:]).is_file())
    media.append({"path":"res://" + relative, "sha256":sha(path), "size":im.size, "alpha_bbox":im.convert("RGBA").getchannel("A").getbbox()})

overlay = (HOME / "mini_marker_overlay.gd").read_text(encoding="utf-8-sig")
semantics = (HOME / "service_semantics.gd").read_text(encoding="utf-8-sig")
check("NO_IMAGE_OR_FILE_WRITE_APIS", not re.search(r"FileAccess\.open|store_|save_png|save_webp|ResourceSaver|Image\.create", overlay + semantics))
check("NO_BUSINESS_OR_PHYSICS_MUTATORS", not re.search(r"go_field|resolve_action|set_flag|set_can_move|move_and_slide|collision_layer\s*=|target_scene_id\s*=", overlay + semantics))
check("REAL_SERVICE_FINALIZED_RECEIPT", '"source_receipt", scene, field' in semantics and 'receipt.get("finalized") != true' in semantics)
check("ONLY_EXACT_SERVICE_NPC_ACTION", 'npc.npc_id != spec.npc_id or npc.interaction_action != "indoor_service25h"' in semantics)
check("NO_DISPLAY_NAME_GUESSING", not re.search(r'"[^"]*(?:shop|inn|herb|smith)[^"]*" in .*name|\.display_name|\.npc_name', semantics))
check("MOUSE_PASSTHROUGH", "mouse_filter = Control.MOUSE_FILTER_IGNORE" in overlay)
check("PORTRAIT_CHILD_ORDER_PRESERVED", "mini.move_child(layer, portrait.get_index())" in overlay)
check("CACHE_NEVER_REQUESTED_OR_REPLACED", "SubViewport.new" not in overlay and 'set("base_texture"' not in overlay)
check("OLD_DOT_LIST_RESTORABLE", 'plan.set("portals", _saved_portals.duplicate(true))' in overlay)
check("11C_GAIT_FREEZE_UNCHANGED", sha(ROOT / "game/build/npc_gait_20261101c_candidate01/source_pins_READY.json") == "9101db3750c99a6c9ceb63ebd5f28f22db850d07b5d3c32ba18827630c8bba85")
print(json.dumps({"passed": True, "checks": checks, "existing_media": media, "engine_run":False, "parser_checked":False, "visual_accepted":False, "writes":0}, ensure_ascii=False, indent=2))
