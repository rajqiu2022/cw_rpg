from pathlib import Path
import runpy,json,hashlib
import numpy as np
P=Path(__file__).resolve().parent
try:
 runpy.run_path(str(P/'model_pixel_prior_NOTENGINE.py'),run_name='__source_diagnostic__')
 raise RuntimeError('Expected retained source-model outside-domain failure')
except AssertionError as error:
 tb=error.__traceback__
 while tb.tb_next:tb=tb.tb_next
 env=tb.tb_frame.f_locals
 yy,xx=np.where(env['different']&~env['union'])
 assert len(xx)<=256
 rows=[{'xy':[int(x),int(y)],'parent':env['parent'][y,x].tolist(),'model':env['rgba'][y,x].tolist()}for x,y in zip(xx,yy)]
 value={'status':'SOURCE_MODEL_FIRST_FAILURE_PRESERVED_DIAGNOSTIC_NOT_ADMISSION','error':str(error),'outside_pixels':rows,'rectangles':env['rectangles'],'engine':0,'canonical_writes':0}
 blob=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
 dest=P/'source_model_first_failure_DIAGNOSTIC.json';assert not dest.exists()
 with dest.open('xb')as out:out.write(blob)
 print(json.dumps({'path':'res://build/luoyang_garden_river_20261025h_source01/'+dest.name,'sha256':hashlib.sha256(blob).hexdigest(),'outside_pixels':rows}))
