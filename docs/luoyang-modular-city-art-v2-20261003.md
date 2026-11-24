# 洛阳分层街市美术第二步 · 2026-10-03

change-id: luoyang-modular-city-art-v2
owner: producer
status: limited-mechanisms-complete-visual-not-approved

## 本轮目标

继续用户要求的洛阳内部模块化制作。首版真实Field有限机制通过，但整体画面不通过；本轮先补地面与街市，不迁入正式剧情。

保留宽主街与公共回环，让客栈、军械铺和实体榜亭成为可辨识地标。地面增加磨损石铺、街沿及不同尺度的材质变化；榜亭、灯柱、货摊独立制作和摆放，不把高物重新烘焙到底图中。

## 分工和边界

1. art：持久化四项内置生图规格，新v2地面／装配源及素材来源合同。已有三栋原创建筑与CC0街树可按原SHA复用；其他旧失败资产不能覆盖。
2. system：新候选Field入口、独立资源合同及动态物理清单，等美术交付后串行实现。所有动作仍只记录，不执行剧情。
3. QA：独立新版本的路线、完整34×24脚底、碰撞、前后alpha、交互和状态保护测试；不继承v1通过结论。
4. producer：实际图片、源码和日志复核，串行运行内置生图与Godot。技术与整体视觉分别下结论。

不改共享Field、Player、Router、存档schema、正式v14、洛阳原四区SceneScript/layout，不写六份玩家存档，不导出Web／微信包。原v1源码、失败测试和截图全部保留。

## 验收门禁

- 真实写实素材、相机尺度一致、真正alpha，来源区分原创与外部CC0。
- 新高物全部配套语义脚底、导航与Y深度，不以阴影或alpha包围盒冒充实体占地。
- 主街、回环与门前站位完整净空；真实Field测试不能由源预测替代。
- 每轮新启动的实际退出码、stderr、截图和SHA可追溯。
- 整体画面仍空旷或素材不协调时，不切正式；既有正式文件及存档保持原SHA／mtime。

## 执行记录

已由主控实际调用内置生图，生成榜亭、灯柱、货摊三件透明独立物件，以及磨损青石ALBEDO材质。原图逐字节保存到`assets/raw/scene_module/luoyang_modular_v2/`和候选`game/art/maps/luoyang_modular_v2/source/`；工具未提供底层模型、费用，不臆造记录。这四件是原创生成素材，不能标为CC0。街树与岩石微法线／ARM沿用既有本地授权来源；岩石通道不冒称青石匹配PBR扫描。

独立QA确认三件物件真实透明背景，但均未满足提示词要求的10%透明边距，货摊底边另有13个alpha=1弱像素。原图未裁切、未阈值清除；实际脚底与占地按真实尺寸、语义实体重新登记。alpha证据位于`game/build/luoyang_modular_v2_qa/raw_alpha_audit_20261003.json`，不把该检查当作整座街市视觉通过。

新v2三份美术源、新候选合同／Field／runner及新QA准备中。正式21文件、v1候选51资源和六份玩家存档在QA准备阶段仍与独立基线一致，不以旧状态证明代替运行后检查。

## 首次捕获与否决

- 新builder check-only wrapper62108实际OS0，source-plan wrapper67780实际OS0；五条路线1441个中心、17鞋及34×24有限源预测0失败。这里只是源预测，不是真实Physics或输入验证。
- 首次GPU wrapper30304实际OS0，三条Image作者告警，无SCRIPT／SHADER／ERROR。日志位于`game/build/luoyang_modular_v2/{check_first,source_plan_first,capture_first}.{stdout,stderr}.log`。
- 11物件首合同SHA `09175C045E7ADE52E918E94FE229A9223B711C63A46991CB7D30A3006DC663F3`；树body及地面ON／OFF重复帧字节相同，实际石材sampler绑定、1254×1254与mipmap读取有独立证据。技术捕获不等于美术批准。
- 主控实际读取首`review_scene.png`：新榜亭／灯柱／货摊较首版完整，但外侧30%随机缺砖形成明显棋盘状空洞，亮石／暗底接缝反差过大，整体仍空旷。**整体视觉FAIL，不绑定给系统，不接正式地图**。已要求保存本轮全部产物，再改为连续铺地与大尺度连续边缘过渡；原素材、五路线、11物件和三NPC站位不改。
- 新真实Field／Space／实体点击／遮挡尚NOT_RUN，不能继承v1机制通过。

## 修正版冻结与真实Field有限验收

首轮30美术文件、3源码及9日志／证据共42项先归档到`assets/_archive/luoyang_modular_v2_capture_first_20261003/`，保留原合同和失败画面，不覆盖历史。然后去掉随机整块省略、降低接缝色差，改连续铺面和连续外边带；五路线、11物件、3原NPC位置、原素材不改。

