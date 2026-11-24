"""Three exact, namespaced Yihong floor assets. Import execution belongs to Root."""
import argparse
import hashlib
import importlib.util
import re
import sys
from pathlib import Path

from PIL import Image

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
REPO = GAME.parent
PROJECT = HERE / "isolated_yihong_media_import"
INPUTS = HERE / "floor_media_import_inputs.json"
PLAN = HERE / "floor_media_formal_install_plan.json"
RECEIPT = HERE / "floor_media_formal_install_receipt.json"
PROMPTS = REPO / "prompts/yihongyuan_floors_20261107/builtin-prompts.md"
GENERATED = Path("C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8")
UTILITY = GAME / "build/interior_identity_20261106_art01/yihong_media_import.py"
assert hashlib.sha256(UTILITY.read_bytes()).hexdigest() == "d4a33369575b358d20c533ab7b35f754ced3e0ce3105a70c54ff5408dff06bd1"
spec = importlib.util.spec_from_file_location("verified_yihong_media_utility", UTILITY)
assert spec is not None and spec.loader is not None
media = importlib.util.module_from_spec(spec)
spec.loader.exec_module(media)

ROWS = {
    "tea_table": ("01b458d1-4eab-440b-ad1d-d76f579938e6", (1610, 977), "f05dd2c74a6dae660859a5979eefc1c25b7bc1eb4eba17b11a91b780615b9d11"),
    "up_stair": ("c57959e6-df52-48aa-a191-a768552146b9", (1024, 1536), "69b0caf4dee4c0f74dc574a7af0fe16dcbe727c957788c4d46740acec283de7a"),
    "upper_shell": ("780becfa-ec2b-40fa-87e3-8364cae30de9", (1536, 1024), "bd38f76c264b173cdcae2e260bcfb31d127c6dc02482db413b3648c4bf21bb0e"),
}


def declared():
    assert media.digest(PROMPTS) == "1350d7c4fafc037e4dc50e4aa07f7b1fe6e5c3980aa0e1da09034055d7cb77ab"
    rows = []
    for role, (guid, size, expected) in ROWS.items():
        name = role + ".png"
        raw = REPO / "assets/raw/yihongyuan_floors_20261107" / name
        generated = GENERATED / f"exec-{guid}.png"
        assert media.digest(generated) == media.digest(raw) == expected
        with Image.open(raw) as src:
            assert src.mode == "RGBA" and src.size == size
        rel = "art/modules/yihongyuan_floors_20261107/" + name
        res = "res://" + rel
        key = hashlib.md5(res.encode("utf-8")).hexdigest()
        ctex = f".godot/imported/{name}-{key}.ctex"
        rows.append({"role": role, "source": str(raw), "source_sha256": expected,
                     "generated": str(generated), "prompt_path": str(PROMPTS),
                     "candidate_sha256": expected, "candidate_size": list(size), "res": res,
                     "png": str(PROJECT / rel), "import": str(PROJECT / (rel + ".import")),
                     "ctex": str(PROJECT / ctex), "ctex_res": "res://" + ctex,
                     "targets": {"png": str(GAME / rel), "import": str(GAME / (rel + ".import")),
                                 "ctex": str(GAME / ctex)}})
    return rows


def prepare():
    rows = declared()
    media.check_live_absent(rows)
    assert not (PROJECT / ".godot").exists()
    template_path = GAME / (
        "build/npc_hd_20261106_batch03/import_project/art/characters/pc_hd_20261102c/"
        "merchant_down_idle_native_20261106b03.png.import"
    )
    template = re.sub(r"^uid=.*\n", "", template_path.read_text(encoding="utf-8"), flags=re.M)
    old_source = "res://art/characters/pc_hd_20261102c/merchant_down_idle_native_20261106b03.png"
    old_ctex = "res://.godot/imported/merchant_down_idle_native_20261106b03.png-24a8aa9d870cbccc42a175daf6e0e0c0.ctex"
    assert template.count(old_source) == 1 and template.count(old_ctex) == 2
    media.create_exact(PROJECT / "project.godot", b'config_version=5\n[application]\nconfig/name="Yihong floor art isolated import"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', True)
    for row in rows:
        media.create_exact(Path(row["png"]), Path(row["source"]).read_bytes(), True)
        text = template.replace(old_source, row["res"]).replace(old_ctex, row["ctex_res"])
        media.create_exact(Path(row["import"]), text.encode("utf-8"), True)
    media.write_json(INPUTS, {"scope": "ISOLATED_YIHONG_FLOORS_3_ONLY", "project": str(PROJECT),
                              "engine_sha256": {str(k): v for k, v in media.ENGINE.items()},
                              "pixel_edit": False, "records": rows}, True)
    print("Prepared 3 raw-exact, isolated sources; live writes=0")


def propose(evidence):
    assert evidence.resolve().parent == HERE and re.fullmatch(r"floor_import[0-9]+", evidence.name)
    exit_record = evidence / "engine_exit.json"
    assert media.read_json(exit_record)["exit_code"] == 0
    rows = declared()
    media.check_live_absent(rows)
    assert rows == media.read_json(INPUTS)["records"]
    checks = {row["role"]: media.verify_texture(row) for row in rows}
    targets = [{"role": row["role"], "kind": kind, "candidate": row[kind],
                "target": row["targets"][kind], "before": "ABSENT",
                "after_sha256": media.digest(Path(row[kind]))}
               for kind in ("ctex", "import", "png") for row in rows]
    media.write_json(PLAN, {"scope": "PROPOSED_YIHONG_FLOORS_3_MEDIA_9_LEAVES",
                           "engine_exit": str(exit_record), "engine_exit_sha256": media.digest(exit_record),
                           "checks": checks, "targets": targets}, True)
    print(f"Verified 3/3 base RGBA plus all mips; plan SHA256={media.digest(PLAN)}")


def install(approved_sha):
    assert re.fullmatch(r"[a-f0-9]{64}", approved_sha)
    assert media.digest(PLAN) == approved_sha and not RECEIPT.exists()
    rows = declared()
    media.check_live_absent(rows)
    plan = media.read_json(PLAN)
    expected = {(row["role"], kind): (row[kind], dst)
                for row in rows for kind, dst in row["targets"].items()}
    assert len(plan["targets"]) == len(expected) == 9
    assert plan["checks"] == {row["role"]: media.verify_texture(row) for row in rows}
    payloads = {}
    for entry in plan["targets"]:
        src, dst = expected.pop((entry["role"], entry["kind"]))
        assert entry["candidate"] == src and entry["target"] == dst and entry["before"] == "ABSENT"
        data = Path(src).read_bytes()
        assert media.sha(data) == entry["after_sha256"]
        payloads[Path(dst)] = data
    assert not expected
    for dst, data in payloads.items():
        media.create_exact(dst, data)
    assert all(media.digest(dst) == media.sha(data) for dst, data in payloads.items())
    media.write_json(RECEIPT, {"scope": "INSTALLED_YIHONG_FLOORS_9_LEAVES_NO_CONSUMER_SWITCH",
                               "approved_plan_sha256": approved_sha, "targets": plan["targets"]})
    print("Installed 9 exact new media leaves; no consumer switch")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    commands = parser.add_mutually_exclusive_group(required=True)
    commands.add_argument("--prepare", action="store_true")
    commands.add_argument("--plan-after-import", type=Path)
    commands.add_argument("--install-approved-plan")
    args = parser.parse_args()
    if args.prepare:
        prepare()
    elif args.plan_after_import:
        propose(args.plan_after_import)
    else:
        install(args.install_approved_plan)
