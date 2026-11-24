# 洛阳专用室内接入 · 2026-10-16 续轮

change-id: luoyang-distinct-rooms-20261016

目标：将上轮5张独立室内原图制作成具有完整家具脚座、通路、出生和返门的房间；优先绑定匹配的商铺外门，同时补专用门脸，不再重复任务/快返整组验收。

## 分工与边界

- ROOT：读现状、冻结几何/接线方案、保护原源和15保存、唯一运行Godot、看实际图、集成结论。
- SYSTEM：先只读旧room resolver/identity/source闭包与单槽驻留，然后经ROOT授权只写NEW室内resolver/数据及最窄生产接线；不得修改已冻结出版证明或canonical原文件。
- ART：读5原图，以1536×1024原像素标出地面/家具底座/可达功能点，NEW author-v2；独立生成当铺、布庄、铁匠3门脸候选。原RGB与rough hints完整保留，未知model/许可不伪称。
- QA：独立看几何与cover坐标，复用原normal input/Physics工具，制作有限新室内数据与代表往返测试，不写生产、不启动引擎。

## 读写与风险

读：current-progress、producer/system/art/qa记忆；20261015 runtime/bindings/home_author；20261016 resident/tasks；5原图及来源。

写：本轮NEW assets/processed、室内author-v2、NEW game房间数据/资源/resolver、经批准最窄Router/C等接线；ROOT文档及证据根 `game/build/luoyang_rooms_20261016_root01/`。具体生产写域待SYSTEM方案后批准。

高风险：公开room身份、来源首末、legacy body-center与1920 cover、返门精确脚点/驻留slot。不能借用旧房间身份与proof授权新几何；不能放宽34×24身体或+42偏移；不能将屋内黑背景当地面、桌柜顶当路。

## 验收

1. 每个类型真实不同PNG/功能布局，记录已接入与候选，正式原3类不可冒数量已超10。
2. 室内按真实落地家具脚座与地面polygon建导航，出生→功能点→出口完整≤4px身体路线可行；撞家具/越界负例保留。视图cover按真实比例，人物身体碰撞尺寸不跟图重复缩放。
3. 外门匹配功能、入口不在立柱/墙树；适用原城几何的门复用已过外场，不重铺整城。豪宅/仓房缺合法匹配门时明确候选，不能塞到档口凑正式数量。
4. 实际只做代表性专用营业空间/带工作底座/豪宅的短往返或候选房间；正常INPUT/Space、出生、实机家具遮挡/碰撞、精返及快返。实际达成几种以结果为准。
5. 原world/farm/旧PNG/import/出版manifest、15保存SHA/bytes/UTCticks不变，不停止用户editor108140/game90296。所有Godot由ROOT唯一启动，固定限域预算，失败原样保留不延长整夜。

## 已完成的限域检查（尚未正式）

- 三个专用门脸已各一次builtin生成＋一次定向编辑，v1/v2原字节均保留。Root逐张实看，功能材质方向可用，但灰雾halo与非零alpha外延未过完整透明边距，全部继续候选，不因图好看直接入正式。原图/完整prompt与来源分别见 `assets/raw/luoyang_city_expansion_20261016/facades_v1/`、`facades_v2/` 及 `prompts/qa/luoyang_city_expansion_facades_20261016/`。没有无限重生成/阈值擦像素。
- 五内景独立导入8176自然OS0，23设置与完整RGBA相等/5项通过；只新增精确PNG/import/ctex，无旧import写入。5Image提醒保留。
- 候选接线helper8C240E2E/C887A9D06/Router1877DF7C/FieldB472320B/residentCD5D3485冻结；普通headless动态加载Router/LM/Field can_instantiate全真，无SCRIPT；独立源码review限定通过，非GPU许可。原旧资源/proof及单槽内存上限不改。
- 五内景CPU实际65824自然OS0、602检查0失败/2840ms（原shared60s），result `game/build/luoyang_five_functional_rooms_cpu_20261016/65824_1682/result.json` SHA CD7DA081D4CA80A85E3BF60C3FB8392D4FDE12C8129A264372F960A69402D9C6。5源PNG/实际import/directctex全RGBA、5Scene全storage自建副本读回、52精确家具polygon、全路线<=4worldpx/连续34×24+round875+17/NPCapproach通过；80来源与15正确save_保存首末同。stderr仅ObjectDBwarning1，0ERROR/SCRIPT；不授Field/Physics/外门。
- 原912/07FA测试稿未执行，不伪造FAIL；保留精确副本，NEW8E3C只修实际save_路径/players_after、875圆整与候选solid域union，原鞋/路线/60s不变。

