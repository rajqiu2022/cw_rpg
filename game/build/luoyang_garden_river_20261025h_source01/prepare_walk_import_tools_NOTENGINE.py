"""Mechanical single-mask import tools from reviewed 24c templates. No engine."""
from pathlib import Path
import hashlib,json,subprocess,sys
P=Path(__file__).resolve().parent; G=P.parents[1]; ROOT=G.parent
R='res://build/luoyang_garden_river_20261025h_source01/'
T=G/'build/luoyang_city_revision_20261024c_source01'
ISO=ROOT/'assets/staging/luoyang_garden_river_walk_20261025h_import'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(name,b):
 p=P/name;assert not p.exists(),str(p);p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=R+name,sha256=sha(b),bytes=len(b))
proofs=[]
def transform(parent,name,changes):
 old=parent.read_bytes();b=old;patch=[]
 for a,c in changes:
  a=a.encode();c=c.encode();assert b.count(a)==1,(name,a[:100],b.count(a));i=b.index(a);b=b[:i]+c+b[i+len(a):];patch.append(dict(offset=i,old=a.decode(),new=c.decode()))
 inv=b
 for e in reversed(patch):
  a=e['old'].encode();c=e['new'].encode();i=e['offset'];assert inv[i:i+len(c)]==c;inv=inv[:i]+a+inv[i+len(c):]
 assert inv==old
 item=out(name,b);proofs.append(dict(parent=str(parent),parent_sha256=sha(old),candidate=item,hunks=patch,whole_byte_inverse=True));return item
report_path=R+'metadata_array04/ROOT_READY/reports/115844/result.json'
rb=(G/report_path[6:]).read_bytes();report=json.loads(rb)
assert report['passed'] and report['published'] and report['whole_typed_scene_layout_source_expression_match']
png=R+'publication01/output/native/luoyang_riverside_garden_20261022ap/walk.png'
png_sha='4cc4fb19ce0df4500e4da12a446b5900cc84b33bf8a0f5aeb1aaa78e59bc7656'
rgba='d552010ef7108d37c38ee472106b244bdc5145ea3ef41748cbd103cfaeb6c456'
assert report['artifacts'][png]==png_sha and report['child_rgba_sha256']==rgba
assert sha((G/png[6:]).read_bytes())==png_sha
builder=transform(T/'prepare_courts_mask_isolate_NOTENGINE.py','prepare_garden_walk_isolate_NOTENGINE.py',[
 ("luoyang_yamen_courts_mask_20261024c_import","luoyang_garden_river_walk_20261025h_import"),
 ("assert pub['walk_path']==target and pub['walk_file_sha256']==item['png_sha256'] and pub['walk_RGBA_sha256']==item['decoded_RGBA_sha256']\n    assert pub['changed_pixels']==140469 and pub['visited_pixels']==206290 and pub['full_RGBA_inverse'] is True", "assert pub['passed'] is True and pub['published'] is True and pub['whole_typed_scene_layout_source_expression_match'] is True\n    assert pub['artifacts'][target]==item['png_sha256'] and pub['child_rgba_sha256']==item['decoded_RGBA_sha256']\n    assert pub['changed_pixels']==781176 and pub['visual_count']==56 and pub['solid_count']==16 and pub['portal_count']==2"),
 ('Yamen One Published Courts Overlay Mask Isolate 20261024c','Garden River One Published Walk Mask Isolate 20261025h')])
