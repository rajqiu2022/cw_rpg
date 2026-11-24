from pathlib import Path
from PIL import Image
import numpy as np,json
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
im=Image.open(ROOT/'assets/raw/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png').convert('RGB');a=np.asarray(im,dtype=float)
tile=im.copy();tile.thumbnail((420,420));board=Image.new('RGB',(tile.width*3,tile.height*3))
for y in range(3):
 for x in range(3):board.paste(tile,(tile.width*x,tile.height*y))
board.save(HERE/'compacted_earth_3x3_PREVIEW.jpg',quality=94)
out={'status':'RGB_TILE_ONE_CALL_NOT_PIXEL_SEAM_IDENTITY','source_size':im.size,
'left_right_edge_MAE':float(np.abs(a[:,0]-a[:,-1]).mean()),'top_bottom_edge_MAE':float(np.abs(a[0]-a[-1]).mean()),
'internal_horizontal_adjacent_MAE':float(np.abs(a[:,:-1]-a[:,1:]).mean()),'internal_vertical_adjacent_MAE':float(np.abs(a[:-1]-a[1:]).mean()),
'RGB_channel_means':a.mean(axis=(0,1)).tolist(),'suggested_world_period_px':[512,512],
'source_RGB_pixels_unchanged':True,'preview_only_tiling':True}
(HERE/'earth_tile_diagnostic.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8');print(json.dumps(out,indent=2))
