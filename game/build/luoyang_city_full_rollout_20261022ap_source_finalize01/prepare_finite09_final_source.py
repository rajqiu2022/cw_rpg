"""NEW29/compiler successor only. Do not instantiate Stage or run engine."""
import argparse,ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def pth(p):
 assert p.startswith('res://') and '..' not in p;return G/p[6:]
def read(p,s):
 b=pth(p).read_bytes();assert sha(b)==s,('EXACT_PIN',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--scope-path',required=True);ap.add_argument('--scope-sha256',required=True);args=ap.parse_args()
 scope=json.loads(read(args.scope_path,args.scope_sha256))
 requestpath=S+'finite_adapter_production09_scope/scope_request_READY.json'
 requestsha='1eade019a011914021f4dae7c0aaa426b0b647ac19cd5564d72bf8828cb4a8d0'
 request=json.loads(read(requestpath,requestsha))
 assert scope['approved_by_root'] is True and scope['target_count']==29 and scope['scope_sha256']==requestsha
 assert scope['before_sha256']=='2ce39bbe5a6afba5bc3661107a776fb107c9e1b909cafc50f3f0b1522ba8de47'
 assert {r['target']:r['old_sha256'] for r in scope['targets']}=={r['target']:r['old_sha256'] for r in request['targets']}
 oldtool=read(S+'stage_finite08_READY.py','1177be57d7b656f825e695ee8be56e635b7915beaf4ef8b50f44c3422658c11f')
 text=oldtool.decode();replacements=[]
 def sub(a,b,label,count=1):
  nonlocal text
  assert text.count(a)==count,(label,text.count(a),count)
  text=text.replace(a,b);replacements.append({'label':label,'old':a,'new':b,'count':count})
 sub('exact28','exact29','scope descriptions',1)
 sub("'0442c193acde18e358fa11fe3b820083023c0245f6001a7f3c616b57227f163a'",repr(args.scope_sha256),'fixed Root29 authority SHA')
 sub("'15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672'",repr(requestsha),'fixed request29 SHA')
 sub("scope.get('target_count')==28","scope.get('target_count')==29",'authority target count29')
 sub("len(self.spec['root_target_allowlist'])==28","len(self.spec['root_target_allowlist'])==29",'allowlist length29')
 sub('len(self.targets)==28','len(self.targets)==29','exact final targets29')
 sub('len(reconstruction)==28','len(reconstruction)==29','reconstruction29')
 sub("'patch_count':27,'copy_count':1,'total':28","'patch_count':28,'copy_count':1,'total':29",'partition28plus1')
 sub("'targets':28,'map_nodes':4","'targets':29,'map_nodes':4",'summary29')
 sub('EXACT28','EXACT29','closed scope error labels',4)
 sub('ORDERED_EXACT28','ORDERED_EXACT29','ordered error label',0) if False else None
 sub('PATCH27_COPY1','PATCH28_COPY1','partition error label')
 anchor='    def build_node(self,row):\n'
 extra='''    def _fixed_runtime_buffer(self,path,expected):
        allowed={d['runtime_manifest_path'] for d in self.binding['domains'].values()}
        if path not in allowed or path not in self.outputs:return None
        need(len(allowed)==2 and path in {self.nodes[k]['path'] for k in ['finite08_market','finite08_yamen'] if k in self.nodes},'ONLY_COMPLETED_TWO_FIXED_RUNTIME_BUFFERS')
        raw=self.outputs[path];need(sha(raw)==expected,'FIXED_BUFFER_COMPLETE_SHA')
        return raw
    def verify_leaf(self,path,expected):
        if self._fixed_runtime_buffer(path,expected) is not None:return
        return super().verify_leaf(path,expected)
    def leaf_bytes(self,path,expected):
        raw=self._fixed_runtime_buffer(path,expected)
        return raw if raw is not None else super().leaf_bytes(path,expected)
'''
 sub(anchor,extra+anchor,'only completed two-runtime buffered leaf interfaces')
 ast.parse(text)
 # Mechanical full reverse, including all count occurrences and exact context.
 inv=text
 for r in reversed(replacements):assert inv.count(r['new'])==r['count'];inv=inv.replace(r['new'],r['old'])
 assert inv.encode()==oldtool
 outputs={S+'stage_finite09_READY.py':text.encode()}
 toolsha=sha(text.encode())
 wrapper=read(S+'stage_finite08_scope01_READY.py','cd8470d6ee6bd7549c8e078943ab3a130b6d6e58ddb5c04daf72375f59debe68').decode()
 for a,b in [('stage_finite08_READY.py','stage_finite09_READY.py'),('1177be57d7b656f825e695ee8be56e635b7915beaf4ef8b50f44c3422658c11f',toolsha),('res://build/luoyang_city_full_rollout_20261022ap_root01/integration12/root_target_scope_READY.json',args.scope_path),('44cfe6d81a6aff79431def1a3026199219f0a63083931de636577efa633841a0',args.scope_sha256),('15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672',requestsha),("value.get('target_count')==28","value.get('target_count')==29"),('EXACT28','EXACT29'),('FRESH28','FRESH29')]:
  assert wrapper.count(a)==1,(a,wrapper.count(a));wrapper=wrapper.replace(a,b,1)
 ast.parse(wrapper);wrapperpath=S+'stage_finite09_scope01_READY.py';wrappersha=sha(wrapper.encode());outputs[wrapperpath]=wrapper.encode()
 inputold=read(S+'finite08_input01_ROOT_LOCKED.json','18fd1b4f97de05a28612fa206c402e84dc0ede6deec9b7b9c60ca74e5aca850e')
 plan=json.loads(inputold);plan['output_root']=S+'outputs/root_finite09_two_domain_stage01/'
 plan['root_target_allowlist']=[r['target'] for r in request['targets']]
 plan['finite08_contract']['canonical_target_count']=29
 plan['repair_epoch_contract']['exact28_new_scope']=False
 plan['repair_epoch_contract']['exact29_new_scope']=True
 plan['root_lock_scope']={'path':args.scope_path,'sha256':args.scope_sha256,'exact_target_count':29,'canonical_deployment_still_requires_fresh_plan_authorization':True}
 for row in plan['pinned_inputs']:
  if row['id'] in ['root_finite08_scope','root_finite08_actual_backups']:row.update(path=args.scope_path,sha256=args.scope_sha256)
  if row['id']=='finite08_scope_request':row.update(path=requestpath,sha256=requestsha)
  read(row['path'],row['sha256'])
 registry=next(r for r in plan['nodes'] if r['id']=='registry_final')
 assert 'target' not in registry
 registry.update(target='res://data/maps/luoyang_estate_rooms_20261021am/registry.json',old_sha256='69602933f93d6c0ede6feb2a8e3c1f355a224017bb59c638440135e42e7634f6')
 assert len(registry['operations'])==5
 # Formal imported mask identity is checked again through exact sidecar->ctex
 # remap, in addition to independently Root-approved136/0 import evidence.
 bindrow=next(r for r in plan['pinned_inputs'] if r['id']=='finite08_binding');binding=json.loads(read(bindrow['path'],bindrow['sha256']))
 compiled={'market':'res://.godot/imported/walk.png-5a109c3389acd4d8723a967a01d33772.ctex','yamen':'res://.godot/imported/walk.png-83913bd6be2721f8f618ce44eb12f575.ctex'}
 for n in plan['nodes']:
  if n['kind']=='map' and n['scene_id'] in ['ch4_s1_luoyang_yamen','ch4_s3_luoyang_market']:
   d='market' if n['scene_id']=='ch4_s3_luoyang_market' else 'yamen'
   assert compiled[d] in binding['domains'][d]['source_sha256']
   n['runtime_media_roots'].append({'path':binding['domains'][d]['artifacts']['walk.png']['path'],'compiled_paths':[compiled[d]]})
 plan['required_generator']={'path':wrapperpath,'sha256':wrappersha,'root_must_read_before_execution':True}
 plan['finite09_changes_from_unexecuted18FD']=['Necessary registry29th target/five exact DT source migrations','Only two fixed completed runtime output buffers may satisfy leaf reads by exactSHA','Root actual29 scope+full backups and original fresh2CE39 baseline','Explicit two already-promoted walk remap closures; no import or media mutation','No production GD/dependency/owned/artifact change']
 inputpath=S+'finite09_input01_ROOT_LOCKED.json';inputbytes=js(plan);inputsha=sha(inputbytes);outputs[inputpath]=inputbytes
 recipe=read(S+'review_finite08_actual_stage_and_prepare_owners_READY.py','a5d7414f0f4962530b03eea9f81cd7cee71615a2b04364a4061b8150ec27744a').decode()
 for a,b in [('root_finite08_two_domain_stage01','root_finite09_two_domain_stage01'),('finite08_input01_ROOT_LOCKED.json','finite09_input01_ROOT_LOCKED.json'),('18fd1b4f97de05a28612fa206c402e84dc0ede6deec9b7b9c60ca74e5aca850e',inputsha),('len(stage[\'targets\'])==28','len(stage[\'targets\'])==29'),("'patch_count':27,'copy_count':1,'total':28","'patch_count':28,'copy_count':1,'total':29"),('finite_adapter_production08_scope/scope_request_READY.json','finite_adapter_production09_scope/scope_request_READY.json'),('15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672',requestsha),('finite08_independent_review','finite09_independent_review'),("'target_count':28","'target_count':29"),('INDEPENDENT28','INDEPENDENT29')]:
  assert a in recipe,a;recipe=recipe.replace(a,b)
 ast.parse(recipe);recipepath=S+'review_finite09_actual_stage_and_prepare_owners_READY.py';outputs[recipepath]=recipe.encode()
 proof={'status':'EXACT29_SOURCE_TOOL_SUCCESSOR_NOT_EXECUTION','parent_tool_sha256':sha(oldtool),'candidate_tool_sha256':toolsha,'whole_tool_byte_inverse_to1177':True,'explicit_replacements':replacements,'new_runtime_leaf_scope':'Only binding-declared two completed finite manifest buffers; exact hash; all other paths delegate unchanged old verifier','registry_only_additional_canonical_target':registry['target'],'production_handoff_8FD3_unchanged':True,'input_parent18FD_preserved_unexecuted':True,'scope':{'path':args.scope_path,'sha256':args.scope_sha256},'stage_runs':0,'engine_calls':0,'canonical_writes':0}
 outputs[S+'finite09_tool_review/exact_successor_to1177_READY.json']=js(proof)
 outputs[S+'finite09_tool_review/tool09_vs08.diff']=''.join(difflib.unified_diff(oldtool.decode().splitlines(keepends=True),text.splitlines(keepends=True),fromfile='frozen1177',tofile='finite09')).encode()
 for p,b in outputs.items():
  assert not pth(p).exists();pth(p).parent.mkdir(parents=True,exist_ok=True)
  with pth(p).open('xb') as f:f.write(b)
 print(json.dumps({'input':{'path':inputpath,'sha256':inputsha},'tool':{'path':wrapperpath,'sha256':wrappersha},'base_tool_sha256':toolsha,'recipe':{'path':recipepath,'sha256':sha(recipe.encode())},'proof_sha256':sha(js(proof)),'targets':29,'stage_runs':0}))
if __name__=='__main__':main()