## 候选实际进出与默认接入

- 候选108892自然OS0，4300检查0失败/102739ms，固定180秒整轮、60秒到达、2000ms快返门槛未变。结果 `game/build/luoyang_functional_rooms_field_key_20261016/108892_2625631/result.json`，SHA E6C13910912FB9E7DF6A4E0406F5E13D7EB87EE7642F627EB5767A8635108BB1。1039来源首末facts及15正确保存逐同；ROOT与独立QA已看全部5PNG。
- 铁匠铺、布庄原门前真实56px INPUT→Space进入，独立source floor/13＋10家具CollisionPolygon、原生34×24/+42、875/17/Physics与NPC接近点通过；屋内正常INPUT/Space返回原门偏10px真实脚点，8个外场实例身份不变、0coldjobs，再16px INPUT可走。返场至Loading完全隐藏+can_move分别551.549/435.941ms。
- 仓房原门754,610及940,750→754,750→754,610路线真实Physics/INPUT通过，但door_enabled仍false，未入仓；当铺/豪宅仍无匹配外门。不能按5份数据计5新增可玩室内。
- 完整候选stderr125Image、退出resourceERROR1及ObjectDBwarning1、0SCRIPT，非clean/音频信用。铁匠4帧可见alpha脚较名义脚低约8px已记录，布庄近0，不冒全角色锚点完全一致。三次public近点定位26.049/20.756/21.353s，不称首次入城加载已解决。
- 原97364 parse拒例与5336独立oracle拒例均保全；前者ROOT错误在check失败后仍顺序运行actual，无Field信用；后者typed Array[Dictionary]未被无类型空数组替换，留下旧blockers被当矩形，非生产家具故障。2616纯诊断复现，23840显式typed empty修后五房均通过且原source52阻挡不变。NEW6F048仅修克隆适配并加强计数，不删检查/改生产导航。
- ROOT已完整备份false helper8C240E2E于 `game/build/luoyang_functional_formal_before_20261016_root01/helper_8C240E2E.source`，仅FORMAL_ENABLED false→true，当前3F2C16DA87F01F5B5B9C2F28CC355BA5C43715A337B96E1D57EE8B3193EF44ED。普通无candidateflag的单铁匠实测进行中；不重跑两房或仓房。

普通无candidateflag最终109012自然OS0，1673检查0失败/54129ms，单铁匠真实门往返536.372ms含Loading隐藏可动，1042来源首末/15实际保存不变。结果 `game/build/luoyang_functional_room_formal_boot_20261016/109012_2661370/result.json` SHA84503985CB9078CF0EDFC1E2144CE3958AED7C3BC75E4ABABF437486FAE7B43F；ROOT实看2PNG，propercheck先独立0再actual。完整317行stderr45Image、退出resourceERROR1/ObjectDBwarning1、0SCRIPT，非clean/音频通过。外层195保护与本轮implementation首比较仅Router/C/Field三项授权变化，其他192含15真实保存存在/SHA/bytes/UTCticks不变；resident另有完整旧源备份与1042来源绑定。用户editor108140/game90296未停。

独立QA最终LIMITED PASS：1042来源facts/15保存逐同、2PNG实际重核，原2320,884脚与返后16px正常INPUT通过，公开定位ready25.963s仍慢；仅该单门普通默认及已过两候选门，不授全城。QA记忆SHA8FE2089471B9789E7B5D801821134D642CA41CF018BB4E4F5551B30109B6B2D2。git diff --check仅旧experience-log中config_version/format/randi_range段尾空白报错，非本轮新增，保留不清理；CRLF提醒亦保留。

状态：两匹配外门已正式默认接入，可重启普通游戏试玩铁匠铺与布庄；五房数据/导入完成但仓房禁用、当铺/豪宅未外门。当前原3＋新增2＝5种正式内景，11+建筑/室内、更多居民与四区丰富度仍待；本轮未改世界/农田/旧canonical资源，未宣称首次入城秒进。
