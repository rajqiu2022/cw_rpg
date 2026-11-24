"""Read only monk occupation records; never runs builders or writes files."""
import hashlib
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[3]
catalog = ROOT / "docs/equipment-skill-catalog.html"
source = catalog.read_text(encoding="utf-8")
match = re.search(r'<script id="catalogData" type="application/json">(.*?)</script>', source, re.S)
assert match, "Existing embedded resource index required"
payload = json.loads(match.group(1))
records = payload["resources"]["records"]
terms = re.compile(r"monk|abbot|shaolin|和尚|僧人|老僧|禅师|方丈|守窟|守钟", re.I)
selected = []
for row in records:
    raw = json.dumps(row, ensure_ascii=False)
    if terms.search(raw):
        selected.append(row)
print(json.dumps({"index":str(catalog), "index_sha256":hashlib.sha256(catalog.read_bytes()).hexdigest(), "selected_occupation_records":selected}, ensure_ascii=False, indent=2))
