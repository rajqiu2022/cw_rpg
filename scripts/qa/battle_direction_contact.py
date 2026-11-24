"""Contact sheets of live battle resources; inspection only, no source mutation."""
import re
import sys
import json
import hashlib
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/previews/sprite/battle_direction_20260910'
OUT.mkdir(parents=True, exist_ok=True)
paths = set()
for folder in ('enemies', 'companions'):
    for source in (ROOT / 'game/data' / folder).glob('*.tres'):
        text = source.read_text(encoding='utf-8-sig')
        for path in re.findall(r'res://(art/sprites/battle/[^"\n]+_(?:ready|move|attack|hit|defeat)_\d+.png)', text):
            paths.add(re.sub(r'_(ready|move|attack|hit|defeat)_\d+.png$', '_ready_01.png', path))
for style in ('sword', 'dao', 'staff', 'palm', 'hidden'):
    version = 'v4' if style in ('sword', 'dao') else 'v3'
    paths.add(f'art/sprites/battle/weapon_variants_{version}/lengguyun/{style}/lengguyun_{style}_ready_01.png')
paths = sorted(paths)
frame_pair = (2, 4) if '--even' in sys.argv else (1, 3)
for page in range((len(paths) + 3) // 4):
    canvas = Image.new('RGB', (1280, 1120), '#727780')
    draw = ImageDraw.Draw(canvas)
    for row, path in enumerate(paths[page*4:page*4+4]):
        draw.text((5,row*280+3), path, fill='white')
        for state_i, state in enumerate(('ready','move','attack','hit','defeat')):
            for frame_i, frame in enumerate(frame_pair):
                src = ROOT / 'game' / path.replace('ready_01', f'{state}_{frame:02}')
                if not src.exists(): continue
                im = Image.open(src).convert('RGBA')
                im.thumbnail((128,220))
                canvas.paste(im, (state_i*256+frame_i*128,row*280+40), im)
                draw.text((state_i*256+frame_i*128,row*280+230), f'{state} {frame}', fill='white')
    canvas.save(OUT / f'live_{frame_pair[0]}_{page:02}.png')
print(f'{len(paths)} unique live ready roots; {(len(paths)+3)//4} pages -> {OUT}')

for style in ('sword', 'dao'):
    frames_dir = ROOT / f'game/art/sprites/battle/weapon_variants_v4/lengguyun/{style}'
    states = ('ready', 'move', 'attack', 'hit', 'defeat')
    contact = Image.new('RGB', (1024, 960), '#747b7f')
    for row, state in enumerate(states):
        animation = []
        for col in range(4):
            im = Image.open(frames_dir / f'lengguyun_{style}_{state}_{col+1:02}.png').convert('RGBA')
            flat = Image.new('RGBA', im.size, '#747b7f')
            flat.alpha_composite(im)
            animation.append(flat.convert('RGB'))
            contact.paste(flat.resize((256,192)), (col*256,row*192))
        animation[0].save(OUT / f'{style}_{state}.gif', save_all=True, append_images=animation[1:], duration=220, loop=0)
    contact.save(OUT / f'{style}_v4_contact.png')
    raw_dir = ROOT / 'assets/raw/sprite/battle/weapon_direction_20260910'
    raw = raw_dir / f'lengguyun_{style}_v4.png'
    manifest = {
        'backend': 'codex_builtin', 'model': 'codex-imagegen-built-in',
        'cost': None, 'currency': None, 'fallback_used': False,
        'generated_date': '2026-09-10',
        'prompt_summary': 'Edit the existing 4x5 atlas: identical blue-grey-robed ponytail protagonist; anatomical right-hand sword/dao grip in ready/move/attack/hit; all poses face screen right; left hand empty; pure magenta backdrop, full feet and blade, no VFX.',
        'raw': raw.relative_to(ROOT).as_posix(),
        'raw_sha256': hashlib.sha256(raw.read_bytes()).hexdigest(),
        'processing': 'remove_chroma_key --auto-key border --tolerance 80 --spill-cleanup --edge-contract 1; process_battle_sprite_atlas',
        'runtime': frames_dir.relative_to(ROOT).as_posix(),
        'frame_spec': '20 RGBA PNGs, 512x384, uniform ready-height 300px, bottom margin 12px',
        'handedness': 'anatomical right hand, checked visually across all 20 frames',
        'frames': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(frames_dir.glob('*.png'))},
    }
    (raw_dir / f'lengguyun_{style}_v4.meta.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
