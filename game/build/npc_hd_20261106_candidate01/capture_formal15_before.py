"""Explicit Root-requested exact-byte capture, zero formal writes."""
from pathlib import Path
import hashlib,json,shutil
O=Path(__file__).parent;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
plan=json.loads((O/'formal_mipmap_install_plan.json').read_text())
B=O/'before_formal15';assert not B.exists(),'Keep prior evidence; do not overwrite'
# Validate all targets and candidate bytes before making any capture.
for e in plan['entries']:
 s=Path(e['candidate']);t=Path(e['target'])
 assert sha(s)==e['after_sha256'],s
 assert (sha(t) if t.exists() else None)==e['before_sha256'],t
B.mkdir()
records=[]
for i,e in enumerate(plan['entries']):
 t=Path(e['target']);r=dict(e)
 if t.exists():
  backup=B/f'{i:02d}_{t.name}.before.bin';shutil.copyfile(t,backup)
  assert sha(backup)==e['before_sha256']
  st=t.stat();r.update(backup=str(backup.resolve()),before_bytes=st.st_size,before_mtime_ns=st.st_mtime_ns)
 else:r.update(backup=None,before_bytes=None,before_mtime_ns=None)
 records.append(r)
result={'status':'EXACT_BEFORE_CAPTURED_ROOT_INSTALL_REVIEW_PENDING','formal_writes':0,'entries':records,'planned_writes':sum(e['write_needed'] for e in records),'frozen_existing_pngs':2,'real_save_content_access':False,'normal_visual_evidence':'Root visual03 actual130952 natural0;15base exact/15panels fail0;Root accepted first-frame actual-scale identity/proportion/minification only. Body128world, viewport1920x1080,screenshot1334x750;not128screenpixels.'}
(O/'formal15_before_receipt.json').write_text(json.dumps(result,indent=2))
print(json.dumps({'planned_writes':result['planned_writes'],'existing_targets_backed_up':sum(r['backup'] is not None for r in records),'absent_targets':sum(r['backup'] is None for r in records),'formal_writes':0}))
