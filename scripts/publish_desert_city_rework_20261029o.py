"""Publish exactly two native scenes and their three-town source successor."""
import re
from desert_city_rework_20261029o import *

BASE='build/three_towns_world_20261029j_system01/'
TARGETS=['scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn','scenes/drafts/desert_town_20261029d/desert_town.tscn',BASE+'world_spec.json',BASE+'native_sources.json',BASE+'town_registry.gd']
before={r['path']:r for r in json.loads((STAGE/'protected-before.json').read_text('utf-8'))}
assert not (STAGE/'publish.json').exists()
for rel in TARGETS:
    p=ROOT/'game'/rel
    assert sha(p)==before['game/'+rel]['sha256'], 'Concurrent target changed: '+rel
manifest=json.loads((PROJECT/BASE/'native_sources.json').read_text('utf-8'))
for path,digest in manifest['sources'].items():
    rel=path.removeprefix('res://')
    p=PROJECT/rel if rel in TARGETS or rel.startswith(ART+'/') else ROOT/'game'/rel
    assert p.is_file() and sha(p)==digest, 'Source mismatch: '+path
media=json.loads((STAGE/'media.json').read_text('utf-8'))
publish=[]
for m in media.values():
    rel=m['path'];p=PROJECT/rel
    assert not (ROOT/'game'/rel).exists()
    publish.extend([rel,rel+'.import'])
    for cached in re.findall(r'res://(\.godot/imported/[^"\]]+)',Path(str(p)+'.import').read_text('utf-8')):
        if cached not in publish:publish.append(cached)
        md5=Path(cached).with_suffix('.md5').as_posix()
        if (PROJECT/md5).exists() and md5 not in publish:publish.append(md5)
for rel in publish:
    assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
save_paths=json.loads((ROOT/'game/build/three_towns_world_20261029j_qa01/trips_READY.json').read_text('utf-8'))['registered_save_paths']
def facts(p):
    return {'path':str(p),'exists':p.is_file(),**({'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} if p.is_file() else {})}
protect=[ROOT/p for p in before if p not in ['game/'+r for r in TARGETS]]+[Path(p) for p in save_paths if not p.startswith('user://')]
save(STAGE/'publish-protected-before.json',[facts(p) for p in protect])
backups=[]
for rel in TARGETS:
    src=ROOT/'game'/rel;dest=STAGE/'backup'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest);assert sha(src)==sha(dest)
    backups.append({'path':rel,'sha256':sha(src)})
for rel in publish+TARGETS:
    dest=ROOT/'game'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,dest);assert sha(dest)==sha(PROJECT/rel)
assets=[]
for key,m in media.items():
    consumer=BASE+'world_spec.json' if key.startswith('world_') else TARGETS[0 if key=='redrock_cliff' else 1]
    assets.append({'key':key,'label':m['label'],'kind':'world_landmark' if key.startswith('world_') else ('terrain' if key=='redrock_cliff' else 'building'),'source':m['raw'],'processed':m['processed'],'output':'game/'+m['path'],'sha256':sha(ROOT/'game'/m['path']),'scenes':['res://'+consumer],'padding':m['padding'],'original_RGBA_preserved':True,'alpha_cleaned_pixels':0})
save(ROOT/'game'/ART/'resource-pack.json',{'status':'NATIVE_DENSITY_REPLACEMENTS_PUBLISHED_PENDING_FORMAL_WORLD_QA','assets':assets})
save(STAGE/'publish.json',{'changed_existing':[{**r,'after_sha256':sha(ROOT/'game'/r['path'])} for r in backups],'new_files':publish+['art/modules/'+NAME+'/resource-pack.json'],'router_changed':False,'imported_leaf_count':len([p for p in publish if p.startswith('.godot/')])})
save(STAGE/'capture01-receipt-correction.json',{'original_receipt':'capture01.run.json','actual_state':'OWN_PROCESS_STOPPED_AFTER_PARSE_FAILURE','pid':130464,'reason':'Unknown external resource from invalid resource header order; stopped only own failed runtime. Original receipt and stderr retained; not a natural-exit or passing run.'})
print('Published',len(TARGETS),'existing and',len(publish)+1,'new files')
