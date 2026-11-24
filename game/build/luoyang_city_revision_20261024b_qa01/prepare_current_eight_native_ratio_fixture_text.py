"""Trace current formal small index/bindings only; never read/decode a native packet."""
from pathlib import Path
import hashlib,json,re
GAME=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent/'current_eight_native_ratio_NOTREADY'
guards={};trace=[]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def res(path): return 'res://'+path.relative_to(GAME).as_posix()
def local(path):
    assert path.startswith('res://') and '..' not in path
    return GAME/path[6:]
def pin(path,expected=None):
    if isinstance(path,str): path=local(path)
    digest=sha(path)
    if expected is not None: assert digest==expected
    guards[path.as_posix()]=digest
    return path
def js(path,expected=None): return json.loads(pin(path,expected).read_bytes())
def text(path): return pin(path).read_text(encoding='utf-8')
def constant(source,name):
    match=re.search(r'const\s+'+re.escape(name)+r'\s*(?::=|=)\s*"([^"]+)"',source)
    assert match,name
    return match.group(1)
def index_manifest(index,key='MANIFEST',sha_key='MANIFEST_SHA'):
    source=text(index);assert 'FORMAL_ENABLED=true' in source.replace(' ','')
    path=constant(source,key);digest=constant(source,sha_key)
    return path,js(path,digest)
def packet(scene_id,path,digest,via):
    p=local(path);size=p.stat().st_size # No packet byte/hash read in preparation.
    assert 0<size<=128*1024*1024
    assert re.fullmatch('[0-9a-f]{64}',digest)
    row={'scene_id':scene_id,'path':path,'absolute_path':p.as_posix(),'sha256':digest,'bytes':size,'current_formal_selection':via}
    trace.append(row.copy())
    return row
def artifact(scene_id,manifest_path,data,via):
    leaves={k:v for k,v in data['artifacts'].items() if k.endswith('/packet.bin')}
    assert len(leaves)==1
    path,digest=next(iter(leaves.items()))
    assert data['scene_id']==scene_id
    return packet(scene_id,path,digest,via+[manifest_path+' /artifacts exact packet.bin leaf'])

# Frozen formal resolvers. No method is loaded or invoked.
bpath='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
b=text(bpath)
assert 'if finite.root_requested(id): return finite.root_for(id)' in b
assert 'AC_ROOT if _ac_requested(id)' in b
adapter_path=constant(b,'FINITE_ADAPTER_PATH');adapter_sha=constant(b,'FINITE_ADAPTER_SHA')
adapter=pin(adapter_path,adapter_sha).read_text(encoding='utf-8')
assert 'ch4_s1_luoyang_yamen' in adapter and 'ch4_s3_luoyang_market' in adapter
rindex_path='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
rtext=text(rindex_path)
assert 'FORMAL_ENABLED=true' in rtext
entries=json.loads(re.search(r'const ENTRIES=(\{.*?\})\s*static func',rtext,re.S).group(1))
gate='ch4_s0_luoyang_gate';row=entries[gate]
gate_data=js(row['manifest_path'],row['manifest_sha256'])
packets=[artifact(gate,row['manifest_path'],gate_data,[bpath+' _root default R_ROOT',rindex_path+' /ENTRIES/'+gate])]

ap_path='res://scripts/city/luoyang_full_city_index_20261022ap.gd'
ap=text(ap_path);assert 'finite_geometry_enabled() -> bool: return true' in ap
finite=json.loads(re.search(r'func finite_geometry_entries\(\) -> Dictionary:\s*return (\{[^\n]+\})',ap).group(1))
yamen='ch4_s1_luoyang_yamen';row=finite[yamen]
ydata=js(row['manifest_path'],row['manifest_sha256'])
packets.append(artifact(yamen,row['manifest_path'],ydata,[bpath+' finite adapter takes precedence',ap_path+' /finite_geometry_entries/'+yamen]))

ac_path='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
ac=text(ac_path);assert 'FORMAL_ENABLED=true' in ac
dpath=re.search(r'"manifest_path":"([^"]+)"',ac).group(1)
ddata=js(dpath,constant(ac,'MANIFEST_SHA'))
packets.append(artifact('ch4_s2_canal_docks',dpath,ddata,[bpath+' _root selects formal AC ahead of AA/R',ac_path+' entry()']))

