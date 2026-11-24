# 新版九区大地图制作与正式接入

本轮目标是完成4608×3072连续分层大地图，替换正式`world_map_jianghu`的旧v12资源，而不是继续交付双区开发试样。2026-10-03已实际激活并完成新进程完整正式回归与当前截图复核。

## 2026-10-03 最终交付：正式 v14 已接入且切换后验收完成

- 正式 `game/data/scenes/world_map_jianghu.tres` 使用 v14 layout、九区 streamed background、原进入对白与 BGM；4608×3072、3×3连续地形、30道路、280独立原生模型实例（运行布局共370物件）与16既有入口。CC0外部模型／扫描地表与原创地标混合制作，许可记录保留，不把原创地标改称CC0。
- 新进程正式FULL：030936 launcher继承冻结068D，headless实际OS exit0／106167项0失败；GPU实际OS exit0／107961项0失败，592张原PNG。结果分别为 `canonical_headless_1790956805/result.json` 和 `canonical_gpu_1790957788/result.json`，不使用candidate参数。
- 16真实入口往返、12跨区输入、16168完整脚底中心、1386681天然水面禁走；战斗胜负／撤离回程、旧坐标迁移及M概览由完整套件覆盖。独立物件的碰撞、脚底前后排序和当前帧局部ghost共同验收，海面／城池实体不作为普通行走地面。
- Root实际读取本次52联系页：四批分别50／127／330／85张，按原路径与SHA去重恰好592／592，0遗漏／0改动；另实际读取九区原1920×1080图和6张代表原图。当前画面结论 `PASS_WITH_DOCUMENTED_LIMITATIONS`，不是测试自动签视觉。具体页与SHA见 `game/build/world_map_v14_qa/root_canonical_0309_completion_20261003.json`。
- 独立review只读核完73份新alpha JSON与72自然NPC ticks：32唯一四向idle0拒站域共128方向零未决，9正例完整脚底／物理／当帧像素成立；NPC四格0～3、60同band的22前／38后排序正确，另12真实跨band。1942批准资源0差异，403旧文件仅正式场景一个预期变化，六份玩家存档与其余ABSENT槽均未写入；09FA原正式图逐字节备份保留。
- 已知限制：RTX4080 Compatibility空地／近城p95为17.145／17.162ms，密冠p95为31.363ms（median28.972／max34.354），不能宣称全区60fps。GPU退出仍有7个SceneTreeTimer告警；headless另有1个refcount0 RefCounted，测试直接读取原Image也有导出提示。无SCRIPT／SHADER／resource ERROR。不宣称已验收导出包或零告警。
- 本次交付完整新版世界地图及16既有场景接驳；没有重建91个地方场景或清零49个历史遮挡候选，没有提交／推送或重导Web／微信。正式启动无需开发参数；已运行的旧游戏需停止后重新运行，未关闭用户编辑器。开阔旅行地形仍保留较疏区域，不宣称AAA场景密度。

以下为过程记录；其中“进行中／未切换／FAIL”是对应时间的历史状态，不替代上面的最终交付状态。

### 正式激活已完成，切换后完整回归进行中

- 2026-10-03：030936 launcher正式FULL headless实际OS exit0，106167检查／0失败，结果`canonical_headless_1790956805/result.json`；16入口实际往返、12接缝输入、16168完整脚底中心、1386681天然水面禁走、音频与cursor实际释放、六玩家存档前后不变。无ERROR，保留7 SceneTreeTimer ref1和1 RefCounted ref0退出WARNING。正式GPU完整套件已串行启动，尚未提前签GPU或最终画面PASS。
- 2026-10-03：独立53F788冷启动诊断实际OS exit0，完成行25／0（JSON在写入三项验证前记录22／0），实证cold12→公开restore14、公开new-game reset14→restore exact，15个常规slot／bak／tmp和全部现有save文件SHA、active_slot=0保持。030936正式FULL launcher仅公开初始化真实新游戏空导航，再super继承冻结068D全部检查；check-only实际exit0、独立review全文复核通过。新正式FULL headless实际运行中，执行身份为030936 launcher，不冒称launcher字节为068D；原主源／interval／全部批准资源不变。
- 切换后第一次冻结068D完整headless实际OS exit1，106158检查／1失败；唯一失败是测试退出时比较冷启动空导航快照。SceneRouter成员初值版本12，而正式v14的公开恢复接口按生产迁移合同升级成14，因此空快照不再逐字相等；16入口／12跨缝／16168脚底与战斗结果通过，六份玩家存档前后不变。原失败结果`canonical_headless_1790954793/result.json`与三类日志完整保留。正在独立复现，并用公开新游戏初始化建立正式版本基线后继承原完整套件复验，不修改冻结套件、运行资源或降低断言。
- A5DED独立只读审批实际OS exit0／DOSSIERS_VALIDATED_NOT_WRITTEN，1942个实际资源键匹配；之后明确Approve实际OS exit0，生成当前独立技术＋视觉批准。F574正式激活实际OS exit0且原stdout唯一`WORLD_V14_ACTIVATED`；正式SceneScript现SHA `838380FDB05D08B4B521D92EFB12A13369358090740DC5C7D4CB7C9EC6F4C015`。
- 原正式09FA逐字节备份于`game/build/world_map_v14_activation_backups/09fa89449b1792063e66ad488aa2f60671aa00da2193e5c68acb861df14d71d5.tres`，发布器浅复制仅改scene_id，fresh加载逐项验证全部测试外部资源和导出玩法字段。激活程序保留ObjectDB退出WARNING，无SCRIPT／SHADER／ERROR；不称完全无告警。
- 正式068D新进程headless完整回归已开始（无candidate参数），结束后串行GPU正式回归；不能提前把候选通过称正式回归通过。用户编辑器未关闭／重启，旧档未用于测试写入。

### 当前：完整实机通过且主控逐图批准，正式切换进行中

- 068D两套完整程序实际OS exit0：headless106159／0，GPU107953／0、592原PNG；16入口实际往返、12跨缝输入、16168完整脚底中心和1386681水面禁走。review独立核完全部73份alpha证据、冻结7源、403旧文件与六份存档，无新增阻断；原始结果与三类日志保留。
- root实际读取53联系页，按原SHA去重覆盖592／592当前截图；另实读九区原图、汴州／原林前后、ghost、密冠和M概览。普通NPC独立自然巡逻附件EA49实际5235／0、两GPU原图与当帧脚线／碰撞／frame JSON实读PASS；完整72tick JSON已全文核读。不把该附件当完整第二次测试。
- root冻结批准依据`docs/world-map-v14-producer-visual-approval-20261002.md`，manifest仅status与两批准布尔值改变；未批准原614149 manifest逐SHA备份在`game/build/world_v14_preapproval_20261002/`。CF6 recorder及62DF prepare已实际完成，仅机械生成两份独立dossier，仍未当作正式激活。
- 保留7 SceneTreeTimer退出警告及headless2 refcount0 RefCounted诊断，无SCRIPT／SHADER／resource ERROR。空地／近城p95约17.2ms，密冠p95约31.22ms，不称全区60fps；连续域证明只覆盖四向当前idle frame0，不外推全部动作。正式切换之后必须再跑新进程完整回归；未做Web／微信重导，也未声称91地方场景全重做。

### 第九 v12 完整捕获已完成：完整游戏验收中，尚未切换

