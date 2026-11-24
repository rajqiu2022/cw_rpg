"""One exact33 recipe from fixed24c tables, never a runtime/current source fill."""
from pathlib import Path
import json,hashlib,copy,argparse,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261024e_root01/';P='res://build/luoyang_city_revision_20261024c_source01/'
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';REGISTRY='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),(p,sha(b));assert b'tokens truncated' not in b;return b
def load(p,h):return json.loads(read(p,h))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def at(v,ks):
    for k in ks:v=v[k]
    return v
def op(ks,a,b,ex=True):return dict(op='set',pointer=ks,existed=ex,old=copy.deepcopy(a),new=copy.deepcopy(b))
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--preparation-path',required=True);ap.add_argument('--preparation-sha',required=True);args=ap.parse_args()
    oldpath=P+'driver_path_residual03/source_input_courts_scholar30_residual03_ROOT_REVIEW.json';oldsha='317b4227f09057bc30fe9436e9815523d042403a496a93d935e261be813128bb';oldraw=read(oldpath,oldsha);old=json.loads(oldraw)
    scopepath=S+'exact33_existing_old_scope_PREPARATION.json';scopehash='560df439ceb31b6e210ea79cef850fbfc96827ad5c4682a7fabfbd1c8be23671';scope=load(scopepath,scopehash);targets={r['target']:r['old_sha256'] for r in scope['targets']}
    parentpath=P+'outputs/root_courts_scholar_exact30_stage03/receipt.json';parenthash='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce';parent=load(parentpath,parenthash);latest_nodes=parent['nodes']
    proofpath=S+'dependencies33_READY/code_execution_whole_inverse_NOT_STAGE.json';proofhash='d6b4c0afcaac7f8f29ca8c15b7412abafa90ad7418c4106a8d113622c715913e';proof=load(proofpath,proofhash);authority=load(proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
    freeze=load(S+'runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad')
    binding=load(freeze['binding']['candidate']['path'],freeze['binding']['candidate']['sha256']);ordinary=load(proof['ordinary']['path'],proof['ordinary']['sha256'])
    pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
    def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h.lower());return {'$pin':i}
    pin('execution_approval',proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256']);pin('space_parent_execution',proof['execution']['parent']['path'],proof['execution']['parent']['sha256'])
    pin('space_parent_stage',parentpath,parenthash);pin('space_scope',scopepath,scopehash);pin('space_code_inverse',proofpath,proofhash)
    pin('space_Root_backup',R+'predeploy33_backup_receipt.json','d09fc312a82a3e90eb4ba681b3b666c757502e42a57dc517377e48d6bed99f6f')
    pin('space_Root_preparation',args.preparation_path,args.preparation_sha);approval=load(args.preparation_path,args.preparation_sha)
    pin('blocks_binding',freeze['binding']['candidate']['path'],freeze['binding']['candidate']['sha256']);pin('blocks_freeze',S+'runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad')
    pin('space_contract_literal',proof['contract']['candidate']['path'],proof['contract']['candidate']['sha256']);pin('space_temple_binding',proof['temple_binding']['candidate']['path'],proof['temple_binding']['candidate']['sha256'])
    pin('blocks_ordinary',proof['ordinary']['path'],proof['ordinary']['sha256'])
    refs={p:pin('blocks_code_'+str(i),r['candidate']['path'],r['candidate']['sha256']) for i,(p,r) in enumerate(proof['records'].items())};refs[EXEC]={'$pin':'execution_approval'};refs[CONTRACT]={'$sha':'runtime_contract_final'}
    for n in old['nodes']:
        if n.get('target') in targets and n['target'] not in refs:refs[n['target']]={'$sha':n['id']}
    groups={g['id']:copy.deepcopy(g) for g in old['source_groups']}
    for g in groups.values():
        if g['kind']=='explicit':
            for p in g['leaves']:
                if p in refs:g['leaves'][p]=copy.deepcopy(refs[p])
    full=copy.deepcopy(binding['required_source_sha256'])
    for name in ['runtime','binding']:
        r=freeze[name]['candidate'];assert r['path'] not in full;full[r['path']]=r['sha256']
    assert len(full)==29
    runtime=freeze['runtime']['candidate'];shared={runtime['path']:runtime['sha256'],freeze['binding']['candidate']['path']:freeze['binding']['candidate']['sha256'],binding['author_path']:binding['author_sha256'],binding['pure_path']:binding['pure_sha256']}
    purpose={
        'res://build/luoyang_city_blocks_20261024e_system01/market_purpose_layer03_clean_base_NOTREADY.gd':'f6b636b4f395c3c35ce10315174e5539a3ea81cedcf665f6accddfc463779f2e',
        'res://build/luoyang_city_blocks_20261024e_system01/market_five_use_spec03_clean_base_NOTREADY.json':'83b78f04dcfc569a8bb3a74f447fa26a6ba03b8b54b92402db9ee43a5da3227d',
        'res://build/luoyang_city_blocks_20261024e_system01/market_use_union01_NOTREADY.gdshader':'18c45381f30776af9c1255e3c3c72ff8403b09f54fbc15c1899061125fda7166'}
    helper=proof['temple_binding']['ordinary_additions']
    for i,leaves in [('blocks_Market_full29',full),('blocks_room_return4',shared),('blocks_Market_purpose3',purpose),('blocks_Docks_ordinary2',ordinary['source_additions']),('blocks_Field_prewarm1',helper)]:groups[i]=dict(id=i,kind='explicit',leaves=leaves)
    # C transition source API always contributes the one prewarm ordinary leaf.
    groups['common_four_city']['groups'].append('blocks_Field_prewarm1')
    groups['G_five_return_added_source_delta']['groups'].append('blocks_room_return4')
    def additions(ident):
        result=[]
        if ident in ['legacy_manifest_3','legacy_manifest_4','legacy_manifest_5','legacy_manifest_6','legacy_manifest_7','legacy_manifest_8','finite08_market','finite08_yamen','market_final','quarter_final','expected_ch4_s1_luoyang_yamen_true','expected_ch4_s2_canal_docks_true','expected_ch4_s3_luoyang_market_true']:result.append('blocks_room_return4')
        if ident in ['legacy_manifest_5','legacy_manifest_8','finite08_market','market_final','expected_ch4_s3_luoyang_market_true']:result+=['blocks_Market_full29','blocks_Market_purpose3']
        if ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7','expected_ch4_s2_canal_docks_true']:result.append('blocks_Docks_ordinary2')
        if ident in ['quarter_final','estate_final']:result.append('blocks_Field_prewarm1')
        return result
    nodes=[]
    for original in old['nodes']:
        n=copy.deepcopy(original);ident,kind=n['id'],n['kind']
        if ident=='execution_final':nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
        if ident=='ENV_code':
            r=proof['records']['res://scripts/city/luoyang_environment_layer_20261022ap.gd']['candidate'];i='blocks_ENV_code';pin(i,r['path'],r['sha256']);nodes.append(dict(id=ident,kind='space_code',base_input=i,immutable_sha256=r['sha256'],is_json=False));continue
        if kind=='space_frozen':nodes.append(n);continue
        if kind=='map':
            wanted=parent['nodes'][ident]['value']['source_sha256'];seed=load(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])['source_sha256'];promoted=copy.deepcopy(seed)
            for p in promoted:
                if p in authority['owned']:promoted[p]=authority['owned'][p]['current_sha256']
            n['operations']=[op(['source_sha256',p],promoted.get(p),refs.get(p,h),p in promoted) for p,h in wanted.items() if p not in promoted or p in refs or promoted[p]!=h]
            n['operations']+=[dict(op='remove',pointer=['source_sha256',p],existed=True,old=promoted[p],new=None) for p in set(promoted)-set(wanted)]
            n['groups']+=additions(ident)
            n['declared_new_groups']=['authority_before_and_candidate_proofs','blocks_Field_prewarm1']+additions(ident);nodes.append(n);continue
        target=n['target'];assert target in targets;r=latest_nodes[ident];assert r['sha256']==targets[target]
        i='blocks_parent_'+ident;pin(i,r['path'],r['sha256']);n['base_input']=i;n['old_sha256']=r['sha256']
        if kind=='index':
            edits=[]
            for h in n['replacements']:
                v=h['new']
                if isinstance(v,dict) and '$sha' in v:edits.append(dict(old=latest_nodes[v['$sha']]['sha256'],new=v))
                elif v=={'$pin':'execution_approval'}:edits.append(dict(old=proof['execution']['parent']['sha256'],new=v))
                elif h['old']=='const FORMAL_ENABLED=true' and v=='const FORMAL_ENABLED=false':edits.append(h)
                else:raise AssertionError(('UNKNOWN_INDEX_EDIT',ident,h))
            assert len([h for h in edits if h['new']=='const FORMAL_ENABLED=false'])==1;n['replacements']=edits;nodes.append(n);continue
        base=r['value']
        if ident=='runtime_contract_final':
            n['operations']=[op(['source_sha256',p],c['old_sha256'],refs[p]) for p,c in proof['contract']['changed'].items()];n['literal_candidate_input']='space_contract_literal';n['kind']='space_contract';n['file']='runtime_contract_C_Field_Router_successor.json';nodes.append(n);continue
        if ident=='registry_final':
            paths=[x['pointer'] for x in original['operations']];assert len(paths)==5
            n['operations']=[op(p,at(base,p),refs[p[-1]]) for p in paths];nodes.append(n);continue
        fields=n.get('source_bundle',{}).get('fields',[])+[f['pointer'] for f in n.get('source_fields',[])]
        n['operations']=[op(ks+[p],h,refs[p]) for ks in fields for p,h in at(base,ks).items() if p in refs]
        if ident=='estate_final':n['operations'].append(op(['registry_sha256'],base['registry_sha256'],{'$sha':'registry_final'}))
        if n.get('source_bundle'):n['source_bundle']['groups']+=additions(ident)
        else:
            if additions(ident):
                assert len(n['source_fields'])==1;n['source_fields'][0]['groups']+=additions(ident)
        nodes.append(n)
    spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=list(groups.values()),root_target_allowlist=list(targets),output_root=S+'outputs/root_market_blocks_prewarm_exact33_stage01/',source_baseline='Fixed24c99A719/BCAC911 plus exact33 values; original native4/24cYamen/worker facts/Packed/ENV union/64classification retained; new Market29+purpose3, G return4, prewarm ordinary1, Docks ordinary2 only; no live collector or current-fill.')
    passed=[dict(target=p,old_sha256=r['parent']['sha256'],candidate_path=r['candidate']['path'],candidate_sha256=r['candidate']['sha256']) for p,r in proof['records'].items()];e=proof['execution'];passed.append(dict(target=EXEC,old_sha256=e['parent']['sha256'],candidate_path=e['candidate']['path'],candidate_sha256=e['candidate']['sha256']))
    spec['pass_through_targets']=passed;spec['prospective_targets']=[dict(target=x['target'],candidate_path=x['candidate_path'],sha256=x['candidate_sha256']) for x in passed]
    for gate in spec['required_gates']:
        if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=33)
    c=spec['space_contract'];c.update(Root_backup_prefix=R+'predeploy33_backup/',expected_Root_preparation_document=approval,root_input_freeze_pending=False,expected_proofs=148,blocks_binding_input='blocks_binding')
    router=proof['records']['res://scripts/autoload/scene_router.gd'];routerraw=read(router['candidate']['path'],router['candidate']['sha256']);shadow=routerraw.replace(b'\r\n',b'\n')
    c['Router_exact_EOL_transport']=dict(old_sha256=router['parent']['sha256'],candidate_sha256=router['candidate']['sha256'],LF_shadow_sha256=sha(shadow),LF_shadow_bytes=len(shadow),raw_CR_count=13)
    driver=S+'stage_market_blocks33_Estate1_NOTREADY.py';driverraw=read(driver,'4fa7f49701bb25ea6d7818fde17406d3d5d27fbb348fa72ef9a3302c6ecf4f5b');spec['required_generator']=dict(path=driver,sha256=sha(driverraw))
    used={spec['authority_input'],spec['authority_helper_input']}
    def collect(v):
        if isinstance(v,dict):
            for k,w in v.items():
                if (k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] or k.endswith('_input')) and isinstance(w,str) and w in pins:used.add(w)
                if k=='$pin':used.add(w)
                collect(w)
        elif isinstance(v,list):
            for w in v:collect(w)
    collect(spec);used.update(['blocks_binding','blocks_freeze','blocks_ordinary','space_temple_binding','space_Root_preparation','space_scope','space_code_inverse','space_parent_stage','space_parent_execution','space_Root_backup'])
    spec['pinned_inputs']=[r for k,r in pins.items() if k in used]
    assert len(targets)==33 and len(passed)==11 and sum('target' in n for n in nodes)+len(passed)==33
    known=set();oldptr=0
    def checkrefs(v):
        if isinstance(v,dict):
            if '$sha' in v:assert v['$sha'] in known,('EARLY_NODE',v)
            if '$pin' in v:assert v['$pin'] in used
            for w in v.values():checkrefs(w)
        elif isinstance(v,list):
            for w in v:checkrefs(w)
    def checkgroup(i,stack):
        assert i not in stack;g=groups[i];checkrefs(g)
        if g['kind']=='node_dictionary':assert g['node'] in known
        if g['kind']=='union':
            for z in g['groups']:checkgroup(z,stack+[i])
    for n in nodes:
        checkrefs(n.get('operations',[]));checkrefs(n.get('replacements',[]))
        if n.get('operations') and n['kind']!='map':
            base=latest_nodes[n['id']]['value']
            for z in n['operations']:
                holder=at(base,z['pointer'][:-1]);k=z['pointer'][-1];assert (k in holder)==z['existed'] and (not z['existed'] or holder[k]==z['old']);oldptr+=1
        for i in n.get('source_bundle',{}).get('groups',[])+n.get('groups',[])+[i for f in n.get('source_fields',[]) for i in f.get('groups',[])]:checkgroup(i,[])
        known.add(n['id'])
    raw=enc(spec);dest=HERE/'source_input_market_blocks33_ROOT_REVIEW.json';assert not dest.exists()
    with dest.open('xb') as f:f.write(raw)
    delta=[];al,bl=oldraw.decode().splitlines(keepends=True),raw.decode().splitlines(keepends=True)
    for tag,i,j,k,l in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_opcodes():
        if tag!='equal':delta.append(dict(old_offset=sum(len(x.encode()) for x in al[:i]),new_offset=sum(len(x.encode()) for x in bl[:k]),old=''.join(al[i:j]),new=''.join(bl[k:l])))
    f,b=oldraw,raw
    for d in reversed(delta):i=d['old_offset'];a,c=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+c+f[i+len(a):]
    for d in reversed(delta):i=d['new_offset'];a,c=d['old'].encode(),d['new'].encode();assert b[i:i+len(c)]==c;b=b[:i]+a+b[i+len(c):]
    assert f==raw and b==oldraw
    patch=enc(dict(parent=dict(path=oldpath,sha256=oldsha),candidate=dict(path=S+dest.name,sha256=sha(raw)),segments=delta,wholebyte_forward_inverse=True));pp=HERE/'stage33_input_full_byte_patch_BUILD.json'
    with pp.open('xb') as f:f.write(patch)
    review=enc(dict(status='EXACT33_INPUT_STATIC_PREFLIGHT_NOT_RUN',driver=spec['required_generator'],input=dict(path=S+dest.name,sha256=sha(raw)),input_inverse=dict(path=S+pp.name,sha256=sha(patch)),code_inverse=dict(path=proofpath,sha256=proofhash),targets=33,partition=dict(GD=18,JSON=15),pass_through=11,nodes=len(nodes),groups=len(groups),pins=len(spec['pinned_inputs']),old_pointers_checked=oldptr,strict_DAG_checked=True,new_groups={i:groups[i] for i in groups if i.startswith('blocks_')},no_engine=True,no_Stage=True,no_current_fill=True))
    rp=HERE/'stage33_package_review_BUILD.json'
    with rp.open('xb') as f:f.write(review)
    print(json.dumps(dict(input_path=S+dest.name,input_sha256=sha(raw),review_path=S+rp.name,review_sha256=sha(review),patch_sha256=sha(patch),nodes=len(nodes),groups=len(groups),pins=len(spec['pinned_inputs']),oldptr=oldptr)))
if __name__=='__main__':main()
