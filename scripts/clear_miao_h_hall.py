"""Move the former small-house rock out of the new hall's frontage; keep native art intact."""
import json
import re
from miao_building_variety_20261029h import STAGE, PROJECT, SCENE
from build_redrock_town_20261028a import save, vec
p=PROJECT/SCENE;t=p.read_text('utf-8');layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
r=next(x for x in layout['objects'] if x['name']=='RockLedge9');assert r['foot']==[4600,1940];r['foot']=[4520,1620]
t,n=re.subn(r'(\[node name="RockLedge9"[^\n]*parent="Town"\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(r['foot']),t,count=1);assert n==1
p.write_text(t,'utf-8');save(STAGE/'layout.json',layout);save(STAGE/'hall-frontage-adjustment.json',{'name':'RockLedge9','before':[4600,1940],'after':r['foot'],'cause':'old little-house rock would visually cover the new broad hall veranda','native_PNG_changes':0})
