<#
ROOT250-only, CPU/read-only evidence preparation. Never executes Godot, publishes,
changes the captured Source/M/report, or writes the production review location.
Run after ROOT250 has really exited successfully:
  powershell -NoProfile -File scripts/qa/prepare_joint_v9e_world_visual_review_draft_20261007.ps1
Source syntax check only (no candidate reads or output):
  powershell -NoProfile -File scripts/qa/prepare_joint_v9e_world_visual_review_draft_20261007.ps1 -ValidateSourceOnly
Actual pinned-source SHA self-test (no final Source/M/report reads or output):
  powershell -NoProfile -File scripts/qa/prepare_joint_v9e_world_visual_review_draft_20261007.ps1 -ValidatePinsOnly
Immutable source/registry alias-map self-test (no final Source/M/report reads):
  powershell -NoProfile -File scripts/qa/prepare_joint_v9e_world_visual_review_draft_20261007.ps1 -ValidateTextureAliasSourceOnly
Direct native world-pixel rounding boundary units (no file reads or output files):
  powershell -NoProfile -File scripts/qa/prepare_joint_v9e_world_visual_review_draft_20261007.ps1 -ValidateSamplingSourceOnly
Requires Python 3 + Pillow. The unique BUILD JSON remains DRAFT with every door,
probe and image pending. All 2687 runtime texture paths are SHA-bound; 44 distinct
PNG SHA classes map the representative images to every byte-identical alias.
Gate-required image paths: 2768; plus 9 final-Source ecology paths: 2777.
Manual-review units are 125 + 9, NOT 2687 independently viewed texture pictures.
CPU diagnostics are NOT Field/Physics2D/input approval.
#>
[CmdletBinding()]
param([string]$Python = 'python', [switch]$ValidateSourceOnly, [switch]$ValidatePinsOnly, [switch]$ValidateTextureAliasSourceOnly, [switch]$ValidateSamplingSourceOnly)
$ErrorActionPreference = 'Stop'
if (@($ValidateSourceOnly,$ValidatePinsOnly,$ValidateTextureAliasSourceOnly,$ValidateSamplingSourceOnly).Where({$_}).Count -gt 1) { throw 'Choose one source-only validation mode' }
$taskWorkspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$draftProgram = @'
import copy, datetime, hashlib, json, math, pathlib, struct, sys, uuid
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(sys.argv[1]).resolve()
GAME = ROOT / 'game'
SIZE = (12288, 8192)
TILE = (1536, 1024)
PROTOCOL = 'COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1'
IDENTITY = 'V9E_SNOW_EXPOSURE_DAMP_FILM_DEPTH_WATER_VISUAL_EXPERIMENT'
SOURCE = 'res://data/maps/world_map_v15_complete_v9c_source.json'
MANIFEST = 'res://art/maps/world_map_v15_complete_v9c/art_contract.json'
REPORT = 'res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json'
FOOTPRINT = 'res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json'
FULL = 'res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd'
SURFACE = 'res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd'
REGIONAL = 'res://scripts/dev/build_world_map_v15_coherent_whole_v9e_regional_proposal.gd'
ECOLOGY_IMAGES = {
 'northern_snow_ridge':'res://art/maps/world_map_v15_complete_v9c/ecology/northern_snow_ridge_scene_components.png',
 'western_limestone':'res://art/maps/world_map_v15_complete_v9c/ecology/western_limestone_scene_components.png',
 'north_eastern_pine':'res://art/maps/world_map_v15_complete_v9c/ecology/north_eastern_pine_scene_components.png',
 'luoyang_farmland':'res://art/maps/world_map_v15_complete_v9c/ecology/luoyang_farmland_scene_components.png',
 'central_meadow':'res://art/maps/world_map_v15_complete_v9c/ecology/central_meadow_scene_components.png',
 'western_woodland':'res://art/maps/world_map_v15_complete_v9c/ecology/western_woodland_scene_components.png',
 'southern_bamboo':'res://art/maps/world_map_v15_complete_v9c/ecology/southern_bamboo_scene_components.png',
 'jiangnan_river_fields':'res://art/maps/world_map_v15_complete_v9c/ecology/jiangnan_river_fields_scene_components.png',
 'southeastern_marsh':'res://art/maps/world_map_v15_complete_v9c/ecology/southeastern_marsh_scene_components.png',
}
TEXTURE_INDEX = 'res://build/joint_world_luoyang_20261003_qa/root262_current_v9e_unique44_texture_review/index.json'
TEXTURE_REGISTRY = 'res://build/joint_world_luoyang_20261003_qa/art_current_v9d_unique44_texture_review_20261005/representative_registry.json'
PRIOR_DRAFT = 'res://build/joint_v9e_world_visual_review_draft_20261007T052734156803Z_515c5459/visual_review_draft.json'
ROOT_WALL_OVERRIDE = {'identity':'ROOT_BIANZHOU_WALL_LEGAL_START_ROAD_V1',
 'author':'producer/root','portal_id':'bianzhou','kind':'wall_approach',
 'old_legal_start_px':[7494.531250000002,2240.7764477287374],
 'new_legal_start_px':[7600,2366.8779296875],
 'unchanged_source_witness_px':[505,754],
 'unchanged_blocked_foot_px':[7494.531250000002,2172.9716796874977],
 'reason':'ROOT independently chose the actual door-front public road already shared by this door roof/wrongside cases; old start was black final nav. This changes only independent uncaptured test intention, not source/nav/collision/threshold.',
 'required_actual_input':'Movement must still stop against unchanged wall and finish outside actual interaction polygon; NOT_RUN',
 'semantic_review_status':'PENDING_ROOT_REVIEW'}
PORTAL_IDS = ('yanmen_pass', 'huashan', 'luoyang', 'bianzhou', 'gufeng',
              'linxi_village', 'qinghe_town', 'zhuwei_village', 'wudang',
              'xiangzhou', 'jinling', 'bailu_ferry', 'east_sea_port',
              'mingwu', 'lingyue', 'lieyun_valley')
PINS = {
 FULL: 'dcda6d3227cad5fd646b6fa3390cae5c4f71354fec1adf15552a12188a8d0121',
 SURFACE: '3cb4f995cc800482fe859f0424a4839b70097721ec5f11f21e53a7d6ca3253b1',
 REGIONAL: 'f00e83e40d3c24f1d48ecee959ddbc02bd5791c924af01a897f5a7667dcf9d0f',
 FOOTPRINT: '72c942db3430e2ae58326b3acd330643d8c90e0cadf073d3ba731582f902f242',
 'res://build/joint_v9d_negative_suggestions_20261005_01/suggestions.json':
     '95c8c1d757185f7205430eb7521ffcad044c86b8df478c1c71b016be1605717d',
 'res://build/world_v9c_ROOT234_before_v9e_material_20261005_01/world_map_v15_complete_v9c_source.json':
     '79ffac820dd6a2f475b4595475d0535b9de0b3c29fb21db03e77bc1fa73273fd',
 TEXTURE_INDEX: 'b142dc94ee4002731c3081c81460692e562d574af22c2e1a4eaba3a6095e89ab',
 TEXTURE_REGISTRY: '0b5309f7db8fa447510dc483d5b8b1cc9b9d692ae42589fc9efecfb8c646e87f',
 PRIOR_DRAFT: '526e1630a138de3493bc56c5a2526dd7370335417fded52dc312380602b374b7',
}
SUGGESTIONS = 'res://build/joint_v9d_negative_suggestions_20261005_01/suggestions.json'
ARCHIVE = 'res://build/world_v9c_ROOT234_before_v9e_material_20261005_01/world_map_v15_complete_v9c_source.json'
CAPTURE_DIR = GAME / 'build/joint_world_luoyang_20261003_qa/250_v9e_full64_112_current_candidate_GPU_20261007'
hashes = {}

