from four_settlements_20261030e import *
import re
p=PROJECT/'scenes/drafts'/NAME/'linxi_south.tscn';s=p.read_text('utf-8');s,n=re.subn(r'(\[node name="Jars1"[^\n]+\]\n[^\[]*?position = Vector2\()([\d.]+)(, [\d.]+\))',lambda m:m[1]+str(float(m[2])+160)+m[3],s);assert n==1;p.write_text(s,'utf-8')
p=PROJECT/ART/'linxi_south.json';j=json.loads(p.read_text('utf-8'));next(o for o in j['objects'] if o['name']=='Jars1')['foot'][0]+=160;save(p,j)
p=PROJECT/'doors04.gd';s=p.read_text('utf-8').replace('["linxi_master","linxi_center","linxi_south"]','["linxi_south"]').replace('door03','door05').replace('doors03.json','doors05.json');(PROJECT/'doors05.gd').write_text(s,'utf-8')
# The first failure is retained in doors03 stdout; separate the accidentally reused result filename.
shutil.copy2(PROJECT/'review/doors03.json',PROJECT/'review/doors04.actual.json')
