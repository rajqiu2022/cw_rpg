from pathlib import Path
import hashlib,json,re
N=Path(__file__).resolve().parent;GAME=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def physical(p):return GAME/p.removeprefix('res://')
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
stage=json.loads((GAME/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json').read_text(encoding='utf8'))
authority={}
for key,node in stage['nodes'].items():
    if key.startswith('expected_'):
        for p,s in node.get('value',{}).get('source_sha256',{}).items():
            assert p not in authority or authority[p]==s
            authority[p]=s
raw=(N/'finish8_publication_input03_NOTREADY.json').read_bytes();assert sha(raw)=='60527f8c9595704453be64bbecce6abc6631c846c4819894a684212cfd8f80cc'
a=json.loads(raw);inventory=[]
for row in a['scenes']:
    scene=row['parent_scene']
    if row['id']=='ch4_s4_ancient_temple': layout='res://data/maps/luoyang_temple_layout_quest_20261018t/layout.tres'
    else: layout=scene.rsplit('/',1)[0]+'/layout.res'
    assert layout in authority,('PAIRED_LAYOUT_NOT_FORMALLY_DECLARED',layout)
    b=physical(layout).read_bytes();assert sha(b)==authority[layout]
    row['parent_layout']=layout;a['sources'][layout]=authority[layout]
    raw_scene=physical(scene).read_bytes()
    if scene.endswith('.tres'):
        external=re.findall(rb'path="(res://[^"\r\n]+)"',raw_scene)
    else:
        # RSRC external references are literal NUL-terminated UTF8 strings.
        # This is only a path ledger, not a native/resource/Variant decoder.
        external=re.findall(rb'res://[^\x00\r\n"]+',raw_scene)
    externals=[p.decode('utf8') for p in external if b'layout' in p and (p.endswith(b'.res') or p.endswith(b'.tres'))]
    inventory.append(dict(scene_id=row['id'],fixed_scene=scene,fixed_scene_sha256=a['sources'][scene],external_layout_literals=externals,
                          actual_packet_paired_layout=layout,paired_layout_sha256=authority[layout],paired_layout_bytes=len(b),
                          stale_external_layout=bool(externals and layout not in externals),
                          policy='Source-only shallow Scene copy replaces map_layout with the exact fixed packet-paired native layout; input native resources are not mutated. Runtime original materializer consumes that fixed packet layout_storage. Axis additionally whole-typed compares native rows to DFD5 extraction.'))
a['output_root']=NS+'publication04/output_NOTREADY'
a['paired_native_layout_semantics']='Explicit fixed packet/family native layout, NOT an assumed scene.res external reference. No packet decode/current-livefill; strict native prefix/old whole storage source gates remain.'
ip=emit('finish8_publication_input04_NOTREADY.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
parent=(N/'publish_finish8_components03_NOTREADY.gd').read_bytes();assert sha(parent)=='e050dcc0727669d24b87074590cf2d5f59931ecafb6291111aaf98e52ce644b9'
t=parent.decode();hunks=[]
def change(o,n):
    global t
    assert t.count(o)==1;t=t.replace(o,n);hunks.append(dict(old=o,new=n))
change('const INPUT: String="'+NS+'finish8_publication_input03_NOTREADY.json"\nconst INPUT_SHA: String="'+sha(raw)+'"','const INPUT: String="'+ip['path']+'"\nconst INPUT_SHA: String="'+ip['sha256']+'"')
change('\t\tvar original: SceneScript=load(scene_spec.parent_scene) as SceneScript\n\t\tvar view:',
       '\t\tvar original_source_scene: SceneScript=load(scene_spec.parent_scene) as SceneScript\n\t\tvar original_layout: WalkableMapLayout=load(scene_spec.parent_layout) as WalkableMapLayout\n\t\tif not check(original_source_scene!=null and original_layout!=null,"FIXED_PACKET_PAIRED_NATIVE_RESOURCES:"+id): finish();return\n\t\t# B/Family materialize their fixed packet layout_storage, not a stale external reference.\n\t\t# This source expression copies only the Scene container; old stored artifacts remain untouched.\n\t\tvar original: SceneScript=original_source_scene.duplicate(false) as SceneScript\n\t\toriginal.map_layout=original_layout\n\t\tvar view:')
back=t
for h in reversed(hunks):back=back.replace(h['new'],h['old'])
assert back.encode()==parent
key=emit('publish_finish8_components04_NOTREADY.gd',t.encode())
proof=emit('publication04_paired_native_layouts_source_expression_inverse_BUILD.json',(json.dumps(dict(status='EXACT_FIXED_NATIVE_LAYOUT_SOURCE_EXPRESSION_NOT_RUNTIME_STORAGE_CHANGE',entry=key,input=ip,source_views=a['source_views'],source_views_sha256=a['sources'][a['source_views']],parent_entry_sha256=sha(parent),hunks=hunks,whole_byte_inverse=True,scene_external_path_ledger=inventory,Root_first_FAIL_preserved=True,geometry_and_independent_expectations_unchanged=True,packet_decodes=0,engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(entry=key,input=ip,proof=proof,stale_external_ids=[v['scene_id'] for v in inventory if v['stale_external_layout']])))