qindex='res://scripts/city/luoyang_quarters_index_20261022ap.gd'
qpath,qdata=index_manifest(qindex)
family_path='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
family=text(family_path)
assert 'const LIFE_READY=true' in family.replace(' ','')
life=js(constant(family,'LIFE_BINDING'),constant(family,'LIFE_BINDING_SHA'))
pin(constant(family,'A2_BINDING'),constant(family,'A2_BINDING_SHA'))
artisan='luoyang_artisan_residential_20261022ap';garden='luoyang_riverside_garden_20261022ap'
for scene_id in [artisan,garden]:
    path=qdata['scenes'][scene_id]['packet_path'];digest=qdata['source_sha256'][path]
    via=[qindex+' -> current manifest.scenes/'+scene_id+'/packet_path']
    if scene_id==artisan:
        assert life['child']['packet.bin']=={'path':path,'sha256':digest}
        via.append(family_path+' _life_artifact_path exact current LIFE child; not original/A2 parent')
    else:
        assert path=='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/'+scene_id+'/packet.bin'
        via.append(family_path+' _life/_a2 artifact functions fall through for IDS[1]')
    packets.append(packet(scene_id,path,digest,via))

eindex='res://scripts/city/luoyang_estate_index_20261021am.gd'
epath,edata=index_manifest(eindex)
efamily='res://scripts/city/luoyang_estate_family_20261021am.gd'
estate=text(efamily)
assert 'FileAccess.get_file_as_bytes(ROOT+"packet.bin")' in estate
packet_path=constant(estate,'ROOT')+'packet.bin'
packets.append(packet('luoyang_estate_riverside_20261021ai',packet_path,edata['source_sha256'][packet_path],[eindex+' -> exact AM manifest',efamily+' packet() ROOT+packet.bin']))
assert len(packets)==6 and len({row['scene_id'] for row in packets})==6

market_path='res://build/luoyang_city_space_20261024b_source01/current_market_native_projection_ROOT_ACTUAL.json'
market_sha='fb0bbddfb1a7d3b4616b7785dbf6f5241f44242d4f502b80705c5969e36e980a'
market=js(market_path,market_sha)
assert market['packet_sha256']=='81e9f0a7cf7d006514ac4dccf00e8eefdd31bbef53f5c3a479b423c5ae0ad9a2'
assert market['record']['canonical_scene_id']=='ch4_s3_luoyang_market' and len(market['record']['objects'])==23
# Verify this retained packet remains the formally selected Market artifact,
# but DO NOT reread/decode/hash that native packet here or in the audit key.
mrow=finite['ch4_s3_luoyang_market'];mdata=js(mrow['manifest_path'],mrow['manifest_sha256'])
assert mdata['artifacts'][market['packet_path']]==market['packet_sha256']

temple_path='res://scripts/city/luoyang_temple_assembly_20261016.gd'
temple=text(temple_path)
assert 'const FORMAL_ENABLED=true' in temple
binding=js(constant(temple,'BIND_PATH'),constant(temple,'BIND_SHA'))
js(binding['parent_binding_path'],binding['parent_binding_sha256'])
assert 'static func build_scene(original: SceneScript,authored: Dictionary)' in temple
assert 'var layout:=WalkableMapLayout.new()' in temple and 'layout.visual_objects.append' in temple
assert 'packet.bin' not in temple
unknown={'scene_id':'ch4_s4_ancient_temple','status':'UNKNOWN_CURRENT_NATIVE_PACKET_DYNAMIC_ASSEMBLY','basis':temple_path+' build_scene constructs layout from source-bound authored placements and original TRES; no native packet resolver in this formal assembly','binding_path':constant(temple,'BIND_PATH'),'binding_sha256':constant(temple,'BIND_SHA'),'native_decode_count_this_run':0,'objects':[],'historical_author_not_substituted_as_current':True,'not_zero_buildings_or_small_building_claim':True}