def need(condition, message):
    if not condition:
        raise ValueError(message)

def disk(path):
    need(isinstance(path, str) and path.startswith('res://') and '\\' not in path,
         'Not a canonical res path: ' + str(path))
    relative = pathlib.PurePosixPath(path[6:])
    need(relative.parts and not relative.is_absolute() and '..' not in relative.parts,
         'Escaping resource path: ' + path)
    result = (GAME / str(relative)).resolve()
    need(result.is_relative_to(GAME.resolve()), 'Resource outside game: ' + path)
    return result

def sha_file(path):
    with pathlib.Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def digest(path):
    if path not in hashes:
        hashes[path] = sha_file(disk(path))
    return hashes[path]

def read(path):
    with disk(path).open(encoding='utf-8-sig') as stream:
        return json.load(stream)

def same_hash(actual, expected):
    return isinstance(actual, str) and isinstance(expected, str) and len(actual) == 64 and actual.lower() == expected.lower()

def validate_pins_only():
    records = []
    for path, expected in PINS.items():
        need(isinstance(expected,str) and len(expected) == 64 and all(c in '0123456789abcdef' for c in expected),
             'Malformed pinned SHA256: ' + path)
        actual = digest(path)
        need(same_hash(actual, expected), 'Actual pinned source SHA differs: ' + path)
        records.append({'path':path,'expected_sha256':expected,'actual_sha256':actual})
    print(json.dumps({'scope':'ACTUAL_ALL_PINS_SOURCE_ONLY_NOT_FINAL_CAPTURE_OR_APPROVAL',
      'checked_pin_count':len(records),'pins':records,'final_Source_manifest_report_read':False,
      'draft_output_created':False,'engine_executed':False},indent=2))

def texture_alias_map(paths, path_hashes, index, registry):
    need(len(paths) == len(set(paths)) == 2687, 'Exact 2687 distinct runtime texture paths required')
    classes = {}
    for path in paths:
        value = path_hashes.get(path)
        need(isinstance(value,str) and len(value) == 64 and all(c in '0123456789abcdefABCDEF' for c in value), 'Malformed actual runtime texture SHA: '+path)
        classes.setdefault(value.lower(), []).append(path)
    need(len(classes) == 44, 'Runtime paths must have exactly 44 distinct actual PNG SHA classes')
    need(index.get('purpose') == 'VISUAL_REVIEW_AID_ONLY_NOT_A_VERDICT' and index.get('original_images_unmodified') is True and same_hash(index.get('registry_sha256'),PINS[TEXTURE_REGISTRY]), 'ROOT262 index is not the frozen representative registry binding')
    need(registry.get('unique_texture_paths') == 2687 and registry.get('unique_png_bytes') == 44, 'Representative registry path/class counts differ')
    entries = index.get('images')
    need(isinstance(entries,list) and len(entries) == 44, 'ROOT262 requires exactly 44 actual representative entries')
    registered = {row['sha'].lower():row for row in registry['groups']}
    need(len(registered) == 44 and set(classes) == set(registered), 'Final texture SHA classes differ from ROOT262 bound registry')
    result, representatives, seen = {}, {}, set()
    for entry in entries:
        value = entry['sha256'].lower()
        need(value in classes and value not in seen, 'Missing/duplicate ROOT262 representative SHA class')
        seen.add(value)
        actual_path = pathlib.Path(entry['path']).resolve()
        need(actual_path.is_relative_to(GAME.resolve()), 'Representative path outside game')
        representative = 'res://'+actual_path.relative_to(GAME.resolve()).as_posix()
        aliases = sorted(classes[value])
        need(representative in aliases and representative == registered[value]['representative'], 'ROOT262 representative not an actual final runtime alias')
        need(len(aliases) == registered[value]['paths'], 'Final SHA-class alias count differs from frozen registry')
        need(entry['dimensions'] == registered[value]['actual_png_size'], 'Representative source dimensions differ')
        result[value] = {'sha256':value,'representative_path':representative,
          'representative_dimensions':entry['dimensions'],'alias_paths':aliases,'alias_count':len(aliases),
          'status':'PENDING_ROOT_CONFIRM_CURRENT_SHA_CLASS',
          'review_scope':'ONE_PNG_BYTE_CLASS_NOT_INDIVIDUAL_OBJECT_PLACEMENT_OR_INPUT'}
        representatives[representative] = {'sha256':value,'alias_paths':aliases,'alias_count':len(aliases)}
    need(seen == set(classes) and sum(row['alias_count'] for row in result.values()) == 2687, 'Incomplete representative-to-all-alias mapping')
    return result, representatives

def validate_texture_alias_source_only():
    for path in (ARCHIVE,TEXTURE_INDEX,TEXTURE_REGISTRY):
        need(same_hash(digest(path),PINS[path]), 'Frozen alias self-test input changed: '+path)
    archive = read(ARCHIVE)
    need(len(archive['ecology_probes']) == 9 and {row['id']:row['scene_components_path'] for row in archive['ecology_probes']} == ECOLOGY_IMAGES,
         'Immutable source exact nine ecology IDs/paths differ')
    paths = sorted({row['texture'] for row in archive['objects']})
    classes, representatives = texture_alias_map(paths,archive['asset_sha256'],read(TEXTURE_INDEX),read(TEXTURE_REGISTRY))
    # Negative controls are pure in-memory mutations, never candidate writes.
    for changed in (dict(archive['asset_sha256'], **{paths[0]:'0'*64}),
                    dict(archive['asset_sha256'], **{paths[0]:archive['asset_sha256'][paths[-1]]})):
        rejected = False
        try:
            texture_alias_map(paths,changed,read(TEXTURE_INDEX),read(TEXTURE_REGISTRY))
        except ValueError:
            rejected = True
        need(rejected,'Mutated SHA/alias-count negative control was accepted')
    print(json.dumps({'scope':'IMMUTABLE234_SOURCE_CATALOG_AND_ROOT262_INDEX_ONLY_NOT_FINAL_SOURCE_OR_ACTUAL_FINAL_PNG_HASHING',
      'runtime_texture_paths':len(paths),'distinct_PNG_SHA_classes':len(classes),'representatives':len(representatives),
      'mapped_alias_paths':sum(row['alias_count'] for row in classes.values()),'gate_required_image_paths':1+64+len(paths)+16,
      'with_ecology_image_paths':1+64+len(paths)+16+9,'visual_review_units':1+64+len(classes)+16+9,
      'frozen_final_Source_ecology_images':ECOLOGY_IMAGES,
      'negative_controls_rejected':2,'final_Source_manifest_report_read':False,'draft_output_created':False,'engine_executed':False},indent=2))

