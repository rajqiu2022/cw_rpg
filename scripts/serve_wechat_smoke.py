from __future__ import annotations

import argparse
import http.server
import urllib.parse
from pathlib import Path


PCK_MAGIC = b"GDPC"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Serve the common Web export and chapter PCKs for local smoke testing.")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    web_root = repo_root / "game" / "build" / "wechat_web"
    trial_root = repo_root / "game" / "build" / "wechat_trial"
    pack_root = trial_root / "packs"
    data_root = trial_root / "webgl"
    if not (web_root / "index.html").exists():
        raise SystemExit(f"Missing common Web export: {web_root}")
    expected_packs = {"chapter1_start.pck", "chapter1_late.pck", "chapter2.pck", "chapter3.pck"}
    actual_packs = {path.name for path in pack_root.glob("chapter*.pck")}
    if actual_packs != expected_packs:
        raise SystemExit(f"Expected {sorted(expected_packs)}, found {sorted(actual_packs)}: {pack_root}")
    pck_file = web_root / "index.pck"
    if not pck_file.exists() or pck_file.read_bytes()[:4] != PCK_MAGIC:
        raise SystemExit(
            f"Godot main pack is missing or malformed: {pck_file}. "
            "The WeChat runtime downloads this GDPC file directly instead of using the Unity data parser."
        )
    data_files = sorted(data_root.glob("*.data.bin"))
    if len(data_files) != 1:
        raise SystemExit(f"Expected exactly one transformed data container, found {data_files}: {data_root}")
    data_file = data_files[0]
    with data_file.open("rb") as stream:
        data_magic = stream.read(16)
    if data_magic != b"UnityWebData1.0\x00":
        raise SystemExit(f"WXGameKit data container is malformed: {data_file}")

    class Handler(http.server.SimpleHTTPRequestHandler):
        def translate_path(self, path: str) -> str:
            clean_path = urllib.parse.unquote(urllib.parse.urlparse(path).path)
            if clean_path == "/.data.bin":
                return str(data_file.resolve())
            if clean_path == f"/{data_file.name}":
                return str(data_file.resolve())
            if clean_path.startswith("/webgl/") and clean_path.endswith(".data.bin"):
                return str((data_root / clean_path.removeprefix("/webgl/")).resolve())
            if clean_path == "/packs" or clean_path.startswith("/packs/"):
                relative = clean_path.removeprefix("/packs").lstrip("/")
                return str((pack_root / relative).resolve())
            return str((web_root / clean_path.lstrip("/")).resolve())

        def end_headers(self) -> None:
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
            self.send_header("Cache-Control", "no-store")
            super().end_headers()

        def log_message(self, format_string: str, *values: object) -> None:
            print("[wechat-smoke] " + format_string % values, flush=True)

    server = http.server.ThreadingHTTPServer((args.bind, args.port), Handler)
    print(f"WeChat smoke server: http://{args.bind}:{args.port}/index.html", flush=True)
    print(f"Web root: {web_root}", flush=True)
    print(f"Pack root: {pack_root}", flush=True)
    print(f"Godot main pack: {pck_file}", flush=True)
    print(f"WXGameKit data container: {data_file}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
