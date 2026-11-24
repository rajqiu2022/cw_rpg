"""Exact fixed metadata-edge repair, no runtime observation used as authority."""
from pathlib import Path
import json,hashlib,copy,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261024e_root01/'
OUT=HERE/'finite_AP_header2_candidate01'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;return b
def load(p,h):return json.loads(read(p,h))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def put(name,b):
    with (OUT/name).open('xb') as f:f.write(b)
    return dict(path=S+OUT.name+'/'+name,sha256=sha(b),bytes=len(b))
def delta(a,b):
    aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);ds=[]
    for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
        if tag!='equal':ds.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
    f,inv=a,b
    for d in reversed(ds):
        i=d['old_offset'];x,y=d['old'].encode(),d['new'].encode();assert f[i:i+len(x)]==x;f=f[:i]+y+f[i+len(x):]
        i=d['new_offset'];assert inv[i:i+len(y)]==y;inv=inv[:i]+x+inv[i+len(y):]
    assert f==b and inv==a;return ds
parent_scope_path=S+'wall_tuple3_candidate01/scope_exact3_NOT_STAGE.json'
parent_scope_sha='169977910700189d46a6b0146368357bc2b0416e64daaf8f5dee10e1fb2281b4'
scope=load(parent_scope_path,parent_scope_sha)
dep_path=R+'wall_tuple3_deployed_actual.json';dep_sha='3550aa2efa1eedc4ba97a353bb085d992ce8507a306d01923199962312d08d78'
dep=load(dep_path,dep_sha);assert dep['targets']==scope['targets']
priorproof_path=S+'wall_tuple3_candidate01/whole_inverse_and_expected_maps_NOT_STAGE.json'
priorproof_sha='8fe178585bac34ca67e7f8c25291db11396a0bbf7f9652d0a87d3c2733a4f914'
proof=load(priorproof_path,priorproof_sha)
AP='res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json'
FINITE='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/runtime_market_manifest_READY.json'
INDEX='res://scripts/city/luoyang_full_city_index_20261022ap.gd'
rows={r['target']:r for r in scope['targets']};assert set(rows)=={AP,FINITE,INDEX}
assert not OUT.exists();OUT.mkdir()
oldrow=rows[FINITE]['candidate'];old=read(oldrow['path'],oldrow['sha256']);v=json.loads(old);assert enc(v)==old
old_ap=proof['records']['market_final']['parent']['sha256'];new_ap=rows[AP]['candidate']['sha256']
assert old_ap=='694431199ee6b9b335c6b5f6e1bc29b4d763500ef7554fcfdfc73587717f5a22'
assert new_ap=='f0df3f05a7f9382507ca92d3174c62bc1358187d50374050f975c347f8f89165'
assert v['runtime_authority_sha256'][AP]==old_ap
candidate=copy.deepcopy(v);candidate['runtime_authority_sha256'][AP]=new_ap
inverse=copy.deepcopy(candidate);inverse['runtime_authority_sha256'][AP]=old_ap
assert inverse==v and enc(inverse)==old
raw=enc(candidate);fc=put('finiteMarket_AP_manifest_SHA_CANDIDATE.json',raw)
records={FINITE:dict(target=FINITE,parent=oldrow,candidate=fc,byte_hunks=delta(old,raw),sole_pointer=['runtime_authority_sha256',AP],old_value=old_ap,new_value=new_ap,whole_typed_ordered_UTF8_inverse=True)}
oldrow=rows[INDEX]['candidate'];old=read(oldrow['path'],oldrow['sha256']);before=rows[FINITE]['candidate']['sha256'].encode();assert old.count(before)==1
raw=old.replace(before,fc['sha256'].encode());ic=put('APCityIndex_finite_header_SHA_CANDIDATE.gd',raw)
records[INDEX]=dict(target=INDEX,parent=oldrow,candidate=ic,byte_hunks=delta(old,raw),sole_finite_manifest_SHA_literal=True,whole_byte_inverse=True)
map_records={};replacements={FINITE:fc['sha256'],INDEX:ic['sha256']}
for ident,row in proof['maps'].items():
    original=load(row['path'],row['sha256']);updated=copy.deepcopy(original);changes={}
    for p,h in replacements.items():
        if p in updated['source_sha256']:changes[p]=dict(old=updated['source_sha256'][p],new=h);updated['source_sha256'][p]=h
    inv=copy.deepcopy(updated)
    for p,d in changes.items():inv['source_sha256'][p]=d['old']
    assert inv==original and enc(inv)==enc(original)
    assert len(updated['source_sha256'])==row['count']
    if ident=='expected_ch4_s3_luoyang_market_true':assert updated['source_sha256'][AP]==new_ap and len(changes)==2
    else:assert len(changes)==1 and set(changes)=={INDEX}
    pin=put(ident+'.json',enc(updated));map_records[ident]=dict(**pin,count=row['count'],changed_existing_values=changes,no_new_keys=True,whole_typed_ordered_UTF8_inverse=True)
