"""
Post-process generated sprite frames into sprite sheets.
1. rembg remove background from each frame
2. Crop to content, resize to 160x160
3. Assemble into horizontal strip
"""
from PIL import Image
import io
import os
import sys
from pathlib import Path
from rembg import remove

PROJECT = Path(__file__).resolve().parent.parent
RAW = PROJECT / 'assets' / 'raw'
PROC = PROJECT / 'assets' / 'processed'
GAME = PROJECT / 'game' / 'art' / 'characters'

TARGET_FRAME = 160  # px per frame

def process_single_frame(src_path: str) -> Image.Image:
    """Remove bg, crop to content, resize to target frame size."""
    with open(src_path, 'rb') as f:
        output = remove(f.read(), alpha_matting=True,
                        alpha_matting_foreground_threshold=240)
    img = Image.open(io.BytesIO(output)).convert('RGBA')

    # Find content bounds
    bbox = img.split()[3].getbbox()
    if bbox:
        img = img.crop(bbox)

    # Resize to fit target frame while keeping aspect ratio
    w, h = img.size
    scale = TARGET_FRAME / max(w, h)
    new_w, new_h = int(w * scale), int(h * scale)
    img = img.resize((new_w, new_h), Image.LANCZOS)

    # Center in TARGET_FRAME square
    canvas = Image.new('RGBA', (TARGET_FRAME, TARGET_FRAME), (0, 0, 0, 0))
    ox = (TARGET_FRAME - new_w) // 2
    oy = (TARGET_FRAME - new_h) // 2
    canvas.paste(img, (ox, oy), img)
    return canvas

def assemble_strip(frames: list[Image.Image], out_path: str):
    """Assemble frames into a horizontal sprite sheet."""
    n = len(frames)
    strip = Image.new('RGBA', (TARGET_FRAME * n, TARGET_FRAME), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * TARGET_FRAME, 0), frame)
    strip.save(out_path, 'PNG')
    print(f'  -> {out_path} ({strip.size})')

def process_sequence(task_ids: list[str], out_name: str, out_dir: str = GAME):
    """Process a sequence of frames into a sprite strip."""
    frames = []
    raw_dir = RAW / 'sprite' / 'lengguyun'
    for tid in task_ids:
        path = raw_dir / f'{tid}.png'
        if not path.exists():
            print(f'  MISSING: {path}')
            return False
        print(f'  Processing: {tid}.png')
        frame = process_single_frame(str(path))
        frames.append(frame)

    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, out_name)
    assemble_strip(frames, out_path)
    return True

if __name__ == '__main__':
    print('=== Processing Idle Right Strip ===')
    idle_ids = [f'sprite_lengguyun_idle_v2_f{i}' for i in range(1, 5)]
    process_sequence(idle_ids, 'lengguyun_idle_right_4f.png')

    print('\n=== Processing Walk Right Strip ===')
    walk_ids = [f'sprite_lengguyun_walk_right_v2_f{i}' for i in range(1, 9)]
    process_sequence(walk_ids, 'lengguyun_walk_right_8f.png')

    print('\n=== Processing NPCs ===')
    for npc_id, out_name in [
        ('sprite_shenbanzhan_idle_v1', 'npc_shenbanzhan_idle.png'),
        ('sprite_duqingshan_idle_v1', 'npc_duqingshan_idle.png'),
    ]:
        src = RAW / 'sprite' / 'npc' / f'{npc_id}.png'
        if src.exists():
            print(f'  Processing: {npc_id}')
            frame = process_single_frame(str(src))
            os.makedirs(str(GAME), exist_ok=True)
            frame.save(str(GAME / out_name), 'PNG')
            print(f'  -> {GAME / out_name}')
        else:
            print(f'  MISSING: {src}')

    print('\n=== Processing Red Banner ===')
    banner_src = RAW / 'props' / 'prop_linxi_red_banner_v2.png'
    if banner_src.exists():
        with open(str(banner_src), 'rb') as f:
            output = remove(f.read(), alpha_matting=True,
                            alpha_matting_foreground_threshold=240)
        img = Image.open(io.BytesIO(output)).convert('RGBA')
        bbox = img.split()[3].getbbox()
        if bbox:
            img = img.crop(bbox)
        # Scale height to 128
        w, h = img.size
        new_h = 128
        new_w = int(w * new_h / h)
        img = img.resize((new_w, new_h), Image.LANCZOS)
        out_path = GAME.parent / 'props' / 'linxi_red_banner.png'
        os.makedirs(out_path.parent, exist_ok=True)
        img.save(str(out_path), 'PNG')
        print(f'  -> {out_path} ({img.size})')
    else:
        print(f'  MISSING: {banner_src}')

    print('\nDone.')
