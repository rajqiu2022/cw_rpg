"""World-space placeables and identity-referenced map walk sheets; no game deployment."""
import argparse,hashlib,json,shutil,msvcrt,yaml
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/raw/world_placeables_walk_20261022'
LEDGER=BASE/'manifest.json'
PROMPTS=ROOT/'prompts/world_placeables_walk_20261022'
PREFIX='placewalk_20261022_'
STYLE='''Chinese wuxia 2.5D RPG WORLD-SPACE map asset, clear bright natural hand-painted realism, consistent detailed wood, cloth, stone and foliage. Parallel orthographic camera looking down 30 degrees, straight verticals, front faces screen-bottom. Genuinely transparent RGBA. Visible complete subject and contact base, SMALL within the central 55 percent of the canvas, generous empty transparent margins on every side INCLUDING faint shadows. No scenic background, terrain rectangle, landscape, inventory icon tile, frame, label, UI, lettering, magic, glow, haze, spiders or webs. No ground shadow disk. Soft upper-left daylight. This is a physical object to PLACE ON THE EXPLORATION MAP, not a floating inventory item.'''
WALK='''Use the supplied full-body NPC as an EXACT CHARACTER IDENTITY reference. Create a MAP WALK ANIMATION SPRITE SHEET, NOT a portrait and NOT four different people. Same face, age, hair, clothing colours, equipment and art style. Orthographic camera looking down 30 degrees. Full adult body with both feet visible, walking TOWARD SCREEN-BOTTOM, fixed camera, torso centre and scale. Entire canvas a single horizontal row of EXACTLY FOUR EQUAL-WIDTH cells, ideally a 4:1 sheet, no drawn grid. Each character precisely centred in its own cell with identical foot-ground baseline and transparent padding. Genuine RGBA transparent background. Four DISTINCT anatomical gait phases in left-to-right playback order: 1 left foot far forward/right foot behind with right arm forward; 2 left planted while right knee passes under torso, close feet; 3 right foot far forward/left foot behind with left arm forward; 4 right planted while left knee passes under torso, close feet. Walk in place: no horizontal travel between phases. Clear alternating foot and knee positions, natural opposing arms. Clothing and carried goods remain identical; no stretch, age or body size changes. No repeated idle poses, not four same static characters. No extra figures, labels, text, background, shadow disk, floor or effects. Complete heads, hands and feet inside each cell. Only four authentic sequential motion frames.'''

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def definitions():
    rows=[]
    specs={
      'scene_props':[
       ('grain_pallet','粮袋木托盘','Three heavy tied grain sacks resting on one low worn timber pallet; tied necks, grounded load, no writing.'),
       ('clay_jars','陶缸组合','Three squat brown earthenware storage jars of different heights standing together, one tied cloth lid; complete flat contact bases.'),
       ('wood_bench','街巷长凳','One low long narrow backless dark wooden bench, sturdy four short legs, complete feet, no table or person.'),
       ('firewood_rack','柴薪木架','One modest timber firewood rack holding a neat horizontal stack of split logs; practical rural proportions, grounded posts.'),
       ('craft_bench','木作工作台','One Chinese carpenter workbench with a wooden hand plane and a few timber pieces resting on top; no machine or forge.'),
       ('dying_rack','晾布木架','One low freestanding wooden drying rack carrying two short plain blue-grey cloth lengths; cloth ends clear of ground, no banner.'),
       ('fish_baskets','鱼篓与竹筐','One compact dockside grouping of a closed woven fishing creel and two empty shallow bamboo baskets, natural contact bases; no fish or person.'),
       ('broken_handcart','旧手车物件','One small worn two-wheeled wooden handcart with an empty tray, one cracked sideboard and a loose handle still attached; complete wheels and shafts, no dramatic destruction.')],
      'field_objects':[
       ('herb_patch','阔叶草药采集簇','One small rooted cluster of three broad-leaf medicinal plants with tiny pale flowers; distinct leaves and short stems at ground level, no pot, no soil tile.'),
       ('ginseng_patch','参草采集簇','One small rooted ginseng-like woodland plant cluster, palmate green leaves and subtle red berries; roots remain mostly underground, no floating picked root or soil rectangle.'),
       ('ore_outcrop','山岩矿石露头','One squat natural grey rock outcrop with restrained pale quartz seams embedded in it, rough grounded base; no crystals floating or sparkling.'),
       ('stepping_stones','浅滩踏脚石组','One short gently curved chain of five low flat weathered stepping stones with varying shapes, mutually separated by transparent gaps, no water or terrain base.'),
       ('fallen_log','倒木路障','One fallen weathered tree trunk with a short broken branch stub, rough bark, complete ends and grounded underside, no leafy forest or surrounding ground.'),
       ('trail_signpost','山道指路木桩','One short weathered wooden trail signpost, three blank simple directional boards, planted pointed lower post, no readable text or symbol.'),
       ('stone_cairn','山路石堆标记','One modest balanced cairn of six irregular local grey stones stacked low, complete grounded bottom stone, no sacred glow or writing.'),
       ('berry_bush','野果灌木簇','One low compact leafy berry bush with restrained small muted red fruit, visible short woody stems touching ground, no pot or terrain patch.')],
      'small_buildings':[
       ('tea_shed','路边茶棚','One small open-front Chinese roadside tea shelter: four timber posts, shallow grey tiled roof, narrow fixed counter along the REAR only, clear standing space, no sign or occupants.'),
       ('thatch_storehouse','乡野草顶储物屋','One compact single-room mud-and-timber storehouse with a low straw roof, one tall adult-sized empty front doorway and dark opaque interior depth, modest narrow footprint.'),
       ('watch_pavilion','山道值守小亭','One simple modest open timber watch shelter on four stone feet with shallow grey tiled roof, no tower, clear adult standing space, no wall or scene.'),
       ('pottery_kiln','陶坊小窑','One small traditional Chinese rounded clay pottery kiln with soot-darkened low firing mouth, earthen dome and short modest vent, no industrial chimney, no flames or other buildings.'),
       ('ferry_shelter','渡口候船小棚','One narrow Chinese ferry waiting shelter with timber posts, shallow grey tile roof and one low back bench inside, open front, no water, boat, stairs or surrounding dock.'),
       ('stable_shelter','驿路马棚','One small two-bay rustic timber stable canopy with shallow weathered roof, short rear partition and one fixed low feeding trough at back, empty bays, no horses or hay rectangle.'),
       ('raised_granary','乡村架高小粮仓','One compact timber granary on four short stone staddle supports, modest sloping grey tile roof, one tall front door, three attached wooden access steps, complete base; no sacks blocking entry.'),
       ('herb_garden_shed','药圃工具小棚','One modest open-front timber garden tools shed with weathered shingle roof, a short side rack holding two bamboo poles, clear adult-height opening and opaque dark rear planks; no garden ground or surrounding plants.')]
    }
    source='docs/luoyang-city-masterplan-20261019z.md'
    for kind,items in specs.items():
        for key,label,detail in items:
            rows.append(dict(id=PREFIX+key+'_v1',label=label,kind=kind,detail=detail,prompt=STYLE+'\n\n'+detail,reference=None,sources=[source],intended_use={'scene_props':'场景生活陈设','field_objects':'野外可放置/互动外观候选，不绑定采集奖励','small_buildings':'场景与大世界的小型建筑组件'}[kind]))
    old=json.loads((ROOT/'assets/raw/world_expansion_100_20261022/current-candidates.json').read_text('utf-8'))
    for r in old['assets']:
        if r['kind']!='npc_sprites':continue
        key=r['id'].replace('world100_20261022_npc_','').replace('_idle_1f_v1','')
        rows.append(dict(id=PREFIX+key+'_walk_down_4f_v1',label=r['label'].replace('静态精灵','地图下行4帧'),kind='npc_walk',detail=WALK,prompt=WALK,reference=r['output'],sources=r['sources'],idle_id=r['id'],intended_use='配套地图下行4帧行走；其他朝向与运行绑定待验'))
    for r in rows:
        r.update(output=f"assets/raw/world_placeables_walk_20261022/{r['kind']}/{r['id']}.png",prompt_path=f"prompts/world_placeables_walk_20261022/{r['id']}.txt",status='PLANNED',attempts=0)
    return rows

