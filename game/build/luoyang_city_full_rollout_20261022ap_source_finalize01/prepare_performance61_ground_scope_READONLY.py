"""Fixed464BA/E717 source-reference closure only; no Stage/collector/native load."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
Y='res://build/luoyang_city_full_rollout_20261022ap_system01/'
def p(v):return G/v[6:]
def fixed(v,s):
    b=p(v).read_bytes();assert hashlib.sha256(b).hexdigest()==s.lower(),('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
stagep=S+'outputs/root_market_complete_parent30_stage01/receipt.json';stages='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f'
ownerp=S+'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json';owners='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'
proofp=Y+'market_ground_finite_count_candidate_epoch01/authorproof_and_wholebyte_inverse_READY_NOT_RUNTIME.json';proofs='2cb284c359ece3eff07efe379d02a1ea7f88fa6f1e717896b821b184eb20d00d'
stage=read(stagep,stages);owner=read(ownerp,owners);proof=read(proofp,proofs)
ground=proof['parent']['path'];groundsha=proof['parent']['sha256'].lower()
old=fixed(ground,groundsha);candidate=fixed(proof['candidate']['path'],proof['candidate']['sha256'])
assert groundsha==owner['scenes'][3]['source_sha256'][ground]
assert b'\r'not in old and old.endswith(b'\n') and b'\r'not in candidate and candidate.endswith(b'\n')
# Reconstruct the two exact source hunks without evaluating any GDScript method.
forward=old
insert=proof['hunks'][0]['new'].encode();anchor=b'static func prepare('
assert forward.count(anchor)==1;forward=forward.replace(anchor,insert+anchor,1)
h=proof['hunks'][1];assert forward.count(h['old'].encode())==1
forward=forward.replace(h['old'].encode(),h['new'].encode(),1);assert forward==candidate
reverse=candidate.replace(h['new'].encode(),h['old'].encode(),1).replace(insert,b'',1);assert reverse==old
rows={r['target']:r for r in stage['targets']}
rows[ground]={'target':ground,'candidate_path':ground,'candidate_sha256':groundsha}
edges={path:[]for path in rows};references=[]
for path,row in rows.items():
    if path==ground:continue
    raw=fixed(row['candidate_path'],row['candidate_sha256'])
    if path.endswith('.json'):
        def walk(v,ks=()):
            if isinstance(v,dict):
                for key,value in v.items():
                    if key in rows and value==rows[key]['candidate_sha256']:
                        edges[key].append(path);references.append({'producer':key,'consumer':path,'pointer':list(ks)+( [key] )})
                    walk(value,ks+(key,))
            elif isinstance(v,list):
                for i,value in enumerate(v):walk(value,ks+(i,))
        walk(json.loads(raw))
    else:
        for producer,r in rows.items():
            if r['candidate_sha256'].encode()in raw:
                edges[producer].append(path);references.append({'producer':producer,'consumer':path,'SHA_literal':r['candidate_sha256']})
seen={ground};todo=[ground]
while todo:
    for consumer in edges[todo.pop(0)]:
        if consumer not in seen:seen.add(consumer);todo.append(consumer)
assert len(seen)==8 and sum(x.endswith('.gd')for x in seen)==4
execrow=next(r for r in stage['targets']if r['target'].endswith('/execution_successor.json'))
authority=read(execrow['candidate_path'],execrow['candidate_sha256'])
assert ground not in authority['owned'] and ground not in authority['source_sha256']
scope=[]
for path,r in rows.items():
    if path not in seen:continue
    scope.append({'target':path,'old_sha256':r['candidate_sha256'],'fixed_old_snapshot':r['candidate_path'],'kind':'GD'if path.endswith('.gd')else'generated_JSON','new_candidate':proof['candidate']if path==ground else'PENDING_EXACT_SOURCE_VALUE_OR_INDEX_LITERAL_SUCCESSOR'})
membership=[]
for row in owner['scenes']+owner['rooms']:
    membership.append({'id':row['id'],'collector_count':len(row['source_sha256']),'receipt_count':len(row['receipt_source_sha256']),'collector_changed_value_paths':[x for x in row['source_sha256']if x in seen],'receipt_changed_value_paths':[x for x in row['receipt_source_sha256']if x in seen],'keys_and_counts_unchanged':True})
result={'status':'EXACT8_GROUND_FINITE35_SOURCE_PREPARATION_SCOPE_ONLY_NOT_STAGE_AUTHORITY','fixed_parent_stage':{'path':stagep,'sha256':stages},'fixed_prior_owner':{'path':ownerp,'sha256':owners},'source_candidate_inverse_proof':{'path':proofp,'sha256':proofs},'target_count':8,'GD_count':4,'JSON_count':4,'targets':scope,'reference_edges':[r for r in references if r['producer']in seen],'owner_value_inheritance':membership,'execution_treatment':{'owned_members_unchanged':True,'ground_is_nonowned':True,'execution_successor_and95pins_unchanged':True,'no_execution_edge_or_new_proof_key':True},'preserved_domains':['Ground own manifest and GroundIndex (own manifest excludes SELF/index/manifest; index only pins own manifest)','B/DT/C/Fade/adapter/G/Field/Router/Coordinator/Temple/runtime_contract','Estate registry scalar/source triple and five room receipt fields','Root39 SOURCE_ONLY exact2 Market leaves','All native/scene/layout/walk/import/texture/RGBA/NPC/NAV/quests/FIRST_FINAL/whole_inverse gates'],'required_future_recipe':['Ground candidate exact pass-through is nonowned with only fixed old02A4/newC1EF and complete two-hunk byte inverse; no OWNED extension.','Four metadata source-only exact existing ground leaf old02A4->newC1EF; retain all other keys and historical ancestors.','TMarket->BI, AOMarket->AOIndex, APMarket->finiteMarket/APCityIndex and finiteMarket->APCityIndex SHA literals/declared source header only.','Four complete C maps derive fixed E717 plus exact changed existing values; Market own SELF plus AP/finite headers and all four shared3index values; no new keys.','All other4scene and5room collector/receipt maps remain whole typed identical; owner tables keep original independent domains.','Root must freeze new fresh guard and all8 old byte backups then authorize final driver/input before one Stage.'],'whole_ground_byte_forward_and_inverse':True,'ground_old_EOL':{'bytes':len(old),'CR':old.count(b'\r'),'LF':old.count(b'\n'),'final_LF':True,'ordinary_strict_patch_no_transport_exception':True},'calls':{'Stage':0,'engine':0,'collector':0,'packetdecode':0,'mediahash':0,'formalwrite':0}}
out=H/'performance61_ground_finite35_exact8_scope_READONLY.json';assert not out.exists()
b=(json.dumps(result,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();out.write_bytes(b)
print(json.dumps({'path':S+out.name,'sha256':hashlib.sha256(b).hexdigest(),'target_count':len(scope),'targets':scope},indent=2))
