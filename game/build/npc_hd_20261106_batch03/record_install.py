"""Record exact approved installation, never install or launch anything."""
from pathlib import Path
import json,hashlib
O=Path(__file__).resolve().parent;R=O.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
plan=read(O/'formal_install_plan.json')
assert len(plan['targets'])==16
assert sha(Path(plan['adapter_frozen']['path']))==plan['adapter_frozen']['sha256']
for row in plan['targets']:
    assert sha(Path(row['target']))==row['after_sha256'],row['target']
    if row['before']!='ABSENT':assert sha(Path(row['backup']))==row['before']
before=read(O/'before/source.json');after=read(R/'game/art/characters/pc_hd_20261102c/source.json')
assert len(before['mappings'])==18 and len(after['mappings'])==23
assert all(after['mappings'][k]==v for k,v in before['mappings'].items())
receipt={'status':'INSTALLED_PENDING_FORMAL5_CONSUMER_CHECK','exact_targets':16,'new_atlases':5,'new_families':1,'new_frames':36,'old_18_mappings_exact':True,'adapter_frozen':True,'all_target_sha_exact':True,'manifest_sha256':sha(R/'game/art/characters/pc_hd_20261102c/source.json'),'whole_npc_complete':False,'engine_launches_by_agent':0,'real_save_content_access':False,'direction_contract':'Legacy filename left displays screen-right and right displays screen-left; original code and semantics unchanged.'}
(O/'formal_after_receipt.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'targets':16,'manifest':23,'adapter_expected':24,'old_mappings_exact':True}))
