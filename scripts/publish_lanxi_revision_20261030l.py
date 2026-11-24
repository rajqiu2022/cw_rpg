from lanxi_revision_20261030l import *
native=GAME/'build/three_towns_world_20261029j_system01/native_sources.json';reg=native.with_name('town_registry.gd')
for rel in [OLD,str(native.relative_to(GAME)),str(reg.relative_to(GAME))]:
 assert sha(GAME/rel)==sha(STAGE/'backup'/rel),rel
j=json.loads(native.read_text('utf-8'))
for path,digest in j['sources'].items():assert sha(GAME/path[6:])==digest,path
old_header=sha(native)
(GAME/OLD).write_bytes((QA/'candidate.tscn').read_bytes())
for rel in [OLD,'build/'+NAME+'/controller.gd','build/'+NAME+'/ghost.gd','build/'+NAME+'/moved_objects.json','art/modules/miao_recompose_20261029g/rock_bank.png']:
 j['sources']['res://'+rel]=sha(GAME/rel)
save(native,j)
s=reg.read_text('utf-8');assert s.count(old_header)==1;reg.write_text(s.replace(old_header,sha(native)),'utf-8')
save(STAGE/'publication.json',{'scene':snapshot(GAME/OLD),'manifest':snapshot(native),'registry':snapshot(reg),'source_count':len(j['sources']),'new_sources':['controller.gd','ghost.gd','moved_objects.json','rock_bank.png']})
print('published',sha(GAME/OLD)[:8],sha(native)[:8],sha(reg)[:8],len(j['sources']))
