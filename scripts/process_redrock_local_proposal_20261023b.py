"""Prepared exact local operation. Execute only after the human explicitly requests this scope."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
PLAN=ROOT/'assets/staging/redrock_gate_20261023b/local-processing-proposal.json'
OUTPUT=ROOT/'assets/processed/redrock_gate_20261023b'


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def run(execute=False):
    plan=json.loads(PLAN.read_text('utf-8'))
    assert plan['status']=='PREPARED_NOT_EXECUTED_REQUIRES_EXPLICIT_LOCAL_PROCESSING_REQUEST'
    assert len(plan['allowed_sources'])==12
    observations=[]
    for item in plan['allowed_sources']:
        source=ROOT/item['source'];assert sha(source)==item['sha256'],str(source)
        with Image.open(source) as im:
            assert im.mode=='RGBA' and list(im.size)==item['old_size']
            src=np.array(im)
        array=src.copy();removed=0
        if item['key']=='gate_opening':
            x0,y0,x1,y1=plan['gate_only_change']['rect'];region=array[y0:y1,x0:x1,3]
            values,counts=np.unique(region[region>0],return_counts=True)
            histogram={str(int(k)):int(v) for k,v in zip(values,counts)}
            assert histogram==plan['gate_only_change']['allowed_alpha_histogram']
            assert int((region>0).sum())==352
            region[region>0]=0;removed=352
        assert np.array_equal(array[:,:,:3],src[:,:,:3])
        diff=np.any(array!=src,axis=2)
        assert int(diff.sum())==removed
        assert not np.any(array[diff,3]!=0)
        px,py=item['pad'];nw,nh=item['new_size']
        padded=np.zeros((nh,nw,4),dtype=np.uint8)
        padded[py:py+src.shape[0],px:px+src.shape[1]]=array
        alpha=Image.fromarray(padded[:,:,3]);bbox=alpha.getbbox();margins=[bbox[0]/nw,bbox[1]/nh,(nw-bbox[2])/nw,(nh-bbox[3])/nh]
        assert min(margins)>=.1
        assert np.array_equal(padded[py:py+src.shape[0],px:px+src.shape[1]],array)
        out=OUTPUT/item['key']/(source.stem+'_padded.png')
        record={'key':item['key'],'source':item['source'],'source_sha256':item['sha256'],
                'output':out.relative_to(ROOT).as_posix(),'old_size':item['old_size'],'new_size':item['new_size'],
                'source_offset':[px,py],'complete_alpha_bbox':list(bbox),'margin_fraction':margins,
                'original_RGB_preserved':True,'changed_original_alpha_pixels':removed,
                'all_other_original_RGBA_preserved':True,'formal_enabled':False}
        if execute:
            assert not out.exists();out.parent.mkdir(parents=True,exist_ok=True)
            Image.fromarray(padded).save(out)
            with Image.open(out) as readback:assert np.array_equal(np.array(readback),padded)
            record['sha256']=sha(out)
            out.with_suffix('.meta.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n','utf-8')
        assert sha(source)==item['sha256']
        observations.append(record)
    report={'status':'EXECUTED_USER_AUTHORIZED' if execute else 'DRY_RUN_ONLY_NO_IMAGES_WRITTEN',
            'proposal_sha256':sha(PLAN),'sources':12,'alpha_changes':352,'local_images_written':12 if execute else 0,
            'records':observations}
    if execute:OUTPUT.mkdir(parents=True,exist_ok=True);(OUTPUT/'processing-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
    else:(PLAN.parent/'local-processing-dry-run.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps({'status':report['status'],'sources':12,'local_images_written':report['local_images_written']}))


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--execute-user-explicitly-requested',action='store_true')
    args=parser.parse_args();run(args.execute_user_explicitly_requested)
