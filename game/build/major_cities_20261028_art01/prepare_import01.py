from pathlib import Path
import hashlib,json,shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
STAGE=HERE/'import01'
receipt=json.loads((HERE/'processing_actual.json').read_text(encoding='utf-8'))
old=ROOT/'assets/staging/luoyang_three_buildings_20261027d_import01/art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png.import'
template=old.read_text(encoding='utf-8')
assert len(receipt['assets'])==3
rows=[];leaves=[]
for item in receipt['assets']:
    name=item['id']+'_padded.png'
    resource='res://art/maps/bianzhou_southgate_20261028/'+name
    source=ROOT/item['processed_path'];dest=STAGE/resource.removeprefix('res://')
    dest.parent.mkdir(parents=True,exist_ok=True)
    assert not dest.exists()
    shutil.copyfile(source,dest)
    assert hashlib.sha256(dest.read_bytes()).hexdigest()==item['processed_sha256']
    compiled='res://.godot/imported/'+name+'-'+hashlib.md5(resource.encode()).hexdigest()+'.ctex'
    sidecar=template
    oldresource='res://art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png'
    oldcompiled='res://.godot/imported/east_shop_residence_v1_padded.png-270e0b92819237b04fbeb96613902b29.ctex'
    sidecar=sidecar.replace(oldcompiled,compiled).replace(oldresource,resource)
    sidecar='\n'.join(line for line in sidecar.splitlines() if not line.startswith('uid='))+'\n'
    Path(str(dest)+'.import').write_text(sidecar,encoding='utf-8')
    im=Image.open(source).convert('RGBA')
    rows.append({'id':item['id'],'png':resource,'compiled':compiled,'png_sha256':item['processed_sha256'],
                 'RGBA_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'size':list(im.size)})
    for kind,r in [('png',resource),('sidecar',resource+'.import'),('ctex',compiled)]:
        leaves.append({'id':item['id'],'kind':kind,'source_isolate':str(STAGE/r.removeprefix('res://')),
                       'target_main':str(ROOT/'game'/r.removeprefix('res://')),'target_res':r})
prepared={'status':'THREE_COMPONENT_ISOLATE_PREPARED_NOT_RUN','textures':rows,
          'processing_receipt_sha256':hashlib.sha256((HERE/'processing_actual.json').read_bytes()).hexdigest(),
          'import_parameters':{'compress/mode':0,'mipmaps/generate':False,'process/fix_alpha_border':False,'process/premult_alpha':False,'detect_3d/compress_to':0}}
(STAGE/'prepared.json').write_text(json.dumps(prepared,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'nine_leaf_promotion_plan_NOT_EXECUTED.json').write_text(json.dumps({'status':'ROOT_ONLY_AFTER_IMPORT_AND_FULL_RGBA_VERIFY','leaves':leaves},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(prepared,ensure_ascii=False,indent=2))