- review只读核完完整headless原结果／完成行及全部73份alpha JSON：32独立四方向DENIED＋9严格POSITIVE（32 domain／41 resolution），128方向零未决，默认阈值与所有预算不变；最大实际alpha查询24,673／域箱155／live20。原武当粗域已闭合，没有以增预算／假覆盖通过。所有wrapper及PNG绑定当前068D／B6DE与原walk SHA。此独立证据审查仍不构成视觉批准。
- 068D完整headless实际OS exit0，106,159检查／0失败、16入口实际往返、12条跨区输入、16,168完整脚底中心、1,386,681水面禁走，六份玩家存档前后不变。原连续alpha未决已在完整当前帧合同中闭合，`candidate_headless_1790950478/result.json`与原stdout／stderr／engine日志保留。音频WAV／playback、3 cursor纹理WeakRef和测试拥有的场景／隔离槽释放；退出仍有7 SceneTreeTimer与2 refcount0 RefCounted的ObjectDB警告，未忽略或称无告警，实际无SCRIPT／SHADER／resource ERROR。GPU完整套件开始，尚未视觉批准或切正式。
- 068DC74F主QA仅3行精确uniform更新、check-only实际exit0。完整headless运行中已独立验证280物件（31真实GPU双读原型／249精确平移复用，不把副本当新GPU捕获）、416,530真实地影逐像素0差异／0禁区、7原始SSAA帧、177真实冠核心、24缓坡与24陡坡；真实Field九区与16门户正在进行。源和正式引用保持冻结。新机械证据bundler `B7F2D672` 已主控全文读取，只接收明确逐图审查与实际两完整run证据，不自动签视觉结论、不批准、不激活，尚未执行。
- 76E4／01D2整图实际GPU、严格导入、F574候选发布均exit0；280独立物件、416,530个body外真实地影、九区同源切片完整生成，五原RF／拓扑／水陆／导航SHA全部0差异。A6E6首次完整headless实际28检查／1FAIL、exit1：第九Shader精确门禁缺新版真实`forest_visual_revision`参数，未进入Field，0入口／0接缝。结果`candidate_headless_1790950231/`与原日志保留；六份玩家存档不变，正式09FA未变。QA按实际8条编译记录的精确required／reflected集合更新，不接受任意参数或减少检查。
- visual_v12局部6E59／01D2实际GPU exit0：两处scaled revision全部原始／派生／运行层序重复精确，228个有关实体重新导出，body外地影102,624／46,315像素。主控已读原图，树木微缩比例与灰白边问题修正，批准完整捕获，不是整图视觉批准。旧111C候选3,381文件归档至`world_map_v14_ninth_v10_forest_scale_visual_failed/original_out/`，逐SHA0差异可恢复，正式09FA不变。
- root-box保守调度15F／12E单测实际324／0、exit0；仅大根域＋长source envelope先保持unknown再细分，原短域／近小根域／长行／atlas边缘全部保留。透明独立oracle首7BCD存在类型推断SCRIPT ERROR（check-only返回0不算成功，runtime依赖失效后root精确终止自己的子进程，用户编辑器未动），原失败日志保留。仅显式bool后的0105／756A实际39／0、exit0，原始帧和每个派生字节独立packed Float32严格一致。
- 上述源码已机械晋级：main／ninth／实际快照76E4A8FF，原路径材质helper01D2，主QA A6E69C、连续域helper B6DE（仅头注变化）；主控＋review核对所有增量，check-only日志无SCRIPT／ERROR。整图GPU重新导出进行中，五原权威SHA后验、严格导入、完整Field与正式切换均未完成。
- 冻结原行输入的3316独立因果fixture实际4,783／0、exit0：三个终端的原actor行宽5.0466／4.3596／4.3599px，实际可达bilinear上界均小于`.12`，旧helper因4px提前返回且alpha查询0而未精化。D4629C隔离草案只删除该任意短路，保持所有阈值／保护／工作预算；长行新反例单测与真实35项重验未完成，不能宣称域已通过。
- B70B透明缩放CPU专项实际exit0：原始重复／导出crop／文件SHA精确绑定；仅改变alpha0像素RGB的两个内存反例均不能改变premultiplied结果，而能改变旧straight结果。原生帧RGBAF预乘→同空间Lanczos→还原→RGBA8消除实际树冠灰白边；alpha非零支持改变330像素、`.12`支持改变15像素如实记录，须用独立新QA从原始帧重建。仅单物件诊断通过，不代表整图或生产批准。后续v12隔离草案同步调整真正3D树模型的微缩比例，原feet／yaw／碰撞／导航保留。
- 长行单测695B实际231／0、exit0后，helper仅注释改为active晋级B07C，主QA仅同步pin为C052。原35再次实际5,568／1FAIL、exit1：原岩肩／tree081未决已解决，但武当地标粗根域90×45px等提前耗尽2M alpha查询预算。没有增预算或忽略该失败；独立成本调度草案将大根域保持unknown先细分，近小根域再枚举全部原长行。结果保留`original35_alpha_1790948050/`。隔离visual_v12源码6E59／01D2的check-only／CPU已实际exit0：7,280脚底、16入口、18包络、24+24坡度及原RF native字节SHA精确一致；局部GPU进行中，不是整图或正式通过。
- 最新限域重验：A867主QA＋08366连续证明helper＋2C861夹具实际exit1，5,560检查／2FAIL，仅岩肩后方与tree081前方仍INCONCLUSIVE。补齐FULL原有独立support mesh前置后，原两项空cache误报已消除；未改导航／碰撞／阈值／预算。结果保留于`game/build/world_map_v14_qa/original35_alpha_1790945715/`。这不是完整Field通过。
- 音乐退出因果fixture73A7实际28／0、exit0：真实journey_v4启动后，使用正常公开停止接口和自然帧释放WAV及playback的WeakRef；不删autoload、不改生产AudioManager、不清缓存。A867限域重验退出亦无ObjectDB／resource ERROR，原失败日志保留。新增独立reachable-bilinear单测DEF42实际140／0，原98例／生命周期147例均保留通过，但不能替代真实未决域。
- 主控实读111CCF整图仍判视觉FAIL：林土地表额外暗乘与真实树影叠加形成大黑块，总览原纯Y排序将地影画到两城屋顶。隔离草案DE5F／5A1F仅修林土暗乘、实际冠缘过渡与总览negative-Z层序；两城真实林缘A/B源码已审查，check-only实际exit0，CPU与局部GPU待验。未写现有OUT／正式引用，不宣称视觉或生产通过。
- 后续DE5F CPU实际exit0、30路7,280完整脚底／16入口／18岩体包络／24缓坡24陡坡保持通过；原生GPU局部四case实际exit0，无SCRIPT／SHADER／ERROR，258独立entity、原始与派生重复逐字节一致、真实冠核心43／60例通过。主控实际读取两张revision合成图仍判视觉FAIL：树冠相对整座城池过大，透明边缘呈浅灰／米白圈。故不晋级整图或正式资源。局部结果保存于`game/build/world_map_v14_ninth_native_preview_visual_v11_forest_transition/result.json`。
- 原alpha终端独立148B fixture实际exit0、4,767检查／0失败，复现两个指定案例及三个原始未决Rect2。逐原强actor像素的实际可达LINEAR上界均低于`.12`，但该诊断仅处理三个终端，不代表整个连续域DENIED；旧helper的整行上包络与4px精化范围仍须因果核对。树两方向终端中心与原最后live点不同，不能用中心full17结果反推原live有效性。未增加预算或豁免未决。
- 111CCF整图GPU、严格导入、F574仅候选发布实际均exit0，无SCRIPT／SHADER／ERROR。280独立物件、16入口、30道路、1,539,218个body外真实地影；五份原权威RF／拓扑／水陆／导航逐SHA全部与06EB相同。正式引用仍09FA，未激活。
- BFE26首局部数组诊断实际237／1FAIL：真实Y仅[0,2]、法线仅首段、RF误差0，但引擎由法线打包派生的tangent亦变化，原“其他属性全不变”假设失败。E8D2独立按原RF分别构建旧错角／新正确角的无tangent输入对照后实际265／0，两份实际bed所有ARRAY_MAX属性严格等各自控制，water全部数组精确不变，变化只在首段。原失败保留，不直接豁免tangent。
- F9主QA的实际完整海床绑定检查1596／0，含原RF高度预算、saved vertices／UV／index、五权威SHA。只是海床门禁，不代替整图Field或视觉验收。
- 原35当前alpha限域实际5476／4FAIL：两项因限域fixture遗漏独立support mesh前置而全为空cache，须补齐同FULL前置后重验；另两处`native_ridge_face_west_volume_talus_left`后方与`native_tree_081`前方连续域仍INCONCLUSIVE。保留相同阈值／预算，未决仍失败。verbose退出精确发现AudioStreamPlaybackWAV与AudioStreamWAV各ref1及1resource ERROR，正在独立检查测试进程正常音乐结束生命周期；没有删生产autoload或操作用户运行进程。

