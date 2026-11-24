"""Publish factual remodel and QA receipts; keep failed evidence intact."""
from four_settlements_20261030e import *
v=json.loads((STAGE/'delivery-verification.json').read_text('utf-8'))
qa=ROOT/'game/build/four_settlements_20261030e_qa';private=PROJECT/'review'
lines=['# 白鹿渡、东海埠、林西村、竹尾村室外改造 · 2026-10-30e','',
'本批已进入主工程并接回原地点，共6个原生室外布局、7个原场景ID。保留原剧情人物、对白、任务条件与11处原室内入口；原室内美术沿用。新增4张设计参考和4张独立透明模块，设计总图没有裁成场景模块。当前交付为可试玩室外首版，仍有重复树群、规则岸线与较疏的街坊间距，不授设计密度或整片美术终验。','',
'## 当前入口与可编辑来源','',
'正式游戏从原江湖大地图地点进入即可。下列tscn可单独F6检查室外布局，但原NPC、剧情门、任务和正式HUD由系统宿主加载，完整业务请从游戏原地点进入。','',
'| 地点 | 原场景ID | 原生场景 | 尺寸 / 物件 |','|---|---|---|---|']
ids={'bailu':'openworld_bailu_ferry','donghai':'openworld_east_sea_port','linxi_master':'linxi_tutorial','linxi_center':'linxi_village_center','linxi_south':'linxi_village_scrollmap','zhuwei':'ch1_s2_qingfeng / ch2_s1_zhuwei_market'}
labels={'bailu':'白鹿渡 · 柳岸栈台','donghai':'东海埠 · 石岸货港','linxi_master':'林西村 · 师徒院','linxi_center':'林西村 · 老井村心','linxi_south':'林西村 · 南坊','zhuwei':'竹尾村 · 村街与练武院'}
for r in v['layouts']:
 k=r['key'];layout=json.loads((ROOT/'game'/ART/(k+'.json')).read_text('utf-8'))
 lines.append(f"|{labels[k]}|`{ids[k]}`|[打开场景](../../game/scenes/drafts/{NAME}/{k}.tscn)|{'×'.join(map(str,layout['size']))} / {r['objects']}|")
