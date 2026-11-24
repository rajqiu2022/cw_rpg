# 襄州、清河、雁门三地室外改造 · 2026-10-30e

## 目标与当前范围

用户要求直接改造襄州城、清河镇、雁门关。三地沿用正式地点ID和原大地图门户，不另造同名草案入口；原场景资源及业务数据保留，由专用作者生成运行时地图副本。本批为室外结构和原服务接线，不宣称新增全部室内、剧情或配音完成。

状态：**首版室外结构与原业务接线已正式，关键实机通过，交用户试玩**。不将此状态扩为参考图密度、全城美术或新增室内剧情全部完成。

| 地点 | 地图尺寸 | 结构与区别 | 原业务 |
| --- | --- | --- | --- |
| 襄州城 | 5632×4096 | 南门、军营校场、江防府署、军需工坊、商街民巷、沿江仓码头；24完整主楼、4后厨，双桥与船岸 | 原守备、通缉榜、矿谷支路、World出口 |
| 清河镇 | 4096×3072 | 紧凑河镇、两桥串联河岸街市与院落；18完整主楼、4后厨 | 原货郎、原商店、World出口 |
| 雁门关 | 4608×4096 | 关楼瓮城、军舍、仓场、山口围合与南土北雪岔路；15完整楼 | 原药包、隐洞门、非安全区遭遇及World出口 |

襄州25人、清河25人，包含各自原业务NPC与普通居民；雁门原场景NPC表为空，未伪造正式军士身份或新增任务。楼型复用原生正向、斜向及大小不同完整楼体，不用孤门充房屋；没有新内景的住宅不造假入口。雁门为实际平面路网和崖壁围合，不将装饰阶冒称地形高差。

## 实现与写权

- 共享运行时、襄州作者：`game/build/three_settlements_20261030e_system01/`。
- 清河作者：`game/build/three_settlements_20261030e_qinghe01/qinghe_author.gd`。
- 雁门作者与雪材质登记：`game/build/three_settlements_20261030e_yanmen01/`。
- QA候选、冻结及实机原始事实：`game/build/three_settlements_20261030e_qa01/`。
- Root是唯一正式接线与引擎运行者；各作者/QA仅写独立负责目录。

正式Router `1BD954EA3C0AFC389137864A5F305CCA8D896CDEAC9372BF1E01038B707C2474`：只为三个精确原ID增加Registry分支，九必要来源完整机械后继。旧24条来源逆边、旧key与原洛阳文化准入保留；新内容独立合同，不向旧清单扩无关key。候选/精确逆/授权见 `system01/router_closure01_READY/`。

专用Field继承正式MainField，保Player、HUD、任务、背包、商店和遭遇逻辑；复用金陵成熟的原生桥岸绘制。小地图保30c真实静态缩略与30d简洁半透细框，仅本地扩清河/雁门地点集。对白后的动态刷新只更新互动、原药包/门户与榜NPC，不重建地形、人物或小地图缓存。

旧脚迁移按合法旧路和对应门户限定，不用nearest搜安全点。World进入统一新南门；襄州矿谷真正返回旧坐标(.50,.18)显式对应新北口；雁门保隐洞返脚与药包条件。原业务字段深复制，未改正式原`tres`/layout或存档schema。

## 美术管线

绝大部分复用既有合格素材，所有新布局楼体等比native_scale≤1。仅补一张雁门薄雪砂砾材质，内置imagegen一次：

- Prompt：`prompts/yanmen_rebuild_20261030e/snow_gravel_v1.txt`。
- RAW：`assets/raw/yanmen_rebuild_20261030e/snow_gravel_v1.png`。
- 工程：`game/art/modules/yanmen_rebuild_20261030e/snow_gravel.png`。
- 原生结果1254×1254 RGB，**未达到请求1024尺寸**；不缩放原图、不将尺寸记PASS。实际地面period640、边缘羽化160。
- PNG SHA `0143a677757dba7f84a8ec8cef023a2fd5229d0d63efa8f406a95a2f64005419`；孤立导入验证RGBA精确，Root只推广三新叶，不全工程import。
- 图库5203→5205，仅添RAW/工程两条及两缩略；旧记录/非resources保持，定向复用索引只涉及六个来源，未全库扫描。详`yanmen01/gallery_two_actual.json`。

## 必要检查与保留失败

