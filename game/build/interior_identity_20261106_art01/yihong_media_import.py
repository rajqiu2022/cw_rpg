"""Finite Yihong import plan. Only the explicit, SHA-bound install subcommand writes live files."""
import argparse
import hashlib
import io
import json
import os
import re
import struct
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
PROJECT = HERE / "isolated_yihong_media_import"
MANIFEST = HERE / "yihong_media_import_inputs.json"
PLAN = HERE / "yihong_media_formal_install_plan.json"
INSTALLED = HERE / "yihong_media_formal_install_receipt.json"
GODOT = Path("F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe")
ENGINE = {
    GODOT / "Godot_v4.6.2-stable_win64.exe": "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0",
    GODOT / "Godot_v4.6.2-stable_win64_console.exe": "2a12df24d1545ff3924a1f40e8ed9f4ec7ce9b140814c1b566dcd2bdf7b79492",
}
SHELL = "yihongyuan_luxury_shell"
WOMEN = ("musician", "singer", "tea_attendant", "receptionist")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def digest(path):
    return sha(path.read_bytes())


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def create_exact(path, data, allow_same=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("xb") as f:
            f.write(data)
    except FileExistsError:
        assert allow_same and path.read_bytes() == data, f"Refusing collision: {path}"


def write_json(path, value, allow_same=False):
    create_exact(path, (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8"), allow_same)


def declared_sources():
    shell = next(x for x in read_json(HERE / "shell_processing_receipt.json") if x["role"] == SHELL)
    women = read_json(HERE / "women_processing_receipt.json")
    assert tuple(x["role"] for x in women) == WOMEN
    rows = []
    for row in [shell, *women]:
        role = row["role"]
        rel = (f"art/modules/interior_identity_20261106/{role}.png" if role == SHELL else
               f"art/characters/yihongyuan_identity_20261106/{role}_idle_native.png")
        name = Path(rel).name
        res = "res://" + rel
        key = hashlib.md5(res.encode("utf-8")).hexdigest()
        ctex_rel = f".godot/imported/{name}-{key}.ctex"
        rows.append({
            "role": role, "source": row["source"], "source_sha256": row["source_sha256"],
            "candidate": row["candidate"], "candidate_sha256": row["candidate_sha256"],
            "candidate_size": row["candidate_size"], "res": res,
            "png": str(PROJECT / rel), "import": str(PROJECT / (rel + ".import")),
            "ctex": str(PROJECT / ctex_rel), "ctex_res": "res://" + ctex_rel,
            "targets": {
                "png": str(GAME / rel), "import": str(GAME / (rel + ".import")),
                "ctex": str(GAME / ctex_rel),
            },
        })
    return rows


def check_live_absent(rows):
    for row in rows:
        for kind, target in row["targets"].items():
            dst = Path(target)
            assert dst.resolve().is_relative_to(GAME.resolve()), dst
            assert not os.path.lexists(dst), (kind, dst)


def prepare():
    rows = declared_sources()
    check_live_absent(rows)
    assert not (PROJECT / ".godot").exists(), "Never overwrite an imported project"
    template_path = GAME / (
        "build/npc_hd_20261106_batch03/import_project/art/characters/pc_hd_20261102c/"
        "merchant_down_idle_native_20261106b03.png.import"
    )
    template = template_path.read_text(encoding="utf-8")
    template = re.sub(r"^uid=.*\n", "", template, flags=re.M)
    old_source = "res://art/characters/pc_hd_20261102c/merchant_down_idle_native_20261106b03.png"
    old_ctex = "res://.godot/imported/merchant_down_idle_native_20261106b03.png-24a8aa9d870cbccc42a175daf6e0e0c0.ctex"
    assert template.count(old_source) == 1 and template.count(old_ctex) == 2
    create_exact(PROJECT / "project.godot", b'config_version=5\n[application]\nconfig/name="Yihong media isolated import"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', True)
    for row in rows:
        original = Path(row["source"])
        candidate = Path(row["candidate"]).read_bytes()
        assert digest(original) == row["source_sha256"]
        assert sha(candidate) == row["candidate_sha256"]
        create_exact(Path(row["png"]), candidate, True)
        sidecar = template.replace(old_source, row["res"]).replace(old_ctex, row["ctex_res"])
        create_exact(Path(row["import"]), sidecar.encode("utf-8"), True)
    write_json(MANIFEST, {"scope": "ISOLATED_YIHONG_5_ONLY", "project": str(PROJECT),
                          "engine_sha256": {str(k): v for k, v in ENGINE.items()},
                          "records": rows}, True)
    print(f"Prepared {len(rows)} isolated media; live writes=0")


def verify_texture(row):
    sidecar = Path(row["import"]).read_text(encoding="utf-8")
    required = [
        f'source_file="{row["res"]}"', f'path="{row["ctex_res"]}"',
        f'dest_files=["{row["ctex_res"]}"]', "compress/mode=0",
        "mipmaps/generate=true", "process/fix_alpha_border=false",
        "process/premult_alpha=false", "process/size_limit=0",
    ]
    assert all(p in sidecar for p in required), row["role"]
    png = Path(row["png"])
    assert digest(png) == row["candidate_sha256"]
    assert digest(Path(row["source"])) == row["source_sha256"]
    with Image.open(png) as src:
        assert src.mode == "RGBA" and list(src.size) == row["candidate_size"]
        original = src.tobytes()
    # Godot 4.6.2's version-1 GST2 lossless texture stores one PNG or
    # lossless WebP payload per mip. Confirm all levels decode and base is
    # byte-identical including RGB under zero alpha, not only appearance.
    data = Path(row["ctex"]).read_bytes()
    magic, version, width, height = struct.unpack_from("<4sIII", data)
    codec, mw, mh, additional_mips, pixel_format = struct.unpack_from("<IHHII", data, 36)
    assert (magic, version) == (b"GST2", 1) and codec in (1, 2) and pixel_format == 5
    assert [width, height] == row["candidate_size"] and (mw, mh) == (width, height)
    assert additional_mips == max(width, height).bit_length() - 1
    offset = 52
    for level in range(additional_mips + 1):
        size = struct.unpack_from("<I", data, offset)[0]
        offset += 4
        blob = data[offset:offset + size]
        offset += size
        if codec == 2:
            assert blob.startswith(b"RIFF") and blob[8:16] == b"WEBPVP8L"
        else:
            assert blob.startswith(b"\x89PNG\r\n\x1a\n")
        with Image.open(io.BytesIO(blob)) as decoded:
            assert decoded.size == (max(1, width >> level), max(1, height >> level))
            if level == 0:
                assert decoded.convert("RGBA").tobytes() == original, (row["role"], "base RGBA")
    assert offset == len(data)
    return {"base_rgba_exact": True, "base_rgba_sha256": sha(original),
            "mip_levels_including_base": additional_mips + 1}


def propose(evidence):
    assert evidence.resolve().parent == HERE and re.fullmatch(r"yihong_import[0-9]+", evidence.name)
    import_run = read_json(evidence / "engine_exit.json")
    assert import_run["exit_code"] == 0
    rows = declared_sources()
    check_live_absent(rows)
    assert rows == read_json(MANIFEST)["records"]
    results = [verify_texture(row) for row in rows]
    targets = []
    # Cache first, then remap, then visible PNG. No live paths exist at plan
    # time; exclusive creation is repeated at install time.
    for kind in ("ctex", "import", "png"):
        for row in rows:
            candidate = Path(row[kind])
            targets.append({"role": row["role"], "kind": kind, "candidate": str(candidate),
                            "target": row["targets"][kind], "before": "ABSENT",
                            "after_sha256": digest(candidate)})
    write_json(PLAN, {"scope": "PROPOSED_NOT_INSTALLED_YIHONG_5_MEDIA_15_LEAVES",
                      "engine_exit": str(evidence / "engine_exit.json"),
                      "engine_exit_sha256": digest(evidence / "engine_exit.json"),
                      "checks": dict(zip((r["role"] for r in rows), results)),
                      "targets": targets}, True)
    print(f"Validated 5/5 base RGBA+mips, 15 proposed live paths; plan SHA256={digest(PLAN)}")


def install(approval_sha):
    assert re.fullmatch(r"[a-f0-9]{64}", approval_sha)
    assert digest(PLAN) == approval_sha and not INSTALLED.exists()
    plan = read_json(PLAN)
    rows = declared_sources()
    assert len(plan["targets"]) == 15
    expected = {(row["role"], kind): (row[kind], dst)
                for row in rows for kind, dst in row["targets"].items()}
    check_live_absent(rows)
    data_by_target = {}
    for entry in plan["targets"]:
        candidate, dst = expected.pop((entry["role"], entry["kind"]))
        assert entry["before"] == "ABSENT" and entry["candidate"] == candidate and entry["target"] == dst
        data = Path(candidate).read_bytes()
        assert sha(data) == entry["after_sha256"]
        data_by_target[Path(dst)] = data
    assert not expected
    for dst, data in data_by_target.items():
        create_exact(dst, data)
    assert all(digest(dst) == sha(data) for dst, data in data_by_target.items())
    write_json(INSTALLED, {"scope": "INSTALLED_15_NEW_MEDIA_LEAVES_NO_CONSUMER_SWITCH",
                           "approved_plan_sha256": approval_sha, "targets": plan["targets"]})
    print("Installed 15 exact new media leaves; no consumer switch")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--prepare", action="store_true")
    modes.add_argument("--plan-after-import", type=Path)
    modes.add_argument("--install-approved-plan")
    args = parser.parse_args()
    if args.prepare:
        prepare()
    elif args.plan_after_import:
        propose(args.plan_after_import)
    else:
        install(args.install_approved_plan)
