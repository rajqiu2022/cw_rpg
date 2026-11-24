"""Independent NumPy/SciPy reconstruction of frozen candidate processing records."""
from pathlib import Path
import argparse
import hashlib
import json
import statistics

import numpy as np
from PIL import Image
from scipy.ndimage import label

STATES = ("ready", "move", "attack", "hit", "defeat")
PROFILES = {"wild_dog": (400, 235), "tiger": (460, 265), "bear": (450, 290), "eagle": (440, 275)}


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def audit(species, directory_suffix=""):
    root = Path("assets/processed/sprite/animal_battle_20261012") / (species + directory_suffix)
    report_path = root / f"{species}_processing_report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    atlas_path = Path(report["source_atlas"])
    meta_path = atlas_path.with_suffix(".meta.json")
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    protected = [atlas_path, meta_path, report_path, Path(report["processor"]), Path(report["style_reference_only"])]
    protected.extend(root / r["output_filename"] for r in report["frames"])
    before = {str(p): digest(p) for p in protected}
    checks = []
    def check(value, name):
        checks.append({"name": name, "ok": bool(value)})
    check(meta["model"] == "gpt-image-2" and meta["fallback_used"] is False and meta["attempt"] == 1, "actual_metadata_model_no_fallback")
    check(report["source_sha256"] == digest(atlas_path) and report["source_generation_metadata_sha256"] == digest(meta_path), "source_meta_SHA")
    check(report["source_generation_metadata"] == meta, "embedded_meta_exact")
    check(report["processor_sha256"] == digest(report["processor"]) and report["style_reference_sha256"] == digest(report["style_reference_only"]), "processor_and_reference_SHA")
    check([(r["state"], r["index"]) for r in report["frames"]] == [(s, i) for s in STATES for i in range(1, 5)], "twenty_ordered_cells")
    with Image.open(atlas_path) as source:
        rgba = np.array(source.convert("RGBA"), dtype=np.int32)
        actual_size = source.size
    red, green, blue, alpha = [rgba[:, :, i].copy() for i in range(4)]
    clear = np.maximum.reduce([abs(red - 255), green, abs(blue - 255)]) < 52
    feather = (red > 45) & (blue > 45) & (green < np.minimum(red, blue) * .62) & ~clear
    rgba[:, :, 3][clear] = 0
    neutral = np.minimum.reduce([red, blue, np.maximum(green, 24)])
    rgba[:, :, 0][feather] = neutral[feather]
    rgba[:, :, 2][feather] = neutral[feather]
    rgba[:, :, 3][feather] = np.minimum(alpha[feather], np.rint(green[feather] * 2.2).clip(0, 255))
    atlas = Image.fromarray(rgba.astype(np.uint8))
    cells, sizes, removed = [], [], []
    for n, row in enumerate(report["frames"]):
        rect = row["source_cell_rect"]
        raw = atlas.crop(rect)
        check(list(raw.getchannel("A").getbbox()) == row["chroma_removed_bbox_before_component_cleanup"], f"{n}_raw_bbox")
        pixels = np.array(raw)
        labels, count = label(pixels[:, :, 3] >= 24)
        totals = np.bincount(labels.ravel()); totals[0] = 0
        largest = int(totals.argmax())
        removed.append(int(totals.sum() - totals[largest]))
        pixels[:, :, 3][labels != largest] = 0
        cell = Image.fromarray(pixels)
        box = cell.getchannel("A").getbbox()
        check(list(box) == row["source_content_bbox"], f"{n}_independent_component_bbox")
        sizes.append((box[2] - box[0], box[3] - box[1]))
        cells.append(cell.crop(box))
    widths, heights = zip(*sizes)
    scale = min(PROFILES[species][0] / statistics.median(widths[:4]), PROFILES[species][1] / statistics.median(heights[:4]), 480 / max(widths), 350 / max(heights))
    check(report["global_scale"] == scale and report["per_frame_fit"] is False, "independent_whole_twenty_global_scale")
    pixel_hashes = []
    for n, (cell, row) in enumerate(zip(cells, report["frames"])):
        check(row["global_scale"] == scale and row["frame_fit_applied"] is False, f"{n}_same_scale")
        resized_size = (round(cell.width * scale), round(cell.height * scale))
        resized = cell.resize(resized_size, Image.Resampling.LANCZOS)
        box = resized.getchannel("A").getbbox()
        resized = resized.crop(box)
        expected = Image.new("RGBA", (512, 384))
        expected.alpha_composite(resized, ((512 - resized.width) // 2, 372 - resized.height))
        path = root / row["output_filename"]
        with Image.open(path) as source:
            actual = source.convert("RGBA")
        check(list(resized_size) == row["resized_size_before_zero_alpha_trim"] and list(box) == row["resized_zero_alpha_trim_bbox"], f"{n}_round_trim_exact")
        check(expected.tobytes() == actual.tobytes(), f"{n}_all_RGBA_reconstructed_exact")
        check(digest(path) == row["output_sha256"] and hashlib.sha256(actual.tobytes()).hexdigest() == row["output_rgba_sha256"], f"{n}_output_hashes")
        pixel_hashes.append(hashlib.sha256(actual.tobytes()).hexdigest())
    for row_index, state in enumerate(STATES):
        group = report["frames"][row_index * 4:row_index * 4 + 4]
        rects = [r["source_cell_rect"] for r in group]
        check(rects[0][0] == 0 and rects[-1][2] == actual_size[0] and all(rects[i][2] == rects[i + 1][0] for i in range(3)), f"{state}_full_width_no_skipped_cells")
        check(all(r[1] == rects[0][1] and r[3] == rects[0][3] for r in rects), f"{state}_same_row")
        for rect in rects:
            a = np.array(atlas.crop(rect).getchannel("A"))
            check(a[0].max() < 24 and a[-1].max() < 24 and a[:, 0].max() < 24 and a[:, -1].max() < 24, f"{state}_cell_boundary_empty_{rect[0]}")
        with Image.open(root / "previews" / f"{species}_{state}_preview.webp") as animation:
            check(animation.n_frames == 4, f"{state}_preview_four_frames")
            for i in range(animation.n_frames):
                animation.seek(i)
                actual = np.array(animation.convert("RGBA"))
                with Image.open(root / group[i]["output_filename"]) as source:
                    expected = np.array(source.convert("RGBA"))
                check(np.array_equal(actual[:, :, 3], expected[:, :, 3]) and np.array_equal(actual[expected[:, :, 3] > 0], expected[expected[:, :, 3] > 0]), f"{state}_{i}_preview_visible_exact")
    bands = [report["frames"][i * 4]["source_cell_rect"] for i in range(5)]
    check(bands[0][1] == 0 and bands[-1][3] == actual_size[1] and all(bands[i][3] == bands[i + 1][1] for i in range(4)), "full_atlas_height_no_skipped_rows")
    check(len(set(pixel_hashes)) == 20, "no_exact_frame_duplicates")
    check(before == {str(p): digest(p) for p in protected}, "tested_sources_unchanged")
    return {"species": species, "scope": "INDEPENDENT_ATLAS_RECONSTRUCTION_NOT_VISUAL_OR_RUNTIME_APPROVAL", "checks": len(checks), "failures": [c for c in checks if not c["ok"]], "global_scale": scale, "maximum_source_size": [max(widths), max(heights)], "discarded_alpha24_pixels_each_cell": removed, "source_hashes": before, "runtime_credit": False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("species", choices=tuple(PROFILES), nargs="+")
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--directory-suffix", default="")
    args = parser.parse_args()
    if args.report.exists():
        parser.error("refusing to overwrite QA report")
    rows = [audit(s, args.directory_suffix) for s in args.species]
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
    print(json.dumps([{k: v for k, v in row.items() if k != "source_hashes"} for row in rows], indent=2))
    raise SystemExit(1 if any(r["failures"] for r in rows) else 0)
