"""Pure small JSON/GD candidate/classification inverse, no Stage or producer import."""
import copy,hashlib,json,pathlib,re
G=pathlib.Path(__file__).resolve().parents[2];S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=raw(p);assert h is None or sha(b)==h,p;return json.loads(b)
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def ptr(v,keys):
    for k in keys:v=v[k]
    return v
base=S+'unified102_ordinary_source_classification_BUILD/'
scope=read(base+'exact15_scope_NOTREADY.json','668ab97fd42f7682e808b8314b00798ba26833751cad8649b64f11df5a4ec05b')
proof=read(base+'cause_and_complete_inverse_NOTREADY.json','052345618c94f2c7ed0d8d8c705b1de4a2f8b1f0b6ebd56d56df168f9790d94a')
owner=read(S+'unified101_actual_owner_READY/owner_source_maps_READY.json','fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c')
binding=read(proof['fixed_adapter_binding']['path'],'dc21bb2a5e8d4e1af6944d6a6fe6c864caf29702e4b17b44063ed2369f53ecff')
actual=read(S+'outputs/root_unified_life_garden_scholar28_stage01/receipt.json','4ce21902185a78f6c441f8ee8d63d30b30a7c31c61f135b5df13322bc266d945')
assert scope['target_count']==len(scope['targets'])==len(proof['records'])==15 and scope['counts']=={'GD':5,'JSON':10}
targets={r['target']:r for r in scope['targets']};records={r['id']:r for r in proof['records']};hash_delta={};allfiles={};metadata=[];indexes=[]
for t in scope['targets']:
    c=t['candidate'];oldbytes=raw(t['old_snapshot']);newbytes=raw(c['candidate_path'])
    assert t['old_sha256']==sha(oldbytes)==owner['core_source_sha256'][t['target']]
    assert c['old_sha256']==t['old_sha256']and c['target']==t['target']and sha(newbytes)==c['candidate_sha256']and len(newbytes)==c['candidate_bytes']
    assert sha(newbytes)!=sha(oldbytes)
    hash_delta[t['target']]={'old':sha(oldbytes),'new':sha(newbytes)};allfiles[t['target']]=(oldbytes,newbytes)
for ident,r in records.items():
    t=targets[r['target']];oldbytes,newbytes=allfiles[r['target']]
    assert r['old_sha256']==t['old_sha256']and r['old_snapshot']==t['old_snapshot']and same(r['candidate'],t['candidate'])
    if r['target'].endswith('.json'):
        old=json.loads(oldbytes);new=json.loads(newbytes);v=copy.deepcopy(new)
        moves=r['class_moves_same_sha256'];replacement=r['source_value_replacements']
        independent_bad={p:h for p,h in old['runtime_authority_sha256'].items()if p.startswith(R)and p not in binding['domains']['market'if ident=='finite08_market'else'yamen']['runtime_authority_paths']}
        assert moves==independent_bad,(ident,'PREEXISTING_STRICT_AUTHORITY_REJECT_EXACT_SET')
        assert len(moves)==(12 if ident in('market_final','finite08_market')else 1)
        for p,h in moves.items():
            assert p not in old['legacy_source_sha256']and p not in new['runtime_authority_sha256']and new['legacy_source_sha256'][p]==h
            assert p.startswith('res://')and '..'not in p and not p.startswith('res://data/maps/luoyang_layout_bundle_20261018t_retry2/')and re.fullmatch('[0-9a-f]{64}',h)
            assert p in old['runtime_authority_sha256']and old['runtime_authority_sha256'][p]==h
        assert set(old['legacy_source_sha256'])|set(old['runtime_authority_sha256'])|set(old['artifacts'])==set(new['legacy_source_sha256'])|set(new['runtime_authority_sha256'])|set(new['artifacts'])
        for delta in reversed(replacement):
            keys=delta['pointer'];holder=ptr(v,keys[:-1]);k=keys[-1]
            assert holder[k]==delta['new']and delta['old']==hash_delta[k]['old']and delta['new']==hash_delta[k]['new']
            assert keys[0]in('legacy_source_sha256','runtime_authority_sha256');holder[k]=delta['old']
        for p,h in moves.items():assert v['legacy_source_sha256'].pop(p)==h;v['runtime_authority_sha256'][p]=h
        v['legacy_source_sha256']={k:v['legacy_source_sha256'][k]for k in r['old_legacy_key_order']}
        v['runtime_authority_sha256']={k:v['runtime_authority_sha256'][k]for k in r['old_authority_key_order']}
        assert same(v,old),(ident,'COMPLETE_TYPED_INVERSE')
        assert json.dumps(v,ensure_ascii=False,indent=2).encode()==json.dumps(old,ensure_ascii=False,indent=2).encode(),(ident,'ORDERED_SERIALIZED_UTF8_INVERSE')
        # Independently ensure classification+declared dependent header values is the entire change.
        predicted=copy.deepcopy(old)
        for p,h in moves.items():assert predicted['runtime_authority_sha256'].pop(p)==h;predicted['legacy_source_sha256'][p]=h
        for delta in replacement:ptr(predicted,delta['pointer'][:-1])[delta['pointer'][-1]]=delta['new']
        assert same(predicted,new)
        if ident.startswith('finite08_'):
            domain='market'if ident.endswith('market')else'yamen'
            assert not[p for p in new['runtime_authority_sha256']if p.startswith(R)and p not in binding['domains'][domain]['runtime_authority_paths']]
        metadata.append({'id':ident,'same_SHA_class_moves':len(moves),'existing_header_value_updates':len(replacement),'complete_typed_ordered_UTF8_inverse':True,'union_keyset_unchanged':True})
    else:
        v=oldbytes
        for h in r['hunks']:
            pair=next(x for x in hash_delta.values()if x['old']==h['old']and x['new']==h['new'])
            assert v.count(h['old'].encode())>=1;v=v.replace(h['old'].encode(),h['new'].encode())
        assert v==newbytes,(ident,'FULL_INDEX_FORWARD')
        for h in reversed(r['hunks']):v=v.replace(h['new'].encode(),h['old'].encode())
        assert v==oldbytes,(ident,'FULL_INDEX_BYTE_INVERSE')
        indexes.append({'id':ident,'only_existing_manifest_SHA_literal_replacements':len(r['hunks']),'whole_byte_inverse':True})
