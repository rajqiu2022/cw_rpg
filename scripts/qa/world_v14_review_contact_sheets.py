"""Read-only screenshot review index; never creates an approval verdict.

Original PNGs are unmodified. Contact sheets are diagnostic review aids only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--pattern", default="*.png")
    parser.add_argument("--exclude-index", action="append", type=Path, default=[],
                        help="Previously reviewed contact index; omit only identical raw PNG bytes")
    args = parser.parse_args()
    source = args.source.resolve(strict=True)
    destination = args.destination.resolve()
    if destination.exists():
        raise SystemExit("Refuse to overwrite existing review evidence")
    files = sorted(source.glob(args.pattern))
    excluded = {}
    for prior_path in args.exclude_index:
        prior = json.loads(prior_path.resolve(strict=True).read_text(encoding="utf-8"))
        if prior.get("purpose") != "VISUAL_REVIEW_AID_ONLY_NOT_A_VERDICT" or Path(prior["source"]).resolve() != source:
            raise SystemExit("Exclude index is not a diagnostic index of this screenshot directory")
        for record in prior["images"]:
            key = str(Path(record["path"]).resolve(strict=True))
            if key in excluded and excluded[key] != record["sha256"]:
                raise SystemExit("Contradictory prior screenshot hash")
            excluded[key] = record["sha256"]
    remaining = []
    for path in files:
        key = str(path.resolve(strict=True))
        if key in excluded:
            with path.open("rb") as handle:
                current = hashlib.file_digest(handle, "sha256").hexdigest()
            if current != excluded[key]:
                raise SystemExit("Previously indexed screenshot changed; must be reviewed again")
        else:
            remaining.append(path)
    files = remaining
    if not files:
        raise SystemExit("No screenshots found")
    destination.mkdir(parents=True)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
    width, height, columns, rows = 480, 270, 4, 3
    records = []
    pages = []
    for offset in range(0, len(files), columns * rows):
        page_number = offset // (columns * rows) + 1
        page = Image.new("RGB", (columns * width, rows * (height + 48)), "#151820")
        draw = ImageDraw.Draw(page)
        for slot, path in enumerate(files[offset:offset + columns * rows]):
            with Image.open(path) as original:
                dimensions = list(original.size)
                thumbnail = ImageOps.contain(original.convert("RGB"), (width, height))
            x = (slot % columns) * width
            y = (slot // columns) * (height + 48)
            page.paste(thumbnail, (x + (width - thumbnail.width) // 2, y))
            label = f"{offset + slot + 1:03d} {path.name}"
            draw.text((x + 5, y + height + 3), label[:59], fill="white", font=font)
            if len(label) > 59:
                draw.text((x + 5, y + height + 23), label[59:], fill="white", font=font)
            with path.open("rb") as handle:
                digest = hashlib.file_digest(handle, "sha256").hexdigest()
            records.append({"index": offset + slot + 1, "path": str(path),
                            "sha256": digest,
                            "dimensions": dimensions, "contact_page": page_number})
        page_path = destination / f"page_{page_number:03d}.png"
        page.save(page_path)
        pages.append(str(page_path))
    report = {"purpose": "VISUAL_REVIEW_AID_ONLY_NOT_A_VERDICT", "source": str(source),
              "original_images_unmodified": True, "image_count": len(files),
              "pages": pages, "images": records}
    (destination / "index.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"images": len(files), "pages": len(pages), "destination": str(destination)}))


if __name__ == "__main__":
    main()
