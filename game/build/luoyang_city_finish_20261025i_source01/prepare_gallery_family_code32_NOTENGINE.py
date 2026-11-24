"""One actual local delta + approved System fixes; immutable authority20 parents only."""
from pathlib import Path
import argparse, json, hashlib, copy, difflib
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';Y='res://build/luoyang_city_finish_20261025i_system01/'
P=S+'docks_gallery_family_repair01/closure_READY01/';OUT=N/'docks_gallery_family_repair01/closure_READY01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p):
 b=(G/p['path'][6:]).read_bytes();assert sha(b)==p['sha256'].lower(),p;return b
def load(p):return json.loads(read(p))
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:100],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
 for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
 f,v=a,b
 for h in hs:f=exact(f,h['old'],h['new'])
 for h in reversed(hs):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return hs
ap=argparse.ArgumentParser();ap.add_argument('--promotion-path',required=True);ap.add_argument('--promotion-sha256',required=True);a=ap.parse_args()
promotion=dict(path=a.promotion_path,sha256=a.promotion_sha256);pv=load(promotion);assert pv['passed'] is True
scopepin=dict(path=S+'docks_gallery_family_repair01/current_authority20_exact32_scope_PREPARATION.json',sha256='e252869c32121af260b27d3b65fc85ce8590959035fcd47757da1675ab20a703');scope=load(scopepin)
parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
oldpin=dict(path=S+'market_ground25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4');oldbundle=load(oldpin);sealold=load(oldbundle['seal'])
priorcode=load(dict(path=S+'gate_texture_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='48f07dd62f7bdf452830d5345a386bef43497c537ab38a8092ea8400cba3ccd9'))
data={};records={}
def out(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(p):return data[p['path'][len(P):]]if p['path'].startswith(P)else read(p)
def record(p,name,b):
 old=read(parents[p]);assert old!=b;pin=out(name,b);records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(old,b),whole_byte_forward_inverse=True);return pin
actual=dict(path=S+'docks_gallery_retirement01/isolated_ROOT_READY02/output_ROOT_READY/37092/result.json',sha256='db47237fdf2839c34633708fb8d6bb8e5407a067da57c00e82bc168038d1f59b');av=load(actual);c=av['components']
assert av['passed'] and av['checks']==120 and av['source_first']==av['source_final'] and av['save_first']==av['save_final']
assert c['new_NAV_count']==43 and c['new_solid_count']==39 and c['mask_visited_pixels']==2928 and c['mask_changed_pixels']==630
binding=load(sealold['binding']);beforebinding=copy.deepcopy(binding);row=binding['scenes']['ch4_s2_canal_docks'];oldrow=copy.deepcopy(row)
assert row['payload']['sha256']=='e55b363b8ddb28c4f36e5b31accfb3dbc3212da8d656756f20b5f1c149d80136'
allowed={'effective_navigation','visual_additions','effective_solids','new_route_contracts'}
for k,h in row['fingerprints'].items():
 if k not in allowed:assert c['fingerprints'][k]==h,(k,h,c['fingerprints'][k])
row['payload']=c['payload'];row['fingerprints']=c['fingerprints'];row['mask']=copy.deepcopy(c['mask']);row['mask']['kind']='IMPORTED_RGBA8'
row['inherited_publication_completion']=copy.deepcopy(row['publication_completion']);row['publication_completion']=actual
media={}
for r in pv['written']:
 path=r['path'];assert path.startswith('res://');assert path not in media;media[path]=r['sha256'];read(dict(path=path,sha256=r['sha256']))
assert len(media)==2 and c['mask']['path']+'.import' in media
side=c['mask']['path']+'.import';text=read(dict(path=side,sha256=media[side])).decode();import re
ctex=re.findall(r'^path="(res://[^"\r\n]+)"\r?$',text,re.M);assert len(ctex)==1 and ctex[0] in media
row['mask']['import_path']=side;row['mask']['compiled_path']=ctex[0]
newsource={actual['path']:actual['sha256'],promotion['path']:promotion['sha256'],**media}
for pin in [c['payload'],c['geometry'],c['inverse'],c['mask']]:newsource[pin['path']]=pin['sha256']
for path in ['input_ROOT_READY.json','publish_delta_ROOT_READY.gd']:
 pinpath=S+'docks_gallery_retirement01/isolated_ROOT_READY02/'+path
 h={'input_ROOT_READY.json':'2c3162e10d18ab002bf5b26d61a0e6bbd0735c487d661b507c298d572b77f126','publish_delta_ROOT_READY.gd':'f2aaf8daf363ab68af4aaffbbe85569aeb8b428e0e54870321d58386d292b271'}[path];newsource[pinpath]=h
for path,fact in av['source_first'].items():
 assert fact['exists'] is True
 if path in row['required_source_sha256']:assert row['required_source_sha256'][path]==fact['sha256']
 else:newsource[path]=fact['sha256']
for path,h in newsource.items():read(dict(path=path,sha256=h));assert path not in row['required_source_sha256'];row['required_source_sha256'][path]=h
row['gallery_retirement_source_successor']=dict(actual=actual,promotion=promotion,retired_id='finish_i_docks_weighing_gallery',retired_solid_count=4,visited=2928,changed=630,source_foot_contract=[2140,1840],portal_before_after_unchanged=True,actual_Field_pass=False)
for sid in binding['scenes']:
 if sid!='ch4_s2_canal_docks':assert binding['scenes'][sid]==beforebinding['scenes'][sid]
bind=out('finish8_binding_READY.json',enc(binding))
system=Y+'family_direct_entry02_NOTREADY/'
# Every functional candidate is a human-approved exact pin; proof is verified independently below.
def functional(target,path,h,proofpath):
 pin=dict(path=path,sha256=h);b=read(pin);raw=(G/proofpath[6:]).read_bytes();proof=json.loads(raw);parent=proof['parent'];assert read(parent)==(read(parents[target])if target in parents else read(sealold['runtime']))
 f=read(parent)
 for step in proof['hunks']:f=exact(f,step['old'],step['new'])
 assert f==b;return b,dict(path=proofpath,sha256=sha(raw))
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';Q='res://scripts/city/luoyang_quarters_family_20261022ap.gd';EST='res://scripts/city/luoyang_estate_family_20261021am.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';ROUTER='res://scripts/autoload/scene_router.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
rb,rtproofpin=functional('__runtime__',system+'finish8_runtime_ferry2140_cold_discard_CANDIDATE.gd','b5d2b0b16fa2a64ac9fd7fedf1ff7340c8167cf94196319f0455aef7afdb8124',system+'finish8_runtime_full_inverse_BUILD.json')
for x,y in [(sealold['runtime']['path'],P+'finish8_runtime_READY.gd'),(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]:rb=exact(rb,x,y)
runtime=out('finish8_runtime_READY.gd',rb)
functionalproofs=[rtproofpin]
for target,name,h,pf in [(Q,'Quarter_pending_FIRST_cold_discard_CANDIDATE.gd','cd08ac4afe34988186ea191710318224c894e6340d9de31022d6a46e217428f8','Quarter_full_inverse_BUILD.json'),(EST,'Estate_pending_FIRST_cold_discard_CANDIDATE.gd','23e1e14fc1f77bd4629e8f7e33091245769a8f54cd04e9cb81bd59448693bffd','Estate_full_inverse_BUILD.json')]:
 b,pp=functional(target,system+name,h,system+pf);functionalproofs.append(pp)
 for x,y in [(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]:b=exact(b,x,y)
 record(target,target.split('/')[-1],b)
for target,name in [(C,'C_READY.gd'),(ENV,'ENV_READY.gd'),(F,'Field_READY.gd')]:
 b=read(parents[target])
 for x,y in [(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]:b=exact(b,x,y)
 record(target,name,b)
rp=Y+'family_direct_entry01_NOTREADY/';b,pp=functional(ROUTER,rp+'Router_family_direct_exactEOL_CANDIDATE.gd','e983a3b2b8c3cc031262100755c1f9e2f37c03a618d1a0a4cf268f8c6ccd3745',rp+'Router_family_direct_exactEOL_full_inverse_BUILD.json');functionalproofs.append(pp);record(ROUTER,'Router_READY.gd',b)
original=load(dict(path=S+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200'));ordinary=[]
def ordinary_successor(consumer,target,stem,edits):
 prior=next(r['proof']for r in priorcode['ordinary']if r['target']==target);proof=load(prior);v=copy.deepcopy(proof)
 for step in v['replacements']:
  for x,y in edits:
   if x in step['new']:step['new']=step['new'].replace(x,y)
 v['new_sha256']=records[target]['candidate']['sha256'];fixed=read(original['records'][target]['parent']);f=fixed;back=value(records[target]['candidate'])
 for h in v['replacements']:f=exact(f,h['old'],h['new'])
 for h in reversed(v['replacements']):back=exact(back,h['new'],h['old'])
 assert f==value(records[target]['candidate'])and back==fixed and len(v['replacements'])==len(proof['replacements'])
 np=out(stem+'_ordinary_to_fixed25h_READY.json',enc(v));b=read(parents[consumer]);changes=[]
 for x,y in [(proof['new_sha256'],v['new_sha256']),(prior['path'],np['path']),(prior['sha256'],np['sha256'])]:b=exact(b,x,y);changes.append((x,y))
 record(consumer,stem+'_consumer_READY.gd',b);ordinary.append(dict(consumer=consumer,target=target,proof=np,parent=prior,inner_gate_replacement_counts_unchanged=True,old_inner_chain_unchanged=True));return changes
edits=ordinary_successor(AA,C,'C',[(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]);ordinary_successor(AC,AA,'AA',edits)
raw=read(parents[CT]);v=json.loads(raw);b=raw;changes={}
for p in [C,F]:
 old=v['source_sha256'][p];assert old==parents[p]['sha256'];v['source_sha256'][p]=records[p]['candidate']['sha256'];b=exact(b,old,v['source_sha256'][p]);changes[p]=dict(old=old,new=v['source_sha256'][p])
assert json.loads(b)==v;contract=dict(parent=parents[CT],candidate=out('runtime_contract_C_Field_READY.json',b),changes=changes,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
tbparent=oldbundle['temple_binding']['candidate'];raw=read(tbparent);v=json.loads(raw);b=raw;changes={}
for p,h in {C:records[C]['candidate']['sha256'],F:records[F]['candidate']['sha256'],CO:records[CO]['candidate']['sha256'],CT:contract['candidate']['sha256']}.items():
 old=v['source_delta'][p];assert old==parents[p]['sha256'];v['source_delta'][p]=h;b=exact(b,json.dumps(p)+': '+json.dumps(old),json.dumps(p)+': '+json.dumps(h));changes[p]=dict(old=old,new=h)
assert json.loads(b)==v;tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=changes,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
b=read(parents[T])
for x,y in [(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256']),(tbparent['path'],tb['candidate']['path']),(tbparent['sha256'],tb['candidate']['sha256'])]:b=exact(b,x,y)
record(T,'Temple_READY.gd',b)
prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==195;new=copy.deepcopy(prior);changed=[F,CO,T,AC,ROUTER]
for p in changed:
 owner=new['owned'][p];r=records[p];assert owner['current_sha256']==parents[p]['sha256'];snapshot=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(dict(path=snapshot,sha256=owner['current_sha256']))==read(parents[p])
 owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for pin in [contract['candidate'],tb['candidate']]:new['source_sha256'][pin['path']]=pin['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==7 and len(new['source_sha256'])==202 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(new)
for p in changed:back['owned'][p]=copy.deepcopy(prior['owned'][p])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX]);assert new['source_sha256']['res://scripts/city/luoyang_execution_authority_20261022ap.gd']=='f120512a771d7e3e482b5befac0f39d44fb0abf794be0805fcd0fe4e638bb5bc'
execution=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=changed,owned_count=10,old_proof_count=195,new_proof_count=202,extra=extra,old195_values_all_edges_retained=True,authority_F120_unchanged=True,no_shortcut=True,whole_typed_UTF8_inverse=True)
seal=copy.deepcopy(sealold);seal.update(status='ONE_GALLERY_FOUR_POSTS_FERRY_CONTRACT_AND_STRICT_FAMILY_ROUTER_SOURCE_SUCCESSOR',runtime=runtime,binding=bind,Field=records[F]['candidate'],records={p:r for p,r in records.items()if p in [C,Q,EST,ENV,T]},functional_proofs=functionalproofs,local_actual=actual,new_mask_promotion=promotion)
seal['runtime_function_bytes_unchanged']=False;seal['runtime_and_binding_unchanged_from_5D6C']=False;seal['runtime_and_binding_unchanged_from_closure01']=False;seal['runtime_header_changes']=[dict(old=x,new=y)for x,y in [(sealold['runtime']['path'],runtime['path']),(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]]
seal['binding_inverse']=dict(parent=sealold['binding'],changed_scene_only='ch4_s2_canal_docks',old_scene=oldrow,new_scene=row,new_source_leaves=newsource,all_other_scenes_whole_typed_unchanged=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
cp=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT_AUTHORITY20_FIVE_OWNED_SUCCESSORS_GALLERY_FAMILY_ROUTER_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,functional_proofs=functionalproofs,local_actual=actual,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)))
assert len(records)==10 and not OUT.exists();OUT.mkdir()
for name,b in data.items():
 with(OUT/name).open('xb')as f:f.write(b)
print(json.dumps(dict(code=cp,seal=sealpin,Field=records[F]['candidate'],runtime=runtime,binding=bind,records={p:r['candidate']for p,r in records.items()},execution=execution['candidate'])))