- v9（06EB）完整捕获、导入和候选发布实际均exit0，五份RF／水陆／导航权威原件与v8b逐SHA完全相同；但独立实际网格验收1596检查3失败。两个海床左角点因Vector2取整后比较原double坐标失败而选错高度，误差0.00036301980413m超过既有0.0001m预算；不得以捕获成功替代真实几何通过。
- JSON表示另有独立91838 fixture实际96检查0失败：原double与落盘默认十进制不同，所有差异严格等于默认JSON stringify／parse结果。QA只按该精确落盘表示比较元数据；顶点／UV／索引和RF容差未放宽。
- 新111CCFF5源仅按角点序号选左右高度并使用新证据目录。实际check-only、局部GPU与CPU source-plan均exit0；CPU保持7280完整脚底、16入口和18岩体包络、24缓坡24陡坡通过。局部重复原图逐字节一致，主控读取原图确认没有直边纯蓝块。独立局部网格验证与完整Field尚待执行，不宣称正式接入。
- 06EB未批准候选3381文件逐SHA可恢复归档到`game/build/world_map_v14_ninth_v9_guard_height_failed/original_out/`，0差异。main／draft／执行快照冻结为111CCFF5，完整GPU重新捕获已完成，正式09FA未变。

- 主控逐图发现 v8b 东北海面 x4392～4608、y0～82 的直边纯蓝块。真实RF顶边水下高度−1.125m投影至y81.4587，而透明水面始于y1.8102；空隙混入天空背景。并非可行走区域错误，不能通过涂导航或换天空颜色掩盖。
- 自足源 `06EB481E20A5A55CFA2CD66FCBEE4A7D0109412ACD9A6BD251B45D6D948363E1` 仅增加域外y[-96,0]湿边海床和水面真实独立几何，保持原RF、原地形网格、道路、入口和物件。实际check-only、CPU source-plan和局部原生GPU均exit0，无SCRIPT／SHADER／ERROR；同一实际相机与材质的control原图保留蓝块，guard原图已消除。局部原始SSAA2与逻辑派生图重复逐字节一致；这仅批准该边缘修正，不是整图视觉批准。
- 11D1旧完整候选3,379文件逐SHA可恢复移动到 `game/build/world_map_v14_ninth_v8b_visual_failed/original_out/`，0字节差异；原75F6完整80失败和日志均保留。06EB执行已完成但后续网格检查失败并另归档；111CCF新捕获仍必须后验比对height_grid.rf、source_topology、land、raw_walk、walk五原件与11D1逐SHA完全一致，否则拒绝候选。正式09FA未变。
- 独立连续alpha域小测试首02D991因L213类型推断解析失败；显式Dictionary后的FC4F check-only与headless实际exit0，98检查0失败，包含粗8px遗漏的0.1px窄站位正例、LINEAR邻texel与保守边界／预算未决分类。保留ObjectDB退出警告，未宣称其关闭；测试只覆盖当前方向格，不外推全部动画。
- 发布器F5740D58固定加入连续证明helper的源码SHA；独立审批目录同步该固定键，actual_sources要求七份实际源码。check-only与只读AuditOnly实际exit0（1,940键／NOT_REVIEWED），没有写批准或正式地图。完整Field源正在补证明JSON写入与读回闭锁，然后重跑真实站位与完整专项。


### 最新实际门禁：第九 v8b 完整候选回归，尚未正式接入

- QA `75F60E6D58FABF9F3DBEB98F517C9894E587F17E56FAF1D0A2E8F8A9E432DCB9` 已实际完整 headless exit 1：103,554检查／80失败、16入口输入往返、12接缝输入、16,168完整脚底中心；玩家存档前后SHA均不变。原结果 `game/build/world_map_v14_qa/candidate_headless_1790938119/result.json`、原engine／stdout／stderr完整保留。失败分组为36贴图mip前SHA、6同姿态复用相机脚点、1冠投影像素、2南区分类、35实际alpha站位；退出另有ObjectDB与1resource ERROR，不当作无错误。正式09FA未变。
- 独立因果fixture `A7296C807BDDF2F7785DB18F25A407F033CB75458731E306153C1CBDF587B9E9` check-only／headless／原生GPU实际均exit0。24种实际原PBR纹理的捕获前SHA与独立解码全部逐字节一致；独立duplicate生成mips在两环境均保持原Texture字节24/24不变。直接对get_image返回对象生成mips，无界面后端24/24返回同实例且改变共享字节，GPU后端0/24同实例、0/24改变。确认是验收代码原地修改共享Image，而非允许贴图SHA漂移；下一改独立副本，严格SHA门槛保留。原诊断结果分别为 `texture_decode_headless_A729_1790939213/result.json` 与 `texture_decode_gpu_A729_1790939239/result.json`；仅进程内控制，没有写原贴图／import／地图像素。
- alpha站位仍须区分粗格遗漏与真正完整脚底禁站；未找到候选不等于证明无可行站位。后续使用真实四方向当前格、真实深度脚线与连续域保守拒站证明，未覆盖域仍按INCONCLUSIVE失败，不能缩碰撞、涂白导航或豁免遮挡。现阶段没有整图技术／视觉批准，没有写正式地图。
- 独立树冠相机fixture `0C2EDF576E054C652A5C270388BED4026E2668D4C9FEED4784DCA44E00535955` check-only／headless verbose实际exit0：按实际9216×6144相机重建、原RF两片三角高度，177记录的Camera3D API整数像素严格177/177相同、原PNG红值177/177相同；简式只有176/177。唯一树049实际低分辨率X=383.999908447266取383，而简式X=384取384。零像素容差，不修改证据；原结果为 `game/build/world_map_v14_qa/ecology_camera_exact_1790939700/result.json`，原verbose退出无resource ERROR。下一用同源实际相机API作精确像素断言，连续简式校核仍保留。