# Small current runtime code identity only, not new projection/Field execution.
formal=pin('res://scripts/field/field_walkable_controller.gd','93c4d7a7b2fef829f8f7e1c88c9dd00b17795f4794e167682a59ae1f52ee22e0')
pin('res://scripts/city/luoyang_assembled_interiors_20261016g.gd','1078ce7fd48ee9cdae91fd56fedfa20ff26cc80f5c3273d8ff3b0b479dd128e6')
project=OUT/'project.godot';pin(project)
save_root=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
save_paths=[(save_root/('save_'+str(slot)+suffix)).as_posix() for slot in range(5) for suffix in ['.json','.json.bak','.json.tmp']]
fixture={'ready':False,'status':'CURRENT_EIGHT_NATIVE_RATIO_BUILD_NOTREADY','blockers':['ROOT must read/freeze exact key+fixture and authorize one no-autoload headless readback; QA has not run/decoded packets.'],'whole_ms':15000,'packets':packets,'market_projection':{'path':market_path,'absolute_path':local(market_path).as_posix(),'sha256':market_sha,'packet_sha256':market['packet_sha256'],'scope':'Already Root actual, inherited only, zero packet reread'},'temple_unknown':unknown,'source_sha256':guards,'save_paths':save_paths,'scope':'Six current formal native packet bytes_to_var once each, object/layout visual fields only; inherited Root Market native23 plus explicit dynamicTempleUNKNOWN. No historical author fallback, no PNG/Image/walk file/ResourceLoader/Field/NAV/Physics/source collector/production write. Decoded embedded packet walk bytes are never accessed/exported. Native packet ratio projection does not claim post-native dynamic Field layout/ENV or art acceptance.'}
fx=OUT/'fixture_NOTREADY.json';assert not fx.exists();fx.write_bytes((json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode())
key=OUT/'audit_NOTREADY.gd';original=key.read_bytes()
ops={b'PENDING_ABSOLUTE_FIXTURE_PATH':fx.as_posix().encode(),b'PENDING_FIXTURE_SHA':sha(fx).encode(),b'PENDING_ABSOLUTE_NEW_OUTPUT_DIRECTORY':(OUT/'output_NOTREADY').as_posix().encode()}
changed=original
for a,b in ops.items(): assert changed.count(a)==1;changed=changed.replace(a,b,1)
restored=changed
for a,b in reversed(list(ops.items())): assert restored.count(b)==1;restored=restored.replace(b,a,1)
assert restored==original
key.write_bytes(changed)
handoff={'status':'NOTREADY_NO_ENGINE_OR_DECODE','key':{'path':res(key),'absolute_path':key.as_posix(),'sha256':sha(key)},'fixture':{'path':res(fx),'sha256':sha(fx)},'project':{'path':res(project),'sha256':sha(project),'autoload_count':0},'formal_mapping':trace,'market_existing_projection':fixture['market_projection'],'Temple':unknown,'small_source_guard_count':len(guards),'packet_bytes_total_stat_only':sum(x['bytes'] for x in packets),'native_packet_reads_or_decodes_during_preparation':0,'scope':'6decodes once/8regions, no image/PNG/walk/NAV/Physics/Field/collector/author-current substitution','ready_freeze_changes_permitted':'Only bool/path/fixtureSHA/output plus fixture readiness/root authorization, preserve function body. ROOT only then one retained no-autoload headless process with15s key deadline.','Root_command_template':"& '<retained run_frozen_godot_once.ps1>' -Headless -Project '"+OUT.as_posix()+"' -ScriptResPath 'res://audit_READY.gd' -ScriptSHA '<NEW_READY_SHA>' -LogStem '"+(OUT/'audit_once').as_posix()+"'"}
p=OUT/'handoff_NOTREADY.json';assert not p.exists();p.write_bytes((json.dumps(handoff,ensure_ascii=False,indent=2)+'\n').encode())
print('KEY',sha(key),'FIXTURE',sha(fx),'PROJECT',sha(project),'HANDOFF',sha(p),'GUARDS',len(guards),'BYTES',sum(x['bytes'] for x in packets))
