from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/raw/ui/field_hud/candidates/system_text_reference.png"
FONT = Path("C:/Windows/Fonts/STXINGKA.TTF")


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (512, 256), (255, 255, 255))
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(FONT), 150)
    text = "系统"
    bbox = draw.textbbox((0, 0), text, font=font)
    x = (image.width - (bbox[2] - bbox[0])) // 2
    y = (image.height - (bbox[3] - bbox[1])) // 2 - 18
    draw.text((x, y), text, font=font, fill=(0, 0, 0))
    image.save(OUT)
    print(OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
