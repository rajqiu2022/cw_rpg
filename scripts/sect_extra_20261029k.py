"""One dispatch per missing native terrain asset; no retries or replacement of prior images."""
from sect_maps_20261029k import *
import gen_assets as renderer
EXTRA={
'limestone_mass':('wudang','武当·灰岩山体','ONE complete isolated long broad limestone crag mass for elevated orthographic 2.5D Chinese mountain RPG. Grey pale weathered vertical naturally fractured LIMESTONE, massive layered buttresses with ledges and a relatively level irregular broad top lip, tiny sparse dark green moss only. Wide horizontal silhouette about2.4width/height. Natural tall cliff face with deep crevices and believable rock stratification, NOT masonry blocks, no walls or stairs, no tree, no people, no sky, no clouds, no ground backdrop. Entire rock complete with generous genuine transparent alpha0 margins20%all sides. Restrained semi-realistic hand-painted game art matching approved mountain design. Not a whole landscape.'),
'quiet_ground':('mingwu','门派·低对比苔草土面','ONE seamless square game ground material texture, directly TOP DOWN orthographic flat surface, no horizon or perspective. Fine weathered muted grey-brown soil with thin scattered desaturated olive-green moss and very short sparse grass, occasional tiny flat grey stone grains. Broad calm lowcontrast zones, no dramatic dark specks or bright noisy foliage, no shrubs, plants taller than2cm, no roots, flowers, cobblestone road, object, tree, border, watermark or text. Even neutral daylight, subdued realistic handpainted wuxia game ground. Seamless TILE in BOTH axes, edge-to-edge opaque texture. Color must read muted grey-green rather than vivid green. Texture ONLY not landscape.')}
def register():
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));renderer.TEMPLATES_DIR=QUEUE/'templates';out={}
    for key,(sect,label,prompt) in EXTRA.items():
        assert not any(r['key']==key for r in m['assets']);assert renderer.render_template('native',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8');ref=ROOT/'assets/raw/sect_redesign_20261029j'/(sect+'_masterplan_v2.png')
        m['assets'].append({'key':key,'sect':sect,'label':label,'prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'calls':1,'status':'DISPATCHED','backend':'builtin_image_gen','model':None,'provider':None,'fallback_used':False})
        out[key]={'prompt':prompt,'reference':str(ref),'transparent':key!='quiet_ground'}
    save(RAW/'manifest.json',m);print(json.dumps(out))
def adopt():
    import math
    media=json.loads((STAGE/'media.json').read_text('utf-8'));checks=json.loads((STAGE/'padding-verification.json').read_text('utf-8'))
    for key in EXTRA:
        src=RAW/(key+'.png');im=Image.open(src);px=py=0;out=im
        if key!='quiet_ground':
            assert im.mode=='RGBA';w,h=im.size;b=im.getchannel('A').getbbox();px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
            out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
            b=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
            checks.append({'key':key,'raw_A1_pass':False,'all_original_RGBA_exact':True,'alpha_cleaned_pixels':0,'offset':[px,py]})
        else:b=[0,0,*im.size]
        dst=ROOT/'assets/processed'/NAME/(key+'.png');out.save(dst);shutil.copyfile(dst,PROJECT/ART/(key+'.png'))
        media[key]={'path':ART+'/'+key+'.png','bbox':[b[0]+px,b[1]+py,b[2]+px,b[3]+py],'padding':[px,py],'size':list(out.size),'raw':src.relative_to(ROOT).as_posix(),'processed':dst.relative_to(ROOT).as_posix(),'label':EXTRA[key][1]}
    save(STAGE/'media.json',media);save(STAGE/'padding-verification.json',checks)
if __name__=='__main__':{'register':register,'adopt':adopt}[sys.argv[1]]()
