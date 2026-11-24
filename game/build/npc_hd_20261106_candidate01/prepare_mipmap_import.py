"""Mechanical import metadata preparation. No engine and no formal writes."""
from pathlib import Path
import hashlib,json,shutil,re
O=Path(__file__).parent; P=O/'import_mipmap_project'; R=O.resolve().parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
template=(O/'import_project/art/characters/pc_hd_20261102c/waiter_idle_down_20261106.png.import').read_text()
template=re.sub(r'^uid=.*\n','',template,flags=re.M).replace('mipmaps/generate=false','mipmaps/generate=true')
rows=json.loads((O/'source.twelve.candidate.json').read_text())['mappings']
formal=json.loads((R/'game/art/characters/pc_hd_20261102c/source.json').read_text())['mappings']
records=[]
for source,row in rows.items():
 res=row['atlas']; name=Path(res).name
 candidate=R/('game/'+res[6:]) if source in formal else O/name.replace('_20261106.png','_candidate.png')
 assert sha(candidate)==row['atlas_sha256']
 png=P/res[6:]; png.parent.mkdir(parents=True,exist_ok=True)
 assert not png.exists(), 'Use fresh isolated project; existing evidence not overwritten'
 shutil.copyfile(candidate,png)
 md5=hashlib.md5(res.encode()).hexdigest()
 text=template.replace('waiter_idle_down_20261106.png',name).replace('58bb655b4ed36df55fab471fb616f2f6',md5)
 sidecar=png.with_suffix('.png.import'); sidecar.write_text(text)
 records.append({'source':source,'png':str(png.resolve()),'sha256':row['atlas_sha256'],'res':res,'import':str(sidecar.resolve()),'ctex':str((P/'.godot/imported'/f'{name}-{md5}.ctex').resolve())})
assert len(records)==15
(O/'mipmap_import_plan.json').write_text(json.dumps({'formal_copy_allowed':False,'project':str(P.resolve()),'records':records},indent=2))
print(json.dumps({'isolated_pngs':15,'formal_copies':0,'base_png_exact':True,'mipmaps':True,'unique_import_uid':'engine generated'}))
