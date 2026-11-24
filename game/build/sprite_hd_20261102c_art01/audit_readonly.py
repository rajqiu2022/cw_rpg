"""Read-only source pixel audit; emits metadata JSON, never edits an image."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
paths = []
paths += list((ROOT / "game/art/characters/weapon_variants/lengguyun/v7_idle_stable/sword").glob("*.png"))
paths += list((ROOT / "assets/raw/sprite/field/weapon_variants/lengguyun/codex_builtin_v5_stowed").glob("*.png"))
paths += list((ROOT / "assets/raw/sprite/field/weapon_variants/lengguyun/codex_builtin_v6_staff_back").glob("*.png"))
paths += [ROOT / "game/art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png"]
paths += list((ROOT / "assets/raw/sprite_sheet/linxi_farmer").glob("*.png"))
paths += [ROOT / "game/art/characters/street_expansion_v1/npc_street_merchant_walk_down_8f_v1_runtime.png"]
paths += list((ROOT / "assets/raw/character/expansion_20260805").glob("npc_street_merchant*.png"))

records = []
for path in paths:
    if not path.is_file():
        records.append({"path": path.relative_to(ROOT).as_posix(), "missing": True})
        continue
    with Image.open(path) as opened:
        im = opened.convert("RGBA")
        width, height = im.size
        is_raw_atlas = "8x4" in path.name
        columns = 8 if is_raw_atlas else (width // height if width > height and width % height == 0 else 4)
        rows = 4 if is_raw_atlas else 1
        # Uniform requested grid is a diagnostic only, not a crop/adoption.
        boxes = []
        for row in range(rows):
            for column in range(columns):
                cell = im.crop((round(column*width/columns), round(row*height/rows), round((column+1)*width/columns), round((row+1)*height/rows)))
                alpha = cell.getchannel("A")
                boxes.append({"row":row,"column":column,"cell":list(cell.size),"alpha_bbox":alpha.getbbox(),"alpha24_bbox":alpha.point(lambda value:255 if value >= 24 else 0).getbbox()})
        records.append({"path":path.relative_to(ROOT).as_posix(),"size":[width,height],"mode":opened.mode,"alpha_extrema":im.getchannel("A").getextrema(),"inferred_grid":[columns,rows],"cells":boxes})

output = {"scope":"read_only_selected_sources_not_all_npcs", "image_writes":0,"engine_runs":0,"records":records}
(OUT/"source_pixels_READONLY.json").write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
for record in records:
    print(record["path"], record.get("size"), record.get("inferred_grid"), [cell["alpha24_bbox"] for cell in record.get("cells",[])[:4]])
