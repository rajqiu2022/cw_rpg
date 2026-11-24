"""Small text/JSON-only full inverse and old-pointer preflight. Never Stage."""
import argparse,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance100_unified_life_garden_scholar_BUILD/'
def raw(p):return (G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def pointer(v,ks):
    for k in ks:v=v[k]
    return v
def strict(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(strict(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(strict(x,y)for x,y in zip(a,b))
    return a==b
def inverse_record(parent,child):
    a,b=raw(parent),raw(child);al=a.splitlines(keepends=True);bl=b.splitlines(keepends=True)
    ai=[0];bi=[0]
    for line in al:ai.append(ai[-1]+len(line))
    for line in bl:bi.append(bi[-1]+len(line))
    changes=[]
    for op,i,j,k,l in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_opcodes():
        if op!='equal':changes.append({'old_offset':ai[i],'new_offset':bi[k],'old':b''.join(al[i:j]).decode(),'new':b''.join(bl[k:l]).decode()})
    forward=a;reverse=b
    for h in reversed(changes):
        x,y=h['old'].encode(),h['new'].encode();i,j=h['old_offset'],h['new_offset']
        assert forward[i:i+len(x)]==x and reverse[j:j+len(y)]==y
        forward=forward[:i]+y+forward[i+len(x):];reverse=reverse[:j]+x+reverse[j+len(y):]
    assert forward==b and reverse==a
    if parent.endswith('.json'):assert strict(json.loads(reverse),json.loads(a))and strict(json.loads(forward),json.loads(b))
    return {'parent':{'path':parent,'sha256':sha(a),'bytes':len(a)},'child':{'path':child,'sha256':sha(b),'bytes':len(b)},'offset_units':'UTF8_BYTES','apply_order':'descending_offsets','segments':changes,'whole_forward_and_inverse':True}
def prepare():
    plan=json.loads(raw(O+'source_input_NOTREADY.json'));pins={r['id']:r for r in plan['pinned_inputs']}
    authority=json.loads(raw(pins[plan['authority_input']]['path']));seen=set();checks=0
    def value(x):
        if isinstance(x,dict)and'$sha'in x:return 'NODE:'+x['$sha']
        if isinstance(x,dict)and'$pin'in x:return pins[x['$pin']]['sha256']
        if isinstance(x,dict)and'$owned'in x:return authority['owned'][x['$owned']]['current_sha256']
        if isinstance(x,dict):return{k:value(v)for k,v in x.items()}
        if isinstance(x,list):return[value(v)for v in x]
        return x
    def refs(x):
        if isinstance(x,dict):
            if'$sha'in x:assert x['$sha']in seen,('FUTURE_NODE_REF',x)
            for v in x.values():refs(v)
        elif isinstance(x,list):
            for v in x:refs(v)
    def grouprefs(ident,stack):
        groups={g['id']:g for g in plan['source_groups']};assert ident not in stack;g=groups[ident]
        if g['kind']=='union':
            for child in g['groups']:grouprefs(child,stack+[ident])
        elif g['kind']=='node_dictionary':assert g['node']in seen,('FUTURE_GROUP_NODE',g)
        elif g['kind']=='explicit':refs(g['leaves'])
        elif g['kind']=='input_dictionary':assert g['input']in pins
        else:assert False,g
    for n in plan['nodes']:
        if n['kind']not in ['life_execution','life_fixed_code','life_frozen','index']:
            base=json.loads(raw(pins[n['base_input']]['path']));v=copy.deepcopy(base)
            if n['kind']=='map':
                v={'source_sha256':copy.deepcopy(base['source_sha256'])}
                for p in list(v['source_sha256']):
                    if p in authority['owned']:v['source_sha256'][p]=authority['owned'][p]['current_sha256']
            for op in n.get('operations',[]):
                ks=op['pointer'];holder=pointer(v,ks[:-1]);key=ks[-1]
                assert(key in holder)==op['existed']and(not op['existed']or strict(holder[key],op['old'])),('EXACT_OLD_POINTER',n['id'],ks)
                refs(op['new'])
                if op['op']=='remove':del holder[key]
                else:holder[key]=value(op['new'])
                checks+=1
            for field in n.get('source_fields',[]):
                pointer(base,field['pointer'])
                for g in field.get('groups',[]):grouprefs(g,[])
            for g in n.get('source_bundle',{}).get('groups',[])+n.get('groups',[]):grouprefs(g,[])
            for ks in n.get('protected_pointers',[]):pointer(base,ks)
            for op in n.get('life_declaration_operations',[]):
                ks=op['pointer'];holder=pointer(base,ks[:-1]);key=ks[-1];assert(key in holder)==op['existed']and(not op['existed']or strict(holder[key],op['old']));checks+=1
        elif n['kind']=='index':
            text=raw(pins[n['base_input']]['path']).decode()
            for h in n['replacements']:
                assert text.count(h['old'])==1,(n['id'],h['old']);refs(h['new']);text=text.replace(h['old'],str(value(h['new'])),1);checks+=1
        seen.add(n['id'])
    proof={'status':'UNIFIED100_WHOLE_DRIVER_INPUT_INVERSE_AND_TEXT_ONLY_PREFLIGHT_NOT_STAGE','driver':inverse_record(S+'stage_performance94_Docks_ordinary21_BUILD.py',S+'stage_unified100_BUILD.py'),'input':inverse_record(S+'performance94_Docks_candidate_identity_repair/source_input_NOTREADY.json',O+'source_input_NOTREADY.json'),'exact_old_pointer_and_index_literal_checks':checks,'all_node_and_group_references_topologically_prior':True,'nodes':len(plan['nodes']),'groups':len(plan['source_groups']),'no_Stage_constructor_or_hash_media_or_native_decode':True,'Root_lock_remains_pending':True}
    b=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();return{O+'driver_input_complete_byte_inverse_NOTREADY.json':b}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--start',type=int,default=0);p.add_argument('--length',type=int,default=16000);p.add_argument('--chunk',action='store_true');a=p.parse_args();outputs=prepare();path,b=next(iter(outputs.items()))
    print(json.dumps({'chunk':b.decode()[a.start:a.start+a.length]}if a.chunk else{'path':path,'sha256':sha(b),'length':len(b.decode())},ensure_ascii=True))
