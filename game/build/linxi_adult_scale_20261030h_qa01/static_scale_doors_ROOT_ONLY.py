"""Read-only changed-domain checks; print JSON only, no engine/save/game input."""
from pathlib import Path
import hashlib, json, sys

REPO=Path('F:/Code/RPG_GAME')
AUTHOR=REPO/'game/build/linxi_building_scale_20261030h_system01'
NPC=REPO/'game/build/linxi_adult_scale_20261030h_system01'
SOURCE={
    'small_home':(943,647,236), 'office':(1493,544,208),
    'warehouse':(1415,667,239), 'repair_shed':(1473,739,305),
    'inn':(938,822,155),
}
errors=[]; checks=0
def need(ok,label):
    global checks
    checks+=1
    if not ok: errors.append(label)
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def overlap(a,b):
    for shape in (a,b):
        for p,q in zip(shape,shape[1:]+shape[:1]):
            axis=(p[1]-q[1],q[0]-p[0])
            pa=[x*axis[0]+y*axis[1] for x,y in a]
            pb=[x*axis[0]+y*axis[1] for x,y in b]
            if max(pa)<min(pb) or max(pb)<min(pa):return False
    return True
def bodies(data):
    origins={x['name']:x['foot'] for x in data['objects']}
    out={}
    for row in data['blockers']:
        path=row['path']; origin=origins[path.split('/')[1]] if path.startswith('Town/') and path.endswith('/Body') else [0,0]
        out[path]=[[x+origin[0],y+origin[1]] for x,y in row['polygon']]
    return out
def hits(foot,solids):
    x,y=foot; box=[[x-17,y-12],[x+17,y-12],[x+17,y+12],[x-17,y+12]]
    return [path for path,poly in solids.items() if overlap(box,poly)]

facts=read(AUTHOR/'candidate_facts_READY.json'); result={}
old_locations=read(REPO/'game/build/linxi_road_portrait_20261030g_source01/closure01_READY/build__four_settlements_20261030e_system01__locations.json')
new_locations=read(AUTHOR/'locations_READY.json')
need(set(old_locations)==set(new_locations),'ORIGINAL_SEVEN_LOCATION_IDS_EXACT')
for scene,row in old_locations.items():
    need(new_locations[scene]['returns']==row['returns'],scene+':EXACT_ORIGINAL_ROOM_AND_OUTDOOR_RETURN_ANCHORS')
    if scene not in ('linxi_village_center','linxi_village_scrollmap'):
        need(new_locations[scene]==row,scene+':UNCHANGED_OTHER_FIVE_ROWS_INCLUDING_MASTER3002')
for key in ('linxi_center','linxi_south'):
    current=read(AUTHOR/(key+'.json'))
    original=read(AUTHOR/'before/game/art/modules/four_settlements_20261030e'/(key+'.json'))
    need(current['business']==original['business'],key+':EXACT_ORIGINAL_NPCS_PORTALS_INTERACTIONS')
    rows={x['name']:x for x in current['objects']}; solids=bodies(current); buildings={}; doors={}
    for name in facts['facts'][key]['buildings']:
        row=rows[name]; width,height,door=SOURCE[row['key']]; scale=row['scale']
        need(0<scale<=1,name+':NATIVE_UNIFORM_SHRINK_ONLY')
        need(abs(row['height']-height*scale)<.001 and abs(row['width']-width*scale)<.001,name+':SOURCE_NATIVE_SIZE')
        storeys=2 if key=='linxi_center' and name=='Tavern' else 1
        ratio=row['height']/storeys/128.52
        need(2.5<=ratio<=3.5,name+':ADULT_REFERENCED_PER_STOREY_HEIGHT')
        need(door*scale>=132*1.1,name+':DOOR_AT_LEAST_1_1_MAX_NPC_ADULT')
        need('Town/'+name+'/Body' in solids,name+':REAL_COMPLETE_BODY_PRESENT')
        buildings[name]={'height_px':row['height'],'storeys':storeys,'height_per_storey_per_hero':ratio,'door_height_px':door*scale,'native_scale':scale,'foot':row['foot']}
    for target,foot in current['business']['portal_targets'].items():
        if target not in ('linxi_scholar_house','linxi_farmer_cottage','linxi_herbal_home','linxi_south_villager_home','linxi_south_scholar_house','linxi_south_apothecary_home'):continue
        hit=hits(foot,solids);need(not hit,key+':ORIGINAL_DOOR_FULL34x24_CLEAR:'+target)
        doors[target]={'foot':foot,'full_foot_hits':hit}
    if key=='linxi_south':
        for label,foot in {'teacher':current['business']['npcs']['linxi_south_teacher'],'hero_normal_camera':[1970,1070]}.items():
            hit=hits(foot,solids);need(not hit,'SOUTH_TEACHER_HERO_NEW_BODY_CLEAR:'+label)
            doors[label]={'foot':foot,'full_foot_hits':hit}
    result[key]={'buildings':buildings,'six_original_door_checks_and_south_camera_feet':doors,'original_business_exact':current['business']==original['business'],'original_returns_checked_in_actual_LOC_rows_not_missing_JSON_fields':True}
projection=read(NPC/'normalized_projection_ACTUAL.json')
need(abs(projection['hero']['visible_height_px']-128.52)<.001,'HERO_VISIBLE_ALPHA_REFERENCE_NOT_CANVAS')
need(all(120<=r['target_height_px']<=132 for r in projection['rows']),'AUTHORED_ADULT_TARGETS_120_TO132')
report={'passed':not errors,'checks':checks,'errors':errors,'changed_scale_domains':result,'hero_reference':projection['hero'],'scope':'STATIC_NUMERIC_AND_CONVEX_SAT_CHANGED_BUILDINGS_SIX_DOORS_ONLY_NOT_GAME_PHYSICS','source_door_pixels_reference':SOURCE,'engine_calls':0,'save_reads':0,'save_writes':0,'game_input':0,'old11room_or_movement_matrix_retested':False}
print(json.dumps(report,ensure_ascii=False,indent=2))
sys.exit(1 if errors else 0)
