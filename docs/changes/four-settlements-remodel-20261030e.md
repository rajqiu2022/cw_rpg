# 白鹿渡、东海埠、林西村、竹尾村室外改造 · 2026-10-30e

本批已进入主工程并接回原地点，共6个原生室外布局、7个原场景ID。保留原剧情人物、对白、任务条件与11处原室内入口；原室内美术沿用。新增4张设计参考和4张独立透明模块，设计总图没有裁成场景模块。当前交付为可试玩室外首版，仍有重复树群、规则岸线与较疏的街坊间距，不授设计密度或整片美术终验。

## 当前入口与可编辑来源

正式游戏从原江湖大地图地点进入即可。下列tscn可单独F6检查室外布局，但原NPC、剧情门、任务和正式HUD由系统宿主加载，完整业务请从游戏原地点进入。

| 地点 | 原场景ID | 原生场景 | 尺寸 / 物件 |
|---|---|---|---|
|白鹿渡 · 柳岸栈台|`openworld_bailu_ferry`|[打开场景](../../game/scenes/drafts/four_settlements_20261030e/bailu.tscn)|4000×3000 / 57|
|东海埠 · 石岸货港|`openworld_east_sea_port`|[打开场景](../../game/scenes/drafts/four_settlements_20261030e/donghai.tscn)|4400×3300 / 49|
|林西村 · 老井村心|`linxi_village_center`|[打开场景](../../game/scenes/drafts/four_settlements_20261030e/linxi_center.tscn)|3600×2800 / 37|
|林西村 · 师徒院|`linxi_tutorial`|[打开场景](../../game/scenes/drafts/four_settlements_20261030e/linxi_master.tscn)|2900×2400 / 27|
|林西村 · 南坊|`linxi_village_scrollmap`|[打开场景](../../game/scenes/drafts/four_settlements_20261030e/linxi_south.tscn)|4200×2600 / 42|
|竹尾村 · 村街与练武院|`ch1_s2_qingfeng / ch2_s1_zhuwei_market`|[打开场景](../../game/scenes/drafts/four_settlements_20261030e/zhuwei.tscn)|4200×3200 / 39|

## 实现范围

- 白鹿渡与东海埠各两处木栈台，栈台踏面可走、外围水面真实阻挡；两港原渡船对话与双向选项保留，新落脚位位于船工旁的甲板。
- 林西三个旧片区分别重排，师徒院0/60台地、两处实际台阶；民房、私塾、药居等门脚按新建筑位置配对，返门后可离开，不会沿用旧墙内坐标。
- 东海埠0/90台地、竹尾0/60台地各两处必要阶口，地面/演员高程、侧缘碰撞分层。所有251个布局物件均未放大。
- 正式冷孤云沿用四向待机/行走，原NPC身份、立绘、对话与条件保留。本批没有另造NPC身份或新任务。建筑维持不透明，遮挡只绘制主角alpha0.42影像。
- 小地图由新场景静态纹理生成实际缩略，一次缓存；采用30d简单半透明底板。原世界地点地标/坐标不改，不增加第二组同名城市。
- 原场景与map `.tres` 不写。独立host运行时只改业务位置。原有map.portals生效时，不把legacy热点再叠加，避免重复入口绕过原条件。

新宿主：`game/build/four_settlements_20261030e_system01/`；控制器：`game/scripts/drafts/four_settlements_20261030e/controller.gd`。注册器追加7个ID，既有三城World portal_rows仍为3条。新布局版本3001，旧脚迁入明确入口，已证明当前版本脚保留。离场宿主过场期间停止写入新payload。

最终注册器 `5d6e6d92d5752329b256af685175fee8f6286ba351fa2a20cc9c0076645b4013`，native_sources `464fe83e3fd58dcf3c8dffc78b8b170d8b7197c11ca3e364595a9cefc5b69f6e`，125份绑定来源逐SHA核对。

## 资源路径与使用

