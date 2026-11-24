"""Construct explicit finite08 source recipe from frozen9AACE nodes, not live collectors."""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'finite_adapter_production08/'
def sha(b):return hashlib.sha256(b).hexdigest()
def pth(p):return G/p[6:]
def read(p,s):
 b=pth(p).read_bytes();assert sha(b)==s,('PIN',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def ptr(v,ks):
 for k in ks:v=v[k]
 return v
def emit(name,v):
 dest=H/name;assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True)
 b=v if isinstance(v,bytes) else js(v)
 with dest.open('xb') as f:f.write(b)
 return {'path':S+name,'sha256':sha(b)}
oldinput=S+'unified06_input05_ROOT_LOCKED.json'
old=json.loads(read(oldinput,'5fe4b02960a4f23692f5d94c5fcaab7a193fc6be6bdda2bf5efb2ce0c7cb40e5'))
stagepath=S+'outputs/root_unified06_numeric_stage03/receipt.json'
stage=json.loads(read(stagepath,'9aacef0735bced81c6f8b0601165b931a9cfe2f54aef682635490619319965b8'))
hand=json.loads(read(P+'handoff_PRODUCTION_PROPOSAL.json','8fd3b3b04b1ce33837aa60e1ae41e8a91d86939b08cf30b15421c546aa706e6c'))
binding=json.loads(read(hand['binding']['path'],hand['binding']['sha256']))
approval=json.loads(read(hand['execution_proposal']['path'],hand['execution_proposal']['sha256']))
scopepath=S+'finite_adapter_production08_scope/scope_request_READY.json'
scope=json.loads(read(scopepath,'15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672'))
spec=copy.deepcopy(old);pins={r['id']:r for r in spec['pinned_inputs']}
def pin(id,path,sh):pins[id]={'id':id,'path':path,'sha256':sh};return {'$pin':id}
pin('execution_approval',hand['execution_proposal']['path'],hand['execution_proposal']['sha256'])
pin('runtime_contract_candidate',hand['contract']['path'],hand['contract']['sha256'])
pin('temple_real_binding',hand['temple_binding']['path'],hand['temple_binding']['sha256'])
env=next(r for r in hand['consumers'] if r['domain']=='ENV')
pin('environment_helper',env['candidate']['path'],env['candidate']['sha256'])
pin('finite08_handoff',P+'handoff_PRODUCTION_PROPOSAL.json','8fd3b3b04b1ce33837aa60e1ae41e8a91d86939b08cf30b15421c546aa706e6c')
pin('finite08_binding',hand['binding']['path'],hand['binding']['sha256'])
pin('finite08_scope_request',scopepath,'15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672')
pin('root_finite08_execution','res://build/luoyang_city_full_rollout_20261022ap_root01/execution_finite08_successor_authorization_READY.json','14c550115dd24b5b2ed5ce71211db9bc882a72f736b05e27ab153d78196a0ac6')
pin('root_finite08_scope','res://build/luoyang_city_full_rollout_20261022ap_root01/finite08_exact28_scope_authorization_READY.json','0442c193acde18e358fa11fe3b820083023c0245f6001a7f3c616b57227f163a')
pin('root_finite08_ground',hand['ground_authority']['path'],hand['ground_authority']['sha256'])
pin('root_finite08_code',hand['code_scope_authority']['path'],hand['code_scope_authority']['sha256'])
for gate in spec['required_gates']:
 if gate['id']=='root_target_preauthorization':gate['input']='root_finite08_scope'
spec['status']='PENDING_ROOT_READ_AND_LOCK_FINITE08_SOURCE_INPUT'
spec['output_root']=S+'outputs/root_finite08_two_domain_stage01/'
spec['blockers']=['Root read and SHA-lock final tool/input before unique stage']
spec['root_target_allowlist']=[r['target'] for r in scope['targets']]
spec['pass_through_targets']=[]
spec['prospective_targets']=[]
for row in hand['consumers']:
 d=row['candidate'];spec['prospective_targets'].append({'target':row['target'],'candidate_path':d['path'],'sha256':d['sha256']})
 spec['pass_through_targets'].append({'target':row['target'],'old_sha256':row['old_sha256'],'candidate_path':d['path'],'candidate_sha256':d['sha256'],'exact_replacements':row['inverse_replacements']})
