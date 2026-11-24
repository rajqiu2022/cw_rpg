"""Local, bounded Lanxi scene revision. Preserve original source and current bindings."""
import json,re,hashlib,shutil,sys,subprocess,time,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];GAME=ROOT/'game';NAME='lanxi_revision_20261030l';STAGE=ROOT/'assets/staging'/NAME
QA=GAME/'build'/NAME;OLD='scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,j):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n','utf-8')
def snapshot(p):return {'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns}
def prepare():
 assert not STAGE.exists();STAGE.mkdir();QA.mkdir()
 paths={GAME/OLD,GAME/'project.godot',GAME/'scripts/autoload/scene_router.gd',GAME/'scripts/field/field_walkable_controller.gd'}
 native=GAME/'build/three_towns_world_20261029j_system01/native_sources.json';reg=native.with_name('town_registry.gd')
 j=json.loads(native.read_text('utf-8'));assert sha(native) in reg.read_text('utf-8');paths.update([native,reg])
 for path,digest in j['sources'].items():
  p=GAME/path[6:];assert sha(p)==digest,path;paths.add(p)
 user=Path.home()/'AppData/Roaming/Godot/app_userdata/云影侠传'
 paths.update(p for p in user.rglob('*') if p.is_file() and ('save' in p.name.lower() or p.suffix=='.bak'))
 for path in re.findall(r'path="res://([^"\n]+\.png)"',(GAME/OLD).read_text('utf-8')):paths.add(GAME/path)
 save(STAGE/'protected-before.json',[snapshot(p) for p in sorted(paths)])
 for rel in [OLD,'scripts/drafts/miao_terrain_20261029i/town_controller.gd','scripts/drafts/miao_terrain_20261029i/terrain.gd','art/modules/miao_terrain_20261029i/terrain.json','build/three_towns_world_20261029j_system01/native_sources.json','build/three_towns_world_20261029j_system01/town_registry.gd']:
  dst=STAGE/'backup'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(GAME/rel,dst)
 # Static node list for planning the bank around real building feet.
 s=(GAME/OLD).read_text('utf-8');rows=[]
 for block in re.split(r'(?=\[node )',s)[1:]:
  head=block.splitlines()[0]
  if 'parent="Town"' not in head:continue
  name=re.search('name="([^"]+)"',head).group(1);pos=re.search(r'position = Vector2\(([^)]+)\)',block);rect=re.search(r'metadata/visual_rect = Rect2\(([^)]+)\)',block)
  if pos:rows.append({'name':name,'position':[float(x) for x in pos[1].split(',')],'rect':[float(x) for x in rect[1].split(',')] if rect else None})
 save(STAGE/'objects-before.json',rows)
 print([(r['name'],r['position'],r['rect']) for r in rows if any(k in r['name'] for k in ['Granary','Pocket','RaisedMarket','DyeWorkshop','Cloth'])])
def run(label):
 exe='F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe';assert not (STAGE/(label+'.run.json')).exists()
 with (STAGE/(label+'.stdout.txt')).open('wb') as out,(STAGE/(label+'.stderr.txt')).open('wb') as err:
  start=time.time();p=subprocess.Popen([exe,'--path',str(GAME),'--resolution','1600x1000','--script','res://build/'+NAME+'/'+label+'.gd'],stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW);print(p.pid,flush=True);save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'RUNNING'})
  try:code=p.wait(timeout=150)
  except subprocess.TimeoutExpired:p.terminate();p.wait();save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'TIMEOUT'});raise
  save(STAGE/(label+'.run.json'),{'pid':p.pid,'state':'NATURAL_EXIT','exit':code,'seconds':time.time()-start});print(code);sys.exit(code)
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='run':run(sys.argv[2])
