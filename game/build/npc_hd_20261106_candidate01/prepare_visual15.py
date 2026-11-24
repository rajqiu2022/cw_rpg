"""Finite visual fixture source inventory update, no engine or formal edits."""
from pathlib import Path
import json
O=Path(__file__).parent;R=O.resolve().parents[2]
p=O/'visual_sources.json';paths=json.loads(p.read_text())['source_paths']
paths.append('game/build/npc_hd_20261106_candidate01/source.twelve.candidate.json')
for source,row in json.loads((O/'source.next_four.candidate.json').read_text())['mappings'].items():
 paths.extend(['game/'+source[6:],'game/build/npc_hd_20261106_candidate01/'+Path(row['atlas']).name.replace('_20261106.png','_candidate.png')])
paths=list(dict.fromkeys(paths));assert all((R/f).is_file() for f in paths)
p.write_text(json.dumps({'source_paths':paths},indent=2))
print(json.dumps({'visual_sources':len(paths),'panels':15,'formal_families':2,'candidate_families':10}))