lines+=['','## 实现范围','',
'- 白鹿渡与东海埠各两处木栈台，栈台踏面可走、外围水面真实阻挡；两港原渡船对话与双向选项保留，新落脚位位于船工旁的甲板。',
'- 林西三个旧片区分别重排，师徒院0/60台地、两处实际台阶；民房、私塾、药居等门脚按新建筑位置配对，返门后可离开，不会沿用旧墙内坐标。',
'- 东海埠0/90台地、竹尾0/60台地各两处必要阶口，地面/演员高程、侧缘碰撞分层。所有251个布局物件均未放大。',
'- 正式冷孤云沿用四向待机/行走，原NPC身份、立绘、对话与条件保留。本批没有另造NPC身份或新任务。建筑维持不透明，遮挡只绘制主角alpha0.42影像。',
'- 小地图由新场景静态纹理生成实际缩略，一次缓存；采用30d简单半透明底板。原世界地点地标/坐标不改，不增加第二组同名城市。',
'- 原场景与map `.tres` 不写。独立host运行时只改业务位置。原有map.portals生效时，不把legacy热点再叠加，避免重复入口绕过原条件。','',
'新宿主：`game/build/four_settlements_20261030e_system01/`；控制器：`game/scripts/drafts/four_settlements_20261030e/controller.gd`。注册器追加7个ID，既有三城World portal_rows仍为3条。新布局版本3001，旧脚迁入明确入口，已证明当前版本脚保留。离场宿主过场期间停止写入新payload。','',
f"最终注册器 `{v['registry_sha']}`，native_sources `{v['manifest_sha']}`，{v['native_sources']}份绑定来源逐SHA核对。","",
'## 资源路径与使用','',
'[分类缩略图与点击放大](../equipment-skill-catalog.html#resources)；[全资源复用索引](../resource-reuse-index.md)；[本批机器可读资源包](../../game/art/modules/four_settlements_20261030e/resource-pack.json)。','',
'4张新原生图：木栈台、柳树、渡船、修船棚；各调用内置生图1次。原图存于 `assets/raw/four_settlements_20261030e/`，透明补白派生位于 `assets/processed/four_settlements_20261030e/`，运行图位于 `game/art/modules/four_settlements_20261030e/`。只增加RGBA0边界，原RGBA逐像素相同，未清alpha；原RAW的A1留白失败保留。4张GPU加载纹理与派生RGBA完全一致。','',
'26条既有图路径有实际场景消费者；资源包按已打包tscn的PNG引用收集，未把孤立ExtResource当成采用。图鉴新增16路径（4设计+4×3阶段），逐全图/缩略图文件验证，装备/技能/任务/剧情等非resources数据完全相同。当前5220条：2913图、2307音；索引1855来源、显式路径0缺失。','',
'## 实际验证与原失败证据','',
'所有测试使用本任务隐藏独立进程，正式测试暂停存档写入，进程自然结束。未操作用户编辑器。下表记录原始结果，不将早期失败整体改写为通过。','',
'| 批次 | 检查数 / 失败数 | 自然退出 | 说明 |','|---|---:|---|---|']
notes={
'verify01':'6图首次加载/门户脚/水域/阶口；村心外门树挡路失败保留，后移树。',
'finish02':'4图GPU像素/新增域/原生烘存；3处新门脚碰水缸失败保留。',
'doors04.actual':'主院与村心水缸清除，南村仍指错Jars0；原残余失败保留。',
'doors05':'南村Jars1精准移开，门脚与实际离开通过。',
'formal01':'7原ID加载/业务数/主角移动/实际缩略通过；2个片区返门被错误默认出生点oracle判失败，后用真Space验证。',
'business02':'两港原对话、5处室内真Space进返/同箭头/返回层与实际离开。',
'business03':'其余6室真进返；师院→村心→南村真实连接门与返门落点。',
'world04':'QA误以target_scene查action式World门，原失败保留。',
'world05':'4处真Space出World、原地标和附近落点、真Space回新图，28项通过。',
'ferry06':'真实Space对话、数字1选项，白鹿↔东海双向航行/甲板落点/无碰撞。',
'locks07':'QA以target查锁门；旧组件锁门时清空target，原失败保留。',
'locks08':'林西佩剑锁实际拦截/解锁成功；竹尾QA选到另一废宅锁门，失败保留。',
'locks09':'QA猜“竹林”标签，实际为“后山密林”，失败保留。',
'locks10':'精确后山门真锁/解锁及原入口返回，旧布局迁移与当前脚保留。'}
for key,note in notes.items():
 report=(private if key in ['verify01','finish02','doors04.actual','doors05'] else qa)/(key+'.json')
 if not report.exists():continue
 j=json.loads(report.read_text('utf-8'));checks=j.get('checks',[]);fail=sum(not r['ok'] for r in checks)
 label='doors04' if key=='doors04.actual' else key;rp=STAGE/(label+'.run.json');run=json.loads(rp.read_text('utf-8')) if rp.exists() else {}
 lines.append(f"|{key}|{len(checks)} / {fail}|{run.get('exit','原run另存')}|{note}|")
