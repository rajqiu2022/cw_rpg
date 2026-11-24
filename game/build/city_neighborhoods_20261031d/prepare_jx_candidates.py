"""Emit apply_patch candidates. Reads canonical sources; never writes them."""
from pathlib import Path
import hashlib,json,sys,difflib
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'game/build/city_neighborhoods_20261031d'
COMMON=(ROOT/'game/build/three_settlements_20261030e_system01/common_author.gd').read_bytes().decode()
HELPER='res://build/city_neighborhoods_20261031d/neighborhoods.gd'
TARGETS={'jinling':'game/build/jinling_city_20261029_system01/city_author.gd','xiangzhou':'game/build/three_settlements_20261030e_system01/xiangzhou_author.gd'}
def function(text,name):
 start=text.index('static func '+name+'(')
 end=text.find('\nstatic func ',start+1)
 return text[start:] if end<0 else text[start:end]
def exact(text,a,b):
 assert text.count(a)==1,(a,text.count(a))
 return text.replace(a,b)
def make(city,path):
 before=(ROOT/path).read_bytes();text=before.decode();oldversion=31 if city=='jinling' else 30
 text=exact(text,'const VERSION:='+str(oldversion),'const VERSION:='+str(oldversion+1))
 # Preserve every historical building descriptor and all unchanged props/NPCs.
 text=exact(text,'static func building_specs()','static func building_specs_before31d()')
 text=exact(text,'static func roads()','static func roads_before31d()')
 if city=='jinling':
  old_safe=function(before.decode(),'safe_foot')
  old_safe=old_safe.replace('static func safe_foot(','static func safe_foot_before31d(').replace('building_specs()','building_specs_before31d()')
 else:
  old_safe=function(COMMON,'safe_foot')
  old_safe=old_safe.replace('static func safe_foot(author: Variant, uv:','static func safe_foot_before31d(uv:').replace('author.SIZE','SIZE').replace('author.building_specs()','building_specs_before31d()').replace('author.','')
 text=text.rstrip()+'''\n\nstatic func building_specs() -> Array[Dictionary]:
\treturn preload("'''+HELPER+'''").buildings("'''+city+'''",building_specs_before31d())

static func roads() -> Array[Dictionary]:
\treturn preload("'''+HELPER+'''").roads("'''+city+'''",roads_before31d())

'''+old_safe.strip()+'\n'
 old='\tif version==VERSION:return uv if safe_foot(uv) else null\n'
 new=old+'\tif version=='+str(oldversion)+':return preload("'+HELPER+'").restore("'+city+'",uv,safe_foot_before31d,safe_foot)\n'
 text=exact(text,old,new)
 old='\treturn p/SIZE if safe_foot(p/SIZE) else null'
 text=exact(text,old,'\treturn preload("'+HELPER+'").restore("'+city+'",p/SIZE,safe_foot_before31d,safe_foot)')
 # Strict-source new candidates use exactly one EOF LF, no whole-file EOL conversion.
 return before,text.encode()
if __name__=='__main__' and sys.argv[-1]=='--seal':
 rows=[]
 for city,path in TARGETS.items():
  before,after=make(city,path)
  ready=OUT/(city+'_author_READY.gd');saved=OUT/(city+'_author_BEFORE.gd')
  assert ready.read_bytes()==after and saved.read_bytes()==before
  sha=lambda b:hashlib.sha256(b).hexdigest()
  rows.append(dict(target=path,before=saved.relative_to(ROOT).as_posix(),candidate=ready.relative_to(ROOT).as_posix(),old_sha256=sha(before),new_sha256=sha(after),before_bytes=len(before),bytes=len(after)))
  diff=''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile='a/'+path,tofile='b/'+path))
  (OUT/(city+'_FORWARD.diff')).write_text(diff,encoding='utf-8',newline='')
 modules={p.relative_to(ROOT).as_posix():dict(sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size)for p in [OUT/'neighborhoods.gd',OUT/'neighborhoods.json']}
 receipt=dict(status='FROZEN_JX_CANDIDATES_NOT_ENGINE_OR_ART_ACCEPTED',targets=rows,new_modules=modules,version_jinling=[31,32],version_xiangzhou=[30,31],business_portals_npc_water_bridge_unchanged=True,migration='Only original-safe foot intersecting new authored building body; declared single target and final-safe check; no nearest',engine_runs=0,canonical_writes=0,history='Initial emitted candidate console GBK corruption and failed EOL assertion retained in tool history; UTF8 whole candidate apply_patch repaired, then exact mixed EOL restoration. No formal source was written.')
 (OUT/'jx_manifest_READY.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='')
 print(json.dumps(receipt,ensure_ascii=False,indent=2));sys.exit()
if __name__=='__main__' and sys.argv[-1]=='--restore-eol-only':
 for city,path in TARGETS.items():
  before,after=make(city,path)
  for name,data in [(city+'_author_READY.gd',after),(city+'_author_BEFORE.gd',before)]:
   target=OUT/name
   actual=target.read_bytes()
   assert actual.replace(b'\r\n',b'\n')==data.replace(b'\r\n',b'\n')
   if actual!=data:target.write_bytes(data)
 print('Only exact source-template EOLs restored; no semantic rewrite or canonical write.')
 sys.exit()
if __name__=='__main__':
 assert sys.argv[-1] in ['--emit-patch','--emit-repair']
 print('*** Begin Patch')
 for city,path in TARGETS.items():
  before,after=make(city,path)
  for name,data in [(city+'_author_READY.gd',after),(city+'_author_BEFORE.gd',before)]:
   target=OUT/name
   if sys.argv[-1]=='--emit-repair':
    print('*** Update File: '+target.as_posix());print('@@')
    for line in target.read_text(encoding='utf-8').splitlines():print('-'+line)
   else:print('*** Add File: '+target.as_posix())
   for line in data.decode().splitlines():print('+'+line)
 print('*** End Patch')
