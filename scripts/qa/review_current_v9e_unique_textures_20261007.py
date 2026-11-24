"""Diagnostic contact pages only; no approval and no source asset edits."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "game/build/joint_world_luoyang_20261003_qa/art_current_v9d_unique44_texture_review_20261005/representative_registry.json"
DEST = ROOT / "game/build/joint_world_luoyang_20261003_qa/root262_current_v9e_unique44_texture_review"
if DEST.exists():
    raise SystemExit("Refuse to overwrite evidence")
registry = json.loads(REGISTRY.read_text(encoding="utf-8-sig"))
records = []
for group in registry["groups"]:
    path = ROOT / "game" / group["representative"].removeprefix("res://")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest.lower() != group["sha"].lower():
        raise SystemExit(f"Current texture differs from registry: {path}")
    with Image.open(path) as source:
        records.append({"path": str(path), "sha256": digest, "dimensions": list(source.size)})
if len(records) != 44 or len({r["sha256"] for r in records}) != 44:
    raise SystemExit("Expected exactly 44 distinct current textures")
DEST.mkdir()
pages = []
for offset in range(0, len(records), 12):
    page = Image.new("RGB", (1920, 1050), "#44413a")
    draw = ImageDraw.Draw(page)
    for slot, record in enumerate(records[offset:offset + 12]):
        x, y = (slot % 4) * 480, (slot // 4) * 350
        with Image.open(record["path"]) as source:
            thumb = ImageOps.contain(source.convert("RGBA"), (470, 310))
            page.paste(thumb, (x + (480 - thumb.width) // 2, y), thumb)
        draw.text((x + 5, y + 315), f"{offset + slot + 1:02} {Path(record['path']).name}", fill="white")
    target = DEST / f"page_{offset // 12 + 1:03}.png"
    page.save(target)
    pages.append(str(target))
report = {"purpose": "VISUAL_REVIEW_AID_ONLY_NOT_A_VERDICT", "original_images_unmodified": True,
          "registry_sha256": hashlib.sha256(REGISTRY.read_bytes()).hexdigest(), "images": records, "pages": pages}
(DEST / "index.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps({"image_count": len(records), "pages": pages}))
