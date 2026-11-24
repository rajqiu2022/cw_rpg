"""Prepare one exact-byte RGB water PNG in a new isolated project; no engine/promotion."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
STAGE=HERE/"water_import01"
RAW=ROOT/"assets/raw/world_water_bridge_20261024d/world_river_fine_water_20261024d_v1.png"
SHA="54718c63a29a7492e78f637acdeb3237b6ddcc43e9dbca07b5b77a373f8081fc"
RESOURCE="res://art/maps/jinling_city_20261029/river_water_v1.png"
assert hashlib.sha256(RAW.read_bytes()).hexdigest()==SHA
dest=STAGE/RESOURCE.removeprefix("res://")
assert not dest.exists(),"CreateNew only; preserve prior attempts"
dest.parent.mkdir(parents=True,exist_ok=True)
shutil.copyfile(RAW,dest)
compiled="res://.godot/imported/river_water_v1.png-"+hashlib.md5(RESOURCE.encode()).hexdigest()+".ctex"
template=(ROOT/"game/art/modules/world_map_v13/bridge_stone_northsouth_v1.png.import").read_text("utf-8")
sidecar=template.replace("res://.godot/imported/bridge_stone_northsouth_v1.png-3c8d112696b32f166d27aa49adb6d9d0.ctex",compiled).replace("res://art/modules/world_map_v13/bridge_stone_northsouth_v1.png",RESOURCE).replace("process/fix_alpha_border=true","process/fix_alpha_border=false").replace("detect_3d/compress_to=1","detect_3d/compress_to=0")
sidecar="\n".join(line for line in sidecar.splitlines() if not line.startswith("uid="))+"\n"
Path(str(dest)+".import").write_text(sidecar,"utf-8")
im=Image.open(RAW).convert("RGBA")
prepared={"status":"ONE_WATER_ISOLATE_PREPARED_NOT_RUN","textures":[{"id":"river_water_v1","png":RESOURCE,"compiled":compiled,"png_sha256":SHA,"RGBA_sha256":hashlib.sha256(im.tobytes()).hexdigest(),"size":list(im.size)}],"raw_path":str(RAW),"raw_sha256":SHA,"import_parameters":{"compress/mode":0,"mipmaps/generate":False,"process/fix_alpha_border":False,"process/premult_alpha":False,"detect_3d/compress_to":0}}
(STAGE/"prepared.json").write_text(json.dumps(prepared,ensure_ascii=False,indent=2)+"\n","utf-8")
leaves=[{"kind":kind,"source_isolate":str(STAGE/res.removeprefix("res://")),"target_main":str(ROOT/"game"/res.removeprefix("res://")),"target_res":res} for kind,res in [("png",RESOURCE),("sidecar",RESOURCE+".import"),("ctex",compiled)]]
(HERE/"three_leaf_plan_NOT_EXECUTED.json").write_text(json.dumps({"status":"ROOT_ONLY_AFTER_NATURAL_IMPORT_AND_WHOLE_RGBA_VERIFY","leaves":leaves},ensure_ascii=False,indent=2)+"\n","utf-8")
print(json.dumps(prepared,ensure_ascii=False))
