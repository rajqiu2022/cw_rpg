from lanxi_revision_20261030l import *
for rel in ['game/art/modules/miao_terrain_20261029i/resource-pack.json','scripts/build_resource_gallery.py','scripts/build_resource_reuse_index.py','docs/equipment-skill-catalog.html','docs/resource-reuse-index.md']:
 p=ROOT/rel
 if p.exists():
  dst=STAGE/'backup-reports'/rel;dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists();shutil.copy2(p,dst)
p=GAME/'art/modules/miao_terrain_20261029i/resource-pack.json';j=json.loads(p.read_text('utf-8'))
j.update(status='LANXI_FORMAL_OPAQUE_ARCHITECTURE_NATIVE_BANKS',formal_world_enabled=True,formal_scene_id='openworld_lanxi_zhai',revision='lanxi_revision_20261030l',revision_notes='岚溪寨：建筑保持不透明，遮挡处只显示0.42半透明主角；88个变形立面退，166段完整等比苔石坡岸，5房屋及3杂物调整，4真阶/0-120-240高程保持。')
j['reused_asset_keys']['miao_recompose_20261029g'].append('rock_bank')
j['layout_revision_report']='docs/changes/lanxi-occlusion-and-banks-20261030l.md'
save(p,j)
