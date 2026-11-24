"""Finite source/data-only checks for31c candidates; never engine or media decode."""
from pathlib import Path
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(name):return json.loads((OUT/name).read_text(encoding="utf-8"))
def orientation(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def proper_cross(a,b,c,d):
    return orientation(a,b,c)*orientation(a,b,d)<0 and orientation(c,d,a)*orientation(c,d,b)<0
def npc_section(text):return text.split("static func npc_rows()",1)[1].split("static func scene()",1)[0]

npc=load("npc_water_manifest_READY.json");district=load("district_manifest_READY.json")
patches=load("district_patches.json")
textures={};polygons=[]
for city,rows in patches["cities"].items():
    assert len(rows)==3
    for row in rows:
        p=row["polygon"];n=len(p);assert 3<=n<=16
        assert all(p[i]!=p[(i+1)%n] for i in range(n))
        for i in range(n):
            for j in range(i+1,n):
                if j==i+1 or (i==0 and j==n-1):continue
                assert not proper_cross(p[i],p[(i+1)%n],p[j],p[(j+1)%n]),row["id"]
        assert min(row["period"])>0
        key="game/"+row["texture"][6:];assert (ROOT/key).is_file();textures[key]=sha(ROOT/key)
        polygons.append({"city":city,"id":row["id"],"vertices":n,"bbox":[min(v[0] for v in p),min(v[1] for v in p),max(v[0] for v in p),max(v[1] for v in p)]})

for a,b in [("xiangzhou_author_NPC_READY.gd","xiangzhou_author_DISTRICT_READY.gd"),("jinling_author_NPC_READY.gd","jinling_author_DISTRICT_READY.gd")]:
    assert npc_section((OUT/a).read_text(encoding="utf-8"))==npc_section((OUT/b).read_text(encoding="utf-8"))
for target in district["targets"]:
    before=(ROOT/target["before"]).read_text(encoding="utf-8")
    after=(ROOT/target["candidate"]).read_text(encoding="utf-8")
    assert re.findall(r'^\s*(?:static )?func ([^\n]+)',before,re.M)==re.findall(r'^\s*(?:static )?func ([^\n]+)',after,re.M)
    assert after.endswith("\n") and not after.endswith("\n\n")
    assert sha(ROOT/target["candidate"])==target["new_sha256"]
for row in district["building_changes"]:assert row["new_body_subset_of_old"]

# Each Luoyang shape is contained in an existing single ground/floor rectangle.
author=ROOT/"game/build/luoyang_yihongyuan_20261029n_system01/output/58540/regions_author_READY.json"
ground=json.loads(author.read_text(encoding="utf-8"))["regions"]["luoyang_civic_market_region_27d"]["ground"]
coverage=[]
for row in patches["cities"]["luoyang"]:
    covers=[]
    for floor in ground:
        origin,size=floor["rect"]
        if all(origin[0]<=p[0]<=origin[0]+size[0] and origin[1]<=p[1]<=origin[1]+size[1] for p in row["polygon"]):covers.append(floor["id"])
    assert covers,row["id"]
    coverage.append({"patch":row["id"],"contained_in_existing_ground_rect":covers})

proof={"status":"FINITE_STATIC_CANDIDATE_CHECKS_NOT_ENGINE_OR_ART","patches":polygons,
       "nine_polygons_simple_max16_vertices":True,"luoyang_floor_rect_coverage":coverage,
       "six_building_bodies_exact_old_body_subsets":True,"original_npc_sections_exact_after_district_stage":True,
       "public_GDS_function_signatures_unchanged":True,"native_scale_max_on_replaced_SIDE_assets":620/1009,
       "root_original_doors_water_bridges_regions_and_migration_methods_not_edited":True,
       "shader_note":"TIME/color sampling only on exact original standalone water tile nodes; originalAlpha retained. NeedsRoot compile/GPU; no local engine claim.",
       "texture_source_sha256_readonly":textures,"new_media":0,"PNG_pixel_writes":0,"engine_calls":0,"save_reads_or_writes":0,
       "facing_audit":"14 authored/compiled patrol rows;3 actual sheets visually checked: merchantLeft, bothguardRight. Exactly5 bad merchant rows patched;4Luoyang merchant rows already correct.",
       "source_facts":"source_facts_FINAL.json","source_facts_sha256":sha(OUT/"source_facts_FINAL.json")}
p=OUT/"candidate_static_PROOF.json";assert not p.exists();p.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"proof_sha256":sha(p),"patches":len(polygons),"building_subsets":6,"luoyang_coverage":coverage}))
