"""Emit apply_patch additions for exact full candidates; never edits formal files."""
from pathlib import Path
import argparse
import difflib
import hashlib
import json
import shutil

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
SHADER="res://build/city_visual_diversity_20261031c/river_flow.gdshader"
ITEMS=[("game/build/three_settlements_20261030e_system01/xiangzhou_author.gd","xiangzhou_author_NPC_READY.gd","npc"),
       ("game/build/jinling_city_20261029_system01/city_author.gd","jinling_author_NPC_READY.gd","npc"),
       ("game/build/three_settlements_20261030e_system01/settlement_field.gd","settlement_field_WATER_READY.gd","xiangzhou_water"),
       ("game/build/jinling_city_20261029_system01/jinling_field.gd","jinling_field_WATER_READY.gd","jinling_water")]

def sha(b):return hashlib.sha256(b).hexdigest()
def make(key,mode):
    before=(ROOT/key).read_bytes();text=before.decode("utf-8")
    if mode=="npc":
        anchor='\t\t\trow.walk_sprite_path="res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png" if p[2]==young else "res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"\n'
        assert text.count(anchor)==1
        insert='\t\t\t# Actual merchant strip faces LEFT despite its historical filename; guard faces RIGHT.\n\t\t\trow.invert_patrol_facing = p[2] != young\n'
        after=text.replace(anchor,anchor+insert,1)
        changes=[{"old":anchor,"new":anchor+insert}]
    else:
        anchor='\tnode.set_meta("jl_texture_path",texture_path);node.set_meta("jl_period",period)\n'
        assert text.count(anchor)==1
        guard='A.ID==&"openworld_xiangzhou_city" and id=="river"' if mode=="xiangzhou_water" else 'id=="canal_water"'
        insert='\t# Exact standalone water tile only; no bridge/bank/feather material changes.\n'
        insert+='\tif '+guard+' and texture_path=="res://art/maps/jinling_city_20261029/river_water_v1.png" and source_uv.is_empty() and feather_px<=0.0:\n'
        insert+='\t\tvar water_flow_material:=ShaderMaterial.new()\n\t\twater_flow_material.shader=preload("'+SHADER+'")\n\t\tnode.material=water_flow_material\n'
        after=text.replace(anchor,insert+anchor,1)
        changes=[{"old":anchor,"new":insert+anchor}]
    # Source snapshots keep original bytes; only new candidate has canonical EOF.
    if after.endswith("\n\n"):
        changes.append({"old":after[after.rfind('\treturn ""'):],"new":after[after.rfind('\treturn ""'):].rstrip()+"\n","reason":"New strict-source GDScript canonical single EOF LF; formal source untouched"})
    after=after.rstrip()+"\n"
    return before,after.encode("utf-8"),changes

parser=argparse.ArgumentParser();parser.add_argument("--emit-patch",action="store_true");parser.add_argument("--seal",action="store_true")
args=parser.parse_args()
if args.emit_patch:
    lines=["*** Begin Patch"]
    for key,name,mode in ITEMS:
        before,after,_=make(key,mode)
        assert not (OUT/name).exists()
        lines.append("*** Add File: "+(OUT/name).as_posix())
        lines.extend("+"+line for line in after.decode("utf-8").splitlines())
    lines.append("*** End Patch")
    print("\n".join(lines))
elif args.seal:
    targets=[]
    for key,name,mode in ITEMS:
        before,after,changes=make(key,mode)
        candidate=OUT/name;assert candidate.read_bytes()==after
        backup=OUT/(name+".BEFORE")
        assert not backup.exists();shutil.copyfile(ROOT/key,backup)
        assert backup.read_bytes()==before and (ROOT/key).read_bytes()==before
        diff="".join(difflib.unified_diff(before.decode("utf-8").splitlines(True),after.decode("utf-8").splitlines(True),fromfile=key,tofile=candidate.relative_to(ROOT).as_posix()))
        diffpath=OUT/(name+".diff");assert not diffpath.exists();diffpath.write_text(diff,encoding="utf-8")
        targets.append({"target":key,"candidate":candidate.relative_to(ROOT).as_posix(),"before":backup.relative_to(ROOT).as_posix(),
                        "old_sha256":sha(before),"new_sha256":sha(after),"bytes":len(after),"mode":mode,"changes":changes})
    shader=OUT/"river_flow.gdshader"
    result={"status":"NPC_AND_TWO_WATER_VISUAL_SOURCE_CANDIDATES_NO_ENGINE_NO_FORMAL_WRITES",
            "targets":targets,"new_modules":{shader.relative_to(ROOT).as_posix():{"sha256":sha(shader.read_bytes()),"bytes":shader.stat().st_size}},
            "npc_changes":{"xiangzhou":["xiangzhou_life_15","xiangzhou_life_18"],"jinling":["jinling_life_03","jinling_life_27","jinling_life_32"],
                           "right_facing_guards_unchanged_false":True,"luoyang_current_four_merchant_walk_rows_already_invert_true":True},
            "water_changes":"Only exact original standalone tile Polygon material; original polygon,UV,period,alpha,bridge/bank geometry/collision and all business identical. TIME drives low-amplitude color sampling only.",
            "not_changed":["shared NPCNode","Router","registry/native manifests","PNG/import","Quest/Dialog/NPC names/positions/actions/patrol speed-distance","Luoyang compiled bins"],
            "engine_calls":0,"old_source_writes":0}
    path=OUT/"npc_water_manifest_READY.json";assert not path.exists();path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"manifest_sha256":sha(path.read_bytes()),"targets":[{"target":t["target"],"old_sha256":t["old_sha256"],"new_sha256":t["new_sha256"]} for t in targets]}))
