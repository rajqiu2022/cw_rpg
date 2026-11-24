"""One fixed signed31 successor. Needs Root actual media/trial pins; never runs Stage."""
from pathlib import Path
import argparse, copy, difflib, hashlib, json, re, struct

N = Path(__file__).resolve().parent
G = N.parents[1]
S = 'res://build/luoyang_city_finish_20261025i_source01/'
Y = 'res://build/luoyang_city_finish_20261025i_system01/'
BASE = S + 'visible_doors_boundaries33_repair01/'
P = BASE + 'closure_READY01/'
OUT = N / 'visible_doors_boundaries33_repair01/closure_READY01'
sha = lambda b: hashlib.sha256(b).hexdigest()
enc = lambda v: (json.dumps(v, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode('utf8')

def read(pin):
    b = (G / pin['path'][6:]).read_bytes()
    assert sha(b) == pin['sha256'].lower(), ('FIXED_SHA', pin)
    if 'bytes' in pin: assert len(b) == pin['bytes']
    return b

def load(pin): return json.loads(read(pin))

def exact(b, old, new, count=1):
    old, new = old.encode(), new.encode()
    assert old != new and b.count(old) == count, (old[:110], b.count(old), count)
    return b.replace(old, new)

def hunks(old, new):
    a, b, result = old.decode().splitlines(True), new.decode().splitlines(True), []
    for group in difflib.SequenceMatcher(None, a, b, autojunk=False).get_grouped_opcodes(2):
        result.append(dict(old=''.join(a[group[0][1]:group[-1][2]]), new=''.join(b[group[0][3]:group[-1][4]])))
    f, back = old, new
    for h in result: f = exact(f, h['old'], h['new'])
    for h in reversed(result): back = exact(back, h['new'], h['old'])
    assert f == new and back == old
    return result

ap = argparse.ArgumentParser()
ap.add_argument('config')
ap.add_argument('--config-sha256', required=True)
args = ap.parse_args()
config_bytes = Path(args.config).read_bytes()
assert sha(config_bytes) == args.config_sha256
config = json.loads(config_bytes)
assert config['status'] == 'ROOT_FIXED_ACTUAL_BELL_ONLY_MEDIA_AND_NEW_TRIAL_NOT_RESULT'
assert config['elder_pair_adopted'] is False
trial = config['trial']
tv = load(trial)
assert tv['admitted'] is True and tv['permission_kind'] == 'TRIAL_PERMISSION_NOT_RESULT' and tv['actual_Field_pass'] is False
portrait_promotion = config['portrait_promotion']
pv = load(portrait_promotion)
assert pv['passed'] is True
bell = config['bell_portrait']
assert bell['path'].endswith('/bell_keeper_middleaged_portrait_v1.png')
assert bell['sha256'] == 'db102e07a46e1115b78358636aeb1bf135f78bbc501a89c18124a5aa7d6a9108'
assert bell['import_path'] == bell['path'] + '.import'
assert set(bell)=={'path','sha256','import_path','import_sha256','ctex_path','ctex_sha256'}
bell_sources = {bell[k]: bell[v] for k, v in [('path', 'sha256'), ('import_path', 'import_sha256'), ('ctex_path', 'ctex_sha256')]}
for p, h in bell_sources.items(): read(dict(path=p, sha256=h))
assert re.findall(r'^path="([^"\r\n]+)"\r?$', read(dict(path=bell['import_path'], sha256=bell['import_sha256'])).decode(), re.M) == [bell['ctex_path']]

parent_descriptor = dict(path=S+'temple_signed_iid_repair01/unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json', sha256='c7896af45a53d8eb45f6bc0f5f6fd794fa40c8999af1757906fa8ec7812a8aa7')
oldbundle = load(parent_descriptor)
sealold = load(oldbundle['seal'])
priorcode = load(oldbundle['code_proof'])
parent_actual=dict(path=S+'temple_signed_iid_repair01/signed_Temple31_deployed_ROOT_ACTUAL.json',sha256='53b5956a004e62a2d91eeab685cc02c5d26dad896801e86e148349327ad72612')
deployed=load(parent_actual)
assert deployed['passed'] and deployed['target_count']==31
parents = {r['target']: r['candidate'] for r in oldbundle['targets']}
natural = load(dict(path=S+'temple_signed_iid_repair01/expected_Temple_natural_sources_READONLY.json', sha256='a0c525ed72fbb2d30617c8074087bc9f20c8d5a27210afba2f879ad2730bbf8b'))
EDATA='res://data/maps/luoyang_full_city_20261022ap/environment.json'
EINDEX='res://scripts/city/luoyang_environment_index_20261022ap.gd'
for target in [EDATA, EINDEX]:
    pin=dict(path=target, sha256=natural['source_sha256'][target])
    parents[target]={**pin, 'bytes':len(read(pin))}
assert len(parents)==33
for target,pin in parents.items():assert (G/target[6:]).read_bytes()==read(pin),('CURRENT_SIGNED31_FIXED_PARENT',target)
data, records = {}, {}

def out(name, b):
    assert name not in data
    data[name] = b
    return dict(path=P+name, sha256=sha(b), bytes=len(b))

def value(pin): return data[pin['path'][len(P):]] if pin['path'].startswith(P) else read(pin)

def record(target, name, b):
    old=read(parents[target]); assert old != b, ('NOOP',target)
    pin=out(name,b)
    records[target]=dict(parent=parents[target], candidate=pin, hunks=hunks(old,b), whole_byte_forward_inverse=True)
    return pin

# Decode only the fixed artifact's native Variant byte spans. Never re-encode or
# derive geometry in Python. Parent spans must match every old native fingerprint.
source=(N/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
klass=source[source.index('class FrozenVariant:'):source.index('binding_pin=')]
scope={'struct':struct}; exec(klass,scope)
FrozenVariant=scope['FrozenVariant']

def native_top_spans(raw):
    v=FrozenVariant(raw)
    assert v.take('<I')[0]==27
    count=v.take('<I')[0]&0x7fffffff
    result={}
    for _ in range(count):
        k=v.value(); start=v.p; decoded=v.value()
        assert k not in result
        result[k]=dict(raw=raw[start:v.p], value=decoded)
    assert v.p==len(raw)
    return result

temple_actual=dict(path=S+'Temple_visible_arrival_local02_ROOT_READY/output_ROOT_READY/33324/result.json', sha256='612a47485d338095a26eb9cf2ff1262ca2f6ee84cab685bd54d2784c32c52ed5')
yamen_actual=dict(path=S+'street_edges_yamen02_local03_ROOT_READY/output_ROOT_READY/30628/result.json', sha256='98a268ebd389ab5b5c8ca1ecef20870e0b22f7d6c0389e49ec5ecf2f72a0345e')
tp, yp=load(temple_actual), load(yamen_actual)
assert tp['passed'] and tp['checks']==219 and yp['passed'] and yp['checks']==282
assert tp['source_first']==tp['source_final'] and yp['source_first']==yp['source_final']
payloads=copy.deepcopy(tp['components']['payloads'])
yr=yp['components']['scenes']['ch4_s1_luoyang_yamen']
payloads['ch4_s1_luoyang_yamen']=yr['payload']
ymedia=dict(path=Y+'qa_role_new/yamen_boundaries_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json',sha256='22bc906dbfcedab8bea8e0ceab83e29d7a0f23f6068686e96dbba6247ed961ff')
ym=load(ymedia); assert ym['passed'] and len(ym['written'])==2
binding=load(sealold['binding']); oldbinding=copy.deepcopy(binding)
binding_deltas={}
for scene_id, payload in payloads.items():
    row=binding['scenes'][scene_id]; oldrow=copy.deepcopy(row)
    before=native_top_spans(read(row['payload'])); after=native_top_spans(read(payload))
    assert before.keys()==after.keys()
    allowed={'effective_navigation','effective_solids','visual_additions'} if scene_id=='ch4_s1_luoyang_yamen' else {'portal_after','new_route_contracts'}
    changed={k for k in before if before[k]['raw']!=after[k]['raw']}
    assert changed<=allowed and changed, ('EXACT_ACTUAL_PAYLOAD_KEY_DOMAIN',scene_id,changed)
    for key, h in row['fingerprints'].items():
        assert sha(before[key]['raw'])==h, ('FIXED_PARENT_NATIVE_CODEC',scene_id,key)
        row['fingerprints'][key]=sha(after[key]['raw'])
    row['payload']=payload
    report=yamen_actual if scene_id=='ch4_s1_luoyang_yamen' else temple_actual
    inverse=yp['components']['inverse'] if scene_id=='ch4_s1_luoyang_yamen' else tp['components']['whole_inverse']
    extra={payload['path']:payload['sha256'], report['path']:report['sha256'], inverse['path']:inverse['sha256'], trial['path']:trial['sha256']}
    row['trial']={**trial, 'admitted':True, 'permission_kind':'TRIAL_PERMISSION_NOT_RESULT', 'actual_Field_pass':False}
    if scene_id=='ch4_s1_luoyang_yamen':
        rawmask=yr['mask']; side=rawmask['path']+'.import'
        media={r['path']:r for r in ym['written']}
        assert side in media
        compiled=re.findall(r'^path="([^"\r\n]+)"\r?$',read(media[side]).decode(),re.M)
        assert len(compiled)==1 and compiled[0] in media
        row['mask']=dict(kind='IMPORTED_RGBA8',path=rawmask['path'],sha256=rawmask['sha256'],RGBA_sha256=yr['full_RGBA_sha256'],import_path=side,compiled_path=compiled[0])
        extra.update({rawmask['path']:rawmask['sha256'], ymedia['path']:ymedia['sha256']})
        extra.update({p:r['sha256'] for p,r in media.items()})
    for p,h in extra.items():
        read(dict(path=p,sha256=h))
        assert p not in row['required_source_sha256'] or row['required_source_sha256'][p]==h
        row['required_source_sha256'][p]=h
    # No old live Field/runtime canonical hashes copied from report.source_first.
    assert not any(p in row['required_source_sha256'] for p in parents if p.endswith('.gd'))
    row['finite_visible_boundaries_source_successor']=dict(actual=report,whole_inverse=inverse,changed_payload_keys=sorted(changed),old_native_storage_unchanged=True,actual_Field_pass=False)
    binding_deltas[scene_id]=dict(old=oldrow,new=copy.deepcopy(row),native_changed_keys=sorted(changed),explicit_new_sources=extra)
for id in set(binding['scenes'])-set(payloads): assert binding['scenes'][id]==oldbinding['scenes'][id]
restored_binding=copy.deepcopy(binding)
for id in payloads:restored_binding['scenes'][id]=copy.deepcopy(oldbinding['scenes'][id])
assert enc(restored_binding)==read(sealold['binding'])
bind=out('finish8_binding_READY.json',enc(binding))

runtime_parent=dict(path=Y+'Temple_visible_arrival03_NOTREADY/finish8_runtime_visible_Temple_CANDIDATE.gd',sha256='74be6359fa36e7699b5e8ba2f3832c11241e1c1b873649590d8aac65775b5f99')
rb=read(runtime_parent)
for a,b in [(sealold['runtime']['path'],P+'finish8_runtime_READY.gd'),(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]: rb=exact(rb,a,b)
runtime=out('finish8_runtime_READY.gd',rb)
runtime_edits=[(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]

helper_parent=dict(path=Y+'wing_doors_monks04_NOTREADY/wing_door_depth_children_CANDIDATE.gd',sha256='79338ffc2fa4487eccbb0c1be486409730bde9e3c27d33c48735b1cf424f57b4')
hb=read(helper_parent)
for a,b in [('const READY: bool=false','const READY: bool=true'),('const MONK_VISUAL_READY: bool=false','const MONK_VISUAL_READY: bool=true'),(helper_parent['path'],P+'wing_door_depth_children_READY.gd')]: hb=exact(hb,a,b)
empty='"bell_portrait":{"path":"","sha256":"","import_path":"","import_sha256":"","ctex_path":"","ctex_sha256":""}'
hb=exact(hb,empty,'"bell_portrait":'+json.dumps(bell,ensure_ascii=False,separators=(',',':')))
assert hb.count(b'const ELDER_PAIR_ADOPTED: bool=false')==1
assert 'cave_keeper_elder_portrait_v1.png'.encode() not in hb
helper=out('wing_door_depth_children_READY.gd',hb)
META='res://build/luoyang_estate_courtyard_20261021ak_system01/receipts/wing.meta.json'
ATLAS='res://build/luoyang_estate_courtyard_20261021al_system01/textures/wing_door_depth.tres'
SHELL='res://art/modules/luoyang_assembled_interiors_20261016g/shell_residential_v1.png'
helper_sources={
    'estate':{helper['path']:helper['sha256'],META:'ea6709f5e4a7c93ccb0feb1c54d41fd50ed0a38292f358aaf4c97fc250bf2fd3'},
    'temple':{helper['path']:helper['sha256'],META:'ea6709f5e4a7c93ccb0feb1c54d41fd50ed0a38292f358aaf4c97fc250bf2fd3',ATLAS:'61c70b6f98c4c399ae4356ccba9151d2621b6833a8c71ed1b2cf8a79e1ee4efd',SHELL:'88189e4971ece89443557c76f7762f28fe9c1740e780bfa9ebdeadfa8c034494',SHELL+'.import':'56e7ee073ab3024a1c61e2df2e235f5095486cbddb33f1253a9545d4de226324','res://.godot/imported/shell_residential_v1.png-48ef764e649ed02b6d198116074ff76b.ctex':'336357ca36ced0b1a85313e59307ae4c8121edf5f8507266d435307509425541',**bell_sources},
}
assert len(helper_sources['estate'])==2 and len(helper_sources['temple'])==9

C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';Q='res://scripts/city/luoyang_quarters_family_20261022ap.gd';EST='res://scripts/city/luoyang_estate_family_20261021am.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def seal_runtime(b):
    for a,c in runtime_edits:b=exact(b,a,c)
    return b
field_parent=dict(path=Y+'wing_doors_monks04_NOTREADY/Field_wing_doors_monks_CANDIDATE.gd',sha256='930fcb08ab07a8eb62c5ca4c1969e4982de40157e7dfba58dba5a7a6926c96ef')
fb=seal_runtime(read(field_parent))
for a,b in [(helper_parent['path'],helper['path']),(helper_parent['sha256'],helper['sha256'])]:fb=exact(fb,a,b,2)
record(F,'Field_READY.gd',fb)
for target,name in [(C,'C_READY.gd'),(Q,'luoyang_quarters_family_20261022ap.gd')]:record(target,name,seal_runtime(read(parents[target])))

def helper_source_hook(b, result_name):
    # Source-only direct dependency. No callback/function of scene/geometry runs.
    marker=b'const FINISH25I_RUNTIME_SHA'
    lines=b.decode().splitlines(True)
    index=next(i for i,line in enumerate(lines) if line.startswith(marker.decode()))
    lines.insert(index+1,'const FINISH25I_DOORS: String='+json.dumps(helper['path'])+'\nconst FINISH25I_DOORS_SHA: String='+json.dumps(helper['sha256'])+'\n')
    b=''.join(lines).encode()
    original='\treturn '+result_name+'\n'
    section=b.index(b'static func source_paths()')
    finish=b.index(original.encode(),section)
    addition='\tif FINISH25I_ENABLED:\n\t\tif FileAccess.get_sha256(FINISH25I_DOORS)!=FINISH25I_DOORS_SHA: return {}\n\t\tvar doors: Variant=load(FINISH25I_DOORS)\n\t\tif not doors is GDScript or doors.resource_path!=FINISH25I_DOORS: return {}\n\t\tvar door_paths: Dictionary=doors.source_paths_for(ID)\n\t\tif door_paths.is_empty(): return {}\n\t\t'+result_name+'.merge(door_paths,true)\n'
    return b[:finish]+addition.encode()+b[finish:]

record(EST,'luoyang_estate_family_20261021am.gd',helper_source_hook(seal_runtime(read(parents[EST])),'paths'))
material_parent=sealold['material_helper'];mb=read(material_parent);newmb=seal_runtime(mb)
for a,b in [(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]:newmb=exact(newmb,a,b)
material=out('material_runtime_finish139_READY.gd',newmb)
eb=seal_runtime(read(parents[ENV]))
for a,b in [(material_parent['path'],material['path']),(material_parent['sha256'],material['sha256'])]:eb=exact(eb,a,b)
record(ENV,'ENV_READY.gd',eb)
edata=dict(path=S+'cart_ruts_center_visual01_BUILD/environment_cart_ruts_center_only_CANDIDATE.json',sha256='51f203d144ebdb0e1acbe9fdd994690a8f9e53f421f0d75ee4aaa16bd171ac12')
record(EDATA,'environment_cart_ruts_center_ONLY.json',read(edata))
record(EINDEX,'environment_index_READY.gd',exact(read(parents[EINDEX]),parents[EDATA]['sha256'],records[EDATA]['candidate']['sha256']))

ordinary=[]
original=load(dict(path=S+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200'))
def ordinary_successor(consumer,target,stem,edits):
    prior=next(r['proof'] for r in priorcode['ordinary'] if r['target']==target)
    oldproof=load(prior);v=copy.deepcopy(oldproof)
    for step in v['replacements']:
        for a,b in edits:
            if a in step['new']:step['new']=step['new'].replace(a,b)
    v['new_sha256']=records[target]['candidate']['sha256']
    fixed=read(original['records'][target]['parent']);f=fixed;back=value(records[target]['candidate'])
    for h in v['replacements']:f=exact(f,h['old'],h['new'])
    for h in reversed(v['replacements']):back=exact(back,h['new'],h['old'])
    assert f==value(records[target]['candidate']) and back==fixed and len(v['replacements'])==len(oldproof['replacements'])
    pin=out(stem+'_ordinary_to_fixed25h_READY.json',enc(v));b=read(parents[consumer]);edits=[]
    for a,c in [(oldproof['new_sha256'],v['new_sha256']),(prior['path'],pin['path']),(prior['sha256'],pin['sha256'])]:b=exact(b,a,c);edits.append((a,c))
    record(consumer,stem+'_consumer_READY.gd',b)
    ordinary.append(dict(consumer=consumer,target=target,proof=pin,parent=prior,inner_gate_replacement_counts_unchanged=True,old_inner_chain_unchanged=True))
    return edits
ed=ordinary_successor(AA,C,'C',runtime_edits);ordinary_successor(AC,AA,'AA',ed)

raw=read(parents[CT]);v=json.loads(raw);b=raw;ctchanges={}
assert len(v['source_sha256'])==26
for target,old in list(v['source_sha256'].items()):
    if target not in records:continue
    assert old==parents[target]['sha256']
    new=records[target]['candidate']['sha256'];v['source_sha256'][target]=new;b=exact(b,old,new)
    ctchanges[target]=dict(old=old,new=new)
assert json.loads(b)==v
contract=dict(parent=parents[CT],candidate=out('runtime_contract_ALL_prospective_READY.json',b),changes=ctchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
prospective={p:r['candidate'] for p,r in records.items()};prospective[CT]=contract['candidate']
tbparent=oldbundle['temple_binding']['candidate'];raw=read(tbparent);tbv=json.loads(raw);b=raw;tbchanges={}
base=load(dict(path=tbv['parent_binding_path'],sha256=tbv['parent_binding_sha256']))
merged={**base['source_sha256'],**tbv['source_delta']};assert len(merged)==196
for target,old in merged.items():
    if target not in prospective:continue
    assert old==parents[target]['sha256'] and target in tbv['source_delta']
    new=prospective[target]['sha256'];tbv['source_delta'][target]=new
    b=exact(b,json.dumps(target)+': '+json.dumps(old),json.dumps(target)+': '+json.dumps(new))
    tbchanges[target]=dict(old=old,new=new)
assert json.loads(b)==tbv
tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=tbchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
b=helper_source_hook(seal_runtime(read(parents[T])),'result')
for a,c in [(tbparent['path'],tb['candidate']['path']),(tbparent['sha256'],tb['candidate']['sha256'])]:b=exact(b,a,c)
record(T,'Temple_READY.gd',b)

prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==218
new=copy.deepcopy(prior);changed=[F,CO,T,AC]
for target in changed:
    owner=new['owned'][target];r=records[target]
    assert owner['current_sha256']==parents[target]['sha256']
    snapshot=next(e['new_snapshot'] for e in reversed(owner['edges']) if e['new_sha256']==owner['current_sha256'])
    assert read(dict(path=snapshot,sha256=owner['current_sha256']))==read(parents[target])
    owner['edges'].append(dict(path=target,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']))
    owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for pin in [contract['candidate'],tb['candidate']]:new['source_sha256'][pin['path']]=pin['sha256']
extra={p:h for p,h in new['source_sha256'].items() if p not in prior['source_sha256']}
assert len(extra)==6 and len(new['source_sha256'])==224 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(new)
for target in changed:back['owned'][target]=copy.deepcopy(prior['owned'][target])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX])
execution=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=changed,owned_count=10,old_proof_count=218,new_proof_count=224,extra=extra,old218_values_all_edges_retained=True,authority_F120_unchanged=True,no_shortcut=True,whole_typed_UTF8_inverse=True)

seal=copy.deepcopy(sealold)
for obsolete in ['binding_whole_bytes_path_SHA_unchanged','all_payloads_masks_actors_portals_geometry_unchanged','optional_ART_excluded','runtime_function_bytes_unchanged','runtime_header_changes','old_runtime','binding_whole_bytes_unchanged','local_actual']:
    seal.pop(obsolete,None)
seal.update(status='ROOT_ACTUAL_LOCAL_COMPONENTS_VISIBLE_DOORS_YAMEN2_CART_BELL_ONLY_NOT_FIELD_PASS',runtime=runtime,binding=bind,Field=records[F]['candidate'],material_helper=material,material_helper_seal=dict(parent=material_parent,candidate=material,hunks=hunks(mb,newmb),whole_byte_inverse=True,only_four_runtime_BIND_literals=True),wing_helper=helper,wing_helper_parent=helper_parent,wing_source_entrypoints=helper_sources,portrait_promotion=portrait_promotion,bell_only=True,elder_pair_adopted=False,local_actuals=[yamen_actual,temple_actual],new_mask_promotion=ymedia,functional_proofs=[dict(path=Y+'wing_doors_monks04_NOTREADY/shared_helper_Field_complete_whole_inverse_BUILD.json',sha256='d0d2427f242b8c32fe7cdf34ce20c21b5077cb3fdd635df9192ffc67f8426e43')],records={p:r for p,r in records.items() if p in [C,Q,EST,ENV,T]},binding_inverse=dict(parent=sealold['binding'],candidate=bind,changed_scenes=binding_deltas,other_four_scenes_identical=True),Root_trial=trial)
seal['functional_proofs'].append(dict(path=Y+'Temple_visible_arrival03_NOTREADY/runtime_two_arrival_hunks_whole_inverse_BUILD.json',sha256='028ed4400eb941444fccacb517cde044fbf35c024aff1023c7de8d09affe2153'))
seal['runtime_seal']=dict(parent=runtime_parent,candidate=runtime,hunks=hunks(read(runtime_parent),rb),only_SELF_BIND_path_SHA_headers=True,functions_byte_identical_to_approved_74BE=True)
seal['wing_helper_seal']=dict(parent=helper_parent,candidate=helper,hunks=hunks(read(helper_parent),hb),only_READY_MONK_VISUAL_READY_SELF_and_bell_six_literals=True,elder_pair_false_entries_empty=True,all_functions_unchanged=True)
seal['Field_functional_parent']=field_parent
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
code=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='SIGNED31_PARENT_NECESSARY_SOURCE_SUCCESSOR_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,extra_source_entrypoints=helper_sources,environment_author=records[EDATA],environment_index=records[EINDEX],parent_descriptor=parent_descriptor,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)))
scope_value=dict(status='CURRENT_SIGNED31_EXISTING33_SCOPE_PREPARATION_NOT_BACKUP',count=33,partition=dict(GD=18,JSON=15),parent_stage=deployed['stage'],parent_descriptor=parent_descriptor,parent_actual=parent_actual,old_backups=403,Root_new_backup_pending=True,targets=[dict(target=t,immutable_old=p['path'],old_sha256=p['sha256'],old_bytes=p['bytes']) for t,p in parents.items()],no_canonical_writes=True,existing_target_superset_only_final_noops_pruned=True)
scope_pin=out('current_signed31_exact33_scope_PREPARATION.json',enc(scope_value))
assert len(records)==11 and not OUT.exists()
OUT.mkdir(parents=True)
for name,raw in data.items():
    with (OUT/name).open('xb') as stream:stream.write(raw)
print(json.dumps(dict(code=code,seal=sealpin,helper=helper,Field=records[F]['candidate'],runtime=runtime,binding=bind,execution=execution['candidate'],scope=scope_pin)))
