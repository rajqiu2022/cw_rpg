"""
gen_menu_buttons_wuxia.py — 武侠风格主菜单按钮生成器

生成类似参考图的武侠风格按钮：
- 深色底板（暗色，略有纹理）
- 银灰金属粗边框，带内外双线
- 四角有圆形铆钉/珠宝装饰
- 上下中间也有装饰点
- hover: 边框发青色/蓝绿色光芒
- pressed: 整体偏暗

输出：game/art/ui/main_menu/buttons/final/ 下 9 张 PNG
"""

from __future__ import annotations
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import math

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "main_menu" / "buttons" / "final"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# 按钮尺寸
BTN_W = 520
BTN_H = 130

# 按钮定义
BUTTONS = [
    ("btn_new_game", "新游戏"),
    ("btn_load", "读取存档"),
    ("btn_quit", "离开"),
]

# 颜色定义
COLOR_BG_DARK = (18, 22, 28, 240)         # 深暗底板
COLOR_BG_TEXTURE = (25, 30, 38, 240)      # 底板纹理色
COLOR_BORDER_OUTER = (90, 100, 110, 255)  # 外边框（银灰）
COLOR_BORDER_INNER = (60, 68, 78, 255)    # 内边框
COLOR_BORDER_HIGHLIGHT = (140, 155, 170, 255)  # 边框高光线
COLOR_RIVET = (120, 140, 155, 255)        # 铆钉/珠宝颜色
COLOR_RIVET_HIGHLIGHT = (180, 200, 220, 255)  # 铆钉高光
COLOR_TEXT = (210, 215, 220, 255)         # 正常态文字（淡银白）

# hover 态颜色
COLOR_GLOW = (80, 220, 240, 180)          # 青色发光
COLOR_BORDER_HOVER = (100, 200, 220, 255) # hover边框
COLOR_TEXT_HOVER = (240, 245, 250, 255)   # hover文字

# pressed 态颜色  
COLOR_BORDER_PRESSED = (70, 80, 90, 255)
COLOR_TEXT_PRESSED = (160, 165, 170, 255)


def find_chinese_font() -> str:
    """查找系统中可用的中文字体"""
    candidates = [
        "C:/Windows/Fonts/STXINGKA.TTF",    # 华文行楷
        "C:/Windows/Fonts/simhei.ttf",       # 黑体
        "C:/Windows/Fonts/msyh.ttc",         # 微软雅黑
        "C:/Windows/Fonts/simsun.ttc",       # 宋体
        "C:/Windows/Fonts/STKAITI.TTF",      # 华文楷体
        "C:/Windows/Fonts/STZHONGS.TTF",     # 华文中宋
    ]
    for f in candidates:
        if Path(f).exists():
            return f
    return ""


def draw_ornament_corner(draw: ImageDraw.Draw, cx: int, cy: int, size: int, color: tuple, highlight: tuple):
    """绘制四角装饰——如意云纹简化为圆形铆钉+小圆环"""
    # 外环
    r = size
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=None, outline=color, width=2)
    # 内实心
    r_inner = size - 4
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], fill=color)
    # 高光点
    r_hl = size // 3
    draw.ellipse([cx - r_hl - 1, cy - r_hl - 2, cx + r_hl - 1, cy + r_hl - 2], fill=highlight)


