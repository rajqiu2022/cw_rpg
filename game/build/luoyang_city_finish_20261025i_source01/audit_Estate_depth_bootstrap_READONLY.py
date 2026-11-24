"""Select one fixed payload and inspect source bootstrap; no engine or publication."""
from pathlib import Path
import hashlib,json,struct
N=Path(__file__).resolve().parent
G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
def read(path,expected):
    raw=(G/path[6:]).read_bytes()
    assert hashlib.sha256(raw).hexdigest()==expected,path
    return raw
binding_pin=dict(path=S+'docks_gallery_family_repair01/closure_READY01/finish8_binding_READY.json',sha256='ed3bdd2b59ab7c18cfbbe274404a04e1d75045dd61d7852f7bc6b4494c12fa66')
binding=json.loads(read(**dict(path=binding_pin['path'],expected=binding_pin['sha256'])))
row=binding['scenes']['luoyang_estate_riverside_20261021ai']
assert row['payload']['sha256']=='48ed6266850b126cf78c752fa940ceef2770cd55ea5a32d0c2a180e2792ecc3f'
t=(N/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf-8')
scope={'struct':struct}
exec(t[t.index('class FrozenVariant:'):t.index('binding_pin=')],scope)
raw=read(row['payload']['path'],row['payload']['sha256'])
v=scope['FrozenVariant'](raw);p=v.value();assert v.p==len(raw)
parent=p['parent_navigation'];effective=p['effective_navigation'];added=p['visual_additions']
assert len(parent)==111 and len(effective)==117 and len(added)==6
assert parent==p['parent_native_navigation'] and p['visual_patches']==[] and p['visual_retired']==[]
assert effective==parent+added
assert len({r['id']for r in effective})==117
before_ids=[r['id']for r in parent if r.get('sort_by_feet',False)]
after_ids=[r['id']for r in effective if r.get('sort_by_feet',False)]
assert len(before_ids)==38 and len(after_ids)==44
assert after_ids==before_ids+[r['id']for r in added]
field_pin=dict(path='res://scripts/field/field_walkable_controller.gd',sha256='306941a8f477e4ae0ea9926cb799808cc7fb41abcde213226838067475f12f98')
runtime_pin=dict(path=S+'docks_gallery_family_repair01/closure_READY01/finish8_runtime_READY.gd',sha256='994eba7c3925ba2f82e983c5037b9806d12a9bac7826d24f8edaac37c3ed857c')
field=read(field_pin['path'],field_pin['sha256']).decode('utf-8')
runtime=read(runtime_pin['path'],runtime_pin['sha256']).decode('utf-8')
branch='if _current_scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"] and _v14_modular_overlap==null:'
assert branch in field
assert 'if not _owned(true,true) or helper == null: return false' in runtime
assert 'if _finish25i != null and not _finish25i.admit_depth(_v14_modular_overlap):' in field
body=field[field.index('func _spawn_scene_objects('):field.index('func _spawn_scene_objects(')+22000] if 'func _spawn_scene_objects(' in field else field[field.index('if TEMPLE_ASSEMBLY.is_scene(_current_scene) and _v14_modular_overlap==null:'):]
report=dict(
 status='READONLY_ESTATE_DEPTH_BOOTSTRAP_NULL_HELPER_SOURCE_DIAGNOSIS_NOT_NEW_ACTUAL_PROBE',passed=True,
 actual_failure='Root actual74236/52876: Field finite depth-ID admission rejected before any draw/NPC. WholeFAIL retained.',
 binding=binding_pin,payload=row['payload'],field=field_pin,runtime=runtime_pin,
 counts=dict(parent_native=111,parent_navigation=111,effective_navigation=117,visual_patch=0,visual_retired=0,visual_addition=6,parent_depth_sorted=38,effective_depth_sorted=44),
 original111_decoded_rows_and_order_exact=True,all117_unique_ids=True,
 parent_depth_ids=before_ids,effective_depth_ids=after_ids,
 actual_helper_ids_observed=False,
 added_rows=[{k:r[k]for k in ['id','texture','pos','render_size_px','world_foot_px','sort_by_feet','depth_sort_foot_y']}for r in added],
 branch_analysis=[
  dict(selector='Field Temple/assembled-room/district fade branches',fact='Estate exterior is not Temple, assembled indoor room or four-C district session.'),
  dict(selector='Field lines2796-2799 generic AP overlap initialization',before=branch,fact='Only Artisan/Garden get the original generic V14 overlap here. Estate exterior is omitted.'),
  dict(selector='Field lines2800-2821 world/outskirts/C fallback',fact='Estate exterior is a Family-native Scene, not WORLD_V14/V15, one of three outskirts or C-owned four city fields. It therefore has no matching overlap constructor branch.'),
  dict(selector='Field line2822 -> finish runtime admit_depth line317',fact='admit_depth first rejects helper==null before inspecting helper properties, _ids, _fade_ids or any admitted row.'),
  dict(selector='res://scripts/world/v14_modular_overlap.gd configure/add_prop/add_actor',fact='Existing generic helper has no _ids or _temple_ids whitelist. configure stores exact world, add_prop and add_actor register source-projected actual nodes and foot depths. Existing runtime already explicitly supports this no-whitelist helper after ownership checks.')],
 diagnosis='The source-proven missing Estate bootstrap yields null helper at the first gate. No source evidence supports an ID mismatch as the first cause; the fixed payload full table has unique exact111 retained plus6 additions.',
 narrow_candidate_for_Root_decision_only='Add exactEstate Family matches/source-bound finish ownership admission to instantiate the existing generic V14 helper for this one exterior, configure the exact world and retain late depth refresh. Keep runtime.admit_depth and all original branch guards/add_prop/add_actor intact; do not allow null helper, invent IDs, delete props or broaden other scenes.',
 limitations=['No live helper properties were read; null is inferred from adopted source branch coverage and the actual first rejection.','Fixed payload selector compares decoded rows, not a new engine typed/geometry test.','System owns the necessary Field candidate; this audit changes no implementation.'],
 engine_calls=0,collector_calls=0,packet_decodes=0,PNG_decodes=0,canonical_writes=0)
out=N/'Estate_depth_bootstrap_READONLY.json';assert not out.exists()
encoded=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
with out.open('xb')as f:f.write(encoded)
print(json.dumps(dict(path=S+out.name,sha256=hashlib.sha256(encoded).hexdigest(),bytes=len(encoded),counts=report['counts'])))
