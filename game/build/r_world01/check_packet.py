"""Source-only candidate audit. Does not run Godot or write production files.

Generated diff/report artifacts are confined to this NEW packet directory.
The Python AABB oracle is not a claim that GDScript/GPU has executed.
"""
from pathlib import Path
import difflib
import hashlib
import json
import math
import random
import re
import shutil
import struct
import sys

ROOT = Path(__file__).resolve().parents[3]
PACK = Path(__file__).resolve().parent
BASELINES = {
    'scripts/field/field_walkable_controller.gd': '638cd8f0a37aacff56d074383d868f2d00bab3b81fcf56bf4d148fb84f556839',
    'scripts/autoload/loading_manager.gd': '5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db',
    'scripts/world/v14_modular_overlap.gd': '92f80ed076d90be292c848cb9743130b465b71e06250e8867d24e01f02090dab',
    'scripts/world/v15_modular_overlap.gd': 'bcd5642667d755d8b6766d8aeef002c9ce60b866d8a795854a61488fe424bd14',
    'data/maps/world_map_jianghu_layout_v15.tres': 'aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072',
    'data/scenes/world_map_jianghu.tres': '685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046',
}
checks = []
def check(name, value, details=None):
    checks.append({'name': name, 'passed': bool(value), 'details': details})
    if not value:
        raise AssertionError(name + ': ' + str(details))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def rows_for(text, key):
    start = text.index(key + ' = Array[Dictionary](')
    start = text.index('[', start + len(key + ' = Array[Dictionary]('))
    i, depth, quoted, escaped, rows, begin = start + 1, 0, False, False, [], None
    while i < len(text):
        ch = text[i]
        if quoted:
            if escaped: escaped = False
            elif ch == '\\': escaped = True
            elif ch == '"': quoted = False
        elif ch == '"': quoted = True
        elif ch == '{':
            if depth == 0: begin = i
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0: rows.append(text[begin:i + 1])
        elif ch == ']' and depth == 0: break
        i += 1
    return rows

def top_values(d):
    result, i, depth = {}, 0, 0
    while i < len(d):
        c = d[i]
        if c == '"':
            j = i + 1
            while j < len(d):
                if d[j] == '"' and d[j - 1] != '\\': break
                j += 1
            word = d[i + 1:j]
            if depth == 1 and j + 1 < len(d) and d[j + 1] == ':':
                k = j + 2
                while d[k].isspace(): k += 1
                end, nest, quoted, escape = k, 0, False, False
                while end < len(d):
                    cc = d[end]
                    if quoted:
                        if escape: escape = False
                        elif cc == '\\': escape = True
                        elif cc == '"': quoted = False
                    elif cc == '"': quoted = True
                    elif cc in '[({': nest += 1
                    elif cc in '])}':
                        if nest == 0: break
                        nest -= 1
                    elif cc == ',' and nest == 0: break
                    end += 1
                result[word] = d[k:end].strip()
                i = end
                continue
            i = j
        elif c == '{': depth += 1
        elif c == '}': depth -= 1
        i += 1
    return result

def vec(raw):
    return tuple(map(float, re.findall(r'-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?', raw.split('(', 1)[1])[:2]))

def intersects(a, b):
    return a[0] <= b[2] and a[2] >= b[0] and a[1] <= b[3] and a[3] >= b[1]

def bounds(row):
    pos = vec(row['pos'])
    pos = (pos[0] * 12288, pos[1] * 8192)
    size = vec(row['render_size_px'])
    centered = row.get('centered', 'true') == 'true'
    offset = (-size[0] / 2, -size[1] / 2) if centered else (0, 0)
    angle = math.radians(float(row.get('rotation', '0')))
    cs, sn = math.cos(angle), math.sin(angle)
    corners = [(offset[0] + dx, offset[1] + dy) for dx, dy in ((0,0), (size[0],0), size, (0,size[1]))]
    points = [(pos[0] + x*cs-y*sn, pos[1] + x*sn+y*cs) for x,y in corners]
    return min(x for x,y in points), min(y for x,y in points), max(x for x,y in points), max(y for x,y in points)

def function_blocks(text):
    matches = list(re.finditer(r'^func ([a-zA-Z_0-9]+)\(', text, re.M))
    return {m[1]: re.sub(r'(?m)^\s*#.*$', '', text[m.start():matches[i + 1].start() if i + 1 < len(matches) else len(text)]).strip()
            for i,m in enumerate(matches)}

source_pins = []
for relative, expected in BASELINES.items():
    source = ROOT / 'game' / relative
    check('baseline:' + relative, sha(source) == expected)
    backup = PACK / 'before' / relative
    if not backup.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, backup)  # Exact original bytes; never synthesized.
    check('backup:' + relative, sha(backup) == expected)
    source_pins.append({'path':'game/' + relative, 'sha256':expected, 'bytes':source.stat().st_size,
                        'mtime_ns':source.stat().st_mtime_ns, 'backup':str(backup.relative_to(ROOT)).replace('\\','/')})

