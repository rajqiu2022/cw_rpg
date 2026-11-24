"""Prepare a finite proposed successor; zero formal writes or implicit approval."""
from pathlib import Path
import hashlib,json
O=Path(__file__).parent;R=O.resolve().parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
combined=json.loads((O/'source.twelve.candidate.json').read_text());assert len(combined['mappings'])==15
combined['approved']=True
candidate_manifest=O/'source.formal15.candidate.json'
candidate_manifest.write_text(json.dumps(combined,indent=2))
plan=json.loads((O/'mipmap_import_plan.json').read_text());receipt=json.loads((O/'mipmap_import01/receipt.json').read_text())
assert receipt['exit_code']==0 and receipt['formal_copies']==0 and len(receipt['outputs'])==15
by_res={r['res']:r for r in receipt['outputs']}
entries=[]
def add(source,target,kind):
 source=Path(source);target=Path(target)
 entries.append({'kind':kind,'candidate':str(source.resolve()),'target':str(target.resolve()),'after_sha256':sha(source),'before_sha256':sha(target) if target.exists() else None,'write_needed':not target.exists() or sha(source)!=sha(target)})
for record in plan['records']:
 imported=by_res[record['res']]
 assert sha(Path(record['png']))==record['sha256']
 assert sha(Path(record['import']))==imported['import_sha'].lower()
 assert sha(Path(record['ctex']))==imported['ctex_sha'].lower()
 target=R/'game'/record['res'][6:]
 if target.exists():assert sha(target)==record['sha256'],'Do not overwrite other authored image'
 add(record['png'],target,'PNG_UNCHANGED_OR_NEW_NATIVE')
 add(record['import'],str(target)+'.import','MIPMAP_IMPORT_SIDECAR')
 add(record['ctex'],R/'game/.godot/imported'/Path(record['ctex']).name,'MIPMAP_CTEX')
add(O/'pc_sprite_view_runtime.sampling_candidate.gd',R/'game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd','TEXT_APPLY_PATCH_ONLY')
add(candidate_manifest,R/'game/art/characters/pc_hd_20261102c/source.json','TEXT_APPLY_PATCH_ONLY')
assert len(entries)==47
result={'status':'PROPOSED_ONLY_ROOT_ART_AND_EXPLICIT_INSTALL_PENDING','formal_writes_performed':0,'families':12,'new_mappings_total':15,'previously_installed_families':2,'additional_families':10,'preexisting_farmer_preserved':True,'real_save_content_access':False,'entries':entries,'requirements':['Root normal128px15panel acceptance','Exact existing-byte backup before any formal write','Apply patch adapter and manifest text only','Existing before hashes must all still match, absent targets remain absent','PNG level0 unchanged; only imported mip levels added','Do not claim independent four directions or all NPC coverage']}
(O/'formal_mipmap_install_plan.json').write_text(json.dumps(result,indent=2))
print(json.dumps({'entries':len(entries),'writes_proposed':sum(e['write_needed'] for e in entries),'existing_pngs_unchanged':2,'formal_writes':0}))