spec['pass_through_targets'].append({'target':hand['execution_parent']['path'],'old_sha256':hand['execution_parent']['sha256'],'candidate_path':hand['execution_proposal']['path'],'candidate_sha256':hand['execution_proposal']['sha256']})
code_refs={r['target']:r['candidate']['sha256'] for r in hand['consumers']}
code_refs[hand['execution_parent']['path']]={'$pin':'execution_approval'}
contracttarget='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
code_refs[contracttarget]={'$pin':'runtime_contract_candidate'}
node_refs={r['target']:{'$sha':r['id']} for r in spec['nodes'] if r.get('target') and r['id']!='runtime_contract_final'}
refs={**code_refs,**node_refs}
oldnodes={r['id']:r for r in old['nodes']};newnodes=[]
def known(v):
 if isinstance(v,dict) and set(v)=={'$pin'}:return pins[v['$pin']]['sha256']
 if isinstance(v,dict) and set(v)=={'$owned'}:return approval['owned'][v['$owned']]['current_sha256']
 return v
fade=next(r for r in hand['consumers'] if r['domain']=='Fade')
fadetarget=fade['target']
for node in spec['nodes']:
 id=node['id']
 if node['kind']=='map':
  base=json.loads(read(pins[node['base_input']]['path'],pins[node['base_input']]['sha256']))
  ops=node['operations']
  for path,new in code_refs.items():
   if path in base['source_sha256'] and not any(o['pointer']==['source_sha256',path] for o in ops):
    ops.append({'op':'set','pointer':['source_sha256',path],'existed':True,'old':base['source_sha256'][path],'new':new})
  for op in ops:
   if op['op']=='set' and op['pointer'][-1] in refs:op['new']=refs[op['pointer'][-1]]
  node['groups'].append('finite08_controls')
  if node['scene_id'] in ['ch4_s1_luoyang_yamen','ch4_s3_luoyang_market']:
   domain='market' if node['scene_id']=='ch4_s3_luoyang_market' else 'yamen'
   node['groups'].append('finite08_'+domain+'_complete')
  newnodes.append(node);continue
 current=stage['nodes'][id]
 pin(node['base_input'],current['path'],current['sha256'])
 if node.get('target'):node['old_sha256']=current['sha256']
 if node['kind']=='index':
  raw=read(current['path'],current['sha256']).decode();replacements=[]
  for r in node['replacements']:
   if r['old']=='const FORMAL_ENABLED=true':replacements.append(r);continue
   if isinstance(r['new'],dict) and '$sha' in r['new']:oldsha=stage['nodes'][r['new']['$sha']]['sha256']
   elif r['new']=={'$pin':'execution_approval'}:oldsha=hand['execution_parent']['sha256']
   else:oldsha=r['old']
   assert raw.count(oldsha)==1,(id,oldsha)
   replacements.append({'old':oldsha,'new':r['new']})
  node['replacements']=replacements
  if id=='ap_city_index':node['kind']='finite_index'
  newnodes.append(node);continue
 base=current['value']
 if id=='runtime_contract_final':
  node['kind']='finite_contract';node['operations']=[]
  for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd']:
   node['operations'].append({'op':'set','pointer':['source_sha256',p],'existed':True,'old':base['source_sha256'][p],'new':code_refs[p]})
  newnodes.append(node);continue
 operations=[]
 # Rebase every old operation on the exact deployed node, never current hash.
 for op in node.get('operations',[]):
  if op['op']=='remove':continue
  ks=op['pointer'];oldvalue=ptr(base,ks)
  ref=next((refs[k] for k in reversed(ks) if isinstance(k,str) and k in refs),op['new'])
  if known(ref)==oldvalue:continue
  operations.append({'op':'set','pointer':ks,'existed':True,'old':oldvalue,'new':ref})
 # Explicit leaf operations before merging groups prevent nonowned SHA drift.
 fields=[f['pointer'] for f in node.get('source_fields',[])]+node.get('source_bundle',{}).get('fields',[])
 for field in fields:
  values=ptr(base,field)
  for p,new in refs.items():
   ks=field+[p]
   if p in values and known(new)!=values[p] and not any(o['pointer']==ks for o in operations):
    operations.append({'op':'set','pointer':ks,'existed':True,'old':values[p],'new':new})
 if id.startswith('legacy_manifest_') or id=='market_final':
  ks=['source_migration','source_delta',fadetarget];oldrow=ptr(base,ks);row=copy.deepcopy(oldrow)
  assert row['new_sha256']=='3f2d43276f89341a450579fa07a0dd0bb2369d059ad928e7187fb35df59f1ac7'
  row['historical_sha256']=row['historical_sha256']+[row['new_sha256']]
  row['current_before_sha256']=row['new_sha256'];row['new_sha256']=fade['candidate']['sha256'];row['candidate_path']=fade['candidate']['path']
  operations.append({'op':'set','pointer':ks,'existed':True,'old':oldrow,'new':row})
 node['operations']=operations
 newnodes.append(node)

