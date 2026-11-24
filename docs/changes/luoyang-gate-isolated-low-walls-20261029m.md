# 洛阳城门街段撤除孤立矮墙

change-id: luoyang-gate-isolated-low-walls-20261029m

用户指出告示亭旁膝高、没有围成院落的短墙不合理，并明确允许不放围墙。本轮仅撤城门街段这一对孤立横墙：`finish_i_gate_queue_low_edge_west`（脚500,1450）和`finish_i_gate_queue_low_edge_east`（脚900,1450）。二者现图256×52.8，来源`v13_market_west_plot_wall.png`；对应独立solid分别x374..626、774..1026/y1445.2..1450。不得仅隐藏图而留下碰撞或短墙底座。

保告示亭1160,1490、候检旅人/商人、城门和真实围合院墙，包括前侧两段院墙与竖向院界。保Router5D6AAA78、上轮文化进城修复、三城接线、所有NPC/任务/存档与美术原PNG。不扩为整城重排，不随手加新墙或填充物。

System定位现役Gate的82020 payload与原生退役/solid通道，QA只准备这两旧墙域与一张正常图；Root唯一出版、目标导入和实际运行，不复入口86成功或三城/全城矩阵。用户已明确只退出游戏、保留编辑器51856。

Root隔离出版132376自然0/16检查0，原typed payload整逆及原RGBA整逆精同，仅从visual_additions[4,5]、effective_navigation[41,42]、effective_solids[49,50]撤这两owner。没有独立base对象：两墙自带脚基随本体移除；ENV/purpose7的候检院地面不是专属底座，全部保留。新payload E2A4FC35，NAV BFC4AB13/RGBA62046F3B，仅2530个原两poly占据像素由黑恢复白，其他solid优先保留。美术原PNG零改，旧导航原图零改。

唯一新NAV在隔离工程导入42812自然0，verify自然0并逐RGBA等源、3072×2048/无mips；只读原PNG校验的Image.load_from_file warning保留。Root精推广3新叶：sidecar7918DFFE、ctex1AFC040A、md54170B1B5，收据C69F6C4A。没有主工程全量import。

现役finish8 runtime被6消费者严格pin整8场binding，故只换Gate数据仍需31项常量/来源机械后继；17GD通过apply_patch、14JSON精copy已合，均整逆/候选SHA精同。最终Field CAE9A1A5、C F1C8DA74、Coordinator B685F7AA、EX A148093E，新runtime A92BA58C；文化合同仅Field/C两源SHA更新，29l精Router完整approved逻辑保，其他24源不变。Router/Authority/三城模块原封，另7场数据typed精同；不改算法或业务。

QA写前原80源+仅缺19补包，共99全文精备，171登记save；正式冻结136来源。只准备公开Gate近脚setup(500,1490)，两旧墙域各穿越/连接约80tick与一原生图，非World入口或全城复验。

首次launch因其他对话华山隔离检查15112仍在运行，在开引擎前被守卫拒；Root等待其自然退出，未停止对方进程。首actual82548自然1、141检查/1失败、0输入/0图：QA明确传近脚但本城版本−1按旧版1处理，被原Router以PUBLIC_CITY_REQUIRES_CURRENT_COORDINATES拒绝。该失败保留，不为错误QA参数更改生产导航或guard；只将测试最后参数改本城版本3，增失败时原public preparation状态记录。

修正后唯一局部actual25116自然0、158检查/0失败、80真实物理输入ticks、16.411秒。两旧墙对应Sprite均不存在，原两solid域使用真实Player全CollisionShape查询净空；人物从500,1490跨西旧墙到500,1418，返回1498后横走至900,1498，再跨东旧墙到900,1418。告示亭、原两候检旅人、竖院界与前侧真院墙均保留。一张1920×1080正常原图SHA8E1A7BF3已由Root亲看，图中两膝高墙已消失。全程无QA瞬移/改Camera，无World或入口/三城/全城复测。

最后`qa01/final_guard_ROOT_ACTUAL.json` SHA9CCCFFC4C130ABDECA68945DFF006627D196C7EC6D24FF5A215E7B1B266A8668：136冻结源/99全文精备/171save SHA、bytes、精确UTC ticks保持，仅31授权源后继；3新NAV叶精同。原编辑器51856保留，自有引擎全自然退出。旧7条纹理/RenderingServer退出ERROR保，非空stderr，不授全城ART。停止本批检查，撤墙完成交用户重开游戏。
