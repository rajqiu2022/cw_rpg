"""Author a measured district drawing, not runtime art or a modular screenshot."""
from __future__ import annotations
import argparse,hashlib,json,math
from pathlib import Path
from xml.sax.saxutils import escape
import numpy as np
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/staging/bianzhou_southgate_20261022c'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,value):p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n','utf-8')

def main(refined=False):
    if (BASE/'district-plan.json').exists():raise RuntimeError('Plan already exists; publish explicit successor rather than overwrite')
    BASE.mkdir(parents=True,exist_ok=True)
    solids=[
        ('主城墙西',[0,850,1040,160]),('主城墙东',[2032,850,1040,160]),
        ('主门西翼',[1040,850,356,260]),('主门东翼',[1676,850,356,260]),
        ('瓮城西侧墙',[1000,1110,140,360]),('瓮城东侧墙',[1932,1110,140,360]),
        ('前闸西墙',[1000,1470,396,140]),('前闸东墙',[1676,1470,396,140]),
        ('西岗棚',[700,300,280,180]),('东岗棚',[2092,300,280,180])]
    roof=[('主门楼檐口',[960,520,1152,590]),('西岗棚檐口',[660,260,360,260]),('东岗棚檐口',[2052,260,360,260])]
    mainline=[[1536,1860],[1536,1540],[1536,980],[1536,620],[1536,120]]
    paths=[('入城主线',mainline,320),('西环连接',[[1536,620],[280,620]],192),('东环连接',[[1536,620],[2792,620]],192),('候车支线',[[2770,620],[2770,500],[2700,500]],160)]
    people=[('西守卒',[1310,1190]),('东守卒',[1762,1190]),('候检旅人甲',[500,370]),('候检旅人乙',[600,450])]
    service=[('排队带',[450,300,220,200]),('候车位',[2390,270,420,230])]
    vehicle=('停放车脚位',[2510,295,140,190])
    if refined:
        solids=[(n,([600,560,280,180] if n=='西岗棚' else [2192,560,280,180] if n=='东岗棚' else r)) for n,r in solids]
        roof=[(n,([560,520,360,260] if n=='西岗棚檐口' else [2152,520,360,260] if n=='东岗棚檐口' else r)) for n,r in roof]
        mainline=[[1536,1860],[1536,1540],[1536,980],[1536,360],[1536,120]]
        paths=[('入城主线',mainline,320),('西环连接',[[1536,360],[280,360]],192),('东环连接',[[1536,360],[2792,360]],192),('候车支线',[[2792,360],[2890,360],[2890,650],[2860,650]],160)]
        people=[('西守卒',[1310,1190]),('东守卒',[1762,1190]),('候检旅人甲',[350,620]),('候检旅人乙',[450,700])]
        service=[('排队带',[300,560,220,200]),('候车位',[2550,530,420,230])]
        vehicle=('停放车脚位',[2620,545,140,190])
    mask=Image.new('L',(3072,2048),255);md=ImageDraw.Draw(mask)
    for _,(x,y,w,h) in solids+[vehicle]:md.rectangle((x,y,x+w-1,y+h-1),fill=0)
    md.rectangle((0,0,3071,2047),outline=0,width=20)
    blocked=(np.array(mask)==0).astype(np.uint32)
    integral=np.pad(blocked,((1,0),(1,0))).cumsum(0,dtype=np.uint32).cumsum(1,dtype=np.uint32)
    sums=integral[25:,35:]-integral[:-25,35:]-integral[25:,:-35]+integral[:-25,:-35]
    safe=np.zeros((2048,3072),dtype=bool);safe[12:2036,17:3055]=(sums==0)
    report_routes=[]
    for name,points,width in paths:
        count=0
        for a,b in zip(points,points[1:]):
            n=max(1,math.ceil(math.dist(a,b)/4))
            for k in range(n+1):
                x=round(a[0]+(b[0]-a[0])*k/n);y=round(a[1]+(b[1]-a[1])*k/n)
                assert safe[y,x],(name,x,y);count+=1
        report_routes.append({'id':name,'samples':count,'status':'PLANNED_BODY_FOOTPRINT_CLEAR_NOT_RUNTIME'})
    assert all(safe[y,x] for _,(x,y) in people)
    # Check the complete nominal 280-pixel corridor at both gates, not just its centre.
    assert np.array(mask)[850:1111,1396:1676].min()==255
    assert np.array(mask)[1470:1611,1396:1676].min()==255
    if refined:
        for _,points,width in paths[1:3]:
            xs=[p[0] for p in points];ys=[p[1] for p in points]
            road=[min(xs),min(ys)-width/2,max(xs),max(ys)+width/2]
            for _,(x,y,w,h) in roof:
                assert min(road[2],x+w)<=max(road[0],x) or min(road[3],y+h)<=max(road[1],y),('Road under roof',road,x,y)
        for i,(_,a) in enumerate(roof):
            for _,b in roof[i+1:]:assert min(a[0]+a[2],b[0]+b[2])<=max(a[0],b[0]) or min(a[1]+a[3],b[1]+b[3])<=max(a[1],b[1]),'Roof envelopes overlap'
    gate='game/art/maps/luoyang_modular_v3/source/south_gate_v1.png'
    front='game/art/modules/luoyang_gate_fortification_v3_a_refined/luoyang_gate_wall_refined_ashlar_v3_a.png'
    tower='game/art/modules/luoyang_gate_fortification_v3_b_refined/luoyang_gate_corner_tower_refined_v3_b.png'
    ground='game/art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png'
    image=Image.open(ROOT/gate).convert('RGBA');alpha=image.getchannel('A');apertures=[]
    for y in [720,760,800,840,860]:
        assert alpha.getpixel((768,y))==0
        l=r=768
        while l>0 and alpha.getpixel((l-1,y))==0:l-=1
        while r<image.width-1 and alpha.getpixel((r+1,y))==0:r+=1
        apertures.append({'source_row':y,'x_range':[l,r],'source_width':r-l+1,'at_nominal_render_width_1152':(r-l+1)*1152/image.width})
    sources=[gate,front,tower,ground,'assets/raw/bianzhou_city_masterplan_20261022b/bianzhou_city_masterplan_overview_v1.png','assets/raw/bianzhou_city_masterplan_20261022b/user-approval.json']
    modules=[
        {'id':'main_gatehouse','role':'嵌入城墙的主门楼','render_envelope':[960,520,1152,590],'net_passage_width':280,'net_height_min':160,'source_candidate':gate,'status':'NEW_COMPONENT_REQUIRED','reason':'旧图在1152全画布宽下的5截面净透明宽142.5–156.75，未达280；这5行也不是完整门洞认证'},
        {'id':'front_city_wall','role':'左右连续正面墙','source_candidate':front,'status':'CONDITIONAL_REUSE_MATERIAL_AND_FRONT_FACE','reason':'需测新门楼接口和相机，不能把旧洛阳捕获准入直接迁到汴州'},
        {'id':'west_barbican_sidewall','role':'西侧有纵深的瓮城墙','status':'NEW_COMPONENT_REQUIRED','footprint':[1000,1110,140,360]},
        {'id':'east_barbican_sidewall','role':'东侧有纵深的瓮城墙','status':'NEW_COMPONENT_REQUIRED','footprint':[1932,1110,140,360]},
        {'id':'front_barbican_gate','role':'前闸低墙和中央净口','status':'NEW_COMPONENT_REQUIRED','net_passage_width':280,'net_height_min':160},
        {'id':'checkpoint_shelter','role':'两侧岗棚同一职能，可复用同一合格组件','status':'NEW_COMPONENT_REQUIRED','body_size':[280,180],'roof_size':[360,260]},
        {'id':'stone_ground','role':'门槛/院铺/主街的同材质不同磨损','source_candidate':ground,'status':'CONDITIONAL_REUSE_TILING_AND_EDGE_TEST_PENDING'},
        {'id':'corner_pier','role':'墙体接头材质参考','source_candidate':tower,'status':'REFERENCE_ONLY_NOT_AUTO_ADMITTED'}]
    data={'status':'DISTRICT_SPATIAL_CONTRACT_NOT_RUNTIME','approved_masterplan':'assets/raw/bianzhou_city_masterplan_20261022b/bianzhou_city_masterplan_overview_v1.png','size':[3072,2048],'adult_visible_height_target':112,'body_size':[34,24],'body_pixel_test':[35,25],'solids':[{'id':n,'rect':r} for n,r in solids],'roof_envelopes':[{'id':n,'rect':r} for n,r in roof],'routes':[{'id':n,'points':p,'nominal_width':w} for n,p,w in paths],'people':[{'role':n,'foot':p} for n,p in people],'service_areas':[{'id':n,'rect':r} for n,r in service],'parked_vehicle':{'rect':vehicle[1]},'modules':modules,'source_sha256':{p:sha(ROOT/p) for p in sources},'existing_gate_aperture_samples':apertures,'route_check':report_routes,'formal_enabled':False,'engine_runs':0,'game_writes':0,'new_imagegen_calls':0}
    dump(BASE/'district-plan.json',data)
    # Technical drawing only. Shapes are planned footprints, not substitute game art.
    W,H=1600,1330;paper='#f8f6ef';canvas=Image.new('RGB',(W,H),paper);draw=ImageDraw.Draw(canvas)
    svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',f'<rect width="100%" height="100%" fill="{paper}"/>']
    scale=.46875;origin=(80,170)
    def point(p):return(origin[0]+p[0]*scale,origin[1]+p[1]*scale)
    def font(size):return ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',size)
    def text(p,t,size=18,color='#263a43'):
        draw.text(p,t,font=font(size),fill=color);svg.append(f'<text x="{p[0]}" y="{p[1]+size}" font-family="Microsoft YaHei,sans-serif" font-size="{size}" fill="{color}">{escape(t)}</text>')
    def rect(r,fill,stroke=None,width=1):
        x,y=point(r[:2]);w,h=r[2]*scale,r[3]*scale
        draw.rectangle((x,y,x+w,y+h),fill=fill,outline=stroke,width=width)
        svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{width}"/>')
    def line(points,color,width=3):
        pp=[point(p) for p in points];draw.line(pp,fill=color,width=width,joint='curve');svg.append(f'<polyline points="'+ ' '.join(f'{x},{y}' for x,y in pp)+f'" fill="none" stroke="{color}" stroke-width="{width}"/>')
    text((80,35),'汴州 01 南门候检区 · 尺寸平面',33)
    text((80,88),'整城设计已确认 → 分区工程示意；非正式美术、非实机、未从概念像素直接裁尺寸',19)
    text((80,122),'北 ↑  接02中轴坊市；西/东支路接环街。尺寸单位：拟定世界像素。',18)
    rect([0,0,3072,2048],'#eeece3','#c9ccbd',2)
    for _,p,w in paths:line(p,'#c7dce1',max(2,round(w*scale)))
    for n,r in service:
        rect(r,'#dce6ce','#92a181',2);text(point([r[0]+6,r[1]+12]),n,17)
    rect(vehicle[1],'#b99b73','#8b6b45',2);text(point([2550,470]) if refined else point([2420,210]),'车位在横街侧方' if refined else '车位在横街北侧',17)
    for n,r in roof:
        x,y=point(r[:2]);w,h=r[2]*scale,r[3]*scale
        # Dashed perimeter is a roof envelope, never collision.
        for a,b in [((x,y),(x+w,y)),((x+w,y),(x+w,y+h)),((x+w,y+h),(x,y+h)),((x,y+h),(x,y))]:
            length=math.dist(a,b)
            for d in range(0,int(length),14):
                t=d/length;u=min(d+7,length)/length;draw.line([(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t),(a[0]+(b[0]-a[0])*u,a[1]+(b[1]-a[1])*u)],fill='#b48b43',width=2)
        svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none" stroke="#b48b43" stroke-width="2" stroke-dasharray="7 7"/>')
    for n,r in solids:
        rect(r,'#536a75','#344b57',2)
        if '岗棚' in n:text(point([r[0]+20,r[1]+60]),n,19,'#ffffff')
    text(point([210,890]),'连续城墙（西）',21,'#ffffff');text(point([2270,890]),'连续城墙（东）',21,'#ffffff')
    text(point([1100,910]),'门楼西翼',20,'#ffffff');text(point([1730,910]),'门楼东翼',20,'#ffffff')
    for name,position in people:
        x,y=point(position);radius=7;draw.ellipse((x-radius,y-radius,x+radius,y+radius),fill='#b85a42')
        svg.append(f'<circle cx="{x}" cy="{y}" r="{radius}" fill="#b85a42"/>')
        if '守卒' in name:text((x-30,y+12),name,16)
    for n,p,_ in paths[:3]:line(p,'#397a89',3)
    text(point([1400,1800]),'南出大地图',21)
    text(point([1400,42]),'接02主街',21)
    text(point([45,290]) if refined else point([45,570]),'西环支路 192',18);text(point([2670,420]) if refined else point([2670,750]),'东环 192',18)
    text(point([1410,1180]),'瓮城净道',18)
    text(point([1405,1290]),'280px',19)
    text(point([1100,1650]),'前闸净口280；非孤立木坊门',18)
    text(point([1475,195]) if refined else point([1475,315]),'主街',18);text(point([1450,270]) if refined else point([1450,390]),'320px',20)
    text((80,1160),'实心蓝灰＝墙脚/建筑实体   金色虚线＝檐口预留   浅蓝＝道路净空   绿色＝排队/候车带',20)
    text((80,1200),'所有守卒、旅人和停放车辆均离开通行中线；门洞目标净高≥160px，成人可视约112px。',19)
    text((80,1235),'平面完整身体净空检查仅针对拟定几何；尚无图片门洞、遮挡、Physics或正式Field验收。',18)
    canvas.save(BASE/'southgate-footprint-plan.png');svg.append('</svg>');(BASE/'southgate-footprint-plan.svg').write_text('\n'.join(svg),'utf-8')
    report={'status':'PROPOSED_PLAN_CLEARANCE_PASS_NOT_RUNTIME','revision':2 if refined else 1,'routes':len(report_routes),'samples':sum(r['samples'] for r in report_routes),'people_clear':len(people),'gate_corridors_full_280_clear':2,'cross_streets_clear_of_roof_envelopes':refined,'roof_envelopes_disjoint':refined,'new_component_classes':sum(m['status']=='NEW_COMPONENT_REQUIRED' for m in modules),'source_sha_unchanged':all(sha(ROOT/p)==h for p,h in data['source_sha256'].items()),'engine_runs':0,'game_writes':0,'shared_tasks_writes':0}
    dump(BASE/'verification.json',report);print(json.dumps(report))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--revision2',action='store_true');args=parser.parse_args()
    if args.revision2:BASE=BASE/'revision2'
    main(args.revision2)
