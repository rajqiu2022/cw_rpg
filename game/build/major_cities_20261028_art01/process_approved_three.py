from pathlib import Path
import hashlib,json,math
import numpy as np
from scipy import ndimage
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
RAW=ROOT/'assets/raw/bianzhou_southgate_20261028'
OUT=ROOT/'assets/processed/bianzhou_southgate_20261028'
IDS=['main_gatehouse_v1','checkpoint_shelter_v1','connected_barbican_v1']
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def plan_one(name):
    path=RAW/(name+'.png'); im=Image.open(path).convert('RGBA');arr=np.array(im);alpha=arr[:,:,3]
    labels,count=ndimage.label(alpha>0,structure=np.ones((3,3),dtype=int))
    sizes=np.bincount(labels.ravel());sizes[0]=0
    significant=[int(i) for i in np.argsort(sizes)[::-1][:2 if name=='connected_barbican_v1' else 1]]
    ys,xs=np.where(np.isin(labels,significant)); bbox=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)]
    protect=[max(0,bbox[0]-8),max(0,bbox[1]-8),min(im.width,bbox[2]+8),min(im.height,bbox[3]+8)]
    outside=np.ones(alpha.shape,dtype=bool);outside[protect[1]:protect[3],protect[0]:protect[2]]=False
    remove=outside&(alpha>0)&(alpha<=3)
    nonweak=outside&(alpha>3)
    assert not nonweak.any(),(name,int(alpha[nonweak].max()),int(nonweak.sum()))
    candidate=arr.copy();candidate[:,:,3][remove]=0
    cleanbbox=Image.fromarray(candidate).getchannel('A').getbbox()
    # Add ONLY transparent canvas; preserve original source origin, no crop or rescale.
    padx=math.ceil(im.width*.18);pady=math.ceil(im.height*.18)
    target=Image.new('RGBA',(im.width+2*padx,im.height+2*pady),(0,0,0,0))
    target.paste(Image.fromarray(candidate),(padx,pady))
    targetarr=np.array(target);back=targetarr[pady:pady+im.height,padx:padx+im.width,:]
    assert np.array_equal(back[:,:,:3],arr[:,:,:3])
    assert np.array_equal(back[protect[1]:protect[3],protect[0]:protect[2]],arr[protect[1]:protect[3],protect[0]:protect[2]])
    changed=np.any(back!=arr,axis=2);assert np.array_equal(changed,remove)
    bbox_final=target.getchannel('A').getbbox()
    margins=[bbox_final[0]/target.width,bbox_final[1]/target.height,(target.width-bbox_final[2])/target.width,(target.height-bbox_final[3])/target.height]
    assert min(margins)>=.10
    return target,{'id':name,'source_path':str(path.relative_to(ROOT)).replace('\\','/'),'source_sha256':digest(path),
                   'source_size':im.size,'significant_8connected_components':len(significant),'significant_component_union_A1_bbox':bbox,'protected_rect_xyxy':protect,
                   'removed_pixels':int(remove.sum()),'removed_alpha_values':np.unique(alpha[remove]).tolist(),
                   'protected_RGBA_unchanged':True,'all_RGB_unchanged':True,
                   'padding_offset_px':[padx,pady],'padded_size':target.size,'complete_A1_bbox':bbox_final,
                   'four_margin_ratios':margins,'pixel_scale_preserved':True,
                   'draw_origin_rule':'new_origin = old_origin - padding_offset * original_uniform_pixel_scale',
                   'raw_original_preserved':True}
def main():
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--execute',action='store_true');args=parser.parse_args()
    initial=[digest(RAW/(n+'.png')) for n in IDS];prepared=[plan_one(n) for n in IDS]
    report={'status':'AUTHORIZED_DRY_RULES_PASS_NO_PNG_WRITTEN','permission':'Human explicitly allowed this Bianzhou batch local outside-subject weak-alpha cleanup and transparent padding; conveyed by Root on 2026-10-28. Only these selected three, not old stock.',
            'scope':IDS,'image_resampling':False,'raw_write':False,'assets':[row for image,row in prepared]}
    if args.execute:
        OUT.mkdir(parents=True,exist_ok=True)
        for image,row in prepared:
            dest=OUT/(row['id']+'_padded.png');assert not dest.exists(),str(dest)
            image.save(dest)
            row['processed_path']=str(dest.relative_to(ROOT)).replace('\\','/')
            row['processed_sha256']=digest(dest)
        report['status']='AUTHORIZED_THREE_EXECUTED_BODY_RGBA_AND_RAW_PRESERVED'
    assert initial==[digest(RAW/(n+'.png')) for n in IDS]
    destreport=HERE/('processing_actual.json' if args.execute else 'processing_dry.json')
    assert not destreport.exists(),str(destreport)
    destreport.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
