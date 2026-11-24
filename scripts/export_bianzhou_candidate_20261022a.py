"""Export reviewable SceneScript/layout files under staging, never deploy them."""
import json,math,re,shutil
from pathlib import Path
import bianzhou_city_remodel_20261022 as b

ROOT=b.ROOT;BASE=b.BASE/'revision2';OUT=BASE/'integration_candidate/game'
author=json.loads((BASE/'author.json').read_text('utf-8'))
if OUT.exists():raise RuntimeError('Existing export must not be overwritten')
OUT.mkdir(parents=True)
relative='art/modules/bianzhou_city_20261022a'
media=OUT/relative;media.mkdir(parents=True)
for a in author['assets'].values():shutil.copyfile(BASE/a['path'],media/Path(a['path']).name)
shutil.copyfile(BASE/'walk.png',media/'walk.png')
domain=OUT/'scripts/domain';domain.mkdir(parents=True)
shutil.copyfile(ROOT/'game/scripts/domain/walkable_map_layout.gd',domain/'walkable_map_layout.gd')

def q(s):return json.dumps(s,ensure_ascii=False)
def v(a):return 'Vector2('+','.join(repr(float(x)) for x in a)+')'
def encode(d):
    parts=[]
    for k,val in d.items():
        if k in ['pos','render_size_px','size','target_pos']:value=v(val)
        elif k=='solid_polygons_px':value='Array[PackedVector2Array](['+','.join('PackedVector2Array('+','.join(repr(float(n)) for point in poly for n in point)+')' for poly in val)+'])'
        elif isinstance(val,bool):value=str(val).lower()
        elif isinstance(val,(float,int)):value=repr(val)
        else:value=q(val)
        parts.append(q(k)+':'+value)
    return '{'+','.join(parts)+'}'
entries=[];atlas=[];expected=[]
def texture(key):return 'res://'+relative+'/'+Path(author['assets'][key]['path']).name
for index,surface in enumerate(author['terrain']):
    sx,sy=author['assets'][surface['asset']]['size'];scale=surface['tile_scale'];tw,th=sx*scale,sy*scale
    ox,oy,w,h=surface['rect']
    for y in range(math.ceil(h/th)):
        for x in range(math.ceil(w/tw)):
            width=min(tw,w-x*tw);height=min(th,h-y*th);ident=f'terrain_{index}_{x}_{y}'
            path=texture(surface['asset'])
            if width!=tw or height!=th:
                name=ident+'.tres';path='res://'+relative+'/'+name
                text='[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path='+q(texture(surface['asset']))+' id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(0,0,'+repr(width/scale)+','+repr(height/scale)+')\n'
                (media/name).write_text(text,'utf-8');atlas.append(name)
            item={'id':ident,'texture':path,'pos':[(ox+x*tw)/3072,(oy+y*th)/2048],'render_size_px':[width,height],'centered':False,'z_index':-100}
            entries.append(item)
for obj in author['objects']:
    solids=[]
    for s in author['solids']:
        if s['owner']==obj['id']:
            x,y,w,h=s['rect'];solids.append([[x,y],[x+w,y],[x+w,y+h],[x,y+h]])
    item={'id':obj['id'],'texture':texture(obj['asset']),'pos':[obj['origin_px'][0]/3072,obj['origin_px'][1]/2048],'render_size_px':obj['render_size_px'],'centered':False,'sort_by_feet':True,'depth_sort_foot_y':obj['foot_px'][1]/2048}
    if solids:item['solid_polygons_px']=solids
    entries.append(item)
    expected.append({'id':obj['id'],'origin_px':obj['origin_px'],'render_size_px':obj['render_size_px'],'foot_px':obj['foot_px'],'solids':solids})
layout=['[gd_resource type="Resource" script_class="WalkableMapLayout" load_steps=2 format=3]','','[ext_resource type="Script" path="res://scripts/domain/walkable_map_layout.gd" id="1"]','','[resource]','script = ExtResource("1")','schema_version = 5','design_size = Vector2i(3072,2048)','display_at_native_size = true','walkable_mask_path = '+q('res://'+relative+'/walk.png'),'walkable_regions = Array[PackedVector2Array]([PackedVector2Array(0.01171875,0.017578125,0.98828125,0.017578125,0.98828125,0.982421875,0.01171875,0.982421875)])','visual_objects = Array[Dictionary](['+',\n'.join(encode(e) for e in entries)+'])']
old=(BASE/'originals/openworld_bianzhou_city_layout_v2.tres').read_text('utf-8')
portals=re.search(r'(?m)^portals = .*$',old).group(0)
interaction=re.search(r'(?m)^interactions = .*$',old).group(0).replace('Vector2(0.795,0.520)',v([1850/3072,1150/2048])).replace('Vector2(0.200,0.260)',v([220/3072,120/2048]))
layout += [interaction,portals,'walkable_probes = Array[Dictionary](['+','.join(encode({'id':r['id'],'pos':[r['points'][-1][0]/3072,r['points'][-1][1]/2048]}) for r in json.loads((BASE/'routes.json').read_text('utf-8')))+'])','blocked_probes = Array[Dictionary](['+','.join(encode({'id':s['id'],'pos':[(s['rect'][0]+s['rect'][2]/2)/3072,(s['rect'][1]+s['rect'][3]/2)/2048]}) for s in author['solids'] if s['owner']!='boundary')+'])']
maps=OUT/'data/maps';maps.mkdir(parents=True);(maps/'openworld_bianzhou_city_layout_20261022a.tres').write_text('\n'.join(layout)+'\n','utf-8')
scene=(BASE/'originals/openworld_bianzhou_city.tres').read_bytes()
changes={b'res://data/maps/openworld_bianzhou_city_layout_v2.tres':b'res://data/maps/openworld_bianzhou_city_layout_20261022a.tres',b'Vector2(0.62,0.58)':v([2120/3072,790/2048]).encode(),b'Vector2(0.31,0.52)':v([1120/3072,1050/2048]).encode()}
original=scene
for before,after in changes.items():assert scene.count(before)==1;scene=scene.replace(before,after)
inverse=scene
for before,after in changes.items():assert inverse.count(after)==1;inverse=inverse.replace(after,before)
assert inverse==original
scenes=OUT/'data/scenes';scenes.mkdir(parents=True);(scenes/'openworld_bianzhou_city.tres').write_bytes(scene)
b.dump(BASE/'integration_candidate/export-receipt.json',{'status':'STAGED_ONLY_NOT_DEPLOYED','scene_changes':3,'scene_whole_inverse_exact':True,'background_bgm_npc_actions_and_portals_preserved':True,'objects':len(author['objects']),'ground_sprites':len(entries)-len(author['objects']),'atlas_resources':len(atlas),'all_source_png_bytes_unchanged':True,'game_writes':0,'integration_pending':['图片与Atlas正式导入','原生Field NPC/玩家遮挡和交互','大地图与旧驿真实往返','素材完整留白与视觉密度收边']})
b.dump(OUT/'expected.json',{'entries':expected,'terrain_count':len(entries)-len(expected),'total':len(entries),'body_count':sum(len(x['solids']) for x in expected)})
(OUT/'project.godot').write_text('config_version=5\n[application]\nconfig/name="汴州候选数据只读核验"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n','utf-8')
print(json.dumps({'scene_changes':3,'ground_sprites':len(entries)-len(expected),'objects':len(expected),'atlas_resources':len(atlas),'game_writes':0}))
