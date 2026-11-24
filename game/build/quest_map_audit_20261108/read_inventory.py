import json,re,collections
from pathlib import Path
data=json.loads(Path("game/build/quest_map_audit_20261108/runtime_inventory.json").read_text(encoding="utf8"))
scenes,dialogs,quests,plans=(data[k] for k in ("scenes","dialogs","quests","plans"))
active=set(sum([p["main"]+p["side"] for p in plans.values()],[])) | {q for q,v in quests.items() if v["independent"]} | {q for q in quests if re.search(r"q_ch4_side_(08|09|10)_",q)}
roots=collections.defaultdict(set)
for s,v in scenes.items():
 if v.get("missing"): print("missing scene",s);continue
 if v["intro"]:roots[v["intro"]].add(s)
 if s in ["ch2_s4_lingyue_gate","ch7_s1_lieyun_valley_ferry","ch7_s2_mingwu_tea_town"]:v["interactions"]+=v["hotspots"]
 for r in v["npcs"]+v["interactions"]+v["objects"]+v["portals"]:
  for item in [r]+r.get("dialog_variants",[]):
   if item.get("dialog_id"):roots[item["dialog_id"]].add(s)
   for key in ["action","interaction_action"]:
    if item.get(key,"").startswith("dialog:"): roots[item[key].split(":")[1]].add(s)
source="\n".join(p.read_text(encoding="utf-8-sig") for p in Path("game/scripts").rglob("*.gd"))
edges=collections.defaultdict(set)
accept,finish,flags=(collections.defaultdict(set) for _ in range(3))
for id,v in dialogs.items():
 for n in v["nodes"]:
  if n["accept"]:accept[n["accept"]].add(id)
  if n["complete"]:finish[n["complete"]].add(id)
  for f in n["flags"]:
   if f.get("value",True):flags[f.get("key")].add(id)
  for cmd in [n["action"]]+[x.get("action","") for x in n["choices"]]:
   a=cmd.split(":")
   if a[0]=="dialog" and len(a)>1: edges[id].add(a[1])
   if a[0] in ["battle_then","battle_group_then","battle_adaptive_then"] and len(a)>2: edges[id].add(a[-1])
reachable=set(roots)|{id for id in dialogs if '"'+id+'"' in source}
while True:
 new=reachable|set().union(*(edges[id] for id in reachable))
 if new==reachable:break
 reachable=new
for q in sorted(active):
 v=quests[q]
 if accept[q] and not accept[q]&reachable and not v["auto"]:print("ACCEPT",q,",".join(accept[q]))
 lost=[]
 for t in v["complete"]:
  if t.startswith("flag_set:"):
   key=t.split(":")[1]
   if flags[key] and not flags[key]&reachable and not re.search('["]'+re.escape(key)+'["]',source):lost.append((key,sorted(flags[key])))
 if (finish[q] and not finish[q]&reachable) or lost:print("COMPLETE",q,sorted(finish[q]-reachable),lost)
for id in sorted(set(roots)-set(dialogs)): print("MISSINGDIALOG",id,roots[id])
print("counts",len(active),len(reachable),len(roots))
for s in ["ch1_s2_qingfeng","ch2_s1_zhuwei_market","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market","ch4_s4_ancient_temple"]:
 print("selected",s,scenes[s]["resolved"],scenes[s]["path"],[d for d in roots if s in roots[d] and ("aftermath" in d or "huilan" in d or "ch4_" in d)])
for q in sorted(active):
 v=quests[q]
 for t in v["complete"]:
  if t.startswith("flag_set:"):
   key=t.split(":")[1]
   if flags[key] and not flags[key]&reachable:print("FLAG PRODUCER",q,key,sorted(flags[key]))
for s,v in scenes.items():
 if v.get("missing") or not v["walkable"]:continue
 if not (s.startswith(("ch","linxi"))):continue
 def target(r):return r.get("target_scene") or r.get("action","").removeprefix("scene:")
 missing={target(r) for r in v["shadow_exits"]}-{target(r) for r in v["portals"]}
 if missing:print("LOST EXIT",s,missing)
