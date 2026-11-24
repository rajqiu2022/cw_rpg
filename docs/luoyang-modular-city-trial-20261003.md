# 洛阳城内部独立物件试样 · 2026-10-03

change-id: luoyang-modular-city-trial-v1

## 目标与边界

用户要求城市内部改用新版大地图的分层制作方法，先尝试洛阳。此次是城市内部人尺度试样，不把世界地图缩略城池放大，也不再生成包含所有房屋和灯柱的整张运行背景。

- 地面：无建筑本体的等比例石铺街道、街沿与公共空地。
- 物件：城门、客栈、铺面、榜亭、灯柱、树各有独立RGBA／来源和脚底合同。
- 导航：地面支持区与建筑占地／门柱／小物脚底阻挡统一登记；门前公共站位必须完整净空。
- 渲染：实体按实际脚底Y和同档兄弟顺序排序；只有被实体alpha覆盖的角色像素显示局部剪影，不靠大矩形让整个人消失。

先制作一张3072×2048连续的城门—南市空间试样：南侧入口、中轴宽街、北侧公共广场、两侧客栈／商铺与一条回环支路。出生在门前石路，不在房屋／桌面。保留现有主角.91试调成人尺度，不以放大屋顶缩小人物掩盖比例。

正式洛阳已有南门→府衙、府衙→南市、南市→南门／码头等连接。试样直达南市只验证新空间动线，不冒称原南门→府衙流程已经改造；不得自行改现有任务／NPC／商店／榜单action或剧情。

## 分工与读写

- producer：设计与实际素材／画面审核、内置独立资产生成、本文及项目快照。
- art：新luoyang_modular_v1地面、物件捕获／装配源、来源清单；不覆盖旧冻结素材。
- system：独立开发Field入口与候选合同；外部layout和数组必须隔离。共享生产Field／Router／存档不改。
- QA：独立脚底、物理、输入、遮挡和存档不变验收；不继承world v14／郊外2499旧结果。

GPU任务仅主控串行批准；不停止用户编辑器。当前正式地图、洛阳各区和六份玩家存档都不替换。

## 最小验收

1. 原地面不含重复烘焙建筑，独立物件边缘真实透明、视角／光照一致，房门与成人角色比例可信。
2. 主街与回环完整17鞋通行；建筑／门柱／水体不能走上去，独立灯柱等止挡与绕行都可核查。
3. 真实field_walkable加载候选，正常移动与Space／实体点击执行；候选范围内前后脚底排序、当前格局部alpha有实际证据。
4. 门口、榜亭、店门前的可站点与交互距离配套，不用原图偏移箭头冒充实体门口。
5. 新启动headless与GPU证据分开；代码编译／预测通过不代表画面通过。

## 当前状态

已完成现有资源探索，并以Codex内置生图生成独立城门、二层客栈、单层铺面三张1536×1024候选。原图与提示词记录位于`assets/raw/scene_module/luoyang_modular_v1/`，候选工程副本位于`game/art/maps/luoyang_modular_v1/source/`。主控已逐张查看；RGBA抽样确认背景与门洞存在真正alpha=0，实体多为alpha252／253，弱alpha边缘、门洞和人尺度尚需装配复核，不把生成成功当作美术验收通过。

旧村落建筑组件部分视角／风格不适合城市，本试样不使用缩略城池或旧整图替代内部独立建筑。已完成原生石板地面、三建筑、四授权街树、两灯柱、一榜亭共10物件的首版GPU导出。地面不烘焙建筑本体，三原生物件prototype及地面ON／OFF重复帧逐字节一致，权威导航为同相机独立支持平面加语义脚底阻挡。

根实际运行：builder check-only exit0；source-plan实际OS0、五路线1441中心的17鞋与34×24矩形预测0失败；首GPU实际OS0。仅三条原始Image读图作者告警，未见ERROR；日志`game/build/luoyang_modular_v1/{source_plan,capture_first}.{stdout,stderr}.log`。这些是源预测／资产捕获，不是实际Field输入通过。

主控实际读取`review_scene.png`、`floor.png`、`native_notice.png`、`native_tree.png`：三独立建筑素材方向可用；但大面积同质灰砖／空铺广场、基础几何榜亭和灯柱不符合正式城市质量，**整体视觉未批准**。原生街树只证明真独立来源，不能据此称城市已经丰满。此版本冻结作为有限普通Field机制试样，不继续覆盖失败产物或转入正式。

