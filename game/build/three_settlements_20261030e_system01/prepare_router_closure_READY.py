"""Bulk mechanical candidate succession only; never writes a canonical target."""
from pathlib import Path
import copy,difflib,hashlib,json

BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
OUT=BASE/'router_closure01_READY'
SNAP='res://build/luoyang_three_settlements_20261030e_snapshot01/scene_router.gd'
R='res://scripts/autoload/scene_router.gd'
E='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EI='res://scripts/city/luoyang_execution_index_20261022ap.gd'
G='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
GI='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
Q='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
QI='res://scripts/city/luoyang_quarters_index_20261022ap.gd'
D='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
DI='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
PATHS=[R,E,EI,G,GI,Q,QI,D,DI]
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p[6:]).read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def once(b,o,n):
    o=o.encode() if isinstance(o,str) else o;n=n.encode() if isinstance(n,str) else n
    assert b.count(o)==1,(o[:100],b.count(o))
    return b.replace(o,n,1)
def edit(b,changes):
    a=b
    for o,n in changes:a=once(a,o,n)
    inverse=a
    for o,n in reversed(changes):inverse=once(inverse,n,o)
    assert inverse==b
    return a
def hunks(a,b):
    aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
    for context in [3,6,12,24,48]:
        out=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
        if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in out):
            assert edit(a,[(r['old'],r['new']) for r in out])==b
            return out
    raise AssertionError('Nonunique inverse hunk')
def keys(v):
    if isinstance(v,dict):return {k:keys(m) for k,m in v.items()}
    if isinstance(v,list):return [keys(m) for m in v]
    return None
def put(name,b):
    with (OUT/name).open('xb') as f:f.write(b)

assert not OUT.exists(),'Immutable candidate output already exists'
before={p:read(p) for p in PATHS};oldsha={p:sha(b) for p,b in before.items()}
assert oldsha[R]=='740b12b7f74a68109f71849e660caab6ab307a8a085ced74bc62f722a3609e6d'
baseline=json.loads(read('res://build/three_settlements_20261030e_qa01/baseline_before_ACTUAL.json'))
for p in PATHS:assert oldsha[p]==baseline['sources']['game/'+p[6:]]['sha256'],p
old_anchor='\tif scene_id==&"openworld_bianzhou_city":\n'
new_anchor='\tif scene_id in [&"openworld_xiangzhou_city", &"openworld_qinghe_town", &"openworld_yanmen_pass"]:\n\t\tvar settlements30e: Variant=load("res://build/three_settlements_20261030e_system01/settlement_registry.gd")\n\t\treturn settlements30e.start(self,scene_id,player_spawn,pending_action,local_spawn_version)\n'+old_anchor
after={R:edit(before[R],[(old_anchor,new_anchor)])}
old_ex=json.loads(before[E]);router_row=copy.deepcopy(old_ex['owned'][R])
assert router_row['current_sha256']==oldsha[R] and len(router_row['edges'])==24
old_snapshot=router_row['edges'][-1]['new_snapshot']
assert read(old_snapshot)==before[R]
router_row['current_sha256']=sha(after[R])
router_row['edges'].append({'path':R,'old_sha256':oldsha[R],'new_sha256':sha(after[R]),'old_snapshot':old_snapshot,'new_snapshot':SNAP,'whole_inverse':True,'replacements':hunks(before[R],after[R])})
text=before[E].decode();marker='    '+json.dumps(R)+': ';start=text.index(marker)+len(marker)
_,used=json.JSONDecoder().raw_decode(text[start:])
replacement=json.dumps(router_row,ensure_ascii=False,indent=2).replace('\n','\n    ')
text=text[:start]+replacement+text[start+used:]
source_start=text.index('  "source_sha256": {');source_end=text.index('\n  }',source_start)
assert SNAP not in old_ex['source_sha256']
text=text[:source_end]+',\n    '+json.dumps(SNAP)+': '+json.dumps(sha(after[R]))+text[source_end:]
after[E]=text.encode();new_ex=json.loads(after[E])
assert new_ex['owned'][R]['edges'][:-1]==old_ex['owned'][R]['edges']
assert new_ex['source_sha256']==dict(old_ex['source_sha256'],**{SNAP:sha(after[R])})
for p,row in old_ex['owned'].items():
    if p!=R:assert new_ex['owned'][p]==row
after[EI]=edit(before[EI],[(oldsha[E],sha(after[E]))])

def source_update(raw,known):
    original=json.loads(raw);changes={}
    def walk(value):
        if isinstance(value,dict):
            for key,member in value.items():
                if key in ['source_sha256','legacy_source_sha256'] and isinstance(member,dict):
                    for p,h in member.items():
                        if p in known and h==oldsha.get(p) and h!=known[p]:
                            changes[json.dumps(p)+': '+json.dumps(h)]=json.dumps(p)+': '+json.dumps(known[p])
                else:walk(member)
        elif isinstance(value,list):
            for member in value:walk(member)
    walk(original);result=raw
    for old,new in changes.items():
        assert old.encode() in result
        result=result.replace(old.encode(),new.encode())
    assert keys(original)==keys(json.loads(result))
    return result