groups={r['id']:r for r in spec['source_groups']}
groups['quarter_family_direct_executable_leaves']['leaves'].update({r['target']:r['candidate']['sha256'] for r in hand['consumers'] if r['domain']=='C'})
control={hand['adapter']['path']:hand['adapter']['sha256'],hand['binding']['path']:hand['binding']['sha256']}
groups['finite08_controls']={'id':'finite08_controls','kind':'explicit','leaves':control}
groups['common_four_city']['groups'].append('finite08_controls')
for domain in ['market','yamen']:
 d=binding['domains'][domain]
 leaves={**control,**binding['shared_source_sha256'],**d['source_sha256'],hand['ground_shader']['path']:hand['ground_shader']['sha256']}
 groups['finite08_'+domain+'_sources']={'id':'finite08_'+domain+'_sources','kind':'explicit','leaves':leaves}
 # Finite manifest pins old source-only canonical header to retain old source
 # ancestry independently; no parent manifest points back at this new child.
 oldnode='market_final' if domain=='market' else 'legacy_manifest_3'
 oldtarget=oldnodes[oldnode]['target']
 groups['finite08_'+domain+'_header']={'id':'finite08_'+domain+'_header','kind':'explicit','leaves':{d['runtime_manifest_path']:{'$sha':'finite08_'+domain}}}
 groups['finite08_'+domain+'_complete']={'id':'finite08_'+domain+'_complete','kind':'union','groups':['finite08_'+domain+'_sources','finite08_'+domain+'_header']}
 finite={'id':'finite08_'+domain,'kind':'finite_manifest','domain':domain,'parent_node':oldnode,'parent_header_path':oldtarget,'file':d['runtime_manifest_path']}
 # Insert immediately before external AP index, after both parent nodes exist.
 idx=next(i for i,n in enumerate(newnodes) if n['id']=='ap_city_index')
 newnodes.insert(idx,finite)
# Extra shader is source-consumed only Market/Yamen. Inherited shared proof
# leaves remain unchanged; the Quarter manifest is not given this material.
for n in newnodes:
 if n['id'] in ['legacy_manifest_3','market_final']:n['source_bundle']['groups'].append('finite08_'+('market' if n['id']=='market_final' else 'yamen')+'_sources')
spec['nodes']=newnodes;spec['source_groups']=list(groups.values())
spec['finite08_contract']={'handoff_input':'finite08_handoff','binding_input':'finite08_binding','execution_root_input':'root_finite08_execution','scope_root_input':'root_finite08_scope','scope_request_input':'finite08_scope_request','ground_root_input':'root_finite08_ground','code_root_input':'root_finite08_code','canonical_target_count':28,'no_native_or_OWNED_expansion':True}
spec['repair_epoch_contract']={'actual_deployed_parent':{'path':stagepath,'sha256':'9aacef0735bced81c6f8b0601165b931a9cfe2f54aef682635490619319965b8'},'exact28_new_scope':True,'source_only_and_fixed_native_89216_inheritance':True,'no_collector_expected_fill':True}
spec['pinned_inputs']=list(pins.values())
# Drop obsolete control pins only if unreachable, preserving all historical
# source inputs actually required by original frozen recipes and native gates.
used=set(spec.get('authority_input','') for _ in [0])|{spec['authority_helper_input']}
def refs_in(v):
 if isinstance(v,dict):
  for k,x in v.items():
   if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(x,str) and x in pins:used.add(x)
   if k=='$pin':used.add(x)
   refs_in(x)
 elif isinstance(v,list):
  for x in v:refs_in(x)
refs_in(spec['nodes']);refs_in(spec['source_groups']);refs_in(spec['required_gates'])
used.update(spec['finite08_contract'][k] for k in ['handoff_input','binding_input','execution_root_input','scope_root_input','scope_request_input','ground_root_input','code_root_input'])
spec['pinned_inputs']=[p for p in spec['pinned_inputs'] if p['id'] in used]
for row in spec['pinned_inputs']:read(row['path'],row['sha256'])
spec['required_generator']={'path':S+'stage_finite08_READY.py','sha256':'PENDING_TOOL_SHA'}
out=emit('finite08_input_PENDING.json',spec)
print(json.dumps({'input':out,'targets':28,'nodes':len(newnodes),'pinned_inputs':len(spec['pinned_inputs']),'no_stage':True}))