[分类缩略图与点击放大](../equipment-skill-catalog.html#resources)；[全资源复用索引](../resource-reuse-index.md)；[本批机器可读资源包](../../game/art/modules/four_settlements_20261030e/resource-pack.json)。

4张新原生图：木栈台、柳树、渡船、修船棚；各调用内置生图1次。原图存于 `assets/raw/four_settlements_20261030e/`，透明补白派生位于 `assets/processed/four_settlements_20261030e/`，运行图位于 `game/art/modules/four_settlements_20261030e/`。只增加RGBA0边界，原RGBA逐像素相同，未清alpha；原RAW的A1留白失败保留。4张GPU加载纹理与派生RGBA完全一致。

26条既有图路径有实际场景消费者；资源包按已打包tscn的PNG引用收集，未把孤立ExtResource当成采用。图鉴新增16路径（4设计+4×3阶段），逐全图/缩略图文件验证，装备/技能/任务/剧情等非resources数据完全相同。当前5220条：2913图、2307音；索引1855来源、显式路径0缺失。

## 实际验证与原失败证据

所有测试使用本任务隐藏独立进程，正式测试暂停存档写入，进程自然结束。未操作用户编辑器。下表记录原始结果，不将早期失败整体改写为通过。

| 批次 | 检查数 / 失败数 | 自然退出 | 说明 |
|---|---:|---|---|
|verify01|95 / 1|1|6图首次加载/门户脚/水域/阶口；村心外门树挡路失败保留，后移树。|
|finish02|38 / 3|1|4图GPU像素/新增域/原生烘存；3处新门脚碰水缸失败保留。|
|doors04.actual|6 / 1|1|主院与村心水缸清除，南村仍指错Jars0；原残余失败保留。|
|doors05|2 / 0|0|南村Jars1精准移开，门脚与实际离开通过。|
|formal01|72 / 2|1|7原ID加载/业务数/主角移动/实际缩略通过；2个片区返门被错误默认出生点oracle判失败，后用真Space验证。|
|business02|39 / 0|0|两港原对话、5处室内真Space进返/同箭头/返回层与实际离开。|
|business03|46 / 0|0|其余6室真进返；师院→村心→南村真实连接门与返门落点。|
|world04|2 / 1|1|QA误以target_scene查action式World门，原失败保留。|
|world05|28 / 0|0|4处真Space出World、原地标和附近落点、真Space回新图，28项通过。|
|ferry06|10 / 0|0|真实Space对话、数字1选项，白鹿↔东海双向航行/甲板落点/无碰撞。|
|locks07|2 / 1|1|QA以target查锁门；旧组件锁门时清空target，原失败保留。|
|locks08|9 / 1|1|林西佩剑锁实际拦截/解锁成功；竹尾QA选到另一废宅锁门，失败保留。|
|locks09|2 / 1|1|QA猜“竹林”标签，实际为“后山密林”，失败保留。|
|locks10|9 / 0|0|精确后山门真锁/解锁及原入口返回，旧布局迁移与当前脚保留。|

证据限制：doors04复制QA时忘记更换输出文件名，覆盖了`review/doors03.json`和同名截图；原doors03 stdout/stderr/run均保留，覆盖后的实际报告另存`doors04.actual.json`。不把覆盖文件当原doors03成功证据。首次catalog新增变量误遮蔽category函数，生成在写图鉴前拒绝；改名后成功。followup源码已全部写入后，在复制已有md5时断言停下；4份既有md5与隔离导入精同，仅核对保留，未重复导入。

正式运行保留既有7条退出纹理/RenderingServer ERROR，部分旧NPC对白有朝向镜像warning；自然0不等于空stderr。原始stdout/stderr/run均位于`assets/staging/four_settlements_20261030e/`。正式报告和截图位于`game/build/four_settlements_20261030e_qa/`。Root已看设计、新模块灰底、6图首轮全景/街景、后续关键门脚、两港甲板、四地正式HUD/缩略与返回实图。

## 保护与交付边界

最终保护399项，396项SHA/bytes/mtime_ns完全相同。两项授权差是注册器和native_sources；第三项为外部并发更新的SceneRouter（740B12B7→1BD954EA），本任务未写Router，保留新头，不回滚。162份记录存档全部精确相同。用户编辑器PID51856保留，本任务引擎均退出。完整差异见`assets/staging/four_settlements_20261030e/delivery-verification.json`。

仅交付四地室外改造与原流程接入；原剧情室内仍沿用，未增加新的室内美术、任务或人物动作。树群分布、岸线形状和街坊密度仍可继续美术细化。停止本批已通过组件复测，不以重复PASS补足视觉还原。
