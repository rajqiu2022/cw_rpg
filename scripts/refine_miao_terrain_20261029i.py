"""Only failed landing domain and newly required route/surface validation; old reports retained."""
import json
import shutil
from build_miao_terrain_20261029i import ROOT, STAGE, PROJECT, ART, NAME
from build_redrock_town_20261028a import save

data=json.loads((STAGE/'terrain.json').read_text('utf-8'))
data['object_moves']={'PocketInfill7':[2740,3080],'Forest178':[2160,2550]}
save(STAGE/'terrain.json',data);save(PROJECT/ART/'terrain.json',data)
layout=json.loads((STAGE/'layout.json').read_text('utf-8'));layout['terrain']=data;save(STAGE/'layout.json',layout)
for name in ['terrain.gd','town_controller.gd','resident.gd']:
    shutil.copyfile(ROOT/'scripts/templates'/NAME/name,PROJECT/f'scripts/drafts/{NAME}'/name)
for name in ['verify_routes.gd']:
    shutil.copyfile(ROOT/'scripts/templates'/NAME/name,PROJECT/name)
print('Updated only terrain successor; original three FAIL checks retained')