def prepare():
    assert not LEDGER.exists()
    BASE.mkdir(parents=True);PROMPTS.mkdir(parents=True)
    rows=definitions();assert len(rows)==34 and len({r['id'] for r in rows})==34
    sources={}
    for r in rows:
        for p in r['sources']+([r['reference']] if r['reference'] else []):sources[p]=sha(ROOT/p)
        (ROOT/r['prompt_path']).write_text(r['prompt']+'\n','utf-8')
    temp=ROOT/'tmp/world_placeables_walk_20261022';temp.mkdir(parents=True)
    tasks=ROOT/'prompts/tasks.yaml';prior=tasks.read_bytes();shutil.copyfile(tasks,temp/'before-tasks.yaml')
    own=[dict(id=r['id'],template='world_placeables_walk_20261022',category='world_placeables_walk_20261022/'+r['kind'],execution_backend='builtin_image_gen',skip=True,attempt_budget=1,retries_allowed=False,cli_fallback_allowed=False,transparent_background=True,model=None,provider=None,cost=None,prompt_path=r['prompt_path'],vars={'asset_prompt':r['prompt']}) for r in rows]
    template=ROOT/'prompts/templates/world_placeables_walk_20261022.yaml';assert not template.exists()
    template.write_text(yaml.safe_dump({'size':'1024x1024','background':'transparent','quality':'medium','prompt_template':'{asset_prompt}'},allow_unicode=True,sort_keys=False),'utf-8')
    body=yaml.safe_dump({'tasks':own},allow_unicode=True,sort_keys=False,width=140).split('tasks:\n',1)[1]
    tasks.write_bytes(prior+('\n  # World-space objects and referenced map-walk supplement, builtin only.\n'+'\n'.join('  '+x if x else '' for x in body.splitlines())+'\n').encode())
    parsed=yaml.safe_load(tasks.read_text('utf-8'))['tasks'];new=[r for r in parsed if r.get('id','').startswith(PREFIX)]
    assert len(new)==34 and tasks.read_bytes()[:len(prior)]==prior
    assert all((ROOT/r['prompt_path']).read_text('utf-8').strip()==r['vars']['asset_prompt'] for r in new)
    LEDGER.write_text(json.dumps({'status':'REGISTERED_34_NOT_GENERATED','assets':rows,'source_sha256':sources},ensure_ascii=False,indent=2)+'\n','utf-8')
    (BASE/'preflight.json').write_text(json.dumps({'status':'OFFLINE_34_TASK_PASS','tasks':34,'sources':len(sources),'old_tasks_prefix_exact':True,'new_task_unique':True,'prompt_exact':True,'cli_calls':0},indent=2)+'\n','utf-8')
    print(json.dumps({'assets':34,'sources':len(sources)}))