- 修正版check wrapper57656／source-plan73032实际OS0。第二GPU wrapper65784实际OS0，仍仅三条Image作者告警。实际新合同SHA `948702C260994754A75C3D113848FC419A34E6C3A15E25A5BF7268500178867B`，50来源／产物、3源角色和7捕获角色绑定冻结；源码source `9D769F07…B3395C`、surface `A66CE8D8…B5C697`、builder `64D4F061…553BEA`。
- 新dev合同只替换待绑定SHA，最终SHA `F57C9EECFD4FD2991CCE35E913DDE24CF96A54D40BA113EC938868974D64355C`；Field `171C4F28…9A57F8`，runner `D13BBDED…1AC36`。全部交互只记录，不执行正式路线／剧情。主控源码审查覆盖外部layout与typed数组隔离、实际资源绑定、动态物件／物理集合及状态保护，不以编译代替运行。
- 严格导入wrapper85328实际OS0，保留wechat_stage嵌套工程WARNING；新QA check wrapper16868实际OS0无stderr。新QA main SHA `9ED87CDD30C43B82C874864BFB6C5E4CF10DE33DDCC4AC4DFBF3C516350F47C2`，probe `F36351860DF42354C4BAC39C8DCA7AB50F647A7802DDA0A7FC8CD9D20D5C79F7`。
- 新headless wrapper82284／实际engine67092、OS0，**737项／0失败**、141.349秒，结果`game/build/luoyang_layered_interior_v2_qa/run_1791035913_1582/result.json`，SHA `D0EB5792CEE89917504CBFC8F7F8122E1035C0376A0D3DA53B85642AF1F72A2C`。
- 唯一新Field GPU wrapper51512／实际engine41456、OS0，**896项／0失败**、176.099秒，53张1920×1080原PNG，结果`game/build/luoyang_layered_interior_v2_qa/run_1791036115_2467/result.json`，SHA `BDCF2A3F0592DB65E91CE00C4D8241CD97FEFDEB2218C2223C84098D4EDCFFBA`。两轮0SCRIPT／SHADER／ERROR，各59条Image／ObjectDB告警和2退出Timer ref1保留，不称无告警。
- 五路线20段716实际physics采样全部通过；完整34×24／875像素、17鞋和实际Physics2D共同检查。11物件均有真实止挡和各4次有限侧边绕行，22组当前idle帧前后强alpha与局部ghost union通过；三原NPC24自然帧、14组双输入case通过。四街树front仍各仅1强像素合法边界例，不能据此宣称所有站位／全部动画无错。
- 真实碰撞清单精确为11物件＋3正常NPC＋外围MapBounds，未知／旧guard-post为0。18条动作观测均dry/noexecute；门前检查与返回仅本地checkpoint，精确回到当次源脚点，不执行原南门→府衙剧情。完整导航／payload／玩家／队伍／任务／背包／榜单保持。
- 主控运行后外部78项核对0差：21正式文件、51旧v1来源／资产SHA保持，6玩家文件SHA／大小／UTCticks保持；headless后与GPU前也复核六档0差。全部owned进程已结束，仅用户编辑器PID36036仍开，不改它。新原图和来源合同未因测试变动。

## 视觉结论与下一步

独立QA收尾审计：`game/build/luoyang_modular_v2_qa/final_readonly_evidence_audit_20261003.json`，SHA `ACB217B3DDA52A64A2FCDEAC40BA3854D8748679DA80356D63023D341F089166`。复核两轮结果、53原图、冻结依赖、正式资源／六档和首失败42项归档，审计差异为0；范围仍仅有限机制，不赋予正式采用或全部截图视觉批准。

主控实际查看第二轮`review_scene.png`及12张新原Field图：entry、公共回环、货摊／西灯／榜亭／城门／树0各front和behind。独立物件材质比首版完整，随机缺砖消除，当前有限前后站位效果可用；但整座试样仍是大面积同质青砖加孤立建筑，缺连续沿街立面、院墙围合、街沿及成组生活细节，**整体视觉FAIL_NOT_ADOPTED**。其余41张仅核原文件SHA，未赋予视觉PASS。

下一阶段先按关卡空间设计补连续街区与院落，而不是继续堆散件；保留宽主街、回环和实体门前净空，重新导出并验证变化域。达到城市整体画面门槛后，再迁正式南门／府衙／南市／码头的原NPC、任务、商店、榜单及路由。原剧情／奖励／商店和通缉结算、非当前门禁flag、全动画／连续域遮挡证明、91地方场景和Web／微信导出均NOT_RUN。

独立开发入口（仅候选，不保存；Esc退出）：

```powershell
& 'F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe' --path 'F:/Code/RPG_GAME/game' --script res://scripts/dev/run_luoyang_layered_interior_v2.gd -- --luoyang-layered-v2-preview
```
