"""Fixed669/1DFF direct-consumer graph only, no candidate/DAG/Stage/source crawl."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1];S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def fixed(v,s):
    b=(G/v[6:]).read_bytes();assert hashlib.sha256(b).hexdigest()==s,('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
stagep=S+'outputs/root_market_ground_exact8_stage01/receipt.json';stages='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe';stage=read(stagep,stages)
oldstagep=S+'outputs/root_market_complete_parent30_stage01/receipt.json';oldstages='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f';oldstage=read(oldstagep,oldstages)
ownerp=S+'performance64_ground8_actual_independent_review/owner_source_maps_READY.json';owners='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0';owner=read(ownerp,owners)
planp=S+'performance58_market_parent30_source_recipe/source_input_ROOT_LOCKED.json';plans='a29f32c01dcac22c4a1289e5bd5084c4cb76195d7666ee021165d6aba98dd140';plan=read(planp,plans)
env='res://scripts/city/luoyang_environment_layer_20261022ap.gd';envsha=owner['core_source_sha256'][env]
assert envsha=='cf945cab9ab689c87364fa477f22f0f326a70f2bb64f2d7e38d699ccdb42c26a'
authorityp=S+'performance57_market_receipt_dependencies/execution_successor_PROPOSAL.json';authoritys='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3';authority=read(authorityp,authoritys)
assert len(authority['owned'])==10 and len(authority['source_sha256'])==95 and env not in authority['owned']and env not in authority['source_sha256']
# Node identities come from the already reviewed58 recipe; values are the actual62
# nodes (frozen nodes explicitly point to their immutable464BA snapshots).
rows={n['target']:{'target':n['target'],'node':n['id'],**stage['nodes'][n['id']]}for n in plan['nodes']if n.get('target')}
rows[env]={'target':env,'node':'ENV_NONOWNED','path':env,'sha256':envsha,'value':None}
edges={path:[]for path in rows};refs=[]
for path,row in rows.items():
    if path==env:continue
    if path.endswith('.json'):
        value=row['value'];assert isinstance(value,dict)
        def walk(v,ks=()):
            if isinstance(v,dict):
                for k,x in v.items():
                    if k in rows and x==rows[k]['sha256']:
                        edges[k].append(path);refs.append({'producer':k,'consumer':path,'pointer':list(ks)+( [k] )})
                    walk(x,ks+(k,))
            elif isinstance(v,list):
                for i,x in enumerate(v):walk(x,ks+(i,))
        walk(value)
    else:
        raw=fixed(row['path'],row['sha256'])
        for producer,r in rows.items():
            if r['sha256'].encode()in raw:edges[producer].append(path);refs.append({'producer':producer,'consumer':path,'SHA_literal':r['sha256']})
seen={env};todo=[env]
while todo:
    for consumer in edges[todo.pop(0)]:
        if consumer not in seen:seen.add(consumer);todo.append(consumer)
targets=[{'target':path,'node':r['node'],'old_sha256':r['sha256'],'fixed_old_snapshot':r['path'],'new_sha256':'PENDING_SYSTEM_CANDIDATE_OR_EXACT_HEADER_SUCCESSOR'}for path,r in rows.items()if path in seen]
affected=[]
for family in ['scenes','rooms']:
    for r in owner[family]:
        affected.append({'family':family,'id':r['id'],'collector_count_before':len(r['source_sha256']),'receipt_count_before':len(r['receipt_source_sha256']),'collector_existing_value_successions':[p for p in r['source_sha256']if p in seen],'receipt_existing_value_successions':[p for p in r['receipt_source_sha256']if p in seen],'new_shader_key_only_if_id_Market':r['id']=='ch4_s3_luoyang_market'})
result={'status':'ENV_A1_NONOWNED_EXISTING_CONSUMER_CLOSURE_READONLY_PROSPECT_NOT_CANDIDATE_OR_STAGE_AUTHORITY','parents':{'actual62':{'path':stagep,'sha256':stages},'prior464BA':{'path':oldstagep,'sha256':oldstages},'independent_owner669':{'path':ownerp,'sha256':owners}},'seed':{'path':env,'old_sha256':envsha,'new_sha256':'PENDING_SYSTEM_NOT_FABRICATED'},'target_count':len(targets),'GD_count':sum(r['target'].endswith('.gd')for r in targets),'JSON_count':sum(r['target'].endswith('.json')for r in targets),'existing_targets':targets,'direct_and_transitive_reference_edges':[r for r in refs if r['producer']in seen],'owner_consumption':affected,'execution':{'path':authorityp,'sha256':authoritys,'owned10_whole_unchanged':True,'old95_proof_pins_whole_unchanged':True,'ENV_not_owned_or_canonical_proof_pin':True,'no_new_owned_member_edge_or_execution_successor':True},'new_shader':{'path':'PENDING_SYSTEM_FIXED_MARKET_ONLY_BUILD_PATH','sha256':'PENDING_SYSTEM_CANDIDATE','existing_production_target':False,'classification':'NEW_RUNTIME_SHADER_SOURCE_LEAF_NOT_EXECUTION_PROOF','source_declaration':'OnlyENV.source_paths_for(Market)/Market install source_pins; APMarket+finiteMarket legacy source class and independentMarket fullmap need +1; do not add shader to sharedQuarter/environment author/other7scene/G room domains. Final exact route must be verified against fixedSystem candidate.'},'scope_conditions':['OnlyENV implementation and one newMarket shader, no ENVauthor/index or other implementation changes.','ENV has no hard current-SHA consumer in B/C/DT/Field/Temple code; those load the existing path and source APIs dynamically.','Temple binding source_delta does not declare ENV; Temple completecollector inherits newENV value dynamically, not a new Temple binding or executable target.','Preserve all current native/history/scenes/layouts/groundC1EF/Root39SOURCE_ONLY2/registry/Estate scalar triple/roomreceipts and wholetyped/byte inverses.','Existing target oldSHAs come from fixed1DFF currentnodes (immutable464BA snapshots where unchanged), not currentcanonical hash crawl.','Newshader semantics/candidate/inverse/ART readiness are not supplied or approved by this prospect. Root must lock exact candidate plus scope/oldbackups and authorize later preparation/Stage separately.'],'operations':{'Stage':0,'engine':0,'collector':0,'candidate_or_DAG_generated':0,'media_hash_crawl':0,'formal_edits':0}}
out=H/'performance66_ENV_A1_existing_scope_READONLY_PROSPECT.json';assert not out.exists();b=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode();out.write_bytes(b)
print(json.dumps({'path':S+out.name,'sha256':hashlib.sha256(b).hexdigest(),'target_count':len(targets),'GD':result['GD_count'],'JSON':result['JSON_count'],'targets':targets},indent=2))
