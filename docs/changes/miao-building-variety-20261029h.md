# 苗风山城建筑体量与类型差异 · 2026-10-29h

change-id: miao-building-variety-20261029h

后续2026-10-29i：用户指出地形平坦、楼梯没有实质作用，现有[三级台地/必经阶口版](miao-terrain-20261029i.md)。本h版本作为建筑资源基线保留；旧四阶检查仅证明平面通行，不能拿来证明高差。当前制作场景为i版，五种差异建筑原图继续复用。

用户指出“建筑太接近，都是一个大小的，不够丰富”。本轮针对结构、用途、轮廓和大中小体量层级，避免把同屋随机放大缩小充当丰富。保持29g斜向溪谷、三桥四阶、土坪/架空铺街、主角/NPC/缓存室内既有逻辑。

状态：建筑差异版已发布，另存h场景，旧f/g与其他城市不覆盖。新资源五种：宽公共木厅、窄高三层木楼、低矮单间宅、转角作坊、小高脚粮棚。大建筑通过开间/层数增加体量，小宅保持成人门，粮棚明确为小储藏舱；不创造新正式设定、业务或剧情。

读：原29e总规、g实景/布局、ai-rules/UI/空间设计/角色记忆；写：专有raw/processed/staging与新game art/scene/script目录、图库/文档。原图保留，透明只按既有许可增RGBA0留白。317项共享/旧城/存档与已发布文件保护；独立导入和受改变占地影响的局部验证，旧桥阶/室内成功矩阵不复。

## 当前场景与体量

[当前miao_town.tscn](../../game/scenes/drafts/miao_building_variety_20261029h/miao_town.tscn)，编辑器打开此场景后F6。默认正式冷孤云跟随，原控制、三桥四短阶、居民侧向四相/左镜像与唯一缓存绣坊前厅沿用；前厅门仍1750,1845。新公共木厅/窄高楼仅外观，没有新增室内、商店、任务或业务。正式大地图入口未接。

![建筑差异版原生实景](../../assets/previews/miao_building_variety_20261029h/overview.png)

|类型|实例数|结构与尺度依据|
|---|---:|---|
|宽公共木厅|1|五开间宽檐/廊厅，横向宽度明显超过普通民居；成人门约120px|
|窄高三层木楼|2|三层窗格＋小侧灶屋，最高约690px；成人门约119px|
|单间低宅|4|一层一门一窗，附柴棚，无楼层/阳台/高支柱；成人门约105px|
|转角长廊作坊|2|低长工作廊接高储物间，屋顶方向与体量不同；成人门约112px|
|小型高脚粮棚|3|高约200px、小储粮舱/鼠盘/短梯，明确不是缩小的成人住宅|

12处替换为同位置附近重构，不是对同一屋型随机缩放。显示只用原图等比缩放与留白脚锚补偿，宽高不单独拉伸。统一成人门约105—120px，人物沿旧112px完整地图精灵；高低来自层数、开间和用途。详情含原门高估读值、运行宽高、原/新脚点和体量：[massing-contract.json](../../assets/staging/miao_building_variety_20261029h/massing-contract.json)。成人门原像素高度是视觉估读，非自动语义分割或现实尺寸测量。

公共木厅置于土坪后侧，街尾三层楼向东南退开；四小宅分散进住宅/桥边/坡巷，三粮棚作为附属小体量。转角作坊换下旧低房并留出作业院。原土材院面按新宽度/脚点同步更新；原挡厅前的岩坎移到厅后，碰撞保持；厅边一株树加独立的主角局部透明窗口，原生树图/实体不改。

![小宅与高脚楼对比](../../assets/previews/miao_building_variety_20261029h/cottage.png)

## 文件、原图与使用

5张imagegen内置原生输出各1次，真实renderer预检通过、提示词逐字从登记文件送入工具，0CLI/fallback；model/provider/cost未返回保null。5透明原图完整A1四边留白失败保留，只增RGBA0画布后留白通过，原RGBA逐像素保持、未清alpha/裁切/改色/拉伸。仅同源隔离工程导入5图，解码RGBA与PNG完全相同。

原图与完整提示词：[RAW manifest](../../assets/raw/miao_building_variety_20261029h/manifest.json) → [授权派生](../../assets/processed/miao_building_variety_20261029h/resource-pack.json) → [工程运行资源](../../game/art/modules/miao_building_variety_20261029h/resource-pack.json)；[图鉴分类缩略与点击放大](../equipment-skill-catalog.html#resources)、[完整路径及复用情况](../resource-reuse-index.md)。

本版仍351布局对象、285阻挡，新建26个工程文件含10新import叶；0旧game文件覆盖。复用23张29f图和6张29g图，旧原生精灵/肖像/家具/正式Player不改。公共木厅及新楼均未接正式业务。

## 验证与证据

- **62项/0FAIL，自然0/空stderr**：仅5新PNG解码RGBA，12处新体量的真实碰撞与脚深度，8居民实际脚体扫路，新占地影响的10个目的地/前院连通、四阶上下邻接落脚点。原三桥/四阶W/S/缓存室内已通过组件不重复运行；源式核对对应8子树保持原文。
- 实图检查后，首高楼截图的主角点落在既存岩体内，改为清楚的真实地面3900,1050；没有为截图移动岩体或放松碰撞，首图保留。厅前原树冠能挡住主角，仅该树加入独立局部窗口，原图/树体保持。
- **6项/0FAIL，自然0/空stderr**：新厅前真实Godot物理键D移动约385px、树冠局部窗口实际启用、三处新截图脚点可走。原62成功组件不复；本批没有失败的功能矩阵，不借旧批失败宣称全城clean。
- 原生总览、厅/三层楼/低宅/转角作坊/粮棚/街尾楼正常视图已亲看，仅准本轮体量差异可见；不授全部设计还原。
- **317项保护精同**：包括162个存档/备份、共享与其他城市、旧f的117及旧g的30工程文件；SHA/bytes/mtime_ns首末同。用户editor51856保留，自有进程自然退，未主工程整导入或代切编辑器。
- 图鉴新增15条原生→派生→工程路径、30个全图/缩略入口核验；非resources对象精同，复用索引显式路径无缺。

证据：[62项报告](../../assets/staging/miao_building_variety_20261029h/town_project/artifacts-h/verification-variety.json)、[6项厅前与脚点](../../assets/staging/miao_building_variety_20261029h/town_project/artifacts-h/verification-views.json)、[留白核对](../../assets/staging/miao_building_variety_20261029h/padding-verification.json)、[发布文件清单](../../assets/staging/miao_building_variety_20261029h/publication.json)、[保护与图库guard](../../assets/staging/miao_building_variety_20261029h/final-guard.json)。

本轮完成楼型/体量差异和局部院距调整，停止重复本批功能检查。仍有部分普通民居重复，整体山势、朝向与总规密度未完全还原；正式World/剧情经济战斗及新楼室内不在此批。
