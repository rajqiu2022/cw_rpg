"""Record the completed new-city milestone and preserve previous dated history."""
import json
import shutil
from desert_town_20261029d import ROOT, STAGE, PROJECT
from build_redrock_town_20261028a import save, sha

def prepend_after(path,marker,text):
    p=ROOT/path;old=p.read_text('utf-8');assert old.count(marker)==1
    p.write_text(old.replace(marker,marker+'\n\n'+text,1),'utf-8')

common='2026-10-29d独立沙漠城首版已创建：用户确认29c总规，`game/scenes/drafts/desert_town_20261029d/desert_town.tscn` C37F2B1C可F6；黄沙/浅土坯六区、15民居/双铺/客栈驼棚工坊井台、3民院+驼院井院/2枣椰，63对象87blocker。正式Player跟随/四向walk、6复用居民巡行和一缓存前厅同人原脚进返。14内置原图含1城廓首稿弃用，12透明当前图只增RGBA0留白/原RGBA精同，13工程图RGBA精确；原A1 FAIL保。49/2首FAIL、13/0后继、222/5院轴FAIL和8/0残余保，原图已看，仅首版结构、不授参考密度/全ART；前墙局部人物窗口/全景不透明。59全新工程文件/26新import叶，0旧game写，168保护含162save精ticks同/editor51856保。图库4980/2673图2307音/40新路径缩略核/非resources同，正式世界/剧情经济战斗未接。详docs/changes/desert-town-20261029d.md。'
prepend_after('AGENTS.md','## 📍 一句话现状',common)
prepend_after('docs/current-progress.md','# 当前工作进展（快照）','## 2026-10-29d 独立黄沙土坯城首版可编辑地图\n\n'+common)
for file,title in [('producer','# Producer Memory'),('system','# System Memory'),('art','# Art Memory'),('qa','# QA Memory')]:
    prepend_after('docs/agents/'+file+'-memory.md',title,common)
prepend_after('docs/experience-log.md','# 经验记录 / Lessons Learned',
    '2026-10-29d：整件低院墙也要按前后深度分层；整体以最前脚排序会让后墙横压井棚/客栈，源PNG不用裁图，用同UV无重叠region分层。城墙遮挡不要整幅透明，采用仅主角身周的世界坐标羽化窗口，全景禁用；原图放大软度另作美术限制记录。院口本身可走仍要查院内中轴，陶罐在门后80px也会挡35×25脚体；移罐不删墙。Godot键事件若紧邻物理帧读取，须process frame+flush证实际派发，不能拿同节点存在当已入室。配置/tscn构造器不能省小数前导0；首49/2与222/5 FAIL保，后继只查残余。详docs/changes/desert-town-20261029d.md。')
p=ROOT/'docs/desert-town-design-20261029c.md';text=p.read_text('utf-8')
text=text.replace('# 独立沙漠商城 · 总规设计','# 独立沙漠商城 · 总规设计\n\n29d更新：用户已确认“按照这个来创建沙漠城”。首版六区可编辑地图已创建，当前入口、逐项资源路径、验证与限制见[实施记录](changes/desert-town-20261029d.md)。以下保留29c设计时点说明。',1)
p.write_text(text,'utf-8')
out=ROOT/'assets/previews/desert_town_20261029d';out.mkdir(parents=True,exist_ok=True)
files={}
for source,name in [('17-whole-city-published','overview'),('03-bazaar','bazaar'),('18-well-published','water-court'),('07-hall-actual','guest-hall')]:
    src=PROJECT/'artifacts'/(source+'.png');dst=out/(name+'.png');shutil.copyfile(src,dst)
    assert sha(src)==sha(dst);files[name]={'source':str(src),'output':dst.relative_to(ROOT).as_posix(),'sha256':sha(dst),'pixels_modified':False}
save(out/'screenshots.json',files)
save(STAGE/'milestone-recorded.json',{'document':'docs/changes/desert-town-20261029d.md','previews':files,'whole_city_final_art':False})
print('Recorded new-city milestone, role memories, source history and four unmodified native screenshots')
