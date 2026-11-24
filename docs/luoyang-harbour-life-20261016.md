# 洛阳码头与城门外生活化 · 2026-10-16

## 最终交付 · 已默认接入正式两域

码头：旧船实体替为两种写实立体船，新增5处建筑＋1处装卸棚（6量体，不是6独立类型）；原21物件减旧船加8新物件=28。南门原28城防/桥物件保持，无普通屋挤到城门外。各域新10人/6真8帧行走/4静驻，原任务人物和门户定义不改。新仓门/室内/上船玩法未增加，固定水平巡游不是动态避人寻路。

正式55916自然OS0/139检查0失败/60.779s，result CBE22B38F12164353ABBA8C38FB2591C55E52758B356C2C2DC63D12F64917CE1。无candidateflag，普通public两域出生、10/6实际节点、两船与仓屋fullRGBA、Scene自有224KB水面补片与2总览＋同帧ROI通过。ROOT三图亲看：原脱体黑船影已去除，局部边缘无可见接缝。沿用本轮107864实际282功能检查，不重走原路线/对话/4秒。79声明源/15保存首末同；327正式首末exactticks同，较本轮首只有C/Field两授权变化，其它325含15保存精确保持；editor108140/game101700未动。

正式public实际33.745/23.109秒仍慢，不授加载提速或全城完成。98Image/7旧退出textureERROR/0SCRIPT/0ObjectDB，Dummy非音乐clean。根证据game/build/luoyang_harbour_life_20261016_root01/final_root_acceptance.json；可重启普通工程试玩，剩余美术/更多室内/装卸细节和加载另做。素材按imagegen技能使用内置工具3首稿；原图assets/raw/luoyang_harbour_life_20261016，提示词prompts/qa/luoyang_harbour_life_20261016；按code-review技能审最终接线与补片。

change-id: luoyang-harbour-life-20261016

## 目标

上轮明确只完成外院/南市/组装铁匠，码头旧线稿船与稀疏建筑、城门外缺人流未改。本轮只两域：①码头换真正匹配固定视角写实船只，扩仓房、沿街商铺与装卸作业区，增加有身份的居民和实际走动人流；②南城门外增加商旅、挑夫、巡逻与候检生活场景。不可冒旧人物静态idle为真实行走，不改前轮两区/铁匠的已过结果。

## 分工与限制

- ROOT producer：按空间动线/环境叙事安排，读守卫与源，唯一启动Godot，保存保护/源码与实图审阅/最窄正式开关/进度记忆。
- SYSTEM单写：NEW两区布局author/出版/runtime/crowd；最窄C/Field接线，不全局重构、不改Player或NPC全局比例，不删/缩碰撞，不改原任务/门户/船任务/奖励，旧源完整备份。
- ART单写：builtin两种独立写实船（漕运货船/小渡船）与一处专用码头仓屋，固定正交俯斜视角，原字节/prompt/provenance保留。至多3首稿＋1次明确问题定向edit，不重复烧图。审现役stock布局并给实际anchor/ground hull。
- QA：独立现状计数/新路/任务NPC可达/船替换/新增行人真正位移、比例、脚点及阻挡/停留验证。只NEW短key，不复上一轮全六/两区/铁匠/任务全链；proper0后才actual。

初始有限保护见game/build/luoyang_harbour_life_20261016_root01/guard_before.json；15玩家文件存在/SHA/bytes/UTCticks不得写/恢复。用户程序不停止/重启。完成后仅关键实机交用户试玩，完整美术与额外玩法不借局部通过冒全城完成。

## 初始事实与素材

码头正式21物件：2主要建筑、1告示亭、1旧俯视低细节船；4NPC定义，fresh状态主要chief/oldSoldier两可见，均idle/无walk。南门28物件包含桥栏城防，只有1静态门吏，不能把28物件计为28栋建筑。用户editor108140及game101700（2026-10-16 13:10:02创建）在运行，ROOT不停止/重启。

ART builtin3首稿0edit：漕运货船D3CFD7F9、篷渡船D67140A7、专用仓屋2FDC8572，原字节在assets/raw/luoyang_harbour_life_20261016。ROOT实看3原图及标准RGBA over棋盘，体积与透明合成方向通过；严格10%非零alpha安全边距未达，低alpha噪点保留不擦。接口920A06CA：货船可见长约610worldpx、渡船391、仓屋.62scale中央门约147px（成人约140），不将仓门缩成mini。原prompt/provenance真实保留，不冒CC0或未披露model。

只新两域child；Gate吃完整城防父，Docks吃完整R父；旧任务/NPC/interaction/portal全保持，新增20角色在TASK投影后附加，其中12复用原真8帧horizontal巡游，其余8静驻。完整sweep避NPCapproach/门热区；不是寻路/动态避人AI。码头新增6建筑/棚体量（不等于6独立建筑类型）与2船替旧boat，Gate不新增普通屋，不启新仓门/内景。