尚未接入正式洛阳；现有NPC／任务／商店／榜单动作身份在开发Field中只记录，不执行剧情副作用。首次有限Field创建被旧归档Player类冲突影响，不计载入通过；修复精确归档扫描隔离后，真实Field首轮515项仍有5项失败，不能作为最终通过。正式21文件SHA仍与本批启动前基线一致，详见`luoyang-modular-city-trial-production-baseline-20261003.json`。六份既有存档SHA、mtime和大小亦未变，独立快照见`luoyang-modular-city-trial-save-baseline-20261003.json`。

## 系统预检与失败保留

- 三个新dev文件为contract／Field子类／独立runner，不改正式Field、Router、四洛阳SceneScript与layout。复制必须显式隔离外部layout及STORAGE数组。
- 主控源码审查修正canvas读取字段、start_preview失败退出、实体鼠标当前格／flip／region、HUD按钮禁用和NPC站位不占五条验收动线。父setup只会写两项临时Router状态，dev作用域精确恢复这两项；不调用会将冷启动12坐标版本迁移到正式14的公开加载接口，也不还原其他玩法状态以掩盖副作用。
- 初次独立Field check-only因无autoload上下文出现Identifier缺失，不计编译通过；首次source-check PID85540虽OS0但stderr存在Player类重复错误，同样不计通过。根因是旧QA证据目录中归档的`game__scripts__field__player.gd`被扫描为全局Player。仅新增该精确目录的`.gdignore`，原证据和正式player未改。
- 首`.gdignore`后strict editor import PID54404实际OS0（保留wechat_stage嵌套工程WARNING），但类缓存继而指向另一旧retry1归档；source-check PID6236和有限smoke PID71624虽OS0仍有Player重复ERROR，后者玩家未创建，不计任何Field通过。PowerShell混合object输出格式曾把错误摘要显示为空，主控复读原日志更正，不以OS0／ready信息替代stderr核对。
- 冷启动前后完整导航／Router payload／玩家／队伍／任务／背包／榜单及存档状态相同，但这不能补足未创建的真实角色。已要求精确旧归档目录补`.gdignore`并在runner增加真实Player fail-closed门禁。日志均在`game/build/luoyang_modular_v1/`，首次失败未覆盖。

## 真实Field首轮与碰撞因果

- 三个精确旧QA归档目录仅新增`.gdignore`后，strict import PID85076实际OS0，全局Player缓存恢复正式`res://scripts/field/player.gd`；新实体smoke PID38496实际OS0，真实Player、34×24完整矩形、三NPC及十物件均存在。保留Image作者告警及嵌套工程warning。
- 首轮真实headless PID31496实际OS1：515项／5失败，107.445秒，结果`game/build/luoyang_layered_interior_v1_qa/run_1791029719_1562/result.json`。五路线中回环一段失败，客栈／铺面侧边绕行及军械铺掌柜站位被物理阻挡；另外一项是测试把DOWN有效身高参考错误套到当前RIGHT。正式状态／六存档／21生产文件／51素材均保持。原测试及helper SHA `8D218AA9…`／`137937DC…`冻结，不覆盖失败。
- 十物件当前帧实际前后排序及alpha局部剪影通过，但树前景合法样本仅有1个强alpha像素，不能拿有限域数据宣称所有站位／全部动画无错。门槛Space与实体鼠标、精确源脚点返回及原动作身份只读记录通过；原洛阳剧情、榜单结算、商店／奖励和正式路由仍NOT_RUN。
- 新只读诊断PID32288实际OS0，4个自然阶段snapshot一致：原南门`Collision_left_guard_post`（中心583.68,1054.72／552.96×430.08）和`Collision_right_guard_post`（中心2503.68,1054.72／506.88×430.08）仍在试样物理空间，造成上述四项真实阻挡；不是NPC过大、查询变换错误或新导航安全边缘问题。证据`game/build/luoyang_layered_interior_v1_qa/physics_cause_1791030317_1538/physics_cause.json`。上侧掌柜点仍正确被新`LabPhysical_shop`阻挡，不能顺便清掉新建筑脚底。
- 只允许dev候选隔离旧碰撞修正和新QA版本按真实朝向校正有效身高，不允许挪公共路线、缩小完整脚底、放松物理oracle或更改正式资源。以下最终新进程通过有限机制，整体美术仍NOT_APPROVED。

