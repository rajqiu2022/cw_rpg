"""Root-only single opaque portrait isolate preparation. No subprocess/main writes."""
from pathlib import Path
import argparse,hashlib,json,struct
HERE=Path(__file__).resolve().parent; GAME=Path(__file__).resolve().parents[2]; ROOT=GAME.parent
ISOLATE=ROOT/'assets/staging/luoyang_scholar_portrait_20261024c_import'
TARGET='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png'
PROFILE=GAME/'data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png.import'
PROFILE_SHA='57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15'
PARAMS={"compress/mode":0,"compress/high_quality":False,"compress/lossy_quality":0.7,"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":False,"mipmaps/limit":-1,"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,"process/fix_alpha_border":False,"process/premult_alpha":False,"process/normal_map_invert_y":False,"process/hdr_as_srgb":False,"process/hdr_clamp_exposure":False,"process/size_limit":0,"detect_3d/compress_to":0}
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(p,h):
    b=p.read_bytes();assert isinstance(h,str) and len(h)==64 and sha(b)==h,(str(p),'EXACT_SHA_REQUIRED');return b
def fact(p):
    s=p.stat();return dict(sha256=sha(p.read_bytes()),bytes=s.st_size,mtime_ns=s.st_mtime_ns)
def new(rel,b):
    p=(ISOLATE/rel).resolve();assert p.is_relative_to(ISOLATE.resolve()) and not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(b)
def main():
    ap=argparse.ArgumentParser();ap.add_argument('input');ap.add_argument('--input-sha256',required=True);args=ap.parse_args()
    inp=Path(args.input).resolve();raw=checked(inp,args.input_sha256);cfg=json.loads(raw)
    assert cfg['ready'] is True and cfg['status']=='ROOT_LOCKED_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATE_PREPARATION' and cfg['target_png']==TARGET
    assert not ISOLATE.exists(),'NEW_ISOLATE_ONLY'
    template_path=GAME/cfg['verifier_template']['path'][6:];template=checked(template_path,cfg['verifier_template']['sha256']).decode()
    assert sha(Path(__file__).read_bytes())==cfg['required_builder_sha256']
    prior_path=Path(cfg['source_prior']['path']).resolve();prior=json.loads(checked(prior_path,cfg['source_prior']['sha256']))
    assert prior['status']=='ROOT_FIXED_OPAQUE_SCHOLAR_PORTRAIT_RGBA_PRIOR' and prior['opaque'] is True
    source=Path(prior['source_png']).resolve();assert source.is_relative_to((ROOT/'assets').resolve()) and not source.is_relative_to(GAME.resolve())
    png=checked(source,prior['png_sha256']);size=prior['source_size'];rgba=prior['decoded_RGBA_sha256']
    assert len(size)==2 and all(type(x) is int and 0<x<=8192 for x in size) and isinstance(rgba,str) and len(rgba)==64 and all(c in '0123456789abcdef' for c in rgba)
    assert png[:8]==b'\x89PNG\r\n\x1a\n' and png[12:16]==b'IHDR' and list(struct.unpack('>II',png[16:24]))==size and png[24]==8 and png[25] in [2,6]
    # Header only, no image decode or pixel processing. Independent prior stays authority.
    profile=checked(PROFILE,PROFILE_SHA).decode();params_text=profile.split('[params]',1)[1]
    parsed={k:json.loads(v) for line in params_text.splitlines() if '=' in line for k,v in [line.split('=',1)]};assert parsed==PARAMS and len(parsed)==23
    expected={'paper_scholar_portrait':dict(png=TARGET,png_sha256=prior['png_sha256'],decoded_RGBA_sha256=rgba,source_size=size)}
    compiled='res://.godot/imported/'+Path(TARGET).name+'-'+hashlib.md5(TARGET.encode()).hexdigest()+'.ctex'
    item=dict(expected['paper_scholar_portrait'],domain='paper_scholar_portrait',sidecar=TARGET+'.import',compiled=compiled,source_original=str(source))
    absent=[str((GAME/p[6:]).resolve()) for p in [TARGET,item['sidecar'],compiled]];assert len(set(absent))==3 and all(not Path(p).exists() for p in absent)
    protected={str(p):fact(p) for p in [source,prior_path,inp,PROFILE,template_path,Path(__file__).resolve()]}
    project=b'config_version=5\n\n[application]\nconfig/name="Luoyang One Opaque Scholar Portrait Isolated Import 20261024c"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n'
    seed=('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\npath='+json.dumps(compiled)+'\nmetadata={\n"vram_texture": false\n}\n\n[deps]\n\nsource_file='+json.dumps(TARGET)+'\ndest_files=['+json.dumps(compiled)+']\n\n[params]'+params_text).encode()
    prepared=dict(status='EXACT_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_IMPORT_PREPARED',textures=[item],project_sha256=sha(project),protected_main_sources=protected,main_three_absent_targets=absent,exact_23_import_params=PARAMS,production_promoted=False,source_prior=cfg['source_prior'])
    manifest=(json.dumps(prepared,ensure_ascii=False,indent=2)+'\n').encode()
    begin=template.index('const EXPECTED: Dictionary=');end=template.index('\nconst PARAMS:',begin)
    verifier=template[:begin]+'const EXPECTED: Dictionary='+json.dumps(expected,indent=2)+template[end:]
    assert verifier.count('PENDING_PREPARED_SHA')==1 and verifier.count('const READY: bool=false')==1
    verifier=verifier.replace('PENDING_PREPARED_SHA',sha(manifest)).replace('const READY: bool=false','const READY: bool=true')
    new('project.godot',project);new(TARGET[6:],png);new(item['sidecar'][6:],seed);new('seeds/paper_scholar_portrait.png.import.seed',seed);new('prepared_READY.json',manifest);new('verify_READY.gd',verifier.encode())
    assert all(fact(Path(p))==v for p,v in protected.items()) and all(not Path(p).exists() for p in absent)
    receipt=dict(status='ONE_PORTRAIT_PREPARED_NOT_IMPORTED_NOT_PROMOTED',isolate=str(ISOLATE),prepared_sha256=sha(manifest),verifier_sha256=sha(verifier.encode()),source_png_sha256=prior['png_sha256'],main_three_targets='ABSENT',engine_calls=0,canonical_writes=0,pixel_edits=0,root_commands=[['GODOT','--headless','--editor','--import','--path',str(ISOLATE),'--quit'],['GODOT','--headless','--path',str(ISOLATE),'--script','res://verify_READY.gd']],process_policy='Root starts once with retained WaitForExit/actual exit report; this script never launches Godot.')
    rb=(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode();new('preparation_receipt_READY.json',rb)
    print(json.dumps(dict(receipt,receipt_sha256=sha(rb)),ensure_ascii=False))
if __name__=='__main__':main()
