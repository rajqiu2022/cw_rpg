"""Bounded static reachability coverage, not proof of spawned NPC instances.

Mirror npc_node's directional filename resolver exactly for these referenced
textures. Do not walk RAW/build trees or launch an engine/read saves.
"""
from pathlib import Path
import json,re
from PIL import Image
R=Path(__file__).resolve().parents[3]; O=Path(__file__).parent
inventory=json.loads((O/'source_reference_inventory.json').read_text(encoding='utf8'))
sources=[x for x in inventory['records'] if '/candidates/' not in x['source'] and '/battle_' not in x['source'] and not Path(x['source']).name.startswith(('hero_','protagonist_'))]
def family(path):
    name=Path(path).stem
    name=re.sub(r'_(?:idle|walk|seated|staff_dummy_practice|(?:down|up|left|right)_(?:idle|walk|conversation)).*','',name)
    name=re.sub(r'_v[0-9]+$','',name)
    return name
def candidates(source,facing):
    direction=next((d for d in ['down','up','left','right'] if '_'+d+'_' in source),None)
    if not direction:return []
    path=source.replace('_'+direction+'_','_'+facing+'_')
    variants=[path]+[path.replace('_v%d_'%v,'_') for v in range(2,10) if '_v%d_'%v in path]
    out=[]
    for p in variants:
        out.extend([p,p.replace('_idle_','_walk_')] if '_idle_' in p else [p.replace('_walk_','_idle_'),p])
    return out
groups={}
for x in sources:groups.setdefault(family(x['source']),[]).append(x)
pixel_cache={}
def pixels(path):
    if path not in pixel_cache:
        p=R/'game'/path[6:]
        with Image.open(p) as im:
            w,h=im.size;frames=w//h if w%h==0 else 1
            a=im.convert('RGBA').getchannel('A');b=[a.crop((i*w//frames,0,(i+1)*w//frames,h)).point(lambda v:255 if v>=24 else 0).getbbox() for i in range(frames)]
            heights=[v[3]-v[1] for v in b if v]
        pixel_cache[path]={'size':[w,h],'frames':frames,'body_heights':heights,'native_min320':bool(heights and min(heights)>=320)}
    return pixel_cache[path]
rows=[]
for fam,records in sorted(groups.items()):
    explicit=[x['source'] for x in records]
    resolved={};reachable=set(explicit)
    for path in explicit:
        # Explicit conversation_sprite_paths/priority are not inferred here.
        by_facing={}
        for world_facing,authored in [('down','down'),('up','up'),('left','right'),('right','left')]:
            selected=next((p for p in candidates(path,authored) if (R/'game'/p[6:]).is_file()),None)
            by_facing[world_facing]=selected
            if selected:reachable.add(selected)
        resolved[path]=by_facing
    rows.append({'family':fam,'referenced_sources':explicit,'conversation_file_resolution_without_explicit_override':resolved,'reachable_texture_paths':sorted(reachable),'native_hd_paths':[p for p in sorted(reachable) if pixels(p)['native_min320']],'low_paths':[p for p in sorted(reachable) if not pixels(p)['native_min320']]})
out={'scope':'STATIC REACHABILITY UPPER BOUND, not active-instance census. Source references include route/fallback and story-only actors. Does not account for dynamic NPC replacement or explicit conversation overrides. All actors retain existing directions/actions; no invented four-direction coverage.','family_count':len(rows),'reachable_unique_textures':len(pixel_cache),'native_hd_texture_count':sum(x['native_min320'] for x in pixel_cache.values()),'families':rows,'texture_measurements':pixel_cache}
(O/'action_coverage.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in out.items() if k not in ['families','texture_measurements']},ensure_ascii=False))
for r in rows:print(r['family'],len(r['reachable_texture_paths']),len(r['native_hd_paths']),len(r['low_paths']))
