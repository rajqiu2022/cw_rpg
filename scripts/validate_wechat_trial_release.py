from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import urlparse


EXPECTED_PACKS = {
    "chapter1_start",
    "chapter1_late",
    "chapter2",
    "chapter3",
}
PCK_MAGIC = b"GDPC"
UNITY_WEB_DATA_MAGIC = b"UnityWebData1.0\x00"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate a converted WeChat trial before IDE import or upload.")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--require-real-credentials", action="store_true")
    parser.add_argument("--require-devtools-plugin", action="store_true")
    return parser.parse_args()


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def wasm_section_ids(path: Path) -> list[int]:
    sections: list[int] = []
    with path.open("rb") as stream:
        if stream.read(8) != b"\x00asm\x01\x00\x00\x00":
            return sections
        while True:
            raw_id = stream.read(1)
            if not raw_id:
                break
            section_id = raw_id[0]
            size = 0
            shift = 0
            while True:
                raw_size = stream.read(1)
                if not raw_size:
                    return []
                value = raw_size[0]
                size |= (value & 0x7F) << shift
                if value < 0x80:
                    break
                shift += 7
            sections.append(section_id)
            stream.seek(size, 1)
    return sections


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    game_root = repo_root / "game"
    output_root = game_root / "build" / "wechat_trial"
    mini_root = output_root / "minigame"
    report_path = output_root / "wechat-package-report.json"
    project_config_path = mini_root / "project.config.json"
    game_json_path = mini_root / "game.json"
    wx_game_kit_config_path = mini_root / "wx-game-kit" / "config.json"
    godot_runtime_adapter_path = mini_root / "wx-game-kit" / "custom" / "custom-instance.js"
    framework_path = mini_root / "framework.js"
    game_entry_path = mini_root / "game.js"
    trial_marker_path = mini_root / "WECHAT_TRIAL_PROJECT.txt"
    wechat_wasm_path = game_root / "build" / "wechat_web" / "index.wechat.compat.wasm"
    manifest_path = game_root / "build" / "wechat_pack_projects" / "common" / "config" / "wechat_content_packs.json"
    pack_root = output_root / "packs"

    failures: list[str] = []
    for path in (report_path, project_config_path, game_json_path, wx_game_kit_config_path, godot_runtime_adapter_path, framework_path, game_entry_path, trial_marker_path, wechat_wasm_path, manifest_path):
        if not path.exists():
            failures.append(f"missing required file: {path}")
    if failures:
        for failure in failures:
            print(f"[FAIL] {failure}")
        return 1

    report = read_json(report_path)
    project_config = read_json(project_config_path)
    game_json = read_json(game_json_path)
    wx_game_kit_config = read_json(wx_game_kit_config_path)
    manifest = read_json(manifest_path)
    app_id = str(report.get("appId", ""))
    cdn_url = str(report.get("cdnUrl", ""))
    data_config = wx_game_kit_config.get("launch", {}).get("data", {})
    godot_runtime_adapter = godot_runtime_adapter_path.read_text(encoding="utf-8")
    framework_source = framework_path.read_text(encoding="utf-8")
    game_entry = game_entry_path.read_text(encoding="utf-8")
    trial_marker = trial_marker_path.read_text(encoding="utf-8")
    pck_path = game_root / "build" / "wechat_web" / "index.pck"
    if pck_path.exists():
        with pck_path.open("rb") as stream:
            pck_has_magic = stream.read(4) == PCK_MAGIC
    else:
        pck_has_magic = False
    data_md5 = str(data_config.get("fileMD5", ""))
    wechat_wasm_sections = wasm_section_ids(wechat_wasm_path)
    data_path = output_root / "webgl" / f"{data_md5}.data.bin"
    if data_path.exists():
        with data_path.open("rb") as stream:
            data_prefix = stream.read(64)
    else:
        data_prefix = b""
    data_has_pack = False
    if data_prefix.startswith(UNITY_WEB_DATA_MAGIC) and len(data_prefix) >= 41:
        pack_offset = int.from_bytes(data_prefix[20:24], "little")
        pack_size = int.from_bytes(data_prefix[24:28], "little")
        name_size = int.from_bytes(data_prefix[28:32], "little")
        pack_name = data_prefix[32:32 + name_size]
        data_has_pack = pack_offset == 32 + name_size and pack_size == pck_path.stat().st_size and pack_name == b"index.pck"

    checks = {
        "project AppID matches the requested build AppID": str(project_config.get("appid", "")) == app_id,
        "project is a WeChat game": project_config.get("compileType") == "game",
        "project name is Yunying Xiazhuan": project_config.get("projectname") == "云影侠传",
        "tourist flag matches the AppID": bool(project_config.get("isGameTourist", False)) == (app_id == "touristappid"),
        "game orientation is landscape": game_json.get("deviceOrientation") == "landscape",
        "main package passes 4 MiB gate": bool(report.get("pass", {}).get("mainPackage", False)),
        "total code package passes 30 MiB gate": bool(report.get("pass", {}).get("totalCodePackage", False)),
        "Web export is fresh": bool(report.get("pass", {}).get("sourceFresh", False)),
        "converted framework syntax passed": bool(report.get("pass", {}).get("frameworkSyntax", False)),
        "WeChat runtime disables Wasm exception sections": (
            13 not in wechat_wasm_sections
            and bool(wechat_wasm_sections)
            and report.get("web", {}).get("wasmExceptions") is False
            and str(report.get("web", {}).get("runtimeVersion", "")) == "4.6.1"
            and str(wx_game_kit_config.get("project", {}).get("engine", {}).get("version", "")) == "4.6.1"
        ),
        "WXGameKit data container embeds the current Godot pack": (
            data_path.exists()
            and int(data_config.get("fileSize", -1)) == data_path.stat().st_size
            and int(data_config.get("optFileSize", -1)) == data_path.stat().st_size
            and bool(data_md5)
            and data_config.get("isCompressed") is False
            and data_has_pack
        ),
        "remote Godot PCK starts with GDPC magic": pck_has_magic,
        "Godot reuses the WXGameKit-mounted index.pck": (
            "--main-pack" in godot_runtime_adapter
            and "pthreadMainPrefixURL" in godot_runtime_adapter
            and "WebAssembly.RuntimeError" in godot_runtime_adapter
            and '"readAsync"' not in godot_runtime_adapter
            and '"readBinary"' not in godot_runtime_adapter
            and "godotMainPackUrl" not in godot_runtime_adapter
            and "wx.downloadFile" not in framework_source
            and "configureGodotWXGameKit(" in game_entry
        ),
        "runtime manifest declares four staged packs": set(manifest.get("packs", {})) == EXPECTED_PACKS,
        "official three-chapter trial marker is present": "微信小游戏前三章试玩工程" in trial_marker,
    }

    if args.require_devtools_plugin:
        uses_plugins = bool(game_json.get("plugins", {}))
        checks["WXGameKit plugin has a non-tourist AppID"] = not uses_plugins or (app_id.startswith("wx") and app_id != "touristappid")

    if args.require_real_credentials:
        parsed_cdn = urlparse(cdn_url)
        checks["real AppID is configured"] = app_id.startswith("wx") and app_id != "touristappid"
        checks["HTTPS CDN is configured"] = parsed_cdn.scheme == "https" and parsed_cdn.hostname not in {None, "localhost", "127.0.0.1"}

    for label, passed in checks.items():
        print(f"[{'PASS' if passed else 'FAIL'}] {label}")
        if not passed:
            failures.append(label)

    for pack_id, entry in manifest.get("packs", {}).items():
        pack_path = pack_root / str(entry.get("file", ""))
        if not pack_path.exists():
            failures.append(f"{pack_id}: file missing")
            print(f"[FAIL] {pack_id}: file missing")
            continue
        size_ok = pack_path.stat().st_size == int(entry.get("bytes", -1))
        hash_ok = file_sha256(pack_path) == str(entry.get("sha256", "")).lower()
        print(f"[{'PASS' if size_ok else 'FAIL'}] {pack_id}: byte size matches manifest")
        print(f"[{'PASS' if hash_ok else 'FAIL'}] {pack_id}: SHA-256 matches manifest")
        if not size_ok:
            failures.append(f"{pack_id}: byte size mismatch")
        if not hash_ok:
            failures.append(f"{pack_id}: SHA-256 mismatch")

    mode = "real" if args.require_real_credentials else "devtools" if args.require_devtools_plugin else "local"
    print(f"[WeChatReleasePreflight] failures={len(failures)} mode={mode}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
