"""Offline, read-only sprite metrics; visual and atlas-scale approval stay separate."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

STATES = ("ready", "move", "attack", "hit", "defeat")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inspect(directory: Path, prefix: str) -> tuple[dict, list[Image.Image]]:
    expected = [f"{prefix}_{state}_{i:02d}.png" for state in STATES for i in range(1, 5)]
    present = sorted(p.name for p in directory.glob("*.png"))
    errors = []
    if sorted(expected) != present:
        errors.append({"kind": "frame_set", "missing": sorted(set(expected) - set(present)),
                       "extra": sorted(set(present) - set(expected))})
    rows, images, duplicates = [], [], {}
    before = {name: sha(directory / name) for name in present}
    for name in expected:
        path = directory / name
        if not path.is_file():
            continue
        with Image.open(path) as source:
            mode = source.mode
            image = source.convert("RGBA")
        alpha = image.getchannel("A")
        bbox = alpha.getbbox()
        solid = alpha.point(lambda a: 255 if a >= 24 else 0).getbbox()
        row = {"name": name, "sha256": before[name], "mode": mode, "size": list(image.size),
               "bbox_alpha_nonzero": bbox, "bbox_alpha_ge24": solid,
               "alpha_extrema": alpha.getextrema()}
        issues = []
        if mode != "RGBA" or image.size != (512, 384):
            issues.append("requires_RGBA_512x384")
        if bbox is None or solid is None:
            issues.append("empty_sprite")
        else:
            row.update(effective_size=[bbox[2] - bbox[0], bbox[3] - bbox[1]],
                       bottom_margin=image.height - bbox[3],
                       horizontal_center_offset=(bbox[0] + bbox[2] - image.width) / 2)
            if image.height - bbox[3] != 12:
                issues.append("bottom_margin_not_12")
            if abs(row["horizontal_center_offset"]) > 0.5:
                issues.append("not_integer_centered")
            if bbox[0] <= 0 or bbox[1] <= 0 or bbox[2] >= image.width:
                issues.append("content_touches_canvas_boundary")
        if alpha.getextrema()[0] != 0:
            issues.append("no_transparent_background")
        pixels = hashlib.sha256(image.tobytes()).hexdigest()
        duplicates.setdefault(pixels, []).append(name)
        row["issues"] = issues
        errors.extend({"frame": name, "kind": issue} for issue in issues)
        rows.append(row)
        images.append(image)
    repeated = [names for names in duplicates.values() if len(names) > 1]
    errors.extend({"kind": "exact_duplicate_pixels", "frames": names} for names in repeated)
    after = {name: sha(directory / name) for name in present}
    if before != after:
        errors.append({"kind": "tested_source_changed_during_read"})
    return {"scope": "OFFLINE_FRAME_METRICS_NOT_VISUAL_ATLAS_OR_RUNTIME_APPROVAL",
            "directory": str(directory.resolve()), "prefix": prefix, "frame_count": len(rows),
            "machine_checks_ok": not errors, "errors": errors, "frames": rows,
            "exact_pixel_duplicates": repeated, "tested_source_unchanged": before == after,
            "uniform_scale_verified": False, "facing_left_verified": False,
            "species_and_animation_visual_approval": False,
            "model_metadata_verified": False, "runtime_credit": False}, images


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("prefix")
    parser.add_argument("--output", type=Path, help="NEW independent QA directory; refuses existing")
    args = parser.parse_args()
    if args.output is not None:
        target = args.output.resolve()
        source = args.directory.resolve()
        if target == source or source in target.parents:
            parser.error("QA output must not be within tested asset directory")
        if target.exists():
            parser.error("QA output already exists; no overwrite")
    report, images = inspect(args.directory, args.prefix)
    if args.output is not None:
        args.output.mkdir(parents=True, exist_ok=False)
        sheet = Image.new("RGBA", (4 * 512, 5 * 408), (54, 58, 65, 255))
        draw = ImageDraw.Draw(sheet)
        for i, (row, image) in enumerate(zip(report["frames"], images)):
            x, y = (i % 4) * 512, (i // 4) * 408
            sheet.alpha_composite(image, (x, y + 24))
            draw.text((x + 8, y + 5), row["name"], fill="white")
            draw.line((x, y + 24 + 372, x + 511, y + 24 + 372), fill=(125, 155, 175))
        sheet.convert("RGB").save(args.output / "contact_sheet.png")
        (args.output / "metrics.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in report.items() if key != "frames"}, indent=2))
    raise SystemExit(0 if report["machine_checks_ok"] else 1)


if __name__ == "__main__":
    main()
