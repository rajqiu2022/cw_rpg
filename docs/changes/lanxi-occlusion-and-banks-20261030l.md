# 岚溪寨遮挡与坡岸优化 · 2026-10-30l

用户截图为苗风岚溪寨（`openworld_lanxi_zhai`），临溪街市/蜡染绣坊区域；与林西村三场景不同。按截图要求直接修正式地图，原三级地形与四处必经阶口保持。

## 当前结果

- 正式场景：`game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn`，SHA 前缀 `DE7EA4A4`；仍从原江湖大地图岚溪寨箭头进入。
- 建筑、屋顶、桥廊与店铺保持不透明。专用控制器关闭旧 `fade_enabled`；在确有前景像素遮挡时，用同一主角纹理/帧/方向/脚锚显示 alpha 0.42 影像，不挖空建筑。覆盖 Sprite2D 与 Polygon2D 铺街，透明像素不会触发遮挡；室内与全景关闭影像。
- 撤下 88 个斜投影/压扁的台地墙面，沿原坎界用 166 段完整苔石坡岸拼接。统一等比缩小 0.16/0.20/0.245，未裁切、拉伸或放大 PNG。北缘低岩隐藏在高台后；阶口保留宽开口。
- 5 栋房屋退离边界或让开前院：PocketHome1、PocketHome6、DyeWorkshop、PocketInfill1、PocketHome8。3 件陈设 Table1、WaterJars、Dry2 移到生活区域。根节点与附属碰撞一起移动，楼层不变。下层 WestWeaver 路线东端收回至 x1900，避免走到坡岸上。
- 原 0/120/240 高程、4 阶、平台轮廓、所有原地形阻挡节点逐字保持。绣坊旧门脚与缓存前厅不变。
- 针对移动物件覆盖旧通路的情况，只迁移“旧版本可走而当前被本次移动物件覆盖”的脚点到该物件预设门前；原本非法的墙内脚不迁移，当前合法脚原值保留。只处理运行时落点，没有读写真实存档。
- 小地图由原实景缓存自动重建，包含新苔石坡岸且不烘入人物。

## 文件与资源

|用途|路径|
|---|---|
|正式场景|`game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn`|
|本次控制器/旧脚兼容|`game/build/lanxi_revision_20261030l/controller.gd`|
|主角遮挡影像|`game/build/lanxi_revision_20261030l/ghost.gd`|
|移动前后脚及门前点|`game/build/lanxi_revision_20261030l/moved_objects.json`|
|复用完整苔石图|`game/art/modules/miao_recompose_20261029g/rock_bank.png`|
|当前资源包|`game/art/modules/miao_terrain_20261029i/resource-pack.json`|
|可重复布局脚本|`scripts/build_lanxi_revision_20261030l.py`|
|初始备份/核验|`assets/staging/lanxi_revision_20261030l/`|

0 新美术图、0 原 PNG 处理、0 全工程导入。苔石 PNG SHA 与旧资源包精确相同。原 terrace.png 长墙用途已从当前场景移除，其历史资源保留。图鉴共 5234 项，本次精改 105 项（34 组件的原图/派生/工程记录及 3 条退役墙记录），全部缩略图和点击放大沿用；其他记录及非资源载荷保持。资源索引复核 1921 文本来源，显式路径缺失 0。

## 验证与失败保留

- candidate01 PID132892：QA 的 OUT 常量与继承脚本重名，编译失败，原报告保留。
- candidate02 PID116540 / candidate04 PID44288：各 52 检查，0 失败；包括建筑 shader 的旧透明窗口全部关闭。04 为布局调整后复看，不作为新增独立矩阵计数。
- ghost03/05/06：定位 Polygon2D 铺街遮挡与影像。冻结同一镜头比较 alpha0.42 / 关闭影像，主角区域有 2019 个像素变化超过 2，确认真实绘制而非只检查 visible。05 的 alpha1 仅是 QA 诊断，不进入生产。
- layout07 PID133816：40 检查、4 失败。四阶真实 W/S 上下行走均通过；一房门前通路被另一楼压缩、旧脚探针在物理运行中偏离、凹多边形被当凸形处理，原失败与警告保留。PocketHome6 向北退 100；旧形状检测改为凸分解；残余探针暂停本地移动。
- residual08 PID113256：8 检查、0 失败，修正房屋门前实际行走、旧合法脚迁移、合法脚精保、旧墙内脚拒迁；不重复四阶成功矩阵。
- formal09 PID107604：16 检查、0 失败，原 World 岚溪寨箭头 Space 真进城、主角步行、实景 mini、绣坊前厅真实进返、铺街不透明/主角 alpha0.42、World 真返回原脚。
- 后继仅删除未使用 terrace Texture2D 声明，全部场景节点与 formal09 版本相同。
- restore10 PID131992：5 检查、0 失败，正式加载旧合法而新房覆盖的脚点，落在预设门前并能实际走离。最终来源合同通过。
- 完成进程全部自然退出 0；上述两次早期失败自然退出 1。运行结束仍有项目既有 7 条纹理/RenderingServer 退出 ERROR，不能称为无错误日志。

审图看过正常镜头铺街、西坡岸、上层民巷、主阶、调整房屋和全景。已消除本次截图薄片/挖洞问题；连续岩带仍有重复纹样和规则台地边缘，本轮不宣称全部美术终验。

## 保护与发布

最终 registry `4A3B814A`、native manifest `CCC1D7A8`，原 162 来源保留（仅当前岚溪寨场景更新）并加 4 个精确来源，共 166。registry 只更换来源头，逆替换后与原备份字节相同；Router `21CAF866`、共享 Field、project、其他城市源均未改。

本轮基线 351 文件：162 个 userdata 下 save/bak 文件 SHA/bytes/mtime_ns 完全相同；另 186 保护项相同；3 个授权正式文件变化。该 162 是本轮匹配范围，不冒充其他任务的 171 口径。并发采集动作任务与最新记录保留。用户编辑器 PID51856 未操作，测试结束只剩该编辑器。无真实存档恢复或写入，未启动/停止用户游戏。

## 实机图

- [正式坡岸与晾布通道](../../game/build/lanxi_revision_20261030l/formal_bank09.png)
- [正式临溪铺街，建筑不透明](../../game/build/lanxi_revision_20261030l/formal_market09.png)
- [正式房前通路](../../game/build/lanxi_revision_20261030l/formal_home10.png)
- [全景布局](../../game/build/lanxi_revision_20261030l/overview07.png)（最终仅房6向北退100；正式房前图见上）

本轮验证已收口，可重开游戏从原岚溪寨入口查看。保留其他地图、门派与原任务，不扩展新剧情/内景或继续重复成功矩阵。