for relative, allowed in (
    ('scripts/field/field_walkable_controller.gd', {'_exit_tree','_setup_scene','_spawn_scene_objects','_is_inside_walkable_screen'}),
    ('scripts/autoload/loading_manager.gd', {'_hold_source_field','_release_source_field','_preload_field_resources'}),
):
    before = (PACK/'before'/relative).read_text(encoding='utf-8-sig')
    candidate = (PACK/'candidate'/relative).read_text(encoding='utf-8-sig')
    old, new = function_blocks(before), function_blocks(candidate)
    changed = {name for name in old if old[name] != new.get(name)}
    check('old_function_scope:' + relative, changed == allowed, sorted(changed))
    (PACK/(Path(relative).stem + '.diff')).write_text(''.join(difflib.unified_diff(
        before.splitlines(True),candidate.splitlines(True),fromfile='before/'+relative,tofile='candidate/'+relative)),encoding='utf-8')

layout = (ROOT/'game/data/maps/world_map_jianghu_layout_v15.tres').read_text(encoding='utf-8')
rows = [top_values(row) for row in rows_for(layout, 'visual_objects')]
check('object_count2687', len(rows) == 2687)
check('unique_ids2687', len({r['id'] for r in rows}) == 2687)
check('unique_textures2687', len({r['texture'] for r in rows}) == 2687)
check('full_poly104', sum('solid_polygons_px' in r for r in rows) == 104)
check('full_rect2218', sum('collision_size' in r for r in rows) == 2218)
check('all16_portal_metadata', len(rows_for(layout,'portals')) == 16)
check('all64_nav_metadata', len(rows_for(layout,'walkable_mask_tiles')) == 64)
check('no_unsupported_runtime_semantics', not any(any(k in r for k in ('require_flag','hide_flag','require_quest_active','require_quest_completed','interaction_action','ground_shadow_size_px')) for r in rows))
check('render_size_every_object', all('render_size_px' in r for r in rows))
all_bounds = [bounds(r) for r in rows]
bins = {}
for ordinal, rect in enumerate(all_bounds):
    for y in range(math.floor(rect[1]/512),math.floor(rect[3]/512)+1):
        for x in range(math.floor(rect[0]/512),math.floor(rect[2]/512)+1):
            bins.setdefault((x,y),[]).append(ordinal)

def query(rect):
    found = set()
    for y in range(math.floor(rect[1]/512),math.floor(rect[3]/512)+1):
        for x in range(math.floor(rect[0]/512),math.floor(rect[2]/512)+1):
            found.update(i for i in bins.get((x,y),[]) if intersects(rect,all_bounds[i]))
    return sorted(found)

rng = random.Random(20261018)
centers = [(2600,3991.09936523438),(0,0),(12288,8192),(12288,0),(0,8192)]
centers += [(rng.uniform(0,12288),rng.uniform(0,8192)) for _ in range(100)]
for n, (x,y) in enumerate(centers):
    x, y = min(max(x,768),11520), min(max(y,432),7760)
    rect = (x-1280,y-944,x+1280,y+944) # 1920x1080/1.25 +512px prefetch.
    check('index_vs_bruteforce:' + str(n), query(rect) == [i for i,b in enumerate(all_bounds) if intersects(rect,b)])

spawn = (2600,3991.09936523438)
selected = query((spawn[0]-1280,spawn[1]-944,spawn[0]+1280,spawn[1]+944))
check('initial_halo_selection202',len(selected)==202,len(selected))
depth_rows = [r for r in rows if r.get('sort_by_feet','false') == 'true']
check('original_depth_order2682', len(depth_rows) == 2682)
ranked = list(enumerate(depth_rows))
rng.shuffle(ranked)
check('reentry_source_ordinal_ties', sorted(ranked,key=lambda it:(float(it[1]['depth_sort_foot_y']),it[0])) == sorted(enumerate(depth_rows),key=lambda it:(float(it[1]['depth_sort_foot_y']),it[0])))
resident_initial = 0
for ordinal in selected:
    path = ROOT/'game'/json.loads(rows[ordinal]['texture'])[6:]
    with path.open('rb') as source: header = source.read(24)
    width,height = struct.unpack('>II',header[16:24])
    resident_initial += width*height*12
check('initial_residency_within256MiB', resident_initial <= 256*1024*1024, resident_initial)

candidate_pins = [{'path':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':sha(p),'bytes':p.stat().st_size}
                  for p in sorted((PACK/'candidate').rglob('*.gd'))]
check('four_candidate_scripts',len(candidate_pins)==4)
for relative, expected in BASELINES.items():
    check('production_unchanged:' + relative,sha(ROOT/'game'/relative)==expected)

target = PACK/(sys.argv[1] if len(sys.argv)>1 else 'source_selfcheck_v2.json')
check('report_is_new',not target.exists())
report = {'version':2,'scope':'SOURCE_ONLY_PYTHON_REFERENCE_NOT_GODOT_OR_GPU','checks':len(checks),
          'failures':sum(not c['passed'] for c in checks),'details':checks,'source_pins':source_pins,
          'candidate_pins':candidate_pins,'initial_object_textures':len(selected),'initial_residency_estimate_bytes':resident_initial,
          'accounting':'ESTIMATE_NOT_VRAM_12_BYTES_PER_BASE_PIXEL_CURRENT_8BIT_PNG',
          'full_geometry_counts':{'poly_objects':104,'rect_objects':2218,'portals':16,'nav_tiles':64,'depth_props':2682},
          'not_validated':['GDScript proper parse','ResourceLoader lifecycle','actual Sprite/Physics','GPU overlap','loading seconds','runtime residency eviction']}
target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'report':str(target),'sha256':sha(target),'checks':report['checks'],'failures':report['failures'],
                  'initial_textures':len(selected),'resident_bytes':resident_initial,'candidate_pins':candidate_pins},ensure_ascii=False))
