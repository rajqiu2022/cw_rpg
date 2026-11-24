# 沙漠院墙、赤岩台地与三处门派室外入口

2026-10-30，针对用户五张标注截图和“烈云谷、凌月派、茗雾山庄没改造”的反馈，已写入当前工程。运行中的旧进程需要重新启动才能加载新场景。本批没有操作用户编辑器 PID 51856。

## 已完成的场景修改

| 场景 | 修改 | 当前工程路径 |
|---|---|---|
| 沙漠城 | 驼院及三处民院去掉穿入房屋/棚柱的后墙、后侧碰撞，保留前矮墙与院口；西城界外移并补接墙段。所有建筑保持不透明，被遮挡时仅显示主角半透明影像。 | `game/scenes/drafts/desert_town_20261029d/desert_town.tscn` |
| 赤岩镇 | 地形改为 0 / 240 / 330 高程，连续台面、坎壁与三处必要阶口；人物沿台阶连续升降，侧墙和非阶坎阻挡，建筑/NPC同层落脚。室内碰撞层及出门高程恢复同步。 | `game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn` |
| 凌月派 | 寒潭竹院，竹径山门、演棍坪、双桥曲潭、临潭双层主楼、不同体量竹舍、后山台。0 / 90 / 180 高程，四阶。 | `game/scenes/drafts/sect_completion_20261030a/lingyue.tscn` |
| 烈云谷 | 灰岩木寨与渡口货院，木石关门、宽厅、窄高货舍与低棚、演武台、河岸落脚地。0 / 120 / 240 高程，四阶。 | `game/scenes/drafts/sect_completion_20261030a/lieyun.tscn` |
| 茗雾山庄 | 已有29k白墙茶院模块场景接入原正式地点，保留茶垄、加工棚、双桥及四阶；0 / 60 / 120 高程。 | `game/scenes/drafts/sect_completion_20261030a/mingwu.tscn` |

### 修复后的实景

以下均为Godot原生截图，未用生图替代实机：

![驼院棚柱与后墙不再穿插](../../assets/previews/sect_completion_20261030a/desert_caravan.png)

![城门保持不透明，仅主角半透明](../../assets/previews/sect_completion_20261030a/desert_gate.png)

![赤岩连续高台、坎面与阶口](../../assets/previews/sect_completion_20261030a/redrock_highland.png)

![凌月竹院及高台入口](../../assets/previews/sect_completion_20261030a/lingyue.png)

![烈云木石主厅及高台入口](../../assets/previews/sect_completion_20261030a/lieyun.png)

![茗雾白墙茶院及高台入口](../../assets/previews/sect_completion_20261030a/mingwu.png)

## 正式入口与原业务

| 原地点ID | 当前室外场景 | 沿用的原内院 |
|---|---|---|
| `ch2_s4_lingyue_gate` | 凌月寒潭竹院 | `openworld_lingyue_inner_court` |
| `ch7_s1_lieyun_valley_ferry` | 烈云灰岩木寨 | `ch7_s3_lieyun_outpost_outer_ward` |
| `ch7_s2_mingwu_tea_town` | 茗雾茶院 | `ch7_s4_mingwu_manor_outer_court` |

三个原地点由现有三城registry扩展分派到专用 `game/build/sect_completion_20261030a_system01/sect_field.gd`。原scene/map数据不写，运行副本只重排业务落点，保留原NPC身份、原对话、调查物与开放条件。未新增任务、奖励或角色。凌月原入口无NPC行，沿用原热点对话，不虚构新弟子。

原内院画面沿用，不属于本批室外改造。实际完成三处进入原内院及返回新室外、两处受限入口拒绝、三处原对话触发。测试开放条件仅内存设置，检查点存档已禁用。不是整条剧情通关测试。

高处的箭头使用 `ExitZone.configure_marker` 的持久偏移，碰撞仍在地面坐标；只移动子图会被箭头浮动动画覆盖，已修复该显示错位。返脚与箭头对应同一真实入口。

另修复三城宿主的过场竞态：离场场景在过场开始后仍写 `set_field_return_spawn`，会把旧脚位置写进新场景payload。现在离场/重建/路由ID不同即停止写入。共享 `scene_router.gd` 与全局Field未改。

