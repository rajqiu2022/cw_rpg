"""Read-only metadata import-key audit; no C call/engine/public request."""
from pathlib import Path
import json
import re

game=Path(__file__).resolve().parents[2]
m=json.loads((game/"data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json").read_text(encoding="utf-8"))
sources=m["legacy_source_sha256"]|m["runtime_authority_sha256"]|m["artifacts"]
extra=[]
for key in sources:
    import_key=key+".import"
    file=game/import_key.removeprefix("res://")
    if not file.is_file():continue
    if import_key not in sources:extra.append({"origin":key,"extra":import_key})
    for remap in re.findall(r'^path(?:\.[^=]+)?="(res://[^"]+)"',file.read_text(encoding="utf-8"),re.M):
        if remap not in sources:extra.append({"origin":key,"extra":remap})
print(json.dumps({"scope":"FIXED_MANIFEST_KEYS_EXISTING_IMPORT_REMAP_EXPANSION_ONLY","source_keys":len(sources),"extra_key_count":len({r['extra'] for r in extra}),"extra":extra},ensure_ascii=False))