template=dict(path='res://build/luoyang_city_revision_20261024c_source01/verify_courts_mask_template_NOTEXEC.gd',sha256='379bf4941c007b1728d5ae25046ebb3873a9d67c412a8f236fab8044c9533a98')
assert sha((G/template['path'][6:]).read_bytes())==template['sha256']
base=json.loads((T/'courts_mask_isolate_input_ROOT_READY.json').read_bytes())
compiled='res://.godot/imported/walk.png-'+hashlib.md5(png.encode()).hexdigest()+'.ctex'
cfg=dict(base,required_builder_sha256=builder['sha256'],verifier_template=template,
 publication=dict(path=report_path,sha256=sha(rb)),texture=dict(domain='courts_overlay',png=png,png_sha256=png_sha,decoded_RGBA_sha256=rgba,source_size=[3072,2048],sidecar=png+'.import',compiled=compiled),
 root_protection=dict(path='res://build/luoyang_city_revision_20261025h_source01/fresh_current25h_READONLY.json',sha256='7b26d75eaad7d95b7d7ab33e572d0ab10c52d02e6b5e07f4ecb8609fa6ed1dcb'),
 scope='Garden one unchanged published walk PNG only. Courtyard domain label retained solely for the reviewed verifier schema, not Yamen geometry. Only two ABSENT import/ctex leaves may later be approved; no main writes or engine by Source.')
inp=out('garden_walk_isolate_input_ROOT_READY.json',enc(cfg))
compile((G/builder['path'][6:]).read_bytes(),builder['path'],'exec')
subprocess.run([sys.executable,str(G/builder['path'][6:]),str(G/inp['path'][6:]),'--input-sha256',inp['sha256']],check=True)
prepared=(ISO/'prepared_READY.json').read_bytes();verifier=(ISO/'verify_READY.gd').read_bytes();project=(ISO/'project.godot').read_bytes()
launcher=transform(T/'import_courts_mask_once_ROOTONLY.ps1','import_garden_walk_once_ROOTONLY.ps1',[
 ('luoyang_yamen_courts_mask_20261024c_import','luoyang_garden_river_walk_20261025h_import'),
 ('luoyang_city_revision_20261024c_root01/courts_mask_isolate_import_once','luoyang_city_revision_20261025h_root01/garden_walk_isolate_import_once'),
 ('7c7140e25a1c0922eebffb7ee53a261ab0e60dc4e1f31be9695d0555fef13006',sha(prepared)),
 ('fc0cd5abf77ce34288683640264a5c19868e703d47a570117230479e6bd83376',sha(verifier)),
 ('f4dd4753edbb5183686a20dc084adb5ff3a2e159d07cafa92c86340204902051',sha(project)),
 ('18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a','7b26d75eaad7d95b7d7ab33e572d0ab10c52d02e6b5e07f4ecb8609fa6ed1dcb')])
promote=transform(T/'promote_courts_mask_two_NOTRUN.ps1','promote_garden_walk_two_NOTRUN.ps1',[
 ('luoyang_yamen_courts_mask_20261024c_import','luoyang_garden_river_walk_20261025h_import'),
 ('res://build/luoyang_yamen_courts_20261024c_system01/publication02/output/54592/walk_overlay.png',png),
 ('res://.godot/imported/walk_overlay.png-53da40f2b4702ac38ad0636f09873742.ctex',compiled),
 ('56fb2f381fe129ed8f9b5292dfc49c765a4f3e5fba144da3e84d979d1cae1b5b',png_sha),
 ('635fffe3c760155d5db61122d19efd88a1e8e6f0bb903515ff35afbdfecfdc3c',rgba)])
receipt=out('garden_walk_import_tools_handoff_NOT_IMPORTED.json',enc(dict(status='GARDEN_WALK_ISOLATE_PREPARED_NO_ENGINE_NO_PROMOTION',builder=builder,input=inp,launcher=launcher,promotion=promote,isolate=str(ISO),prepared_sha256=sha(prepared),verifier_sha256=sha(verifier),project_sha256=sha(project),publication=dict(path=report_path,sha256=sha(rb)),texture=cfg['texture'],whole_byte_inverses=proofs,engine_calls=0,canonical_writes=0,PNG_edits=0)))
print(json.dumps(dict(handoff=receipt,launcher=launcher,promotion=promote,prepared_sha256=sha(prepared),verifier_sha256=sha(verifier),project=str(ISO))))
