"""Read-only finite current Luaoyang Variant-bundle inventory; no engine/formal writes."""
from pathlib import Path
import struct, json, hashlib

GAME = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent

class Reader:
    def __init__(self, data): self.data, self.at = data, 0
    def get(self, fmt):
        value = struct.unpack_from('<' + fmt, self.data, self.at)
        self.at += struct.calcsize('<' + fmt)
        return value[0] if len(value) == 1 else list(value)
    def string(self):
        n = self.get('I'); text = self.data[self.at:self.at+n].decode('utf-8')
        self.at += (n + 3) & ~3
        return text
    def value(self):
        header = self.get('I'); kind, wide = header & 0xffff, bool(header & (1 << 16))
        if kind == 0: return None
        if kind == 1: return bool(self.get('I'))
        if kind == 2: return self.get('q' if wide else 'i')
        if kind == 3: return self.get('d' if wide else 'f')
        if kind in (4, 21): return self.string()
        counts = {5:2, 7:4, 9:3, 11:6, 12:4, 14:4, 15:4, 16:6, 17:9, 18:12, 19:16, 20:4}
        if kind in counts: return self.get(('d' if wide else 'f') * counts[kind])
        if kind in (6, 8, 10, 13): return self.get('i' * {6:2,8:4,10:3,13:4}[kind])
        if kind == 27:
            n = self.get('I') & 0x7fffffff; out = {}
            for _ in range(n):
                key = self.value(); value = self.value()
                out[str(key)] = value
            return out
        if kind == 28:
            typed = (header >> 16) & 3
            if typed == 1: self.get('I')
            elif typed == 2: self.string()
            elif typed == 3: self.value()
            return [self.value() for _ in range(self.get('I') & 0x7fffffff)]
        if kind == 29:
            n = self.get('I'); value = list(self.data[self.at:self.at+n]); self.at += (n+3)&~3
            return value
        if kind in (30,31,32,33):
            fmt = {30:'i',31:'q',32:'f',33:'d'}[kind]
            return [self.get(fmt) for _ in range(self.get('I'))]
        if kind == 34: return [self.string() for _ in range(self.get('I'))]
        if kind in (35,36,37,38):
            count = {35:2,36:3,37:4,38:4}[kind]; fmt = ('d' if wide else 'f') * count
            return [self.get(fmt) for _ in range(self.get('I'))]
        raise ValueError((kind, header, self.at))

def physical(path): return GAME / path.removeprefix('res://')
def decode(path):
    data = physical(path).read_bytes(); reader = Reader(data); value = reader.value()
    assert reader.at == len(data), (path, reader.at, len(data))
    return value
def f32(value): return struct.unpack('<f',struct.pack('<f',value))[0]
def exact_region_solids(bundle, row):
    source = row.get('source_row', {})
    raw = source.get('city_v3_solid_polygons_px', [])
    if not raw: return []
    old = source['world_foot_px']; delta = [f32(row['foot_px'][i]-old[i]) for i in range(2)]
    selected = []
    for polygon in raw:
        expected = [[f32(p[i]+delta[i]) for i in range(2)] for p in polygon]
        matches = [i for i,p in enumerate(bundle['solids']) if p == expected]
        assert len(matches) == 1, (row['id'], expected, matches)
        selected.append(matches[0])
    return selected
def size_summary(row):
    size = row.get('render_size_px',row.get('source_row',{}).get('render_size_px',[]))
    if not size and row.get('texture_size_px'): size=[row['texture_size_px'][i]*row['scale'][i]for i in range(2)]
    return size
def selected_small(row):
    texture = row.get('texture','').split('/')[-1]
    return texture in ('v13_market_west_plot_wall.png','v13_gate_west_plot_wall_1.png','broken_vermilion_wall_v1.png')
def main():
    manifest = json.loads(physical('res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json').read_text(encoding='utf-8'))
    finish = json.loads(physical('res://build/luoyang_gate_front_walls_20261101c_system01/closure_READY01/finish8_binding_READY.json').read_text(encoding='utf-8'))
    paths = {key:row['path'] for key,row in manifest['compiled_bindings'].items() if key.startswith('luoyang_')}
    paths.update({key:row['payload']['path'] for key,row in finish['scenes'].items()})
    decoded = {}; walls = []
    for key,path in paths.items():
        value = decode(path); decoded[key] = value
        arrays = [value.get('render', []), value.get('visual_additions', []), value.get('effective_navigation', []), value.get('parent_navigation', [])]
        for array_name,array in zip(['render','visual_additions','effective_navigation','parent_navigation'],arrays):
            for index,row in enumerate(array):
                if isinstance(row,dict) and any(word in json.dumps(row,ensure_ascii=False).lower() for word in ['wall','围墙']):
                    walls.append({'scene':key,'path':path,'array':array_name,'index':index,'row':row})
    (OUT/'decoded_current.json').write_text(json.dumps(decoded,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'wall_inventory_READONLY.json').write_text(json.dumps(walls,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    selected_scenes=['luoyang_civic_market_region_27d','luoyang_estate_region_27d','luoyang_temple_region_27d','ch4_s2_canal_docks','luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap']
    spec={'status':'FINITE28_CURRENT_OWNER_PUBLICATION_CANDIDATE_NOT_FIELD_RESULT','scenes':{},'source_pins':{}}
    for key in selected_scenes:
        value=decoded[key]; region='render'in value
        rows=value['render']if region else value['visual_additions']
        owners=[]
        for index,row in enumerate(rows):
            if not selected_small(row):continue
            solids=exact_region_solids(value,row) if region else [i for i,p in enumerate(value['effective_solids']) if p in row.get('city_v3_solid_polygons_px',[])]
            assert len(solids)==len(row.get('source_row',row).get('city_v3_solid_polygons_px',[])),row['id']
            navigation=[] if region else [i for i,n in enumerate(value['effective_navigation']) if n==row]
            if not region:assert len(navigation)==1,row['id']
            owners.append({'id':row['id'],'render_index':index,'solid_indices':solids,'navigation_indices':navigation,'foot':row.get('foot_px',row.get('world_foot_px')),'render_size':size_summary(row),'texture':row['texture']})
        binding=manifest['compiled_bindings'][key]if region else finish['scenes'][key]['payload']
        row={'kind':'REGION'if region else 'LEGACY','binding':binding,'owners':owners,'original_solid_count':len(value['solids']if region else value['effective_solids'])}
        if not region:row['mask']=finish['scenes'][key]['mask']
        if key=='luoyang_civic_market_region_27d':row['ground_join']=[620,2264,4904,40]
        spec['scenes'][key]=row;spec['source_pins'][paths[key]]=hashlib.sha256(physical(paths[key]).read_bytes()).hexdigest()
        if not region and row['mask']['kind']=='IMPORTED_RGBA8':
            spec['source_pins'][row['mask']['path']]=row['mask']['sha256']
    spec['total_actual_retired_owners']=sum(len(r['owners'])for r in spec['scenes'].values())
    assert spec['total_actual_retired_owners']==28
    (OUT/'publication_spec_READY.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'actual28':{k:{'owners':len(v['owners']),'solids':sum(len(r['solid_indices'])for r in v['owners']),'mask':v.get('mask',{}).get('kind')}for k,v in spec['scenes'].items()}},ensure_ascii=False))
    print(json.dumps({'scenes':len(paths),'wall_rows':len(walls),'keys':{k:list(v.keys())for k,v in decoded.items()}},ensure_ascii=False))
if __name__ == '__main__': main()
