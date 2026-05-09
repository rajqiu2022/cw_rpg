from pathlib import Path
import json
from PIL import Image, ImageEnhance

root = Path("f:/Code/RPG_GAME")
base = root / "assets/raw/ui/cold_wuxia/v2"
outputs = [
    ("ui_cold_wuxia_main_menu_screen_gpt_v5", "ui_cold_wuxia_main_menu_screen_gpt_v6"),
    ("ui_cold_wuxia_field_hud_screen_gpt_v1", "ui_cold_wuxia_field_hud_screen_gpt_v2"),
    ("ui_cold_wuxia_inventory_screen_gpt_v1", "ui_cold_wuxia_inventory_screen_gpt_v2"),
    ("ui_cold_wuxia_equipment_screen_gpt_v1", "ui_cold_wuxia_equipment_screen_gpt_v2"),
    ("ui_cold_wuxia_quest_screen_gpt_v1", "ui_cold_wuxia_quest_screen_gpt_v2"),
    ("ui_cold_wuxia_skill_screen_gpt_v1", "ui_cold_wuxia_skill_screen_gpt_v2"),
]

for src_id, dst_id in outputs:
    src = base / f"{src_id}.png"
    dst = base / f"{dst_id}.png"
    if not src.exists():
        raise FileNotFoundError(src)

    img = Image.open(src).convert("RGB")
    img = ImageEnhance.Brightness(img).enhance(1.20)
    img = ImageEnhance.Contrast(img).enhance(1.03)
    img.save(dst, "PNG", optimize=True)

    meta_src = base / f"{src_id}.meta.json"
    meta = {}
    if meta_src.exists():
        try:
            meta = json.loads(meta_src.read_text(encoding="utf-8"))
        except Exception:
            meta = {}

    meta_out = {
        "id": dst_id,
        "derived_from": str(src),
        "adjustment": "brightness +20%, contrast +3%",
        "source_meta": str(meta_src) if meta_src.exists() else "",
        "base_model": meta.get("model", "gpt-image-2"),
        "base_prompt_id": meta.get("id", src_id),
        "note": "在保留 gpt-image-2 原始构图和风格基础上做整体提亮版本。",
    }
    (base / f"{dst_id}.meta.json").write_text(json.dumps(meta_out, ensure_ascii=False, indent=2), encoding="utf-8")

src_main = base / "ui_cold_wuxia_main_menu_screen_gpt_v6.png"
dst_main = root / "game/art/backgrounds/bg_main_menu_gpt_v6.png"
dst_main.write_bytes(src_main.read_bytes())

print("generated bright UI set:")
for _, dst_id in outputs:
    print(base / f"{dst_id}.png")
print(dst_main)
