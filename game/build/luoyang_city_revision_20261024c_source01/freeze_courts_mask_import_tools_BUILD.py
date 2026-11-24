"""Mechanical verifier successor and locked input only. No decoding or isolate run."""
from pathlib import Path
import hashlib,json,struct
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024c_source01/'
Y='res://build/luoyang_yamen_courts_20261024c_system01/publication02/output/54592/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(name,b):
    if (HERE/name).exists():
        assert (HERE/name).read_bytes()==b
        return dict(path=S+name,sha256=sha(b),bytes=len(b))
    with (HERE/name).open('xb') as f:f.write(b)
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
parent=HERE/'verify_scholar_portrait_template_NOTEXEC.gd';old=parent.read_bytes()
assert sha(old)=='a27b07fbb5a192f41de547955008b97d594bd58d61778b3650cded36bc11cafb'
text=old.decode();edits=[]
def change(a,b):
    global text
    assert text.count(a)==1,(a[:50],text.count(a));i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
for a,b in [('## NOTRUN. Root-only isolated2PNG verification, two fixed complete-shop PNGs.','## NOTRUN. Root-only one published courts overlay mask verification.'),('EXACT_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_IMPORT_PREPARED','EXACT_ONE_COURTS_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED'),('Exact one opaque scholar portrait PNG only','Exact one published courts overlay mask PNG only'),('Exactly one independently expected portrait PNG verified','Exactly one published overlay mask verified'),('scholar_portrait_import_result_','courts_overlay_import_result_'),('ONLY_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME','ONLY_ONE_PUBLISHED_COURTS_OVERLAY_MASK_ISOLATED_FULL_RGBA_NOT_RUNTIME'),('Main three targets still ABSENT','Main two targets still ABSENT')]:change(a,b)
for a,b,n in [('SCHOLAR_PORTRAIT_IMPORT','COURTS_OVERLAY_IMPORT',2),('main_three_absent_targets','main_two_absent_targets',2)]:
    assert text.count(a)==n
    for _ in range(n):
        i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
start=text.index('\t\tvar rgba_data: PackedByteArray=raw.get_data()');end=text.index('\t\tif not need(raw.get_data()==imported.get_data()',start)
change(text[start:end],'')
change('"opaque_full_RGBA":true,','')
inverse=text.encode()
for e in reversed(edits):
    i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert inverse[i:i+len(b)]==b;inverse=inverse[:i]+a+inverse[i+len(b):]
assert inverse==old
verifier=out('verify_courts_mask_template_NOTEXEC.gd',text.encode())
pub=(GAME/(Y+'overlay_manifest_NOTREADY.json')[6:]).read_bytes();assert sha(pub)=='d825c4caf50c5fa0a68dca85fe14dba59cf3568f1198229549341dda057e46f8'
v=json.loads(pub);target=Y+'walk_overlay.png'
assert v['walk_path']==target and v['walk_file_sha256']=='56fb2f381fe129ed8f9b5292dfc49c765a4f3e5fba144da3e84d979d1cae1b5b'
assert v['walk_RGBA_sha256']=='635fffe3c760155d5db61122d19efd88a1e8e6f0bb903515ff35afbdfecfdc3c'
compiled='res://.godot/imported/walk_overlay.png-'+hashlib.md5(target.encode()).hexdigest()+'.ctex'
profile=GAME/'data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import'
pr=profile.read_bytes();assert sha(pr)=='57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15'
params={k:json.loads(a) for line in pr.decode().split('[params]',1)[1].splitlines() if '=' in line for k,a in [line.split('=',1)]};assert len(params)==23
builder=HERE/'prepare_courts_mask_isolate_NOTENGINE.py';compile(builder.read_bytes(),builder.name,'exec')
cfg=dict(status='ROOT_LOCKED_ONE_COURTS_OVERLAY_MASK_ISOLATE_PREPARATION',ready=True,required_builder_sha256=sha(builder.read_bytes()),verifier_template=verifier,publication=dict(path=Y+'overlay_manifest_NOTREADY.json',sha256=sha(pub)),texture=dict(domain='courts_overlay',png=target,png_sha256=v['walk_file_sha256'],decoded_RGBA_sha256=v['walk_RGBA_sha256'],source_size=[3072,2048],sidecar=target+'.import',compiled=compiled),exact_23_import_params=params,scope='One unchanged published PNG copied only into NEW isolate. No main PNG/import/ctex writes or engine by Source. Root later may approve only two NEW import/ctex leaves.',root_protection=dict(path='res://build/luoyang_city_revision_20261024b_root01/c_start_fresh_observation.json',sha256='18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a'))
inp=out('courts_mask_isolate_input_ROOT_READY.json',enc(cfg))
proof=out('courts_mask_import_tools_inverse_BUILD.json',enc(dict(status='COURTS_SINGLE_MASK_IMPORT_TOOLS_BUILD_NO_ENGINE',parent_template=dict(path=S+parent.name,sha256=sha(old)),template=verifier,edits=edits,whole_byte_forward_inverse=True,builder=dict(path=S+builder.name,sha256=sha(builder.read_bytes())),input=inp,PNG_decode=0,pixel_writes=0,engine_calls=0,main_project_writes=0)))
print(json.dumps(dict(builder=dict(path=S+builder.name,sha256=sha(builder.read_bytes())),input=inp,template=verifier,proof=proof,compiled=compiled)))
