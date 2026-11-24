"""Read-only independent rectangle audit; deliberately not Godot or Physics QA."""
from pathlib import Path
import json
import math
import re

source = Path(__file__).with_name("yanmen_author.gd").read_text(encoding="utf-8")
solids = []


def rect(identity, x, y, width, height):
    solids.append((identity, (x, y, x + width, y + height)))


for match in re.finditer(r'_house\("([^"]+)","[^"]+",Vector2\(([\d.]+),([\d.]+)\),([\d.]+),([\d.]+),([\d.]+),', source):
    identity, x, y, scale, width, depth = match.groups()
    x, y, width, depth = map(float, (x, y, width, depth))
    rect(identity, x - width * .43, y - depth, width * .86, depth)
for match in re.finditer(r'_gate\("([^"]+)",Vector2\(([\d.]+),([\d.]+)\),([\d.]+)\)', source):
    identity, x, y, scale = match.groups()
    x, y, scale = map(float, (x, y, scale))
    for side, anchor_x in [("left", 347), ("right", 1267)]:
        rect(identity + side, x + (anchor_x - 1044.5) * scale, y - 192 * scale, 475 * scale, 192 * scale)
for match in re.finditer(r'\["(main_wall_[we])",Vector2\(([\d.]+),([\d.]+)\)\]', source):
    identity, x, y = match.groups()
    x, y = map(float, (x, y))
    rect(identity, x - 723 * .72, y - 90 * .72, 1446 * .72, 90 * .72)
for match in re.finditer(r'\["([^"]+)",(WALL_[WE]),Vector2\(([\d.]+),([\d.]+)\),([\d.]+)\]', source):
    identity, kind, x, y, scale = match.groups()
    x, y, scale = map(float, (x, y, scale))
    a, b, width, height = (49-148.5, 329-892, 199, 563) if kind == "WALL_W" else (50-136.5, 337-624, 173, 287)
    rect(identity, x+a*scale, y+b*scale, width*scale, height*scale)
loops = re.findall(r'for p: Vector2 in \[(.*?)\]:', source)
for index, (scale, anchor, box) in enumerate([
    (.59, (1107, 976), (360, 535, 1460, 441)),
    (.30, (990, 1116), (920, 1050, 140, 66)),
    (.14, (1005, 966), (600, 780, 810, 186)),
    (.14, (643.5, 965), (300, 780, 687, 185)),
]):
    for number, (x, y) in enumerate(re.findall(r'Vector2\(([\d.]+),([\d.]+)\)', loops[index])):
        x, y = map(float, (x, y))
        a, b, width, height = box
        rect(f"prop_{index}_{number}", x+(a-anchor[0])*scale, y+(b-anchor[1])*scale, width*scale, height*scale)
for identity, x, y, scale in [("post_spine", 1750, 3560, .39), ("parcel_rock", 3750, 3220, .33)]:
    rect(identity, x+(360-1107)*scale, y+(535-976)*scale, 1460*scale, 441*scale)
rect("barbican_left", 1930, 2670, 50, 420)
rect("barbican_right", 2628, 2670, 50, 420)
for identity, x, y in [("shelter_west", 1530, 3020), ("shelter_east", 3100, 3020)]:
    rect(identity, x+(420-1045)*.37, y+(810-1065)*.37, 1150*.37, 255*.37)

land = [(1050,4020),(3370,4020),(4250,3650),(4250,1360),(4010,790),(3020,790),(2780,930),(950,930),(480,1290),(480,3210),(970,3610)]


def inside(x, y):
    result = False
    previous = len(land) - 1
    for index, (a, b) in enumerate(land):
        c, d = land[previous]
        if ((b > y) != (d > y)) and x < (c-a)*(y-b)/(d-b)+a:
            result = not result
        previous = index
    return result


def blocked(point):
    x, y = point
    if any(not inside(x+a, y+b) for a,b in [(-17,-12),(17,-12),(17,12),(-17,12)]):
        return "land"
    for identity, (left, top, right, bottom) in solids:
        if x+17 >= left and x-17 <= right and y+12 >= top and y-12 <= bottom:
            return identity
    return None


# Only the two failed branches are rechecked; prior successful main/parcel
# evidence remains in attempt01 and is not recounted as new successes.
routes = {
    "west_residual": [(2304,3290),(1270,3290),(720,2860),(720,1800),(1060,1660),(1060,2230),(2304,2230)],
    "east_residual": [(2304,3580),(3360,3580),(4160,3450),(4160,1810),(3500,1660),(3500,2230),(2304,2230)],
}
report = {}
for identity, points in routes.items():
    hits = []
    samples = 0
    for start, end in zip(points, points[1:]):
        count = math.ceil(math.dist(start, end) / 8)
        for step in range(count + 1):
            point = tuple(start[axis]+(end[axis]-start[axis])*step/count for axis in range(2))
            hit = blocked(point)
            samples += 1
            if hit:
                hits.append([point, hit])
    report[identity] = {"samples": samples, "blocked_count": len(hits), "first_hits": hits[:3]}
print(json.dumps({"read_only_independent_rect_audit": True, "not_engine_physics": True, "solids": len(solids), "routes": report}, ensure_ascii=False))
raise SystemExit(1 if any(row["blocked_count"] for row in report.values()) else 0)
