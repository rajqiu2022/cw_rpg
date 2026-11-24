"""Mechanical NEW isolated transport/READY successor; never runs Godot."""
import hashlib, json, pathlib, difflib

ROOT = pathlib.Path(__file__).resolve().parent
BASE = ROOT / 'docks_gallery_retirement01'
OUT = BASE / 'isolated_ROOT_READY02'
assert not OUT.exists()
P = 'res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/'
raw = (BASE / 'publish_delta_NOTREADY.gd').read_bytes()
old = raw.decode('utf-8')
text = old
changes = []
def one(before, after):
    global text
    assert text.count(before) == 1, before
    text = text.replace(before, after)
    changes.append({'old': before, 'new': after})

fixture_old = (BASE / 'input_NOTREADY.json').read_bytes()
fixture_text = fixture_old.decode('utf-8')
fixture_changes = [
    ('"ready": false', '"ready": true'),
    ('"root_run_authorized": false', '"root_run_authorized": true'),
    ('"output_root": "'+P+'output_NOTREADY/"', '"output_root": "'+P+'isolated_ROOT_READY02/output_ROOT_READY/"'),
]
for a,b in fixture_changes:
    assert fixture_text.count(a)==1
    fixture_text=fixture_text.replace(a,b)
fixture = fixture_text.encode('utf-8')
sha = lambda b: hashlib.sha256(b).hexdigest()
one('const READY: bool=false', 'const READY: bool=true')
one('const INPUT: String="'+P+'input_NOTREADY.json"', 'const INPUT: String="'+P+'isolated_ROOT_READY02/input_ROOT_READY.json"')
one('const INPUT_SHA: String="652b9e1d340a3300444afc2743cd91eba6de5cbd2b80523586c2e532f320e0d3"', 'const INPUT_SHA: String="'+sha(fixture)+'"')
one('const SELF: String="'+P+'publish_delta_NOTREADY.gd"', 'const SELF: String="'+P+'isolated_ROOT_READY02/publish_delta_ROOT_READY.gd"\nconst GAME_ROOT: String="F:/Code/RPG_GAME/game/"\nfunc physical(path: String) -> String:\n\treturn GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path')
for func, arg in [
    ('FileAccess.file_exists','path'), ('FileAccess.open','path'),
    ('FileAccess.get_sha256','path'), ('FileAccess.get_modified_time','path'),
    ('FileAccess.get_file_as_string','pin.path'), ('Image.load_from_file','pin.path'),
    ('DirAccess.make_dir_recursive_absolute','report_root'),
    ('FileAccess.get_sha256','INPUT'),
    ('FileAccess.get_file_as_bytes','spec.parent_payload.path'),
    ('FileAccess.get_file_as_bytes','spec.independent_geometry.path'),
    ('DirAccess.dir_exists_absolute','prefix'), ('DirAccess.make_dir_recursive_absolute','prefix'),
    ('FileAccess.file_exists','mask_path'), ('output_image.save_png','mask_path'),
    ('FileAccess.get_sha256','mask_path'), ('FileAccess.get_file_as_bytes','mask_path'),
]:
    a=func+'('+arg
    b=func+'(physical('+arg+')'
    n=text.count(a)
    assert n>0,(a,n)
    text=text.replace(a,b)
    changes.append({'old':a,'new':b,'occurrences':n})
restored=text
for change in reversed(changes):
    assert restored.count(change['new'])==change.get('occurrences',1),change
    restored=restored.replace(change['new'],change['old'])
assert restored.encode('utf-8')==raw
fixture_back=fixture_text
for a,b in reversed(fixture_changes): fixture_back=fixture_back.replace(b,a)
assert fixture_back.encode('utf-8')==fixture_old
project=b'config_version=5\n\n[application]\nconfig/name="RootOnlyDocksGalleryRetirement"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
new=text.encode('utf-8')
proof={'status':'NEW_ROOT_READY_ISOLATED_TRANSPORT_ONLY_FULL_BYTE_INVERSE', 'passed':True,
       'key_parent':{'path':P+'publish_delta_NOTREADY.gd','sha256':sha(raw),'bytes':len(raw)},
       'key_child':{'path':P+'isolated_ROOT_READY02/publish_delta_ROOT_READY.gd','sha256':sha(new),'bytes':len(new)},
       'fixture_parent_sha256':sha(fixture_old),'fixture_child_sha256':sha(fixture),
       'project_sha256':sha(project),'changes':changes,'fixture_changes':fixture_changes,
       'key_whole_byte_inverse':True,'fixture_whole_byte_inverse':True,
       'scope':'Only READY/input/self/output + fixed physical filesystem path transport. Geometry, expected values, 2928-domain loop, 630 restoration, all strict gates unchanged.',
       'engine_runs':0,'canonical_writes':0,
       'key_unified_diff':''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile='publish_delta_NOTREADY.gd',tofile='isolated_ROOT_READY02/publish_delta_ROOT_READY.gd'))}
OUT.mkdir()
for name,data in [('input_ROOT_READY.json',fixture),('publish_delta_ROOT_READY.gd',new),('project.godot',project),('mechanical_transport_full_inverse_READY.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())]:
    with (OUT/name).open('xb') as f:f.write(data)
    print(name,sha(data),len(data))
