from repair_town_layout_20261029r import *
BASE='build/three_towns_world_20261029j_system01/'
old={r['path']:r for r in json.loads((STAGE/'before.json').read_text('utf-8'))}
for rel in SCENES.values():assert sha(ROOT/'game'/rel)==old[str(ROOT/'game'/rel)]['sha256']
manifest_path=ROOT/'game'/BASE/'native_sources.json';registry_path=ROOT/'game'/BASE/'town_registry.gd'
manifest=json.loads(manifest_path.read_text('utf-8'));registry=registry_path.read_text('utf-8');old_sha=sha(manifest_path)
assert old_sha in registry
for path,digest in manifest['sources'].items():assert sha(ROOT/'game'/path[6:])==digest,path
new=['scripts/drafts/'+NAME+'/'+n+'.gd' for n in ['actor_ghost','desert_controller','redrock_controller','redrock_terrain']]
targets=list(SCENES.values())
for rel in new:assert not (ROOT/'game'/rel).exists()
for rel in targets+new:manifest['sources']['res://'+rel]=sha(PROJECT/rel)
extra='scripts/drafts/sect_maps_20261029k/terrain.gd';manifest['sources']['res://'+extra]=sha(ROOT/'game'/extra)
save(PROJECT/BASE/'native_sources.json',manifest);new_sha=sha(PROJECT/BASE/'native_sources.json')
(PROJECT/BASE/'town_registry.gd').write_text(registry.replace(old_sha,new_sha),'utf-8')
targets += [BASE+'native_sources.json',BASE+'town_registry.gd']
receipt=[]
for rel in targets:
    p=ROOT/'game'/rel;backup=STAGE/'publish-backup'/rel;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup)
    receipt.append({'path':rel,'before':sha(p),'after':sha(PROJECT/rel)})
for rel in targets+new:
    dest=ROOT/'game'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PROJECT/rel,dest)
save(STAGE/'publication.json',{'changed':receipt,'new':new,'PNG_changed':False,'Router_changed':False,'status':'published_pending_formal_actual'})
print('Published',len(targets),'existing targets and',len(new),'new helpers')