## 最终有限机制交付（不采用正式）

- 新dev合同SHA `77E2FF231557CABF122895E3040BEC6B2808D3487E9916A008DB9C69A6841ED5`，Field子类`90B5AD1C93FC1911042F82AE46A371ECB3821D991DC4C28654F3EFFD3D1FF434`，runner `0CE8D2BC92AA6DF4D6B76DE237A2F7B8D831B267F1A05A5E5515630559E20557`。复制隔离后对typed Array就地清空并复读，所有9项scene／13项layout字段逐一验证；仅候选数据变，不改正式源。
- 主控source-check wrapper PID49756实际OS0／0ERROR，实际22项before／after证明blockers2→0、walkable_regions3→0、occluders1→0；15条Image／ObjectDB warning保留。这只是source gate，不把它代替Field。
- retry1真实headless wrapper11812／实际engine77376、OS1，547项／2失败，原记录`run_1791031220_1592/result.json`。仅新QA外边界期望写40×2048，父控制器实际为40×2088（上下各20px margin）。保留该版本失败，另建retry2仅修精确期望，不改物理体或阈值。有效高度改按真实当前朝向原PNG SHA及实际Sprite scale严格比较，保留原失败源。
- retry2 main SHA `73569029AFC73B0D76BFDC43FA0E3891A774BECF12F2B529D14D6E8FC9A3A83C`，probe `7368020796DA1541C9ACEA464613AD40C6591E278DDF6D9F34506C506002304E`。主控headless wrapper49996／实际engine78228、OS0，547项／0失败、162.248秒，结果`game/build/luoyang_layered_interior_v1_qa/run_1791031470_1614/result.json`。
- 唯一实际Field GPU wrapper23744／实际engine68572、OS0，697项／0失败、194.599秒，50张1920×1080原PNG，结果`game/build/luoyang_layered_interior_v1_qa/run_1791031722_2412/result.json`。两轮均0 SCRIPT／SHADER／ERROR，各62条Image／ObjectDB warning、两个退出SceneTreeTimer ref1保留。console包装进程ID与结果内真实engine PID分开记录，不混为同一进程。
- 两轮均完整五路线通过（本段716真实physics采样）、十物件脚底止挡／有限四侧绕行、20组当前帧前后alpha正例、三原NPC各8自然帧排序、14组正常Space与实体鼠标只读动作记录通过。真实碰撞清单精确为10独立物件＋3正常NPC＋外围MapBounds，未知／旧guard-post为0；34×24完整脚底与875像素／17鞋／实际Physics共同验证，不以单点可走替代。
- 原门槛两种输入只在试样内移动，原南门→府衙action不执行；返回当次源脚点(1536,1660)精确。六真实存档行为后及cleanup后SHA、mtime／normal slot不变，完整Router／玩家／队伍／任务／背包／榜单保持，21生产文件及51素材／来源冻结。QA独立只读复核两结果、6执行依赖与50原PNG逐SHA一致。
- 主控实际查看11张原Field图：entry、公共回环、客栈front、城门behind、门实体mouse、商铺front、榜亭behind、东灯front／behind、树0front／behind。**整体视觉FAIL**：单一灰砖／街市留白、简陋榜亭与灯柱、建筑与地面缺统一接地／环境细节，不能晋级正式。不是对剩余39张图赋予视觉PASS；四树front仍仅1个强像素边界例，不宣称所有站位／所有动画无错。

## 运行与下一步

独立开发入口（使用本机Godot；不会保存）：

```powershell
& 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' --path 'F:/Code/RPG_GAME/game' --script res://scripts/dev/run_luoyang_layered_interior_v1.gd -- --luoyang-layered-preview
```

Esc退出；全部交互只记录。三建筑为原创内置生成RGBA，街树为现有CC0来源，地面／基础灯柱／榜亭为项目原生制作，不能把混合资产统称外部CC0。

下一步先补真实石铺材质、街沿／墙围合、摊位与生活物件、完整榜亭／灯柱，保留独立脚底和RGBA合同。新素材／新布局须重新导出并实测，不继承本次素材审批；之后才迁移正式南门、府衙、南市、码头的NPC／任务／商店／榜单及存档路由。原剧情／奖励／商店执行、非当前榜单flag状态、完整城市回归／全动画／连续域alpha缺席证明、91场景和Web／微信导出均NOT_RUN。