# Reconstruct the exact B.describe formula from the repaired manifest plus fixed
# eight index/header leaves. This catches the edge missed in tuple3's static proof.
maprow=map_records['expected_ch4_s3_luoyang_market_true'];market=load(maprow['path'],maprow['sha256'])['source_sha256']
formula=copy.deepcopy(candidate['legacy_source_sha256']);formula.update(candidate['runtime_authority_sha256']);formula.update(candidate['artifacts'])
for p in ['res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd','res://scripts/city/luoyang_estate_index_20261021am.gd','res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd',INDEX,'res://scripts/city/luoyang_environment_index_20261022ap.gd','res://scripts/city/luoyang_execution_index_20261022ap.gd','res://scripts/city/luoyang_quarters_index_20261022ap.gd','res://scripts/city/luoyang_market_ground_index_20261020ae.gd']:formula[p]=market[p]
formula[FINITE]=fc['sha256'];assert formula==market and len(formula)==1853
scope2=dict(status='EXACT2_FINITE_AP_MANIFEST_EDGE_CANDIDATES_NOT_DEPLOYED',parent_deployment=dict(path=dep_path,sha256=dep_sha),parent_scope=dict(path=parent_scope_path,sha256=parent_scope_sha),target_count=2,targets=[dict(target=p,old_sha256=r['parent']['sha256'],old_bytes=r['parent']['bytes'],candidate=r['candidate']) for p,r in records.items()],partition=dict(GD_literal_patch=1,JSON_exact_copy=1),APMarket_unchanged=rows[AP]['candidate'],no_key_domain_changes=True,no_owned_code_proof_native_media_changes=True)
sp=put('scope_exact2_NOT_DEPLOYED.json',enc(scope2))
result=dict(status='EXACT2_FINITE_AP_MANIFEST_EDGE_WHOLE_INVERSE_NOT_DEPLOYED',scope=sp,records=records,maps=map_records,B_formula_vs_independent_Market_exact=True,Market_count=1853,authority='Fixed tuple3 candidates/3550 deployed parent; AP newSHA from immutable APMarket candidate, not actual observation fill.',all_prior_failures_preserved=True,engine_calls=0,collector_calls=0,canonical_writes=0)
pp=put('whole_inverse_and_expected_maps_NOT_DEPLOYED.json',enc(result))
# Direct apply_patch transport: one existing literal, no EOL normalization.
idx=records[INDEX];a=read(idx['parent']['path'],idx['parent']['sha256']).decode();b=read(idx['candidate']['path'],idx['candidate']['sha256']).decode()
diff=list(difflib.unified_diff(a.splitlines(keepends=True),b.splitlines(keepends=True),n=3));body=''.join('@@\n' if line.startswith('@@') else line for line in diff[2:]);patch='*** Begin Patch\n*** Update File: game/'+INDEX[6:]+'\n'+body+'*** End Patch\n'
ap=put('APCityIndex_exact1literal.apply_patch',patch.encode())
print(json.dumps(dict(scope=sp,proof=pp,index_patch=ap,targets=scope2['targets'],maps={k:dict(path=v['path'],sha256=v['sha256'],count=v['count']) for k,v in map_records.items()})))
