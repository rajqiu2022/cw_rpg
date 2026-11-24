"""Prepare exact full source successors after NPC/water stage; never edit formal targets."""
from pathlib import Path
import argparse
import difflib
import hashlib
import json
import shutil

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
HELPER="res://build/city_visual_diversity_20261031c/district_visuals.gd"
BASES=[("game/build/three_settlements_20261030e_system01/xiangzhou_author.gd","xiangzhou_author_NPC_READY.gd","xiangzhou_author_DISTRICT_READY.gd","xiangzhou"),
       ("game/build/jinling_city_20261029_system01/city_author.gd","jinling_author_NPC_READY.gd","jinling_author_DISTRICT_READY.gd","jinling"),
       ("game/build/jinling_city_20261029_system01/jinling_field.gd","jinling_field_WATER_READY.gd","jinling_field_DISTRICT_READY.gd","jinling_field"),
       ("game/build/luoyang_regions_20261027d_source01/region_field.gd",None,"luoyang_region_field_DISTRICT_READY.gd","luoyang")]
BUILDINGS=[
 {"city":"xiangzhou","id":"north_lodging","old":[4820,900,850,240],"new":[4900,890,640,220],"replacement":"WEST"},
 {"city":"xiangzhou","id":"workshop_long","old":[700,2260,900,250],"new":[700,2260,900,250],"replacement":"BASE+canal_warehouse_v3.png"},
 {"city":"xiangzhou","id":"quay_wing_e","old":[3440,2900,560,220],"new":[3440,2890,540,210],"replacement":"WEST"},
 {"city":"jinling","id":"silk_workshop","old":[2300,1180,950,250],"new":[2180,1170,620,220],"replacement":"EAST"},
 {"city":"jinling","id":"silk_storage","old":[3500,1180,900,250],"new":[3610,1160,620,220],"replacement":"WEST"},
 {"city":"jinling","id":"west_home_front","old":[600,3580,950,240],"new":[470,3570,540,230],"replacement":"EAST"}]

def sha(b):return hashlib.sha256(b).hexdigest()
def swap(text,old,new,changes):
    assert text.count(old)==1,old
    changes.append({"old":old,"new":new})
    return text.replace(old,new,1)
def make(target,base,mode):
    before=(OUT/base).read_bytes() if base else (ROOT/target).read_bytes()
    text=before.decode("utf-8");changes=[]
    if mode=="xiangzhou":
        for a,b in [
          ('["north_lodging",BASE+"inn_v1.png",Vector2(4820,900),850,240,','["north_lodging",WEST,Vector2(4900,890),640,220,'),
          ('["workshop_long",BASE+"shop_v1.png",Vector2(700,2260),900,250,','["workshop_long",BASE+"canal_warehouse_v3.png",Vector2(700,2260),900,250,'),
          ('["quay_wing_e",EAST,Vector2(3440,2900),560,220,','["quay_wing_e",WEST,Vector2(3440,2890),540,210,'),
          ('PackedVector2Array([Vector2(270,1050),Vector2(5410,1050)])','PackedVector2Array([Vector2(270,1050),Vector2(1450,1050),Vector2(2050,1090),Vector2(3920,1090),Vector2(4120,1050),Vector2(5410,1050)])'),
          ('{"id":"military_cross","points":PackedVector2Array([Vector2(270,1760),Vector2(5410,1760)]),"width":176.0,"texture":STONE},',
           '{"id":"military_cross","points":PackedVector2Array([Vector2(1450,1760),Vector2(3950,1760)]),"width":176.0,"texture":STONE},\n\t\t{"id":"military_supply_spur","points":PackedVector2Array([Vector2(270,1760),Vector2(1380,1760),Vector2(1380,2180)]),"width":112.0,"texture":SOIL},')]:text=swap(text,a,b,changes)
        anchor='\tfor raw: Dictionary in River.river_binding().get("ground",[]):\n'
        text=swap(text,anchor,'\tfor patch: Dictionary in preload("'+HELPER+'").rows("xiangzhou"):out.append(patch)\n'+anchor,changes)
    elif mode=="jinling":
        for a,b in [
          ('["silk_workshop",BASE+"shop_v1.png",Vector2(2300,1180),950,250,','["silk_workshop",EAST,Vector2(2180,1170),620,220,'),
          ('["silk_storage",BASE+"street_row_v3.png",Vector2(3500,1180),900,250,','["silk_storage",WEST,Vector2(3610,1160),620,220,'),
          ('["west_home_front",BASE+"shop_v1.png",Vector2(600,3580),950,240,','["west_home_front",EAST,Vector2(470,3570),540,230,'),
          ('PackedVector2Array([Vector2(260,1260),Vector2(5372,1260)])','PackedVector2Array([Vector2(260,1260),Vector2(1200,1260),Vector2(1630,1340),Vector2(2200,1340),Vector2(2500,1260),Vector2(3650,1260),Vector2(4150,1320),Vector2(5372,1320)])'),
          ('{"id":"north_service","points":PackedVector2Array([Vector2(260,780),Vector2(5372,780)]),"width":128.0,"texture":SOIL},',
           '{"id":"north_service","points":PackedVector2Array([Vector2(260,780),Vector2(1300,780),Vector2(1750,860),Vector2(2600,860)]),"width":112.0,"texture":SOIL},\n\t\t{"id":"north_service_e","points":PackedVector2Array([Vector2(3650,780),Vector2(4300,780),Vector2(4800,860),Vector2(5372,860)]),"width":104.0,"texture":SOIL},'),
          ('PackedVector2Array([Vector2(1360,2660),Vector2(1360,3900)])','PackedVector2Array([Vector2(1360,2660),Vector2(1380,3140),Vector2(1380,3660),Vector2(900,3760)])')]:text=swap(text,a,b,changes)
    elif mode=="jinling_field":
        anchor='\tfor road: Dictionary in JL.roads():\n'
        insert='\tfor patch: Dictionary in preload("'+HELPER+'").rows("jinling"):\n\t\t_draw_jl_patch(patch.id,patch.polygon,patch.texture,patch.period,patch.z,PackedVector2Array(),patch.feather_px)\n'
        text=swap(text,anchor,insert+anchor,changes)
    elif mode=="luoyang":
        anchor='\tif GardenVisual.handles(_region): return GardenVisual.install(self, _region_owner, _region)\n'
        insert='\t# Only drawing in the Civic/Market exterior; all immutable bins/physics/doors stay intact.\n\tif not preload("'+HELPER+'").install_luoyang(self,_region):return false\n'
        text=swap(text,anchor,insert+anchor,changes)
    return before,(text.rstrip()+"\n").encode("utf-8"),changes

