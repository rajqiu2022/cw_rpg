"""Read frozen author rectangles into visual-only boundary proposal; no engine."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
author=HERE/"artisan_revision4/author_READY.json"
j=json.loads(author.read_text(encoding="utf-8"))
scene=next(s for s in j["scenes"] if s["scene_id"]=="luoyang_artisan_residential_20261022ap")
rows=[s for s in scene["ground_sections"] if s["asset"]=="stone"]
assert len(rows)==9
rects=[s["rect"] for s in rows]
xs=sorted(set(x for r in rects for x in (r[0],r[0]+r[2])))
ys=sorted(set(y for r in rects for y in (r[1],r[1]+r[3])))
def inside(x,y):return any(a<=x<=a+w and b<=y<=b+h for a,b,w,h in rects)
edges={}
for x0,x1 in zip(xs,xs[1:]):
    for y in ys:
        above=inside((x0+x1)/2,y-.01);below=inside((x0+x1)/2,y+.01)
        if above!=below:edges.setdefault(("horizontal",y,"stone_above" if above else "stone_below"),[]).append([x0,x1])
for y0,y1 in zip(ys,ys[1:]):
    for x in xs:
        left=inside(x-.01,(y0+y1)/2);right=inside(x+.01,(y0+y1)/2)
        if left!=right:edges.setdefault(("vertical",x,"stone_left" if left else "stone_right"),[]).append([y0,y1])
segments=[]
for (axis,fixed,side),intervals in sorted(edges.items()):
    merged=[]
    for lo,hi in sorted(intervals):
        if merged and merged[-1][1]==lo:merged[-1][1]=hi
        else:merged.append([lo,hi])
    for lo,hi in merged:
        segments.append({"from":[lo,fixed] if axis=="horizontal" else [fixed,lo],"to":[hi,fixed] if axis=="horizontal" else [fixed,hi],"stone_side":side})
screens=[GAME/"build/luoyang_city_full_rollout_20261022ap_qa01/bounded_actual_A/117812_2743"/s for s in ("ch4_s0_luoyang_gate.png","ch4_s1_luoyang_yamen.png","ch4_s4_ancient_temple.png")]
screens.append(GAME/"build/luoyang_city_full_rollout_20261022ap_qa01/bounded_actual_C/31780_2912/luoyang_artisan_residential_20261022ap.png")
proposal={"status":"SOURCE_DERIVED_VISUAL_BOUNDARY_PROPOSAL_ONLY_NO_PATCH_NO_GEOMETRY_CREDIT",
 "images_actually_viewed":[{"path":ref(p),"sha256":sha(p)} for p in screens],
 "author":{"path":ref(author),"sha256":sha(author)},"scene_id":scene["scene_id"],
 "observed_cause":"C screenshot rectilinear grass/stone boundaries are the original nine native ground_sections, not ENV (only one cart-rut alpha stamp). Every original tile must remain.",
 "preserved_nine_sections":[{"id":r["id"],"rect":r["rect"],"tile_size":r["tile_size"],"z":r["z"]} for r in rows],
 "exterior_union_segments_only":segments,
 "recommended_next_scope":"If separately authorized, bind a visual-only alpha transition to exact native stone-ground sprites using distance to the union exterior segments in world coordinates. No per-tile feather or per-section inner seams, no grass/stone berm repetition. Keep texture/atlas/resource/transform/count, preserve full-opacity connected paving core, and keep at least 48world transparent-to-opaque transition outside all door thresholds. This proposal changes no shader or sprite itself.",
 "not_chosen":"Do not mass-tile road_stone_grass_edge: actual viewed asset has raised moss/stone relief, making every civic lane look like a berm. Its approved Garden shoreline use remains untouched.",
 "forbidden":["native scene/layout/packet/mask edits","route recompute","NPC/door/spawn/return changes","image generation or processing","art pass inferred from numerical union","A/C technical replay"],
 "finite_acceptance":"One later same-camera visual comparison with original C image, original nine paths visibly continuous, no interior tile seams, no raised borders or bare-gray deletion. Technical C input/room credit remains inherited, not rerun."}
target=HERE/"artisan_ground_union_boundary_visual_proposal_READY.json"
assert not target.exists()
target.write_text(json.dumps(proposal,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"path":ref(target),"sha256":sha(target),"native_stone_sections":len(rows),"exterior_union_segments":len(segments)}))
