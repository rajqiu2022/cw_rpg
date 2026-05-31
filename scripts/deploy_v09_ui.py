"""
Post-process and deploy v0.9 UI assets:
- 5 buttons: crop normal → generate hover (brighten) + pressed (darken)
- Scene name panel: rembg + crop → deploy
- Quest panel: rembg + crop → deploy
- Dialog frame: crop → deploy
- Update field_primary_hud.tscn to reference system button textures
"""
from PIL import Image, ImageEnhance
import io, os, shutil
from pathlib import Path
from rembg import remove

PROJECT = Path(__file__).resolve().parent.parent
RAW = PROJECT / 'assets' / 'raw'
GAME_UI_V2 = PROJECT / 'game' / 'art' / 'ui' / 'field_hud' / 'v2'
GAME_UI_V1 = PROJECT / 'game' / 'art' / 'ui' / 'field_hud' / 'v1'

BUTTON_MAP = {
    'ui_btn_inventory_v2': 'hud_btn_inventory',
    'ui_btn_equipment_v2': 'hud_btn_equipment',
    'ui_btn_skill_v2': 'hud_btn_skill',
    'ui_btn_quest_v2': 'hud_btn_quest',
    'ui_btn_system_v2': 'hud_btn_system',
}

def process_image(src_path: Path, target_dir: Path, out_name: str,
                  target_size: tuple = None, use_rembg: bool = True):
    """Generic: load, remove bg, crop to content, optionally resize."""
    img = Image.open(src_path).convert('RGBA')

    if use_rembg:
        with open(src_path, 'rb') as f:
            output = remove(f.read(), alpha_matting=True,
                            alpha_matting_foreground_threshold=240)
        img = Image.open(io.BytesIO(output)).convert('RGBA')

    # Crop to non-transparent content
    bbox = img.split()[3].getbbox()
    if bbox:
        img = img.crop(bbox)

    if target_size:
        w, h = img.size
        tw, th = target_size
        scale = min(tw / w, th / h)
        nw, nh = int(w * scale), int(h * scale)
        img = img.resize((nw, nh), Image.LANCZOS)
        canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
        ox, oy = (target_size[0] - nw) // 2, (target_size[1] - nh) // 2
        canvas.paste(img, (ox, oy), img)
        img = canvas

    target_dir.mkdir(parents=True, exist_ok=True)
    out = target_dir / out_name
    img.save(str(out), 'PNG')
    print(f'  -> {out} ({img.size})')
    return img

def make_button_variants(normal_img: Image.Image, out_base: Path):
    """Generate hover (brighten) and pressed (darken) from normal."""
    # Hover: brighten + slight warm
    hover = normal_img.copy()
    enhancer = ImageEnhance.Brightness(hover)
    hover = enhancer.enhance(1.25)
    enhancer = ImageEnhance.Contrast(hover)
    hover = enhancer.enhance(1.10)
    hover.save(str(out_base.parent / f'{out_base.name}_hover.png'), 'PNG')

    # Pressed: darken + desaturate
    pressed = normal_img.copy()
    enhancer = ImageEnhance.Brightness(pressed)
    pressed = enhancer.enhance(0.75)
    enhancer = ImageEnhance.Contrast(pressed)
    pressed = enhancer.enhance(0.90)
    pressed.save(str(out_base.parent / f'{out_base.name}_pressed.png'), 'PNG')

    print(f'  hover + pressed variants generated')

if __name__ == '__main__':
    print('=== 1. Buttons (5 normal → 15 states) ===')
    for task_id, base_name in BUTTON_MAP.items():
        src = RAW / 'ui' / 'field_hud' / 'buttons' / f'{task_id}.png'
        if not src.exists():
            print(f'  MISSING: {src}')
            continue
        print(f'  {task_id}')
        normal = process_image(src, GAME_UI_V1, f'{base_name}_normal.png',
                                target_size=(241, 93))
        make_button_variants(normal, GAME_UI_V1 / base_name)

    print('\n=== 2. Scene Name Panel ===')
    src = RAW / 'ui' / 'field_hud' / 'ui_scene_name_panel_v6.png'
    if src.exists():
        process_image(src, GAME_UI_V2, 'hud_map_info_panel.png',
                      target_size=(522, 62))
    else:
        print(f'  MISSING: {src}')

    print('\n=== 3. Quest Panel ===')
    src = RAW / 'ui' / 'field_hud' / 'ui_quest_panel_v6.png'
    if src.exists():
        process_image(src, GAME_UI_V2, 'hud_quest_summary_panel.png',
                      target_size=(536, 252))
    else:
        print(f'  MISSING: {src}')

    print('\n=== 4. Dialog Frame ===')
    src = RAW / 'ui' / 'field_hud' / 'ui_dialog_frame_v6.png'
    if src.exists():
        process_image(src, GAME_UI_V2, 'hud_dialog_frame.png',
                      target_size=(1600, 280))
    else:
        print(f'  MISSING: {src}')

    # Clear Godot caches
    print('\n=== Clearing Godot caches ===')
    cache_dir = PROJECT / 'game' / '.godot' / 'imported'
    patterns = ['hud_btn_*', 'hud_map_info*', 'hud_quest_summary*', 'hud_dialog_frame*']
    for pat in patterns:
        for f in cache_dir.glob(pat):
            f.unlink()
            print(f'  Deleted: {f.name}')
    print('Done.')
