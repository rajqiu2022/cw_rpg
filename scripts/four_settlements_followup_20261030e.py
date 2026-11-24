"""Exact new-domain follow-up: ferry arrival foot and tree/arrow visibility."""
import re
from four_settlements_20261030e import *
reg=ROOT/'game/build/three_towns_world_20261029j_system01/town_registry.gd';mp=reg.with_name('native_sources.json');manifest=json.loads(mp.read_text('utf-8'));oldreg=reg.read_text('utf-8');assert sha(mp) in oldreg
for path,digest in manifest['sources'].items():assert sha(ROOT/'game'/path[6:])==digest,path
backup=STAGE/'followup-backup';backup.mkdir();changed=[]
def edit(rel,text):
 p=ROOT/'game'/rel;shutil.copy2(p,backup/rel.replace('/','__'));p.write_text(text,'utf-8');changed.append(rel)
rel='build/four_settlements_20261030e_system01/locations.json';p=ROOT/'game'/rel;j=json.loads(p.read_text('utf-8'))
j['openworld_bailu_ferry']['returns']['openworld_east_sea_port']=[2830,1365]
j['openworld_east_sea_port']['returns']['openworld_bailu_ferry']=[3210,1715]
for id in ['linxi_tutorial','linxi_village_center','linxi_village_scrollmap']:j[id]['world_foot']=[2600,3999.12]
edit(rel,json.dumps(j,ensure_ascii=False,indent=2)+'\n')
rel='scenes/drafts/'+NAME+'/linxi_center.tscn';s=(ROOT/'game'/rel).read_text('utf-8');s,n=re.subn(r'(\[node name="Grove7"[^\n]+\]\n[^\[]*?position = )Vector2\([^)]+\)',r'\g<1>Vector2(1120, 2630)',s);assert n==1;edit(rel,s)
rel=ART+'/linxi_center.json';j=json.loads((ROOT/'game'/rel).read_text('utf-8'));next(o for o in j['objects'] if o['name']=='Grove7')['foot']=[1120,2630];edit(rel,json.dumps(j,ensure_ascii=False,indent=2)+'\n')
for rel in changed:manifest['sources']['res://'+rel]=sha(ROOT/'game'/rel)
shutil.copy2(mp,backup/mp.name);shutil.copy2(reg,backup/reg.name);save(mp,manifest);reg.write_text(re.sub(r'const NATIVE_SOURCE_SHA := "[0-9a-f]+"','const NATIVE_SOURCE_SHA := "'+sha(mp)+'"',oldreg),'utf-8')
# Import bookkeeping is from the same isolated import, never a global reimport.
leaves=[]
for file in ['wood_pier','willow','ferry_boat','repair_shed']:
 for p in (PROJECT/'.godot/imported').glob(file+'.png-*.md5'):
  dst=ROOT/'game/.godot/imported'/p.name;assert not dst.exists();shutil.copy2(p,dst);leaves.append(p.name)
save(STAGE/'followup.json',{'changed':changed,'md5_leaves':leaves,'registry_sha':sha(reg),'manifest_sha':sha(mp)})
