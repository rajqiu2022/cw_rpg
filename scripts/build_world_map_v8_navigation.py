"""Build, inspect and validate road-survey navigation for the adopted v8 image."""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import binary_erosion, label
from world_map_v8_road_survey import ROUTES, PORTALS, WALKABLE, BLOCKED, ROAD_SURFACES, ROAD_CHECK_SECTIONS

ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT/'game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v8_2304.png'
MASK = ROOT/'game/art/navigation_masks/world_map_jianghu_walk_v8.png'
OUT = ROOT/'assets/processed/scene/world_map_v8'
SIZE = (2304,1536)
REFERENCE = (1920,1280)
SURVEYED_BACKGROUND_SHA256 = '6057ea346226519807b148be4f0cf3784def7ca38d0517117879791410849272'

def px(point):
    return tuple(round(point[i]*SIZE[i]/REFERENCE[i]) for i in (0,1))

def write_inspection():
    """Coordinate-labelled source/mask crops; diagnostic only, never new art."""
    OUT.mkdir(parents=True, exist_ok=True)
    background = Image.open(BACKGROUND).convert('RGB').resize(REFERENCE)
    old_mask = Image.open(MASK).convert('L').resize(REFERENCE)
    road = background.copy()
    draw = ImageDraw.Draw(road)
    for x in range(300, 821, 20):
        for y in range(600, 801, 20):
            draw.ellipse((x-1,y-1,x+1,y+1), fill='red')
            if y == 600:
                draw.text((x+2,y+2), str(x), fill='white', stroke_width=1, stroke_fill='black')
            if x == 300:
                draw.text((x+2,y+2), str(y), fill='white', stroke_width=1, stroke_fill='black')
    road.crop((300,600,820,810)).resize((1560,630)).save(OUT/'inspect_village_road_detail.png')
    for name, bounds in {'southwest': (100, 480, 1000, 1080),
                         'northwest': (100, 60, 1000, 610),
                         'northeast': (1120, 50, 1920, 610),
                         'southeast': (1000, 570, 1920, 1170)}.items():
        for mask_on in [False, True]:
            canvas = background.copy().convert('RGBA')
            if mask_on:
                tint = Image.new('RGBA', REFERENCE, (20, 235, 170, 0))
                tint.putalpha(old_mask.point(lambda v: 85 if v else 0))
                canvas = Image.alpha_composite(canvas, tint)
            draw = ImageDraw.Draw(canvas)
            for x in range(0, REFERENCE[0], 50):
                for y in range(0, REFERENCE[1], 50):
                    draw.ellipse((x-1,y-1,x+1,y+1), fill='red')
                    draw.text((x+2,y+2), f'{x},{y}', fill='white', stroke_width=1, stroke_fill='black')
            canvas.crop(bounds).save(OUT/f'inspect_{name}_{"mask" if mask_on else "source"}.png')

def build():
    assert hashlib.sha256(BACKGROUND.read_bytes()).hexdigest() == SURVEYED_BACKGROUND_SHA256, 'Background changed; review the road survey before rebuilding navigation.'
    background=Image.open(BACKGROUND).convert('RGBA')
    assert background.size == SIZE, 'Master dimensions changed; re-review tracing.'
    mask=Image.new('L',SIZE,0); draw=ImageDraw.Draw(mask)
    for name,width,route in ROUTES:
        points=[px(p) for p in route]; w=round(width*1.2)
        draw.line(points,fill=255,width=w,joint='curve')
        for x,y in points:
            r=w/2; draw.ellipse((x-r,y-r,x+r,y+r),fill=255)
    for polygon in ROAD_SURFACES.values():
        draw.polygon([px(p) for p in polygon], fill=255)
    return background,mask

def surface_coverage(mask):
    data=np.asarray(mask)>0
    sections={}
    for name,(start,end) in ROAD_CHECK_SECTIONS.items():
        a=np.array(px(start)); b=np.array(px(end))
        points=np.unique(np.rint(np.linspace(a,b,int(np.linalg.norm(b-a))+1)).astype(int),axis=0)
        hits=sum(bool(data[y,x]) for x,y in points)
        sections[name]={'covered':hits,'samples':len(points)}
    total=sum(s['samples'] for s in sections.values())
    covered=sum(s['covered'] for s in sections.values())
    return {'covered':covered,'samples':total,'percent':round(100*covered/total,2),'sections':sections}

