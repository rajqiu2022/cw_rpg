"""Independent new-map data/35x25-foot connectivity audit. Stdlib; stdout only.
No Godot, imports, save reads, source writes, author module execution or repo scan.
"""
from pathlib import Path
from collections import deque
import argparse, ast, hashlib, json, math, re, struct, xml.etree.ElementTree as ET

ROOT=Path('F:/Code/RPG_GAME'); GAME=ROOT/'game'
IDS=('adventure_zhuwei_hunting_ground','adventure_xiangzhou_deep_mine','adventure_luoyang_riverside_route')
HALF=(17.5,12.5); STEP=24; EPS=1e-7
FILES={}; ERRORS=[]; CHECKS=0
def need(ok,label):
    global CHECKS
    CHECKS+=1
    if not ok:ERRORS.append(label)
    return ok
def path(uri):
    p=GAME/uri[6:] if uri.startswith('res://') else ROOT/uri
    p=p.resolve();assert p.is_relative_to(GAME.resolve()),('outside game scope',uri)
    return p
def read(uri):
    p=path(uri);b=p.read_bytes();FILES[str(p.relative_to(ROOT)).replace('\\','/')]={'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)};return b
def evaluate(node):
    if isinstance(node,ast.Constant):return node.value
    if isinstance(node,(ast.List,ast.Tuple)):return [evaluate(v) for v in node.elts]
    if isinstance(node,ast.Dict):return {evaluate(k):evaluate(v) for k,v in zip(node.keys,node.values)}
    if isinstance(node,ast.UnaryOp) and isinstance(node.op,(ast.USub,ast.UAdd)):return evaluate(node.operand)*(-1 if isinstance(node.op,ast.USub) else 1)
    if isinstance(node,ast.Name) and node.id in ('true','false','null'):return {'true':True,'false':False,'null':None}[node.id]
    if isinstance(node,ast.Call) and isinstance(node.func,ast.Name):
        name=node.func.id;a=[evaluate(x) for x in node.args]
        if name in ('ExtResource','SubResource'):return {'$'+name:a[0]}
        if name in ('Vector2','Vector2i','Rect2','Color'):return a
        if name=='PackedVector2Array':return a[0] if len(a)==1 and isinstance(a[0],list) else [a[i:i+2] for i in range(0,len(a),2)]
        if name in ('TypedArray','PackedStringArray'):return a[0] if len(a)==1 and isinstance(a[0],list) else a
    raise ValueError('non-literal Godot expression: '+ast.dump(node))
def value(text):
    text=re.sub(r'&(?=")','',text.strip());text=re.sub(r'Array\[[A-Za-z0-9_]+\]\s*\(','TypedArray(',text)
    return evaluate(ast.parse(text,mode='eval').body)
def tres(uri):
    text=read(uri).decode('utf-8-sig');ext={};props={};active=False
    for line in text.splitlines():
        if line.startswith('[ext_resource '):
            attrs=dict(re.findall(r'(\w+)="([^"]*)"',line));ext[attrs['id']]=attrs['path']
        if line.startswith('['):active=line=='[resource]';continue
        if active and '=' in line and not line.lstrip().startswith('#'):
            key,raw=line.split('=',1);props[key.strip()]=value(raw)
    return {'uri':uri,'props':props,'ext':ext}
def reference(doc,key):return doc['ext'][doc['props'][key]['$ExtResource']]
def rect_hit(a,b):return a[0]<=b[0]+b[2]+EPS and b[0]<=a[0]+a[2]+EPS and a[1]<=b[1]+b[3]+EPS and b[1]<=a[1]+a[3]+EPS
def in_rect(p,r):return r[0]-EPS<=p[0]<=r[0]+r[2]+EPS and r[1]-EPS<=p[1]<=r[1]+r[3]+EPS
def cross(a,b):return a[0]*b[1]-a[1]*b[0]
def sub(a,b):return (a[0]-b[0],a[1]-b[1])
def inside(p,poly):
    result=False
    for a,b in zip(poly,poly[1:]+poly[:1]):
        d=sub(b,a);q=sub(p,a)
        if abs(cross(d,q))<EPS and min(a[0],b[0])-EPS<=p[0]<=max(a[0],b[0])+EPS and min(a[1],b[1])-EPS<=p[1]<=max(a[1],b[1])+EPS:return True
        if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:result=not result
    return result
def clip_segment(a,b,r):
    low=0.;high=1.;d=sub(b,a)
    for coordinate in (0,1):
        minimum=r[coordinate]+EPS;maximum=r[coordinate]+r[coordinate+2]-EPS
        if abs(d[coordinate])<EPS:
            if not minimum<a[coordinate]<maximum:return False
        else:
            t1=(minimum-a[coordinate])/d[coordinate];t2=(maximum-a[coordinate])/d[coordinate]
            low=max(low,min(t1,t2));high=min(high,max(t1,t2))
            if low>=high:return False
    return low<high
class Mask:
    def __init__(self,uri,size):
        root=ET.fromstring(read(uri));self.shapes=[];self.edges=[];self.tags=[]
        assert float(root.attrib['width'])==size[0] and float(root.attrib['height'])==size[1],'mask native size differs'
        for element in list(root):
            tag=element.tag.rsplit('}',1)[-1];attr=element.attrib;fill=attr.get('fill','black').lower()
            assert fill in ('white','#fff','#ffffff','black','#000','#000000'),('unsupported mask fill',fill)
            white=fill in ('white','#fff','#ffffff')
            assert 'transform' not in attr and 'stroke' not in attr,'transformed/stroked SVG needs separate native proof'
            if tag=='rect':
                x=float(attr.get('x',0));y=float(attr.get('y',0));w=float(attr['width']);h=float(attr['height']);poly=[(x,y),(x+w,y),(x+w,y+h),(x,y+h)]
            elif tag=='polygon':
                raw=[float(x) for x in re.findall(r'[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?',attr['points'])];poly=[tuple(raw[i:i+2]) for i in range(0,len(raw),2)]
            else:raise ValueError('unsupported nav primitive '+tag)
            self.shapes.append((white,poly))
            self.tags.append(tag)
        # This exact authored form permits analytic full-foot tests, not center samples.
        whites=[poly for white,poly in self.shapes if white]
        self.simple=len(whites)==1 and len(self.shapes)>=2 and self.tags[0]=='rect' and not self.shapes[0][0] and self.shapes[1][0] and all(white or self.tags[i]=='rect' for i,(white,poly) in enumerate(self.shapes[2:],2))
        self.outline=whites[0] if self.simple else None
        self.black_rects=[]
        if self.simple:
            for white,poly in self.shapes[2:]:
                if not white:self.black_rects.append((poly[0][0],poly[0][1],poly[2][0]-poly[0][0],poly[2][1]-poly[0][1]))
            self.edges=list(zip(self.outline,self.outline[1:]+self.outline[:1]))
        else:
            # Retain only actual white/black boundaries, splitting at all intersections.
            edges=[(a,b) for _,poly in self.shapes for a,b in zip(poly,poly[1:]+poly[:1])]
            for a,b in edges:
                d=sub(b,a);length=math.hypot(*d)
                if not length:continue
                cuts={0.,1.}
                for c,e in edges:
                    v=sub(e,c);den=cross(d,v)
                    if abs(den)<EPS:continue
                    t=cross(sub(c,a),v)/den;u=cross(sub(c,a),d)/den
                    if 0<t<1 and -EPS<=u<=1+EPS:cuts.add(t)
                cuts=sorted(cuts)
                for lo,hi in zip(cuts,cuts[1:]):
                    mid=(lo+hi)*.5;p=(a[0]+d[0]*mid,a[1]+d[1]*mid);n=(-d[1]/length*.0001,d[0]/length*.0001)
                    if self.point((p[0]+n[0],p[1]+n[1]))!=self.point((p[0]-n[0],p[1]-n[1])):self.edges.append(((a[0]+d[0]*lo,a[1]+d[1]*lo),(a[0]+d[0]*hi,a[1]+d[1]*hi)))
    def point(self,p):
        result=False
        for white,poly in self.shapes:
            if inside(p,poly):result=white
        return result
    def whole(self,r):
        corners=[(r[0],r[1]),(r[0]+r[2],r[1]),(r[0]+r[2],r[1]+r[3]),(r[0],r[1]+r[3])]
        if self.simple:
            if not all(inside(p,self.outline) for p in corners) or any(rect_hit(r,b) for b in self.black_rects):return False
        elif not all(self.point(p) for p in corners):return False
        return not any(clip_segment(a,b,r) for a,b in self.edges)
def texture_size(uri):
    p=path(uri)
    if p.suffix=='.png':
        b=read(uri);assert b[:8]==b'\x89PNG\r\n\x1a\n';return struct.unpack('>II',b[16:24])
    doc=tres(uri);props=doc['props'];region=props.get('region')
    assert region and '$ExtResource' in props['atlas'],'real native AtlasTexture alias required'
    atlas=texture_size(doc['ext'][props['atlas']['$ExtResource']])
    assert region[0]>=0 and region[1]>=0 and region[0]+region[2]<=atlas[0]+EPS and region[1]+region[3]<=atlas[1]+EPS,'alias region outside source'
    return region[2:]
def vec(v,size):return (v[0]*size[0],v[1]*size[1])
def audit(scene_id,spec,sites):
    scene=tres('res://data/scenes/'+scene_id+'.tres');s=scene['props'];layout=tres(reference(scene,'map_layout'));m=layout['props'];stream=tres(reference(scene,'streamed_background'));bg=stream['props'];size=bg['logical_size']
    need(s['scene_id']==scene_id and s.get('is_walkable') is True and s.get('actor_positions_are_feet') is True and s.get('encounter_chance')==0,scene_id+':TRUE_FEET_RANDOM_RATE_ZERO')
    need(m['design_size']==size==spec['size'] and list(vec(s['player_spawn'],size))==spec['spawn'],scene_id+':REAL_STREAM_WORLD_SIZE_AND_SPAWN')
    for doc in (scene,layout,stream):
        for uri in doc['ext'].values():need(path(uri).is_file(),scene_id+':EXT_RESOURCE_EXISTS:'+uri)
    aliases=[];chunks=bg.get('desktop_chunks') or bg['mobile_chunks'];area=0
    for platform in ('mobile_chunks','desktop_chunks'):
        rows=bg.get(platform,[]);need(len({r['path'] for r in rows})==len(rows),scene_id+':STREAM_CACHE_PATH_UNIQUE:'+platform)
    for row in chunks:
        uri=row['path'];native=texture_size(uri);scale=row.get('draw_scale',1);r=row['logical_rect'];position=row['draw_position']
        need(0<scale<=1 and position[0]<=r[0]+EPS and position[1]<=r[1]+EPS and position[0]+native[0]*scale>=r[0]+r[2]-EPS and position[1]+native[1]*scale>=r[1]+r[3]-EPS,scene_id+':NATIVE_TILE_COVERS_OWN_LOGICAL_RECT:'+uri)
        area+=r[2]*r[3];aliases.append({'path':uri,'logical_rect':r,'native_size':native,'scale':scale})
    need(abs(area-size[0]*size[1])<EPS and all(not (max(a['logical_rect'][0],b['logical_rect'][0])<min(a['logical_rect'][0]+a['logical_rect'][2],b['logical_rect'][0]+b['logical_rect'][2])-EPS and max(a['logical_rect'][1],b['logical_rect'][1])<min(a['logical_rect'][1]+a['logical_rect'][3],b['logical_rect'][1]+b['logical_rect'][3])-EPS) for i,a in enumerate(aliases) for b in aliases[i+1:]),scene_id+':BACKGROUND_COVERAGE_NO_ALIAS_OVERLAP_OR_HOLE')
    physical=[];logic=[]
    for row in m.get('blockers',[]):
        p=vec(row['pos'],size);z=vec(row['size'],size);margin=float(row.get('walkability_margin',.014))
        physical.append((p[0]-z[0]/2,p[1]-z[1]/2,*z));logic.append((p[0]-z[0]/2-margin*size[0],p[1]-z[1]/2-margin*size[1],z[0]+2*margin*size[0],z[1]+2*margin*size[1]))
        need(margin==0,scene_id+':EXPLICIT_ZERO_NATIVE_BLOCKER_MARGIN:'+str(row.get('id')))
    for row in m.get('visual_objects',[]):
        need(path(row['texture']).is_file(),scene_id+':VISUAL_SOURCE_EXISTS:'+str(row.get('id')))
        scale=row.get('scale',[1,1]);need(0<scale[0]<=1 and abs(scale[0]-scale[1])<EPS and 'render_size_px' not in row,scene_id+':UNIFORM_NATIVE_SHRINK:'+str(row.get('id')))
        if 'collision_size' in row:
            p=vec([row['pos'][i]+row.get('collision_offset',[0,0])[i] for i in (0,1)],size);z=vec(row['collision_size'],size)
            physical.append((p[0]-z[0]/2,p[1]-z[1]/2,*z));logic.append((p[0]-z[0]/2-.004*size[0],p[1]-z[1]/2-.004*size[1],z[0]+.008*size[0],z[1]+.008*size[1]))
    mask=Mask(m['walkable_mask_path'],size)
    def safe(p):
        r=(p[0]-HALF[0],p[1]-HALF[1],HALF[0]*2,HALF[1]*2)
        return r[0]>=0 and r[1]>=0 and r[0]+r[2]<=size[0] and r[1]+r[3]<=size[1] and not any(rect_hit(r,b) for b in physical) and not any(in_rect(p,b) for b in logic) and mask.whole(r)
    points={'spawn':vec(s['player_spawn'],size)}
    for row in m.get('portals',[]):
        points['portal:'+row['id']]=vec(row['pos'],size)
        target=row.get('target_scene','');need(bool(target) and path('res://data/scenes/'+target+'.tres').is_file(),scene_id+':REAL_PORTAL_TARGET_EXISTS:'+target)
        need(target==spec['return']['target_scene'] and max(abs(row['target_pos'][i]-spec['return']['target_pos'][i]) for i in (0,1))<EPS,scene_id+':EXACT_PAIRED_ORIGINAL_RETURN_TARGET')
    for row in spec.get('points',[]):points['point:'+row['id']]=row['foot'];need(row.get('kind') in ('clue','challenge','shortcut'),scene_id+':EXPLICIT_OPTIONAL_KIND:'+row['id'])
    for row in sites:
        if row['scene_id']==scene_id:points['gather:'+row['id']]=row['foot'];need(path(row['texture']).is_file(),scene_id+':GATHER_ART_EXISTS:'+row['id'])
    for row in m.get('walkable_probes',[]):points.setdefault('probe:'+row['id'],vec(row['pos'],size))
    feet={name:{'foot':p,'full35x25_clear':safe(p)} for name,p in points.items()}
    for name,item in feet.items():need(item['full35x25_clear'],scene_id+':FULL35X25_MASK_AND_PHYSICAL_AND_LOGIC_CLEAR:'+name)
    width=math.ceil(size[0]/STEP);height=math.ceil(size[1]/STEP);cache={}
    def center(cell):return (cell[0]*STEP+STEP/2,cell[1]*STEP+STEP/2)
    def cell_safe(cell):
        if not (0<=cell[0]<width and 0<=cell[1]<height):return False
        if cell not in cache:cache[cell]=safe(center(cell))
        return cache[cell]
    def link(a,b):
        pivot=(b[0],a[1])
        for p,q in ((a,pivot),(pivot,b)):
            n=max(1,math.ceil(math.dist(p,q)/12))
            if not all(safe((p[0]+(q[0]-p[0])*i/n,p[1]+(q[1]-p[1])*i/n)) for i in range(n+1)):return False
        return True
    def candidates(p):
        c=(int(p[0]//STEP),int(p[1]//STEP))
        for radius in (0,1,2):
            for y in range(c[1]-radius,c[1]+radius+1):
                for x in range(c[0]-radius,c[0]+radius+1):
                    cell=(x,y)
                    if cell_safe(cell) and link(p,center(cell)):yield cell
    starts=list(candidates(points['spawn']));visited=set(starts);queue=deque(starts)
    while queue:
        c=queue.popleft()
        for d in ((1,0),(-1,0),(0,1),(0,-1)):
            n=(c[0]+d[0],c[1]+d[1])
            if n not in visited and cell_safe(n):visited.add(n);queue.append(n)
    for name,item in feet.items():
        item['connected_to_spawn_24px_four_neighbor_full_foot']=item['full35x25_clear'] and any(cell in visited for cell in candidates(item['foot']))
        need(item['connected_to_spawn_24px_four_neighbor_full_foot'],scene_id+':SPAWN_CONNECTED:'+name)
    return {'size':size,'stream_aliases':aliases,'blockers':len(physical),'mask_analytic_simple':mask.simple,'points':feet,'connected_grid_cells':len(visited),'grid_step':STEP,'continuous_cardinal_coverage':'24px step <=25px foot height: adjacent complete footprints overlap; links subdivided12px','runtime_spec_semantic_sha256':hashlib.sha256(json.dumps(spec,sort_keys=True).encode()).hexdigest(),'Luoyang_public_Region_return_not_claimed':scene_id=='adventure_luoyang_riverside_route'}

parser=argparse.ArgumentParser();parser.add_argument('--scene',action='append',choices=IDS);parser.add_argument('--config',action='append');parser.add_argument('--gather',action='append');args=parser.parse_args()
selected=args.scene or list(IDS);maps={};gather_sites=[]
for uri in args.config or ['game/data/maps/adventure_20261030k/adventure_config.json']:
    for row in json.loads(read(uri)).get('maps',[]):maps[row['scene_id']]=row
for uri in args.gather or ['game/data/maps/adventure_20261030k/gathering_additions.json']:
    gather_sites.extend(json.loads(read(uri)).get('sites',[]))
results={}
for scene in selected:
    try:
        need(scene in maps,scene+':RUNTIME_SPEC_PRESENT')
        if scene in maps:results[scene]=audit(scene,maps[scene],gather_sites)
    except Exception as error:need(False,scene+':STATIC_INPUT_OR_PARSER_ERROR:'+repr(error))
print(json.dumps({'passed':not ERRORS,'checks':CHECKS,'errors':ERRORS,'scope_scene_ids':selected,'maps':results,'read_inputs':FILES,'engine_calls':0,'source_or_PNG_writes':0,'save_access':0,'not_runtime_Physics_or_real_portal_route_acceptance':True,'old_city_World11doors_crafting754_gather146_retested':False},ensure_ascii=False,indent=2))
raise SystemExit(1 if ERRORS else 0)