def record(asset_id,source):
    with (BASE/'record.lock').open('a+b') as lock:
        lock.seek(0,2)
        if not lock.tell():lock.write(b'0');lock.flush()
        lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_LOCK,1)
        try:
            m=json.loads(LEDGER.read_text('utf-8'));r=next(r for r in m['assets'] if r['id']==asset_id);p=ROOT/r['output'];assert not p.exists()
            if r['reference']:
                assert sha(ROOT/r['reference'])==m['source_sha256'][r['reference']]
                r['reference_input']={'path':r['reference'],'sha256':sha(ROOT/r['reference']),'role':'identity_reference'}
            p.parent.mkdir(exist_ok=True);shutil.copyfile(source,p)
            with Image.open(p) as im:
                a=im.getchannel('A');box=a.getbbox();w,h=im.size;margins=[box[0]/w,box[1]/h,(w-box[2])/w,(h-box[3])/h]
                metrics=dict(size=[w,h],source_mode=im.mode,has_real_alpha=im.mode=='RGBA' and a.getextrema()[0]==0,full_alpha_bbox=list(box),margin_fractions=margins,margin_10_percent_pass=min(margins)>=.1)
            r.update(status='RAW_CANDIDATE_NOT_RUNTIME',attempts=1,sha256=sha(p),source_path=str(source),bytes=p.stat().st_size,prompt_sha256=sha(ROOT/r['prompt_path']),metrics=metrics,model=None,provider=None,cost=None)
            p.with_suffix('.meta.json').write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n','utf-8')
            LEDGER.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n','utf-8')
            print(json.dumps({'id':asset_id,'size':metrics['size'],'margin_pass':metrics['margin_10_percent_pass']}))
        finally:lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_UNLCK,1)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['prepare','record']);p.add_argument('--id');p.add_argument('--source');p.add_argument('--ledger-name');a=p.parse_args()
    if a.ledger_name:
        assert a.ledger_name in ('walk-successors.json','walk-frames.json','walk-guided-frames.json')
        LEDGER=BASE/a.ledger_name
    prepare() if a.action=='prepare' else record(a.id,Path(a.source))
