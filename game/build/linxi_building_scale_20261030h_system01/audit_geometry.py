"""Independent rectangle/polygon checks for this changed domain only; no Godot."""
from pathlib import Path
import json
import math
import sys

HERE = Path(__file__).parent


def solids(data):
    feet = {r["name"]:r["foot"] for r in data["objects"]}
    out = {}
    for row in data["blockers"]:
        path = row["path"]
        origin = feet[path.split("/")[1]] if path.startswith("Town/") and path.endswith("/Body") else [0,0]
        out[path] = [[x+origin[0],y+origin[1]] for x,y in row["polygon"]]
    return out


def overlap(a,b):
    for shape in [a,b]:
        for p,q in zip(shape,shape[1:]+shape[:1]):
            axis = [p[1]-q[1],q[0]-p[0]]
            x = [u*axis[0]+v*axis[1] for u,v in a]
            y = [u*axis[0]+v*axis[1] for u,v in b]
            if max(x)<min(y) or max(y)<min(x):
                return False
    return True


def blocked(foot, bodies):
    x,y = foot
    body = [[x-17,y-12],[x+17,y-12],[x+17,y+12],[x-17,y+12]]
    return [key for key,polygon in bodies.items() if overlap(body,polygon)]


report = {"engine_calls": 0, "method": "Independent convex SAT full34x24, no runtime/physics/ART claim", "layouts": {}}
for key in ["linxi_center","linxi_south"]:
    data = json.loads((HERE / (key+".json")).read_text(encoding="utf-8"))
    bodies = solids(data)
    old = json.loads((HERE / "before/game/art/modules/four_settlements_20261030e" / (key+".json")).read_text(encoding="utf-8"))
    old_bodies = solids(old)
    facts = json.loads((HERE/"candidate_facts_BUILD.json").read_text(encoding="utf-8"))["facts"][key]
    rows = {r["name"]:r for r in data["objects"]}
    doors = {name:{"foot":p,"hits":blocked(p,bodies)} for name,p in data["business"]["portal_targets"].items()}
    npcs = {name:{"foot":p,"hits":blocked(p,bodies)} for name,p in data["business"]["npcs"].items()}
    changed = set(facts["buildings"])
    intersections = []
    for name in changed:
        own = "Town/"+name+"/Body"
        for other,polygon in bodies.items():
            if own == other:
                continue
            if overlap(bodies[own],polygon):
                intersections.append([own,other])
    routes = {}
    # Only main existing circulation and functional doorway approach stubs.
    for i in [0,1,2,3,4] if key == "linxi_center" else [0,1,2,3,4]:
        route = data["roads"][i]
        hits = []
        inherited_hits = 0
        new_hits = []
        count = 0
        for a,b in zip(route["points"],route["points"][1:]):
            n = math.ceil(math.dist(a,b)/6)
            for j in range(n+1):
                p = [a[d]+(b[d]-a[d])*j/n for d in range(2)]
                count += 1
                hit = blocked(p,bodies)
                if hit:
                    hits.append({"foot":p,"bodies":hit})
                    if blocked(p,old_bodies):
                        inherited_hits += 1
                    else:
                        new_hits.append({"foot":p,"bodies":hit})
        routes[str(i)] = {"samples":count,"blocked":len(hits),"inherited_old_blocked_samples":inherited_hits,"newly_blocked_samples":len(new_hits),"first_hits":hits[:5]}
    report["layouts"][key] = {"doors":doors,"npcs":npcs,"building_solid_overlaps":intersections,"routes":routes}
path = HERE / (sys.argv[1] if len(sys.argv)>1 else "geometry_attempt01.json")
assert not path.exists(), path
path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({key:{"blocked_doors":[k for k,v in val["doors"].items() if v["hits"]],"blocked_npcs":[k for k,v in val["npcs"].items() if v["hits"]],"overlaps":val["building_solid_overlaps"],"routes":{k:v["blocked"] for k,v in val["routes"].items()}} for key,val in report["layouts"].items()},ensure_ascii=False))
