"""Move only three door-blocking jar groups; preserve already baked geometry."""
import re
from four_settlements_20261030e import *
for key in ['linxi_master','linxi_center','linxi_south']:
 p=PROJECT/'scenes/drafts'/NAME/(key+'.tscn');s=p.read_text('utf-8');pattern=r'(\[node name="Jars0"[^\n]+\]\n[^\[]*?position = Vector2\()([\d.]+)(, [\d.]+\))'
 s,n=re.subn(pattern,lambda m:m[1]+str(float(m[2])+160)+m[3],s);assert n==1
 p.write_text(s,'utf-8');p=PROJECT/ART/(key+'.json');j=json.loads(p.read_text('utf-8'));o=next(o for o in j['objects'] if o['name']=='Jars0');o['foot'][0]+=160;save(p,j)
print('Moved three jars away from doorway feet')
