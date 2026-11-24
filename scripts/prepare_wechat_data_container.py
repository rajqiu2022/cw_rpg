from __future__ import annotations

import argparse
import shutil
import struct
from pathlib import Path


MAGIC = b"UnityWebData1.0\x00"
PCK_MAGIC = b"GDPC"
ENTRY_NAME = b"index.pck"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Wrap a Godot PCK in the data container expected by WXGameKit.")
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    if source == output:
        raise SystemExit("Source and output must be different files.")
    if not source.is_file():
        raise SystemExit(f"Godot PCK is missing or malformed: {source}")
    with source.open("rb") as probe:
        has_pck_magic = probe.read(4) == PCK_MAGIC
    if not has_pck_magic:
        raise SystemExit(f"Godot PCK is missing or malformed: {source}")

    pack_size = source.stat().st_size
    header_size = len(MAGIC) + 4 + 12 + len(ENTRY_NAME)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as target, source.open("rb") as payload:
        target.write(MAGIC)
        target.write(struct.pack("<I", header_size))
        target.write(struct.pack("<III", header_size, pack_size, len(ENTRY_NAME)))
        target.write(ENTRY_NAME)
        shutil.copyfileobj(payload, target, length=4 * 1024 * 1024)

    expected_size = header_size + pack_size
    if output.stat().st_size != expected_size:
        raise SystemExit(f"Container size mismatch: expected {expected_size}, got {output.stat().st_size}")
    print(f"Prepared WXGameKit data container: {output} ({expected_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
