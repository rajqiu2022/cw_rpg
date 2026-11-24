"""Root-approved map-only FE154 incremental successor. No Stage execution."""
from pathlib import Path
import copy,json,hashlib,ast,difflib,collections
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;return b
def patch(a,b):
    al,bl=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);rows=[]
    for tag,i,j,k,l in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_opcodes():
        if tag!='equal':rows.append(dict(old_offset=len(''.join(al[:i]).encode()),new_offset=len(''.join(bl[:k]).encode()),old=''.join(al[i:j]),new=''.join(bl[k:l])))
    f,v=a,b
    for r in reversed(rows):
        x,y=r['old'].encode(),r['new'].encode();i,j=r['old_offset'],r['new_offset'];assert f[i:i+len(x)]==x and v[j:j+len(y)]==y;f=f[:i]+y+f[i+len(x):];v=v[:j]+x+v[j+len(y):]
    assert f==b and v==a;return rows
dp=S+'stage_docks_frontages31_NOTREADY.py';dh='5d58fa15bb1e551ab91ca57a105663b0de839d8dcf9c86eb0ab6d92e41a02a2d';a=read(dp,dh);s=a.decode()
needle="        super().build_node(row)\n"
assert s.count(needle)==1
block='''        if kind=='docks_incremental_map':
            need(ident not in self.nodes and row['scene_id'] in M.BASELINES,'INCREMENTAL_FOUR_FIXED_SCENES_ONLY')
            scene=row['scene_id'];baseline_sha,baseline_count=M.BASELINES[scene]
            ancestor_pin=self.inputs[row['ancestor_base_input']]
            need(ancestor_pin['path']==M.BASE_ROOT+scene+'_true.json' and ancestor_pin['sha256']==baseline_sha,'ORIGINAL_AO_BASELINE_LITERAL_UNCHANGED')
            ancestor=self.read_json_input(row['ancestor_base_input'])['source_sha256']
            need(len(ancestor)==baseline_count,'ORIGINAL_AO_BASELINE_COUNT_UNCHANGED')
            parent=self.read_json_input(row['base_input'])
            need(row['base_input']==self.contract['parent_map_inputs'][ident] and parent['scene_id']==scene and parent['baseline_path']==ancestor_pin['path'] and parent['baseline_sha256']==baseline_sha and same(parent['source_sha256'],self.parent_maps[ident]),'FIXED_FE154_PARENT_MAP_IDENTITY')
            old=parent['source_sha256'];value={'source_sha256':self.promote_owned(old)}
            need(all(len(op['pointer'])==2 and op['pointer'][0]=='source_sha256' and op['op']=='set' and op['existed'] is True and op['pointer'][1] in self.oldtargets for op in row['operations']),'INCREMENTAL_ONLY_EXISTING_31_TARGET_VALUES')
            deltas=self.change(value,row['operations'])
            for group in row['groups']:self.merge(value['source_sha256'],self.group(group))
            # This independent mathematical model is equality evidence only.
            # It does NOT authorize or replace approved() for historical hashes.
            declared={'source_sha256':copy.deepcopy(ancestor)}
            for path in declared['source_sha256']:
                if path in self.authority['owned']:declared['source_sha256'][path]=self.authority['owned'][path]['current_sha256']
            self.change(declared,row['ancestor_operations'])
            for group in row['groups']:self.merge(declared['source_sha256'],self.group(group))
            need(same(declared,value),'WHOLE_TYPED_EQUAL_ORIGINAL_DECLARED_AO_MODEL')
            expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:
                    need(expected[path]==target['old_sha256'],'FE154_EXACT_OLD_TARGET_MAP_VALUE');expected[path]=target['candidate_sha256']
            for group in row['declared_new_groups']:self.merge(expected,self.group(group))
            need(same(expected,value['source_sha256']) and set(old)<=set(expected),'FE154_PLUS_ONLY_APPROVED_31_DELTAS_AND_DECLARED_ADDITIONS')
            added=set(expected)-set(ancestor)
            if scene!='ch4_s3_luoyang_market':need(not any(p.startswith('res://data/maps/luoyang_full_city_20261022ap/quarters/') for p in added),'ONLY_MARKET_ACQUIRES_NEW_QUARTER_NATIVE_CLOSURE')
            if scene=='ch4_s0_luoyang_gate':need(not any('/rooms/' in p or '/luoyang_layout_rooms_' in p for p in added),'GATE_MUST_NOT_ACQUIRE_ROOM253')
            removed=set(ancestor)-set(expected);retired={r['path']:r for r in row.get('retired_runtime_authorities',[])}
            need(removed==set(retired),'NO_UNDECLARED_OLD_MAP_SOURCE_REMOVAL')
            for path in removed:need(path.endswith('/manifest.json') and retired[path]['old_sha256']==ancestor[path] and retired[path]['replacement'] in expected,'ONLY_EXPLICIT_REPLACED_RUNTIME_AUTHORITY')
            for path,h in expected.items():self.verify_leaf(path,h)
            output=dict(status='AP_INDEPENDENT_EXPECTED_NOT_ACTUAL_COLLECTOR',baseline_path=ancestor_pin['path'],baseline_sha256=baseline_sha,scene_id=scene,source_sha256=expected)
            media=self.media_closure(expected,row.get('runtime_media_roots',[]));p,h=self.output(row['file'],encode(output))
            self.nodes[ident]=dict(path=p,sha256=h,value=output)
            self.proofs[ident]=dict(baseline_count=baseline_count,parent_FE154_input=row['base_input'],parent_count=len(old),count=len(expected),explicit_delta=deltas,retired_runtime_authorities=list(removed),runtime_media_closure=media,no_collector_or_current_disk_derivation=True,original_declared_AO_model_whole_typed_equal=True,mathematical_model_not_historical_permission=True,approved_unchanged_on_fixed_current_parent_owned_values=True)
            return
'''
s=s.replace(needle,block+needle);b=s.encode();ast.parse(s)
newdp=S+'stage_docks_frontages31_residual02_NOTREADY.py';assert not (GAME/newdp[6:]).exists();(GAME/newdp[6:]).write_bytes(b)
ip=S+'source_input_docks31_ROOT_REVIEW.json';ih='393143c0ba62cdb16e18693b153e244d135d440ef96a0245c978798f9fd55e33';ia=read(ip,ih);spec=json.loads(ia);oldspec=copy.deepcopy(spec)
pins={r['id']:r for r in spec['pinned_inputs']};authority=json.loads(read(pins[spec['authority_input']]['path'],pins[spec['authority_input']]['sha256']))
depth_evidence={};CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';row=authority['owned'][CO];q=collections.deque([(row['current_sha256'],0)]);distance={}
while q:
    h,d=q.popleft()
    if h in distance:continue
    distance[h]=d
    for edge in row['edges']:
        if edge['new_sha256']==h:q.append((edge['old_sha256'],d+1))
