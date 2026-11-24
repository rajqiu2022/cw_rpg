"""Prepare exactly five native atlases for isolated mipmap import. No engine."""
from pathlib import Path
import hashlib,json,shutil,re
O=Path(__file__).resolve().parent;R=O.parents[2];P=O/'import_project'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
plan=json.loads((O/'mapping_plan.json').read_text());assert plan['complete']
template=(R/'game/build/npc_hd_20261106_candidate01/import_project/art/characters/pc_hd_20261102c/waiter_idle_down_20261106.png.import').read_text()
template=re.sub(r'^uid=.*\n','',template,flags=re.M).replace('mipmaps/generate=false','mipmaps/generate=true')
mapping=json.loads((O/'source.batch03.candidate.json').read_text())['mappings'];receipts=json.loads((O/'preparation_receipt.json').read_text());assert len(mapping)==5
assert sum(x['framecount'] for x in mapping.values())==36
records=[]
for source,row in mapping.items():
 rec=next(x for x in receipts if x['candidate_sha256']==row['atlas_sha256']);candidate=Path(rec['candidate']);assert sha(candidate)==row['atlas_sha256']
 res=row['atlas'];name=Path(res).name;png=P/res[6:];png.parent.mkdir(parents=True,exist_ok=True);assert not png.exists()
 shutil.copyfile(candidate,png);md5=hashlib.md5(res.encode()).hexdigest()
 text=template.replace('waiter_idle_down_20261106.png',name).replace('58bb655b4ed36df55fab471fb616f2f6',md5)
 sidecar=png.with_suffix('.png.import');sidecar.write_text(text)
 records.append({'source':source,'png':str(png),'sha256':row['atlas_sha256'],'res':res,'import':str(sidecar),'ctex':str(P/'.godot/imported'/f'{name}-{md5}.ctex')})
(O/'mipmap_import_plan.json').write_text(json.dumps({'formal_copy_allowed':False,'project':str(P),'records':records},indent=2))
print(json.dumps({'isolated_inputs':len(records),'formal_copies':0,'mipmaps':True}))
