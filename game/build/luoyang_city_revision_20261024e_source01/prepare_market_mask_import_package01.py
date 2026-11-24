"""Mechanical one-mask isolate tools from Root-reviewed24c; never engine."""
from pathlib import Path
import hashlib,json
B=Path(__file__).resolve().parent;G=B.parents[1]
OLD=G/'build/luoyang_city_revision_20261024c_source01'
N=B/'market_mask_import01'
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(path,h):
    raw=path.read_bytes();assert sha(raw)==h,(path,sha(raw),h);return raw
def put(name,raw):
    p=N/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw);return p,sha(raw)
def adapt(raw,ops):
    result=raw
    for a,b in ops:
        a=a.encode();b=b.encode();assert result.count(a)==1,(a,result.count(a));result=result.replace(a,b,1)
    inverse=result
    for a,b in reversed(ops):
        a=a.encode();b=b.encode();assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
    assert inverse==raw;return result
builder=checked(OLD/'prepare_courts_mask_isolate_NOTENGINE.py','730b001389db9ee2b89a02da7c5401a6ca8a03d0f0fba81d869f4828ec724ea7')
before="    assert pub['walk_path']==target and pub['walk_file_sha256']==item['png_sha256'] and pub['walk_RGBA_sha256']==item['decoded_RGBA_sha256']\n    assert pub['changed_pixels']==140469 and pub['visited_pixels']==206290 and pub['full_RGBA_inverse'] is True\n"
after="    prior=json.loads(checked(GAME/cfg['independent_prior']['path'][6:],cfg['independent_prior']['sha256']))\n    assert pub['status']=='MARKET24E_FIXED_COMPONENTS_NOT_RUNTIME' and pub['source_first']==pub['source_final_before_route']\n    assert pub['walk_path']==target and pub['walk_sha256']==item['png_sha256'] and pub['walk_RGBA_sha256']==item['decoded_RGBA_sha256']\n    assert prior['ready'] is True and prior['expected_child_RGBA_sha256']==pub['walk_RGBA_sha256']==item['decoded_RGBA_sha256']\n    assert pub['changed_pixels']==prior['changed_pixels']==590860 and pub['visited_pixels']==prior['union_visited_pixels']==1000516\n"
ops=[("luoyang_yamen_courts_mask_20261024c_import","luoyang_market_blocks_mask_20261024e_import01"),
 ("ROOT_LOCKED_ONE_COURTS_OVERLAY_MASK_ISOLATE_PREPARATION","ROOT_LOCKED_ONE_MARKET_BLOCK_OVERLAY_MASK_ISOLATE_PREPARATION"),
 (before,after),
 ('Yamen One Published Courts Overlay Mask Isolate 20261024c','Market One Fixed Block Overlay Mask Isolate 20261024e'),
 ("status='EXACT_ONE_COURTS_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED'","status='EXACT_ONE_MARKET_BLOCK_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED'"),
 ("expected={'courts_overlay':","expected={'market_block_overlay':"),
 ("production_promoted=False,publication=cfg['publication'])","production_promoted=False,publication=cfg['publication'],save_paths=cfg['save_paths'])")]
newbuilder=adapt(builder,ops)
builderpath,builderhash=put('prepare_isolate_NOTENGINE.py',newbuilder)
template=checked(OLD/'verify_courts_mask_template_NOTEXEC.gd','379bf4941c007b1728d5ae25046ebb3873a9d67c412a8f236fab8044c9533a98')
# Labels/status only. All fullRGBA/parameter/source/absent predicates unchanged.
newtemplate=template.replace(b'COURTS_OVERLAY',b'MARKET_BLOCK_OVERLAY').replace(b'courts_overlay',b'market_block_overlay').replace(b'courts overlay',b'Market block overlay')
assert newtemplate.replace(b'MARKET_BLOCK_OVERLAY',b'COURTS_OVERLAY').replace(b'market_block_overlay',b'courts_overlay').replace(b'Market block overlay',b'courts overlay')==template
tp,th=put('verify_template_NOTEXEC.gd',newtemplate)
oldcfg=json.loads((OLD/'courts_mask_isolate_input_ROOT_READY.json').read_bytes())
png='res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/walk_overlay.png'
compiled='res://.godot/imported/walk_overlay.png-'+hashlib.md5(png.encode()).hexdigest()+'.ctex'
fresh=json.loads(checked(B/'fresh_24e_current_observation_READONLY.json','63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85'))
cfg=dict(status='ROOT_LOCKED_ONE_MARKET_BLOCK_OVERLAY_MASK_ISOLATE_PREPARATION',ready=True,required_builder_sha256=builderhash,
 verifier_template=dict(path='res://'+tp.relative_to(G).as_posix(),sha256=th,bytes=len(newtemplate)),
 publication=dict(path='res://build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/components_FIXED_NOT_RUNTIME.json',sha256='cafee170b4e33b159c8ad769e96ceeb97987d70eb561ee9b5049a8e25e827194'),
 independent_prior=dict(path='res://build/luoyang_city_revision_20261024e_source01/market_prior03_admitted_source01/independent_pixel_prior_READY_NOT_RUNTIME.json',sha256='dcc92d0aa8e2839a0eddf9200b68f07595e13a92cda0c692b0188707a982a856'),
 texture=dict(domain='market_block_overlay',png=png,png_sha256='051ac64ff157f1cc7ae4ab2abb4b03f650d8da74bd15bf5ff528164d5bfdc9d4',decoded_RGBA_sha256='b6d6d0af0e2e03a7588a2f3561fd6c9aa4f821fe31265338ee79f0463305cb06',source_size=[3072,2048],sidecar=png+'.import',compiled=compiled),
 exact_23_import_params=oldcfg['exact_23_import_params'],save_paths=[r['path'] for r in fresh['current_save_protection_start']],
 scope='Only unchanged Root9720 fixed PNG; route/art/runtime not admitted. No engine or main writes by Source. Root imports/validates in NEW isolate only; new2 runtime sidecar/ctex later separately approved. Optional isolated md5 is bookkeeping, never auto-promoted.',
 root_protection=dict(path='res://build/luoyang_city_revision_20261024e_source01/fresh_24e_current_observation_READONLY.json',sha256='63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85'))
ip,ih=put('input_ROOT_PREPARE.json',(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
proof=dict(status='MECHANICAL_SINGLE_MARKET_MASK_ISOLATE_TOOLS_NO_ENGINE',builder=dict(path=builderpath.as_posix(),sha256=builderhash),input=dict(path=ip.as_posix(),sha256=ih),verifier_template=dict(path=tp.as_posix(),sha256=th),
 builder_replacements=[dict(old=a,new=b) for a,b in ops],builder_wholebyte_inverse=True,verifier_label_only_wholebyte_inverse=True,
 prior_B6D6_already_independent=True,mask_geometry_or_routes_replayed=0,PNG_pixel_edits=0,engine_calls=0,main_project_import=0,
 target_sidecar=png+'.import',target_ctex=compiled,optional_md5=compiled[:-5]+'.md5',optional_md5_policy='Inspect only in isolate after Root actual; no main new3 or extra sourcekey without explicit Root admission.')
pp,ph=put('tools_whole_inverse_NOTRUN.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
print(json.dumps(dict(builder=builderpath.as_posix(),builder_sha256=builderhash,input=ip.as_posix(),input_sha256=ih,proof_sha256=ph)))
