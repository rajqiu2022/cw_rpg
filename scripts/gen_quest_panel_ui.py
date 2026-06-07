"""
gen_quest_panel_ui.py — PIL 生成任务面板 UI 组件

用程序画像素级精确的冷色武侠 UI 组件，替代 AI atlas 方案。
输出到 game/art/ui/quest/ 供 Godot 直接使用。

调色板：深墨蓝、玄铁黑、冷钢蓝、霜蓝、深竹绿、金色（选中态点缀）
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path("game/art/ui/quest")
OUT.mkdir(parents=True, exist_ok=True)

# ── 调色板 ──
INK_DARK   = (12, 18, 28, 255)      # 深墨蓝底
STEEL_BG   = (22, 32, 48, 255)      # 玄铁面板底
STEEL_EDGE = (60, 90, 130, 255)     # 冷钢蓝边框
FROST      = (120, 160, 210, 255)   # 霜蓝高光
FROST_DIM  = (80, 120, 170, 255)    # 霜蓝暗
BAMBOO     = (40, 90, 70, 255)      # 深竹绿
BAMBOO_HI  = (60, 130, 100, 255)    # 竹绿高亮
GOLD       = (180, 150, 80, 255)    # 金色点缀
GOLD_LIGHT = (220, 190, 110, 255)   # 金色高亮
CRIMSON    = (140, 30, 25, 255)     # 暗血红（关闭按钮）
CRIMSON_HI = (190, 50, 40, 255)     # 血红高亮
MUTED      = (100, 120, 140, 255)   # 暗灰文字色
DARK       = (8, 12, 20, 255)       # 极深（pressed 态内凹）
HALO       = (40, 60, 100, 80)      # 光晕（半透明）


def rounded_rect_mask(w: int, h: int, r: int) -> Image.Image:
    """生成圆角矩形 alpha mask。"""
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=255)
    return mask


def apply_mask(img: Image.Image, mask: Image.Image) -> Image.Image:
    """将 mask 应用到图像 alpha 通道。"""
    img = img.convert("RGBA")
    r, g, b, a = img.split()
    a = Image.composite(a, Image.new("L", img.size, 0), mask)
    return Image.merge("RGBA", (r, g, b, a))


def make_panel_bg(w: int = 1280, h: int = 700) -> Image.Image:
    """面板底框：深墨蓝底 + 冷钢蓝边框 + 四角云纹角花。"""
    img = Image.new("RGBA", (w, h), INK_DARK)
    draw = ImageDraw.Draw(img)

    # 边框
    border_r = 16
    draw.rounded_rectangle([4, 4, w - 5, h - 5], radius=border_r, outline=STEEL_EDGE, width=3)
    # 内边框（霜蓝细线）
    draw.rounded_rectangle([10, 10, w - 11, h - 11], radius=border_r - 2, outline=FROST_DIM, width=1)

    # 四角云纹角花（简化为小方块+弧线）
    corner_sz = 24
    for cx, cy in [(16, 16), (w - 16, 16), (16, h - 16), (w - 16, h - 16)]:
        draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], outline=FROST, width=1)
        draw.rectangle([cx - 3, cy - 3, cx + 3, cy + 3], fill=FROST)

    return img


def make_title_plaque(w: int = 360, h: int = 70) -> Image.Image:
    """标题匾额：玄铁底 + 冷钢蓝边框 + 云纹角花。"""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    mask = rounded_rect_mask(w, h, 10)
    bg = Image.new("RGBA", (w, h), STEEL_BG)
    img = Image.alpha_composite(img, apply_mask(bg, mask))

    draw.rounded_rectangle([2, 2, w - 3, h - 3], radius=10, outline=STEEL_EDGE, width=2)
    # 角花
    for cx, cy in [(14, h // 2)]:
        draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], outline=FROST, width=1)
    for cx, cy in [(w - 14, h // 2)]:
        draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], outline=FROST, width=1)

    return img


def make_button(w: int, h: int, color: tuple, state: str = "normal") -> Image.Image:
    """通用按钮三态。color: 底色元组。"""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r = 8
    mask = rounded_rect_mask(w, h, r)

    if state == "pressed":
        bg_color = tuple(max(0, c - 30) for c in color[:3]) + (255,)
        border_color = tuple(max(0, c - 40) for c in STEEL_EDGE[:3]) + (255,)
        # 内凹阴影
        shadow = Image.new("RGBA", (w, h), (0, 0, 0, 80))
        img = Image.alpha_composite(img, apply_mask(shadow, mask))
    elif state == "hover":
        bg_color = tuple(min(255, c + 20) for c in color[:3]) + (255,)
        border_color = FROST
        # 外发光
        glow = Image.new("RGBA", (w + 8, h + 8), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.rounded_rectangle([0, 0, w + 7, h + 7], radius=r + 2, fill=HALO)
        glow = glow.filter(ImageFilter.GaussianBlur(3))
        img = Image.alpha_composite(Image.new("RGBA", (w, h), (0, 0, 0, 0)),
                                     glow.crop((4, 4, 4 + w, 4 + h)))
    else:
        bg_color = color
        border_color = STEEL_EDGE

    bg = Image.new("RGBA", (w, h), bg_color)
    img = Image.alpha_composite(img, apply_mask(bg, mask))
    draw.rounded_rectangle([1, 1, w - 2, h - 2], radius=r, outline=border_color, width=2)

    return img


def make_close_btn(state: str = "normal") -> Image.Image:
    return make_button(130, 50, CRIMSON if state == "normal" else (CRIMSON_HI if state == "hover" else (100, 20, 18, 255)), state)


def make_tab_btn(state: str = "normal") -> Image.Image:
    color = STEEL_BG
    if state == "selected":
        color = (30, 50, 80, 255)
    return make_button(105, 42, color, state)


def make_track_btn(state: str = "normal") -> Image.Image:
    color = BAMBOO
    if state == "hover":
        color = BAMBOO_HI
    return make_button(190, 50, color, state)


def make_quest_row(state: str = "normal") -> Image.Image:
    """任务列表项底框。"""
    w, h = 460, 100
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r = 10
    mask = rounded_rect_mask(w, h, r)
    bg_color = (18, 28, 44, 255) if state == "normal" else (30, 48, 72, 255)
    bg = Image.new("RGBA", (w, h), bg_color)
    img = Image.alpha_composite(img, apply_mask(bg, mask))

    border_color = STEEL_EDGE if state == "normal" else GOLD
    draw.rounded_rectangle([1, 1, w - 2, h - 2], radius=r, outline=border_color, width=2)

    # 内部分隔线（上下两行暗示）
    draw.line([(16, h // 2), (w - 16, h // 2)], fill=(30, 45, 65, 120), width=1)

    return img


def make_dropdown(w: int = 190, h: int = 42) -> Image.Image:
    """章节下拉框。"""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r = 7
    mask = rounded_rect_mask(w, h, r)
    bg = Image.new("RGBA", (w, h), INK_DARK)
    img = Image.alpha_composite(img, apply_mask(bg, mask))
    draw.rounded_rectangle([1, 1, w - 2, h - 2], radius=r, outline=STEEL_EDGE, width=1)

    # 右侧三角箭头
    cx, cy = w - 20, h // 2
    draw.polygon([(cx - 6, cy - 4), (cx + 6, cy - 4), (cx, cy + 5)], fill=FROST_DIM)

    return img


def make_detail_panel(w: int = 630, h: int = 500) -> Image.Image:
    """详情描述面板。"""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r = 12
    mask = rounded_rect_mask(w, h, r)
    bg = Image.new("RGBA", (w, h), (16, 24, 40, 255))
    img = Image.alpha_composite(img, apply_mask(bg, mask))

    draw.rounded_rectangle([2, 2, w - 3, h - 3], radius=r, outline=STEEL_EDGE, width=2)

    # 角花
    for cx, cy in [(18, 18), (w - 18, 18), (18, h - 18), (w - 18, h - 18)]:
        draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], outline=FROST_DIM, width=1)

    # 分区线
    for y_pos in [80, 220, 360]:
        draw.line([(30, y_pos), (w - 30, y_pos)], fill=(35, 55, 80, 100), width=1)

    return img


def make_summary_label(w: int = 220, h: int = 26) -> Image.Image:
    """卷宗统计标签。"""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r = 6
    mask = rounded_rect_mask(w, h, r)
    bg = Image.new("RGBA", (w, h), (16, 24, 40, 200))
    img = Image.alpha_composite(img, apply_mask(bg, mask))

    return img


# ═══════════════════════════════════════════
# 生成全部组件
# ═══════════════════════════════════════════

def generate_all() -> None:
    items = [
        ("panel_bg", make_panel_bg()),
        ("title_plaque", make_title_plaque()),
        ("btn_close_normal", make_close_btn("normal")),
        ("btn_close_hover", make_close_btn("hover")),
        ("btn_close_pressed", make_close_btn("pressed")),
        ("tab_normal", make_tab_btn("normal")),
        ("tab_selected", make_tab_btn("selected")),
        ("tab_hover", make_tab_btn("hover")),
        ("tab_pressed", make_tab_btn("pressed")),
        ("dropdown_chapter", make_dropdown()),
        ("quest_row_normal", make_quest_row("normal")),
        ("quest_row_selected", make_quest_row("selected")),
        ("detail_panel", make_detail_panel()),
        ("btn_track_normal", make_track_btn("normal")),
        ("btn_track_hover", make_track_btn("hover")),
        ("btn_track_pressed", make_track_btn("pressed")),
        ("summary_label", make_summary_label()),
    ]

    for name, img in items:
        path = OUT / f"{name}.png"
        img.save(path)
        print(f"  ✓ {name}: {img.size[0]}×{img.size[1]} → {path}")

    # 生成预览拼图
    make_preview(items)
    print(f"\n全部 {len(items)} 个组件已生成到 {OUT}/")


def make_preview(items: list) -> None:
    """生成预览拼图，方便看整体效果。"""
    cols = 4
    cell_w = max(it[1].size[0] for it in items) + 20
    cell_h = max(it[1].size[1] for it in items) + 20
    rows = (len(items) + cols - 1) // cols

    preview = Image.new("RGBA", (cols * cell_w, rows * cell_h), (20, 26, 38, 255))
    draw = ImageDraw.Draw(preview)

    for i, (name, img) in enumerate(items):
        col = i % cols
        row = i // cols
        x = col * cell_w + 10
        y = row * cell_h + 10
        preview.alpha_composite(img, (x, y))
        draw.text((x + 4, y + img.size[1] + 4), name, fill=MUTED[:3])

    preview_path = OUT / "preview_all.png"
    preview.save(preview_path)
    print(f"  预览图: {preview_path}")


if __name__ == "__main__":
    generate_all()
