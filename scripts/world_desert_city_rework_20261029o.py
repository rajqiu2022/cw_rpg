"""Dedicated whole-town miniatures and strict source successor, staged only."""
from desert_city_rework_20261029o import *
import re
BASE='build/three_towns_world_20261029j_system01/'
media=json.loads((STAGE/'media.json').read_text('utf-8'))
spec=json.loads((ROOT/'game'/BASE/'world_spec.json').read_text('utf-8'))
spec['status']='NATIVE_WORLD_COMPOUNDS_REWORK_CANDIDATE'
spec['notes']=['20261029o: two dedicated original native whole-town miniatures; prior three-town doors/IDs/world feet unchanged.','Native source-space footprint and one open front entrance authored against the new images; complete original PNG retained.']
for row in spec['landmarks']:
    if row['id']=='lanxi_zhai':continue
    key='world_redrock' if row['id']=='redrock_town' else 'world_desert'
    m=media[key];pad=m['padding'];foot=row['door_foot_px'];door=[770,920] if key=='world_redrock' else [770,890];scale=.46
    pivot=[door[0]+pad[0],door[1]+pad[1]];origin=[foot[i]-pivot[i]*scale for i in range(2)]
    row['sprites']=[{'key':'compound','texture':'res://'+m['path'],'size_px':m['size'],'source_foot_px':pivot,'foot_px':foot,'scale':scale,'anchor_basis':'native_dedicated_compound_front_gate','source_foot_uv':[pivot[i]/m['size'][i] for i in range(2)],'origin_px':origin}]
    # The entire town mass is impassable above the doorway; small front opening remains clear.
    # As in the existing Luoyang compound, this is a miniature landmark, not town exploration.
    if key=='world_redrock':
        polys=[[[92,590],[360,295],[1180,295],[1450,590],[1390,743],[825,743],[715,743],[155,743]],
               [[155,743],[715,743],[715,910],[570,910],[155,790]],
               [[825,743],[1390,743],[1390,790],[950,910],[825,910]]]
    else:
        polys=[[[100,110],[1425,110],[1480,755],[825,755],[715,755],[45,755]],
               [[45,755],[715,755],[715,885],[605,885],[45,840]],
               [[825,755],[1480,755],[1480,840],[920,885],[825,885]]]
    row['solid_polygons_px']=[[[foot[0]+(x-door[0])*scale,foot[1]+(y-door[1])*scale] for x,y in p] for p in polys]
    row['approach_clearance_px']=[[foot[0]-18,foot[1]-22],[foot[0]+18,foot[1]-22],[foot[0]+18,foot[1]+40],[foot[0]-18,foot[1]+40]]
target=PROJECT/BASE;target.mkdir(parents=True,exist_ok=True)
save(target/'world_spec.json',spec)
manifest=json.loads((ROOT/'game'/BASE/'native_sources.json').read_text('utf-8'))
for rel in ['scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn','scenes/drafts/desert_town_20261029d/desert_town.tscn',BASE+'world_spec.json']:
    manifest['sources']['res://'+rel]=sha(PROJECT/rel)
for m in media.values():manifest['sources']['res://'+m['path']]=sha(PROJECT/m['path'])
save(target/'native_sources.json',manifest)
registry=(ROOT/'game'/BASE/'town_registry.gd').read_text('utf-8')
registry=registry.replace('Native layouts and the original sixteen World doors stay immutable.','Native layout updates are explicitly pinned; the original sixteen World doors stay unchanged.')
registry=re.sub(r'const NATIVE_SOURCE_SHA := "[0-9a-f]+"','const NATIVE_SOURCE_SHA := "'+sha(target/'native_sources.json')+'"',registry)
(target/'town_registry.gd').write_text(registry.rstrip()+'\n','utf-8')
save(STAGE/'world-successor.json',{'replaced_landmarks':['redrock_town','desert_town'],'native_source_sha':sha(target/'native_sources.json'),'world_spec_sha':sha(target/'world_spec.json'),'town_registry_sha':sha(target/'town_registry.gd'),'router_changed':False,'unchanged_miao_row':next(r for r in spec['landmarks'] if r['id']=='lanxi_zhai')==next(r for r in json.loads((ROOT/'game'/BASE/'world_spec.json').read_text('utf-8'))['landmarks'] if r['id']=='lanxi_zhai')})
