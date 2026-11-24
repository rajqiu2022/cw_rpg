"""Inspection-only composites and four equal-cell playback; never edits source PNGs."""
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/raw/world_placeables_walk_20261022'
DEST=ROOT/'assets/previews/world_placeables_walk_20261022'

def main():
    DEST.mkdir(parents=True,exist_ok=True)
    font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',15)
    rows=[]
    for name in ['manifest.json','walk-successors.json','walk-frames.json','walk-guided-frames.json']:
        p=BASE/name
        if p.is_file():rows += [r for r in json.loads(p.read_text('utf-8'))['assets'] if r.get('sha256')]
    sheets={};metrics=[];families={}
    for r in rows:
        if r['kind']=='npc_walk_frames':
            families.setdefault(r['family'],[]).append(r);continue
        if r['kind']=='npc_walk':
            with Image.open(ROOT/r['output']) as im:
                w,h=im.size
                if w%4:
                    metrics.append({'id':r['id'],'equal_four_columns':False,'preview_created':False});continue
                cw=w//4;frames=[];boxes=[];strip=Image.new('RGB',(4*260,360),(232,234,228));draw=ImageDraw.Draw(strip)
                for i in range(4):
                    cell=im.crop((i*cw,0,(i+1)*cw,h)).convert('RGBA');boxes.append(list(cell.getchannel('A').getbbox()))
                    image=Image.new('RGBA',cell.size,(228,232,226,255));image.alpha_composite(cell)
                    image.thumbnail((250,330),Image.Resampling.LANCZOS)
                    panel=Image.new('RGB',(260,360),(232,234,228));panel.paste(image.convert('RGB'),((260-image.width)//2,0))
                    ImageDraw.Draw(panel).text((12,338),'原格帧'+str(i+1),font=font,fill=(25,35,40))
                    frames.append(panel);strip.paste(panel,(260*i,0))
                frames[0].save(DEST/(r['id']+'.gif'),save_all=True,append_images=frames[1:],duration=180,loop=0,disposal=2)
                strip.save(DEST/(r['id']+'_frames.jpg'),quality=94)
                metrics.append({'id':r['id'],'equal_four_columns':True,'raw_cell_size':[cw,h],'original_ratio_4_to_1':w==4*h,'full_alpha_cell_bboxes':boxes,'preview_created':True,'preview_is_runtime_artifact':False,'gait_semantics_require_visual_review':True})
        else:sheets.setdefault(r['kind'],[]).append(r)
    for kind,items in sheets.items():
        sheet=Image.new('RGB',(1360,300*((len(items)+3)//4)),(232,234,228));draw=ImageDraw.Draw(sheet)
        for i,r in enumerate(items):
            x,y=(i%4)*340,(i//4)*300
            panel=Image.new('RGBA',(330,255),(228,232,226,255))
            with Image.open(ROOT/r['output']) as im:
                thumb=im.convert('RGBA');thumb.thumbnail((320,245),Image.Resampling.LANCZOS)
                panel.alpha_composite(thumb,((330-thumb.width)//2,(255-thumb.height)//2))
            sheet.paste(panel.convert('RGB'),(x+5,y+3));draw.text((x+8,y+263),r['label'],font=font,fill=(25,35,40));draw.text((x+8,y+283),'原图候选 · 场景可放置',font=font,fill=(105,62,38))
        sheet.save(DEST/(kind+'.jpg'),quality=93)
    for family,items in families.items():
        guided=[r for r in items if r['id'].endswith('_v4')]
        if guided:items=guided
        items.sort(key=lambda r:r['frame_index'])
        if len(items)!=4:continue
        sizes=[r['metrics']['size'] for r in items];mw=max(s[0] for s in sizes);mh=max(s[1] for s in sizes)
        frames=[];strip=Image.new('RGB',(1040,360),(232,234,228))
        for i,r in enumerate(items):
            with Image.open(ROOT/r['output']) as im:
                canvas=Image.new('RGBA',(mw,mh),(228,232,226,255));canvas.alpha_composite(im.convert('RGBA'),((mw-im.width)//2,0))
                canvas.thumbnail((250,330),Image.Resampling.LANCZOS)
                panel=Image.new('RGB',(260,360),(232,234,228));panel.paste(canvas.convert('RGB'),((260-canvas.width)//2,0))
                ImageDraw.Draw(panel).text((10,338),'原生帧'+str(i+1)+' · '+r['phase'],font=font,fill=(25,35,40))
                frames.append(panel);strip.paste(panel,(260*i,0))
        frames[0].save(DEST/(family+'_raw_walk_down.gif'),save_all=True,append_images=frames[1:],duration=180,loop=0,disposal=2)
        strip.save(DEST/(family+'_walk_down_frames.jpg'),quality=94)
        aligned=[];placements=[];aligned_strip=Image.new('RGB',(1280,340),(232,234,228))
        for i,r in enumerate(items):
            with Image.open(ROOT/r['output']) as im:
                # Display fitting only: no alpha is erased in either source or the displayed layer.
                # Full A>0 margins are independently checked and never replaced by this diagnostic bbox.
                box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
                scale=240/(box[3]-box[1]);anchor=[(box[0]+box[2])/2,box[3]]
                layer=im.convert('RGBA').resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
                offset=[round(160-anchor[0]*scale),round(285-anchor[1]*scale)]
                panel=Image.new('RGBA',(320,340),(228,232,226,255));panel.alpha_composite(layer,tuple(offset))
                ImageDraw.Draw(panel).text((10,308),'对齐查看 · 原图未规范化',font=font,fill=(95,53,32))
                aligned.append(panel.convert('RGB'));aligned_strip.paste(panel.convert('RGB'),(320*i,0))
                placements.append({'id':r['id'],'diagnostic_alpha128_bbox':list(box),'scale':scale,'offset':offset,'source_unchanged':True,'runtime_admitted':False})
        aligned[0].save(DEST/(family+'_walk_down.gif'),save_all=True,append_images=aligned[1:],duration=180,loop=0,disposal=2)
        aligned_strip.save(DEST/(family+'_aligned_frames.jpg'),quality=94)
        metrics.append({'family':family,'individual_native_frames':4,'source_sizes':sizes,'equal_source_canvas':len({tuple(s) for s in sizes})==1,'preview_created':True,'preview_is_runtime_artifact':False,'foot_alignment_correction':'aligned preview only; raw preview also preserved','placements':placements,'synthetic_interpolation':False,'gait_semantics_require_visual_review':True})
    (BASE/'preview-cell-metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps({'raw_images':len(rows),'walk_previews':sum(r['preview_created'] for r in metrics),'placeable_groups':list(sheets)}))

if __name__=='__main__':main()