1. 八新脚本解析通过，未重编旧成功组件。
2. 几何首轮1204检查/4失败：仅襄州四名居民脚体触货物或楼边。保原报告，仅迁四脚，13项残余自然0/0失败；精确逆回旧作者，原1200成功继承不复。
3. 实机77552：170检查/1失败，11真实输入ticks；World→襄州原入口、32px输入与两正常图通过。失败是QA未先推进Hero开场即按数字选项，原报告保留，不据此改生产对白。
4. 02候选未启动引擎：Root误传大写SHA被runner前置拒；新03仅改榜前公开setup离边坐标。03实际135908：164检查/1失败、0INPUT0图，初次公开near设置被Registry正确按World来源重置南门，QA误判目标脚；保原FAIL，后续仅补公开bootstrap再继续未完成服务。
5. 04实际112804：172检查/1失败、2INPUT，公开bootstrap与真实Hero首句已过；新增QA错误把DialogLayer根当DialogBox读取`choices_container`，产生Nil属性SCRIPT ERROR。原错误日志保留，05只改QA真实子节点路径和空值防护，未改生产。此错误与旧七条退出纹理/RenderingServer ERROR分开记录。
6. 05实际139640自然0：229检查/0失败、50真实输入ticks、五新增正常图。继承77552已成功襄州World入城/32px/两图，不复原前缀。襄州原守备真实Hero→NPC选项2关闭、原通缉榜开闭不接任务、南门真Space返原World；清河与雁门首次原World真Space进入、32px动作及真Space返原World别名/门脚均通过。清河原Hero→NPC选项1打开`wulin_trade_hall`，关闭无交易；主角/队伍/统计/金钱/背包/任务语义前后同。
7. 所有near细节站位均由公开`go_field_smart`新Field设置，明确不是从入口连续步行，不直写人物/相机。通缉榜懒初始化仅将两原ID四字段完整默认状态视为absence等价，保留raw差异；未知、接取或其他字段不归一化。
8. 05无04新增Nil/SCRIPT ERROR；原货郎缺up朝向有mirror fallback WARNING，旧七条退出纹理/RenderingServer ERROR与ObjectDB warning保留，不声称空stderr。

最终只读guard `45BCDBAA3CD3E1A134A3FF7897191F0BB4BF946E27CD9D4FEA3E07D3BA4111FF`：166保护来源、9全文备份、171存档SHA/bytes/UTC ticks同。四external中另任务`town_registry.gd`及`native_sources.json`两路径改变，仅记录保留，未回滚或混称0外差。编辑器51856保留；本任务自有引擎全自然退出。guard时另任务138788运行`four_settlements_20261030e_qa/locks10.gd`，没有操作该进程，不能声称系统仅剩编辑器。

原生襄州图已Root亲看：`qa01/actual/77552/openworld_xiangzhou_city_arrival.png`与`openworld_xiangzhou_city_detail.png`，仅接受城门/水岸/桥接显示，不代替军营街区或另外两城ART检查。

Root另亲看139640五张原生1920×1080图：襄州守备校场街口、清河镇口驿舍及行旅十字街、雁门瓮城双门及关内军营仓院。完整楼体/成人比例、关门墙接合与真实小地图可辨，接收本批室外结构显示；襄州校场大空地、清河规整土院、雁门空军院与参考密度仍有差距，不授全ART，也不为已接受的功能重跑矩阵。

- [襄州校场街口](../../game/build/three_settlements_20261030e_qa01/actual/139640/openworld_xiangzhou_city_service_street.png)
- [清河商街](../../game/build/three_settlements_20261030e_qa01/actual/139640/openworld_qinghe_town_detail.png)
- [雁门瓮城](../../game/build/three_settlements_20261030e_qa01/actual/139640/openworld_yanmen_pass_arrival.png)

## 保护与未扩范围

171存档仅核路径、SHA、字节、UTC ticks，不读内容、不回写、不恢复。九正式改动均有精确全文备份，旧三地场景/layout、原服务/任务、全局MainField、World保持。四个其他任务路径record-only，不回滚外差。用户Godot编辑器51856保留，只运行本任务自有自然退出进程。

本批不含全部房屋内景、专属新增任务配音、雁门真实高程及全地图参考密度终验。雁门仍沿原NPC空表，军民驻点与生活内容待补；襄州/清河普通人可家常对白，但不冒专属新剧情。原矿谷/隐洞目标、返回迁移及门条件经静核保留，未本批真进入两支路，不能把World往返成功扩大成这两支路完整旅行验收。
