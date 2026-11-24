"""Root-only NEW one-sprite isolate. Default is read-only code/contract preflight.

No engine invocation, promotion, image processing or canonical writes. --prepare
requires this exact reviewed script SHA; all outputs must be ABSENT. Interrupted
output is retained and rejected on subsequent invocation, never overwritten.
"""
from pathlib import Path
import argparse, hashlib, json
from PIL import Image

SELF = Path(__file__).resolve()
ROOT = SELF.parents[3]
GAME = ROOT / 'game'
A = SELF.parent
S = GAME / 'build/luoyang_city_finish_20261025i_source01'
ISOLATE = A / 'monks17_single_sprite_isolate_ROOT_PREPARED'
TEMPLATE = GAME / 'build/luoyang_city_revision_20261025h_qa01/portrait_import01/verify_template02_NOTEXEC.gd'
PROFILE = TEMPLATE.with_name('input02_ROOT_READY.json')
PLAN = A / 'monks16_single_sprite3_ingress_MINIMAL_BUILD_PLAN.json'
PINS = {
    ROOT / 'assets/raw/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1.png': '86cbb758e08e52c851abdd2714a5f7d7dddba88c9b07b74fa01c344de7b034d0',
    A / 'monks13_ROOT_ONLY_OUTPUT/elder86CB_external_alpha1_clean.png': 'b25cf1a8015ec07f87d3e8e949041dd4a5b5d13b9d212dd2da4a0a964c138a0a',
    A / 'monks13_ROOT_ONLY_OUTPUT/elder86CB_clean_fullRGBA_padded1792.png': 'dd590ee73c8ef80248556bacb3cb3a1e8b438fdd219c66a0030ca44d2b908554',
    A / 'monks13_ROOT_ONLY_OUTPUT/elder86CB_compact1118_before_Lanczos.png': 'e7a5903fb85403d3c29f6dca2d09e2bae08536508d9a6c9c6052fd464ec3c67a',
    A / 'monks13_ROOT_ONLY_OUTPUT/cave_keeper_elder_idle_v1_runtime.png': '1c28942cdbf43ce8c6cffb28c498c66a87150afb53436a2d68f6deab766a3531',
    A / 'monks13_ROOT_ONLY_OUTPUT/receipt.json': '4576a4b1d2f8edcdd12f408b670e983554fb1987306cf8d68350081c254ba6c5',
    A / 'monks15_ROOT_ONLY_OUTPUT/elder86CB_compact1150_before_Lanczos.png': '8e2da857c9b3b7a626ae9859b02bcc14e605f308aa9d020f375d41e71c48cb0d',
    ROOT / 'game/art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png': '6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad',
    PLAN: 'e7e67b031621f4e0398f9295d6b773230b50f50184f47565377fb93e50c47d97',
    TEMPLATE: '445a516cf0a5995f33a6f388f657ebe4fb08207761f86dba14f3608486a6798d',
    PROFILE: '870c304c9abb7717552a9502735a199a9c40b7818c616a9700485b98cc643505',
    A / 'monks16_independent_pixel_ART_RESULT.json': '292c9b2e7998cf2adf2517ef4c1bda4bde8b48eb4f96d76cb9ee10dd93abf892',
    A / 'monks15_ROOT_ONLY_OUTPUT/receipt.json': 'c578f4e5f207e918c5b809f002edcc768d942b953f188ce5ece6cbf293e6d571',
    S / 'Estate_wall_source_repair01/post_finite_actuals31_guard_ROOT_ACTUAL.json': '259523bf512ae4218457afe96524e605dd76b9827647c6e4a71737a58199befd',
    S / 'Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json': 'ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e',
    S / 'Estate_wall_source_repair01/Estate_wall_source31_deployed_ROOT_ACTUAL.json': '47cc68861ae8165dd1517cf77787165d4f48d708faa10e587a062c3193860583',
    S / 'guard_Estate_wall_source31_current2121_ROOT_ONLY.py': 'f1178c6453e2c4dbb0481de3e37dcc00e1dc4e6c88d9b02a132120bf8d200fdc',
    S / 'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json': 'ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54',
}
def sha(b): return hashlib.sha256(b).hexdigest()
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def resolve(p): return GAME / p[6:] if p.startswith('res://') else Path(p)
def fact(p):
    p = resolve(str(p))
    if not p.exists(): return {'exists': False}
    a = p.stat(); b = p.read_bytes(); z = p.stat()
    assert (a.st_size, a.st_mtime_ns) == (z.st_size, z.st_mtime_ns)
    return {'exists': True, 'sha256': sha(b), 'bytes': len(b), 'ticks': str(z.st_mtime_ns // 100 + 621355968000000000)}
def sig(r): return {k: r[k] for k in ['exists', 'sha256', 'bytes', 'ticks'] if k in r}
def encoded(o): return (json.dumps(o, ensure_ascii=False, indent=2, allow_nan=False)+'\n').encode()
def new(p, b):
    assert p.is_relative_to(A) and not p.exists(), p
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open('xb') as f: f.write(b)
def replace_one(s, old, new):
    assert s.count(old) == 1, (old, s.count(old))
    return s.replace(old, new)
def make_verifier(prepared_sha='PENDING_PREPARED_SHA', ready=False):
    s = TEMPLATE.read_text(encoding='utf-8')
    s = s.replace('innkeeper_portrait_import_result_', 'elder_sprite_import_result_').replace('INNKEEPER_PORTRAIT_IMPORT', 'ELDER_SPRITE_IMPORT')
    s = s.replace('EXACT_ONE_INNKEEPER_PORTRAIT_ISOLATED_IMPORT_PREPARED', 'EXACT_ONE_ELDER_SPRITE_ISOLATED_IMPORT_PREPARED')
    s = s.replace('ONLY_ONE_ORIGINAL_OPAQUE_INNKEEPER_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME', 'ONLY_ONE_ELDER160_ISOLATED_FULL_RGBA_NOT_ADOPTED')
    s = s.replace('one original opaque innkeeper portrait', 'one fixed transparent elder160 sprite').replace('one original opaque portrait', 'one fixed transparent elder160 sprite')
    s = s.replace('main_two_absent_targets', 'main_three_absent_targets').replace('Main two targets still ABSENT', 'Main three targets still ABSENT').replace('Unique fixed portrait domain', 'Unique fixed elder sprite domain')
    plan = load(PLAN); item = plan['one_texture']; source = plan['source']
    expected = {item['domain']: {'png': item['png'], 'source_size': source['size'], 'png_sha256': source['sha256'], 'decoded_RGBA_sha256': source['decoded_RGBA_sha256']}}
    s = replace_one(s, 'const EXPECTED: Dictionary={}', 'const EXPECTED: Dictionary='+json.dumps(expected, indent=2))
    s = replace_one(s, 'raw.get_used_rect()==Rect2i(Vector2i.ZERO,size)', 'raw.get_used_rect()==Rect2i(46,6,61,148)')
    s = s.replace('Opaque source retains entire visible canvas; no trimming or alpha editing', 'Exact complete A1 [46,6,107,154], all RGBA preserved; no runtime cleanup')
    old = '\tfor path: String in spec.protected_main_sources:\n\t\tif not track(path,String(spec.protected_main_sources[path].sha256)): return false'
    replacement = '''\tfor path: String in spec.protected_main_sources:
\t\tvar wanted: Dictionary=spec.protected_main_sources[path]
\t\tif not track(path,String(wanted.sha256)): return false
\t\tvar expected_mtime: int=(int(String(wanted.ticks))-621355968000000000)/10000000
\t\tif not need(sources[path].bytes==int(wanted.bytes) and sources[path].mtime==expected_mtime,"Frozen source bytes and integer mtime "+path): return false
\tfor path: String in spec.protected_main_absent_targets:
\t\tif not need(not FileAccess.file_exists(path),"Frozen absent save/source remains ABSENT "+path): return false'''
    s = replace_one(s, old, replacement)
    marker = '\tif not need(Time.get_ticks_msec()-began<LIMIT_MS,"Whole fixed30s"): passed=false'
    insertion = '''\tif spec is Dictionary:
\t\tfor path: String in spec.protected_main_absent_targets:
\t\t\tif not need(not FileAccess.file_exists(path),"Frozen absent save/source still ABSENT "+path): passed=false
'''
    s = replace_one(s, marker, insertion+marker)
    assert s.count('PENDING_PREPARED_SHA') == 1
    s = s.replace('PENDING_PREPARED_SHA', prepared_sha)
    if ready: s = replace_one(s, 'const READY: bool=false', 'const READY: bool=true')
    return s.encode()
def protection():
    backup = load(S/'Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json')
    dep = load(S/'Estate_wall_source_repair01/Estate_wall_source31_deployed_ROOT_ACTUAL.json')
    bundle = load(S/'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json')
    post = load(S/'Estate_wall_source_repair01/post_finite_actuals31_guard_ROOT_ACTUAL.json')
    assert post['passed'] and not post['differences'] and post['backups_total'] == 492
    actual = {r['target']: r for r in dep['targets']}
    targets = {r['target']: r for r in bundle['targets']}
    assert len(actual) == 31 and set(actual) == set(targets)
    for p, r in targets.items(): assert actual[p]['sha256'] == r['candidate']['sha256'] and actual[p]['bytes'] == r['candidate']['bytes']
    overlay = {str(resolve(p).resolve()): p for p in actual}
    groups = {}; expected = {}
    def add(path, r, group):
        p = str(resolve(path).resolve()); value = sig(r)
        assert p not in expected or expected[p] == value, (group, p)
        expected[p] = value; groups[group] = groups.get(group, 0)+1
    def deployed(p): return dict(exists=True, sha256=actual[p]['sha256'], bytes=actual[p]['bytes'], ticks=actual[p]['ticks'])
    assert len(backup['frozen2121_current_facts']) == 2121
    for r in backup['frozen2121_current_facts']:
        p = overlay.get(str(resolve(r['path']).resolve())); add(r['path'], deployed(p) if p else r, 'current2121')
    for p in actual: add(p, deployed(p), 'exact31')
    for p, r in backup['save15'].items(): add(p, r, 'save15')
    for r in backup['old461_backup_facts']: add(r['path'], r, 'old461')
    for r in backup['new_backups']: add(r['backup'], dict(exists=True, sha256=r['sha256'], bytes=r['bytes'], ticks=r['backup_ticks']), 'new31')
    for r in backup['media_facts']: add(r['path'], r, 'media125')
    add(backup['ui']['path'], backup['ui'], 'UI')
    for r in backup['current36']: add(r['target'], deployed(r['target']) if r['target'] in actual else r['current'], 'current36')
    assert groups == dict(current2121=2121, exact31=31, save15=15, old461=461, new31=31, media125=125, UI=1, current36=36)
    return expected, groups
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--prepare-root-reviewed-script-sha256'); ap.add_argument('--render-verifier-stdout', action='store_true'); ap.add_argument('--guard-prepared-sha256'); args = ap.parse_args()
    for p, h in PINS.items(): assert sha(p.read_bytes()) == h, p
    if args.render_verifier_stdout:
        print(make_verifier().decode(), end=''); return
    if args.guard_prepared_sha256:
        p = ISOLATE/'prepared_READY.json'; assert sha(p.read_bytes()) == args.guard_prepared_sha256.lower()
        spec = load(p)
        for path, wanted in spec['protection_full_exactticks'].items(): assert fact(path) == wanted, path
        assert all(not Path(path).exists() for path in spec['main_three_absent_targets'])
        print(json.dumps(dict(status='ROOT_READONLY_PRE_POST_EXACTTICKS_GUARD_PASS', passed=True, protected_unique=len(spec['protection_full_exactticks']), main3_absent=True, engine=0, writes=0))); return
    expected, groups = protection()
    plan = load(PLAN); source = ROOT/plan['source']['path']; native = source.read_bytes()
    assert sha(native) == plan['source']['sha256'] and len(native) == 17794
    with Image.open(source) as im:
        assert im.mode == 'RGBA' and im.size == (160, 160) and im.getchannel('A').getbbox() == (46, 6, 107, 154)
        assert sha(im.tobytes()) == plan['source']['decoded_RGBA_sha256']
    item = dict(plan['one_texture']); item.update({k: plan['source'][k] for k in ['decoded_RGBA_sha256']})
    item.update(png_sha256=plan['source']['sha256'], source_size=[160,160])
    absent = [str(resolve(item[k]).resolve()) for k in ['png','sidecar','compiled']]
    assert item['compiled'] == 'res://.godot/imported/'+Path(item['png']).name+'-'+hashlib.md5(item['png'].encode()).hexdigest()+'.ctex'
    assert not ISOLATE.exists() and all(not Path(p).exists() for p in absent)
    params = load(PROFILE)['exact_23_import_params']; assert params == plan['exact_23_import_params'] and len(params)==23
    if not args.prepare_root_reviewed_script_sha256:
        print(json.dumps(dict(status='STATIC_CONTRACT_ONLY_NOT_PREPARED', builder_sha256=sha(SELF.read_bytes()), groups=groups, protected_unique=len(expected), main3_absent=True, engine=0, PNG_copies=0))); return
    assert args.prepare_root_reviewed_script_sha256.lower() == sha(SELF.read_bytes())
    # Compare to frozen independent expectations, never snapshot current as expected.
    for p, r in expected.items(): assert fact(p) == r, (p, r, fact(p))
    for p in list(PINS)+[SELF, source]:
        p = str(p.resolve()); value = fact(p)
        assert p not in expected or expected[p] == value
        expected[p] = value
    existing = {p:r for p,r in expected.items() if r['exists']}; missing = [p for p,r in expected.items() if not r['exists']]
    project = b'config_version=5\n\n[application]\nconfig/name="Luoyang25i single elder160 import isolate"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n'
    prepared = dict(status='EXACT_ONE_ELDER_SPRITE_ISOLATED_IMPORT_PREPARED', textures=[item], project_sha256=sha(project), protected_main_sources=existing, protected_main_absent_targets=missing, main_three_absent_targets=absent, protection_groups=groups, exact_23_import_params=params, protection_full_exactticks=expected, production_promoted=False)
    pb = encoded(prepared); vb = make_verifier(sha(pb), True)
    seed = '[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\npath='+json.dumps(item['compiled'])+'\nmetadata={\n"vram_texture": false\n}\n\n[deps]\n\nsource_file='+json.dumps(item['png'])+'\ndest_files=['+json.dumps(item['compiled'])+']\n\n[params]\n'+'\n'.join(k+'='+json.dumps(v) for k,v in params.items())+'\n'
    new(ISOLATE/'project.godot', project)
    new(ISOLATE/item['png'][6:], native)
    new(ISOLATE/item['sidecar'][6:], seed.encode())
    new(ISOLATE/'prepared_READY.json', pb); new(ISOLATE/'verify_READY.gd', vb)
    for p, r in expected.items(): assert fact(p) == r, p
    assert all(not Path(p).exists() for p in absent)
    receipt = dict(status='ROOT_PREPARED_ONE_ELDER160_ISOLATE_NO_ENGINE_NO_MAIN_WRITE', builder_sha256=sha(SELF.read_bytes()), prepared_sha256=sha(pb), verifier_sha256=sha(vb), project_sha256=sha(project), isolate=str(ISOLATE), groups=groups, main3_absent=True, exactticks_before_after=True, engine_calls=0, canonical_writes=0, portraits_included=0, production_adopted=False)
    new(ISOLATE/'preparation_receipt.json', encoded(receipt)); print(json.dumps(receipt))
if __name__ == '__main__': main()
