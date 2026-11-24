"""Prepare generated region backgrounds and normalize Duan Changfeng's idle strip.

The generated masters are preserved. Runtime copies are enlarged to the shared
2304x1536 exploration canvas. Duan's four authored poses are scaled to one
visible body height and anchored to one foot line, eliminating idle size jitter.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BG = ROOT / "game" / "art" / "backgrounds"

BACKGROUND_NAMES = (
    "bg_luoyang_south_gate_v1.png",
    "bg_luoyang_yamen_courtyard_v1.png",
    "bg_luoyang_south_market_v1.png",
    "bg_luoyang_canal_docks_v1.png",
    "bg_bailu_grand_ferry_v1.png",
    "bg_wudang_mountain_gate_v1.png",
)


def prepare_background(path: Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGB")
        if image.size == (2304, 1536):
            return
        image.resize((2304, 1536), Image.Resampling.LANCZOS).save(
            path, optimize=True, compress_level=7
        )


def alpha_bounds(frame: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = frame.getchannel("A")
    return alpha.point(lambda value: 255 if value > 12 else 0).getbbox()


def normalize_duan() -> None:
    source_path = (
        ROOT
        / "game"
        / "art"
        / "characters"
        / "street_expansion_v1"
        / "npc_duan_changfeng_idle_down_4f_v1_runtime.png"
    )
    output_path = source_path.with_name("npc_duan_changfeng_idle_down_4f_v2_stable.png")
    with Image.open(source_path) as source:
        strip = source.convert("RGBA")
    frame_size = strip.height
    count = max(1, strip.width // frame_size)
    target_height = round(frame_size * 0.77)
    target_foot_y = round(frame_size * 0.91)
    output = Image.new("RGBA", (frame_size * count, frame_size), (0, 0, 0, 0))
    for index in range(count):
        frame = strip.crop((index * frame_size, 0, (index + 1) * frame_size, frame_size))
        bounds = alpha_bounds(frame)
        if bounds is None:
            continue
        actor = frame.crop(bounds)
        scale = target_height / max(1, actor.height)
        actor = actor.resize(
            (max(1, round(actor.width * scale)), target_height),
            Image.Resampling.LANCZOS,
        )
        x = index * frame_size + (frame_size - actor.width) // 2
        y = target_foot_y - actor.height
        output.alpha_composite(actor, (x, y))
    output.save(output_path, optimize=True, compress_level=7)


def main() -> None:
    for name in BACKGROUND_NAMES:
        prepare_background(BG / name)
    normalize_duan()


if __name__ == "__main__":
    main()
