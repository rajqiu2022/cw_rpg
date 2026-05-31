"""
Slice the generated 4x2 grid sprite strip into individual frames,
process with rembg, and assemble into final horizontal strip.
"""
from PIL import Image
import io, os
from rembg import remove

RAW = r'F:/Code/RPG_GAME/assets/raw/sprite/lengguyun/sprite_lengguyun_walk_right_strip_v3.png'
GAME = r'F:/Code/RPG_GAME/game/art/characters'

# Grid layout: 4 columns x 2 rows, each cell 256x512
# With 2px gray borders between cells
COLS, ROWS = 4, 2
CELL_W, CELL_H = 256, 512
CANVAS = 1024
BORDER = 2

img = Image.open(RAW).convert('RGBA')
print(f'Source: {img.size} mode={img.mode}')

frames = []
for row in range(ROWS):
    for col in range(COLS):
        x = col * (CELL_W + BORDER)
        y = row * (CELL_H + BORDER)
        cell = img.crop((x, y, x + CELL_W, y + CELL_H))

        # Remove white background from cell
        cell_bytes = io.BytesIO()
        cell.save(cell_bytes, format='PNG')
        cell_bytes.seek(0)
        output = remove(cell_bytes.read(), alpha_matting=True,
                        alpha_matting_foreground_threshold=240)
        cell_clean = Image.open(io.BytesIO(output)).convert('RGBA')

        # Find content bounds
        bbox = cell_clean.split()[3].getbbox()
        if bbox:
            cell_clean = cell_clean.crop(bbox)

        # Resize to fit 160x160 frame
        w, h = cell_clean.size
        target = 160
        scale = target / max(w, h)
        nw, nh = int(w * scale), int(h * scale)
        cell_clean = cell_clean.resize((nw, nh), Image.LANCZOS)

        # Center in target frame
        canvas = Image.new('RGBA', (target, target), (0, 0, 0, 0))
        ox = (target - nw) // 2
        oy = (target - nh) // 2
        canvas.paste(cell_clean, (ox, oy), cell_clean)
        frames.append(canvas)
        print(f'  Frame {row*COLS+col+1}: content={w}x{h} -> {target}x{target}')

# Assemble horizontal strip
strip = Image.new('RGBA', (target * 8, target), (0, 0, 0, 0))
for i, f in enumerate(frames):
    strip.paste(f, (i * target, 0), f)

out = os.path.join(GAME, 'lengguyun_walk_right_8f.png')
strip.save(out, 'PNG')
print(f'Saved: {out} ({strip.size})')

# Also save individual frames for inspection
for i, f in enumerate(frames):
    fout = os.path.join(GAME, f'walk_right_f{i+1}.png')
    f.save(fout, 'PNG')
print(f'Individual frames saved to {GAME}/walk_right_f*.png')
