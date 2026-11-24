"""Small fixed-source/inverse review only. No native loads or engine execution."""
import hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent;GAME=BASE.parents[1]
SYS=GAME/'build/world_water_bridge_20261024d_system01/native_sample01'
PROJECT=SYS/'project'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
proofp=SYS/'ROOT_READY_whole_byte_inverse_and_dependency_READONLY.json'
assert sha(proofp)=='ee1aad6a0a4c68359b5af231eb94b2934e10d381d25d02ae9320f2d6fdd0fb20'
proof=json.loads(proofp.read_text(encoding='utf-8'))
key=PROJECT/'sample_ROOT_READY.gd';fixture=PROJECT/'input_ROOT_READY.json'
assert sha(key)=='45386f063574f71d7c00a49b994bed61999aa638f3baa4ff11476a4b876ec5a9'
assert sha(fixture)=='d0ac1fda1f51c4d3051f0c03a9137765c26c401a9936d24ec91e8ceb6aedb071'
inverse_results=[]
for path,parent,replacements in [(key,PROJECT/'sample_scope02_NOTREADY.gd',proof['key_replacements']),
    (fixture,PROJECT/'input_v1final_NOTREADY.json',proof['fixture_replacements'])]:
    before=parent.read_bytes();after=path.read_bytes();forward=before
    for row in replacements:
        a=row['before'].encode();b=row['after'].encode();assert forward.count(a)==1
        forward=forward.replace(a,b)
    assert forward==after
    inverse=after
    for row in reversed(replacements):
        a=row['before'].encode();b=row['after'].encode();assert inverse.count(b)==1
        inverse=inverse.replace(b,a)
    assert inverse==before
    inverse_results.append(dict(file=res(path),parent=res(parent),parent_sha256=sha(parent),sha256=sha(path),replacement_count=len(replacements),whole_byte_forward_inverse=True))
i=json.loads(fixture.read_text(encoding='utf-8'));text=key.read_text(encoding='utf-8')
assert len(i['source_pins'])==59 and len(i['bridge']['parts'])==17
assert len({p['id'] for p in i['bridge']['parts']})==17
assert i['camera']['pixel_identical_to_user_screenshot'] is False
assert i['scope']['old_sinusoid_phase_exact'] is False and i['scope']['render_png_count']==2
assert i['deadline_ms']==60000 and i['camera']['output_size']==[3072,1728]
assert i['material']['sampling'].startswith('one clamped non-repeating')
assert i['new_art']['state']=='ROOT_FINAL_V1_ONLY_SEAM_EDITS_REJECTED_NOT_SEAMLESS_CERTIFIED'
project=PROJECT/'project.godot';assert sha(project)=='d92e36d4cbdef6815e4a7d1dfcd5d5ae7f36aa3b745352917bd6df0e5e67f9aa'
pt=project.read_text(encoding='utf-8')
assert '[autoload]' not in pt and 'run/main_scene' not in pt
assert 'set_shader_parameter("actual_height_rf"' not in text
assert 'camera.transform==before_camera and _geometry()==before_geometry' in text
assert 'for state: int in range(2):' in text
assert 'old_grain_phase_exact":false' in text
for name,h in [('wood_bitmap.gdshader','5c149080e0b6efecee1ad4be32d1e27748414888143a1e13f0fd84cc1f2fa86e'),('wood_reference.gdshader','0a41c3b9114166a7583dc9e896da2fcf10b5f77165ea8cf544f63610f6bfcc69')]:
    assert sha(PROJECT/name)==h
pre=BASE/'pre_sample_guard_current_epoch_READY.json'
assert sha(pre)=='1e8d5811c1ca5c747ba134a094c0e174f50bc06662787d87d6bdff61e5aeec70'
g=json.loads(pre.read_text(encoding='utf-8'));assert g['passed'] is True and len(g['facts'])==111
report=dict(status='LIMITED_STATIC_SCOPE02_AND_MECHANICAL_READY_REVIEW_NOT_RUNTIME_ART',
    static_blocker_found=False,key=dict(path=res(key),sha256=sha(key)),fixture=dict(path=res(fixture),sha256=sha(fixture)),project=dict(path=res(project),sha256=sha(project)),
    full_byte_inverses=inverse_results,
    reviewed=dict(isolated_project_no_autoload_or_main_scene=True,imports_or_formal_writes=False,
        geometry='17 exact source mesh references plus bare terrain/water mesh. Node material_override only; per-state19mesh surface-array SHA/local transform and camera transform invariant. No Mesh.set_surface/vertex edits or Physics nodes.',
        RF='Original water ShaderMaterial/RF resource remains shared old/new; new water appends only ALBEDO mix. Existing depth/discard/alpha and planeY-.025 unchanged. External terrain RF file is pinned/read-only, not rewritten.',
        material='Wood clamped one patch with role-axis mapping, no repetition/seam credit. Water PNG weight.08; land brown_mud ALBEDO only maximum.18 band.03-.14; no old background PNG/shadow overlay. Freshly re-lit same original terrain.',
        camera='Same fixed source basis/position; selected orthographic size6.75/projection1.25 basis/density2,3072x1728 both states. Not user screenshot pixel-identical framing.',
        outputs='NEW private-project output unique PID/ticks directory, exactly2PNG maximum plus result.json. No game assets, old PNG, walk, saves, Field/Router/24c or sourceDAG writes.'),
    native_dependency_boundary='System20RSRC complete-string scan plus bare mesh author construction is limited source evidence, not a generic binary dependency parser. QA did not load/decode native resources or repeat that scan.',
    original_current_vs_reference='Formal current bridge/ground are baked old PNGs. Program reference is an isolated same-geometry reprojection with approximate original grain phase, not exact old/current PNG or actual Field before. New candidate is not formal deployment.',
    pre_guard=dict(path=res(pre),sha256=sha(pre),fresh_paths=111,source_bytes_hashed_once=390267507,
        acknowledged_prior_external_save_changes=2,old_epoch_FAIL='C730E721 original preserved',post_pending=True),
    limitations=['GPU actual, source first/final, shader compile stderr, retained true process exit and both images remain pending Root.',
        'v1 wood/water are not seamlessly certified; seamFAIL v2 is excluded. No alpha/edge treatment or new asset permission inferred.',
        'No navigation, physical walk/support/portal, formal Field, fullworld ART or load-performance acceptance. Original17 equal geometry segmentation can remain visually regular.'],
    QA_operations=dict(engine=0,ResourceLoader=0,import_calls=0,collector=0,media_decode=0,production_writes=0))
out=BASE/'scope02_READY_static_review_READONLY.json';assert not out.exists()
out.write_bytes((json.dumps(report,ensure_ascii=True,indent=2)+'\n').encode())
print(json.dumps(dict(path=res(out),sha256=sha(out),static_blocker_found=False,engine=0)))
