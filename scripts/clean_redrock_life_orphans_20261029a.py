"""Remove six unreachable authoring blocks from an overbroad Dwelling1 prefix match."""
import re
import shutil
from redrock_city_life_20261029a import STAGE, PROJECT, SCENE
from build_redrock_town_20261028a import save, sha

scene=PROJECT/SCENE
assert not (STAGE/'before-orphan-cleanup.tscn').exists()
shutil.copyfile(scene,STAGE/'before-orphan-cleanup.tscn')
blocks=re.split(r'(?=\[node )',scene.read_text('utf-8'))
removed=[b for b in blocks if re.search(r'parent="Town/Life(?:North|East)Home0(?:/|")',b.splitlines()[0] if b else '')]
assert len(removed)==6
scene.write_text(''.join(b for b in blocks if b not in removed).rstrip()+'\n','utf-8')
save(STAGE/'orphan-cleanup.json',{'removed_unreachable_blocks':6,'cause':'Dwelling1 prefix also matched Dwelling10 children',
     'actual_instanced_geometry_changed':False,'prior_warning_retained':True,'scene_sha256':sha(scene)})
print('Removed six unreachable blocks; live geometry unchanged')
