"""Move one palm off a projected wall face; no image or collision edits."""
import json
import re
from desert_town_20261029d import PROJECT, SCENE, STAGE
from build_redrock_town_20261028a import save, sha

p=PROJECT/SCENE;text=p.read_text('utf-8');old=sha(p)
pattern=r'(\[node name="DatePalm2"[^\n]*\]\nposition = )Vector2\([^\n]+'
text,n=re.subn(pattern,r'\g<1>Vector2(7440, 2940)',text,count=1);assert n==1
p.write_text(text,'utf-8')
layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
next(r for r in layout['objects'] if r['name']=='DatePalm2')['foot']=[7440,2940]
save(STAGE/'layout.json',layout)
save(STAGE/'palm-visual-fix.json',{'scene_before':old,'scene_after':sha(p),'only_move':'DatePalm2: 7040,2770 -> 7440,2940','reason':'root on visible sand beside court, not projected rear-wall face'})
