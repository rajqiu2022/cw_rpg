"""Diagnostic animation previews from runtime rects/anchors; never changes game assets."""
from pathlib import Path
from PIL import Image
import json
base=Path('F:/Code/RPG_GAME')
config=json.loads((base/'game/scripts/life_skills/gathering_actions_20261030l.json').read_text('utf-8'))
out=base/'assets/previews/sprite/gather_actions_20261030l';out.mkdir(parents=True,exist_ok=True)
for kind,action in config['actions'].items():
    source=Image.open(base/'game'/action['sheet'][6:]).convert('RGBA');frames=[]
    for spec in action['frames']:
        x,y,w,h=spec['rect'];scale=spec['scale'];sx,sy=spec['source_foot']
        frame=source.crop((x,y,x+w,y+h)).resize((round(w*scale),round(h*scale)),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(192,208),(35,40,40,255))
        canvas.alpha_composite(frame,(round(96-sx*scale),round(185-sy*scale)))
        frames.append(canvas.convert('RGB'))
    frames[0].save(out/f'{kind}_runtime_anchor_preview.gif',save_all=True,append_images=frames[1:],duration=round(action['duration']*1000/4),loop=0)
    strip=Image.new('RGB',(192*4,208),(35,40,40))
    for i,frame in enumerate(frames):strip.paste(frame,(i*192,0))
    strip.save(out/f'{kind}_runtime_anchor_contact.png')
print(str(out))
