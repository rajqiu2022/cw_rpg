from PIL import Image
import numpy as np
import os

FRAME_PATH = "assets/raw/ui/button/main_menu/frame/v1/ui_btn_main_frame_normal_v1.png"
TASKS = [
    (
        "assets/raw/ui/button/main_menu/text/v1/ui_btn_main_text_new_game_v1.png",
        "game/art/ui/main_menu/buttons/text/v1/btn_menu_text_new_game_v1.png",
    ),
    (
        "assets/raw/ui/button/main_menu/text/v1/ui_btn_main_text_load_v1.png",
        "game/art/ui/main_menu/buttons/text/v1/btn_menu_text_load_v1.png",
    ),
    (
        "assets/raw/ui/button/main_menu/text/v1/ui_btn_main_text_quit_v1.png",
        "game/art/ui/main_menu/buttons/text/v1/btn_menu_text_quit_v1.png",
    ),
]


def extract_text_layer(src_rgb: np.ndarray, frame_rgb: np.ndarray) -> np.ndarray:
    diff = np.abs(src_rgb.astype(np.int16) - frame_rgb.astype(np.int16)).sum(axis=2)
    lum = 0.299 * src_rgb[:, :, 0] + 0.587 * src_rgb[:, :, 1] + 0.114 * src_rgb[:, :, 2]
    sat = src_rgb.max(axis=2) - src_rgb.min(axis=2)

    h, w = diff.shape
    # 仅在中间文字区寻找差异，避免边框噪声
    band = np.zeros_like(diff, dtype=bool)
    band[int(h * 0.34):int(h * 0.68), int(w * 0.20):int(w * 0.80)] = True

    # 保留偏亮、低饱和、与底框存在明显差异的像素（贴近旧风格字形）
    mask = (diff > 22) & (lum > 120) & (sat < 120) & band
    if mask.sum() < 1200:
        mask = (diff > 16) & (lum > 95) & (sat < 140) & band

    ys, xs = np.where(mask)
    if len(xs) == 0:
        # 兜底透明图
        return np.zeros((96, 320, 4), dtype=np.uint8)

    x1, x2 = xs.min(), xs.max()
    y1, y2 = ys.min(), ys.max()
    pad_x = max(10, int((x2 - x1 + 1) * 0.12))
    pad_y = max(8, int((y2 - y1 + 1) * 0.15))
    x1 = max(0, x1 - pad_x)
    x2 = min(w - 1, x2 + pad_x)
    y1 = max(0, y1 - pad_y)
    y2 = min(h - 1, y2 + pad_y)

    crop_rgb = src_rgb[y1:y2 + 1, x1:x2 + 1]
    crop_diff = diff[y1:y2 + 1, x1:x2 + 1]
    crop_lum = lum[y1:y2 + 1, x1:x2 + 1]

    # 差分转 alpha，并压掉暗噪声
    alpha = np.clip((crop_diff - 14) * 10, 0, 255).astype(np.uint8)
    alpha[crop_lum < 90] = 0
    alpha[alpha < 18] = 0

    out = np.dstack([crop_rgb, alpha])
    return out


def main() -> None:
    frame_img = Image.open(FRAME_PATH).convert("RGB")
    frame_rgb = np.array(frame_img)

    for src_path, out_path in TASKS:
        src_img = Image.open(src_path).convert("RGB")
        src_rgb = np.array(src_img)

        if src_rgb.shape != frame_rgb.shape:
            src_img = src_img.resize(frame_img.size, Image.Resampling.LANCZOS)
            src_rgb = np.array(src_img)

        out = extract_text_layer(src_rgb, frame_rgb)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        Image.fromarray(out, "RGBA").save(out_path)
        opaque = int((out[:, :, 3] > 0).sum())
        print(f"extracted {out_path} size={out.shape[1]}x{out.shape[0]} opaque_px={opaque}")


if __name__ == "__main__":
    main()
