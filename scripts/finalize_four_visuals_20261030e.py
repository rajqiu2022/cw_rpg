from four_settlements_20261030e import *
import re
p=PROJECT/'scenes/drafts'/NAME/'donghai.tscn';s=p.read_text('utf-8');s,n=re.subn(r'(\[node name="BackHouse1"[^\n]+\]\n[^\[]*?position = )Vector2\([^)]+\)',r'\g<1>Vector2(1850, 3150)',s);assert n==1;p.write_text(s,'utf-8')
p=PROJECT/ART/'donghai.json';j=json.loads(p.read_text('utf-8'));next(o for o in j['objects'] if o['name']=='BackHouse1')['foot']=[1850,3150];save(p,j)
labels={'inn':'街边客栈','office':'渡口票房','warehouse':'货栈仓房','cottage':'临街民居','small_home':'木梁小宅','repair_shed':'日用作棚'}
for p in (PROJECT/ART).glob('*.json'):
 j=json.loads(p.read_text('utf-8'))
 if 'objects' not in j:continue
 scene=PROJECT/'scenes/drafts'/NAME/(p.stem+'.tscn');s=scene.read_text('utf-8')
 for o in j['objects']:
  if o['label'].isascii():
   old=o['label'];o['label']=labels.get(o['key'],'村坊建筑');s=s.replace('metadata/label = '+json.dumps(old),'metadata/label = '+json.dumps(o['label'],ensure_ascii=False))
 save(p,j);scene.write_text(s,'utf-8')
print('Separated port cottages; localized examination labels')
