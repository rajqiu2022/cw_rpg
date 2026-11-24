"""Independent native-alpha reconstruction. Never imports the tested processors."""
from pathlib import Path
import hashlib
import json
import statistics

import numpy as np
from PIL import Image
from scipy.ndimage import label


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def cuts(alpha, segments, axis, radius):
    occupancy = (alpha >= 24).sum(axis=1 if axis == "y" else 0)
    size = len(occupancy)
    result = [0]
    for i in range(1, segments):
        expected = round(i * size / segments)
        lo, hi = max(result[-1] + 1, expected - radius), min(size - 1, expected + radius)
        candidates = np.flatnonzero(occupancy[lo:hi + 1] == occupancy[lo:hi + 1].min()) + lo
        runs = np.split(candidates, np.flatnonzero(np.diff(candidates) != 1) + 1)
        run = min(runs, key=lambda r: (abs((int(r[0]) + int(r[-1])) / 2 - expected), -len(r)))
        result.append(round((int(run[0]) + int(run[-1])) / 2))
    return result + [size]


def main():
    directory = Path("assets/processed/sprite/animal_battle_20261012/eagle_v2")
    report_path = directory / "eagle_processing_report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    source_path = Path(report["source_atlas"])
    meta_path = source_path.with_suffix(".meta.json")
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    protected = [source_path, meta_path, report_path, Path(report["processor"]), Path(report["style_reference_only"])]
    protected += [directory / r["output_filename"] for r in report["frames"]]
    protected += list((directory / "previews").glob("*"))
    before = {str(p): sha(p) for p in protected}
    checks = []
    def check(ok, name):
        checks.append({"name": name, "ok": bool(ok)})
    with Image.open(source_path) as image:
        check(image.mode == "RGBA" and image.size == (1024, 1024), "actual_RGBA_1024_native_input")
        pixels = np.array(image)
    check(np.all(pixels[[0, 0, -1, -1], [0, -1, 0, -1], 3] == 0), "four_native_alpha_zero_corners")
    check(report["chroma_removal_applied"] is False and report["input_kind"] == "ACTUAL_RGBA_NATIVE_ALPHA_ZERO_BACKGROUND_NOT_CHROMA", "native_not_magenta_protocol")
    check(hashlib.sha256(pixels.tobytes()).hexdigest() == report["source_rgba_sha256"], "native_all_RGBA_sha")
    check(sha(source_path) == report["source_sha256"] and sha(meta_path) == report["source_generation_metadata_sha256"], "raw_meta_file_sha")
    check(report["source_generation_metadata"] == meta and meta["model"] == "gpt-image-2" and meta["fallback_used"] is False and meta["attempt"] == 1, "actual_metadata_exact_model_no_fallback")
    check(sha(report["processor"]) == report["processor_sha256"] and sha(report["style_reference_only"]) == report["style_reference_sha256"], "processor_style_hash_binding")
    states = ("ready", "move", "attack", "hit", "defeat")
    check([(r["state"], r["index"]) for r in report["frames"]] == [(s, i) for s in states for i in range(1, 5)], "five_by_four_ordered_exact")
    y_cuts = cuts(pixels[:, :, 3], 5, "y", 1024 // 25)
    crops, sizes, discarded = [], [], []
    for row_index, state in enumerate(states):
        top, bottom = y_cuts[row_index:row_index + 2]
        band = pixels[top:bottom]
        x_cuts = cuts(band[:, :, 3], 4, "x", 1024 // 20)
        for col in range(4):
            n = row_index * 4 + col
            r = report["frames"][n]
            left, right = x_cuts[col:col + 2]
            rect = [left, top, right, bottom]
            cell_pixels = pixels[top:bottom, left:right].copy()
            raw_alpha = cell_pixels[:, :, 3]
            check(rect == r["source_cell_rect"], f"{n}_independent_adaptive_cell_rect")
            check(list(Image.fromarray(raw_alpha).getbbox()) == r["native_nonzero_bbox_before_component_cleanup"], f"{n}_raw_nonzero_bbox")
            strong = raw_alpha >= 24
            check(list(Image.fromarray((strong * 255).astype(np.uint8)).getbbox()) == r["native_alpha24_bbox_before_component_cleanup"], f"{n}_strong_bbox")
            check(not (strong[0].any() or strong[-1].any() or strong[:, 0].any() or strong[:, -1].any()), f"{n}_strong_actual_body_never_touches_edges")
            components, count = label(strong)
            counts = np.bincount(components.ravel()); counts[0] = 0
            check(count > 0, f"{n}_subject_exists")
            keep = int(counts.argmax())
            discarded.append(int(counts.sum() - counts[keep]))
            cell_pixels[:, :, 3][components != keep] = 0
            clean_alpha = cell_pixels[:, :, 3]
            check(not (clean_alpha[0].any() or clean_alpha[-1].any() or clean_alpha[:, 0].any() or clean_alpha[:, -1].any()), f"{n}_clean_all_nonzero_edges_empty")
            clean = Image.fromarray(cell_pixels)
            box = clean.getchannel("A").getbbox()
            check(list(box) == r["source_content_bbox"], f"{n}_independent_component_bbox")
            crops.append(clean.crop(box)); sizes.append((box[2] - box[0], box[3] - box[1]))
    widths, heights = zip(*sizes)
    scale = min(440 / statistics.median(widths[:4]), 275 / statistics.median(heights[:4]), 480 / max(widths), 350 / max(heights))
    check(scale == report["global_scale"] and report["per_frame_fit"] is False, "one_independent_twenty_pose_scale")
    hashes = []
    for n, (crop, row) in enumerate(zip(crops, report["frames"])):
        size = (round(crop.width * scale), round(crop.height * scale))
        resized = crop.resize(size, Image.Resampling.LANCZOS)
        box = resized.getchannel("A").getbbox(); resized = resized.crop(box)
        expected = Image.new("RGBA", (512, 384))
        expected.alpha_composite(resized, ((512 - resized.width) // 2, 372 - resized.height))
        path = directory / row["output_filename"]
        with Image.open(path) as image:
            check(image.mode == "RGBA" and image.size == (512, 384), f"{n}_actual_RGBA_canvas")
            actual = image.copy()
        check(actual.tobytes() == expected.tobytes(), f"{n}_independent_all_RGBA_exact")
        check(size == tuple(row["resized_size_before_zero_alpha_trim"]) and list(box) == row["resized_zero_alpha_trim_bbox"], f"{n}_rounding_zeroalpha_trim_exact")
        check(row["global_scale"] == scale and row["frame_fit_applied"] is False, f"{n}_uniform_scale_no_perframe_fit")
        digest = hashlib.sha256(actual.tobytes()).hexdigest(); hashes.append(digest)
        check(sha(path) == row["output_sha256"] and digest == row["output_rgba_sha256"], f"{n}_all_file_and_pixel_hashes")
        bbox = actual.getchannel("A").getbbox()
        check(384 - bbox[3] == 12 and abs((bbox[0] + bbox[2] - 512) / 2) <= .5, f"{n}_actual_bottom12_center")
    for index, state in enumerate(states):
        with Image.open(directory / "previews" / f"eagle_{state}_preview.webp") as animation:
            check(animation.n_frames == 4, f"{state}_preview_four_actual_frames")
            for i in range(animation.n_frames):
                animation.seek(i); actual = np.array(animation.convert("RGBA"))
                with Image.open(directory / report["frames"][index * 4 + i]["output_filename"]) as image:
                    expected = np.array(image.convert("RGBA"))
                check(np.array_equal(actual[:, :, 3], expected[:, :, 3]) and np.array_equal(actual[expected[:, :, 3] > 0], expected[expected[:, :, 3] > 0]), f"{state}_{i}_preview_visible_exact")
    check(len(set(hashes)) == 20, "no_exact_duplicate_frames")
    check(before == {str(p): sha(p) for p in protected}, "all_tested_inputs_outputs_unchanged")
    result = {"scope": "INDEPENDENT_NATIVE_ALPHA_EAGLE_V2_RECONSTRUCTION_NOT_VISUAL_OR_RUNTIME", "checks": len(checks), "failures": [r for r in checks if not r["ok"]], "global_scale": scale, "maximum_source_size": [max(widths), max(heights)], "discarded_alpha24_component_pixels": discarded, "source_hashes": before, "runtime_credit": False}
    destination = Path("game/build/animal_sprite_independent_qa_20261012/eagle_reconstruction_v2.json")
    if destination.exists(): raise FileExistsError(destination)
    destination.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k != "source_hashes"}))
    return 1 if result["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
