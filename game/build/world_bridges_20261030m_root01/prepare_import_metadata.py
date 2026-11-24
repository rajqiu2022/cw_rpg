"""Generate importer sidecars in the isolated asset-import project only."""
import hashlib
from pathlib import Path

base = Path(__file__).resolve().parent / "import_isolated"
for i in range(5):
    relative = f"art/modules/world_bridges_20261030m/bridge_{i:02}.png"
    resource = "res://" + relative
    compiled = "res://.godot/imported/" + Path(relative).name + "-" + hashlib.md5(resource.encode()).hexdigest() + ".ctex"
    sidecar = base / (relative + ".import")
    sidecar.parent.mkdir(parents=True, exist_ok=True)
    assert not sidecar.exists(), "Preserve previous import metadata"
    sidecar.write_text(f'''[remap]
importer="texture"
type="CompressedTexture2D"
path="{compiled}"
metadata={{"vram_texture": false}}

[deps]
source_file="{resource}"
dest_files=["{compiled}"]

[params]
compress/mode=0
mipmaps/generate=false
process/fix_alpha_border=false
process/premult_alpha=false
process/size_limit=0
detect_3d/compress_to=0
''', encoding="utf-8")
print("ISOLATED_METADATA_READY=5; alpha-fix=false; source-pixels-not-edited")
