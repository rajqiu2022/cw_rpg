from pathlib import Path
import hashlib,json,shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
STAGE=HERE/'import05'
receipt_path=HERE/'processing_actual.json'
assert receipt_path.exists(), 'Stop: no actual user-authorized processing receipt, do not substitute raw fallback.'
receipt=json.loads(receipt_path.read_text(encoding='utf-8'))
assert receipt.get('status') in ['PASS','PASS_AUTHORIZED_FOUR','FOUR_AUTHORIZED_COMPONENTS_PROCESSED']
binding=json.loads((HERE/'selected_four_native_binding_PROPOSAL.json').read_text(encoding='utf-8'))
byid={item['id']:item for item in receipt['assets']}
assert set(byid)=={item['id']for item in binding['assets']}
old=ROOT/'assets/staging/luoyang_three_buildings_20261027d_import01/art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png.import'
template=old.read_text(encoding='utf-8')
textures=[];leaves=[]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
for item in [*binding['assets'],binding['ground']]:
 name=item['id'];filename=item['formal_filename']
 if name in byid:
  actual=byid[name];source=ROOT/actual['processed_path'];expected=actual['processed_sha256']
 else:source=ROOT/item['raw'];expected=item['sha256']
 assert sha(source)==expected
 resource='res://art/maps/bianzhou_enclosure_20261028d/'+filename
 dest=STAGE/resource.removeprefix('res://');dest.parent.mkdir(parents=True,exist_ok=True)
 assert not dest.exists(), 'CreateNew isolate only; retain any earlier attempt.'
 shutil.copyfile(source,dest)
 compiled='res://.godot/imported/'+filename+'-'+hashlib.md5(resource.encode()).hexdigest()+'.ctex'
 sidecar=template.replace('res://.godot/imported/east_shop_residence_v1_padded.png-270e0b92819237b04fbeb96613902b29.ctex',compiled).replace('res://art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png',resource)
 sidecar='\n'.join(line for line in sidecar.splitlines()if not line.startswith('uid='))+'\n'
 Path(str(dest)+'.import').write_text(sidecar,encoding='utf-8')
 im=Image.open(source).convert('RGBA')
 textures.append({'id':name,'png':resource,'compiled':compiled,'png_sha256':expected,'RGBA_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'size':list(im.size)})
 for kind,res in [('png',resource),('sidecar',resource+'.import'),('ctex',compiled)]:
  leaves.append({'id':name,'kind':kind,'source_isolate':str(STAGE/res.removeprefix('res://')),'target_main':str(ROOT/'game'/res.removeprefix('res://')),'target_res':res})
prepared={'status':'FIVE_TEXTURES_ISOLATE_PREPARED_NOT_RUN','textures':textures,'processing_receipt_sha256':sha(receipt_path),
'import_parameters':{'compress/mode':0,'mipmaps/generate':False,'process/fix_alpha_border':False,'process/premult_alpha':False,'detect_3d/compress_to':0}}
(STAGE/'prepared.json').write_text(json.dumps(prepared,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'fifteen_leaf_promotion_plan_NOT_EXECUTED.json').write_text(json.dumps({'status':'ROOT_ONLY_AFTER_NATURAL_IMPORT_AND_FULL_RGBA_VERIFY','leaves':leaves},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(prepared,ensure_ascii=False,indent=2))
