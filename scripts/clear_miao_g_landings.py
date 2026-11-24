"""Clear two geometrically evident landing conflicts before the first route test."""
import json
import re
from miao_recompose_20261029g import STAGE, PROJECT, SCENE
from build_redrock_town_20261028a import save, vec
p=PROJECT/SCENE;t=p.read_text('utf-8');layout=json.loads((STAGE/'layout.json').read_text('utf-8'));rows=[]
for name,foot,cause in [('RockLedge13',[2890,3590],'rock on east covered-bridge landing'),('PocketHome9',[5690,1690],'home covering third stair upper landing')]:
    r=next(x for x in layout['objects'] if x['name']==name);rows.append({'name':name,'before':r['foot'],'after':foot,'cause':cause});r['foot']=foot
    t,n=re.subn(r'(\[node name="'+name+r'"[^\n]*parent="Town"\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(foot),t,count=1);assert n==1
p.write_text(t,'utf-8');save(STAGE/'layout.json',layout);save(STAGE/'landing-precheck-adjustments.json',{'rows':rows,'runtime_runs_before':0})
