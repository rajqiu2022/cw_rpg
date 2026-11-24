import re
import shutil
from pathlib import Path
game = Path("game")
temp = game / "build/story_enemies_20261109/import_project"
for mapping in temp.glob("art/**/*.png.import"):
    local = game / mapping.relative_to(temp)
    shutil.copyfile(mapping, local)
    files = set(re.findall(r'res://(\.godot/imported/[^"]+?\.ctex)',mapping.read_text(encoding="utf-8")))
    assert files, mapping
    for artifact in files:
        shutil.copyfile(temp / artifact, game / artifact)

