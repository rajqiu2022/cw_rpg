from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "logs/qa/equipment_icon_audit_20260817.jpg"
QUALITY_COLORS = ["#c0c8d0", "#1eff00", "#4d8fff", "#b56cff", "#ff9b38"]
SLOT_NAMES = ["武器", "头盔", "衣甲", "护手", "鞋子", "饰品"]
SLOT_FALLBACKS = [
    "res://art/ui/inventory/icons/icon_sword.png",
    "res://art/ui/inventory/icons/icon_iron_helmet.png",
    "res://art/ui/inventory/icons/icon_armor.png",
    "res://art/ui/inventory/icons/icon_silk_gloves.png",
    "res://art/ui/inventory/icons/icon_shoes.png",
    "res://art/ui/inventory/icons/icon_ring.png",
]


def field(source: str, key: str, default: str = "") -> str:
    match = re.search(rf'^{re.escape(key)} = "([^"]*)"', source, re.MULTILINE)
    return match.group(1) if match else default


def int_field(source: str, key: str, default: int = 0) -> int:
    match = re.search(rf"^{re.escape(key)} = (\d+)", source, re.MULTILINE)
    return int(match.group(1)) if match else default


def main() -> None:
    font = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 18)
    small = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 14)
    rows = []
    for path in sorted((ROOT / "game/data/equipment").glob("*.tres")):
        source = path.read_text(encoding="utf-8")
        rows.append(
            {
                "name": field(source, "display_name", path.stem),
                "slot": int_field(source, "slot"),
                "quality": int_field(source, "quality"),
                "icon": field(source, "icon_path"),
            }
        )

    columns, cell_w, cell_h = 6, 250, 190
    sheet = Image.new("RGB", (columns * cell_w, ((len(rows) + columns - 1) // columns) * cell_h), (24, 27, 31))
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(rows):
        x, y = (index % columns) * cell_w, (index // columns) * cell_h
        color = QUALITY_COLORS[min(max(row["quality"], 0), len(QUALITY_COLORS) - 1)]
        draw.rectangle((x + 2, y + 2, x + cell_w - 3, y + cell_h - 3), outline=color, width=3)
        resolved_icon = row["icon"] or SLOT_FALLBACKS[row["slot"]]
        icon_path = ROOT / "game" / resolved_icon.removeprefix("res://")
        if icon_path and icon_path.exists():
            icon = Image.open(icon_path).convert("RGBA")
            icon.thumbnail((118, 118), Image.Resampling.LANCZOS)
            sheet.paste(icon, (x + (cell_w - icon.width) // 2, y + 6), icon)
        draw.text((x + 8, y + 128), row["name"], font=font, fill=color)
        mode = "独立图标" if row["icon"] else "槽位回退"
        draw.text((x + 8, y + 157), f"{SLOT_NAMES[row['slot']]} · {mode}", font=small, fill="#9fb0bd")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT, quality=92)
    print(f"EQUIPMENT_ICON_CONTACT_SHEET rows={len(rows)} output={OUTPUT}")


if __name__ == "__main__":
    main()