- 冻结 draft `CC030024537EB3C27611FCD5A490EA5DAA33398D9EA5DB0E13BC1AF5576D2454` check-only 实际 exit 0；CPU source-plan 实际 exit 1。30路7,280完整脚底源预测、16实际入口锚点与修复终点一致／完整17脚底检查、24缓坡与24陡坡证据通过；280独立物件中18块替代岩石有3块实际投影包络超出旧范围约3像素。因此没有启动 GPU，也没有发布候选。
- 正在改真实摆放坐标，不扩大旧碰撞包络，不放宽导航或`.025px`浮点预算。失败结果和日志保留于 `game/build/world_map_v14_ninth_v8_portal_ridge_source_plan_result.json` 与 `world_map_v14_ninth_v8_source_plan_root.*`。
- 新 QA `610B1E7D0E72BCEFE446A641A6776E27F219975960A851CF7840E2D2D11FB3A6` 完整差异已主控复核，check-only 实际 exit 0；尚未运行完整 Field。新发布器 `E87DBDAB779FB702F8E0C009965D936AE5B5A2EE84DCE9678FFD8B9065292D86` 窄增正式写前精确字节备份、写后重新加载验证及失败恢复，check-only 实际 exit 0。审批工具同步固定发布器 SHA，原整图技术／视觉门槛没有更改；未创建验收批准，未激活正式地图。
- 后续 v8b `11D1A583116D10F1F38C5FBAE7FCB845245B44ECD42F00A29A8A6F27DBEF3B1C` 两主岩真实下移5px、关口碎岩上移5px；尺寸、旧包络和检查预算不变。实际 CPU exit 0：30路7,280完整脚底、16入口、18岩体包络零失败；北部单view原生 GPU 实际 exit 0，重复 RGBA 严格一致、独立模型地影成立。主控已读取实际局部图，裁切直板消除、允许整图捕获，**这不是整图视觉批准**。主控将该精确 draft 复制为 main／执行快照后开始整图 GPU；当前正式仍 v12。
- v8b 整图 GPU 实际 exit 0：280独立原生物件、16地标、30道路、1,539,218个body外真实阴影像素；主控已读取实际 overview，六处裁切岩板不再存在。严格导入 exit 0、E87DB仅候选发布 exit 0（外部 layout／stream 绑定正确）。导入日志存在旧可恢复归档的UID重复警告，候选发布存在退出 ObjectDB 警告，均原样保留，未当作无告警；没有 SCRIPT／SHADER／ERROR。尚未正式激活。
- 610B 首轮完整 headless 实际 exit 1／12检查1失败／0入口0接缝：旧前置条件硬编码4条编译记录，与第九实际8条记录不符。实际8条均compiled且参数存在（surface0／1／2各2，RF水1，ecology4为1）；QA正在按精确名称、次数和必需参数适配合同，而非删掉或跳过编译门禁。失败日志及 `candidate_headless_1790937885/result.json` 保留；此轮没有进入 Field，不能宣称游戏行为通过。

## 范围与分工

- 美术负责一套连续原生地形、同源道路和水陆导航、九区切片、16个独立地标及来源记录。使用已登记授权素材与项目已有原创素材，二者的许可分别记录。
- 系统负责生产资源装配、正式路由、旧世界坐标迁移、入口返回与战斗回程。保留16个门户ID、目标场景、现有剧情与音乐，不把关闭玩法的实验控制器接为正式游戏。
- QA独立验证真实Field、完整脚底、当前动画帧遮挡、九区12条内部边界、16入口往返及隔离存档；主控做跨模块审查与最终视觉判断。

不改造所有91张地区场景，不更改故事、奖励、战斗数值，不操作玩家存档，不发布远端版本或提交无关工作区变更。历史403份冻结清单中包含正式SceneScript；激活前全部保持原样，激活后仅此正式引用文件允许授权变更，旧字节以同SHA的完整副本保留，其余402份不动。

本轮完整入口验收另发现白鹿渡现役旧客栈碰撞框侵占公共北路，阻断完整脚底回程。为保证16入口实际可进可出，最小关联修复仅重锚该布局的`ferry_inn`碰撞字典，保留实体、膨胀边距、背景、导航及门户坐标；原布局字节另存证据。此布局不在403份历史试样冻结清单中，不修改冻结清单或借此放宽历史文件门禁，也不宣称其余地区已全面改造。

## 生产资源与高风险边界

新版资源目录为`game/art/maps/world_map_v14/`，包括完整视觉、陆地、导航、拓扑、切片和来源清单；运行资源不能依赖`game/build/`。系统新增生产合同、布局、流式背景资源与待验收SceneScript。正式SceneScript只在整图验收后改引用；旧v12资源与完整场景副本保留作回退和旧坐标来源。

路由和存档兼容涉及`scene_router.gd`、`save_manager.gd`及必要Field判断，实施前搜索全部调用。世界坐标版本独立于现有存档结构版本14；缺字段按旧世界处理，不反复迁移新版存档。旧门户按ID映射，旧自由位置按区域映射并修复完整脚底净空。正式世界场景ID保持不变。

## 验收与切换条件

- 九区具有不同、连续、固定等比例2.5D地貌，不复制双区或直接拼接九张旧图；山岸有体积，地表不呈软绿地毯，地标与地基、光照和岸线衔接自然。
- 视觉、陆地与导航由同一几何和相机生成；道路可见且同域连通，跨河只允许实际桥面／甲板通行，邻水负例必须阻挡。
- 16个独立地标同时交付脚底碰撞、深度线、安全入口与明示道路；真实角色在前／后及边缘绕行验证，不能把透明矩形或整条动画带当实体alpha。
- 逐区、逐入口和桥岸实机截图目检；技术通过不替代视觉通过。
- 严格导入、完整运行专项、旧档默认读入、新版存读、入口和战斗回程通过；用户真实存档和无关状态未被测试写入。
- 通过后激活正式引用，再从正式入口与正常路由复跑验收，不能只测候选资源。

## 验证记录

待产物落地后填入实际命令、日志、截图、通过及失败项目。上一轮双区2300项零失败不作为本轮九区验收结果。

### 最新限域与第八局部实测