def pair(point):
    return isinstance(point, list) and len(point) == 2 and all(type(n) in (int, float) and math.isfinite(n) for n in point)

def world(point):
    return pair(point) and all(0 <= point[i] < SIZE[i] for i in range(2))

def f32(value):
    return struct.unpack('<f', struct.pack('<f', value))[0]

def vec(point):
    need(pair(point), 'Malformed numeric Vector2: ' + str(point))
    return [f32(point[0]), f32(point[1])]

def native_world_pixel(point):
    # Frozen Source round_world_pixel and contract:155 / gate:888:
    # native Vector2 components, direct roundi, then reject rounded bounds.
    # The prior normalized SIZE-1 sampler is retired, not NAV evidence.
    if not world(point):
        return None
    point = vec(point)
    if not world(point):
        return None
    pixel = [math.floor(n+.5) for n in point]
    return pixel if all(0 <= pixel[i] < SIZE[i] for i in range(2)) else None

def validate_sampling_source_only(emit=True):
    cases = [([0,0],[0,0]), ([.49999997,.49999997],[0,0]),
      ([.5,.5],[1,1]), ([.50000006,.50000006],[1,1]),
      ([1535.4998779296875,1023.4999389648438],[1535,1023]),
      ([1535.5,1023.5],[1536,1024]),
      ([7494.53125,2240.7763671875],[7495,2241]),
      ([12287.4990234375,8191.49951171875],[12287,8191]),
      ([12287.5,100],None), ([100,8191.5],None),
      ([12288,0],None), ([0,8192],None), ([-.001,0],None),
      ([0,-.001],None), ([float('nan'),0],None), ([0,float('inf')],None),
      ([12287.9999,0],None), ([0,8191.9999],None)]
    for point, expected in cases:
        need(native_world_pixel(point)==expected, 'Direct native round_world_pixel boundary unit failed: '+str(point))
    result = {'scope':'PURE_NATIVE_FLOAT32_DIRECT_ROUNDI_BOUNDARY_UNITS_NOT_NAV_OR_FIELD_APPROVAL',
      'method':'NATIVE_FLOAT32_DIRECT_ROUNDI_WORLD_PIXEL_REJECT_ROUNDED_OUTSIDE',
      'cases':len(cases),'failures':0,'final_Source_manifest_report_read':False,
      'draft_output_created':False,'engine_executed':False}
    if emit:
        print(json.dumps(result,indent=2))
    return result

# Native Vector2 fields are compared by float32 bits, not broad epsilon. JSON
# float64 spelling tails do not license even a one-native-ULP geometry change.
SPATIAL = {'pos', 'size', 'render_size_px', 'foot_uv', 'world_foot_px',
 'solid_polygons_px', 'collision_size', 'collision_offset', 'walkability_margin_px',
 'depth_sort_foot_y', 'door_foot_px', 'source_XZ_foot_px', 'passage_path_px',
 'passage_polygon_px', 'interaction_polygon_px', 'target_pos', 'approach_direction'}

def native(value):
    if isinstance(value, list):
        return [native(n) for n in value]
    if type(value) in (int, float):
        need(math.isfinite(value), 'Nonfinite frozen geometry')
        return struct.pack('<f', value).hex()
    return value

def frozen_rows(current, previous, ignored=()):
    need(len(current) == len(previous), 'Frozen row count changed')
    old = {row['id']: row for row in previous}
    need(len(old) == len(previous), 'Duplicate archived geometry id')
    seen = set()
    for row in current:
        identity = row['id']
        need(identity not in seen and identity in old, 'Unknown/duplicate geometry id: ' + identity)
        seen.add(identity)
        a = {k: v for k, v in row.items() if k not in ignored}
        b = {k: v for k, v in old[identity].items() if k not in ignored}
        need(set(a) == set(b), 'Frozen geometry fields changed: ' + identity)
        for key in a:
            need((native(a[key]) == native(b[key])) if key in SPATIAL else a[key] == b[key],
                 'Frozen geometry changed: ' + identity + '/' + key)

def bound(path, catalog):
    actual = digest(path)
    need(same_hash(actual, catalog.get(path)), 'Current captured asset changed/missing: ' + path)
    return actual

def on_segment(p, a, b):
    cross = (p[0]-a[0])*(b[1]-a[1]) - (p[1]-a[1])*(b[0]-a[0])
    return abs(cross) <= 1e-8 and min(a[0], b[0]) <= p[0] <= max(a[0], b[0]) and min(a[1], b[1]) <= p[1] <= max(a[1], b[1])

