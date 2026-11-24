"""Package the four real carrier cells as review-only media.

No pose, interpolation or simulation is created. Each source cell is composited
unchanged onto a neutral checker. The GIF repeats frames 0,1,2,3 at a fixed
duration; the contact sheet keeps original 160px scale and sole baseline.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


EXPECTED_WALK_SHA = "53E331017AE6EACC569D4B35E241557221E151C59135F44C274F8AC0EAC8CA55"
EXPECTED_REPORT_SHA = "2CED8169D001F71C5A409B42AC23C62D6A7BE3C001DB768781E06CFAD514DBD4"
CELL = 160
FRAMES = 4
DURATION_MS = 160
SOLE_Y = 152


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def checker(size: tuple[int, int], tile: int = 10) -> Image.Image:
    image = Image.new("RGB", size, (34, 40, 42))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], tile):
        for x in range(0, size[0], tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, min(x + tile - 1, size[0] - 1), min(y + tile - 1, size[1] - 1)), fill=(43, 49, 51))
    return image


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--walk", type=Path, required=True)
    parser.add_argument("--mechanical-report", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    walk_path = args.walk.resolve()
    report_path = args.mechanical_report.resolve()
    output_dir = args.output_dir.resolve()
    if not walk_path.is_file() or not report_path.is_file():
        raise FileNotFoundError("walk strip and mechanical report must exist")
    if sha256(walk_path) != EXPECTED_WALK_SHA:
        raise ValueError(f"walk SHA mismatch: {sha256(walk_path)}")
    if sha256(report_path) != EXPECTED_REPORT_SHA:
        raise ValueError(f"mechanical report SHA mismatch: {sha256(report_path)}")
    report = json.loads(report_path.read_text(encoding="utf-8"))
    reported_walk = next(row for row in report["outputs"] if row["kind"] == "walk")
    if reported_walk["sha256"] != EXPECTED_WALK_SHA or reported_walk["size_px"] != [640, 160]:
        raise ValueError("mechanical report does not bind the expected 640x160 walk strip")

    walk = Image.open(walk_path)
    walk.load()
    if walk.mode != "RGBA" or walk.size != (CELL * FRAMES, CELL):
        raise ValueError(f"walk must be RGBA 640x160, got {walk.mode} {walk.size}")
    frames: list[Image.Image] = []
    frame_rows: list[dict[str, object]] = []
    for index in range(FRAMES):
        frame = walk.crop((index * CELL, 0, (index + 1) * CELL, CELL))
        bbox = frame.getchannel("A").getbbox()
        if bbox is None or bbox[3] - 1 != SOLE_Y:
            raise ValueError(f"frame {index} does not have actual sole row {SOLE_Y}: {bbox}")
        background = checker((CELL, CELL))
        background.paste(frame, (0, 0), frame)
        frames.append(background)
        frame_rows.append({
            "index": index,
            "source_rect_xyxy_exclusive": [index * CELL, 0, (index + 1) * CELL, CELL],
            "alpha_bbox_xyxy_exclusive": list(bbox),
            "sole_row_y_px": bbox[3] - 1,
        })

    gif_path = output_dir / "carrier_walk_right_4f_mechanical_preview.gif"
    sheet_path = output_dir / "carrier_walk_right_4f_equal_scale_contactsheet.png"
    preview_report_path = output_dir / "carrier_walk_preview_report.json"
    if gif_path.exists() or sheet_path.exists() or preview_report_path.exists():
        raise FileExistsError("refusing to overwrite an existing preview or report")
    output_dir.mkdir(parents=True, exist_ok=True)

    enlarged = [frame.resize((CELL * 3, CELL * 3), Image.Resampling.NEAREST) for frame in frames]
    enlarged[0].save(
        gif_path,
        save_all=True,
        append_images=enlarged[1:],
        duration=[DURATION_MS] * FRAMES,
        loop=0,
        disposal=2,
        optimize=False,
    )

    sheet = checker((CELL * FRAMES, CELL))
    draw = ImageDraw.Draw(sheet)
    draw.line((0, SOLE_Y, sheet.width - 1, SOLE_Y), fill=(120, 136, 139), width=1)
    for index, frame in enumerate(frames):
        sheet.paste(frame, (index * CELL, 0))
    draw = ImageDraw.Draw(sheet)
    for index in range(FRAMES):
        if index:
            draw.line((index * CELL, 0, index * CELL, CELL - 1), fill=(94, 107, 110), width=1)
        draw.text((index * CELL + 4, 4), f"F{index}", fill=(220, 225, 224))
    sheet.save(sheet_path, format="PNG", optimize=False)

    output = {
        "schema": "luoyang_docks_carrier_walk_preview_v1",
        "passed": True,
        "source": {
            "walk_path": walk_path.as_posix(),
            "walk_sha256": sha256(walk_path),
            "mechanical_report_path": report_path.as_posix(),
            "mechanical_report_sha256": sha256(report_path),
        },
        "frames": frame_rows,
        "gif": {
            "path": gif_path.as_posix(),
            "sha256": sha256(gif_path),
            "bytes": gif_path.stat().st_size,
            "frames": FRAMES,
            "size_px": [CELL * 3, CELL * 3],
            "duration_ms_each": DURATION_MS,
            "sequence": [0, 1, 2, 3],
            "loop": 0,
            "background": "neutral checker",
            "preview_scale": "3x nearest-neighbour",
        },
        "contact_sheet": {
            "path": sheet_path.as_posix(),
            "sha256": sha256(sheet_path),
            "bytes": sheet_path.stat().st_size,
            "size_px": [CELL * FRAMES, CELL],
            "frame_scale": "1x source pixels",
            "sole_baseline_y_px": SOLE_Y,
        },
        "processing": "exact four-cell crop; checker composite; GIF packaging; no interpolation between poses, no pose synthesis and no source write",
        "credit_boundary": "Review media only. A passing script does not prove good motion, same-person identity, import, runtime, Field movement or formal use.",
    }
    preview_report_path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
