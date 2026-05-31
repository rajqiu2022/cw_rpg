"""
Post-process and deploy all v0.9 generated assets to game directories.
- Protagonist idle strip (4 frames -> 640x160)
- Protagonist walk right strip (8 frames -> 1280x160)
- NPC sprites (single frame each)
- Protagonist avatar
- HUD player panel
"""
from PIL import Image
import io, os, sys, shutil
from pathlib import Path
from rembg import remove

PROJECT = Path(__file__).resolve().parent.parent
RAW = PROJECT / 'assets' / 'raw'
GAME = PROJECT / 'game' / 'art' / 'characters'
GAME_UI = PROJECT / 'game' / 'art' / 'ui' / 'field_hud' / 'v2'
GAME_PROPS = PROJECT / 'game' / 'art' / 'props'

TARGET_FRAME = 160

def process_single(src_path: Path, target_size: int = TARGET_FRAME, scale_content: float = 1.0) -> Image.Image:
    """Remove bg, crop, resize to fit target_size square."""
    with open(src_path, 'rb') as f:
        output = remove(f.read(), alpha_matting=True,
                        alpha_matting_foreground_threshold=240)
    img = Image.open(io.BytesIO(output)).convert('RGBA')
    bbox = img.split()[3].getbbox()
    if bbox:
        img = img.crop(bbox)
    w, h = img.size
    scale = target_size * scale_content / max(w, h)
    nw, nh = int(w * scale), int(h * scale)
    img = img.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    ox = (target_size - nw) // 2
    oy = (target_size - nh) // 2
    canvas.paste(img, (ox, oy), img)
    return canvas

def assemble_strip(frames: list[Image.Image], out_path: Path):
    """Assemble frames into horizontal sprite sheet."""
    n = len(frames)
    size = frames[0].size[0]
    strip = Image.new('RGBA', (size * n, size), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * size, 0), f)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    strip.save(str(out_path), 'PNG')
    print(f'  -> {out_path} ({strip.size})')

def process_strip(task_ids: list[str], out_name: str, raw_subdir: str = 'sprite/lengguyun', scale: float = 1.0):
    """Process a sequence into a sprite strip."""
    frames = []
    raw_dir = RAW / raw_subdir
    for tid in task_ids:
        path = raw_dir / f'{tid}.png'
        if not path.exists():
            print(f'  MISSING: {path}')
            return
        print(f'  {tid}')
        frames.append(process_single(path, scale_content=scale))
    assemble_strip(frames, GAME / out_name)

def deploy_single(task_id: str, out_name: str, raw_subdir: str, target_dir: Path = GAME,
                  target_size: int = TARGET_FRAME, scale: float = 1.0, skip_rembg: bool = False):
    """Process single frame and deploy."""
    src = RAW / raw_subdir / f'{task_id}.png'
    if not src.exists():
        print(f'  MISSING: {src}')
        return
    print(f'  {task_id}')
    if skip_rembg:
        img = Image.open(src).convert('RGBA')
    else:
        img = process_single(src, target_size=target_size, scale_content=scale)
    target_dir.mkdir(parents=True, exist_ok=True)
    out = target_dir / out_name
    img.save(str(out), 'PNG')
    print(f'  -> {out} ({img.size})')

def deploy_panel(task_id: str, out_name: str):
    """Deploy HUD panel: crop to content, no rembg needed."""
    src = RAW / 'ui' / 'field_hud' / f'{task_id}.png'
    if not src.exists():
        print(f'  MISSING: {src}')
        return
    print(f'  {task_id}')
    img = Image.open(src).convert('RGBA')

    # Find non-white content bounds
    w, h = img.size
    # Scan for panel bounds
    left, top, right, bottom = w, h, 0, 0
    for y in range(0, h, 4):
        for x in range(0, w, 4):
            r, g, b, a = img.getpixel((x, y))
            if r < 240 or g < 240 or b < 240:
                left = min(left, x)
                top = min(top, y)
                right = max(right, x)
                bottom = max(bottom, y)

    pad = 4
    left, top = max(0, left-pad), max(0, top-pad)
    right, bottom = min(w, right+pad), min(h, bottom+pad)
    cropped = img.crop((left, top, right, bottom))
    print(f'  Panel crop: ({left},{top})-({right},{bottom}) = {cropped.size}')

    GAME_UI.mkdir(parents=True, exist_ok=True)
    out = GAME_UI / out_name
    cropped.save(str(out), 'PNG')
    print(f'  -> {out} ({cropped.size})')

if __name__ == '__main__':
    print('=== 1. Idle Strip (4 frames) ===')
    process_strip(
        [f'sprite_lengguyun_idle_v3_f{i}' for i in range(1, 5)],
        'lengguyun_idle_right_4f.png',
        scale=1.0
    )

    print('\n=== 2. Walk Right Strip (8 frames) ===')
    process_strip(
        [f'sprite_lengguyun_walk_right_v3_f{i}' for i in range(1, 9)],
        'lengguyun_walk_right_8f.png',
        scale=1.0
    )

    print('\n=== 3. NPCs ===')
    deploy_single('sprite_shenbanzhan_idle_v2', 'npc_shenbanzhan_idle.png', 'sprite/npc', scale=0.85)
    deploy_single('sprite_duqingshan_idle_v2', 'npc_duqingshan_idle.png', 'sprite/npc', scale=0.85)

    print('\n=== 4. Protagonist Avatar ===')
    avatar_src = RAW / 'character' / 'portrait_protagonist_avatar_v3.png'
    if avatar_src.exists():
        with open(str(avatar_src), 'rb') as f:
            output = remove(f.read(), alpha_matting=True,
                            alpha_matting_foreground_threshold=240)
        img = Image.open(io.BytesIO(output)).convert('RGBA')
        bbox = img.split()[3].getbbox()
        if bbox:
            img = img.crop(bbox)
        w, h = img.size
        size = max(w, h)
        square = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        square.paste(img, ((size-w)//2, (size-h)//2), img)
        square = square.resize((512, 512), Image.LANCZOS)
        out = GAME / 'protagonist_neutral.png'
        square.save(str(out), 'PNG')
        print(f'  -> {out} ({square.size})')
    else:
        print(f'  MISSING: {avatar_src}')

    print('\n=== 5. HUD Player Panel ===')
    deploy_panel('ui_field_hud_player_panel_v6', 'hud_player_panel.png')

    print('\n=== Clearing Godot caches ===')
    import glob
    cache_dir = PROJECT / 'game' / '.godot' / 'imported'
    patterns = ['lengguyun_idle_right_4f*', 'lengguyun_walk_right_8f*',
                'npc_shenbanzhan*', 'npc_duqingshan*',
                'protagonist_neutral*', 'hud_player_panel*']
    for pat in patterns:
        for f in cache_dir.glob(pat):
            f.unlink()
            print(f'  Deleted cache: {f.name}')
    print('Done.')