- 第九v7 `B869816D3ED25B75BA68BA92E3533C11DD09502769C3A5C270CC96A91DD02BD9` 实际check-only、30路线／7,280鞋中心／268原生实例CPU预测、整图GPU和严格导入全部exit0；原始engine／stderr无SCRIPT／SHADER／ERROR，geometry JSON与24／24真实RF证据正常写入，body外地影1,600,370像素。候选publisher `441CE` 实际exit1，明确拒绝`gufeng`：源道路已修到(2535.9988,897.8397)，实际门户源脚点却保留(2535.9988,832.90)、投影(2535.9988,806.4655)，与`native_ridge_base_5`完整XZ阻挡重合。主控按原PNG与全部17鞋／所有实体独立检查16门户，只有这一处拒绝；不是把新nav涂白即可修复。主控再次实际读overview仍判六处RockFace裁切代理直板视觉FAIL，因此下一同时同步门户／道路终点并用既有CC0三维巨石分级岩肩组替换直板，所有child独立脚底／碰撞／Y／alpha／caster，QA来源合同须如实更新。未跑完整Field、未正式接入。v7共3,247文件含import逐SHA可恢复归档到`game/build/world_map_v14_ninth_v7_technical_unpublished/original_out`，迁移前后0差异，实际归档脚本及证据保留；正式09FA不变、403冻结0变化。
- 第九见证诊断实际 `22F91A06B592162742E13DAA6537BF5FDB4E00AB1F376419121DBF4D50A38F9C` check-only／headless exit0，无SCRIPT／SHADER／ERROR；123,343源样本取得24个真实完整17鞋缓坡与24个相机可见陡坡，最大干地三角梯度0.8385775685。历史24px网格仅找到3个陡坡，6px实际三角中心另找到21个，因此不加山、不降低12例／坡度／脚底门槛、不重涂导航。实际JSON另存 `game/build/world_map_v14_ninth_v6c_witness_pass_root.json`，SHA `0276B5642C7001B7CF37A65010148FB29FAB10802DE1E318F73241D0CCA00172`。此前FACE check-only解析失败、B81C check-only通过但typed Array ternary运行失败并返回空字典，错误engine日志保留；主控只停止自身失败的83496进程，玩家36036不动。修为typed append及空结果拒绝后本次实测成立，尚不代表GPU导航／完整Field／视觉通过。下一重建完整候选；正式v12不变。
- 第九首次整图真实GPU `E869` 进程exit0，16地标/30路/268原生物件与1,600,370个body外地影像素导出，所有高res及逻辑repeat成立、三个光标引用退出释放无残留。然而原stderr存在真实 `SCRIPT ERROR: Assertion failed: Need12 genuine fullfoot gentle and actual steep witnesses`（`_export_geometry:1240`），geometry.json缺失；子函数assert返回后父导出继续误写候选状态，属于明确技术FAIL，不能被OS0或PNG存在覆盖。原完整产物共1,762文件逐SHA可恢复归档至 `game/build/world_map_v14_ninth_first_whole_failed/original_out/`，迁移前后0字节差异。主控实读完整visual与overview，但不据此正式批准、不发布候选、不运行完整Field作为可接入版本。下一先增加geometry导出返回值闭锁，并实际诊断真gentle/steep样本；若新低坡RF缺陡坡，必须修真实北方地貌而不是降低12例门槛。正式v12仍原SHA。
- 第九v5 `E48812403A85E099F9CEC49D71B4008195B9935E8E87C6FC983DCEE6562947D1` 实际check-only/CPU/GPU局部均exit0：30路、7,280完整鞋中心、268原生实例，三处raw高分辨率及单帧Lanczos派生图repeat均逐字节一致。主控实际读取北岭、中央森林、南岸三张scene图；森林冠/地面已对齐，水岸清晰，北岭仍有直切岩面边缘及与底部碎石色差，暂仅允许完整候选审查，不是整图视觉批准。原局部退出三ImportedTexture RID/null错误完整保留。
- 退出残留已定位为三张48×48自定义光标的完整RGBA mip链（48/24/12/6/3/1，各12,280字节），不是PBR纹理。仅工具源码 `E869CC7F8F59C17240325AB031E5796307314D659D630EC596EF1312497D6823` 解除Input/DisplayServer句柄及CursorManager三强引用，生产cursor_manager.gd不改。独立GPU fixture `9AFB8D105E1241EA7207295D2F38D5279D219DDECB02136F393AD8CAB56941C7` 实际exit0、stderr空，三WeakRef自然帧后全释放；此为退出限域证明，非世界验收。第七原OUT共864文件已可恢复移动到 `game/build/world_map_v14_seventh_failed_before_ninth/original_out/`，移动前后所有SHA一致；旧源/候选/布局/stream字节另存。main已与E869逐字节一致，下一实际完整捕获；正式v12仍不变。
- 主控独立repeat v2源码 `F4AED6DF0C1F7A97C0A66D60FF20B13922C8528A353D36B72672C40B6CB8D890`实际check-only/GPU exit0、24张PNG（18逻辑＋6高res），生产9540不改。MSAA4／2五对仍RGB1波动；MSAA0同相机1536×1536真实SSAA2原始高res五对逐字节一致，明确Lanczos缩到768后的五对亦逐字节一致，无时间帧平均／色值量化。根读取实际派生图；批准下一v5视觉／body／shadow／ecology采用显式SSAA2证据，权威land/nav仍原画布MSAA0不缩采样。必须记录真实高res相机和logical÷2，不能把1536原捕获标768或用缩采样导航开海岸。还不是完整局部／整图／Field通过。
- 独立单RockFace重复诊断源码 `13C1D841E5B00E2751AADBB001BDA2E816C882D5CF2DD48905CA5F1A8599348A`实际check-only／GPU exit0，12原图有效。相同viewport、原mesh／pose／PBR／灯／环境／相机仅切MSAA：8倍在累计8／16／32／64／72／80自然帧的五相邻对分别60／0／14／16／31像素差，均仅RGB最大1且alpha零变化；随后MSAA0已预热控制五对均逐字节精确。不是等待更久即可收敛，尚不能据此放宽repeat；下一独立比较MSAA4／2与明确高分辨率SSAA缩采样，选稳定真实AA机制而非删除原差异。该诊断无正式产物写入，3旧ImportedTexture退出错误仍保留。
- 第九v4实际local GPU exit1：诊断确认`native_ridge_face_near` 768×768实际两帧的画布、透明四角、非空body和裁切余量全部PASS；唯一重复差异为18字节／11像素、最大色值差1。原body/repeat与JSON逐SHA保留，根已读取实际body图，不能将这个失败称整体材质坏图，也不能直接删除差异像素或放宽门槛通过。下一用独立单mesh、同pose／灯／环境／MSAA8的连续帧与MSAA0控制定位。v4另补最终冠绑定后模式0/4编译门禁和whole ecology空材质明确拒绝，源码审查关闭默认白回退缺陷，但不代替实际捕获。
- 第九v2实际GPU local exit1：生态诊断mode4缺少`shore`函数声明，编译反射门禁正确拒绝；未生成三张场景预览，原v2文件与日志保留，不称技术PASS。v3源 `D19F82056AC8A3115499FBD123F503587923F87323AA934E367F73AEF966E8C9`／helper `90AC04DDC65920521DE72DFC7E401DDB912EA219EF2645F7FA6BF3D43C4BE16E`补同源函数并清理CPU测量节点，实际check-only和CPU均exit0、268实例、7,280完整鞋中心、0几何失败，CPU无SCRIPT／SHADER／ERROR。随后v3 GPU仍exit1：第二代表物件sourcebody复合断言失败，首独立碎石已保存重复图，尚无完整局部图；不得放宽重复一致／透明画布门槛，下一保存失败body与repeat拆分诊断。旧3纹理RID／RenderingServer退出错误仍原样保留。
- 第七独立因果清理retry3：冻结main `266B3F6F695A0ED36DC2D6393276D885036C56D5A489EFA27DDB6386069D11CB`与fixture `007C57E8C942370DC5F9C27337F86B6DA67108FB16B4F69982362A916ABC3505`实际GPU exit0、1,663项／0失败。实际隔离场景/slot WeakRef释放、测试前后玩家存档SHA不变；原始stdout/stderr未见SCRIPT／SHADER／ERROR，旧离线Image告警仍保留。这是清理与因果限域控制，不是完整地图通过。
- 第九v2源 `A7195B80FF89278AEF6E184657939E329066E813F0847A81DC2181237DB7CB45`／helper `90344938203F8E1B5601E7942CA32F6AE0C977A6DCE46DAF866BA2305C045252`实际check-only exit0；源预测实际exit0、30路、7,280完整鞋中心、268独立实例、0几何失败。CPU末端仍有未释放测量prototype与材质的RID／资源ERROR，不能称日志干净；不影响该几何结果，但须单独修清理并复验。GPU局部另存v2目录，正式仍v12，尚无整图通过或接入批准。
- 独立因果retry2 `seventh_causal_1790926191` actualexit0、1,659／0，复制历史behind ghost调用后重现两树`front_original_assert_timing=false`；紧接下一自然physics边界与两个自然process阶段均为true，无测试强刷。确认早期SceneTree.process_frame信号先于Node晚处理，不是完成渲染阶段持续倒序；原4,609／3失败日志仍完整保留。main验收须在正常Node处理完成后观察，当前动画mask强刷不得先于排序断言。
- 第九源`742619955b13938744631fa5532a4bca6d636902bc3d4ff248dd433f5079f257`／helper`de1519f196fa1c7312c2d4c4f0c222054d609f1203ad9749738f97995b52f392`实际check-only exit0，CPU源预测exit0：30路、7,302完整脚底中心、92独立原生实例。2px源格显式枚举所属6px几何两片三角的覆盖范围（例如origin(4,0)同时涉及两片），坡度取最大；不会用边界端点的下一格替代旧格上三角。此前三处类型推断解析失败保留记录，修为显式类型后复验；这不是GPU或全图通过。
- 第九局部第一版实际GPU exit0、三组重复／相机／body／cast／forest编码技术PASS；地面独立cast像素分别118,427／13,494／151,102，投影误差≤0.000733px。逐读三张`scene_components`主控仍判视觉FAIL：原生岩代理露直切边、树叶盐椒噪点、中央1900／1530城市净空过滤掉树后留下人工圆土斑，地貌仍空旷。保留`game/build/world_map_v14_ninth_native_preview/`及当期冻结源；正式仍v12，不执行这一版整图。下一源修须把生态与真实树群对齐、保留每棵窄树干碰撞/Y/cast并改善叶材质AA；不能把旧原图涂色冒充模型导出。离线Image与退出GLES RID/null告警原样保留，未称日志无错误。
- 因果retry1 `seventh_causal_1790924638` actualexit0、1,631／0；72巡逻帧alpha421～486，35后／28前同档交叉、0错误顺序、0真实body相交，全部四格出现。原完整限域retry2 `seventh_oracle_same_band_1790924681` actualexit1、4,609／3，仍保留两树早期观察时点失败及一个真正陡坡鞋像素Walk白值：实际屏幕(1646,263)最近三角gradient1.0685，而2px源selector只测左上角。第九要让整个selector cell涉及的真实三角均合法才标可走；不能只修测试或重涂海岸。两树是否仅process信号前采样须复制历史ghost调用顺序作独立因果判断，不能用新静站PASS抹掉原失败。
- 第七原限域 `seventh_oracle_same_band_1790922887` 实际exit1、3,793项／5断言失败，并有NPC释放后的无效cast脚本错误；精确当期源码另存。三项地形失败是中心可见gentle但完整鞋点踩到更近陡坡，不能把鞋点涂白；两项树前排序发生在正常process之前的观察时点。
- v14生产层新增priority100晚处理，在NPC正常移动后按真实脚底重排；helper先核有效实例再cast，避免队列释放错误。独立因果 `seventh_causal_1790923774` actualexit1、1,496项／1失败；两株树原观察时点排序和退出普通场景恢复255／移除helper均通过，唯一断言失败为正常巡逻两actor横距32px导致实际alpha始终0，不是排序失效。保留失败，不改称全suite通过；新fixture需真实重叠且不穿碰撞复验。无SCRIPT ERROR，离线Image与退出资源告警仍在。
- 第八源预测actualexit0：30路、7,319完整脚底中心、86原生物件与五真实Y0甲板成立。三处独立GPU预览actualexit0、同图重复／实际相机与RF覆盖通过；主控逐图目检仍视觉FAIL：北岭灰黏土、中央forest权重实际0、南岸仍同色草毯。未执行第八整图、未替换第七OUT或正式v12。
- 第九新源采用独立授权原生岩面与真实林区主导，而非继续小调色；新CC0 Grass Ground完整2K PBR官方MD5／size／SHA已核13,605,640字节，物理2.51m，原始diffuse实读为自然绿棕短草。下载不代表视觉／正式批准。

