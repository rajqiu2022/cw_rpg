from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b): return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f: f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
raw=(N/'overview_eight_fields11_ROOT_READY_input.json').read_bytes()
assert sha(raw)=='a93c85aa0498cdbb48499e8fd0ff112b55a77b439897971f3eb96b8a3b36f965'
a=json.loads(raw)
changes={
 'surface_factory':('city_purpose_surface04_explicit_repeat_NOTREADY.gd','28fcbf648affc0e867126a88e71286a69d82e44e0c505eb72202cea63a66b5d3'),
 'surface_shader':('city_purpose_surface04_explicit_repeat_NOTREADY.gdshader','13c1a3181570845460c624fa909232d06fb5dec5677d04dd484f14dea9388e86'),
 'surface_author':('eight_fields_purpose_surface04_explicit_repeat_NOTREADY.json','7b95cbb5f9ff62541e259ac8779aff76ebb8e6f3cdbaf161cacbf06f96ffd63d')}
for key,(name,digest) in changes.items():
    assert sha((N/name).read_bytes())==digest
    a['sources'].pop(a[key]);a[key]=NS+name;a['sources'][NS+name]=digest
remaining=['ch4_s4_ancient_temple','luoyang_riverside_garden_20261022ap']
for scene in a['scenes']:
    sid=scene['id']
    if sid in remaining: continue
    if sid=='luoyang_estate_riverside_20261021ai': continue
    name='overview_eight_fields11_ROOT_READY/output_ROOT_READY/94120/'+sid+'.png'
    a['inherited_images'][sid]={'path':NS+name,'sha256':sha((N/name).read_bytes()),'source':'ROOT94120 complete PNG inherited for building/geometry composition ONLY. Material04 is NOT claimed displayed in this inherited image.'}
a['render_scene_ids']=remaining
a['material04_component_evidence']={
 'floor':{'path':NS+'material_sampling_native_probe02_ROOT_READY/output_ROOT_READY/53100/result.json','sha256':sha((N/'material_sampling_native_probe02_ROOT_READY/output_ROOT_READY/53100/result.json').read_bytes()),'scope':'Only floor20 native GPU RGB samples inherited; original wholeFAIL preserved.'},
 'road':{'path':NS+'material_sampling_native_probe03_road_ROOT_READY/output_ROOT_READY/73428/result.json','sha256':'5b16fe618d9e548ebf37ed1c1b159878dde960388a1ff376a8673b4e84736e56','scope':'ROOT73428 natural0/48 checks0/29 unique RGB; no other scene pixels implied.'}}
for value in a['material04_component_evidence'].values():
    assert sha((N/value['path'].removeprefix(NS)).read_bytes())==value['sha256']
    a['sources'][value['path']]=value['sha256']
for sid,value in a['inherited_images'].items():
    if sid not in remaining: a['sources'][value['path']]=value['sha256']
a['output_absolute']=(N/'overview_eight_fields12_material04_two_ROOT_READY/output_ROOT_READY').as_posix()
a['artifact_creation_scope']='Only Temple/Garden2 NEW PNGs plus contact sheet with6 fixed inherited composition images. No other6 rendering, parse replay, geometry, Field, or whole-city ART pass.'
ip=emit('overview_eight_fields12_material04_two_ROOT_READY_input.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
parent=(N/'overview_eight_fields11_ROOT_READY.gd').read_bytes()
assert sha(parent)=='a1adb1760193685e9f6e489d4056893e13e484f7520eb7dd11130e3105ceeb6b'
t=parent.decode();hunks=[]
def change(o,n):
    global t
    assert t.count(o)==1
    t=t.replace(o,n);hunks.append(dict(old=o,new=n))
change('const INPUT: String="'+NS+'overview_eight_fields11_ROOT_READY_input.json"\nconst INPUT_SHA: String="'+sha(raw)+'"\nconst SELF: String="'+NS+'overview_eight_fields11_ROOT_READY.gd"',
       'const INPUT: String="'+ip['path']+'"\nconst INPUT_SHA: String="'+ip['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields12_material04_two_ROOT_READY.gd"')
change('if id=="luoyang_estate_riverside_20261021ai":\n\t\t\tvar inherited:', 'if id not in fixture.render_scene_ids:\n\t\t\tvar inherited:')
back=t
for h in reversed(hunks):
    assert back.count(h['new'])==1
    back=back.replace(h['new'],h['old'])
assert back.encode()==parent
key=emit('overview_eight_fields12_material04_two_ROOT_READY.gd',t.encode())
proof=emit('overview12_material04_two_whole_inverse_READY.json',(json.dumps(dict(status='ROOT_AUTHORIZED_MATERIAL04_TWO_REMAINING_VIEWS_ONLY',key=key,input=ip,parent_sha256=sha(parent),hunks=hunks,whole_byte_inverse=True,material_changes=changes,rendered_scene_ids=remaining,other6_scope='Inherited composition only, not new04 pixel validation or whole-city ART.',engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(key=key,input=ip,proof=proof)))
