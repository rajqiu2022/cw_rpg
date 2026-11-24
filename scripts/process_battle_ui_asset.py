"""Process the generated battle UI sheet into reusable transparent controls."""
from pathlib import Path

from PIL import Image


SOURCE = Path(r"C:/Users/rajqiu/.codex/generated_images/019f37c1-1867-7ba0-b982-13e2b66df97b/exec-2d816d71-4f34-49bf-8bcc-0a74674b2647.png")
OUT = Path(r"F:/Code/RPG_GAME/game/art/ui/battle/candidates")


def key_out(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            # Keep a small feather around the chroma edge while removing the
            # flat magenta canvas and its antialiased fringe.
            distance = max(0, r - g) + max(0, b - g)
            if r > 190 and b > 150 and g < 80:
                pixels[x, y] = (r, g, b, 0)
            elif distance > 150 and g < 125:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def save_crop(image: Image.Image, name: str, box: tuple[int, int, int, int]) -> None:
    crop = image.crop(box)
    crop.save(OUT / name)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    source = key_out(Image.open(SOURCE))
    source.save(OUT / "battle_controls_sheet_v1.png")
    save_crop(source, "battle_skill_panel_frame_v1.png", (43, 77, 1624, 620))
    save_crop(source, "battle_command_normal_v1.png", (43, 698, 548, 855))
    save_crop(source, "battle_command_hover_v1.png", (583, 698, 1088, 855))
    save_crop(source, "battle_command_pressed_v1.png", (1122, 698, 1626, 855))


if __name__ == "__main__":
    main()