### 制作过程与拒绝记录

- 首轮4608×3072整图完成实际GPU导出，但主控目检`visual.png`和`overview.png`判为视觉FAIL：横纵道路过于规整、河道断头、矩形地基、北方积雪过曝、山体贴图拉伸、分区地貌和植被不足。首轮证据保存于`game/build/world_map_v14_first_iteration/`，不作为生产资源或通过凭据。
- 第二轮回到同源地形和道路源调整；16个地标重新登记源图地面实体范围，不直接沿用v13碰撞矩形。汴州旧碰撞下沿比深度脚底线靠上约130px，原闭合前城墙和城内庭院需作为独立负例检查。入口站位与实际墙体阻挡均须通过，不能只检查碰撞中心。
- 发现流式世界的独立物件虽按Y排序，但旧完整背景遮挡路径不适用，主角可能在物件后完全消失；v14需增加真实物件alpha与当前人物帧重叠的局部半透明剪影，并核验南区深度上限。不能用扩大透明矩形代替。
- 新补充Poly Haven小松资源已核验公开CC0许可和8个官方文件MD5，另存SHA清单；此时仍是候选，是否实际采用以最终Field目检为准。城市等项目原创图不因此改称CC0。
- 第二次导出主控独立查日志发现三处`SHADER ERROR: Invalid arguments ... mat2(float,float,float,float)`，即使进程exit 0、输出PNG和READY状态，也属于技术FAIL：地形材质可能回退到默认材质。已退回美术修正Godot矩阵构造、增加实际Shader预检与捕获错误门禁；禁止使用这批输出发布候选或进入Field。失败证据应保留，不混称第二轮成功。
- 第三次捕获修复实际Shader编译并通过四种材质GPU预检，35个原生物件的独立地影覆盖81,975像素；但整图仍视觉FAIL：草土过软、条带耕地、北部横向岩墙、阶梯岸线与过小幼树均需返工。技术捕获成功不代表美术晋级。
- 首次候选发布发现Godot JSON浮点数组与整型数组不能直接相等，发布器改逐项核验有限、精确数值；之后完成候选装配，16入口及默认出生点的完整脚底预检通过。真实首轮Field测试又发现外部流式资源错误内嵌，已要求发布器纠正资源路径；正式v12未变。
- 首轮headless实跑为6,609检查、24条断言失败、exit 1，同时测试自身有Array到Vector2转换和加载结束等待缺陷，不能把24条当完整生产问题数。原日志`game/build/world_map_v14_qa_candidate_first.log`保留。独立诊断确认七条路线的首失败点导航脚底样本全白，实际侵入汴州／金陵／白鹿渡／烈云地标完整脚底阻挡，须修真实路线与物件布局，而非删阻挡或放宽测试。两株草的层级断言差异则来自测试双精度标量与运行Vector2单精度边界，修测试为实际全局转换公式，不采用±1容差。修正后仍须完整重跑门户、遮挡、存档与战斗回程。
- 第二轮完整headless为21,592检查、71条失败、exit 1，14,462脚底中心、12边界真实输入、16入口尝试/8次Space实际进入、无GPU截图；资源与系统/测试源码失败证据保存于`game/build/world_map_v14_third_capture_second_qa_failed/`。真实移动仅中心检查、出生/验收却17点检查的问题已修为v14专用完整脚底移动，宽筛优化对旧完整合同59,285点实际比较零差异，旧场景行为不变。鼠标超时独立定位为headless物理窗口64×64与1920×1080逻辑事件坐标误用，不为此改玩法输入；站位有限扫描域和地影AABB混入也需修正新测试再复测。不能把71条直接称为全部生产故障或改写为通过。
- 局部系统补测`focused_system_ghost_gpu_1790908383`实际GPU为1,160项、0失败、19图；仅`SYSTEM_GHOST_NOT_FULL_MAP`范围。两城更强alpha交点的局部剪影正常，空路／城边各240帧完整脚底非法数0；累计往返行程393.602／383.994px并非净位移，帧时中位16.670／16.647ms、p95 17.483／17.355ms。退出仍有纹理RID／RenderingServer／ObjectDB告警，不声称整图或成熟树群性能通过。
- 第四完整捕获实际exit 0，48个原生物件、16门户、30路线、768×512网格的786,432个三角形，body外真实地影277,878像素；无SHADER／SCRIPT／断言错误，仍有扫描纹理退出告警。源使用真实三角仿射高度及坡度，不再把RF双线性高度当GPU实际面；路线／入口／物件按真实高度投影。第四整图仍视觉FAIL：大块绿区硬边、北山幕布感、统一软地面与河源尖折，不能晋级。原执行源码SHA为`645877EB4BC2850DD288D831F5E50446C763D6F105845B6814DAB750A49C2736`；后续源设计及camera JSON的明确审计重建不是该次捕获的新读回。
- 第四版首次编辑器导入exit 0却有全局类Parse Error：历史失败快照未隔离，快照中的`NPCNode`／`WorldMapPanel`抢占全局类并产生纹理UID重复。添加快照目录`.gdignore`后严格重导exit 0，日志`world_map_v14_import_root_fourth_archive_isolated.log`无SCRIPT／SHADER／ERROR／重复UID；全局类路径已恢复到正式`scripts/`。此修复不删除历史证据，不把首次导入改记成功。
- 发现项目默认近邻采样，而只有背景显式线性；独立物件随相机放大时出现棋盘噪声。仅v14物件改线性过滤，局部遮挡同步采用独立物件的四texel alpha插值，人物过滤和旧场景不变；12脚本编译、19项source边界验证通过，仍需完整新Field复验。
- 第四候选完整headless为28,469项、33失败、exit 1；17,006个脚底中心、14个真实入口完成、11条真实接缝完成，0张GPU图。桥岸、八条路线与白鹿渡返回等尚需修复；实际三角索引顺序、原生normal重新打包、保守包围盒画布等测试假设另作独立诊断，不删除本次失败记录。战斗已产生真实胜利奖励，但测试可能在Loading中提前停止，仍须补证正式胜利页和回程。完整日志`game/build/world_map_v14_qa_candidate_fourth.log`；未切正式，玩家存档未变。
- 独立代码审查又发现两个验收覆盖缺口：完整脚底检查不可仅复用被测Field判断，自由旧坐标迁移不可只验证安全与幂等。下一次测试补独立导航／碰撞采样与非门户映射期望；GPU帧时采集后再校验脚底，避免将QA遍历算入帧间隔。第四版失败结果不因此改记通过。
- 在完全相同相机、光照、变换及固定冠ROI下，单树原始L0／原生LOD1／LOD2三例实际GPU捕获exit 0、重复图一致。冠部alpha像素分别23,615／17,691／13,329；主控目检确认减面削掉叶冠，不是源树本来枯疏。此为独立模型诊断，不是整图视觉通过。下一生产方案保留原始叶面、仅枝干采用LOD2，并先验证混合case；游戏运行仍使用独立2D纹理。证据`game/build/world_map_v14_tree_lod_compare/`，仍有音频回退和退出纹理告警。
- 混合单树实际GPU捕获exit 0、body与地影ON/OFF重复一致，固定冠ROI保留99.30%、实际绘制顶点最低Y与地面差0；主控目检树冠正常，body之外地影32,680像素。证据`game/build/world_map_v14_tree_hybrid_compare/`，仅认可用于下一整图候选，不作为整图／真实Field通过。
- 第四独立几何诊断18项0失败、exit 0：786,432三角形的实际index→UV cell全部正确；旧整数索引顺序、normal再次原生打包、AABB八角保守画布、cliff引擎导入与rawGLTF差异均取得实际证据，主suite据此修正相应假设，不使用任意容差。原33条完整失败保持历史原样。
- 白鹿渡独立控制：8px网格仅原导航／另两阻挡均有277节点路径，只加旧`ferry_inn`即不连通；中心-only路径有265处完整脚底非法，不能以中心检查宣称可回程。两条世界路线另发现QA网格边端点合法但中间穿黑像素，独立规划器需逐边≤4px完整脚底验证并找合法替代，不为此把源图海岸／非道路涂白。
- 第五源CPU预检首次失败51项，仅东南绕城道路侵入实体阻挡与陡坡；改为城外西肩绕行后retry1实际exit 0、30路线7,333个中心及17点完整脚底预测零失败，三桥实际三角高度非零样本0，白鹿干岸42.54px／93.58px、船下水域负例通过。证据`game/build/world_map_v14_fifth_source_plan_retry1_result.json`。这是未运行GPU的源预测，不作为实际导航捕获、Field或视觉通过。
- 修复旧客栈后白鹿渡限域真实返回又遇船夫实际碰撞；首次限域exit 1的147条失败包含146条后续错场景级联，不能称147处游戏缺陷。保留日志，独立规划正常绕NPC，仍须真实进出和完整脚底复验。新增真实失败／撤离测试的代码审查另发现结果页截图误读已释放Field，只影响GPU路径，修正后再运行，不能拿headless成功替代该截图证据。
- 白鹿限域复跑经历一次测试属性API错误，原失败日志保留；校正后`world_map_v14_return_planner_alpha_focused_api_corrected.log`实际exit 0、2,078项0失败、503个完整脚底中心、0张GPU图。真实Space进入、连续正常输入绕过船夫、Mouse实际出口返回精确脚点通过。独立physics query确认船夫是21.504×27.648矩形体，不移动NPC。竹尾／清河替代路各263／245节点且全边完整脚底合法，只计静态规划，不冒称实际走完全路。三处alpha有限扫描仍未找到相应站位，不作为严格不存在证明。此限域结果不等于整图通过。
- 第五四材质GPU预检实际exit 0；故意错误Shader负例被拒绝，四个真实fragment均通过。完整捕获实际exit 0、约2分11秒，46个独立原生物件，真实body外地影292,472像素，0 SHADER／SCRIPT／断言错误，仍有3扫描纹理退出告警。主控独立目检完整`visual.png`与`overview.png`，整图仍视觉FAIL：黄颗粒地表、圆土丘、塑料河槽，不能据成功导出晋级。严格导入及仅候选发布均实际exit 0，正式引用未切换；随后只进行技术诊断。
- 第六方案源审查确认材质类别错误：`boulder_01_diff_1k.jpg`是独立模型UV图集，含UV岛和扩边三角，不是可重复地面纹理；第五却作world-XZ三平面地表使用。已有两张地表只下载diff、无normal／roughness，导入关闭mip链，而Shader声明mipmap过滤并不会补链。水只有背景色环境，无法凭specular常量产生天空反射。下一采用真正授权可重复地表完整材质并先做隔离局部真实viewport预览，不再以小调色和连续整图重渲代替根治。
- 第五完整headless实际exit 1、28,018检查／88失败，16,134个脚底中心、16真实入口往返、12真实接缝、0张GPU图。失败包含46项camera来源字段层级假设、3项有限alpha域无站位断言及39项战斗UI等待；原日志`world_map_v14_qa_candidate_fifth.log`与结果`candidate_headless_1790914889`保留。不能删除这些历史失败或把当前候选改称通过。
- 战斗独立正常UI诊断`world_map_v14_battle_input_diagnostic.log`实际exit 0、29项0失败：胜利4次真实按下、防御失败1次、撤离1次与正常确认均产生真实结算及精确v14回程；三例各有1帧正常null场景交接。证实结果页直接换场景不走Loading，入场INTRO期间默认可见按钮尚不能行动，原测试需等PLAYER_TURN与真实pressed而非耗尽32次点击。未改生产战斗、未注入奖励或结果。限域诊断不是完整suite或GPU通过。
- 第六局部候选定向取得官方CC0 `rock_01`、`leafy_grass`、`forest_ground_04`、`brown_mud_03`的12张2K diffuse／OpenGL normal／ARM，官方MD5及大小全部吻合，总42,038,318字节；逐文件SHA与米制宽度登记于各`SOURCE.json`。独立preview仅读第五冻结源，真实mip链、分段棱脊与河床／天空反射需先经局部实际GPU目检，不写正式目录或据下载成功宣称通过。
- 第六隔离局部`world_map_v14_sixth_local_preview_capture.log`actual GPU exit0，三处PBR重复精确、12图实际11级mip、两Shader编译反射门禁通过；check-only首遇不存在的Environment枚举，修正后exit0，原失败不改记成功。主控读取三张真实PNG，明显全画面周期斜向条纹、北山等高条带和南岸黑阶梯，局部仍视觉FAIL。normal关闭控制仍有条纹，下一只做同mesh自影ON／OFF及normal bias最小对照，不把假纹解释自然岩层；正式与第五目录未改。退出仍有3旧RID／RenderingServer空告警，离线rawImage导出提示保留。
- 独立`world_map_v14_sixth_self_shadow_capture.log`actual GPU exit0：原ON .02／.08、仅cast OFF、ON .02／1.0三组重复精确；真实257,600三角cross负、无退化、上向normal成立，实际PlaneMesh vertex／UV与source映射误差0px。主控读取OFF和bias1图，OFF斜纹消失、bias1仍有淡纹，证实自阴影acne而非错误贴图法线／绕序；不能靠整图关闭阴影宣称体积完成。南岸实际mesh／解析裁切双边仍需独立修复，不把UV正确改称修过UV。旧退出告警仍在。
- 三处原始alpha限定诊断保留三次失败／修正历史：首次1px域1,061／2FAIL是视觉脚线浮点残差oracle遗漏，校正后1,079／0；中心连续覆盖首1,103／1FAIL发现63个白像素，不能宣称center全黑；最后`world_map_v14_alpha_domain_proof_south_fullfoot.log`actual7秒、exit0、1,103／0。山石后合法站位(1604,1050)实际当前帧48个强实体alpha及71个union像素，旧8px扫描漏站；南崖后(3377,2839)只有3个soft alpha、真实4个union像素，不能称假影。底边灌木前方连续域的+6px南鞋702个原mask采样cell全黑，余域脚点越画布；只证明四向当前idle frame0域无完整脚底站位，不外推所有行走帧。主suite须动态按新产物再验证这些性质，不涂白导航或降低全局实体阈值凑全绿。
- 第六refined局部actual GPU exit0，三个真实PNG重复精确；uniform6px索引保留，水面读取native返回vertices.Y的无mip float32 RF并按相同三角仿射求水深，36px连续岸层消除了第二条裁切岸线。主控逐图读取确认严重斜纹和黑阶梯消失，北岭ON／OFF实际仍有325,958像素真实暗化，不靠关闭自影冒称修复。三处可见receiver保守最远55.80／57.40／57.50m<60；只适用于局部10m镜头，完整镜头另检。草粒重复、北山软灰锯齿与九区整体融合仍待整图，允许机制进新自足源草案，不标整图视觉PASS。证据`game/build/world_map_v14_sixth_refined_preview/`，root保存实际执行源SHA `A54475715C112AA9A87443952214EAAD874B56B6669BF3004A7C87240131CA17`。
- 主控已对第五578个美术文件和13项实际builder／日志／结果／候选引用作逐SHA证据拷贝，归档`.gdignore`隔离，原OUT尚未移走。第五QA启动SHA `358A057D9080DF62E897392733AB0FA05009B1D3D21C7190F102555A3721316E`有实际启动记录，但没有启动前原字节副本；如实保留证据缺口，不把当前修正测试反构为原执行源。下一完整测试必须先保存精确源码／SHA并冻结到OS退出。