早期author check-only在line67 water类型推断自然1，crowd check未执行、无actual；只显式bool修，不冒运行时失败或通过，原源由SYSTEM保留。

## 接入阶段记录

三张新素材隔离import75504自然0，verify100260自然0；三图完整RGBA、23导入参数逐一保持，无损/no-mip/fix-alpha-border=false/detect3d0。仅六个原本缺席的NEW import/ctex精确复制入游戏；旧imports未覆盖。验证3Image提醒、0ERROR；不是运行场景通过。

首CPU出版111568自然1/33.591s，Gate保存后严格storage比较拒。独立审发现generic entry漏原Gate.apply_entry语义，NEW retry2改为完整clone原父visual entries；83416纯固定源诊断自然0，九项world_origin注记差均nativeFloat32 exact，仍保留原FAIL。retry2出版48108自然1/58.236s：Gate全几何/人流1842采样及storage成功，Docks保存比较拒；未接正式。

24824纯固定源Docks全差诊断自然0：八项仅新增render entries的world_origin_px冗余Float64注记，nativeFloat32全部精确，Field无该字段consumer。下一NEW retry3只移除新render entries该无用注记，完整author record/来源/导航几何保持，不加epsilon、不放松875/17，不覆盖原失败。两诊断各1ObjectDB退出提醒。首两轮后327有限源与15玩家exact ticks零差，用户editor108140/game101700保持。尚无本轮GPU/正式信用。

最终retry3 CPU93032出版两域成功，result B1BF4131/69.576s：Gate1842、Docks2739中心含各264人流采样，原875＋17与34×30连续NPC包络/≤4px完整。launcher62152已gone但OS退出码未捕，不写自然OS0。两新walk隔离import与verify25016均自然OS0，完整RGBA/23参数通过（2Image提醒）；仅四个原缺席NEW目标精确copy。58叶binding4A2E9A49/R FEFC623B false冻结。

C CC0D5078/Field3B7824E9完整diff经ROOT与独立REVIEW审，最终proper与普通headless动态load均自然0、两can_instantiate=true，1ObjectDB提醒/0ERROR。仅此两旧源授权接线，327guard其它325含15玩家exact ticks零差。REVIEW58叶逐SHA零差，SOURCE_APPROVE；尚非GPU/正式。原父只用于Gate.moat.prepare视觉模块，新child保持自己的导航/物件/任务后新NPC投影；不冒导航回退。

唯一两域候选GPU107864自然OS0，282检查0失败/73.542s，result EB3BB908E9B13E76A52E795CFF78FB0B46006E7E3AC948FCFC4B5930A9E6F5D7。两区public实际32.740/22.829s非提速；各4秒共享窗口真实6人位移+8walk帧，两代表每帧visiblefoot−0.5px/原22.4×28.8碰撞体/34×30+87517/原生Physics通过；原门吏与码头头领真Space（仅拒委托）、原world出口can_enter通过。70声明源与15保存首末同，ROOT327 GPU首末exactticks同；Dummy非音乐，97Image/7旧退出textureERROR+ObjectDB1/0SCRIPT保留。

ROOT实看两GPU总览，城门人流与码头新船/仓屋方向通过，但发现渡船上方孤立黑船影。SYSTEM与QA各自实看确认该影直接烘于现役旧floor（494C52DA），非新PNG/旧boat节点/ground_shadow_size；移除旧船实体不能清烘影。282功能证据不冲销，但尚不授最终艺术/正式。下一仅NEW场景渲染层采用同次真实shadow-OFF水域局部UV补片，不编辑旧PNG、不动导航/CPU出版、不重跑两域原路线/4秒或全城。

局部补片已实现：同次真实OFF raw6144×4096在原拥有者CPU worker取432×592 halo/Lanczos半缩/裁200×280，只传224000字节Scene-owned严格metadata，主线程生成小ImageTexture，位置2500/1292、z−999在地面−1000上/船与人物下；不是上传100MB纹理、单色猜补或修改PNG。CPU99604自然0/1758ms（75508589）：与整张OFF Lanczos同ROI完整字节相等，3776边缘样本零差；3Image/1ObjectDB提醒。W仅由真实RGBA dc4ba07d填pin至FA857DA4，完整前源保留。

REVIEW窄补片SOURCE_APPROVE；R false51B5E84F/Field7CDED3F8与C CC0D最终proper+普通动态编译自然0。ROOT false全文精备root01/runtime_51B5E84F_before_formal.source，仅一个bool改true至R7BD8039B，文本实际替换逐字等；58原叶/binding4A2E/作者/CPU出版/导航保持。ordinary薄key B7F43581 proper自然0，GPU55916无candidateflag正在两域出生验证，未重复282。当前仅正式试切，须结果与三实图检查后才授用户可试玩。
