"""Generate isolated texture-import metadata, never copy candidates to formal game art."""
from pathlib import Path
import json,hashlib,shutil
O=Path(__file__).parent;P=O/'import_remaining_project';R=O.resolve().parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
template=(O/'import_project/art/characters/pc_hd_20261102c/waiter_idle_down_20261106.png.import').read_text()
rows={}
for manifest in ['source.reuse.candidate.json','source.next_four.candidate.json']:
 rows.update(json.loads((O/manifest).read_text())['mappings'])
records=[]
for source,row in rows.items():
 res=row['atlas'];name=Path(res).name;candidate=O/name.replace('_20261106.png','_candidate.png');assert sha(candidate)==row['atlas_sha256']
 png=P/res[6:];png.parent.mkdir(parents=True,exist_ok=True)
 if png.exists():assert sha(png)==row['atlas_sha256']
 else:shutil.copyfile(candidate,png)
 md5=hashlib.md5(res.encode()).hexdigest()
 text=template.replace('waiter_idle_down_20261106.png',name).replace('58bb655b4ed36df55fab471fb616f2f6',md5)
 sidecar=png.with_suffix('.png.import')
 if sidecar.exists():assert sidecar.read_text()==text
 else:sidecar.write_text(text)
 records.append({'source':source,'candidate':str(candidate.resolve()),'png':str(png.resolve()),'sha256':row['atlas_sha256'],'res':res,'import':str(sidecar.resolve()),'ctex':str((P/'.godot/imported'/f'{name}-{md5}.ctex').resolve())})
assert len(records)==13
(O/'remaining_import_plan.json').write_text(json.dumps({'formal_copy_allowed':False,'project':str(P.resolve()),'records':records},indent=2))
combined=json.loads((O/'source.combined.candidate.json').read_text());combined['mappings'].update(json.loads((O/'source.next_four.candidate.json').read_text())['mappings'])
(O/'source.twelve.candidate.json').write_text(json.dumps(combined,indent=2))
print(json.dumps({'isolated_candidate_pngs':13,'formal_copies':0,'family_count':12,'mappings':len(combined['mappings'])}))
