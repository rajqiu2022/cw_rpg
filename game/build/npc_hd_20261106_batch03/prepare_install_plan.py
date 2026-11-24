"""Propose five native atlas triples plus the manifest; never install."""
from pathlib import Path
import json,hashlib,shutil
O=Path(__file__).resolve().parent;R=O.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
records=json.loads((O/'mipmap_import_plan.json').read_text())['records'];assert len(records)==5
manifest=R/'game/art/characters/pc_hd_20261102c/source.json'
adapter=R/'game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd'
before=json.loads((O/'mapping_plan.json').read_text());assert before['complete']
assert sha(manifest)==before['formal_manifest_before_sha256']
candidate=O/'source.merged.candidate.json'
old=json.loads(manifest.read_text());new=json.loads(candidate.read_text())
assert len(old['mappings'])==18 and len(new['mappings'])==23
assert all(new['mappings'][k]==v for k,v in old['mappings'].items())
targets=[]
for rec in records:
 for key,target in [('png',R/'game'/rec['res'][6:]),('import',R/'game'/(rec['res'][6:]+'.import')),('ctex',R/'game/.godot/imported'/Path(rec['ctex']).name)]:
  src=Path(rec[key]);assert src.is_file();assert not target.exists(),target
  targets.append({'candidate':str(src),'target':str(target),'before':'ABSENT','after_sha256':sha(src),'kind':key})
backup=O/'before/source.json';backup.parent.mkdir(exist_ok=True)
if backup.exists():assert sha(backup)==sha(manifest)
else:shutil.copyfile(manifest,backup)
targets.append({'candidate':str(candidate),'target':str(manifest),'before':sha(manifest),'backup':str(backup),'after_sha256':sha(candidate),'kind':'json_apply_patch'})
plan={'status':'PROPOSED_NOT_INSTALLED','write_count':16,'old_mappings_preserved':18,'new_mappings':5,'new_families':1,'new_frames':36,'adapter_frozen':{'path':str(adapter),'sha256':sha(adapter)},'targets':targets}
(O/'formal_install_plan.json').write_text(json.dumps(plan,indent=2))
print(json.dumps({'target_count':len(targets),'formal_writes':0,'adapter_frozen':sha(adapter)}))
