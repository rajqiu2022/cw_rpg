"""Repair only the diagnosed two home domains and one patrol, keeping successful routes."""
import json
import re
from miao_recompose_20261029g import STAGE, PROJECT, SCENE, ART
from build_redrock_town_20261028a import save, vec, poly
p=PROJECT/SCENE;t=p.read_text('utf-8');layout=json.loads((STAGE/'layout.json').read_text('utf-8'));rows=[]
for name,foot,cause in [('PocketHome11',[2420,1980],'DyeWorker route at2110'),('PocketHome13',[6500,2340],'grain destination and Farmer route2510')]:
    r=next(x for x in layout['objects'] if x['name']==name);old=r['foot'];rows.append({'name':name,'before':old,'after':foot,'cause':cause});r['foot']=foot
    t,n=re.subn(r'(\[node name="'+name+r'"[^\n]*parent="Town"\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(foot),t,count=1);assert n==1
    shader=PROJECT/ART/'ground.gdshader';g=shader.read_text('utf-8');g=g.replace('p-vec2('+str(old[0])+','+str(old[1]+20)+')','p-vec2('+str(foot[0])+','+str(foot[1]+20)+')');shader.write_text(g,'utf-8')
route=[[3890,2480],[4340,2480]]
t,n=re.subn(r'(\[node name="PlazaCraftsman"[^\n]*\]\n)position = [^\n]+',lambda m:m[1]+'position = '+vec(route[0]),t,count=1);assert n==1
parts=re.split(r'(?=\[node )',t)
for i,b in enumerate(parts):
    if b.startswith('[node name="PlazaCraftsman" '):parts[i]=re.sub(r'^route = [^\n]+','route = '+poly(route),b,flags=re.M)
p.write_text(''.join(parts),'utf-8');next(r for r in layout['patrols'] if r['name']=='PlazaCraftsman')['route']=route
save(STAGE/'layout.json',layout);save(STAGE/'residual-repair.json',{'homes':rows,'plaza_route_after':route,'oracle_correction':'1050,2300 is outside the diagonal creek; actual center1362.5,2300','first_65_6_FAIL_preserved':True,'previous_successful_bridges_stairs_imports_not_repeated':True})
