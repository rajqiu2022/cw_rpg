"""Exact Router successor: preserve old authority edges and all unrelated source entries."""
import re,copy,difflib
from linxi_entry_repair_20261029q import *
GAME=ROOT/'game';OUT=GAME/'build/luoyang_linxi_entry_repair_20261029q/closure';PREFIX='res://build/luoyang_linxi_entry_repair_20261029q/closure/'
def read(p):return (GAME/p[6:]).read_bytes()
def digest(b):return hashlib.sha256(b).hexdigest()
def once(b,o,n):
    o=o.encode() if isinstance(o,str) else o;n=n.encode() if isinstance(n,str) else n
    assert b.count(o)==1,(o[:80],b.count(o));return b.replace(o,n,1)
def literals(raw,replacements):
    b=raw
    for o,n in replacements:b=once(b,o,n)
    inverse=b
    for o,n in reversed(replacements):inverse=once(inverse,n,o)
    assert inverse==raw;return b
def addpin(b,name,path,h):
    start=b.index(('  "'+name+'": {').encode());end=b.index(b'\n  }',start)
    assert path not in json.loads(b)[name]
    return b[:end]+(',\n    "'+path+'": "'+h+'"').encode()+b[end:]
rp='res://scripts/autoload/scene_router.gd';ep='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
gp='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json';bi='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
qp='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json';qi='res://scripts/city/luoyang_quarters_index_20261022ap.gd'
dp='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json';di='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
paths=[rp,ep,ei,gp,bi,qp,qi,dp,di];before={p:read(p) for p in paths};after={}
helper='res://scripts/field/linxi_entry_contract_20261029q.gd'
edits=[('\t\tvar world_contract: Variant = layered_world_contract(_load_field_scene_def(scene_id)) if is_world_map_scene(scene_id) else null', '\t\tif scene_id == &"linxi_farmer_cottage":\n\t\t\tspawn = load("'+helper+'").repair_saved_origin(spawn)\n\t\tvar world_contract: Variant = layered_world_contract(_load_field_scene_def(scene_id)) if is_world_map_scene(scene_id) else null'),
       ('\t# World gateways move when the illustrated road survey changes.', '\tif source_scene_id == &"linxi_farmer_cottage" or target_scene_id == &"linxi_farmer_cottage":\n\t\tarrival = load("'+helper+'").portal_arrival(source_scene_id, target_scene_id, arrival)\n\t# World gateways move when the illustrated road survey changes.')]
after[rp]=literals(before[rp],edits)
oldex=json.loads(before[ep]);oldrow=oldex['owned'][rp];assert oldrow['current_sha256']==digest(before[rp])
old_snapshot=oldrow['edges'][-1]['new_snapshot'];assert read(old_snapshot)==before[rp]
snapshot=PREFIX+'Router_READY.gd'
newrow=copy.deepcopy(oldrow);newrow['current_sha256']=digest(after[rp]);newrow['edges'].append({'path':rp,'old_sha256':digest(before[rp]),'new_sha256':digest(after[rp]),'old_snapshot':old_snapshot,'new_snapshot':snapshot,'whole_inverse':True,'replacements':[{'old':o,'new':n} for o,n in edits]})
text=before[ep].decode();start=text.index('    "'+rp+'": {')+len('    "'+rp+'": ');_,used=json.JSONDecoder().raw_decode(text[start:]);oldpart=text[start:start+used].encode();newpart=json.dumps(newrow,ensure_ascii=False,indent=2).replace('\n','\n    ').encode()
after[ep]=once(before[ep],oldpart,newpart)
pins=[(snapshot,digest(after[rp])),(helper,digest(read(helper)))]
for p,h in pins:after[ep]=addpin(after[ep],'source_sha256',p,h)
assert all(json.loads(after[ep])['source_sha256'][p]==h for p,h in oldex['source_sha256'].items())
after[ei]=literals(before[ei],[(digest(before[ep]),digest(after[ep]))])
for p in [gp,dp]:
    after[p]=literals(before[p],[(f'"{rp}": "{digest(before[rp])}"',f'"{rp}": "{digest(after[rp])}"'),(f'"{ep}": "{digest(before[ep])}"',f'"{ep}": "{digest(after[ep])}"')])
    for key,h in pins:after[p]=addpin(after[p],'legacy_source_sha256',key,h)
after[qp]=literals(before[qp],[(f'"{ep}": "{digest(before[ep])}"',f'"{ep}": "{digest(after[ep])}"'),(f'"{ei}": "{digest(before[ei])}"',f'"{ei}": "{digest(after[ei])}"')])
for p,h in pins:after[qp]=addpin(after[qp],'source_sha256',p,h)
for p,source in [(bi,gp),(qi,qp),(di,dp)]:after[p]=literals(before[p],[(digest(before[source]),digest(after[source]))])
names=['Router_READY.gd','execution_successor_READY.json','execution_index_READY.gd','gate_manifest_READY.json','bundle_index_READY.gd','quarters_manifest_READY.json','quarters_index_READY.gd','docks_manifest_READY.json','docks_index_READY.gd']
OUT.mkdir(parents=True,exist_ok=False);rows=[]
for p,name in zip(paths,names):
    (OUT/name).write_bytes(after[p]);backup=STAGE/'backup'/('game/'+p[6:]);backup.parent.mkdir(parents=True,exist_ok=True)
    if backup.exists():assert backup.read_bytes()==before[p]
    else:backup.write_bytes(before[p])
    rows.append({'path':p,'candidate':PREFIX+name,'before':digest(before[p]),'after':digest(after[p])})
save(STAGE/'closure.json',{'targets':rows,'router_edges_before':len(oldrow['edges']),'router_edges_after':len(newrow['edges']),'old_source_keys_preserved':True})
for p in paths:assert read(p)==before[p]
for p in paths:(GAME/p[6:]).write_bytes(after[p])
print('Published exact nine Router/source successor targets')