parser=argparse.ArgumentParser();parser.add_argument("--emit-patch",action="store_true");parser.add_argument("--seal",action="store_true");args=parser.parse_args()
if args.emit_patch:
    lines=["*** Begin Patch"]
    for target,base,name,mode in BASES:
        _,after,_=make(target,base,mode);assert not (OUT/name).exists()
        lines.append("*** Add File: "+(OUT/name).as_posix());lines.extend("+"+s for s in after.decode("utf-8").splitlines())
    lines.append("*** End Patch");print("\n".join(lines))
elif args.seal:
    targets=[]
    for target,base,name,mode in BASES:
        before,after,changes=make(target,base,mode);candidate=OUT/name;assert candidate.read_bytes()==after
        backup=OUT/(name+".BEFORE");assert not backup.exists();backup.write_bytes(before)
        diffpath=OUT/(name+".diff");assert not diffpath.exists()
        diffpath.write_text("".join(difflib.unified_diff(before.decode("utf-8").splitlines(True),after.decode("utf-8").splitlines(True),fromfile=target,tofile=candidate.relative_to(ROOT).as_posix())),encoding="utf-8")
        targets.append({"target":target,"candidate":candidate.relative_to(ROOT).as_posix(),"old_sha256":sha(before),"new_sha256":sha(after),"bytes":len(after),"before":backup.relative_to(ROOT).as_posix(),"changes":changes,
                        "base_stage":"NPC_WATER_READY first; not the older formal source" if base else "current formal RegionField"})
    for item in BUILDINGS:
        old=item["old"];new=item["new"]
        def body(v):x,y,w,d=v;return [x-.43*w,y-d,.86*w,d]
        a=body(old);b=body(new)
        subset=b[0]>=a[0]-1e-7 and b[1]>=a[1]-1e-7 and b[0]+b[2]<=a[0]+a[2]+1e-7 and b[1]+b[3]<=a[1]+a[3]+1e-7
        assert subset,item
        item.update({"old_body":a,"new_body":b,"new_body_subset_of_old":subset})
    modules={}
    for name in ["district_visuals.gd","district_ground_edge.gdshader","district_patches.json"]:
        p=OUT/name;modules[p.relative_to(ROOT).as_posix()]={"sha256":sha(p.read_bytes()),"bytes":p.stat().st_size}
    result={"status":"DISTRICT_LAYOUT_SOURCE_CANDIDATES_AFTER_NPC_WATER_NOT_ENGINE_OR_ART_ACCEPTED",
            "targets":targets,"new_modules":modules,"building_changes":BUILDINGS,
            "cities":{"xiangzhou":["U-shaped drill hardstand and short supply spur","military warehouse/side lodging inside old body","asymmetric quay loading/office"],
                      "jinling":["nonmirrored silk side courts and short back alleys","west well courtyard with side residence","east quay pocket court"],
                      "luoyang":["west artisan approach continuous frontage","cloth front/back workcourt threshold","medicine courtyard asymmetric frontage; original main axis retained"]},
            "preserved":["all real portals/NPC rows-feet-actions/shops/quests","water polygons/bridges/rail bodies","original saved foot semantics and layout versions","all Luoyang immutable bins/floor_rects/solids","non-Civic Luoyang areas including temple/garden/indoors"],
            "old_native_save_safety":"Six building bodies are equal/subsets of their exact old bodies; no new blocked old-legal native foot, no generic or nearest migration. Decorative ground has no collision. No new props/body added.",
            "proof_scope":"Analytic exact Rectangle subset only, not runtime/Physics or visual acceptance. Root must inspect new architectural/road interfaces in normal camera.","engine_calls":0,"official_writes":0}
    p=OUT/"district_manifest_READY.json";assert not p.exists();p.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"manifest_sha256":sha(p.read_bytes()),"targets":[{"target":x["target"],"old_sha256":x["old_sha256"],"new_sha256":x["new_sha256"]} for x in targets],"body_subsets":len(BUILDINGS)}))