- 第六自足整图源实际check-only通过，主控保存精确源快照：builder SHA `6B413EA421F42A6942AB8EAD9D5FD88ED632477197A346A264786BE487357AAB`、helper SHA `19AD86780BF4718771752439C49D922AC42D570051287F93A539561F8E4D7729`。`world_map_v14_sixth_source_plan.log`实际exit0，30路线7,306中心×17鞋点预测0失败；三桥自然床高度约−0.933／−0.819／−0.921m，五实际PlaneMesh顶点Y0独立。两干岸与船水域负例通过；这仍是源预测，不是GPU导航或Field通过。
- 第六隔离四材质GPU预检实际exit0，故意错误mat2负例被正确拒绝。水湿RF−0.5m实际非黑RGBA约(.063,.145,.165,1)，同镜头只换干RF0m实际discard为纯黑；两RF字节另存。`world_map_v14_sixth_material_preflight/result.json`通过，不把默认背景黑当水面成功。退出仍有3旧纹理RID／RenderingServer空告警；负例Shader错误是受控预期，不宣称日志零ERROR。
- 主控再次逐SHA复核第五578文件拷贝一致、旧403基线0变化，然后将原OUT recoverably移至`game/build/world_map_v14_fifth_failed/original_out_before_sixth/`，不删除失败候选；新OUT在第六完整捕获启动前不存在。批准自足源复制到主builder，同SHA开始完整GPU捕获，正式v12引用未改。publisher固定加入draft与helper源指纹，主QA新增真实保存的甲板Mesh／负床独立oracle，check-only exit0；尚无本轮完整Field或视觉通过。

