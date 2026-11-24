from pathlib import Path
from hashlib import sha256
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "assets/processed/luoyang_city_full_rollout_20261022ap"
OUT = Path(__file__).resolve().parent / "alpha_diagnostic_actual"
FILES = {
    "sign": ("sign_luoyang_pawnshop_dang_vertical_v1_clean_padded.png", "37C59298F97F640787F7B7CD612C41891C35F3E85EBAA6E7E2A8CE75299711D4"),
    "bridge": ("module_luoyang_riverside_curved_stone_bridge_v1_clean_padded.png", "A1C6CF366FCD922C65AF0227470A38EEDDF8575C704B1DC6D094D4BC52D023F4"),
    "pavilion": ("module_luoyang_riverside_four_column_hex_pavilion_v1_clean_padded.png", "E8F857C15C1A9BE0738663EF05825307E24500A2B889A578B53FA90DFC37E570"),
}
OUT.mkdir(parents=True, exist_ok=True)
for key, (name, expected) in FILES.items():
    path = SRC / name
    before = sha256(path.read_bytes()).hexdigest().upper()
    assert before == expected, (key, before)
    fg = Image.open(path).convert("RGBA")
    checker = Image.new("RGBA", fg.size, (238, 238, 238, 255))
    draw = ImageDraw.Draw(checker)
    for y in range(0, fg.height, 32):
        for x in range(0, fg.width, 32):
            if ((x // 32) + (y // 32)) & 1:
                draw.rectangle((x, y, min(x + 31, fg.width - 1), min(y + 31, fg.height - 1)), fill=(176, 176, 176, 255))
    white = Image.new("RGBA", fg.size, (255, 255, 255, 255))
    checker.alpha_composite(fg); white.alpha_composite(fg)
    joined = Image.new("RGB", (fg.width * 2, fg.height), "white")
    joined.paste(checker.convert("RGB"), (0, 0)); joined.paste(white.convert("RGB"), (fg.width, 0))
    target = OUT / f"{key}_checker_and_white.png"
    assert not target.exists(), target
    joined.save(target)
    assert sha256(path.read_bytes()).hexdigest().upper() == before
    print(key, target, sha256(target.read_bytes()).hexdigest().upper(), fg.size)
