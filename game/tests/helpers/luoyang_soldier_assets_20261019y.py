"""Read-only y PNG measurements. No generation, editing, import or engine.

Raw may be a rectangular-cell 4x2 atlas, not a runtime horizontal strip.
Optional runtime-map: {"identities": {identity: {"runtime_sprite_path": path,
"idle_path": path, "portrait_path": path, "raw_grid_rect_px": [x,y,w,h]}}}.
Only a single explicit common grid rectangle is accepted; no per-frame fitting.
Example: python game/tests/helpers/luoyang_soldier_assets_20261019y.py
  --manifest prompts/luoyang_soldier_diversity_20261019y/manifest.json
  --report game/build/luoyang_soldier_assets_20261019y/raw01/result.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageOps

ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "prompts/luoyang_soldier_diversity_20261019y/manifest.json"
REPORT_ROOT = ROOT / "game/build/luoyang_soldier_assets_20261019y"


def local(value: str | Path) -> Path:
    text = str(value)
    path = ROOT / "game" / text[6:] if text.startswith("res://") else Path(text)
    if not path.is_absolute():
        path = ROOT / path
    path = path.resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError(f"Input outside explicitly scoped workspace: {path}")
    return path


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fact(path: Path) -> dict:
    if not path.is_file():
        return {"exists": False, "path": str(path), "sha256": "ABSENT"}
    stat = path.stat()
    return {"exists": True, "path": str(path), "bytes": stat.st_size,
            "mtime_ns_string": str(stat.st_mtime_ns), "sha256": sha(path.read_bytes())}


def border_nonzero(alpha: Image.Image) -> int:
    width, height = alpha.size
    pixels = alpha.load()
    return sum(pixels[x, 0] > 0 for x in range(width)) + sum(
        pixels[x, height - 1] > 0 for x in range(width)) + sum(
        pixels[0, y] > 0 for y in range(1, height - 1)) + sum(
        pixels[width - 1, y] > 0 for y in range(1, height - 1))


def visible_fingerprint(image: Image.Image) -> dict:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    rgba = Image.new("RGBA", image.size, (0, 0, 0, 0))
    rgba.paste(image, (0, 0), alpha.point(lambda x: 255 if x else 0))
    gray = image.convert("L")
    gray.paste(0, (0, 0), ImageOps.invert(alpha.point(lambda x: 255 if x else 0)))
    silhouette = alpha.point(lambda x: 255 if x else 0)
    if bbox:
        silhouette = silhouette.crop(bbox).resize((32, 64), Image.Resampling.NEAREST)
        normalized_gray = ImageOps.autocontrast(gray.crop(bbox)).resize((32, 64), Image.Resampling.BILINEAR)
    else:
        silhouette = Image.new("L", (32, 64), 0)
        normalized_gray = silhouette.copy()
    return {"rgba_sha256": sha(rgba.tobytes()), "alpha_sha256": sha(alpha.tobytes()),
            "gray_alpha_sha256": sha(gray.tobytes() + alpha.tobytes()),
            "silhouette": silhouette, "gray": normalized_gray}


class Audit:
    def __init__(self) -> None:
        self.checks: list[dict] = []
        self.before: dict[str, dict] = {}
        self.rows: list[dict] = []
        self.first: dict[str, dict] = {}

    def check(self, value: bool, label: str, detail=None) -> bool:
        self.checks.append({"ok": bool(value), "label": label, "detail": detail})
        return bool(value)

    def track(self, path: Path) -> dict:
        key = str(path)
        current = fact(path)
        if key in self.before:
            self.check(current == self.before[key], "Repeated source unchanged: " + key)
        else:
            self.before[key] = current
        return current

    def image(self, path: Path, label: str) -> Image.Image | None:
        if not self.check(self.track(path)["exists"], label + " exists", str(path)):
            return None
        with Image.open(path) as source:
            self.check(source.format == "PNG", label + " actual PNG storage", source.format)
            self.check(source.mode == "RGBA", label + " actual RGBA alpha, not RGB checkerboard", source.mode)
            image = source.convert("RGBA")
        alpha = image.getchannel("A")
        self.check(alpha.getbbox() is not None and alpha.getextrema()[0] == 0,
                   label + " has nonempty art and genuinely transparent pixels", alpha.getextrema())
        self.check(border_nonzero(alpha) == 0, label + " all four outer borders A=0")
        return image

    def measure(self, image: Image.Image, rows: int, columns: int, label: str,
                rectangle=None) -> tuple[list[dict], list[dict]]:
        x, y, width, height = 0, 0, image.width, image.height
        if rectangle is not None:
            if not self.check(isinstance(rectangle, list) and len(rectangle) == 4 and
                              all(type(v) is int for v in rectangle), label + " explicit integral common grid rectangle", rectangle):
                return [], []
            x, y, width, height = rectangle
            if not self.check(x >= 0 and y >= 0 and width > 0 and height > 0 and
                              x + width <= image.width and y + height <= image.height,
                              label + " measured grid stays inside original canvas", rectangle):
                return [], []
            outside = image.getchannel("A").copy()
            outside.paste(0, (x, y, x + width, y + height))
            if not self.check(outside.getbbox() is None, label + " common crop discards no nonzero-alpha art"):
                return [], []
        if not self.check(width % columns == 0 and height % rows == 0,
                          label + " exactly divisible equal-cell grid; no guessed fractional cuts",
                          {"canvas": list(image.size), "grid": [columns, rows], "rect": [x, y, width, height]}):
            return [], []
        cw, ch = width // columns, height // rows
        frames: list[dict] = []
        fingerprints: list[dict] = []
        for index in range(rows * columns):
            left = x + (index % columns) * cw
            top = y + (index // columns) * ch
            cell = image.crop((left, top, left + cw, top + ch))
            alpha = cell.getchannel("A")
            bbox = alpha.getbbox()
            strong_bbox = alpha.point(lambda v: 255 if v >= 16 else 0).getbbox()
            self.check(bbox is not None, f"{label} frame{index} complete nonempty alpha")
            self.check(border_nonzero(alpha) == 0, f"{label} frame{index} transparent cell boundary/no cross-cell clipping")
            fingerprint = visible_fingerprint(cell)
            fingerprints.append(fingerprint)
            frames.append({"index": index, "source_rect_px": [left, top, cw, ch],
                           "alpha_gt0_bbox": bbox, "alpha_ge16_bbox": strong_bbox,
                           "visible_height": bbox[3] - bbox[1] if bbox else 0,
                           "baseline_bottom_exclusive": bbox[3] if bbox else None,
                           "bottom_transparent_margin": ch - bbox[3] if bbox else None,
                           **{key: value for key, value in fingerprint.items() if key.endswith("sha256")}})
        return frames, fingerprints

    def role(self, spec: dict, binding: dict) -> None:
        identity = spec["identity"]
        layout = spec["source_layout"]
        count = layout["frames"]
        self.check(count == layout["rows"] * layout["columns"] and
                   ((layout["kind"] == "equal_cell_atlas" and [layout["columns"], layout["rows"], count] == [4, 2, 8]) or
                    (layout["kind"] == "single_fullbody_static" and [layout["columns"], layout["rows"], count] == [1, 1, 1])),
                   identity + " actual final spec kind/mode/frame/grid are consistent")
        raw = self.image(local(spec["output_path"]), identity + " raw")
        result = {"identity": identity, "source_mode": layout["kind"], "declared_frames": count,
                  "facing_declared_not_visually_verified": layout["facing"],
                  "portrait_same_person_review": "PENDING", "identity_role_age_armour_review": "PENDING",
                  "actual_walk_phase_or_Field_verified": False}
        if raw is not None:
            frames, fingerprints = self.measure(raw, layout["rows"], layout["columns"],
                                                identity + " raw", binding.get("raw_grid_rect_px"))
            result.update({"raw_canvas_px": list(raw.size), "raw_frames": frames})
            if fingerprints:
                self.first[identity] = fingerprints[0]
        runtime = binding.get("runtime_sprite_path")
        runtime_first_hash = None
        if runtime:
            image = self.image(local(runtime), identity + " runtime")
            if image is not None:
                self.check(image.size == (160 * count, 160), identity + " strict NPCNode horizontal runtime strip", list(image.size))
                frames, _ = self.measure(image, 1, count, identity + " runtime")
                result["runtime_frames"] = frames
                if frames:
                    runtime_first_hash = frames[0]["rgba_sha256"]
                if frames and all(frame["alpha_gt0_bbox"] for frame in frames):
                    first = frames[0]["alpha_gt0_bbox"]
                    target = spec["runtime_target_after_actual_measurement"]["target_alpha_bounds_y"]
                    self.check([first[1], first[3]] == target,
                               identity + " first frame exact declared target alpha y", {"actual": [first[1], first[3]], "target": target})
                    scale = 140.0 / (first[3] - first[1])
                    feet = [(frame["alpha_gt0_bbox"][3] - first[3]) * scale for frame in frames]
                    result.update({"actual_calibrated_scale": scale, "world_foot_deltas": feet,
                                   "world_height_each": [frame["visible_height"] * scale for frame in frames]})
                    self.check(all(math.isfinite(v) and abs(v) <= 12 for v in feet),
                               identity + " every frame actual first-alpha anchor drift <=12 world px", feet)
                    if count > 1:
                        self.check(len({f["rgba_sha256"] for f in frames}) == count,
                                   identity + " no copied complete frames passed off as eight-phase animation")
                        result["distinct_frames_are_not_walk_phase_approval"] = True
                result["runtime_structure_measured_not_imported"] = True
        else:
            result["runtime_structure_measured_not_imported"] = False
        idle = binding.get("idle_path")
        if idle:
            self.check(count == 8 and runtime_first_hash is not None,
                       identity + " optional contact-idle extraction only from supplied true walk runtime")
            image = self.image(local(idle), identity + " extracted idle")
            if image is not None:
                self.check(image.size == (160, 160), identity + " honest single-frame idle, not duplicated fake breathing")
                result["extracted_idle_frames"], _ = self.measure(image, 1, 1, identity + " extracted idle")
                self.check(visible_fingerprint(image)["rgba_sha256"] == runtime_first_hash,
                           identity + " contact idle exactly equals runtime walk frame1 visible RGBA, not a substituted identity")
                result["contact_pose_idle_art_root_approval"] = "PENDING"
        if binding.get("portrait_path"):
            portrait = local(binding["portrait_path"])
            result["portrait_fact"] = self.track(portrait)
            self.check(portrait.is_file(), identity + " explicitly supplied portrait exists")
        self.rows.append(result)

    def compare_identities(self) -> list[dict]:
        pairs: list[dict] = []
        keys = list(self.first)
        for i, left in enumerate(keys):
            for right in keys[i + 1:]:
                a, b = self.first[left], self.first[right]
                self.check(a["rgba_sha256"] != b["rgba_sha256"], f"{left}/{right} not identical full visible pixels")
                self.check(a["gray_alpha_sha256"] != b["gray_alpha_sha256"], f"{left}/{right} not exact recolour-only grayscale+alpha duplicate")
                ma, mb = a["silhouette"], b["silhouette"]
                intersection = sum(v > 0 for v in ImageChops.multiply(ma, mb).getdata())
                union = sum(v > 0 for v in ImageChops.lighter(ma, mb).getdata())
                gray_difference = sum(ImageChops.difference(a["gray"], b["gray"]).getdata()) / (2048 * 255)
                pairs.append({"left": left, "right": right, "normalized_alpha_iou": intersection / max(1, union),
                              "normalized_gray_mean_difference": gray_difference,
                              "metrics_do_not_prove_age_face_role_material_or_non_recolour": True})
        return pairs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default=str(MANIFEST))
    parser.add_argument("--runtime-map")
    parser.add_argument("--identity", action="append", help="Explicit bounded subset; default all manifest identities")
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    report_path = local(args.report)
    if not report_path.is_relative_to(REPORT_ROOT.resolve()) or report_path.exists():
        raise ValueError("Use a NEW report path under game/build/luoyang_soldier_assets_20261019y; no overwrites")
    audit = Audit()
    manifest_path = local(args.manifest)
    audit.track(manifest_path); audit.track(Path(__file__).resolve())
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    identities = [row["id"] for row in manifest["identities"]]
    selected = args.identity or identities
    if len(set(selected)) != len(selected) or not set(selected) <= set(identities):
        raise ValueError("Only unique identities explicitly registered in the manifest")
    bindings = {}
    if args.runtime_map:
        mapping = local(args.runtime_map); audit.track(mapping)
        bindings = json.loads(mapping.read_text(encoding="utf-8"))["identities"]
        if not set(bindings) <= set(identities):
            raise ValueError("Runtime map contains an unregistered identity")
    specs = {}
    for path in sorted(manifest_path.parent.glob("*.spec.json")):
        audit.track(path)
        spec = json.loads(path.read_text(encoding="utf-8"))
        if spec["identity"] in specs:
            raise ValueError("Duplicate identity spec")
        specs[spec["identity"]] = spec
    if set(specs) != set(identities):
        raise ValueError("Manifest and actual six specs must have identical identity sets")
    for identity in selected:
        try:
            audit.role(specs[identity], bindings.get(identity, {}))
        except (OSError, ValueError, KeyError, ZeroDivisionError) as error:
            audit.check(False, identity + " readable source and declared layout", str(error))
    pairs = audit.compare_identities()
    after = {key: fact(Path(key)) for key in audit.before}
    audit.check(audit.before == after, "All read input bytes/mtime facts unchanged; no PNG edits")
    passed = all(row["ok"] for row in audit.checks)
    report = {"scope": "PNG_STRUCTURE_MEASUREMENTS_ONLY_NOT_ART_ANIMATION_IMPORT_OR_FORMAL",
              "structural_checks_passed": passed, "full_art_pass": False,
              "actual_walk_phase_verified": False, "portrait_identity_verified": False,
              "engine_calls": 0, "generation_calls": 0, "image_writes": 0,
              "selected_identities": selected, "checks": len(audit.checks),
              "failures": sum(not row["ok"] for row in audit.checks),
              "assertions": audit.checks, "assets": audit.rows, "pair_measurements": pairs,
              "source_before": audit.before, "source_after": after}
    report_path.parent.mkdir(parents=True, exist_ok=True)
    with report_path.open("x", encoding="utf-8") as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(json.dumps({"report_path": str(report_path), "checks": report["checks"],
                      "failures": report["failures"], "structural_checks_passed": passed,
                      "full_art_pass": False}, ensure_ascii=False))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
