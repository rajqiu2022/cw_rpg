# 林西村外山道模块化改造 · 2026-10-30g

当前状态（30h更新）：30f+g已联合正式合入，Router `21CAF866`，native151/registry `E7045064`。30h随后保持原山道业务/道路与宿主，仅更新竹林与洞肩地表并增加村内人物/房屋比例修复；native162/registry `AA3FDF3B`。以下“待合/未获许可/只check-only”是早期计划，已由末节实际记录取代。

## 用户问题与边界

截图实际是原`ch1_s1_road`，显示名“林西村外 · 山道”，仍使用`bg_ch1_s1_road_cave_entry_v2.png`整张背景。上一批六个村港室外不包括此路段，不能把林西村内已改冒作山道已完成。

目标是新4608×3456模块化山路、竹林、灰岩围合和洞前岔路，接原地点，不增同名World入口。继续合入未正式的30f：师徒院成人尺度、阶护墙、后院草路与三类小地图头像。原入口、NPC、任务、对话、遭遇和各锁门条件保持，不新编剧情、奖品或怪物。

## 原业务核对

当前scene实际引用`ch1_s1_road_layout_v5.tres`，schema2；不能拿旧v1/v2路线做实现。五个portal rows只含三个实际目的地：

- 林西：`return_to_linxi` → `linxi_village_center`。
- 竹尾同北口有检查/复命对话/实际旅行三阶段，`defeated_thug_lone`、`master_training_done`、`ready_for_zhuwei`按原逐row保留。
- 洞口：`bandit_cave_entry` → `interior_bandit_cave`，要求`rumour_bandit_cave`，原标签为“山寨洞窟”，不是新增矿洞业务。

原四map交互（石碑、拓碑、尸体、冷灶）、四动态视觉（碑、尸体、宝箱、任务药草）、条件商旅NPC、两遭遇组/620步距/.16概率/`master_training_done`原样消费。map存在时仍以v5整套替代旧legacy trigger/hotspot，不把尸体改成走近就自动战斗。首次intro的三个节点、flag与主线任务副作用保持。

## 实现拆分

- 地图/专用Entry与Field：`game/build/linxi_mountain_road_20261030g_system01/`。直接继承正式MainField，保移动计步和遭遇/动态visual；不借不完整处理此业务shape的原生预览host。
- 联合30f+30g必要来源候选：`game/build/linxi_road_portrait_20261030g_source01/`；旧30f F3674FB9闭包、各首稿和修订候选均不覆盖，未部署的边不算正式历史。
- QA：`game/build/linxi_mountain_road_20261030g_qa01/`，只本批静态几何、编译、明确原业务字段/条件和文件保护，既有旧成功不复。

单road版本3003隔离于30f师徒院3002及其余六村3001。原scene/layout不写，在运行时深复制和精确重映脚点，原来各target及任务门槛不改。共享注册器只为精ID新增专支，`get_field_scene_path`也返回实际专用Field，不能只改正常dispatch而让其它调用退回旧TownField。

## 资源策略

现有灰岩/竹丛/地表优先定向复用，不把旧大图裁成模块，也不放大低清PNG。唯一缺口是完整自然灰岩洞口，Root使用imagegen技能内置生成一次。

- Prompt：[cave_mouth_v1.txt](../../prompts/linxi_mountain_road_20261030g/cave_mouth_v1.txt)，纯模板dry-run通过、0网络/API调用。
- RAW：[原图](../../assets/raw/linxi_mountain_road_20261030g/cave_mouth_v1.png)，1536×1024 RGBA；原边缘128留白失败/maxA254均保留，不伪造原图PASS。
- 仅按用户永久许可清主体框外551个alpha1点、四边补128透明留白，原RGB/保护框RGBA精同，1792×1280、不缩图；[像素收据](../../assets/staging/linxi_mountain_road_20261030g_art01/authorized_processing_ACTUAL.json)。
- 工程：[cave_mouth.png](../../game/art/modules/linxi_mountain_road_20261030g/cave_mouth.png)，SHA8AAC2550。透明像素隐藏RGB在预览工具显示的灰雾，不据此擦除主体/改变高alpha；须真实叠地预览确认。

## 验证边界与进程保护

用户后台游戏139344仍在、编辑器51856保留，未获代停许可，不控制/停止它，也不向其注入输入。**普通源码/布局修改可以继续**，本轮另备“保留用户进程、只读采证”的source/save基线，不假称游戏已退出；若存档在用户游戏中改变，报告保留现值，不恢复或声称旧基线零差。

新源码只用`--check-only`强制preload编译，不执行正式Field/SceneTree逻辑；素材只用无autoload独立工程导入/纹理验证。静态SAT与源码编译不代替实际Physics/剧情往返/ART；正式游玩效果交用户重新运行验证，不为此阻塞合入或重跑旧全城。

待补：最终来源头/30f+g合入、实际编译与隔离素材原始结果、目标源和171存档当前元数据保护事实。早期几何失败保留，未执行的测试不记PASS。

## 实际合入与收尾（30h补录）

- 30g联合闭包receipt `78185366`，Root以apply_patch合30目标；三处只CRLF/EOF规范化前全文归一相等，最终各SHA精同。Router `21CAF866` / native `068F3E61`151 / registry `E7045064`；30f未部署候选边未另冒历史。
- 首const preload/check-only因autoload标识未注册而失败，即便进程exit0也保FAIL。改普通项目autoload资源解析：46检查/40资源通过，0Field/Actor/Input，不等于游戏物理。
- 新洞口独立无autoload单纹理41/0、原PNG/整RGBA精同，三新import叶精晋升；图库5220→5223，仅3路径/3缩略，旧记录保持。
- 正常图首62392因PS5环境Get-FileHash失败，0Field/0图，原FAIL保；仅改实际pwsh绝对路径的新02进程98012自然0、170/0/0Input。真正推进原intro三节点，原seen/主线/rain副作用保；两张1920×1080原zoom图，公开near setup而非连续步行/World旅行。
- Root接受成人洞口和真实头像，但拒旧青蓝竹块与灰色洞前岛的ART。30h另生一次自然绿竹，13丛代33丛，退竹连体退；地表重叠收口，原任务/门槛/道路未改。详[30h](linxi-adult-building-scale-20261030h.md)，不把30g技术通过洗成整图美术通过。
- g末guard `10FDA712`核30target/30backup/67保护/14新叶/15输入/171save精SHA、bytes、UTCticks同。用户随后授权只停止139344，Root核精命令和父51856后执行；编辑器不动。旧七纹理/RenderingServer退出ERROR与ObjectDB警告保留，不宣称stderr干净。