def draw_rivet(draw: ImageDraw.Draw, cx: int, cy: int, size: int, color: tuple, highlight: tuple):
    """绘制边框上的小铆钉"""
    draw.ellipse([cx - size, cy - size, cx + size, cy + size], fill=color)
    # 高光
    hl_s = max(1, size // 2)
    draw.ellipse([cx - hl_s, cy - hl_s - 1, cx + hl_s, cy + hl_s - 1], fill=highlight)


def create_button_base(state: str = "normal") -> Image.Image:
    """创建按钮底板（不含文字）"""
    img = Image.new("RGBA", (BTN_W, BTN_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 参数
    border_w = 4
    margin = 8  # 装饰区域留白
    
    # 底板区域
    inner_x1 = margin + border_w
    inner_y1 = margin + border_w
    inner_x2 = BTN_W - margin - border_w
    inner_y2 = BTN_H - margin - border_w
    
    # 1. 绘制深色底板（带轻微纹理感）
    for y in range(inner_y1, inner_y2):
        for x in range(inner_x1, inner_x2, 4):
            # 简单噪点模拟纹理
            noise = ((x * 7 + y * 13) % 17) - 8
            r = max(0, min(255, COLOR_BG_DARK[0] + noise))
            g = max(0, min(255, COLOR_BG_DARK[1] + noise))
            b = max(0, min(255, COLOR_BG_DARK[2] + noise))
            x_end = min(x + 4, inner_x2)
            draw.rectangle([x, y, x_end, y], fill=(r, g, b, COLOR_BG_DARK[3]))
    
    # 2. 绘制边框
    if state == "hover":
        border_color = COLOR_BORDER_HOVER
        border_hl = COLOR_GLOW
    elif state == "pressed":
        border_color = COLOR_BORDER_PRESSED
        border_hl = COLOR_BORDER_PRESSED
    else:
        border_color = COLOR_BORDER_OUTER
        border_hl = COLOR_BORDER_HIGHLIGHT
    
    # 外边框
    draw.rectangle(
        [margin, margin, BTN_W - margin, BTN_H - margin],
        outline=border_color, width=border_w
    )
    # 内边框线（细线）
    inner_margin = margin + border_w + 3
    draw.rectangle(
        [inner_margin, inner_margin, BTN_W - inner_margin, BTN_H - inner_margin],
        outline=COLOR_BORDER_INNER, width=1
    )
    # 高光线（上边+左边偏亮）
    draw.line(
        [(margin + border_w, margin), (BTN_W - margin - border_w, margin)],
        fill=border_hl, width=1
    )
    
    # 3. 四角装饰
    corner_size = 8
    corner_offset = margin + 2
    corners = [
        (corner_offset + corner_size, corner_offset + corner_size),           # 左上
        (BTN_W - corner_offset - corner_size, corner_offset + corner_size),   # 右上
        (corner_offset + corner_size, BTN_H - corner_offset - corner_size),   # 左下
        (BTN_W - corner_offset - corner_size, BTN_H - corner_offset - corner_size),  # 右下
    ]
    
    rivet_color = COLOR_GLOW[:3] + (200,) if state == "hover" else COLOR_RIVET
    rivet_hl = (200, 240, 255, 255) if state == "hover" else COLOR_RIVET_HIGHLIGHT
    
    for (cx, cy) in corners:
        draw_ornament_corner(draw, cx, cy, corner_size, rivet_color, rivet_hl)
    
    # 4. 上下中间铆钉
    mid_x = BTN_W // 2
    rivet_size = 5
    draw_rivet(draw, mid_x, margin + 2, rivet_size, rivet_color, rivet_hl)
    draw_rivet(draw, mid_x, BTN_H - margin - 2, rivet_size, rivet_color, rivet_hl)
    
    # 5. 左右中间铆钉
    mid_y = BTN_H // 2
    draw_rivet(draw, margin + 2, mid_y, rivet_size, rivet_color, rivet_hl)
    draw_rivet(draw, BTN_W - margin - 2, mid_y, rivet_size, rivet_color, rivet_hl)
    
    # 6. hover 态添加外发光
    if state == "hover":
        # 创建发光层
        glow_layer = Image.new("RGBA", (BTN_W, BTN_H), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_layer)
        glow_draw.rectangle(
            [margin - 3, margin - 3, BTN_W - margin + 3, BTN_H - margin + 3],
            outline=(80, 220, 240, 100), width=3
        )
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(4))
        img = Image.alpha_composite(img, glow_layer)
    
    return img


def add_text(img: Image.Image, text: str, state: str = "normal") -> Image.Image:
    """在按钮上绘制文字"""
    draw = ImageDraw.Draw(img)
    
    font_path = find_chinese_font()
    font_size = 38
    
    if font_path:
        try:
            font = ImageFont.truetype(font_path, font_size)
        except Exception:
            font = ImageFont.load_default()
    else:
        font = ImageFont.load_default()
    
    # 文字颜色
    if state == "hover":
        text_color = COLOR_TEXT_HOVER
    elif state == "pressed":
        text_color = COLOR_TEXT_PRESSED
    else:
        text_color = COLOR_TEXT
    
    # 获取文字边界
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    
    # 居中
    tx = (BTN_W - tw) // 2
    ty = (BTN_H - th) // 2 - 2  # 微调上移
    
    # 文字阴影
    shadow_offset = 2
    draw.text((tx + shadow_offset, ty + shadow_offset), text, fill=(0, 0, 0, 180), font=font)
    
    # 正文
    draw.text((tx, ty), text, fill=text_color, font=font)
    
    return img


def darken_image(img: Image.Image, factor: float = 0.7) -> Image.Image:
    """整体变暗（pressed态用）"""
    enhancer = ImageEnhance.Brightness(img)
    return enhancer.enhance(factor)


def generate_all():
    """生成所有按钮的三态贴图"""
    print(f"输出目录: {OUTPUT_DIR}")
    print(f"按钮尺寸: {BTN_W}x{BTN_H}")
    print()
    
    font_path = find_chinese_font()
    if font_path:
        print(f"使用字体: {font_path}")
    else:
        print("警告: 未找到中文字体，将使用默认字体")
    print()
    
    for btn_key, btn_text in BUTTONS:
        for state in ["normal", "hover", "pressed"]:
            # 创建按钮底板
            img = create_button_base(state)
            
            # 添加文字
            img = add_text(img, btn_text, state)
            
            # pressed 态整体稍暗
            if state == "pressed":
                img = darken_image(img, 0.8)
            
            # 保存
            filename = f"{btn_key}_{state}.png"
            filepath = OUTPUT_DIR / filename
            img.save(filepath, "PNG")
            print(f"  [OK] {filename} ({img.size[0]}x{img.size[1]})")

    
    print(f"\n完成！共生成 {len(BUTTONS) * 3} 张按钮贴图")
    print(f"目录: {OUTPUT_DIR}")


if __name__ == "__main__":
    generate_all()
