"""Publish only the six native maps and one additive registry extension."""
import re
from four_settlements_20261030e import *
from prepare_four_settlements_host_20261030e import HOST,ROWS
def publish():
 reg=ROOT/'game/build/three_towns_world_20261029j_system01/town_registry.gd';manifest=reg.with_name('native_sources.json');old=reg.read_text('utf-8');j=json.loads(manifest.read_text('utf-8'))
 assert sha(manifest) in old
 for path,digest in j['sources'].items():assert sha(ROOT/'game'/path[6:])==digest,path
 assert 'four_settlements_20261030e' not in old
 backup=STAGE/'publication-backup';backup.mkdir();shutil.copy2(reg,backup/reg.name);shutil.copy2(manifest,backup/manifest.name)
 copies=[]
 for folder in [ART,'scenes/drafts/'+NAME,'scripts/drafts/'+NAME]:
  for p in (PROJECT/folder).rglob('*'):
   if p.is_file():copies.append((p,p.relative_to(PROJECT)))
 for p in (STAGE/'ready'/HOST).rglob('*'):
  if p.is_file():copies.append((p,p.relative_to(STAGE/'ready')))
 for src,rel in copies:
  target=ROOT/'game'/rel;assert not target.exists(),target;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,target)
  if target.suffix not in ['.uid','.import']:j['sources']['res://'+rel.as_posix()]=sha(target)
 leaves=[]
 for src,rel in copies:
  if src.suffix=='.import':
   for leaf in set(re.findall(r'res://(\.godot/imported/[^"\]]+)',src.read_text('utf-8'))):
    target=ROOT/'game'/leaf;assert not target.exists();shutil.copy2(PROJECT/leaf,target);leaves.append(leaf)
 for id in ROWS:
  p=ROOT/'game/data/scenes'/(id+'.tres');j['sources']['res://'+p.relative_to(ROOT/'game').as_posix()]=sha(p)
  for m in re.findall(r'path="res://(data/maps/[^"]+)"',p.read_text('utf-8')):j['sources']['res://'+m]=sha(ROOT/'game'/m)
 # All inherited geometry/host dependencies remain pinned too.
 for rel in ['build/sect_completion_20261030a_system01/sect_field.gd','scripts/drafts/sect_completion_20261030a/controller.gd','scripts/drafts/sect_completion_20261030a/ghost.gd','scripts/drafts/sect_maps_20261029k/controller.gd','scripts/drafts/sect_maps_20261029k/terrain.gd']:
  path='res://'+rel
  if path in j['sources']:assert j['sources'][path]==sha(ROOT/'game'/rel)
  else:j['sources'][path]=sha(ROOT/'game'/rel)
 save(manifest,j)
 new=old.replace('const VERSION := 1','const VERSION := 1\nconst SETTLEMENTS=preload("res://'+HOST+'locations.gd")')
 new=re.sub(r'(const IDS := \[[^\n]*)(\])',lambda m:m[1]+','+','.join('&'+json.dumps(k) for k in ROWS)+m[2],new,count=1)
 new=new.replace('static func town(id: StringName) -> Dictionary:\n','static func town(id: StringName) -> Dictionary:\n\tif SETTLEMENTS.IDS.has(id):return SETTLEMENTS.town(id)\n')
 new=new.replace('static func start(router: Node,id: StringName,requested: Variant,action: String,version: int) -> bool:\n','static func start(router: Node,id: StringName,requested: Variant,action: String,version: int) -> bool:\n\tif SETTLEMENTS.IDS.has(id):return SETTLEMENTS.start(router,id,requested,action,version) if source_valid() else false\n')
 new=re.sub(r'const NATIVE_SOURCE_SHA := "[0-9a-f]+"','const NATIVE_SOURCE_SHA := "'+sha(manifest)+'"',new);assert reg.read_text('utf-8')==old;reg.write_text(new,'utf-8')
 save(STAGE/'publication.json',{'new_files':[rel.as_posix() for _,rel in copies],'new_import_leaves':leaves,'registry_sha':sha(reg),'native_sources_sha':sha(manifest),'sources':len(j['sources'])});print('published',len(copies),'files',len(leaves),'leaves')
if __name__=='__main__':publish()
