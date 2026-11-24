# 洛阳外场重排与室内真组装 · 2026-10-16b

change-id: luoyang-assembled-scenes-20261016b

## 本轮目标与纠正

用户实际截图 `C:/Users/rajqiu/AppData/Local/Temp/codex-clipboard-9d412398-26b6-4003-ae59-648273442d1c.png` 显示人物叠在铁砧/木墩上。上一轮只做家具落地碰撞和两内景接入，整图仍没有独立前景家具；不能将脚座Physics通过称作遮挡正确。衙门外院和南市没有实际重排，用户指出整体没变化属实。

目标：①铁匠空房底图与6类独立家具组装，visual占据/地面solid/深度脚点各自明确；②衙门外院主轴＋照壁/侧值房/告示/庭院与两侧动线；③南市主街＋连续铺面/宅院/摊群/货运侧巷，实际移位不只加装饰。

## 读写与职责

- ROOT producer：读AGENTS/进度/规范/角色记忆、2D关卡空间与环境叙事参考、imagegen及code-review技能；冻结范围，保护保存，唯一启动Godot，审源与实图。写本记录/根证据/进度记忆，不直接写跨模块实现。
- SYSTEM唯一实现写权：NEW assembled room/city author、Scene/layout、runtime helper/publisher；最窄Field/C/functional resolver接线。旧源先完整备份，旧历史manifest/result/PNG/import不覆盖；Router/LM/resident默认保持，有需要另报。
- ART：NEW builtin空房shell＋6独立透明家具，原图参考固定相机/材质；现役外院/街面模块审计与NEW布局几何建议。7次首稿＋至多1次明确问题定向编辑，不无限循环；模型未披露不写指定模型或CC0。现成资产保实际来源。
- QA：独立审user截图与源脚座；只NEW有限视觉/Physics/主路/门户检查，禁止写生产或启动引擎；不重跑上轮任务/双房/全六，不再堆层叠守卫代替看图。

## 实现约束

室内旧家具必须从底图移除，不能在旧家具上叠同一个Sprite。每个新物件应有source/alpha、render尺寸与ground anchor、visual占据、脚底solid、depth foot。角色34×24/+42不缩小；家具高处不能按全visual bbox一概当阻挡。独立Sprite的排序/淡化需真实看到前人后物、后物前人，出生至功能点/出口可走。

外场采用NEW来源绑定/几何/出版记录，不用旧通过证明授权新位置，也不借旧proof禁止真实重排。旧NPC身份/任务/门户动作保留，必要位移有显式delta。关键门与角色足点不可夹树墙/堆摊；主街宽、支路窄，庭院与商区可辨。

## 验证范围

1. 新素材实看/透明边缘与源尺寸，独立隔离导入；原图保留。
2. 新room正常门入、砧前/侧后实际INPUT/Physics与对比图、原门快返；两外区overview与各一条主路/关键门户及任务脚点。
3. proper check成功后才actual；固定短范围，不整夜循环。15玩家文件存在/SHA/bytes/UTCticks保持；不停止用户editor108140。本轮初观察仅该editor，旧game90296已不在进程列表，非ROOT停止。

初始保护见 `game/build/luoyang_assembled_20261016b_root01/guard_before.json`（195有限路径）。本轮尚未交付新正式场景；完成情况以末尾实际结果为准。

## 已定位与当前制作证据