def validate(mask):
    data=np.asarray(mask)>0
    yy,xx=np.ogrid[-5:6,-5:6]
    safe=binary_erosion(data,structure=xx*xx+yy*yy<=25)
    labels,count=label(safe)
    components=[]
    for name,p in PORTALS.items():
        x,y=px(p); component=int(labels[y,x]); assert component, f'{name}: no foot clearance'
        components.append(component)
    assert len(set(components))==1, f'disconnected portal components: {dict(zip(PORTALS,components))}'
    centerline_samples = 0
    for name, width, route in ROUTES:
        for start, end in zip(route, route[1:]):
            a=np.array(px(start)); b=np.array(px(end))
            for t in np.linspace(0,1,max(2,int(np.linalg.norm(b-a)/2)+1)):
                x,y=np.rint(a+(b-a)*t).astype(int)
                assert labels[y,x] == components[0], f'{name}: disconnected/narrow centerline at {x},{y}'
                centerline_samples += 1
    for name,p in WALKABLE.items():
        x,y=px(p); assert data[y,x], f'visible road blocked: {name} {p}'
    for name,p in BLOCKED.items():
        x,y=px(p); assert not data[y,x], f'non-road walkable: {name} {p}'
    coverage=surface_coverage(mask)
    assert coverage['covered']==coverage['samples'], f'painted road surface gaps: {coverage}'
    return {'portal_count':len(PORTALS),'foot_clearance_px':5,'all_portals_connected':True,
            'walkable_pixels':int(data.sum()),'semantic_road_checks':len(WALKABLE),'semantic_block_checks':len(BLOCKED),
            'centerline_foot_clearance_samples':centerline_samples,'surface_coverage':coverage}

def main():
    old_mask=Image.open(MASK).convert('L') if MASK.exists() else None
    background,mask=build(); report=validate(mask)
    if old_mask is not None:
        report['previous_surface_coverage']=surface_coverage(old_mask)
        previous_path=OUT/'navigation_validation.json'
        if previous_path.exists():
            previous=json.loads(previous_path.read_text(encoding='utf-8'))
            # Keep the first comparison on idempotent rebuilds, not a false
            # 100% -> 100% "before" after the adopted mask was already replaced.
            if previous.get('mask_sha256')==hashlib.sha256(MASK.read_bytes()).hexdigest():
                report['previous_surface_coverage']=previous.get('previous_surface_coverage',report['previous_surface_coverage'])
    OUT.mkdir(parents=True,exist_ok=True); MASK.parent.mkdir(parents=True,exist_ok=True)
    mask.save(MASK,optimize=True)
    color=Image.new('RGBA',SIZE,(40,225,180,0));color.putalpha(mask.point(lambda v:115 if v else 0))
    overlay=Image.alpha_composite(background,color);d=ImageDraw.Draw(overlay)
    for name,p in PORTALS.items():
        x,y=px(p);d.ellipse((x-4,y-4,x+4,y+4),fill='yellow');d.text((x+7,y),name,fill='white',stroke_width=1,stroke_fill='black')
    overlay.save(OUT/'world_map_v8_navigation_overlay.png',optimize=True)
    if old_mask is not None:
        old_color=Image.new('RGBA',SIZE,(245,80,50,0));old_color.putalpha(old_mask.point(lambda v:105 if v else 0))
        before=Image.alpha_composite(background,old_color)
        bounds=(*px((300,600)),*px((820,810)))
        if not (OUT/'linxi_road_before.png').exists():
            before.crop(bounds).save(OUT/'linxi_road_before.png')
        overlay.crop(bounds).save(OUT/'linxi_road_after.png')
    report['background_sha256']=hashlib.sha256(BACKGROUND.read_bytes()).hexdigest()
    report['mask_sha256']=hashlib.sha256(MASK.read_bytes()).hexdigest()
    report['routes']=len(ROUTES)
    (OUT/'navigation_validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--inspect-only', action='store_true')
    args = parser.parse_args()
    write_inspection() if args.inspect_only else main()
