"""
合成主菜单 v4：
- 底图：ui_main_menu_blue_green_v3.png（蓝调剑客背景，木匾标题将被覆盖）
- 标题：从 ui_main_menu_bright_green_v1.png 裁切"云影侠传"金字+剑
- 按钮：从 ui_cold_wuxia_main_menu_screen_gpt_v5.png 裁切三个菜单按钮
"""
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np

ROOT = Path(__file__).resolve().parent.parent

# 输入
BASE_IMG = ROOT / "assets/raw/scene_background/ui_main_menu_blue_green_v3.png"
TITLE_SRC = ROOT / "assets/raw/scene_background/ui_main_menu_bright_green_v1.png"
BUTTONS_SRC = ROOT / "assets/_archive/main_menu_hover_unwanted/ui_cold_wuxia_main_menu_screen_gpt_v5.png"

# 输出
OUTPUT_DIR = ROOT / "assets/raw/scene_background"
OUTPUT_FILE = OUTPUT_DIR / "ui_main_menu_composite_v4.png"


def extract_title_text_only(title_img: Image.Image) -> Image.Image:
    """
    从 bright_green_v1 精确裁切"云影侠传"金字+剑标志。
    只取文字和剑的核心区域，去掉周围的天空和竹叶。
    文字+剑大约在: x=750~1430, y=30~250
    """
    # 精确裁切文字+剑区域
    title_crop = title_img.crop((740, 25, 1440, 260))
    title_crop = title_crop.convert("RGBA")
    
    arr = np.array(title_crop).astype(np.float32)
    
    # 这个区域主要是：金色文字 + 剑 + 浅蓝天空背景
    # 我们要去掉浅蓝天空，保留金色/深色的文字和剑
    # 天空特征：高亮度(>180) + 蓝色调(B>R, B>G) 或 白色(R>220,G>220,B>220)
    r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]
    brightness = r * 0.299 + g * 0.587 + b * 0.114
    
    # 天空/浅色背景 mask
    is_sky = (brightness > 170) & (b > r - 30)  # 浅蓝或白色
    is_white = (r > 210) & (g > 210) & (b > 210)  # 纯白
    is_background = is_sky | is_white
    
    # 设背景为透明
    alpha = arr[:,:,3].copy()
    alpha[is_background] = 0
    # 边缘区域半透明渐变
    # 对 alpha 做 3px erosion 让边缘更柔和
    alpha_img = Image.fromarray(alpha.astype(np.uint8))
    # 轻微模糊边缘
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(radius=1.5))
    
    arr[:,:,3] = np.array(alpha_img).astype(np.float32)
    result = Image.fromarray(arr.astype(np.uint8))
    return result


def extract_buttons_as_strip(buttons_img: Image.Image) -> Image.Image:
    """
    从 v5 裁切整个按钮区域（含三个按钮），保留原始暗色风格。
    不做去背，而是整体作为一个带框的面板贴上去。
    按钮区域: x=370~1160, y=310~910
    """
    # 裁切整个按钮面板区域
    panel = buttons_img.crop((395, 320, 1135, 895))
    panel = panel.convert("RGBA")
    return panel


def create_soft_mask(size, feather=30):
    """创建柔化边缘的 alpha mask，避免裁切硬边"""
    w, h = size
    mask = Image.new('L', (w, h), 255)
    arr = np.array(mask, dtype=np.float32)
    
    # 四边渐变
    for i in range(feather):
        alpha = int(255 * (i / feather))
        arr[i, :] = np.minimum(arr[i, :], alpha)        # top
        arr[h-1-i, :] = np.minimum(arr[h-1-i, :], alpha)  # bottom
        arr[:, i] = np.minimum(arr[:, i], alpha)         # left
        arr[:, w-1-i] = np.minimum(arr[:, w-1-i], alpha)  # right
    
    return Image.fromarray(arr.astype(np.uint8))


