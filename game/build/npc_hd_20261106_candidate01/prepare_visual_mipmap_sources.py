"""Finite fixture consumer-source inventory; mechanical metadata only."""
from pathlib import Path
import json
O=Path(__file__).parent;R=O.resolve().parents[2]
paths=json.loads((O/'visual_sources.json').read_text())['source_paths']
for record in json.loads((O/'mipmap_import_plan.json').read_text())['records']:
 for key in ['png','import','ctex']:
  path=Path(record[key]).resolve();assert path.is_file(),path
  paths.append(path.relative_to(R).as_posix())
paths=list(dict.fromkeys(paths));assert all((R/p).is_file() for p in paths)
(O/'visual_mipmap_sources.json').write_text(json.dumps({'source_paths':paths},indent=2))
print(json.dumps({'source_paths':len(paths),'ctex':15,'engine_launched':False}))
