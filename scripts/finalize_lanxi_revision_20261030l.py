from lanxi_revision_20261030l import *
native=GAME/'build/three_towns_world_20261029j_system01/native_sources.json';reg=native.with_name('town_registry.gd');j=json.loads(native.read_text('utf-8'));h=sha(native)
assert h in reg.read_text('utf-8');p=GAME/OLD;assert j['sources']['res://'+OLD]==sha(p)
shutil.copy2(p,STAGE/'published09.tscn')
s=p.read_text('utf-8');line='[ext_resource type="Texture2D" path="res://art/modules/miao_town_20261029f/terrace.png" id="terrace"]\n';assert s.count(line)==1
p.write_text(s.replace(line,''),'utf-8');(QA/'candidate.tscn').write_bytes(p.read_bytes())
j['sources']['res://'+OLD]=sha(p);save(native,j);reg.write_text(reg.read_text('utf-8').replace(h,sha(native)),'utf-8')
p=GAME/'art/modules/miao_terrain_20261029i/resource-pack.json';pack=json.loads(p.read_text('utf-8'));pack['reused_asset_keys']['miao_town_20261029f'].remove('terrace');save(p,pack)
save(STAGE/'publication10.json',{'scene':snapshot(GAME/OLD),'manifest':snapshot(native),'registry':snapshot(reg),'only_after09_scene_delta':'remove unused terrace Texture2D ext_resource; all nodes exact'})
print('heads',sha(GAME/OLD)[:8],sha(native)[:8],sha(reg)[:8])
