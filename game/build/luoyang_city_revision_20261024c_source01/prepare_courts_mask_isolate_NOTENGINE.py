"""Root-only exact one published overlay mask preparation; no engine/main writes."""
from pathlib import Path
import argparse,hashlib,json,struct
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];ROOT=GAME.parent
ISOLATE=ROOT/'assets/staging/luoyang_yamen_courts_mask_20261024c_import'
PROFILE=GAME/'data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import'
PROFILE_SHA='57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15'
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(p,h):
    b=p.read_bytes();assert len(h)==64 and sha(b)==h,(str(p),'EXACT_SHA');return b
def fact(p):
    s=p.stat();return dict(sha256=sha(p.read_bytes()),bytes=s.st_size,mtime_ns=s.st_mtime_ns)
def new(rel,b):
    p=(ISOLATE/rel).resolve();assert p.is_relative_to(ISOLATE.resolve()) and not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as stream:stream.write(b)
def main():
    ap=argparse.ArgumentParser();ap.add_argument('input');ap.add_argument('--input-sha256',required=True);a=ap.parse_args()
    ip=Path(a.input).resolve();cfg=json.loads(checked(ip,a.input_sha256))
    assert cfg['ready'] is True and cfg['status']=='ROOT_LOCKED_ONE_COURTS_OVERLAY_MASK_ISOLATE_PREPARATION'
    assert not ISOLATE.exists(),'NEW_ISOLATE_ONLY'
    assert sha(Path(__file__).read_bytes())==cfg['required_builder_sha256']
    pubp=GAME/cfg['publication']['path'][6:];pub=json.loads(checked(pubp,cfg['publication']['sha256']))
    item=cfg['texture'];target=item['png'];source=GAME/target[6:]
    assert pub['walk_path']==target and pub['walk_file_sha256']==item['png_sha256'] and pub['walk_RGBA_sha256']==item['decoded_RGBA_sha256']
    assert pub['changed_pixels']==140469 and pub['visited_pixels']==206290 and pub['full_RGBA_inverse'] is True
    png=checked(source,item['png_sha256']);size=item['source_size']
    assert png[:8]==b'\x89PNG\r\n\x1a\n' and png[12:16]==b'IHDR' and list(struct.unpack('>II',png[16:24]))==size==[3072,2048] and png[24]==8 and png[25] in [2,6]
    compiled='res://.godot/imported/'+Path(target).name+'-'+hashlib.md5(target.encode()).hexdigest()+'.ctex'
    assert item['compiled']==compiled and item['sidecar']==target+'.import'
    absent=[str((GAME/p[6:]).resolve()) for p in [item['sidecar'],compiled]]
    assert all(not Path(p).exists() for p in absent)
    profile=checked(PROFILE,PROFILE_SHA).decode();params_text=profile.split('[params]',1)[1]
    params={k:json.loads(v) for line in params_text.splitlines() if '=' in line for k,v in [line.split('=',1)]}
    assert len(params)==23 and params==cfg['exact_23_import_params']
    template_path=GAME/cfg['verifier_template']['path'][6:];template=checked(template_path,cfg['verifier_template']['sha256']).decode()
    protected={str(p):fact(p) for p in [source,pubp,ip,PROFILE,template_path,Path(__file__).resolve()]}
    project=b'config_version=5\n\n[application]\nconfig/name="Yamen One Published Courts Overlay Mask Isolate 20261024c"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n'
    seed=('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\npath='+json.dumps(compiled)+'\nmetadata={\n"vram_texture": false\n}\n\n[deps]\n\nsource_file='+json.dumps(target)+'\ndest_files=['+json.dumps(compiled)+']\n\n[params]'+params_text).encode()
    prepared=dict(status='EXACT_ONE_COURTS_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED',textures=[item],project_sha256=sha(project),protected_main_sources=protected,main_two_absent_targets=absent,exact_23_import_params=params,production_promoted=False,publication=cfg['publication'])
    manifest=(json.dumps(prepared,ensure_ascii=False,indent=2)+'\n').encode()
    expected={'courts_overlay':{k:item[k] for k in ['png','png_sha256','decoded_RGBA_sha256','source_size']}}
    start=template.index('const EXPECTED: Dictionary=');end=template.index('\nconst PARAMS:',start)
    verifier=template[:start]+'const EXPECTED: Dictionary='+json.dumps(expected,indent=2)+template[end:]
    assert verifier.count('PENDING_PREPARED_SHA')==1 and verifier.count('const READY: bool=false')==1
    verifier=verifier.replace('PENDING_PREPARED_SHA',sha(manifest)).replace('const READY: bool=false','const READY: bool=true')
    new('project.godot',project);new(target[6:],png);new(item['sidecar'][6:],seed);new('seeds/overlay.png.import.seed',seed);new('prepared_READY.json',manifest);new('verify_READY.gd',verifier.encode())
    assert all(fact(Path(p))==v for p,v in protected.items()) and all(not Path(p).exists() for p in absent)
    receipt=dict(status='ONE_OVERLAY_MASK_PREPARED_NOT_IMPORTED_NOT_PROMOTED',isolate=str(ISOLATE),prepared_sha256=sha(manifest),verifier_sha256=sha(verifier.encode()),project_sha256=sha(project),source_png_sha256=item['png_sha256'],main_two_targets='ABSENT',engine_calls=0,canonical_writes=0,pixel_edits=0,root_commands=[['GODOT','--headless','--editor','--import','--path',str(ISOLATE),'--quit'],['GODOT','--headless','--path',str(ISOLATE),'--script','res://verify_READY.gd']],process_policy='Root retained WaitForExit/actual exit only. No main project import; later exact two-leaf promotion requires Root approval.')
    rb=(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode();new('preparation_receipt_READY.json',rb)
    print(json.dumps(dict(receipt,receipt_sha256=sha(rb))))
if __name__=='__main__':main()
