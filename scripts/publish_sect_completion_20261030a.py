"""Publish scoped native sect entry replacements with unchanged story resources."""
import re
from sect_completion_20261030a import *
assert not (STAGE/'publication.json').exists()
assert json.loads((PROJECT/'review/finish03.json').read_text('utf-8'))['failures']==0
assert json.loads((PROJECT/'review/verify02.json').read_text('utf-8'))['failures']==0
# Visual-only finish after looking at the native screenshots.
p=PROJECT/'scenes/drafts'/NAME/'lieyun.tscn';s=p.read_text('utf-8').replace('res://art/modules/miao_recompose_20261029g/woodland_floor.png','res://art/modules/sect_maps_20261029k/quiet_ground.png');p.write_text(s,'utf-8')
p=PROJECT/ART/'lieyun_ground.gdshader';s=p.read_text('utf-8').replace('vec3 grass=texture(earth_tex,p/1254.).rgb;','vec3 grass=mix(texture(earth_tex,p/1254.).rgb,texture(dirt_tex,p/800.).rgb,0.55);');p.write_text(s,'utf-8')
# Move only the eastern staff rack out of the curved bank's visible stones.
p=PROJECT/'scenes/drafts'/NAME/'lingyue.tscn';s=p.read_text('utf-8');a=s.index('[node name="StaffRack1"');b=s.index('\n[node ',a+1);s=s[:a]+s[a:b].replace('Vector2(2220, 1960)','Vector2(2060, 1960)')+s[b:];p.write_text(s,'utf-8')
p=PROJECT/ART/'lingyue.json';j=json.loads(p.read_text('utf-8'))
for o in j['objects']:
 if o['name']=='StaffRack1':o['foot']=[2060,1960]
save(p,j)
sysdir='build/'+NAME+'_system01'
(PROJECT/sysdir).mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'scripts/templates'/NAME/'sect_field.gd',PROJECT/sysdir/'sect_field.gd')
(PROJECT/sysdir/'sect_field.tscn').write_text('[gd_scene load_steps=3 format=3]\n[ext_resource type="PackedScene" path="res://scenes/field_walkable.tscn" id="1"]\n[ext_resource type="Script" path="res://'+sysdir+'/sect_field.gd" id="2"]\n[node name="NativeSectField" instance=ExtResource("1")]\nscript = ExtResource("2")\n','utf-8')
prefixes=[ART,'scripts/drafts/'+NAME,'scenes/drafts/'+NAME,sysdir]
rels=[p.relative_to(PROJECT).as_posix() for prefix in prefixes for p in (PROJECT/prefix).rglob('*') if p.is_file() and p.name not in ['verify01.gd','sect_field.gd']]
rels.append(sysdir+'/sect_field.gd')
leaves=[]
for src in (PROJECT/ART).glob('*.png.import'):
 for rel in set(re.findall(r'res://(\.godot/imported/[^"\]]+)',src.read_text('utf-8'))):
  assert (PROJECT/rel).is_file();leaves.append(rel)
  md5=str(Path(rel).with_suffix('.md5')).replace('\\','/')
  if (PROJECT/md5).exists():leaves.append(md5)
rels=sorted(set(rels+leaves));assert all(not (ROOT/'game'/r).exists() for r in rels)
base=ROOT/'game/build/three_towns_world_20261029j_system01';mp=base/'native_sources.json';rp=base/'town_registry.gd'
oldm=json.loads(mp.read_text('utf-8'));oldr=rp.read_text('utf-8');assert sha(mp) in oldr
for path,digest in oldm['sources'].items():assert sha(ROOT/'game'/path[6:])==digest,path
protect=[rp,mp,ROOT/'game/scripts/autoload/scene_router.gd',ROOT/'game/project.godot',ROOT/'prompts/tasks.yaml']
protect += [ROOT/'game/data/scenes'/ (x+'.tres') for x in ['ch2_s4_lingyue_gate','ch7_s1_lieyun_valley_ferry','ch7_s2_mingwu_tea_town']]
protect += [ROOT/'game/data/maps'/(x+'_layout_v1.tres') for x in ['ch2_s4_lingyue_gate','ch7_s1_lieyun_valley_ferry','ch7_s2_mingwu_tea_town']]
prior=json.loads((ROOT/'assets/staging/town_layout_20261029r/before.json').read_text('utf-8'))
protect += [Path(r['path']) for r in prior if 'save' in r['path'].lower() and Path(r['path']).is_file()]
save(STAGE/'protected-before-publication.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in protect])
for p in [rp,mp]:
 d=STAGE/'publish-backup'/p.name;d.parent.mkdir(exist_ok=True);shutil.copy2(p,d)
for rel in rels:
 d=ROOT/'game'/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PROJECT/rel,d)