targets=set(spec['root_target_allowlist'])
for n in spec['nodes']:
    if n['kind']!='map':continue
    ident=n['id'];ancestor_pin=pins[n['base_input']];ancestor=json.loads(read(ancestor_pin['path'],ancestor_pin['sha256']))['source_sha256'];parent_id=spec['docks_contract']['parent_map_inputs'][ident];parentpin=pins[parent_id];parent=json.loads(read(parentpin['path'],parentpin['sha256']))['source_sha256']
    n['kind']='docks_incremental_map';n['ancestor_base_input']=n['base_input'];n['ancestor_operations']=copy.deepcopy(n['operations']);n['base_input']=parent_id
    promoted=copy.deepcopy(parent)
    for path in promoted:
        if path in authority['owned']:promoted[path]=authority['owned'][path]['current_sha256']
    finalrefs={r['pointer'][1]:r['new'] for r in n['ancestor_operations'] if r['op']=='set' and r['pointer'][1] in targets}
    n['operations']=[dict(op='set',pointer=['source_sha256',path],existed=True,old=promoted[path],new=ref) for path,ref in finalrefs.items() if path in promoted]
    depth_evidence[ident]=dict(Coordinator_original_AO_sha=ancestor[CO],original_shortest_depth=distance[ancestor[CO]],Coordinator_fixed_FE154_sha=parent[CO],current_parent_shortest_depth=distance[parent[CO]],core_range16_tests_depth0_to15=True)
    assert distance[ancestor[CO]]==16 and distance[parent[CO]]==1
spec['required_generator']=dict(path=newdp,sha256=sha(b));spec['output_root']=S+'outputs/root_docks_frontages_exact31_stage02/'
ib=enc(spec);newip=S+'source_input_docks31_residual02_ROOT_REVIEW.json';assert not (GAME/newip[6:]).exists();(GAME/newip[6:]).write_bytes(ib)
pr=dict(status='ROOT_APPROVED_DOCKS31_FE154_INCREMENTAL_MAP_RESIDUAL_NOT_EXECUTED',driver=dict(path=newdp,sha256=sha(b)),input=dict(path=newip,sha256=sha(ib),bytes=len(ib)),parent_driver=dict(path=dp,sha256=dh),parent_input=dict(path=ip,sha256=ih),driver_offset_patch=patch(a,b),input_offset_patch=patch(ia,ib),whole_byte_forward_inverse=True,exact_Coordinator_depth_evidence=depth_evidence,unchanged_fields_except_four_map_nodes_generator_outputroot=True,original_four_AO_literal_baselines_and_five_gates_retained=True,old_driver_input_and_failed_stage01_preserved=True,all_31_candidates_execution_CF1C_162_and_old_edges_unchanged=True,depth16_not_expanded=True,no_shortcut=True,Stage_imports=0,Stage_calls=0,collector_calls=0,canonical_writes=0)
for k,v in oldspec.items():
    if k not in ['nodes','required_generator','output_root']:assert spec[k]==v
for a,bn in zip(oldspec['nodes'],spec['nodes']):
    if a['kind']!='map':assert a==bn
raw=enc(pr);dest=HERE/'docks31_residual02_whole_inverse_NOT_EXECUTED.json';assert not dest.exists();dest.write_bytes(raw)
print(json.dumps(dict(driver=pr['driver'],input=pr['input'],proof=dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw)))))