- 除背景家具不可独立遮挡外，旧铁匠房使用legacy Player origin，scale1.18时名义视觉脚偏移80.2872而碰撞child42，差38.2872worldpx。用户截图不能仅据红框证明穿入旧solid，视觉脚错位加永远在角色下的烘焙家具就会造成踩台观感。新房明确feet=true，经已有set_ground_anchored把child置0、sprite对齐；只对NEW房间，不全局改Player。
- builtin imagegen 7次首稿、0次额外编辑，原字节复制到 `assets/raw/luoyang_assembled_20261016b/`，完整prompt集在 `prompts/qa/luoyang_assembled_20261016b/`（最终实际路径以ART README为准），provenance580D3BED。shell已清全部家具；6件独立组件接口148A6385，sourcefeet/groundfoot/visual occupied/ground solid分开；砧80/桶75/台83/架151/风箱127/炉327 source高，避免家具比人还大。
- ROOT与ART实看原7图及正常alpha over棋盘诊断：view_image原透明图会显示A0隐藏RGB的灰晕，不等于真实合成halo；正常合成干净。A1边噪和严格10%非零alpha边距失败仍保留，不改/擦alpha、不冒全部边距通过。离线assembly_DIAGNOSTIC只艺术布局，不是Godot图。
- 7图隔离import110492自然0，实际verify112440自然0/7项0失败，23参数+全RGBA保持；report293121F6。14个新import/ctex目标原不存在，SYSTEM File.Copy(false)逐同复制，旧imports不动。
- 第1城市CPU actual107908（console launcher100808自然1）49528ms：court_loop在[992,1280]被新布局阻挡，0区出版。原author70BA/helperB3CB/publisherA083/result完整保留；只准新路/布局修复，不缩身体/放宽875或延长120秒。此时Root195对implementation首仍零差；不授外场可玩。
- 薄测试草稿20E6 propercheck拒const PLAN非constant，未actual；NEW最终稿运行期PLAN，保原拒例。不复旧4300/1673层叠测试链。

## 数据通过、实机首次拒绝

- 城市retry2 CPU出版78428自然0/63.104s：衙门20→24、南市26→30物件，2626＋4090路线中心按完整身体875＋17/4px检查；新增walk从原raw减去新solid完整重建。manifest分别517A0E68/EAC64463，来源917项。只是数据出版，不授实机或艺术。
- 独立铁匠组装CPU15492自然0/105检查0失败/1069ms：7图全RGBA、6sprite/6solid、9路线935中心、3站位、负例砧座与全storage通过。2新walk隔离import/verify110996自然0，完整RGBA与23参数保持。生产三旧源完整备份后最窄hook，Router/Loading/resident不改，两个FORMAL仍false。
- 独立REVIEW源码通过37＋32叶/父子完整校验/取消join/搬门返脚/feet与家具排序；源码动态load自然0，不授实机。
- 8B0055测试propercheck因line258 Vector2i/Vector2比较自然1，未actual；NEW D6C946只显式integer尺寸，proper0后唯一GPU110284（startticks639277193048066500）自然OS1/1000检查2失败/86.367s。新child在全published record比较拒绝，public准备FAILED，0图、未入室，不冒布局或遮挡通过。完整result与stderr保留，7旧退出textureERROR非clean；SYSTEM正限域定位具体字段差异，不删比较、不延长原预算。根195保护与implementation首仅C/Field两授权旧源变化，其余193含15玩家exactticks不变。
- 纯CPU诊断85100自然0/214ms唯一复现objects[26].render_size_px[1]，native245.75999450683594，原manifest文件字面仍245.75999450683594，JSON.parse读回变245.7599945068359；诊断只重放published parent，明确非实际live parent证明。NEW runtime E751A55C只将完整native记录经原publisher相同JSON.stringify(完整精度)/parse后严格全字段比较，不加epsilon/删字段；原生record继续用于实际raster/875/17/Scene。独立REVIEW通过。NEW薄key F0417172增加独立同域全字段、roundtrip、真实1px改动/新增字段拒例；原D6及110284失败保留，proper0后21700开始同120秒scope（startticks639277200076137502）。
- 21700最终自然OS1/1000检查2失败/87.165s：已过完整record与原始重建像素/87517，随后严格Scene storage比较拒绝；0Field/0图。7916/28916/24996三次短纯CPU均proper0后自然0，最后一次952ms一次收齐两城9叶差异：南市两新树各3、外院一新树3，只在collision_size_px/physical_center_px（真实物理转Vector2的两字段）。ResourceSaver文本缩写后Float32原生位全部精确相同，未发现真实物理变化证据；其余全storage原判据无差。诊断仍非live parent证明，不冒GPU通过。下一限3新树/两字段的精确原生位适配，不修改旧C比较器、不泛化epsilon；最后一轮关键GPU若仍拒就如实保候选，不无限循环。
- 最小adapter2350382B明确3新树ID＋donor/oldfoot/newfoot/scale完整绑定，两个物理Array2仅finite Float32逐字节比较；其它所有storage沿原C严格判据。runtime BDDE1212/binding0EEFE2FC（只增新adapter来源叶），旧E751/A144完整备份。2656两城CPU proper0后自然0/1042ms，14项正负例通过，含1px/1原生ULP/Array数量/transform来源/author/无关spawn拒绝，9源首末SHA同。result A435B18D，原SER原始false仍记录；纯重放信用，不冒实机。

