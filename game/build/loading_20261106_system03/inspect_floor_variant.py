"""Read only the accepted synthetic room asset, not game state or save data."""

import hashlib
import json
import math
import struct
import sys
from pathlib import Path

ROOM = Path(__file__).resolve().parent.parent / "interior_identity_20261107_runtime01/yihongyuan27n_interior.bin"
ROOM_HASH = "649075ce491953d63013f9f4ca0fe7d6eb3e6451e28980ff5865e451d9c004d9"


class Reader:
    def __init__(self, data):
        self.raw = data
        self.pos = 0

    def get(self, fmt):
        layout = struct.Struct("<" + fmt)
        out = layout.unpack_from(self.raw, self.pos)
        self.pos += layout.size
        return out[0] if len(out) == 1 else out

    def string(self):
        n = self.get("I")
        value = self.raw[self.pos:self.pos+n].decode()
        self.pos += (n+3) & ~3
        return value

    def variant(self):
        p = self.pos
        head = self.get("I")
        t, wide = head & 255, bool(head & (1 << 16))
        f = "d" if wide else "f"
        if t == 0:
            return None
        if t == 1:
            return bool(self.get("I"))
        if t == 2:
            return self.get("q" if wide else "i")
        if t == 3:
            return self.get(f)
        if t in (4, 21):
            return self.string()
        if t in (5, 6, 7, 8):
            return self.get((f if t in (5, 7) else "i") * (2 if t < 7 else 4))
        if t == 20:
            return self.get("ffff")
        if t == 27:
            count = self.get("I") & 0x7FFFFFFF
            return {self.variant(): self.variant() for _ in range(count)}
        if t == 28:
            if wide:
                self.get("I")  # Packed declaration of built-in element type.
            count = self.get("I") & 0x7FFFFFFF
            return [self.variant() for _ in range(count)]
        if t == 34:
            return [self.string() for _ in range(self.get("I"))]
        if t == 35:
            return [self.get(f * 2) for _ in range(self.get("I"))]
        raise ValueError("Unsupported plain Variant", p, t, head)


def load_room():
    data = ROOM.read_bytes()
    if hashlib.sha256(data).hexdigest() != ROOM_HASH:
        raise ValueError("Incorrect accepted immutable payload")
    reader = Reader(data)
    room = reader.variant()
    if reader.pos != len(data) or room["id"] != "yihongyuan27n_interior":
        raise ValueError("Asset identity")
    return room


def intersects(body, polygon):
    axes = [(1, 0), (0, 1)]
    for a, b in zip(polygon, polygon[1:] + polygon[:1]):
        axes.append((b[1]-a[1], a[0]-b[0]))
    for axis in axes:
        projected = [[x*axis[0]+y*axis[1] for x, y in vertices] for vertices in (body, polygon)]
        if max(projected[0]) < min(projected[1]) or max(projected[1]) < min(projected[0]):
            return False
    return True


def verify_x416(room):
    solids = room["solids"] + [
        [(384, 428), (395, 428), (386, 550), (359, 550)],
        [(437, 428), (448, 428), (473, 550), (446, 550)],
        [(384, 427), (448, 427), (448, 438), (384, 438)],
    ]
    boxes = []
    for row in room["npcs"]:
        assert row["data"]["movement_mode"] in {"idle", "seated"}
        x, y = (sum(p) for p in zip(row["foot"], row["body_offset_px"]))
        u, v = row["half_body"]
        boxes.append((x-u-17, y-v-12, x+u+17, y+v+12))
    assert room["floor_rects"] == [(0, 0, 1536, 1024)]
    routes = {
        "in": [(768, 850), (768, 594), (416, 594), (416, 456)],
        "out": [(416, 576), (416, 600), (768, 600), (768, 920)],
    }
    failures = []
    samples = 0
    for key, route in routes.items():
        for a, b in zip(route, route[1:]):
            count = max(1, math.ceil(math.dist(a, b)))
            for i in range(count+1):
                x, y = (s+(t-s)*i/count for s, t in zip(a, b))
                body = [(x-17,y-12),(x+17,y-12),(x+17,y+12),(x-17,y+12)]
                if any(intersects(body, p) for p in solids) or any(x1 <= x <= x2 and y1 <= y <= y2 for x1,y1,x2,y2 in boxes):
                    failures.append((key, x, y))
                samples += 1
    return {"sampled": samples, "failures": failures, "offline_geometry_only": True}


if __name__ == "__main__":
    data = load_room()
    if sys.argv[1:] == ["--x416"]:
        result = verify_x416(data)
        print(json.dumps(result))
        raise SystemExit(bool(result["failures"]))
    print(json.dumps({
        "floor": data["floor_rects"],
        "solids": data["solids"],
        "npcs": [
            [r["data"]["npc_id"], r["foot"], r.get("half_body"), r.get("body_offset_px"), r["data"].get("movement_mode"), r["data"].get("patrol_axis"), r["data"].get("patrol_distance")]
            for r in data["npcs"]
        ],
    }, ensure_ascii=False, indent=2))
