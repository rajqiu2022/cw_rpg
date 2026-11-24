"""Build a deterministic v13 native terrain candidate, never a runtime asset.

The 1536x1024 topology image is only a low-frequency placement reference. A
build without native material layers is deliberately marked PLACEHOLDER and
must not be promoted into the game. The output manifest records a single
source master for nine overlap-safe chunks and verifies exact reconstruction.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageFilter, ImageOps, ImageStat


ROOT = Path(__file__).resolve().parents[1]
NATIVE_SIZE = (4608, 3072)
CELL_SIZE = (1536, 1024)
OVERLAP = 24


def _source_path(value: str) -> Path:
    path = (ROOT / value).resolve()
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"Missing or out-of-workspace input: {value}")
    return path


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _relative(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def _native_placeholder(topology: Path, seed: int) -> Image.Image:
    """Conspicuous contract-test stand-in, not acceptable visual output."""
    with Image.open(topology) as source:
        if source.size != (1536, 1024):
            raise ValueError(f"Topology reference must be 1536x1024: {source.size}")
        # This provides topology and low frequencies only. It is never enough
        # to qualify as a final native game texture on its own.
        base = source.convert("RGB").resize(NATIVE_SIZE, Image.Resampling.BICUBIC)
    return base.filter(ImageFilter.GaussianBlur(1.5))


def _texture_edge_delta(texture: Image.Image) -> float:
    right = ImageOps.mirror(texture.crop((texture.width - 1, 0, texture.width, texture.height)))
    bottom = ImageOps.flip(texture.crop((0, texture.height - 1, texture.width, texture.height)))
    horizontal = ImageChops.difference(texture.crop((0, 0, 1, texture.height)), right)
    vertical = ImageChops.difference(texture.crop((0, 0, texture.width, 1)), bottom)
    return max(max(ImageStat.Stat(horizontal).mean), max(ImageStat.Stat(vertical).mean))


def _high_frequency_fraction(texture: Image.Image, threshold: int = 7) -> float:
    gray = texture.convert("L")
    detail = ImageChops.difference(gray, gray.filter(ImageFilter.GaussianBlur(3)))
    histogram = detail.histogram()
    return sum(histogram[threshold:]) / (texture.width * texture.height)


def _edge_match_texture(texture: Image.Image, band: int = 48) -> Image.Image:
    """Match opposite edges before deterministic mirrored tiling.

    The original edge mismatch is still recorded as a QA warning. This local
    colour correction is not proof that repeated motifs are visually hidden.
    """
    band = min(band, texture.width // 4, texture.height // 4)
    original = texture.load()
    matched = texture.copy()
    pixels = matched.load()
    for offset in range(band):
        strength = 1.0 - offset / band
        opposite = texture.width - 1 - offset
        for y in range(texture.height):
            left = original[offset, y]
            right = original[opposite, y]
            mean = tuple((left[channel] + right[channel]) // 2 for channel in range(3))
            pixels[offset, y] = tuple(round(left[channel] * (1 - strength) + mean[channel] * strength) for channel in range(3))
            pixels[opposite, y] = tuple(round(right[channel] * (1 - strength) + mean[channel] * strength) for channel in range(3))
    horizontal_image = matched.copy()
    horizontal = horizontal_image.load()
    for offset in range(band):
        strength = 1.0 - offset / band
        opposite = texture.height - 1 - offset
        for x in range(texture.width):
            top = horizontal[x, offset]
            bottom = horizontal[x, opposite]
            mean = tuple((top[channel] + bottom[channel]) // 2 for channel in range(3))
            pixels[x, offset] = tuple(round(top[channel] * (1 - strength) + mean[channel] * strength) for channel in range(3))
            pixels[x, opposite] = tuple(round(bottom[channel] * (1 - strength) + mean[channel] * strength) for channel in range(3))
    return matched


def _tile_texture(texture: Image.Image, size: tuple[int, int], *, edge_matched: bool = False) -> Image.Image:
    if not edge_matched:
        texture = _edge_match_texture(texture)
    tiled = Image.new("RGB", size)
    for row, y in enumerate(range(0, size[1], texture.height)):
        for col, x in enumerate(range(0, size[0], texture.width)):
            variant = texture
            if col % 2:
                variant = ImageOps.mirror(variant)
            if row % 2:
                variant = ImageOps.flip(variant)
            tiled.paste(variant, (x, y))
    return tiled


def _apply_native_layers(master: Image.Image, spec: dict) -> tuple[list[dict], bool, dict[str, Image.Image]]:
    provenance: list[dict] = []
    masks: dict[str, Image.Image] = {}
    composition_mode = spec.get("composition_mode", "replace")
    if composition_mode not in ("replace", "detail_residual"):
        raise ValueError(f"Unknown composition mode: {composition_mode}")
    prepared_materials: list[tuple[Image.Image, Image.Image | None, Image.Image]] = []
    for layer in spec.get("materials", []):
        texture_path = _source_path(layer["texture_path"])
        mask_path = _source_path(layer["mask_path"])
        with Image.open(texture_path) as source:
            texture = source.convert("RGB")
        with Image.open(mask_path) as source:
            mask = source.convert("L")
        if texture.width < 512 or texture.height < 512:
            raise ValueError(f"Native material is too small: {texture_path}")
        if mask.size != NATIVE_SIZE:
            raise ValueError(f"Material mask must be native-size: {mask_path}: {mask.size}")
        if mask.getbbox() is None:
            raise ValueError(f"Material has an empty mask: {mask_path}")
        prepared = _edge_match_texture(texture)
        tiled = _tile_texture(prepared, NATIVE_SIZE, edge_matched=True)
        lowpass = tiled.filter(ImageFilter.GaussianBlur(10)) if composition_mode == "detail_residual" else None
        prepared_materials.append((tiled, lowpass, mask))
        masks[layer["id"]] = mask
        provenance.append({
            "kind": "material", "id": layer["id"],
            "texture_path": _relative(texture_path), "texture_sha256": _sha256(texture_path),
            "mask_path": _relative(mask_path), "mask_sha256": _sha256(mask_path),
            "source_edge_delta_rgb": round(_texture_edge_delta(texture), 3),
            "processed_edge_delta_rgb": round(_texture_edge_delta(prepared), 3),
            "processed_high_frequency_fraction": round(_high_frequency_fraction(prepared), 5),
        })
    fully_covered_by_native_materials = False
    if prepared_materials:
        min_weight, max_weight = float("inf"), 0.0
        # Stripe accumulation avoids a full-canvas float RGB buffer. In a
        # fully covered area there is no contribution from the low-res guide.
        for top in range(0, NATIVE_SIZE[1], 256):
            bottom = min(NATIVE_SIZE[1], top + 256)
            shape = (bottom - top, NATIVE_SIZE[0])
            colour = np.zeros((*shape, 3), dtype=np.float32)
            weight = np.zeros(shape, dtype=np.float32)
            for tiled, lowpass, mask in prepared_materials:
                alpha = np.asarray(mask.crop((0, top, NATIVE_SIZE[0], bottom)), dtype=np.float32) / 255.0
                pixels = np.asarray(tiled.crop((0, top, NATIVE_SIZE[0], bottom)), dtype=np.float32)
                if composition_mode == "detail_residual" and lowpass is not None:
                    low_pixels = np.asarray(lowpass.crop((0, top, NATIVE_SIZE[0], bottom)), dtype=np.float32)
                    pixels -= low_pixels
                colour += pixels * alpha[:, :, None]
                weight += alpha
            min_weight = min(min_weight, float(weight.min()))
            max_weight = max(max_weight, float(weight.max()))
            source = np.asarray(master.crop((0, top, NATIVE_SIZE[0], bottom)), dtype=np.float32)
            if composition_mode == "detail_residual":
                colour /= np.maximum(1.0, weight)[:, :, None]
                colour = source + colour * float(spec.get("detail_gain", 1.0))
            else:
                colour += source * np.maximum(0.0, 1.0 - weight)[:, :, None]
                colour /= np.maximum(1.0, weight)[:, :, None]
            master.paste(Image.fromarray(np.clip(colour, 0, 255).astype(np.uint8), "RGB"), (0, top))
        fully_covered_by_native_materials = min_weight >= 0.995 and max_weight <= 1.005
    for decal in spec.get("decals", []):
        if decal.get("depth_class") != "ground_flat":
            raise ValueError("Raised rocks/trees/structures must be visual_objects with blocker and Y depth, not terrain decals")
        path = _source_path(decal["path"])
        with Image.open(path) as source:
            image = source.convert("RGBA")
        x, y = map(int, decal["top_left"])
        if x < 0 or y < 0 or x + image.width > NATIVE_SIZE[0] or y + image.height > NATIVE_SIZE[1]:
            raise ValueError(f"Decal is outside the master: {path}")
        master.paste(image, (x, y), image.getchannel("A"))
        provenance.append({"kind": "decal", "path": _relative(path), "sha256": _sha256(path), "top_left": [x, y]})
    return provenance, fully_covered_by_native_materials, masks


def _check_topology_probes(spec: dict, masks: dict[str, Image.Image]) -> bool:
    probes = spec.get("topology_probes", [])
    if len(probes) < int(spec.get("min_topology_probe_count", 20)):
        return False
    seen: set[tuple[str, int, int]] = set()
    for probe in probes:
        x, y = map(int, probe["pos"])
        if not (0 <= x < NATIVE_SIZE[0] and 0 <= y < NATIVE_SIZE[1]):
            return False
        identity = (str(probe.get("id", "")), x, y)
        if not identity[0] or identity in seen:
            return False
        seen.add(identity)
        allowed = probe.get("allowed_material_ids", [])
        forbidden = probe.get("forbidden_material_ids", [])
        if not allowed and not forbidden:
            return False
        if any(name not in masks for name in allowed + forbidden):
            return False
        if allowed and max((masks[name].getpixel((x, y)) for name in allowed if name in masks), default=0) < 200:
            return False
        if any(name in masks and masks[name].getpixel((x, y)) > 55 for name in forbidden):
            return False
    return True


def build(spec_path: Path, out_dir: Path, detail_gain_override: float | None = None) -> dict:
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    if detail_gain_override is not None:
        if detail_gain_override < 0.0 or detail_gain_override > 2.0:
            raise ValueError("Detail gain override must be in [0, 2]")
        spec["detail_gain"] = detail_gain_override
    if spec.get("logical_size") != list(NATIVE_SIZE) or spec.get("cell_size") != list(CELL_SIZE):
        raise ValueError("v13 master must be 4608x3072 with 1536x1024 cells")
    candidate_build_root = ROOT / "game/build"
    if out_dir.resolve() == candidate_build_root or not out_dir.resolve().is_relative_to(candidate_build_root):
        raise ValueError("Candidate output must be a narrow directory under game/build")
    topology = _source_path(spec["topology_reference"])
    out_dir.mkdir(parents=True, exist_ok=True)
    master = _native_placeholder(topology, int(spec.get("seed", 130928)))
    layers, fully_covered_by_native_materials, masks = _apply_native_layers(master, spec)
    required = set(spec.get("required_material_ids", []))
    supplied = {layer["id"] for layer in spec.get("materials", [])}
    edge_limit = float(spec.get("max_processed_edge_delta_rgb", 1.0))
    detail_min = float(spec.get("min_source_high_frequency_fraction", 0.12))
    native_detail_ok = bool(supplied) and all(
        layer["processed_edge_delta_rgb"] <= edge_limit
        and layer["processed_high_frequency_fraction"] >= detail_min
        for layer in layers if layer["kind"] == "material"
    )
    topology_probes_ok = _check_topology_probes(spec, masks)
    visual_status = (
        "CANDIDATE_VISUAL_REVIEW"
        if required and required <= supplied and fully_covered_by_native_materials
        and native_detail_ok and topology_probes_ok
        else "PLACEHOLDER_CONTRACT_ONLY"
    )

    master_path = out_dir / "terrain_master_native_candidate.png"
    master.save(master_path)
    chunks: list[dict] = []
    assembled = Image.new("RGB", NATIVE_SIZE)
    for row in range(3):
        for col in range(3):
            x, y = col * CELL_SIZE[0], row * CELL_SIZE[1]
            left, top = max(0, x - OVERLAP), max(0, y - OVERLAP)
            right, bottom = min(NATIVE_SIZE[0], x + CELL_SIZE[0] + OVERLAP), min(NATIVE_SIZE[1], y + CELL_SIZE[1] + OVERLAP)
            source_rect = (left, top, right, bottom)
            chunk_path = out_dir / f"terrain_{row}_{col}.png"
            chunk = master.crop(source_rect)
            chunk.save(chunk_path)
            assembled.paste(chunk.crop((x - left, y - top, x - left + CELL_SIZE[0], y - top + CELL_SIZE[1])), (x, y))
            chunks.append({
                "id": f"r{row}c{col}", "path": _relative(chunk_path),
                "sha256": _sha256(chunk_path),
                "logical_rect": [x, y, *CELL_SIZE],
                "source_rect": [left, top, right - left, bottom - top],
                "draw_position": [left, top], "draw_scale": 1.0,
                "source_master_path": _relative(master_path),
            })
    if ImageChops.difference(master, assembled).getbbox() is not None:
        raise RuntimeError("The nine chunks did not reconstruct the native master exactly")
    sample_rect = (1536, 1024, 4608, 2048)
    sample_path = out_dir / "center_east_native_sample.png"
    master.crop(sample_rect).save(sample_path)
    manifest = {
        "schema": "world-map-v13-native-candidate-1",
        "visual_status": visual_status,
        "runtime_enabled": False,
        "logical_size": list(NATIVE_SIZE), "cell_size": list(CELL_SIZE),
        "overlap_px": OVERLAP,
        "topology_reference": _relative(topology), "topology_sha256": _sha256(topology),
        "source_master_path": _relative(master_path), "source_sha256": _sha256(master_path),
        "source_pixels_sha256": hashlib.sha256(master.tobytes()).hexdigest(),
        "center_east_sample": _relative(sample_path),
        "composition_mode": spec.get("composition_mode", "replace"),
        "detail_gain": float(spec.get("detail_gain", 1.0)),
        "required_material_ids": sorted(required),
        "native_material_full_coverage": fully_covered_by_native_materials,
        "native_detail_thresholds_pass": native_detail_ok,
        "topology_probe_count": len(spec.get("topology_probes", [])),
        "topology_probes_pass": topology_probes_ok,
        "human_runtime_visual_approval": spec.get("human_runtime_visual_approval", "PENDING"),
        "visual_review_note": spec.get("visual_review_note", "Requires 1.25x Godot screenshot review"),
        "layers": layers, "chunks": chunks,
        "checks": {"native_size": True, "nine_chunks": True, "exact_pixel_reconstruction": True},
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", type=Path, default=ROOT / "game/data/maps/world_map_v13_native_compose_v0.json")
    parser.add_argument("--out-dir", type=Path, default=ROOT / "game/build/world_map_v13_native_candidate")
    parser.add_argument("--detail-gain", type=float, default=None, help="A/B candidate override; recorded in manifest")
    args = parser.parse_args()
    result = build(args.spec.resolve(), args.out_dir.resolve(), args.detail_gain)
    print(f"{result['visual_status']}: {result['source_master_path']}, 9 exact chunks")
