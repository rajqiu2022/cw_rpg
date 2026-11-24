"""Bounded read-only NPC source inventory; never opens save files or starts Godot."""
from pathlib import Path
import re,json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
GAME=ROOT/'game'
OUT=Path(__file__).parent
roots=list((GAME/'data/scenes').glob('*.tres'))+[GAME/'data/npcs/npc_catalog.tres', GAME/'scripts/field/field_walkable_controller.gd',GAME/'build/three_towns_world_20261029j_system01/town_registry.gd',GAME/'build/three_settlements_20261030e_system01/xiangzhou_author.gd',GAME/'build/three_settlements_20261030e_qinghe01/qinghe_author.gd',GAME/'build/three_settlements_20261030e_yanmen01/yanmen_author.gd']
queue=list(roots); seen=set(); sources={}
while queue:
    p=queue.pop(0)
    if p in seen or not p.is_file():continue
    if len(seen)>=550:raise RuntimeError('bounded source budget exceeded')
    seen.add(p)
    s=p.read_text(encoding='utf-8-sig',errors='replace')
    for ref in re.findall(r'res://[^\s\"\'<>]+',s):
        if any(x in ref.lower() for x in ['root_only','before_install','snapshot','qa_','capture','fixture','backup']):continue
        q=GAME/ref[6:]
        if q.suffix in ['.gd','.tscn'] and q.is_file():queue.append(q)
        if q.suffix=='.png' and '/art/characters/' in ref and 'portrait' not in ref and '/lengguyun' not in ref:
            sources.setdefault(ref,set()).add(p.relative_to(ROOT).as_posix())
records=[]
for ref,consumers in sorted(sources.items()):
    p=GAME/ref[6:]
    if not p.is_file():continue
    with Image.open(p) as im:
        w,h=im.size
        frames=max(1,w//h) if w>h and w%h==0 else 1
        alpha=im.convert('RGBA').getchannel('A')
        bounds=[alpha.crop((i*w//frames,0,(i+1)*w//frames,h)).point(lambda a:255 if a>=24 else 0).getbbox() for i in range(frames)]
        heights=[b[3]-b[1] for b in bounds if b]
    stem=re.sub(r'_(?:idle|walk|seated).*','',p.stem)
    records.append({'source':ref,'family_key':stem,'dimensions':[w,h],'square_cell_frames_inferred':frames,'alpha24_body_heights':heights,'native_min320':bool(heights and min(heights)>=320),'consumers':sorted(consumers)})
report={'scope':'Bounded authored-scene + selected live-host dependency source reference set; includes fallback and historical rows, NOT proof all are live after runtime projection. Dynamic string composed paths and catalog override priority require followup.','source_files_read':len(seen),'npc_png_reference_count':len(records),'family_keys':len(set(r['family_key'] for r in records)),'native_min320_pngs':sum(r['native_min320'] for r in records),'records':records,'source_files':sorted(p.relative_to(ROOT).as_posix() for p in seen)}
(OUT/'source_reference_inventory.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k not in ['records','source_files']},ensure_ascii=False))
for r in records:print(r['family_key'],r['dimensions'],min(r['alpha24_body_heights'] or [0]),'HD' if r['native_min320'] else 'LOW')
