"""Publish the tested Redrock successor and only its new import leaves."""
import json
import re
import shutil
from pathlib import Path

from build_redrock_town_20261028a import ROOT, save, sha
from redrock_city_life_20261029a import NAME, D, STAGE, RAW, PROJECT, SCENE, ART


def main():
    assert not (STAGE/'publication.json').exists()
    before=json.loads((STAGE/'scene-before.json').read_text('utf-8'))
    assert sha(ROOT/before['path'])==before['sha256']
    for name,failed in [('verification-life.json',8),('verification-life-residual.json',4),('verification-life-final.json',0),('verification-life-clean.json',0)]:
        report=json.loads((PROJECT/'artifacts'/name).read_text('utf-8'))
        assert report['failed']==failed
    assert (STAGE/'clean.stderr.log').stat().st_size==0
    protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'))
    changed=[]
    for r in protected:
        p=Path(r['path'])
        if sha(p)!=r['sha256'] or p.stat().st_size!=r['bytes'] or p.stat().st_mtime_ns!=r['mtime_ns']:
            changed.append(r['path'])
    save(STAGE/'protected-after.json',{'count':len(protected),'changed':changed,'exact_sha_bytes_mtime':not changed})
    assert not changed,changed
    raw=json.loads((RAW/'manifest.json').read_text('utf-8'))
    raw_row={**raw,'key':'sandstone_paving','id':NAME+'_sandstone_paving_v1','kind':'ground',
             'label':'赤岩·砂岩街巷铺地','transparent':False,
             'review_note':'街巷与四院地面原生材质，512周期在Godot中采样；RGB原样，不适用透明组件A1边距。未授正式世界或整城艺术终验。'}
    save(RAW/'resource-pack.json',{'status':'EDITOR_MAP_MATERIAL_SOURCE','assets':[raw_row]})
    row={k:raw_row[k] for k in ['key','kind','label','sha256','review_note']}
    row.update(source=raw['output'],destination=ART+'/sandstone_paving.png',output='game/'+ART+'/sandstone_paving.png',scene='res://'+SCENE)
    save(PROJECT/ART/'resource-pack.json',{'status':'CITY_LIFE_EDITOR_MAP','scene':'res://'+SCENE,
         'validated_image_count':1,'resource_status_label':'街坊生活与砂岩铺地 · 已装配','assets':[row]})
    assert sha(PROJECT/ART/'sandstone_paving.png')==raw['sha256']
    rels=[ART+'/sandstone_paving.png',ART+'/sandstone_paving.png.import',ART+'/ground.gdshader',ART+'/ground.gdshader.uid',ART+'/resource-pack.json',
          f'scripts/drafts/{NAME}/town_controller.gd',f'scripts/drafts/{NAME}/town_controller.gd.uid']
    side=(PROJECT/ART/'sandstone_paving.png.import').read_text('utf-8')
    imports=set(re.findall(r'res://(\.godot/imported/[^"\s]+)',side))
    assert len(imports)==1
    for rel in imports:
        rels.extend([rel,str(Path(rel).with_suffix('.md5')).replace('\\','/')])
    for rel in rels:
        source=PROJECT/rel;target=ROOT/'game'/rel
        assert source.is_file() and not target.exists(),rel
    # Prove all three stairs, their original UV overlays and bodies are byte-identical blocks.
    old=(STAGE/'scene-before.tscn').read_text('utf-8');new=(PROJECT/SCENE).read_text('utf-8')
    def stairs_blocks(text):
        return [b for b in re.split(r'(?=\[node )',text) if re.search(r'(name="(?:LaneStairs|LookoutStairs|WestLaneStairs)"|parent="Town/(?:LaneStairs|LookoutStairs|WestLaneStairs)(?:/|"))',b.splitlines()[0] if b else '')]
    # Appending new root nodes adds one separator LF after the former final node.
    # The complete 21 stair node bodies/properties remain identical.
    assert len(stairs_blocks(old))==21
    assert [b.rstrip() for b in stairs_blocks(old)]==[b.rstrip() for b in stairs_blocks(new)]
    save(STAGE/'stair-node-identity.json',{'nodes':21,'all_node_bodies_exact':True,
         'separator_only_difference':'former final RightCheek now followed by one blank separator line',
         'first_raw_separator_assertion_failed_before_production_write':True})
    assert new.endswith('\n') and not new.endswith('\n\n')
    for rel in rels:
        target=ROOT/'game'/rel;target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(PROJECT/rel,target)
    shutil.copyfile(PROJECT/SCENE,ROOT/'game'/SCENE)
    files=[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels+[SCENE]]
    save(STAGE/'publication.json',{'files':files,'changed_existing_files':['game/'+SCENE],
         'new_files':len(rels),'protected':len(protected),'protected_exact_sha_bytes_mtime':True,
         'old_stair_blocks_exact':True,'first_whole_failure_retained':True,'new_objects':28,
         'new_homes':2,'new_life_props':22,'new_native_reuse_patrols':4,'native_png_modified':False,
         'scene_before_sha256':before['sha256'],'scene_after_sha256':sha(ROOT/'game'/SCENE),
         'production_import_invoked':False,'scope':'editor map city-life revision; no formal world/quest/battle'})
    print(f'Published scene + {len(rels)} new files; {len(protected)} protected files exact; all stair blocks exact')


if __name__=='__main__':
    main()