## 资源来源、路径和复用

- 7张新增原图：`assets/raw/sect_completion_20261030a/`。
- 原图prompt、真实模板预检及单次调用登记：`assets/staging/sect_completion_20261030a/production/`、`preflight.json`。
- 留白派生：`assets/processed/sect_completion_20261030a/`。
- 工程PNG与布局JSON：`game/art/modules/sect_completion_20261030a/`。
- [逐项路径、SHA与实际消费者](../../game/art/modules/sect_completion_20261030a/resource-pack.json)。7种新组件、26种实际复用贴图，按场景节点的真实纹理使用登记，不把无实例的ExtResource声明当作采用。
- [分类缩略图、点击放大](../equipment-skill-catalog.html#resources)；[资源复用总索引](../resource-reuse-index.md)。

新增为凌月双层竹楼/低竹舍/竹门/长棍架、烈云木石门/宽木厅/货舍。每张内置imagegen一次。只增加RGBA0透明留白，未裁剪、缩放、清alpha；原RGBA逐像素保持，原RAW A1留白失败保留。隔离导入的七张工程纹理逐RGBA通过。茗雾没有重复生图。

图鉴本轮新增21条原图/派生/工程路径，42个图与缩略图解码通过；5203条总资源（2896图/2307音），非resources数据完全相同。总索引1847文本来源，显式路径缺失0。

## 验证记录及失败保留

| 检查 | 结果 | 证据 |
|---|---|---|
| 沙漠四院、城门；西墙残余 | 6/0、1/0，自然退出0 | `assets/staging/town_layout_20261029r/town_project/review-r/court01.json`、`west03.json` |
| 赤岩三阶上下与非阶坎阻挡 | 7/0，自然退出0 | 同目录 `terrain02.json` |
| 正式沙漠城门 | 通过；整批formal05随后赤岩落点失败，整批FAIL保留 | `game/build/town_layout_20261029r_qa/formal05.json` |
| 竞态修复后赤岩实际上下阶、保存脚、进返屋 | 7/0，PID132060自然0 | 同目录 `formal06.json` |
| 新门派贴图RGBA、8阶双向、山门、保存 | 27/0，PID130900自然0；测试Image.load只读警告保留 | `assets/staging/sect_completion_20261030a/town_project/review/verify02.json` |
| 新物主路、双桥、水体阻挡与保存重开 | 9/0，PID120336自然0，空stderr | 同目录 `finish03.json` |
| 三个实际原地点加载、返脚、门户、NPC数及W移动 | 20/0，PID6024自然0 | `game/build/town_layout_20261029r_qa/sects04.json` |
| 原对话、条件锁与三个内院实际进返 | 17/0，PID111100自然0 | 同目录 `sects05.json` |
| 高台箭头动画持续对齐残余 | 10/0，PID133852自然0 | 同目录 `sects06.json` |

原verify01类型推断解析失败、formal05过场落点失败及旧截图全部保留；修后只跑残余，不重写旧FAIL。正式工程运行仍有既有7条Texture/RenderingServer退出错误，不能称空stderr；没有把这些旧错误抹掉。

正式截图及私有场景关键原图已亲看。只证明上述修改、通路、入口和画面；未宣称整城设计密度完全还原或所有剧情内景重新制作。

## 保护与当前状态

`assets/staging/sect_completion_20261030a/final-verification.json`：171个保护对象（其中162个存档路径）SHA/bytes/mtime精确相同；82项原生来源匹配当前manifest及registry固定SHA。保存原publication收据，末态另存，不把初始发布hash伪改为最终值。

三城registry当前AD875028、native_sources237DD4AD；门派宿主967606A9、三城宿主F28D97DC。新门派首次发布44个工程文件，含14个隔离导入叶；后续箭头改动单独保存在 `marker-before/`，原PNG不改。三城宿主竞态修复未有原mtime快照，不声称其旧mtime已经归档。

用户编辑器PID51856保留、自有游戏均自然退出；共享Router、项目配置、根tasks、原剧情资源未写。洛阳及林西并发任务的现状保留。当前停止本批已成功组件复测，供用户查看场景细节。
