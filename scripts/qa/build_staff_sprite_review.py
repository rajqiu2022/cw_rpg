from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
FIELD_ROOT = ROOT / "game/art/characters/weapon_variants/lengguyun/v6_stowed/staff"
BATTLE_ROOT = ROOT / "game/art/sprites/battle/weapon_variants_v3/lengguyun/staff"
OUTPUT_ROOT = ROOT / "assets/previews/sprite/lengguyun_staff_v6"
STATES = ("ready", "move", "attack", "hit", "defeat")


def save_gif(frames: list[Image.Image], path: Path, duration: int, scale: float = 1.0) -> None:
    converted: list[Image.Image] = []
    for frame in frames:
        image = frame.convert("RGBA")
        if scale != 1.0:
            image = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
        converted.append(image)
    palette = [frame.convert("P", palette=Image.Palette.ADAPTIVE, colors=255) for frame in converted]
    path.parent.mkdir(parents=True, exist_ok=True)
    palette[0].save(path, save_all=True, append_images=palette[1:], duration=duration, loop=0, disposal=2, transparency=0)


def field_frames(direction: str) -> list[Image.Image]:
    strip = Image.open(FIELD_ROOT / f"lengguyun_staff_walk_{direction}_25d_8f.png").convert("RGBA")
    return [strip.crop((index * 160, 0, (index + 1) * 160, 160)) for index in range(8)]


def battle_frames(state: str) -> list[Image.Image]:
    return [Image.open(BATTLE_ROOT / f"lengguyun_staff_{state}_{index:02d}.png").convert("RGBA") for index in range(1, 5)]


def build_contact_sheet() -> None:
    cell_size = (256, 192)
    sheet = Image.new("RGBA", (cell_size[0] * 4, cell_size[1] * 5), (23, 20, 29, 255))
    for row, state in enumerate(STATES):
        for column, frame in enumerate(battle_frames(state)):
            scaled = frame.resize(cell_size, Image.Resampling.LANCZOS)
            sheet.alpha_composite(scaled, (column * cell_size[0], row * cell_size[1]))
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT_ROOT / "staff_battle_contact.png")


def main() -> int:
    for direction in ("down", "up", "left", "right"):
        save_gif(field_frames(direction), OUTPUT_ROOT / f"staff_field_walk_{direction}.gif", 100, 2.0)
    for state in ("ready", "move", "attack", "hit", "defeat"):
        save_gif(battle_frames(state), OUTPUT_ROOT / f"staff_battle_{state}.gif", 145, 0.75)
    build_contact_sheet()
    print(OUTPUT_ROOT.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
