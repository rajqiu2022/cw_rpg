"""
生成主菜单按钮最终版：
- 半透明暗色渐变底框 + 金色细边框 + 微光效果
- 华文行楷字体渲染（清晰锐利）
- 输出三态按钮完整贴图（文字烤在底框里，不再分层）
- 适配 1920x1080 主菜单
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import numpy as np
import os

OUT_DIR = "game/art/ui/main_menu/buttons/final"
PREVIEW_PATH = "tools/main_menu_preview.png"

# 按钮参数
BTN_W, BTN_H = 420, 72  # 更修长的比例，不那么"厚"
CORNER_R = 6
FONT_PATH = "C:/Windows/Fonts/STXINGKA.TTF"
FONT_SIZE = 40
TEXTS = ["新游戏", "读取存档", "离开"]
FILE_NAMES = ["btn_new_game", "btn_load", "btn_quit"]

# 三态颜色配置
STATES = {
    "normal": {
        "bg_color": (12, 18, 28, 180),      # 深蓝黑半透明
        "border_color": (120, 135, 160, 200), # 银灰边框
        "text_color": (210, 218, 230, 255),   # 冷白色文字
        "glow": None,
    },
    "hover": {
        "bg_color": (20, 28, 42, 210),       # 稍亮
        "border_color": (180, 165, 120, 240), # 金色边框
        "text_color": (245, 240, 220, 255),   # 暖白文字
        "glow": (180, 165, 120, 60),          # 金色外发光
    },
    "pressed": {
        "bg_color": (8, 12, 20, 230),        # 更暗
        "border_color": (100, 90, 70, 200),   # 暗金边框
        "text_color": (180, 175, 160, 255),   # 暗白
        "glow": None,
    },
}


def draw_button(text: str, state_name: str) -> Image.Image:
    """绘制单个按钮"""
    state = STATES[state_name]
    
    # 创建带外发光的画布（多留 padding）
    pad = 12
    canvas = Image.new("RGBA", (BTN_W + pad*2, BTN_H + pad*2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    # 外发光（hover 态）
    if state["glow"]:
        glow_img = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_img)
        glow_draw.rounded_rectangle(
            [pad-4, pad-4, pad+BTN_W+4, pad+BTN_H+4],
            radius=CORNER_R+4, fill=state["glow"]
        )
        glow_img = glow_img.filter(ImageFilter.GaussianBlur(6))
        canvas = Image.alpha_composite(canvas, glow_img)
        draw = ImageDraw.Draw(canvas)
    
    # 底框背景（渐变效果 - 上深下浅）
    bg = Image.new("RGBA", (BTN_W, BTN_H), (0, 0, 0, 0))
    bg_arr = np.array(bg)
    r, g, b, a = state["bg_color"]
    for y in range(BTN_H):
        # 从上到下 alpha 渐变，给一点层次感
        ratio = y / BTN_H
        row_a = int(a * (0.85 + 0.15 * ratio))
        row_r = int(r * (1.0 + 0.3 * ratio))
        row_g = int(g * (1.0 + 0.2 * ratio))
        bg_arr[y, :, 0] = min(row_r, 255)
        bg_arr[y, :, 1] = min(row_g, 255)
        bg_arr[y, :, 2] = b
        bg_arr[y, :, 3] = row_a
    bg = Image.fromarray(bg_arr)
    
    # 用 rounded rect mask 裁切
    mask = Image.new("L", (BTN_W, BTN_H), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, BTN_W, BTN_H], radius=CORNER_R, fill=255)
    bg.putalpha(ImageEnhance.Brightness(Image.merge("L", [bg.split()[3]])).enhance(1.0))
    # 简单做法：直接把 mask 应用到 alpha
    bg_arr = np.array(bg)
    mask_arr = np.array(mask)
    bg_arr[:, :, 3] = np.minimum(bg_arr[:, :, 3], mask_arr)
    bg = Image.fromarray(bg_arr)
    
    canvas.paste(bg, (pad, pad), bg)
    draw = ImageDraw.Draw(canvas)
    
    # 边框
    br, bg_c, bb, ba = state["border_color"]
    draw.rounded_rectangle(
        [pad, pad, pad+BTN_W-1, pad+BTN_H-1],
        radius=CORNER_R, outline=(br, bg_c, bb, ba), width=2
    )
    
    # 顶部高光线（微妙的玻璃质感）
    highlight = Image.new("RGBA", (BTN_W - CORNER_R*2, 1), (255, 255, 255, 30))
    canvas.paste(highlight, (pad + CORNER_R, pad + 2), highlight)
    
    # 文字
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = pad + (BTN_W - tw) // 2
    ty = pad + (BTN_H - th) // 2 - bbox[1]
    
    # 文字阴影
    shadow_color = (0, 0, 0, 100)
    draw.text((tx + 1, ty + 2), text, font=font, fill=shadow_color)
    
    # 正文
    tr, tg, tb, ta = state["text_color"]
    draw.text((tx, ty), text, font=font, fill=(tr, tg, tb, ta))
    
    # 裁切到 final 尺寸（去掉 padding 如果没有 glow）
    if state["glow"]:
        return canvas
    else:
        # 保留少量 padding 给抗锯齿
        return canvas.crop((pad-2, pad-2, pad+BTN_W+2, pad+BTN_H+2))


def generate_all():
    os.makedirs(OUT_DIR, exist_ok=True)
    
    for text, fname in zip(TEXTS, FILE_NAMES):
        for state_name in STATES:
            img = draw_button(text, state_name)
            out_path = os.path.join(OUT_DIR, f"{fname}_{state_name}.png")
            img.save(out_path)
            print(f"  Saved: {out_path} ({img.size[0]}x{img.size[1]})")
    
    # 生成实际背景上的合成预览
    generate_preview()


def generate_preview():
    """在实际主菜单背景上预览按钮效果"""
    bg_path = "game/art/backgrounds/bg_main_menu_gpt_v7_clean.png"
    if os.path.exists(bg_path):
        bg = Image.open(bg_path).convert("RGBA").resize((1920, 1080), Image.LANCZOS)
    else:
        bg = Image.new("RGBA", (1920, 1080), (10, 15, 25, 255))
    
    # 按钮排列：画面中央偏右偏下
    btn_x = 1920 // 2 + 60  # 略偏右（左边有角色立绘）
    btn_start_y = 480
    btn_gap = 24
    
    for i, fname in enumerate(FILE_NAMES):
        btn_path = os.path.join(OUT_DIR, f"{fname}_normal.png")
        btn = Image.open(btn_path).convert("RGBA")
        y = btn_start_y + i * (btn.height + btn_gap)
        x = btn_x - btn.width // 2
        bg.paste(btn, (x, y), btn)
    
    # 也显示一个 hover 态示例（第一个按钮）
    hover_path = os.path.join(OUT_DIR, f"{FILE_NAMES[0]}_hover.png")
    hover_btn = Image.open(hover_path).convert("RGBA")
    # 在左侧额外显示 hover 态作为对比
    bg.paste(hover_btn, (100, 900), hover_btn)
    
    # 标注
    from PIL import ImageFont
    label_font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 16)
    draw = ImageDraw.Draw(bg)
    draw.text((100, 880), "↑ Hover态示例", font=label_font, fill=(150, 150, 150))
    
    bg.convert("RGB").save(PREVIEW_PATH)
    print(f"\n  Preview saved: {PREVIEW_PATH}")


if __name__ == "__main__":
    print("Generating final menu buttons...")
    generate_all()
    print("\nDone!")
