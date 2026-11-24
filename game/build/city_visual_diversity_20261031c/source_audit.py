"""Targeted current city source audit; no Godot, media edits, or save access."""
from pathlib import Path
import hashlib
import json
import re
import struct

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
MANIFEST="game/build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
X="game/build/three_settlements_20261030e_system01/xiangzhou_author.gd"
J="game/build/jinling_city_20261029_system01/city_author.gd"
FACING={"res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png":"left",
        "res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png":"right",
        "res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1_runtime160.png":"right"}

def read(p):return (ROOT/p).read_text(encoding="utf-8-sig")
def fact(p):
    data=(ROOT/p).read_bytes();return {"path":p,"sha256":hashlib.sha256(data).hexdigest(),"bytes":len(data)}

class Decoder:
    def __init__(self,data):self.data=data;self.pos=0
    def unpack(self,fmt):
        count=struct.calcsize(fmt);value=struct.unpack_from("<"+fmt,self.data,self.pos);self.pos+=count;return value[0] if len(value)==1 else list(value)
    def string(self):
        n=self.unpack("I");value=self.data[self.pos:self.pos+n].decode("utf-8");self.pos+=(n+3)//4*4;return value
    def variant(self):
        header=self.unpack("I");typ=header&0xffff;wide=bool(header&0x10000)
        if typ==0:return None
        if typ==1:return bool(self.unpack("I"))
        if typ==2:return self.unpack("q" if wide else "i")
        if typ==3:return self.unpack("d" if wide else "f")
        if typ in [4,21]:return self.string()
        if typ==5:return self.unpack("2d" if wide else "2f")
        if typ==6:return self.unpack("2i")
        if typ==7:return self.unpack("4d" if wide else "4f")
        if typ==8:return self.unpack("4i")
        if typ==20:return self.unpack("4f")
        if typ==27:
            n=self.unpack("I")&0x7fffffff;result={}
            for _ in range(n):
                key=self.variant()
                result[tuple(key) if isinstance(key,list) else key]=self.variant()
            return result
        if typ==28:return [self.variant() for _ in range(self.unpack("I")&0x7fffffff)]
        if typ in [30,31,32,33]:
            fmt={30:"i",31:"q",32:"f",33:"d"}[typ];return [self.unpack(fmt) for _ in range(self.unpack("I"))]
        if typ==34:return [self.string() for _ in range(self.unpack("I"))]
        if typ==35:return [self.unpack("2d" if wide else "2f") for _ in range(self.unpack("I"))]
        raise ValueError(("unsupported variant",typ,self.pos-4))

def authored_rows(path,city):
    raw=read(path);section=raw.split("static func npc_rows()",1)[1].split("static func scene()",1)[0]
    variables=dict(re.findall(r'var (\w+): String="([^"]+)"',section))
    stations=re.findall(r'\["([^"]+)",Vector2\(([^)]+)\),(\w+),"([^"]+)"\]',section)
    patrol=[3,5,15,18] if city=="xiangzhou" else [3,12,27,32]
    rows=[]
    for i,(name,xy,kind,ambient) in enumerate(stations):
        index=i+1 if city=="xiangzhou" else i
        if index not in patrol:continue
        if city=="xiangzhou" and kind not in ["young","merchant"]:continue
        walk="res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png" if kind=="young" else "res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"
        rows.append({"city":city,"npc_id":f"{city}_life_{index:02d}","npc_name":name,
                     "foot":[float(n) for n in xy.split(",")],"sprite_path":variables[kind],"walk_sprite_path":walk,
                     "patrol_axis":[1,0],"patrol_distance":28 if city=="xiangzhou" else 32,"patrol_speed":18,
                     "invert_patrol_facing":False,"ambient_action":ambient,"origin":path})
    return rows

def correctness(row):
    path=row.get("walk_sprite_path","");axis=row.get("patrol_axis",[1,0])
    native=FACING.get(path)
    row["source_facing_visually_confirmed"]=native
    if native is None:return
    if abs(axis[0])<=abs(axis[1]):row["requires_vertical_visual_review"]=True;return
    expected=(native=="left")!=(axis[0]<0)
    row["expected_invert_patrol_facing"]=expected
    row["currently_wrong_horizontal_face"]=bool(row.get("invert_patrol_facing",False))!=expected

manifest=json.loads(read(MANIFEST));facts=[fact(MANIFEST),fact(X),fact(J),fact("game/scripts/field/npc_node.gd")]
patrols=authored_rows(X,"xiangzhou")+authored_rows(J,"jinling")
regions={};water=[]
for id,binding in manifest["compiled_bindings"].items():
    path="game/"+binding["path"][6:]
    before=fact(path);assert before["sha256"]==binding["sha256"]
    reader=Decoder((ROOT/path).read_bytes());region=reader.variant();assert reader.pos==before["bytes"]
    rows=region.get("npcs",[])
    selected=[]
    for actor in rows:
        data=actor.get("data",{})
        if data.get("movement_mode")!="patrol":continue
        row={"city":"luoyang","region_id":id,"foot":actor.get("foot"),"slot_key":actor.get("slot_key"),
             "origin":path,**{k:data.get(k) for k in ["npc_id","npc_name","sprite_path","walk_sprite_path","patrol_axis","patrol_distance","patrol_speed","invert_patrol_facing"] if k in data}}
        selected.append(row);patrols.append(row)
    surfaces=region.get("surfaces",[])
    water.extend({"region_id":id,"surface":r} for r in surfaces if any(s in str(r.get("texture","")).lower() for s in ["water","river","pond"]))
    regions[id]={"path":path,"size":region.get("size"),"npc_count":len(rows),"patrol_count":len(selected),
                 "surface_count":len(surfaces),"root_keys":list(region)}
    assert fact(path)==before;facts.append(before)
for row in patrols:correctness(row)
unique=sorted({r.get("walk_sprite_path","") for r in patrols})
result={"status":"READ_ONLY_CURRENT_CITY_FACTS_NOT_ENGINE","source_facts":facts,"regions":regions,"patrols":patrols,
        "unique_walk_textures":unique,"unreviewed_walk_textures":[p for p in unique if p not in FACING],
        "confirmed_facing_by_actual_image_not_filename":FACING,
        "wrong_confirmed_horizontal_rows":[{"city":r["city"],"id":r.get("npc_id"),"region":r.get("region_id"),"expected_invert":r.get("expected_invert_patrol_facing")} for r in patrols if r.get("currently_wrong_horizontal_face")],
        "luoyang_water_surfaces":water,"binary_variant_consumed_exact":True,"engine_calls":0,"official_writes":0,"save_reads":0}
target=OUT/"source_facts_FINAL.json";assert not target.exists()
target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"output":str(target),"sha256":fact(target.relative_to(ROOT).as_posix())["sha256"],"patrol_rows":len(patrols),"walk_textures":unique,"unreviewed":[p for p in unique if p not in FACING],"confirmed_wrong":result["wrong_confirmed_horizontal_rows"],"water_surfaces":water},ensure_ascii=True))
