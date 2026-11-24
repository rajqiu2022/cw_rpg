"""Read fixed stage metadata to derive header propagation; no Stage or candidate."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def p(v):return G/v[6:]
def fixed(v,s):
    b=p(v).read_bytes();assert hashlib.sha256(b).hexdigest()==s,('PIN',v);return b
stage=json.loads(fixed(S+'outputs/root_culture_C_source_repair_stage01/receipt.json','5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e'))
rows={r['target']:r for r in stage['targets']}
pins={r['candidate_sha256']:r['target']for r in rows.values()}
edges={path:[]for path in rows};references=[]
for path,row in rows.items():
    b=fixed(row['candidate_path'],row['candidate_sha256'])
    if path.endswith('.json'):
        def walk(v,ks=[]):
            if isinstance(v,dict):
                for k,x in v.items():
                    if k in rows and x==rows[k]['candidate_sha256']:
                        edges[k].append(path);references.append({'producer':k,'consumer':path,'pointer':ks+[k]})
                    walk(x,ks+[k])
            elif isinstance(v,list):
                for i,x in enumerate(v):walk(x,ks+[i])
        walk(json.loads(b))
    else:
        for s,producer in pins.items():
            if s.encode()in b:edges[producer].append(path);references.append({'producer':producer,'consumer':path,'literal':s})
root='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'
seen={root};todo=[root]
while todo:
    for consumer in edges[todo.pop(0)]:
        if consumer not in seen:seen.add(consumer);todo.append(consumer)
result={'status':'FIXED_STAGE_METADATA_REFERENCE_PROPAGATION_ONLY_NOT_RUNTIME_OR_AUTHORITY','fixed_parent_stage_sha256':'5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e','seed':root,'target_count':len(seen),'GD_count':sum(x.endswith('.gd')for x in seen),'JSON_count':sum(x.endswith('.json')for x in seen),'proposed_targets':[r for path,r in rows.items()if path in seen],'excluded_from24':[path for path in rows if path not in seen],'references_in_closure':[r for r in references if r['producer']in seen],'method':'Exact path->candidateSHA values in fixed priorStage24 JSONs plus fixedindex SHA literals; not current collector or guessed equality. No unrelated historical leaf value replacements.','no_Stage_engine_collector_formal_write':True}
out=H/'performance45_estate_registry_scope_READONLY.json';assert not out.exists();b=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode();out.write_bytes(b)
print(json.dumps({'path':S+out.name,'sha256':hashlib.sha256(b).hexdigest(),'count':len(seen),'GD':result['GD_count'],'JSON':result['JSON_count'],'targets':list(seen),'excluded':result['excluded_from24']},indent=2))