## 最后候选实机通过与默认接入

- 最后薄key91F27CF8 proper0后108472（startticks639277210903689116）自然OS0，1113检查0失败/95.942s，未加长原120/60/2000/alpha12。result `game/build/luoyang_assembled_scenes_key_20261016b/108472_2508/result.json` SHA FBC52A4563EEF3A816094ED4FEF8F5D01C263A7479FA314B4682BA84792D35E1。
- 两真实public近门setup：南市26.346s、外院31.189s；各新whole-record/原生Physics/短正常INPUT/可进入门户通过，不授长途或秒加载。两整城图用明确QA临时Camera2D .5总览，普通camera/玩家脚点精还原，不冒普通镜头游走。
- 南市真Space进入NEW铁匠空壳＋6sprite/6solid，原34×24身体/child0/名义脚点齐；4自然idle可见alpha脚差+1.6727，4站−9.4783，都在原12px限。砧前/同脚侧/前复原alpha1，背后.55且native排序翻转；22tick真实UP碰撞后停稳、砧心真实shape负例拒。原门Space返回同一Field/原脚[2320,874]，Loading隐藏+可动535.477ms，0cold重建。
- ROOT与独立QA均逐看6PNG。限定结构方向可供用户试玩；建筑/灰铺重复、外院两处旧悬空树影、完整园林/正式侧值房形制仍待，不授全城艺术或11+室内完成。完整652行stderr98Image/7旧退出texture/RenderingServer ERROR＋1ObjectDBwarning/0SCRIPT，功能PASS非clean/Dummy不授音乐。980source和15保存首末完全相同，ROOT195对首仅C/Field两授权变化，193其它含15玩家exactticks保持；旧69source只functional resolver授权变，其余68保持。
- 两false完整源码已精确备份到本轮root01，ROOT仅两行bool true：room8272B480 / runtime73E09F2F；旧6E2D/BDDE与旧失败均保留。默认实际单门短测仍待，未借candidate替普通模式。

## 普通入口最终实测

正式单门稿C113B999完整审读、proper0后45860（startticks639277215656683742），无任何candidate flag，自然OS0/2011检查0失败/55.577s；独立90秒预算仅普通南市近门出生、46px正常INPUT/原门Space、新组装room真脚点出生、87517/Physics/1GPU图。984source及15保存首末保持。result `game/build/luoyang_assembled_formal_entry_20261016b/45860_2451/result.json` SHA 9A958E4144DD7515337AAE012F2AF31AB061665255B64E9628965696FCB76C0A；ROOT已看正式出生PNG6F6B56B8。不重跑return/三站/外院，沿用本轮候选对应实际证据。完整stderr仍有Image、旧退出texture/resource/ObjectDB告警，非clean，不冒音乐/全城美术通过。

默认版本已可重启普通工程试玩：衙门外院、南市新布局，以及南市铁匠铺的组装房间。最终195有限源对implementation首仅C/Field2项授权变，其余193存在/bytes/SHA/UTCticks完全同（含15玩家）；旧69室内源仅functional resolver授权变，其余68保持。最终只剩用户editor108140，测试进程均自然退出，未停止或重启用户程序。根证据 `game/build/luoyang_assembled_20261016b_root01/`。结束本轮实机验收，下一主要制作更多差异化街区/室内，不再扩测试链。

独立QA末审限定PASS：正式984source/15保存与solebool全文差异成立，唯一正式PNG完整SHA匹配并实看；public实际ready27.403s，不冒秒进。完整302行stderr44Image/8退出ERROR（7texture/RenderingServer＋1resource）/1ObjectDBwarning/0SCRIPT，原因未唯一定位、不扩测。候选对应652行98Image/7退出ERROR保留。根最终acceptance.json归档，69旧房源再次实核与after快照69/0差，15保存不恢复/覆盖。
