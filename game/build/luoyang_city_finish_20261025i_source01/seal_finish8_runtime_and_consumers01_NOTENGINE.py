"""Root facts -> exact candidate binding/headers only. No engine, Stage or canonical writes."""
from pathlib import Path
import json,hashlib,re,copy
N=Path(__file__).resolve().parent;G=N.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
SYS='res://build/luoyang_city_finish_20261025i_system01/'
OUT=N/'runtime_READY01';PREFIX=NS+'runtime_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def physical(p):return G/p.removeprefix('res://')
def checked(p,h):
    b=physical(p).read_bytes();assert sha(b)==h,(p,h,sha(b));return b
prepared={}
def emit(name,b):
    assert name not in prepared;prepared[name]=b
    return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def load(pin):return json.loads(checked(pin['path'],pin['sha256']))
publication=dict(path=NS+'publication11/output_ROOT_READY/109200/result.json',sha256='f4925d3ff6e57900a0f7ac0c1549b9477fe9ce3ad255882096a3cd956222df66')
pub=load(publication);assert pub['passed'] is True and pub['complete'] is True and len(pub['scenes'])==8 and pub['source_first']==pub['source_final']
trial=dict(path=NS+'finish8_ROOT_TRIAL_PERMISSION01.json',sha256='e4da07475a77c31b4bcee99c75dfa226eca5baaf4723bd4f3530b1979b8065cb')
tv=load(trial);assert tv['admitted'] is True and tv['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT' and tv['actual_Field_pass'] is False
promotion=dict(path=SYS+'qa_role_new/finish7_mask_media_promotion07_ROOT_ONLY/promotion_ROOT_EXECUTED.json',sha256='aba31957cb919a94a6138b39f253c48cd390e486e989cb3ac979a36d47806d3b')
media=load(promotion);assert media['passed'] is True and len(media['written'])==14
media_pins={r['path']:r['sha256'] for r in media['written']};assert len(media_pins)==14
root30=dict(path='res://build/luoyang_city_finish_20261025i_art01/ten_media30_promotion_ROOT_EXECUTED.json',sha256='43289bd6757cb470cdafb955658a386b04faea0143a91d18916fd76461d798a1')
r30=load(root30);assert r30['passed'] is True and len(r30['written'])==30
stagepin=dict(path='res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json',sha256='ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5')
stage=load(stagepin);authority={}
def merge(dst,src):
    for p,h in src.items():assert p not in dst or dst[p]==h,(p,dst.get(p),h);dst[p]=h
for k,node in stage['nodes'].items():
    if k.startswith('expected_') and isinstance(node.get('value'),dict):merge(authority,node['value'].get('source_sha256',{}))
for row in stage['targets']:authority[row['target']]=row['candidate_sha256']
declared=dict(authority);merge(declared,pub['source_first']);merge(declared,media_pins)
for row in r30['written']:
    p='res://'+Path(row['path']).resolve().relative_to(G.resolve()).as_posix()
    merge(declared,{p:row['sha256']})
for pin in [publication,trial,promotion,root30]:declared[pin['path']]=pin['sha256']
inp_path=NS+'finish8_publication_input11_ROOT_READY.json'
inp=json.loads(physical(inp_path).read_text(encoding='utf-8'))
assert sha(physical(inp_path).read_bytes())=='d6aea52568f7c066a8d59c2c83573efa5edec2fba9c285764086c4a54c4f2ece'
scene_specs={r['id']:r for r in inp['scenes']}
axis_path=NS+'author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json'
axis_library_path=NS+'axis_infill_asset_library05_processed_kitchen_SOURCE_ONLY.json'
adj_path=NS+'author_adjacent_four_fields07_final_dry_bank_routes_NOTREADY.json'
adj_library_path=NS+'adjacent_adopted_asset_library03_SOURCE_ONLY.json'
axis=json.loads(checked(axis_path,declared[axis_path]));axis_lib=json.loads(checked(axis_library_path,declared[axis_library_path]))
adj=json.loads(checked(adj_path,declared[adj_path]));adj_lib=json.loads(checked(adj_library_path,declared[adj_library_path]))
processed_path='res://build/luoyang_city_finish_20261025i_art01/three_buildings_processed_source_declarations01_CANDIDATE.json'
processed=json.loads(checked(processed_path,declared[processed_path]))
binding=json.loads(physical(SYS+'finish8_binding03_NOTREADY.json').read_text(encoding='utf-8'))
binding['ready']=True;binding['status']='ROOT_READY_EXACT_EIGHT_FIELD_OVERLAY_TRIAL_NOT_RESULT'
binding['publication']=publication;binding['media_promotion']=promotion
binding['limits']={'actual_Field_pass':False,'whole_city_ART_pass':False,'loading_target_pass':False,'new_OWNED_members':0,'old_native_storage_changed':False}
def add_source(dst,p):
    assert p in declared,('NO_FIXED_SOURCE_AUTHORITY',p)
    merge(dst,{p:declared[p]})
def tuple_for(dst,p):
    add_source(dst,p);side=p+'.import';add_source(dst,side)
    text=checked(side,declared[side]).decode('utf-8')
    remaps=re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$',text,re.M)
    assert remaps and re.findall(r'^source_file="([^"\r\n]+)"\r?$',text,re.M)==[p]
    for cp in remaps:assert cp.endswith('.ctex');add_source(dst,cp)
    return dict(path=p,compiled_paths=sorted(set(remaps)))
texture_roots={}
for id,component in pub['scenes'].items():
    row=binding['scenes'][id];sources={}
    for pin in [publication,trial,promotion,component['payload'],component['geometry']]:merge(sources,{pin['path']:pin['sha256']})
    row['payload']=component['payload'];row['fingerprints']=component['fingerprints']
    row['publication_completion']=publication;row['trial']={**trial,'admitted':True,'permission_kind':'TRIAL_PERMISSION_NOT_RESULT','actual_Field_pass':False}
    prior_key='artisan' if 'artisan_residential' in id else 'temple' if id=='ch4_s4_ancient_temple' else 'residual'
    prior=inp['priors'][prior_key]
    row['independent_prior']={k:prior[k] for k in ['path','sha256']};add_source(sources,prior['path'])
    if prior.get('geometry_path'):add_source(sources,prior['geometry_path'])
    if id=='ch4_s4_ancient_temple':row['mask']={'kind':'SOURCE_POLYGON_ONLY'}
    else:
        m=component['mask'];side=m['path']+'.import'
        remaps=re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$',checked(side,media_pins[side]).decode('utf-8'),re.M)
        assert len(set(remaps))==1 and remaps[0] in media_pins
        row['mask']={'kind':'IMPORTED_RGBA8','path':m['path'],'sha256':m['sha256'],'RGBA_sha256':m['RGBA_sha256'],'import_path':side,'compiled_path':remaps[0]}
        merge(sources,{m['path']:m['sha256'],side:media_pins[side],remaps[0]:media_pins[remaps[0]]})
    spec=scene_specs[id];original={}
    for p in [spec['parent_scene'],spec['parent_layout']]:
        assert p in authority and declared[p]==authority[p]
        original[p]=authority[p];add_source(sources,p)
    row['required_original_source_sha256']=original
    for p in [inp['source_views'],inp['payload_builder']]:add_source(sources,p)
    textures=set()
    if id in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen']:
        for p in [axis_path,axis_library_path,inp['axis_helper'],inp['binary_inputs']['parent_seed']]:add_source(sources,p)
        source=next(s for s in axis['scenes'] if s['scene_id']==id)
        for placement in source['placements']:textures.add(axis_lib['assets'][placement['asset_id']]['texture'])
    elif id=='luoyang_artisan_residential_20261022ap':
        for p in [inp['artisan_helper'],inp['json_inputs']['artisan_author'],inp['json_inputs']['artisan_old_author'],inp['json_inputs']['artisan_life_author'],processed_path]:add_source(sources,p)
        # Exact three adopted full PNGs, never raw BUILD paths or new canvas fits.
        textures.update('res://art/modules/luoyang_city_finish_20261025i/'+name+'.png' for name in ['chinese_open_ironwork_v2','pottery_kiln_house_v2','ordinary_kitchen_rear_body_v2'])
    elif id=='ch4_s4_ancient_temple':
        for p in [inp['temple_builder'],inp['json_inputs']['temple_author'],inp['json_inputs']['temple_old_author']]:add_source(sources,p)
        ta=json.loads(checked(inp['json_inputs']['temple_author'],declared[inp['json_inputs']['temple_author']]))
        # Temple source contract captures all its actual authored textures.
        textures.update(r['texture'] for r in ta['assets'])
    else:
        for p in [adj_path,adj_library_path,inp['adjacent_helper']]:add_source(sources,p)
        source=next(s for s in adj['scenes'] if s['scene_id']==id)
        for placement in source['placements']:textures.add(adj_lib['assets'][placement['asset_id']]['texture'])
        if id=='luoyang_estate_riverside_20261021ai':
            textures.add('res://art/modules/luoyang_city_finish_20261025i/ordinary_kitchen_rear_body_v2.png');add_source(sources,processed_path)
    roots=[]
    for texture in sorted(textures):roots.append(tuple_for(sources,texture))
    texture_roots[id]=roots
    row['required_source_sha256']=sources
    row['new_whole_typed_inverse']=True;row['actual_Field_pass']=False
    for p,h in sources.items():checked(p,h)
bindingpin=emit('finish8_binding_READY.json',enc(binding))

mechanical=[]
def seal_text(path,pin,name,changes):
    old=checked(path,pin);text=old.decode('utf-8');hunks=[]
    for before,after in changes:
        assert text.count(before)==1,(name,before,text.count(before));text=text.replace(before,after);hunks.append(dict(old=before,new=after))
    back=text
    for h in reversed(hunks):back=back.replace(h['new'],h['old'])
    assert back.encode('utf-8')==old
    result=emit(name,text.encode('utf-8'));mechanical.append(dict(parent=dict(path=path,sha256=pin),candidate=result,hunks=hunks,whole_byte_inverse=True))
    return result
ambient_path=PREFIX+'ambient18_runtime_READY.gd'
ambient=seal_text(SYS+'ambient18_runtime05_family_receipt_NOTREADY.gd','db339bcb7b5a734a24116f4d73bafb936d075bef445babe7d454d36394da984a','ambient18_runtime_READY.gd',[
 ('const FORMAL_READY := false','const FORMAL_READY := true'),
 (SYS+'ambient18_runtime04_NOTREADY.gd',ambient_path)])
runtime_path=PREFIX+'finish8_runtime_READY.gd'
runtime=seal_text(SYS+'finish8_runtime07_NOTREADY.gd','fec8a4e79478c2767941d79c7398f1df635e4e3498589558f74d4008ba9f94be','finish8_runtime_READY.gd',[
 ('const FORMAL_READY := false','const FORMAL_READY := true'),(SYS+'finish8_runtime07_NOTREADY.gd',runtime_path),
 (SYS+'finish8_binding03_NOTREADY.json',bindingpin['path']),('PENDING_ROOT_FINAL_BINDING_SHA',bindingpin['sha256'])])
field=seal_text(SYS+'Field_finish8_ambient_toast08_CANDIDATE.gd','b6022da44db1305b5d18ece7c7f497da2db848dbd66a113a0b946cb9cbfcd49b','Field_READY.gd',[
 (SYS+'finish8_runtime07_NOTREADY.gd',runtime['path']),('fec8a4e79478c2767941d79c7398f1df635e4e3498589558f74d4008ba9f94be',runtime['sha256']),
 (NS+'original_owner_receipts02_source_arrays_NOTREADY.gd',NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd'),('a427abf67f581e6970135cc4c1fe88393c1db99e9a9cf00b69eaf1dd5f30380a','9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5'),
 (SYS+'ambient18_runtime04_NOTREADY.gd',ambient['path']),('44514521029882f84241cc24dce1ae8311e1564b4494fba5274172b29a49fe44',ambient['sha256'])])
consumer_proofs=['C_finish8_exact_ambient_scope03_direct_formal_inverse_BUILD.json','Quarter_finish8_consumer02_direct_formal_whole_inverse_BUILD.json','Estate_finish8_exact_ambient_scope03_direct_formal_inverse_BUILD.json','G_finish8_artisan_returns01_whole_inverse_BUILD.json','Temple_finish8_purpose_source01_whole_inverse_BUILD.json','ENV_finish8_purpose_source01_whole_inverse_BUILD.json']
records={}
for proofname in consumer_proofs:
    proof=json.loads((N/proofname).read_text(encoding='utf-8'));p=proof['candidate'];old=checked(p['path'],p['sha256']);text=old.decode('utf-8');edits=[]
    def change(before,after):
        nonlocal_placeholder=None
        global text
        assert text.count(before)==1,(proofname,before,text.count(before));text=text.replace(before,after);edits.append(dict(old=before,new=after))
    flag='FINISH25I_RETURNS_ENABLED' if proofname.startswith('G_') else 'FINISH25I_ENABLED'
    change('const '+flag+': bool=false','const '+flag+': bool=true')
    if not proofname.startswith('G_'):
        change(SYS+'finish8_runtime07_NOTREADY.gd',runtime['path']);change('fec8a4e79478c2767941d79c7398f1df635e4e3498589558f74d4008ba9f94be',runtime['sha256'])
    for oldpath,oldhash in [(SYS+'ambient18_runtime04_NOTREADY.gd','44514521029882f84241cc24dce1ae8311e1564b4494fba5274172b29a49fe44'),(SYS+'ambient18_runtime05_family_receipt_NOTREADY.gd','db339bcb7b5a734a24116f4d73bafb936d075bef445babe7d454d36394da984a')]:
        if oldpath in text:change(oldpath,ambient['path']);change(oldhash,ambient['sha256'])
    hunks=[]
    for h in proof['hunks']:
        value=h['new']
        for e in edits:
            if e['old'] in value:value=value.replace(e['old'],e['new'])
        hunks.append(dict(old=h['old'],new=value))
    parent=checked(proof['target'],proof['parent_sha256']);forward=parent.decode('utf-8')
    for h in hunks:assert forward.count(h['old'])==1;forward=forward.replace(h['old'],h['new'])
    assert forward==text
    back=text
    for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
    assert back.encode('utf-8')==parent
    c=emit(proofname.split('_')[0]+'_READY.gd',text.encode('utf-8'))
    records[proof['target']]=dict(parent_sha256=sha(parent),parent_bytes=len(parent),candidate=c,hunks=hunks,whole_byte_forward_inverse=True,mechanical_edits=edits)
proof=emit('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(dict(status='ROOT_FACTS_MECHANICAL_READY_NOT_PARSE_NOT_STAGE',binding=bindingpin,runtime=runtime,ambient=ambient,Field=field,records=records,mechanical=mechanical,texture_roots=texture_roots,publication=publication,Root_media14=promotion,Root_trial=trial,original8_sources_only_immutable_subset=True,engine_calls=0,Stage_calls=0,canonical_writes=0)))
assert not OUT.exists();OUT.mkdir()
for name,b in prepared.items():
    dest=OUT/name;dest.parent.mkdir(parents=True,exist_ok=True)
    with dest.open('xb') as f:f.write(b)
print(json.dumps(dict(proof=proof,binding=bindingpin,runtime=runtime,ambient=ambient,Field=field,consumers={p:r['candidate'] for p,r in records.items()},source_counts={id:len(row['required_source_sha256'])for id,row in binding['scenes'].items()})))