def composite():
    print("Loading images...")
    base = Image.open(BASE_IMG).convert("RGBA")
    title_src = Image.open(TITLE_SRC).convert("RGBA")
    buttons_src = Image.open(BUTTONS_SRC).convert("RGBA")
    
    print(f"Base: {base.size}")
    print(f"Title source: {title_src.size}")
    print(f"Buttons source: {buttons_src.size}")
    
    # 1. 先去掉 v3 底图的木匾标题
    # v3 的木匾在 x:420~1080, y:0~260 区域
    # 用上方天空颜色（取 y=0~10 的平均色）填充，再用周围模糊融合
    print("Removing v3 original wooden plaque...")
    base_arr = np.array(base)
    # 采样木匾上方天空色（y=0~5, x=420~1080 的外侧）
    # 用 content-aware 的简单方式：把木匾区域用周围像素 inpaint
    # 简单方案：复制左右两侧的天空纹理到木匾区域
    plaque_x1, plaque_y1, plaque_x2, plaque_y2 = 420, 0, 1100, 260
    
    # 用木匾区域外的天空(x:0~420)水平拉伸填充
    # 更简单：取右侧天空条(x:1100~1536, y:0~260)镜像填充
    sky_right = base_arr[plaque_y1:plaque_y2, 1100:1400, :].copy()
    # resize sky_right to fill plaque area
    sky_fill = Image.fromarray(sky_right).resize(
        (plaque_x2 - plaque_x1, plaque_y2 - plaque_y1), Image.LANCZOS
    )
    base.paste(sky_fill, (plaque_x1, plaque_y1))
    
    # 对填充边缘做模糊融合（避免硬边）
    # 简单方案：在拼接边缘做 alpha 混合
    base_blurred = base.filter(ImageFilter.GaussianBlur(radius=15))
    # 在边缘区域混合原图和模糊图
    blend_mask = Image.new('L', base.size, 0)
    blend_arr = np.array(blend_mask)
    # 左边缘
    for i in range(30):
        blend_arr[plaque_y1:plaque_y2, plaque_x1+i] = int(255 * (1 - i/30))
    # 右边缘
    for i in range(30):
        blend_arr[plaque_y1:plaque_y2, plaque_x2-1-i] = int(255 * (1 - i/30))
    # 下边缘
    for i in range(30):
        blend_arr[plaque_y2-1-i, plaque_x1:plaque_x2] = np.maximum(
            blend_arr[plaque_y2-1-i, plaque_x1:plaque_x2], int(255 * (1 - i/30))
        )
    blend_mask = Image.fromarray(blend_arr)
    base = Image.composite(base_blurred, base, blend_mask)
    print("  Plaque area cleaned")
    
    # 2. 裁切标题（只取金字+剑，去天空背景）
    print("Extracting title text...")
    title = extract_title_text_only(title_src)
    print(f"  Title crop: {title.size}")
    
    # 2. 裁切按钮面板
    print("Extracting buttons panel...")
    buttons_panel = extract_buttons_as_strip(buttons_src)
    print(f"  Buttons panel: {buttons_panel.size}")
    
    # 3. 先去掉 v3 的木匾（用 inpaint 方式不现实，直接覆盖就好）
    
    # 4. 合成标题 - 放在中上方（居中）
    title_w, title_h = title.size
    title_x = (1536 - title_w) // 2 + 50  # 略偏右（因为左边有人物）
    title_y = 25
    
    # 贴标题（已有 alpha 通道，直接 paste）
    base.paste(title, (title_x, title_y), title)
    print(f"  Title placed at ({title_x}, {title_y})")
    
    # 5. 合成按钮面板
    # 缩小按钮面板到合适尺寸（原 740x575 太大）
    target_btn_w = 520
    scale = target_btn_w / buttons_panel.width
    target_btn_h = int(buttons_panel.height * scale)
    buttons_panel = buttons_panel.resize((target_btn_w, target_btn_h), Image.LANCZOS)
    
    # 给按钮面板加半透明黑底（让暗色按钮和亮背景融合更好）
    # 创建一个半透明黑色底板
    dark_bg = Image.new("RGBA", (target_btn_w + 60, target_btn_h + 50), (10, 15, 25, 160))
    # 加圆角效果（简单处理：用高斯模糊边缘）
    dark_bg_arr = np.array(dark_bg).astype(np.float32)
    # 边缘 25px 渐变到透明
    feather = 25
    for i in range(feather):
        factor = i / feather
        dark_bg_arr[i, :, 3] *= factor
        dark_bg_arr[-(i+1), :, 3] *= factor
        dark_bg_arr[:, i, 3] *= factor
        dark_bg_arr[:, -(i+1), 3] *= factor
    dark_bg = Image.fromarray(dark_bg_arr.astype(np.uint8))
    
    # 按钮面板放在右侧中间（避开左侧人物）
    btn_x = 1536 // 2 + 150 - target_btn_w // 2
    btn_y = 360
    
    # 先贴半透明黑底
    base.paste(dark_bg, (btn_x - 20, btn_y - 20), dark_bg)
    # 再贴按钮面板
    base.paste(buttons_panel, (btn_x, btn_y), buttons_panel)
    print(f"  Buttons placed at ({btn_x}, {btn_y}), size ({target_btn_w}, {target_btn_h})")
    
    # 6. 保存
    output = base.convert("RGB")
    output.save(OUTPUT_FILE, quality=95)
    print(f"\n[OK] Saved: {OUTPUT_FILE}")
    print(f"   Size: {output.size}")


if __name__ == "__main__":
    composite()
