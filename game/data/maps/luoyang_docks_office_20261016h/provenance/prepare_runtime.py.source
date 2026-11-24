"""One-pass full-canvas runtime derivation and NEW isolated import seed.

ROOT runs this after actual ART source hashes are frozen. No Godot process,
old import, game target, threshold, crop, repaint or alpha cleanup is invoked.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from PIL import Image, __version__ as PILLOW_VERSION

ROOT = Path(__file__).resolve().parents[2]
PREFIX = "art/modules/luoyang_docks_office_20261016h/"
PARAMS = {
    "compress/mode": 0, "compress/high_quality": False,
    "compress/lossy_quality": 0.7, "compress/uastc_level": 0,
    "compress/rdo_quality_loss": 0.0, "compress/hdr_compression": 1,
    "compress/normal_map": 0, "compress/channel_pack": 0,
    "mipmaps/generate": False, "mipmaps/limit": -1,
    "roughness/mode": 0, "roughness/src_normal": "",
    "process/channel_remap/red": 0, "process/channel_remap/green": 1,
    "process/channel_remap/blue": 2, "process/channel_remap/alpha": 3,
    "process/fix_alpha_border": False, "process/premult_alpha": False,
    "process/normal_map_invert_y": False, "process/hdr_as_srgb": False,
    "process/hdr_clamp_exposure": False, "process/size_limit": 0,
    "detect_3d/compress_to": 0,
}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def rgba_sha(image):
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True)
    for role in ("office", "loader", "clerk"):
        parser.add_argument("--" + role, required=True)
        parser.add_argument("--" + role + "-sha", required=True)
    args = parser.parse_args()
    output = Path(args.output).resolve()
    build = (ROOT / "game/build").resolve()
    if not output.is_relative_to(build) or output == build or output.exists():
        raise ValueError("Output must be a NEW named child under game/build")
    sources = {}
    for role in ("office", "loader", "clerk"):
        path = Path(getattr(args, role)).resolve()
        if not path.is_relative_to(ROOT / "assets/raw/luoyang_docks_office_20261016h"):
            raise ValueError("Input outside exact new raw namespace")
        expected = getattr(args, role + "_sha").lower()
        if len(expected) != 64 or sha(path) != expected:
            raise ValueError("Raw SHA mismatch: " + role)
        image = Image.open(path).convert("RGBA")
        if role != "office" and image.width != image.height:
            raise ValueError("Single actor source must be square, no crop allowed")
        sources[role] = (path, image, expected)
    output.mkdir()
    rows = []
    for role, (raw, source, source_sha) in sources.items():
        name = {"office": "docks_cargo_office_v1.png",
                "loader": "npc_docks_loader_idle_down_1f_v1_runtime.png",
                "clerk": "npc_docks_booking_clerk_idle_down_1f_v1_runtime.png"}[role]
        target = output / PREFIX / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if role == "office":
            shutil.copyfile(raw, target)
            derived = source
        else:
            # Exactly ONE resize of the entire unmodified RGBA source canvas.
            derived = source.resize((160, 160), Image.Resampling.LANCZOS,
                                    box=None, reducing_gap=None)
            with target.open("xb") as handle:
                derived.save(handle, format="PNG")
        actual = Image.open(target).convert("RGBA")
        if actual.size != derived.size or actual.tobytes() != derived.tobytes():
            raise ValueError("Serialized runtime full RGBA mismatch")
        if sha(raw) != source_sha:
            raise ValueError("Raw source changed during derivation")
        resource = "res://" + PREFIX + name
        compiled = "res://.godot/imported/" + name + "-" + hashlib.md5(resource.encode()).hexdigest() + ".ctex"
        seed = ('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n'
                'path=' + json.dumps(compiled) + '\nmetadata={"vram_texture": false}\n'
                '[deps]\nsource_file=' + json.dumps(resource) + '\ndest_files=[' + json.dumps(compiled) + ']\n[params]\n')
        seed += "\n".join(key + "=" + json.dumps(value) for key, value in PARAMS.items()) + "\n"
        with Path(str(target) + ".import").open("x", encoding="utf-8", newline="\n") as handle:
            handle.write(seed)
        rows.append({"role": role, "raw_path": str(raw), "raw_sha256": source_sha,
                     "raw_size_px": list(source.size), "raw_rgba_sha256": rgba_sha(source),
                     "texture": resource, "source_sha256": sha(target),
                     "size_px": list(actual.size), "rgba_sha256": rgba_sha(actual),
                     "derivation": "EXACT_BYTE_COPY" if role == "office" else "PILLOW_RGBA_FULL_CANVAS_ONE_RESIZE_LANCZOS_BOX_NONE_REDUCING_GAP_NONE",
                     "single_frame_not_animation": role != "office",
                     "runtime_raw_byte_identical": role == "office"})
    prepared = {"status": "NEW_ISOLATED_SEED_NOT_IMPORTED_NOT_GAME_PUBLISHED", "rows": rows,
                "pillow_version": PILLOW_VERSION, "tool_sha256": sha(Path(__file__)),
                "params23": PARAMS, "raw_pixel_edits": False,
                "cropping_alpha_threshold_or_repainting": False}
    with (output / "prepared.json").open("x", encoding="utf-8") as handle:
        json.dump(prepared, handle, ensure_ascii=False, indent=2)
    with (output / "project.godot").open("x", encoding="utf-8") as handle:
        handle.write('config_version=5\n[application]\nconfig/name="Docks office and roles isolated import"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    verifier = ROOT / "game/scripts/dev/verify_docks_office_import_20261016h.gd"
    shutil.copyfile(verifier, output / "verify_import.gd")
    print(json.dumps({"output": str(output), "rows": len(rows), "prepared_sha256": sha(output / "prepared.json"),
                      "verify_sha256": sha(output / "verify_import.gd"), "engine_started": False}))

if __name__ == "__main__":
    main()