assert len(metadata)==10 and len(indexes)==5
assert set(targets)=={r['target']for r in actual['targets']if r['target']in targets}
assert not any(p.endswith('/execution_successor.json')or p.endswith('/registry.json')or p.endswith('/runtime_contract.json')for p in targets)
scenes=copy.deepcopy(owner['scenes']);core=copy.deepcopy(owner['core_source_sha256']);rooms=copy.deepcopy(owner['rooms'])
counts={};changed={}
for r in scenes+rooms:
    count=0
    for field in('source_sha256','receipt_source_sha256'):
        before=owner['scenes'if r in scenes else'rooms'] # No runtime source calls.
        for p,v in hash_delta.items():
            if p in r[field]:assert r[field][p]==v['old'];r[field][p]=v['new'];count+=1
    changed[r['id']]=count
    if r in scenes:counts[r['id']]={'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}
for p,h in hash_delta.items():assert core[p]==h['old'];core[p]=h['new']
assert [counts[i]['collector']for i in('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')]==[904,1255,1734,1741]
assert all(a['receipt_source_sha256']==b['receipt_source_sha256']for a,b in zip(rooms,owner['rooms']))
print(json.dumps({'status':'UNIFIED102_EXACT15_CLASSIFICATION_CANDIDATES_STATIC_NO_BLOCKER_NOT_STAGE_OR_RUNTIME_PASS','scope_SHA':'668ab97fd42f7682e808b8314b00798ba26833751cad8649b64f11df5a4ec05b','proof_SHA':'052345618c94f2c7ed0d8d8c705b1de4a2f8b1f0b6ebd56d56df168f9790d94a','10metadata':metadata,'5indices':indexes,'predicted_owner_from_fixed_FD58_only15existing_SHA_values_no_new_keys':True,'all_scene_counts_unchanged':counts,'core_count':len(core),'five_room_receipts_whole_frozen':True,'old_execution101_runtimecode_and_native_not_targets':True,'B_original_allowlist_and_legacy_rule_not_changed':True,'causality_scope':'Exact prior manifest classification reject is removed statically. Does not prove later runtime gates/Field/artwork pass. No engine/Stage/collector/packet/image/media hash/current expected fill.'},indent=2))
