"""Read generated PNG exactly, report whole-alpha bounds; never modify an image."""
from pathlib import Path
import argparse, hashlib, json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--raw',required=True);p.add_argument('--sha',required=True)
    p.add_argument('--max-width',type=int,required=True);p.add_argument('--max-height',type=int,required=True)
    p.add_argument('--task',required=True);p.add_argument('--output',required=True)
    a=p.parse_args();assert '/' not in a.output and '\\' not in a.output
    path=ROOT/a.raw;raw=path.read_bytes();before=path.stat();assert sha(raw)==a.sha.lower()
    im=Image.open(path);im.load();rgba=im.convert('RGBA');W,H=rgba.size
    bounds=rgba.getchannel('A').getbbox();assert bounds
    x0,y0,x1,y1=bounds;bw,bh=x1-x0,y1-y0
    margins=[x0,y0,W-x1,H-y1]
    margin_ok=all([10*x0>=W,10*y0>=H,10*(W-x1)>=W,10*(H-y1)>=H])
    fit=min(a.max_width/bw,a.max_height/bh)
    report=dict(status='READONLY_RAW_PIXEL_FACTS_NOT_IMPORT_OR_GEOMETRY_ADMISSION',task_id=a.task,raw_path=a.raw,raw_sha256=sha(raw),raw_bytes=len(raw),source_mode=im.mode,source_size=[W,H],full_RGBA_sha256=sha(rgba.tobytes()),alpha_extrema=rgba.getchannel('A').getextrema(),full_A1_bbox=list(bounds),full_A1_size=[bw,bh],full_A1_margin_pixels=margins,full_A1_margin_fractions=[x0/W,y0/H,(W-x1)/W,(H-y1)/H],full_A1_four_edge_10percent_pass=margin_ok,complete_A1_ratio=bw/bh,maximum_world_A1=[a.max_width,a.max_height],uniform_max_fit_scale=fit,uniform_fit_A1_size=[bw*fit,bh*fit],minimum_source_clear_door_for_world145=145/fit,minimum_source_clear_width_for_world170=170/fit,door_measurement_status='NOT_AUTOMATICALLY_INFERRED_FROM_OPAQUE_INTERIOR; visual polygon and ground contact must be separately authored and checked',generation_mode='builtin_image_gen; generation itself performed by Root',model=None,provider=None,cost=None,local_image_edits=0,resize=0,Godot_calls=0,source_unchanged=True)
    out=OUT/a.output
    with out.open('xb') as f:f.write((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
    after=path.stat();assert path.read_bytes()==raw and (after.st_size,after.st_mtime_ns)==(before.st_size,before.st_mtime_ns)
    print(json.dumps(dict(report=str(out.relative_to(ROOT)).replace('\\','/'),sha256=sha(out.read_bytes()),A1_box=list(bounds),A1_four_edge_margin_pass=margin_ok,fit_A1=report['uniform_fit_A1_size'],source_door_min=report['minimum_source_clear_door_for_world145'])))
if __name__=='__main__':main()
