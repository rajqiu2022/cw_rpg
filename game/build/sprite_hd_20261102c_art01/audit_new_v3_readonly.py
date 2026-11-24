"""Metadata-only audit of new raw sprites; no image mutation or image writes."""
from pathlib import Path
from hashlib import sha256
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
RAW=ROOT/'assets/raw/sprite/pc_hero_hd_native1536_20261102c'
rows=[]
for kind,columns,nrows in [('idle',4,1),('walk',4,2)]:
    path=RAW/f'hero_sword_down_{kind}_v3_RAW.png'
    with Image.open(path) as original:
        im=original.convert('RGBA')
        width,height=im.size
        result={'state':kind,'path':path.relative_to(ROOT).as_posix(),'size':[width,height],'grid':[columns,nrows],'sha256':sha256(path.read_bytes()).hexdigest(),'image_writes':0,'frames':[]}
        for row in range(nrows):
            for column in range(columns):
                cell=im.crop((column*width//columns,row*height//nrows,(column+1)*width//columns,(row+1)*height//nrows))
                alpha=cell.getchannel('A')
                bounds={str(threshold):alpha.point(lambda value:255 if value>=threshold else 0).getbbox() for threshold in [1,2,3,8,24,64,128,224,250]}
                body=bounds['128']
                body24=bounds['24']
                data=list(cell.getdata())
                histogram=alpha.histogram()
                footline=body[3]-1 if body else -1
                feet=[]
                outside_body8=[]
                outside_body24_8=[]
                for y in range(cell.height):
                    for x in range(cell.width):
                        rgba=data[y*cell.width+x]
                        if rgba[3]>=128 and y>=footline-8:
                            feet.append(x)
                        if body and not (body[0]-8<=x<body[2]+8 and body[1]-8<=y<body[3]+8) and rgba[3]>2:
                            outside_body8.append(rgba[3])
                        if body24 and not (body24[0]-8<=x<body24[2]+8 and body24[1]-8<=y<body24[3]+8) and rgba[3]>2:
                            outside_body24_8.append(rgba[3])
                border=[]
                for y in range(cell.height):
                    for x in [0,cell.width-1]:border.append(data[y*cell.width+x][3])
                for x in range(cell.width):
                    for y in [0,cell.height-1]:border.append(data[y*cell.width+x][3])
                record={'index':row*columns+column,'row':row,'column':column,'cell_size':list(cell.size),'threshold_bounds':bounds,'body_height_alpha24':body24[3]-body24[1] if body24 else 0,'foot_y_alpha128':footline,'foot_center_alpha128_bottom9':sum(feet)/len(feet) if feet else None,'border_max_alpha':max(border),'outside_body128_bbox_grow8_alpha_gt2_count':len(outside_body8),'outside_body128_bbox_grow8_maxalpha':max(outside_body8,default=0),'outside_body24_bbox_grow8_alpha_gt2_count':len(outside_body24_8),'outside_body24_bbox_grow8_maxalpha':max(outside_body24_8,default=0),'rgba_sha256':sha256(cell.tobytes()).hexdigest(),'alpha_sha256':sha256(alpha.tobytes()).hexdigest()}
                result['frames'].append(record)
                print(kind,record['index'],bounds,'body',record['body_height_alpha24'],'foot',footline,record['foot_center_alpha128_bottom9'],'outside',len(outside_body8),max(outside_body8,default=0),'border',max(border))
        result['unique_rgba_frames']=len({f['rgba_sha256'] for f in result['frames']})
        result['unique_alpha_frames']=len({f['alpha_sha256'] for f in result['frames']})
        rows.append(result)
(OUT/'new_v3_pixels_READONLY.json').write_text(json.dumps({'scope':'new_down_idle4_walk8_raw_only','image_edits':0,'image_writes':0,'rows':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