def inside(p, polygon):
    need(isinstance(polygon, list) and len(polygon) >= 3 and all(pair(q) for q in polygon), 'Malformed authored polygon')
    result = False
    for i, a in enumerate(polygon):
        b = polygon[(i+1) % len(polygon)]
        if on_segment(p, a, b):
            return True
        if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < (b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:
            result = not result
    return result

def shoe_samples(center):
    center = vec(center)
    return [center] + [[f32(center[0]+f32(math.cos(math.tau*i/16)*10)),
                        f32(center[1]+f32(math.sin(math.tau*i/16)*6))] for i in range(16)]

def write_witness_contact_pages(destination, doors, source_sha):
    # QA annotation on separate downscaled contact pages, never an asset edit.
    # Every original full-resolution RGBA and its hash remain unchanged.
    font_path = pathlib.Path('C:/Windows/Fonts/consola.ttf')
    title_font = ImageFont.truetype(str(font_path),24) if font_path.is_file() else ImageFont.load_default()
    font = ImageFont.truetype(str(font_path),18) if font_path.is_file() else ImageFont.load_default()
    pages, originals = [], []
    for page_number in range(4):
        canvas = Image.new('RGB',(1800,1400),(19,25,29))
        draw = ImageDraw.Draw(canvas)
        draw.text((24,14),'SOURCE QA WITNESSES  |  W: wall ground  H: roof / high face  |  NOT FIELD INPUT',font=title_font,fill=(239,222,174))
        for slot, identity in enumerate(PORTAL_IDS[page_number*4:(page_number+1)*4]):
            door = doors[identity]
            wall = next(p for p in door['input_negative_probes'] if p['kind']=='wall_approach')
            roof = next(p for p in door['input_negative_probes'] if p['kind']=='roof_click')
            path = door['source']
            actual_sha = sha_file(disk(path))
            need(same_hash(actual_sha,door['source_sha256']), 'Original mutated before QA contact annotation: '+identity)
            with Image.open(disk(path)) as image:
                original = image.convert('RGBA')
            px, py = (slot%2)*900, 56+(slot//2)*666
            draw.rectangle((px+10,py+4,px+890,py+654),outline=(81,95,99),width=2)
            draw.text((px+24,py+14),identity+'  source SHA '+actual_sha[:16],font=title_font,fill=(246,234,202))
            scale = min(840/original.width,550/original.height)
            resized = original.resize((round(original.width*scale),round(original.height*scale)),Image.Resampling.LANCZOS)
            ix, iy = px+(900-resized.width)//2, py+54+(550-resized.height)//2
            background = Image.new('RGBA',resized.size,(42,49,52,255))
            grid = ImageDraw.Draw(background)
            for gy in range(0,resized.height,20):
                for gx in range(0,resized.width,20):
                    if (gx//20+gy//20)%2:
                        grid.rectangle((gx,gy,gx+19,gy+19),fill=(52,59,61,255))
            canvas.paste(Image.alpha_composite(background,resized).convert('RGB'),(ix,iy))
            for label, point, color in (('W',wall['source_witness_px'],(255,103,78)),('H',roof['source_witness_px'],(92,224,246))):
                x, y = ix+point[0]*scale, iy+point[1]*scale
                draw.ellipse((x-10,y-10,x+10,y+10),outline=(0,0,0),width=7)
                draw.ellipse((x-8,y-8,x+8,y+8),outline=color,width=4)
                draw.line((x-15,y,x+15,y),fill=color,width=2)
                draw.line((x,y-15,x,y+15),fill=color,width=2)
                lx = min(px+855,max(px+18,x+14))
                ly = min(py+580,max(py+50,y-29))
                draw.rectangle((lx-3,ly-2,lx+19,ly+25),fill=(13,18,21))
                draw.text((lx,ly),label,font=title_font,fill=color)
            text = 'W ground '+str(wall['source_witness_px'])+' | H '+('high rock face ' if identity=='lieyun_valley' else 'roof/high face ')+str(roof['source_witness_px'])
            draw.text((px+24,py+610),text,font=font,fill=(234,224,200))
            draw.text((px+24,py+634),'Original '+str(list(original.size))+' px; only this QA copy is scaled/marked.',font=font,fill=(169,189,192))
            need(same_hash(sha_file(disk(path)),actual_sha),'Original mutated during QA contact annotation: '+identity)
            originals.append({'id':identity,'source':path,'source_sha256':actual_sha,'original_size_px':list(original.size),
              'wall_source_witness_px':wall['source_witness_px'],'roof_or_highface_source_witness_px':roof['source_witness_px'],
              'page_number':page_number+1,'slot':slot+1,'QA_scale':scale,'original_modified':False})
        page_path = destination/('door_source_witnesses_page_%02d.png'%(page_number+1))
        canvas.save(page_path)
        pages.append({'path':str(page_path),'sha256':sha_file(page_path),'size_px':list(canvas.size)})
    index = {'scope':'QA_16_ORIGINAL_COMPOUND_WITNESS_CONTACTS_NOT_RUNTIME_ART_NOT_FIELD_INPUT',
      'source_sha256':source_sha,'status':'PENDING_ROOT_ACTUAL_CONTACT_REVIEW','visual_approved':False,
      'production_approved':False,'original_images_modified':False,'pages':pages,'originals':originals}
    index_path = destination/'door_source_witnesses_index.json'
    with index_path.open('x',encoding='utf-8',newline='\n') as stream:
        json.dump(index,stream,ensure_ascii=False,indent=2,allow_nan=False)
        stream.write('\n')
    return {'index_path':str(index_path),'index_sha256':sha_file(index_path),'pages':pages,
            'scope':index['scope'],'status':'PENDING_ROOT_ACTUAL_CONTACT_REVIEW'}

def main():
    sampling_units = validate_sampling_source_only(False)
    # Fail before expensive reads and before creating any output if capture is
    # unfinished/failed. ROOT234 approval is never copied into the new review.
    after_path = CAPTURE_DIR / 'after.json'
    need(after_path.is_file(), 'ROOT250 after.json absent: capture not yet a completed actual OS0 run')
    after = json.loads(after_path.read_text(encoding='utf-8-sig'))
    after_sha = sha_file(after_path)
    before = json.loads((CAPTURE_DIR/'before.json').read_text(encoding='utf-8-sig'))
    need(type(after.get('actual_os_exit')) is int and after['actual_os_exit'] == 0,
         'ROOT250 actual OS exit is not integer zero')
    need(after.get('source_changes') == [] and after.get('player_file_changes') == [], 'ROOT250 source/player preservation failed')
    need(before.get('entry') == FULL and before.get('gpu') is True, 'ROOT250 is not the actual E GPU entry')
    for path, expected in PINS.items():
        need(same_hash(digest(path), expected), 'Frozen preparation input changed: ' + path)
    source, manifest, report = read(SOURCE), read(MANIFEST), read(REPORT)
    source_sha, manifest_sha, report_sha = digest(SOURCE), digest(MANIFEST), digest(REPORT)
    catalog = manifest.get('asset_sha256')
    need(isinstance(catalog, dict), 'Missing final manifest catalog')
    for path in (FULL, SURFACE, REGIONAL, FOOTPRINT):
        bound(path, catalog)
    need(source.get('status') == 'ART_ASSETS_READY' and source.get('schema_version') == 15 and source.get('world_size') == list(SIZE), 'Final source not ready coordinate15')
    need(source.get('pixel_sampling') == 'round_world_pixel' and source.get('physical_navigation_margin_px') == 0, 'Final sampling/margin changed')
    need(manifest.get('status') == 'ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA' and manifest.get('source_contract_path') == SOURCE, 'Final manifest not candidate-only')
    need(report.get('status') == 'V9C_FULL64_112SEAMS_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_FIELD_REVIEW' and report.get('input_hashes_unchanged_after') is True, 'Actual final technical report incomplete')
    for value in (source, manifest, report):
        need(value.get('visual_approved') is False and value.get('production_approved') is False, 'Capture was mutated into an approval')
        need(value.get('material_revision_identity') == IDENTITY, 'Current E identity absent')
    for entry in (source['capture']['executed_builder'], report['executed_builder']):
        need(entry.get('path') == FULL and same_hash(entry.get('sha256'), PINS[FULL]), 'Actual E executor differs')
    for value in (source, manifest):
        need(value['material_revision_script'].get('path') == SURFACE and same_hash(value['material_revision_script'].get('sha256'), PINS[SURFACE]), 'Actual E surface differs')
    for value in (source['capture'], manifest, report):
        need(value.get('capture_protocol') == PROTOCOL, 'Technical protocol changed')
    need(same_hash(bound(SOURCE, catalog), source_sha) and same_hash(bound(REPORT, catalog), report_sha), 'Final source/report catalog binding differs')
    for entry in (source['capture']['capture_report'], manifest['whole_actual_capture']):
        need(entry.get('path') == REPORT and same_hash(entry.get('sha256'), report_sha), 'Final report binding differs')
    need(len(source['chunks']) == 64 and len(source['seams']) == 112 and len(source['objects']) == 2687 and len(source['portals']) == 16 and len(source['ecology_probes']) == 9, 'Final complete inventory count differs')
    need({row['id']:row['scene_components_path'] for row in source['ecology_probes']} == ECOLOGY_IMAGES,
         'Final Source must retain the exact nine frozen ecology IDs and current source paths')
    revision = report['v9e_revision_evidence']
    need(revision == source['v9e_revision_evidence'] == manifest['v9e_revision_evidence'], 'Final E evidence copies differ')
    need(revision.get('geometry_RF_NAV_body_coordinates_changed_by_revision') is False and len(revision.get('actual_material_creations', [])) == 5 and len(revision.get('actual_attached_material_creations', [])) == 5, 'E geometry/material evidence differs')
    for key, path in (('full', FULL), ('regional', REGIONAL)):
        entry = revision['actual_execution'][key]
        need(entry.get('path') == path and same_hash(entry.get('sha256'), PINS[path]), 'Current actual execution role differs: ' + key)
    need(revision['actual_execution']['full'].get('role') == 'ACTUAL_FULL_EXECUTOR', 'Not an actual full execution')
    archive = read(ARCHIVE)
    frozen_rows(source['objects'], archive['objects'])
    frozen_rows(source['portals'], archive['portals'], ('doorstep_review_image_sha256', 'input_negative_probes'))
    for key in ('routes', 'structures', 'world_size', 'tile_size'):
        need(source[key] == archive[key], 'Frozen world geometry changed: ' + key)
    for key in ('height_rf_sha256', 'terrain_mesh_sha256'):
        need(source['geometry'][key] == archive['geometry'][key], 'Original derived geometry changed: ' + key)
    for path_key, sha_key in (('height_rf_path','height_rf_sha256'), ('terrain_mesh_path','terrain_mesh_sha256')):
        need(same_hash(bound(source['geometry'][path_key],catalog),source['geometry'][sha_key]), 'Actual derived geometry bytes changed: '+path_key)

    # Hash ALL gate-required runtime paths, not only one path per PNG class.
    # 2687 paths contain 44 unique PNG byte classes; ROOT262 representative
    # review can only be carried by explicit exact-SHA alias mapping.
    groups = {'overview': [source['overview_path']],
              'ground': [row['visual_path'] for row in source['chunks']],
              'textures': sorted({row['texture'] for row in source['objects']}),
              'doors': [row['doorstep_review_image_path'] for row in source['portals']],
              'ecology': [row['scene_components_path'] for row in source['ecology_probes']]}
    need([len(groups[k]) for k in groups] == [1, 64, 2687, 16, 9], 'Exact 2768 + 9 required runtime image-path inventory differs')
    required = [p for k in ('overview', 'ground', 'textures', 'doors') for p in groups[k]]
    need(len(set(required)) == 2768 and len(set(required+groups['ecology'])) == 2777, 'Required runtime image paths overlap unexpectedly')
    image_hashes = {path: bound(path, catalog) for path in required+groups['ecology']}
    texture_classes, texture_representatives = texture_alias_map(groups['textures'],image_hashes,read(TEXTURE_INDEX),read(TEXTURE_REGISTRY))
    representative_review_paths = groups['overview']+groups['ground']+sorted(texture_representatives)+groups['doors']+groups['ecology']
    need(len(representative_review_paths) == len(set(representative_review_paths)) == 134, 'Exact 125 + 9 representative visual-review units differ')
    for path in representative_review_paths:
        with Image.open(disk(path)) as image:
            need(image.format == 'PNG' and image.width > 0 and image.height > 0, 'Current reviewed asset not PNG: ' + path)
            if path in texture_representatives:
                need(list(image.size) == texture_classes[image_hashes[path]]['representative_dimensions'], 'Actual final representative dimensions differ')
            image.verify()

    tiles = {}
    for row in source['chunks']:
        rect = row['logical_rect_px']
        need(isinstance(rect, list) and len(rect) == 4, 'Malformed chunk rect')
        x, y, w, h = rect
        need(type(x) in (int,float) and type(y) in (int,float) and x % TILE[0] == 0 and y % TILE[1] == 0 and [w,h] == list(TILE), 'Non-native navigation rect')
        cell = (int(x/TILE[0]), int(y/TILE[1]))
        need(cell not in tiles and 0 <= cell[0] < 8 and 0 <= cell[1] < 8, 'Duplicate/outside navigation tile')
        tiles[cell] = row['walk_path']
    nav_cache = {}
    solids = []
    for kind, rows in (('visual_objects', source['objects']), ('blockers', source.get('blockers', []))):
        for row in rows:
            if kind == 'visual_objects' and 'solid_polygons_px' in row:
                need(isinstance(row['solid_polygons_px'], list) and row['solid_polygons_px'], 'Empty exact solids')
                for poly in row['solid_polygons_px']:
                    native_poly = [vec(p) for p in poly]
                    need(len(native_poly) >= 3, 'Short exact solid')
                    solids.append((row['id'], native_poly, None))
                continue
            size_key = 'collision_size' if kind == 'visual_objects' else 'size'
            if size_key not in row:
                continue
            pos, extent = vec(row['pos']), vec(row[size_key])
            offset = vec(row.get('collision_offset', [0,0])) if kind == 'visual_objects' else [0,0]
            margin = vec(row.get('walkability_margin_px', [18.432,12.288] if kind == 'visual_objects' else [64.512,43.008]))
            center = [f32(f32(pos[i]+offset[i])*SIZE[i]) for i in range(2)]
            size = [f32(extent[i]*SIZE[i]) for i in range(2)]
            need(all(n > 0 for n in size) and all(n >= 0 for n in margin), 'Invalid source collision extent')
            lo = [f32(f32(center[i]-f32(size[i]*.5))-margin[i]) for i in range(2)]
            grown_size = [f32(size[i]+f32(margin[i]*2)) for i in range(2)]
            hi = [f32(lo[i]+grown_size[i]) for i in range(2)]
            solids.append((row['id'], None, (lo,hi)))

    def foot(center):
        samples = shoe_samples(center)
        for index, p in enumerate(samples):
            if not world(p):
                return {'clear':False, 'kind':'invalid_or_outside', 'shoe_index':index, 'point':p}
            pixel = native_world_pixel(p)
            if pixel is None:
                return {'clear':False, 'kind':'rounded_pixel_outside', 'shoe_index':index, 'point':p}
            cell = (pixel[0]//TILE[0], pixel[1]//TILE[1])
            path = tiles[cell]
            if path not in nav_cache:
                bound(path, catalog)
                with Image.open(disk(path)) as img:
                    need(img.size == TILE, 'Non-native actual navigation PNG')
                    nav_cache[path] = img.convert('RGBA')
            rgba = nav_cache[path].getpixel((pixel[0]%TILE[0], pixel[1]%TILE[1]))
            if rgba[3] < 128 or max(rgba[:3]) < 128:
                return {'clear':False, 'kind':'raw_nav', 'shoe_index':index, 'point':p, 'pixel':pixel, 'rgba':list(rgba), 'path':path, 'sha256':hashes[path]}
        for identity, poly, rect in solids:
            for index, p in enumerate(samples):
                occupied = inside(p, poly) if poly is not None else all(rect[0][i] <= p[i] < rect[1][i] for i in range(2))
                if occupied:
                    return {'clear':False, 'kind':'source_collision', 'id':identity, 'shoe_index':index, 'point':p}
        return {'clear':True, 'kind':'full17_CPU_only'}

    suggestions, footprints, prior_draft = read(SUGGESTIONS), read(FOOTPRINT), read(PRIOR_DRAFT)
    old_unsafe = [r for r in prior_draft['unsafe_legal_stands'] if r['portal_id']=='bianzhou' and r['kind']=='wall_approach']
    need(len(old_unsafe)==1 and native(old_unsafe[0]['stand_px'])==native(ROOT_WALL_OVERRIDE['old_legal_start_px']), 'Original unsafe witness evidence changed')
    authoring_record = dict(ROOT_WALL_OVERRIDE,prior_draft_path=PRIOR_DRAFT,prior_draft_sha256=digest(PRIOR_DRAFT),previous_unsafe_evidence=copy.deepcopy(old_unsafe[0]),
      previous_diagnostic_status='RETIRED_NORMALIZED_SIZE_MINUS_ONE_SAMPLER_NO_CURRENT_NAV_CREDIT',
      original_start_current_direct_round_diagnostic=foot(ROOT_WALL_OVERRIDE['old_legal_start_px']))
    need(suggestions.get('status') == 'UNAPPROVED_NOT_EXECUTABLE_REVIEW', 'Suggestions are no longer unapproved source suggestions')
    suggested = {row['portal_id']:row for row in suggestions['doors']}
    portals = {row['id']:row for row in source['portals']}
    need(len(suggested) == len(portals) == 16 and set(suggested) == set(portals) == set(PORTAL_IDS), 'Exact sixteen door identities differ')
    doors, unsafe, problems = {}, [], []
    for identity in PORTAL_IDS:
        portal, proposal, measured = portals[identity], suggested[identity], footprints['landmarks'][identity]
        compound = next(row for row in source['objects'] if row['id'] == portal['compound_id'])
        need(portal['source'] == measured['source'] == proposal['source_binding']['original_path'] == compound['source'], 'Original source path differs: ' + identity)
        original_sha = bound(portal['source'], catalog)
        need(all(same_hash(original_sha, n) for n in (portal['source_sha256'], measured['source_sha256'], proposal['source_binding']['original_sha256'], compound['source_sha256'])), 'Original PNG bytes changed: ' + identity)
        need(same_hash(bound(compound['texture'], catalog), original_sha), 'Runtime compound PNG differs from original: ' + identity)
        source_uv, measured_uv = portal['source_doorstep_uv'], measured['source_doorstep_uv']
        need(pair(source_uv) and pair(measured_uv) and all(0 <= v < 1 for v in source_uv+measured_uv), 'Invalid finite same-dimension doorway UV: '+identity)
        uv_serialization = {'source_scalar_values':copy.deepcopy(source_uv),'footprint_scalar_values':copy.deepcopy(measured_uv),
          'source_native_Float32_bytes':native(source_uv),'footprint_native_Float32_bytes':native(measured_uv),
          'comparison':'FINITE_VECTOR2_SAME_DIMENSION_EXACT_PACKED_FLOAT32_BYTES_NO_TOLERANCE'}
        need(portal['compound_id'] == measured['compound_id'] == proposal['compound_id'] and native(source_uv) == native(measured_uv), 'Compound/native UV authority changed: ' + identity)
        need(native(compound['pos']) == native(proposal['transform']['object_pos']) and native(compound['render_size_px']) == native(proposal['transform']['render_size_px']) and native(portal['door_foot_px']) == native(proposal['transform']['actual_door_foot_px']), 'Suggestion native transform differs: ' + identity)
        need(native(compound['render_size_px']) == native(measured['render_size_px']) and native(compound['foot_uv']) == native(measured['source_doorstep_uv']) and native(compound['world_foot_px']) == native(portal['door_foot_px']), 'Measured compound render/foot binding differs: ' + identity)
        def project_measured(points):
            # Exact exporter source-point formula uses scalar doubles with the
            # actual native doorway. Compare resulting native polygon bits.
            door = vec(portal['door_foot_px'])
            return [[door[i]+(p[i]-measured['source_doorstep_px'][i])*measured['render_size_px'][i]/measured['source_size_px'][i] for i in range(2)] for p in points]
        expected_solids = [project_measured(poly) for poly in measured['solid_polygons_source_px']]
        need(native(expected_solids) == native(compound['solid_polygons_px']), 'Current exact solids differ from original measured footprint: ' + identity)
        for actual_key, measured_key in (('passage_path_px','passage_path_source_px'), ('passage_polygon_px','passage_polygon_source_px'), ('interaction_polygon_px','interaction_polygon_source_px')):
            need(native(portal[actual_key]) == native(project_measured(measured[measured_key])), 'Current doorway geometry differs from measurement: ' + identity+'/'+actual_key)
        with Image.open(disk(portal['source'])) as original:
            need(list(original.size) == measured['source_size_px'] == proposal['source_binding']['actual_size_px'], 'Actual original PNG size differs: ' + identity)
            alpha = original.convert('RGBA').getchannel('A')
        # Preserve captured records if present; explicit malformed records never
        # fall back to independently invented suggestions.
        captured = 'input_negative_probes' in portal
        probes = copy.deepcopy(portal['input_negative_probes'] if captured else proposal['input_negative_probes'])
        need(isinstance(probes,list) and len(probes) == 3 and {p.get('kind') for p in probes} == {'wall_approach','roof_click','wrongside'}, 'Malformed captured/proposed three-mechanism probes: ' + identity)
        row_problems = []
        for probe in probes:
            kind = probe['kind']
            if identity=='bianzhou' and kind=='wall_approach':
                need(not captured,'ROOT standalone wall intention cannot replace captured source negatives')
                need(native(probe['legal_start_px'])==native(ROOT_WALL_OVERRIDE['old_legal_start_px']) and probe['source_witness_px']==ROOT_WALL_OVERRIDE['unchanged_source_witness_px'] and native(probe['blocked_foot_px'])==native(ROOT_WALL_OVERRIDE['unchanged_blocked_foot_px']), 'ROOT wall override must preserve exact original wall witness/target')
                probe['legal_start_px']=copy.deepcopy(ROOT_WALL_OVERRIDE['new_legal_start_px'])
                probe['root_authored_override']=copy.deepcopy(authoring_record)
            sk, tk = ('legal_start_px','blocked_foot_px') if kind == 'wall_approach' else ('legal_stand_px','world_click_px')
            need(world(probe.get(sk)) and world(probe.get(tk)) and native(probe[sk]) != native(probe[tk]), 'Invalid distinct native negative world points: ' + identity+'/'+kind)
            stand = foot(probe[sk])
            if not stand['clear']:
                unsafe.append({'portal_id':identity, 'kind':kind, 'stand_key':sk, 'stand_px':probe[sk], 'CPU_evidence':stand})
            probe['semantic_review_status'] = 'PENDING_ROOT_REVIEW'
            # Old source-only checks are removed, not represented as current
            # complete navigation/continuous physics or successful input.
            probe.pop('stand_geometry', None)
            probe['current_CPU_diagnostic'] = {'scope':'CPU_NATIVE17_SOURCE_NAV_ONLY_NOT_FIELD_PHYSICS_INPUT',
              'pixel_sampling':'NATIVE_FLOAT32_DIRECT_ROUNDI_WORLD_PIXEL_REJECT_ROUNDED_OUTSIDE',
              'stand':stand, 'physics_status':'NOT_RUN', 'input_status':'NOT_RUN', 'reachable_status':'NOT_RUN'}
            if kind == 'wall_approach':
                witness = probe.get('source_witness_px')
                need(witness in measured['solid_ground_source_probes_px'] and any(inside(witness,p) for p in measured['solid_polygons_source_px']), 'Wall witness not registered actual occupied ground: ' + identity)
                target = foot(probe[tk])
                probe['current_CPU_diagnostic']['blocked_target'] = target
                if target.get('kind') != 'source_collision':
                    row_problems.append('wall target oracle kind is '+target['kind']+', actual QA requires source_collision')
            elif kind == 'roof_click':
                uv, witness = probe.get('source_uv'), probe.get('source_witness_px')
                need(pair(uv) and all(0 <= v < 1 for v in uv) and witness == measured['roof_or_high_face_source_probe_px'], 'Roof/high-face witness differs: ' + identity)
                need(all(uv[i] == witness[i]/measured['source_size_px'][i] for i in range(2)), 'Roof UV not exact original witness: ' + identity)
                native_uv = vec(uv)
                px = [min(alpha.size[i]-1,max(0,math.floor(f32(native_uv[i]*alpha.size[i])))) for i in range(2)]
                actual_alpha = alpha.getpixel(tuple(px))
                need(actual_alpha/255 > .12, 'Roof native UV hits transparent pixel: ' + identity)
                pos, render = vec(compound['pos']), vec(compound['render_size_px'])
                projected = [f32(f32(pos[i]*SIZE[i]) + f32(f32(-render[i]*.5)+f32(native_uv[i]*render[i]))) for i in range(2)]
                delta = math.dist(projected, vec(probe[tk]))
                need(delta < .01, 'Roof projection not exact actual native transform: ' + identity)
                probe['current_CPU_diagnostic'].update({'original_native_pixel':px,'alpha_8bit':actual_alpha,'projected_world_click_px':projected,'projection_distance_px':delta})
                if inside(vec(probe[tk]), [vec(q) for q in portal['interaction_polygon_px']]):
                    row_problems.append('roof/high-face target is inside actual door interaction polygon')
            else:
                polygon = [vec(q) for q in portal['interaction_polygon_px']]
                if inside(vec(probe[sk]), polygon) or not inside(vec(probe[tk]), polygon):
                    row_problems.append('wrongside stand/door-click polygon roles invalid')
        # If captured inputs were present, replacing status would violate exact
        # immutable-source equality; flag it for root, never fake source authorship.
        if captured and probes != portal['input_negative_probes']:
            row_problems.append('captured probes require exact unchanged source records; this pending draft is intentionally not gate-executable')
        if identity == 'lieyun_valley':
            row_problems.append('roof_click semantic object is high rock face, not a literal roof')
        problems.extend({'portal_id':identity,'issue':message} for message in row_problems)
        door_image = portal['doorstep_review_image_path']
        need(same_hash(portal['doorstep_review_image_sha256'], image_hashes[door_image]), 'Final doorstep PNG SHA differs: '+identity)
        doors[identity] = {'status':'PENDING_ROOT_REVIEW','source':portal['source'], 'source_sha256':original_sha,
          'compound_id':portal['compound_id'], 'source_doorstep_uv':portal['source_doorstep_uv'], 'door_foot_px':portal['door_foot_px'],
          'source_UV_serialization_diagnostic':uv_serialization,
          'doorstep_review_image_path':door_image, 'doorstep_review_image_sha256':image_hashes[door_image],
          'negative_origin':'CAPTURED_SOURCE_INPUT_NEGATIVES_EXACT_V1' if captured else 'INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1',
          'negative_source_footprint_path':FOOTPRINT, 'negative_source_footprint_sha256':digest(FOOTPRINT),
          'input_negative_probes':probes, 'root_attention':row_problems}
    if 'player_spawn_px' in source:
        need(world(source['player_spawn_px']), 'Explicit invalid source spawn must NOT fall back to Linxi')
        spawn = {'approved':False,'status':'PENDING_ROOT_REVIEW','policy':'EXPLICIT_SOURCE_SPAWN_NO_FALLBACK','foot_px':source['player_spawn_px'],'current_CPU_diagnostic':foot(source['player_spawn_px'])}
    else:
        spawn = {'approved':False,'status':'PENDING_ROOT_REVIEW','policy':'EXACT_REVIEWED_LINXI_DOOR_V1','portal_id':'linxi_village','foot_px':portals['linxi_village']['door_foot_px'],'current_CPU_diagnostic':foot(portals['linxi_village']['door_foot_px'])}
    unchanged_probes = 0
    for identity, door in doors.items():
        previous = {p['kind']:p for p in prior_draft['doors'][identity]['input_negative_probes']}
        for probe in door['input_negative_probes']:
            authored = {k:v for k,v in probe.items() if k!='current_CPU_diagnostic'}
            previous_authored = {k:v for k,v in previous[probe['kind']].items() if k!='current_CPU_diagnostic'}
            if identity=='bianzhou' and probe['kind']=='wall_approach':
                expected=copy.deepcopy(previous_authored)
                expected['legal_start_px']=copy.deepcopy(ROOT_WALL_OVERRIDE['new_legal_start_px'])
                expected['root_authored_override']=copy.deepcopy(authoring_record)
                need(authored==expected,'ROOT wall authoring unexpectedly changed another authored wall field')
                need(probe['current_CPU_diagnostic']['stand']['clear'],'ROOT-authored wall stand is not currently full17 CPU clear')
            else:
                need(authored==previous_authored,'Another independent authored negative probe changed: '+identity+'/'+probe['kind'])
                unchanged_probes+=1
    need(unchanged_probes==47,'All other 47 authored independent probes must remain exactly unchanged; CPU diagnostics alone are refreshed')
    # Prevent time-of-check/time-of-use publication of a stale draft. Rehash
    # all 2777 required image paths plus sampled navigation/source/immutable
    # inputs, not the unrelated multi-GB allcatalog PBR dependency closure.
    for path, expected in hashes.items():
        if path in catalog and path != SOURCE:
            need(same_hash(source['asset_sha256'].get(path),expected), 'Source/manifest bounded catalog disagreement: '+path)
        need(same_hash(sha_file(disk(path)),expected), 'Input changed during draft preparation: '+path)
    need(sha_file(after_path) == after_sha, 'Capture completion record changed during preparation')
    output = {'schema_version':1,'version':15,'capture_protocol':PROTOCOL,
      'scope':'ACTUAL_CURRENT_CAPTURE_VISUAL_REVIEW_NOT_FIELD_INPUT_APPROVAL',
      'status':'DRAFT','visual_approved':False,'production_approved':False,
      'reviewer_role':'producer/root','reviewer':'PENDING_ROOT',
      'review_method':'PENDING_ACTUAL_PNG_INDIVIDUAL_REVIEW',
      'required_final_review_method':'actual_png_individual_review',
      'review_execution_status':'NOT_EXECUTED_DRAFT_SCHEMA_ONLY',
      'source_sha256':source_sha,'manifest_sha256':manifest_sha,
      'whole_capture_report_path':REPORT,'whole_capture_report_sha256':report_sha,
      'material_revision_identity':IDENTITY,'reviewed_assets_sha256':image_hashes,
      'reviewed_image_status':{path:('PENDING_ROOT_SHA_CLASS_ALIAS_BINDING' if path in groups['textures'] and path not in texture_representatives else 'PENDING_ROOT_ACTUAL_PNG_REVIEW') for path in image_hashes},
      'required_image_groups':groups,'required_gate_image_path_count':2768,'additional_ecology_image_path_count':9,
      'frozen_final_Source_ecology_images':ECOLOGY_IMAGES,
      'all_bound_image_path_count':2777,'texture_runtime_path_count':2687,'texture_distinct_PNG_SHA_count':44,
      'texture_SHA_classes':texture_classes,'texture_representative_to_aliases':texture_representatives,
      'representative_visual_review_paths':representative_review_paths,'representative_visual_review_unit_count':134,
      'ROOT262_texture_review_aid':{'path':TEXTURE_INDEX,'sha256':digest(TEXTURE_INDEX),
        'registry_path':TEXTURE_REGISTRY,'registry_sha256':digest(TEXTURE_REGISTRY),
        'status':'PENDING_ROOT_CONFIRM_CURRENT_CLASS_BINDING_NOT_AUTOMATIC_APPROVAL'},
      'doors':doors,'default_spawn':spawn,'portal_count':16,'negative_count':48,
      'unsafe_legal_stands':unsafe,'root_attention':problems,
      'root_authored_negative_override':authoring_record,'other_negative_probe_authorship_exactly_unchanged':47,
      'current_CPU_diagnostics_refreshed_with_direct_world_rounding':48,
      'preparation':{'generator_sha256':sha_file(pathlib.Path(sys.argv[2])),
        'actual_ROOT250_after_path':str(after_path),'actual_ROOT250_after_sha256':after_sha,
        'immutable_inputs_sha256':PINS,'current_hashed_inputs_sha256':hashes,
        'frozen_geometry_comparison':'2687 source objects + 16 portals against immutable ROOT234; native spatial float32 bits, other fields exact',
        'runtime_texture_paths_SHA_bound':2687,'distinct_texture_PNG_SHA_classes':44,
        'all_bound_image_paths':2777,'representative_visual_review_units':134,
        'current_CPU_pixel_sampling':sampling_units['method'],'sampling_boundary_units':sampling_units,
        'retired_diagnostics':{'method':'NORMALIZED_POINT_OVER_SIZE_TIMES_SIZE_MINUS_ONE',
          'current_NAV_exact_credit':False,'reason':'Does not match frozen Source round_world_pixel / contract:155 / gate:888. Prior normalized CPU clear/unsafe results are historical diagnostics only.',
          'preserved_drafts':[{'path':PRIOR_DRAFT,'sha256':digest(PRIOR_DRAFT)},
            {'path':'res://build/joint_v9e_world_visual_review_draft_20261007T053338800126Z_6939719d/visual_review_draft.json',
             'sha256':'322a55ca1c46ac2df416230a205b2fe1c6caac959ddf9f3d6d298a0c5c93ccde'}]},
        'previous_actual_draft_attempts':[{'generator_sha256':'48e0017d0a30aaab8b8a383f2d7e6c40289056ca2c1845d572442818da17e883',
          'actual_script_exit':1,'reason':'Final complete inventory count differs',
          'diagnosis':'Final Source contains 9 ecology probes, not the incorrectly assumed 10; original failed output retained in task tool transcript.',
          'capture_or_gate_modified':False,'draft_output_created':False},
          {'generator_sha256':'7a264115e14bb1bf77ff6a72189aa95504510fc83846af206ff8e2a72f93a877',
           'actual_script_exit':1,'reason':'Compound/UV authority changed: huashan',
           'diagnosis':'JSON scalar source 0.498697916666667 vs footprint 0.4986979166666667 has identical actual Vector2 Float32 bytes 5555ff3e. Exact native-byte comparison authorized for NEW draft only; original output retained in task tool transcript.',
           'capture_or_gate_modified':False,'draft_output_created':False}],
        'CPU_navigation_tiles_read':len(nav_cache),'engine_executed':False,'field_input_executed':False,
        'limits':['No actual image review or approval has been performed by this generator.',
          'All 2687 runtime texture path hashes are measured; they represent 44 exact PNG byte classes, not 2687 independently viewed pictures.',
          'ROOT262 representative SHA classes must match final current Source exactly; aliases do not inherit object placement or Field input approval.',
          'CPU shoes/nav/source polygons are not actual Physics2D or reachable standing-position evidence.',
          'Old normalized bianzhou diagnostic is retained historically with NO current NAV credit; original start is resampled by direct world roundi. ROOT-authored start/wall target and other 47 authored probes are unchanged; all 48 current CPU diagnostics are refreshed.',
          'No source, manifest, report, staging, formal, player or production review file is written.',
          'ROOT must actually inspect current PNGs and explicitly author approval; actual 48 negative inputs remain mandatory.']}}
    build = (GAME/'build').resolve()
    destination = build / ('joint_v9e_world_visual_review_draft_'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'_'+uuid.uuid4().hex[:8])
    need(destination.resolve().parent == build and not destination.exists(), 'Output must be unique immediate BUILD child')
    destination.mkdir()
    output['source_witness_QA_contact_pages']=write_witness_contact_pages(destination,doors,source_sha)
    path = destination/'visual_review_draft.json'
    with path.open('x',encoding='utf-8',newline='\n') as stream:
        json.dump(output,stream,ensure_ascii=False,indent=2,allow_nan=False)
        stream.write('\n')
    print(json.dumps({'status':'DRAFT_NOT_APPROVAL','path':str(path),'sha256':sha_file(path),
      'source_sha256':source_sha,'manifest_sha256':manifest_sha,'report_sha256':report_sha,
      'required_gate_image_paths':2768,'additional_ecology_image_paths':9,'all_bound_image_paths':2777,
      'runtime_texture_paths':2687,'distinct_texture_PNG_SHA_classes':44,'representative_visual_review_units':134,
      'doors':16,'negative_probes':48,
      'unsafe_stand_count':len(unsafe),'unsafe_legal_stands':unsafe,'root_attention':problems,
      'other_negative_probe_authorship_exactly_unchanged':47,'sampling_boundary_units':sampling_units,
      'source_witness_QA_contact_pages':output['source_witness_QA_contact_pages']},ensure_ascii=False,indent=2))

if __name__ == '__main__':
    try:
        if '--validate-pins-only' in sys.argv[3:]:
            validate_pins_only()
        elif '--validate-texture-alias-source-only' in sys.argv[3:]:
            validate_texture_alias_source_only()
        elif '--validate-sampling-source-only' in sys.argv[3:]:
            validate_sampling_source_only()
        else:
            main()
    except Exception as error:
        print('DRAFT_PREPARATION_REFUSED: '+str(error),file=sys.stderr)
        sys.exit(1)
'@
if ($ValidateSourceOnly) {
    $draftProgram | & $Python -c 'import sys; compile(sys.stdin.read(), ''embedded'', ''exec''); print(''Embedded Python syntax valid; no candidate reads, engine execution or output'')'
} elseif ($ValidatePinsOnly) {
    $draftProgram | & $Python - $taskWorkspace $PSCommandPath --validate-pins-only
} elseif ($ValidateTextureAliasSourceOnly) {
    $draftProgram | & $Python - $taskWorkspace $PSCommandPath --validate-texture-alias-source-only
} elseif ($ValidateSamplingSourceOnly) {
    $draftProgram | & $Python - $taskWorkspace $PSCommandPath --validate-sampling-source-only
} else {
    $draftProgram | & $Python - $taskWorkspace $PSCommandPath
}
if ($LASTEXITCODE -ne 0) { throw ('Draft preparation refused; Python exit ' + $LASTEXITCODE) }