newm=json.loads(json.dumps(oldm));scene_prefix='scenes/drafts/'+NAME+'/'
# Pin new outdoor sources and exact original business data. The shared Router/Field remain untouched.
pending=[scene_prefix+k+'.tscn' for k in ['lingyue','lieyun','mingwu']]+[sysdir+'/sect_field.gd',sysdir+'/sect_field.tscn']
seen=set()
while pending:
 rel=pending.pop()
 if rel in seen:continue
 seen.add(rel);p=ROOT/'game'/rel
 if not p.is_file():continue
 if rel.startswith(('scripts/drafts/','scenes/drafts/','art/modules/',sysdir)):
  newm['sources']['res://'+rel]=sha(p)
  if p.suffix in ['.tscn','.gd','.json','.gdshader']:
   pending+=re.findall(r'res://([^"\s)]+)',p.read_text('utf-8'))
for p in protect:
 if '/data/' in p.as_posix():newm['sources']['res://'+p.relative_to(ROOT/'game').as_posix()]=sha(p)
save(mp,newm)
sectids='[&"ch2_s4_lingyue_gate",&"ch7_s1_lieyun_valley_ferry",&"ch7_s2_mingwu_tea_town"]'
newr=oldr.replace('const IDS := [&"openworld_redrock_town", &"openworld_desert_city", &"openworld_lanxi_zhai"]','const SECT_IDS := '+sectids+'\nconst IDS := [&"openworld_redrock_town", &"openworld_desert_city", &"openworld_lanxi_zhai",&"ch2_s4_lingyue_gate",&"ch7_s1_lieyun_valley_ferry",&"ch7_s2_mingwu_tea_town"]')
entries=''
for id,key,label,size,arrival,inner,source in [
 ('ch2_s4_lingyue_gate','lingyue','凌月派',(4800,3600),(1900,3370),(3250,1120),'openworld_lingyue_inner_court'),
 ('ch7_s1_lieyun_valley_ferry','lieyun','烈云谷',(4800,4000),(2600,3730),(3100,1160),'ch7_s3_lieyun_outpost_outer_ward'),
 ('ch7_s2_mingwu_tea_town','mingwu','茗雾山庄',(5600,3800),(1700,3470),(4080,1350),'ch7_s4_mingwu_manor_outer_court')]:
  v=lambda t:'Vector2('+','.join(map(str,t))+')'
  entries+='\t\t&"'+id+'":\n\t\t\treturn {"id":id,"label":"'+label+'","scene":"res://'+scene_prefix+key+'.tscn","size":'+v(size)+',"arrival":'+v(arrival)+',"inner_arrival":'+v(inner)+',"inner_source":&"'+source+'","sect":true}\n'
newr=newr.replace('\treturn {}\n\nstatic func portal_rows()',entries+'\treturn {}\n\nstatic func portal_rows()',1)
newr=newr.replace('for id: StringName in IDS:','for id: StringName in IDS.slice(0,3):')
needle='\tif router.call("is_world_map_scene",current):foot=row.arrival/row.size'
newr=newr.replace(needle,'\tif row.get("sect",false):\n\t\tvar known:Dictionary=router.get("_local_layout_versions")\n\t\tif not same or (version<1 and int(known.get(String(id),0))<1):foot=row.arrival/row.size\n\t\tif current==row.inner_source:foot=row.inner_arrival/row.size\n'+needle)
newr=newr.replace('router.call("_transition_to",FIELD,&"field",','router.call("_transition_to","res://'+sysdir+'/sect_field.tscn" if row.get("sect",false) else FIELD,&"field",')
newr=newr.replace(sha(STAGE/'publish-backup/native_sources.json'),sha(mp));assert newr!=oldr;rp.write_text(newr,'utf-8')
save(STAGE/'publication.json',{'status':'PUBLISHED_PENDING_FORMAL_QA','files':[{'path':'game/'+r,'sha256':sha(ROOT/'game'/r)} for r in rels],'new_import_leaves':len(leaves),'changed':[{'path':str(p),'before':sha(STAGE/'publish-backup'/p.name),'after':sha(p)} for p in [rp,mp]],'Router_written':False,'original_story_resources_written':False})
print('Published',len(rels),'new files, retained original business data; formal verification pending')
