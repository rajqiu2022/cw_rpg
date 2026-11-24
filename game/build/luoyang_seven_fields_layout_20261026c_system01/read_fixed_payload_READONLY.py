"""Read-only fixed DFCF payload summary for ART. No engine/PNG decode/collector."""
import argparse, hashlib, json, struct
from pathlib import Path
GAME=Path(__file__).resolve().parents[2]
BIND="build/luoyang_city_finish_20261025i_source01/market_living_street_repair01/closure_READY01/finish8_binding_READY.json"
BIND_SHA="150142ed9bb2c52af9c39bd128090b4f2b86e5cacc657a0fc8f3e5ecbe64a942"
class Reader:
    def __init__(self,data): self.data=data;self.pos=0
    def fmt(self,kind):
        result=struct.unpack_from("<"+kind,self.data,self.pos);self.pos+=struct.calcsize("<"+kind)
        return result[0] if len(result)==1 else list(result)
    def string(self):
        count=self.fmt("I");value=self.data[self.pos:self.pos+count].decode("utf-8");self.pos+=(count+3)&~3;return value
    def read(self):
        tag=self.fmt("I");kind=tag&65535;wide=bool(tag&65536)
        if kind==0:return None
        if kind==1:return bool(self.fmt("I"))
        if kind==2:return self.fmt("q" if wide else "i")
        if kind==3:return self.fmt("d" if wide else "f")
        if kind in (4,21):return self.string()
        if kind in (5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20):
            counts={5:2,6:2,7:4,8:4,9:3,10:3,11:6,12:4,13:4,14:4,15:4,16:6,17:9,18:12,19:16,20:4}
            unit="i" if kind in (6,8,10,13) else ("d" if wide and kind!=20 else "f")
            return self.fmt(unit*counts[kind])
        if kind==27:
            count=self.fmt("I")&0x7fffffff;value={}
            for _ in range(count): key=self.read();value[key]=self.read()
            return value
        if kind==28:
            if wide:self.fmt("I")
            return [self.read() for _ in range(self.fmt("I")&0x7fffffff)]
        if kind==29:
            count=self.fmt("I");value=list(self.data[self.pos:self.pos+count]);self.pos+=(count+3)&~3;return value
        if kind in (30,31,32,33):
            count=self.fmt("I");return [self.fmt({30:"i",31:"q",32:"f",33:"d"}[kind]) for _ in range(count)]
        if kind==34:return [self.string() for _ in range(self.fmt("I"))]
        if kind in (35,36,37,38):
            count=self.fmt("I");unit="d" if wide and kind!=37 else "f";n={35:2,36:3,37:4,38:4}[kind]
            return [self.fmt(unit*n) for _ in range(count)]
        raise ValueError((kind,self.pos))
def main():
    parser=argparse.ArgumentParser();parser.add_argument("--scene");args=parser.parse_args()
    raw=(GAME/BIND).read_bytes();assert hashlib.sha256(raw).hexdigest()==BIND_SHA
    binding=json.loads(raw);result={}
    for scene,row in binding["scenes"].items():
        if args.scene and scene!=args.scene:continue
        path=GAME/row["payload"]["path"].removeprefix("res://")
        data=path.read_bytes();assert hashlib.sha256(data).hexdigest()==row["payload"]["sha256"]
        decoder=Reader(data);payload=decoder.read();assert decoder.pos==len(data)
        fields=["id","texture","pos","render_size_px","world_foot_px","depth_sort_foot_y","centered","city_v3_solid_polygons_px"]
        result[scene]={"world_size":payload["world_size_px"],"payload_sha256":row["payload"]["sha256"],"visual":[{key:r[key] for key in fields if key in r} for r in payload["effective_navigation"] if r.get("sort_by_feet",False)],"solids":payload["effective_solids"],"native_portals":payload["portal_after"],"npc_migrations":payload["npc_migrations"],"new_NPCs":payload["new_NPCs"],"walkable_polygons":payload["effective_walkable_polygons"]}
    assert result;print(json.dumps(result,ensure_ascii=True))
if __name__=="__main__":main()