lines+=['',
'证据限制：doors04复制QA时忘记更换输出文件名，覆盖了`review/doors03.json`和同名截图；原doors03 stdout/stderr/run均保留，覆盖后的实际报告另存`doors04.actual.json`。不把覆盖文件当原doors03成功证据。首次catalog新增变量误遮蔽category函数，生成在写图鉴前拒绝；改名后成功。followup源码已全部写入后，在复制已有md5时断言停下；4份既有md5与隔离导入精同，仅核对保留，未重复导入。','',
'正式运行保留既有7条退出纹理/RenderingServer ERROR，部分旧NPC对白有朝向镜像warning；自然0不等于空stderr。原始stdout/stderr/run均位于`assets/staging/four_settlements_20261030e/`。正式报告和截图位于`game/build/four_settlements_20261030e_qa/`。Root已看设计、新模块灰底、6图首轮全景/街景、后续关键门脚、两港甲板、四地正式HUD/缩略与返回实图。','',
'## 保护与交付边界','',
f"最终保护{v['protected']}项，{v['same']}项SHA/bytes/mtime_ns完全相同。两项授权差是注册器和native_sources；第三项为外部并发更新的SceneRouter（740B12B7→1BD954EA），本任务未写Router，保留新头，不回滚。162份记录存档全部精确相同。用户编辑器PID51856保留，本任务引擎均退出。完整差异见`assets/staging/four_settlements_20261030e/delivery-verification.json`。",
'',
'仅交付四地室外改造与原流程接入；原剧情室内仍沿用，未增加新的室内美术、任务或人物动作。树群分布、岸线形状和街坊密度仍可继续美术细化。停止本批已通过组件复测，不以重复PASS补足视觉还原。','']
path=ROOT/'docs/changes/four-settlements-remodel-20261030e.md';path.write_text('\n'.join(lines),'utf-8')
summary='四地室外6布局/251物件无放大，接7原ID；11原室内真进返、4World往返与双向渡船、林西/竹尾锁及旧脚迁移过。4设计+4native各builtin1次/透明仅RGBA0补白原RGBA同/4GPU精同，原A1与早期QA FAIL保。registry5D6E6D92/native464FE83E/125源；399保护396精同，2授权+并发Router740B→1BD954EA保/162save精ticks同/editor51856留。图库5220/16新路径32图核/非resources同，索引1855源0缺。室外首版，原内景沿用，树群/岸线/密度非全ART；详docs/changes/four-settlements-remodel-20261030e.md。'
def insert(p,body):
 old=p.read_text('utf-8');head,rest=old.split('\n',1);p.write_text(head+'\n\n'+body+'\n'+rest,'utf-8')
for rel in ['AGENTS.md','docs/current-progress.md','docs/agents/producer-memory.md']:
 insert(ROOT/rel,'## 2026-10-30e 白鹿渡、东海埠、林西村、竹尾村室外已接原入口\n\n'+summary+'\n')
insert(ROOT/'docs/agents/system-memory.md','2026-10-30e：四地独立宿主复用原Scene业务，运行时仅重映NPC/门/互动脚；旧map.portals生效时不追加legacy热点。版本3001隔离旧归一化坐标，原室内返回按currentID选新门脚；World原landmark脚精读，ferry互返甲板。小地图clone专用accepted IDs且缓存实际纹理。source_valid绑定125源，0共享Router/Field写。详四地30e专题。\n')
insert(ROOT/'docs/agents/art-memory.md','2026-10-30e：四地4设计+木栈台/柳/渡船/修船棚4native各1builtin；仅RGBA0补白，原RGBA同，原A1失败保。6布局251物件不放大、26既有图复用。水面只开放栈台踏面；阶口连真实层。当前室外首版仍有规则岸线/重复树群与疏街坊，不能宣称设计还原终验。详四地30e专题。\n')
insert(ROOT/'docs/agents/qa-memory.md','2026-10-30e：11室内实际Space进返、4World往返、数字1渡船双向选项、2条件锁与3001迁移完成。ExitZone锁门清target，QA应按已知原门户位置/准确destination查，不能查target或猜竹林名；World另有action式门。doors04覆盖doors03 JSON的失误已披露，原stdout/run保；正式旧7退出ERROR保。成功组件不复测。详四地30e专题。\n')
insert(ROOT/'docs/experience-log.md','2026-10-30e：原场景改造必须分别验证室内返门、World原landmark、跨港对白场景跳转；三条来源需要不同落脚，不能统一default。旧存档版本与新布局编号要隔离。锁门会清空运行target，QA应从原数据稳定ID/坐标映射；复制测试必须先改所有输出名，避免覆盖失败证据。\n')
print(path)