- 第六完整GPU实际exit0（`world_map_v14_capture_sixth.log`），47独立物件、16地标、30路线，body外真实地影888,772像素。实际20/20正交镜头与36/36源投影最大差0.000549px，可见receiver保守最远44.875m<60；不是沿用局部镜头证明。严格导入exit0且无SCRIPT／SHADER／ERROR／UID重复，仅旧微信stage提示。candidate发布exit0未激活；根逐图读取overview与北部、中心块，整体视觉仍FAIL（灰折墙、黄绿粒毯、胶带道路、稀疏植被），允许另起第七自足源，不覆盖本次失败记录。六完整headless启动前已保存精确`world_map_v14_sixth_candidate_executed_test.gd`，SHA `6758BECD7A1842A4AA503889C5479F58CF99EDDDD8193249CEDE65A1D027CAEC`，冻结至OS退出；尚不能宣称完整结果。

### 主控独立兼容性复核（正式切换前）

- 第七主控实际GPU捕获exit0，86原生物件、16地标、30路线，body外地影1,008,900像素。strict editor import及仅candidate publish均exit0，无SCRIPT／SHADER／ERROR／UID重复；离线raw Image导出及旧3RID／RenderingServer退出告警保留。主控真实读取overview与r0c1，整图仍视觉FAIL：灰尖锥及平滑山面、统一浅粉绿粒毯。成熟树群已生效不等于整图完成。第七draft SHA `B5B4283EA770ADC1C567DBDF421DA796760D4B331CA783A7A58BE8938A99E81E`、helper `2DD4DFC8EA5C1C762F6A09E7FD6FAA29FEFFC8E646AC06B1C84E4DEC2EEFB086`精确执行副本保留；第六590美术文件与18项绑定证据逐SHA归档，原OUT recoverably移走。第六系统预修改字节未保存的缺口如实记录，不重构伪证据。
- 第八源仅在新draft/helper制作，移除线性max面形成的尖锥，用真实有限台脊／坡沟侵蚀与生态材料主导。官方公开API定向新增CC0 `aerial_grass_rock`15×15m完整2K diffuse／OpenGL normal／ARM共7,368,961字节，各官方MD5／大小／SHA通过，来源在`game/art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/SOURCE.json`；不扩放1.5m纹理冒称15m，不把模型UV图集作地表。仍需局部actualGPU、全图与完整Field验收，未激活正式。

- 第六完整headless实际结束为28,332检查／49失败、exit1，16,216脚底中心、16真实入口、12真实接缝，0张GPU图。精确当期测试6758快照与`world_map_v14_qa_candidate_sixth.log`、`candidate_headless_1790919839/result.json`保留。47项源相机断言仍硬写36/36而捕获实际20/20；船水域断言误用负床投影而非可见水面；一处源gentle三角被前方陡坡遮挡，原屏幕17鞋点Walk全黑是正确负例，不能删断言凑通过。独立邻列真实RF三角视线重建找到三层交点，最近陡坡gradient1.24、depth36.48，gentle层depth40.64。测试正修为真实相机、实际水面及最近可见三角，仍须完整新运行。
- 又查到真实生产层级缺陷：v14与其他Field共用8px深度档，ActorLayer关闭原生Y-sort，物件／NPC／Player依次插入；同档时Player总在上，即使实际脚底在物件后方。局部ghost还排除了同档物件。下一仅v14按真实注册脚底补同档稳定兄弟顺序，并让ghost使用实际覆盖顺序；静态Sprite位置是图片中心，不能直接打开Y-sort冒称根治。旧91地区场景不在此排序修复范围，待独立真实Field同档前后／NPC测试。

命令：`Godot_v4.6.2-stable_win64_console.exe --headless --path game --log-file game/build/world_map_v14_legacy_save_root.log --script res://tests/test_world_map_v13_save_manager_isolated_20260928.gd`。

结果：195项、0失败、exit 0；退出仍有ObjectDB告警。该项仅确认切换前旧默认v12与显式v13隔离JSON存档路径未被新系统代码破坏，不代表新版v14已通过或已正式接入。用户6份实际存档未用作测试写入目标。

另独立运行`test_npc_scale_bgm_continuity_20261001.gd --headless --audio-driver Dummy`：205项、0失败、exit 0；真实中心→南坊SceneRouter切换播放进度17.099s→18.120s、换曲事件0，共享小尺寸成人条目审计28个，正常玩家存档不变。日志`game/build/world_map_v14_npc_bgm_root.log`；退出仍有ObjectDB/1资源告警。本次未换曲、未做听感验收，亦不计为新v14专项通过。
