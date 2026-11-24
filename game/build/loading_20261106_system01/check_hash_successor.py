"""Read-only formal/candidate source map and inverse check; no save or engine access."""
from pathlib import Path
import json,hashlib,base64
ROOT=Path(__file__).resolve().parents[3]
TASK=Path(__file__).resolve().parent
OUT=TASK/'hash_closure_READY01'
sha=lambda b:hashlib.sha256(b).hexdigest()
receipt=json.loads((OUT/'receipt.json').read_bytes());original=json.loads((OUT/'original_bytes.json').read_bytes())
overlays={r['target']: (ROOT/r['candidate']).read_bytes() for r in receipt['targets']}
checks=[];fail=[]
def check(label,value):
 checks.append({'label':label,'passed':bool(value)})
 if not value: fail.append(label)
def read_res(p):
 key='game/'+p[6:]
 return overlays[key] if key in overlays else (ROOT/key).read_bytes()
for row in receipt['targets']:
 p=row['target'];check('PARENT '+p,sha((ROOT/p).read_bytes())==row['old_sha256'])
 check('CANDIDATE '+p,sha(overlays[p])==row['new_sha256'])
for entry in json.loads((OUT/'all_hunks.json').read_bytes()):
 p=entry['target'];b=overlays[p]
 for h in reversed(entry['hunks']):
  at=h['new_offset'];n=h['new'].encode();o=h['old'].encode();check('SLICE '+p,b[at:at+len(n)]==n);b=b[:at]+o+b[at+len(n):]
 check('WHOLE INVERSE '+p,b==base64.b64decode(original['res://'+p[5:]]['base64']))
quarter='game/data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
sources=json.loads(overlays[quarter])['source_sha256']
for p,h in sources.items():
 check('SOURCE '+p,sha(read_res(p))==h)
print(json.dumps({'passed':not fail,'check_count':len(checks),'failures':fail,'source_count':len(sources),'scope':'READ_ONLY_OVERLAY_SOURCE_AND_INVERSE_NO_ENGINE_NO_SAVE'},ensure_ascii=False))
