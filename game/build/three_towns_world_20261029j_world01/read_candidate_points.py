"""Read-only candidate native mask/old polygon survey; not a runtime approval."""
import json, math
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'game/art/maps/world_map_v15_complete_v9c'
tiles={}
def pixel_ok(x,y):
    x=int(math.floor(x+.5)); y=int(math.floor(y+.5))
    if not 0<=x<12288 or not 0<=y<8192:return False
    key=(x//1536,y//1024)
    if key not in tiles:tiles[key]=Image.open(OUT/f'chunks/r{key[1]}_c{key[0]}_walk.png').convert('RGBA')
    r,g,b,a=tiles[key].getpixel((x%1536,y%1024))
    return a>=128 and max(r,g,b)>=128
def foot_ok(p):
    offsets=[(0,0)]+[(math.cos(math.tau*i/16)*10,math.sin(math.tau*i/16)*6) for i in range(16)]
    return all(pixel_ok(p[0]+dx,p[1]+dy) for dx,dy in offsets)
routes={
 'desert_northwestern_branch':[(3100,1100),(2700,1120),(2000,1200),(1100,1200),(650,1200),(650,1050)],
 'redrock_northwestern_branch':[(2000,1200),(2000,1050)],
 'lanxi_southwestern_branch':[(1400,5728.84375),(1400,6000),(1400,6100),(900,6160),(900,6000)],
}
report={}
for name,points in routes.items():
    bad=[]; total=0
    for a,b in zip(points,points[1:]):
        n=max(1,math.ceil(math.dist(a,b)/8))
        for i in range(n+1):
            p=(a[0]+(b[0]-a[0])*i/n,a[1]+(b[1]-a[1])*i/n);total+=1
            if not foot_ok(p):bad.append(p)
    report[name]={'route':points,'mask_foot_samples':total,'failed':len(bad),'first_bad':bad[:6]}
report['warning']='MASK ONLY, no Godot/world solid-margin/landmark footprint clearance credit; new icon source bodies and feet require runtime testing.'
print(json.dumps(report,ensure_ascii=False))
