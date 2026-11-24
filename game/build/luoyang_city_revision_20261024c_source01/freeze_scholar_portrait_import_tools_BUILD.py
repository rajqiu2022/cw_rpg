"""One read-only raw-image prior, then mechanical isolated-verifier preparation."""
from pathlib import Path
import hashlib,json,copy
from PIL import Image
GAME=Path(__file__).resolve().parents[2];ROOT=GAME.parent;HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024c_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(name,b):
    with (HERE/name).open('xb') as f:f.write(b)
    assert (HERE/name).read_bytes()==b
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
source=ROOT/'assets/raw/luoyang_scholar_portrait_20261024c/luoyang_paper_scholar_portrait_20261024c_v1.png'
raw=source.read_bytes();assert sha(raw)=='ebd60b64edbcc061401a0fc1219d1f120a4f5d4e98db1ab1d129c81f845c2a74' and len(raw)==2627408
prior_file=HERE/'scholar_portrait_raw_RGBA_prior_READONLY.json'
if prior_file.exists():
    pb=prior_file.read_bytes();pv=json.loads(pb);assert pv['png_sha256']==sha(raw) and pv['source_size']==[1254,1254] and pv['opaque']
    prior=dict(path=S+prior_file.name,sha256=sha(pb),bytes=len(pb))
else:
    st=source.stat()
    with Image.open(source) as image:
        assert image.mode=='RGB' and image.size==(1254,1254)
        rgba=image.convert('RGBA');pixels=rgba.tobytes();assert rgba.getextrema()[3]==(255,255)
    prior=out('scholar_portrait_raw_RGBA_prior_READONLY.json',enc(dict(status='ROOT_FIXED_OPAQUE_SCHOLAR_PORTRAIT_RGBA_PRIOR',source_png=str(source),png_sha256=sha(raw),png_bytes=len(raw),source_size=[1254,1254],original_mode='RGB',opaque=True,decoded_RGBA_sha256=sha(pixels),decoded_RGBA_bytes=len(pixels),all_alpha=255,pixel_edits=0,PNG_writes=0,engine_calls=0,source_before_after_same=source.read_bytes()==raw and source.stat().st_mtime_ns==st.st_mtime_ns,basis='Independent Source one raw Pillow decode before isolated import; complete in-memory RGBA bytes only, no crop/resize/background/alpha changes.')))
templatepath=ROOT/'assets/staging/luoyang_two_complete_shops_isolated_import_20261024b/verify_READY.gd';old=templatepath.read_bytes();assert sha(old)=='f37b510ff7df642c9f8aec90f60535015ce701b0fcca07e43174c7d0ce89e1d7'
text=old.decode();edits=[]
def change(a,b,remaining_count=1):
    global text
    assert text.count(a)==remaining_count,(a[:100],text.count(a));i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
start=text.index('const EXPECTED: Dictionary=');end=text.index('\nconst PARAMS:',start)
change(text[start:end],'const EXPECTED: Dictionary={}')
change('const PREPARED_SHA: String="5fe0e961788181638b338caebfb354a35fe709e341a890a98917e1a18cff2596"','const PREPARED_SHA: String="PENDING_PREPARED_SHA"')
change('const READY: bool=true','const READY: bool=false')
# Replacements repeated at several report/guard sites are exact counted mechanical operations.
for a,b,count in [('TWO_SHOPS_IMPORT','SCHOLAR_PORTRAIT_IMPORT',2),('EXACT_TWO_COMPLETE_SHOPS_ISOLATED_IMPORT_PREPARED','EXACT_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_IMPORT_PREPARED',1),('main_six_absent_targets','main_three_absent_targets',2),('spec.textures.size()==2','spec.textures.size()==1',1),('seen.size()==2','seen.size()==1',1),('two_complete_shops_import_result_','scholar_portrait_import_result_',1),('ONLY_TWO_COMPLETE_SHOPS_ISOLATED_FULL_RGBA_NOT_RUNTIME_OR_GEOMETRY','ONLY_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME',1),('Main six targets','Main three targets',1),('Exact two complete shop PNGs only','Exact one opaque scholar portrait PNG only',1),('Exactly two independently expected PNGs verified','Exactly one independently expected portrait PNG verified',1)]:
    assert text.count(a)==count,(a,text.count(a),count)
    for index in range(count):change(a,b,count-index)
needle='\t\tif not need(raw.get_data()==imported.get_data() and raw.get_data()==direct.get_data()'
i=text.index(needle)
block='\t\tvar rgba_data: PackedByteArray=raw.get_data()\n\t\tvar opaque: bool=true\n\t\tfor alpha_index: int in range(3,rgba_data.size(),4):\n\t\t\tif rgba_data[alpha_index]!=255:\n\t\t\t\topaque=false;break\n\t\tif not need(opaque,"Every source RGBA alpha is255; opaque portrait, not background removal"): return false\n'
change(needle,block+needle)
change('"full_RGBA_exact":true,','"full_RGBA_exact":true,"opaque_full_RGBA":true,')
inverse=text.encode()
for e in reversed(edits):
    i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert inverse[i:i+len(b)]==b;inverse=inverse[:i]+a+inverse[i+len(b):]
assert inverse==old
vr=out('verify_scholar_portrait_template_NOTEXEC.gd',text.encode())
builder=HERE/'prepare_scholar_portrait_isolate_NOTENGINE.py';compile(builder.read_bytes(),builder.name,'exec')
inp=out('scholar_portrait_isolate_input_ROOT_READY.json',enc(dict(status='ROOT_LOCKED_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATE_PREPARATION',ready=True,target_png='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png',required_builder_sha256=sha(builder.read_bytes()),verifier_template=dict(path=vr['path'],sha256=vr['sha256']),source_prior=dict(path=str(HERE/'scholar_portrait_raw_RGBA_prior_READONLY.json'),sha256=prior['sha256']),root_protection=dict(path='res://build/luoyang_city_revision_20261024b_root01/c_start_fresh_observation.json',sha256='18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a'),authorization_scope='Root message permits one new opaque exact-ID portrait isolate preparation. No engine by Source, no main project import or promotion, no runtime binding.',source_art_meta=dict(path=str(source.with_suffix('.meta.json')),sha256=sha(source.with_suffix('.meta.json').read_bytes())))))
proof=out('scholar_portrait_import_template_inverse_BUILD.json',enc(dict(status='ONE_PORTRAIT_IMPORT_TOOLS_PREPARED_NO_ENGINE',parent_template=dict(path=str(templatepath),sha256=sha(old)),template=vr,edits=edits,whole_byte_forward_inverse=True,builder=dict(path=S+builder.name,sha256=sha(builder.read_bytes())),input=inp,prior=prior,opaque_no_pixel_processing=True,main_project_writes=0,engine_calls=0)))
print(json.dumps(dict(builder=dict(path=S+builder.name,sha256=sha(builder.read_bytes())),input=inp,template=vr,prior=prior,proof=proof),ensure_ascii=False))
