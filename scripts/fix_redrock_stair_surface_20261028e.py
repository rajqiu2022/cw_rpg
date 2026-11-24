"""Separate traversable stair surface from native cheek overlays; no raster changes."""
import json
import re
import shutil
from pathlib import Path

from build_redrock_town_20261028a import ROOT,sha,save,vec,poly

NAME='redrock_stair_surface_20261028e'
STAGE=ROOT/'assets/staging'/NAME
D='redrock_desert_complete_20261028d'
PROJECT=ROOT/'assets/staging'/D/'town_project'
SCENE=f'scenes/drafts/{D}/redrock_town.tscn'
LEFT=[[470,678],[477,600],[535,575],[649,338],[660,292],[715,280],[745,300],[744,335],[716,352],[633,499],[573,611],[536,647],[532,688]]
RIGHT=[[884,729],[890,649],[927,626],[1026,383],[1035,326],[1074,315],[1118,332],[1124,551],[981,653],[977,720],[949,736]]

def run():
    assert not (STAGE/'scene-before.tscn').exists()
    STAGE.mkdir(parents=True,exist_ok=True)
    source=ROOT/'game'/SCENE;private=PROJECT/SCENE
    assert source.read_bytes()==private.read_bytes()
    shutil.copyfile(source,STAGE/'scene-before.tscn')
    protected=[ROOT/'game/project.godot',ROOT/'game/scripts/field/player.gd',ROOT/'game/scripts/autoload/scene_router.gd',ROOT/'game/scripts/drafts'/D/'town_controller.gd',ROOT/'game/art/modules'/D/'stairs.png']
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in protected])
    text=source.read_text('utf-8');overlays=[];rows=[]
    for name in ['LaneStairs','LookoutStairs','WestLaneStairs']:
        pattern=r'(\[node name="Art" type="Sprite2D" parent="Town/'+name+r'"\]\n)([\s\S]*?)(?=\[node|\Z)'
        match=re.search(pattern,text);assert match
        block=match[2];position=[float(v) for v in re.search(r'position = Vector2\(([^)]+)\)',block)[1].split(',')];scale=[float(v) for v in re.search(r'scale = Vector2\(([^)]+)\)',block)[1].split(',')]
        assert scale[0]==scale[1]
        text,n=re.subn(pattern,lambda m:m[1]+'z_index = -2\n'+m[2],text,count=1);assert n==1
        bodies=[]
        for i,(side,points) in enumerate([('Left',LEFT),('Right',RIGHT)]):
            body=[[position[0]+x*scale[0],position[1]+y*scale[1]] for x,y in points]
            collision=r'(\[node name="Block'+str(i)+r'" type="CollisionPolygon2D" parent="Town/'+name+r'/Body"\]\npolygon = )PackedVector2Array\([^\n]+'
            text,n=re.subn(collision,lambda m:m[1]+poly(body),text,count=1);assert n==1
            overlays.append(f'[node name="{side}Cheek" type="Polygon2D" parent="Town/{name}"]\nposition = {vec(position)}\nscale = {vec(scale)}\ntexture = ExtResource("d_stairs")\npolygon = {poly(points)}\nuv = {poly(points)}')
            bodies.append(body)
        rows.append({'name':name,'floor_z_index':-2,'side_render_z_index':0,'native_side_polygons':[LEFT,RIGHT],'collision_polygons':bodies,'uniform_visual_scale':scale[0]})
    text+='\n\n'+'\n\n'.join(overlays)+'\n'
    # Private validation first; the user's live project remains untouched until it passes.
    private.write_text(text,'utf-8')
    save(STAGE/'geometry.json',{'native_texture':'res://art/modules/'+D+'/stairs.png','native_png_sha256':sha(ROOT/'game/art/modules'/D/'stairs.png'),'stairs':rows,'original_png_modified':False,'purpose':'tread surface below actor, original native side faces above with matched blocking'})
    save(STAGE/'candidate.json',{'target':'game/'+SCENE,'before_sha256':sha(source),'candidate_sha256':sha(private),'production_scene_written':False})
    print('Private candidate: three tread layers, six original-UV cheeks, six matched polygons')

if __name__=='__main__':run()
