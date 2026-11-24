"""Create a finite source inventory for the isolated stair trip; never visit save paths."""
import hashlib
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[3]
here = Path(__file__).resolve().parent
previous = root / "game/build/interior_identity_20261106_system01/formal_trip_source_inventory.json"
media = root / "game/build/yihongyuan_floors_20261107_art01/floor_media_formal_install_plan.json"

if len(sys.argv) not in (3, 4):
    raise SystemExit("Usage: prepare_trip_inventory.py deployment-receipt SHA [trip.gd]")

receipt_path = Path(sys.argv[1]).resolve()
if not receipt_path.is_relative_to(root / "game/build"):
    raise SystemExit("Receipt must be a verified build artifact")
receipt = receipt_path.read_bytes()
if hashlib.sha256(receipt).hexdigest() != sys.argv[2].lower():
    raise SystemExit("Deployment receipt SHA mismatch")

paths = set(json.loads(previous.read_text(encoding="utf-8"))["source_paths"])
paths.add((here / (sys.argv[3] if len(sys.argv) == 4 else "stair_trip_ROOT_ONLY.gd")).relative_to(root).as_posix())
for record in json.loads(receipt)["targets"]:
    paths.add(Path(record["target"]).as_posix())
for record in json.loads(media.read_text(encoding="utf-8"))["targets"]:
    paths.add(Path(record["target"]).relative_to(root).as_posix())

for source in paths:
    parts = Path(source).parts
    if not parts or parts[0] != "game" or any(p.lower() in {"..", "app_userdata", "saves", "save", "appdata", "localappdata"} for p in parts):
        raise SystemExit(f"Out of protected source scope: {source}")
    path = (root / source).resolve()
    if not path.is_relative_to(root / "game") or not path.is_file():
        raise SystemExit(f"Unexpected source: {source}")

blob = (json.dumps({"source_paths": sorted(paths)}, indent=2) + "\n").encode()
destination = here / (Path(sys.argv[3]).stem + ".json" if len(sys.argv) == 4 else "trip_inventory.json")
with destination.open("xb") as output:
    output.write(blob)
print(f"{destination} {len(paths)} paths SHA256={hashlib.sha256(blob).hexdigest().upper()}")