known={p:sha(b) for p,b in after.items()}
pending=[p for p in PATHS if p not in after]
def deps(p):return {q for q,h in oldsha.items() if q!=p and h.encode() in before[p]}
for _ in PATHS:
    progress=False
    for p in list(pending):
        if any(q in pending for q in deps(p)):continue
        if p.endswith('.json'):data=source_update(before[p],known)
        else:
            changes=[(oldsha[q],known[q]) for q in known if known[q]!=oldsha[q] and oldsha[q].encode() in before[p]]
            data=edit(before[p],changes) if changes else before[p]
        assert data!=before[p],p
        after[p]=data;known[p]=sha(data);pending.remove(p);progress=True
    if not pending:break
    assert progress,pending
assert not pending and len(after)==9
for p in [G,Q,D]:assert keys(json.loads(before[p]))==keys(json.loads(after[p]))

# Freeze new code and narrowly relevant immutable inputs separately. No such keys
# are admitted into old city metadata, source_delta, compiled data or contracts.
module_paths=[
    'res://build/three_settlements_20261030e_system01/common_author.gd',
    'res://build/three_settlements_20261030e_system01/settlement_registry.gd',
    'res://build/three_settlements_20261030e_system01/settlement_field.gd',
    'res://build/three_settlements_20261030e_system01/settlement_field.tscn',
    'res://build/three_settlements_20261030e_system01/minimap_layout_snapshot.gd',
    'res://build/three_settlements_20261030e_system01/city_minimap.gd',
    'res://build/three_settlements_20261030e_system01/xiangzhou_author.gd',
    'res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd',
    'res://build/three_settlements_20261030e_yanmen01/yanmen_author.gd']
input_paths=[
    'res://data/scenes/openworld_xiangzhou_city.tres','res://data/scenes/openworld_qinghe_town.tres','res://data/scenes/openworld_yanmen_pass.tres',
    'res://data/maps/openworld_xiangzhou_city_layout_v2.tres','res://data/maps/openworld_qinghe_town_layout.tres','res://data/maps/openworld_yanmen_pass_layout.tres',
    'res://build/jinling_city_20261029_system01/city_author.gd','res://build/jinling_city_20261029_system01/river_binding_BUILD.json',
    'res://build/bianzhou_city_20261028_lore01/ambient_dialogues.json',
    'res://build/luoyang_city_visual_minimap_20261030c_system01/visual_cache.gd',
    'res://scripts/field/field_walkable_controller.gd']
contract={'schema':'THREE_SETTLEMENTS_20261030E_EXACT_NEW_CONTENT_V1','status':'CANDIDATES_FROZEN_NOT_RUNTIME_APPROVAL','scope':'Separate source receipt; never broadens old city metadata or ART authority','modules':{},'immutable_inputs':{},'canonical_scene_writes':0,'shared_Field_CT_World_writes':0}
for group,paths in [('modules',module_paths),('immutable_inputs',input_paths)]:
    for p in paths:
        data=read(p);contract[group][p]={'sha256':sha(data),'bytes':len(data)}
assert contract['modules'][module_paths[6]]['sha256']=='212ba133fa4eceb3fb493a15adef4c8d1983a0c634d953052748b95982c6278c'
assert contract['modules'][module_paths[8]]['sha256']=='b8ab26548498e93c51cd64c537076d8c268a300485970cc87f66fdaf34c122f0'

OUT.mkdir()
snapshot_file=GAME/SNAP[6:]
if snapshot_file.exists():assert snapshot_file.read_bytes()==after[R]
else:
    snapshot_file.parent.mkdir(parents=True,exist_ok=True)
    with snapshot_file.open('xb') as f:f.write(after[R])
rows=[];patches=[]
for p,data in after.items():
    name=p[6:].replace('/','__');put(name,data)
    rows.append({'target':'game/'+p[6:],'candidate':'game/'+OUT.relative_to(GAME).as_posix()+'/'+name,'old_sha256':oldsha[p],'new_sha256':sha(data),'bytes':len(data),'whole_byte_inverse':True})
    patches.append({'target':'game/'+p[6:],'replacements':hunks(before[p],data)})
receipt={'status':'NINE_ROUTER_SOURCE_CANDIDATES_NOT_DEPLOYED','targets':rows,'new_snapshot':SNAP,'new_snapshot_sha256':sha(after[R]),'Router_edges_before':24,'Router_edges_after':25,'old_EX_owned_other_rows_exact':True,'old_EX_source_keys_values_exact':True,'only_new_EX_key':SNAP,'gate_docks_quarters_all_old_keysets_unchanged':True,'new_content_in_separate_source_contract_only':True,'canonical_writes':0,'engine_runs':0,'first_geometry_FAILURES_kept':4,'only_residual_NPC_moves':['xiangzhou_life_01','xiangzhou_life_02','xiangzhou_life_09','xiangzhou_life_14']}
auth={'sources':{r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes']} for r in rows},'new_modules':{'game/'+SNAP[6:]:{'sha256':sha(after[R]),'bytes':len(after[R])}},'new_content_sources':contract['modules']}
for name,value in [('receipt_READY.json',receipt),('hunks_READY.json',{'targets':patches}),('auth_READY.json',auth),('source_contract_READY.json',contract)]:put(name,enc(value))
print(json.dumps({'targets':len(rows),'router_sha256':sha(after[R]),'receipt_sha256':sha(enc(receipt)),'hunks_sha256':sha(enc({'targets':patches})),'auth_sha256':sha(enc(auth)),'source_contract_sha256':sha(enc(contract)),'new_snapshot':SNAP,'canonical_writes':0,'engine_runs':0}))
