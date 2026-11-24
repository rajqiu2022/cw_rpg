# 经验记录 / Lessons Learned

## 2026-11-17 蓄势的伤害归因与攻击帧

- 回合边界仍会结算先前施加的毒伤和流血。验证蓄势本身无伤害时，应先隔离旧持续状态，并同时记录施招信号和内力变化。
- 穿阵或残影位移可能只播放移动帧。验收时在攻击信号的实际触发时刻检查精灵纹理，并核对单次结算。无渲染的压测夹具应覆写视觉行为，避免未入树的 BattleActor 调用计时器。

## 2026-11-09 同一线索只推进一次，石阶按真实踏面验收

- 能重复聊天的 NPC 应在已记线索后走不含任务副作用的对白。剧情门不要只说“去打听”；分别提示缺少的来源与线索齐全后的交付对象。支线等待对白不得吞掉缺少的主线线索。
- 有高差的石阶按上口、下口和斜向护边分开校验。仅测试正中容易漏掉靠边可见踏面卡人；新增旁路也要从低地连续走到上层，检查屋基、路面与阶口一致。

## 2026-11-08 用屏幕画面复核脚点、分帧和加载交接

- 建筑先按屋基与可达前沿定排序线；截图须使用真实层级更新，测试直接移动坐标不会触发角色的移动信号。以最终人物图的有效 Canvas 深度及正常镜头复核，不以局部 z 值代替。
- NPC 文件名不能证明图像朝向，四帧也不能证明每帧都有完整脚部。检查实际分帧，区分素材自身裁切与代码配置错误；走路测试同时检查真实位移和低清/高清显示翻转。
- 世界微缩是可穿越的地景图，应在人物之下、入口提示之下，不照搬屋子的物理占地。加载层等目标场景实际使用的小地图所有者及渲染完成，不用跳过来源校验来掩盖错误的等待条件。

## 2026-11-07 正式快照目录也是来源合同

离线字节逆正确不等于正式准入。EX 对非 canonical 新快照限制 `res://build/luoyang_` 前缀，首方案在真实百工坊 Field 被 Culture 拒绝，23 个目标精确回退后才以同字节快照换合法路径、同步派生来源 pin。以后离线验收同时验证路径域、双 SHA、唯一替换、全文逆和真实历史消费者；Gate 比较不能加入 Market 专用索引。批准的字节偏移始终应用于 UTF-8 bytes，不能用于 Unicode 字符位置。[实测和回退](../game/build/loading_20261106_system03/FORMAL_HANDOFF.md)。

## 2026-11-06b 存档哈希也是读取；局部计时收益不自动准入

旧“保护脚本”通过Get-FileHash读取真实存档字节，虽然没有反序列化或写入，也不能报告零内容读取。后续只检查明确槽的exists/length/LastWriteTimeUtc，禁止把真实槽加入项目来源哈希或备份清单。本轮metadata-only runner只覆盖15路径，不冒称历史171矩阵；原错误声明更正，原证据保留。

NPCNode姓名是动态`_name_label`而非名为`NameLabel`的固定子节点。fixture必须先看实际节点/字段，缺必要对象立即失败退出；一次QA空引用拖到超时不应误判为正式游戏资源失败。高清正式采用检查核AtlasTexture底层atlas、region和source合同；本轮只检查新增3项，不复旧16。

纹理串行576.765ms到原生4批请求446.783ms只是有限headless观测。候选新增ObjectDB退出warning而收益约130ms，先留候选，不为局部小收益扩展正式来源闭包。异步预载可以保持最终原序path/type拒绝，却会改变失败前资源副作用顺序，不能宣称完全串行等序。原4.353s长帧与独立阶段SHA采样不一定同窗，不可简单相减报告3.487s精确未知段。

## 2026-11-06 原生高清也要检查缩小采样；性能数据须区分总耗时与长帧

本轮原生人体557–1119px的图缩到游戏人物尺寸时，单层LINEAR出现明显噪点。正确处理是保留原PNG与base RGBA，增加mipmap采样层；不是将旧低清图放大，也不是模糊重写人物。ab02把含mip链的全部数据与base数据比较导致QA误判，原FAIL保留；ab03精比较RGBA8首层字节后两图全同，visual03十五图也逐一精同。正常对照图要注明128是world单位、不是截图像素；首帧接受不能冒充全部方向和动作已验。

加载优化先测实际热路径：道路AABB只能提前排除不可能命中者，保原精多边形计算；FIRST/FINAL可分别并行fresh SHA，但不可跨阶段缓存文件哈希或放松失败行为。冷进程同路线观测25.575s→10.561s→8.488s，不等同操作系统磁盘冷缓存，也不能将全部差额归因单项。8.488s时首Loading46.542ms、退屏后最大帧19.750ms，屏内仍4.353s长帧；未细分的约3.487s必须记录为未知，不以延长遮罩或推测解析成本宣布完成。

真实消费者必须再次核准精确来源集合：并行SHA本身值与顺序全同，南市仍因历史来源清单漏22项、旧8项SHA而拒绝。仅按已授权快照补精闭包，41264实际C→B为2696/2696、零多缺差；不能将该有限来源PASS写成南市全程旅行通过。已成功的图、lease与进出路线不为改报告反复重跑。

正式采用检查必须理解资源包装：HD显示用AtlasTexture裁片，其resource_path为空不等于底层正式图未采用，应核裁片atlas身份、底层资源路径与有效region。formal16_03因此15误判，FAIL保留；04仅修QA oracle后16消费者全过。受保护启动脚本使用ConvertFrom-Json -AsHashtable，必须PS7；不要先用Windows PowerShell5浪费一轮。后续先静态核对fixture类型与纹理包装，再做一次必要残余。

## 2026-11-02c 不可用PASS数量代性能/ART；空场景安装窗也属Loading生命周期

真实Space基线首Loading约6186ms、退屏后长帧5861ms。新draw-first将首帧缩至69–95ms，但73400/133776/122040均仍在退屏后卡4.8–5秒，虽脚本6/0也必须保留为性能未达。bounded trace证实第二hide时`current_scene=null`、旧smart route无field_scene_id；不是强类型绕过override（同PackedScene两调用各1已否）。必须仅凭已接受pair的原七字段/固定endpoint/Router实际target核准安装空窗，屏保留、旧manager自然reset，等真实目标complete再做原SHA/Geo/入口/小地图barrier；不伪造ready/不私改manager flags。137624首次消退屏后长卡：Loading隐藏25574.465、可操作25574.689、最大后帧31ms；总耗时仍25.6秒且Loading内仍10.5秒长帧，**只能说遮盖/就绪时机修复，不能说整体加载优化完成**。

旧闭包的合法目录前缀也是合同：5新edge逆内容对却放在scene_cleanup前缀，Culture依旧拒；须迁到合法luoyang前缀并精换当前source keys，不扩OWNED。撤墙后还须核真实Material消费者硬编码payload SHA/声明行数，不能只更外manifest。新包145行只退8墙声明、保原136/118ground/18patch/base139，stage完整逆链留，不能松guard遮错。

高清要量原生可见人体而非画布请求值。4方向多行表生成1254方/1774宽不足320，拒而不放大；1536×1024单向idle4×1/walk4×2实得426–460px。透明图黑灰外观可能只是alpha0 RGB，先量alpha再决定，不做无意义去背景。不同hash不等于有效8相位；动作/方向未齐与站走体量变化仍须正常尺度判断，不以单方向样板冒全角色完成。

测试身份和坐标须同域：Civic y2240/2225实际属market，QA误传yamen也会报REGION_SAVED_FOOT_BLOCKED。先核district边界和solid来源，只纠正fixture logical，不搬建筑或改碰撞迎合错误测试。所有本轮失败保留，未重采171真实存档矩阵。

## 2026-11-02b 入口信息是世界顶层，最后写者也必须核对

林西实际Portal500+Prompt31=531，而罐子absolute536；原地文字因此被遮。入口箭头和名称须同处绝对世界顶层4096，高于既有4095角色影像，但保HUD/对话独立Canvas层在上。只抬父层受相对/绝对祖先影响，只抬名称仍漏箭头。World晚attach还会raise_names将名称写回4095：一次ready修正不够，独立适配器监听新节点并仅维护已登记WeakRef，保显隐、变换和业务不动。实际结构17/0、原zoom.9图12/0且亲看同罐同位文字完整，不能拿z属性断言代正常图；不扩大成全城ART/旧旅行矩阵。[本轮](changes/entrance-overlay-20261102b.md)。

## 2026-11-02a 路口须避真实投影，信用替换不累加，原生镜头不是统一zoom1

73468技术97/1中Docks原Scene1.05被QA误锁1；修尾oracle必须取实际原生Scene，保原生图，不改摄影迎合测试。另一Civic图则确ART拒：围墙/屋瓦投影x627..694/y918..1230遮旧mouth720970，碰撞安全/技术绿不能证明路口可读。只一口北移720840/arrival824840并保retired720970/原墙，97124两向真实进返+正常图才有限收口；原报告整FAIL/拒图不洗。

样板先接受再分类推广：22端14短轴+1South原样+7保真实既有道路，只有South/Docks/Civic三类正常图本域接受，不能叫逐22ART。函数信用按唯一方向算：8+14−被后继旧2+新2=22，未改20继承不复；首次24624的原pair2不与97124重复相加。UTF8非ASCII传输会损label，原677A预检拒/生产0写保留，另AE22 UTF8精hunks全文正逆后才可apply。

新增第三叶Pair时只补1全文且核精等原208 before，不重采171/重置d815。唯一guard02 C476EBDC保护208/204同含134、99/93原叶同、171metadata9absent精同，只before1+after1，0内容读写恢复；停止验证。详[最终证据](changes/scene-quality-20261102a.md)，沿[标准S01–S07](scene-art-quality-standard.md)保用途/真几何/有效祖先z/原生正常图，不再以代码PASS代ART。

## 2026-11-02（11-01d）量alpha主体/有效祖先z，配对双向出口必须到真实消费者

证据措辞同样按实际：六ID不等于六人当场存在（本轮5resident，封砚秋原absent）；132目标不等于每帧每人精132（考官134.955、刀客132.000003）；前方ghost_pixels=0不能当背后影像实测。原mini头像也不能记成新做。

1. **画布不是可见体量。**旧wing画布render908×532，alpha屋身仅606×354；旧NPC160帧/alpha120，校准140后再乘.82仅114.8。先追最后覆盖者、逐帧alpha和统一倍率，再定成人/净门/原生占地；新堂实出alpha1499×768，等比950×487/净门144.5获有限接受，不压成预期560高、不假造710基脚（真实842）。alpha0隐藏RGB灰晕不是应擦背景，仅授权框外A1/透明补白，保RAW与主体像素。
2. **local z通过不等于有效遮挡正确。**91216技术193/0却abs365新堂绕过WorldContainer−100，遮门前2990主角及2950僧；ghost按前脚早退亦不能救错误基准。只改新堂同父relative，109688实有效楼265/人273/僧268+正常图才关闭；楼全不透明，不抬整人z，后方沿原.42同帧影像。以前11b已遇相同根因，后续美术样板必须同时看父链有效z和前/后正常像素，不能只断言本地数值。
3. **一对出口共一份端点关系，不能只修箭头。**旧百工marker被边缘钳离trigger82px；提示/点击派发/Space/方向/arrival/return/道路/mini需同源，A能到B不推出B能回A。accepted=true也不等于新Field ready。11pair22静态端只能叫静态；本轮4pair8真腿分别由131104/25304/109688组成，成功前缀继承不重跑，其余7pair不冒实测。原mini头像继续用不算新功能，石地+牌只授功能路口而非完整ART。
4. **实际collector闭包先于静态source表绿。**Docks B.header先问AA.author；普通C硬锁旧F1使author空/collector0，不能先修几个manifest值就宣称来源过。精固定父字节逆层后，115984真实C2583/B2574又揭出9已批准Router历史snapshot；只追加这9精键/不扩OWNED或任意目录，109688才有真实consumer及四新方向。静态2562/虚拟2583不是实际C/B。
5. **阶段后继不重置before，末次metadata只一次。**Quarter原before→已合after→21后继、AC21after→精9后继逐段双逆；03因已授权apply不再补采“before”，用9201已固定全文+3CB实际回执/Root核正式before证明，不把after补成before。原113/旧96保，96只同keyArt单行后继/另95叶精同，最终158D1D01保护134源/96+3叶/171metadata9absent。02final不调用，直接原113final一次；0档内容/恢复，旧FAIL/91216拒图/旧7ERROR保。停止复验交试玩，[七项状态与完整证据](changes/scene-quality-20261101d.md)，沿[标准S01–S07](scene-art-quality-standard.md)执行，不再逐图口头兜底。

## 2026-11-01c 同类墙要精owner，步态要同次位移，残余不能重置基线

29m撤两墙不等于Gate所有孤墙已撤；新图定位seven26c两前墙，视觉/实体/NAV同退。首102424技术66检查1错是QA x600碰保留gallery55柱，实际query命中后只改同原墙跨度x650，不搬柱/关碰撞；World真Space/C/B1727前缀继承不复。57604双墙真W跨与3正常图才有限收口。大跨步但慢须同一次观察位移/步频/方向/停步，不单改speed或相信walk文件名；10.5s每target627样本及原daily自然冻结/收尾支持节奏改善，不授完美footlock。MainField新SHA仍要查native228消费者，只2literal后继保另227值和完整guard。原183中的2源默认不可变但非strict60，新授权另fresh2全文备份/explicit after和guard successor，不重写baseline/泛加白名单。最终26DF2620 PASS保183源/33授权恰33变化/171save9absent精metadata/16叶/36备与project一行精逆，旧FAIL/7ERROR/ObjectDB/Imagewarning全保，停止复验交试玩；详[本轮](changes/scene-quality-20261101c.md)。

## 2026-11-01b 把用户否决变成制作前置，不再逐图救火

怡红院真实坐姿的方向strip按.28s循环仍会快速转身，不能只减速或误诊重生；室外地面也不能拿29p室内不漏底作答。用途/成人净门/纹理样板与真实同类消费者现按[标准S01–S07](scene-art-quality-standard.md)由ai-rules前置。91364技术112/0后地面首ART拒，95060再88/0却砂土盖掉铺石：底材absolute z=-1050、铺石relative经父−100后更低，local z比较“通过”不证明真实绘制。04统一原父层relative并记录有效旧底−1200/砂土−1150/铺石−1100，44444/89检查0/0输入/3正常图Root才有限接受。故QA必须有效祖先深度+实际正常图，不能继续堆local属性断言。坐客91364的2.1s/至少15样本和真门成功继承不复；地面接口改善仍直边/空地/重复/临时墙，非整城ART。首probe11PASS/2FAIL、91364/95060拒证和旧7ERROR/ObjectDB全保；最终guard87056F24有限97源/171save9absent/60pins零差、project一行精逆，停复验交试玩，详[记录](changes/scene-quality-20261101b.md)与[登记册](scene-art-defect-register.md)。

## 2026-11-01a 局部地面视觉与导入边界

窄视觉返工先区分runtime绑定SHA与作者历史source_graph，不能因换World地标误扩共享来源继承。道路用固定worldUV和中心线距离场并集合成，避免Line2D平铺UV/叠色把岔口画成深色管路；mini须复用同helper，不单画另一套路。PowerShell数组里字符串加法两端必须各括号：`@(($prefix+'.import'),($compiled))`，否则会合成一条含空格路径；导入推广成功是启动实机的硬前置，不能复制失败后继续跑。完整PNG有alpha0像素中的RGB雾色，不等于可见背景；按alpha证据处理，只清授权框外alpha1，不能据RGB预览任意去背。详岸驿11-01a专题。

## 2026-11-01 来源准入有多层消费者；候选档案先隔离扫描

31h的C collector/B.describe全键全SHA通过仍不能代替Field实际进城：Culture readiness另对Field及C直接SHA校验，加载77%后拒。先纯readiness列出整张CT差异，已有OWNED的Field走原EX完整逆链，非OWNED的C只精更新CT来源键并继承Coordinator CONTRACT_SHA；不要扩OWNED、通配放行或关闭late guard。Coordinator本身属于既有OWNED，变更必须保历史追加精逆边。ResourceSaver duplicate后未必外引layout/stream，实际resource_path可能变成Scene::SubResource；用薄外引Scene，并真实ResourceLoader验证身份，不反复重烘地形。候选copies/before等含class_name的GD放入工程会被保留编辑器注册，抢走正式WorldMapPanel路径；档案根先.gdignore，生成cache只精纠正一条，不改生产UI绕过。城镇动作式门action=world_map与World can_enter门API不同；普通World门没有portal_id元数据，QA先读真实构建代码，成功子域不因残余oracle失败全部重跑。详31h专题。

## 2026-10-31f 多入口同场景须绑定真实来源，QA不抢先加载autoload依赖类

World直入口和原localG进入同一冒险Scene，不能全局替换return资源；只对可信固定World-origin运行实例返门绑定，localG实际目标live后才清来源。void portal调用不代表accepted，pending需源实例/固定目标/代次/期限及精origin快照，菜单或失败只能取消自己的pending。主QA SceneTree脚本静态WorldMapPanel类型会在SceneRouter注册前加载依赖并污染class缓存；用运行期Variant检查，不改生产UI绕过。原World门can_enter与冒险outskirts门_can_enter不是同API，先读真实脚本；8输入应逐按放核，不凭计数推断返门Space。详31f专题。

## 2026-10-31e 已批准后继不自动更新所有精集合消费者

Authority.source_paths随Router后继增加不可变快照，Region基脚本也有新SHA；旧B包legacy表若仍旧，prewarm的自洽expected不代表实际collector通过，最终B.describe精集合会拒而表现加载后返回。先实际C._transition_sources与B.expected做差；本例恰3过期pin/9missingexpected。只更新Gate清单与动态索引，保 strict hash/keyset，不改公共Router或扩OWNED来规避。原World真实进门一短腿可验收，不以新Region街坊成功冒城门已可入。详31e专题。

## 2026-10-31d 看有效父层深度，街坊检查完整巡路及任务末腿

WorldContainer−100与子地标绝对z会绕过相同局部深度比较，须查祖先z_is_relative/有效层并在最终viewport核人物像素。新增整栋楼不仅核NPC站点，还需完整巡行扫掠、旧任务接近路线和门返脚；165项出版过不覆盖未列任务腿，不可冒全PASS。JSON数字/typedArray的整体相等不可替逐字段类型与坐标核，改精确Core.vec及逐TYPE_INT而非放宽几何。新增域一轮短走/旧脚兼容/正常图即止；三个街坊变好不等于整城密度和地域美术完成。详31d专题。

## 2026-10-31c 技术断言不覆盖正常图，fresh范围必须显式

世界地标actor.z大于Sprite.z、源SHA及可交互全部通过，不证明主角已在最终画面可见；Root必须看正常图，未见即保留显示待修，不冒PASS。Sprite有效深度还受父层/绝对z与材质影响，不能只改一处sort脚反复宣布完成。实测filename带right的商贩行走条实际朝左，朝向修复按纹理而不是全NPC反转。基础保护清单未包含后加入正式目标时，应诚实拆fresh与历史字节链，不借after补拍before或宣称旧mtime完整保护。详31c专题。

## 2026-10-31b 田图跨台地造成假通路

完整梯田PNG可横跨物理坎界；仅按组件root判level不足以保证视觉占地同层。先逐可见alpha投影回ground核真实平台，和石岸实际alpha核重叠，再调整完整组件与实体/脚锚；不能只退前景石头留下隐形墙，或关闭整条Cliff抹平高差。用户要田内向左时，验收应同实例真A/D连续接村巷，中间无setup，邻坎负控允许沿斜壁滑行但整脚不越界。新实体覆盖旧合法脚的兼容必须重放旧形状，预设同层净空落点，不广域nearest。详31b专题。

## 2026-10-31a 高脚桥侧边碰撞与旧脚兼容

画上高脚柱不自动代表有物理高程；先认实际Scene、局部deck与脚体，不能因桥图相似就改World五桥。桥面侧边需独立阻挡，不能把支架整片变成巨型障碍或封端；旧水体端点本就不可走应保，不以删水通过测试。旧合法被新增栏边覆盖脚可保X归桥中，必须核旧全脚合法/新目标净空，远地脚不迁。实际脚34×24与迁移保守35×25用途不同，接触oracle不能混用。只新边/可用桥端/迁移一轮局部足够，不复旧三桥四阶矩阵；UID缺失先查旧Scene本就有无，避免无关全Scene重存。

## 2026-10-30n 既有原生草案采用到正式业务

独立F6草案不是只加Scene路径就完成：须保原SceneScript身份/NPC/dialog/portal action，禁草案独立R/Tab/Space输入并处理缺失examine接口，保物理XY与高程投影、箭头持久偏移。新Field不在_ready后set_script；旧UV独立版本3005，真合法旧脚显式迁门前、同版脚全足净空精保/非法拒。离场控制与return_spawn都要检查current owner/id和LoadingManager；原World generic go_world_map会强制gateway覆盖记忆脚时，新精ID宿主应复用已有直接return路径，不能只存一个永远被覆盖的key。上阵前创建Root日志目录；本轮首Start-Process重定向目录不存在是pre-engine launcher FAIL，不算引擎测试通过或失败。只两新入口+原NPC/原内区进返足以验当前采用，不重已通过五桥或整个旧门派矩阵。

## 2026-10-30m World桥图采用：原始素材数据不等于Godot正式标量

素材JSON中的float64与TRES序列化标量可能不同（0.193575918674469→0.19357592），不能让严格运行guard拿原始数值拒绝正常正式地图。固定原TRES SHA精提全部实际校验字段作为独立新证，保旧RAW与FAIL，保持严格==/不泛epsilon/不改几何。Field创建前的LoadingManager初选可静默拒绝，诊断应直接记录make_index.error和loadingmetrics，不能75秒只等current_scene而空records。JSON浮点Array与整型Array整体比较也可能误判相同尺寸，应记录原始值/类型并严格逐整型分量核验。透明PNG的灰雾预览先查alpha；V4灰halo其实A0隐藏RGB，盲目去背景或再次生图会浪费且损伤RGB不变量。同纹理分层GPU/CPU应同source polygon分区；同图只计一次驻留，压力驱逐末ref后必须重新算费用再确认预算。

2026-10-30l 岚溪寨：完整石面图片投到接近竖直的二维坎边会形成纸片墙，改用按相机方向布置的完整等比岩岸，并把生活陈设和门前路从坡界退开。建筑遮挡统一主角影像；Polygon2D 铺街需按三角形UV与alpha判断，不能只支持Sprite。凹碰撞多边形先凸分解再做旧脚兼容检测；迁移只承认旧合法且新物件覆盖，不泛用nearest。详 docs/changes/lanxi-occlusion-and-banks-20261030l.md。

2026-10-30l：有时长的采集必须把“开始pending”和“提交奖励”分开，完成时重新检查空间/可采/真实射线及原完整脚；别在按F时先给料再播动画。控制锁应独立token，不能借Field宽泛modal_close无条件解开别人的面板。劳动动作只是自有显示层，原Player脚体/约束不能跟着PNG尺寸变；镜像围绕每帧源脚，不靠flip_h默认offset猜。真实4帧和AudioPlayer播放tick比debug帧列表更可靠；矿点完整脚净空仍可能被视觉岩壁盖住，Root图必须看，优先移普通采集点而非抬人z穿墙。用户游戏仍在跑时拍save基线可能随后合法更新，严禁把新用户进度恢复为旧快照；保whole FAIL，按时间与真实API证据单独归因。PowerShell ConvertFrom-Json可自动把ISO Z转DateTime，再DateTime.Parse会丢Kind并按本地时区重解释；应先判DateTime直接ToUniversalTime，否则DateTimeOffset.Parse，保错误审计后另存修正版。

2026-10-30k：原生ChunkStreamer以path缓存，同一素材铺整图也要唯一AtlasTexture别名，否则wanted字典吞块；native draw_scale1只裁末边。Line2D TEXTURE_TILE不代表启用纹理重复，texture_repeat必须明确ENABLED，否则路面拉成条纹；GPU羽化仅材质，不应修改受保护PNG。SubViewport用world_2d=World2D.new()，不要不存在的own_world_2d；TextureRect先expand_mode再texture再size，避免最小尺寸留下1024×768巨图。lambda回调直接抓已释放Node会在is_instance_valid之前报capture freed，抓WeakRef再解。typed Array[StringName]的三元数组表达式可能返回untyped Array，逐append更稳。原Battle按钮在INTRO已存在且未禁用，QA必须等待合法PLAYER_TURN再GUI点击；返回门亦要站真实脚区，不能拿出生点或箭头视觉中心猜触发域。保失败、只跑残余，别为新支路重打旧城/制作全矩阵。

2026-10-30j：Inventory.add_item会满包部分加入后返回false，remove_item也同步发事件；制作不能“扣料→加货失败再回滚”。应副本模拟扣料腾格、完整容量与唯一装备serial，然后一次提交slots/gold/serial，信号期间持锁防二次制作。普通资源采集状态虽复用GameState.flags存档，也不应广播剧情flag_set让旧MainField重建地形；资源自有簿记直接存子字典，并容错真正剧情刷新造成资源根失效。任务专属采集与普通常驻点必须不同ID。密林display_at_native_size=false时须按设计基准投实际world_size，不能照抄设计px。I快捷当前被旧代码禁用时，新的功能要有可见可用入口，不声称背包快捷已经可达。QA勿命名seed，撞Godot内建；UI Atlas只在运行时选既有PNG非透明主体，标题避底图透明留白。有限现场F+GUI闭环够证明首批接线，不用反复跑旧11门和全城。

2026-10-30i：扩展通用Registry.IDS时必须审所有消费者的必需字段，不能只验证专用Field.start。门派row缺world_foot可正常进场，却在go_world_map/get_world_map_position_for_scene时炸Dictionary访问。补坐标从当前正式地图原portal.pos取值，不能拿建筑source_XZ_foot或画面底脚作返回点；测试遍历全注册ID及两World别名，逐一核原门目标/脚，避免同批其它门派漏修。仅数据字段遗漏可窄修数据契约，不必改已封Router造成无关来源级联。

2026-10-30h：人物尺寸要读真实alpha框，不能用PNG透明画布或继续叠旧场景npc_visual_scale；已有NPCNode校准可只改显示，再逐字节核原身体/Area/巡路/脚锚/业务不变。门高与建筑层高分别定标，两层楼不应按整栋仅3成人压小。Vector2 float32校准132px会得132.000006px，QA范围需物理意义的.01px容差且保目标差检查，保首FAIL而非修改正确生产逻辑。首失败前应写原始回执，否则只能静态复算推断。正常渲染要原zoom同画面成人对照；新纹理整RGBA同不代表配色/地面衔接合格，Root可拒ART再只修新域。Godot普通项目autoload解析与--check-only不同，后者exit0也可能autoload标识失败；必须读实际stderr。旧纹理退出ERROR不能洗成clean。局部截图不冒连续键盘路程，用户要求加速时继承旧成功，只验新尺度/新视觉，停止全城重复巡游。

2026-10-30e：原场景改造必须分别验证室内返门、World原landmark、跨港对白场景跳转；三条来源需要不同落脚，不能统一default。旧存档版本与新布局编号要隔离。锁门会清空运行target，QA应从原数据稳定ID/坐标映射；复制测试必须先改所有输出名，避免覆盖失败证据。


2026-10-30e：原MainField会动态注入Hero开场，真Space开对白后不能立即按原NPC数字选项；先看实际当前node再推进到可见choices。DialogPlayer._box是DialogLayer根而非DialogBox脚本，读取控件须按真实子路径且判空，否则测试自造Nil错误。专用Registry按World来源强制南入是生产规则，公开near setup在新进程初次调用也会被覆盖；测试应先公开默认bootstrap，再同图公开near，明确不冒连续步行，不直写Actor/Router来凑oracle。新布局应保原非安全区遭遇，不把所有“城”统一改安全区。通缉榜懒初始化只允许精ID/精字段默认状态的absence等价，raw仍留；失败测试不应因此改生产业务。三地仅一次新雪补图，其余复用完整原生建筑，能快交室外，但功能通不能冒大空土院/空军院已达参考密度或全ART。

2026-10-30d：用户要求小地图简单半透明时，只画贴近实际地图区域的半透底板与细边，不把整widget设为半透明，否则实景和标记也会变淡。保留aspect-fit计算但去掉大面积装饰letterbox，直接围绕_map_rect绘制可减少无效遮挡；本次只样式单图，不重跑缓存和旅行矩阵。

2026-10-30c：小地图画真实道路/碰撞位置仍可能过于抽象；用户要建筑缩略时应复用真实纹理而非色块占地。Region视觉分chunk，截当前树会漏远楼，须由完整compiled.render重建静态绘制副本。纯视觉缓存隔离World2D、只new无脚本Sprite/Polygon，StaticBody下visual可遍历但不复制物理；NPCNode本身可能是Node2D，不能仅排CharacterBody或猜文件名。SubViewport的canvas_transform必须在视口和绘制根入树后赋值，否则即使画面可见仍报canvas_map错误。一次缓存+动态marker既清晰又避免逐帧全城渲染；发现初始化错只检新残余，不复已过346项。

2026-10-30b：同纹理同UV不代表拼接自然；分别圆角的矩形与渐收段仍会在接边留下凹口，应先合一轮廓再圆角。旧主轴地面在新曲径下方仍会露出，撤断头须处理底层可见面而不是只删新路段。地图的floor_rects包含整片草地，不能全部当道路；读取可见铺装，compiled实体和门户不要重复扫描。World专用地图不会自动在城市显示，需三类Field显式接入；动态marker与静态plan分层避免逐帧全城重绘。必要来源闭包里已加canonical helper pin时，改helper必须传播所有真实pin，不可只升Router。Root实图拒形状问题后只检新残余，不重已过UI。

2026-10-30a 场景切换与高程：离场场景的每帧回写会覆盖已开始的新目标出生点，须同时以过场状态及当前sceneID阻止；入口碰撞保持地面坐标，箭头用持久投影锚，否则浮动动画会将一次性Sprite偏移还原。楼梯的上/下可走不等于可见高地，台面/连续立面/阶口/角色投影/分层碰撞必须共用同份高程。详docs/changes/town-layout-and-sect-entries-20261030a.md。


2026-10-30（29q私园）：单向“前往后园”不等于存在回程，须检查实际编译门户而非仅作者说明；两片可走区域之间30px空缝足以阻断完整脚体。新增池塘后要精确兼容旧合法存档脚，而不是全局最近安全点。透明PNG预览显示的灰雾可能只是alpha0隐藏RGB，先核alpha并看真实叠地，不为预览误象反复生图。共享Router封源前重读当前头，继承并发林西修改；一轮真实进园绕路回厅南出通过后停止复测。

2026-10-29q：入口正常默认点不代表旧坐标恢复正常；候选被拒后，nearest搜索仍可能选到错误大可走区里的墙。门户往返应由对应箭头确定，室内合法续玩位置与入门位置分开处理。要在箭头处真按Space检查邻近NPC是否截获；数值停止在墙前仍可能踩到画内筐篓，需看原图补局部阻挡。继承成功路径，仅检新残余；中途外部保存应记录并保留现值，不能回滚或声称原基线零差。


## 2026-10-29o 赤岩、沙漠原生像素返工已正式

用户“直接修改”已执行：赤岩7A2C4FC1/沙漠BB7F127A，外围崖短段搭接及0.95原生侧崖、门组缩回；沙漠5倍整圈图退，独立门/正侧墙/圆堡、5院整体原生与沙丘0.9分段，东墙外移400。8新native各builtin1次/只RGBA0补白原RGBA同，World两专用完整微缩城0.46且原脚保；3来源合同后继、0Router写。静态253节点0放大；私有257/0→新域25/0→东墙2/0，正式129984自然0/57检查0/两城真Space进返4图亲看，旧7退出ERROR保。早期资源头和QA提前HUD编译FAIL保。245保护含171save精ticks同/editor51856保；图鉴5181/24新路径48图缩略核/非resources同，索引1836源0缺。侧墙两轴收缩、沙丘重复/街坊密度非设计全ART，停止本批成功复测。详docs/changes/desert-city-native-rework-20261029o.md。


2026-10-29p：CanvasItem patch材质在fragment再用COLOR*=取样会把默认整纹理的颜色/透明轮廓二次混入，出现整shell残影和黑洞；保存vertex tint并直接赋局部采样，Polygon2D像素UV须按实际归一化约定还原。纵墙不能复用横墙末边生成立面。视觉铺底须覆盖实际镜头范围但不扩大可走区。共享工作区全源首末失败要列具体外部变更；本次另任务4三城文件改变，保原79/1失败，只独立确认本室源/进返/两图与171存档，不回滚他人也不反复跑成功路径。

2026-10-29o：外观门洞左右墙有碰撞不代表中央已封，角色会沿空洞穿到背后。补门槛须按完整脚体半高及离散移动步长计算停止带，同时保门热区可触发。新碰撞也会覆盖历史合法保存脚；兼容应限定精区域/revision/新增quad/不可变旧bin合法性，并迁往已定义返脚，不能放宽所有blocked或搜索最近安全点。此次同一局部实际覆盖W持续阻挡、Space进返、旧合法与原墙内负例，成功后停止复测。

2026-10-29n原生资源不等于原生显示：沙漠圈墙虽为原RGBA，scale5仍把有效1580px横宽扩成7900px；赤岩北崖2172×724画布的可见崖高仅329px却放成850px。留白不增加细节，检PNG SHA/导入/可走也不能代替像素预算。近景先记录主体有效像素→世界尺度→相机zoom→窗口stretch，超预算拆原生段，不能用整城微缩图放大近景；世界地标反过来也不能用单门或两大屋混搭冒完整微缩城。29j入城原图已显城门模糊，此前视觉漏验应记为返工，不能拿技术成功反驳用户。TSCN静态审计先规范化内存CRLF并拒绝零节点，原文件不改。详docs/changes/desert-city-pixel-rework-20261029n.md。

2026-10-29n：透明建筑换牌后的生成图尺寸/主体坐标会变，必须重测脚锚与基础占地，不能套旧图参数。台阶低层但门洞仍整块高层，会在门前切掉主角头部；本次精将门洞与踏面并为原UV低层，墙柱高层和实体不变。室内屏风虽不堵物理通路，仍可能完全遮住柜台人物；需要看一次真实图，本轮撤唯一屏风图与实体，其余NPC/对白继承，不为家具强行保留遮挡。

QA必须静查实际ExitZone的 `_can_enter()`，不能臆造公开can_enter接口；异步脚本主协程报错不会自动结束SceneTree，应有独立watchdog。真实键盘计tick时按下后先await process_frame会吞入截图GPU耗时积累的多物理tick；先同步physics边界，按下期间只数physics，原FAIL保，残余只走未过出口。用户中途运行自己游戏产生新save要保现值与原差异，再只读冻结当前哈希/bytes/UTCticks，不回滚，也不能宣称相对最初零差。

2026-10-29m：没有形成真实院界的孤立短墙，不应作为街头装饰随手摆；撤除需精到owner的图、navigation row、solid与专属地面，不能只hide图。overlay新增row应从visual_additions移除，不能塞到只作用parent旧row的visual_retired。墙图自带脚座随本体退；ENV的大院铺地并非墙base，不得按附近位置误删。NAV仅恢复撤墙poly且检查其余solid重叠，整typed payload与整RGBA逆证明保原父版；本轮2530像素、两实体同步退，其他院界保。

明确城内近脚的公共go_field_smart调用，最后local版本必须传C.VERSION=3。空进程中−1会按旧版1而被PUBLIC_CITY_REQUIRES_CURRENT_COORDINATES拒，world版本15不能替代local版本；首拒尚未执行导航或来源验收，不为坏测试去改生产安全规则。保82548 FAIL，仅改测试参数，后继158/0与80真实ticks局部跨两旧墙、一原图即可，不重World/入口/三城矩阵。共享immutable runtime/binding的必要SHA传播要维持CT Field+C两pin与29l Router承认，不漏旧消费者。详docs/changes/luoyang-gate-isolated-low-walls-20261029m.md。

2026-10-29l洛阳入口：机械来源“全逆通过”不代表运行时准入通过。Authority.edge_valid要求新snapshot只能为canonical或res://build/luoyang_前缀；jinling_city/three_towns新快照字节正确但目录不合法，导致历史approved链仍拒。保原规则，发布同字节合法副本，仅精改实际边引用并保旧快照/来源键，不能为新目录放宽Authority。

独立模块的直SHA循环不一定消费EX后继，洛阳Culture.readiness26源中Router仍锁旧D25D，单更新9闭包与新城实测不覆盖它。只对确切Router使用既有AP_NPC._source_matches闭集/完整逐边逆承认，其余25项直SHA、文化合同/剧情保持。之后公共Router每次更改，封包前实际跑Culture.readiness+Authority.approved关键历史pin/未知SHA拒，不重复全城却必须覆盖旧消费者。本轮仅headless21/0与一腿World真Space入Gate86/0/32px原图，原失败日志保留。详docs/changes/luoyang-entry-regression-20261029l.md。

2026-10-29j三城World接线：原生可F6地图还需正式HUD、系统面板暂停、状态与室外返脚包装，不能只把门户指向草案。存在World默认/v15双alias时，要记实际来源ID与脚点并原alias返回，M面板重新加载canonical资源，故运行时增门应有同注册表只读显示层，不污染旧cached layout与原16门证明。真实新增solid先查Player实际CollisionShape，再保原nav/stream guard，不用一点可走代替完整脚体。

QA `--script`若静态引用依赖autoload的HUD类，会在autoload注册前提前编译报GameState未找到，造成假World加载失败；改核实际实例脚本路径/实际Label值，而不改正确正式HUD。关闭原生Title/Status/Hint时也要隐藏独立TopPanel，否则留下空黑板。Camera.position更新不等于该帧Viewport scroll已同步：初次装配移动actor后，native update_view再force_update_scroll，直接核screen center和actor canvas投影；UI节点PASS不能替代看首图。旧失败保留，功能成功不因视觉残余整批重跑。详docs/changes/three-towns-world-entry-20261029j.md。

2026-10-29k：同一台地边有多个阶口时，必须对已有边段逐个扣除开口，不能每遇到新阶就从完整边重算，否则最后一阶会封掉前一阶。短桥要先落平岸再接侧路上台，验证终点不可伸入台地侧墙；桥缩短后的桥栏净宽需按35×25脚体重核。北向坎立面应被上层面遮住，不应全部绘成院后高墙。并行任务改公共Router时保留首guard拒绝，再核当前独立场景无该依赖，仅发布新命名空间，不回滚对方版本也不声称全部保护文件未变。详docs/changes/sect-maps-20261029k.md。

2026-10-29i：楼梯必须改变可达层级。只有楼梯图片、侧墙碰撞与W/S通行，不等于地形起伏；需平台高程/连续边界/入口状态/踏面插值/上下层碰撞与建筑脚点共用数据。验证既要连续采样真实升降，又要非阶坎/中段侧向逃离负控、移除阶边的可达性反证，以及默认出生点全程真实行走。分层AStar允许跨阶，验证“同层接近”时必须限制层级，否则会先上另一阶再下目标阶，不能把验证器主动中止归咎地图。键事件按帧刷新；图例/截图不能替代通路。保存运行时装配为原生场景后，需防重复生成和二次抬脚，坎碰撞不得被通用物件层重赋值覆盖。详docs/changes/miao-terrain-20261029i.md。

2026-10-29h：建筑丰富度需要层数、开间、屋顶方向、檐廊和附属用途的差异。普通门与112px人物应保持接近的成人尺度，宽厅增加开间、窄高楼增加楼层、单宅去掉上层，小粮棚明确储藏舱；随机整图缩放会同时改变门窗、柱粗与瓦片尺度。截图先查真实脚体可走，岩体内的传送脚点不能拿来证明实际行走遮挡；保首图、改到正常地面，厅前可走树冠的可见性另用一株独立材质局部窗口解决。详docs/changes/miao-building-variety-20261029h.md。

2026-10-29g：总规的核心要先落实空间拓扑与建筑支撑关系；用同风格屋顶排成三横台地、均匀铺满石路，即便所有通路检查通过也可能完全偏离溪谷聚落设计。用户视觉拒绝必须写为拒绝，不能继续用旧QA计数当符合证据。高架铺街屋体前景要排在前步道居民背后，不能只给主角开透明窗而把NPC挡成腿。水域负控坐标随真正中心线变，不为旧直溪oracle改正确斜溪；巡路查实际碰撞器并窄移房/路线，不删真实阶侧墙。详docs/changes/miao-recompose-20261029g.md。

2026-10-29f苗风山城：原生4×4atlas尺寸合法仍可能是宽跨重复，不能把四向站姿当四向walk；保原稿，独立登记contact/passing四相后继，实际只采用侧行并明示左镜像/上下未采用。世界脚深度改绝对z后，桥阶踏面也必须取消父相对z，仍保全局低层；克隆房不可共享同一个人物窗口ShaderMaterial，否则最后一栋参数覆盖全组。曲流视觉改动要同步真实水碰撞，并保原桥面窄走廊；巡路用真实35×25脚体sweep，附近短凳也会阻路。原85/1失败与后52/0、新物7/0分开保存，成功前缀不复；图鉴结构字段以thumbnail/diskPath为准，错误检查器不改生产适配。详docs/changes/miao-town-20261029f.md。

2026-10-29d：整件低院墙也要按前后深度分层；整体以最前脚排序会让后墙横压井棚/客栈，源PNG不用裁图，用同UV无重叠region分层。城墙遮挡不要整幅透明，采用仅主角身周的世界坐标羽化窗口，全景禁用；原图放大软度另作美术限制记录。院口本身可走仍要查院内中轴，陶罐在门后80px也会挡35×25脚体；移罐不删墙。Godot键事件若紧邻物理帧读取，须process frame+flush证实际派发，不能拿同节点存在当已入室。配置/tscn构造器不能省小数前导0；首49/2与222/5 FAIL保，后继只查残余。详docs/changes/desert-town-20261029d.md。

2026-10-29b金陵：完整石桥不能只用踏面点PASS代替沿岸横街真走。首桥.68/.62跨440px河但长端伸到岸路，桥中/岸点全过仍在北街x1620撞栏；只整图等比缩.46/.44并同步原UV栏/实体/岸口，真横穿3km才证断点消。基类`_scene_object_nodes`是Array[Sprite2D]，原UV栏Polygon2D须进专用Node2D列表，不能运行时硬塞；静态不重建检查也须包含该自有栏列表。

NPC入场占地必须匹配实体创建时的源帧与scale，不是后置显示scale，更不能猜脚下0..32框。NPCNode初始.9/160帧建20.16×25.92体、ground-anchor抵消偏移使体居中；Field后来.8只改显示。金陵假域把合法Shop返回脚2584,1944拒掉，按原源式/居中/巡逻sweep精修后原脚返回通过，不跳过NPC或找最近安全点。Hero首图也应依现役neutral配置，不拿旧portrait期待去改正确生产。南岸20px材质缝仅三cap6Y补齐同worldUV石路，最后一图0INPUT，不重功能或全城矩阵；两整FAIL与既有退出ERROR均保留。详docs/changes/jinling-waterways-city-20261029a.md。

2026-10-29a：复制TSCN子树不能仅用`parent="Town/Dwelling1`前缀匹配，会误带Dwelling10的Art/Body成为Parent vanished孤儿。须要求节点名后是引号或斜杠；物理测试通过不代表场景实例化无警告，需读完整stderr。家具负控要从可走院内侧接近，不能把起点设在前墙实体内而为坏oracle挪墙。赤岩原斜线过阶侧墙应经上口正交接路，不能为快捷斜穿删真实护墙。详docs/changes/redrock-city-life-20261029a.md。

2026-10-29a：汴州本轮176技术检查过后，原生总览仍暴露灰石大坪、草土贴岛、四块无耕行的假田和裁脚女性，不能因此报整城完成。优先修连续院地、石街真实粒度与已有精灵完整性，而不是继续堆楼或重画。旧女性条虽为合法640×160四帧，每格最后一行仍60余实像素，源本身缺脚；补透明留白不能修复缺失主体，应换完整有鞋现货及职业年龄一致头像，原PNG不修画。

道路同层按创建顺序覆盖会把石环路截断：本次只统一PAVING/STONE/SOIL绘制层级-998/-999/-1000，保碰撞/路线/脚点；最后仅18检查和一张正常图，不重109/176或整图矩阵。通路oracle也须止于真实道路端点：西环原到4456，不应强测到4970穿工坊而为错误检查搬楼。7登记迁移落点另是真缺陷，需避新增巡商完整sweep和铁砧，不能把两类错误混在一起回滚。

用户明确普遍允许后续同类“保原图/全RGB/主体RGBA，仅框外alpha1杂点清理+补RGBA0留白”，不要反复逐批问；范围不扩到重画、改色、任意去背景或擦可见阴影。整城图是独立审阅相机共享真实World2D，不是烘焙底图或普通游戏镜头；八区室外结构可交付不等于参考图密度、全部室内或全ART验收。详docs/changes/bianzhou-whole-city-finish-20261028c.md。

2026-10-28e：楼梯中央能走通不能证明能正常上阶。整图以底脚参与Y排序会把步入踏面的角色全盖住，必须把踏面与遮挡侧墙分层；侧墙应按原源图轮廓同步绘制和碰撞，不用两竖直矩形猜。赤岩旧中段可见率0、新九位置1，补三阶真实W/S上下后才授该组件通过，保留旧漏验记录。详docs/changes/redrock-stair-surface-20261028e.md。

2026-10-28d：峡壁围合不能仅把同一L岩沿边界排队；赤岩首轮总览仍断续，改为分别原生绘制西/东长壁与北横壁，再做岩坎接缝。真实NPC路线同样会占据静态主通道，必须在足体检查中保留NPC实体；石匠带从2590移2660才放开原路线。追加渲染截图若手工改Camera后仍每physics被controller覆盖，会截到错误地点；用实际主角跟随位置补图并保原误图，不拿save_png成功当构图正确。详docs/changes/redrock-desert-complete-20261028d.md。

## 2026-10-28b 替换占位人物时要区分 authored 保护域与实际 NPC 自动体

汴州街段1213新域检查通过仍在图中暴露旧debug小人。换现货正式4帧而不改NPCNode时，碰撞会按源帧尺寸从占位192×256自动变为160×160帧对应20.16×25.92；不能只因Author ID/脚不变便声称NPC物理体逐值不变。保留正式合理体、只复核人物显示和短步；原路体迁移已过组件继承，不重复1213。

## 2026-10-28b 新街坊会占旧保存脚；低货碰撞不能按中心猜

新增实体后继续沿用旧本地布局版本，会让原合法保存脚落在新房体并被入口安全门拒。汴州升29而不改存档schema：28仅与新增body脚体保护域相交时按该行登记服务巷锚点显式迁移，域外原UV保持，v1先原投影再同增量，未知拒；不全城nearest-safe。此实现尚待新probe，不冒已运行。

手车可见脚锚偏在右下，居中190×56体会漏左把约77px。必须以原源bounds经`foot+(sourcePoint-sourceFoot)*native_scale`同步映射，不用显示宽度估体。grain/cloth同样沿源基，若扩大真实碰撞后冲突只移新货物，不挪原NPC或撤body。

2026-10-28c：供用户F6试玩的地图默认正式主角与跟随镜头；匿名巡检体/全景仅供制作。赤岩误用Inspector，现复用既有Player与四向动画，专用适配层分离本地移动，不改共享Player或重画主角。详docs/changes/redrock-player-camera-20261028c.md。

## 2026-10-28 城市返程锚点与大地图旧UV必须分清

通用门记忆的是原作者source门锚点，不是Space前任意移动脚；汴州原3102.72,245.76与实际3104,246相差1.302335px，不能为了错误QA预期改生产或放宽容差。旧World v15的city target(.535,.9)又不能因本城已记layout28就冒充新6144坐标；Entry须按真实source World选择外门，唯一39检查真往返证精落3072,5910，旧103整FAIL保。

材质路径名不证明城市适用：大面积brown_mud和无纹灰石首图均不合街市，改已有细石铺/院坪即可，不为此再生成素材。只复新分支与必要一图。PowerShell单行嵌套数组需JSON回读形状核，属性计数用`@(...).Count`；首运输/显示错误保，不洗actual事实。

## 2026-10-28b 整体院墙资产也需要按脚点分层，家具缩图必须同步缩体

一张U形院界若整体按前墙脚线排序，后墙也会压住房屋，Y排序本身不会知道图内深度。赤岩通过三个完整连续Sprite2D.region视图分后墙/侧墙/前墙，原PNG/全部RGBA保持，无本地裁图，分片总高覆盖887；真实壁体在本地像素坐标映射，四院入口/负控过。柜/桌成人尺收小时，body同等比收缩并证仅旧体内，不留看不见的大体；仅补两负控和新图，79成功不复。

隔离project.godot资源构造文本要求`Color(0.16,...)`，GDScript可用的`.16`不能直接写入；首配置拒但OS exit0仍不能当解析通过。报告事件计数也须分清3Space与1Esc：原头误4只修元数据并存原件，不改79事实或重跑成功。

## 2026-10-28a 横向岩台放大后要验整个人物脚体，不能只看宽度

赤岩首六区54检查中民巷往返2FAIL：新岩台原图视觉比例比“长宽5:1”提示更厚，等比拉到2900宽时高711，真实前脸阻挡顶到1538，直接侵入1560街线。不能非等比压扁或撤碰撞。改两短等比岩台，保持岩体前脸真实阻挡，残余只跑民巷/新增侧巷与新图，继承原52成功，不重20PNG或旧输入矩阵；14检查0/2438motion，首整FAIL保。城市可并行的边界是目录、引擎project与user-data独立；公共接线/生产全import不是并行写域。

## 2026-10-28 来源正确、可走通过仍不能把工程墙与漏底当艺术完成

27d关键actual121140的87检查全部通过，但原生图有灰空横缝、灰色竖纸条与孤矮墙。前者是只画用途surface、没有全域底地；后者源PNG本来就是工程灰tile代理，来源SHA正确也不会变成正式美术。必须在首次原生图看清后修可见问题：已有自然底纹仅z低层补漏，不扩walkable；代理墙退视觉与专属基/局部cells，不留下不可见障碍；不能把north/south屋脊段旋转拉伸冒充完整侧墙。功能成功前缀停止复测，视觉后继只拍必要画面。

## 2026-10-28 Callable 不代替 RefCounted 的长期所有权

27d实际102304在NPC投影`null::project`：Entry局部`Phase.new()`传入Callable，adopt当时is_valid，但函数返回后对象无强引用被释放。拥有异步/后续回调的Field必须同时强持实际Callable.get_object()得到的RefCounted宿主，并核脚本/方法身份；只保存Callable或在构建时is_valid不够。原phase业务/几何不需重编，修复验收应继续真实Field就绪及对白，不新增无关语法矩阵。

## 2026-10-28 新区域业务快照不能残留会随发布变化的元数据路径

27d首新区域actual在`REGION_COMPILED_CONTENT_SOURCE`拒绝：编译几何正确、Gate新hook已过，但Civic/其它bin的sources仍以canonical路径锁原Estate/Quarter manifest；必要旧接线同步更新其发布头，导致新Entry按字节校验必拒。几何组件通过不能替代真实新Field。若消费的是原不可变门户业务，必须指向已锁定的原全文快照，不把新头填成旧业务期待、不删来源检查。修复仅二terminal与九bin的sources key、绑定及必要Router来源后继，原typed几何/人物/门任务完整逆保；成功组件及Gate前缀不重跑。

## 2026-10-27 跨Family出口要走一次真实冷目标，不能只检查箭头与落脚

园林→宅园原由AP.owns_route管理，但Estate.owns_route不含园林；Router只启动AP校验，冷Estate serial仍0，目标matches被严格adapter拒。即便补begin，末尾`if AP.finish elif Estate.finish`仍漏Estate FINAL。只对这条精确AP路线补原Estate begin和独立finish，保其它路由归属与所有来源/身体净空校验；不要伪serial或放松matches。唯一真Space到自然冷Estate、两Family原FIRST/FINAL及短输入才覆盖玩家故障，不重旧矩阵。

围墙摆放不仅是比例问题：草地孤段未构成院界、花坛已有自带边时直接退除该新增段及真实墙基；遮罩仅恢复其所属PIP像素并保其它solid优先，不能整矩形刷白或还原整旧mask。本次2205像素完整逆、花坛河桥保持。

## 2026-10-27 出口与围墙要按玩家画面验收，不能只看局部净空

府衙新增百工坊门120,1240紧挨原南市门300,1220，虽然各自碰撞净空成立，玩家画面仅约190px间距，且源式payload把`City public branch`占位英文直接带入正式显示。新增支路必须写具体简体中文地名，并与原出口共同检查空间层级；移门需同步双向落脚/UV/真实触发多边形和路由合同，不能只挪箭头。

南市两后界墙把640×132整长墙缩到.38/.4，墙高只47/49px，等比缩放也会产生玩具尺度。受街宽限制时应复用成人高度的短墙模块接段，而非一味缩小整长墙或直接放大侵占通道。短墙接段要同步真实墙基/局部遮罩，保街宽，普通园林矮花墙不必一律加高。

## 2026-10-27 正常编辑器保存的格式变化应在封头前消化

七区交付后Field仍有三末尾LF，Godot保存只保留单LF，4201A29C变9CBB187A，270269→270267字节；完整前缀逐字节相同。严格来源仍锁旧值导致用户不能入城。不要补空行要求用户别保存，更不要全局忽略SHA；保编辑器规范字节，登记精确两LF全逆后继，后续候选先稳定EOF再封SHA。本次只查普通World入口，不把旧显式near入场通过冒充玩家路径已覆盖。

隔夜编辑器重导入还把112份媒体导入产物的mtime刷新，但203份受查媒体全部SHA/bytes不变。修复前应以内容确认继承、重新采当前ticks作为本轮保护；不能拿昨日mtime拒绝开始，也不能回写mtime伪装没发生。原备份01在复制前失败、0备份0正式写，保留；02只修新鲜基线边界。用户save_0及bak的新值保留，不能被昨日测试快照覆盖。

## 2026-10-26 七区收口：有效返脚与现役碰撞必须属于同一投影视图

新增百工洗盆的真实碰撞覆盖了东宅早期返脚2290,674，但最终现役返脚已迁到2460,504；G在最终迁移前拿旧脚检查新遮罩，导致整区拒入。修复应仅让既有三个迁移房间的预检读取已受来源约束的room_binding有效返脚，仍保原生门坐标整等、唯一性以及最终门/返脚完整safe_body。不能删除碰撞、关校验或任意移动房屋来遮掩视图错配。原失败保留，六区已过不重跑，只续百工残余。

已完成的协作agent需要用followup_task重新启动；send_message只投递消息，不会唤醒完成状态的工作。主控必须确认任务处于运行态，避免把静候误当成并行实施。布局交付优先完成正式接线，不让重复矩阵和过细收据运输占据主要工时。

## 2026-10-26 用户要求快速试玩时，冻结可见交付段并缩小验收

布局批次应一次完成连续街段的铺地、院界、货物和碰撞，而非只有两件低矮物品就宣称规划改造。复用正式素材，最终方案冻结后只做一次局部出版、必要新图导入和一次入场/基本移动，不重跑旧城区与已过店铺。详细视觉、比例与完整通行交用户试玩；不因基本进图通过而称整城完成或加载达标。

## 2026-10-26 家具改造必须一次贯通可见物、通行几何与真实碰撞

当铺首版只换G作者视图，Field仍从原layout读取六个blockers，会造成新货架可穿、旧椅柜位置幽灵阻挡；不要到部署之后才检查这条消费者链。实施前同时检查视觉投影、安全几何、实际StaticBody构造和淡化名单。共享常量名也必须追到真实脚本：Field的ASSEMBLED_ROOMS是旧包装器，没有author_for_id，现役G接口在ELEVEN_ROOMS；此疏漏造成一次真实编译失败与额外来源后继，责任在实现和主控审查，不应归咎用户编辑器。

门坐标要推演到最后消费：DE191的pawn threshold5501940是中间作者值，D296城市分支对非药/书入口实际采用return_foot5501964，最终finish仅替换Temple门户。QA误取中间值会在真实门前失败，不能据此修改生产或声称门不存在。冻结前完整追踪最终投影，可避免反复重启和清单重封。本次最终两轮真实Space进返、四对白、真实货架阻挡通过后即停止，不重复整城矩阵。

## 2026-10-26 门能进入不代表交互键最终派发到门

Market→Temple真实单腿57820的门polygon、can_enter、完整身体与Physics都通过，但Space触发了`NPC.npc_action_requested`，DialogPlayer实际打开`runtime_spar_preface_spar_luoyang_patrol`，没有Exit信号。巡捕真实脚1260,1580距门1170,1600为92.19544，小于NPC原118兜底且Area也命中；immutable24b曾迁过该站岗，后来的环境NPC表静查漏掉了它。诊断应被动记录有序全部NPC、出口及实际信号，不只测目标门，不把Router public空/C无错误判为加载故障。修复优先清理此岗位与门整polygon的交互净区，保全局NPC优先级、任务与动作。原失败保留，仅续失败单腿。

浮点断言必须沿实际作者常量：原Task MONK_SCALE精literal与QA重算140/148可能不相等，JSON舍入同不能证明具体bit原因；身体varbytes/位置/其余12项精同只证明缩放预期来源错误。新断言先锁原Task SHA再读其常量，不改角色、epsilon或从观测反填期望。Hero首对白头像同理应沿当前GameState默认`protagonist_neutral.png`，不能猜另一个主角图名。

## 2026-10-26 投影结果与内层收据不能混用字段合同

Temple Task 返回的顶层有`ok/matched`，内层`receipt`只含阶段和人物形体等证据；adapter已经验证顶层`matched`，但Field复制内层后，新显示helper又检查内层`matched`，导致实际116100在parent/owner门必拒（0图0Space）。修复应在精确Temple适配边界把原顶层真实布尔值传播到消费收据，而不是删消费门、写常量true或改任务阶段。其它Weak身份/FIRST/存储门全保；字段缺失的确定静态拒因与现场首个细分predicate未单独观测应分开记录。整体失败通用标签含60s不能据此误报为超时，需看实际elapsed和首个生产ERROR。原FAIL留存，修后仅续未执行前缀。

## 2026-10-26 正式屏幕模型也必须进入空间与截图验收

Temple原design1536×1024在1920×1080下均匀cover成1920×1280、worldorigin(0,-100)，本来无Camera2D。Family截图测试强求camera!=null会误拒合法画面；精单屏分支应核源式origin/scale与无相机，不改生产镜头，记录也不能继续访问null camera.zoom。更重要的是，源y980合法碰撞脚会变world1225，落可见下沿1180以外45px；只验safe_foot不足，入场需同时验完整人物/箭头/标签可见和有效门户返回。child景深也须以actual centered及f32阶段计算：Estate centered=true local(-208,168)，同PNG的Temple centered=false local(893,812.5)，不能照搬常数。

新墙须先核真实水域/原solid，再检查A1与路线。Gate740墙虽不交可见楼和旧路，却全在护城河blocker内；应取消，不缩河或移旧桥硬塞。Inn薄墙只碰Player扫体1px仍挡路，应取消而非epsilon放行。JSON整数坐标经JSON解析为floatArray时，不能直接同intArray做typed==；逐scalar有限、整数性、精ceil/floor值后转换，形体不动（39680原FAIL、30628新域通过），不得把格式门修复冒几何改正。

## 2026-10-26 Godot实例IID与自增serial不能共用正数门

RefCounted.get_instance_id()可返回合法负int64（小域97488实际-9223371883745900042），0才是无效ID；C/Family自增serial则仍要求>0。统一adapter若把两者都按正serial判断，会在Temple.prepare通过后拒原FIRST租约。修复必须精确限定原Temple scene+kind的非零IID，并保instance_from_id/Weak同一实例、Scene/Layout/原token、FIRST/FINAL全等；不能abs重映射、另造serial或整体允许负数。103132的5组24条件只证明这一区分和负例，不等于实际Temple会话已进入，真实门户仍需一次必要验证。

## 2026-10-26 合并运行分支需继承视觉副作用与初始化

25i新完整碰撞分支install_static后return跳过NG.install，而旧NG同时创建Garden水面视觉；故导航/门户可通过但原图桥下草地。应拆出原sourcebound视觉构造继承，不能重跑旧整套碰撞造成重复。Estate则未命中任何旧遮挡helper创建分支，admit_depth在helper=null即拒，尚未读ID集合；不能凭错误文案放宽ID或删实体。码头真实Space被80px旁NPC抢先响应，portal can_enter真不代表玩家能正常触发；作者必须同时留身体、触发与交互净距，验收不能换站位绕过。

## 2026-10-26 来源清单通过不等于消费者内部硬 pin 已同步

25i D581把Router由908F更新至E983，Stage32的完整文件SHA、旧source分类与历史边全过，但CT生成器仍只允许C/Field两个值后继，漏Router第三项。原Coordinator.readiness对CT内26个值直接get_sha256精比，不调用EX历史批准；实际C91108在Field已构建后拒CULTURE_X_SOURCE_CHANGED:Router。Temple.source_paths可正确收集当前Router，也不代表prepare使用的父+delta有效196项期望已更新；该合并表仍908F，会同因拒。不能靠关闭exact门或接受当前磁盘修复。

后继Stage应把direct consumer内部表逐项与明确prospective候选SHA/未变固定旧值比对：本案CT26与Temple196都只Router旧，W24、Quarter/Estate头与74个直接literal JSON有限静审未发现额外活动硬pin（System04F0877A/SourceD49AB9B5）。旧作者允许历史EX、AA/AC显式UTF8整逆适配与CT/Temple直接current-exact是不同合同，不能用一个泛化“source合法”门替代。精确更新CT Router→Coord→Temple及必要metadata，不触Scene/几何/玩家存档；原FAIL保留。

## 2026-10-26 冷入口、未完成租约与源式门户坐标

新Family严格ensure要求原validation serial>0，已有scene_path API不能替代begin→原matches→FINAL生命周期。若公开直入跳过begin，失败后掉经典controller会误猜不存在flat tres；应修真实生命周期并对该明确Family拒fallback，不用复制假tres。失败FIRST Weak快照及runtime未FINAL冷state须一起精身份释放：同Scene/Layout/kind/key/token/全FIRST、field=null且未FINAL/未released；已FINAL、正在显示或parked的租约不得清空。仅清Family字典会使下一serial继续撞旧runtime owner。25i相关候选与独审7E11B76A记录其范围，未冒真实入场通过。

真实portal row可能早被先前作者迁移：Docks旧ferry340,1840已变2140,1840，新作者只改目标时保留该pos与polygon，而路线合同和QA仍硬写旧340，导致真Space之前唯一门筛选拒。必须从固定父payload/portal_moves/manifest完整追继源脚，并联同runtime到达合同修复，不能按最近出口猜测或只改QA字段绕过。

撤除穿叠建筑不能只删Sprite：25i新封包廊同时含四柱脚solids及可行走图黑点。唯一局部37092/120检查0证明2928点域中只630点需恢复固定父support（其余仍被原office挡住），完全payload与RGBA可逆；不能把整域刷白或把原建筑碰撞一并删去。技术通过不替代最终实图不重叠验收。

## 2026-10-26 合法版本链不能用固定16层截断

25i第二个必要后继合入后，NPC不可变作者仍引用合法Field F4BE，但现役F84A到它已累积17条精确登记边；旧`approved`固定16轮提前返回false，导致NPC `source_paths`为空，继而B/C公共入城在Field构建前失败。顶层当前manifest与期望2032源完全一致也无法暴露这个旧作者的深层历史pin。独立QA逐17条snapshot SHA、原顺序替换和完整UTF8逆验证通过；不能把“保持16常数”当作历史合同完整验收。

必要算法候选只将遍历界改为固定批准行的`edges.size()`：任意可达简单路径最长不超过登记边数，仍有visited防重，原header/当前canonical SHA/OWNED闭表/逐边hash与全字节逆全部保留。不是加快捷边、随意提高常数、接受任意当前磁盘值或关闭来源校验。唯一逻辑实测98216自然0/43检查0/397ms：原16拒17跳祖、新界接受，当前/相邻历史都保持，未知SHA/坏格式/非owned路径仍拒；只属逻辑候选，正式来源闭包与实机仍待。以后Stage必须检查原消费者真正固定的历史SHA可达性，不能只核新边正逆与顶层metadata。

## 2026-10-26 门户脚点判据与Area重叠缓存应分开

25i A07从远处检查定位到府衙出口后，QA额外复合条件失败而未记录分句；09新进府衙原本就在门脚，原复合条件通过并真实按Space返回城门，但不能据此证明A07同一时序或暖返。生产v3/world门户用公开`can_enter`（脚点在门多边形、guard与锁），不消费`Area2D.overlaps_body`缓存；原ExitZone没有该API时则必须保其真实`_in_range`触发条件。QA应记录分句、采用对应生产判据及完整玩家碰撞/精确目标，固定有限物理阶段后发真实输入；缓存overlap作诊断，不循环等通过、不改生产门或追认旧wholeFAIL为PASS。

## 2026-10-25 运行中的入口脚本不可用CACHE_MODE_IGNORE自重载

统一总览04将当前SceneTree入口自身纳入`ResourceLoader.load(..., CACHE_MODE_IGNORE)`解析列表，前五依赖解析后当前脚本方法失效，line186报`Nonexistent function ''`，45秒限时自然OS1退出，0场景图；原FAIL、日志与收据273CAA9C保留。入口本身已由进程启动成功编译，Root外部精SHA及首末SELF字节核验足够；只加载未运行的纯依赖，不能强制热替换正执行脚本。05后继只撤SELF重载，原5依赖与渲染逻辑保持。该错误仅测试入口，不修改生产脚本或要求用户关闭编辑器。

## 2026-10-25a 内置透明原图不保证存在精确alpha255

赤岩井棚/工作台是真RGBA，有alpha0背景与大量alpha250–254主体，但最大254。首QA把“真实透明”误写为必须有255而FAIL，原失败单列；后继保原值、报告min/max/255数量，只验证透明通道事实，不授合格运行图。完整A>0留白8张仍全FAIL，不能把alpha128的主体框当留白通过，也不能擅清弱alpha。共享根tasks在独立生产窗口内变化，末检如实列差且保当前，不能仅凭自己没写就宣称首末全同。

## 2026-10-25 店主服务事务、分房来源与静态房镜头验收

原室内`npc_policy`为空不等于spawn故障：新增服务身份应在原投影/来源FIRST与FINAL闭环内接入，原铁匠保唯一ID，不向其余八房拉入SKU域。owner准备期只允许canonical Field真实同步ready窗口；正常交互仍须当前owner、玩家距离、来源完成与非transition。消耗请求必须先标记一次性，再按确认时全队当前Stats/max/gold原子校验扣费；全满、拒绝、不足与旧owner不能产生副作用。换房/战斗/重建只结束本helper自己的对白，不取消无关dialog。商店关闭原Router允许重建Field，不把客栈同owner条件误套商店返脚。

单屏房1536×1024在原1920×1080视窗按既有规则无Camera2D、世界容器居中偏移，并非生产镜头坏。QA截图不得硬要求相机；锁原无相机/容器变换/静态viewport期待后只补未完成项，原失败和已过inn菜单保留。打开ShopUI并Close不等于执行买卖；图中可读确认与正确扣费也不能掩盖快速连测时旧黄色toast同位叠的视觉瑕疵。QA整段14.973/9.581秒不是加载成绩。

ResourceSaver对metadata Array会擦除typed容器属性，先对原scene/layout全部storage差量诊断；只将源中该metadata显式构造untyped容器、保持PackedVector2Array项及序值，补尚不存在packet，不重跑已过桥像素/几何。来源合同原inline JSON数组必须按raw字节精替换，而非用encoder重排；分类投影重复和历史不存在的索引键应在新候选窄修，不关门禁/加shortcut。

## 2026-10-25 院落拼接、局部先验与结果汇总不要互相冒名

围合应按门前净空与真实构件组织：完整复用灰瓦廊时，只4柱脚碰撞而非屋顶大矩形；降短孤立高墙、撤廊下重复帐棚，既有门/NPC不搬。柱间实际111.6虽满足96净空，不能因旧院口120而继续写120；f32精值照实记。原1396路线擦既有买菜NPC，应调整新测试的合法起脚1384，不移动NPC让验收通过。新增1.35安全裕量仅本新域，不伪称继承生产合同。

Godot Dictionary.merge默认不覆盖已有键，初始化passed=false再merge passed=true会造成检查全过但整体自然1；原FAIL必须保留，剩余只读核精SHA报告/产物与独立先验后单独准组件，不重做几何洗失败。来源Stage的ancestor模型先promote_owned至新authority后，其后exact-old断言也必须迁到新owned值；只修数学模型断言，不改现役增量/历史权限或放宽depth。源检查器必须读实际部署收据schema，不能预想GD_apply_patch等不存在字段。

## 2026-10-25 材质用途要核真实纹理、绘制覆盖与默认参数

语义asset键不等于不同纹理：南市road_stone/court_stone实际同PNG，同尺度相位加较弱混色仍是同一大片灰砖。`texture_contrast`实际是mix权重，core又把旧石底透出，土院原纹理实际仅14.52%参与；先核采样源和覆盖顺序，再以真实材质的方向/尺度/实覆盖分用途。后画铺前曾盖掉主街47.33%宽，土院又吃掉服务支路，视觉优先级应从原用途矩形派生，不修改导航迎合图片。首350/0总览仍因深巷如地毯ART拒；只收敛巷色与原纹理权重、保几何和成功材料，不能用参数不同代替实看。

Godot ShaderMaterial未显式设置的bool默认也可能读回NIL，不能假设只有未用uniform如此。只对本例两legacy材料，在精shader/helper SHA、唯一false默认literal、唯一i<4显式true设置块都锁定时解释缺省；明确记录原NIL，非NIL错误仍拒，不加生产setter或泛用NIL→false兜底。原26/2失败保留，剩余55/0仅补材料与一图，不重门/路线/collector。工具JSON转义外观有歧义时核实际UTF8字节和解码文本count，别因双层显示再造一个修复版本。

## 2026-10-25 首检预热、source闭包与QA空间域须分别证明

连续来源后继不应每次从最老AO表重提历史：新Coordinator到原29E恰16边，而既有range(16)只测试深0～15；这是Stage seed问题，不能扩上限/删边/临时shortcut。可从精SHA锁定且已验收的现役parent map做有限变更，原approved仍核新1边；保原四AO literal与五门禁，另用旧声明模型整表精等证明集合，但数学相等不能冒历史授权。原FAIL和新build入口都保留。QA对JSON nested数字Array不能直接比原生intArray：按有限numeric schema转原Vector2精等，0epsilon；precheck失败后的complete=false scope FAIL只是级联，不应加预算或篡生产迎合它。

世界真正hidden可动post_draw后可投机做合法Gate完整纯SHA首检；claim仍收集完整keys/values并匹配Scene/epoch，fresh末检不复用。2→默认8路实际把本路径首入11.193s降至8.813s，不能外推进程/SSD冷或全城。最大帧隙必须从首World postdraw内开始计，旧32.695ms遗漏166ms同步块；新169.108ms如实保留，性能达标不等于无卡顿。

复用PNG会由原C collector展开既有import/ctex两叶，来源准备必须保该三元组；修叶域之后还要查finite header嵌套legacy AP来源边，不应关闭B门禁。Node Vector2→UV→Field全链f32与JSON raw double可差1ULP，QA应从原标量推导逐层f32精值，不加epsilon。World真实Circle5不能套城市Rectangle34×24；横巷撞既有NPC时按源布局走合法间隙，不暂停NPC或搬身体迎合测试。Docks完整39导航与任务阶段非阻挡视觉分开：导航全值核，三目标行精迁，任务证物显示仍由原producer掌管。

## 2026-10-25 有限发布器要先保存成功组件，并区分真实剩余项与失败前缀

新布局的物理通路不能只查主角34×24：任务NPC34×30在8801340与灯右缘863.635相交不到1px，真实消费末端精迁888后1085+17点和闭形体才清。原任务链还会在native800之后再次投影1320/1290→880，必须追到Coordinator之后的真实spawn与resident刷新两处，不能只改作者或QA假人。失败路径后的六room-return尚未执行，继承通过前缀时须补这六项，不能把“纸匠最后失败”误写成所有其余项已过。

有限publisher应先冻结mask/投影/几何成功组件再做后续路线，失败后仅检查剩余项并生成小header；未记录的前缀样本数保持null，不从口述补造。GDScript Rect2i.intersects没有Rect2的第二参数；JSON数值Array与原生intArray须按有限精整数schema逐值比，不能放epsilon。混缩进与同scope重复变量会使运行钥匙或依赖解析失败，正式前要统一一次候选parse；挂起时只能确认父PID/命令的自身child后停止，并纠正旧launcher的“natural”标签。原Router混CRLF/DT尾LF运输也应整byte保护，不能暗全文件格式化。

## 2026-10-24 原生几何证据Mesh不等于完整渲染Mesh；局部技术过不能替代艺术审查

world v9c的actual_world_draw_geometry按index展开只存VERTEX，NORMAL/INDEX/UV为空。同原证据数组只证明顶点，不证明原建模法线或纹理相位；再渲染时应明确由原author-UP/Box朝外面恢复法线并另列UV属性，而非把偏浅光照全部归PNG。source平面经PPX/ZPPM异比变换后along/lateral不正交，逐板纹理要用真实skew basis inverse，正交dot会出现斜向编织格。新增侧底须独列顶点，不能继承旧19mesh全数组同信用。shader参数名与类型须实际get回读；默认值碰巧相同不能证明fixture绑定。

两无缝提示材质均可能接缝失败；唯一模型edit若更差且重绘中央，保原v1/v2和数值事实，不追加循环或暗做本地像素修复。对照234/0仍可ART拒，后继1688/0也只能是局部材质基线，不代表自然河岸/桥头结构/正式世界完成。fresh保护快照前已有外部save变化应保原失败、明示新epoch，以本轮前后同证明边界，不回滚或追认旧epoch全同。

## 2026-10-24 最终渲染消费者、自然入场脚位与历史链上限要分开判断

native占位楼的尺寸不等于最终可见楼：DT/DG后还会由G同ID换图。先追最终素材/锚点，再做比例；移楼必须精退旧native和旧用途基座、同步图片/Physics/mask，不能只挪sprite。完整像素逆记录留作固定来源审计，运行时只解析同源小header且完整大记录仍在首末SHA域，避免把审计JSON当每次入场数据展开。

固定16轮校验只检查深度0..15；新增精边可使最老声明从15变16而拒。保原边/成员/上限，仅允许固定两端、全文正逆通过的明确复合捷径，不扩大任意历史权限。新nested驱动的相对parents必须静态核CORE绝对路径/精SHA，不能只看脚本文字逆。

public near可能合法返回安全fallback，不可把测试near当精确最终脚位。原wholeFAIL保留，仅对未完成腿先证明显式QA inspection setup前后真实净空，再真实INPUT；不能冒两院连续旅行或默认性能。生活NPC的运行ID由CROWD统一加district_life_前缀，找不到未加前缀ID不是门控证据；既有clerk有限overlay也要叠到最终期待。24c后7个NPC实查活、另2UNKNOWN，不强显/挪NPC迎合测试。

## 2026-10-24 新原生与用途层的消费者合同须逐层闭合，勿用测试期待改生产

完整城市source map包含新packet/Scene/layout/walk，不代表同token worker子域自动含这四事实；应从固定binding精确投影，保原逆与token校验。原几何PackedVector2Array在只收Array的decoder会变空，修有限Packed分支并duplicate、保原Array路径与派生实体等式，不直接拿packet.solids绕过。用途组从两种变四种贴图时，预载集合必须跟新消费者取并集，而非沿旧ground rows；原素材hash与其余场景保持。

显式near调用要带当前C.VERSION；warm室内返程使用remembered门槛，冷authored脚另被验证，不是同一个期待。静态mask/建筑路线不涵盖运行NPC身体，不能把穿过固定NPC的测试阻停当建筑导航坏或关碰撞迎合。文化菜单ID由空nodes和`x_%d_%s`源式生成，不能沿旧TRES猜`menu`。每个原wholeFAIL都保留，仅为尚未完成的窄项做独立suffix，不重入室/重复街景/再跑已过对白；最终菜单拒接79/0只授它本身，不能洗前面整体FAIL或授默认性能。实际看见书生仍waiter肖像应登记未修，而非只凭英雄开场成功冒全部肖像通过。

## 2026-10-24 原底图格式、共享深度层与固定视窗须按实际源式处理

正堂原壳PNG是RGB8而非RGBA8。运行时局部clip需要alpha时先兼容两种格式、只在内存转RGBA，保原PNG；错误格式guard曾导致房间安装拒绝，原失败保留。新柱必须与Player共用现有ActorLayer，挂在WorldContainer会被严格native depth快照拒绝；0hit只有snapshot与preview有效后才有意义。固定单屏房间没有Camera2D是正常分支，测试应核WorldContainer中心变换，不改生产相机迎合期待。最终有效3092相交/人物ghost与两端0、真实INPUT正逆补完剩余项，不重做已完成入口/几何。入口着色器COLOR已含纹理，重复乘TEXTURE会暗红；用入口专用后继修正，保共享NPC与锁定门禁，并以三态两尺度GPU原图基色对照验证。

## 2026-10-24 NPC对白必须追到Task投影与文化包装后再写期待

南市书生原TRES/overlay的ch4_luoyang_paper_offer只用于投影前严格身份匹配。Task.project在Field实例化NPC之前经PREFIX+paper_offer生成luoyang_city_tasks_20261016/paper_offer，随后文化Coordinator保存当前dialog至culture_x_primary并改interaction_action。新图不能改对白；65新图/身体/脚与自然完整来源都过，但测试拿旧原图配置当最终ID而整体FAIL，必须保留。后继只核正确源式配置与剩余相机图，不重默认加载/全来源或身体。

## 2026-10-24 遮挡期待必须包含当前角色帧，不能只用世界脚位

长凳同一foot1176，63走向上帧无相交，64public近点静止默认帧则114相交；这是按当前actor alpha与prop alpha的原遮挡合同，不支持生产坏。64只因未经证的initialfalse期待整体FAIL，0INPUT不能补写成路径通过；保114人物ghost/物件alpha1的实际组件并停止重复测试。近点检查也不能授默认首绘或连续旅行。

## 2026-10-24 路径可走不等于必然像素遮挡；Root构建目录不等于runtime authority

四物件875+17路线清空只能证明可通行，不证明终点的actor alpha和prop alpha相交。长凳1176点在脚位1224后方仍可完全离开低矮凳面，0hit不能直接诊断生产遮挡坏；保1193/2整体失败与前三组件过，补验只测新独立更近suffix，不重前三或改像素阈值。另一方面build/Root中的新proof/snapshot是普通来源叶，不因路径含root即可归runtime_authority；B.ROOT实际是data/maps的特定包根，finite adapter另有精白名单。Source DAG/所有文件hash过仍不能代替实际manifest分类可接受性；修分类迁legacy而非扩白名单或删校验。

## 2026-10-24 授权目标并入后继保护集，不能照抄旧路径数量

62的28精确授权目标包含原2118集外的NativeGeometry正式脚本，final事实真实为2119，28授权变化、2091保持。初63机械继承2118必在采集前拒绝，保原失败；NEW仅域数量2119后继完整继承全部路径，不能删新增路径以凑旧数。旧status中的2118标签不是实际checked值，不应修改历史收据。NPC图入库、正式sprite绑定、实际Field可见三项独立记账，未实机不能冒完成。

## 2026-10-24 新媒体采用先隔离全RGBA，再防编辑器竞争精五叶晋升

书生160与walk新mask先在工程外新隔离项目导入，全RGBA必须对事前独立先验而非导入后观察值，23是导入参数数量不是Image格式枚举（RGBA8为5）。本次146检查0，只有两raw读取导出警告，不应冒完全clean。资源晋升先.import与.ctex、PNG最后，exclusive CreateNew；编辑器无需关闭，遇竞争即停而非覆盖缓存。2118保护集中本来存在ABSENT临时保存文件，复制前核对不能无条件GetItem；首预写失败0copy保留，新后继显式核ABSENT仍不存在后才继续。五NEW资源事实须单独入账，不能拿未扩域2118 guard冒五叶也在其中；入库也不等正式NPC/Family已接线。

## 2026-10-24 码头严格来源后继与候选身份键域必须分开

1726个文件各自SHA过，并不能证明来源producer非空：AA.author历史C锁与AC旧C/AA锁会让B.manifest在Field创建前拒绝。修复须给固定旧→新的完整字节逆，不把C/AA偷加OWNED、不回填当前散列表；旧author/几何仍保留。候选记录的bytes是独立约束，不应把三键candidate整dict与两键path/SHA比较；92真实pre-output失败保，94投影身份二键并显式len验证才通过。大proof经工具传输可能混入裸截断文本，必须核实际文件JSON与物理SHA；保坏E096，NEW93完整132段双向字节重构替代，不能用预测D425冒实际文件。

58自然入场恢复并不等于性能达标或进程clean：首绘13.103148s/3501功能检查过，但自然退出C0005与shader/RID/资源释放错仍须保留。先冻结可动首绘时钟，再读来源/计时与截图，后验3秒不能倒加成加载时间；setup内source-final await3.020180s与pre-resolve source-start2.817s只是已记录span，不可无证归因为某单函数或删校验。

## 2026-10-24 新书生局部清理只动外围弱alpha

用户仅授权本图主体外散点/留白。先保护maincomponent+8px完整矩形，再仅清该矩形外56个alpha1；原RGB全保、所有alpha>2及保护矩形全RGBA精同。1440扩画布新区RGBA0、原1254画布offset9393不裁，完整A1边距均≥10%；160候选整画布统一缩放，不能单独拉人物。npc_node现成人校准由文件前缀触发，新名字直接挂会变小，必须明确校准继承后才正式接线，不能把完成生图说成玩家已见。

## 2026-10-23 连续地面只合并外轮廓和世界纹理相位

两既有矩形组成L路面时，分别羽化会留下内部接缝。48保原两rect/采样资源/数量，仅六条并集外边计算coverage、共享世界UV和主街profile；前庭只RGB轻调，opaque覆盖不撤，以免旧树影重现。三角关系和像素采样不能仅凭相邻色值推断：47南侧两样本实际都在前庭外，只可当未改控制。后续以唯一当前实机一图确认，不能用静态数学证明替代艺术或加载指标。

## 2026-10-23 避免因并行容量问题重复准备整个QA

QA/System容量失败时，复用已全文独审的false47草稿FCD8/D4A3+Source7FFEDF，Root只NEW readiness/路径/SHA/output机械冻结并完整byte逆，单次残余图即可。47完整原镜头1.05实际3487/0/图60C6通过，但真C0005非clean，不能把功能complete升为进程或全城完成。当前画面证明当牌/门和退墙有效，也暴露深色前庭硬边；下一材质改动须以这张当前实图而非旧concept或旧失败无图为基线。ENV为非owned codeleaf，不能因source继承需求误增execution闭集或proof95。

## 2026-10-23f 授权padding到工程Scene需要连带保持origin与导入RGBA

新3明确许可后严格按冻结plan/processor执行，不清任何源alpha；独立逐RGBA/新增边区/源SHA核对后，保uniform pixel scale并将origin减padding×scale。完整A1合格仅属于新派生，原图FAIL及历史计划保留；已执行同范围不应再问许可。

将raw @tool试拼转为原生Scene时，贴图、七碰撞polygon与actor/camera要真正序列化，避免运行时存在而编辑器不可编辑。只晋升相同res路径隔离验证的新import/ctex/md5叶，不拷贝工程/cache数据库。Ground需z低于门后actor，否则F2临时显示地面会把人物盖掉；此例新Scene实际按键覆盖验证了该问题。结构编辑可看可走不等完整地图/世界接入或艺术验收。

## 2026-10-23e 先减少跨模块接缝，再做有限原生试拼

赤岩将岗楼/门关/门墩连体，再用各含岩肩的两翼，共两处现场接口，比独立楼墙各自摆放能保持结构。翼用已成核心作相机/材质参考，实际等比尺度按可见墙高配合前脚；共有端截面需明确绘制顺序，右核心端面突不能用PNG删像素洗掉，先原生层次对比。仅接缝中段条带无透空不等于完整墙道/垛口/五锚/艺术通过。

PNG完整A1触边仍应保FAIL；只读ImageTexture可用于隔离结构试验，不能借此当正式import过。隐藏RGB的棕色雾在alpha0时原生不显示，不凭查看器擦背景。临时土纹镜像形成重复，结构阶段默认隐藏，不再把技术试验台冒作城市成品。新3透明扩画布仍须按本批明确范围，旧12图授权不扩用。

## 2026-10-23 普通镜头应绑定原Scene倍率，不可凭经验硬写1

46实际南市功能进入且自然1712FINAL/真INPUT过，截图却因聚合条件固定camera.zoom=ONE拒绝；原Scene18行明确1.05，Field852/1517照原继承。QA应先固定原生/源码倍率，再用实际镜头身份/倍率/viewport记录检查，不能改生产镜头去迎合错误测试。原46整体FAIL与退出C0005保留，功能组件10.812653s仅near入场、不是SSD冷/完整world旅行，也未达10秒。补图应是独立残余scope，保原镜头、不再做重复INPUT/几何或伪造PNG。

## 2026-10-23d 碰撞和导入过关不能替代建筑连接审图

赤岩c版77项技术过却被用户明确否定：岗楼游离、斜墙插正墙、砖尺度/墙顶/地脚不一。把Sprite包围盒靠拢或有重叠当成建筑接合是错误；必须在结构阶段同时核墙道、墙面、地脚与厚度，配专用内外角和岩端收口。完整关防核心应先连体成立，模块化边界从共有接缝开始，不能让所有复杂连接都留给编辑器拖图解决。

被用户否定的布局与其技术证明均保留，但加明确reject/current指针防旧生成器恢复推荐。新整体图只能表达连接意图；不能直接裁概念当模块，也不能把斜视概念当固定地图镜头/精确净宽/碰撞验收。

## 2026-10-23 来源闭包正式后仍须实际入场，不能把静审当可玩

Root43精30闭包正式13B8后，唯一44实际62016_2825/D64BB1越过父记录T逆，却在旧MarketGround.prepare聚合谓词拒绝，3467/2 wholeFAIL。静态重点是拆墙后23native+12DG应35，而旧BASE_COUNT仍36；实际未记录具体子谓词，须保留这一证据边界。0首绘/INPUT/图/自然1712 FINAL；真实C0005/9ERR1WARN保，44finalE856与15save/三fact同。不能用已通过的来源包掩盖后层兼容失败，也不能盲改计数为多值放行。

## 2026-10-23 完整出版证明域与运行回执归一化域不可混用

DT已验值后删当前record的runtime receipt是合法运行比较步骤，但finite adapter不能据此把供AP/AO全逆使用的frozen出版父副本也提前删键。原fixedAP确有两键（42一次原生小投影CCB89B），故静态62≠64使AP完整逆必拒。修法是独立副本域：frozen保持完整，current按原四键strip；完整逆后B原末strip/两独立比较仍保，不能放宽equal或从observed expected补值。

只为原生包少量字段取证，不要重写通用Variant解析器：手写reader在typed Array头FAIL保留；改空工程一次原生bytes_to_var前完整固定SHA，只留六scalar，不访问/复制walk，不授几何或运行成功。

## 2026-10-23 来源修复通过不等于入场链已完成

Root40精3来源闭包正式后41从原B.describe前拒进入Field10%的父记录逆校验；T_COMPLETE_REVERSIBLE_PARENT_RECORD仍真实FAIL。不能把静态完整1702期待、已建立Field或某段source修好冒首绘/自然FINAL。应保原失败并只读追具体restore分支，优先现有自然快照与纯源推导，不靠重跑多拍图、放宽equal或回退已经证明的G注册表修复。

## 2026-10-23 历史proof的新增导入文件须独立分类，不借旧导入信用

编辑器可能为build中的既有PNG产生sidecar/ctex。原PNG有CPU出版证明，不代表新tuple已声明或符合旧detect0运行贴图规范。Root39以空工程直接只读ctex，对原独立全RGBA、23现参数、三叶精ticks与存档做新证明；原detect1/fixalpha真保留，准SOURCE_ONLY后只补真正消费C822展开的两Market来源，不扩不消费该展开的Quarter，也不删缓存/停编辑器。有限源证明不冒Market/ART通过。

## 2026-10-23 静态来源owner不是自然collector已通过

Root38 Market在B.describe的完整legacy/artifact/source严格相等拒绝，虽静态5857预期1700/Stage四map都整表一致，不能冒本次自然FINAL或Field通过。修复G目录恢复其source_paths分支后可能暴露先前隐藏的分类问题，但固定G557已是Market1700子集/值同，尚须追具体键差，不凭猜测更改期待、跳相等或盲重跑。失败前自然已有source字典可用时应记录它，不再额外调用collector制造观察。

## 2026-10-23 修门须测真实进出，缓存计时按隐藏且可动首绘

摘要源一致修复后hall37原严格条件不改即found1，真实Space进堂3.316602s、同Field/Player/Scene/layout暖返1.733385s。驻留metadata内total1685.57ms明确不含Loading hide，用户体验用post_draw隐藏且canmove的1733385µs；不得只报resume13.452ms或把metadata proof冒新SHA。首near13.250610s仍未达10秒，旧空目录12.8s不是等工作量基线。功能3696/0与退出C0000005/10ERROR并存，分别报告，不洗成整体clean。

## 2026-10-23c 新编辑场景可以隔离验证后窄范围落主工程

同工程另聊天正改洛阳时，赤岩通过全新Scene/脚本/Art命名空间、无autoload依赖的原生节点，先在独立Godot项目按完全相同res路径导入/Physics/GPU，再只晋升既有目标必须ABSENT的新文件及对应import/ctex/md5叶。不能整体复制隔离project.godot、UID/文件系统数据库或启动第二生产编辑器。保留用户编辑器，文件已落工程与“已自动打开用户标签”应分开陈述。

默认Godot`process/fix_alpha_border=true`会改透明RGB，即便PNG源未变也会破坏精确RGBA合同。本次7/9首轮失败保；只新图导入参数false/detect3D0后9图RGBA精确，不放松比较、不动源像素。源材质柔和混合也不能充真实峡壁/层台高差，静态精灵跟着CharacterBody平移不等于walk完成。

复用索引若扫描遇其它聊天保存，严格拒写是正确结果。保其当前文件，不回滚、不暂停他人，待稳定后重新只读构建；本轮首6源变化拒写，后继1772源稳定/0路径缺口。

## 2026-10-23 编辑器同内容重导入的时间戳漂移

35正式部署前严格guard发现walk.ctex及其png.import仅ticks更新，SHA/bytes均精同F583/B720；授权被阻止，0生产写。保35FAIL和编辑器当前文件，不恢复旧ticks、不给事后白名单、不强关编辑器。新36fresh捕有效34路径当前值，沿同一已审核Stage96CA/17全文旧备部署，未重复Stage或引擎。内容校验与文件元数据保护的信用分开说明，不能把guard失败包装成旧轮通过。

## 2026-10-23b 增加透明画布必须补偿摆放原点

用户精确允许12旧图padding与门352弱alpha后，原RGB/其余RGBA逐字节保，独立105检查，A1最小11.1178%。新增padding并不应缩小人物/建筑：保原uniform pixel scale，new_draw_origin=old_draw_origin−padding_offset×scale；新全画布可更宽但旧内容世界坐标相同。不能fit到原整PNG宽度，否则门洞和角色会缩。本批18张原PNG及根tasks均按执行前清单核对SHA/bytes/mtime，无范围推断。

局部438×250透明矩形通过不等整个门形通过：旧y740截面313.97仍保，受许可只清352个alpha1–3。透明画布也不修walk高/脚底漂移。原pending计划和dry报告作为历史保留，单列人类许可+执行结果作为当前状态，不能因历史字段仍pending而再问同一许可，也不能扩到b新5图。

## 2026-10-23 来源表迁移还须同步业务摘要字段

Estate manifest的source_sha256[registry_path]已迁F529，但独立registry_sha256仍040664，使严格registry_source拒空。下游G.project_portals对空catalogue循环0次却返回ok，外场可载入但室内门全部缺失。修复应同步已核准注册表摘要，不关闭来源校验、不凭缺门重造坐标；发布器应检查此类业务摘要与来源表/实际文件三者一致。hall34先保完整实际门列表才确证0门，不能把此前未知count冒成同一事实。

## 2026-10-23b 两场景并行先隔离共享任务表

洛阳正式守卫可能覆盖根prompts/tasks.yaml，即使另城只追加美术任务也会令其整体验证FAIL。新城在独立art workspace保持同名prompts/tasks.yaml与templates，真实renderer本进程指定模板目录、参考用已存在绝对路径；每ID一次内置、根任务首末SHA同。登记位置如实写清，不能冒根任务已合入。正式运行源仍需单写串行，不私停编辑器或发送未授权跨聊天消息。

门洞声明rect的352个非零alpha实际只有1×338/2×13/3×1，必须保RGB与其余RGBA精确保护，再经用户明确本地处理方式才能执行；预演允许做像素差量模拟，不落派生图。旧12范围不得扩到新5。脚锚定点生成把高/底差26/27→10/12仍未中指定sole坐标，也不以指标改善冒稳定步态完成。

## 2026-10-23 原生多边形门不可套旧矩形启用断言

Field通过world_v15_exit_zone.configure_doorway将旧CollisionShape2D禁用并增启用DoorwayPolygon，城市门继承该合同。hall33 QA后半要求旧矩形enabled会误拒，但此次先在未记录count的门筛选失败，不能把后续已知QA错误冒充当前首因。新诊断应先记实际门target/pos/脚/shape scalar再严匹配，保持原来源/精坐标/超时，不能凭失败观察生成期待。并行无关tasks.yaml修改导致Rootguard失败要保事实与当前文件，不能事后加白名单抹失败或覆盖其它工作。

## 2026-10-23 赤岩关门：局部截面达宽不代表连续门口可用

资源图鉴动画卡的`img.src`沿既有实现取`animationPreview || thumbnail`。离线检查若一律要求card HTML含缩略图URL，会误拒walk_f01卡；保原FAIL，只修断言预期，原PNG入口与缩略图文件仍分别检查，不改应用实现迁就测试。

先定320净门与主路的设计再制图。首门六条真alpha0截面在1160画布宽下136–306，另登记一次定点编辑后前五截面329–353但门底314，且声明438×250原像素矩形有352弱alpha；不能只选过宽行/降低alpha阈值或放大整楼挤步道报通过。新墙/岗楼有原生RGBA也不等完整A1四边10%留白通过。真实alpha合成后隐藏RGB晕色不见，只能纠正查看器误显，不能洗掉完整alpha范围失败。

分区地脚过检仍需整可视包络：初版北分流位于门楼图下，revision2向北移到包络外，塔及其侧路相应西调，单元假定不是原图实际匹配。关卒4张同画布仍有26px高度/27px脚位变化及经过弱；原始统一缩小GIF不许逐帧fit掩饰漂移，不把立绘计成地图动作，候选数量不等运行准入。

## 2026-10-23 子段计时应先决定优化方向

原DT投影约1.9s容易被23MB父JSON归因，但08同owner原outer内真实G.project只404541µs，Brestore862697、末对称wire348896才占大头。不能把整个outer都算JSON解析，也不能将子段加到outer形成双计。先只读找重复whole-inverse/serialize；保原对称typed证明，不用native替独立JSON父，不绕FIRST/FINAL。08首入12.809060s只是单次当前样本，旧06差值不是稳定因果测量。

## 2026-10-23 来源修复工具也须读取真实备份schema

本轮Root旧备3A817采用target_count与行path绝对/sha256，Source初41假设旧式count/target/old_sha256；Root全文审查运行前发现，未运行41，NEW42精适配真实schema、严game内绝对路径转res/唯一24域/fullbytes，原备份不改。避免为迁就工具回写证据。guard31初版逆核因父状态与生成状态字面碰撞而0输出拒；NEW窄改只匹配parent.status谓词，原失败脚本保，未改校验域。修复实际24通过后仍须新08入城，来源通过不等于Field完成。

## 2026-10-23 来源合同的内部声明也必须沿代码后继更新

AP15新C只改adapter来源pin，外层Stage/owner完整精SHA仍通过，却遗漏文化合同7EE122内部声明旧C8C145；唯一07正式Field在NPC投影前拒入。文件本身未变不代表其内部依赖声明仍有效。发布闭包必须同时枚举代码SHA常量、JSON source_sha256内容边及其传递owner/Temple依赖。修复只迁明确代码来源，保完整验证、剧情奖励与原失败；不能改Field忽略错误或用当前collector自动回填期望。

## 2026-10-23 洛阳：精字节逆还须验证补丁EOF可表示域

首次扩大15GD时，adapter新旧都无末LF、0CR，原严格LF patch helper拒而Stage35自然1/零输出；49pin与整逆通过不证明patch可运输。不要误称CRLF、泛化normalize或偷偷复制GD。Root真实隔离apply_patch证明候选5709+sole末0A=567645，精old/new/path门限下只该文件在内存补LF交原strict生成shadow；实际部署先全字节SHA/长度核中间，再机械从deployed字符去唯一末0A，终值5709，不改其余14GD或8DE0。另：扩大scope时build代码目标可能不在父guard路径域；必须事前scope+全文旧备与原ticks证明后在部署plan锁定，不能假设父guard覆盖所有文件或事后加白名单。保失败脚本/记录和覆盖边界。

## 2026-10-23 洛阳：复制优化要保副本独立，组件收益不等于入城收益

认证后的完整房间目录可直接查成员，避免每次catalogue深复制约1.9MB；冷路径、INDEX缺失和完整FIRST/FINAL仍保。有限域父记录仅返回实际消费的两个独立深副本，不能以共享字典替代，因为调用方会擦收据字段。真实88次查询158446→1545µs、单Yamen复制103302→52091µs仅操作观察；Market tiny不冒真实native域、B静态分支不冒运行覆盖，也不能据此推整场节约几秒。按一次后继整合再测Field，不重复已完成微测试。

## 2026-10-23 洛阳：完整候选拒域与语义通过、快速命中分开

9D5B修String/Name键后，两真实typed大pair完整快成功且约.20s，比部署.63/.67s明显少；numeric旧候选只改数字却因6个Name键整树fallback，第二组还更慢。诊断坏键/碰撞不能直接返回并藏住其它唯一有效键子树；用独立seen排歧义名、两侧都不猜映射，再扫唯一交集。未知Int键路径用str，不依赖String(int)构造。实际Dictionary合并同名String/Name时只能诚实报碰撞未覆盖，synthetic索引单测不能冒真实覆盖。59检查0/console0不抹8故意INF警告，也不自动证明Field已提速。

## 2026-10-23 洛阳：诊断必须覆盖候选实际拒点，失败快路会增加开销

真实typed T两pair均原wire接受，但StringName根键让旧严格快路立即退回；另一pair的首旧strict float差能被数字leaf修复，不代表候选余树通过。numeric实际wholefalse且第二组.765s比旧.616s更慢，不能因“测试33检查都过/语义相同”就晋升性能候选。应分别报告完整命中、旧新结果、计时及候选自身所有拒reason/type；仅旧谓词首拒不足。键StringName规范化若采用必须逐侧canon唯一、两侧集合一致、值逐项比，碰撞拒快路而非挑最后键；仍不授源新鲜度或DT单边比较信用。

## 2026-10-23 洛阳：纯JSON微对照不能代替实际typed包的命中证明

B纯JSON父record比较644576→137563µs，但正式05对04的DT投影包络只低.131s、首绘只低.305s，仍14.45s。两次观察不宜做稳定因果结论，更不能直接乘调用次数。adapter实际_parent来自bytes_to_var，其record域不必等同JSONmanifest测试域，必须追类型来源/支持叶和实际命中，不能凭微基准就宣称整城提速。下一任何逐叶wire比较须保String键集合/顺序/深度边界与未知型完整fallback；尚无新实现或实际分支信用。

## 2026-10-23 洛阳：对称JSON可快成功，非对称往返不能套同一证明

B两边先wire再equal时，有限JSON域同型同值全树可直接证明两解析结果相等，失败仍执行原predicate；DT原先只wire左边而直接比较右边，不能把同一优化泛用到它。±0说明证明应落在解析后相等，不笼统宣称JSON文本逐字相同。固定10MB记录单pair644576→137563µs只能说明这个操作的单次收益，不能乘次数当真实入城提速，必须接正式来源后再测。AP13只B后继，scope26可减为22，DT/hash/Temple/registry四项不应造无意义新版本。

## 2026-10-23 洛阳：先用owner绑定子段计时定位，再改同步热点

AP12府衙首绘14.753393s，DT总3.101980s中投影和父记录整逆2.863942s，期间process/physics均0；反而三纹理readback/fullRGBA和既有await很小，LM26预读仅.239293s。不能因加载慢就泛改贴图、减人物或削校验。getter必须在ready/draw时间冻结后单读且核同Scene/layout/transition token，测量快照不授新鲜来源信用；先读调用链区分JSON往返、重复storage和原有还原，再准备最小候选。真实C0000005退出继续与功能complete、性能未达标分开记录。

## 2026-10-23 洛阳：完整来源鲜读可有界并行，正式引用必须成套迁移

府衙1217源每遍逻辑payload约2.876GiB；两次鲜读不能靠mtime跳过。hash新候选保每1MiB取消/完整SHA与全join，8线程tiny76项通过；固定16ctex各450.63MiB的单次8先.162166s/4后.298963s观察支持进入正式验证，但受缓存/次序偏差，不等于全城提速。计数器在lane本地累加、全join后汇总，不能把其运行中0值当即时进度。

只改B/DT/hash三GD仍需Temple绑定、五房registry和来源/index最小级联，Root精26成套发布，不能漏五房DT或把非owned hash加入OWNED。Shell调用成功的.ps1若没有显式exit，不会刷新LASTEXITCODE；本轮copy439F成功后外层陈旧1触发假失败，未重复copy，另独立finalguard核2117/26差精同。应依据当前调用成功状态及实际回执，不凭残留native退出码判定脚本失败。

## 2026-10-23 洛阳：分开记录功能、加载目标与进程退出；接触点勿混用取整mask和实数身体

府衙性能03功能报告complete/2465零失败，但首绘15.898秒仍未达10秒，且实际WaitForExit为C0000005；不能把报告通过扩展为性能或whole-clean通过。阶段计时显示贴图预读仅.237秒而DT约3.098秒、末核await约3.142秒，应据分段证据优化，不能把嵌套wall累计或最大观测gap当纯CPU。

百工布架真实身体顶1446.375尚在固定底1446.359985外，取整foot北mask点却到1446落黑；测试聚合先拒后没有调用Physics查询。因此保留原整FAIL和未执行尾项，既不补造Physics空结果，也不为取整oracle误差放宽生产碰撞。已通过的六通道/材质/默认5.041秒只保有限组件信用，停止重复入场洗通过。

## 2026-10-23 洛阳：构建逆证明与运行来源校验分层，预览陈设不能在接线时丢失

百工A2已用固定旧native与独立RGBA先验完成唯一局部出版/六通道检查；正式消费者应精确绑定已验证产物、出版及完整FIRST/FINAL来源，保原packet/mask/Scene-layout校验，而不是为了重复同一构建证明在每次加载新增父50MB同步解码和八域重算。此为新分支设计边界，不授权删除既有来源校验或跨调用泛化缓存。纯预览保留的旧车辙stamp，在ENV改成新材质earlyreturn时可能被漏掉；要逐项核对预览→正式消费者，不能仅因材料通过就认定画面一致。A2本轮整区仍空旷，局部美术准入不得表述成整城完成。

## 2026-10-23 洛阳：局部遮挡退出不等全场无任何遮挡

府衙三新家具背后透影/前恢复实际均过，最终站位仅旧灯杆lamp_0命中，三家具都无hit；key以globalghostfalse当“离开三家具”而错误失败。原wholeFAIL与未执行尾断言仍须保留，不改生产灯杆、不强制clear，不另重跑整入场洗通过；按原记录仅授三物件local组件。真实退出C0000005/Event1000须另列，不能因report生成或完整图片就写clean/OS0。原Vector2乘scalar先收窄real_t，独立纯常量ABI可验证期待式，不拿实际node值回填oracle。

## 2026-10-23 洛阳：来源分类错误应修清单，不放宽验证器

府衙有限清单把原T_ROOT的layout/packet/scene/parentmanifest四叶放legacy，B原验证门禁止该域，runtime_authority本已合法允许。修复只迁四同path/SHA项并更新外index一个SHA；完整union1203与1211expected键不变，B/C/binding不动。对已正式消费的build内清单也须完整旧byte快照；旧出版收据保持原样，NEW owner用实际两metadata收据继承。拒入17.399秒是失败全过程，不能当成功loading时间。

## 2026-10-23 洛阳：几何独立复算必须保持原float32运算顺序

Market旧oracle把每角单独变换改成low+scaled_size、或先四角舍入再平移，与原作者表达式相差1ulp，严格校验正确拒绝。只读112732先拆证record→packet31整序真同；独立冻结B11/0F824/EAC再重推两行四分量，不用actual补expected或epsilon。原04 FAIL保，NEW05_bound01唯一实际249/0、两局部RGBA与早先独立PNG先验同。纯Scene候选没有新meta时，后续消费者应依据精packet/config与owner会话，而不是为了模板条件重出版几何。候选技术通过不等正式接入/户外艺术通过。

## 2026-10-22 洛阳：实际来源后继只测剩余性能，不复已过组件

06四JSON坐标精比较真正修复了未触发park，E65152实测同一Field返回4.392701秒，仍fresh SHA全部1613文件、4worker全join，非省略来源校验。原Field估值333MB保留在512MiB上限，不能把该估值冒显存测量。原11.203165秒FAIL及两次早期FAIL保留；首次13.287716未达10另列。只后续E性能一次，不借机复D/两visual/旧房室几何。

固定审批artifact的真实schema必须先读：Root FF10/ACA3以固定status与精sha表达授权，没有approved_by_root通用bool；builder不可假设字段存在，应只对这两固定文档精schema检查，不删除审批门禁。来源oldpin必须继承实际上批receipt冻结snapshot：unused合同4Dcanonical控制pin在04首读失败，NEW05继承EF969的ACF3静态snapshot，不能用扫描live值回填expected。独立owner也须继承既有BDF3完整core+新23，不能假设上批target集包含未改CC97/G/Family。

## 2026-10-22门派与西域：区分地形、空间与轮廓，保留概念偏差

门派/西域不能给同一十字街换色：武当用高山层台，茗雾用茶镇到多院横向层进，绿洲以水源/遮阳巷市，赤岩以峡口/折返阶街。总览画得好不代表约束全过：d图茗雾瀑差和绿洲水面超设计尺度、赤岩少量中原瓦檐、边缘裁体须明确保留待分区纠正。概念小人带包头也不能沿为正式NPC；不裁整图当独立组件、不统计图中人当动画完成，不继承另一张总规的人类确认。

共享图鉴只同步资源时，旧四类数据应保持，但旧资源usage可能因另一线源更新而变化。本批首37核验“所有旧资源行相同”真FAIL保，精两usage字段10→9/24→25后继核当前消费者，不把原报告改PASS，不回滚其它线源，也不冒全工程零漂移。只给实际检查范围信用。

## 2026-10-22 洛阳：JSON数值数组与整数常量的等价须显式编码

Godot JSON.parse_string的数字读为Float；嵌套Array对整数literal Array的严格比较会误拒，QA11440真实发生且生产Router四入口足点同因令header为空，使新增lease完全不启用。只这四已hash绑定字段先要求Array长度2、组件int/float且finite，再转原生Vector2对同一固定坐标做精等；不加epsilon、不接受bool/string、不把实际值回填expected。QA字段修正与生产缺陷分开保FAIL。实际45640只到Artisan/未park，不能报cache或返程性能通过。

统一文件部署后技术/艺术/耗时必须分开：Market10088黑底与立绘真UI过而首绘仍13.41秒；Artisan37408外缘shader过而L形规划/高频石地仍拒。不能拿局部材质通过替代城市用途规划，也不复已过组件来累计“完成”。

## 2026-10-22汴州南门：图像适配与屋顶包络须先于复用拼装

总体获人类确认后，分区工程平面仍需独立拟定尺度。旧门楼看似类型正确，但在目标全画布1152宽下，5行真alpha0门洞仅142.5–156.75，不能当280宽门直接复用；完整可见高度也超拟定檐口590。应登记新门楼缺口，不为旧素材倒改已合理的动线、把整楼放大挤街。正面墙PNG也不能旋转冒有纵深的侧墙。

首平面即便地脚路线安全，横街若在门楼屋顶投影下仍会遮住停脚；岗棚与门楼檐口相交也不能用Y排序掩饰。新平面先将横街北移、岗棚外移，检查整条横街宽带避檐口与三顶包络不交。Pillow.rectangle末端闭区间与半开rect不一致会把280门口多堵1像素；保首FAIL，只修raster末点width-1，不放宽净口断言。以上仅设计几何信用，不冒图片或Physics实机。

## 2026-10-22 AP：完整collector相同不代表消费者内部声明完整

码头raw诊断的actual与独立QA固定表均1665叶、无extra/missing/mismatch，但B.describe对两者都返回empty。B自身从manifest1631＋外部12叶只构造1643，缺口恰为G新增的冻结Estate返脚registry/AP_QUARTERS/5房各4叶。遇到这种“fixed也失败”先读消费者内部构造域，不重复60秒正式入场，也不能把collector实际哈希全抄回manifest；新增声明必须从既有冻结发布祖先独立继承。

驻留优化也要查触发链：Market→Artisan不是revision_room，Router原loading_context未附field_scene_id，LoadingManager根本未调用park，而不仅是park函数拒绝。精确双区优化须同时覆盖context→park→return→来源/身份/脚位→失败回滚，原room/world不可扩大放行。裸check-only另会因候选HUD重复class_name或autoload符号域缺失而失败，原日志保留，后继用明确有限验证副本/正确autoload域，不能将环境错误直接标生产逻辑修复。

## 2026-10-22汴州用户纠正：先设计再做模块，不能拿技术验证代替城市设计

用户已给洛阳“整城总规→分区平面→建筑地面生活→NPC与内容→分区验收”范式，换城时直接复用素材拼6栋独立房、硬贴矩形路，再报告路线/Physics通过，仍违反任务的设计前置。标“独立试点/NOT_ART_READY”不能弥补跳过设计，用户明确否定后必须停用旧布局，原收据只保历史；旧文档生成器应拒绝把已拒current-candidate恢复成推荐。

正确纠正是重读总规/分区方案并列逐条偏离，先出与该城身份相符的完整城廓、连续街沿、围合院落、道路层级和生活用途设计图。参考洛阳的是空间品质和过程，不照抄河港/园林/古寺；汴州按原中轴坊市/邮驿/行商身份。设计图未获用户认可前不恢复引擎和模块拼装。概念图街宽/门洞/足迹没有测量信用，后续另做分区平面，不把好看概念整图铺成可走地图。

## 2026-10-22汴州：并行城市先做独立工程，原生预览也不等正式接入

另一对话正在洛阳生产工程跑引擎时，新城的布局作者、PNG字节副本、导航、预览与待集成TRES放在assets/staging的独立project.godot，原生渲染/物理查询只指向该项目，不复用生产.godot、不操纵用户进程。待集成包里的核验project/domain副本不属于部署内容。只保护实际读过的3汴州来源事实，不把另线全工程变化冒成零差。

首图即使8route/原生Physics通过，也仍暴露裁切墙、纹理颗粒与门压出生视线。保首图，有限后继只修对应作者值；修版仍矩形地面硬边/低围合和民居原地脚亮边时，标整体NOT_ART_READY，不能靠技术PASS发正式。预览人物112px统一只是观察尺度，正式Scene .96/.90原值未变，不能冒正式同身高。首GDScript验证器动态Resource布尔表达式用:=会推断失败，显式bool后继可修，原失败收据保留。

## 2026-10-22行走帧：相位可辨与稳定运行须分开

整sheet看似四格也可能只重复两种着地；分四次文本生成仍可能同脚在前。首两整sheet、两修版、首人四文本帧都因此保留为失败，未把SHA不同当动作完成。旧身份与独立技术腿部关节参考可改善左右脚/经过意图，但逐张原生图仍有身高、脚锚与衣褶漂移；对齐查看GIF必须与原始播放共存，不能把预览缩放平移授为运行atlas。alpha128只作诊断适配，完整A>0留白仍64全FAIL，不换阈值洗通过。72真实PNG/64当前/8失败/116登记44未调用分别记账。

浏览器策略拒绝file://后，不启动服务器或换浏览器绕过；采用文件路径/解码/GIF帧与隔离JS逻辑检查，明确无浏览器实点信用。图鉴新动图卡须保留原PNG入口，待机、立绘、行走和地图实体分别注明当前引用状态。

## 2026-10-22 AP：运行包准入声明须一次覆盖完整消费者链

只核原生出版和来源SHA不代表运行适配齐全。本批Market先漏7个历史PNG的14个既有import/remap来源，补后真实请求继续被B.run拒：manifest完全缺`mask_sha256`。它必须继承原17536报告的整RGBA D161，而不是PNG文件16DA。静态继续沿Field→DistrictFade→B.parent_scene发现还缺`parent_publication.complete_immutable_manifest`，需精继承冻结AO内的原r3完整声明，不能拿当前collector重造。

后续新运行manifest应在首次正式入场前一次枚举`manifest/run/materialize/packet_valid/bound/whole_bound/describe/parent_scene`全部消费者必需字段，并检查Field实际接线；不逐个GUI试缺键。诊断优先一次公共请求匹配终态后立即同步保存C.errors与阶段，禁止为了查看raw再调用Router私有loader触发旧几何。已发生的原B与误resolve诊断FAIL均保留，不借新后继回标原PASS。并行tasks登记漂移的授权失败和after整体FAIL亦原样保留，不回滚其它工作或迟加白名单。

## 2026-10-22百图：主体数量、文件版本与失败调用分别记账

100主体不等于100工具调用：本批102调用产生101PNG，其中1张薛影持剑稿弃用，1次青冥剑录被工具violence拒绝没有图；另登记静置书册后继，单ID不重试。当前100选择要通过显式current-candidates解析，原manifest/meta保留初稿与失败，图鉴/复用索引不能继续推荐被纠正的旧稿，也不能把无图拒绝凑成图片数。

即使record已加跨进程锁，生产期间另一个提示词编辑器若整写旧manifest快照，仍会覆盖刚登记的新项。本批vendor身份纠正正好丢一Jinling收据，已有meta/PNG可精验恢复，portrait不必重生成。所有编辑者须共用锁，或在活跃生产期禁止非record/reconcile写ledger。首6路径parser失败且缺原逐call映射时，人工按视觉规格恢复必须明确例外，不能伪称原收据完整。完整A>0留白100失败仍保，不因原图漂亮或隐藏RGB查看器怪色改用阈值bbox。

## 2026-10-22 AP：路径与SHA必须一同继承，typed相同不等于字节相同

- Temple候选改了BIND_PATH却沿用旧BIND_SHA，生产入口严格返回空。源闭包生成本身不证明所有动态常量已接齐；独立按真实consumer构造完整来源表能在Field前发现遗漏。不得关闭校验或以当前磁盘SHA回填expected；本次从最后真实D581绑定原字节保EOL精改六值，Temple仅路径/SHA两literal后继，并保完整执行源逆与189消费叶核对。
- 原proof声称绑定父692780，但正式AN/AO父为D581。两者typed语义相同不授权原“whole-byte inverse”；CRLF/末换行不同也必须保原失败，另建真实父精确后继。已批准的执行JSON9C3F原为CRLF/无末LF，应原字节机械部署，不能为适配patch悄悄归一化再声称原SHA保持。
- 素材分支并发写prompts/tasks导致部署保护基线漂移时，保其当前数据与原FAIL，不回滚、不事后白名单、不冒全工作区零变化。实际授权目标与15save可独立证明精确；新修复epoch只能事前建立新的有限目标与备份。

## 2026-10-22其他城镇：并发生图与汇总登记要分开；完整alpha检查保留失败

多份独立图像可以并行请求，但各自子进程对同一manifest执行read-modify-write会丢更新；此次原图和逐件meta都在，汇总漏4条，又引发一个portrait参考SHA KeyError。必须先精备失败ledger，按已保存的调用收据/原始输出SHA逐项补齐，不能凭新文件存在编造成功或重生成盖掉失败。修复为记录进程文件锁、顺序写入，并在复制前验证参考；已有PNG只在原始源SHA完全相同且缺收据的明确恢复分支补meta。

内置出图虽请求15%留白，真实A>0范围仍可能触边。真实alpha合成查看可以排除隐藏RGB误显雾底，却不能代替完整alpha留白验收；本批22图均保留10%留白FAIL，无许可不清边或扩画布。单帧NPC/战斗ready不得当完整动画；图鉴应显示候选与不足，文件索引、生成完成和正式游戏采用分开。

## 2026-10-22音频：按实际选择路径盘点；保留PCM与试听编码各自合同

对白必须递归扫描并按Godot当前情绪/分段优先级计算覆盖：旧Python生成器的关键词与运行时不同，存在MP3也可能是零字节。此次447份对白含63份子目录，14旧空MP3中只有1个当前被选择；682个明确说话人节点需要新候选，不能用562个语音文件数当对白覆盖率。对白ID可含斜杠，候选文件名须转义并查碰撞，游戏目标层级保持；纯BBCode括号内心话用合法primary，不能制造空分段骗查找。152个空speaker节点须结合运行时上下文，不冒已补齐。

音乐游戏循环使用PCM WAV的逐帧合同；试听MP3完整解码可有编码帧尾差，此次两项分别多15/23采样。保留原18通过/2失败和固定SHA诊断，NEW残余只核2项PCM仍精确、MP3完整有限非静音，不设任意容差、不重编码、不重跑20曲，也不把残余PASS写成原whole-run PASS。数值接缝与弱段统计不能代替音乐听审。

旧Edge握手失败可用独立新版小wheel验证，隔离安装不改全局包，明确在线TTS与本地Stable的区别。Windows标准Selector事件循环解决退出callback时，保留原probe日志。603成功/1本地路径失败要原批封存，仅NEW补唯一失败与明确残余，不重跑603段。685片段、682节点、116说话人标签和7真实voice ID分别统计；48变体与10派生也不能称58次模型生成。

## 2026-10-22ao：拆实体不等于只改布局；来源与遮挡合同需一并继承

已发布父场景中的sort_by_feet墙被拆后，旧fade精确ID守卫会拒绝，即使新碰撞/NAV/87517已通过。不能返回伪造的删墙parent资源，也不能泛化允许所有缺ID；用固定已批准包+同实例whole_bound+唯一退休ID+原exact1/新exact0证明，给fade明确的一条退休合同。由此改变公共fade源码时，D原冻结source与AC执行依赖链也必须显式后继，不能只改manifest当前SHA。保持原CPU几何/原native/旧审批不变，精确证明D单hunk全文逆和旧AE四hunk链，再同步三room执行源；没有必要重跑四城和十房。

PowerShell变量名大小写不敏感，路径$SNAP与对象$snap、路径$D与循环$d会互相覆盖；会造成整字典成为JSON key，或更晚的路径误算。路径用明确长名，与数据对象/循环变量分开。另Godot JSON会把1536重写1536.0；PS比较的NEW规范只将finite且精确整数的Double/Single转Int64，bool/小数严格不变，旧失败收据不洗。保留完整typed/整文件逆，不用epsilon或删比较规避。

门户返回需区分固定门marker与真Space前实际脚：Field正常记忆真实出发脚，输入走到门有微小差值时，QA应在离开前固定这次sourceUV作为预期，再逐值核返回；不能从返回结果反填，也不应扩大.03阈值。首绘可动时间与之后QA全源散列另记。本次首南市11.346434秒、两室内约3秒、街道暖返约1秒，不可宣称首次<10秒或全城完成。

## 2026-10-21ao：候选登记也有单写边界，未授权变化应先封存FAIL

ART准备生图任务时不能把“登记要求”理解为可直接改现役tasks；收到“只NEW候选、不canonical”必须交完整候选/片段和未应用patch。AO曾违规追加v1/v2，Root发现后立即精备异常全文并执行原guard真实FAIL（唯一tasks变化、保存无差），再只撤自有hunk恢复原SHA，保留真实新mtime，不回拨。后继另fresh/精备/预授权才登记唯一最终任务，不末尾扩白名单或倒填auth。没有影响正式游戏仍不代表流程通过。

## 2026-10-21an：区分raw几何与运行编译域，门户拒绝不能盲目当加载慢

strict safe_origin需要_compiled.world_size；即使author几何与spawn真实安全，直接传原JSON仍必拒。先按同一source world_size编译，再原fullsafe_foot即可，不能关闭34×24/87517或凭延长timeout绕过。read-only最小诊断应先复现raw拒、同spawn compiled过及桌体仍拒，再仅跑未完成门户。保留原整体FAIL与已通过的前段组件，不能把剩余三次往返PASS洗成原全链PASS。

显式public Estate setup只有manifest source-first，不经过joint validation_finish；真正Space门户才有两次全源hash/finalized收据。测试必须按真实生命周期分别断言，禁止替生产调用finish制造通过。首次部署已冻结authorization后发现窄修，应先封存原epoch实际final_guard，再NEW fresh/current、精备及精确依赖计划，不末尾追加白名单。Godot natural0仍可有旧纹理退出ERROR，功能通过与clean日志必须分开写。

## 2026-10-21an：Atlas短片完整A1与已出版房间的历史来源

从同一墙PNG裁出的短片不保证继承整片A1顶部/底部，需逐crop alpha>0实测；锚点和真实石脚不因透明边界而伪移。JSON数值数组与代码int字面量在严格typed比较下不同域，应把固定预期显式构造成原JSON域，而非放宽比较。旧房间source表可能保留后续城区已合法变更的历史脚本SHA；复用其几何时应显式继承已有后继，不把旧source表当当前闭包。多阶段publisher早退后已成功写出的native须保留，并以独立重建预期+typed整逆复用，不能删掉失败产物或覆盖重跑整个流程。

## 2026-10-21am：路由改动的来源闭包；autoload脚本的直接编译域

新增地图家族即使只改Router/G/房间index/B，也需搜索实际传递引用：现文化runtime合同直接固定Router SHA，古寺绑定又固定Router与协调器。漏掉会使正常入口被严格来源拒绝。应制作显式窄后继并保持原合同整逆，不能删除校验或要求关闭编辑器。

Godot单独 `--script Router_candidate --check-only` 可能因autoload标识GameState未注册而失败；保留这次实际FAIL，用建立autoload后的受控SceneTree延迟加载候选检查剩余编译域。该结果不授实例、旅行或来源闭包通过。生成图可见主体比例合适而A1仍触边时，不能按A8偷偷通过；局部清理需要对应新图授权，不泛化旧建筑或湿岸许可。

## 2026-10-21al：纹理像素不是世界尺度；门内补片必须覆盖真实开口

现成平面青石直接native1:1会成数米巨板，即使Atlas未拉伸也不等于符合成人120世界标尺。保首实际与ART拒，修正只同比quarter并4×4铺满各原footprint，可精确继承全部碰撞/路线而不复旧body采样。门内材质补片按已校准source clear_rect＋少量门框后重叠映射，比凭视觉估118/80尺寸更稳；使用真实墙脚/地板纹理而非黑Rect，不填院门和回廊本应通透的孔。铺装/深度改善不能冒围合完成，短墙/花床须有实体差量。

## 2026-10-21ak：明确局部抠图授权与保护区；尺寸不合适应调整占地而不是压人物

三新组件获明确许可后，仅外背景先验mask归零并裁空透明canvas再padding；保护主体全RGBA不变，不能把背景清理称整个原canvas无损。人工源门脚与整楼中心不同，必须对齐实际台阶（厢房556,915）。廊500–560世界宽只能约101–113净高，改新占地620–640可达约127–131，不非均匀拉伸或缩主角，也不重标原失败。

独审应完整继承输出annotation中的不变height/uncertainty scalar；遗漏导致43/2时保留原wholeFAIL，窄补两项和原全部来源事实，不重跑已经通过的像素。GDScript静态类preload不能当实例读取resource_path，来源pin用明确helper路径。Windows console启动PID与实际render报告PID可不同，按真实收据路径读取图，不用launcherPID拼路径或补造子OS码。数学不叠与安全通行不代表整体艺术完成：真实图仍可暴露透明门洞透草、未铺院地和孤立组件。

## 2026-10-21aj：建筑宽度应按完整alpha包络统一缩放；门高与透明边距分别验收

透明PNG画布宽不是建筑世界宽；用完整A>0宽确定uniform scale，再同倍率换算门洞、完整高度与canvas render_size，不能忽略弱alpha或挑主连通块放大门高。主厅首次门约111world不达标，唯一定点edit后保守约128通过，但边距仍失败，必须分别记账。连续生成出现零散alpha/灰雾后应停止，另问明确背景处理授权；不能泛化旧单图padding或湿岸许可，也不能把预备Sprite脚本冒实际地图预览。

## 2026-10-21ai：真空间不足要拆街区；几何通过不能当城市艺术完成

旧东街北窗只有171px完整高度，正常成人门楼约220–240px，南窗与DG树相交；继续缩楼或用虚化遮穿都不解决规划。完整城应为缺区建立必要紧凑外场，不是十区强制十张，也不是把四区挤现南市。新干院2226角色脚印数学通行全过，但13Sprite实图仍宽石带/四树/无建筑层次，必须艺术拒绝；缩路的visual-only后继可typed全逆保原mask/实体/几何，不重复导航证明，也不能因此称整个宅园完成。

文化crowd新增身份5与全部文化演员6是不同集合（原书生也有话题）；资源测试不能把旧摘要数字当manifest真值。保留原573/2失败，按六确切演员+三carrier只补残余74项，12资源/24Node已完成组件不重复加载。Windows GUI引擎外壳返回0不一定是实际子进程退出码，实际验收用console/显式Wait；119464旧子码未捕获就保持未知。

## 2026-10-21ah：无损扩画布必须保留隐藏RGB和低alpha像素

用户明确授权后用无mask `paste`复制整个RGBA，不能用`alpha_composite`或带alpha蒙版粘贴，否则会改变半透明像素及A=0下RGB。独立复核整幅回裁byte相等、框外RGBA零、全部连通块平移和alpha直方图只加零，比只量主连通块更可靠。本次20/0通过但只授留白，不授边缘擦除/落位/部署。静态AST可接受未定义的JSON式true/false名字，Root全文审在执行前修正；不能把AST parse当实际运行通过。

## 2026-10-21ag：先按净门尺度定单开间；透明扩画布与落位是不同验收

零宽楼参考、真实单窄bay/约2.1m净门/2.8m面宽的新药铺，宽门比降到约1.70–1.80且不再烘柜挡入口；但生成器仍未遵守留白：完整A1占98.62%并触边，不能用A16看起来干净替代A1整项准入。只补透明画布有机会全保原RGBA，无需阈值擦主体；本地处理仍须明确授权，不能拿旧wet的许可通用于新建筑。

形体通过和尺寸窗口名义fit也不代表能放：当前A280×205保不了120px净门，B220×284虽可容纳仍与旧楼相交。窗口要纳入实际District替换摊位、伙计、追加灯/树，而不是仅旧native或粗render框；不以背景padding给旧楼拆分、solid/NAV、门户往返额外信用。

## 2026-10-20af：单层化不等于门洞成人尺度；先画净门再定面宽

引用原三开间楼仅为材质/镜头，仍使新药铺/书斋继承宽横向比例；定点编辑删除二层后，总宽与门高比仍大，拟380/360px面宽下净门仅99.6/104px。生成图全尺寸“好看”不等于可进入门脸合格，不能直接整体缩小挤三栋，也不能把书桌柜台烘在主入口。下一轮应以成年人净门、可用街宽与固定灯/树/巡游域先约束形体，而非靠后处理透明背景补救建筑比例。

A16主体包络只能辅助量轮廓，不能替代完整A>0檐口与真透明边距；本批原稿/修稿A>0均触边，宅门两版灰雾。六raw与wholeFAIL保留，停止追加调用/导入，候选8脚本语法通过不能授予运行/门往返/正式替换。Root最终2094保护项仅素材登记变化，15存档完全未动。

## 2026-10-20ae：运行作者的传递来源也会固定公共脚本；平面湿痕不能用石沿代替

更改District的Market-only地面分支后，六份manifest与独立完整source map都可精确继承，但AC.author()还会逐个比较不可变author.source_sha256，里面固定旧District0137；因此最初CPU118004在原packet验证处真实拒绝，不是测试期望问题。改公共脚本前必须扫描实际author()消费的嵌套来源，不能以manifest全逆/当前source map匹配替代这层检查。本次保留原author85DFF/packet/META/native，只用固定path/旧新SHA、四段文本whole逆/navigation原文同的严格执行依赖后继，AC代码与三份Docksmanifest/三外置pin有限更新。其他城市manifest不改，但共用BI自身SHA变后，四城市独立期望map都要继承这个权威叶。

失败键保原wholeFAIL，已过的3+1两实际导入组件只引用原报告；残余键只做未完成的两source/native/Market36，不复导或冒一次四图运行。控制台wrapper PID与实际报告PID不同要分开记录，后续直接运行实际exe可使PID一致。

湿岸素材两次生成／授权本地去背景后的石条虽然技术alpha可清理，仍像凸起实体；不能无碰撞贴到可走区域，也不能以降低透明度掩盖。改成真正平面水膜、保原PNG字节，用固定命名色类做正常调制。系缆要使用真实桩与船舷alpha锚点；绳结层级应高于原wharf(-2)但低于船/人物，不能所有贴花统一-998导致结点被盖。离线合成不授真实Field，inspection相机图也不授角色走到该处；测试后恢复相机/人物脚位。本轮退出仍有纹理释放告警，不能写成clean或把全部告警都归为旧问题。

## 2026-10-19ad：更换行走图必须核原翻转约定，NPC期望也要包含既有后置配置

原商贩walk画朝左，巡游row以invert_patrol_facing=true适配。新搬运工walk画朝右，若只换路径而保留旧值，会向右移动却朝左。必须读NPCNode真实cos/flip公式，仅对新carrier视觉翻转字段适配false，不动sin路线、速度、身体或全局NPC逻辑；四相位PNG和导入通过不能替代实际自然位移/帧/朝向检查。

Field在spawn后还调用既有x.configure_actors，给码头记货伙计加culture_x_menu并在meta保存原主动作。原AD测试期望只包含postoffice+AD，导致101548默认入场成功后误拒booking整row，wholeFAIL完整保留。NEW后继应从冻结w actors及x合同独立推导该唯一后置动作，仍逐值核原meta、另9人无此meta和其余全部字段；不能改生产文化逻辑或把失败改成PASS。

内置去背景编辑仍带光晕时保留失败，不用阈值擦边冒透明切图；需要替代本地处理时先取得用户明确许可。四格contact sheet只授四个authored phase，生成但未观看的GIF不授流畅循环或8帧信用。ConfigFile的deps.dest_files实际writer域为Array，导入校验要精确匹配该域，不能用PackedStringArray误拒。

## 2026-10-19ac：来源类别要去重，完整逆不能误删父场景的native叶

派生子场景依赖父packet/layout/scene时，这三叶已在父manifest.artifacts内；新增依赖处理必须先识别同SHA已拥有artifact并跳过，异SHA仍显拒。若只检查legacy/runtime两类，会把同一artifact误记为新增legacy，source-map逆操作又按existed=false删掉原本存在的键。本次原7937实际整逆FAIL与部分产物保持，NEW B642仅修类别去重，不放松整集合断言、不按实际collector回填期望。

独立polygon oracle要求每个solid唯一非空id。Field草稿漏id在actual前静态读接口发现，保留原2C01，NEW A8DE补source派生id；不为已知夹具错误跑一整次入场。小物件遮挡验证要用真实Input从前方绕到后方，并跨自然动画帧比较source-alpha的CPU/GPU mask；小物件本身A1、主身体34×24/RID和其他NPC透明度均不改。CPU/导入/来源通过分别记录，不能替代真实画面、Physics或全区艺术信用。

## 2026-10-19ab：来源后继要校语义与导入闭包，测试入口不能沿用旧图坐标

PowerShell变量大小写不敏感，`$AA`路径与`$aa`manifest不能并用，否则可能把对象写入自身author_path；仅验证完整逆和SHA不能代替新增字段类型/作者路径语义。失败产物和原报告保留，NEW后继只修已证差异。运行时collector会补已有PNG的.import与remap ctex，作者引用的预览图也不例外；依赖清单应从冻结作者与ConfigFile独立推导，不能用实际collector输出反填期望。

原设计340,1840在20261015 revision已迁到2140,1840；普通null出生须读已出版native入口，不能直接沿旧canonical TRES或古寺返码头slot。验收误期望要保留FAIL、修NEW测试而不是改游戏迁就。首绘/可动时间在frame_post_draw与Loading隐藏后立即采样，逐文件SHA核验另计，不能混在加载耗时里。

用户授权释放模型后仍须核实具体runner：本轮74364父gone/无连接，仅卸该runner；Ollama API与编辑器保持，不把卸载模型说成关闭服务，也不删除模型文件。

## 2026-10-19z：大城总规先于继续摆楼，内容身份先于加显隐门控

同商楼三开间技术上可接三房，不等于药铺/书房/豪宅在城市用途上合理；豪宅先要独立门庭/院落。已撤一个北仓不覆盖码头别簇，需按人物驻点和三栋来源一起定位。总规图可表达密度/地标/街坊，透视图仍不能当足迹/导航证明或单张可走底图。

地上卷轴先辨别是任务道具还是收藏：当前玄铜鳞编札不是所追踪含嘉旧刃；交互hide不自动给visual同门控。教官年轻头像也不是场景sprite必然错误：当前已有壮实甲士，只是缺portrait落默认年轻男；追实际消费链再补同人图，避免反复生成不相干角色。

## 2026-10-19y：军士精灵的武器包络、动画质量与校准分支

长枪超过人体头脚时，按整张alpha高度校准会把人物缩小；不要裁掉枪尖或擦低alpha硬过。明确保留初稿，只对同角色做一次已登记的武器包络EDIT，再统一等比缩放/透明平移。图集八格RGBA不同不等于八相位步态；同脚在前、近四姿重复时拒真实8帧walk/contact-idle，可另立四静态后继范围，不改原失败标准或把新idle接旧身份walk。

当前NPCNode的SMALL_ADULT_FAMILIES按basename决定adult校准。替图不仅要固定160格/脚152，还要保原每ID分支；前三普通兵可沿既有前缀，都头原examiner必须非SMALL，152−80=72与160*.45一致。不为一批素材修改全局NPC/Field。负透明平移要证明丢弃行alphaMax0和非零像素数/alphaSum守恒，不能只看成图bbox。

用户退出game后仍可能显存不足。以实际GPU计数器查到local Ollama约3.2GiB，而非猜编辑器是唯一占用；暂停别的模型需用户明确授权，不私停进程、不反复笼统要求关编辑器。已通过资产/CPU与已备正式包应如实交清，不能在尚无Field实测时写“已上线”。

## 2026-10-19x：文化支线的正式适配、存储和验收范围

冻结的纯归约器只接公共事件schema。正式对话会话的qid、Node身份、serial等私有字段不能duplicate后直接透传；按事件类型构造精确String-key字面量，保留原严格校验，合法拒接也应断言“成功处理且未接取”，不能只看状态没变。

GameState.set_flag会通知所有旧listener，当前GameState._on_flag_set先执行bool(value)，Dictionary和String不能安全传入。新任务可在自己命名空间的既有flags槽存严格六键JSON String，再用独立专用bool true flag发变化通知；不为此放宽全局listener或改保存schema。读入时真正absent与显式null分开，坏JSON/非Dictionary/非整值schema和report严格拒。JSON数字解码为float，比较规范状态必须独立验证有限、精确整数、原离散域后仅规范两个整数字段，再整六字段精确比较，不能加epsilon或丢字段。

OS0和checks0不足以判成功：119368真实日志有bool(Dictionary) SCRIPT错误，旧报告和原源保持FAIL；坏JSON负例本身产生的17条Parse JSON ERROR则须按回溯明确为预期、仍不称clean。WeakRef返回Variant在项目warning-as-error下也要显式类型，proper的引擎退出码须立即捕获，不能让其后nvidia-smi等命令的0覆盖。

固定预算失败不洗成PASS。115872四完整collector、全逆映射和2473源首末/15保存完成，但91.679秒超过60秒，总体FAIL原样保存；后继只消费精确pin报告＋日志、确认唯一预算失败后的已完成SOURCE_ONLY组件，仍对实际场景重核全SHA/proof，不改预算、不重几何或全城。Yamen旧runtime collector没有Field叶，不能按另三区假定有；明确新增叶，并保留历史publication旧SHA。

实际站点必须来自当前作者NPC脚位，不能凭旧截图猜。102268已实际完成Docks取消＋同一封信Node亲领，但Market测试站2820,1960距作者本人1110,1240约1855px，Space当然无会话；只修NEW QA站位并补Market-only，保生产、不挪NPC、不重已完成码头。普通对话框遮住底部收信人和信件的截图也不能冒视觉通过，运行身份收据与美术实看信用分开。

## 2026-10-19w：文化支线的“核认”“交付”“回报”不能混成同一步

归信文案明确本人码头亲领，但初版状态机solve后可直接南市report已收到；即使设计文档写“未来补交接”，仍是当前原型语义漏洞。应在合同和状态机增加专用pickup/collected阶段，并测试未领取直接回报、提前/重复/错人错地领取拒绝；其余任务不得误用此状态。纯事件里的bool不是实际NPC到场或物品交接证明，正式Coordinator必须消费真实场景事件，不能接受玩家自报，也不能靠对话句末直接写已领取。

典故灵感不等于历史复现：董宣旧事、洛书传说、洛神赋文学分层记录原出处，具体收条时记、家书标识和九宫方位为原创。九宫须独立验证数字唯一与八线和及题面朝向，不能只有“正确字符串”。既有同题七支线先审，避免换名复刻取纸/诗会/机关寻宝。

测试不得要求所有人物normal情绪：对照DialogNode实际export枚举验显式作者值，同时固定资源SHA；本轮两offer共4concerned合法，QA修前键保存、actual前纠正，没有为测试改台词。候选资源真实加载与纯逻辑1723项过不代表NPC入口、距离或实际领取已接；数值0待审批也不是最终零奖励。

## 2026-10-19v：居民完整身份、对白覆盖与音频失败要分开计数

NPC多不等于可聊：本次36新增生活人crowd明确留空dialog/action。向其catalog直接补profile会被Field既有ground-anchored身份保护拒绝，不能为聊天关掉检查。人物display name与node.speaker不一致时默认头像不兜底（书生/诗会主持/脚夫），不能只数portrait文件存在；更不能拿160全身精灵当完成了立绘。

日常不能抢原任务入口。纸匠保taskprimary并给独立闲聊计划，三空聊居民只修改副本dialog字段；阶段要同时读真实quest状态与已有flag，旧solved单标记不授事后状态或奖励。首批12资源24句在实际Godot资源里核副作用为空，不能把设计JSON解析冒Field已可交谈。

生图要求2048×512不等于真实输出：本raw1942×809，四主要角色完整同人/有微动仍不授等格或30度镜头；A1边缘散点只作诊断，不能阈值删掉冒过。保留raw与失败、未知model/provider不猜。在线Edge7.2.8八段握手失败不意味着Python包没安装，不盲重试或改全局依赖。独立SAPI离线试音须明确真实voice名/共用声线/格式，不将WAV重命名MP3或冒原在线自然语音。文本、speaker、emotion、node_id和dialogSHA绑定，版本化输出拒覆盖，8离线合同单测无网络。WAV只解码有声不是听审；SHA hex字符串大小写应规范比较，原误拒报告保存。

## 2026-10-19u：门户克隆、来源后继与实际首绘分开验收

复制室内模板时必须核实际出口target_scene/target_pos，而不只入口、家具与显示名：府衙正堂克隆豪宅后仍返南市，真实Space返程抓到生产错误。只改两native门户语义与来源metadata，不重家具/几何；失败报告保留，后继通过不能把旧失败洗成成功。

严格来源闭包应包含实际读取的肖像import/ctex以及被迁移模块的原固定pin。明确旧SHA→新SHA、候选别名与真实owner证明可保持校验；不能泛化为“当前磁盘都接受”。测试接取任务后须等正常deferred重建与首绘可动，再断言NPC持久；不能靠强制setup或删生命周期检查通过。

计时冻结在Loading隐藏、Player可动的首个postdraw帧，完整来源postverify另列，whole脚本不是玩家Loading。实测Gate9.409s与府衙13.394s必须分别报告，不以一处达标宣称全城10s。编辑器可保持打开：普通源码/隔离新图导入及有限运行检查不需强关，只在真实同文件写冲突或资源不足时说明具体范围。通过的代表链不为退出码、截图或统计再重跑；最终守卫和文档收束即可交用户验收。

## 2026-10-19u：整批路线诊断、合法矩形实体与编辑器共存

不要逐个publisher遇拒后盲重跑。两次窄拒后先聚合所有route/anchor首拒：灯座1.55px擦碰、沿x80撞旧院墙、东bay穿原树、旧门前保护点仍在旧坐标。保原875/17/连续鞋体与NPC1085，不epsilon/删保护；只显式绕行、门前语义随门迁移，成功房间产物用exactSHA+wholeStorage+当前source复用，不重制作。

实体有solid_polygons_px=[]不代表无碰撞或非法：本两树本来是24×18矩形且blockingtrue。应按受限shape contract保矩形大小、平移foot/center/depth/render并保空poly，不能把空poly自动拒，也不能放宽任意shape。遇布局域问题先读真实packet/layout，Root关于render-only的推测经鲜证否定后明确撤回。

Editor运行不阻普通源码修改和无界面测试；隔离同res-path项目可只导入新图再复制精确新ctex，不扫描/重写主工程其它import。GUI Godot exe从PowerShell返回早于实际child，shell0不是engine自然0；看完整report+processgone并保未捕事实，后续distinct原子用console exe/Wait捕真实退出，不为OS码重跑成功链。Source-only候选proper遇canonical尚无新API是依赖阶段失败，不能用dynamic load绕解析后冒正式可用。

## 2026-10-18t：摆放、烘焙与任务生命周期必须按实际来源区分

幽灵树影先核ground_capture原caster与现树脚：府衙确为移树后原烘影残留，可还原树脚；南市移动PNG建筑自带影，原底图只烘四树，不应误重烘底图。建筑缩小塞空隙不等于规划：应撤重复体、按街坊给足实际alpha间距，门/返脚/solid/NAV同步新出版；历史几何PASS不能套新坐标。药铺椅子朝向问题可换原长凳，不需旋转整幅透视图。

有任务对白/感叹号不等于真人存在，古寺Scene无NPC且适配器原样返回空列表。接取后同段dialog继续set solved/complete和QuestManager.accept立即查旧flag都可致秒完；需结束offer，分独立调查、回报、领取，并对旧flag/重复reward做实际状态核。DialogPlayer自身不调用CityTasks.authorize，静态测试或直接play不能冒Field入口权限已接。候选人物别用ambient校准flag，现有Field会禁互动。普通portal不能随意添source_spawn_pos，否则改变构造分支。

生成目标1024不等于实际尺寸：本次builtin真实1254²，raw微alpha触左缘/边距FAIL必须保留。仅授权整canvas一次160²机械表示，不裁切/阈值清alpha，实际bbox与脚锚再独立核；tool未披露model/provider/cost保持null。用户编辑器活时准备源候选可继续，但缺闭包和实际验证就应明确NOTREADY收束，不能因耗时长以未部署草稿冒成果。

## 2026-10-18s：编辑器保存也会改变缓存来源；退出校验必须分世界/城区

原Field217490字节末尾连续2LF，Godot编辑器保存为单LF后217489字节、3462→3408。代码逻辑完全同但严格预制地图来源校验合理拒绝，导致Loading后回world。勿恢复容易再删的空行，勿关闭SHA/泛化忽略空白：保稳定编辑器格式，全文单字节逆证后发布明确当前source后继manifest/index；原出版first/final/proof全留。嵌套Templev13同pin必须一起NEWv14迁移，Market/Docks也包含Templehelper/v14来源闭包；仅修顶层Gate不足。

制作脚本/GD固定恰1尾LF/CR0，再预制冻结，避免普通编辑器保存改多余EOF空行。运行仍只严格接受当前3408，内部byte/BOM/0LF/3LF/旧3462等负例必须拒；无双哈希。原artifact与NAV不重做，不为纯元数据改动重跑全城/十房。

34260真实入口/32px/出城全部通过后整体FAIL，因为复用城区退出夹具要求当前world._district_session=null也产出released=true。保整体FAIL/2检查原证；独立world-cleanup键只验证treeexit/Fieldstream弱引用gone/drain0即可补清理域，不反复跑已过旅行造绿。世界与城区应有不同严格生命周期合同，而不是统一放宽released断言。

## 2026-10-18r：首绘可动边界、预制运行包与TRES弱缓存

Loading时间在目标Scene实际绘制、Loading隐藏、人物可动且source finalized时冻结，后续完整SHA/Physics验收另计但仍须通过。夹具arm前为取portal加载Scene会掩盖默认出生费用；new-game/reset原有formal_version也在进图计时外，不能冒进程总启动或所有首次解析计入。

Godot CACHE_REUSE不等于强驻留：18MB文本layout随临时Scene释放后三次各约1.1秒解析；强持合法Scene元数据后同实例读取约微秒。保原初始化阶段，不改路径/二进制别名/remap，不持全部贴图。默认进图15.07→6.72秒。测出LM207仅0.787秒后拒绝F95B分流，不为不足1秒屏障扰动大量source依赖。

城市原完整制作管线可出版原生Scene/layout/record/NAV，运行仍全来源首末SHA、动态任务/门/Field合同；不是跳过正确性。资源安全图固定白名单脚本，保typed Array/shared ref/full storage，拒未知Resource；Yamen真实Dialog先最小单元，避免整包试错。source迁移用新binding、旧proof原留，不删源叶。guard总授权源数不等于旧事实变化数；本轮WorldContract不在818，另精备核，原错6/812 false报告保留，鲜核实际5/813。

## 2026-10-18q：门户要接原生交互形状；驻留要与运行投影和发布数值域一致

新增三门仅有pos/size不足：Field严格出口要求interaction_polygon_px，否则禁用rectangle后Area为空。只补原40×32四点poly，不扩大门域。第二层问题是Router只计冻结layout.portals而新门在运行投影里，须调用同源project_portals并仍严格唯一目标。不能因室内564检查成功就冒门能进出。

第三层为float32域：mansion raw脚2830.8先构Vector2再除3072，与TRES writer先scalar double除再构Vector2差1ULP。C绑定沿facade已委派g，不要只看旧author文件猜旧坐标。41960核实际选中row/layout/原生8bytes，仅此一房差；修shared scalar-first helper，Router parked authored与g.room_return都仍精确==，不epsilon掩盖。旧FAIL保留。

间距child改District源会使十房registry顶层+十行11处pin失效；采用NEW registry声明迁移、逆变换全字段等immutable prior，再用prior核旧89历史proof，当前room仍逐SHA核新源。不能篡历史proof。QA检查实际Sprite还要服从当前task projection：record保留泥痕不等于未接任务就应渲染，唯一零碰撞线索有界核对，其他物件/实体不跳过。

## 2026-10-17p：数据制作完不等于普通入口已用；房屋通行通过不等于视觉间距合理

NEW动态调用正确性还要核本层wrapper签名：C._safe_body_cpu仅3参，底层/相邻_raster_walk_cpu及_all_gameplay_safe_cpu可接cancel，不应套4参。proper可能看不到Variant动态调用错误；首11088保留SCRIPT失败，retry1只修多参且保上层cancel，67340才CPU通过。另嵌套binding中的source_first是历史，不是current源码：本轮Root把历史Field277B错认current，经绝对路径与鲜815核实current638C，原QA稿正确；不能按记忆制造新pin或无意义失败重跑。

十新拼装室内虽已有28图/59家具/337来源和CPU证明，正式bool仍false，用户普通同ID因此继续旧整图。交付必须核Router实际解析路径和Field组件，而不是按生成文件或CPU计数宣称已替换。当前仅最小true候选，尚无本轮真实Field或正式通过。

码头原导航/碰撞通过仍有新增大仓与两侧独栋屋檐、墙体明显穿插；.55淡化只把穿插暴露得更明显，不是修布局的方法。全画布bbox可作初筛，但透明边/阴影不能直接定罪，需真实轮廓和画面。撤重复无门建筑要同步撤Scene条目、底座并用原raw重建NAV，不能hide后留下不可见墙；旧冻结父出版保留，用显式新child承接。候选与正式需分开记，用户游戏活着时不抢显存或恢复其存档。

## 2026-10-17o：累计计时不能解释某一帧gap，入口准备与Fieldsetup要分边界

原字典快照可能大但实测发布63.553ms/导航提交7.677ms，不能凭形状认作秒级瓶颈。packet9次累计817.389ms跨1337..1501，其最长91.634ms在1501，绝不能全归1336→1337的1.664372s停顿。import结束比gap起点早50us也应判区间不相交，不能按阶段名称拼总数。只增观测的本次arrival21.837s较前38.017快，不是新优化收益。

resolve返回之后仍有Router到达校验、world Scene/layout重读与Loading同步handoff；Field实例化/首setup在更晚帧，不能跨边界归因。下一计时覆盖候选同步链后再改算法，保留source/owner/取消完整性；本次526/0证明功能与诊断完整而非目标加载速度已达，52Image7旧退出ERROR如实保留。

## 2026-10-17n：局部19微秒不等于整场更快；max只有数值无法归因

树Mesh首次已逐slot/primitive/storage验证后，可本attempt局部强持两Resource供后续原材质RGBA/mip，省同两CACHE_IGNORE重读；不globalcache、不把GPU资源放worker、不省数组与材质、不改变同步路径。实际tree.load19us只证明此局部，整次cold38.017s比前22.952慢，425/0正确性也不等于提速验收；其它未改stage慢不能无证据归用户环境/新observer。新scalar max事件限两域各一条，圈定3.204s帧间且C.activefalse→true，但不能从前后状态唯一推出某函数；旧max1.69s无现场，不倒填事件。

Godot合法VRAM texture import可只有`remap.path.s3tc`而无`path`。QA不能硬取path；NEW只认可实际source SHA钉住的明确唯一path/s3tc、对应format metadata/source_file/type/单dest_files与ctex，不任意format fallback也不跳compiled校验。原24564夹具FAIL与末complete=false断言保留，6.584秒不是30秒超时。旧sync1.421/新live含yield2.323秒也不是速度基准，局部取消内部locals未暴露时不能冒weakref直接无漏证明。

## 2026-10-17m：批准四对不等于四次校验；live可选context不能静默回同步

Gate两native报告+manifest各有四import及四ctex，共24个批准路径调用，不是12对；approval每次15叶及raw/import/ctex重复读，静态下界1.139GB。同一真实joined/token/id/Script来源收据可替SHA，但每条精确审批/三联/逐实例几何与全RGBA、首末625完整SHA仍必须保留，不用历史SHA相等绕过批准。原API null供同步兼容时，live消费者必须额外显式_owned门禁，避免缺上下文自动走磁盘fallback；取消全join后才release共享只读收据。

CPU完整packet等价4.148→1.481s与真实module4.258→1.675s支持局部收益；整场24.705→22.952s只单次1.753s，仍gap1.69s，不冒全程流畅。console.exe可启动不同PID的GUI进程：本次wrapper25200自然0而actual93528只有成功result，不能把wrapper码套child；后续直接GUIexe29348持Process才有actual自然0。有限guard列表要审成员，不按预期变更数猜：506初始未含Stable，四差真实；Stable另CPU101+predeploy全文备份保护，不事后虚补507首ticks。所有旧退出ERROR保留。

## 2026-10-17l：找准prepare_live而非materialize名字，逐实例数学不能被prototype缓存省略

BASE main9.888秒包括prepare_live完整检查，实际base.materialize仅7.420毫秒。对象映射17次仍对6墙重复读40MB .res SHA，并对未变PNG重复SHA；已有joined同token/id/Script身份的完整来源收据可复用，必须缺path/unready/cancel拒且无filefallback，同步Web仍原读盘，末次全SHA不减。缓存的是资源身份，不是逐实例caster/脚点/basis数学；后者每物件必须执行，1px负例不能省。

CPU单次旧新17slice1.098→.442秒与完整state/error相同支持此局部改进；实际冷24.705秒较上轮43.975快，但其它未改阶段亦下降，不能把全19.27秒归小改或无证据环境原因，也不能承诺稳定百分比。保原观测器以免混入仪器改动；当前waitgap1.67秒仍有卡顿，不冒全程流畅。只授当前Gate实际；Market Note算法仅pin更改，不顺带授Market提速。

## 2026-10-17k：阶段快不等于整链快，CPU正确性与性能证据要分开

完整SHA同一624源2.92GB实测1/2/4线程14.154/6.924/3.640秒且全部map/末重哈精确相同，能支持选择4线程；单次既定顺序有OS缓存影响，不能冒完全同冷条件。真实普通world→Gate的来源首/末确约3.741/3.883秒，但完整43.975秒反慢此前35.260秒，407项正确性零失败也不能写成整体提速PASS。其它未改BASEmain/moduleCPU等也慢，分项有包含/重叠不能求和归因；事后CPU负载/电源计划不能当测试同时证据，不私改电源/杀用户进程。

不要在WorkerThreadPool任务里再排同池子任务并等待；有界独立Thread全部join后才发布完整SHA map，missing/错误/合作cancel全组清空，每文件独占FileAccess/HashingContext，原1MiB读与错误/长度/摘要检查不减。读中取消应证实至少读过块且未全部完成，不能用预取消替代。

薄QA基类同步virtual被async子类覆盖时，本轮首收尾typed check出现Object→bool SCRIPT；原因不唯一，保留原失败/noresult/OS−1。NEW最小只读诊断显示原始返回/比较均BOOL，再NEW明确基类async contract并落盘原始比较域，保持严格相等/预算/生产不动。修后CPU通过只能授本次有限运行，不武断宣布所有线程路径绝无race。

## 2026-10-17j：存活场景复用与磁盘缓存、首入提速要分清；Array回执注意别名

同一已完成冷校验Field离开SceneTree/Physics后保留，回来复用同Scene/Player/静态Sprite/Texture/身体/导航Image及人群会话，可以避免完整重建。本轮实际普通Space到Loading隐藏可动1.527秒，首次仍35.260秒、出世界仍11.475秒，不能用内部930ms回执冒完整延迟，也不能把暖返回收益冒首次提速。来源长度/秒级mtime用于普通编辑失效，非伪造时间戳防护/新鲜磁盘SHA；只保留一外场、取消/新游戏释放专项与任务dirty动态投影要独立测。code-review核查这些生命周期边界，不重跑全城套件。

GDScript的`_npc_nodes=ambient`共享Array，随后追加8位非ambient NPC会让`ambient.size()`变18。旧回执`ambient_preserved`不是实际保留十人的计数；不能改生产消除测试失败或粗放改期望为18。NEW夹具独立按任务投影/旗标得到8个实际ID、精确十人四个原生身份保持、总18两旧回执同域，同时逐条检查任务/对话/位置。旧1124失败保留，retry2通过。Dictionary证据若直接引用随后cleanup.clear的变量，最终JSON会丢before映射；必须注明当帧断言信用与落盘边界，不能事后补填猜测原数据。

## 2026-10-17i：导入自动3D转换可让已验证入口再次失效；必须测真实转场

四份历史无损/no-mip配置保留detect_3d/compress_to=1，编辑器检测到3D使用后自动改mode2/mips/S3TC，Gate严格来源拒绝，Router结束Loading还原world；没有日志ERROR不等于成功（C错误仅存内部数组）。仅恢复历史配置会复发。新配置必须明确detect0并做完整RGBA验证：本次新CTEX全字节仅offset19 13→12，不能伪称旧CTEX SHA相同。保留旧失败，用独立四对8path/oldSHA/newSHA/完整RGBA证明授权，其余48与历史manifest/capture/record严格保持；当前C首末记录实际新SHA，不把历史证明冒新运行来源。

码头直接出生通过不覆盖world→Gate。96048唯一真实验证先正常走96px，再按Space成功进入原1860城门并走32px，383/0/自然0；区分world半径5/17与city34×24/87517，等待所有owner/worker结束才判回退。修复后冷加载仍36.057秒，不能把“能进城”写成提速完成。存档与用户项目配置不为修来源漂移而回滚。原90360错误容器比较导致SCRIPT/守卫停止，必须使用ConfigFile实际原始Array域逐元素核对，不能让测试夹具故障伪装生产错误。

## 2026-10-16h：实际对象与出版TRES比较要使用既有的精确序列化域

码头真实入场26584已ready却被QA对未改仓库的`_equal_value`拦截。纯原条目诊断108536实证唯一深度叶原生0.283203125/文本0.28320313，Float32均`0000913e`；这不是物体移动。NEW关键夹具仅在两处视觉storage比较使用工程既有的路径限定`equal_visual_serialized_value`，其它字段仍严格比较，失败时输出具体leaf与原生字节；不采用epsilon或忽略深度。修后100808自然OS0/382项0失败，原失败保留。真实入场通过后才精备helper全文，仅切正式bool，不能把局部比例图冒普通地图验收。退出纹理/资源告警单独保留，不因断言通过宣称clean。

## 2026-10-16h：职业身份不要按NPC序号选，Resource深拷贝不保证外部layout隔离

- Harbour静驻奇偶交替FARMER/WAITER把装卸与记货都画成托盘小二。按两个明确岗位ID替专用形象，不全局替WAITER或换8/10个无关人物；只换sprite，原任务/位置/静驻/身体保持。高分辨率单帧虽hframes1可读，直接入图会放大物理身体，必须有显式全canvas160运行派生、保原raw和Pillow实际域，不能谎称raw==runtime。
- 开始等比投影办公门只有103px；显式xy.488/.68 runtime投影保新基底在旧闭矩形、门143.48，再看实际一图而不是额外生图/裁资产。新视觉source/sourceSHA/sourceSize必须同步；旧actual_gpu只能移明确历史来源，不能给新图挂旧GPU证明。
- Scene.duplicate(true)对外部ExtResource layout仍可共享。QA构造expected先修改它，会污染随后actual输入；26872用真实instanceID、原条目前后与5leaf native类型/bytes证实此因。仅NEW fixture显式clone外部layout，加完整source storage不变断言；严格_equal/生产代码/旧FAIL全保，不能用忽略historical字段掩盖测试污染。
- 局部两NPC+1楼GPU只几十MiB，可以另立512MiBfree局部门槛并记录真实纹理计数；这不授权降低world/重Field原4.188GiB，也不能把局部摆图冒正式码头。旧floorROI船黑影未叠W补片是scope限制，不判完整正式画面回归。
- 用户关游戏不必然够显存；实查editor仍用约2.6GiB，free3.5低原门槛时请保存关闭，不私停。CPU/局部已过就停止复测，等外部状态再仅一真实public关键入场。完整退出纹理ERROR保留，断言0FAIL与OS0不叫clean。

## 2026-10-16g：组装室内计数、真实素材和适配边界分开验

- 10新布局+旧铁匠是11类型，不是11新门脸或新衙门。4空壳/24家具逐件来源；透明10%边FAIL不能因主体完整改称sprite标准，保原RGBA尾像素，真实遮挡实图另验。
- ART初manifest批次全00虽200项source检查通过，但原检查没覆盖批次链接。新v2逐真实batch反查且pin批次SHA，旧错与旧报告留存，不把旧200/0扩授来源链。
- 独立CPU原Array<float>与int literal数组拒绝，须逐标量位值证实后只修测试域；general_stall与ART market_counter须唯一SceneID显式别名，不能模糊忽略。真实客栈柜角拒绝只改绕角中点，保柜台/身体/地板/终点，再复原完整71路一次，不降低门禁。
- 新Scene走旧facade会遇到Smith固定6件、no-arg author、旧dialog白名单和+42脚点假设。适配要按明确房间会话/META/当前propIDs/原NPC+dialogSHA分流，并玩家生成前同row完整SHA末检；不能用旧C收据假授房间。20112薄键验10会话8柱2对话和clone/storage/伪SHA克隆拒绝，避免重全路线/导入/GPU。
- 门口图片原1210靠柜台，不因几何clear就当门；Root raw视图确认1288门洞中心，再按原native投影和当前全部新增底座做三短路。136ms CPU与50中心不授Physics/Space。
- 跨世界真实live Field复用性能必须测到Loading隐藏且可动；35状态夹具不能代世界往返，固定512MiB是估算非VRAM，元数据快检查不是新鲜SHA。用户游戏未退出且free显存不足原门槛时停在候选，不降门槛/私停/无止境整夜测试。
- 较长交接期save0/bak变化写入者未观测，保新字节；各own测试15save相等不授整轮0差。mtime_ticks以字符串记录，数字精度丢失快照不能追补成exact证据。

## 2026-10-16f：独立oracle也要拆分验证；新游戏reset不是当前Field销毁

- 独立CPU85776在无物空地2226,1350拒绝，而生产发布已采样通过。49784仅同一点old/combined/delta三域分量实测，确认矩形floor内点2241,1362的原生point-in-poly假false；mask875全白、17/连续碰撞/solid无命中。NEW辅助仅对明确轴对齐矩形用精确bounds算术，保留旧FAIL/旧辅助与solid/875/17，补内/边/外负例；不移动正确家具或削路线、加epsilon去迎合测试。
- Router.reset_for_new_game只清状态和parked resident，不必销active SceneTree.current_scene。Market110080旧10退出断言失败必须保留；NEW夹具明确销毁QA自己创建的Field，观察tree_exited、生产lease.released、Field/actor弱引用均释放。31068只补这一退出作用域，不复用整轮PASS字样或重人流/门户。
- 四域R单bool切正式也要精确false全文备份；普通无candidate/null默认出生、真32px/Physics/Loadinghidden最小验证足够，不重4s动画/总览或全任务。956/0与4图只授本批接线，41陈设不是41种建筑，职业居民/真药摊/官署外形配套增量不能替灰地和重复街屋的艺术判断。
- C/Field变更会影响固定依赖Temple binding。保留原2E2E与原source_first/final历史，NEW v2只授权两实际sourceSHA、追加旧binding pin，Root两行接340E；只一次普通寺出生验证，不重七站。whole脚本秒数与纯加载时间分开，退出纹理/资源告警不因为断言0FAIL就抹掉。

## 2026-10-16e：原UV与source像素运算不是同一native域，功能验收不能替美术

- 门户原数据Vector2(.22,.8)*WORLD与JSON sourcePx337.92先转Vector2再*1.25恰差1ULP。16808真实出口Area已ready但夹具exact失败必须保留；NEW只按原canonical的同native运算生成期望，零epsilon、零生产修改。七站实际信用可复用，不应因为后面的夹具错而重跑整组，70888只验两出口。
- 新组装场景要有自己的来源首末/取消owner/实际纹理与storage证明，不伪装旧canonical或拿四城C收据替Temple；低家具/高殿分fade策略。9真实PNG/import/directCTEX全RGBA不擦alpha1尾，邻空反例实测，而非提高alpha阈值掩盖。
- 单寺基础组装21物件功能过，不代表环境艺术完成。实际PNG仍暴露砖块过大、竹石疏离、短墙陈列感，Root/ART只准基础试玩并明确待办；不再用新一轮完整技术验收掩盖地表和空间丰富度问题。

## 2026-10-16d：移动楼图必须移动native底座；低家具与屋顶分策略

- 图像平移不能代替真实solid平移：府衙东厢房与纵墙实际22×10重叠。新record、render的city_v3_solid_polygons_px、native物理与新walk同源生成，逐24项核两改/22原样，并以旧基底clear/新基底blocked验证无残留隐形阻挡。
- 矮桌、砧墩、风箱和淬火桶不应混入屋顶fade；只移除家具fade记录，保留原alpha遮挡/脚点排序。使用现有当帧玩家视觉ghost，不复制Actor/碰撞，不泛改NPC。native Float正alpha命中与RGBA8量化非零计数不是同一域，应分别记录并严格比较CPU蒙版/实际texture字节，不能直接混等或加epsilon。
- 合并测试把房间四站及第二public串在120秒里，第二请求已92.998秒，最终无result不得以四PNG冒整轮通过。独立Yamen90秒519/0可复用两巷证据。随后普通出生60秒到达上限时末检worker未完，reset后Fieldidentity拒是否衍生未证；保FAIL、停止自动延时循环，不能因candidate已过就称formal已通过。十房设计与十房素材/正式接入分别计数。

## 2026-10-16c：替换实体时核对地表烘焙投影

- 删除旧船sprite不代表影子消失：Docks floor已包含原moored_canal_boat caster影。107864功能282/0仍被实图发现脱体黑影，不能用节点/路径检查代替画面验收。只在真实samecapture ON/OFF均有的水域局部修补，不编辑旧底图或猜单色（原ROI有14种RGBA）。
- OFF432×592带halo局部Lanczos半缩裁200×280，与整张缩放同ROI逐字节相等、3776边缘0差；CPU worker传224KB严格Scene-owned数据，Field只建小ImageTexture。避免上传100MB全图/新增全局proof缓存；完整published比较后才加metadata，之后storage快照仍纳入字节包，导航/任务不豁免。
- 首保存拒例实际还有语义漏项：generic Gate投影遗漏原apply_entry的atlas/sort/z，正确做法是无布局改动就完整保留父entry。Docks旧20完整clone，新8仅删无consumer冗余render world_origin，完整author/record保留；不以通用epsilon掩盖。原失败封存。最后只普通双出生验补片，复用本轮已过282，禁止再全城整夜回归。

## 2026-10-16b：JSON读回与TRES原生物理坐标域必须区分

- 新布局完整record拒绝的85100短CPU诊断显示，JSON文件即使保留245.75999450683594完整字面，Godot JSON.parse读回也可能是245.7599945068359。不能猜成写文件截断，或加通用epsilon。新child在完整原publisher stringify(full_precision=true)/parse域逐字段严格对比，实际几何仍保留native记录；真实1px/新增字段负例应继续拒绝。
- 原record域问题与Scene ResourceSaver域是两处不同拒点。24996两城全storage纯CPU重放一次收齐9叶，只有3新树的collision_size_px/physical_center_px文本缩写，全部PackedFloat32Array字节完全相同。只可对明确来源绑定物件、真实使用Vector2的字段核精确原生位；不能泛化到任务/门户/元数据或旧地图比较器，更不能以纯重放替实际Field信用。旧110284/21700 GPU失败、原脚本和全stderr保留。
- 明确public同请求FAILED时测试应立即拒绝，不空等剩余60秒；正常arrival上限及物理/视觉门禁不变。propercheck失败仍不得启动actual。透明PNG的alpha0隐藏RGB被某些查看器显示，不等于真实合成halo；检查必须标准RGBA over不透明底，不能擅自阈值擦alpha。

## 2026-10-16：独立室内几何与 typed Array 克隆适配

- Object.set("blockers",[])不能假设清空Array[Dictionary]属性：本轮5336实际拒绝后，2616纯诊断证明5个clone仍留13/10/9/10/10旧阻挡，独立oracle又按旧矩形解释而失败。NEW23840用显式Array[Dictionary]空数组，核clone0/source原计数不变，才获得五房CPU适配信用；最终6F048实测同样核floor/solids精确计数。不可为测试通过删掉生产碰撞或oracle检查。
- 新内景1536×1024真实cover到1920×1280，source feet缩放后只减一次legacy +42来得到Player origin；34×24身体不随cover缩放。家具底座先编译source/world polygons，避免每帧JSON/几何重建。新NPC只对本批节点启用已有ground anchored模式，不能全局改旧角色。可见alpha脚仍需记录实际偏差，不用名义anchor代替像素结论。
- 继承测试脚本不可用与父类不同签名的同名方法；WeakRef等推断warning-as-error要显式类型。proper check失败就不准启动actual；97364是ROOT串联命令未按退出码门禁的真实失误，必须保留，之后check与actual分两次调用。
- 新门脸主体居中不代表透明边距合格：灰雾halo/非零alpha可能延伸到全图边缘。三图一次生成＋一次定向编辑仍未过时保留候选、停止循环，不用alpha阈值擦除来假装完整cutout。室内原图可独立做geometry/import接入，不应因门脸未过而把所有资产当同一完成状态。

## 2026-10-16：活外场驻留、任务接受副作用与非阻挡证物

- 对话scene根可能只是CanvasLayer，真实UI脚本位于子Control；DialogPlayer._box不等于DialogBox。13692测试误读根的_choice_rects返回null导致SCRIPT，须保留FAIL，新脚本读取真实DialogBox、核脚本身份并在原deadline内等2个真实Rect2选项，再发送正常KEY2/KEY1；不能改生产节点树来迎合测试，或直接调用私有choose冒充UI输入。最终22420自然0/3446/0。
- 进屋时真正保持一个已完成首末SHA/像素/几何验证的外场实例，摘出SceneTree强持有，可同时退出Physics/Canvas/处理。只hide或DISABLED不能隔离autoload信号，须逐连接记录并断开指向整个Field子树的连接；恢复时重连，房内任务变化从live managers读回而不是还原旧任务快照。单槽、估算内存上限、离城/新游戏/失败/取消释放不可遗漏。完整proof的SHA值和stamps应绑定真实成功_ready，不能只比path集合/mtime，否则克隆伪SHA可能被当作合法收据。秒mtime是编辑器失效信号，不是防同秒同长伪造的密码学证明。
- 门口固定authored exit与玩家真实进入脚点是两份事实。把两者要求相等，会只让精确门轴QA命中快返、普通玩家仍冷重建。分别绑定固定room契约与记忆的真实安全脚点。预审偏40px不一定在门热区：原客栈polygon仅40x32，52780拒绝正确；NEW合法偏10px测试且不扩大门/缩身体。实际return计时必须到Loading完全隐藏+can_move，不能把Router READY前收据当最终耗时。
- DialogPlayer在side offer显示时会执行除accept_quest以外的node effects。把started flag与accept_quest写同node，会导致玩家还没选择、甚至拒绝时就置flag/隐藏NPC。最窄业务修法是offer节点无副作用，接受分支next:accepted节点再置started；真实play/choose拒与接各测，不能只静态看字段。
- 从任务箱改成真人NPC时，不能把原箱子的hide_flag=started照搬到人。常驻委托者应有未接/进行/待回报/完成对白。旧箱若已有烘焙solid，隐藏图会留幽灵墙；本批保普通货物图/solid无任务action，真正证物用原nonblocking废仓泥痕，active+线索旗标控制同一图/热区/动作，取证后移除。原source Scene/导航数组与runtime任务投影分开，不能把改过的render数组冒充旧完整证明，或为任务显示删NAV。
- 数量必须按真实可辨功能计：9room ID/8门并不等于9种室内（实际3）；文件名building可能是树叶/黑裁片，仓库/铁匠铺不能拿地下洞或旧夜景凑。builtin新5室内原图是候选，未做进口/地图碰撞/门轴前不计正式可玩类型。

## 2026-10-15：公开城市排队与同城取消必须保持原导航

桌面public go_field_smart不能在Loading前调用同步完整resolve；复用原token/live链后，true只能表示已排队，实际ready须独立等Field。唯一依赖旧bool提交portal return坐标的内部调用改为private prepared原体，不能先写return再凭排队true声称提交。go_chapter预加载是另一路径，不借本轮public通过称全部入口优化。

同城live开始会erase目标C四nav；取消时只藏Loading会使旧Field无法走。仅请求期保存四map项存在状态/原mask Image引用，合作cancel并join全部worker后，确认无后继owner且原Scene仍在，再精确undo；不作为新请求缓存证明。LM启动即失败可能已清Ctoken，因此请求identity与C/LM ownership必须分开，允许清自己的busy，禁止清新external Loading。Dictionary按引用传递，清active dict后还读局部context.token会出错，须断开owner引用而不clear局部context。Script不能用C.get读取static字段，改显式引用四dictionary。Web的resolve_live本来回退non-live，新的desktop队列必须显式排除Web。

108812实际live首末多出6室内背景import/ctex，而917旧测试before缺它们；不删source首末assert或补旧before。NEW E2D8只在启动前加入6精确pins，924源首末同，87192自然0/2193/0与真实晚CPU取消/重入通过。首真实post_draw应先于worker；测显示属性而不实际frame_post_draw不能证明Loading已到屏幕。public完整观测maxgap有效，但room旧父framegap未连得到0，不得宣称零卡顿。


## 2026-10-15：室内 cover 坐标与公共城市重复解析

- 107684 的室内拒绝是 QA 域混用：1536×1024、fill_viewport=true 的背景在1920视口实际为1920×1280，人物960/755.2位于可行走空地、同帧Physics=true；不能据未投影的1536 oracle把右桌移走或缩小阻挡。NEW测试独立读PNG头+cover公式核实际画布，仅投影normalized家具/区域，34×24原生身体和+42偏移不缩放；875每点同时核地面与家具。
- effective_author_record(id)不是纯getter，会重新prepare。已完整完成生产校验的实机测试，应深拷贝既有record并严格核binding/meta/manifest/objects/slots/routes，用独立原始mask+875/17/Physics验收，不能为了读证据再触发完整城市校验。
- public go_field_smart原同调用4次完整城市resolve。Router EEA08CA0仅两行复用已验证city_scene选择控制器与默认spawn，原显式/同场出生优先级和非城市分支不变，初始解析与迁移完整检查仍保留。A3本次同步69.470s（旧A2本次132.905s）只是实际观察，非稳定提速比例或不卡；真实返回南市仍21.367/21.348s。
- A2的12项import/ctex时间变化（字节/SHA相同）仍保留guard FAIL，写入者未观测不归定editor。A3与B3新鲜保护源和玩家首末exactticks保持；不能重置旧失败或恢复玩家文件。


## 2026-10-15：公开城市定位必须显式说明坐标版本；Loading耗时要拆真实转场与QA

99548 的 Gate真实Space/875/17/Physics通过，但随后用公开go_field_smart指定当前Yamen[300,1220]而省略local_spawn_version，reset后的记录默认1。旧迁移分支需要真实source_scene，空source被严格拒，不能误判为新门口碰撞或松门禁。NEW单Market测试明确五参(id,spawn,"",-1,C.VERSION=3)，实际27260自然0/149零失败；这只证明正确域，不改变生产迁移策略或旧失败。

同轮Market真实Space至ready22.160s、最大可见帧gap614873us；完整测试146.553s另含公开Yamen setup115.236s（其中同步调用83.421s）和独立QA全来源oracle7.336s。QA同步耗时不能扣成用户提速，也不能用两张Loading图授全程不卡。模块CPU207ms/5帧及4原fullRGBA导入通过只授这段后台拆分；真正public同步与冷加载仍待。生成船v2虽然刚性船体不再贴边，alpha>0范围[168,128,991,1465]仍不满足原>=10%透明边距，保候选拒例，不用alpha阈值或人工裁切冒sprite通过。

## 2026-10-14：原生 Vector2i 与 PowerShell 数字转换不等价

农田12dirty候选81896在分配GPU前因素材子集总像素预审失败，正式资源未改。独立scout用PowerShell `[int]` 把清河原render_size_px高度306.666656494141转307，而原Godot compositor `Vector2i`转换为306；仅这一幅460宽建筑使总像素1,555,023与原生1,554,563差460，body45/draw47/key45不变。22660实际CPU复用原Vector2i/Float32 Vector2/round/Rect2i操作记录所有45对象（diagnostic7DF04D16），确认不是资源或几何变化。必须先记录原生实际值，再做NEW预审事实修正并绑定诊断／旧失败源，不能直接删校验、加epsilon或把失败改PASS。原82AE/7653/81896 FAIL保留，新CDB2/9A90仅metadata事实与来源绑定，原采样/缩放/几何/RGBA判据保持。

## 2026-10-14：外部准备阶段旧Field仍ready不是回退；UI以可见内容测边界

世界入洛阳源校验先由LoadingManager._external_active显示loading并保留旧Field，_transition_active此时尚false。29352测试35ms把旧ready世界误判为回退，自然OS1/95/2；当帧source_worker_active=true、errors[]。NEW测试须等LM transition/external、C active/source/navigation/baseCPU/BASElive、预读active/drain全部idle，再判断目标到达或真正回退，不能删除wrongready拒例或延长预算。A7FCE修后47320原正常INPUT/Space往返133/0自然OS0，生产未为测试放宽。

小地图牌匾PNG含大透明canvas；用max(canvas.right,map.right)做右对齐测试会误授通过（94488）。正确排版以小地图面板right为边界，牌匾可见alpha中心共同定位，实际两分辨率截图确认F7F修后16px/11.52px。

Gate来源漂移来自四.import导入设置：无损无mip变VRAM＋mip、NOR normal_map变1，而原PNG/UID与旧compiled仍正确。恢复旧字节解决当前入口严格拒绝，但旧detect_3d/compress_to=1不能保证未来3D自动检测不再转；长期须明确disable并重新冻结来源闭包、实测原RGBA，不仅替换SHA或每次转场偷偷恢复。

## 2026-10-14：复用图片也必须核实际导入像素，短启动不要重跑素材全审

南市扩充使用的三张旧 PNG 文件 SHA 保持不代表 Godot 纹理 RGBA 保持。只读 GPU 诊断 77684 确认：作者/26物件/原7路线/gameplay/floor 全部精确相等，walk 原像素与导入像素相等，但 street_row、goods_stall、native_tree 的导入 RGBA 与原图不同；三份旧 `.import` 均开启 `fix_alpha_border`。不能据通用 composition 拒绝擅改碰撞，也不能忽略透明像素或放宽完整 RGBA。最窄制作独立、原字节完全相同的 v2 运行别名，关闭透明边修正/预乘、保持无损及尺寸，旧 PNG/import/v1 全保留。新 source 与 alias 双路径同 SHA，运行时完整 RGBA 检查全文不变；6148 实机 source 与几何/阻挡/淡化/Space 往返138检查零失败。

测试 pin 应在启动前逐项核实际 SHA 和64字符长度。首98036因 LoadingManager 哈希误多 `FE` 拒绝，实际加载源码/保存没有变化；旧测试源与失败保留，新副本仅改字面量。不要把没有运行过的玩法授通过。

短正式启动不应重复已通过候选的独立全地表审查。95800正式短测在90秒共享预算内仅余17.628秒等待入场，仍失败；不能扩时或改写旧 FAIL。新启动检查可严格绑定完整候选结果、所有当前源/import和明确批准的 canonical 字节，复用已过的来源/几何证据，继续实际入场、26节点、原出生875/17足点与Physics检查；必须标注本轮没有重跑完整地表。根进程 WaitForExit 到期后再出现完整结果，不等于捕获了真实OS退出码：6148和95800后来自然消失但退出码未知，不能记自然OS0或限时整轮完成。

## 2026-10-14：参考包应绑定来源与精灵合同证据，不只绑定图片

素材PNG没变不代表参考合同没变。首CE/FF工具只检查sprite evidence存在，导出没有其实际SHA，虎处理器改变而索引/PNG/source report不变时旧包可能仍被接受。最窄给observed增加按合同路径筛选的sprite_contract_evidence，Node和浏览器导出镜像同时带入，严格deepEqual可拒旧包；新增独立反例必须证明三input SHA和PNG没变，不能靠整索引改动伪造拒例。

路径事实/登记状态/艺术许可分开：proposal/candidate目录名不决定现役，game/art入库也不等于绑定。素材板adopted须记录当前canonical/layout/NPC链，但工具文件存在检查不解析整链语义；许可未知与未验alpha保持未知，不套上游Apache或某个CC0材质给混合成品。浏览器草稿必须不能改路径/来源/采用事实，schema全验通过才换state，导入失败保旧。

本地file页面lazy图的DOM load/paint有先后：首次截图可能空卡，不能马上归因路径或授视觉。实际后续naturalWidth与二次截图一起核，本轮20图都成功。浏览器File/DataTransfer可以验证真实change处理器，但不能冒OS文件选择器通过；导出按钮Blob经独立CLI refs回核比只调纯helper多一层真实证据。只测工具关键，不重开Godot全世界回归。

## 2026-10-14：有限并发要覆盖旧请求排空，测速必须包含入口同步调用

Godot线程读取无直接取消接口；旧owner取消只转drain，finished才get并丢弃。pending+drain共同计入8的上限，同path旧请求排空前不重复request/get；单看新队列长度会漏旧后端工作。取消还须清原局部数组（别留下别名）并在每个await后核owner，防旧协程失败/释放新转场。实际同path在途取消夹具旧false/新true，仅队列信用，不冒Field取消；8是请求数而非引擎线程数，也不限制全部保留纹理的显存。

请求前started→同步publicRouter→首process_frame观测的8.744秒，是含调用的首观察间隔，不是两个已观察帧之差；当时预读尚未开始。2692资源预读5.834s不能替代完整入场18.854s。先测public前后、资源/落点/界面分项再认因；用户进程运行、OS缓存不受控，无旧串行对照，不给cold或提速百分比。

autoload源码直接--script/--check-only不能建立SceneRouter单例名（本次旧版也有同原引用），不要为隔离预检错误改生产；使用SceneTree驱动proper check-only再正常project运行。自然OS0与28/0功能检查不覆盖完整stderr退出资源ERROR；缺失资源负例的expected错误、rawImage提醒、GL/CompressedTexture退出告警分开保留，不泛称clean。

## 2026-10-14：HUD对齐应取实际贴图节点中心，2D视口不要用3D属性

MapInfoPanel的子MapPanelArt有169px本地偏移且PNG带透明边，父容器center不等牌匾图center；按实际art rect的center共同安排mini与牌匾，较宽rect预留GM边界。只在world helper保存/恢复整个牌匾原位置，别把偏移残留到其它场景，resize按目标中心重新计算不累计delta。

SubViewport没有own_world_2d bool；本次原UI夹具实际L36拒SCRIPT，不因check-only通过授运行。独立2D隔离用viewport.world_2d=World2D.new()，NEW测试仅一处修并保原SOURCE/FAIL。小UI测试只说明布局，不冒正式Field/入口/帧性能；已知退出纹理七ERROR与30/0功能断言分别记录。

## 2026-10-14：组合预览不要混 JSON 数值域和正式布局

Godot JSON解码尺寸数值的float数组直接与int字面量数组比较，会让真实656×280资源在组合阶段被拒。B3 root06已自然OS1保原失败；完整source精确备份后仅expected改[656.0,280.0]，不int截断/epsilon或宽尺寸，root07才通过。影像capture成功和最终组装成功要分别记录，不因已有crop收据假称PNG已落盘。

纯展示统一scale.6/local asset1不等正式世界坐标；整组塔位100/2972为端部收束，runtime仍140/2932，后接不能照抄布局。B新crop333较旧332、foot+1px是实际透明轮廓变化，必须按新foot安放；支撑差一个Float32 ULP虽在原1e−6内，也不能说native-bit-exact。素材技审通过/旧七退出错误/最终艺术与部署是独立结论；完成成组资产后推进候选接线，别永远重复单墙材质小样。

## 2026-10-14：物件替换应绑定实际绘制与支撑，材质改动别重建 mesh

去瓦帽后使用的墙体draw bounds z±.36125与原全mesh含瓦帽±.391387不同，最低Y支撑又是x±2.46/z±.34375。新墙误取全bounds会把脚点推5px，不能松脚点标准或靠PNG底边补。应分别验证当前被替换物件真实draw bounds、minYsupport、相机/body-origin与实际capture；本次656×280/foot272.362/四支撑最终逐值复原。

材质-only替换不要把surface_get_arrays再次add_surface_from_arrays当作必然位元不变：本次全arrays SHA门禁真实拒绝，但未记录具体差异分量，不能猜唯一法线/切线原因。保全失败后改浅clone原ArrayMesh，只赋新material，原完整数组/保存reload严格证明实际才通过。不能删UV/normals/tangent/colors或放宽float比较迎合改法。逐源码SHA literal校验可在启动前捕到63位笔误；原失败或SOURCE拒应保留而非冒新版已运行。

微小luma噪声加纯灰base仍像水泥，实际albedo加入授权漫反射色度/明暗与原创石材裂纹能改善；但材质指标通过不能掩盖砖层/垛口比例太规则的积木感。只一段物件与已有门楼同尺度对照，明确离线拼组非Field实机；不得据自然OS0授正式美术或忽略旧七退出错误。达到本轮有限样件后停止自主shader循环，交用户真实图，不把source审计反复扩成全城测试。

## 2026-10-13：城门候选实测与艺术验收分开

测试站位白像素不等于可从当前出生到达：墙外1100/540处于墙/护城河/栏杆围成的窄条，测试应依据真实门内路线绕翼墙，而非改生产碰撞迎合站位。NEW墙内1100/420经1536/380与1100/380绕行后实际stop436通过；旧失败保留。30秒QA等待会在真实异步载入未完时启动清理，随后来源错误可能是取消链衍生，不应贸然松生产来源保护。独立入口诊断实际首府衙30.587秒、Space/Mouse正常往返通过，只证明90秒范围内可完成，不追认旧FAIL或授速度改善。

城墙截出RGBA/尺寸正确并不代表风格匹配。必须在真实Field镜头与原城楼同屏看：本轮两侧墙偏暗、平板、大方垛口，尽管碰撞/门户有限通过仍拒正式美术。原材质14正确、同profile其余表面无法补灰基色/缺石层；应先只一段墙独立浅灰材质、真实错缝与浅倒角/窄垛口，视觉匹配后再派生塔。不要反复全量实测已通过路线代替制作；三case入口专项不充当完整九case或全城发布证明。

## 2026-10-13：水面技术通过不等于视觉认可

v3空stderr与像素随时间变化仍被用户评价一般；别重复旧测试或只加wave数值。v4改变反射/微光/近水平中细纹的整体层次，透明独立建筑源SubViewport避免把HUD/地板映进水里；先真实GPU非空alpha采样后才截图。2D源足线投影/压缩只是美术近似，不称物理3D反射。canvas fragment不要二次TEXTURE*COLOR让岸材脏暗，vertex保tint后fragment采纹理乘一次。

自然动画证据要与固定t0/t2区分。PNG回读/保存使本轮3秒仅7自然采样、约440ms间隔，不是游戏FPS；GIF按原时间舍入10ms/末帧明确hold/只真实自然样本，循环播放不等于接缝无缝。静态图像素指标只证动态存在，最终水感仍交用户审。v4局部自然OS0/空stderr亦不冲销旧主游戏Loading退出纹理错误，不授formal碰撞/入口。

## 2026-10-13：护城河材质与动态预览分层

河面不要把一张非无缝亮蓝图拉成整条河。局部候选采用独立水Polygon、石岸压顶/湿立面/桥台，水波世界坐标随TIME而非屏幕坐标，石材按192世界px重复；水shader的光与影不能代替岸壁体积。新CC0许可只覆盖Poly Haven原字节资产，不扩到既有城门/桥/守卫；石材nor_gl不能冒充水法线。本轮只借鉴Waterways/MaterialMaker概念，无插件/源代码采用。

Texture2D.get_size返回Vector2，不能直接与Vector2i严格!=；Image.get_size则为Vector2i。独立首次实际root01在L68失败，无水绘制信用；保留完整原源后只修两Texture2D expected，root02才自然OS0/空stderr。固定shader t0/t2截图可以比较纹理时间响应，但关闭override后只有一个自然样本不等于连续自然录像；154自然process_frame与单样本另标。独立无autoload的小project适合快速调水岸，不能把它的GPU/空stderr通过当作正式Field碰撞/门户通过或主游戏加载错误已修。

## 2026-10-13：Loading必须覆盖真实重工作，不只线程读通用场景

Stage10把实际同帧mapping＋unaffected重段分开，mesh→metadata/PNG字节→第二次load→逐surface material共享给sync/live，原完整比较/第二次读取/失败序不删。私有子字典持Mesh，取消只能清其自身，不能clear主validation state导致后续objects/prototypes丢失；caller围住await的总时长不能再称单次CPU耗时，改同步子label。唯一95348实际101/0、70BASE帧/max616357us，只是本轮数值（source也比旧轮快），不能算固有百分比。冷校验23.095s仍含完整首末SHA，不是全Field入场；最大paving610.546ms尚未拆完，7纹理退出错误继续保留。

布局尺度必须实看，不靠“全屏有墙”称完成：本轮城防v1横墙虽贯穿视野，却只有约一人高，仍像院围墙；v2保持同角度等比2×，将其顶部与城楼翼墙衔接，只认可比例方向。明亮非无缝水候选不能充当正式护城河，已有石桥也不会自动补出真实岸壁；守卫静态首帧只作尺度证人，1920图只是离线crop非实机镜头。自产/已有ImageGen图与程序原生几何须标真实来源，不冒新CC0外部授权素材；旧v1文件不覆盖，正式Scene/portal/导航未改就不授实际入口或城防部署信用。

Stage9真实分帧把原连续BASE段拆到64自然观察帧，maxgap实测1.821106s（旧8.968841s），但BASE总9236ms及首末SHA仍约40s，不可把“能刷新”说成“载入已快/流畅”。scalar显示tree unaffected prototype1252.673ms与mapping560.209ms仍同帧；下次应先在两段间yield，再拆native mesh/material子检查，不能凭墙体240Boxes名义定位。原source、数学、比较及sync/Web均保留；local四缓存原子commit与await前后same owner是分帧的必要正确性条件。root/source review另纠正了capture MISS分支误绑error-if的else，使hit计数恢复原义；诊断计数也不能悄然漂移。

新的纯QA观测也必须实际校验：54100首parse因Variant表达式无法推断 `timing_valid := ...` 失败，NEW只显式bool；6256原首帧Engine counter0→0不能证明未经历process_frame，原断言77/1保留且未执行cold。NEW独立one-shot直接记录真实signal，88456 first callback order1→signal2→last callback3，raw三个Engine counter仍0，拒绝false/calls2/全局状态不变保持；只授共享checkpoint，不追认原Engine涨值断言或whole BASE取消。测试修正要使用NEW文件保留原源码/失败日志，不能改原判据后洗白。100/0仍伴37Image和7真实纹理退出ERROR，不是clean；源码/保存保护与性能/退出验收是不同结论。

阶段8两大目录收据复用后C同步878ms、BASE仍8847ms/max8.969s，91/0只能证明合同与来源保护，不代表冷加载顺畅或整体比旧7.386s更快；source首亦翻倍且隐藏窗口帧率改变，需记录实际而非百分比。下一应细分真实大函数再分帧；不要凭helper名推断性能成本：BASE._png_size实际只读PNG signature/IHDR24字节，不是完整decode，主控猜测已撤回且无代码据此变更。更不能把新增await塞进原同步API或让旧async取消调用全局_fail清掉新owner。

Agent阶段已completed后，send_message只排消息不会启动新turn；正式冻结后的QA写入/复审应使用followup_task推进下一阶段。等待无输出时先查agent状态，不忙等或反复发送未触发消息；单模块写权与根串行引擎仍保持。

同次已完成的来源收据可以消除主线程重复读取，但不能删除比较或跨转场永远信任：stage7六loop只SHA getter换为同token/id/path/script的joined收据，全部原type/path/expected/lowercase判据和最终完整复查保持；缺项返回空，不回落同步IO。显式mark_joined在wait及owner检查后才置位；工作空间release_pixels与release身份分开，大图用后即释放而token结束必清所有收据。此次实际84/0、最大gap7.386s，前轮29.803s仅对照，source首也改变所以不算固有性能百分比；剩deep V4/GROUND及GPU同步仍在。process.exe初记录null保留，不给已结束进程补before/path信用，已有literal启动和自然退出证据只限域使用。

纯CPU拆分成功也不等于总帧停顿改善：阶段6PNG/Lanczos/Float32透明重建在后台5220ms推进280帧，全部旧字节/裁剪/相机门禁仍通过，但BASEmain29.646s/Cmain9.239s/maxgap29.803s仍在；source首耗时也从6.672到12.505s，不能凭跨轮数字唯一归因复制/线程或计算提速百分比。应继续消除主线程重复catalog读取/哈希、分帧混合GPU工作，而不是重跑更多冷测试。既有完整token首SHA/强制出生前末SHA可用于设计有限来源收据，但不能用永久缓存或跳过原比较，实际尚未接该下一步。

线程输入必须按真实作者数据枚举，不假定每城都有两个墙prototype：Gate一类/Yamen两类/Docks与Market零类。后台图像必须从被同次hash的字节解码而非重新读路径，原RGBAF转换→Float32预乘→Lanczos→epsilon除alpha→RGBA8的顺序完整保留；worker仅自有Images/字节包，主线程join及身份复核后消费，缓存在剩余import/几何/玩法检查成功后提交。PNG native decode/resize不能即时取消，本轮只有源码边界信用，不授动态取消延时。退出7纹理ERROR继续保留，计数71/0不覆盖其失败。

后台拆分应依真实阶段计时排优先：本次C导航worker仅137ms，BASE同步18196ms、C导入/来源4774ms仍占主线程，虽61项合同断言通过，最大gap18.200976s明确不授流畅。process_frame观察的phase是恢复时状态，nav标签4.776714s包含上一段C-main，不能把标签当CPU任务本身耗时。GPU截屏读回232/234ms也必须计入观察；单次不同renderer/文件缓存测量不计算虚假的加速百分比。

纯CPU worker不得先写静态导航再做安全检查：独占RGBA字节、深拷贝原作者数据及polygons，在worker新建CPU Image，完整raster/875像素/全部4px路线校验；主线程join后再核同job/token/cancel及结果一次提交。GPU合同naturalOS0仍须审完整stderr，本次3纹理RID退出泄漏及CompressedTexture析构共7ERROR不受断言计数覆盖，保留原证据、不能猜归因或声称clean。

后台任务取消也必须实测：首次来源worker确实推进1402自然帧，但_cancel先token0后同步join仍卡11.735秒，安全清理通过不等于流畅。NEW仅任务独占Mutex旗标＋1MiB分块FileAccess/HashingContext，每块前后检查cancel，短读/长度变化/缺文件/取消拒整份hash结果；正常空文件和跨块SHA须与标准算法exact。实际取消调用低于1ms计时分辨率，恢复原Field约2ms，不将0ms写成绝对零延时或慢存储保证。

取消不能把验证变成可选：Field创建时捕获原live token，末尾必须finalize；若末尾仅询问当前has_live，取消清token会跳过检查而生成Player。Router两帧后及await后均核source/Loading准备和external代际/token，不能默认prepared=true使已取消链回落完整同步校验。被拒首revision保留，修后只实际授已测试的取消路径，不授完整城市成功末检链。

同次token免重复full校验不等于无需等待：真实Gate cold34.893s、两次源hash复用各约6s依然堵主线程；必须分别量测，不能仅fullattempt计数不增加就称提速完成。worker测试必须沿实际Field的参数来源：map_layout存在时visual_objects替代scene_objects；BASE旧scene_objects可为空，测试错用该数组只能证明正确拒绝，不能判生产worker失败或放宽guard。原63/1证据保留，只建正确域专项。

小地图生命周期43/0不等于大地图不卡。实际退出stderr必须另外审：本次verbose只证明village_zhuwei.wav AudioStreamWAV/Playback和RefCounted泄漏，不能根据测试名称归因Loading。保留原证据，仅NEW副本通过正常AudioManager停止与deferred quit隔离退出生命周期。ready协议在同Field二次重建起始也应清零，不能沿用上次complete=true直到重建结束。

新增ready握手不得包在“current_scene非null且has_method”可选分支里，否则缺协议会绕过验证并隐藏Loading。修后显式必需协议、typedcomplete/failed及exactscene_id。显示动画必须归代际所有：新show kill旧fade，旧hide不再收尾新屏；kill Tween可能不发finished，不能继续await killedTween.finished挂协程。第一拒版0DCB/7196保留，修后9007/60A8源码独核；四脚本编译自然OS0仅有限parse，不代表世界/洛阳真实加载提速。

SceneScript的地图/物件贴图是字符串路径，不会随Field PackedScene自动全量异步读完。Router若在show_screen前解析城市、反复做源SHA/PNG像素与导航/路线校验，即使LoadingManager用load_threaded_request仍会卡住。改造需要先让Loading绘制、后台读资源、主线程分帧实例化并等Field真实完成；Node/Physics/Rendering禁止直接后台创建。重复验证可按同次transition独立token传完整结果，不能永久跳验证当优化。

实际城门修复先查portal绑定：洛阳入口500对应院墙north_court_boundary，现役大灰砖south_gate1660未绑定入口。只放大后者不能修用户看到的错误。城防轴线、市场街坊、住宅/府衙与园林须连续空间组织，而非空地散物件。复用室内模板不复用门返回SceneID/足点身份。

动物sprite素材离线规范：所有20帧用同一global fit，底部12px、512×384RGBA；透明原生输出不可再按不透明洋红图处理。鹰v2边界只有alpha1黑噪点，NEW native-only处理保留色彩，先alpha>=24边界校验、既有component清理后再全部非零alpha检查，独立RGBA重建296/0；不以边界降阈值洗白真实裁切。犬v2技术规范通过但朝向仍错，视觉FAIL应保持，不因文件齐全接入。

gen_assets等额预算>=拒会在供应商返回后、素材写盘前抛异常丢失响应；本次最窄改>并离线case核验，旧丢响应失败保留。估计API成本不是实际账单。新头像生成/文件拷贝不等于Godot已import，45秒import无完成必须报告未验证，不绕ResourceLoader授runtime信用。

## 2026-10-12 ROOT549–550：世界入口关键验收通过

正式Field1041/Zone1966使用建筑实际门前通路，箭头可进入时高亮描边，发光/空格/点击共用同一安全谓词；远处、锁定或17足点不安全拒绝。C最终00652631保留city_v3_solid_polygons_px严格原生Float32同位比较及StringName精确键，仅未知键提前类型拒绝。549运行身份BC39001A，GPU自然OS0/129零失败/complete true，16源passage夹具+清河、洛阳各Space/Pointer四真实往返通过；resultD2A807CC6E4D765792A365AEB04EA3E81B0FBC0EA51ECDF84CA74A7ABDB23C13。663 Image提醒、其它WARNING/ERROR/SCRIPT0；worldapproach两Physics样本各clear，清河Space返23样本，另三返zero-motion据实，不授城内875或16实际转场。426首末源/15玩家/2exe精确保护保持。550最终C纯单位25/0、自然OS0、stderr空，427current/归档和15玩家/2exe精确ticks零差；合法原路径不变，不借550冒成549当前身份。有限独审通过，用户game31752/editor36036保留；重启游戏可测试本次正式脚本。旧536/547的113/2、538超时、548SCRIPT均保留。

地表544首次GPU只获parse FAIL（NEW undefined LOCAL_SHADOW_MAX_M），未执行材质或产图；645有限源/15玩家/2exe保持，修后需NEW授权/独立实际预览。10野外仍候选而非正式可玩场景，动物素材补齐与入口/敌人/等级牌待办。入口关键修复可交付，不能称本次三项全部完成。

### 本轮停止点：地表候选尚无实际画面通过

补充更正（已实看输出目录）：556虽未生成最终result，但已落盘grass/bridge各raw、repeat、logical共6PNG及两个reconstructed贴图；不能写成完全无图。root逐看两张logical：草地已有深浅和低花丛，但花丛规则重复；河岸仍太直且边缘锯齿，木桥外形/木纹仍粗糙，不符合用户重做要求，因此拒绝正式视觉采用。不是单纯等待更长超时即可上线。下一改河岸形态细节和桥视觉物件（保留通行面/碰撞），分区局部初始化；已有PNG仅partial候选，没有全三样本final/末内部2891保护信用。


552授权数组JSON Float/int域拒；554全部授权分量真后发现报告pin原字面65位笔误，报告实际64位CDD74B329CF84EB24CCD136A5F26AFD515795EA612508D197263DB31FDCFB851并未变化。root仅1行精确pin串联修，NEWbuilderDD4B6940CACD1F83BF8F85DF77A23760489BDA4D97925168F2AF89AF4F21A45C；556fresh GPU在240s上限精确停止own29376，actualOS−1/timed_out，无final result或PNG，不能授视觉/完整素材PASS。649外层（648seed+inventory）、15玩家与2exe首末changes全部空，用户game31752/editor36036保留；旧544/552/554/556拒例原记录不冲销。当前NEW builder继承整图初始化过重，下一应改真正局部初始化/复用当前派生输入，不延长为整夜重试，不先替换正式64块。最终入口脚本/550单位与549有限真实4trip已可交付；河桥/植被与10新野外场景尚未上线。动物资源策略问题已发用户，等待混合生成或仅授权资源选择，无新增生成/下载/付费/存档改动。



## 2026-10-12 ROOT535–549：世界入口短专项与地表/野外候选推进中

入口 Field1041/Zone1966 已对齐实际门前通路：去掉约246px横向箭头偏移，以原passage polygon和当前17足点安全判定统一发光、点击、空格；不改世界RF/nav/桥碰撞。536真实GPU113/2、16源夹具与清河Space/Pointer两次往返通过，但洛阳目标加载为空，原FAIL保留；538重复诊断60s超时OS−1保留。540单resolve28s定位visual_objects；542单物化实采六个city_v3_solid_polygons_px短小数，native32位相同。C新增仅此字段的严格原生polygon比较，无ε，不改坐标/形状/顺序。546纯单位20/0但547仍拒，实际StringName键未中String-only分派；新C BC39001ABB25E93C717472A7FDF40D8F54FE4B2C51C4968781902BD3149576E7明确兼容该精确键，548纯单位25/0。549原四次输入往返正在运行，尚未授完整入口修复；旧536/538/547证据不冲销。每轮有限源码、15玩家、两exe保护保持；用户game31752/editor36036保留。

地表新版仅NEW v10两源码/授权：深浅草地、湿岸/水纹、木桥材质和低矮CC0灌木/原生花草；543有限645叶约1.32GB，历史2891来源仅内部hash，不授wholeART。三局部GPU预览尚未执行，不改正式64块或桥几何。10野外区域仅待接入候选manifest（1–20级）与四狼EnemyDef；没有可玩10场景信用，野狗/虎/熊/鹰专属素材缺，已向用户询问混合生成或仅授权资源。待办：549实际结论、局部视觉审→正式素材替换、补动物与10独立场景/入口/等级牌及关键玩法验收；不重开完整六槽/旧档兼容。

548独审补记：stdout25/0与OS0不授单位PASS；完整stderr含SCRIPT ERROR（旧_native_authoring_scalar_path处理整数key时int!=String），须补路径类型前置，549冻结源运行中不可同时修改。427源/归档、15玩家、两exe首末/current精确保护零差，仅协议异常待修。


## 2026-10-12 ROOT533–534：世界右上缩略地图已正式接入

用户要求大世界行走时右上显示缩略地图。新增 `game/scripts/ui/world_travel_minimap.gd`（1D4EA7A1A1EBEA46C09F2A3E980C05C75E32C46621B5AA3DD43EC3E5E9F1621D），Field仅六处preload/变量/setup/release接线（5716BB1467E4811FC8932BE87D05AE815C69B14303C7AA3E42EC0ECF60613488）；E545原Field精确备份在 `game/build/world_minimap_field_before_20261012_ffc5df39968a4ca2866463b7d7e3e9fe/field_walkable_controller.gd.source`。复用已入库world15 overview与冷玄铁hud_quest_panel框纹理，没有新生图。仅world15显示，16入口点、实时玩家足点/朝向、视野框共用一个aspect-fit坐标域；无鼠标焦点/点击遮挡，右侧预留100px供GM。WeakRef、configure缓存及release避免每帧加载和跨场景残留；按现役HUD牌匾/右侧菜单可见性隐藏。世界canonical685876、洛阳四区/郊外、Player/nav/C/audio/save未改。

533有限UI源库存417（非完整world来源）；534 GPU RTX4080/WASAPI自然OS0、142/0、8记录完整、stderr空。正常向下80px原INPUT/Physics与角色marker跟随、16独立入口映射、1080/720及恢复1080布局、owned非world拒绝/重复configure/release通过。1080面板(1540,116)/280×210；720面板(978.4,110.2)/201.6×151.2；root实际查看两图，未越界/盖GM。result `game/build/joint_world_luoyang_20261003_qa/world_travel_minimap_100784_2630921/result.json` SHA FED7527A010AD969324DAB37E081F2147117B871617E0171C7C2C141DAD7A5CF；outer534 after F96228BC40A24BA93AA4C093226007DC9F79D2B42BBAE518F4B66B18C9700B38，418源首末、15玩家与2exe changes空；own100784自然退，editor36036和用户正式game31752保持。源码与实际限域独审通过；不借此重授全world几何/音频。

保护范围补记：26内层来源中23项已被418外层库存覆盖；现有hud_quest_panel框纹理、其import与ctex三叶仅内层首末和当前SHA/bytes一致，未获外层精确ticks/归档保护信用。原533库存与534证据保持，不补首guard，不称全部UI素材完整外层保护；不阻本次有限展示与用户试玩。

已完成：正式世界HUD小地图与短专项验收。用户待验：重启正在运行的游戏加载新脚本；长途观察方向、入口点和视野框。真实跨城市transition清理/系统弹窗显隐及相机框精确inverse独立数学未在本夹具直接运行，仅源码审与owned生命周期，不称全量回归。


## 2026-10-12 ROOT530–532：新版大地图正式接入，关键点通过交用户验收

按用户“大地图也继续加快验收就部署上线，我来验收”，本次上线仅指本地正式工程接入，不对外发布、不追加完整六槽/旧存档迁移。世界canonical由v14换成当前已发布v15/V9E地表：12288×8192、64地表块、16入口、27道路、2687独立物件；仅候选scene_id改canonical，其余bytes保持，正式SHA685876AC86CB3B739F9B51BE12DA60E4A125480C715DA2D08F9B486D76E5A046。四洛阳canonical与布局、郊外adoption保持。

WORLD ONLY切换54F346BA经独审，proofA9AB4437；旧838380FD完整备份，独占捕获/写入/字节读回通过。journal `game/build/world_key_acceptance_playtest_cutover_20261012/20261012T0225074173340Z_56b7774de32b42278e46e19ef1646251/journal.json` SHA BD49C89980D218D7AFA68030C85E007B9FBF41F22909F9EB72A843B00657CE99 保留原pending状态，后续532实际另存收据。C684C71CC仅新增exact world15 canonical+layout双SHA外源选择，原world14路径与portal/UV/到达脚/安全检查保持，CFE8原源独立备份。

530鲜路径库存16942，532 outer16943；2026-10-12T02:27:52.9938290Z实际RTX4080/WASAPI自然OS0，51/0、complete true、6rows。默认出生(2600,3991.099365)17足点+Physics clear；public setup后原bridge00约784px正常INPUT到达，98 Physics样本全clear；16入口仅目标配置核验，不授实际进入。3GPU图SHA完整实核，root逐看出生/桥实际Field与冻结ROOT250总览显示（非全部Field物件）。result D6B4E1152C4AD745382D7AEB568BF599E0F883A29D632DB8F4E33F1DA5C23796，after44774343F2129115F549F125C33871779C0310380E200B84C634489B41367E9B；16943源首末、15玩家与2exe精确ticks保持，完整有限独审PASS。stderr774A7146仅3RAW Image提醒、ERROR/SCRIPT/其它0，非无提醒clean；own94452自然退/editor36036保留。

闭包限域如实保留：6017 unique quoted叶中6013在首guard，另4制作注解原始gltf/mesh/obj仅被重复引用6432次，不是6432个漏文件；实际Field仅消费PNG/已序列化碰撞，不读取这4字段。不得授这4原始素材本轮首保护或完整原生几何来源重验。实际音乐WASAPI/playing、exploration_journey.wav仅状态记录，不授听感/连续性；不冲销529音频失败。

已完成：新版世界可恢复正式接入、出生/一座桥/入口配置与3图关键验收。用户待验：重启正式游戏避免资源缓存，经GM/F12选择江湖行旅图；全部入口实际进入（含洛阳）、长途行走/区域边界、画面细节、剧情战斗/存读档及音乐听感。重复草地、简木桥与雪地平台等美术局限保留。Source/M原visual_approved/production_approved=false不改，不冒充完整发布批准。


## 2026-10-12 ROOT526–529：洛阳四区已正式接入，余项交用户试玩

按用户“验收关键点就可以剩下我来验收”，正式接入不再等待完整候选/正式六槽，也不追加完整保存读档前置。520/521当前几何双端与实机视觉已独审通过，522仅复用28完成交互/11入口收据（parent OS−1，不授whole）；524编译失败、525超时、527/528正式加载拒例全部保留，不冲销。

526限域proof1EB87577与NEW切换037AC766独审后，2026-10-12T00:54:10Z完成四canonical精确备份及写入：城门872B4FF5、府衙5A0C1124、码头51527C47、南市3D4D7FB9。四current均等已验candidate，四backup均等原文件；journal在 `game/build/luoyang_key_acceptance_playtest_cutover_20261012/20261012T0054109115555Z_f124c525ea4848b9ac450aac72eedb53/journal.json`，保留STATE=ACTIVATED_USER_PLAYTEST_FORMAL_SMOKE_PENDING，原六未满足/完整发布false。世界与郊外配置、旧布局、15玩家存档不改。

527/528无candidate flags四资源身份通过，但实际public Gate拒绝；528真实C.errors为Serialized V11 native layout differs: visual_objects。四区58原生Vector/Transform派生authoring注解TRES短小数读回，Float32位完全一致，旧视觉比较遗漏明确路径。NEW CFE8A054窄adapter仅这些字段TYPE_FLOAT/finite/native位exact；BASE、物理顶层、其它double、键/类型/结构/素材哈希保持严格。改前558A完整备份且逆换逐字节exact，58差项/28组去重数值及生成源码已独审SOURCE_READY；不授修后实际Field通过。

529 NEW65508B63仅正式Gate启动复验，无candidate flags，actualOS1@2026-10-12T01:10:56.8548196Z，无超时/源玩家exe changes。开头WASAPI ERR_CANT_OPEN/init_output_device error，退Dummy触原音频断言，未执行Gate/无出生截图，因此不能宣称正式启动或音乐复验PASS；未绕过音频门禁/未改系统输出。after C1A0817D、stderr27F83B75保全；own68504自然退，仅editor36036保持。停止自动循环，保留新版供用户手试玩。

已完成：四正式地图接入、回滚备份、关键几何/遮挡验证、序列化源码窄修。用户待验：重启正式游戏（避免旧资源缓存），GM/F12选择洛阳；修后实际进入城门、各区切换及加载耗时、完整剧情/战斗/榜单/当前保存读档、音乐。当前地面重复与简墙/码头材质局限仍在，非完整发布验收，不再自主重启六槽。

## 2026-10-12 用户缩减验收范围：关键点通过后交正式试玩

用户明确“验收关键点就可以剩下我来验收”。本决定替代此前剩余完整候选六槽/正式六槽计划，不再将全玩法、全赏金和全部负例回归作为本次试玩接入前置。复用ROOT520/521已独审通过的四区行走、阻挡、前后遮挡及实机视觉结果；仅补关键入口/出生点和隔离当前格式保存读档，备份四canonical后接入，余项由用户试玩验收。旧完整门禁脚本/失败证据保留，不制造六槽签批或完整发布PASS。

ROOT522长玩法按新范围主动中止：精确核own24608的PID/startUTC/path后仅停该进程，after UTC2026-10-12T00:12:11.1999153Z实际OS−1，source/player/executable changes均空，editor36036与15玩家路径保持。已完成的独立交互收据保留；未完成整轮不能算通过。正式四此刻尚未切换，下一为最小关键点收尾及可恢复接入。

## 2026-10-12 ROOT520/521完整候选几何双端通过；玩法/保存及正式接入仍待

同冻结0E2D0BC6/475AAFCF与NEW消费者83231028/B399AD92，519鲜路径库存4767、两轮outer4768。520 headless/WASAPI自然OS0@2026-10-11T21:28:25Z/top2384/0/stage2874/0，完整独审有限PASS；521 RTX4080 GPU/WASAPI自然OS0@2026-10-11T22:04:12.9791823Z/top2384/0/stage3627/0，result88956509641293499AB5F8B9C73B9308D4EF0A30C5408CCC07E5507AA3735CD6，251PNG完整。原4区20路79物件/75stop/80NPC native/六roof ALL240支持域与前后正常输入，root复用冻结严格函数实核通过；521完整actual独审进行中。

两轮source/player/executable changes均空，15玩家与editor36036保留，own69920/95416自然退出。521完整stderr1588Image/12750具体源栈/ERROR/SCRIPT/未知0；两轮stdout退出均有Orphan StringName process_frame及1 unclaimed，保留非clean、原因未归属，不称旧known。root已实看本轮全部20路线与重点门洞、墙角、灯柱、仓房、客栈商铺前后图：未见新增阻断性层级问题；重复灰地表/简墙与码头材质局限保留，不授完整美术成熟。

目前只完成新候选六槽中geometry两槽，不借515有限赏金或517SOURCE填六。下一同冻结来源fresh gameplay双端、save双端，真实六与视觉签批后备份切换四canonical，再无candidate flags正式六回归；四正式仍旧，旧FAIL不冲销。

## 2026-10-12 ROOT517完整桥接编译/加载通过；整城六阶段待，正式四未切

NEW完整phase475AAFCF/3336B仅包装赏金driver安装/释放/恢复与BOUNTY_SEGMENT_ONLY附录；完整entry0E2D0BC6/35933B逆撤销逐字节还原BC066，165pins/264GD完整SOURCE独审。516鲜库存4764；517 actual headless/WASAPI自然OS0@2026-10-11T20:36:30.3140847Z、resultA5EBF439AAF0482511E2FCFA5407D68E14DB2BEE330C5413A46700C4F120CB94/1089/0、stderr空，仅SOURCE compile/load/mode合同，Field未执行。4765规范唯一源/5,855,791,883B首末/current/归档SHAbytes精确UTCticks、608内部映射、15玩家与2exe完整独审零差；165pins/264GD/111Shop/23raw+23import+23compiled首次保护齐全，own84844自然退/editor36036保持，checkpoint首await前暂停持至quit/slot0→0。四canonical仍旧。

下一只窄NEW候选/正式消费者接线至新whole entry/output、当前Field/toast与实际warning源栈，追加本轮赏金段核验；原6槽、20路79物件/52动作24门户2赏金55负例/当前保存、所有源与15玩家严格门禁不变，不造新框架。随后fresh完整候选六、备份切换四formal及无flags正式六；515不填SIX，旧FAIL保持。

## 2026-10-12 ROOT515正常两批补给与两赏金有限实际通过；正式四未切

514鲜库存4761路径；515外层4762规范唯一源/5,853,403,377B，WASAPI/headless自然OS0@2026-10-11T20:19:16.2943125Z。result353DDBFB1A45C26CE1201CB11CC544FF3213AB934F0535B31E3AD6579E4AB116/top2382/0、返回stage328/0，保存stage1732B8A2自身325/0；complete true。50即时native全解9,780,640B、794健康rows/6started6ended，保护与实际独审有限PASS。

两批真实采购46累计命令/160058ms，原96/180000ms共享域保持；22药/扣1172/gold18828、同脚2480/950且未自动装备。四普通战真实win/nonfled/returned，奖励与Bounty状态分开核；两赏金redscar38命令/9药、seal28命令/6药均胜利返脚/captured一次/escape0，金币119=59+60、196=91+105，训练129=101+28、210=166+44及声望14/22严格绑定，不借普通战奖励。24真实库存动作=2装备+22药，同owner/event/commit与每药HP+80/stock−1完整native实核；末HP57/754、alive，不授跨随机轮次必胜。556同live ROOT17+实际Physics采样全clear，两次单go/共享30s travel保持。

4762源首末/current/归档SHAbytes精确UTCticks、1316内部首末映射、15玩家与两exe均零差；own17788自然退/editor36036保持，checkpoint首await前公开暂停至退出、slot0→0。完整stderr858E6DF607AD1140DF9A460C474B17BF0430E097713DB87D15803A4B55C57EA9/18468行：1625已知Image、13593源绑定栈行，ERROR/SCRIPT/未知/其它WARNING及ObjectDB/RID/Timer退出异常0；非无提醒clean。原513/511等FAIL冻结，不冲销。

只认可本轮有限NOT_SIX；下一仅两份NEW正常补给完整桥接源码，保留原4区20路79物件/52动作24门户2赏金55负例及当前保存流程。独审后fresh完整候选六，再备份四canonical切换及无flags正式六；正式四仍旧，未授接入完成。

## 2026-10-12 ROOT513正常四批采购共享时间超限；原FAIL保持、正式四未切

512鲜库存4756路径；513外层4757源/5,850,943,587B、1312内部首末来源均完整有限独核。WASAPI/headless自然OS1@2026-10-11T19:42:16.1073846Z，resultAC2101EE81234D414651A6701D731438F5D0732B889FE2054FEC614F71BDAAB8/top2374/1、返回stage101/2，保存stageAB0672C8自身98/2，completefalse。10即时native完整，健康44755FA8/95rows无Battle；两赏金未执行。

前两真实交易完整原脚返回2480/950、875+17/Physics重新绑定，累计32/46命令、药12/22、金币19128/18828；第二批返回相对共同start213529ms耗160.662s。第三批真实Accept成功，药22→32、金币18828→18528，累计59命令未达96；同步pointer前374689289us、后429517835us跨共同deadline393529ms，实际await跨度54.828546s，B7D6 _click返回pressed且时间域第二项false，shop提前return，command_end/after未执行，954CB拒绝。没有函数级计时，不能把耗时唯一归某Field/contract/loader，不放宽原180秒、不冲销513。

独审4757首末/current/归档SHAbytes精确UTCticks、15玩家和2exe零差；own91448自然退/editor36036保持。完整stderrD906EB9431D70B6F195E34ADCCCA9155AE94425BCE688BFC51665098D957D470/15438行，11427具体GD栈帧首源及行号全绑定：1334原Image/3原及衍生ERROR/0SCRIPT/未知及其它WARNING0，本轮无出口资源异常，不洗505。outer after24A3F0CB…0B2FB三个changes空，checkpoint在首await前公开暂停、slot0→0。有限FAIL/保护PASS，不授SIX。

下一仅NEW正常两批采购20药候选：总stock22/cost1172/gold18828，完整原输入/统一96commands和首180000ms deadline保持，quarter战斗/Victory/reward/Stats/敌/RNG不改。按511同前缀末余10药只是有限预计，不保证胜利；不复用本次32库存。原stock40四源及513FAIL冻结，有限通过后才桥接完整候选六、备份四canonical切换与无flags正式六，正式四仍旧。

## 2026-10-12 ROOT511四分之一血策略真实战败；正常补给有限通过，正式四未切

510鲜库存4751叶，511外层4752源/5,848,487,177B。WASAPI/headless自然OS1@2026-10-11T19:06:47.0575896Z，resultD2DD56309236683C7AFF722BE613F95AEF690E7F431A3E9F9F0ECC5C9D3ACDC6/top2367/1、stage287/3、completefalse。46即时native与627健康rows：首赤疤真实获胜/captured一次，四普通战真实nonfledwon/原脚返回；14即时库存动作=2装备+12药，首案6颗、末普通双敌6颗，逐event/同owner/HP+80/stock−1/commit绑定。第二印贼入场HP117/754且药0，4Attack+4Target后HP0/deadtrue、wonfalse/fledfalse，无Victory/返回/奖励，是真败而非无药策略提前拒绝。原511及509/505失败保持，NOT_SIX。

完整有限末独审闭合：4752源首末/current/归档SHAbytes精确UTCticks、15玩家和2exe均零差，1309内部源与外层映射零差，own102760自然退/editor36036保持。stderrCEB1A39A0C8068F9D045C2D35E2D873A5FAAEFC8A0B3ED31E05719FE8DB821E7共15502行/11404具体GD帧绑定：1362原Image/4原及衍生ERROR/0SCRIPT/未知及其它WARNING0，本轮stdout无退出资源异常，不冲销505。返回stage287/3，保存stageAD9452A6自身284/3，healthE46A0EC3/627；46native完整解码，JSON数值展示不冒原生bits。六follow共554同live ROOT17+Physics采样全clear，遇敌失效不冒到达；有限FAIL/保护PASS，不授全玩法或正式。

下一仅NEW正常Shop补给：商店单次MAX_TRADE_QUANTITY10且Accept立即返Field，40药须4次真实入店交易，首批剑甲+10药、后三批各10药，总cost1772/stock42/gold18228。全部共享原96命令/180秒，不逐批刷新；战斗四分之一血策略、原96/180/30与实际Victory/返程/奖励判据保持，不改Stats/敌/RNG/物品价或库存注入。有限通过后才桥接完整候选六、可恢复正式四切换及无flags正式六。

## 2026-10-12 ROOT509来源绑定和正常补给通过；治疗策略耗药拒绝，正式四未切

508鲜库存4746叶，509外层4747源。自然WASAPI/HEADLESS OS1@2026-10-11T18:36:02.9315362Z，resultB74C8573BE11C8C18AC3B72883013841FFEAF06A7D363F27D3F58D3DD5634292/top2361/1，返回stage232/5；38即时收据、459健康rows。商店五收据独审有限通过：来源固定scene/layout、整组NPC/native储存绑定；复制resource_path实际为空，原L30错域分量仅本轮确证，不补507信用。真实10药/1甲/1剑、扣872、未自动装备，返脚2480/950精确。

首red_scar真实获胜/原脚返程/captured一次、奖励严格；第二案途中普通战因半血且药0策略主动拒绝，末HP363/max754、dead=false，不能写成死亡。原509失败保留，不改生产数值；下一NEW仅将治疗触发降低至四分之一血，活玩家无药继续正常攻击，保持真实UI、原96/180预算、实际Victory/返程/奖励严格判据。完整有限独审已闭：4747源/5,846,046,247B首末/current/归档SHAbytes精确ticks、15玩家和2exe零差；1306内部源、38native与459健康rows完整。首案+前两普通战获胜返场，14即时inventory actions（2装备+12药）逐event/owner/HP+80/药−1/commit核实。stderr96825817…7B2A3/15518行，1362Image+6原/衍生ERROR，其它primary0；本轮自然遇敌退出无leak，不冲销505。own104620自然退/editor36036保持，第二赏金未完成、NOT_SIX、四canonical仍旧。

## 2026-10-12 ROOT507正常补给首来源校验拒绝；正式四未切

506鲜库存4743叶，507外层4744源/5,843,665,482B，DISPLAY headless/WASAPI verbose自然OS1@2026-10-11T18:03:04.5744403Z。result2CC2107044B63F9E82FA514E77484776889ED36E1777FDED40D80DFEFEFCA173/top2355/1，返回stage48/2、保存45/2。首Market复制资源来源合取拒绝，采购/战斗/两案均未执行；6健康rows无Battle，连接释放。静态发现legacy_scene返回独立duplicate而新测试要求其resource_path等于源文件名，尚未采集该合取各实际分量，不宣布唯一实际因果。下一NEW仅校正复制身份与明确冻结scene/layout来源绑定，原507源/FAIL保留。

完整独审4744首末/current/归档SHAbytes精确UTCticks、15玩家及2exe零差，own102172退出/editor36036保持。stderrDD456A442317FB47EEAE7CD09672199E6DA5DC08A18838CC010CD95D3FC35786/6892行：588原Image、3原/衍生ERROR，SCRIPT/ObjectDB/Loading/未知0；stdout无leak/orphan，仅本轮无Battle退出信用，不能冲销505五timer。Field E5458347…EE1ED已将2.5秒toast跨场景timer改为所属toast Tween（暂停语义保持），源码逆换精确8C7D4CAD；实际遇敌释放修复仍待。NOT_SIX，完整候选六/可恢复四canonical切换/无候选flags正式六未完，正式四仍旧。

## 2026-10-12 ROOT505健康与共享转场采集闭轮；真实战败保留、正式四未切

NEW三文件经全文独审，504鲜库存4736叶、505外层4737源/5,841,202,716B。DISPLAY headless/WASAPI verbose实际自然OS1@2026-10-11T17:10:31Z，result0FB9D561B20A6C9E18C2121FF0439510D48F7BD52A13343BC9F8FEF56596AF16/top1757/1，保存stage227/4。43即时JSON/native与363健康rows完整；6started/6ended、45真实pointer前后对，观察不改Stats/策略，释放后连接清空。两次travel均在同一原30秒deadline内单次正常go并到达，Loading重复请求warning0；不授Battle返回完整Loading生命周期修复。

本轮首red_scar真实captured/count1；连续真实Battle血754→723→700→429，首赏金胜后99，下一普通战胜后43，末双敌43→0/deadtrue/victoryfalse/fledfalse，level31/exp558保持。只授本轮健康及实际战败，不给501补HP信用或唯一策略因果。下一NEW仅正常商店购买、真实战斗背包装备/用药，敌/RNG/奖励/原输入时间预算不改，不注入血量或金币、不私开隐藏背包。

独审首末/current/.source SHAbytes精确UTCticks、15玩家和2exe均零差；own105088退/editor36036保持。完整stderr2575519D7A0AD05496F67E8775B8652BCA7E01EFBC60020AAC2B4B06AE871B04共9379行，836原Image、5原/衍生ERROR、1ObjectDB warning、SCRIPT0；verbose明确5 SceneTreeTimer leaked与orphan timeout，owner原因另查，不授clean。原505FAIL冻结、不冲销旧失败，NOT_SIX；待正常补给/退出问题与当前完整候选六、可恢复四正式切换及无flags正式六，生产/素材/玩家及四canonical仍未改。

## 2026-10-12 ROOT503五入口与府衙切磋完整有限通过；正式四仍未切

502鲜路径库存4731叶，503外层4732源/5,838,820,069B。五个原Space/mouse入口及原府衙巡捕切磋实际WASAPI自然OS0@2026-10-11T16:36:15.221005Z，result23E2081AB0293FE45E54B735DF6ADFC38C56B4DE7C57C782D244734888BF8D56/top1576/0/stage287/0。独审group03=233/0、group04=280/0，市场返城门沿原Gate→Yamen→Market正常两步；古寺/world正常返回保持。进入转场同曲原连续性及异曲一次正确换曲分别通过，不授返程音乐或DAC。

巡捕129接近采样均原clear真，三个正常Attack实际nonfledwon，返回精确原脚1210/1000；training0→30，未额外改变金币、旗标、任务、赏金或调查。Confirm/Continue以源码及实际result链绑定，不冒独立持久化pointer/focus信用。原释放、弱引用清理和导航恢复闭轮通过，own103204自然退/editor36036保持。

完整stderr29AB70F7B7031432A7127F132CB7E082E7370757F920FF9280C60B0EAC757841共87653行：5541原Image提醒、镜像/focus各1，ERROR/SCRIPT/Loading/ObjectDB/未知0。独审4732首末/current/副本SHAbytes精确UTCticks、949内部源、15玩家及2exe全零差。此轮NOT_SIX，55负例与赏金未执行，491/501原FAIL不冲销；已完成五入口和切磋定向组，待办NEW真实健康观察及共享原30秒转场就绪守卫，再当前完整候选六、可恢复正式四切换、无候选flags正式六。生产/素材/玩家及四canonical未改。

## 2026-10-11 ROOT501首案完整结算与真实切场保护通过；第二普通战败保留

500鲜路径库存4728叶，501外层保护4729源；NEW driver905A/phase9E59/entry307F经全文独审后实际WASAPI自然OS1@15:46:12.7417101Z，resultC36BADB425B0FE02E078CE777C76AD26D02DD28EB5FD6E87D867C1DBD4D90855/top1744/1/stage135/4，21JSON/native完整。首red_scar真实胜利返原脚、captured/count1，实际战斗gold49/exp101加原赏金gold60/training28/rep14严格到账；普通奖励不借作赏金。

第二案118次有效同帧RAW root+17与Physics全部真，5749 after_physics_await current0/Field离树显式identity_loss，lastlive1408/1024与原7key普通payload归一化逐组件native字节相同，5757真正Battle身份绑定。随后实际普通战6attack/4target却won=false/fled=false，无Victory/返场，第二案未完成；没有HP现场分量，不唯一归因低血量或碰撞，不冲销499旧false。

完整stderrD42ED06DBFFB8C73FCC80DB0CEA8EB346446EAA5C20641E53F49331CEDB0445B：9386行/836Image/Loading重复field转场及ObjectDB各1warning/5ERROR/0SCRIPT未知。独审4729首末/current/副本SHAbytes精确UTCticks、15玩家与2exe零差，own30920退/editor36036保持。下一先只读连续战斗HP/真实UI及转场时序方案，不注入HP或改敌人/遇敌/RNG；所有原源与失败冻结，55不重跑，正式四仍未切，SIX无批准。

## 2026-10-11 ROOT499两次揭榜与一次普通战通过；完整赏金仍失败

499自然OS1@15:08:28.465583Z，result9A63DFEA748EEFA266610737B68929D2CE06D073DD52F806E59F18DB4BAC48EC，top1735/1、stage104/3，17即时JSON/native完整。Board C664脱树后延迟删除的一行修复使两原实名按钮正常接受，两案均active/location1；一次普通战真实UI7attack/4target胜利，gold44/training71、赏金状态不变，正常返原脚并续原waypoint。仅有限信用，赏金完成0，不授SIX或正式。

第二次原follow有92样本（91clear真/1假），最后4357未采同帧RAW/Physics及live身份分量，不能断言唯一原因生命周期或洗掉false；4366确已Battle。完整stderr76795AF3DAD71CF1860C79C7358DE19FCAE2B293C40AB20F4B4865F933B5256A：9384行、836Image/1LoadingManager重复transition/1ObjectDB退出warning、4ERROR/0SCRIPT/未知0。独审4725首末/current/副本SHAbytes精确UTCticks、15玩家与2exe零差，own94712退/editor36036保持。

下一仅三NEW QA sibling：同帧Field/player身份守卫，离开有效地图显式scene_changed，不改任何live clearfalse；复用原BATTLE30/180/30预算、严格普通payload/奖励与剩余waypoint。旧499/496失败及原源冻结，55已过不重跑；生产、素材和正式四未切，完整当前候选及正式验收仍待。

## 2026-10-11 同名UI延迟删除与自然遭遇不能被误诊为地图阻挡

496实际首案pointer后旧两卡queue_free仍占名、立即add同名新卡自动变@PanelContainer@317/@318；第二实名lookup=nil，但新可用按钮真实存在。最窄修为remove_child再queue_free，保延迟释放/信号栈及原布局，不换测试lookup来掩盖生产命名。实际跟随失败也要保存完整原返回和即时current_scene/public payload：本轮121合法采样却进入普通raider Battle，无赏金键；不能放宽follow、关随机遭遇或挪目标。应正常UI胜利返程后重新绑定原source/raw，续原未完成waypoints，普通奖励与赏金结算分开。旧FAIL保持，12完整观测不等于两案奖励通过。

## 2026-10-11 集中回归的已封组通过不能遮盖后组失败

494原55负例完整通过，实际15项状态（不是旧口述14项）首后相等、events空，有限证明Field8C拒交互不再写导航缓存；但随后榜单4拒使整轮自然OS1，专项不可填SIX。先保存各组即时结果和闭日志，再只观察失败组件，避免重复55或改掉原失败。UI按钮null/disabled、刷新后真实节点路径及planner空路径/原输入失败必须实际采集；源码怀疑queue_free同名重建不等于实际原因，不能先改生产或放宽奖励/规划判据。玩家存档保持不动。

## 2026-10-11 拒交互不应写返程缓存，独立规划需同时覆盖旧root与可见脚域

491原负例10次仅navigation.current_field_spawn改变，剧情/物品/奖励/其它状态及事件未变；Field在Space和pointer实际匹配前先写缓存，不能通过删除导航比较把它洗为PASS。最窄新enclosure修为接受后捕获，同时核所有接受链：world_map action由exit_action_triggered直Router，不能只补target_scene世界分支；spar前言/缺NPC确认fallback也须保精确脚点。旧场景行为保持。

古寺legacy碰撞形状在root下42px，可见鞋也有offset；17鞋与Physics全clear不等于原root点经过grown blocker合法。保留原17/Physics，独立再AND同一源root regions/grown blockers重新规划，勿挪石桌或放宽阈值。榜单奖励fixture必须读原entry.require_flag；错误旗标会点到另一对白并遗留hide_flag副作用，后续身份失败不能先怪polygon。分组因果后短测，再完整回归，可避免每个假设都重跑数小时。

## 2026-10-11 QA成功状态合并与实际有效选曲必须单独绑定

Dictionary.merge默认overwrite=false，初始拒绝结果含complete=false时，后续成功字段合并不能自动更新该标志。482实际六initial因此早拒、12FAIL保留；NEW retry2仅成功merge显式true，单位193/0与485六roof实际351/0分别给有限信用。独立素材RGBA/240几何与当前显示状态必须分开证明；当前.55并非任意alpha范围放行，同帧Field/runtime/prop弱引用/baseColor/nativeColor严格绑定保持。

MusicCatalog采用新曲后，SceneScript旧bgm_path相等不再代表同曲：四洛阳区旧字段不同却实际同city_luoyang，码头→world旧journey相同却实际换曲。测试应绑定固定resolver源及独立effective预期，exact PCM path/SHA/rate/frames；同曲维持原身份/零事件/连续性判据，异曲验证正常目标换曲而不冒同曲信用。动态目录WAV及import/compiled必须进入future首保护，源码闭包不自动等于素材闭包；不得补历史before或借其它专项填全城槽。

## 2026-10-11 音乐接入须核实际导入格式与项目扫描边界

新WAV的Godot默认导入可能采用QOA；本批已处理循环WAV保持PCM16，只改新23份导入配置的compress/mode=0，再核运行时格式、采样率与完整帧数。新曲从曲首播放，同曲切室内继续，异曲交叉淡入。对话音乐恢复须检查当前路径/上下文的所有权，并处理同ID重入、战斗、胜利短曲、显式stop和解锁前待播队列，不能在旧对话结束时抢回音乐。

历史QA目录中的class_name脚本副本会污染Godot全局类注册；只对档案/导出父目录设置.gdignore并保护原副本，不能屏蔽整个game/build（当前郊外生产素材仍从中读取）。保留引擎元数据备份和失败日志，由Godot生成真实类注册表，核52个当前路径均来自生产scripts。Windows GUI引擎用隐藏Start-Process、Handle、WaitForExit及完整stdout/stderr取得真实退出码，不能把立即返回的空LASTEXITCODE当OS0。

独立SceneTree测试通过root节点取得autoload；文本检查TRES属性须允许等号两侧无空格，并与实际首保护的99场景路径逐项核对，不能只检查“解析后路径存在”。详 [本次接入记录](wuxia-music-integration-20261011.md)，原失败日志保留。

## 2026-10-10 实际逐gate诊断区分素材证明与显示状态

479六屋顶实际behind唯一旧selfalpha1 gate拒55%淡化；18同帧原返回前后收据证明因果，仅限本轮六次，不把早拒后另算core冒原proof通过。下一适配保留完整源RGBA/240几何，另精确绑定当前runtime同prop弱引用、原色、frame与native显示Color，不能按透明度范围或epsilon放行。八NPC旧Double重建脚点999.999996185303与native Float32足点1000跨8px边界，复用独立native观察而非放大容差；原失败保留。

观察Dictionary中Image/Texture仍是共享引用，晚序列化不能证明当次像素状态；在每个同步观察点立即冻结尺寸/格式/数据SHA/实例身份，保留native收据用于Float32/Color逐位判断。JSON有限十进制展示不冒原浮点逐位相等。自然退出与来源保持仅各自有限信用；诊断complete不等于原整轮complete或正式接入。

## 2026-10-10 当前显示淡化不能直接借旧不透明证明；收集实际合取分量

476六屋顶旧proof在Sprite门禁要求self_modulate.a==1，新获准建筑behind显示会变.55。静态冲突不能替代每次实际早退gate，L106还合取当前人物身份；原失败未采分量不能补唯一因果。最窄新诊断应保持原INPUT/位置/完整240drawrect/RGBA/Physics/875+17/alpha及原返回，只同步采身份、Color原字节、runtime base/display/factor与每个早退条件，副求子谓词明确不是旧执行路径/不是替代PASS。强停后的source/player保持不等于自然资源释放验收。

当前依赖保护必须区分GD来源祖先和实际执行data：注释中的res路径需保持引号/转义后词法过滤；历史祖先world-review常量不能当city实际asset图。保护全部真实GD来源，同时固定当前catalog与startup/import真实data，未执行literal标excluded不授asset保护信用；真实必备missing仍拒绝。PowerShell exact-stack须先验每项真正String，bool或单元素Array不得以truthiness/强转混入。469/470/472单位通过不能代替实际Field；474/475真实WASAPI启动也不等于音乐连续性或曲风批准。

## 2026-10-10 同一素材路径别名不等于身份放宽；合取失败须采每个真实分量

465实际首纹理保护用res键查first却只有该PNG精确absolute鲜记录，合取首失败后只1图/2释放；不能反推其它texture/strip/frame/flags均正确，原失败冻结。NEW466只接受expected res://与其精确globalize同leaf，所有出现alias必须类型/存在/bytes/SHA一致并匹配当前实际文件，拒basename/兄弟路径/旧digest/冲突；26直接谓词正反例通过后另实际采六身份全分量，OS0才授有限Field信用。真实前方虽有原像素重叠仍须排序拒淡化；release收据保存值可验证原色，但不持Node/Texture以制造退出泄漏。源码接线、有限真实移动与正式资源切换是三种不同信用，Dummy亦不能补WASAPI。

## 2026-10-10 首库存须包含生成器自身；历史路径只能作种子

452/454规范4623首记录全部runtime闭包齐，但漏固定424库存明确要求的collector脚本自身；不能把它未运行或当前SHA正确当成过去受保护。保留452几何技术通过与454局部证据，严格六均重收fresh4624，不改历史before或消费者规则。给只接受project-relative的wrapper传absolute会在首保护/engine前路径拼接拒绝（453）；调用前先规范Resolve-Path、去重并转相对路径。串行完整运行每轮重新hash/copy路径种子，不复用旧digest，不将队列基本检查冒完整独立审核。

## 2026-10-10 JSON展示深度不是字段类型证据；PowerShell反例要隔离表达式

码头警告消费者的两次纯PS单位失败保留：`@($replace,$line+' extra',$replace)` 实际展开四项，包含原合法header；各表达式独立括号后才是三个真实反例，另断言count与每项非原值。`ConvertTo-Json -Depth 5` 深层展示把真实指针数组格式化为字符串，导致SOURCE审与实现误认协议；必须读原JSON或`ConvertFrom-Json -AsHashtable -Depth 100`直接检查类型。原两输入的pointer真实为2/2/6数值Array，NEW retry9严格限定Array/Long或Double/有限数值，不接受误认的String协议。修正测试消费者不改生产输入；NEW单位actual361／0只授六旧实际私有case和反例，不能代替wholeKnownCase或正式六验收。

## 2026-10-10 生命周期诊断文件名不能代替实际战斗/奖励证据

ROOT446城门六case增量实审核实，四份`battle_entry_*`虽名称含battle，实际`requiresBattle=false/on_end=end/actualBattleUI=false`，只是正常对话生命周期旁证。撤回先前“实战返回”推断；必须读取真实case分支、Battle UI/loading、正常结算返回与状态奖励，才能授战斗信用。悬赏榜开关界面也不能代替接榜、抓捕和奖励。SOURCE-bound断言+实际case完成的推论应显式区别raw pointer/modal收据，不虚构未采集的字段；完整候选52动作/24入口/2奖励和源/玩家末保护仍各自必要，局部通过不等于整轮批准。

## 2026-10-10 音乐对照不自动改善；最大弱段与低窗比例分别判断

本地Stable地域/剧情/战斗20主题续作，依据真实试听PCM固定40ms窗/10ms步长/−45dBFS、3s..预定analysis_end，追加各一次汴州/夜村/密林/紧张对照。汴州两指标变差；夜村最长略短而整体弱窗明显增加，均保原版。密林最长6.69→2.10s但低窗只13.87→13.57%，只能声称最长空档缩短；紧张5.20→.73s/47.98→1.64%才双明显改善。不能把新增生成默认选入，也不能改检测区间隐藏原弱段或把数字当乐句/曲风耳审。原20及对照各自封存，选听manifest显式记录18原＋两ALT与真实sourceSHA。串听直接拼原audition PCM前缀＋1秒零分隔，不重复gain/量化；分曲停顿须向用户说明。合报931F466F与1786旧＋266sealed保护PASS只授音频技术和来源关系，所有新音乐/循环听审及实际游戏接入另待。

## 2026-10-09 SOURCE_READY不是实际编译；复制主体先核混合缩进

ROOT439的NEW NPC probe前部空格、机械复制run_objects为tab，静态主体与pins一致仍会拒编译。439只得到parent preload/resolve错误，ROOT440直接installed --check-only才定位child L72混合缩进。保全两原失败、先备份551386，NEW5C913只统一前71行缩进前缀；441实际parse OS0/空stderr且鲜源与15玩家ticks保持。仅parse不执行脚本或Field，不能借其授几何/音频/存档通过；完整旧阈值与真实输入仍须fresh运行。静态审应同时核全文缩进、子脚本实际compiler、原方法机械diff和literal pins，不能以SOURCE_READY冒compilerPASS。

## 2026-10-09 脚线double/nativefloat域差不能当真正behind；哈希pin需逐字首核

ROOT432沿原正常INPUT到客栈(735,830)，原completed_actor_stage、下一自然stage和postdraw全记录 Player depth829.999999523163、prop registered foot830、同103 band sibling22/23、4550角色alpha均被inn PNG mask覆盖。正常832控制opaque且返回830又持续ghost；full875/17和Physics均clear。开放门洞PNG alpha252–253并非孔洞，简单全图遮挡把极小假behind放大成整人变淡。不能只凭原832 front PASS批准原830；也不能仅改mask或用不传递pairwise epsilon sort。条件式方案为NEWcity限定统一nativeFloat32脚点strict tuple，bucket/sibling/mask/cache同用，并保adjacent nativekey真正behind、tie actorfront、NPC及各band自然phase控制；此处只证明因果，未证明该修复或正式批准。

ROOT431源审READY漏检DIAG_SHA字面65hex多1a，实际首guard失败、0obs且noField。哈希工具输出正确不代表源码常量抄对。新运行前逐个literal检查64hex长度及实际SHA匹配，包含继承engine主体（非console loader）和Bridge；原失败日志/pin不改，NEWretry只修误字后实际采集。结构source审与literal实核都要做，不能以脚本存在/可解析替代执行证据。

## 2026-10-09 ≤4px计划采样不能保证rounded完整脚底连续安全

ROOT418南市shop第14段(1888,832)→(1920,864)，原13个等距≤4px点全部通过，但沿(1888+u,832+u)在9.5≤u<10.5会将黑角(1915,830)纳入inclusive875。实际正常输入记录1897.999756/841.998962也拒，精确整数1898/842仍拒，不能当浮点噪声或只归QA误报。连续Physics矩形右缘尚在实体左侧，缺before/requested/constrained/slide记录则不可断言Physics穿墙；Player只检查预测终点，实际move_and_slide轨迹与终点不同仍须实际因果采集。下一定向诊断保持原route/target/input，独立逐半整数事件与区间代表核完整raster，再记录真实physics前后，不重选成功路径来掩盖原生产瞬时违规。旧FAIL/原PNG/完整875+17/阈值不改。

419随后实际90组priority−1/0/+1同frame观测复现：full请求终点1899.313721/843.313721与875/Physics均clear，shop corner1915/830两次slide后actual落在原rawbad/Physicsclear点。终点合法不能保证实际滑动落点合法。窄修只在新city3 motion完整栅格区间与源实体sweep，原C端点、脚底、静态实体、通用Player不动；原safe_margin只读包络新增保守拒绝需明确批准，不能宣称可走域完全等价。闭事件及区间包络完整raw可用一次prefix O1查询，不能每tick数十次875Color循环后只凭理论称性能合格。原坏14段必须先用原INPUT/旧planner复验生产修复，再验证严格新planner，避免把改路冒称修复。419外层font/音频import漏首guard和内部伪.gd/空path ABSENT不可补末次信用；下轮从实际启动资源闭包首快照补齐，不追递归所有历史artifact JSON使只读inventory扩到GB内存。

## 2026-10-09 悬高屋顶的地面脚点与alpha底不是同一坐标

ROOT412府衙三roof-only载片无法发现front强alpha站位，原FAIL保留。只读作者UV显示其按真实ground foot排序，屋顶刻意上提190.298/171.855px；PNG透明尾端仍到foot+5。将foot改到alpha底会错误移动物理与排序基准；为满足每件front阳性的测试补假低位alpha也不成立。搜索无结果不能证明无交集，当前113.5px人物高度不能代全武器/全部帧。

NEW正确诊断口径是逐实际source/import全部非零alpha、按原bilinear邻域扩大支持并映射actual transform；与实际允许40strip/240帧的完整160cell drawrect连续front半平面保守比较。不能用metadata used_rect自证，也不能套prop完整PNG drawrect分离（含透明尾）。源审进一步拒绝只记录gap不加入完成/exit门禁、只认actualtexture属于inventory而不核Player当前weapon/state/direction精确路径；这两项必须封严。414实际24正常朝向观察及415独立6真实/46阴性通过，严格F>=foot最小gap40.787598px；单位不能代Field输入。behind强阳性、完整875+17鞋、Physics、正常输入、Y/ghost/union不能被替代；原412不改通过。

## 2026-10-09 原生RGBA载片的默认alpha-border导入会改变非零alpha像素

ROOT405严格publisher拒绝新Sprite原图/import全字节，不能靠放宽pixel比较或重编码PNG解决。ROOT407独立实际28载片逐像素分alpha域、engine.fix_alpha_edges内存副本对照：28/28不等原图且28/28精确等该操作；非零alpha RGB60426变、alpha变化0，并非只透明RGB变化。最窄修复是保原PNG/patch/C阈值，只为这28新entity import显式fix_alpha_border=false；原配置精确备份，唯一行diff。408实际编辑器reimport不作为Field信用；409独立固定8manifest/36资产实际source-import全部baseRGBA通过（stdout436/0、saved434/0），125内部文件含36compiled首末保持，15player精确ticks零变。外层构造compiled列表时PowerShell逗号/字符串加法误合并walk/floor两路径，8compiled漏额外外层guard如实保留，不补信用；下轮直接从实际unit完整source_before枚举，避免手拼数组域。410真实activation签名pure132/0/空stderr，修nested{scene,layout}应显式.scene而非字典比较；纯单位不等实际切换。411四candidate实际保存读回通过/source-player0，Field/正式双端仍必须真实执行。

## 2026-10-09 独立生成的转角不能按同墙高直接视为同截面

用户认可ROOT387正面墙后继续围合。固定镜头实际为south→north、yaw0、30°正交，纵墙应窄端视且沿屏幕Y，不得旋转正面PNG或照搬旧斜折墙。v10/b方向成立，但A端面厚度与B/C墙高未共同匹配；一次针对编辑后仍拒用A，不靠X压缩、镜像或旧54px碰撞假装兼容。原图、实际尺寸/alpha残留及完整prompt均保留。

ROOT389南角pair技术捕获OS0仍出现贯穿瓦顶、灰泥、砖脚的两条素材断缝：同ridge/foot高度不等于瓦粒径、檐厚、风化密度相同。接柱只能解释墙段分界，不能消除柱上屋顶拼贴。后续最窄方案应保持横向屋顶/墙身/砖脚同一已批墙板，只让新图提供真实曲角、北向瓦顶及角柱；占域必须明确让旧屋顶停绘，不叠图掩接线。新曲角仍须实际GPU复审，不能继承389技术通过、387正面批准或旧碰撞/排序信用。

390实际GPU复核证实横墙灰泥/砖脚断层消除，但曲瓦尺度偏大/直切接点仍在，只有结构方向有限晋级，不得称无缝构件或直接扩完整院落。99源/15玩家精确ticks/30输入9PNG及门洞通过也不能替代该美术判断；完整纵墙/端帽/接厅及新Field物理遮挡仍需另验。

运行包装器SourcePaths采用已验证工程内相对路径：直接把before.json绝对路径交给Join-Path会重复F:\\Code\\RPG_GAME前缀，ROOT388因此未启动引擎。保留失败目录，明确前缀后转相对路径并用新目录重试，不覆盖旧证据。

## 2026-10-09 同一正面墙跨旧/新模块统一资产；生成期望不等于实际质量

ROOT387用同一真实墙板替换全部门旁旧墙与native延长墙视觉，避免继续在两套瓦/灰泥/砖脚之间调色掩接缝。原中央门楼通过显式GPU UV保留，门洞不画墙，旧native停绘；root/art实图有限批准材质方向后转向转角/围合，不无限微调。仅2.5D载片，不能冒称native/PBR、完整院落或正式接入；新alpha/crop与角色遮挡/脚底/碰撞需分别验收。

生成要求3450内容宽/无端柱/透明边，但实际2172×724、选用1980内段只1.72×、边A1且有端柱；记录偏差，以显式UV排除端柱而不改原PNG，不放大后称3×原生。为保瓦体比例统一XY缩放，应接受并记录新墙高度，不能暗中非均匀拉伸使旧三条高度全“保持”。386 JSON解析Array[2172.0,724.0]与int literal Array整体比较拒绝；保全原FAIL，consumer逐维类型/有限/整数/exactactualPNG+原SHA后387实际通过。不能用容错round或字符串转数替代严检查，也不把离线镜像测试冒称实际引擎正反例。OS0仍含7旧退出ERROR，完整stderr必须披露。

## 2026-10-09 接墙先审整体墙线，不以局部墙厚替代拓扑

ROOT384原门图已包含正面门墙与两端后折墙，新增横翼却接在折角附近；局部砖脚/厚度较好，整体仍形成岔接。root/art上轮漏看此问题，用户实图复核后纠正。接模块前先标明素材已有转角、前后端点和整个院墙围合，选定单一走向；若改为直墙，必须明确排除原纹理烘焙侧折，而不是让新增墙压住接缝。固定镜头下砖脚、墙顶、檐口均应检查，不只看AABB/alpha或单个body。

## 2026-10-09 从烘焙场景图抽材质不能替代可信瓦资产

ROOT383真实native接墙复用完整原屋面RGB投影，原图光影/瓦沿与真实筒瓦叠加造成假波纹；384改逐瓦局部UV虽去掉该投影冲突，但9×12单瓦内表只有108像素，拉伸后灰糊重复，无法匹配高细节门楼。全源/patch SHA、alpha与包络技术通过都不是视觉批准。应保留已改善的砖脚/墙厚/断灰泥结构，瓦材改用有足够像素密度、可重复且不含烘焙投影接缝的素材或完整可信构件，不再靠小图采样/颜色/噪声循环。

新轮廓必须独立测alpha/crop/support，不能强制旧alpha；套旧transform也不证明旧脚底兼容。Godot实际native Mesh的合法non-indexed槽可为NIL，检查器必须先判Variant类型再解析draw indices，原NIL槽SHA保持，不能typed赋值后才is_empty。ROOT382原SCRIPT ERROR保留，383/384 capture OS0仍有7退出资源ERROR，不能以OS0替代完整stderr审核或正式批准。

## 2026-10-08 分层城市的材质微调不能替代构件美术

ROOT380/381两区实际GPU对比中，即使保留所有原生数组/alpha/crop并加强灰泥破损、雨痕和地面状态，简模墙的瓦檐/厚度/端柱与高细节门楼仍断层，程序蒙版反而形成波浪裙边；码头的平板/低模船/亮箱亦不能靠整体调色统一。遇此结果应停止继续shader微调，转向可信的接墙/转角/围合及码头实体构件。技术保持仅证明没有破坏原边界，不能证明画面合格。新轮廓或新增实体须另做alpha/crop/bounds/通路验证，不沿用旧材质限域批准。

## 2026-10-08 · 只读GPU测试也可能由窗口生命周期写玩家存档

- ROOT376四区几何子项完成，但整轮3334／1、OS1，唯一失败为save0及.bak变化；当前.bak精确等于运行前save0，新档内容吻合南市fixture。没有事件/进程日志，不能据此断言具体哪次焦点通知或哪个进程触发，也不能覆盖恢复玩家档掩盖失败。
- PlatformBridge的APP_PAUSED与窗口focus_out都走公开checkpoint→SaveManager(active_slot)，故“测试代码没有直接调用保存”不构成只读保证。必须在任何fixture/await前建立公开、明确范围的自动checkpoint暂停；不能改私有busy字段、吞整个音频生命周期通知或删除15文件/slot保护断言。默认生产自动保存和手动SaveManager保持，隔离手动保存仍需真实验证。
- 技术子项通过与整轮/视觉批准分开记录。240张实际图暴露重复铺地及简模墙/码头木板质感，应做隔离surface-only样图，不为视觉问题重排已验道路/碰撞，也不能拿源合成图替代正常游戏镜头。

## 2026-10-08 · 继承QA辅助函数必须先用真实引擎做窄编译

- ROOT370新helper五处把继承的void `_check` 当作bool；源码审查未检出，真实Godot立即ParseError。修复只分离原predicate与记录调用，不改变阈值；模式单位应动态加载、失败保存报告并自然退出，避免继续调用未编译脚本而挂起。ROOT371实际83／0/OS0，原370失败保留。
- fresh范围实测ROOT372主菜单输入及11当前场景33保存/22Field+Physics出生/26非法版本零变拒绝，437／0/OS0；这些限域事实不能冒充整图GPU、全部玩法或正式切换通过。ROOT373新冻结仅准备输入，不授审批信用。

## 2026-10-08 · 未上市试玩的验收范围必须服从用户兼容策略

- 用户明确允许重新开玩、不支持旧档后，停止历史world12/13/14及local1迁移调试，不能继续把旧兼容当作接入阻塞。旧失败证据仍保留，不改标通过；验收显式标注fresh-start/current-format，保留真实新游戏、当前格式保存重读和正常玩法检查。
- 不为范围缩减复制整套发布框架。现执行器/门禁增加明确mode，旧分支保留；新模式报告/冻结/签批范围严格一致，继续使用原可恢复六目标备份和journal，不触碰玩家存档。源变更前将六份执行/门禁源原件保存在369_before_fresh_start_mode_20261008，不能让新SHA追溯覆盖旧结论。

## 2026-10-08 · QA工作字典的清理不能破坏调用方目录

- ROOT362素材阶段局部通过后16屋顶地标定位拒绝，ROOT363/364不执行素材阶段时全定位正常；必须沿阶段生命周期找共享所有权，不直接改生产碰撞、映射或放宽UV条件。artifact取得owner.manifest.asset_sha256引用后，真实_finish清自身catalog同时清掉owner目录，正常结束及五条早退都受影响。
- ROOT365使用保留旧归档和新代码的真实run→原空finalpin拒绝→原_finish，旧17792→0/16binding→0，新取得duplicate(true)后完整owner nativebytes及16binding保持，fresh实例重复和typed nested变异保持。收集预期拒绝必须保留原失败且明确仅因果pure；不能把OS0当完整artifact/RELEASE。清理前建立自己拥有的深副本，不靠清理后重新读盘恢复。大型完整字典原生bytes比较为线性，勿调用逐键双循环的递归semantic比较造成n²；typed深层语义另用小夹具验证。

## 2026-10-08 · CACHE_MODE_IGNORE不保证独立脚本实例

- ROOT359实际证明GDScript加载仍可返回共享缓存实例，不能因CACHE_MODE_IGNORE就写source_code制造反例。必须先is_same所有权检查；本次保护分支未进入，唯一夹具失败完整保留，70既有变异全拒不能抵消整单位OS1。
- 同路径代码篡改校验应机械提取实际生产消费者中原typed字段核心，以readonly真实path/code和owned字符串变异测试；Resource入口仍双方GDScript/metadata严格。明确核心predicate负例不等于真实同path独立GDScript实测，禁止take_over_path/cache污染或为了造反例改共享脚本。

## 2026-10-08 · 合法内存场景副本不能只凭resource_path验收

- ROOT357林西三入口在旧QA路径身份断言失败，不是行走失败；ROOT358原super三模式实际采集证实生产既有OUTSKIRTS source-entry合约会隔离scene及外部layout，实际resource_path为空，仅追加竹林路标和入口，原全部字段/metadata/cache保持。必须先保全失败和实际差分，不因静态猜测直接允许任何空路径克隆。
- 身份消费者只能为已绑定完整合约、确切源ID开放完整字段/类型/元数据/资源脚本内容/独立layout及唯一追加项严格验证，candidate与正式adoption分别核验；不能放宽成scene_id或path相同即可。字典应比较精确键类型和逐value native数据，键插入顺序不同使整var_to_bytes不同并非内容不同；typed Array元数据、浮点原字节和同path伪资源仍必须拒绝。归因诊断OS0保留原3FAIL，不代表正常返程或RELEASE完成。

## 2026-10-08 · 旧图设计尺寸不是实际行走坐标域

- ROOT353三门户15失败不能据泛化消息猜成生产地图坏；ROOT354原九次实际诊断证明displayfalse旧图1536×1024经viewport cover运行于1920×1280，原QA仍把实际root送原raw并用原边界寻路。必须分别保留actualroot、visiblefoot和实际CollisionShape/globaltransform；古峰/凌月实际visiblefoot偏移约68.04，不是只读默认值推测的50.4。
- 修QA应逐个实际10×6的17鞋点先在actualcanvas拒越界，再映射source像素/多边形/源solid；不能只缩center后让原oracle重采source10×6，偷换实际鞋半径。actual Physics/Area/4px段/32网格/20000cap/80候选不减，真实碰撞负候选仍拒绝；专项与旧FAIL均保全，不能将原诊断OS0等同原验收或RELEASE通过。

## 2026-10-08 · 资源引用出现次数不应变成完整文件哈希次数

- ROOT354前置regex扫18MB布局43836次res出现，对同129MB树模型重复数百次hash；5945实际唯一文件仅1.044GiB，却重复读321.513GiB，耗时约十三分钟才开始诊断。无stdout但CPU活跃不证明在JSON解析，也不证明卡死，应只读量化实际调用域。
- NEW专项应先收集唯一路径，首轮每路径完整hash一次、末次对所有唯一路径重新完整hash，并保留首次/末次SHA与bytes/mtime。不能借旧结果、只看mtime或省略源保护来提速；运行中源冻结，旧慢诊断及证据不覆盖。

## 2026-10-08 · 地表可走记录不等于包含独立物件后的角色净空

- 冻结Cwriter的ecology.walkable来自投影后完整17鞋的当前PNG精确WHITE，不包含source solids；native_selector又是源XZ单cell，不可替代17鞋。ROOT350旧QA误拿raw.clear（17地表后另查实体）对照该字段而拒绝；ROOT351全部九区实际分域诊断证明唯一西侧树林地表WHITE、原树干正确阻挡。不能按失败数量猜区域、删除实体、移动probe或修改冻结记录来通过。
- 应保持原writer地表17域精确比较，并独立保留源实体完整脚底验证与树干负例，明确源实体oracle不是实际Physics信用。旧结果/父检查保全，新消费者必须定向正反例和fresh完整验收；域校正专项不能冒充整个世界或发布通过。

## 2026-10-08 · live资源路径与native保存重载路径不是同一承诺

- Cwriter先保存ShaderMaterial，再从仍在内存的纹理记录resource_path，42项均为空；native .res重载后实际获得parent.res::ImageTexture_id。ROOT347六项合取42失败不能直接归为mip损坏；ROOT348逐分量独立诊断才证实唯一差异是路径，36原JPEG全mip及2原RF逐字节一致。诊断OS0仍明确保留旧genericfail42，不能洗为artifactPASS。
- 正确QA应绑定原父资源实际SHA、ordered具名uniform/schema/type、record typed空live路径和native加载后精确父内部ImageTexture归属，并保留完整尺寸/格式/mip/hash/独立原源字节；不能简单删路径检查或为了检查器给冻结writer补伪字段。先定向实际正反例，随后fresh完整候选及正式回归，限域检查不继承发布信用。

## 2026-10-08 · 音频设备标签不等于工程部署位置

- 只读原生端点枚举应与音频播放批准分开：ROOT344三角色GetDefault返回0x80070490/null、ALLstates枚举成功count0，诊断自然OS0/complete仅代表失败观测完整，不是音频可用。它只证明该诊断进程当时的可见端点，不证明其它桌面/进程无声，也不能把返回码冒认为早前Godot进程内部原始HRESULT。应先核微软SDK ABI、IUnknown槽位、PreserveSig和CoTaskMem释放，保持MTA创建/清理同线程；超时只记incomplete，不能无限重跑或越权改系统。
- 本机Godot的历史输出设备名“远程音频”与Windows session Disc只描述当时环境，不能据此认定工程位于远程机器、确认默认端点初始化失败的原因或要求用户重连。ROOT338的Dummy回退是实际失败，原因仍未证实；ROOT340同一安装引擎与原参数、新进程自然OS0、10帧真实WASAPI且stderr空，未改任何系统设置。可用性复测与音乐连续性/完整RELEASE必须分别验收，不把环境恢复写成代码修复或正式接入。
- 复用运行包装器时先核对其SourcePaths协议：该包装器内部Join-Path仓库根，只接受仓库相对路径。ROOT339从before.json还原绝对路径导致双根拼接、引擎未启动；失败目录保留，ROOT340显式去掉已核对的仓库前缀后另开唯一目录成功。不要覆盖失败现场或为启动错误赋测试信用。

## 2026-10-07 · Packed数组所有权与源记录槽位

- ROOT324轻单元将caller PackedFloat32Array直接赋给probe，probe.release的clear同时清空caller。首正例通过、后续19反例因空RF越界获得false，OS0/count0仍不是有效拒绝。NEW retry325显式duplicate，每例完整1575425节点与b721SHA在API前后、release后检查，且必须命中预定拒绝marker；实际194／0、stderr空才授单位信用。不要修改生产cleanup掩盖fixture所有权错误。
- 源记录的“全部槽”必须以真实writer为准：V5 prototype只保存VERTEX/NORMAL/UV/INDEX四槽SHA，而ArrayMesh还可能有native TANGENT。ROOT326旧QA用全nonnull计数要求记录包含tangent导致拒绝。不能伪造旧记录或删除额外槽验证；应先用绑定原glTF和同native存储边界的独立control证明额外槽内容，再按真实四键合同绑定原记录，所有13槽内容仍需验证。

## 2026-10-07 · 分层地标关联必须按真实作者协议验证

- 完整候选318 world3220／9不是建筑缺失：author source在portal.compound_id登记实际object.id，publisher原样保留，Field实例名为SceneObject_<object.id>；旧QA静态间距和屋顶sprite仍查object.portal_id，前者提前失败掩盖后者。应修独立QA到唯一portal→compound→runtime sprite的真实关联，保留原16门／36中心及36门间距／屋顶源像素投影／正常输入谓词；不能给生产资源补虚假旧字段、按标签猜建筑或跳过未找到的对象。专项合格仍不代替完整候选和切换后的正式双端回归。
- GDScript的int与String直接比较可能抛SCRIPT ERROR而不让整个SceneTree OS失败；319错误类型反例获得空返回后按计数“拒绝”，仍出现OS0/count0，不能算正确拒绝。类型guard必须在跨类型比较前；每轮stderr完整复核应先于下一轮启动，root320过早派发后明确保全中止，不把两个轮次写成通过。

## 2026-10-04 · 导航完整三角支持域和交互站位必须分别验证

- RF顶点改动不应只冻结导航查询点：2px selector会读取整个8px晶格三角。ROOT210证明protected点(4992,614)仍引用保护矩形外y608节点，使坡度跨.72。RF支持冻结独立扩16px而NAV合法域/阈值原样，ROOT212才通过；RF软过渡过窄仍会形成实际陡墙，数据PASS不能替代GPU视觉。
- 全875脚底导航像素＋17样本都白也不代表能站：ROOT216札记原站2440,950精确撞同位NPC。交互必须核实际Physics、NPC占位/范围、独立可点击图像以及Space和mouse；两个Action绑同一Sprite会被数组首Area截获。修复应真实移动物件/站位并验证原剧情onceflag，不扩大交互范围或关闭NPC碰撞。
- SOURCE_READY不是编译通过：literal预载闭包迁移仍可能漏掉旧GPU_CACHE标识。ROOT217真实编译拒绝后，mesh/RF须改绑定当前派生原件而不是补回旧cached geometry；保留初次错误和三行窄修diff，ROOT218再取得实际compile OS0、stderr空。

## 2026-10-04 · 原生网格重编码与真实转换必须独立取证

- Godot实际ArrayMesh.surface_get_arrays→add_surface_from_arrays即使输入未改，NORMAL/TANGENT也会由native codec重编码；不能把这误报为RF/道路变化，或取消保护slot断言。ROOT206两个独立control全slot重复零差，单normal-node trial仅该节点TBN改变；新的派生须保留原semantic tangent输入，明确授权normal关联的TBN重编码，域外与control零差，XZ/UV/index/其它槽原字节，不使用epsilon。
- 原著对白终节点正常跳转battle或scene时，Field可能已脱树而LoadingManager尚未完成。下一fixture必须等待真实目标Field及其on_enter对白自然结束，或真实Battle/Victory回原场景；否则测试自己的切图产生grace与脱树级联。不能改生产剧情、瞬时找攻击按钮、注入结算或把部分记录当完整52动作通过。
- HashingContext.update不接受空bytearray；只读诊断也要跳过空update并如实保留旧ERROR，不能仅据OS0宣称零告警。

## 2026-10-03 · 郊外技术通过不代表生态成立，材料重试必须走原实体

- `SceneScript.duplicate(true)`在实际Godot4.6.2仍与原资源共享外部map_layout和其objects数组。首次候选轻检因此OS1；必须显式复制外部layout及所有被写数组／字典，并对原native壳和source overlay逐持久化字段快照、引用独立检查。根转换需同步ground／nav／entities／capture graph，不用新物件配旧地表。四启动模式轻检通过不继承改动前Field／视觉验收。
- 三独立郊外local links最终2499／0、九次双向正常输入、自然战斗回程及六玩家档保持，只覆盖冻结旧产物；真实CC0竹换入v3后的31／23／6物件不能继承旧Field验收。原v3三GPU成功但主控实读仍判生态FAIL，保留旧证据，视觉版本、玩法版本、正式采用分别记录。
- 注册资产名称不是视觉结论：forest_ground_04原图实际偏石屑，不是落叶腐殖层；仅给整个地面换颜色不能解决生态同质。地表混合应共用ALBEDO／法线／粗糙度权重；水岸形态修改必须同步实际地形RF与导航，不只改底图。
- 首次满袋点击的fallback对话结束后，新材料cache的inflight锁必须只释放对应场景/trigger/真实dialog ID，才能原地腾空后点击同实体领取。公开play首次发奖不能冒充点击流程通过；重访和隔离存档重载后还须拒绝重复领取，不清所有trigger或绕容量门禁。
- 自然音乐sting协程可在公开stop后仍持有局部WAV至timer结束；应以有界自然等待和WeakRef证明释放，不靠清全局资源缓存掩盖。保留首退出ERROR与最新Timer／Image警告，不把exit0称零告警。

## 2026-10-02 · 分层整图正式接入必须绑定真实脚底、alpha与独立审批

- 2026-10-03最终正式FULL headless106167／GPU107961项0失败、均实际exit0；root实际52联系页绑定本次592原图全覆盖，独立资源／存档审查后才交付。批准旧dossier保持冻结，切换后的新launcher身份与新证据另记，不能把旧批准来源伪装成新执行身份。密冠p95 31.363ms、7Timer等退出告警及未重导包如实列为限制。

- 正式切换后的冷autoload尚未走新游戏初始化时，成员导航版本仍是12；公开恢复接口按正式v14合同迁移成14，因此测试不能把未初始化空字典版本当成生产新游戏的还原基线。保留首次完整106158／1失败；独立复现后，仅以公开reset建立真实新游戏前置，再继承原冻结FULL与全部cleanup断言，不修改生产资源或冒称原失败通过。
- 粗8px深度band不是最终前后关系；同档角色仍须按实际脚底稳定排序，透明剪影须读实际兄弟顺序。普通NPC保持原StaticBody2D／Rectangle、自然巡逻和真实动画格，测试不能缩碰撞／冻结演员制造重叠；JSON自然过程与GPU当帧图必须分开绑定，不把区域图虚构成NPC覆盖。
- 连续alpha拒站未决不能当“没有遮挡”通过。实际四向当前idle格域以保守细分闭合，原alpha阈值与预算不提高；优化是成本调度，不是删短行／抬预算。明确不外推全部武器与动作。
- Godot透明缩放应在同RGBAF空间预乘alpha后Lanczos再还原，保持alpha0 RGB不影响边缘的独立packed-Float32对照；真实不透明原地表另保原straight路径，不能同一个缩放函数混称所有源。
- 生图／原生导出成功、check-only exit0、技术总数都不能签视觉PASS。Root实读联系页逐原PNG SHA、全部当前图片集合与独立附图后，才录明确PASS；机械工具仅CreateNew证据和只读catalog，不代替主控、审批或正式激活。
- 激活浅复制测试候选，仅scene_id改变，外部资源和导出玩法逐项精确核验；先备份旧正式字节再保存，失败自动精确恢复。成功仍须新进程正式完整回归，保存旧失败及退出警告，不宣称所有场景已修或所有区域60fps。

## 2026-10-01 · 遮挡探针必须先合法，绕行侧数由实际地理决定

- 用碰撞矩形半宽17px、布局归一化扩边和完整脚底共同计算站位；本样段安全距为24.288×14px，旧16px侧距／10px前后距离本身不合法。有alpha交集但站位被导航拒绝，不等于精灵alpha为空。验证当时真正动画格和物理净空，不能复用诊断常数充当新测试。
- 河岸20px安全带可在陆地上拒走。东岩西侧实体净空区与岸侧脚底合法区无交集，应明确保留天然禁走，验证陆侧连续绕行；不能填河、缩碰撞或把陆地误报成水面来迎合旧双侧断言。首2135/10保留，语义澄清后headless2262/0与GPU2300/0是不同阶段结果。
- 技术PASS不替代画面质量：19张实机图仍有软草毯、重复土斑及锐利地标贴片。真实投影15966像素证明原生接影恢复，不证明整图地基／材质已融合；草根间隙读不清时保留风险，不猜测后挪anchor。见 `docs/world-map-native-pair-front-winding-v12-20261001.md`。

## 2026-10-01 · 空影要用可重复对照定位 影包围框必须按像素计算

- 相机排除caster图层即便light mask包含该层，也可能让阴影一起消失。本机最小矩阵四组camera-excluded全空，同层visible／SHADOWS_ONLY八组真ground非空；这只支持该路径失败，不解释所有整图失败，不代表Compatibility不支持阴影。
- ON/OFF普通可见对照保持同本体，另渲原body alpha并膨胀2px排除。要求body有透明像素、非空局部有效范围、重复捕获与PNG SHA精确一致；仅判断非空差分会把本体或帧漂移当影。
- JSON数值需按数值语义比较；RGBA8 alpha重建需遵守实际字节量化。Rect2i.expand(point)的几何右下沿不包含末像素，影metadata bbox会少1px；用原PNG.get_used_rect和独立inclusive像素范围复核。QA先192/44再192/8，修测试与真实metadata错误后277/0，不放松非空／本体排除。
- ORTHO/max40及32在小场景也非空，但比两split影更宽浅；不能凭非空宣称原大图已修或质量相同。应继续真实地形／实际物件transform／多viewport捕获的受控过渡实验。见 `docs/world-map-native-shadow-capability-v12-20261001.md`。
- 实际地形三角绕序可被cull_disabled掩盖：有画面不代表朝上正面受光／接影正确。受控网格对照只逆index就恢复1904个本体外地影，而材质替换与原绕序flat均0；须与Godot原生PlaneMesh实际decoded三角方向核对，不能只看显式NORMAL朝上。索引改动逐triangle与vertex／UV／normal SHA精确断言，packed index按真实16／32位宽编码；普通解包再建mesh会重新量化normal，初版stride错误造成退化必须在GPU前抓出。
- check-only可能放过动态对象上不存在的API；首v12整图因Image.has_alpha调用失败，不能把解析成功当可执行证明。使用实际Image格式和透明像素门禁，并直接运行合成图正负例；仅小于整画布仍会放过边缘内缩的近全幅图。本轮十个小物件限定小于半画布，生成与启动端一致；不能将此小物件限制推广到任意大型sprite。嵌套捕获失败须显式返回到外层停止构建，保留每轮原日志与真实尝试计数。

## 2026-10-01 · 模型接地点不能用旋转AABB角假代，空cast必须拒绝

- 旋转AABB八角包络不是实际实体支撑面，会把岩石脚底标到透明图下50px。应从模型真实顶点／最低支撑集合推导接地点，并与透明capture投影及完整XZ底面核对；仅修改代码而未导出稳定新alpha不能声称已修。
- 同相机／灯光的SHADOWS_ONLY或caster独立层ON/OFF仍可能捕获出空差分。先验证非空和来源，不能用ground土斑或程序椭圆影补齐断言。v11两次capture都0后exit1停止；正确下一步是最小receiver/caster捕获诊断，不无证据把整个兼容renderer判无阴影，不继续整图材质微调。
- partial文件即使路径、尺寸、metadata完整也不等于READY；启动器应同时拒绝失败状态及空影，测试要区分未运行／预检拒绝／完整专项通过。旧v10回归1582/0及62份冻结源SHA不变只证明旧内容未破坏，不证明v11已可玩。见 `docs/world-map-native-pair-native-props-relief-v11-20261001.md`。

## 2026-10-01 · 视觉接触缓存与地理必须隔离，诊断要来自实际Shader

- 只改接触阴影时不能让新增site进入原高度压平cache，否则城／亭地基变化会偷偷改变导航。v10单独视觉site，真实重渲land／walk先与冻结v9逐像素比对再存盘；复制旧mask不能证明几何没变。
- contact诊断须同网格／同相机、调用可见材质同一Shader函数；水域discard和bridge／dock veto同时检查，不能另画空白权重图自证。116872陆地非零、水／甲板0只能证明作用域与非空，无法证明正常镜头接地可信。
- 新版文件不能仅换名却由route loader继续读旧前缀；v10修为读自身route，并检查字节相同和运行绑定。冻结老源／正式文件SHA与新visual实际不同应同时验证。
- 连续两轮后灰石和暗核改善仍不等于美术通过。应停止只调噪声／强度，转向局部地貌体积、群落与统一光影／边缘；不扩大暗核凑接地，也不凭1582/1602全绿接正式图。见 `docs/world-map-native-pair-material-contact-v10-20261001.md`。

## 2026-10-01 · 水域结构不能当陆地，透明像素不能当纯前景

- 新港湾改变海岸净空时，应把道路退回陆侧并保持最后一段完整脚底采样，不为旧路线填海或大范围涂白水域。桥／甲板允许结构支撑，天然陆地蒙版仍必须保持水域；桥中心不能当干地正例。
- 完整渡口图应在人物脚下，栏柱／亭屋独立排序。矩形alpha裁切即使有透明背景仍会夹带真实木板；中心线通行通过会漏侧边鞋缘。要保留合法侧边站位并验证完整脚底前景排除，不移路线或改黑碰撞掩盖。
- 上述排除必须限定真实地板语义。“可走脚底不允许任何前景”也会误报站在真实栏柱／石座后方的正确遮挡；v9修后9处重叠由独立原图确认是柱根／桩帽，不能为全绿擦掉。应保留完整遍历及已知木板负例，独立定义地板与小范围实体见证，正负例同时验证。
- 把真实栏柱从地板分离后，仍不能把多个不同底座的柱子共用一条Y线。v9找到中柱前方朝右实际22像素相交却反序的P2，改为五独立底沿；源重叠像素须唯一归属且合并alpha不变。验证当前动画格／hframes，不能把整条带缩进单格制造假alpha交集；同8px深度带还要核对兄弟顺序，不盲要求z严格大于。
- Godot严格导入exit0不能替代独立dev脚本check-only；入口的Variant推断错误可能不被导入捕获。资源不可读／画布尺寸不一致应在预览启动时明确失败，不静默省掉前景。
- 技术全绿不等于美术全绿。港湾／曲河改善后仍须审查铺地网格、岩肩体积、软地表、锐利贴片与重复植被；不能跳过视觉门禁接正式图。见 `docs/world-map-native-pair-authored-bay-v9-20261001.md`。

## 2026-10-01 · 路带近似不能外推为宽地形压平；测试点必须保留语义

- 主路局部法线宽度近似可用于窄路芯，直接外推为200px高度过渡会因急弯导数变化制造竖岩针。v8高度改用附近折线实际段距，修真实网格；不以shader伪造平地。
- 地形重塑后旧陡坡坐标可能变平缓。先报告原断言失败，保留实测梯度与当前可走正例，再补真正陡坡的源点/投影点拒走合同；不为通过历史断言涂假障碍。道路投影长度变化也会改变4px探针数量，应记录密度与覆盖，不固定旧count。
- 去除扫描低频旋纹会削弱重复感，但也可能让地表软糊、物件更显贴片；接触土斑不是接触阴影。视觉需在真实Field城池/桥/渡口截图独立审查，不凭无建筑底图或技术全绿晋级。见 `docs/world-map-native-pair-ground-contact-v8-20261001.md`。

## 2026-10-01 · 地标接驳必须验证完整脚底与真实输入

- 道路中心点落在陆地不代表整个人的脚底可站；渡口入口中心离岸83px，右侧脚底仍越过缓冲。测试应沿主路/入口支路每4px验证完整脚底，出生修复不能替代精确入口合同。
- 新路画出来不代表导航已采用新路；继承旧路带会在新增急弯断路。当前曲线按局部法线近似宽度，渲染与导航读取同源topology；天然陆地/海岸和河道否决必须最后胜过道路白芯。未来更急曲线仍需实测，不能把局部近似说成任意曲线的精确距离。
- 独立石桥需拆脚下桥面与前栏，不可将整桥图Y排序在人物之上；天然陆地蒙版和结构支撑桥面须区分，仅合同桥矩形允许跨河。物件阻挡仍独立否决主路。
- 摄影测量glTF可能是一组并排展示的扫描变体。先隔离单株再计算透明画布、物理脚底和渲染尺度，不能把四株目录图整排摆到游戏中。
- 临时路线进入现有城市/渡口时只用无剧情/奖励的运行副本，正式入口、存档和任务不变；实际Space/鼠标交互要补充直接函数断言。见 `docs/world-map-native-pair-landmark-route-v7-20261001.md`。

## 2026-10-01 · 按可见身高校准 NPC，同曲不能按场景名重新定位

- 相同160px精灵画布不代表相同成人大小；南坊学徒、持枪守卫有效身高120px而多数成人140px。共用家族按有效alpha校准并缓存测量，但仍需保持原地面脚底、碰撞和对话方向切换，不应给所有角色盲目乘倍率，也不改变儿童/坐姿语义。
- BGM资源身份与场景上下文应分开：场景只决定真正换曲时的入段，同曲跨房间/加载不重新play或seek。兼容资源UID/规范化路径、停止淡出被撤回的竞态；平台暂停时playing可能为false，仍须用stream_paused保留同曲。
- 没有扬声器输出的dummy音频测试只能证明播放器身份与playhead连续，不能宣称实际听感、曲风或硬件零间隙已验收。专项与真实SceneRouter切图证据见 `docs/npc-scale-bgm-continuity-20261001.md`。

## 2026-09-30 · 地形数据的编码范围与独立物件的投影脚底

- v4 把只编码 ±128px 的拓扑 alpha 当作真实海岸距离，并在 245px 以上才完全恢复高度，结果所有内陆高差都被抑制。高度、坡度和岸线过渡应来自实际几何函数；压缩纹理须明确范围，不能外推饱和值。
- 正交独立物件的物理脚底是模型底面中心的投影，不一定在透明 PNG 下边。记录同镜头 foot_uv 后，再由该脚底统一视觉中心、碰撞、接触阴影和 Y 排序；不能凭图片最下边猜深度。
- 新增陡坡禁走会改变旧物件侧边可达性。v5 东岸灌木一侧被坡面挡住，应调整真实摆放，而非删掉绕行断言。用真实 Field 连续脚底检查补充蒙版定点检查，但仍不能代替移动输入与整图视觉验收。

## 2026-09-29 · 角色节点原点不是可见脚底，烘焙物件不能靠单块前景长期兜底

- 林西村水井的旧 `y_sort` 比较角色节点原点，角色自身却按贴图脚底排层；两套 Y 值错开后，玩家明明站在井前仍被井盖住。通用前景比较必须使用角色真实渲染脚底，且角色初次入场要等外观缩放/锚点确定后再排序。
- 把井从底图清出并设为独立透明物件后，画面、井座禁走和排序线共用布局数据，前/后实机双例可以做明确断言。只改某个遮挡矩形会反复出现同类坐标漂移。
- 独立物件也非自动正确：需逐项校准投影、视觉脚底、碰撞和可达入口。授权资源必须有素材级来源及许可记录，不能把“可下载”或仓库代码许可证当作美术授权。

## 2026-09-28 · “扫完全部场景”不等于“修完全部层级”

- 全库盘点可以验证资源加载、归一化几何和前景配置；视觉正确性还依赖物件在底图的实际坐标。华山两张长凳原有 blocker 却落在空地，单纯统计阻挡数会漏掉。
- 双侧可走且没有前景的 blocker 是复核线索，不一定是缺陷（地面物、边界物可能不需遮挡）。逐图目检后再决定是否补脚底阻挡、Y 前景或精确 alpha 蒙版，避免通用矩形把地面一起盖住。
- 大地图分层试样把地形、导航、独立建筑物件拆开后，角色／建筑可共用脚底排序；但单局部试样不应冒充完成整张大地图，必须继续补齐道路、地标、门户、高分辨率与接缝验收。

## 2026-09-27 · “数据里有入口”不等于玩家能在实体上交互

- 烘焙榜亭、告示牌等对象同时有三个坐标语义：画面实体位置、角色可站位置、交互Area。Area只写在附近空地会让测试看到action存在、玩家却认为城市没有榜单；应让区域跨接实体与可走站位，并对可走点单独设探针。
- NPC代开功能菜单会掩盖场景入口错误，也削弱探索反馈。NPC只负责提供方向，正式行为由可见物件触发；这样换城市后玩家仍能用同一规则寻找通缉榜。
- 带完整美术框架的UI不能靠通用HBox猜分栏。先测量底图安全区，再给印记、正文和按钮固定相对区间，并用目标分辨率实机抓图；自动化负责防重叠，目检负责判断文字是否真正落在纸卷/牌匾中。

## 2026-09-13 · 门派对白、透明区和美术统一要按玩家视角验收

- NPC对白不能复述设计文档。“开放、触发剧情、选择门派”是开发语汇；玩家需要听到的是谁提出什么要求、还缺什么、现在能做什么，以及完成后去哪里复命。
- 山门“可穿越”不等于整段上山路径都半透明。透明判定应使用角色脚底，只覆盖门楼横梁/屋檐下的建筑底层；外露楼梯必须保留完全不透明负例，门下再设透明正例，并用同机位实机图验证。
- 2.5D门派美术统一不是把所有图机械重画。先按材质、轮廓、色彩、相机和通路审计，重做卡通塑料感或线稿感明显的武当、华山、凌月；已符合写实基准的古峰和茗雾保留，降低导航漂移和资产回归风险。
- 生图只负责像素表现，不能悄悄改玩法空间。提示词必须锁定原有相机、路径、平台、出入口和负空间；运行时仍由结构化布局定义可走区、阻挡、门楼前景和交互。

## 2026-09-11 · 高级奖励、战斗分层和撤离反馈要按玩家语义闭环

- 开放探索中的高级武器不应靠章节硬锁，也不应进图即得。用可重复遭遇中的若干次“成功结果”揭示隐藏地点，再以作者化守藏战保护宝箱，既保留开局越级探索，也让奖励有旅程和风险。
- “获得心法”要区分秘籍物品、阅读内容、悟性门槛、实际习得四个状态。界面禁用只能提供反馈，核心学习方法仍须二次校验；研习不消耗关键秘籍，避免玩家失去传闻载体。
- 2.5D接敌动作的层级不能跟随“谁在行动”粗暴置顶。阵型记录脚底纵深，接近目标时按双方原始Y临时放在目标前后，归位后恢复，才不会出现后排敌人踩在前排人物身上。
- 撤离成功与战败必须分开：前者不播放死亡帧、不进入失败页；胜利页的多人经验则必须来自实际成长结果，显示每人经验和跨级信息，不能只把总经验复制成一行文案。
- 同一首已审核BGM可以按场景稳定落在作者化乐句入口，但这只是减少同开头重复，不能冒充新增曲目。验收要同时统计资源哈希、场景映射和运行切换；与BGM无关的既有SFX失败应单列。

## 2026-09-11 · 空槽图标要表达装备部位，不要借用相邻品类

- “护腕”和“手套”在战斗装备语义上不同，成对手套会让玩家误以为该槽是拳套或掌法武器；空槽应使用腕部护具的清晰轮廓。
- 通用鞋履图标若在小尺寸下像草鞋，即使文件名叫`shoes`也不适合作为全品质回退。优先复用资源库里轮廓清楚的成对皮靴，并在64px实际UI尺寸下目视验收。
- 回退图标需要覆盖主界面、旧背包和兼容装备面板；资源存在检查只能证明可加载，专项还应断言实际槽位解析到正确路径。

## 2026-09-11 · 可见路面、世界点击与信息展示要按玩家实际路径验收

- 导航门户全部连通仍可能让玩家在画面上的路面受阻。除图连通外，应登记可见道路横断面、沿中心线按角色脚底半径采样，并保留水面、悬崖、屋顶负例；指标要写明覆盖的是登记样本，不能把局部100%包装为整图语义覆盖。
- 出口箭头、NPC和物件重叠时，多个Area各自收输入会出现遮挡、抢占或重复触发。用屏幕坐标统一命中和显式优先级，交互距离仍在执行层复核，既可点箭头也不会隔着地图传送。
- 输入专项不能只直接调用控制器方法。Godot根Control的`mouse_filter`可能吞掉世界事件，触摸/鼠标互相模拟又会产生`device=-1`合成事件；必须从Viewport投递原生事件，同时验证GUI按钮仍可用、每次按下只执行一次、对白打开后不被第二事件关闭。
- 场景名称属于美术合同。“私塾”至少需要公共讲席、成组桌凳、多人容量和明确过道；卧床、单书桌、茶桌构成的是私人书房。用途不同的场景应拆分底图与碰撞布局，不能只换标题。
- 装备详情的正负色不能依赖解析已经格式化的字符串。属性名、原始数值、百分比和展示色应在结构化层生成，再由装备槽、固定详情卡和悬浮提示共用；这样负基础属性、比较差值和品质词条不会各自漂移。

## 2026-09-11 · 可招募NPC的切磋强度与快捷入口必须分层处理

- 同一角色的切磋 `EnemyDef` 与入队 `CompanionDef` 是两套身份数据。加强切磋时只能改切磋敌人并回归正式对话入口、奖励账本和战后快照；不能让一次难度反馈意外改变队友强度或共享武功。
- 可选切磋适合做成长软门槛：初见允许胜负不稳，授艺后正确用招应接近稳定，纯普攻仍明显更慢。只看静态伤害或单次胜负不足，应同时比较固定种子胜局、平均/P90回合、最低气血和有限内力的技能选择。
- “隐藏快捷入口”不等于“禁用快捷键”。UI节点可设为不可见，菜单展开动画也不得重新显示；输入分支、信号和功能继续保留，同时从可见提示移除已隐藏的入口，避免界面说法和实际产品状态冲突。

## 2026-09-10 · 数值要验证成长来源与真实行动，不只验证公式

- 永久药物不能只改派生max_hp/max_mp：升级或学心法会覆盖。按物品来源保存永久增量账本，每次从核心属性+账本重算；读档必须覆盖而非累加，兼容player/party重复载入。v13迁移只保留旧存档可证明的正容量差额，不猜喝酒次数；未来若改核心公式，迁移必须使用对应旧版公式。
- 调整理由：高防减法把入门敌人过早压到1、免费命名攻击替代普攻、隐性残血衰减让双方越打越弱，掩盖真实强度。期望体验：入门安全但能受伤，招式消耗内力换效率，Boss要求准备，强装与伙伴带来真实优势。实测对比：参考早期套装下陪练/高阶/山贼普攻由1提高为5/6/6；新规则下3级Boss用招配药63/64胜，纯普攻39/64，提前紫剑+高手3.42轮，详见实测报告。
- 不要同时大幅加强Boss和移除全局残血惩罚；后者已经提高后半场危险性。第一轮只调整有证据的早期敌人，头狼与赵无忌保留面板，按实际群攻、异常和有限补给决定下一轮。
- 自动平衡样本应实例化正式战斗，替换动画/音效表现而非伤害、AI、状态与内力逻辑。未命中、耗尽内力、晕冻跳过行动后的状态递减、吃药占整次行动、首击致死优先结算，都必须经过真实路径。最低生命需在回合开始持续伤害后采样，不能被吃药/跳过分支漏掉。
- 样本装备ID必须从现行获取数据核验：旧straw_shoes不存在；早期紫剑应取雪岭奖励heavy_iron_sword，而非凭相同品质假定青冥剑已取得。固定等级压力样本不应冒充真实任务路线，拦截经验和升级恢复必须公开标注。
- 新回归存档使用隔离临时目录或内存写入替身，不碰用户槽位。历史断言只有与批准的新合同冲突时才迁移；无关剧情/城市资源失败保留记录，不为测试全绿改内容。
- 数据图鉴同步遇到旧美术欠账时，不可偷偷取消默认校验或复用别的招式预览。严格构建继续拒绝；只有显式诊断开关可导出，且JSON、静态卡与动态卡都显示待补状态，保留终端缺失ID警告。本轮裂创扑咬只有角色动作和通用受击，不能称已有独立VFX。

## 2026-09-10 · 开放地图、剧情入口与视觉地面分离

- 只给Scene.on_enter加进度条件不够：同一对白还会被NPC、选项或play_at直接调用。主线门槛必须落在对白执行前，同时让Field在消耗once flag前检查，才能兼容“提前到访、日后再回来”。
- 无奖励的一般游历、购物和独立奇遇不应因为所在章节较晚而一起上锁。新入口必须有真实场景和可返回路径，不能只删除锁定文案。
- 导航图全部连通并不能证明路线正确：粗折线会穿山，角色中心与脚底偏差又会让正确蒙版看起来仍错位。按底图重描、脚底坐标一致、危险地形负例和实际截图必须分别检查。
- 可见交互不等于把库存图标散落在场景中央。卷册、药案、水则应依附真实桌案、摊位或石刻，激活位置需在玩家可接近一侧。
- 可提前获得的一次性装备需要背包容量检查与持久化幂等；满包时应留下木箱，不能发奖失败后仍把领取flag写为已完成。

## 2026-09-10 · 雨景必须同时改变空间、地面与声音

- 只在整屏叠加几根长白线会像光柱，不像雨。雨丝需要远近两层、不同长度与速度、较细线宽和受控透明度；实机静态截图是必要门禁，第一版过粗后必须回调，而不能只凭 Shader 参数判断。
- 全图雨景适合一个无屏幕采样的程序 Shader，地面反馈只使用有上限的复用水花节点；这比大尺寸逐帧雨图或数百独立粒子更适合滚动地图和微信端。
- 雨声应作为独立 ambience 随场景淡入淡出，不能并入 BGM。这样室内、洞穴和后续屋檐遮雨区可以单独降低或关闭环境声，而不破坏武侠配乐。
- 天气本身不能配置在场景资源上，否则同一地点永远下雨、剧情也无法控制。权威状态应由全局天气管理器持有并存档；场景只提供“是否暴露在室外”的物理判断，剧情节点负责开始、加剧和结束天气。

## 2026-09-10 · 火焰不能只靠颜色和缩放表达

- 三块固定多边形即使使用橙黄渐变并循环缩放，轮廓仍会被看成橡胶锥体；可信火焰至少需要向上流动的连续扰动、分叉火舌、内外焰温差、非同步闪烁与少量上升余烬。
- 战斗图集的提示词如果要求“抽象掌气”，生成结果就不会成为真实火焰。火系四阶段应明确写出点燃、推进、爆燃、余烬的同源连续变化，并把火焰轮廓、白热焰芯和消散量作为验收项。
- 网页预览必须服从运行时显式 VFX 映射；扫描通用目录只能补缺，不能覆盖 v2 或专项资源，否则游戏已经更新而图鉴仍展示旧图。

## 2026-08-22 · 视觉禁用、数据拒绝与人物性格必须三层一致

- 装备被队友占用时只在UI灰显不够，其他入口仍可能调用装备API把物品抢走；正确做法是UI灰显、操作按钮禁用、Inventory数据层拒绝三层同时落地。
- `weapon_specialty`只说明角色擅长什么，不代表角色手里存在一把隐形武器。招式显示与执行必须检查实际武器槽；空武器只能普通攻击，掌法也要有拳套、指虎或手甲。
- 字体模糊问题若来自`[b]`，只调字号和颜色不会解决。发布前应搜索用户可见BBCode粗体；需要强调时优先用颜色、留白和字号层级。
- 关键角色不能只靠人物小传写性格。第一次招募流程、拒绝后的复访台词、语速/音高/音量参数都要共同表达性格；沈青禾的“青梅竹马”落实为会直接数落并管住主角逞强，而不是温吞关心。
- 连续剧情被拆成两个NPC点击，会让玩家误以为内容结束或触发失败。没有场景行为插入时，应在同一DialogScript里用`next:`串联，而不是靠下一次对话变体续接。

## 2026-08-22 · 武侠音乐不能用规则琶音代替器乐编配

- 即使合成器函数命名为古琴或琵琶，连续、等间隔、音高规则的短音仍会被听成钢琴琶音。判断标准是实际听感和节奏角色，不是代码中的乐器标签。
- 用户认可早期曲目时，应保留其旋律密度、段落推进和动态起伏，而不是只复制五声音阶。v4直接使用早期CC0曲作为骨架，再做传统器乐方向的稀疏再编配。
- 探索音乐的武侠感主要来自留白、持续箫/弦与偶发锣鼓；战斗紧凑感主要来自第一小节立即出现的堂鼓节奏。两者都不需要持续高密度拨弦。
- 同一轮音乐改版必须同时更新SceneScript、默认回退、普通战场、切磋和Boss映射，否则玩家会在不同入口听到新旧两套风格。

## 2026-08-22 · 大地图碰撞不能只靠手工折线，也不能只靠全图颜色阈值

- 手工中心线便于表达拓扑，但会因几像素偏差切进山体；全图颜色阈值虽然贴合道路，却会把雪山、浅色屋顶和城墙识别成道路。可靠方案是人工定义宽走廊限制搜索范围，再从最终运行底图提取官道像素，并用短段寻路补齐桥面和阴影断点。
- 世界地图、M地图和城市返回点不能各有一份坐标表。运行布局保存唯一门户坐标；路由只保存场景所属门户ID，地图UI直接读取同一布局。
- `world_map`不是普通调查动作。旧场景迁移时必须与`scene:`一样进入门户层，否则会显示感叹号，破坏出口语义。
- 场景图看起来像游戏画面仍不代表已经是可玩场景。没有正向行走轮廓时，天空、悬崖和黑边都会被放行；后期场景接入至少要同时具备底图、行走区域、可达交互和门户箭头。

## 2026-08-11：已有 party 数组不等于队伍系统已经接通

- `GameState.party` 即使存在，若普通 battle payload 仍只构造主角、`BattleController` 又把非主角技能复制成 `_player.skills`，实机仍是假队伍。队伍接入必须同时覆盖：持久成员资源、普通遭遇 payload、活动角色技能列表、目标类型、经验分配和存档。
- “共享背包、独立装备”应以装备实例 ID 为全队唯一键。只复制多份装备字典会导致同一把剑被多人同时穿戴；正确做法是 `character_id -> slot -> instance_id`，换人穿戴时先从原持有人卸下。
- 透明边距只能证明图片没有贴画布边，不能证明角色身份完整；本批伙伴立绘由完整全身原图经统一洋红抠图生成，并保留 raw、引用图和 `codex_builtin` 元数据。

## 2026-08-01: Field controller indentation and map presentation rules
- Runtime overrides inside `_spawn_npcs()` must retain the per-entry indentation level. A single dedented patrol branch can prevent the entire Godot project from parsing, so run the headless editor parser immediately after changing nested scene-specific logic.
- Full-screen field presentation means uniform cover scaling for outdoor maps, never separate X/Y scaling. Reviewed compact interior rooms are an intentional exception: keep their native-size black-stage framing rather than stretching them merely to remove margins.
- NPC seating belongs in source scene data as well as any compatibility override. Keeping both aligned avoids stale serialized scenes moving a seated actor back into an aisle.

> 按 `user_rules` 第 1、2 条沉淀。每次踩坑或定位复杂数据后追加。

---

## 2026-07-31：重要角色四方向精灵应从同一张母图切分

- 独立生成方向或单帧时，面部、体态和服装非常容易漂移。重要 NPC 统一采用一张四行四列母图，单图内锁定身份，行方向为下/上/右/左，列为待机、左脚、过渡、右脚，再由通用脚本输出 8 帧行走和 4 帧静止条带。
- 服务端可能把请求的洋红键控底替换为灰底网格，也可能实际交付非 1024 的方图（本批为 1254x1254）。切图工具不能硬编码像素尺寸，须按实际方图的四等分裁切，并支持灰底和键控色的透明处理。
- 生成成功不代表可采用。杜青衫本批返回了与请求无关的卡通设定页，必须拒绝；后续单独重试返回空 `400`，不应覆盖运行时原资源。
- 对杜青衫改用不带参考图、但写死年龄、体型、工装、围裙、肩布和锤子的母图描述后，连续三张均恢复为可用四向动作图。服务不稳定时可用“详细文字身份锚点 + 单角色单任务”作为参考图失败的受控降级方案，但仍必须人工筛选候选。


## 1. AI 出图 - 大模型与中转商

### 1.1 ChatGPT 订阅 ≠ OpenAI API（最重要的认知陷阱）

**结论**：买 ChatGPT Plus / Pro 完全不能用 API。两者独立计费、互不抵扣。

来源：`help.openai.com/en/articles/6950777`
> ChatGPT Plus is a subscription plan that provides enhanced access to **the ChatGPT web app** for $20/month. **Not included: API usage is separate and billed independently.**

| 想做的事 | 该买什么 |
|---|---|
| 网页/APP 手动聊天/出图 | ChatGPT Plus / Pro |
| 脚本批量调用 | OpenAI API（platform.openai.com，最低 $5 起充）|

### 1.2 gpt-image-2 已上线（2026-04-21）

OpenAI 官方 API 模型 ID：`gpt-image-2`。比 image-1 便宜，原生 4K，支持中文 prompt。

| Quality | 1024×1024 单价 |
|---|---|
| Low | $0.006 (¥0.04) |
| Medium | $0.053 (¥0.38) |
| High | $0.211 (¥1.5) |

调用方法：标准 OpenAI SDK，只需把 `model` 改成 `gpt-image-2`。
- ✅ 原生 2K/4K
- ❌ **不支持透明背景**（仍需 rembg 后处理）
- ⚠️ 高清耗时 ~120 秒/张

### 1.3 Lovart - 没有公开 API，警惕仿冒站

**事实**：lovart.ai 官方定价页明确把 API Access 标记为 **Roadmap**（规划中）。
任何 lovart.pro / lovart.info / lovart.me 自称的 "Lovart API"（如 `api.lovart.pro/v1/generate`）**都是第三方仿冒站**，付费风险高。

**Lovart 的真实价值**：网页版 agent 帮你打磨 5-10 张关键参考图（Style Bible），不要用来量产。

**封号案例**：用户充近 ¥4000 PRO 年费，10 天后封号不退款（网易报道 2026-02）。结论：**只买月付，不要年付**。

### 1.4 中转商对比（国内可用）

| 平台 | gpt-image-1 | gpt-image-2 | 支付 | 注意 |
|---|---|---|---|---|
| **DMXAPI** | ¥1/张 | 应已支持 | 微信/支付宝 | 偶发抖动，连接超时常见 |
| **API易（apiyi.com）**| - | ~¥1.5/张 (high) | 微信/支付宝 | 比 DMXAPI 便宜，docs.apiyi.com 有 gpt-image-2 接入文档 |
| **OpenAI 官方** | $0.011-0.167 | $0.006-0.211 | 海外卡 | 最便宜，但需 VPN |

### 1.5 DMXAPI 超时配置（必须记）

OpenAI SDK 默认 connect_timeout=5s，对 DMXAPI 不够用，会出现 `APIConnectionError`。
必须显式配置：

```python
from openai import AsyncOpenAI
import httpx

client = AsyncOpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL"),
    timeout=httpx.Timeout(300.0, connect=30.0),  # 关键
    max_retries=0,                                 # 用我们自己的重试
)
```

### 1.5.1 DMXAPI 不稳定模式总览（2026-04-27 一日实测）

⚠ **结论先行**：DMXAPI 适合**冷批量出图**，**不适合开发期实时迭代**。
推荐：开发期手动用 ChatGPT Plus / Lovart 网页出图，DMXAPI 仅在批量阶段做容错路由。

四类失败模式 + 应对：

| # | 错误特征 | 触发条件 | 恢复 | 应对 |
|---|---|---|---|---|
| 1 | `APIConnectionError` + `schannel: SEC_E_INVALID_TOKEN` | 并发 ≥ 4 或短时间高频请求 | 30+ 分钟自动解封 | `--concurrency 1`，避开 IP 封禁 |
| 2 | `BadRequestError 400 moderation_blocked` | 中文武侠 prompt 含"杀/血/绝世/IP 名"等 | 改 prompt 即可 | `extra_body={"moderation":"low"}` + 软化措辞 |
| 3 | `InternalServerError 503: 所有令牌分组 default 下对于模型 X 均无可用渠道` | 不可控（DMXAPI 上游 OpenAI 渠道熔断） | 5–30+ 分钟，无 SLA | 跑批前用 `scripts/ping_dmx.py` 探活；失败任务 fallback 到 `gpt-image-1.5` 或人工 |
| 4 | `RuntimeError: API 未返回图像数据`（HTTP 200 但 `data[]` 空） | 渠道熔断前的过渡态 | 同 #3 | 视为可重试 |

**重要**：错误 #1 vs #3 完全不同：
- #1 客户端 TLS 层失败（`curl` 也连不上） → IP 风控
- #3 应用层 503（`curl` 能通，业务返错）→ 上游渠道问题

诊断脚本：`scripts/ping_dmx.py` 单次最小调用，退出码 0/1 区分渠道存活。

### 1.6 DMXAPI 实际可用模型 ID（不是常见名）

⚠ **2026-04-27 修正**：DMXAPI 的**接口文档页**和**定价页**信息不同步。下结论前必须**两个页面都看，并 curl 实测一次**。

| 通常叫法 | DMXAPI 实际 model 参数 | 状态（2026-04-27 实测）|
|---|---|---|
| GPT Image 2 | `gpt-image-2` | ✅ **已上线**（定价页有，文档页未更新） |
| GPT Image 1.5 | `gpt-image-1.5` | ✅ 已上线 |
| GPT Image 1 | `gpt-image-1` | ✅ 已上线 |
| GPT Image 1 Mini | `gpt-image-1-mini` | ✅ 便宜版 |
| GPT Image 1.5 SSVIP | `gpt-image-1.5-ssvip` | ✅ OpenAI 直连版（更贵） |
| DALL-E 3 | `dall-e-3` | ✅ |
| Seedream 3.0 | `doubao-seedream-3-0-t2i-250415` | 估算可用 |
| FLUX Kontext Pro | `flux-2-pro` | 估算可用 |

**坑**：曾经只看 `doc.dmxapi.cn/img-gpt-image-1.html` 文档表，看到只列 `gpt-image-1.5/1/1-mini/dall-e-3`，
就下结论"DMXAPI 没有 image-2"。**实际定价页 `dmxapi.cn/pricing` 已经有 image-2，且实测可用**。

教训：DMXAPI 文档更新滞后于服务，**永远 curl 一次实测**再下结论。
单图 `gpt-image-2` medium 1024² 实测 **¥0.131/张**（远低于定价表粗估的 ¥1+/张），
具体见 `docs/consistency-test-report.md` 第 4 节。

### 1.7 GPT Image 容易默认输出繁体字

**触发**：UI 按钮、技能图标的中文标签
**修复**：prompt 模板里同时强调 "简体中文" 和 negative "禁止繁体 / traditional chinese characters"
**已落地**：`prompts/templates/_shared.yaml` `ui_button.yaml` `ui_icon_skill.yaml`

### 1.8 GPT Image 不擅长传统 RPG 精灵图

GPT Image 2 的强项是**电影级单张大图**（立绘/海报/场景），弱项是**多帧、低分辨率、统一规格的 sprite**。
回合制 RPG 应该用 **battler（战斗大立绘）** 而不是传统 sprite。

### 1.9 DMXAPI 实测 gpt-image-2 单图成本 ¥0.13（不是 ¥1）

2026-04-27 一致性测试实测：1024×1024 medium quality，**实际单张 ¥0.131**，
不是定价页粗看的 ¥1+/张。原因：image-2 是 token 计费（input ¥24.82/M + output ¥148.92/M），
medium 1024² 实际只用 ~450 input + ~805 output tokens。

**整套 RPG 资源（700 张）成本估从 ¥700 下降到 ~¥100**，AI 出图方案经济性远超预期。
脚本默认估值偏高是好事（保守预算），但要让 `cost_from_usage()` 正确读 usage 字段才能算准实际成本。

### 1.10 DMXAPI 后端是 Azure OpenAI，moderation 默认严

DMXAPI 中转的 gpt-image 系列实际走 Azure OpenAI，而不是 OpenAI 官方端点。
体现：错误信息里有 `Azure support ticket`、`rix_api_error`、`moderation_blocked`。

放宽方法：通过 `extra_body={"moderation": "low"}` 透传给 DMXAPI（其文档支持此参数）。
但即使 `low`，仍会拦截较强的暴力/血腥/版权词。

### 1.11 武侠中文 prompt 的 Azure moderation 雷区

实测以下组合**会触发 moderation_blocked**（即使 `moderation: low`）：

- 直接写艺术家或 IP 名："马荣成"、"《风云》" → 用风格特征替代（"中国港式漫画"）
- 极端肢体词："畸形手指"、"多余四肢" → 整段从 `_shared.yaml` 的 negative 里删除
- 强暴力倾向："杀意"、"绝世好剑" → 软化为"气势"、"长剑"
- 血腥联想："血红"、"暗红内衬" → 换"橙红"、"深紫"

**经验法则**：写中文武侠 prompt 时把"负面/血腥/IP 名"全部脱敏，依靠"画面要求"段的正面描述去引导，
比依赖 `negative` 词更稳。

### 1.12 OpenAI SDK 异常优先级：BadRequestError 必须放在 APIError 前

`BadRequestError` 是 `APIError` 的子类。Python 异常匹配是顺序短路，写成：

```python
except (RateLimitError, APIError):  # ← BadRequestError 会先被这里吃掉
    重试
except BadRequestError:              # ← 永远不会执行
    不重试
```

会导致 **moderation_blocked 等"永不可重试"错误也被当限流重试 3 次**，浪费时间和 token。

修复：调换顺序，`BadRequestError` 在前，`APIError` 在后。

### 1.13 cost_from_usage 必须容忍 None 字段

DMXAPI 返回的 usage JSON 里某些字段值是 `None`（不是 0）：

```json
"input_tokens_details": {
  "image_tokens": null,         // ← None
  "text_tokens": 450,
  "cached_tokens_details": {}
},
"output_tokens_details": null,  // ← None（整段是 null）
```

直接 `dict.get("image_tokens", 0)` 会返回 `None`（默认值仅在 key 缺失时生效），
后续 `None * 24.82` 抛 `TypeError: unsupported operand type(s) for *: 'NoneType' and 'float'`，
让脚本进重试循环、再次扣费、再次崩。

修复：所有 token 字段都加 `or 0` 兜底。

```python
text_in = details.get("text_tokens") or 0
image_in = details.get("image_tokens") or 0
image_out = usage_dict.get("output_tokens") or 0
```

### 1.14 DMXAPI 并发 ≥ 4 触发隐性 IP 风控（5-10 分钟）

并发 4 跑 7 张图后，**之后 5-10 分钟内所有连接 RST**：
- curl 报 `schannel: SEC_E_INVALID_TOKEN`（TLS 握手被服务端关）
- OpenAI SDK 报 `APIConnectionError: Connection error.`
- 但 ping 和 443 端口都正常，区分点是"应用层连接立即关闭"

**结论**：`GEN_CONCURRENCY ≤ 2`，最稳是 1。
如果触发了，等 10 分钟再试，期间可继续做其他工作（写报告/读图等）。

### 1.15 纯 prompt 文本锚定足够保持角色一致性

实测：在**不依赖 reference image** 的情况下，gpt-image-2 仅靠 character_appearance 文本描述，
就能让同一角色在 2-3 张不同姿态的图里保持脸型/服装/发型/腰带高度一致（⭐⭐⭐⭐⭐）。
gpt-image-1.5 也行但略差（⭐⭐⭐⭐）。

**项目意义**：
- Style Bible（reference image）从"必须前置"降级为"锦上添花"
- 可以**先批量出 sprite 表情/动作变体验证一致性**，跑得不满意再回头做 Style Bible
- 实测见 `docs/consistency-test-report.md`

---

## 2. PowerShell / Windows 环境踩坑

### 2.1 中文文件名导致 PowerShell ItemNotFoundException

**症状**：`dir /a` 不工作，编码错乱

**修复**：
```powershell
Get-ChildItem -Force                    # 替代 dir /a
Copy-Item "中文.png" "english.png"      # 用引号包裹中文路径
```

### 2.2 Python 脚本 UnicodeEncodeError（PowerShell 输出）

**症状**：`rich` 库或 emoji 在 PS 控制台报 `UnicodeEncodeError`

**修复**：脚本顶部加：
```python
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
```
另：避免 emoji，改纯文本（`[OK]` `[FAIL]`）

### 2.3 git commit -m 多行 heredoc 在 PowerShell 失败

**修复**：写到临时文件再 `git commit -F tmp.txt`

### 2.4 pip install 失败：requirements.txt 中文注释

**修复**：requirements.txt 全部用英文注释

---

## 3. Godot 4 项目搭建

### 3.0.1 对话选项里的调查 ID 也必须做静态校验（2026-08-06）

只校验 `DialogNode.add_evidence` 等节点字段不够。调查分支通常把 `add_evidence`、`add_testimonies`、关系变化和办事方式写在 `choices` 字典里；若 ID 拼错，Godot 仍能解析资源，但运行时选择后只会静默失败。`validate_chapters_1_4_flow.gd` 现已扫描选项内的证物/证词 ID，重要章节还应增加专用语义测试，检查分支数量、持久状态与汇合节点。

### 3.0 可行走地图出口必须按角色半径验收（2026-07-20）

只验证出口中心点没有落在碰撞矩形内是不够的：出口附近若只留一条很窄的缝，角色的实际 CollisionShape 仍无法进入。新可行走场景至少要验证：

- 建筑屋顶、山体、密林、围栏使用完整碰撞，而不是只挡门面。
- 出口中心和出口区域不与障碍重叠，且出口外侧的视觉道路与碰撞缺口一致。
- BFS 验证时将所有碰撞矩形按角色半径外扩；从 `player_spawn` 到每个出口均可达。

脚本：`game/test/validate_first_two_walkability.gd`。首例问题是主街出口中心与右侧竹林碰撞重叠；另一个问题是新手关后屋和铁匠铺之间的通道过窄。

补充：`CharacterBody2D` 和运行时创建的 `StaticBody2D` 不应依赖默认 collision layer/mask。玩家必须显式 `collision_mask = 1`，障碍必须显式 `collision_layer = 1`，否则数据测试即使通过，运行时仍可能穿过建筑或岩壁。

### 3.1 .tscn / project.godot 必备格式

`project.godot` 顶部必须 `config_version=5`（Godot 4.x）。  
`.tscn` 顶部必须 `format=3`。  
不写 UID 也能跑，Godot 启动时会补。

### 3.2 unique_name_in_owner 配 % 引用

子节点设 `unique_name_in_owner = true` 后，父脚本里可以用 `%NodeName` 直接引用：
```gdscript
@onready var btn_attack: Button = %BtnAttack
```
比 `$ButtonPanel/Vbox/BtnAttack` 路径硬编码稳得多——节点重排不会断引用。

### 3.3 autoload 和 class_name 的初始化顺序

autoload 的 `_ready()` 里直接用 `CharacterStats.new()`（class_name 资源类）OK，
因为 `class_name` 在 Godot 启动早期就被注册到全局 ClassDB。

### 3.4 TextureRect 拉伸适配背景

```gdscript
expand_mode = 1   # IGNORE_SIZE，强制按容器尺寸缩放
stretch_mode = 6  # KEEP_ASPECT_COVERED，保持比例填满（裁剪超出部分）
```

### 3.5 Godot 4 内置全局函数

- `randf_range(0.8, 1.2)` 浮点
- `randi_range(0, 20)` 整数  
- `await get_tree().create_timer(0.7).timeout` 等待
- `get_tree().change_scene_to_file("res://...")` 切场景

---

## 4. 部署 / Git 操作

### 4.1 远程仓库

GitHub: `https://github.com/rajqiu2022/cw_rpg`

### 4.2 大文件 PNG 应走 LFS

> 当前还没启用，资产数量上 50 张时记得 `git lfs install` + `git lfs track "*.png"`。

### 4.3 推荐 commit 节点

| 节点 | 内容 |
|---|---|
| AI 资产管线骨架 | scripts/ + prompts/ + docs/ |
| Godot 项目骨架 | game/ 整个目录 |
| 每次产出 ≥ 5 张新资产 | 单独 commit |

---

## 5. 项目结构关键路径速查

```
f:\Code\RPG_GAME\
├── game\                ← Godot 项目（双击 project.godot 打开）
├── scripts\             ← Python AI 资产管线
├── assets\
│   ├── _style_bible\    ← 风格圣经原图（保留中文/原始名）
│   ├── raw\             ← AI 出图原图
│   └── processed\       ← rembg 抠图后
├── images\              ← Lovart 网页版下载的图（中文名）
├── prompts\templates\   ← 11 个 YAML 模板
├── docs\
│   ├── tech-selection.md
│   ├── art-pipeline.md
│   ├── budget.md
│   ├── dmxapi-setup.md
│   ├── style-bible-prompts.md
│   └── experience-log.md  ← 本文件
└── .env                 ← API Key（已 gitignore）
```

---

## 6. 下一步路线图（v0.2.0 — MVP 第一章）

详见 `docs/design-mvp-chapter1.md`，7 个 milestone 推进：

```
M1 数据驱动重构  ──→ M2 探索场景+对话  ──→ M3 任务系统
M4 多场景+商店    ──→ M5 背包/装备 UI   ──→ M6 章末 Boss+结算
M7 5 槽存档
```

每个 M 完成都跟一份验收清单（如 `docs/mvp-m1-checklist.md`），用户 F5 跑一遍点完所有 ✓ 才进下一个 M。

---

## 7. v0.2.0-M1 阶段经验记录（2026-04-27）

### 7.1 Godot 4 类型化数组在 .tres 里的写法

**坑**：直接写 `drop_random = [{...}]` 给类型化字段 `Array[Dictionary]` 赋值，Godot 4 加载时会报 type mismatch 警告，运行时字段可能为空。

**修复**：必须显式包装类型构造器：
```
drop_random = Array[Dictionary]([{ "item_id": "...", "chance": 0.5 }])
skill_ids = Array[StringName]([&"basic_attack", &"palm_strike"])
drop_items = Array[StringName]([])         # 空数组也得包
```

`StringName` 字面量用 `&"name"` 前缀（`@""` 是 unique node path，不通用）。

### 7.2 typed array 字段的 GDScript 赋值

**坑**：`stats.skills = [&"a", &"b"]` 给 `Array[StringName]` 字段赋 untyped array literal 在 Godot 4 会触发 implicit conversion warning。

**修复**：先建好类型化局部变量再赋：
```gdscript
var skill_ids: Array[StringName] = [&"basic_attack", &"palm_strike"]
stats.skills = skill_ids
party = [stats] as Array[CharacterStats]    # 或用 as 强制 cast
```

### 7.3 函数命名要避开 Godot 内置方法

**坑**：在 `DialogScript`（继承 Resource）里写 `func get_node(id)` 起初不报错，但若未来改继承 Node 就立即与 `Node.get_node()` 冲突；同理 `Inventory.has()` 与 Dictionary/Array 内置 `has` 在某些上下文有歧义。

**修复**：用更具体的方法名：
- `DialogScript.get_node()` → `find_node_by_id()`
- `Inventory.has()` → `has_item()`

通用规则：autoload / Resource 子类的公开方法**避开** `get_node` / `has` / `clear` / `add_child` 等节点/容器内置名。

### 7.4 全局信号枢纽 EventBus 模式

**架构选择**：所有"游戏事件"统一从 `EventBus` 发出（`enemy_defeated` / `item_picked_up` / `scene_entered` 等），任务/成就/统计系统都订阅 EventBus 而不是直接跨模块连接信号。

**好处**：
- 任务系统不需要知道谁触发了"杀敌"——只看 `enemy_defeated.emit(id)`
- 战斗/场景代码不需要 import 任务系统
- 加新订阅者（成就/统计/录像）零侵入

**autoload 顺序**：`EventBus` 必须排在所有依赖它的 autoload **之前**，因为 GameState/Inventory 在 `_ready()` 里就可能 `EventBus.xxx.emit()`。

```
EventBus → GameState → Inventory → SceneRouter → SaveManager
```

### 7.5 装备加成不能写进 CharacterStats.attack 字段

**坑**：很容易把"装备 +5 攻"直接累加进 `_player.attack`，但脱装备时复原会算错（已经升级过的话）。

**正确做法**：`CharacterStats.attack` 永远只代表"裸值"，装备加成在战斗运行时即查即算：

```gdscript
func _player_effective_attack() -> int:
    return _player.attack + Inventory.get_atk_bonus()
```

`Inventory.get_atk_bonus()` 遍历当前 equipped_weapon / equipped_armor 求和。脱装备只需 `Inventory.unequip(slot)`，不动 stats 字段。

### 7.6 .tres 单文件多 Resource 引用

`@export var on_enter_dialog: DialogScript = null` 这种 Resource 字段，在 .tres 编辑器里可以"内嵌"或"引用外部 .tres"。

**约定**：`SceneScript` 的对话引用统一用外部 .tres（`res://data/dialogs/<id>.tres`），便于：
- 单独编辑对话不动场景
- 多个场景复用同一段对话
- diff 友好（一个文件一个改动）

---

## 8. v0.2.0-M2 阶段经验记录（2026-04-26）

### 8.1 DialogNode 拆"附带效果"和"结束动作"

**坑**：M2.0 之前，`DialogNode.on_end` 一个字段既要表达"给玩家东西"，又要表达"接下来跳哪"。结果同一节点 *既给金币又跳战斗* 写不出来——只能拆成两个 node。

**修复**：把语义分开：
- `give_items` / `give_gold` / `set_flags` / `accept_quest` / `complete_quest`：**节点结束时执行的副作用**，可叠加多个
- `on_end`：**唯一一条**导航指令（`next:id` / `battle:id` / `scene:id` / `end`）

DialogPlayer 推进节点时先 `_apply_node_side_effects(node)`，再 `_resolve_action(on_end)`。

通用经验：**任何"动作字符串"字段，凡涉及副作用 + 流程控制都该拆开**，否则后期组合爆炸。

### 8.2 SceneRouter 作为"动作字符串解析中枢"

**架构**：M2 把"动作字符串解析"集中到 `SceneRouter.resolve_action(s)`，DialogPlayer / FieldController / 未来的 QuestManager 都直接调用。

支持语法（详见 `scene_router.gd` 文件头）：
```
dialog:<id>            打开对话
battle:<id>            进战斗（自动记 _current_field_id 作为 return_scene）
scene:<id>             跳探索场景
give_item:<id>:<n>     发物品
give_gold:<n>          发金币
set_flag:<key>:<v>     置 flag（v=true/false/数字/字符串自动判类型）
accept_quest:<id>      接任务
complete_quest:<id>    完成任务
open_inventory         打开背包（占位）
end / 空                 不做事
```

**好处**：DialogNode/SceneScript .tres 里只写字符串，不写脚本；新增动作只改 SceneRouter 一处。

### 8.3 战斗胜利自动写入 `defeated_<enemy_id>` flag

**痛点**：M2 场景里"打过的尸体不能再点"是高频需求。如果让每段对话手动 `set_flag:defeated_xxx:true`，容易漏。

**做法**：`BattleController._end_battle(true)` 里直接：
```gdscript
var flag_key := "defeated_%s" % String(_enemy_def.enemy_id)
GameState.flags[flag_key] = true
EventBus.flag_set.emit(StringName(flag_key), true)
```

**约定**：所有打过的敌人都自动记 flag，hotspot 用 `hide_flag = "defeated_<enemy_id>"` 隐藏即可。多次刷怪场景用别的字段（M3+ 再加 `kill_count` 字典）。

### 8.4 `start_battle` → `go_victory` → `go_field` 闭环要带 `return_scene`

**陷阱**：玩家在 field 里点战斗，胜利后要回**原 field**，不能弹主菜单。

**实现链**：
1. `SceneRouter.start_battle(id, return_scene_id = "")` 默认用 `_current_field_id`
2. payload 存 `{enemy_id, return_scene}`
3. `go_victory()` 把 `return_scene` 转写到 `_result_payload`
4. `result_victory.gd` 检查 `return_scene` 非空 → `go_field(return_scene)`，否则 `go_main_menu()`

**未来扩展**：败北也应支持 `return_scene`（M6 章末 Boss 输了走"客栈醒来"路径）。

### 8.5 FieldController 在 `flag_set` / `dialog_ended` 时立即重刷热点

**为什么**：玩家点对话 → 对话副作用改了 flag → require/hide 立即生效。如果只在进场 spawn 一次，必须切场景才更新，体验差。

**做法**：`FieldController._ready()` 同时 connect：
- `EventBus.flag_set` → `_spawn_hotspots(_current_scene.hotspots)`
- `EventBus.dialog_ended` → 同上（兜底，对话改了多个 flag 时只刷一次）

**性能**：M2 阶段每场景 ≤ 6 个 hotspot，重 spawn 完全够用；后续场景元素多了再做 diff 增量更新。

### 8.6 .tres 内嵌 `Array[Resource]` 子资源的写法

**做法**：DialogScript 的 `nodes: Array[DialogNode]` 字段，把每个 DialogNode 写成 sub_resource 块，最后用：
```
nodes = Array[Resource]([SubResource("node_a"), SubResource("node_b")])
```

注意：
- 数组类型用 `Array[Resource]` 而**不是** `Array[DialogNode]`——`DialogNode` 是脚本里的 `class_name`，.tres 文本格式里 Godot 4 不认这种自定义类型名
- 每个 sub_resource 头要写 `script = ExtResource("2_dnode")` 显式绑脚本，否则 load 出来 type 是 Resource 而不是 DialogNode

### 8.7 Godot 4 Button 字号不能直接赋字段

**坑**：写 `btn.theme_override_font_sizes_font_size = 18` 不报错但**不生效**。

**修复**：用方法 API：
```gdscript
btn.add_theme_font_size_override("font_size", 18)
```

通用：theme override 字段在 GDScript 里只能用 `add_theme_*_override(name, value)` / `get_theme_*_override(name)` 系列，不能当成属性赋值。

### 8.8 M2 完整闭环测试路径（可复用）

1. 主菜单「开始新游戏」
2. 进官道 → 看进场对话
3. 点 `查看石碑` → 看石碑对话 → 自动结束
4. 点 `路边尸体` → 看尸体对话 → 自动 `battle:thug_lone`
5. 战斗胜利 → 「继续」回到官道
6. 验证：尸体按钮消失，新出现"继续前行"按钮
7. 点「继续前行」→ 看战后剧情 → 拿到地图、麻衣、+8 金
8. 在 Godot Remote 调试器里检查 `Inventory.slots` / `GameState.flags`

任意一步断了都先看 `EventBus` 是否 emit 了对应信号，再看 `SceneRouter.resolve_action` 是否收到正确 action 字符串。

---

## 9. v0.2.0-M3 阶段经验记录（2026-04-26）

### 9.1 Quest source-of-truth：禁止外部 emit `EventBus.quest_accepted`

**反模式（M2 临时代码）**：DialogPlayer 在节点副作用里直接 `EventBus.quest_accepted.emit(qid)`，让"未来的 QuestManager"订阅。

**坑**：QuestManager 一旦在 accept(qid) 内部也 emit `EventBus.quest_accepted`，外部触发 + 内部广播 = **双重事件 + 重入风险**。

**正确**：QuestManager 是任务状态的唯一 source of truth：
- 外部"想接受任务" → **直接调** `QuestManager.accept(qid)`（DialogPlayer / SceneRouter / 未来 NPC 脚本都这样）
- QuestManager 内部 accept/complete 时**统一负责** emit `EventBus.quest_accepted` / `quest_completed` 给 UI / 成就系统等订阅者
- QuestManager 自己**不订阅** `quest_accepted` / `quest_completed`，只订阅"事件类信号"（`enemy_defeated` / `scene_entered` / `flag_set` …）

通用经验：**有"状态机"语义的子系统，状态变更命令走调用，状态变更通知走信号**——不要混一起。

### 9.2 Trigger 字符串语法 ≠ Action 字符串语法

虽然语法很像，但语义完全不同：

| 用途 | 写在哪 | 谁解析 | 例子 |
|---|---|---|---|
| **Action**（命令）| DialogNode.on_end / SceneScript.hotspots | `SceneRouter.resolve_action` | `battle:thug_lone` = 启动战斗 |
| **Trigger**（事件匹配）| QuestDef.completion_triggers | `QuestManager._check_match` | `enemy_defeated:thug_lone` = 监听敌人被击败信号 |

**容易混淆**：写 quest 时手滑写成 `battle:thug_lone`（动作）当 trigger，永远不会触发。

约定：trigger 字符串前缀必须是 EventBus 信号名（`enemy_defeated` / `scene_entered` / `item_picked_up` / `flag_set` / `npc_talked_to`）。

### 9.3 接受任务时立即检查"已满足"

**场景**：玩家先打 boss，再回村触发 NPC 对话才接到"击败 boss"任务——这种边界情况下任务永远完成不了，因为事件已经过去。

**修复**：`QuestManager.accept(qid)` 末尾调 `_check_all_active()`，对 `flag_set` / `defeated_<id>` 类 trigger 做"回看历史"判定（依赖 GameState.flags 里有持久化的状态）。

纯事件型 trigger（`item_picked_up` / `npc_talked_to` 等历史不持久化的）则不会回看，必须保证设计上"先接任务再触发事件"。

### 9.4 SaveManager schema 升版要约定 version 字段

M3 加 `quests` 和 `current_field` 字段时把 `version: 1` 升成 `version: 2`。

**经验**：每次改 save 数据结构都升 version，后续 `load_from_slot` 可以做向后兼容（`if version < 2: ...`）。本期没做兼容（玩家手动删存档），但 version 字段保住了升级窗口。

### 9.5 RichTextLabel 多行任务列表用 `bbcode_enabled = true`

任务面板用 RichTextLabel + bbcode 写：
```gdscript
"%s[b]%s[/b]\n  %s" % [prefix, q.title, q.desc_in_progress]
```

注意：
- `bbcode_enabled = true` 必须在 .tscn 里设，运行时 set 太晚
- `fit_content = true` 让高度自动撑开（替代手动改 size）
- `scroll_active = false` 否则少量内容也出现滚动条
- `theme_override_font_sizes/normal_font_size`（不是 `font_size`）—— RichTextLabel 的字号 override 名字与 Label 不同！

### 9.6 autoload 顺序：QuestManager 在 SceneRouter 后、DialogPlayer 前

```
EventBus → GameState → Inventory → SceneRouter → QuestManager → DialogPlayer → SaveManager
```

理由：
- DialogPlayer._apply_node_side_effects 调 `QuestManager.accept` → QuestManager 必须先 ready
- SceneRouter.resolve_action 也调 QuestManager → SceneRouter 不在 _ready 里调，但保险起见 QuestManager 排在它后面
- SaveManager 调 QuestManager.to_dict / from_dict → 必须最后

实操：autoload _ready 顺序 = project.godot `[autoload]` 段从上到下。出错时先看这个段。

### 9.7 任务奖励发放走 GameState/Inventory，不绕开

**坑**：QuestManager 自己写 `GameState.gold += def.reward_gold` 不 emit `gold_changed`，HUD 不会刷新。

**修复**：必须走 `GameState.add_gold(n)` / `Inventory.add_item(id, n)` / `GameState.player.gain_exp(n)`，让信号链完整传播到 UI。

通用规则：**任何修改 autoload 数据的地方都用 autoload 自己的方法**，不要绕过去直接改字段。

---

## 10. v0.2.0-M4 阶段经验记录（2026-04-27）

### 10.1 SceneScript hotspot 用 require + hide flag 组合实现状态分支

需求：**同一个 NPC 按状态切对话**（哭泣女子：未接 → 含选项；已接未完成 → 哽咽；已完成 → 隐藏）。

**做法**：在 `hotspots[]` 里写多个 **同名 + 同坐标** 的 entry，靠 `require_flag` / `hide_flag` 互斥。`FieldController._spawn_hotspots` 已支持二者并存判定（同时满足 require + 不满足 hide 才显示），无需改代码。

```gdscript
# ch1_s2_qingfeng.tres 节选
{ "label": "哭泣女子", ..., "action": "dialog:ch1_s2_crying_woman",
  "hide_flag": "accepted_rescue_husband" },     # 未接受时显示
{ "label": "哭泣女子", ..., "action": "dialog:ch1_s2_crying_woman_waiting",
  "require_flag": "accepted_rescue_husband",
  "hide_flag": "rescued_husband" },             # 已接受未完成
# 完成（rescued_husband=true）则两者都不显示 → NPC 自动消失
```

替代方案（更复杂）：在对话脚本第一节加 choices/branch 判 flag。**hotspot 分支更解耦**：UI 层可视、对话脚本不污染 if 逻辑。

### 10.2 DialogNode：节点级 `set_flags`（数组）vs 选项级 `set_flag`（单 dict）

**Schema 不对称，写对话时极易混**：

| 字段 | 类型 | 格式 | 触发时机 |
|---|---|---|---|
| `DialogNode.set_flags` | `Array[Dictionary]` | `[{"key": "k", "value": v}, ...]` | 节点无 choices 走"继续"时 |
| `DialogNode.choices[i].set_flag` | `Dictionary`（单层） | `{"k1": v1, "k2": v2}` | 玩家点该选项时 |

`dialog_player.gd` 第 75-79 行直接遍历 `flag_dict.keys()`，所以选项 set_flag 是 **flag_name → value** 字典；节点 set_flags 走 `entry.get("key")` / `entry.get("value")`。

写对话切记：**"我帮你"选项加 flag 用 `set_flag: {accepted_rescue_husband: true}` 不能写成 `[{key: ..., value: ...}]`**。

### 10.3 进商店不污染 `_current_field_id`，关闭时直接复用

`SceneRouter.go_shop()` **故意不修改** `_current_field_id`（只改 `_shop_payload`）。这样 `shop_ui.gd` 关闭按钮一行就能回原 field：

```gdscript
SceneRouter.go_field(SceneRouter.get_current_field_id())
```

代价：商店本身没法当独立场景做 save（M4 范围内不需要）。如果以后要存档"在商店里"，再扩 _current_view_kind。

### 10.4 hotspot action 链式效果一律放对话节点里

需求："旧木箱"点一下就给铁剑 + 隐藏自身。

**坑**：`hotspot.action` 只解析一个 SceneRouter action，不能链 `give_item:... + set_flag:...`。

**做法**：hotspot.action = `dialog:<id>`，对话节点写 `give_items + set_flags`（同时给物 + 置 flag）。`DialogPlayer._apply_node_side_effects` 一次性执行。

```
ch1_s3_box_iron_sword.tres node_a:
  give_items = [{"id": "iron_sword", "count": 1}]
  set_flags = [{"key": "looted_west_ruin_box", "value": true}]
  on_end = "next:b"
```

通用模式：**hotspot = 触发器，对话节点 = 副作用容器**。

### 10.5 Item.sell_price × ShopDef.sell_back_ratio 是"再次折扣"

字段语义：

- `Item.buy_price` = 玩家**买入价**（店家挂牌）
- `Item.sell_price` = 店家**收购全价**（市场参考价）
- `ShopDef.sell_back_ratio` (0~1) = 实际收购折扣（默认 0.5）

最终 `玩家卖出实收 = floor(item.sell_price × shop.sell_back_ratio)`。

**易错点**：把 sell_price 直接当玩家实拿（不乘 ratio），导致玩家卖物收入翻倍。

### 10.6 `choices` 非空时显式 `Array[Dictionary]([...])` 标注

空数组 `choices = []` Godot 4 自动推断；**非空** 数组建议跟 `nodes`/`set_flags` 一样标显式类型：

```
choices = Array[Dictionary]([
    {"text": "...", "next": "...", "set_flag": {"k": v}}
])
```

否则 Godot 4 偶发"Array of inferred type, expected Array[Dictionary]"warning。

### 10.7 卖装备前必须先 unequip

`Inventory.equipped_weapon` 是直接持有 Equipment Resource 实例的引用，与 `slots` 解耦。所以 `remove_item` 不会自动 `unequip`，会留下"幽灵装备"——卖完铁剑但 atk_bonus 仍 +5。

修复：商店 `_on_sell` 之前判断如果是已穿戴装备先 `Inventory.unequip(slot)`。

### 10.8 M4 完整闭环测试路径

`docs/mvp-m4-checklist.md` §0-§9。关键节点：

1. 进官道 → 接 q1 → 战胜 thug → 进对话 → **走到 ch1_road_after_thug node_c 自动 `scene:ch1_s2_qingfeng`** → 进场景 2
2. 进场景 2 → q2 trigger `scene_entered:ch1_s2_qingfeng` 立即匹配 → q2 ✓
3. 客栈老板对话 → set_flag `rumour_west_ruin` → "前往城西"出口立即出现（FieldController 监听 flag_set 重渲染热点）
4. 神秘商人 → `shop:qingfeng_merchant` → SceneRouter.go_shop → shop.tscn → 关闭回 ch1_s2_qingfeng
5. 哭泣女子选"我帮你" → set_flag accepted_rescue_husband + accept_quest q3 → 哭泣女子 hotspot 切到 waiting 版
6. 进场景 3 → 拾铁剑 → 救丈夫（set_flag rescued_husband → q3 自动 ✓ + 50 gold）→ 大门 → boss 战斗 → 胜利回主菜单

---

## 11. 世界观 / 命名

### 11.1 命名禁区清单（项目级）

> 用户在 review world-bible.md v0.3 时明确删除某些意象。每次踩到记录在此 + 同步到 `docs/world-bible.md §5.7`。后续生成新武功 / 怪物 / 道具 / 美术 prompt 关键词都要查这个表回避。

| 日期 | 禁区 | 触发场景 | 替代思路 |
|---|---|---|---|
| 2026-04-27 | 蜘蛛 / 蛛丝 / 蛛网 | 戚云笙武功原叫"千机蛛丝"，被否 | 用"针 / 镖 / 链 / 索 / 缕"。已改为"离魂针" |

**自检流程**（每次新增内容前 30 秒自查）：

1. 武功名 / 怪物名 / 道具名 / 美术 prompt 关键词
2. 通读一遍是否含禁区表中任何字眼
3. 含 → 立即换；不含 → 通过

> 这个表会增长，所以每次新增意象时也建议反向问用户一次"这个意象有忌讳吗"。

---

## 12. Prompt 模板防腐 / 硬编码污染

### 12.1 模板硬编码"角色专属外貌"会污染所有任务（2026-04-27）

**踩坑**：v0.2 stage 2 跑批前 dry-run 发现，`prompts/templates/character_portrait_textonly.yaml` 里的"画面要求"段落硬编码了：

```yaml
- 五官比例固定：清瘦轮廓 / 眉目俊朗 / 神色沉稳   ← 步惊云特征
- 服装固定：黑色长袍 + 深紫色披风                ← 步惊云服装
- 色调统一：黑、深灰、深紫、银                   ← 步惊云配色
```

这是 v0.1 一致性测试期间为锁住步惊云写的"二次保险"，但当 task 切到冷孤云时，**模板硬编码会直接覆盖 task 自定义的外貌**。如果不 dry-run 验证就直接跑，6 张图全废、白花 ¥7-8。

**修复**：

```yaml
# 改前（v0.1）
- 五官比例固定：清瘦轮廓 / 眉目俊朗 / 神色沉稳
- 服装固定：黑色长袍 + 深紫色披风
- 色调统一：黑、深灰、深紫、银

# 改后（v0.2）
- 五官、发型、服装、配饰、体格、色调：严格遵循上方"外貌（每张图必须严格一致）"段所述，不可偏离
```

把这些"角色专属字段"改成"指向上方 identity_anchor 的引导句"，让 anchor 成为单一真相源。

**经验抽象**：

1. **模板 = 风格层 + 结构层，不应混入"角色身份层"**。角色身份只能由 task 注入的 `character_appearance` 控制。
2. **任何写在模板里的"硬编码细节"都是技术债**——只要主角换人就会污染。
3. **跑批前必须 dry-run 看 1 张实际渲染的 prompt**——这是真正的最后防线，比 yaml 校验、字段对齐这些都重要。读一眼实际拼接出的 prompt 才能发现"模板 vs task" 的语义冲突。

**关联技术债**：`prompts/templates/character_portrait.yaml`（带 reference image 的版本）也有同类问题：
- 引用 `assets/_style_bible/01_protagonist_full.png`（步惊云图）
- 写死"披风颜色与参考图一致"
- 但当前所有调用它的任务都 `skip:true`，故未阻塞 v0.2 stage 2

待 v0.2 主角参考图（`portrait_lengguyun_neutral`）跑通后，**用它替换 _style_bible/ 下的步惊云图**，并把模板里"披风"等专属字眼一起改成中性。

### 12.2 跑批前 dry-run 自检清单（2026-04-27 沉淀）

```
✅ 1. yaml 语法（python -c "yaml.safe_load(...)"）
✅ 2. tasks 数量 / priority 分布
✅ 3. ≥1 个任务的 .meta.json 实际 prompt 内容
✅ 4. 通读 prompt：有无前任 IP / 角色专属 / 旧风格残留
✅ 5. 反向词段是否含 negative 必备项
```

3-4 步必读 1 个完整渲染结果，不能跳。代价就是 1 个 dry-run 调用 ~1s 时间，回报是避免一整批白花钱。

### 12.3 DMXAPI 余额不足必须分类为 fatal（2026-04-27 stage 2 跑批）

**踩坑**：v0.2 stage 2 跑 6 立绘，前 3 张成功（lengguyun / xingfantian / shenbanzhan），第 4 张起触发：

```
PermissionDeniedError: Error code: 403
{"message":"用户额度不足, 剩余额度: $0.499336", "code":"insufficient_user_quota"}
```

`gen_assets.py` 的 `classify_error` 把这种错误归类为 `ERR_TRANSIENT`（默认未识别），导致：

- 主模型 gpt-image-2 重试 3/3 次（每次都失败 + 指数退避，浪费 ~30s/任务）
- 切 fallback gpt-image-1.5 又试 1 次（仍失败）
- **3 个失败任务 × 4 次无意义请求 = 12 次浪费的 API 调用**

虽然额度不足时被拒不扣费（成本无关），但浪费的是**时间**（多耗 ~3-5 分钟）和**信心**（看到一堆 retry 心累）。

**修复**：classify_error 顶部加余额识别，归类 `ERR_FATAL`：

```python
if (
    "insufficient_user_quota" in msg
    or "用户额度不足" in msg
    or "insufficient_quota" in msg
):
    return ERR_FATAL
```

**经验抽象**：

1. **永久错误必须显式识别为 fatal**：余额、密钥失效、账号封停、配额耗尽——这些不会自己恢复，重试和 fallback 都白费。
2. **看到 403 别条件反射重试**：403 ≠ 429（rate limit）。403 一般是权限/账号问题，重试无解。
3. **跑批后第一时间看 failed.log 错误码**：如果整批失败码同质（都是 403 / 都是 insufficient_quota），这是基础设施问题，不是 prompt 问题；先补血再重跑，别尝试改 prompt。

### 12.4 跑批前先查 DMXAPI 余额（建议加 ping_dmx 扩展）

**当前痛点**：DMXAPI 余额不会主动告知；只有触发不足时才在错误消息里露馅。

**改进方向（待补 todo）**：`scripts/ping_dmx.py` 调用余额查询接口（DMXAPI 应该有 `/v1/dashboard/billing/credit_grants` 类似 endpoint），跑批前先打印当前余额 + 估算本次跑批成本 + 是否够。

> **⏩ 已完成于 commit `ac2fded`**：DMXAPI 实际接口是 `GET /api/user/self`（不是 OpenAI 兼容的），需要 `system_token` + `user_id` 两个新认证字段（不同于 OpenAI 兼容的 sk- 密钥）。详见 §13.2。

**临时人工流程**：登录 DMXAPI 控制台首页，记下当前余额。按 ¥0.13-0.15/张（gpt-image-1.5 medium）估算这次需要的总额，余额至少 1.5 倍才放心跑批。

### 12.5 美术总基调：用户审美 vs prompt 写实（2026-04-27）

**用户拍板**：游戏整体偏鲜明光亮（参照 90 年代港漫《风云》、《天子传奇》等），仅特定阴暗场景才暗调。

**触发**：v0.2 stage 2 跑出 3 张立绘后，用户回看觉得人物 OK，但顺势提出风格调整。这种"做出第一波东西后，用户才能具象表达审美偏好"是常态——一开始问用户"你想要什么风格"，得到的答案永远是抽象的"武侠风、港漫风"；只有看到具体图后才能精准定位。

**修改面（一次性）**：

| 文件 | 改动 |
|---|---|
| `prompts/templates/_shared.yaml#style_anchor` | "苍凉壮阔"→"明亮通透、光影对比鲜明、阳光感强、色彩活力充沛"|
| `prompts/templates/_shared.yaml#negative` | 新增反向词："整体灰暗，雾蒙蒙，低饱和，沉郁压抑，黯淡无光，灰蒙蒙的色调"|
| `prompts/templates/scene_background_45deg.yaml` | "画面边缘可适度暗角"→"默认场景：明亮通透、阳光感强、暖色调主导（除非已声明为洞穴 / 夜战）"；删除 v0.1 残留的 isometric 参考图引用 |
| `prompts/tasks.yaml` 场景 task | 林西村主街 / 山道：升级描述为"明亮阳光"系；竹尾密林：保留暗调但明确"高饱和、不灰暗、绝非整体灰暗压抑" |
| `docs/world-bible.md §5.8` | 新增"美术总基调"项目级约定（跟 §5.7 命名禁区同级）|

**踩到的隐式陷阱**：

1. **"苍凉壮阔"是审美毒药**：这种文学化形容词容易让模型出图低饱和、灰蒙蒙。AI 出图 prompt 里要避开"苍凉、萧瑟、沉郁、苍茫、悠远"等词，改用具体的色彩 / 光感描述（"鲜红"、"橙红炉火"、"翠绿竹林"、"蔚蓝天空"）。
2. **暗调场景 ≠ 灰暗场景**：黄昏密林、夜战、洞穴这些**叙事上偏暗**的场景，仍要靠"高饱和 + 强对比"维持港漫风格，不能让模型理解成"低饱和+灰蒙蒙"。在 prompt 里明确加"**绝非整体灰暗压抑**"这种粗暴反向指令是有效的。
3. **negative 段是有效杠杆**：把"整体灰暗，雾蒙蒙，低饱和，沉郁压抑"加进 negative，比改正向描述更有效——AI 对 negative 的服从度更高。

**后续约定**：
- 任何场景 task 写 `time_of_day` / `weather` 时，默认 morning/noon + clear；用 dusk/night/overcast 必须在 scene_desc 里同步明确"高饱和"和"不要灰暗"。
- `world-bible.md §5.8` 是单一真相源，新风格调整都要回到这里更新。

### 12.6 隐藏 bug：getattr(dict, key) 永远拿不到值（2026-04-27）

`gen_assets.py` 第 586 行原写法：

```python
if out_png.exists() and not getattr(task, "_force", False):
```

`task` 是 dict，`getattr` 用于访问对象 attribute，对 dict 的 key 永远返回 default。结果：`--force` 参数完全无效，已存在的 png 永远 skip。

**修复**：`getattr(task, "_force", False)` → `task.get("_force", False)`

**经验**：dict 取值用 `.get()` / `.[ ]`，对象取属性用 `getattr` / `.x`。Python 这两个 API 容易眼瞎写错——尤其是当对象同时支持两种访问时（比如某些 ORM 模型）。**code review 时遇到 dict 看见 getattr 必停 0.5 秒检查**。

---

## 13. stage 2 完整批跑复盘（2026-04-27 22:17 ~ 23:30）

### 13.1 实测数据：9 任务 100% 成功，单图均价 ¥0.49

**任务清单**：6 张主线角色立绘（v0.3 阵营，character_portrait_textonly 模板）+ 3 张场景背景（45° 等距，scene_background_45deg 模板）。

| 阶段 | 时间 | 结果 |
|---|---|---|
| 第一波（充值前） | 22:09 ~ 22:13 | 3 张立绘成功（冷孤云 / 刑樊天 / 沈半盏），余额耗尽，3 张 fatal 失败 |
| 充值 + B2 跑批 | 23:17 ~ 23:30 | 9 任务全部处理：3 跳过 + 6 成功 + 0 失败 |

**第二波关键指标**：

| 指标 | 实测值 | 预估值 | 偏差 |
|---|---|---|---|
| 总耗时 | 757.5s（12'37") | ~10 min | 准 |
| 总花费 | ¥2.9337 | ~¥7.2（按 ¥1.2/张 × 6） | **超预期：仅花 41%** |
| 单图均价 | ¥0.489 | ¥1.20 | **比预估便宜 60%** |
| 成功率 | 100%（6/6） | ≥ 80% | 超预期 |
| 单张耗时 | 立绘 ~110s / 场景 ~150s | – | – |

**便宜的原因推测**：`gpt-image-2 medium` 实际消耗的 token 比 `gpt-image-1.5 medium` 低，DMXAPI 价格表（¥24.82 / ¥148.92 per M tokens）对 medium 质量产生约 ¥0.4-0.5/张实际成本。我们之前 ¥1.2/张的预估是**按 high 质量算的**，没区分质量档。

**结论**：M5-M7 阶段（约 30-50 张资产）总成本 ≈ **¥15-25**，比之前预估的 ¥36-60 大幅下调。

### 13.2 ping_dmx 实现：DMXAPI 余额查询接口非 OpenAI 标准

**接口确认（doc.dmxapi.cn/yuer.html）**：

```
GET https://www.dmxapi.cn/api/user/self
Headers:
  Authorization: <system_token>     ← 不是 sk-... API 密钥！
  Rix-Api-User: <user_id>
  Accept: application/json
Response:
  data.quota                        ← 整数，单位需 / 500000 得人民币
```

**关键认知陷阱**：DMXAPI 的"系统令牌"和"API 密钥（sk-...）"是**两个独立凭证**：

| 凭证 | 用途 | 入口 |
|---|---|---|
| **API 密钥** sk-... | OpenAI 兼容接口（图像、对话） | DMXAPI → 创建令牌 |
| **系统令牌** 32 字符 | DMXAPI 自有 API（余额、日志、统计） | DMXAPI → 个人设置 → 系统访问令牌 |
| **用户 ID** 数字 | 配合系统令牌使用 | DMXAPI → 个人设置 → 用户 ID |

我曾以为 sk- 密钥就能查余额，会节省一次配置步骤——错了。**这是中转商常见模式**：自有 API（订单 / 配额 / 日志）需要 system_token；OpenAI 兼容 API（业务调用）用 sk-。

**ping_dmx.py v0.2 设计**（commit `ac2fded`）：

- `query_balance()` 三档告警：< ¥0.5 critical / < ¥5 low / ≥ ¥5 ok
- 优雅降级：未配置 system_token 时跳过余额、仍执行 ping
- 余额接口走 DMXAPI 自有 API（不上游 OpenAI），**IP 风控期间仍能查**——这反而是个意外收获，下一次 IP 风控时可以先看余额避免误判
- 退出码 0 / 1 / 2 / 3 分别表示 ok / connection-fail / empty-data / quota-exhausted，方便上层脚本编排

### 13.3 ping 失败 ≠ 跑批失败：--skip-ping 反而稳

**反直觉现象**：22:57 / 23:06 两次 `python scripts/ping_dmx.py` 分别报 `APIConnectionError`（30s）和 `APITimeoutError`（90s = OpenAI SDK 默认 max_retries=2，30s × 3）；但 23:17 立刻用 `--skip-ping` 跑 9 任务批，**0 失败一次过**。

**可能解释**：

1. **ping 路径自身瞬时拥塞**：探活调用次数极低（一次一张图），渠道分配可能命中"冷"通道；批跑过程中 SDK 可能复用 connection pool 命中"热"通道。
2. **重试机制差异**：ping_dmx.py 简单调用没有 backoff/重试；gen_assets.py 内有 transient 类错误的指数退避，能扛过短暂抖动。
3. **DMXAPI 渠道队列动态变化**：1 分钟内的可用通道可能不一样。

**新流程建议**（写入工作流）：

| ping 结果 | 行动 |
|---|---|
| OK ✅ | 直接跑 |
| 1 次失败（transient） | 立刻试 `--skip-ping` 跑 1 个任务验证 |
| 连续 2 次失败（30 分钟内） | 等 30 分钟再试；或转 ChatGPT Plus 网页 |
| 余额 critical | 充值后再跑（不必 retry） |

**教训**：这次差点因为两次 ping 失败劝退用户改用 ChatGPT Plus 手贴 30 分钟，实际**直接 --skip-ping 12 分钟全搞定**，省了不少工。下次类似情况要更激进一点。

### 13.4 美术基调 v0.2 验证：场景"明亮 / 暗调特例"双轨制可行

stage 2 的 3 张场景是**v0.2 美术基调拍板后第一次实测**：

| 场景 | 设计意图 | prompt 关键词 | 验收 |
|---|---|---|---|
| 林西村主街 | 明亮鲜艳（默认） | morning + clear + 鲜艳明亮 + 阳光感 | 待用户审 |
| 林西村外山道 | 明亮鲜艳（默认） | morning + clear + 蓝天 + 翠绿竹林 | 待用户审 |
| 竹尾村外密林 | 暗调特例 | dusk + foggy + **高饱和、不灰暗** | 待用户审 |

如果 3 张场景都通过，说明**"_shared.yaml 全局明亮 + 单 task 暗调反向覆盖"** 双轨制可推广到 M5-M7 后续场景；如果竹尾密林仍偏灰暗压抑，则需要在场景任务级补更激进的反向词。

> 用户最终验收：**全部合格**（2026-04-27 23:37）。归档到 `assets/art_validation_v2/character_v2/` 和 `scene_v2/`。双轨制确认可行。

### 13.5 存档约定：通过的 PNG 必须从 raw/ 拷到 art_validation_v2/

**问题**：`assets/raw/` 在 `.gitignore` 里被排除（避免巨量草图入库），但 stage 2 的 6 张通过立绘 + 3 张场景默认输出到 `assets/raw/character/v2/` 和 `raw/scene/v2/`，**git 看不到**——意味着磁盘故障会丢这 ¥6.5 的成果。

**约定（沿用 stage 1 模式）**：

```
assets/
├── raw/                          # gitignore，工作区，gen_assets.py 默认输出
│   ├── character/v2/*.png        # 工作中 / 草稿 / 待审
│   └── scene/v2/*.png
└── art_validation_v2/            # 进 git，已通过的归档
    ├── npc/                      # stage 1 通过：5 NPC（commit 1559978）
    ├── character_v2/             # stage 2 通过：6 主线立绘
    └── scene_v2/                 # stage 2 通过：3 场景背景
```

**操作**：用户审阅通过 → `Copy-Item raw/.../X.png art_validation_v2/X_v2/` → `git add` 进归档 commit。**meta.json 不入库**（包含的是工作区状态，归档版本不需要追踪 prompt 漂移）。

**未来改进**：可以加个 `scripts/archive_passed.py`，参数 `--task <id>` 一键拷贝到归档区，并写一份 archive_log（哪张图哪天通过、谁审的）。当前 ≤ 10 张手工拷贝够用。

---

## 14. M5 背包 / 装备 UI 实现经验（2026-04-28）

### 14.1 Godot CLI 不一定在 PATH，自动验证要先定位可执行文件

**问题**：本机 PowerShell 执行 `godot --version` / `where.exe godot` 均失败，说明 Godot 编辑器可用不等于 CLI 已加入 PATH。

**经验**：后续要跑 `game/tests/*.gd` 自动校验时，先确认 Godot 可执行文件路径；如果没有 PATH，需让用户提供编辑器安装路径，或在项目脚本中配置 `GODOT_BIN`。否则只能用 `ReadLints` 做静态检查，不能声称 Godot headless 测试已通过。

建议命令：

```powershell
$env:GODOT_BIN="C:\path\to\Godot_v4.x-stable_win64.exe"
& $env:GODOT_BIN --headless --path game --script res://tests/test_inventory_m5.gd
```

### 14.2 GDScript 静态类型调用自定义 scene 方法要谨慎

**问题模式**：如果变量声明为 `Control`，但实际实例是挂了自定义脚本的 `inventory_panel.tscn`，直接调用 `.open()` / `.close()` 可能被静态检查认为 `Control` 没有这些方法。

**修复**：这类动态实例变量要么保持未显式收窄类型，要么用 `call("open")`，要么为面板脚本定义 `class_name` 后使用真实类型。

**经验**：Godot UI 场景脚本之间互调时，类型标注别为了"看起来严谨"而标到父类；父类没有的方法会让 IDE / linter 报错。

### 14.3 SceneRouter action 新增分支时必须补完整三件套

**问题**：启动 Godot 后报 `Parser Error: Function "go_shop()" not found in base self.`。根因是 `resolve_action("shop:<id>")` 已经接入了 `"shop"` 分支，`shop_ui.gd` 也调用 `SceneRouter.get_shop_payload()`，但 `scene_router.gd` 里只声明了 `_shop_payload`，漏了 `go_shop()` / `get_shop_payload()` 两个方法。

**修复**：在 `SceneRouter` 中补：

```gdscript
func go_shop(shop_id: StringName) -> void:
	_shop_payload = {"shop_id": shop_id}
	get_tree().change_scene_to_file(SCENE_SHOP)

func get_shop_payload() -> Dictionary:
	return _shop_payload
```

**经验**：以后给 `SceneRouter.resolve_action()` 新增动作时，必须同时检查：

1. `const SCENE_*` 或数据目录常量是否存在；
2. `go_*()` 是否存在；
3. `get_*_payload()` 是否存在（如果目标场景要读 payload）。

只补 action 分支不补跳转 API，会在 Godot 解析期直接炸，甚至进不了游戏。

### 14.4 仓库只有 `.import` 没有 PNG：主菜单 / 野外会像「没有 UI」

**现象**：能进游戏，但主菜单与野外几乎一片空或很「抽象」，热点按钮像飘在虚空里。

**根因**：`res://art/**/*.png` 未进仓库（常见：大图 gitignore / 未提交），只剩 Godot 生成的 `*.png.import`。`TextureRect.texture` 为空时，叠上半透明遮罩后对比度极差。

**修复策略**：

1. 场景里加 **FallbackBg**（纯色或渐变感的 ColorRect）垫底；
2. 代码里 `ResourceLoader.exists` 再 `load`，缺失则 `push_warning`；
3. 野外热点按钮加 **StyleBoxFlat** 半透明底，保证在纯色底上也能看见；
4. 底部加 **HintBar** 文案，告诉玩家「点按钮推进 + 快捷键」。

**长期**：把通过的背景 PNG 按 `art_validation_v2` 约定归档进 git，或导出 WebP 小体积进库。

---

## 15. 主角 Sprite 提示词：外部分享文结构 + 本项目画风（2026-04-28）

**来源**：微信文章 [游戏元素拆分 gpt-image2](https://mp.weixin.qq.com/s/eLTx7bCpckLHfefR2M9l4Q)（分段写「整体 / 部位清单 / 排版 / 反向」）。

**适配**：

- 原文偏 **像素拆件**；本项目 `style_anchor` 是 **港漫厚涂 2.5D**，新模板 `sprite_protagonist_idle` / `sprite_protagonist_parts_sheet` 写明非像素、并与 `_shared.yaml` 明亮基调一致。
- 拆件总图在 **1024×1024** 下部件不能贪多，否则易糊、粘连；拆件任务默认 **`skip: true`**，避免误跑批烧钱。
- **无参考图**：不写 `reference_images`，走 `generations`，与 `character_portrait_textonly` 同一策略。

**验证**：`python scripts/gen_assets.py --task sprite_lengguyun_idle_south --dry-run` 已通过。

**文档**：`docs/sprite-prompt-playbook.md`。

### 15.2 批量 sprite 帧时 DMXAPI 全链路 `APIConnectionError`（2026-04-28）

**现象**：同机此前单张 `sprite_lengguyun_idle_south` 可成功；同一晚对 9 个 `--task` 连续跑批时，`gpt-image-2` 与 fallback `gpt-image-1.5` 均报 `APIConnectionError: Connection error.`，无扣费。

**处理**：任务与模板已落库；网络恢复后**缩小批次**（1～2 张/次）或错峰重试；详见 `docs/sprite-prompt-playbook.md` §2.2。

**后续成功样本（2026-04-29）**：同一 9 任务在约 **18 分钟**后 **9/9 成功**，总花费 **¥1.2428**（`--skip-ping`），输出均在 `assets/raw/sprite/v2/`。

### 15.3 行走 4 帧帧间「换装」：纯文不足、须关键帧 + edits（2026-04-28）

**现象**：`walk_south_f01`～`f04` 各走独立 `generations` 时，衣裤肤色酒葫芦鞋子等跨帧不一致。

**原因**：模型无视觉记忆，仅靠 prompt「序列一致」不足以锁住细部。

**处理**：

1. `sprite_protagonist_walk.yaml` 增补 **外观硬锁定** 清单（色阶、葫芦釉色、靴型、肤色等），专用于 **f01** 锚帧。
2. 新增 `sprite_protagonist_walk_ref.yaml`：`reference_images` 指向已产出的 `sprite_lengguyun_walk_south_f01.png`，`tasks.yaml` 中 **f02～f04** 改用该模板，走 **`images.edit`**。
3. `gen_assets.py`：模板可设 `require_reference_images: true`，参考图缺失时 **报错**，禁止静默清空参考后退回纯文生成。

**操作**：重出行走时先跑（或保留满意）**f01**，再跑 f02～f04；批量时 **f01 必须排在 f02 前**。

### 15.4 主角 sprite 画幅改为 896×896（2026-04-28）

**动机**：游戏内 sprite 不需要 1024²；略小画幅省 token / 省时间，Godot 里再按目标格缩放即可。

**实现**：`sprite_protagonist_idle` / `idle_anim` / `walk` / `walk_ref` / `attack` / `parts_sheet` 的模板 `size` 与 prompt 内画幅说明统一为 **896×896**（满足 gpt-image-2 文档「总像素 ≥ 655360」约束；512² 过小不可用）。`gen_assets.py` 的 `PRICE_OPENAI_USD` 增加 `896x896` 粗估档位。

**注意**：行走链式参考仍读 `sprite_lengguyun_walk_south_f01.png`；**续帧输出尺寸须与模板一致**，故重出 f01 后 f02～f04 才会与参考同分辨率；跑批建议 **`GEN_CONCURRENCY=1`**。

### 15.5 Field sprite 镜头与 45° 场景解耦（2026-04-28）

**现象**：行走 4 帧一致性尚可，但观感像 **45° 等距地砖 RPG**，与当前 Field（`Sprite2D` + 立绘缩放 + `flip_h`）不一致。

**处理**：`sprite_protagonist_*` 模板与冷孤云相关 `facing` 文案改为 **正交侧向、略俯视、身体朝画幅左**（明确禁止 45° 等距地砖假三维）；`docs/sprite-prompt-playbook.md` v0.3 说明任务 id 中 `_south_` 仅为历史命名。场景背景仍可继续用 `scene_background_45deg` 等 **插画透视**，与角色小贴图镜头分开约定。

### 15.6 行走 f03 外衣偏浅（2026-04-29）

**现象**：链式 edits 后仍出现 **f03 袍色比其它帧浅**（交叉步、大块袍面易被模型整体提亮）。

**处理**：`sprite_protagonist_walk` / `walk_ref` 增补 **外衣明度与灰阶锁定**；`walk_ref` 增加可选变量 `color_stability_hint`，在 `sprite_lengguyun_walk_south_f03` 写入 **严禁整袍提浅** 的帧专用句；f02/f04 置 `color_stability_hint: ""` 占位。

### 15.7 行走像站桩 + 跨帧色差（2026-04-29）

**现象**：续帧颜色仍看得出差别；**脚步几乎不变**，不像走路。

**原因**：模板中「双脚落在同一水平线」易被模型理解成 **钉死脚位**；`leg_phase` 偏含蓄时 **edits** 为保脸会弱化下肢；色温未与明度一起锁。

**处理**：`walk` / `walk_ref` 改为强调 **水平地面上的前后错步与承重切换**、禁止站桩；`walk_ref` 写明 **须改变脚底落点**、允许小幅整体平移；补 **冷灰色相** 防偏褐偏紫；`tasks.yaml` 四帧 `leg_phase` 改为 **接触/过渡/镜像接触/回环** 的可读描述；禁忌加 **站桩行走**。

### 15.8 仅使用 gpt-image-2、禁用自动 fallback（2026-04-29）

**需求**：重跑时不要用 `gpt-image-1.5` 兜底。

**做法**：`gen_assets.py` 传 **`--fallback-model gpt-image-2`**（与主模型同名），则 `fallback_model != primary_model` 不成立，**不会**再切 1.5。已写入 `docs/sprite-prompt-playbook.md` 示例注释。

### 15.9 主角 sprite 全量重跑顺序（2026-04-29）

**需求**：参考老式武侠 RPG 侧向场景移动观感，完成冷孤云现有主角 sprite 批次。

**命令顺序**：先单独跑 `sprite_lengguyun_walk_south_f01`，再跑 idle / idle_anim / walk f02～f04 / attack，且设置 `GEN_CONCURRENCY=1` 与 `--fallback-model gpt-image-2`。这样 f02～f04 读到的是最新 f01 参考图，并且全程只用 `gpt-image-2`。

**结果**：10 张成功（walk f01 单张 + 其余 9 张），总花费约 **¥1.3869**，输出在 `assets/raw/sprite/v2/`。

### 15.10 参考传统武侠 sprite sheet 改成四向行走表（2026-04-30）

**反馈**：此前单帧图仍像缩小立绘，不像可播放的游戏 sprite；`idle_south` 等还可能出现头巾/额带这种明显错误。

**处理**：新增 `sprite_protagonist_walk_4dir_sheet.yaml` 与任务 `sprite_lengguyun_walk_4dir_sheet`（`sprite/v3`）。使用用户提供的传统武侠 sprite sheet 作为 **动作节奏/小人比例/四向排布参考**，但角色身份仍以冷孤云锚点为准；prompt 明确禁止头巾、额带、红头绳、蓝衣、文字标签。

**结果**：`gpt-image-2` 成功生成 1 张 **4 方向 × 4 帧** 行走表，花费约 **¥0.1762**，输出 `assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png`。后续应优先从这种 sheet 裁切/缩放，而不是继续用“单帧大立绘”做 sprite。

### 15.11 从四向行走 sheet 生成 GIF 预览（2026-04-30）

**做法**：把 `assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png` 按 4×4 网格裁切，生成单方向 GIF 与四方向同屏预览。

**输出**：`assets/previews/sprite/`

- `sprite_lengguyun_walk_down_4f.gif`
- `sprite_lengguyun_walk_left_4f.gif`
- `sprite_lengguyun_walk_right_4f.gif`
- `sprite_lengguyun_walk_up_4f.gif`
- `sprite_lengguyun_walk_4dir_4f_preview.gif`

**经验**：先用 GIF 看“是否像走路”，再决定是否扩到 8 帧；不要只看静态 sheet 判断动作连贯性。

### 15.12 单方向 8 帧右走 strip（2026-04-30）

**反馈**：4 帧行走跳帧，且原 sheet 单元格里角色中心/脚线不稳定；大部分帧都是跨开腿，缺少 passing / up 过程态。

**处理**：新增 `sprite_protagonist_walk_right_8f_strip.yaml` 与任务 `sprite_lengguyun_walk_right_8f_strip`（`sprite/v3`），输出 **1536×512 单行 8 帧**；prompt 强制 8 相位（contact/down/passing/up × 双腿）、同一脚底基线、同一格内身体中心、角色高度 110～140px，并继续禁止头巾/额带。

**结果**：`gpt-image-2` 成功生成 1 张右走 8 帧 strip，花费约 **¥0.2234**；输出 `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_strip.png`。预览 GIF：`assets/previews/sprite/sprite_lengguyun_walk_right_8f.gif` 与 `_raw.gif`。当前观感比 4 帧顺，但角色仍偏大，过渡帧仍需继续压小人与均匀步态。

### 15.13 GIF 跳帧：固定锚点导出而不是逐帧白边裁切（2026-04-30）

**现象**：预览 GIF 中每帧画布/角色位置不一致，动画看起来跳；等分裁切还会因为模型未严格对齐格子而切到衣摆或剑。

**处理**：新增 `scripts/build_sprite_preview.py`。流程：先可选按非白像素列分割角色块（`--segment-columns`），再将每帧放入统一画布并以 **底部居中** 为锚点；需要检查原始比例时用 `--preserve-scale`，需要游戏小图时统一 `--sprite-height`。

**输出样例**：

- 固定 160×160 / 统一高度版：`assets/previews/sprite/sprite_lengguyun_walk_right_8f_segmented_fixed.gif`
- 保留原比例 / 底部锚定版：`assets/previews/sprite/sprite_lengguyun_walk_right_8f_segmented_anchor.gif`

**经验**：游戏中使用 sprite 时必须导出 **同尺寸帧 + 同 anchor（通常 bottom-center）**；不要直接把自动裁白边后的不同尺寸 PNG 串成 GIF，否则一定跳。

### 15.14 8 帧右走闭环接缝：加第 9 格校验帧（2026-04-30）

**现象**：固定锚点后，第 8 帧回第 1 帧仍明显跳，说明源动作本身没有闭环。

**处理**：新增 `sprite_protagonist_walk_right_8f_loop_strip.yaml` 与任务 `sprite_lengguyun_walk_right_8f_loop_strip`。生成 **9 格**：第 1～8 格为动画，第 9 格必须复制第 1 格姿态，作为 loop check，迫使第 8 格成为可接回第 1 格的过渡。

**结果**：`gpt-image-2` 成功生成，花费约 **¥0.2226**。输出：

- 原图：`assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png`
- 8 帧预览：`assets/previews/sprite/sprite_lengguyun_walk_right_8f_loopcheck.gif`
- 9 格校验预览：`assets/previews/sprite/sprite_lengguyun_walk_right_9f_with_loopcheck.gif`

**经验**：AI 生成动画 strip 时，仅写“8 帧循环”不够；必须显式要求 **首尾闭环校验帧**，否则最后一帧经常不是回到第一帧前的过渡。

---

## 16. 多 Agent 协作启动（2026-04-30）

### 16.1 现象与触发

单 agent 同时跑剧情 / Godot 系统 / 战斗 / 任务 / 美术 / 测试，长链路下出现：
- 上下文污染（美术 prompt 残留进 Godot 脚本）
- 风格漂移（同一 NPC 口吻变化）
- 经验记录遗漏（解决了不写 `experience-log`）
- 重复试错（同一种 fallback 反复触发）

### 16.2 处理

落地多 Agent 协作 v0.1：
- 新增 `docs/agent-workflow.md`：固定 7 角色（producer / lore / system / battle / art / qa / review）、标准流程、`[handoff]` 交接格式、模型分层建议、并行串行规则。
- 新增 `docs/module-owners.md`：把 `game/` `prompts/` `scripts/` `assets/` `docs/` 下每个目录的写权 agent 写死。
- 新增 `docs/acceptance-checklists/{lore,system,battle,art,qa}.md`：各角色提交前自检清单。
- `AGENTS.md` 加「多 Agent 协作」速查节，并把读文件清单更新为：
  `AGENTS.md → current-progress → agent-workflow → module-owners → experience-log`。
- `docs/current-progress.md` §6 新增「多 Agent 协作」状态行，列出当前唯一进行中的试运行任务。
- 试运行：当前主角 sprite 8 帧右走闭环作为首个走完整流程的任务，handoff 模板见 `docs/pilot-handoff-sprite-walk-right-8f.md`。

### 16.3 经验

- **不要按文件随便分 agent**，按「写权目录」分；同一文件的字段也要按字段拆 owner（如 `q_*.tres` 文案归 lore，trigger 字段归 system，奖励数值归 battle）。
- **acceptance 必填**：任何收到不带可验证 acceptance 的请求，agent 应当先把 acceptance 补齐再开工，否则容易又跑回主控代为决策。
- **写权串行 + 探索并行**：探索 agents 可以并行调研多模块，但同一文件的写改任何时候只能一个 agent 持有。
- **新坑必写**：包括「越界」也算坑（如 art agent 改了 Godot 脚本），写到本文件下一节，由 producer 决定边界是否需要调整。

---

## 17. 多 Agent 独立角色记忆（2026-04-30）

### 17.1 现象与触发

用户指出：如果只是同一个 agent 在同一会话中“扮演不同角色”，长期仍然会共享同一套上下文窗口和即时记忆，容易把剧情、美术、系统、战斗、QA 的经验混在一起；持续开发时，角色经验无法稳定累积。

### 17.2 处理

在 `docs/agents/` 下落地独立角色记忆系统：

- `docs/agents/README.md`：角色记忆索引、读写协议、handoff 需要新增 `memory_files`。
- `docs/agents/producer-memory.md`：优先级、sprint 状态、跨角色决策和集成风险。
- `docs/agents/lore-memory.md`：世界观、角色口吻、禁忌、旧名替换规则。
- `docs/agents/system-memory.md`：Godot autoload、路由、存档、UI 和系统坑。
- `docs/agents/battle-memory.md`：技能、敌人、装备数值、战斗节奏和状态异常准备。
- `docs/agents/art-memory.md`：prompt、sprite 规格、出图模型、后处理、GIF/QA 经验。
- `docs/agents/qa-memory.md`：测试命令、手测清单、bug 复现格式、sprite strip QA。
- `docs/agents/review-memory.md`：审查关注点、历史回归、角色越界风险。
- `docs/agents/memory-template.md`：新增角色时复制的模板。

同步更新：

- `AGENTS.md`：新会话读取顺序增加 `docs/agents/README.md` 与 `producer-memory.md`；具体角色领取任务前读自己的 memory。
- `docs/agent-workflow.md`：handoff 格式新增 `memory_files`；增加 §5.1 角色记忆读写规则。
- `docs/module-owners.md`：明确 `docs/agents/*.md` 的写权归属。
- `docs/current-progress.md`：§6 增加角色记忆系统状态。

### 17.3 经验

- **角色记忆不是聊天记录**：只记录长期有用的规则、命令、坑点、当前模块状态；不要复制整段对话。
- **短结论写 memory，完整复盘写 experience-log**：例如 sprite 基线跳帧的完整原因仍写 §15，art-memory 只保留可执行结论。
- **每个 handoff 必须带 `memory_files`**：否则下一棒不知道该读哪份长期记忆，仍会退回“一个 agent 混合记忆”。
- **producer 记忆只收跨角色决策**：不要把 lore/art/system 的细节全部塞进 producer-memory，否则主控又会变成新的混合记忆池。

---

## 18. Sprite 未解决前的低成本优化纪律（2026-04-30）

### 18.1 现象与触发

主角 sprite 已经做过多轮：v2 单帧 / 4 帧 edits、v3 四向 sheet、8 帧右走 strip、9 格 loop-check strip。虽然方向更接近游戏 sprite，但仍未最终解决：角色比例、过渡帧、闭环、脚底基线、参考图稳定性都还需要优化。

继续凭肉眼感觉反复重跑，会浪费 API 成本。

### 18.2 处理

新增 `docs/sprite-cost-optimization-plan.md`，把后续 sprite 出图改成三段式：

1. **零 API**：先跑 `scripts/qa/check_sprite_strip.py`、`scripts/build_sprite_preview.py`，用现有 raw 判断是裁切/锚点问题还是源动作问题。
2. **dry-run**：付费前用 `python scripts/gen_assets.py --task <id> --dry-run --force` 看 prompt 和参考图，不让旧图跳过掩盖新 prompt。
3. **最小付费实验**：一次只跑 1 个 task；右走方向稳定后再复制到其他方向；不批量盲跑四方向。

同时把依赖外部参考图的两个 v3 模板加上 `require_reference_images: true`：

- `prompts/templates/sprite_protagonist_walk_4dir_sheet.yaml`
- `prompts/templates/sprite_protagonist_walk_right_8f_loop_strip.yaml`

这样参考图丢失时会在 dry-run / render 阶段报错，不会静默无参考烧钱出图。

另外修正 `scripts/gen_assets.py` 的 dry-run 行为：dry-run meta 改写到 `logs/dry_run/<task_id>.meta.json`，不再覆盖 `assets/raw/**/*.meta.json` 的真实出图成本记录。

### 18.3 经验

- **先归因再出图**：GIF 跳帧可能是裁切/锚点问题，不一定是 prompt 问题；必须先用固定锚点预览验证。
- **8 帧循环默认带第 9 格校验**：第 9 格复制第 1 格只用于验收，导入游戏时只用前 8 格。
- **QA 命令必须匹配格数**：普通 8 帧 `--expected 8`；9 格 loop-check `--expected 9`。
- **参考图路径是成本风险**：依赖本机 `workspaceStorage` 绝对路径的模板不可长期复用；重要参考图应归档进仓库或至少让模板 `require_reference_images` 失败保护。
- **dry-run 不能污染真实元数据**：真实 `.meta.json` 是成本与模型记录，dry-run 只能写 `logs/dry_run/`。
- **场景/角色经验已保存，但要区分历史 prompt**：`style-bible-prompts.md` 仍有早期旧 IP 提示词，当前新图不要直接沿用，应以 `world-bible` 与 `art-memory` 为准。

---

## 19. Agent Hub 本地 Web 调度台（2026-05-01）

### 19.1 现象与触发

多 agent 规范和角色记忆已经落地，但文档、产物、QA、成本、handoff 仍然分散在 `docs/`、`assets/`、`logs/`、`prompts/` 中。用户希望有一个 Web 管理系统，能看全整个项目，也能按不同职能 agent 管理任务与产出。

同时用户明确不想第一版就单独部署多个 agent 或分别配置大模型；Web 上发布任务后，实际仍由 Cursor 中的当前 agent 按角色规范执行。

### 19.2 处理

新增 `tools/agent_hub/`：

- `app.py`：FastAPI 本地 Web 应用。
- `db.py`：SQLite 初始化与通用查询。
- `scanner.py`：扫描 `docs/agents/`、`docs/`、`prompts/`、`assets/`、`logs/qa/`、`logs/dry_run/` 等产出。
- `templates/`：Dashboard、Agents、Tasks、Handoffs、Artifacts、QA、Costs 页面。
- `static/style.css`：本地 UI 样式。
- `verify_agent_hub.py`：不启动服务的扫描验收脚本。
- `README.md`：启动方式与第一版边界。

第一版边界：

- Web 不调用大模型，不保存模型 key，不自动触发外部 agent。
- Web 创建任务、生成标准 `[handoff]`，用户复制到 Cursor 执行。
- Cursor 执行后写回仓库文档 / 产物 / 日志，Web 重新扫描更新状态。
- 本地 SQLite `tools/agent_hub/agent_hub.sqlite3` 加入 `.gitignore`，避免把个人看板状态提交。

### 19.3 验证

已执行：

```powershell
python -m py_compile tools/agent_hub/app.py tools/agent_hub/db.py tools/agent_hub/scanner.py tools/agent_hub/verify_agent_hub.py
python -m tools.agent_hub.verify_agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; client=TestClient(app); paths=['/health','/','/agents','/tasks','/handoffs','/artifacts?owner_agent=art&kind=image','/qa','/costs']; [print(p, client.get(p).status_code) for p in paths]"
```

扫描结果：

- agents: 7
- artifacts: 162
- qa_runs: 2
- cost_records: 42
- tasks: 48

路由 smoke test 全部 200。

### 19.4 经验

- **Web 是调度台，不是 agent runtime**：第一版只做任务 / handoff / 扫描 / 状态，不解决模型调用。
- **先用 SQLite 做本地事实索引**：Markdown/YAML/目录仍是源数据，SQLite 是本地视图层。
- **本地文件服务也要最小授权**：`/repo/{path}` 不能直接开放仓库任意文件；只能返回已扫描 artifact，且必须拒绝 `.env`、`*.key`、本地 SQLite 等敏感文件。
- **成本不能跨币种直接相加**：DMXAPI 是 CNY，OpenAI 官方是 USD；Dashboard 必须按 `currency` 分组展示。
- **Jinja/Starlette 版本要注意 `TemplateResponse` 签名**：当前环境使用 `templates.TemplateResponse(request, "template.html", context)`；旧写法会触发 `TypeError: unhashable type: 'dict'`。
- **包内导入要用相对导入**：`tools.agent_hub.app` 被 uvicorn 作为模块导入时，应使用 `from .db import ...`，否则会报 `ModuleNotFoundError: No module named 'db'`。
- **不要整包安装重依赖**：验证 Web 只需安装 `fastapi uvicorn jinja2 python-multipart`，避免顺带拉 `rembg/onnxruntime` 等大包。

### 19.5 中文化与界面升级（2026-05-01）

用户反馈 Agent Hub 页面仍有较多英文，且视觉效果偏基础。处理方式：

- `tools/agent_hub/app.py` 增加 Jinja 过滤器：`status_label`、`agent_label`、`kind_label`、`yes_no`，数据库仍保存英文状态值，页面显示中文。
- `tools/agent_hub/templates/*.html` 将导航、标题、表单、表格列名、状态、成本 dry-run 标记等改为中文；handoff 协议正文仍保留固定字段，避免破坏复制给 Cursor 的格式。
- `tools/agent_hub/static/style.css` 重新设计为暗色宣纸 + 描金 + 朱砂点缀的“武侠项目驾驶舱”风格，强化顶栏、卡片、表格、状态胶囊和表单层次。
- 验证命令：

```powershell
python -m compileall "tools\agent_hub"
python -m tools.agent_hub.verify_agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); paths=['/','/agents','/tasks','/handoffs','/artifacts','/qa','/costs']; print({p: c.get(p).status_code for p in paths})"
```

结果：编译通过，`agents: 7`、`artifacts: 162`、`qa_runs: 2`、`cost_records: 42`、`tasks: 49`，主要页面均返回 200。运行中的 uvicorn `--reload` 进程曾短暂保留旧 Jinja 环境导致 `/` 500（`No filter named 'status_label'`），重启 Agent Hub 后线上本地服务 `/`、`/agents`、`/tasks`、`/handoffs`、`/artifacts`、`/qa`、`/costs` 均返回 200。

经验：

- **显示中文，不要改内部枚举**：`planned/in_progress/qa/review/blocked/done` 等内部值继续用于查询和表单提交，Jinja filter 只负责展示层翻译。
- **协议字段与用户界面分离**：`[handoff] from/to/goal/...` 是跨 Agent 的标准协议，不应为了中文化改掉字段名；页面标题、按钮和说明可以中文化。
- **主题要贴合项目语境**：普通深色后台容易显得临时；本项目可使用暗色、金色、朱砂、宣纸纹理，形成更像“江湖制作中枢”的识别度。
- **新增 Jinja filter 后要确认运行中服务**：TestClient 通过不等于浏览器里的旧 uvicorn 进程已刷新；若模板新增 filter 后页面 500，应查看服务日志并重启本地服务。

### 19.6 故事剧情总览页（2026-05-01）

用户希望 Agent Hub 增加“故事剧情”页面，把主要角色、门派介绍以及每章剧情概要展示清楚。处理方式：

- 新增 `tools/agent_hub/story_data.py`，把 `docs/world-bible.md`、`docs/design-mvp-chapter1.md`、`docs/agents/lore-memory.md` 中的核心剧情整理为只读结构化数据。
- 新增 `/story` 路由与 `tools/agent_hub/templates/story.html`，展示：
  - 一句话世界观与核心悬念节奏
  - 主要角色名帖
  - 七大门派 / 势力榜
  - 八章主线时间线
  - A/B/C/D 四结局路线
- `tools/agent_hub/templates/base.html` 导航新增“故事”入口。
- `tools/agent_hub/static/style.css` 增加故事页专属样式：卷宗 hero、人物名帖、势力榜、卷轴时间线、结局卡。

验证命令：

```powershell
python -m compileall "tools\agent_hub"
python -m tools.agent_hub.verify_agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); paths=['/','/story','/agents','/tasks','/handoffs','/artifacts','/qa','/costs']; print({p: c.get(p).status_code for p in paths})"
python -c "import urllib.request; paths=['/story','/']; print({p: urllib.request.urlopen('http://127.0.0.1:8765'+p, timeout=5).status for p in paths})"
```

结果：编译通过，TestClient 主要页面全部 200；运行中的本地服务重启后 `/story` 与 `/` 均返回 200。

经验：

- **剧情页先做只读总览，不急着做编辑器**：当前目标是让项目管理时看清角色、势力、章节和结局全貌；编辑功能会牵涉 canonical source、冲突合并和验收，后续再做。
- **剧情数据应独立于路由文件**：大量角色 / 章节文案不要直接堆进 `app.py`，单独放 `story_data.py`，未来迁移到 YAML 或 SQLite 更容易。
- **Web 总览要标注资料来源**：页面中保留 `world-bible`、`design-mvp-chapter1`、`lore-memory` 链接，避免后续不知道剧情展示来自哪里。
- **新增路由后要验证真实运行服务**：TestClient 通过后仍要访问本地 uvicorn；若 `--reload` 没刷新路由，需重启服务。

### 19.6.1 Agent Hub 需求列表页（2026-05-05）

用户希望 Agent Hub 增加“需求列表”页面，用“大模块 + 子模块 + 功能需求”来跟进进度。

处理：

- 新增 `docs/requirements.yaml`，作为仓库内可追踪的初始需求源。
- `tools/agent_hub/db.py` 增加 `requirements` 表。
- `tools/agent_hub/scanner.py` 增加 `import_requirements()`，从 `docs/requirements.yaml` 导入需求；扫描时不覆盖 Web 中已更新的 `status`。
- `tools/agent_hub/app.py` 增加 `/requirements`、新增需求、更新需求状态、从需求拆任务的路由。
- `tools/agent_hub/templates/requirements.html` 增加需求页，支持按大模块 / 子模块分组查看。
- `tools/agent_hub/templates/base.html` 导航新增“需求”。
- `tools/agent_hub/verify_agent_hub.py` 增加 requirements 表和 `/requirements` 路由验证。

经验：

- **需求和任务要分层**：需求是产品/模块目标，任务是分派给 agent 的执行项；Web 上应能从需求拆任务，但不要混为同一张表。
- **需求源要进仓库**：只存在 SQLite 会随本地状态丢失；用 `docs/requirements.yaml` 做初始事实源，SQLite 做状态视图。
- **扫描导入不要覆盖状态**：YAML 提供需求定义，页面更新的进度状态应保留，避免每次扫描把状态重置回 planned。

### 19.6.2 Agent Hub 工作证明门禁（2026-05-05）

背景：

- 需求页和任务页虽然能跟进状态，但“直接点完成”缺少可追溯证据，容易造成口头完成、后续难复盘。

处理：

- `requirements` 与 `tasks` 表新增 `proof_summary`、`proof_links`、`proof_updated_at` 字段。
- `db.py` 增加兼容迁移逻辑：老库启动时自动 `ALTER TABLE` 补列，不需要手动删库。
- 新增接口：`POST /requirements/{id}/proof`、`POST /tasks/{id}/proof`。
- 状态门禁：`/requirements/{id}/status` 与 `/tasks/{id}/status` 在置为 `done` 前强校验“摘要 + 证据链接”都非空。
- `requirements.html`、`tasks.html` 增加工作证明卡片与“已齐全/未齐全”标识，并显示成功/失败反馈。

经验：

- **完成态必须有证据**：没有证据的“完成”在多人协作里不可审计，后续交接和回归会反复踩坑。
- **门禁要后端兜底**：不能只靠前端按钮禁用，必须在状态更新接口再次校验。
- **迁移优先无破坏**：已有 SQLite 数据应自动补字段，避免要求团队先手工清库。

### 19.7 Agent Hub 字号缩放（2026-05-01）

用户反馈 Web 系统整体字体偏大。处理方式：

- 在 `tools/agent_hub/static/style.css` 中将 `body` 基础字号降为 `14px`。
- 同步下调导航、主标题、二级标题、表格头、状态标签、路径、表单标签、故事页 lead、角色 / 门派 / 章节 / 结局卡标题，避免只缩正文导致视觉层级失衡。

验证：

```powershell
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); paths=['/','/story','/agents','/tasks','/handoffs','/artifacts','/qa','/costs']; print({p: c.get(p).status_code for p in paths})"
python -c "import urllib.request; paths=['/static/style.css','/story','/']; print({p: urllib.request.urlopen('http://127.0.0.1:8765'+p, timeout=5).status for p in paths})"
```

结果：主要页面和 `style.css` 均返回 200，linter 无报错。

经验：

- **后台类页面要优先信息密度**：故事 / 任务 / 产出页面内容很多，基础字号用 14px 更适合长时间浏览。
- **缩放字号要成组处理**：正文、标题、标签、表格、故事页专属组件要同步缩放，否则会出现正文小、标题仍压迫的失衡感。

### 19.8 Agent Hub 下拉框可读性（2026-05-01）

用户反馈产出页面下拉框字体呈金色，不容易看清。处理方式：

- 在 `tools/agent_hub/static/style.css` 中显式设置 `select` 和 `select option` 的前景色为浅色、背景为深色，避免被强调色或浏览器默认样式影响。

验证：`/artifacts` 与 `/static/style.css` 均返回 200，linter 无报错。

经验：

- **select 要单独设 option 颜色**：只设置 `select` 本体不一定能覆盖展开选项，尤其在深色主题下需要同时设置 `select option`。

### 19.9 主角四方向 walk sprite 一次过 PASS（2026-05-01）

目标：在 `docs/sprite-cost-optimization-plan.md` 的纪律下，把主角 Field 四方向行走素材一次性补齐。

策略：

- 右走沿用已有 9 格 loop-check PASS 基准，不重生成。
- 上走 / 下走各新增一个 `prompts/templates/sprite_protagonist_walk_<dir>_8f_loop_strip.yaml`，结构、画幅、对齐、身份硬锁与右走完全一致，只重写运动方向描述。
- 左走由右走通过 `scripts/mirror_sprite_strip.py` 做逐格水平镜像得到，0 API 成本。

验证命令（关键步骤）：

```powershell
# 1) dry-run，输出在 logs/dry_run/
python scripts/gen_assets.py --task sprite_lengguyun_walk_down_8f_loop_strip --dry-run --force
python scripts/gen_assets.py --task sprite_lengguyun_walk_up_8f_loop_strip   --dry-run --force

# 2) 单方向付费生成（一个一个跑，先下再上）
python scripts/gen_assets.py --task sprite_lengguyun_walk_down_8f_loop_strip --fallback-model gpt-image-2 --skip-ping
python scripts/gen_assets.py --task sprite_lengguyun_walk_up_8f_loop_strip   --fallback-model gpt-image-2 --skip-ping

# 3) QA + 固定锚点 GIF / processed sheet
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png --expected 9 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_loop_strip.json
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_loop_strip.png   --expected 9 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_8f_loop_strip.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png --cols 9 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_9f_check.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_9f_check.png
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_loop_strip.png   --cols 9 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_9f_check.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_9f_check.png

# 4) 左走镜像（不消耗 API）
python scripts/mirror_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png --output assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png --expected 9
python scripts/qa/check_sprite_strip.py --source assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png --expected 9 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_left_8f_loop_strip.json
python scripts/build_sprite_preview.py --source assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png --cols 9 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_left_9f_check.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_left_9f_check.png
```

QA 结果：

| 方向 | 检出 | 基线极差 | 高度极差 | 状态 |
|------|------|----------|----------|------|
| 右 | 9/9 | 7 px | 7 px | PASS |
| 下 | 9/9 | 5 px | 5 px | PASS |
| 上 | 9/9 | 3 px | 3 px | PASS |
| 左（镜像） | 9/9 | 7 px | 7 px | PASS |

成本：下 ¥0.1522 + 上 ¥0.1526 = **¥0.3048**，左走 0 元。

经验：

- **方向模板要在右走 PASS 之后再写，不要四方向并行造**：一旦右走的对齐 / 身份锁仍在跳动，复制到三个方向只会把同一个错放大三倍。
- **正面 / 背面方向必须显式禁止侧向行走**：默认 prompt 里所有“前后步幅、剑挂腰侧”等描述容易被模型重解读为侧向走，模板里要把“正面朝镜头 / 背朝镜头”当硬约束写。
- **左走永远走镜像，别二次出图**：镜像继承右走基线和身份，QA 数据完全一致；任何 prompt 重写都可能引入身份漂移和成本支出。
- **镜像产物属于 `processed/`**：`assets/processed/sprite/...mirror.png` 不要污染 `assets/raw/sprite/v3/`，便于回溯它来自后处理而非 API。
- **dry-run + 单方向付费 + QA 立即跑**：付费完后必须当场跑 `check_sprite_strip` 才决定是否进入下一方向，而不是“四方向连发再回头看”。
- **`--fallback-model gpt-image-2`** 锁主模型不降级；`--skip-ping` 在 DMXAPI 偶尔抖动时也能把单方向跑掉，但不要把它当默认开。

### 19.10 Agent Hub 产出页索引滞后（2026-05-01）

现象：主角四方向 sprite 已经生成到 `assets/raw/`、`assets/processed/`、`assets/previews/` 和 `logs/qa/`，但 Agent Hub 的 `/artifacts` 产出页没有立刻显示最新图片。

根因：

- `tools/agent_hub/app.py` 只在 FastAPI startup 或手动 POST `/scan` 时调用 `scan_all()`。
- 出图是在服务运行期间完成的，SQLite 中的 `artifacts` 表仍是旧索引；页面渲染只读旧表，不会主动扫描文件系统。
- 直接运行 `python -m tools.agent_hub.verify_agent_hub` 能刷新索引，所以不是文件缺失，也不是图片类型过滤错误。

处理：

- 新增 `_refresh_index(conn)`，统一包装 `scan_all(conn)`。
- `/`、`/artifacts`、`/qa`、`/costs` 在查询前主动刷新索引，保证仓库派生产物页面与磁盘同步。
- 保留 `/scan` 手动刷新入口，但不再依赖用户每次产图后手动点刷新。

验证：

```powershell
python -m compileall tools\agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); resp=c.get('/artifacts?owner_agent=art&kind=image'); html=resp.text; print(resp.status_code); print('sprite_lengguyun_walk_down_9f_check.gif' in html, 'sprite_lengguyun_walk_up_9f_check.gif' in html, 'sprite_lengguyun_walk_left_9f_check.gif' in html, 'sprite_lengguyun_walk_right_9f_check.gif' in html)"
python -c "import urllib.request; html=urllib.request.urlopen('http://127.0.0.1:8765/artifacts?owner_agent=art&kind=image', timeout=10).read().decode('utf-8', errors='replace'); print('sprite_lengguyun_walk_down_9f_check.gif' in html, 'sprite_lengguyun_walk_up_9f_check.gif' in html, 'sprite_lengguyun_walk_left_9f_check.gif' in html, 'sprite_lengguyun_walk_right_9f_check.gif' in html)"
```

结果：TestClient 和真实本地服务均返回 200，四张 `_9f_check.gif` 都能在产出页 HTML 中找到。

经验：

- **仓库扫描型页面不能只靠 startup 索引**：AI 出图、QA 报告、成本 meta 都是在服务运行时追加的，列表页应在查询前刷新或提供明确刷新动作。
- **先判断是“文件没生成”还是“索引没更新”**：先跑 `verify_agent_hub` 或直接查页面 HTML，避免误以为图片路径、缩略图或过滤条件有问题。
- **PowerShell 不支持 Bash `python - <<'PY'` heredoc**：Windows 下临时 Python 查询用 `python -c "..."` 或脚本文件，避免把排查时间浪费在 shell 语法上。
- **本机 PowerShell 也不要假设可用 `&&`**：需要串联验证命令时用 `;`，或拆成多次 Shell 调用。

### 19.11 9 格 loop-check GIF 不应当作播放版（2026-05-01）

用户反馈主角四方向 walk 的动作不连贯，两只脚卡顿明显。排查结果：

- `check_sprite_strip.py` 只验证检出数、脚底基线、角色高度，不能证明“腿部相位连续”。
- 产出页最先看到的是 `_9f_check.gif`，它包含第 9 格 loop-check；第 9 格本来就应该复制第 1 格，用来证明 8 → 1 能闭环。
- 把 9 格校验 GIF 当动画播放，会在循环点出现“第 1 帧停两拍”的视觉卡顿。
- 排除第 9 帧后，循环点卡顿会减轻；若仍卡，才说明原始 1～8 帧本身的步态相位不均匀。

处理：

- `scripts/build_sprite_preview.py` 新增 `--frame-count` 参数，可从 9 格 loop-check 源图只取前 8 帧生成真正播放版。
- 新增四方向播放预览：
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_play.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_left_8f_play.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_down_8f_play.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_up_8f_play.gif`
- 对应 fixed sheet：
  - `assets/processed/sprite/sprite_lengguyun_walk_right_8f_play.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_left_8f_play.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_down_8f_play.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_up_8f_play.png`

验证：

```powershell
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png --cols 9 --segment-columns --frame-count 8 --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 80 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_play.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_play.png
python -m compileall scripts\build_sprite_preview.py
python -c "import urllib.request; html=urllib.request.urlopen('http://127.0.0.1:8765/artifacts?owner_agent=art&kind=image', timeout=10).read().decode('utf-8', errors='replace'); print('sprite_lengguyun_walk_down_8f_play.gif' in html, 'sprite_lengguyun_walk_up_8f_play.gif' in html, 'sprite_lengguyun_walk_left_8f_play.gif' in html, 'sprite_lengguyun_walk_right_8f_play.gif' in html)"
```

经验：

- **文件名区分 QA 版和播放版**：`_9f_check.gif` 只给 QA / review 看闭环，第 9 帧不要导入 Godot；`_8f_play.gif` 才给用户看真实播放效果。
- **对齐 PASS 不等于动作 PASS**：脚底稳定只能说明没有上下跳，不能说明两脚动作连贯；后续需要增加“相位 QA”或人工标注。
- **若 8 帧播放版仍卡，别靠调 GIF 时长硬救**：那是原始帧姿态分布问题，应改 prompt / 工作流。推荐先生成 4 个强约束关键姿态，再用 edits 补 4 个过渡帧，而不是一次自由生成 8 帧。

### 19.12 Walk sprite 改用 4 帧稳定策略（2026-05-01）

用户确认 8 帧播放版仍“不连贯、抖动走动”。结论：现有 8 帧源图动作相位本身不连续，不能再靠裁切、锚点或播放时长修复。

处理路径：

1. 新增 `prompts/templates/sprite_protagonist_walk_right_4f_stable_strip.yaml`。
   - 只做单行 4 格：左脚前 / 中立 / 右脚前 / 中立。
   - 重点约束“头、躯干、腰带、剑、酒葫芦稳定”，只让腿和手臂轻微变化。
   - 新增 task：`sprite_lengguyun_walk_right_4f_stable_strip`。
2. dry-run 通过，参考图存在，prompt 没有旧 IP / 头巾 / 45° 等距。
3. 付费生成时 DMXAPI 返回 `APIConnectionError`，三次重试失败，未扣费。
4. `python scripts/ping_dmx.py` 也返回 `APIConnectionError`，提示连续失败通常是 IP 风控 / 渠道临时不可用，建议等待 30+ 分钟后再试。
5. 为避免空等，先从已有 `assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png` 零成本导出 4 帧固定锚点候选。

新增 / 更新的本地工具能力：

- `scripts/build_sprite_preview.py` 支持：
  - `--frame-count`：从 9 格 loop-check 只取前 N 帧；
  - `--cell-top-inset` / `--cell-bottom-inset`：从等分 grid cell 裁掉跨行残留。

4 帧候选产物：

| 方向 | GIF | QA |
|------|-----|----|
| 右 | `assets/previews/sprite/sprite_lengguyun_walk_right_4f_sheet_play.gif` | `logs/qa/sprite_walk_right_4f_sheet_play.json` |
| 左（右走镜像） | `assets/previews/sprite/sprite_lengguyun_walk_left_4f_sheet_mirror_play.gif` | `logs/qa/sprite_walk_left_4f_sheet_mirror.json` |
| 下 | `assets/previews/sprite/sprite_lengguyun_walk_down_4f_sheet_play.gif` | `logs/qa/sprite_walk_down_4f_sheet_play.json` |
| 上 | `assets/previews/sprite/sprite_lengguyun_walk_up_4f_sheet_play.gif` | `logs/qa/sprite_walk_up_4f_sheet_play.json` |

QA 结果：

| 方向 | 检出 | 基线极差 | 高度极差 | 状态 |
|------|------|----------|----------|------|
| 右 | 4/4 | 1 px | 1 px | PASS |
| 左（镜像） | 4/4 | 1 px | 1 px | PASS |
| 下 | 4/4 | 0 px | 0 px | PASS |
| 上 | 4/4 | 0 px | 0 px | PASS |

经验：

- **8 帧源图动作不连续时，直接降到 4 帧比继续补救更可靠**：4 帧经典 RPG 循环牺牲细腻度，换稳定和可用。
- **QA 要分层**：`check_sprite_strip` 只能证明对齐；动作顺不顺仍要看 GIF / sheet，后续可考虑增加相邻帧差异评分。
- **现有 4dir sheet 可做低成本候选**：它虽然比例偏大，但缩到 96px 后角色一致性好，适合作临时可用版本。
- **左走优先镜像右走**：原 4dir sheet 的左走行顶部有跨行残留；镜像右走可以避免左右动作节奏和裁切残留不一致。
- **DMXAPI 连接失败时不要连续烧时间重试**：dry-run 通过但 ping 失败，说明是渠道/网络层；记录失败，保留模板，等 30+ 分钟后单任务重试。

### 19.13 右走 4 帧稳定版重试仍为连接失败（2026-05-02）

用户要求继续重试 `sprite_lengguyun_walk_right_4f_stable_strip`。执行顺序：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍返回 `APIConnectionError: Connection error.`。
- 付费任务三次 attempt 全部为 `APIConnectionError`。
- 结果汇总：成功 0，失败 1，总花费 ¥0.0000，未扣费。
- 失败明细已追加到 `logs/failed.log`。

判断：

- dry-run 已通过，参考图存在，因此不是 prompt / 任务配置问题。
- 错误发生在网络 / 渠道层，当前继续立即重试收益很低。
- 后续应等网络 / VPN / DMXAPI 渠道恢复后再跑同一个单任务；恢复判断以 `python scripts/ping_dmx.py` 能通过为准。

### 19.14 右走 4 帧稳定版按小时自动重试（2026-05-02）

用户要求：每隔 1 小时尝试一次，连续 3 次不行就停止。

执行策略：

- 后台 PowerShell 循环最多尝试 3 次。
- 每次先跑 `python scripts/ping_dmx.py`。
- ping 成功后才跑：
  `python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping`
- 如果生成成功，立即跑 QA、右走固定锚点 GIF / sheet、左走镜像和左走预览，然后停止循环。
- 如果 ping 或生成失败，失败计数 +1；未满 3 次则 `Start-Sleep -Seconds 3600`。
- 日志写入 `logs/dmx_retry_right_4f.log`。

当前状态：

- 第 1 次尝试已执行，`ping_dmx.py` 仍为 `APIConnectionError`。
- 后台任务已进入第 1 次 3600 秒等待。
- 预计后续第 2 / 第 3 次在下一小时和再下一小时自动执行；连续 3 次失败后自动停止。

经验：

- **长间隔重试要先 ping 后生成**：避免渠道明显不可达时直接进入付费生成请求。
- **后台重试必须写独立日志**：跨小时任务不能只靠终端滚动输出，需落到 `logs/` 方便后续恢复和复盘。
- **成功后立即做 QA / 预览 / 镜像**：不要等人工回来再补后处理，否则容易忘记该产物是否已验收。

### 19.15 右走 4 帧稳定版再次手动重试失败（2026-05-02）

用户要求“现在继续试试”。执行顺序：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍为 `APIConnectionError: Connection error.`。
- 付费生成任务 3 次 attempt 全部为 `APIConnectionError`。
- 结果汇总：成功 0，失败 1，总花费 ¥0.0000，未扣费。

判断：

- `sprite_lengguyun_walk_right_4f_stable_strip` 模板和 dry-run 仍可用，问题继续发生在 DMXAPI 网络 / 渠道层。
- 该问题已持续跨多个小时窗口，后续更建议先修网络 / VPN / DMXAPI 渠道连通性，或临时切换可用图像后端，再继续烧生成尝试。

### 19.16 右走 4 帧稳定版第三轮手动重试失败（2026-05-03）

用户继续要求重试。执行：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍为 `APIConnectionError`。
- 生成任务 3 次 attempt 全部为 `APIConnectionError`。
- 总花费 ¥0.0000，未扣费。

判断：DMXAPI 连接问题仍未恢复；继续短间隔重试意义很低，应先解决网络 / VPN / DMXAPI 渠道，或切换后端。

### 19.17 右走 4 帧稳定版第四轮手动重试失败（2026-05-03）

用户继续要求尝试。执行：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍为 `APIConnectionError`。
- 生成任务 3 次 attempt 全部为 `APIConnectionError`。
- 总花费 ¥0.0000，未扣费。

判断：问题继续稳定复现为 DMXAPI 网络 / 渠道不可达，模板无需再改；后续应优先换网络 / VPN / 后端。

### 19.18 DMXAPI `.com` 域名可达但 token 不通（2026-05-03）

用户建议改用 `https://www.dmxapi.com/`。未修改 `.env`，只在当前命令临时覆盖：

```powershell
$env:OPENAI_BASE_URL='https://www.dmxapi.com/v1'
python scripts/ping_dmx.py
```

结果：

- `.com` 域名不再出现 `APIConnectionError`，说明网络可达。
- 返回 `AuthenticationError: 401 Invalid token`。
- 判断：当前 `.env` 中的 `OPENAI_API_KEY` 可能是 `.cn` 站点令牌，不能直接用于 `.com` 的 New API 后端；需要在 `dmxapi.com` 对应控制台确认 / 新建 token 后再重试。

经验：

- **换域名要同时验证 token 归属**：同一品牌不同域名可能不是同一个 token 系统；连接可达不代表认证可用。
- **测试新域名先用临时环境变量，不要直接改 `.env`**：确认连通性和认证都通过后，再把 `OPENAI_BASE_URL` 持久化到 `.env`。

### 19.19 `.com` 新 token 生成右走 4 帧稳定版成功（2026-05-03）

用户提供 `dmxapi.com` 对应新 token 后，将本地 `.env` 更新为：

- `OPENAI_BASE_URL=https://www.dmxapi.com/v1`
- `OPENAI_API_KEY=<dmxapi.com 新 token>`（不在日志记录明文）

过程：

1. `python scripts/check_dmxapi.py --no-image --timeout 30 --connect 10`
   - 成功读取 `.com` base_url 和新 key，说明本地配置已生效。
2. 第一次正式生成返回 `BadRequestError: Invalid size '1024x512'. Requested resolution is below the current minimum pixel budget.`
   - 说明 `.com` 和新 key 已成功打到图像接口，问题转为模板尺寸。
3. 将 `sprite_protagonist_walk_right_4f_stable_strip.yaml` 从 `1024x512` 改为 `1024x1024`。
4. dry-run 通过后重新生成：
   `python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping`

结果：

- 右走 4 帧稳定版生成成功，成本 ¥0.3241。
- `assets/raw/sprite/v3/sprite_lengguyun_walk_right_4f_stable_strip.png`
- `assets/processed/sprite/sprite_lengguyun_walk_right_4f_stable_play.png`
- `assets/previews/sprite/sprite_lengguyun_walk_right_4f_stable_play.gif`
- QA：4/4 检出，基线极差 1px，高度极差 1px，PASS。

左走：

- 从右走 fixed sheet 镜像生成：
  `assets/processed/sprite/sprite_lengguyun_walk_left_4f_stable_mirror.png`
- 预览：
  `assets/previews/sprite/sprite_lengguyun_walk_left_4f_stable_mirror_play.gif`
- QA：4/4 检出，基线极差 0px，高度极差 0px，PASS。

经验：

- **`.com` 域名解决了 `.cn` 的连接问题，但 token 必须换成 `.com` 对应 token**。
- **gpt-image-2 不能用 1024×512 这种低像素画幅**：4 帧 strip 也应使用 `1024x1024`，让角色占中下部，上方留白。
- **遇到 400 invalid size 是模板问题，不是渠道问题**：修模板后 dry-run，再正式跑。
- **生成成功后立刻做 QA / GIF / 镜像**：这次右走成功后马上产出左走镜像，避免漏掉配套产物。

### 19.20 从 4 帧稳定版扩展右走 8 帧试验（2026-05-03）

用户反馈 4 帧比之前好，希望扩展到 8 帧试试看。策略：

- 不再使用旧 8 帧自由生成模板。
- 新增 `prompts/templates/sprite_protagonist_walk_right_8f_stable_from_4f.yaml`。
- 参考图直接使用已通过的 `assets/processed/sprite/sprite_lengguyun_walk_right_4f_stable_play.png`。
- 提示词明确：参考图第 1/2/3/4 帧对应新图第 1/3/5/7 帧，第 2/4/6/8 帧只做中间插补。
- 画幅使用 `1536x1024`，8 列单行，每格约 192px 宽。

执行：

```powershell
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_stable_from_4f --dry-run --force
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_stable_from_4f --fallback-model gpt-image-2 --skip-ping
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_stable_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_right_8f_stable_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_stable_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png
```

结果：

- 右走 8 帧生成成功，成本 ¥0.2483。
- QA：8/8 检出，基线极差 4px，高度极差 4px，PASS。
- 产物：
  - `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_stable_from_4f.png`
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.gif`
  - `assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png`
  - `logs/qa/sprite_walk_right_8f_stable_from_4f.json`

左走镜像：

- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.png`
- `assets/previews/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.gif`
- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror_play.png`
- `logs/qa/sprite_walk_left_8f_stable_from_4f_mirror.json`
- QA：8/8 检出，基线极差 1px，高度极差 1px，PASS。

经验：

- **8 帧扩展必须以 4 帧稳定版为参考图**：否则模型容易再次自由重画，回到抖动问题。
- **偶数帧插补能改善对齐，但仍需人工看节奏**：本轮 QA 数据好，但 sheet 中仍有中立帧偏近的可能；最终是否优于 4 帧要以 GIF 观感为准。
- **左走仍然镜像，不单独生成**：镜像继承右走节奏，避免再次引入左右不一致。

### 19.21 右走 8 帧 polish 细节优化（2026-05-03）

用户认为 `stable_from_4f` 已经非常接近，希望再优化一点细节。观察 sheet 后判断：主要可优化点是第 2/3 帧、第 6/7 帧略接近，容易产生轻微停顿；其它体块稳定性已经较好。

策略：

- 新增 `prompts/templates/sprite_protagonist_walk_right_8f_polish_from_8f.yaml`。
- 参考图使用 `assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png`。
- prompt 明确要求：
  - 保持角色、构图、脚底基线、剑、酒葫芦不变；
  - 只优化腿部过渡；
  - 第 2/4/6/8 帧不能复制第 1/3/5/7 帧；
  - 衣摆和头发只轻微随动，不大幅换形。

执行：

```powershell
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_polish_from_8f --dry-run --force
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_polish_from_8f --fallback-model gpt-image-2 --skip-ping
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_polish_from_8f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_right_8f_polish_from_8f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_polish_from_8f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.png
```

结果：

- 右走 8 帧 polish 生成成功，成本 ¥0.2506。
- QA：8/8 检出，基线极差 3px，高度极差 3px，PASS。
- 产物：
  - `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_polish_from_8f.png`
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.gif`
  - `assets/processed/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.png`
  - `logs/qa/sprite_walk_right_8f_polish_from_8f.json`

左走镜像：

- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror.png`
- `assets/previews/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror.gif`
- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror_play.png`
- `logs/qa/sprite_walk_left_8f_polish_from_8f_mirror.json`
- QA：8/8 检出，基线极差 0px，高度极差 0px，PASS。

经验：

- **polish prompt 要指出具体帧问题**：笼统写“更流畅”不如明确“第 2/3 和第 6/7 太接近，偶数帧必须更像过渡帧”。
- **轻微优化时只跑 1 张右走**：右走通过后镜像左走即可，不需要为左走单独付费。
- **不要只看 QA**：polish 版 QA 比 stable 版略好，但是否最终采用仍要由 GIF 动作观感决定。

### 19.21.1 复核：8 帧 polish 不如 stable_from_4f（2026-05-03）

用户指出 `sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.gif` 效果更好，后面的 polish 反而没这么好。复核后确认用户判断正确。

对比：

- `stable_from_4f` 左走：
  - QA：8/8，基线极差 1px，高度极差 1px。
  - bbox 宽度变化更有节奏：85 / 70 / 67 / 82 / 75 / 64 / 65 / 77。
  - 第 1/4/5/8 帧步幅轮廓更明确，行走节奏更自然。
- `polish_from_8f` 左走：
  - QA：8/8，基线极差 0px，高度极差 0px。
  - bbox 宽度更平滑但也更相似：79 / 70 / 70 / 79 / 74 / 66 / 65 / 77。
  - 第 2/3 帧几乎同宽，第 6/7 也接近，动态轮廓被“抹平”，观感不如 stable。

结论：

- 当前推荐基准改为 `stable_from_4f`：
  - `assets/previews/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.gif`
- `polish_from_8f` 只保留为实验对照，不作为当前推荐版本。

经验：

- **动作资源不能只按 QA 数字选版本**：polish 的基线 / 高度更稳，但动态步幅轮廓变弱，实际观感下降。
- **bbox 宽度节奏可辅助判断步态**：宽度变化过于平滑或重复，可能意味着步幅被抹平；适度的 contact / passing 宽度差更像行走。
- **用户目视反馈优先级高于脚本评分**：脚本只做底线检查，最终动画采用必须以 GIF 观感为准。

### 19.22 Agent Hub 产出页分页（2026-05-03）

用户反馈产出列表一页太多。处理：

- `/artifacts` 增加 `page` 和 `per_page` 查询参数。
- 默认 `per_page=20`。
- 可选 `20 / 50 / 100 / all`。
- 筛选条件 `owner_agent`、`kind` 与分页参数互相保留。
- 页面顶部显示总数和当前显示范围，顶部 / 底部提供分页导航。

验证：

```powershell
python -m compileall tools\agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); checks={'default':'/artifacts','50':'/artifacts?owner_agent=art&kind=image&per_page=50','100':'/artifacts?per_page=100&page=2','all':'/artifacts?per_page=all'}; print({k:c.get(v).status_code for k,v in checks.items()})"
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); html=c.get('/artifacts').text; body=html.split('<tbody>',1)[1].split('</tbody>',1)[0]; print('default_rows', body.count('<tr>')); html50=c.get('/artifacts?per_page=50').text; body50=html50.split('<tbody>',1)[1].split('</tbody>',1)[0]; print('rows_50', body50.count('<tr>')); htmlall=c.get('/artifacts?per_page=all').text; bodyall=htmlall.split('<tbody>',1)[1].split('</tbody>',1)[0]; print('rows_all', bodyall.count('<tr>'))"
python -c "import urllib.request; paths=['/artifacts','/artifacts?per_page=50','/artifacts?per_page=100&page=2','/artifacts?per_page=all']; print({p: urllib.request.urlopen('http://127.0.0.1:8765'+p, timeout=10).status for p in paths})"
```

结果：

- TestClient：默认 / 50 / 100 / all 均 200。
- 默认行数 20，`per_page=50` 行数 50，`per_page=all` 显示全部。
- 真实本地服务重启后四个 URL 均 200。

经验：

- **分页参数要在后端校验**：`per_page` 只允许固定值，避免任意大 LIMIT 或非法输入。
- **筛选和分页必须共存**：分页链接要带上当前 `owner_agent`、`kind`、`per_page`，否则翻页会丢筛选条件。
- **FastAPI reload 可能出现“模板新、Python 旧”的半刷新**：这次 TestClient 正常但真实服务 500，栈显示模板访问 `total_pages` 未定义；重启 uvicorn 后恢复。以后改模板 + 路由上下文时，TestClient 通过后仍要测真实服务，失败就重启。

### 19.23 上 / 下走 8 帧 stable_from_4f 生成（2026-05-03）

目标：沿用右走已验证的 `stable_from_4f` 策略，把现有 4 帧上 / 下方向候选扩展成 8 帧播放版。

新增：

- `prompts/templates/sprite_protagonist_walk_down_8f_stable_from_4f.yaml`
- `prompts/templates/sprite_protagonist_walk_up_8f_stable_from_4f.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_8f_stable_from_4f`
  - `sprite_lengguyun_walk_up_8f_stable_from_4f`

流程：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_8f_stable_from_4f --task sprite_lengguyun_walk_up_8f_stable_from_4f
python scripts/gen_assets.py --task sprite_lengguyun_walk_down_8f_stable_from_4f
python scripts/ping_dmx.py
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_8f_stable_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_stable_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_stable_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_stable_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.png
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_8f_stable_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_stable_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_8f_stable_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_stable_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.png
```

结果：

- 下走：`assets/previews/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.gif`
  - QA：8/8，基线极差 1px，高度极差 1px。
  - 成本：¥0.2496。
- 上走：`assets/previews/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.gif`
  - QA：8/8，基线极差 0px，高度极差 0px。
  - 成本：¥0.2494。

问题与处理：

- 第一次正式跑下走时，启动探活 `gpt-image-2` 超时（>60s），fallback `gpt-image-1.5` 返回 `insufficient_quota`。
- 独立 `scripts/ping_dmx.py` 也返回 `APITimeoutError: Request timed out.`，说明模板 / 任务配置不是根因。
- 由于 dry-run 已通过、参考图存在，且目标任务本身就是要生成这一张图，改为单任务 `--skip-ping` 做最小验证；正式生成成功，说明当时是探活请求不稳定，不是编辑生成完全不可用。

经验：

- **探活超时不等于正式编辑一定失败**：DMXAPI 有时最小生成探活超时，但带参考图的实际任务可成功；可以在 dry-run 通过后做一次单任务 `--skip-ping` 验证。
- **跳过探活必须小步执行**：只能一张一张跑，不能批量跳过探活，避免通道真实异常时浪费预算。
- **fallback 配额不足不要继续依赖 fallback**：当前 `gpt-image-1.5` 返回配额不足，后续 sprite 生成应继续以 `gpt-image-2` 为主，必要时显式 `--fallback-model gpt-image-2` 禁掉降级。

### 19.24 上 / 下走 8 帧视觉验收失败（2026-05-03）

用户复核后指出：上 / 下方向新做的 8 帧 `stable_from_4f` 不行，不如前面左右行走。

复核结论：用户判断正确。问题不是 QA 对齐，而是动作可读性。

对比：

- 右走 `stable_from_4f`：
  - bbox 宽度节奏约 166 / 131 / 123 / 162 / 141 / 115 / 117 / 152。
  - contact / passing 差异明显，腿部跨步读得出来。
- 左走镜像：
  - bbox 宽度节奏约 61 / 46 / 43 / 58 / 51 / 40 / 41 / 53。
  - 与右走一致，横向步幅轮廓明确。
- 下走 `stable_from_4f`：
  - bbox 宽度节奏约 148 / 147 / 145 / 143 / 142 / 142 / 144 / 144。
  - 8 帧轮廓过于接近，像原地轻微踏步。
- 上走 `stable_from_4f`：
  - bbox 宽度节奏约 107 / 117 / 113 / 117 / 116 / 117 / 120 / 120。
  - 背面方向保持正确，但步幅变化弱，整体不如左右方向。

根因：

- 上 / 下使用的 4 帧候选本身腿部 key pose 不够强，脚向画面前后方向的位移在正面 / 背面视角里很难读。
- `stable_from_4f` 策略会继承参考图优点，也会放大参考图缺点：参考姿态弱时，插补只会更平滑、更接近，不会自动产生更强步幅。
- QA 的 baseline / height spread 只能证明“不跳”，不能证明“走得好”。这次下 1px/1px、上 0px/0px 反而说明模型过度稳定。

处理：

- 文档已改为：右 / 左 `stable_from_4f` 是当前推荐；上 / 下 `stable_from_4f` 仅保留为失败对照，不作为推荐基准。
- 下一步不要直接继续扩 8 帧；应先重做上 / 下 4 帧关键姿态，要求更明确的脚部前后错位、衣摆摆动和左右肩/手臂节奏，再由用户看 4 帧 GIF 后决定是否扩展到 8 帧。

经验：

- **正面 / 背面 walk 不能照搬侧向策略**：侧向靠横向腿部轮廓读步幅；正面 / 背面必须靠脚掌前后位置、左右肩摆、衣摆和武器摆动共同读动作。
- **过稳也是失败**：baseline / height 越稳不一定越好，若 bbox 节奏几乎不变，动画会像抖动或站桩。
- **上 / 下方向先验收 4 帧 key pose**：4 帧不明显时不要扩 8 帧，否则只会把弱动作平滑成更弱的 8 帧。

### 19.25 上 / 下 4 帧强关键姿态候选（2026-05-03）

基于 §19.24 的结论，按用户选择的推荐路线，先重做上 / 下 4 帧 key pose，不再直接扩 8 帧。

新增：

- `prompts/templates/sprite_protagonist_walk_down_4f_strong_keypose.yaml`
- `prompts/templates/sprite_protagonist_walk_up_4f_strong_keypose.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_4f_strong_keypose`
  - `sprite_lengguyun_walk_up_4f_strong_keypose`

关键改动：

- 不再只引用弱 4 帧参考。
- 同时引用：
  - 已目视通过的 `sprite_lengguyun_walk_right_8f_stable_from_4f.png` 学习 contact / passing 轮廓节奏。
  - 旧上 / 下 `*_8f_play.png` 学习正面 / 背面方向感。
- Prompt 明确要求强 key pose：contact 帧宽、passing 帧窄，脚掌前后深度、手臂反摆、衣摆摆动必须读得出来。

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_4f_strong_keypose --task sprite_lengguyun_walk_up_4f_strong_keypose
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_4f_strong_keypose
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_strong_keypose.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_4f_strong_keypose.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_strong_keypose.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_4f_strong_keypose.png
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_4f_strong_keypose
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_strong_keypose.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_4f_strong_keypose.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_strong_keypose.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_4f_strong_keypose.png
```

结果：

- 下走 4 帧强 keypose：
  - `assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose.gif`
  - QA：4/4，基线极差 11px，高度极差 11px。
  - bbox 宽度节奏约 180 / 128 / 187 / 133，比失败 8 帧的 148 / 147 / 145 / 143 / 142 / 142 / 144 / 144 明显更有 contact / passing 差异。
  - 成本：¥0.3118。
- 上走 4 帧强 keypose：
  - `assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose.gif`
  - QA：4/4，基线极差 5px，高度极差 5px。
  - bbox 宽度节奏约 162 / 135 / 162 / 141，比失败 8 帧更有轮廓变化。
  - 成本：¥0.3121。

状态：两者只作为候选，需用户目视确认后再决定是否扩展到 8 帧。

经验：

- **用“成功方向 + 旧方向感”双参考，比单独引用弱方向 4 帧更好**：右走基准提供节奏，旧上 / 下提供朝向，prompt 再约束不要复制旧缺点。
- **4 帧候选也要看 baseline spread 的语义**：下走 11px 接近阈值，但这是强 key pose 带来的动作幅度，不一定是坏事；最终仍以 GIF 观感为准。
- **下一步扩 8 帧前必须人工确认 4 帧**：如果 4 帧仍不满意，应继续改 4 帧 prompt，而不是进入 8 帧插补。

### 19.26 上 / 下 4 帧强关键姿态仍视觉失败：左右晃动 + 速度偏快（2026-05-03）

用户复核 `sprite_lengguyun_walk_down_4f_strong_keypose.gif` / `sprite_lengguyun_walk_up_4f_strong_keypose.gif` 后指出：不行，左右晃动，而且速度过快了一点。

复核：

- 当前 GIF 是 120ms/帧，4 帧一轮约 480ms，对 walk cycle 偏快。
- 已零成本重建慢速版，180ms/帧：
  - `assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose_slow.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose_slow.gif`
- processed sheet 的 bbox 中心基本固定：
  - 下走 center_x：80.0 / 79.5 / 79.5 / 79.5。
  - 上走 center_x：80.0 / 79.5 / 80.0 / 80.0。
- 因此“左右晃动”不是简单的后处理整帧错位，而是素材内部躯干 / 袍摆 / 肩线摆动过强，尤其 contact 帧为了强化轮廓，把身体和大袍摆做成左右摇摆。

结论：

- `strong_keypose` 解决了 §19.24 的“步幅太弱”，但引入新问题：动作通过左右摇摆读出来，而不是通过稳定躯干 + 脚步深度读出来。
- 该组只保留为失败对照，不作为推荐基准，也不要扩 8 帧。

下一版要求：

- GIF 默认速度改为 160-180ms/帧，4 帧 cycle 约 640-720ms。
- Prompt 必须锁住中轴：
  - 头、胸口 / 背脊、腰带中心、酒葫芦挂点的水平位置几乎不动。
  - 左右肩摆动小于 2px，只允许手臂和脚变化。
  - 袍摆只能小幅摆，不要用大面积侧向披风制造步幅。
  - contact / passing 差异主要来自脚掌前后深度、膝盖弯曲和脚尖露出，不来自身体左右晃。
- 生成后先做 4 帧慢速 GIF，并对比普通 / 慢速两个版本；用户确认前不扩 8 帧。

经验：

- **强 keypose 不能等于左右摆**：正面 / 背面 walk 的核心是脚步深度和稳定中轴，不是身体左右摇。
- **预览速度会放大缺陷**：4 帧 120ms/帧太快，晃动会更明显；上 / 下 4 帧候选应默认 160-180ms/帧审片。
- **中心漂移要区分外部 bbox 与内部躯干**：bbox 居中不代表观感不晃，袍摆或肩线变化仍会造成躯干视觉摆动。

### 19.27 上 / 下 4 帧 balanced 候选（2026-05-03）

基于 §19.26，继续参考左右方向经验优化：

- 不是继续加强大 keypose，而是在两个失败极端之间取平衡：
  - `strong_keypose`：步幅明显，但靠身体 / 袍摆左右摇。
  - `locked_axis`：中心稳定，但四帧太接近，像站桩。
- 新模板要求：
  - 头 / 胸 / 腰带中轴稳定。
  - contact 比 passing 下半身轮廓宽约 8-18px。
  - 脚底最低点不跳，默认 180ms/帧慢速审片。

新增：

- `prompts/templates/sprite_protagonist_walk_down_4f_balanced.yaml`
- `prompts/templates/sprite_protagonist_walk_up_4f_balanced.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_4f_balanced`
  - `sprite_lengguyun_walk_up_4f_balanced`

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_4f_balanced
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_4f_balanced
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_balanced.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_4f_balanced.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_balanced.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 180 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_up_4f_balanced
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_4f_balanced
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_balanced.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_4f_balanced.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_balanced.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 180 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.png
```

结果：

- 下走 balanced：
  - `assets/previews/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.gif`
  - raw QA：4/4，baseline spread 17px（FAIL），height spread 17px（PASS）。
  - processed 慢速预览：center_x 79.5 / 79.5 / 79.5 / 80.0，center_y 全 104.0，width 47 / 39 / 49 / 40。
  - 成本：¥0.3103。
- 上走 balanced：
  - `assets/previews/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.gif`
  - raw QA：4/4，baseline spread 10px（PASS），height spread 10px（PASS）。
  - processed 慢速预览：center_x 79.5 / 80.0 / 79.5 / 79.5，center_y 全 104.0，width 47 / 38 / 43 / 37。
  - 成本：¥0.3104。

状态：

- 两张只作为候选，待用户目视确认。
- 不扩 8 帧，直到用户确认 4 帧慢速 GIF 的节奏和左右稳定性。

经验：

- **processed 预览是最终观感口径，raw QA 是风险提示**：下走 raw baseline fail，但 processed 慢速预览中心和高度稳定；仍需人工看 GIF 判断是否可接受。
- **上 / 下方向的有效节奏目标**：中心固定 + 高度固定 + contact/passing 宽度差约 8-12px，比“强 keypose”的大幅差异更稳。
- **每轮只推进通过的方向策略正确**：`locked_axis` 下走暴露“太弱”后没有继续生成上走，节省了一张图成本。

### 19.28 上 / 下 8 帧 balanced_from_4f 扩展（2026-05-04）

用户确认 §19.27 的上 / 下 4 帧 balanced 候选「这次可以」，要求扩充到 8 帧。

新增：

- `prompts/templates/sprite_protagonist_walk_down_8f_balanced_from_4f.yaml`
- `prompts/templates/sprite_protagonist_walk_up_8f_balanced_from_4f.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_8f_balanced_from_4f`
  - `sprite_lengguyun_walk_up_8f_balanced_from_4f`

策略：

- 直接引用用户确认的 processed 4 帧 slow sheet：
  - `assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.png`
- 明确把参考图第 1 / 2 / 3 / 4 格映射为 8 帧中的第 1 / 3 / 5 / 7 格。
- 第 2 / 4 / 6 / 8 格只补小过渡，避免重新生成新动作或重回左右摇。
- 同时输出 120ms 与 140ms 预览；基于用户之前反馈「速度过快」，建议优先看 140ms。

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_8f_balanced_from_4f --task sprite_lengguyun_walk_up_8f_balanced_from_4f
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_8f_balanced_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_balanced_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_balanced_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_120ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f.png
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 140 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_140ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_140ms.png
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_8f_balanced_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_balanced_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_8f_balanced_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_120ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f.png
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 140 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_140ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_140ms.png
```

结果：

- 下走 8 帧：
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_120ms.gif`
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_140ms.gif`
  - fixed sheet：`assets/processed/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f.png`
  - QA：8/8，baseline spread 1px，height spread 1px。
  - 成本：¥0.2476。
- 上走 8 帧：
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_120ms.gif`
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_140ms.gif`
  - fixed sheet：`assets/processed/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f.png`
  - QA：8/8，baseline spread 6px，height spread 6px。
  - 成本：¥0.2478。

经验：

- **用户确认的 4 帧 processed sheet 是更好的 8 帧参考**：比引用 raw 或旧方向图更能保留最终观感。
- **8 帧扩展会自然变平滑，步幅可能略弱**：因此 prompt 要明确保留第 1/3/5/7 的关键姿态差异，避免模型把动作全部抹平。
- **速度输出应保留多版本**：120ms 适合较快移动，140ms 更接近当前用户偏好的审片速度。

### 19.29 上 / 下 8 帧 balanced_from_4f 脚步相位仍不协调（2026-05-04）

用户仔细复核 §19.28 的 8 帧上 / 下走后指出：两只脚走路还是有点不协调。

复核：

- 整体锚点 / baseline 数字没有问题：
  - 下走 8 帧：QA 8/8，baseline spread 1px，height spread 1px。
  - 上走 8 帧：QA 8/8，baseline spread 6px，height spread 6px。
- 下半身 processed 量化：
  - 下走 8 帧 width：47 / 41 / 39 / 44 / 49 / 44 / 41 / 44。
  - 上走 8 帧 width：46 / 39 / 39 / 43 / 44 / 44 / 37 / 38。
  - 对比 4 帧 balanced：下走 47 / 39 / 49 / 40；上走 47 / 38 / 43 / 37。

结论：

- 4 帧 balanced 的 contact / passing 关系是清楚的。
- 8 帧扩展时模型把部分中间帧插得过于相似，脚步相位没有真正形成“左脚 contact → passing → 右脚 contact → passing”的自然交替。
- 这不是整体锚点或播放速度问题，而是 AI 插补的脚部语义问题。

建议：

- 不要继续盲目扩 8 帧。若目标是尽快接入游戏，上 / 下方向优先用 4 帧 `balanced` 慢速版，视觉上比当前 8 帧更可靠。
- 若坚持做 8 帧，需要换策略：
  - 不是“由 4 帧整张图自由插补”，而是更强约束每一格脚步语义；
  - 或者分阶段生成 / 单独修中间帧，但成本和失败风险更高。

经验：

- **QA PASS 不代表脚步相位 PASS**：baseline / height 只能说明不跳，不能判断左右脚是否自然交替。
- **正面 / 背面 8 帧插补比侧向更难**：侧向腿部轮廓清楚，模型较容易读；正 / 背面脚步深度容易被抹平成同脚小动。
- **4 帧可比 8 帧更可靠**：如果 8 帧中间帧语义不稳定，宁可用清楚的 4 帧慢速循环。

### 19.30 下走 8 帧 strict_phase 尝试仍未解决脚步相位（2026-05-04）

用户选择继续尝试 8 帧，但加强逐帧脚步相位约束。

新增：

- `prompts/templates/sprite_protagonist_walk_down_8f_strict_phase.yaml`
- `prompts/templates/sprite_protagonist_walk_up_8f_strict_phase.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_8f_strict_phase`
  - `sprite_lengguyun_walk_up_8f_strict_phase`

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_8f_strict_phase --task sprite_lengguyun_walk_up_8f_strict_phase
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_8f_strict_phase
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_strict_phase.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_strict_phase.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_strict_phase.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 140 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_strict_phase_140ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_strict_phase.png
```

结果：

- `assets/previews/sprite/sprite_lengguyun_walk_down_8f_strict_phase_140ms.gif`
- `assets/processed/sprite/sprite_lengguyun_walk_down_8f_strict_phase.png`
- QA：8/8，baseline spread 6px，height spread 6px。
- 成本：¥0.2501。

复核：

- strict_phase 的下半身宽度节奏：44 / 43 / 38 / 38 / 45 / 40 / 43 / 42。
- balanced_from_4f 的下半身宽度节奏：47 / 41 / 39 / 44 / 49 / 44 / 41 / 44。
- 4 帧 balanced 的下半身宽度节奏：47 / 39 / 49 / 40。

结论：

- strict_phase 虽逐帧写清左右脚状态，但模型仍把中间帧画得相似，脚步相位没有明显改善。
- 因下走验证未明显优于 balanced_from_4f，取消上走 strict_phase，避免继续浪费。

经验：

- **自然语言逐帧约束不一定能控制正面 / 背面脚步语义**：模型会满足“稳定”和“同人”，但仍可能把脚步动作抹平。
- **继续整张 8 帧出图收益低**：若要真正修 8 帧脚相位，可能需要单独修中间帧或换更可控的动画管线；当前项目阶段优先使用 4 帧 balanced 更稳。

### 19.31 Seedance 视频试跑未进入生成：当前 DMXAPI 分组无视频通道（2026-05-04）

用户提出“生成视频再转 GIF”的方案，并确认先试一个下走方向。

新增：

- `scripts/gen_seedance_video.py`：独立 Seedance 试跑脚本，不接入 `gen_assets.py`；支持 `/v1/responses` 与 `/v1/videos` 两种异步视频 API 形态，使用 `.env` 的 `OPENAI_API_KEY` / `OPENAI_BASE_URL`，可轮询并下载 mp4。
- 脚本默认从 `assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png` 裁出第 1 格作为首帧，避免把整张 4 帧 sheet 当作多个角色。

执行与结果：

```powershell
python scripts/gen_seedance_video.py --direction down --poll-seconds 10 --timeout-seconds 420
python scripts/gen_seedance_video.py --direction down --endpoint "https://www.dmxapi.cn/v1/responses" --model "doubao-seedance-1-5-pro-responses" --poll-model "seedance-get" --poll-seconds 10 --timeout-seconds 420
python scripts/gen_seedance_video.py --direction down --model "doubao-seedance-1-5-pro-responses" --poll-model "seedance-get" --poll-seconds 10 --timeout-seconds 420
python scripts/gen_seedance_video.py --direction down --api-mode videos --endpoint "https://www.dmxapi.com/v1/videos" --model "doubao-seedance-1-0-pro-fast-251015" --poll-seconds 10 --timeout-seconds 420
```

- `.com /v1/responses` + `doubao-seedance-2-0-260128`：`model_not_found`。
- `.cn /v1/responses`：本机 Python TLS 握手失败，未提交成功。
- `.com /v1/responses` + `doubao-seedance-1-5-pro-responses`：`model_not_found`。
- `.com /v1/videos` + `doubao-seedance-1-0-pro-fast-251015`：`model_not_found`。
- `/v1/models` 查询当前 `.com` 默认分组只看到 Doubao 文本模型与 `doubao-seedream-4-0-250828`，没有 `seedance` 视频模型。
- 本机 PATH 没有 `ffmpeg`，即使生成 mp4，视频抽帧/GIF 也需要另补解码方案或安装 ffmpeg。

结论：

- 本次没有拿到 Seedance task id，也没有产生 mp4；失败点在提交前的模型通道/网络层，不是 prompt 或视频质量问题。
- 继续试同一 API key 的 Seedance 模型名收益低；需要先在 DMXAPI 后台确认/开通 Seedance 视频通道，或拿到可用的视频模型名与 endpoint。

经验：

- **先查 `/v1/models` 再试视频模型**：如果当前分组没有 `seedance`，直接提交会反复 `model_not_found`，可能浪费排查时间。
- **视频 API 与图片 API 不应混进同一生成脚本**：端点、轮询、结果解析、后处理都不同，独立脚本更容易控制风险。
- **视频转 sprite 需要预置抽帧工具**：Windows 环境没有 `ffmpeg` 时，应先准备抽帧方案，否则 mp4 下载后还不能直接进现有 `build_sprite_preview.py`。

### 19.32 火山方舟 Seedance 2.0 试跑被模型未开通拦截（2026-05-04）

用户提供火山方舟 API key，并说明有免费额度，希望尝试 Seedance 2.0。

新增：

- `scripts/gen_volcengine_seedance_video.py`：独立火山方舟 Seedance 2.0 试跑脚本。
  - 支持 `contents/generations/tasks` 与 `videos` 两种 API 形态。
  - 从 `assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png` 裁第 1 格做首帧，避免整张 4 帧 sheet 被识别为多角色。
  - 从 `VOLCENGINE_API_KEY` 或 `ARK_API_KEY` 读取凭据；本地 `.env.local` 已被 `.gitignore` 忽略。

执行：

```powershell
python scripts/gen_volcengine_seedance_video.py --direction down --api-mode tasks --poll-seconds 10 --timeout-seconds 600
python scripts/gen_volcengine_seedance_video.py --direction down --api-mode tasks --model "doubao-seedance-2-0-fast-260128" --poll-seconds 10 --timeout-seconds 600
```

结果：

- API key 鉴权成功，请求到达火山方舟账户。
- 标准模型 `doubao-seedance-2-0-260128` 返回 `ModelNotOpen`：账号尚未开通该模型服务。
- Fast 模型 `doubao-seedance-2-0-fast-260128` 同样返回 `ModelNotOpen`。
- 未拿到 task id，未产生视频，也未发生视频质量评估。

下一步：

- 需要先在火山方舟控制台开通 Seedance 2.0 / Seedance 2.0 Fast 模型服务，然后重新运行同一脚本。

经验：

- **免费额度不等于模型已开通**：火山方舟即使 key 有效、账户有额度，具体模型仍可能需要在控制台单独开通。
- **`ModelNotOpen` 是控制台开通问题，不是 prompt / payload 问题**：不要在这个错误下反复改提示词或重试生成。

### 19.33 四方向行走 MVP 改为混合帧数接入（2026-05-04）

用户决定暂停 Seedance 视频方案，回到 image 方式，并按“左右 8 帧、上下 4 帧慢速 balanced”的低成本策略继续。

接入：

- 复制 processed sprite 到 Godot 跟踪资源目录：
  - `game/art/characters/lengguyun_walk_right_8f.png`
  - `game/art/characters/lengguyun_walk_left_8f.png`
  - `game/art/characters/lengguyun_walk_down_4f.png`
  - `game/art/characters/lengguyun_walk_up_4f.png`
- `game/scripts/field/player.gd` 从占位翻转图改为四方向 sprite sheet 播放：
  - 右 / 左：8 帧，0.10s/帧；
  - 上 / 下：4 帧，0.18s/帧；
  - 停止移动时停在当前方向第 1 帧。
- `game/scenes/player.tscn` 默认贴图改为下走 4 帧 sheet。
- `game/scripts/field/field_walkable_controller.gd` 保留旧立绘覆盖逻辑，但当 Player 已启用方向行走 sprite 时不再覆盖其 texture。
- 新增 `game/tests/test_player_walk_animation.gd`，用于校验 Player 能选择右 8 帧与下 4 帧贴图。

验证：

- PNG 尺寸确认：
  - 右 / 左：1280×160，即 8×160；
  - 上 / 下：640×160，即 4×160。
- `ReadLints` 无报错。
- 当前环境没有 `godot` 命令，未能运行 `game/tests/test_player_walk_animation.gd`；需要在装有 Godot CLI 的环境执行。

经验：

- **MVP 可以接受混合帧数**：左右方向轮廓清楚，8 帧收益明显；正 / 背面 8 帧脚相位不自然时，4 帧慢速反而更稳定。
- **Player 代码必须允许每方向不同帧数/速度**：不要假设四方向统一 8 帧，否则会上下方向播放越界或节奏过快。
- **行走 sprite 接入后要阻止旧立绘覆盖**：否则 FieldController 可能把 Player 的 movement sheet 替换成 portrait，导致动画消失。
- **新 PNG 接入 Godot 需要关注 `.import`**：首次用编辑器打开会生成 import 文件，提交资源前应检查是否需要一并纳入。

### 19.34 Agent Hub 系统设计文档归属错误（2026-05-04）

现象：

- `system` agent 已产出 `docs/system-technical-design-v0.1.md`，但 Agent Hub Web 的 system/Godot 产出列表中看不到该记录。

原因：

- `tools/agent_hub/scanner.py` 的 `_owner_for_path()` 规则把 `docs/*.md` 默认归到 `producer`。
- 系统设计文档虽然文件名以 `system-` 开头，但不在 `game/**` 下，因此没有归到 `system`。

修复：

- 在 `_owner_for_path()` 中增加规则：`docs/system-*` 归属 `system`。
- 重新运行扫描验证。

验证：

```powershell
python -m py_compile tools/agent_hub/scanner.py
python -m tools.agent_hub.verify_agent_hub
python -c "from tools.agent_hub.db import connect, init_db; from tools.agent_hub.scanner import scan_all; conn=connect(); init_db(conn); scan_all(conn); row=conn.execute('select path, kind, owner_agent from artifacts where path=?', ('docs/system-technical-design-v0.1.md',)).fetchone(); print(dict(row) if row else 'NOT_FOUND')"
```

结果：

- `verify_agent_hub` 通过：agents 7、artifacts 320、qa_runs 25、cost_records 74、tasks 66。
- `docs/system-technical-design-v0.1.md` 已记录为 `kind=doc`、`owner_agent=system`。

经验：

- **Web 产出页依赖扫描归属规则**：新增角色专属设计文档时，文件路径命名要能被 `_owner_for_path()` 识别。
- **system 设计文档建议使用 `docs/system-*.md` 命名**，这样可自动归到 Godot/system agent。

### 19.35 Agent Hub Markdown 产出默认应展示预览（2026-05-04）

现象：

- Agent Hub 产出库中点击 `.md` 文件会通过 `/repo/<path>` 直接返回原始文件，浏览器显示 Markdown 源码。
- 用户希望默认看到渲染后的预览，而不是源码。

修复：

- `tools/agent_hub/app.py`：
  - `/repo/{path}` 对 `.md` 文件默认渲染 `markdown_preview.html`。
  - 保留 `?raw=1` 查看源码。
  - 增加 Markdown 渲染；如果本地缺少 `Markdown` 包，则降级为安全转义的基础预览。
- `tools/agent_hub/templates/markdown_preview.html`：新增文档预览页，提供“查看源码”和“返回产出库”。
- `tools/agent_hub/static/style.css`：新增 Markdown 正文、表格、代码块、引用块样式。
- `scripts/requirements.txt`：增加 `Markdown>=3.6`。
- `tools/agent_hub/verify_agent_hub.py`：增加路由验证，确保默认是预览页，`?raw=1` 是源码。

验证：

```powershell
python -m py_compile tools/agent_hub/app.py tools/agent_hub/scanner.py tools/agent_hub/verify_agent_hub.py
python -m tools.agent_hub.verify_agent_hub
```

结果：

- 验证通过：agents 7、artifacts 320、qa_runs 25、cost_records 74、tasks 66。

经验：

- **产出库链接不应等同原始文件下载**：文档类产出默认预览更适合 Web 管理系统；源码入口应作为显式选项。
- **验证脚本要覆盖关键 UI 路由行为**：否则页面行为回退成源码打开时，扫描数量仍会通过。
- **角色详情页也要内嵌 memory 预览**：只修 `/repo/*.md` 不够；`/agents/<role>` 原本仍用 `<pre>` 显示摘要，用户会感觉角色页面还在看源码。应在角色详情页渲染 `memory_path` 对应 Markdown，并保留“查看源码”按钮。
- **角色详情页要置顶关键文档**：只把设计稿放进“最近产出”表格不够明显。按角色筛出 `kind=doc` 的重要文档并单独展示，system 设计稿如 `docs/system-technical-design-v0.1.md` 应在 system 页面可直接看到。
- **重要文档要直接展示正文**：只列出链接仍不够。角色页应提供“重要文档预览”，并默认展开第一篇关键设计稿，避免用户需要二次点击才能看到内容。

### 19.36 Agent Hub 重发布时 8765 被 Cursor 旧监听占用（2026-05-04）

现象：

- 修改 Agent Hub Markdown 预览后，`python -m tools.agent_hub.verify_agent_hub` 通过，但浏览器访问 `http://127.0.0.1:8765/repo/docs/system-technical-design-v0.1.md` 仍返回 Markdown 源码。
- 多次新启动 `uvicorn --port 8765` 报 `WinError 10048`，端口被占用。

排查：

```powershell
netstat -abno | Select-String -Context 1,1 ":8765"
```

结果显示：

- `127.0.0.1:8765` 的监听归属显示为 `[Cursor.exe]` / PID `73976`。
- `taskkill /PID 73976 /F` 与 `Stop-Process -Id 73976` 都提示找不到进程，说明这是 Cursor 管理的旧监听/端口代理，不能在不关闭 Cursor 的情况下可靠清理。

处理：

- 不强杀 Cursor。
- 将新版本 Agent Hub 发布到备用端口：

```powershell
python -m uvicorn tools.agent_hub.app:app --reload --host 127.0.0.1 --port 8766
```

验证：

```powershell
Invoke-WebRequest http://127.0.0.1:8766/health
Invoke-WebRequest http://127.0.0.1:8766/repo/docs/system-technical-design-v0.1.md
Invoke-WebRequest "http://127.0.0.1:8766/repo/docs/system-technical-design-v0.1.md?raw=1"
```

结果：

- `/health` 正常。
- `.md` 默认预览返回 `markdown-preview`。
- `?raw=1` 返回源码。

经验：

- **本地 Web 发布先验端口再验功能**：如果 8765 返回旧行为，不要只看 `verify_agent_hub`，还要打真实浏览器端口。
- **Cursor 旧监听可能无法单独 taskkill**：此时优先用备用端口发布，避免误杀 Cursor。


### 19.39 SceneRouter 需要统一经典 Field / 可行走 Field 入口（2026-05-04）

现象：

- 项目同时存在 `field.tscn`（经典热点模式）和 `field_walkable.tscn`（可行走模式）。
- 新游戏入口可以显式进入可行走场景，但读档、战后继续、商店返回、对话 `scene:`、可行走出口等路径如果各自调用不同入口，容易把同一个 `SceneScript` 放进错误容器。

修复：

- `SceneRouter` 新增 `go_field_smart(scene_id, player_spawn?)`：
  - 读取 `res://data/scenes/<scene_id>.tres`。
  - 若 `SceneScript.is_walkable == true` 且 `field_walkable.tscn` 存在，进入可行走容器。
  - 否则进入经典 `field.tscn`。
- 新增 `get_field_scene_path(scene_id)` 作为可测试的纯查询方法。
- 改造入口：
  - 主菜单新游戏 / 继续游戏。
  - 战斗胜利继续 / 逃跑返回。
  - 商店关闭返回。
  - `SceneRouter.resolve_action("scene:<id>")`。
  - `field_walkable_controller.gd` 的出口跳转。
- 新增测试：`game/tests/test_scene_router_field_smart.gd`，覆盖 walkable 与 classic 两类场景路径选择。

验证：

- Cursor lint：相关 GDScript 文件无新增诊断。
- 搜索确认：游戏代码里没有残留 `SceneRouter.go_field(` / `SceneRouter.go_field_walkable(` 调用。
- 当前 shell 找不到 `godot` / `Godot` 可执行文件，未能运行 Godot SceneTree 测试；后续配置 `GODOT_BIN` 后应补跑：

```powershell
Godot --headless --path game --script res://tests/test_scene_router_field_smart.gd
```

经验：

- **路由选择逻辑必须集中在 SceneRouter**：调用方不应凭经验决定 classic / walkable 容器；只传场景 ID 和可选出生点。
- **可行走出口也属于跨场景入口**：只改读档和战后不够，出口若固定调用 `go_field_walkable()`，目标经典场景也会被错误装进可行走容器。
- **给路由选择拆出纯查询方法**：`get_field_scene_path()` 让无法启动完整场景树的情况下也能写最小测试。


### 19.40 转交给另一个 AI 时需要固定交接文档并进入 Agent Hub（2026-05-04）

现象：

- 只在聊天里整理交接内容，另一个 AI 不一定能稳定获得完整上下文。
- Agent Hub 虽然会扫描 `docs/**/*.md`，但如果文档命名不归属具体角色，角色页的重要文档不一定明显展示。

处理：

- 新增 `docs/system-handoff-2026-05-04.md`，集中记录：
  - 当前项目状态。
  - 最近完成项。
  - `SceneRouter.go_field_smart()` 改动范围。
  - 验证状态与 Godot CLI 缺口。
  - 下一步 Step 2 建议。
- 更新 `docs/current-progress.md` 与 `docs/agents/system-memory.md`，把交接文档列为 system 入口文档。
- 更新 `tools/agent_hub/verify_agent_hub.py`，检查：
  - `/repo/docs/system-handoff-2026-05-04.md` 能以 Markdown 预览渲染。
  - `/agents/system` 能展示这份交接文档。

经验：

- **交接内容要落地成 docs 文件**：聊天摘要适合即时沟通，但跨 AI 接续要用仓库内稳定路径。
- **命名要配合 Agent Hub 归属规则**：`docs/system-*.md` 会自动归属 `system` 并进入 system 角色页重要文档，比普通 `docs/handoff-*.md` 更容易被下一位 agent 看到。
- **Web 展示规则要有验证**：新增交接文档后，把预览路由和角色页展示加入验证脚本，避免“文档存在但网页看不到”。

### 19.41 可行走地图 Step 2 数据化与 UI action 补齐（2026-05-04）

现象：

- `SceneScript` 已有 `is_walkable` / `player_spawn` / `npcs` / `exits`，但缺少静态障碍和剧情触发区，第一章可行走地图只能靠边界碰撞。
- `SceneRouter.resolve_action()` 注释中已有 `open_inventory` / `open_quest_log`，但实现仍是 warning；对话数据无法通过 action 打开现有 I/E/J UI。
- `q_ch1_main_02_qingfeng.tres` 中 `desc_completed` 与 `completion_triggers` 粘在同一行，可能导致 Godot 资源解析失败。
- `ch1_road_after_thug.tres` 跳转到不存在的 `ch1_s2_linxi_road`。

修复：

- `SceneScript` 新增 `collision_rects`、`trigger_zones` 两个 `Array[Dictionary]` 字段，均使用归一化 `Vector2` 坐标。
- `field_walkable_controller.gd` 根据 `collision_rects` 生成 `StaticBody2D` 障碍，根据 `trigger_zones` 生成 `Area2D` 触发区并调用 `SceneRouter.resolve_action()`。
- flag 变化重建可行走场景时保留玩家当前位置，避免触发区 `set_flag` 后瞬移回出生点。
- `EventBus` 新增 `ui_requested(panel_id)`；`SceneRouter` 将 `open_inventory` / `open_equipment` / `open_quest_log` 转成事件，由 classic / walkable Field 复用现有 UI 打开逻辑。
- 新游戏恢复从 `ch1_s1_road` 开始；战后对话跳到 `ch1_s2_qingfeng_walkable`；q2 完成条件改为 `scene_entered:ch1_s2_qingfeng_walkable`。

验证：

- `read_lints` 检查 `game/` 无新增诊断。
- 搜索确认 `game/` 下没有残留直接调用 `SceneRouter.go_field(` / `SceneRouter.go_field_walkable(`。
- 搜索确认不存在 `ch1_s2_linxi_road` 与 `desc_completed = ...completion_triggers` 粘连。
- 当前 PowerShell 环境仍找不到 `Godot` / `godot`，未能运行 headless SceneTree 测试。

经验：

- **触发区 action 若会 set_flag，必须考虑 flag 刷新副作用**：如果刷新场景直接用默认 spawn，会造成玩家走进触发区后瞬移，应保留当前归一化位置。
- **UI action 不应让 SceneRouter 持有 UI 节点引用**：用 `EventBus.ui_requested` 让当前 Field 响应，classic / walkable 两套容器都能复用。
- **场景 ID 和任务 trigger 要一起改**：从 classic 场景迁到 walkable 场景时，只改 `scene:` 跳转不够，`scene_entered:<id>` 任务条件也要同步。

### 19.42 Sprite 白底透明化与场景美术方向转向模块化（2026-05-04）

现象：

- 主角已经可以移动，但行走 sprite 在 Godot 中显示白色底，说明源 PNG 是不透明 RGB/RGBA 白底，不是透明背景。
- 当前几个场景图更像 loading / splash / 概念图，不像可行走游戏场景；继续逐场景生成整张大背景会复用差、交互弱、成本高。

处理：

- 新增 `scripts/make_sprite_bg_transparent.py`，只移除从图片边缘连通的近白背景，避免把冷孤云白色内衫误删。
- 已处理四张 Godot 使用中的行走图：
  - `game/art/characters/lengguyun_walk_right_8f.png`
  - `game/art/characters/lengguyun_walk_left_8f.png`
  - `game/art/characters/lengguyun_walk_down_4f.png`
  - `game/art/characters/lengguyun_walk_up_4f.png`
- 处理后四张图均为 RGBA，alpha 范围为 `(0, 255)`。
- 将角色移动经验写入 `docs/agents/art-memory.md`：NPC 后续复用 Player 的每方向帧数/速度/底部锚点策略。

调研结论：

- Godot 4 官方 `TileMapLayer` 适合用 `TileSet` 做多层模块化地图：地面、装饰、建筑、碰撞、导航等可拆层。
- Tiled 是成熟的开源 2D 地图编辑器，支持多图层、对象层、地形工具、Automapping 和 JSON 导出，也适合外部生产地图数据。
- 本项目短期不应马上切纯像素 tilemap；更推荐“模块化美术 kit + Godot 组合摆放”：道路、建筑、植物、装饰物、前景遮挡物做成可复用 PNG/atlas，场景通过数据摆放。

经验：

- **透明化不能全局扣白**：角色衣物有白色区域，必须 edge-connected 或手工 mask。
- **场景不要再以单张 loading 图为目标**：后续 prompt 应生成可拼装模块，而不是一张完整电影概念图。
- **模块资产要同时服务画面和玩法**：建筑/树/摊位不仅是视觉元素，还应能附带碰撞矩形、遮挡层、NPC 锚点和触发区。

### 19.43 正式 UI 第一轮：统一武侠主题 + 主菜单/背包/装备/战斗换肤（2026-05-04）

处理：

- 新增 `game/scripts/ui/wuxia_theme.gd`，集中管理墨色、金边、朱印、玉色等 UI 配色和 StyleBox。
- `main_menu.gd` 不再只依赖大背景图观感，运行时叠加标题纸、菜单卷轴、朱印和墨色遮罩；按钮改为“启程 / 续卷 / 归隐”。
- `inventory_panel.gd` 改为“行囊”风格，行项目使用金边暗色卡片，按钮统一武侠样式。
- `equipment_panel.gd` 改为“武备”风格，6 槽装备行使用同一套卡片样式。
- `battle_controller.gd` 对战斗日志、按钮、HP/MP 条、姓名标签做统一样式处理；暂不做技能特效。
- 新增 `docs/art-modular-scene-kit-v1.md` 与 `prompts/templates/scene_module_atlas.yaml`；`prompts/tasks.yaml` 增加 3 个默认 `skip:true` 的模块化场景 kit 任务。

验证：

- `read_lints` 检查改动 GDScript 无新增诊断。
- `python -c "import yaml..."` 验证 `prompts/tasks.yaml` 语法通过。
- 当前仍未运行 Godot 编辑器实机验收。

经验：

- **正式 UI 先建统一主题工具**：不要每个界面散落 StyleBox 常量，否则背包、装备、战斗会再次风格漂移。
- **主菜单应由 UI 自身成立**：背景图只做氛围，不应承担全部视觉质量。
- **第一轮 UI 换肤先动脚本和样式，不重写业务逻辑**：这样不会影响背包、装备、战斗的功能闭环。

### 19.44 主界面 / 装备界面参考图风格校正（2026-05-04）

反馈：

- 第一版主菜单只是按钮更正式，但整体仍太简单，不像 `images/游戏主界面UI.png` 的完整武侠主界面。
- 装备界面需要参考 `images/装备界面UI.png`，而不是普通列表。
- 风格要中国武侠浓郁，不要外国神话、妖魔鬼怪元素。

处理：

- `WuxiaTheme` 增强为木纹深棕 + 金边 + 朱印 + 玉色点缀的中国武侠 UI 基调。
- `main_menu.gd` 增加顶梁、底梁、标题匾、红/金丝带、木质菜单板、角色卡框、左右竖牌等结构，尽量贴近参考图的“标题大匾 + 木牌菜单 + 角色卡 + 山水背景”构图。
- `equipment_panel.gd` 从单列装备列表改为三栏：左侧角色立绘、中间 3×2 装备槽、右侧纸张详情卡、下方 attributes 文本，贴近参考装备页布局。

经验：

- **参考图的关键不是按钮样式，而是构图层级**：顶部大标题匾、木牌按钮组、人物/装备卡、竖向角色标签、底部宣言共同构成“武侠游戏 UI”。
- **装备页不能只是列表**：RPG 装备界面应有角色展示区、装备槽位区、详情纸张区和属性区，列表只是临时实现。
- **禁止妖魔化装饰**：本项目 UI 装饰应使用山水、云纹、木牌、金边、朱印、绸带、屋檐纹样；避免骷髅、恶魔、西幻符文等元素。

### 19.45 UI 色调修正：从暖木金边转为寒山玄铁冷色（2026-05-05）

反馈：

- 用户明确不要橙黄色，整体要更阴沉、冷色调。

处理：

- `WuxiaTheme` 统一改为寒夜黑、深墨蓝、玄铁、冷钢边、霜蓝、寒玉、暗血红；保留常量名兼容旧代码，但数值已不再是暖金色。
- `main_menu.gd` / `main_menu.tscn` 的背景叠色、暗角、标题匾、菜单板、角色卡、丝带和文字高光改为雾蓝/冷白。
- `inventory_panel.gd`、`equipment_panel.gd`、`battle_controller.gd` 中散落的暖色 StyleBox 改为冷色玄铁卡片、灰白冷宣纸、寒蓝 MP、暗血 HP。
- `tools/ui_style_preview.html` 升级为 UI Kit v2「寒山玄铁」，覆盖主菜单、按钮、对话框、buff/debuff、血条、装备槽、详情卡和冷色板。
- `docs/ui-style-v1.md` 与 `docs/agents/art-memory.md` 已记录：禁止大面积橙黄 / 暖金 / 喜庆红绸，参考图只取构图，不取暖色调。

经验：

- **统一主题常量不够**：之前不少界面脚本里有散落的硬编码暖色，改色调时必须全局搜索并同步替换。
- **常量名可暂时兼容，语义要在文档里修正**：`GOLD` 等旧常量名短期保留以降低代码改动，但文档和预览里要明确它现在代表“冷钢边 / 霜蓝高光”。
- **冷色武侠不等于西幻暗黑**：装饰仍用山水、云纹、匾额、宣纸、寒玉，避免骷髅、恶魔、符文等西幻/妖魔元素。

### 19.46 UI 从 HTML 风格稿推进到 art agent 美术资产 brief（2026-05-05）

反馈：

- 当前 UI 方向接近，但 `tools/ui_style_preview.html` 只是 HTML 风格稿，不是真正游戏美术资产。
- 需要 art agent 基于「寒山玄铁 · 雾蓝侠影」去画带武侠元素的 UI。
- UI 内不要英文；属性体系为：筋骨、机敏、内劲、悟性、生命、内力、防御。

处理：

- 新增 `docs/art-ui-asset-kit-v1.md`，明确第一批 UI 美术资产：通用框架 atlas、属性图标 atlas、状态条 / Buff / 战斗 HUD。
- 新增 `prompts/templates/ui_cold_wuxia_kit.yaml`：生成无字 UI 组件 atlas（匾额、按钮、对话框、冷宣纸卡、装备槽、状态条框等）。
- 新增 `prompts/templates/ui_cold_wuxia_icon_atlas.yaml`：生成无字属性 / 状态图标 atlas，并为 7 个属性定义视觉意象。
- `prompts/tasks.yaml` 增加 3 个默认 `skip:true` 的 UI 美术任务：`ui_cold_wuxia_common_kit_v1`、`ui_cold_wuxia_attribute_icons_v1`、`ui_cold_wuxia_battle_hud_v1`。
- `docs/agents/art-memory.md` 记录：UI 图片不要英文、不要拉丁字母，优先无字，中文标签由 Godot 渲染。

经验：

- **正式 UI 资产不要依赖 AI 写字**：属性名、按钮文案、标题最好由 Godot 字体渲染；美术只画无字框体和图标，避免错字/英文/乱码。
- **属性图标要有中文语义映射**：图标本身无字，但 brief 必须写清筋骨/机敏/内劲/悟性/生命/内力/防御各自的意象，方便切图命名和程序接入。
- **生成任务默认 skip**：UI atlas 属于付费生成任务，先审 prompt / 小批次试跑，避免一次性烧钱和风格跑偏。

### 19.47 UI 风格确认：`ui_cold_wuxia_common_kit_v1` 作为后续基准（2026-05-05）

结果：

- 已生成 `assets/raw/ui/cold_wuxia/v1/ui_cold_wuxia_common_kit_v1.png`。
- 用户确认“这个风格可以，按照这个来做”。

处理：

- `ui_cold_wuxia_common_kit_v1.png` 设为后续 UI 美术 canonical reference。
- `prompts/templates/ui_cold_wuxia_kit.yaml` 和 `ui_cold_wuxia_icon_atlas.yaml` 已把该图加入 `reference_images`，后续属性图标 / 战斗 HUD 生成都会参考这张。
- `docs/art-ui-asset-kit-v1.md`、`docs/ui-style-v1.md`、`docs/agents/art-memory.md`、`docs/current-progress.md` 已同步记录。

经验：

- **风格确认后立刻固化引用图**：不要只在聊天里说“按这个做”，要把成功图写进模板 `reference_images`，否则下一批生成容易漂移。
- **后续生成顺序**：先属性图标 atlas，再战斗 HUD；通过后再切图进 `game/art/ui/cold_wuxia/`。

### 19.48 主菜单按钮最终方案：从参考素材裁切 + 书法字体合成（2026-05-08）

反馈：

- 此前所有方案（差分提取文字、系统字体重出图、gpt-image-2 重新生成）都无法一步到位
- 用户明确要求：风格对标 `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_main_menu_hover_load_gpt_v1.png`
- 按钮底框已有现成素材 `assets/raw/ui/btn_menu_3states.png`（三态并排）

**最终成功方案**：

1. 从 `btn_menu_3states.png` 裁切三态底框（不用 AI 重新生成）
2. 去除灰色背景（素材不是透明底，而是灰色 (218,217,217) 实底）
3. 用华文行楷（STXINGKA.TTF）渲染白色书法文字 + 黑色阴影
4. 合成 9 张最终按钮（3 个按钮 × 3 态），输出透明底 PNG
5. 更新 `main_menu.gd` 和 `main_menu.tscn` 适配新贴图

脚本：`scripts/gen_menu_buttons_from_ref.py`

关键技术细节：

| 步骤 | 要点 |
|------|------|
| 灰色背景去除 | `remove_gray_background()`: 检测 R≈G≈B 且亮度>180 的像素，设 alpha=0 |
| 三态裁切 | 原图水平三等分（normal/hover/pressed），getbbox() 裁掉透明边缘 |
| 文字渲染 | 华文行楷 56px，白色 (240,240,255) + 黑色阴影 GaussianBlur(3) |
| 尺寸 | 底框 resize 到 550×165，文字 y 偏移 +8px（避开顶部宝石装饰） |
| 输出 | `game/art/ui/main_menu/buttons/final/btn_<key>_<state>.png`，共 9 张 |

**为什么这次成功了**：

1. **不依赖 API 调用**：不用 gpt-image-2，不怕余额不足或连接超时
2. **底框直接复用参考素材**：保证视觉风格 100% 一致
3. **背景去除算法正确**：不是简单 threshold，而是灰度+亮度双条件
4. **字体选择正确**：华文行楷是系统自带的书法字体，风格匹配武侠
5. **文字合成方式正确**：shadow + text 分层合成，不用混合模式

经验：

- **已有高质量参考素材时，优先裁切复用，不要重新生成**：AI 生成容易风格漂移，裁切能保证 100% 一致。
- **素材可能不是透明底**：不要假设 PNG 就是透明底，要检查四角像素值。灰底素材需要先做背景去除。
- **背景去除要用多条件判断**：单纯按阈值扣色会误伤正常像素；应同时判断"通道一致性"（R≈G≈B）和"亮度"（>180），避免误删按钮装饰。
- **按钮合成比整图出图更可控**：底框+文字分层合成，每一层都可独立调整，不需要重新烧 API。
- **文字用系统自带中文字体**：华文行楷/隶书/彩云都是 Windows 内置，不需要额外下载字体。
- **文字渲染加黑色阴影**：白字直接放在暗色底框上对比度足够，但加 GaussianBlur 阴影可以增加深度感和可读性。
- **后续所有 UI 按钮都应按此流程**：先确认有没有参考素材可裁切，有则裁切+合成；没有再考虑 AI 生成。

### 19.48.1 主菜单文字白底/消失/风格问题修复（2026-05-08 旧方案，已弃用）

反馈：

- 主菜单按钮文字显示白底块，不是透明文字
- 尝试用 `CanvasItemMaterial.BLEND_MODE_MUL` 去除白底，导致文字在深色背景上消失
- 重出图（系统字体）后风格不对，太饱满，不是原来的美术字风格
- 需要调整文字大小适配底框

处理：

- **错误做法（已弃用）**：使用 `BLEND_MODE_MUL` 混合模式，试图"吃掉"白底 → 文字完全消失，因为深色背景下乘法混合会使所有像素变黑
- **错误做法（已弃用）**：用系统字体（STZHONGS.TTF）重出文字贴图 → 风格与原始美术字不符，太饱满
- **正确做法**：从 `assets/raw/ui/button/main_menu/text/v1/` 原始图差分提取文字层
  - 用 `assets/raw/ui/button/main_menu/frame/v1/ui_btn_main_frame_normal_v1.png` 作为底框基准
  - 计算 `text_rgb - frame_rgb` 的差异，提取差异像素作为文字
  - 生成透明底 PNG（RGBA），保留原始美术字的颜色和质感
  - 输出到 `game/art/ui/main_menu/buttons/text/v1/`（420x120）
- **文字缩放**：在 `main_menu.gd` 的 `_apply_button_art_text()` 中，按按钮尺寸动态缩放文字贴图
  - 当前比例：`half_w = btn_width * 0.38`，`half_h = btn_height * 0.33`
  - 可根据视觉效果微调这两个系数
- **读取存档灰态**：新增 `_update_continue_button_state()` 函数
  - 无存档时，`btn_continue.disabled = true`
  - 同时灰化按钮底框和美术字（`modulate = Color(0.58, 0.60, 0.64, 0.94)`）
- **脚本**：新增 `scripts/extract_menu_text_from_source.py`，可复用

经验：

- **不要滥用混合模式**：`BLEND_MODE_MUL` 会使所有像素向黑色偏移，不适合去除白底。正确做法是生成真正的透明底贴图。
- **保留原始美术资产**：当原始素材（带文字的按钮图）存在时，优先从原始图提取，而不是重新生成。差分提取可以保留原始风格。
- **文字贴图尺寸要适配底框**：文字贴图输出尺寸（420x120）要小于底框尺寸（496x149），留出边距；显示时用动态缩放，方便微调。
- **灰态要同时影响多个节点**：无存档时，不仅要 `disabled=true`，还要同时调整按钮和美术字节点的 `modulate`，让用户清楚看到"不可点击"状态。
- **Windows 控制台编码问题**：Python `print()` 中的 Unicode 字符（如 ✓）会导致 `UnicodeEncodeError`，改用 ASCII 字符（如 `[OK]`）。

### 19.49 ALAPI 生成主菜单按钮层需要压缩参考图并短退避（2026-05-09）

现象：

- 使用 ALAPI `https://v3.alapi.cn/api/ai/images/generations` 生成主菜单按钮底框和文字层时，第一次批量请求全部出现：
  - `RemoteProtocolError: peer closed connection without sending complete message body`
  - `502 Bad Gateway`
- `gen_assets.py` 原先把 `RemoteProtocolError` 归类为 DMXAPI 风控 / TLS 错误，触发全局 30 分钟暂停；这对 ALAPI 不合适。

原因：


- ALAPI 的 generations 接口使用 `token` header，不是标准 `Authorization: Bearer`。
- ALAPI 可传 `image` base64 参考图，但原始 PNG 直接 base64 后 payload 偏大，容易断流。
- ALAPI 的 502 / incomplete chunked read 更像临时网络 / payload 问题，应短退避重试，不应进入 DMXAPI 的 30 分钟风控暂停。

修复：

- `scripts/gen_assets.py`：
  - 新增 ALAPI 直连分支，支持完整 endpoint 和 `token` header。
  - ALAPI 参考图先压缩为 JPEG（最长边 1280，quality 88）再放入 payload。
  - ALAPI 下 `RemoteProtocolError` / TLS 连接类错误走短退避 transient。
  - ALAPI 下 502 / 503 / 504 也走短退避 transient，不走长时间 channel/IP pause。
- `prompts/templates/ui_button_frame_cold_main_menu.yaml` 与 `ui_button_text_cold_main_menu.yaml` 改为参考 `assets/raw/scene_background/ui_main_menu_full_v5.png`。
- 新增 `scripts/process_main_menu_button_layers.py`：
  - 将 AI 原图白底转透明。
  - 裁切并统一输出 512x128 的底框三态和文字层。
  - 输出到 `game/art/ui/button/btn_menu_frame_*.png` 与 `btn_menu_text_*.png`。
  - 生成 `tools/main_menu_button_layers_preview.png`。

验证：

- 6 张按钮资产均由 ALAPI + `gpt-image-2` 生成，`fallback_used=false`。
- 每张成本记录约 ¥1.2，总计约 ¥7.2。
- 输出层尺寸均为 512x128。
- Cursor lint：相关 GDScript / Python 无新增诊断。
- `python -m py_compile scripts/gen_assets.py scripts/process_main_menu_button_layers.py` 通过。

经验：

- **ALAPI 不能直接套 OpenAI SDK 认证方式**：必须使用 `token` header；通用管线要单独分支。
- **参考图先压缩再传**：ALAPI generations 接口对大 JSON payload 不稳定，压缩参考图能显著降低断流概率。
- **不同后端的错误退避不能混用**：DMXAPI 的 TLS 风控经验不应直接套到 ALAPI；否则会误等 30 分钟。
- **主菜单按钮适合底框 + 文字分层**：底框三态复用，文字单独贴图，Godot 只负责 StyleBoxTexture 状态切换和热区。

### 19.50 Godot Button 设置 flat=true 会隐藏 StyleBoxTexture 底框（2026-05-09）

现象：

- 主菜单按钮分层方案中，文字贴图正常显示，但按钮底图 / 三态底框完全看不到。
- `game/art/ui/button/btn_menu_frame_*.png` 与 `.import` 都存在，文字资源也能加载。

原因：

- `game/scripts/ui/main_menu.gd` 在 `_apply_frame_text_button()` 里设置了 `btn.flat = true`。
- Godot 的 `Button.flat=true` 会让按钮不绘制背景装饰，导致已经设置的 `normal` / `hover` / `pressed` `StyleBoxTexture` 不显示。
- 文字是子节点 `TextureRect`，不受 `flat` 影响，所以出现“只有字体，没有底图”。

修复：

- 将 `btn.flat = true` 改为 `btn.flat = false`。
- 保留原生文字透明化，仍由子节点 `TextureRect` 显示文字。

验证：

- `ReadLints` 检查 `game/scripts/ui/main_menu.gd` 无新增错误。
- 资源尺寸检查确认 3 张底框 + 3 张文字均为 `512x128`。

经验：

- **Button 使用 StyleBoxTexture 做正式底图时不能 flat=true**：需要透明文字可以隐藏 font color，但不要关掉按钮背景绘制。
- **分层 UI 排查顺序**：先确认资源存在和 import，再确认脚本加载路径，最后确认控件属性是否禁止绘制。

### 19.51 主菜单按钮三态不能分别让 AI 自由生成轮廓（2026-05-09）

现象：

- `assets/raw/ui/button/main_menu/frame/v1/ui_btn_main_frame_normal_v1.png` 的 normal 底框形状和 hover / pressed 差异过大。
- Godot Button 状态切换时，按钮外轮廓会跳变，动画效果不稳定。

原因：

- 三态底框分别由 AI 生成，即使提示词描述一致，装饰件、边角曲线、宝石位置也会发生漂移。
- 对 UI 交互态来说，三态应该共享同一透明轮廓，只改变亮度、颜色、描边、辉光或按压明暗。

修复：

- `scripts/process_main_menu_button_layers.py` 改为只使用 normal 原图作为底框母版。
- hover / pressed 不再读取各自 AI 原图，而是由程序从 normal 母版派生：
  - hover：提高亮度和饱和度，叠加轻微青色调。
  - pressed：降低亮度，保留同一 alpha 轮廓。
- 重新生成：
  - `game/art/ui/button/btn_menu_frame_normal.png`
  - `game/art/ui/button/btn_menu_frame_hover.png`
  - `game/art/ui/button/btn_menu_frame_pressed.png`
  - `tools/main_menu_button_layers_preview.png`

验证：

- `python scripts/process_main_menu_button_layers.py` 通过。
- 三态输出尺寸均为 `512x128`。
- 三态 alpha 非透明像素数均为 `34784`，bbox 均为 `(63, 6, 449, 122)`。
- mask 验证：
  - `normal_vs_hover_mask_equal=True`
  - `normal_vs_pressed_mask_equal=True`
- `ReadLints` 检查 `scripts/process_main_menu_button_layers.py` 无新增错误。

经验：

- **按钮三态要同源派生**：AI 可生成母版，但 hover / pressed 更适合程序调色和明暗处理，不能让 AI 分别重新设计轮廓。
- **交互态优先检查 alpha mask**：视觉预览之外，要验证三态透明轮廓、bbox、尺寸完全一致，避免 Godot 状态切换时跳形。

### 19.52 主菜单文字层不能只按亮度扣白底（2026-05-09）

现象：

- 主菜单按钮文字叠到底框后，金色笔画内部能看到底框绿色透出。
- 尤其是 `读取存档` 这类较暗文字，看起来像被底图染绿。

原因：

- `scripts/process_main_menu_button_layers.py` 原来对文字层复用了 `white_to_alpha()`。
- 该函数按亮度把接近白色的像素转透明，但金色文字高光本身也很亮，导致部分笔画被误处理成半透明。
- 缩放后还会产生更多半透明像素，叠加到底框时就露出绿色。

修复：

- 为文字层新增 `white_to_alpha_keep_colored()`：
  - 只把“高亮且低饱和”的像素视作白底。
  - 对高饱和金色、深棕阴影、暗描边保持不透明。
- 新增 `harden_text_alpha()`：
  - 缩放后将文字主体 alpha 固化为 255。
  - 只保留最外沿少量抗锯齿半透明。
- 重新生成：
  - `game/art/ui/button/btn_menu_text_new_game.png`
  - `game/art/ui/button/btn_menu_text_load.png`
  - `game/art/ui/button/btn_menu_text_quit.png`
  - `tools/main_menu_button_layers_preview.png`

验证：

- `python scripts/process_main_menu_button_layers.py` 通过。
- `python -m py_compile scripts/process_main_menu_button_layers.py` 通过。
- `ReadLints` 检查 `scripts/process_main_menu_button_layers.py` 无新增错误。
- 文字层半透明像素占比从约 `17%-36%` 降至约 `2%`，只剩边缘抗锯齿。

经验：

- **金色文字扣白底不能只看亮度**：要结合饱和度 / chroma，否则会把金色高光误扣成透明。
- **游戏 UI 文字主体应尽量不透明**：分层叠加时，文字主体 alpha 低会把底框颜色带进笔画里。

### 19.53 从完整主菜单参考图复用按钮时优先裁完整按钮（2026-05-09）

现象：

- 用户认可按钮三态同源派生逻辑，但认为 AI 单独生成的按钮母版不如 `assets/raw/scene_background/ui_main_menu_full_v5.png` 里的原按钮好看。
- v5 原图中的按钮已经包含更好的金属框、宝石、内板配色和文字风格。

原因：

- 之前的 AI 底框和文字层虽然功能正确，但美术风格与 v5 首界面不完全一致。
- v5 原图按钮自带文字和不同配色，强行拆成“无字底框 + 单独文字”会损失原图质感，且抠字/补底容易留下痕迹。

修复：

- `scripts/process_main_menu_button_layers.py` 新增 v5 完整按钮导出：
  - 从 `ui_main_menu_full_v5.png` 裁出 `新游戏`、`读取存档`、`离开` 三枚按钮。
  - 使用 `rembg` 抠掉背景，保留原按钮和原文字。
  - 每枚按钮再派生 normal / hover / pressed 三态，保证同一按钮三态 mask 一致。
- `game/scripts/ui/main_menu.gd` 新增 `V5_BUTTON_MAP`：
  - 优先使用 `btn_menu_v5_*_{normal,hover,pressed}.png`。
  - 如果 v5 完整按钮资源缺失，再回落到旧的共享底框 + 文字层方案。

验证：

- `python scripts/process_main_menu_button_layers.py` 通过，生成 9 张 v5 按钮状态图。
- `python -m py_compile scripts/process_main_menu_button_layers.py` 通过。
- `ReadLints` 检查 `game/scripts/ui/main_menu.gd` 与 `scripts/process_main_menu_button_layers.py` 无新增错误。
- 三枚按钮各自的 normal / hover / pressed alpha mask 完全一致。
- `tools/main_menu_button_layers_preview.png` 已切换为 v5 完整按钮预览。

经验：

- **参考图按钮已经足够好时，不要强行重绘**：优先裁原图按钮并做状态派生，能最大化保持首界面一致性。
- **完整按钮适合保留原字**：当原图文字、材质、阴影与底框融合得很好时，拆字会破坏质感；工程上可以让完整按钮优先、分层按钮兜底。
- **裁图抠背景优先用专用 matting 工具**：复杂金属边框和山水背景颜色接近时，手写颜色阈值容易残留背景，`rembg` 更稳。

### 19.54 抠图后的按钮不能按各自 alpha bbox 缩放（2026-05-09）

现象：

- v5 完整按钮接入后，`新游戏` 按钮明显比 `读取存档` 和 `离开` 大。
- 三态效果正确，但三枚按钮之间的视觉尺寸不统一。

原因：

- `rembg` 对三枚按钮的透明边界不同。
- `fit_v5_button_on_canvas()` 原来复用了 `fit_on_canvas()`，会按每张图自己的 alpha bbox 裁切再缩放。
- alpha bbox 越紧，最终缩放越大，导致 `新游戏` 看起来比另外两枚大。

修复：

- v5 完整按钮改为按固定裁图尺寸统一缩放：
  - 三枚按钮都来自 `575x155` 裁图。
  - 缩放比例统一由原始裁图尺寸和 `512x128` 输出画布计算。
  - 不再按每张图的 alpha bbox 单独决定缩放比例。
- 重新生成 `btn_menu_v5_*_{normal,hover,pressed}.png` 与 `tools/main_menu_button_layers_preview.png`。

验证：

- `python scripts/process_main_menu_button_layers.py` 通过。
- `python -m py_compile scripts/process_main_menu_button_layers.py` 通过。
- `ReadLints` 检查 `scripts/process_main_menu_button_layers.py` 无新增错误。
- 三枚按钮 normal 输出横向 bbox 已统一到约 `x=64-440`。
- 每枚按钮的 normal / hover / pressed mask 仍保持完全一致。

经验：

- **同组 UI 资源要用同一几何基准缩放**：抠图 alpha bbox 只能用于清透明边，不能用于决定同组按钮的最终尺寸。
- **先统一尺寸，再做三态派生**：否则即使每个按钮自己的三态稳定，不同按钮之间仍会视觉不齐。

### 19.55 UI 资产生产流程要沉淀成项目 Skill（2026-05-09）

现象：

- 主菜单按钮从参考图裁切、抠图、三态派生、Godot 接入，连续踩了多个可复发问题。
- 后续背包、装备、商店等 UI 还会大量复用类似流程，靠对话记忆容易遗漏。

原因：

- UI 资产生产不是单张图片问题，而是“参考图 → 透明 PNG → 三态 → Godot 主题覆盖 → 预览 → 验证”的完整管线。
- 如果没有固定 checklist，后续 AI 容易重复：
  - 独立生成三态导致轮廓跳动。
  - 按每张 alpha bbox 缩放导致同组控件大小不一。
  - `UI_THEME.style_button()` 或 `Button.flat` 覆盖贴图样式。
  - 修复后忘记写经验记录。

修复：

- 新增项目级 Cursor Skill：`.cursor/skills/producing-godot-ui-assets/SKILL.md`。
- Skill 覆盖：
  - 参考图裁切 / 分层或完整按钮复用。
  - 同组 UI 的统一 canvas、统一裁图几何和统一缩放规则。
  - alpha 清理、金色文字保色、三态同源派生。
  - Godot `StyleBoxTexture` 接入与 `flat=false` 规则。
  - `UI_THEME.style_button()` 覆盖风险。
  - 预览、mask 检查、脚本编译、lint、场景验证和经验记录。

验证：

- Skill 文件 132 行，低于 500 行。
- `ReadLints` 检查 `.cursor/skills/producing-godot-ui-assets/SKILL.md` 无新增错误。
- 用 subagent 做无 Skill 基线测试，确认自然流程会遗漏部分关键约束。
- 用 subagent 读取新 Skill 后应用到“背包面板按钮三态生产”场景，最终复测通过。

经验：

- **复杂资产管线要写成 Skill，不只写经验日志**：经验日志适合追溯坑，Skill 适合让后续 Agent 直接执行正确流程。
- **Skill 不能过度绑定一次案例**：可以保留主菜单作为例子，但脚本名、按钮名、mask 检查必须提示按目标 UI 替换。
- **写 Skill 也要验证**：用一个非主菜单场景复测，能及时发现模板硬编码问题。

### 19.56 图像批量接口需单独成文：ALAPI 非 DMXAPI（2026-05-09）

现象：

- 协作者仍默认「量产图 = DMXAPI + OpenAI SDK」，不知道当前 `gen_assets.py` 已支持 **ALAPI**（`v3.alapi.cn`），且认证为 **`token` 头** 而非 `Authorization: Bearer`。
- `AGENTS.md`、美术流水线文档多处仍写「DMXAPI 主」，与仓库实际可选后端不一致。
- §19.49 已记录 ALAPI 踩坑，但缺少一页「端点 + 环境变量 + 与 DMX 差异」的速查。

原因：

- 接口分散在 `gen_assets.py` 实现与 `.env.example` 注释中，没有独立规范文档。
- DMXAPI 与 ALAPI 的 URL、鉴权、SDK 用法不同，仅靠「改 base_url」容易配错。

修复：

- 新增 `docs/alapi-image-api.md`：端点、`.env` 示例、`token` 头、与 DMXAPI 对照、相关脚本入口。
- 更新 `AGENTS.md` 关键决策第 3 条：明确多后端含 ALAPI，并指向上述文档。
- 更新 `docs/art-pipeline.md`、`docs/dmxapi-setup.md` 文首交叉引用；修正 `.env.example` 选项 D 的 `OPENAI_BASE_URL` 写法说明（根路径与完整 path 均可）。

验证：

- 文档内链接路径与 `scripts/gen_assets.py` 中 `_alapi_generations_url` 行为一致。

经验：

- **一种后端一页规范**：OpenAI 兼容站与 ALAPI 这种「半兼容」要分开写，避免把 DMX 经验套到 ALAPI。
- **决策文档要与 .env 同步**：新人先看 `AGENTS.md` + `alapi-image-api.md` 再配环境。

---

## 20. 后端切换：DMXAPI → ALAPI 永久化（2026-05-09）

### 20.1 决策

用户指定 ALAPI（`v3.alapi.cn/api/ai/images/generations`，`token` 头）为唯一后端，不再使用 DMXAPI。

### 20.2 已执行

- `.env` 已清理旧 DMXAPI key，仅保留 ALAPI 配置
- `.env.example` 已更新，ALAPI 为唯一推荐选项
- `AGENTS.md` 已更新后端引用
- `docs/current-progress.md` 已移除 DMXAPI 欠费阻塞项
- `scripts/gen_assets.py` 已完整支持 ALAPI（`_call_alapi_generation()` + `_alapi_reference_base64()`）

### 20.3 注意事项

- ALAPI 使用 `token` 头而非 `Authorization: Bearer`
- POST endpoint: `{base_url}/images/generations`
- 参考图需先压缩为 JPEG base64（`_alapi_reference_base64()`）避免 payload 过大
- 后续所有出图操作统一走 `gen_assets.py`，不再提 DMXAPI

---

## 21. OkRouter Gemini Vision 接入（2026-05-09）

### 21.1 背景

ALAPI 只提供图像生成，不提供 chat/vision 接口。无法用已有后端做图片分析。
用户提供 OkRouter + Gemini 3.1 Pro Preview 作为 vision 后端。

### 21.2 配置

```env
OKROUTER_API_KEY=sk-...
OKROUTER_BASE_URL=https://api.okrouter.com/v1
OKROUTER_VISION_MODEL=gemini-3.1-pro-preview-customtools
```

### 21.3 已落地的两个脚本

| 脚本 | 用途 |
|---|---|
| `scripts/qa/review_image.py` | 通用图片分析：传任意图 + 自定义检查项 → JSON 报告 |
| `scripts/qa/review_module_atlas.py` | Atlas 专项：按 `scene-element-kit-spec.md` 逐项检查 + 元素数校验 |

### 21.4 注意事项

- 图片需先压缩为 JPEG（`MAX_IMAGE_SIDE=1568, QUALITY=75`），否则 7MB PNG 会超时
- Gemini 返回的 JSON 可能被 markdown 包裹，脚本做了 ```json 剥离
- Vision 输出是"视觉判断"，非像素级精确——适合风格/内容/违禁项检查，不适合 alpha 通道检查
- `gen_assets.py` 仍用 ALAPI 出图，Vision 用 OkRouter 审核




## 20. 后端切换：DMXAPI → ALAPI 永久化（2026-05-09）

### 20.1 决策

用户指定 ALAPI（`v3.alapi.cn/api/ai/images/generations`，`token` 头）为唯一后端，不再使用 DMXAPI。

### 20.2 已执行

- `.env` 已清理旧 DMXAPI key，仅保留 ALAPI 配置
- `.env.example` 已更新，ALAPI 为唯一推荐选项
- `AGENTS.md` 已更新后端引用
- `docs/current-progress.md` 已移除 DMXAPI 欠费阻塞项
- `scripts/gen_assets.py` 已完整支持 ALAPI（`_call_alapi_generation()` + `_alapi_reference_base64()`）

### 20.3 注意事项

- ALAPI 使用 `token` 头而非 `Authorization: Bearer`
- POST endpoint: `{base_url}/images/generations`
- 参考图需先压缩为 JPEG base64（`_alapi_reference_base64()`）避免 payload 过大
- 后续所有出图操作统一走 `gen_assets.py`，不再提 DMXAPI

---

## 22. Tiled 才是模块化场景拼装编辑器（2026-05-10）

### 22.1 现象

- 场景元素 atlas / 66 个 PNG 已经形成素材库后，继续用 Python PIL 按坐标盲排完整场景不可控。
- PIL 盲排无法直观看到可行走路面、建筑遮挡、碰撞边界、NPC 站位和交互触发区。

### 22.2 决策

- Tiled 作为模块化 2.5D 场景拼装的 source of truth。
- Python 只负责导入和校验，不再作为正式布局编辑器。
- Godot 继续使用现有可行走 Field，不重写探索系统；Tiled 数据导入到 `SceneScript`。

### 22.3 已落地

- 新增 `docs/tiled-godot-scene-pipeline.md`：
  - Tiled 地图设置、层命名、自定义属性、对象层规范、导入命令、当前限制。
- `SceneScript` 新增 `scene_objects: Array[Dictionary]`。
- `field_walkable_controller.gd` 新增 `_spawn_scene_objects()`：
  - 按 `texture`、`pos`、`scale`、`rotation`、`z_index` 渲染 `Sprite2D`。
  - 支持 `require_flag` / `hide_flag` 条件显示。
- 新增 `scripts/import_tiled_scene.py`：
  - 支持 Tiled `.tmj/.json`。
  - 支持内嵌 image collection tileset，也支持外部 `.tsj/.json/.tsx` image collection tileset。
  - 导入 `scene_objects`、`player_spawn`、`npcs`、`exits`、`collision_rects`、`trigger_zones`。
- 新增 `scripts/create_tiled_tileset.py`：
  - 从 `game/art/modules/{ground,building,veg,prop}/` 扫描 PNG。
  - 自动生成 Tiled image collection `.tsx`。
  - 写入 `id`、`category`、`z_index` 自定义属性。
  - 使用相对图片路径，避免 `.tsx` 绑定本机绝对路径。
- 新增 `scripts/generate_linxi_tutorial_tiled.py`：
  - 读取 `scene_elements.tsx`，按类别 / 文件名提示选择素材。
  - 用固定构图模板生成 `linxi_tutorial.tmj`，不是让大模型自由拼图。
  - 同时输出 PNG 预览，用户只做审核和微调。
- 新增 `maps/tiled/sample_scene.tmj` 与导入样例 `game/data/scenes/sample_tiled_import.tres`。
- 新增 `game/art/modules/` 与 `maps/tiled/tilesets/` 目录骨架。

### 22.4 验证

- `python scripts/import_tiled_scene.py maps/tiled/sample_scene.tmj --out game/data/scenes/sample_tiled_import.tres --scene-id sample_tiled_import --display-name "Tiled 导入样例"` 通过。
- `python scripts/create_tiled_tileset.py game/art/backgrounds/bg_linxi_main.png --out maps/tiled/tilesets/sample_backgrounds.tsx --name sample_backgrounds` 通过。
- `sample_scene.tmj` 改用外部 `sample_backgrounds.tsx` 后，导入器仍能解析并生成 `res://art/backgrounds/bg_linxi_main.png`。
- `python scripts/generate_linxi_tutorial_tiled.py --tileset maps/tiled/tilesets/sample_backgrounds.tsx --out maps/tiled/linxi_tutorial_sample.tmj --preview tools/linxi_tutorial_tiled_preview_sample.png` 通过。
- `linxi_tutorial_sample.tmj` 可继续由 `import_tiled_scene.py` 导入为 `linxi_tutorial_sample.tres`。
- `python -m py_compile scripts/import_tiled_scene.py scripts/create_tiled_tileset.py scripts/generate_linxi_tutorial_tiled.py` 通过。
- `ReadLints` 检查 `scene_script.gd`、`field_walkable_controller.gd`、`import_tiled_scene.py`、`create_tiled_tileset.py`、`generate_linxi_tutorial_tiled.py` 无新增错误。

### 22.5 经验

- **可视化布局交给 Tiled**：路、建筑、植物、交互物、碰撞和触发区必须人眼可调，不能再靠 PIL 盲排。
- **Tiled 不是传统 TileMap 限定**：本项目把它当 Sprite2D 模块摆放器，用 image collection tileset 承载厚涂 PNG。
- **导入器输出数据，不输出逻辑**：系统行为仍走 `SceneScript` + `SceneRouter.resolve_action()`，保持内容和代码边界清晰。
- **`.tsx` 必须用相对路径**：绝对路径会把 Tiled 项目锁死在当前电脑盘符，生成器要统一输出相对路径。
- **首版布局必须模板化生成**：不要让大模型“自由摆图块”；用固定构图 + 文件名规则生成可审核初稿，Tiled 只负责可视化校准。
- **不能用完整背景图当 sample tile**：这会生成“几张原图堆一起”的假场景，误导审核；没有真实模块 PNG / `scene_elements.tsx` 时生成器必须直接失败。

### 22.6 模块 PNG 不是无缝 tile，必须先做语义清单（2026-05-10）

现象：

- `linxi_tutorial.tmj` 虽然已经不再把完整背景图当素材堆叠，但整体仍显得凌乱。
- 根因不是 Tiled 工具本身，而是生成器只知道 `ground/building/veg/prop` 粗分类和文件名提示，不能判断每个 PNG 是否是：
  - 可连续拼的路面；
  - 完整建筑；
  - 建筑零件；
  - 前景遮挡；
  - 低可见度 / 空白污染素材；
  - 不适合当前场景首版的混合素材。
- 典型例子：`road_dirt_linxi_straight_a` 同时包含土路与石板条，盲放后会在画面底部露出不相关石板，造成“拼错图块”的观感。

修复：

- 生成 `tools/scene_module_contact_sheets/{ground,building,veg,prop}_contact_sheet.png`，先用带编号联系表看清每个素材。
- 新增 `maps/tiled/scene_elements_manifest.json`：
  - 记录素材 `purpose`、`recommended`、`z_index`。
  - 把插画式模块与真正适合当前首版布局的模块区分开。
- `scripts/generate_linxi_tutorial_tiled.py` 改为读取 manifest，并点名使用少量确定素材：
  - 主路：曲线路 / 岔路模块；
  - 建筑：完整客栈、完整铁匠铺、完整房屋墙体；
  - 植被：边缘竹林、灌木、草簇；
  - 交互物：路牌、石坛、车、木桶。
- 移除预览图里的额外黄褐色引导线，避免误判为真实地形。
- 将 `road_dirt_linxi_straight_a` 标记为不推荐用于当前首版，避免混合素材污染路面。

验证：

- `python -m py_compile scripts/generate_linxi_tutorial_tiled.py scripts/import_tiled_scene.py` 通过。
- `python scripts/generate_linxi_tutorial_tiled.py` 通过，重新生成 `maps/tiled/linxi_tutorial.tmj` 与 `tools/linxi_tutorial_tiled_preview.png`。
- `python scripts/import_tiled_scene.py maps/tiled/linxi_tutorial.tmj --out game/data/scenes/linxi_tutorial.tres --scene-id linxi_tutorial --display-name "林西村 · 新手关"` 通过。
- `ReadLints` 检查 `scripts/generate_linxi_tutorial_tiled.py`、`maps/tiled/scene_elements_manifest.json`、`game/data/scenes/linxi_tutorial.tres` 无新增错误。

经验：

- **厚涂模块不是无缝 tile**：不要按 TileMap 思路密集铺满；应按“少量大模块 + 明确层级 + 留白路径”拼场景。
- **生成器必须读语义清单**：文件名只能做初筛，不能代替 `purpose/recommended/z_index`。
- **预览图不能混入调试引导层**：额外画线会误导审核，真实元素和调试辅助必须分离。
- **Windows PowerShell 不要套 Bash 写法**：`python - <<'PY'` 和部分环境中的 `&&` 都会失败；复杂 Python 片段用 PowerShell here-string 管道，串联命令用 `; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }`。

### 22.7 新手关改用整图背景，Tiled 只负责隐形玩法层（2026-05-10）

现象：

- 即使加了素材联系表和 manifest，厚涂 PNG 模块仍然像插画碎片，建筑和植物有“七零八碎”的拼图感。
- 对本项目当前资产质量来说，继续做模块拼接会把精力消耗在识别和摆放碎片上，难以达到完整场景美术效果。

决策：

- 新手关采用“完整背景图 + 隐形玩法层”：
  - 背景图负责视觉完整性；
  - Tiled 只维护 `spawn`、`collisions`、`triggers`、`exits`、`npcs`；
  - Godot 继续用 `SceneScript.background_path` + `FieldWalkableController` 渲染和交互。
- 这条路线更符合 GPT Image 场景出图能力，也符合项目早期“AVG/RPG 背景整图 + 运行时角色叠加”的方向。

修复：

- 新增 `prompts/templates/scene_background_walkable_full.yaml`：
  - 明确要求完整场景图，不是 tileset / atlas / 拼图；
  - 要求中央 16:9 安全区、清晰宽阔可行走主路、无人物 / NPC / 动物。
- `prompts/tasks.yaml` 新增 `scene_linxi_tutorial_full_bg`。
- 通过 ALAPI + `gpt-image-2` 生成：
  - `assets/raw/scene/v2/scene_linxi_tutorial_full_bg.png`
  - `assets/raw/scene/v2/scene_linxi_tutorial_full_bg.meta.json`
- 将 1536×1024 原图中间 16:9 安全区裁切并缩放为：
  - `game/art/backgrounds/bg_linxi_tutorial_full.png`（1920×1080）
  - `tools/linxi_tutorial_full_bg_1920_preview.png`
- 新增 `maps/tiled/linxi_tutorial_full_bg.tmj`：
  - 无 tileset；
  - 无 scene object；
  - 只包含隐形矩形碰撞、触发区、出口、NPC、出生点。
- 用 `import_tiled_scene.py` 导入为 `game/data/scenes/linxi_tutorial.tres`，并传入：
  - `--background-path res://art/backgrounds/bg_linxi_tutorial_full.png`
- 新增碰撞审核预览：
  - `tools/linxi_tutorial_full_bg_collision_overlay.png`
- 新增 `SceneRouter.START_FIELD_SCENE = &"linxi_tutorial"`，主菜单新游戏和空存档默认入口改走新手关。

验证：

- `python scripts/gen_assets.py --task scene_linxi_tutorial_full_bg --dry-run` 通过。
- `python scripts/gen_assets.py --task scene_linxi_tutorial_full_bg --budget 5` 通过，`fallback_used=false`，成本约 ¥1.2。
- `python scripts/import_tiled_scene.py maps/tiled/linxi_tutorial_full_bg.tmj --out game/data/scenes/linxi_tutorial.tres --scene-id linxi_tutorial --display-name "林西村 · 新手关" --background-path res://art/backgrounds/bg_linxi_tutorial_full.png` 通过。
- `ReadLints` 检查 `scene_router.gd`、`main_menu.gd`、`save_manager.gd`、`test_scene_router_field_smart.gd`、`linxi_tutorial.tres` 无新增错误。
- 当前终端没有 `Godot` / `GODOT_BIN`，未能执行 `Godot --headless --path game --script res://tests/test_scene_router_field_smart.gd`；需在本机配置 Godot CLI 后补跑。

经验：

- **厚涂场景优先整图，不要强行模块拼图**：除非素材天然是规则 tile / 明确组件，否则完整背景图的视觉一致性远高于拼接。
- **碰撞层与视觉层分离**：背景图可以是完整插画，玩法数据仍可由 Tiled 隐形对象层维护，程序完全能实现。
- **最终游戏背景尽量 16:9**：本项目 Field 以 1920×1080 归一化坐标管理碰撞，出图后应裁成 16:9，避免 TextureRect 裁切/缩放导致坐标偏移。
- **入口场景要集中成常量**：新手关成为真实入口后，不要在主菜单、存档、商店返回等处散落 `"ch1_s1_road"` 默认值。

### 22.8 整图背景要强调 2.5D 体块感，动态物件用程序化叠加层（2026-05-10）

现象：

- 第一张完整新手关背景已经比碎 PNG 拼图稳定，但建筑仍偏“原画插画”，体块、台阶、屋檐厚度和接地阴影不够像可走的 2.5D 游戏场景。
- 用户提出希望有一些 3D 感，并询问旗子、炊烟等动态物件能否实现。

决策：

- 背景图继续保持整图路线，但 prompt 从“厚涂插画”推进到“2.5D 预渲染 3D 场景 + 手绘武侠贴图”：
  - 强调厚屋檐、侧墙、台阶高度、墙根投影、接地阴影；
  - 禁止照片级 3D / 低多边形卡通，避免偏离项目港漫武侠风。
- 动态物件不画进背景图，而作为运行时叠加层：
  - `banner`：程序化布旗摆动；
  - `smoke`：程序化烟雾粒子 / puff；
  - `glow`：炉火 / 灯笼光晕闪烁。

修复：

- `prompts/templates/scene_background_walkable_full.yaml` 增加 2.5D 预渲染体块感要求。
- `prompts/tasks.yaml` 新增 `scene_linxi_tutorial_3d_bg`。
- 通过 ALAPI + `gpt-image-2` 生成：
  - `assets/raw/scene/v2/scene_linxi_tutorial_3d_bg.png`
  - `assets/raw/scene/v2/scene_linxi_tutorial_3d_bg.meta.json`
- 将 3D 体块感版本裁切为游戏背景：
  - `game/art/backgrounds/bg_linxi_tutorial_full.png`
  - `tools/linxi_tutorial_3d_bg_1920_preview.png`
- `SceneScript` 新增 `animated_props: Array[Dictionary]`。
- `scripts/import_tiled_scene.py` 支持读取 Tiled `animated_props` / `animated` / `atmosphere` 对象层。
- `field_walkable_controller.gd` 新增 `_spawn_animated_props()`：
  - `banner`：`Line2D` + `Polygon2D` + Tween 循环；
  - `smoke`：多个 radial puff `Sprite2D` 循环上升淡出；
  - `glow`：radial `ImageTexture` + Tween alpha 闪烁。
- `maps/tiled/linxi_tutorial_full_bg.tmj` 新增 `animated_props` 层，配置：
  - 酒馆旗子摆动；
  - 民居炊烟；
  - 铁匠铺烟囱烟；
  - 铁匠铺炉火光；
  - 酒馆灯笼光。
- 重新导入 `game/data/scenes/linxi_tutorial.tres`，包含 `animated_props` 数据。
- 新增审核图：
  - `tools/linxi_tutorial_3d_collision_animation_overlay.png`

验证：

- `python scripts/gen_assets.py --task scene_linxi_tutorial_3d_bg --dry-run` 通过。
- `python scripts/gen_assets.py --task scene_linxi_tutorial_3d_bg --budget 5` 通过，`fallback_used=false`，成本约 ¥1.2。
- `python -m py_compile scripts/import_tiled_scene.py` 通过。
- `python scripts/import_tiled_scene.py maps/tiled/linxi_tutorial_full_bg.tmj --out game/data/scenes/linxi_tutorial.tres --scene-id linxi_tutorial --display-name "林西村 · 新手关" --background-path res://art/backgrounds/bg_linxi_tutorial_full.png` 通过。
- Python 资源校验确认：
  - `bg_linxi_tutorial_full.png` 为 1920×1080；
  - `linxi_tutorial.tres` 含 `animated_props`；
  - 5 个动态物件 id 均已写入。
- `ReadLints` 检查 `scene_script.gd`、`field_walkable_controller.gd`、`import_tiled_scene.py`、`linxi_tutorial.tres`、prompt 文件无新增错误。

经验：

- **3D 感优先写成“预渲染 2.5D + 手绘贴图”**：直接说 3D 容易走向照片级 / CG；必须同时约束港漫武侠贴图和明亮色彩。
- **小动画适合程序化叠加，不适合烘进背景**：旗子、烟、火光这类循环氛围物件应独立于背景，方便调位置、速度和显隐条件。
- **Tiled 可以继续做隐形 source of truth**：即使视觉是整图，`animated_props` 也可作为对象层维护，不必写死在 GDScript。

### 22.9 参考图要约束“空间语言”，不是只说 3D 感（2026-05-10）

现象：

- 仅在 prompt 中写“2.5D 预渲染体块感”仍不够，生成图虽然更立体，但建筑还是偏漂亮插画，和地面分离感不足。
- 用户提供一张老式 2.5D ARPG 村落截图后，关键差异变清楚：
  - 建筑有立面、屋檐厚度、柱子、台阶；
  - 建筑与地面之间有强接地阴影；
  - 建筑会自然遮挡玩家和地面；
  - 地面有石板、杂草、围栏、桶、晾衣架等尺度物；
  - 画面更像“可玩的关卡截图”，不是“场景原画”。

修复：

- 将用户参考图归档：
  - `assets/_style_bible/scene_reference/ref_prerendered_arpg_village.png`
- 新增模板 `prompts/templates/scene_background_prerendered_arpg.yaml`：
  - 引用该参考图；
  - 明确写“Use the reference image for spatial language only”；
  - 强调 `solid occluding volumes`、`contact shadows`、`wall height`、`roof overhang`、`courtyard ground plane`。
- `prompts/tasks.yaml` 新增 `scene_linxi_tutorial_prerendered_bg`。
- 通过 ALAPI + `gpt-image-2` 生成：
  - `assets/raw/scene/v2/scene_linxi_tutorial_prerendered_bg.png`
  - `assets/raw/scene/v2/scene_linxi_tutorial_prerendered_bg.meta.json`
- 将生成图裁切接入：
  - `game/art/backgrounds/bg_linxi_tutorial_full.png`
  - `tools/linxi_tutorial_prerendered_bg_1920_preview.png`
- 按新画面重新对齐 `maps/tiled/linxi_tutorial_full_bg.tmj` 中的碰撞、出口、NPC 和 `animated_props` 坐标。
- 重新导入 `game/data/scenes/linxi_tutorial.tres`。
- 新增审核图：
  - `tools/linxi_tutorial_prerendered_collision_animation_overlay.png`

验证：

- `python scripts/gen_assets.py --task scene_linxi_tutorial_prerendered_bg --dry-run` 通过。
- `python scripts/gen_assets.py --task scene_linxi_tutorial_prerendered_bg --budget 5` 通过，`fallback_used=false`，成本约 ¥1.2。
- `python scripts/import_tiled_scene.py maps/tiled/linxi_tutorial_full_bg.tmj --out game/data/scenes/linxi_tutorial.tres --scene-id linxi_tutorial --display-name "林西村 · 新手关" --background-path res://art/backgrounds/bg_linxi_tutorial_full.png` 通过。
- Python 校验确认：
  - `bg_linxi_tutorial_full.png` 为 1920×1080；
  - `linxi_tutorial.tres` 含 `animated_props`；
  - `scene_objects = []`，没有回到碎图拼接路线。
- `python -m py_compile scripts/import_tiled_scene.py` 通过。
- `ReadLints` 检查 prompt、Tiled map、`linxi_tutorial.tres` 无新增错误。

经验：

- **不要只说“更 3D”**：模型容易理解成光影更漂亮，但仍是原画；要说“老式 2.5D ARPG 预渲染关卡截图”。
- **参考图用途要写清楚**：使用参考图的 camera / occlusion / contact shadow / clutter scale / ground plane，不照搬人物、UI、水印和具体内容。
- **建筑要被描述为会遮挡玩家的 solid volume**：这比“建筑有立体感”更能逼出墙体、屋檐、柱子和接地阴影。

### 22.10 白天版要拆分参考图职责：暗版管体块，亮版管色彩（2026-05-10）

现象：

- `scene_linxi_tutorial_prerendered_bg` 的建筑体块、屋檐、台阶、接地阴影已经更接近老式 2.5D ARPG，但整体明显偏暗，像傍晚 / 阴天。
- 用户希望保留新版建筑的突出感，同时把道路、植物和整体光照拉回之前明亮清晨版本。

修复：

- 新增模板 `prompts/templates/scene_background_prerendered_daylight_mix.yaml`。
- 模板使用三张参考图，并明确拆分职责：
  - `ref_prerendered_arpg_village.png`：只管空间语言、镜头、遮挡、尺度；
  - `scene_linxi_tutorial_prerendered_bg.png`：只管建筑体块、立面、屋檐、接地阴影；
  - `scene_linxi_tutorial_3d_bg.png`：只管白天色彩、黄土路、绿色植物、明亮清晨氛围。
- `prompts/tasks.yaml` 新增 `scene_linxi_tutorial_prerendered_day_bg`。
- 通过 ALAPI + `gpt-image-2` 生成：
  - `assets/raw/scene/v2/scene_linxi_tutorial_prerendered_day_bg.png`
  - `assets/raw/scene/v2/scene_linxi_tutorial_prerendered_day_bg.meta.json`
- 裁切并接入：
  - `game/art/backgrounds/bg_linxi_tutorial_full.png`
  - `tools/linxi_tutorial_prerendered_day_bg_1920_preview.png`
- 重新对齐 `maps/tiled/linxi_tutorial_full_bg.tmj` 中的碰撞、出口、NPC 和 `animated_props` 坐标。
- 重新导入 `game/data/scenes/linxi_tutorial.tres`。
- 新增审核图：
  - `tools/linxi_tutorial_prerendered_day_collision_animation_overlay.png`

验证：

- `python scripts/gen_assets.py --task scene_linxi_tutorial_prerendered_day_bg --dry-run` 通过。
- `python scripts/gen_assets.py --task scene_linxi_tutorial_prerendered_day_bg --budget 5` 通过，`fallback_used=false`，成本约 ¥1.2。
- Python 校验确认：
  - `bg_linxi_tutorial_full.png` 为 1920×1080；
  - `linxi_tutorial.tres` 含 `animated_props`；
  - `scene_objects = []`，仍保持整图 + 隐形玩法层路线。
- `python -m py_compile scripts/import_tiled_scene.py` 通过。
- `ReadLints` 检查 `scene_background_prerendered_daylight_mix.yaml`、`tasks.yaml`、`linxi_tutorial_full_bg.tmj`、`linxi_tutorial.tres` 无新增错误。

经验：

- **多参考图必须指定角色**：不要让模型平均融合；要明确“这张管结构，那张管颜色”。
- **白天版要显式否定 dusk/evening/night/gloomy**：否则参考图中的暗调会把生成结果拉回傍晚。
- **先选定视觉，再重贴隐形层**：同一个 `linxi_tutorial.tres` 可复用玩法合同，但每次背景构图变化后都要重新对齐碰撞和动画坐标。

### 22.11 试玩入口必须确认走新手关 SceneScript（2026-05-10）

现象：

- 新手关背景、动画层、碰撞盒已经写入 `linxi_tutorial.tres`，但检查发现 `SceneRouter.START_FIELD_SCENE` 一度指向 `ch1_s0_linxi_main_walkable`。
- 这会导致用户点击“新游戏”时进不到刚接好的 `linxi_tutorial`，误以为场景没有接入游戏。

修复：

- 将 `game/scripts/autoload/scene_router.gd` 的 `START_FIELD_SCENE` 改回：
  - `&"linxi_tutorial"`
- 主菜单仍通过 `SceneRouter.go_field_smart(SceneRouter.START_FIELD_SCENE)` 进入，不散落硬编码。
- `linxi_tutorial.tres` 当前包含：
  - `background_path = "res://art/backgrounds/bg_linxi_tutorial_full.png"`
  - `is_walkable = true`
  - `animated_props`
  - `collision_rects`
  - `trigger_zones`
  - `exits`
  - `npcs`

验证：

- Python 静态校验通过：
  - 背景存在且为 1920×1080；
  - `linxi_tutorial.tres` 含背景、碰撞、触发、出口、NPC、动画物件；
  - `SceneRouter.START_FIELD_SCENE == &"linxi_tutorial"`；
  - `main_menu.gd` 使用 `SceneRouter.START_FIELD_SCENE`。
- `ReadLints` 检查 `scene_router.gd`、`main_menu.gd`、`field_walkable_controller.gd`、`linxi_tutorial.tres` 无新增错误。
- 当前环境仍未配置 `GODOT_BIN`，`Godot --headless` 自动化测试跳过；需要在 Godot 编辑器内实机走动验收。

经验：

- **接入游戏不等于资源生成完成**：必须确认入口路由、SceneScript、背景、碰撞、动画层全部连上。
- **试玩入口要用常量集中控制**：切换新手关 / 主街时，只改 `START_FIELD_SCENE`，不要改多处硬编码。

### 22.12 新手关动态物件要分清“世界层”和“UI层”（2026-05-10）

现象：

- 新手关红旗使用 `Line2D` + `Polygon2D` 程序绘制，视觉像调试占位，不像正式资产。
- 红旗、炊烟等 `animated_props` 的 `z_index` 较高，打开背包 UI 时可能盖在 UI 上。
- 屋顶黄色闪烁来自 `inn_lantern_glow`，位置不像灯笼，误读为“屋顶发光”。

修复：

- 新增正式贴图资源：
  - `game/art/props/linxi_red_banner.png`
  - `game/art/props/blacksmith_hammer.png`
  - `game/art/characters/npc_blacksmith_idle.png`
- `field_walkable_controller.gd` 新增：
  - `texture_sway`：用 PNG 旗帜贴图做轻微摆动，不再画多边形红旗。
  - `hammer`：用锤子 PNG 做循环敲打动作。
- `field_walkable.tscn` 设置：
  - `Background.z_index = -200`
  - `WorldContainer.z_index = -100`
  - UI 控件仍保持默认层级，确保世界物件不盖住背包 / 装备 / 任务面板。
- 从 `maps/tiled/linxi_tutorial_full_bg.tmj` 移除 `inn_lantern_glow`，只保留：
  - `rear_house_cooking_smoke`
  - `smithy_chimney_smoke`
  - `smithy_forge_glow`
- 修正 `scripts/import_tiled_scene.py`，让 Tiled `animated_props` 可导入 `texture` / `texture_path` 属性。

验证：

- `linxi_tutorial.tres` 已重新导入，`animated_props` 中红旗类型为 `texture_sway`，不再有 `inn_lantern_glow`。
- `linxi_tutorial.tres` 新增铁匠铺 `blacksmith_hammer_loop`，贴图路径为 `res://art/props/blacksmith_hammer.png`。

经验：

- **世界动画不要靠高 z_index 压 UI**：探索场景里世界层整体应低于 HUD / 面板层，局部排序只在世界层内部解决。
- **调试动画和正式资产要分阶段**：程序画旗子适合验证数据管线，正式接入时应换成贴图或 sprite sheet，再用轻量 tween 做动态。
- **炊烟方案可以复用**：用径向透明纹理 + 多个 `Sprite2D` puff + 位置/缩放/alpha tween，成本低、效果稳定，适合烟、雾、灰尘等氛围物件。
- **Tiled 导入命令要用当前参数格式**：`python scripts/import_tiled_scene.py <map> --out <tres> --scene-id <id> --display-name "<name>" --background-path <res_path>`，不要使用旧的位置参数格式。

### 22.13 新手关角色比例要让场景数据 scale 真正生效（2026-05-10）

现象：

- 用户反馈主角 / NPC 相对房子太小。
- `linxi_tutorial.tres` 里 NPC 已有 `scale` 字段，但 `npc_node.gd` 和 `field_walkable_controller.gd` 仍按固定 `96 / origin_size` 缩放，导致 Tiled 数据里的比例调节无效。

修复：

- `player.gd` 新增 `VISUAL_SCALE = 1.35`，主角行走 sprite 在新手关里更接近建筑尺度。
- `npc_node.gd` 改为优先使用 `sprite_scale`。
- `field_walkable_controller.gd` 加载 NPC 贴图后使用 `npc.sprite_scale`，不再覆盖为固定 96px。
- `linxi_tutorial_full_bg.tmj` 中：
  - 刑樊天 `scale` 从 `0.08` 调到 `0.15`。
  - 新增铁匠铺老板 `blacksmith_liu`，使用 `npc_blacksmith_idle.png`，`scale = 0.62`。
- 新增 `game/data/dialogs/ch1_tutorial_blacksmith.tres`，铁匠可交互对话。

经验：

- **数据字段必须被运行时代码消费**：只在 `.tres` / Tiled 里写 `scale` 不够，导入和实例化路径都要确认不会被硬编码覆盖。
- **大背景场景里的角色尺度要按视觉审核调**：1920×1080 整图背景不是 tilemap，角色比例更依赖实际建筑体量，不能只沿用旧野外 demo 的 96px NPC 标准。

### 22.14 第一场景 UI 可先接展示稿，不急着重做功能图（2026-05-11）

现象：

- 用户确认以下 UI 设计稿质量已经可用，只需要整体调亮：
  - `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_field_hud_screen_gpt_v1.png`
  - `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_inventory_screen_gpt_v1.png`
  - `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_equipment_screen_gpt_v1.png`
  - `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_quest_screen_gpt_v1.png`
  - `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_skill_screen_gpt_v1.png`
- 当前阶段目标是“第一场景正式观感展示”，不是补完背包 / 装备 / 任务 / 武学的完整交互。

修复：

- 从上述 5 张源图生成调亮后的展示资源：
  - `game/art/ui/cold_wuxia/v2/ui_display_field_hud_bright.png`
  - `game/art/ui/cold_wuxia/v2/ui_display_inventory_bright.png`
  - `game/art/ui/cold_wuxia/v2/ui_display_equipment_bright.png`
  - `game/art/ui/cold_wuxia/v2/ui_display_quest_bright.png`
  - `game/art/ui/cold_wuxia/v2/ui_display_skill_bright.png`
- 同步接入已有对话框图：
  - 源图：`assets/raw/ui_frame/ui_cold_wuxia_dialog_box_v1.png`
  - 输出：`game/art/ui/cold_wuxia/v2/ui_display_dialog_box_bright.png`
- 新增 `game/scripts/ui/ui_display_art.gd`：
  - 面板打开时用全屏展示稿作为主视觉。
  - 保留透明关闭热区和 Esc 关闭。
  - 原有功能控件暂时隐藏，避免默认控件破坏展示稿观感。
- `field_walkable_controller.gd` 接入 HUD 展示图：
  - HUD 图中间做透明窗口，避免完全盖住场景和玩家。
  - 原有 I/E/K/J 按钮保持可点击但视觉透明。

验证：

- Python 校验确认 6 张展示资源存在，尺寸分别为 1920×1080（面板 / HUD）和 1760×400（对话框）。
- 校验确认 4 个面板脚本、对话框脚本、可行走场景脚本均引用了对应展示资源。
- `ReadLints` 检查 UI 脚本和 `field_walkable_controller.gd` 无新增错误。

经验：

- **展示稿阶段不要急着拆功能层**：当目标是验证整体正式观感时，先全屏加载已认可设计稿，保留关闭和快捷键即可。
- **全屏 UI 源图接游戏要先统一尺寸**：1536×1024 的设计图接到 1920×1080 时，用模糊背景 + contain 前景比强行拉伸或裁切更稳。
- **HUD 展示稿不能整张压住玩法画面**：如果源图是 RGB 全屏稿，接入时要给玩法中心区域做透明窗口，保留玩家和场景可见。

### 22.15 主 HUD 要从整图展示升级为可程序调用部件（2026-05-11）

现象：

- `ui_display_field_hud_bright.png` 作为整图展示能快速提升观感，但它仍是“一张图盖上去”：
  - 右侧按钮不能有真正的独立 hover / pressed；
  - 金币、场景名、任务内容会被源图示例文字干扰；
  - 后续背包 / 装备 / 任务 / 武学界面无法复用这套调用方式。

修复：

- 新增 `scripts/process_field_hud_assets.py`，从已认可源图：
  - `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_field_hud_screen_gpt_v1.png`
  裁出主 HUD 部件：
  - `game/art/ui/field_hud/v1/hud_player_panel.png`
  - `game/art/ui/field_hud/v1/hud_gold_panel.png`
  - `game/art/ui/field_hud/v1/hud_scene_title.png`
  - `game/art/ui/field_hud/v1/hud_quest_panel.png`
  - `game/art/ui/field_hud/v1/hud_bottom_bar.png`
  - `hud_btn_{inventory,equipment,skill,quest,system}_{normal,hover,pressed}.png`
- 对需要运行时写字的区域做“底框化”：
  - 场景名；
  - 金币数字；
  - 任务详情正文。
- 新增 `game/scripts/ui/ui_texture_skin.gd`，作为正式 UI 资源调用模块：
  - `load_texture()`
  - `place_texture()`
  - `make_texture_button()`
  - `stylebox_texture()`
  - `label()` / `rich_text()`
- `field_walkable_controller.gd` 改为初始化 `FormalFieldHud`：
  - 使用独立贴图部件绘制主 HUD；
  - 右侧 I/E/K/J/System 使用 `TextureButton` 三态；
  - 金币、场景名、任务摘要由程序写入；
  - 原默认 HUD 控件隐藏，但键盘快捷键仍保留。

验证：

- `python scripts/process_field_hud_assets.py` 通过，并生成 `tools/ui_field_hud_v1/field_hud_v1_preview.png`。
- `python -m py_compile scripts/process_field_hud_assets.py` 通过。
- Python 校验确认 20 个主 HUD 部件均存在且为 RGBA。
- `ReadLints` 检查 `ui_texture_skin.gd`、`field_walkable_controller.gd`、`process_field_hud_assets.py` 无新增错误。

经验：

- **UI 正式化要从“展示图”进入“部件图”**：整图适合快速验收风格，真正可复用必须裁成按钮、面板、底栏、信息框。
- **按钮三态必须从同一底图派生**：保持 alpha mask 和轮廓一致，避免重蹈主菜单三态轮廓跳动的问题。
- **源图里的示例文案要主动遮掉**：金币、任务、场景名这类运行时文本必须交给程序写，否则换场景或换任务时会出现双重文字。
- **资源调用模块要先小后大**：先服务主 HUD 的 TextureRect / TextureButton / StyleBoxTexture，后续再扩展到背包道具框、数量角标、拖动 ghost、删除确认等复杂控件。

### 22.16 调度台产出页采用按钮没反应要先查前端事件绑定（2026-05-11）

现象：

- 调度台 `/artifacts` 产出页面点击“采用”按钮没有可见反馈。
- 用户无法把候选产出标记为已采用。

原因：

- `artifacts.html` 的采用 / 拒绝 / 重置脚本会动态创建确认弹窗 DOM，但创建后没有重新获取：
  - `confirmModal`
  - `confirmMsg`
  - `confirmOk`
  - `confirmCancel`
  - `toast`
- 脚本随后直接调用 `confirmOk.addEventListener(...)`，浏览器会抛 `ReferenceError`，导致后续按钮监听器没有绑定。
- 同页还有一个状态分支拼写错误：`rjected`，会导致已淘汰产出不显示重置按钮。
- 另一个隐患：`scanner.py` 每次刷新索引时会把 `artifacts.adopted_status` 覆盖为路径推断值，手动点击 adopted / rejected 后可能在刷新页面时被重置。

修复：

- `tools/agent_hub/templates/artifacts.html`：
  - `ensureConfirmUI()` 后显式 `document.getElementById(...)` 获取确认弹窗和 toast 元素。
  - 初始化失败时直接 `return` 并输出错误，避免静默失败。
  - 修正 `rjected` 为 `rejected`。
- `tools/agent_hub/scanner.py`：
  - 扫描更新已有 artifact 时保留数据库中的 `adopted_status`，不再覆盖手动状态。
- `tools/agent_hub/verify_agent_hub.py`：
  - 增加 adopted API 验证：调用 adopt 后再跑 `scan_all()`，确认 adopted 状态不会被扫描器重置。

验证：

- `python -m py_compile tools/agent_hub/scanner.py tools/agent_hub/app.py tools/agent_hub/verify_agent_hub.py` 通过。
- `ReadLints` 检查 `artifacts.html`、`scanner.py`、`verify_agent_hub.py` 无新增错误。
- 直接运行 `python tools/agent_hub/verify_agent_hub.py` 会因包路径报 `ModuleNotFoundError: No module named 'tools'`，正确命令是：
  - `python -m tools.agent_hub.verify_agent_hub`
- `python -m tools.agent_hub.verify_agent_hub` 通过。

经验：

- **页面按钮没反应先查 JS 初始化错误**：不是只看后端 API；如果脚本中途 ReferenceError，事件监听器根本不会绑定。
- **动态创建 DOM 后必须重新取引用**：不要依赖浏览器把 id 自动暴露成全局变量，尤其带连字符的 id 不可靠。
- **扫描器不能覆盖人工状态**：产出库这种“自动扫描 + 人工采用”的模型，扫描器只应更新路径、分类、mtime 等客观字段，不能重置用户决策。
- **调度台验证脚本要用模块方式运行**：从仓库根目录使用 `python -m tools.agent_hub.verify_agent_hub`，不要直接运行文件路径。

### 22.17 主 HUD 资源不能从整图裁切，要走独立母版生成（2026-05-11）

现象：

- 第一版 `game/art/ui/field_hud/v1/` 资源来自 HUD 展示稿局部裁切，角色框、金币框、场景名框、任务框、底栏和右侧按钮都存在位置不准、错位、带背景的问题。
- 用户明确要求全部删除，按首界面 3 个菜单按钮的生产规范重做，不怕出图成本。

原因：

- HUD 展示稿是完整界面设计图，不是可直接程序调用的部件 atlas；从整图盲裁会把背景、示例文字、局部阴影和错位边缘一起带进最终资源。
- 右侧按钮如果让 AI 直接生成中文，容易出现错字/伪字；按钮三态如果分别出图，也会导致轮廓跳变。

修复：

- 删除上一版错误 PNG、预览和 `scripts/process_field_hud_assets.py`。
- 新增正式模板：
  - `prompts/templates/ui_field_hud_component_cold_wuxia.yaml`
  - `prompts/templates/ui_field_hud_button_cold_wuxia.yaml`
- 在 `prompts/tasks.yaml` 新增 10 个 HUD 母版任务，通过 `scripts/gen_assets.py` 走 ALAPI/gpt-image-2 生成独立透明底资源。
- 新增 `scripts/process_formal_field_hud_assets.py`：
  - 对独立母版做 alpha bbox、统一目标尺寸、透明像素清理。
  - 按固定尺寸输出 5 个面板 PNG。
  - 右侧 5 个按钮保留正式图形和图标，清掉 AI 伪字区域，用本地中文字体重新渲染“背包 / 装备 / 武学 / 任务 / 系统”。
  - hover / pressed 从同一 normal 派生，保持 alpha mask 完全一致。
- `field_walkable_controller.gd` 中任务文字颜色改为深色，适配新任务面板的浅色正文纸面。

验证：

- `python scripts/gen_assets.py --task ... --dry-run` 通过，参考图路径有效。
- `python scripts/gen_assets.py --task ... --budget 20` 成功生成 10 张，花费约 ¥12。
- `python scripts/process_formal_field_hud_assets.py` 成功输出 20 个 PNG 和预览 `tools/ui_field_hud_v1/field_hud_formal_v1_preview.png`。
- 尺寸与数量校验通过：5 个面板 + 5 个按钮 × 3 状态，共 20 个资源；所有按钮 normal/hover/pressed alpha mask 一致。

经验：

- **展示稿不能直接当程序部件裁**：完整 UI mockup 适合定方向，不适合产出 runtime 资源；正式 UI 部件要独立生成母版。
- **中文按钮不要依赖 AI 写字**：AI 可做底框和图标，最终标题由后处理脚本用本地字体渲染，避免错字和乱码。
- **按钮三态必须同源派生**：只生成 normal 母版，hover/pressed 用程序调亮/压暗，且最后强制恢复同一 alpha mask。
- **HUD 面板要按运行时目标矩形归一化**：透明边距过大会造成 Godot 里看起来错位；UI 切图允许受控缩放到目标画布。

### 22.18 HUD 右侧按钮参考不能误用首界面，AI 小字直出不可靠（2026-05-11）

现象：

- 用户要求 HUD 右侧按钮必须参考新提供的设计图：左侧图标 + 右侧白色书法字 + 蓝灰玄铁牌匾，而不是首界面 3 个菜单按钮。
- 继续让 AI 直接生成“系统 / 背包”等小尺寸中文字时，出现错字、伪字或字体不一致。
- 在 PowerShell 下使用 bash 风格 `python - <<'PY'` 会失败。

原因：

- “首界面按钮规范”只代表三态派生、alpha、尺寸稳定等生产流程，不代表所有 HUD 按钮都要照首界面视觉风格。
- 小按钮里的中文对图像模型非常不稳定，即便加文字参考图也可能写错。
- Windows PowerShell 不支持 bash heredoc 语法。

修复：

- 将用户上传图保存为 `assets/raw/ui/field_hud/reference/hud_right_buttons_design_ref.png`，作为 HUD 右侧按钮唯一视觉参考。
- 新增 `prompts/templates/ui_field_hud_button_right_stack_match.yaml` 和单按钮候选任务，只用于尝试生成参考风格，不直接批量采用。
- AI 直出中文字失败后，改为 `scripts/make_hud_right_button_sample.py` 程序重绘一枚“背包”样例按钮：不裁参考图，不加文字背景块，normal 母版再派生 hover/pressed。
- Windows 临时 Python 脚本使用 `@' ... '@ | python -`，不要用 bash heredoc。

验证：

- `python scripts/gen_assets.py --task ui_field_hud_btn_inventory_right_stack_candidate_v1 --dry-run` 通过。
- ALAPI 单张生成成功但中文字错误，因此未作为候选。
- `python scripts/make_hud_right_button_sample.py` 输出三态样例到 `tools/ui_field_hud_v1/right_button_sample/`。
- 三态校验：尺寸 `241x93`，normal / hover / pressed alpha mask 完全一致。

经验：

- **同一“生产规范”不等于同一“视觉风格”**：先确认用户给的是流程规范还是美术参考。
- **HUD 右侧按钮以用户上传设计图为准**：不要再自动回退到首界面按钮。
- **AI 不适合直接写小号中文按钮字**：若必须正确，需文字层单独管控，并尽量让字形风格贴近参考。
- **PowerShell 执行多行 Python 用 here-string 管道**：`@' ... '@ | python -`。

### 22.19 HUD 右侧按钮最终采用 image-to-image 候选筛选，不再用 PIL 手画质感（2026-05-11）

现象：

- PIL 手绘的背包样例虽然布局接近，但用户指出整体质感差，底框、左侧图标、字体都不像参考图。
- 继续调线条、颜色、阴影仍然像硬边矢量图，无法达到参考图的厚涂手绘质感。

原因：

- 参考图的质量来自手绘材质、暗部渐变、边框磨损、图标体积和柔化笔触；这些不是简单多边形、字体和渐变能稳定复现的。
- 对 HUD 美术部件，PIL 更适合作三态派生、alpha 清理、尺寸归一化，不适合作主视觉绘制。

修复：

- 保存用户最新近景参考为 `assets/raw/ui/field_hud/reference/hud_inventory_button_closeup_ref.png`。
- 新增：
  - `prompts/templates/ui_field_hud_inventory_button_closeup_redraw.yaml`
  - `prompts/templates/ui_field_hud_button_closeup_redraw_generic.yaml`
  - `scripts/process_hud_right_buttons_redraw.py`
- 先对背包跑 3 张 image-to-image 候选，筛出 A：`tools/ui_field_hud_v1/closeup_redraw_candidate_a/`。
- 用户确认 A 方向后，对装备 / 武学 / 任务 / 系统各跑 3 张候选，筛选：
  - 装备：A
  - 武学：C
  - 任务：C
  - 系统：本轮 3 张文字均不合格，未纳入最终，避免错字进游戏。
- 将背包 / 装备 / 武学 / 任务四个按钮输出到 `game/art/ui/field_hud/v1/`，每个生成 normal / hover / pressed。
- 预览输出：`tools/ui_field_hud_v1/right_buttons_redraw_v1_preview.png`。

验证：

- 12 张候选生成成功，花费约 ¥14.4。
- `python scripts/process_hud_right_buttons_redraw.py` 成功输出四个按钮三态。
- 校验通过：背包 / 装备 / 武学 / 任务均为 `241x93`，normal / hover / pressed alpha mask 完全一致。
- `python -m py_compile scripts/process_hud_right_buttons_redraw.py` 通过。
- `ReadLints` 检查新脚本和模板无新增错误。

经验：

- **PIL 不负责主视觉质感**：它适合后处理，不适合复刻厚涂 UI。
- **候选必须人工筛字**：即使 image-to-image 质感对了，中文仍可能错；错字候选必须淘汰。
- **先做用户确认的最小集合**：参考图只有背包 / 装备 / 武学 / 任务，系统没有可靠参考时不要强行塞进最终。
- **最终采用流程**：image-to-image 出 normal 母版 → 人工筛选 → 程序抠背景/归一尺寸 → 程序派生 hover/pressed。

### 22.20 一级 HUD 剩余 UI 补齐：系统按钮、角色框、底部栏（2026-05-11）

现象：

- 右侧 4 个按钮方向确认后，一级 HUD 仍有三块不统一：
  - 系统按钮缺失。
  - 左上角角色信息框仍是旧质感。
  - 底部操作栏仍是旧质感，且正式 HUD 层没有承接旧 `HintLabel` 信息。
- ALAPI 批量生成 7 张候选时，启动探活曾超时，随后 `--skip-ping` 大批次也连续 `ReadTimeout`，没有新 PNG 落盘。

原因：

- 系统按钮没有参考图里的原始按钮，AI 直接写“系统”仍容易错字。
- 旧 `field_walkable_controller.gd` 隐藏了 `PlayerInfo` / `HintBar`，但正式 HUD 层只接了场景名、金币、任务，没有角色信息和底部提示文字。
- ALAPI 当前通道偶发超时，大批次串行会被多个 timeout 拖住。

修复：

- 新增：
  - `prompts/templates/ui_field_hud_system_button_closeup_redraw.yaml`
  - `prompts/templates/ui_field_hud_panel_closeup_redraw.yaml`
  - `scripts/process_hud_primary_ui_redraw.py`
- 系统按钮：
  - image-to-image 生成系统按钮底框/齿轮候选。
  - AI 文字仍不合格，因此脚本只保留底框和图标，清除错字区域，再用本地书法字体叠加正确“系统”，不加背景块。
  - 从 normal 派生 hover / pressed。
- 左上角角色框：
  - 采用 `ui_field_hud_player_panel_closeup_candidate_a_v1.png`，后处理到 `650x188`。
- 底部操作栏：
  - 采用 `ui_field_hud_bottom_bar_closeup_candidate_a_v1.png`，后处理到 `1920x143`。
- `field_walkable_controller.gd`：
  - 新增 `_formal_player_label`，显示角色名、等级、HP/MP。
  - 新增 `_formal_hint_label`，显示底部操作提示。
  - 继续隐藏旧 `PlayerInfo` / `HintBar`，但信息转移到正式 HUD 层。

验证：

- `python scripts/process_hud_primary_ui_redraw.py` 成功输出：
  - `hud_player_panel.png`
  - `hud_bottom_bar.png`
  - `hud_btn_system_normal/hover/pressed.png`
- 预览输出：`tools/ui_field_hud_v1/primary_ui_redraw_v1_preview.png`。
- 资源校验通过：
  - 角色框 `650x188`
  - 底部栏 `1920x143`
  - 5 个右侧按钮均为 `241x93`
  - 5 个按钮 normal / hover / pressed alpha mask 一致。
- `python -m py_compile scripts/process_hud_primary_ui_redraw.py scripts/process_hud_right_buttons_redraw.py` 通过。
- `ReadLints` 检查 `field_walkable_controller.gd` 与新脚本无新增错误。

经验：

- **ALAPI 大批次超时时先缩小批次**：探活超时可 `--skip-ping`，但连续 `ReadTimeout` 时要拆成单张/小批次，不要让整批一直挂住。
- **AI 字错但底框可用时可做混合方案**：保留 AI 厚涂底框和图标，清掉错字后叠加正确文字；关键是不能加明显文字背景块。
- **正式 HUD 隐藏旧控件后要迁移信息**：隐藏 `PlayerInfo` / `HintBar` 前，必须在新 HUD 层创建对应 label，否则 UI 信息丢失。

### 22.21 HUD 右侧按钮反馈修正：系统风格、装备字重、任务亮度（2026-05-11）

现象：

- 用户确认背包、武学匹配，但指出：
  - 系统按钮与其他按钮风格不一致。
  - 装备按钮字体过大、颜色偏深。
  - 任务按钮整体偏暗。
- 第一次尝试用 PIL 清文字区、补齿轮和重绘字，结果装备/系统出现明显糊块和方形贴片痕迹，不适合进正式资源。
- 调试时又误用 bash heredoc `python - <<'PY'` 和 `&&` 串联命令，PowerShell 下直接解析失败。

原因：

- 系统按钮不能靠“错字清除 + 本地字体补字”硬拼；只要文字区域修补不自然，就会破坏厚涂质感。
- 装备文字问题不适合用模糊覆盖修，覆盖区域会变成灰色补丁。
- PowerShell 不支持 bash heredoc；当前 shell 也不能依赖 `&&`，复杂 Python 片段应使用 `@' ... '@ | python -`，多命令用 `;` 或单独执行。

修复：

- 新增 `prompts/templates/ui_field_hud_button_feedback_fix.yaml`，只锚定已确认的背包/武学按钮，生成系统、装备、任务的小批次修正版候选。
- 新增 `scripts/adjust_hud_button_feedback.py`：
  - 背包、武学保持不动。
  - 装备采用 `ui_field_hud_btn_equipment_feedback_fix_candidate_a_v1.png`，并按宽度归一，解决字过大/偏暗且避免视觉尺寸缩水。
  - 任务保留原任务候选 C 的造型，只做亮度/色彩轻微提升，避免为“提亮”引入新造型。
  - 系统改用 `ui_field_hud_btn_system_closeup_ref_candidate_c_v1.png`，比上一版更接近右尖角 HUD 按钮形。
  - hover / pressed 仍从 normal 程序派生，保持 alpha mask 不跳。
- `docs/current-progress.md` 更新 HUD 部件化状态，记录该反馈修正版脚本。

验证：

- `python scripts/gen_assets.py --skip-ping --force --task ...` 成功生成 6 张反馈候选。
- `python scripts/adjust_hud_button_feedback.py` 成功输出装备 / 任务 / 系统三态到 `game/art/ui/field_hud/v1/`。
- 预览输出：`tools/ui_field_hud_v1/feedback_adjusted_buttons_preview.png`。
- `python -m py_compile scripts/adjust_hud_button_feedback.py` 通过。
- 校验通过：装备 / 任务 / 系统均为 `241x93`，normal / hover / pressed alpha mask 完全一致。
- `ReadLints` 检查 `adjust_hud_button_feedback.py`、新模板、`tasks.yaml` 无新增错误。

经验：

- **用户只指出局部问题时，优先保持已确认资产不动**：背包、武学不重写，任务只提亮不换造型。
- **不要用模糊覆盖修主视觉文字**：厚涂 UI 的文字和底框是融合质感，模糊补丁会比原问题更显眼。
- **系统按钮缺原始参考时要多筛候选**：宁可小批次重跑，也不要把混合补字版强行部署。
- **PowerShell 片段固定写法**：多行 Python 用 `@' ... '@ | python -`；不要再用 bash heredoc，命令串联优先 `;` 或拆开跑。

### 22.22 HUD 右侧按钮标准化：底框复用、图标层、文字层（2026-05-11）

现象：

- 用户复核后指出上一版仍不合格：底框、图标、字体尺寸都有偏差。
- 根本偏差来自“每枚完整按钮各自生成 / 各自归一化”，这违背了此前主菜单按钮已定的规范：底框和文字分层，底框复用。
- 第一次尝试直接从“武学”按钮用 `cv2.inpaint` 拆空底框，出现大块灰色补丁，不可采用。

原因：

- 完整按钮候选天然会带来外轮廓、内板、边框厚度、图标大小、字重和字距漂移。
- 用算法硬抠除已有图标/文字，难以补回自然厚涂纹理；UI 主视觉底框不应靠后处理修补。
- 图标层必须从原始候选中分离，不能把旧按钮底框纹理一起贴进统一底框，否则会出现小方块/旧底框残影。

修复：

- 新增 `prompts/templates/ui_field_hud_skill_frame_textless.yaml`，以已确认“武学”按钮为标本，生成“无图标、无文字”的可复用底框候选。
- `scripts/adjust_hud_button_feedback.py` 改为标准分层管线：
  - 采用 `ui_field_hud_skill_frame_textless_candidate_b_v1.png` 作为唯一底框源。
  - 程序统一重映射为武学方向的冷蓝灰玄铁色，输出 `tools/ui_field_hud_v1/skill_frame_recomposed_buttons/shared_frame_normal.png`。
  - 五个按钮共享同一底框、同一图标中心/最大尺寸、同一文字中心/字号。
  - 图标从各自原始候选分离为 `icon_<key>.png`；文字输出为 `text_<key>.png`；最终合成为 normal，再派生 hover / pressed。
  - 输出预览：`tools/ui_field_hud_v1/skill_frame_recomposed_buttons_preview.png`。
- `docs/current-progress.md` 更新 HUD 部件化状态：记录当前脚本已回到“底框复用 + 图标层 + 文字层”的标准管线。

验证：

- `python scripts/gen_assets.py --skip-ping --force --task ui_field_hud_skill_frame_textless_candidate_a_v1 --task ui_field_hud_skill_frame_textless_candidate_b_v1` 成功。
- `python scripts/adjust_hud_button_feedback.py` 成功重组五个右侧按钮。
- `python -m py_compile scripts/adjust_hud_button_feedback.py` 通过。
- 校验通过：背包 / 装备 / 武学 / 任务 / 系统均为 `241x93`，各自 normal / hover / pressed alpha mask 完全一致。
- `ReadLints` 检查 `adjust_hud_button_feedback.py`、`ui_field_hud_skill_frame_textless.yaml`、`tasks.yaml` 无新增错误。

经验：

- **HUD 同组按钮不能再整枚独立归一化**：必须是“同一底框层 + 固定图标槽 + 固定文字层”，否则肉眼一定会看出偏差。
- **底框缺失时应先生成 textless base**：不要从带图标/文字的成品按钮硬抠底框。
- **所有中间层必须留预览和文件**：`shared_frame_normal.png`、`icon_*`、`text_*` 是后续排查偏差的证据。
- **图标层抠取要避免旧底框残影**：按图标类型固定裁剪框，只保留高亮/高饱和图标笔触，避免把旧按钮纹理贴回新底框。

### 22.23 UI 按钮三态生产 Skill 固化（2026-05-11）

现象：

- HUD 右侧按钮几轮返工后，问题反复出现在同一类决策上：整枚按钮独立生成、独立归一化，导致底框、图标、字体和三态动画漂移。
- 仅靠 `docs/experience-log.md` 记录不够，后续新 UI 或新会话仍可能忘记“底框 + 图标 + 文字分层”的三态规范。

修复：

- 新增项目级 skill：`.cursor/skills/producing-ui-button-states/SKILL.md`。
- Skill 明确适用场景：创建或修复 normal / hover / pressed / click / selected / disabled 等 UI 按钮状态，尤其是匹配已确认样本、复用底框、分离图标/文字层、部署到 Godot 时。
- Skill 核心规范：
  - 同组按钮使用一个 approved specimen。
  - 先做可复用 textless/iconless base frame。
  - 图标层与文字层分开生产和保存。
  - normal 合成后，hover / pressed 从 normal 程序派生。
  - 校验尺寸、alpha mask、预览和 Godot 加载。

验证：

- 读取并检查 `.cursor/skills/producing-ui-button-states/SKILL.md`：
  - frontmatter 包含合法 `name` / `description`。
  - 文件路径使用仓库相对路径和正斜杠。
  - 内容聚焦三态按钮生产流程，没有把一次性返工叙事当作 skill 主体。

经验：

- **流程型失误要写成 skill，而不是只写经验日志**：经验日志适合追溯，skill 适合下一次自动触发。
- **三态按钮 skill 必须强调禁止项**：禁止整枚按钮各自生成、禁止独立生成 hover/pressed、禁止用 inpaint 硬补底框。

### 22.24 HUD 按钮分层素材质量返工：先预览不覆盖（2026-05-11）

现象：

- 标准合成管线结构正确，但用户继续指出三层素材质量不达标：
  - 底框质感比已采用样板差很多。
  - 图标质量差，有缺块。
  - 程序绘制文字丑，系统文字尤其不匹配。

原因：

- 分层结构不能弥补低质量素材层；底框、图标、文字必须各自先达到可采用质量。
- 当前 `adjust_hud_button_feedback.py` 使用低质 textless 底框、从完整按钮里抠图标、用本地字体画系统字，导致质感和完整度都不够。
- AI 生成中文“系统”仍会把“系”写成近似“禾”，不能直接采用。

修复：

- 新增参考 sheet：
  - `assets/raw/ui/field_hud/reference/hud_button_accepted_text_style_ref.png`
  - `assets/raw/ui/field_hud/reference/hud_button_accepted_icon_style_ref.png`
- 新增分层生成模板：
  - `prompts/templates/ui_field_hud_button_frame_layer_v2.yaml`
  - `prompts/templates/ui_field_hud_button_icon_layer_v2.yaml`
  - `prompts/templates/ui_field_hud_button_text_layer_v2.yaml`
- 新增 `scripts/preview_hud_layered_buttons_v2.py`，只输出候选预览，不覆盖 `game/art`：
  - 采用高质量图标层候选。
  - 文字层：背包 / 装备 / 武学 / 任务先从已采用旧按钮提取，系统字用程序保证字形正确并套近似厚边/阴影。
  - 底框使用新候选 A 预览，暂不部署。
- 预览输出：`tools/ui_field_hud_v1/layered_v2_candidates_preview.png`。

验证：

- `python scripts/gen_assets.py --skip-ping --force --task ...` 成功生成底框 / 图标 / 系统文字分层候选。
- `python scripts/preview_hud_layered_buttons_v2.py` 成功生成 v2 分层预览。
- `python -m py_compile scripts/preview_hud_layered_buttons_v2.py` 通过。
- 候选预览中五个按钮均为 `241x93`，normal / hover / pressed alpha mask 完全一致。
- `ReadLints` 检查新脚本、三份新模板、`tasks.yaml` 无新增错误。

经验：

- **分层合成前必须先看层质量**：结构正确不代表美术可用；底框、图标、文字要分别预览。
- **AI 中文不能做唯一真相**：系统字必须有人类可读性校验，错字候选直接淘汰。
- **不确定可采用时不要覆盖游戏资源**：先输出到 `tools/` 做候选预览，通过后再部署到 `game/art`。
- **程序文字的描边会改变观感颜色**：即使填充色是米白，过重灰黑描边和二次灰色叠字也会让最终缩放后的字面发灰。修正时要同时减弱描边、移除压灰叠色，并在最终按钮预览里看颜色，而不是只看 RGB 参数。
- **单枚按钮确认后可单独部署**：当用户只确认“系统”按钮时，只覆盖 `game/art/ui/field_hud/v1/hud_btn_system_normal.png`、`hud_btn_system_hover.png`、`hud_btn_system_pressed.png`，不要重新生成或覆盖整组按钮。部署后检查目标 PNG 尺寸和三态 alpha mask 一致。
- **恢复已采用按钮时要查“最终采用记录”，不能看当前 game 目录倒推**：本次 `game/art/ui/field_hud/v1` 中背包 / 装备 / 武学 / 任务被后续低质重组版覆盖，当前游戏资源不是已采用真相。正确来源应回查 `docs/experience-log.md` 的采用记录：背包 / 装备 / 武学 / 任务来自 `tools/ui_field_hud_v1/right_buttons_redraw_v1/`，系统来自用户单独确认的 `tools/ui_field_hud_v1/system_button_v2/`。恢复后生成 `tools/ui_field_hud_v1/game_current_restored_buttons_preview.png` 并验证五个按钮三态尺寸与 alpha mask。
- **HUD 右侧按钮最终仍必须走单底框分层，不应停留在五张完整按钮**：用户再次指出五个完整按钮的底框、字号、字色都不同。新增 `scripts/compose_hud_buttons_single_frame_v3.py`，强制使用一个共享底框、同一图标槽位、同一程序文字配方，再派生三态；预览输出 `tools/ui_field_hud_v1/single_frame_v3_preview.png`，对比输出 `tools/ui_field_hud_v1/single_frame_v3_vs_game_preview.png`。验证五个按钮 normal / hover / pressed 均为 `241x93`，alpha mask 完全一致，且每个按钮 mask 面积相同，说明共享底框真正生效。
- **统一文字色要参考最终状态图，不只看 normal 层**：用户要求 v3 文字颜色参考 `tools/ui_field_hud_v1/layered_v2_candidates/hud_btn_quest_hover.png`，因此在 `compose_hud_buttons_single_frame_v3.py` 中把 normal 文字填充压深到灰米色，让 hover 派生后接近参考状态。调色后重新生成 `single_frame_v3_preview.png`，验证五个按钮三态尺寸与 alpha mask 仍一致。
- **字体“看起来没变深”通常是高光层在抵消**：本次继续反馈 v3 文字太浅，根因是主填充虽然压深，但浅色高光层仍叠在字面上，hover 派生后继续显浅。修正时同时降低主填充、加深描边、把高光层改为低透明深米色；重新生成 `tools/ui_field_hud_v1/single_frame_v3_preview.png` 并验证 mask 不变。
- **“字体颜色不对”要区分实体字面和阴影**：继续调暗后用户指出文字像阴影，真正需要的是实体笔画的奶白色。修正时不能只压暗整体，而要让主填充回到奶白、收窄描边、降低投影占比；`compose_hud_buttons_single_frame_v3.py` 将 `TEXT_STROKE` 从 2 调为 1，并使用奶白填充 + 轻描边，重新生成 `single_frame_v3_preview.png`。
- **匹配字体颜色要采样参考按钮，不要凭感觉调**：用户指定 `tools/ui_field_hud_v1/layered_v2_candidates/hud_btn_inventory_normal.png` 后，采样“背包”字面得到实体色约 `(228,218,196)`、边缘灰约 `(108,110,113)`。修正 `compose_hud_buttons_single_frame_v3.py` 在文字层缩放后统一重映射 RGB；不要强行提高 alpha，否则会把字体内部笔刷纹理变成白色刮痕。
- **特殊按钮文字不要强行套统一字体**：`系统` 两个字用 `STXINGKA` 重绘后会显得碎、瘦、行草感过强，和其他按钮不一致；正确做法是只对系统按钮复用已采用的 raster 字层 `tools/ui_field_hud_v1/layered_v2_candidates/text_system.png`，只做缩放定位，不再套统一 RGB 归一化，避免把原始光影纹理抹平成色块。
- **PowerShell 下不要使用 Bash heredoc**：Windows/PowerShell 执行内联 Python 时，`python - <<'PY'` 会解析失败；继续使用 `@' ... '@ | python -`，尤其在快速做资产采样或预览脚本时不要切错 shell 语法。
- **系统字层颜色要以 `text_equipment.png` 为风格参考重建**：旧 `text_system.png` 字形可用但颜色偏灰，直接复用会和装备/其他按钮不一致。修正 `compose_hud_buttons_single_frame_v3.py`：系统按钮使用正确字形 mask，但从 `tools/ui_field_hud_v1/layered_v2_candidates/text_equipment.png` 采样实体、暗部、边缘三段颜色后重新映射，生成新的 `single_frame_v3/text_system.png` 和系统三态；避免把系统文字继续套旧灰色或全局灰白归一化。
- **外部 docx 方案参考要先转 UTF-8 文本再读**：读取 `F:/Code/vision_auto_test/DeepFlow2.0/output/.../AI游戏UI开发效率提升方案.docx` 时，`ReadFile` 不支持 docx，PowerShell 直接打印中文会乱码；用 Python `ZipFile` 抽取 `word/document.xml`，写入 `tools/ai_game_ui_efficiency_plan_extracted.txt` 后再读取。该方案对本项目的关键启发：UI 实现困难的根因是让 AI 猜布局，应建立精确坐标/组件模板/Design Token/Animation Preset，并把 Figma 或结构化规格作为布局真值源。
- **Godot MCP 只能执行规格，不能替代规格**：本次检查 `C:/Users/rajqiu/.cursor/projects/f-Code-RPG-GAME/mcps` 时只看到 Figma MCP，尚无 Godot MCP tool descriptor，因此不能直接调用 Godot MCP 操作场景。一级 HUD 先落地 `ai-specs/ui/field-primary-hud.md`，固定 1920x1080 坐标、节点职责、资源路径、右侧按钮冻结规则；等 Godot MCP 可用后，也应按该规格创建/检查 Control 节点，而不是让 MCP 临场决定布局和风格。
- **Cursor 使用 Godot MCP 需项目级 `.cursor/mcp.json`**：Claude 已通过项目配置使用旧版 `@coding-solo/godot-mcp` 细粒度工具，正确 Godot 项目路径是 `F:/Code/RPG_GAME/game`，不是仓库根目录；Godot 可执行路径为 `F:/文件下载/编程工具/Godot_v4.6.2-stable_win64.exe`。已新增 `.cursor/mcp.json` 镜像该 stdio MCP 配置，但当前 Cursor 会话的 MCP descriptor 目录尚未刷新出 `godot`，需要在 Cursor MCP 面板刷新/重载后才能在本会话工具列表中调用。
- **半透明整屏概念图不能直接裁成正式 UI 资源**：`assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_field_hud_screen_gpt_v1.png` 的一级 HUD 效果可作为布局/风格真值，但面板是叠在背景上的半透明效果，直接裁 `PlayerInfo/MapInfo/Quest/HintBar` 会把竹林、屋檐、人物头发一起带入资源。正确流程是先用概念图定布局，再复用或重生成干净透明面板；本次脚本 `scripts/process_field_primary_hud_v2.py` 输出 `tools/field_primary_hud_v2_preview.png`，并以已导入的干净 v1 面板重组为 v2 第一版结构素材。
- **新 Godot `class_name` 不一定能被同轮预加载脚本立刻解析**：新增 `FieldPrimaryHud` 后，`field_walkable_controller.gd` 若直接声明 `var _primary_hud: FieldPrimaryHud`，Godot MCP 运行 `field_walkable.tscn` 会报 `Parser Error: Could not find type "FieldPrimaryHud" in the current scope`。在同轮新增场景/脚本并接入旧控制器时，先用弱类型实例引用通过解析；等 Godot 导入/类型缓存稳定后，再考虑恢复显式类型标注。
- **Godot 新 PNG 资源验证要区分文件存在与导入缓存存在**：脚本生成的 `game/art/ui/field_hud/v2/*.png` 可被文件系统读取，但 Godot `ResourceLoader.exists()` 只有在 `.import` 生成后才稳定。小素材若尚未导入会触发 `UITextureSkin texture missing`。本次头像框和金币框直接复用已导入的 v1 资源，避免 UI 接入阶段被导入缓存阻塞。
- **对话框纹理底框要保留旧 DialogPlayer 协议**：替换 `dialog_box.tscn` 时只调整 `Frame` 锚点和底框纹理，不改 `DialogPlayer.text_displayed / choices_displayed / dialog_ended` 信号协议。正式底框由 `scripts/process_field_primary_hud_v2.py` 生成 `game/art/ui/field_hud/v2/hud_dialog_frame.png`，`dialog_box.gd` 在 `_ready()` 注入 `DisplayFrameArt`，并把旧 `ColorRect` 背景改成透明 fallback。
- **运行时生成 PNG 可用 ImageTexture 兜底绕过导入缓存**：`hud_dialog_frame.png` 文件存在但 `.import` 尚未生成时，`ResourceLoader.exists()` 会返回 false。对话框这类运行期 UI 可以先尝试 `load()`，再用 `Image.load(ProjectSettings.globalize_path(path))` + `ImageTexture.create_from_image()` 兜底，避免因为导入缓存未刷新导致底框缺失。
- **一级 HUD 不能只“风格相似”，必须先标注设计稿元素坐标**：上一版问题是把 v1 干净面板硬套到 `ui_cold_wuxia_field_hud_screen_gpt_v1.png` 的大概位置，导致左上头像、姓名、生命/内力、数值、等级、金币槽完全错位。修正时在 `scripts/process_field_primary_hud_v2.py` 中固定 `REF_RECTS`，输出 `tools/field_primary_hud_reference_measure.png` 做坐标标注，再把坐标映射到 1920x1080 的 `FieldPrimaryHud`。以后用户给 UI 整屏设计稿时，必须先产出标注预览和对比图，不能直接凭肉眼重排。
- **参考图半透明面板要重做完整底框，不要截一段旧图**：右上地图和右下任务面板上一版来自旧资源拉伸，视觉上像“一截框”。本次改为生成完整半透明冷钢蓝底框，避免遮挡场景内容，同时保留完整四边和内框；输出 `game/art/ui/field_hud/v2/hud_map_info_panel.png`、`hud_quest_summary_panel.png`，对比图为 `tools/field_primary_hud_design_compare.png`。
- **底部按键说明不是正式一级 UI 常驻项**：设计稿里的底部条是快捷栏风格，不是当前要做的按键说明文字。用户明确要求去掉后，`FieldPrimaryHud` 不再构建 `HintBar`，`set_hint_text()` 改为空安全，避免旧控制器继续传提示文案时报空。
- **对话框需要图像模型质感时不要用程序画框顶替**：用户指出底部对话框像程序画的。新增 `scripts/generate_field_dialog_frame_gpt2.py`，使用 `gpt-image-2` 生成原图 `assets/raw/ui/field_hud/dialog_frame_gpt2_v1.png`，再后处理成 `game/art/ui/field_hud/v2/hud_dialog_frame.png`。白底抠透明时要额外清理低饱和高亮残留，否则四角会留下白雾边。

---

## 23. Godot 双面板叠加：兄弟控件无法传递鼠标事件（20+ 次反复调试）

### 23.1 问题
装备界面打开时，装备面板（后添加的 child）覆盖背包面板（先添加的 child），导致背包页签/格子无法点击。

### 23.2 踩过的坑

| 尝试 | 方法 | 结果 |
|---|---|---|
| MOUSE_FILTER_PASS / IGNORE | 在装备根节点上设 PASS，希望事件穿透到背包 | ❌ PASS 只传给 parent，不传给 sibling 身后 |
| move_child 调换顺序 | 把背包 `move_child` 到最前面渲染 | ❌ 装备被挡，X 按钮和槽位点不了 |
| 装备根节点 `anchors_preset = PRESET_RIGHT_WIDE` | 让装备锚定到右半区 | ❌ 子控件绝对坐标跟着错了 |
| 只移 Container | Container 右移 + 子控件补偿 | ❌ Container 移除后整个方案崩塌 |
| **最终方案** | EquipmentPanel 根节点右移 1280px + 所有子控件 `offset -= 1280`，背包 MainPanel 左移对齐 InventorySlot。零重叠 + 关面板时全还原 | ✅ |

### 23.3 核心教训
1. **Godot 4 兄弟 Control 节点之间没有事件穿透机制**。不管你设什么 mouse_filter，上层永远拦截。唯一解：物理不重叠。
2. **绝对偏移 + compensate 子控件** 是可靠的移位方案。用 `offset_left/right` 不碰 `anchors_preset`，避免锚点带来的二次计算。
3. **开/关成对操作必须带 guard**。打开时判断 `offset_left >= 1280` 才移（防止重复移），关闭时判断 `offset_left < 1280` 才还原（防止重复还原）。
4. **复杂节点层级（Container 套子控件）增大了移位复杂度**。移除 Container 后，根节点 + 直接子控件的两层结构一次就修通。
5. **Dim 蒙版必须显式隐藏**。装备模式下背包 Dim 覆盖全屏，阻挡所有点击。`_open_equipment_panel` 中 `dim.visible = false`，`_on_system_panel_closed` 中恢复。

---

## 24. GDScript 严格模式踩坑（2026-06-28）

### 24.1 Godot 4 的 "Treat Warnings as Errors"

本项目的 Godot 编辑器开启了将警告视为错误的严格模式。以下模式会导致解析失败：

| 错误模式 | 正确写法 |
|----------|----------|
| `var mode := key[1]`（从无类型数组取元素） | `var mode: String = str(pair[1])` |
| `for key in [[...], ...]:` | 用命名数组 `var pairs: Array = [...]` |
| `if cond == &: action` | `if cond == &"": action` |
| `if cond == &"" action`（缺冒号） | `if cond == &"": action` |
| `connect(func(i: int): ...)` | `connect(_on_xxx_changed)` 命名函数 |

### 24.2 核心教训
1. GDScript 不是 Python——`if cond action` 必须写成 `if cond: action`。
2. 严格模式下所有 `:=` 都必须能从右侧明确推断类型；遍历 Dictionary 或无类型 Array 返回的全是 Variant，必须显式声明。
3. 批量写 UI 代码时优先用显式类型（`var x: Type = value`），不省 `:=` 那一行。

---

## 25. godogen 调研与误解（2026-06-28）

### 25.1 godogen 的核心思路
- 用 C# Scene Builder 脚本在 headless 模式下 **代码生成 .tscn**，跑引擎截图，AI 对比视觉差异后迭代修复
- UI 元素用 Godot Container（VBox/HBox/GridContainer）自动排版，不是手调 offset
- **关键**：美术图先生成 → 贴到面板上，不是代码画 UI

### 25.2 我们踩的坑
- 错误地把 "程序化画 UI"（Label.new + StyleBoxFlat + 彩色徽章）当成改进——应该保持现有贴图风格，只优化布局骨架
- godogen 的 C#/GDScript 差异决定了不能直接复制它的 Scene Builder 模式
- 正确的借鉴方向：① AI 先生成 UI mockup 图 → ② 写代码匹配 → ③ 截图对比 → ④ 修复。不是纯文本改代码。

### 25.3 对现有项目的启发
- 任务/技能面板的 toolbar/actions 应从代码生成改为 .tscn 预建（已完成 2026-06-28）
- 如果有新的美术图资源，可以直接替换 `art/ui/quest/` / `art/ui/skill/` 下的贴图
- 后续 UI 迭代应以「先出图 → 再写代码 → 截图验证」为流程

---

## 26. 第一章 Boss 战后剧情不要被战斗结算抢走（2026-07-07）

现象：

- `ch1_forest_yuewuxing.tres` 指向 `battle:masked_killer_ambush`，但敌人资源缺失，战斗会 fallback 成“未知之敌”。
- `BattleController` 虽然 `EnemyDef` 已有 `is_chapter_boss` 字段，却仍用 `enemy_id.begins_with("boss_")` 判断章末 Boss。
- 如果把第一章直接改成 `battle:masked_killer_leader` 且立即按章末 Boss 进 `chapter_end`，会跳过蒙面首领临死、火焰竹叶、悦无姮告别和 `chapter1_complete` 置旗。

修复：

- 新增 `game/data/enemies/masked_killer_ambush.tres`，作为第一章“蒙面杀手首领”聚合战斗资源，匹配设计案中的 `battle:masked_killer_ambush`。
- 密林场景战后热点改为依赖 `defeated_masked_killer_ambush`，让玩家打完先回密林播放 `ch1_forest_victory` 与 `ch1_forest_yuewuxing_talk`，再由对话 `chapter_end:1` 结算。
- `BattleController._is_chapter_boss()` 改为读取 `EnemyDef.is_chapter_boss`，但战斗层只置 `chapter_boss_defeated_<enemy_id>` 标记，不直接抢走章节结算；章节结束仍交给内容数据的 `chapter_end:<n>` action。

经验：

- 章末 Boss 有“战斗胜利”和“章节结束”两个语义，不能默认绑定在一起。若 Boss 后还有关键剧情，应由对话链或场景 action 触发 `chapter_end`。
- 设计案里的 battle id 必须有同名 `.tres`；否则 Godot 不会硬崩，但 fallback 敌人会让任务、旗标和剧情全部错位。

## 27. Godot 场景验证中的两类轻易漏掉的硬错误（2026-07-07）

- GDScript 不能写 `save_btn.theme_override_font_sizes/font_size = 14` 这种属性路径赋值；应使用 `add_theme_font_size_override("font_size", 14)`。
- UI 脚本如果用 `$Path/To/Node` 硬取可选节点，场景里缺节点会在 `_ready` 前直接报错。可选 Label 应使用 `get_node_or_null(...) as Label`，或在 `.tscn` 里补齐节点。





## 28. 资产冒烟测试不得清理共享 raw 目录（2026-07-14）

### 现象

旧版 `scripts/smoke_test.py` 在 dry-run 前直接递归清空 `assets/raw/`。该目录通常不受 Git 跟踪，混有真实生成原图时无法通过 Git 恢复。

### 修复

- dry-run 本身只写 `logs/dry_run/`，冒烟测试不再删除 `assets/raw/`。
- `verify.py` 改为在临时空目录上执行，避免把历史 processed 资产问题误判为管线骨架失败。
- 冒烟测试只选择一条已知可渲染任务，不再默认扫描全部历史任务。

### 规则

任何测试脚本不得递归删除 `assets/raw/`、`assets/library/`、`assets/adopted/` 或 `game/art/`。临时产物必须写入独立临时目录，清理范围应由测试进程创建并持有。

## 29. Godot 不会在启动时解析所有未引用 `.tres`（2026-07-14）

项目 headless 启动正常，不代表未被当前场景引用的对话和任务资源可用。后续章节资源可能仍包含错误引号、未闭合字符串或错误的 `Array[Dictionary]` 语法，直到首次加载才出现 Parser Error。

处理方式：新增 `game/test/validate_chapters_1_4_resources.gd`，按文件名前缀逐个 `ResourceLoader.load()` 前四章资源。首次检查发现 5 个隐藏错误：两份悦无姮对话、第一章序章、`月下琴声`、`牡丹诗会`；修复后 80 个资源全部通过。

规则：新增章节入口前必须运行章节资源全量加载测试。中文台词中的引用统一使用「」，避免裸双引号破坏 `.tres` 字符串。

## 30. 背景铺满方式与世界坐标必须共用同一矩形（2026-07-24）

### 现象

场景数据中的出口中心与自动寻路测试都显示可达，但实机里角色站到画面右上真实村口仍无法触发；多个碰撞矩形也出现“数据看似正确，角色却能走上房屋或山体”的横向错位。

### 根因

`TextureRect` 使用 `KEEP_ASPECT_COVERED` 铺满 `1920x1080` 视口，但 `field_walkable_controller.gd` 曾按原图宽高比计算一个约 `1620x1080` 的世界尺寸。归一化坐标 `x=0.845` 因此渲染在约 1369px，而画面中的真实村口位于约 1622px。测试只在同一套错误归一化数据内验证连通性，无法发现渲染坐标偏移。

### 规则

- 背景、玩家、NPC、出口、碰撞和模块化物件必须使用同一个实际控件/视口矩形转换归一化坐标。
- `KEEP_ASPECT_COVERED` 会裁切源图，不要把“原图等比显示尺寸”当作世界坐标尺寸。
- 可行走测试除连通性外，还要对关键出口加入与画面地标约定坐标的断言，并用一次实际渲染截图复核。
- 建筑、树木、箱子等独立资产使用 `scene_objects` 配置；碰撞只覆盖脚底实体区域，互动范围和显示贴图分开声明。

补充：对话节点写入 flag 时会广播 `flag_set`。若 Field 在对话仍播放时同步重建，玩家会原地进入新建的 `Area2D`，从而再次启动同一对话。可调查的一次性物件必须同时使用 `interaction_only = true` 和与对话写入值一致的 `hide_flag`；场景刷新统一延迟到 `dialog_ended` 后执行。

## 31. 2.5D 地图应使用正向行走区域而非屋顶障碍黑名单（2026-07-24）

旧地图把建筑整张屋顶投影做成矩形障碍，再靠更多矩形补竹林、围栏和山体。这种黑名单数据与背景图缺少结构关系，容易切断真实道路，也无法证明出口和交互点可达。主街还曾把未经审核的模块 atlas 批量铺在完整背景上，造成建筑碎片和透明边缘大面积错位。

修复后地图空间拆为 `WalkableMapLayout` V2：正向可行走多边形决定玩家活动范围，建筑只阻挡脚底和台基，视觉物件、交互区、出口和角色分别进入独立运行层。`validate_walkable_map_v2.gd` 会检查每个出口/交互点从出生点的真实 BFS 可达性，并要求自动触发区具备一次性隐藏条件。

规则：正式整图可以作为稳定底层；只有需要状态变化、遮挡排序或互动的建筑/树木/箱子才拆成独立 PNG。独立资源必须逐个审核位置、缩放、透明边缘和脚底碰撞，禁止未经人工验收的批量拼图直接进入运行场景。

## 32. 正向可行走区需要运行时约束，出口不可与 HUD 重叠（2026-07-24）

现象：林西村新手关的数据 BFS 已判定左下庭院可达、铁匠铺屋顶不可达，但旧版仅靠 `CollisionPolygon2D.BUILD_SEGMENTS` 的边界线，角色在物理帧与斜向输入的组合下仍可能越过道路边界；右上出口坐标又落在场景标题 HUD 下方，导致玩家看不到引导。

修复：`Player` 接受由 `FieldWalkableController` 提供的正向区域约束，在移动前校验目标点；到达边缘时分别尝试横向或纵向移动，以保留沿道路边缘滑行。教程出口最终改到下方主路尽头，避免任务路径穿过右侧铁匠铺的底图屋顶；锁定状态仍常驻显示金色动态箭头和“村外山道（需铁剑）”。教程地图同时保留 `lower_courtyard_path` 与 `smithy_roof` 两个永久探针。

规则：碰撞边界用于实体接触，`walkable_regions` 同时必须作为运行时的玩家位置许可；任何出口标识必须在首屏可见且不得压在 HUD、标题或对话层下方。地图改动后必须运行 V2 BFS 校验并截取实机画面。

补充：剧情阶段变化不能以 `hide_flag` 删除常驻 NPC。教程中的刑樊天与杜青衫使用“剧情对话 NPC 隐藏 + 无奖励闲聊 NPC 出现”的替换方式，保证角色留在场景里且奖励只结算一次。
# 2026-07-27: gpt-image-2 field sprite generation endpoint returned empty 400

- Reproduction: `python scripts/gen_assets.py --tasks-file prompts/tasks_field_sprite_rework_v1.yaml --force --skip-ping --fallback-model gpt-image-2 --budget 20`.
- The dry run rendered successfully, including the local battle-reference image. The ALAPI startup probe and all three controlled generation retries returned `RuntimeError: ALAPI error code=400 message=` with an empty message.
- Conclusion: do not attribute this failure to the sprite prompt or reference path and do not claim a generated GIF exists. Keep `prompts/templates/sprite_protagonist_walk_right_battle_match_v1.yaml` and retry the single task after the provider is repaired.

# 2026-07-28: Field sprite body-standard generation and response contamination

- `sprite_lengguyun_turnaround_standard_v1` produced a PNG that was an unrelated Chinese information graphic. A successful response plus PNG/meta files is not acceptance; all generated art requires human visual review.
- Do not correct protagonist body-proportion drift by stretching existing idle or walk frames. Generate and approve one full-body neutral body standard first, then use it as the shared reference for all idle and walk directions.
- `sprite_protagonist_body_standard_v1.yaml` locks a seven-head, medium athletic build, blue-grey cross-collar robe, diagonal leather strap, sword and one left-side grey-green gourd. Candidate files remain outside `game/art/**` until approved.

- Adopted result: the approved A body standard drove the final 4-frame walk/idle set. The user selected down candidate `v1_b` and up candidate `v1_a`; right was accepted and left is its per-cell mirror. All eight fixed 160x160 runtime sheets were transferred to `game/art/characters` under `hero_*_body_standard_v1_4f.png`, with old sheets retained as rollback files.

- Godot 4.6 treats Variant inference warnings as errors in headless test scripts. A test must assign `load()` to a typed `PackedScene` and cast `instantiate()` to `Player`; when sprite frame count or resource paths change, update the regression assertions in the same change.

## 2026-07-28: Battle reaction assets must be bounded on both axes

- A fixed-height `256x256` post-process works for upright fighters but crops horizontal defeat poses: the source alpha silhouette can exceed the canvas width, cutting away the head, feet, weapon, or cloak.
- `scripts/prepare_battle_reaction.py` now uses a `512x384` combat canvas and computes scale from both the available width and height. It preserves the bottom anchor, keeps a top/side safety inset, and rejects output that would touch a canvas edge.
- Processed reaction art remains a candidate until visual review confirms both full-body coverage and character identity consistency. Never deploy a processed image simply because it contains alpha.
# 2026-07-28: Native panorama generation retry pattern

- The Linxi right-panel request with a local reference image returned an empty ALAPI `400` twice and produced no PNG. Do not immediately duplicate reference-image requests.
- A no-reference prompt with explicit camera, palette, route width, seam treatment, and forbidden baked objects generated successfully. For scene panels, prefer this locked-style prompt when the provider rejects reference inputs, then review the seam manually before adoption.
- Successful candidates from this run remain outside `game/art/**` until native side-by-side composition and walkability review:
  - `assets/raw/scene_background/linxi/panorama/v4/scene_linxi_tutorial_panorama_right_v4.png`
  - `assets/raw/scene_background/ch1-forest/panorama/v1/scene_ch1_forest_panorama_left_v1.png`
  - `assets/raw/scene_background/linxi/modules/v1/scene_linxi_modular_props_v1.png`

# 2026-07-29: World-map entry and native panorama rules

- `M` is a map-information affordance, never a travel command. Travel-map scenes must be entered by an ExitZone with an explicit target spawn.
- World-map movement must use connected positive road corridors. A single landmass polygon makes mountains, cities and coastline silently traversable even when physical blockers exist.
- A panorama can only be adopted after checking the native composed image for seam continuity. Compose same-height panels without scaling, then derive design size, NPCs, portals and collision footprints from the adopted composition.
- If independent panels fail continuity review, discard the composition. Generate one complete native 3:2 map and enlarge only with a uniform runtime scale; this preserves proportions and is preferable to a visible AI seam.

# 2026-07-29: Native-size map centering must convert player coordinates

- A reviewed `1536x1024` scene cannot be declared as a `3072x2048` layout merely to fill a `1920x1080` viewport. It must opt into `display_at_native_size`, render at scale `1.0`, and use neutral viewport margins rather than map-art stretching.
- Once the world container is centered (or camera-shifted), `Player` movement constraints receive global coordinates while `walkable_regions` are world-local. Convert targets with `world_container.to_local()` before normalizing, or valid spawn movement can be rejected.
- Regression coverage for a native map must assert: native design size, native-display flag, spawn inside the positive region, and a short valid move in all four cardinal directions.

# 2026-07-29: Foreground occluders are separate from collision

- Fences, low eaves and foliage painted into a background cannot occlude a runtime Player. Slice the reviewed prop into a transparent PNG and declare it as a `render_layer = "foreground"` scene object; `ForegroundLayer` must be above actors while its optional blocker remains only at the object foot.
- A portal marker must render above foreground occluders and sit on visible traversable road pixels, not on bamboo or other edge decoration. Keep the roof footprint blocked separately so the route stays visible without allowing a player to stand on the roof.
- Never substitute a generic fence for a distinct gate frame. If the baked map contains a gate, generate and alpha-extract a matching open-gate foreground prop, align it over the baked frame, and keep the portal's marker offset below the roof on the actual exit road.

# 2026-07-30: ALAPI does not provide an ultrawide world-map path

- A `3072x1024` `gpt-image-2` world-map task rendered correctly in dry-run but three real attempts all returned `422: 选定的 size 无效`; no image was created.
- A previous `2048x1152` request returned a downscaled `1672x941` image, proving request dimensions are not delivery dimensions.
- Do not spend further budget on independent panorama panels or unsupported ultrawide sizes. Existing `1536x1024` world maps must use `display_at_native_size = true` and matching `design_size`; expandable local exploration areas must use a terrain-only base plus reviewed module assets.

# 2026-07-31: Scene art must be a playable 2.5D map, not a loading illustration

- A polished hand-painted room can still read as a flat design sheet when it lacks a navigation plane, wall thickness, floor perspective, contact shadows and object occlusion.
- New scene acceptance requires: a pre-rendered 2.5D camera, visible wall/roof side faces, a clearly readable middle walking route, furniture with grounded feet/shadows, and a separate foreground layer where tall props must occlude the player.
- Prefer a terrain-base plus independently reviewed buildings, trees and props for large local maps. Interior room stages remain centered on black, but must use the same spatial rules rather than a flat cutaway illustration.

# 2026-07-31: Battle returns must preserve field context

- A battle `return_scene` alone is insufficient for a walkable RPG. Reconstructing the scene at its resource default spawn turns every dialog or ambush into an involuntary teleport.
- `SceneRouter` therefore keeps a normalized last field position; `FieldWalkableController` refreshes it at spawn and after movement. `start_battle` copies that context into the result payload, and Victory uses it with `go_field_smart`.
- Treat full-body combat art as a separate resource class from dialogue portraits. A portrait may be aesthetically strong but must never be used as the battlefield actor fallback.

# 2026-07-31: Native background policy is executable, not aspirational

- A map layout that leaves `display_at_native_size` false will still uniformly enlarge a 1536px background to the viewport or a legacy design width, even when no non-uniform scaling occurs. This reads as a stretched map in gameplay and also invalidates collision review.
- All adopted first-chapter exploration maps and Linxi room stages must enable native display. If the asset is smaller than the viewport, use neutral margins or a reviewed, native modular extension; never hide the shortage by scaling the background.

# 2026-07-31: Audio replacement needs provenance

- Placeholder tones are useful for wiring audio but are not acceptable as a release BGM baseline. When adopting public audio, keep the original filename, creator, license, source page and intended in-game role in a versioned local `LICENSES.md`.
- The first production baseline uses CC0 tracks from OpenGameArt for field and battle BGM. Keep combat cues as separate paths: later SFX replacement must not require touching combat logic.

# 2026-07-31: Mobile-first interaction feedback

- Do not show keyboard-only interaction prompts in a mobile-targeted build. Proximity feedback is a visual affordance: alpha sprites use the shared jade outline shader, while baked background details use a thin runtime line frame.
- Keep the interaction action itself input-agnostic. `Area2D` accepts proximity + the legacy interact key, plus mouse left-click and screen touch when the player is in range. This preserves PC usability without putting `空格` text into the UI.

# 2026-07-30: Terrain-base requests can fail silently

- `scene_ch1_road_terrain_base_v1` passed dry-run but two real ALAPI requests returned after the job header with no file, metadata, result summary, or failed-log entry.
- Treat this as provider non-delivery, not success and not an art rejection. Do not replace a running map or deploy a substitute asset. Keep the retry scope to this single terrain-base task when the provider recovers.
- The current `ch1_s1_road` background contains a baked stone tablet and distant buildings, so it cannot be used as a modular terrain base. Its layout is native `1536x1024` only until an approved replacement exists.

## 2026-07-30 update: ALAPI result summaries can lag behind file output

- The third controlled retry eventually wrote `scene_ch1_road_terrain_base_v1.png` and metadata even though the console stopped after the task header with no summary. The candidate is native `1536x1024`, cost `¥1.20`, and passed visual review.
- After a silent return, inspect the exact output directory and `.meta.json` before declaring failure or repeating a paid request. Stop retries immediately when an accepted candidate exists.

## 2026-07-30: Remove a baked gate before adding foreground occlusion

- The original Linxi tutorial background contained a baked village gate and fence across the lower-right route. Adding a separate gate in front would have created duplicate perspective and could not make the baked gate occlude the player.
- The correct fix is to regenerate a gate-free base image first, then rebuild road bounds, foot collisions, and the portal from the approved image. Only add a transparent `render_layer = "foreground"` gate after it is designed against that exact base image; no generic prop may cover an unrelated baked gate.
- The approved replacement keeps the lower-right road entirely open. The portal marker is positioned on road pixels, while only actual house, forge, and side-fence footprints are blocked; the central practice disc is intentionally walkable.

## 2026-07-30: House interiors stay modular

- House interiors are separate `SceneScript` + `WalkableMapLayout` resources. Door portals and furniture-foot blockers are authored from the exact generated interior image; background art never contains the interactive chest.
- The practice disc is decorative terrain with an interaction area, not a solid object. A central landmark that players are expected to stand on must never remain in `blockers`.

## 2026-08-08: Runtime state and map continuity are release contracts

- Formation rendering and turn resolution must share the same initialized
  combatant list. A 1v1 formation battle still needs runtime units; otherwise
  an empty enemy array is interpreted as an immediate victory.
- Progress flags are not skill ownership. A training event must grant the
  skill and set its flag in the same transaction, then reconcile old saves
  whose flags predate the explicit skill grant.
- A visible road crossing polygon boundaries needs intentional overlap.
  Validate several consecutive samples through the narrow connector instead
  of testing only its start and destination.
- Review every interior against the 160 px field-character reference before
  adoption. Furniture silhouettes, especially beds and weapon racks, cannot
  be corrected later by scaling the runtime character.

## 2026-07-30: Indoor furniture scale and props

- A generated bedroom can satisfy the layout prompt while still making the bed several times too large relative to the runtime character. Review furniture against an in-game character screenshot before adoption; do not stretch the character to hide a bad background scale.
- Interactive chests must be separate transparent props. The accepted bedroom chest is a modest wood-and-iron supply box, trimmed to a small runtime canvas; the old oversized metal chest and the generated v4 background with a baked duplicate chest were rejected.

## 2026-07-30: Indoor scenes use room-stage composition

- For compact interiors, do not force a scenic background to fill the entire viewport. A centered cutaway room on pure black provides a clear classic-RPG presentation and makes the runtime character scale legible.
- A room exit should be a dark interior opening, not a rendered exterior landscape. `ExitZone` owns the animated arrow and interaction prompt, so no outdoor grass, route, or baked portal marker belongs behind it.

## 2026-07-30: Bedroom scale correction needs art and runtime validation

- The V5 bedroom still had a visible wooden doorway frame and furniture that dwarfed the Field player. Replacing that frame with a foreground prop would recreate the occlusion problem, so the approved V6 base removes every post, lintel, threshold and exterior element from the exit.
- `scene_linxi_hero_bedroom_interior_v6_refined.png` is adopted as `bg_linxi_hero_bedroom_stage_v2.png`. The room has a lower-center unframed black gap, smaller cot/desk/rack silhouettes, and no baked chest.
- Compact rooms may use `SceneScript.player_visual_scale` only as a local presentation adjustment. Keep collisions and interaction coordinates in world space; use the reviewed `1.32` multiplier for `linxi_hero_bedroom`, not a global Player scale change.
- Acceptance requires both `validate_walkable_map_v2.gd -- scene=linxi_hero_bedroom` and the in-game capture. The screenshot confirms the exit arrow rests on the last floorboards, while the portal remains reachable without letting the player enter the black void.

## 2026-07-30: Investigable background details use explicit interaction zones

- Baked background details such as beds, bedding and papers must remain visually part of the room art, but their gameplay affordance belongs to `WalkableMapLayout.interactions`: an `activation = "interact"`, label, action and small reachable area.
- `FieldWalkableController` now presents the nearby prompt only while the Player overlaps an interaction-only area. It triggers the action only from the explicit interact input, never while walking into range. This prevents accidental dialogue interruption and makes decorative versus interactive objects readable.
- The first reusable examples are `ch1_hero_bedroom_bed`, `ch1_hero_bedroom_bedding` and `ch1_hero_bedroom_note`. They use flags as durable clues; a later quest can consume those flags or add an item reward without rewriting the scene art.

## 2026-07-30: Interior scene pack acceptance

- A reusable indoor image needs a broad clean center route, furniture only at the edge, a black unframed lower exit and no baked characters or chest. This lets the same visual support NPCs, combat, loot and puzzle states without another background generation.
- Accepted assets: `bg_interior_inn_hall_v1.png`, `bg_interior_martial_hall_v1.png`, `bg_interior_bandit_cave_v1.png`, and `bg_interior_temple_tunnel_v1.png`. Each has V2 positive walkable geometry and an explicit inspect action.
- Reject art that includes baked quest containers or legible unintended signage, even if its composition is otherwise useful. The villager cottage V1 has both a fixed storage box and generated shrine text, so it remains a raw candidate only.

## 2026-07-30: Exit orientation and Field sprite lighting

- A lower cave opening is visually ambiguous: a default down arrow reads as entering deeper. `ExitZone.marker_rotation_degrees` lets a return exit rotate its marker by 180 degrees. The bandit cave uses an up arrow and the label `离开洞窟`, positioned on the threshold rather than inside the black void.
- The existing protagonist Field strips have flatter, brighter lighting than the newer indoor scenes. Do not tint them globally. Generate a one-character 2.5D lighting master first, then use its approved material, contour and warm key-light treatment for every direction and motion frame.
- Candidate `sprite_lengguyun_field_25d_master_v1.png` was produced on a #00ff00 chroma key and successfully alpha-extracted to `assets/processed/sprite/field-25d-master/sprite_lengguyun_field_25d_master_v1_alpha.png`. It remains a visual reference until four-direction animation art exists.

## 2026-07-31: Battle facing, contact position and party health UI

- Do not derive an attack-facing flip from an actor's idle flip. Initial formation facing and target direction are separate facts: battle sheets are authored facing left, so left-side allies use `flip_h = true` at rest and any actor attacking right uses that same mirror; right-side enemies stay unflipped to face left.
- Fixed-distance attack movement fails as soon as actor art, scale, formation slot or viewport changes. Compute the contact position from the target and attacker global rectangles, convert the intended centre back into the actor parent space, then tween to it. This keeps melee contact and impact VFX aligned for both 1v1 and party formations.
- Party units should not carry name cards above their heads. The reusable `BattleActor` owns one compact HP bar, which follows its actor during enter/attack/hit tweens. Keep the larger player panel only as the selected/current actor detail surface; hide the redundant enemy corner HUD.

## 2026-07-31: Gate-free scene replacement before foreground props

- A village gate baked into a scene background cannot be repaired by placing an unrelated foreground gate over it. Regenerate a gate-free 2.5D base first, then put the portal on real road pixels. Only create a transparent gate prop later when it is designed against that exact approved base.
- `scene_zhuwei_main_street_25d_gatefree_v2` is the accepted first application: it has no baked gate, posts or arch at the lower-right exit, while preserving a continuous stone road for the portal marker and collision layout.
- Field NPC scale must be specified against the actual per-frame canvas, not the full sprite-strip width. The old Zhuwei entries multiplied a strip by `0.11`; the 160x160 2.5D sheets now use the same ~`0.95` display scale as the player.

# 2026-07-31: Modular building collisions must affect both physics and movement prediction

- `visual_objects` can declare their own foot collision, but `FieldWalkableController._is_blocked_by_layout()` originally read only layout-level `blockers`. Physics would eventually reject a building overlap while the Player pre-move constraint still considered it valid, producing a visible step into an inn or house on fast movement.
- Combine explicit blockers and every visual-object collision footprint before evaluating the normalized movement target. Keep collision at the building's base/steps, never over the whole transparent roof silhouette. Check each door interaction against this combined set; a trigger inside its own collision is an unreachable false affordance.

# 2026-07-31: Release-flow tests must read the live walkable map graph

- A SceneScript can contain retired hotspots while current navigation lives in `WalkableMapLayout.portals`, `.interactions`, and `visual_objects[*].interaction_action`. A content flow validator that reads only classic scene arrays can report a false broken chapter path or, worse, miss a real one.
- Validate both representations, but treat map-layout actions as required release graph edges for walkable scenes. This exposed the stale `scene_entered:ch1_s2_qingfeng_walkable` trigger; Chapter 1 now completes its arrival quest on the live `ch1_s2_qingfeng` field ID.
# 2026-07-31 · 场景模块不能把棋盘格当透明

- 生图接口声明 transparent 仍可能返回 RGB 棋盘底图；必须在接入 Godot 前检查 PNG mode/alpha，不能只看预览是否像透明。
- 竹尾村的建筑模块应保持独立 Sprite2D、缩小到与 NPC 同比例，并把建筑脚部碰撞和入口交互尺寸一起调整；不能用放大建筑去弥补小场景。
- 城西废宅的出口可视化不等于可达性；每次替换底图后要用 BFS 同时验收出生点、回村出口和剧情解锁出口。

# 2026-08-01 · HUD 菜单按钮不能与滑出菜单共用位置管理

- 右上角系统菜单是固定入口，不应加入背包/装备/武学/任务的滑出按钮数组，否则入口会被一起移到屏幕外。
- `@onready var foo = %Foo` 要求场景节点名称和 unique name 完全一致；系统菜单滑条曾命名为 `Slider`，脚本却读取 `%BgmSlider/%SfxSlider`，点击时才暴露为空实例错误。

# 2026-08-01 · 主街建筑要和底图一起生成

- 当独立建筑的透视、光照和地面比例无法与野外底图稳定匹配时，主街应改为整张预渲染 2.5D 场景；独立物件只保留给确实需要动态交互的箱子、门、树等小物件。
- 室内出口的 `target_pos` 必须落在目标场景的可行走道路，而不是建筑门口的视觉位置；否则传送成功但玩家会立刻被碰撞层卡住。

# 2026-08-05 · 单主角对多敌人也必须进入队伍运行时

- 不能用“我方人数大于 1”作为队伍模式的唯一条件；1v2、1v3 同样需要初始化敌方 `BattleCombatant`、行动队列和目标选择，否则敌方数组为空会被误判为即时胜利。
- 多敌胜利不能只结算首个 `EnemyDef`。必须逐敌写入击败 flag、广播任务事件并累计金币、经验与掉落，否则任务链和经济都会漏结算。
- 随机遭遇要保存进入战斗前的精确场景坐标，胜利后回到原位置；回出生点会造成重复触发、路线倒退和练级体验中断。

# 2026-08-06 · 调查事实与人物说法必须分层

- 物证只记录玩家实际观察到的事实，NPC 的解释必须作为独立证词保存并带初始可信度。不要因为某人说“是我杀的”就把凶手身份写成永久 flag。
- 开放世界分支不能只依赖一个好感值。阵营信任、伙伴信任、关系关键事件、城市结果和办事手段需要分别持久化，结局组合时再共同判断。
- 新增持久状态必须升级存档 schema，并为旧存档提供缺省空数据。本批次 SaveManager 升至 v5，`investigation` 缺失时由 `InvestigationState.from_dict({})` 安全迁移。
- 内容发布校验器必须和运行时 action/trigger 协议同步。运行时支持 `battle_then` 而校验器遗漏它，会造成假的章节不可达报告。
# 2026-08-06 - 门派选择应改变调查视角而不是封锁主谜案

- 开放世界中的门派选择最适合改变信息来源、训练方式、阵营信任和证词偏向；如果直接给某派完整真相或永久关闭其他调查内容，会让选择变成单次答案题，也会削弱各派的灰度。
- 每条门派分支必须有独立的加入动作、信任变化、持久调查权限和本派证词，同时必须明确回到共同主线的节点。
- 为分支剧情写专项校验，检查分支数量、配置 ID、证物/证词、副作用以及汇合节点。只做通用场景可达性测试无法发现某一派漏回主线的问题。

# 2026-08-06 - 双案分支要让玩家选择保留哪类真相

- 当救人与追捕同时发生时，不要把其中一项写成明显错误选项。让同伴承担另一项任务，可以保持正义主角边界，同时用“完整活证”和“完整文书”的差异制造真实取舍。
- choice 节点本身有选项时，节点级副作用不会执行；证物、证词、信任、关系事件、城市结果和方法标记必须写在各自 choice 字典中。
- 分支汇合不能抹掉选择。共同主线读取持久方法标记和城市结果，后续审讯、伙伴评价与结局组合才能反映玩家先前的办事方式。
# 2026-08-08 - 入口、精灵脚点和剧情奖励必须由运行时契约兜底

- 160x160 的 Field 单帧不能让非透明像素贴到画布底边；正式运行资源统一把脚底控制在 y<=152，预留至少 8px，避免缩放、采样和动画切帧截脚。
- 场景默认出生点、建筑返回点和战斗返回点是三种不同语义。首次进入使用 authored spawn，建筑返回使用门前坐标，战斗返回保留原位置；旧存档中的已知错误坐标需要显式迁移。
- 场景数据中的正式资源可能被控制器按 NPC ID 再次覆盖。资源验收必须检查最终解析路径，禁止运行时回退到旧图。
- 剧情显示“学会招式”时，设置进度标记与写入角色技能列表必须在同一事件链完成，并在读档校准中补偿旧存档，不能只显示提示文字。
- `style_rich_text()` 会重新安装默认背景。需要透明文本层时，必须在应用主题后再覆盖 `StyleBoxEmpty`，否则黑色内容框会遮住生成的正式面板。
- 带地面站位标记的战斗图必须按 arena profile 使用角色脚点对齐站位，且单敌人也不能绕过阵型视图。

# 2026-08-08 - 同款装备必须区分模板身份与实例身份

- `item_id` 只标识装备模板，不能用来标识背包中的具体一件装备。不可堆叠装备进入背包时必须生成稳定的 `instance_id`，穿戴、出售、丢弃和存档均以实例为准。
- 同一装备槽仍只能保存一个已穿戴实例；替换同槽装备时只切换实例引用，其他同款副本保持未穿戴。商店批量出售同款时应优先消耗未穿戴实例，避免玩家无意卖掉身上的装备。
- 旧存档若只有模板 ID，应在加载时为每个不可堆叠副本补实例 ID，并将旧的已穿戴模板映射到其中一个实例。迁移规则必须由运行测试覆盖。
- 出口的触发碰撞与箭头视觉位置也应分离：碰撞留在真实道路尽头，箭头按屏幕安全边距显示，靠近提示读取 `destination_name`，不能为了修显示位置而破坏可达性。
# 2026-08-08 - NPC conversation facing must use directional assets

- In a 2.5D four-direction field, conversation facing should be derived from `player_global_position - npc_global_position` and should select the authored up/down/left/right texture. Horizontal mirroring is only a fallback when an authored direction is unavailable.
- If an older idle strip touches the frame bottom or crops the feet, freeze a complete neutral frame from the matching walk strip during conversation, then restore the patrol texture and frame loop when the conversation ends.
- Do not recolor a jade exit arrow only by multiplying its runtime color: dark source pixels stay muddy. Export a separate RGBA amber variant while preserving the original alpha and dimensions.
# 2026-08-08 - 生成 UI 裁切、场景重建与对话奖励契约

- 生图面板即使视觉上像透明素材，也可能在四周带有不透明暗边。接入 `StyleBoxTexture` 前应先用 `AtlasTexture` 裁掉素材外沿，再做九宫格缩放，不能用额外黑色遮罩掩盖。
- 运行时构建场景节点时，应先 `add_child()` 再设置依赖场景树或父级坐标的属性；重建场景期间访问旧玩家或旧 NPC 引用前必须执行 `is_instance_valid()` 检查。
- 对话授艺、发放道具和写入关键剧情标记必须在节点首次进入时一次性提交，并设置防重复标记；不能依赖玩家推进下一句、关闭对话或重新进入场景才生效。
- 本项目直接用 `--script` 启动 `SceneTree` 测试时不会自动解析项目 Autoload 名称。Autoload 相关测试应使用工程内测试入口，或在测试脚本中显式预加载依赖；不能把该测试方式的编译失败误判为游戏工程解析失败。

# 2026-08-09 - ALAPI 空 400 必须用异质单任务确认后停跑

- 批次中途出现 `ALAPI error code=400 message=` 时，先用一项无参考图任务和一项安全题材任务分别执行 `--skip-ping` 单任务验证。两类都连续空 400，且任务费用为 0，即可判定为服务端通道故障，而不是某条 prompt 或参考图问题。
- 故障期间禁止盲目重跑整批；保留预算、成功 PNG 和旁车 `.meta.json`，并记录失败任务 ID。通道恢复后先以 ¥1.30 单图预算验证，再逐项续跑。
- startup ping 会产生未计入任务元数据的真实调用。批次恢复阶段优先使用 `--skip-ping`，避免每个单任务都额外探活。
- API 107 当前公开协议使用 `image_urls` 传参考图，并推荐 `/images/generations_sync` 提交、`/images/generations/task` 查询。同步公共 400 时可用异步路径区分“请求未受理”和“上游模型任务失败”；若异步任务可创建但不同题材均返回 `task failed, please try again later`，应携带 task ID 联系渠道支持，继续修改 prompt 没有诊断价值。

# 2026-08-09 - 内置生图的网格数量必须先目检再切片

- 即使 prompt 多次声明 Battle 图集为 4×5，模型仍可能生成 5×5。不能让切片脚本把错误网格强行解释为 4×5；先肉眼数行列，再用“只删除多余第五列、保持人物动作不变”的单点编辑纠正。
- Codex 内置输出本批为 1254×1254 RGB。Field/Battle 母图应先保留原始尺寸，再由项目切片器统一锚点和运行尺寸；VFX 则抠图后归一为 1024×1024 RGBA。
- 内置工具不提供与 ALAPI 相同的任务计费字段。旁车 meta 必须使用独立 `codex_builtin` backend 且成本留空，禁止填写推测金额。

# 2026-08-09 - 多帧武器动作不要只靠左右手文字约束

- 同一角色多帧单手武器图即使明确写“解剖学右手”，模型仍可能在收势帧产生换手读法。必须把备战与攻击放在同一母图中，并逐帧追踪手腕、拳、护手与剑柄的连续关系。
- 当单手连续性两次目检仍不稳定时，可改用全程双手握柄的动作设计，消除左右手歧义；但仍需确认八帧双拳均落在同一剑柄且没有烤入 VFX。
- NPC 场景数据中的新版资源可能被 `NPCCatalog` 再次覆盖回旧图。脚底安全区验收必须检查运行时最终解析路径，不能只看场景 `.tres`。
- UI 图片若烤有功能文字，不得作为另一功能按钮的九宫格背景。交互文字应由 Godot 渲染，按钮图只保留无字框体。

# 2026-08-09 - 人物热点、任务秒结和章节返程必须一起验收

- `WalkableMapLayout.interactions` 适合门、告示、箱子等无实体物件；用它承载货郎、掌柜、捕快会只剩感叹号，没有人物、名字和身份锚点。凡是对白说话者，应优先建成 `SceneScript.npcs`。
- 同一对话串联多名证人并在末尾同时写完成 flag 和 `complete_quest`，会让调查退化成一次点击领奖。前置证词分别落状态，最终 NPC 通过全部 `require_flags` 才切换结论对白；任务只保留一个完成来源。
- 章节入口场景如果所有出口都带 `require_flag`，且没有 `locked_label`，玩家初进场会看见零出口并被困住。必须提供一个无条件返回上一枢纽的 portal，同时让未解锁路线以锁定箭头告知方向。
- 1536×1024 单屏背景在更宽窗口使用 native centering 会露出灰边；户外场景应等比 cover，不能非等比拉伸。
- 脚底验收不能只比较文件名。逐帧读取 alpha，正式 Field 精灵至少保留 6px 底部透明区，并检查 NPCCatalog 覆盖后的最终路径。

# 2026-08-09 - 脚底留白不能证明人物全身完整

- 把一张已经贴底或截脚的运行条带整体缩小，再补透明边距，只会让 alpha 合同变绿，不能恢复源图中已经丢失或不可读的鞋靴轮廓。运行图必须从保有完整双脚的 raw source 重新切片，禁止用旧 runtime 作为二次处理源。
- Field 源图预检必须发生在裁切和缩放之前：抠色后逐格检查原始人物与格子底边的距离；原始 bbox 触底时应立即失败，不能由后处理 padding 掩盖。
- `sprite_quality = "full_body_reviewed"` 只是声明，不是证据。正式采用资源应保存 source/runtime SHA-256、处理脚本与参数，并让专项测试锁定审批后的 runtime hash；首次仍需查看下半身放大接触表和实机截图。

# 2026-08-09 - Loading 构图与可玩地图需要不同的清晰度合同

- 带景深、雾化和摄影式虚化的村落全景可以作为章节 Loading 图，但不适合承载 2.5D 精灵与精确交互；正式探索底图必须从前景到出口保持统一清晰，地面、台阶、摊位和建筑脚点都要可辨。
- `KEEP_ASPECT_COVERED` 会在 3:2 底图进入 16:9 视口时产生上下裁切。NPC 的屏幕归一化坐标不能只看原始 PNG 猜位置，必须在目标分辨率实机截图中复核脚点；自动测试同时校验 walkable polygon 和 blocker 只能拦住数据错误，不能替代视觉落地检查。
- 宣传感强但不适合玩法的旧图不要覆盖删除；保留版本化文件并标注 Loading 候选，游戏场景只引用经过清晰度、道路和 NPC 落脚验收的 gameplay 版本。

# 2026-08-09 - 视觉道路、出生脚点与大图滚动要分别验收

- 场景拥有三个外部去向但底图只有两条明确道路时，不能靠堆叠箭头或把传送点塞进草丛解决；先补出第三条真实道路，再同步 walkable polygon、portal 与 blocker。画面正确但导航数据未扩展，同样会形成“看得到、走不到”的假出口。
- 归一化坐标通过多边形/矩形检测，只能证明它在数据上的可行走区域，不能证明角色脚点没有压在预渲染屋檐上。大地图入口必须在原图上叠加候选坐标目检，并用目标分辨率实机截图复核；本次 `(0.300, 0.500)` 逻辑通过却仍落在小屋屋顶，最终改为 `(0.220, 0.600)`。
- 大尺寸完全不透明底图不要以 RGBA 保存；先移除冗余 alpha，减少磁盘、导入与显存压力。角色按 physics tick 移动而相机在 render tick 直接追坐标时，会出现 4–5px 级跳动；相机应做帧率无关平滑，最后再取整以兼顾稳定和清晰。
- 任务“追踪”若只保存在任务窗口脚本的局部变量，Field HUD 与存档都无法读取。追踪状态应由 `QuestManager` 作为单一来源，只允许活动支线进入追踪槽，并在完成、失败、读档和新游戏时统一校准。

# 2026-08-10 - 出口碰撞点正确不代表箭头显示点正确

- 出口物理坐标可以位于地图边缘，但通用箭头安全区若设置得过大，会把边缘箭头强制拉回内场，并与附近房屋入口重叠。本项目旧的右侧 440px 回缩正是村民家与南坊箭头叠放的根因；提示文本实际只需要约 120px 边距。
- 房屋入口需要以门槛外侧、楼梯底部或围栏开口为视觉锚点逐个审核，不能仅靠“portal 可达”判定。专项测试应锁定已审核坐标、目标室内场景、可通行性及相邻入口的最小距离。

# 2026-08-10 - 剧情旗标不能代替可追踪的主线阶段

- 对话只写 `master_farewell_done`、`got_sword` 等 flag，虽然能控制 NPC 和出口显隐，却不会自动出现在任务日志或 Field HUD。每个玩家可行动阶段都必须有明确的 `QuestDef`，并在前一段剧情结束时立即接取。
- 连续主线应遵循“完成上一阶段、同节点接取下一阶段”的交接合同，避免玩家离开对话后出现任务空窗。本次第一章固定为：领取佩剑 → 启程前往竹尾村/山道遇袭 → 回禀师傅 → 师门授艺 → 继续前往竹尾村。
- 同一剧情并存新旧任务 ID 会让两个主线同时激活，HUD 若读取 Dictionary 第一项还会显示错误阶段。读档时必须把旧 ID 迁移到正式 ID；当前主线选择应按剧情进度排序，而不是依赖插入顺序。

# 2026-08-10 - 对话转身必须有可用的四向人物素材

- 根据玩家位置算出 `up/down/left/right` 只是逻辑朝向；如果 NPC 只有正面条带，水平镜像仍然是正面人物，无法表现背面或侧面，对话时就会继续背对玩家。
- 可对话 NPC 应优先提供完整四向 idle/walk 家族；历史资源只有正面时，必须通过场景数据显式绑定 `conversation_sprite_paths`。进入对话时冻结所选方向的中性帧，退出后恢复原巡逻方向和动画状态。
- 方向缺失不能静默 fallback。运行时应输出包含 NPC ID 与缺失方向的警告，专项测试则锁定当前重点场景每个静态 NPC 的四个资源路径都存在；版本化正面文件还要能解析同角色已审核的无版本四向家族。
- 四向图除方向语义外仍要执行 Field 合同：160×160 RGBA、完整头脚、统一比例和脚底安全区。首次采用必须目检正面、背面和两侧身份一致，自动像素检查不能替代人物朝向审核。

# 2026-08-10 - 可见道路、NPC 交互与任务提示需要独立合同

- 多段 walkable 矩形在视觉上相接不代表导航连续；边界之间只要留下很窄的归一化间隙，就会形成看不见的空气墙。相邻道路区域应保留重叠，并在每个交汇处设置可达探针。
- NPC 交互不能只依赖 `Area2D.body_entered` 的瞬时状态。场景重建、碰撞刷新或快速点击时可能漏掉进入信号；点击和按键入口应共享一个受限距离兜底，同时仍由导航测试证明玩家能够走到交互半径内。
- 任务日志说明和 HUD 引导不是同一份文案。日志可记录剧情和阶段信息，Field 追踪只显示不剧透的地点目标；不得把 `desc_in_progress` 直接投放到常驻 HUD。
- 同一页面的功能按钮应共享一套无字 normal/hover/pressed 资源，由 Godot 动态渲染文字；不能因功能不同混用绿色平框、战斗长条和正式纹样框。

# 2026-08-10 - 版本化人物不能静默降级到旧方向图

- 正面资源是 V3、方向兄弟资源缺失时，按文件名移除 `_v3_` 再寻找旧图会混用不同身份和处理质量；本次杜青衫旧 V1 方向条还含格顶残肢，直接造成对话重影。
- 重点 NPC 的四向资源必须保持同一版本，并在场景中显式绑定。专项测试不仅检查方向文件存在，还要断言运行时最终 `resource_path` 仍属于当前版本。
- processed 资产库中已有合格资源但未复制到 `game/art`，等价于运行时资源缺失；资产采用验收必须覆盖实际游戏目录，而非只查看 processed 预览。

# 2026-08-10 - 大型探索地图必须布局先行

- 先生成细节密集的场景图、再靠人工矩形拼 walkable 区域，会不断出现“石路走不通、屋顶可以走”的错位。地图生成前必须先固定道路拓扑、建筑禁行岛、门前落脚区、NPC 锚点和出口。
- 生图时结构图是硬参考，旧场景只能作为画风参考；prompt 必须明确道路和广场内禁止出现房屋、屋顶、围栏、岩石、树干、摊位及其他阻挡物。
- 运行时导航数据应由同一结构图重建，并同时布置道路 reachable probes 与屋顶 blocked probes。只看最终美术图或只跑出口可达测试都不够。
- 生成图中的道路可以适当宽于真实碰撞范围，但建筑 blocker 不得反向侵入道路；NPC 验收要证明玩家能从出生点走到其交互半径，而非只证明 NPC 坐标落在画面内。

# 2026-08-10 - 低分辨率场景图不能靠大幅插值冒充大地图

- 1817×866 的生成图放大到 3388×1614 后，即使 PNG 文件更大，也不会增加真实细节；相机再以 1.35 倍取景时，石路和屋瓦会明显发虚。运行尺寸应尽量接近源图，本次采用 2048×976、相机缩放 1.15。
- 房屋“画在背景里”不等于可进入。至少对剧情和功能相关建筑配置门槛外入口、室内场景及原路返回点，并由导航测试校验双向链路。
- `bottom_margin >= 6` 只能拦截 alpha 贴底，拦不住“旧截脚图整体缩小后补透明边”。全身修复必须从明确含双脚的上游源帧重切，并同时做逐帧 alpha 合同与实机目检。

# 2026-08-10 - 行动点不能延迟胜负与完整行动结算

- formation 状态机若先扣行动点、发现仍有行动后直接重开按钮，敌人即使已经死亡也会要求玩家再点一次。固定顺序应为：动作/伤害完成 → 敌方全灭判定 → 强制结束类动作清空行动点 → 普通剩余行动处理。
- 防御沿用旧的“下回合额外行动”奖励，会在已有多行动点时表现为防御后仍可攻击，违背玩家对防御即结束操作的预期。防御只保留减伤状态，并强制结束当前角色行动。
- 战斗背包不能依赖普通 `_post_action()` 自然扣一点，因为角色可能拥有多行动点。使用道具或更换装备成功时必须显式走 `force_end_turn`；取消/关闭则恢复按钮而不扣行动。
- NPC 资源路径中的身份语义也是验收项。普通参农误绑 `bound_villager` 即使尺寸、alpha 和脚底边距全部合格，仍是严重内容错误；专项测试需禁止明显冲突的资源族。
## 2026-08-11 - Boss 练级需求优先使用数值软门槛

- Boss 前不应默认设置强制等级门槛。先通过 Boss 生命、攻击、防御、技能和补给压力形成软门槛，让玩家实战失败或感到吃力后，自主选择支线、野外遭遇和装备准备。
- 剧情门槛仍应明确表达，例如必须先击败废宅外围守卫才能进入内堂；剧情资格与战斗准备度不能混成同一个硬锁。
- 扩展已有章节时必须迁移旧存档。若旧版本已经把最终任务设为进行中，应依据永久剧情 flag 回退/推进到新链条的正确阶段，同时保留已经击败章节 Boss 的完成档，不得强迫玩家重开。

## 2026-08-11 - Boss 登场前必须完成身份、职责和冲突三段铺垫

- “线索指向某地”不能直接等于“玩家认识最终 Boss”。Boss 正式出场前至少需要逐步回答：目标是谁、他在事件中负责什么、主角为什么必须与他冲突。
- 调查推进应让任务标题和目标地点同步变化。本轮先以“潜入废宅”承载外院战斗与两份现场记录，确认赵无忌后再切换“雾纹匪踪”进入内堂，避免一个任务从远距离追踪直接跳到击杀姓名未知的人。
- 章节结尾给出的新线索不能重新指向玩家刚完成的区域。后续钩子应连接下一章的实际入口，并只公布可观察事实，不提前宣布幕后阵营或真凶。

## 2026-08-11 - 战斗胜利不等于剧情击杀

- 初出茅庐的主角面对重要长期对手时，可以通过“重伤并逼退”获得阶段性胜利，不应因通用的 `enemy_defeated` 命名就默认把对手写死。
- 机械状态与叙事状态要分层：`defeated_<enemy_id>` 负责战斗、任务和隐藏热点，另用明确的长期 flag 记录负伤、逃脱和后续再登场。
- 重伤不能只写在对白里。若剧情声称主角伤势严重，战斗结算应同步留下可见的生命值代价；非致死 Boss 也不应继续播放明确的死亡式胜利演出。

## 2026-08-12 - 同一数值字段不得同时充当属性、最终值和倍率

- 装备 `atk_bonus` 若既作为最终攻击加成，又被折入筋骨再乘二，会让界面 `+7` 在单挑中实际变成 `+14`；队伍路径若又直接加 7，同一装备会因战斗模式不同而改变价值。最终值字段和核心属性字段必须分开结算，并用增量断言锁定。
- 伤害公式已经减过防御后，生命组件不能再次按自身防御减伤。公式层负责“固定伤害、攻击叠加、暴击、状态、防御”，生命层只负责扣除最终伤害。
- 武学 `power` 同时表示攻击倍率、固定治疗、装备加成和互补加成，会让资源、UI 和多条战斗路径逐渐分叉。攻击拆为 `fixed_damage` / `attack_scaling`，治疗拆为 `effect_value`，加成统一写成攻击系数百分点。
- 品质不能由展示层按“主动=蓝、被动=紫”推断。品质必须是资源字段，目录生成器和游戏 UI 只负责读取；验证器应锁定总量与各品质分布。

## 2026-08-12 - 高风险操作必须共用同一正式确认组件

- 只在某一个界面手写确认框，会让存档覆盖、读取、旧背包丢弃和战斗撤离继续出现原生窗口或无确认操作。确认框必须做成独立场景，调用者只提供标题、正文与按钮文案。
- 正式 UI 的一致性不只是底图相同。确认与取消按钮必须共享 normal/hover/pressed/focus 纹理、字体大小和内容边距；提示型单按钮应自动居中。
- 高风险确认应覆盖“数据不可恢复或会改变当前流程”的操作：覆盖存档、读取、丢弃、永久成长消耗品和撤离战斗；普通消耗品与可逆装备切换不增加确认负担。
- 剧情物品不能仅靠界面隐藏丢弃按钮保护，详情按钮与右键菜单必须进入同一规则函数，并在数据层操作前再次拒绝。
- 正式底图已包含完整明暗与框体时，不应再叠加低透明度或深色兜底遮罩；失败页与胜利页应使用同一套等比裁切和按钮资源。

## 2026-08-12 - 系统原生菜单不能混入正式游戏界面

- `PopupMenu`、`OptionButton` 即使功能正确，也会继承系统/默认主题的边框、字体与间距，在正式武侠底图上非常突兀。章节、流派和右键操作应共用数据驱动的正式选项组件。
- 通用选项菜单应接收 `{id, label, enabled}` 数据，不让业务界面复制按钮构建和三态样式；当前选项只负责高亮，不把显示文案当作业务 ID。
- 原生弹出菜单若已经被新的完整面板取代，应连同变量、初始化和死函数一起移除；仅仅不再连接按钮仍会留下以后误调用和风格回退的风险。
- 主菜单 Esc 直接退出容易误触，因此离开游戏需要确认；新游戏会重置内存中的临时进度但不会删除已有存档，应直接开始，不增加多余确认。

## 2026-08-12 - 品质用颜色表达时不要重复写颜色名称

- “白、绿、蓝、紫、橙”是开发侧品质分级，不应作为 `[绿] 招式名` 直接暴露给玩家；列表名称本身使用品质色即可，详情可用同色小标记维持辨识。
- AI 底图若只在四周带有固定宽度的不透明黑边，优先用 `AtlasTexture.region` 在运行时精确裁切，并让裁后纹理留在原始 inset 位置；把裁后内容重新拉满会让所有程序覆盖层与底图装饰错位。
- 回归测试应同时锁定裁切 region、显示尺寸和文案禁词，仅验证“纹理存在”无法拦住黑边回归或颜色标签复现。

## 2026-08-13 - 内容清单必须验证场景可达性

- `.tres` 任务存在、章节计划数量达标，只能证明“写过定义”，不能证明玩家能接到或完成。章节深度验证必须从场景入口索引 NPC、热点与串联对话，再核对每条任务的接取和完成来源。
- 跨章节收藏不能让最后一件物品的单一 flag 直接解锁奖励。应在状态层汇总全部前置条件，并用运行态测试覆盖“两件不解锁、三件只开放研读、完成研读才授予武功”。
- 历史典故适合提供城市质感、谜题机制和道德选择，但改编桥段必须写成架空借典；任务结论只能推进到玩家实际验证的层级，不能借典故顺手剧透幕后者。
## 2026-08-13 - 武器差异化属性必须贯通资源、公式、界面和目录

- 只在装备描述里写“提高暴击”不会产生玩法差异。新增武器属性时必须同时覆盖 Resource 字段、Inventory 聚合、BattleFormula、所有战斗入口、游戏内详情和静态目录，并用真实装备做回归。
- 武器品质不能只按攻击数值机械排序；有明确江湖名气的兵器要先满足叙事位阶，再在对应品质预算内配置数值与副属性。
- 图标全量审计不能只看已有图片的美观度，还要检查资源路径为空、文件缺失和 256px 下主体轮廓是否可辨。本轮除重做两把剑外，正是通过全量审计发现虎啸刀完全没有图标。
- “门派武功加成”和“兵器招式加成”是两个独立维度：前者体现名器与传承的契合，后者保证每把武器都有可感知的招式收益。展示与聚合结果必须拆开命名，不能让只有部分门派武器显示一条模糊的“威力”。
## 2026-08-13 - 成长属性不能顺手叠入战斗派生

- 悟性表达的是领悟武功与心法的能力，不应因为“属性需要有用”就顺手增加内力、速度和暴击；这样会让单个属性过于万能，也迫使大量普通装备堆叠悟性。
- 学习型属性应形成独立闭环：武学资源声明悟性门槛，研读消耗长期阅历，高出门槛的悟性提供有上限的费用折扣。战斗公式只读取战斗属性和明确的装备词条。
- 剧情直接授予武学仍需经过悟性门槛。未满足时把武学记入待领悟列表，并在升级或更换悟性装备后自动重试，避免玩家永久错过一次性剧情奖励。
- 装备稀有属性必须同时受槽位和品质约束。悟性仅允许出现在稀有饰品、少数高品质衣服与个别标志性武器；鞋帽手套等常规战斗装备不得为了“全属性”随意附加。

## 2026-08-13 - 招式特效与角色位移必须分层

- `animation_id` 只回答“刀光、剑气、掌劲如何出现”，不能同时隐含角色是站桩、突进、穿身还是折返；否则所有近身武功最终都会演成同一种滑步。
- 位移使用独立枚举并让四条战斗路径走同一分发函数。残影可由当前角色纹理程序化复制和淡出，不必给每个角色额外生成一套位图。
- 资料页动态预览直接由运行时 VFX 图集生成，避免网页展示图与游戏素材各维护一份后失配。主动招式缺预览应让构建失败，被动心法则明确标注无释放特效。

## 2026-08-13 - 特效“已注册”不等于每个招式拥有专属画面

- 多个招式可以拥有不同名称和合法 `animation_id`，却仍指向同一个底层图集；只检查“字段非空、文件存在、播放器能运行”无法发现视觉重复。验收必须同时锁定技能 ID、特效 ID、运行图集路径和最终画面哈希的唯一性。
- 招式特效首先要表达玩法语义：护体应形成罩体或屏障，治疗应有回生与汇聚感，身法应表现足下路径和位移，剑刀掌针则分别强调刃线、重量、冲击面和穿刺点。不能因为同属 BUFF 或内功就共享一团通用光效。
- 抠图底色必须避开主体色域。本轮治疗/月华图集使用洋红底时污染了紫粉边缘，改用纯红底后才获得干净 alpha；每批都要目检透明结果，不能只相信自动去色脚本。
- 网页预览应从游戏实际采用的 42 套图集自动生成，并对预览哈希做唯一性验证。这样“游戏里改了但网页没改”和“网页换了名字但游戏仍复用”都会在构建或测试阶段暴露。

## 2026-08-13 - 资源定义、获得入口和按 ID 加载必须同时验收

- `.tres` 文件存在且能被编辑器解析，不代表玩家能获得它；必须从商店、任务、对话、掉落和入派逻辑反向建立获得索引，空索引直接报错。
- 高品质资源不能为了清零“未接入”而全部塞进商店。品质和章节共同决定投放渠道：橙装走稀有任务或终局，门派绝学走门派限定奖励，普通补给才进入常规商店。
- QuestManager 按 `quest_id` 拼接文件路径加载，文件名与资源内部 ID 不一致会出现“目录看得到、运行时接不到”的假接入。验证器必须同时检查引用存在和 ID/文件名一致。
- 任务新增武学奖励时，目录生成器也要读取普通与门派限定字段；否则运行时已接入，静态资料仍会错误显示“未配置获得方式”。

## 2026-08-14 - 可重复战斗必须把“战斗结果”和“奖励资格”拆开

- 复用普通 `battle:` 入口做切磋，会顺带触发敌人掉落、经验、击败标记和任务事件；只在结果页改文案不能阻止刷取。切磋必须在战斗 payload 中显式标记模式，并在所有结算路径进入普通奖励前分流。
- 一次性奖励不能只记“是否赢过”。首次败北和首次胜利是两个独立资格；玩家先输后赢时应同时体验到见识奖励和首胜认可，而胜后故意输不能再补领败北奖励。
- NPC 直接 action 在进入战斗前需要正式确认。取消确认不应广播 `npc_talked_to`，否则一次“暂不”仍可能推进对话类任务。
- 书籍与残页若走 `Inventory.use_item()`，很容易被消耗品逻辑和战斗行动提交误伤。阅读应是独立的非消耗展示动作，并在数据完整性测试中锁定 KEY_ITEM 类别、长正文和场景投放来源。

## 2026-08-14 - 装备槽的查看与卸下不能共用左键

- 装备栏左键若直接卸下，玩家无法先确认属性，也容易在浏览槽位时误操作。统一约定为左键选中并展示详情、右键快速卸下；背包详情按钮承担明确可见的“装备 / 卸下”操作。
- “是否已装备”必须按当前角色与装备实例共同判断。只调用全局 `is_instance_equipped()` 会把队友身上的装备也显示成当前角色可卸下，破坏多人装备槽隔离。
- 已占用和当前选中是两个不同 UI 状态；如果共用同一种高亮，右栏会看起来所有已穿装备都同时被选中。

## 2026-08-14 - 多属性 Tooltip 不能用空格拼成单行

- Godot 默认 tooltip 会按最长一行自动扩宽。装备属性用空格连接时会变成横跨界面的黑色长条，遮住角色属性和装备栏。
- 数值型 tooltip 应使用固定最小宽度的专用面板，名称、每条属性和操作提示分行排列；系统默认 tooltip 只适合“关闭”“尚未开放”等短提示。
- 验收不能只检查 tooltip 文本存在，还要锁定面板宽度，并断言属性之间使用换行而非连续空格。

## 2026-08-14 - 透明脚底边距不能证明人物真的有脚

- 已截脚的运行条带整体缩小后再补透明边，也会通过“底部透明像素不少于 6px”的测试；这只能证明版式有余量，不能证明靴子、脚尖和鞋底轮廓完整。
- 全身精灵必须从保留完整脚部的 raw atlas 重新切片，并同时保存 source、processed、runtime 血缘。旧 runtime 不允许作为下一版 source，否则会把永久缺失的像素包装成新版本。
- 自动验收保留尺寸、帧数、alpha bbox 和脚底边距；首次采用仍需看接触表或实机图。场景里的 `full_body_reviewed` 只能作为审批结果，不能代替可追溯来源。

## 2026-08-14 - 碰撞框正确不代表角色视觉上没站在屋顶

- 2.5D 烘焙背景的屋檐、围栏和道路边界不一定与矩形 blocker 完全吻合。NPC 点位通过碰撞测试后，仍可能在画面中落到屋顶纹理或树丛里。
- NPC、出口和交互点的验收必须包含“数据可达 + 1920×1080 实机截图”两层；关键点位应额外加入贴合画面的 walkable probe，不能只靠视觉猜坐标。
- 多个人物的遮挡顺序不宜使用 64px 等粗粒度深度分桶，同一桶会退回节点插入顺序，产生主角站到 NPC 头上的错觉。改用更细的深度分桶并仅在值变化时更新，可同时改善遮挡与移动开销。
## 2026-08-14 - 互斥页面入口应使用页签状态而不是普通按钮状态

- “买入 / 卖出”这类互斥内容入口表达的是当前页面，不是一次性命令。视觉和交互都应保留选中态，并通过同组切换保证任一时刻只有一个页签选中。
- 页签至少需要未选中、选中、悬停三种反馈：选中/未选中由底框纹理表达，悬停可以只改变字体颜色，避免底框在指针经过时误读成页面已经切换。
- 正式底图若已经烘焙了页签槽，新页签必须完整覆盖旧槽并连续排列；只在槽中央叠一枚小按钮会形成双层边框，仍然像两个独立按钮。
- 自动回归应锁定控件类型、互斥状态、底框纹理切换与悬停不换底图，同时保留两页实机截图，验证视觉层级而不只验证 `current_tab` 数值。
## 2026-08-14 - 方向文件名不等于角色真实朝向

- 旧精灵资源可能采用镜头标注：文件名 `left` 的人物实际朝屏幕右，`right` 实际朝屏幕左；显式对话方向表若直接按文件名填写，会绕过运行时的自动方向纠正。
- `conversation_sprite_paths` 的键统一表示“NPC 在世界中应朝向玩家的方向”，值必须指向视觉上真正朝该方向的素材，不能仅依据文件名猜测。
- 新制作的专用对话方向图采用语义正确命名，不能为修复一套旧资源而全局交换所有左右方向；旧资源应在场景映射层显式校正，并以左右两侧运行态测试锁定。

## 2026-08-14 - 队伍表现与覆盖层验收规则

- 世界节点的 `z_index` 不能保证盖不过全屏 UI；对话、确认框等模态界面必须使用独立高层 `CanvasLayer`，并由专项测试锁定层级。
- 不要为了复用悬浮详情而让无详情的选择卡继承自定义 Tooltip Button；空文本也可能生成有最小尺寸的空白提示框。
- 可入队角色必须拥有独立身份资产根，不能复用敌人、教头或剧情 NPC 的战斗动作。招募至少包含建立关系或行动证明，不能初次见面直接入队。
- 战斗阵位坐标表达的是可见脚底落点，不是 512×560 Actor Control 的中心；生成图留白改变时必须通过可见脚点重新换算。
- 卡片还有纵向空间时应优先自动换行，禁止先手工截断再交给控件；状态标题不使用粗体来补层级，改用颜色与留白。

## 2026-08-14 - 战斗背景站位点必须表达脚底坐标

- 画有圆盘、法阵或擂台站位的背景必须拥有专用 formation profile，槽位坐标统一表达角色脚底接触点；角色画布中心、透明图中心和脚点不能混用。
- 修改战斗 Actor 的透明留白、Control 高度或脚底偏移后，所有带烘焙站位的背景必须一起复拍，不能只验证默认背景。
- 敌我缩放不能分别按双方人数计算，否则“一名敌人对三名队友”会天然产生敌大我小。双方先按本场最大阵型人数选择共同基准，再叠加 Boss、猛兽等明确的体型修正。
## 2026-08-15 · 不同交互语义的指示箭头不能复用

- 地图出口箭头强调“可前往的位置”，通常尺寸较大、带长杆和琥珀导航色；战斗当前行动标记强调“此刻可操作角色”，需要更小、更贴近人物且服从战斗 UI 配色。
- 即使把地图箭头缩小，轮廓和语义仍会显得突兀。两者必须使用独立资源，并在测试中同时锁定资源路径和最大显示尺寸。
- 小型行动标记采用透明大画布时，验收不能只看纹理尺寸；应按 `texture_size * sprite_scale` 锁显示画布，并结合 alpha 主体比例目检真实可见尺寸。

## 2026-08-15 · 单张烘焙背景不能直接实现建筑独立半透明

- 把同一张不透明背景再采样到前景层，然后降低前景 alpha，并不会让背景里已经烘焙的建筑消失；前景与底图混合时还会把建筑颜色叠到人物上，看起来反而是人物半透明。
- 真正的建筑淡出至少需要两层：移除目标建筑后的 clean plate，以及保留原坐标的建筑/屋顶前景。正常时前景还原完整场景，触发时只降低前景层透明度，底层地面和人物才有内容可显露。
- `cover_polygon` 表示需要覆盖角色的视觉轮廓，`fade_region` 表示玩家脚点进入后触发淡出的近侧区域。两者若共用一个大矩形，会把道路和空地也重复绘制，产生角色在露天仍半透明的穿帮。
- 第一次试做同时踩了“底图未移除建筑”和“宽矩形覆盖道路”两个坑，机械测试仍然全绿；因此测试必须锁定独立前景来源，并保留建筑正常态、淡出态和人物局部重叠三类实机图。
- 动态淡出只是一层可读性反馈，不能顺手改变 blocker、walkable、portal 或 NPC 深度。碰撞负责“能不能走”，前景负责“人物是否被挡住”，二者需要分别验证。

## 2026-08-15 · 素材完整不代表场景里不会“截断”

- NPC 条带有完整脚部、透明底边距合格，仍可能被高层 `cover_polygon` 遮住身体；验收必须把每个 NPC 的运行时可视矩形与高层建筑遮挡多边形做相交检查。
- 遮挡冲突优先按真实建筑轮廓收紧 `cover_polygon`，并把 NPC 移到明确的可站立地面；不能为了让测试通过而削掉本应遮挡玩家的屋檐轮廓。
- 人物与木桩等固定道具共存的动作图集必须使用全序列共享裁切框和统一缩放，逐帧独立裁切会造成角色、木桩与脚底基线跳动。

## 2026-08-15 · 队友身份图不能把主角当人物参考

- 主角图即使只想用于“画风参考”，也会把脸型、发型、服装轮廓和英雄气质传给新队友；一旦立绘成为身份锚点，后续 Field、Battle 和剧情动作会把相似性逐级放大。
- 新队友应先用非主角的多张项目图片只锁画风，再用文字明确设计独有的脸型、肤色、发型、色组和轮廓；立绘通过身份差异验收后，才能作为后续全部动作图的唯一人物锚点。
- 身份修订不能只换当前场景图，必须同步更新立绘、四向 Field、战斗五状态和所有数据引用，否则会在对话或战斗切换时再次“变脸”。

## 2026-08-16 · 世界 Y 排序与全屏 UI 必须分属不同 CanvasLayer

- 角色按脚底位置动态写入 `z_index` 后，即使全屏面板在场景树中最后创建，也可能被同一画布中的主角、NPC、出口标记或建筑前景覆盖；节点顺序和单个面板的高 `z_index` 都不是全局保证。
- 探索 HUD、战斗 HUD、系统面板和对话框应使用独立画布层：世界层保持默认画布，HUD 为 40，背包/角色/武学/任务/地图/存档等系统 UI 为 80，对话为 120。画布层级负责大类顺序，面板内部 `z_index` 只负责自身弹窗与提示的局部顺序。
- 新增或动态实例化 UI 时必须加入对应的 UI CanvasLayer，禁止直接 `field.add_child(panel)` 或 `battle.add_child(panel)`；专项回归需要把世界角色强制设到最高合法 `z_index`，确认仍无法越过 UI。

## 2026-08-16 · 任务采集物必须由任务状态驱动可见性

- “到指定地点采集”不能把物件永久摆在地图上，也不能只在任务定义里写完成旗标。交互对象需要显式 `require_quest_active`，任务接受、完成或追踪状态变化后，Field 必须重新构建受任务门控的对象。
- 采集交互应是完整闭环：任务进行中显示物件 → 玩家靠近显示采集提示 → 点击后给予物品并写入唯一旗标 → 当前物件隐藏 → QuestManager 根据该旗标推进。接受任务前和完成任务后都不应残留热点。
- 主线入口、洞窟战斗和证据点也要使用同一门控规则，避免玩家提前触发后，真正接任务时被“历史旗标”瞬间完成。

## 2026-08-16 · 烘焙背景已经包含的物件不能再叠一张运行时素材

- AI 场景背景若已经画出宝箱、矿车或火堆，运行时再次叠加同类 PNG 会出现比例、透视和光照不一致的“双重物件”。这种对象应只配置透明交互区，必要时用旗标关闭交互，不再覆盖背景像素。
- 只有需要明显状态变化（开/关、破坏、移动）且拥有配套 clean plate 时才使用独立视觉对象。否则优先让背景承担视觉、布局承担碰撞和交互。

## 2026-08-16 · 可行走地图应先画拓扑再生成场景

- 山洞、山道等多分支场景先用简图确定入口、分叉、汇合、奖励点和任务点，再把简图作为生图参考。这样能从源头保证路线与美术一致，而不是在出图后用碰撞多边形勉强拼路。
- “无死路”不是只看多边形相连；应从玩家出生点对每个道路探针、交互点和出口执行网格寻路。画面上明显的道路转折尤其要逐段布置探针，才能防止后续改碰撞时切断中间一小段。
- 背景人物动画的稳定性也不能只看帧数。备战循环需要同时锁定脚底基线、alpha 中心和可见高度，避免素材齐全但角色每帧跳位。

## 2026-08-16 · 心法不能套用攻击招式的数据与界面

- 攻击段数、攻击系数和命中预览只属于攻击招式；心法需要独立表达“习得即生效的常驻属性”和“战斗中主动运功的效果”。纯被动心法没有主动运功时，必须从战斗招式列表排除，不能用零消耗、零威力伪装成可点击技能。
- 心法常驻属性不能只写“提升生命和内功”，必须给出当前层数的明确数值，并统一使用武侠语境的“生命 / 内功”，避免在正式中文界面混用 HP / MP。提升心法时，数据层应同时驱动常驻成长与主动效果成长，界面只负责读取结果。
- 武学品质是资源数据，不是提示框自己的装饰状态。习得提示、列表文字和详情标识都必须从同一 `Skill.quality` 解析颜色；禁止在事件回调中硬编码紫色或其他稀有度。

## 2026-08-16 · 被隐藏的 HUD 内容与独立装饰必须同步可见性

- 队伍战斗隐藏旧单体 HUD 时，如果血条内容和边框装饰被挂在不同父节点，只隐藏内容会留下一个没有文字的巨大空框。所有由某个 HUD 派生出的 overlay 必须镜像目标控件的 `visible`，或统一放入同一容器管理。
- 备战动画即使脚底和中心检测通过，轮廓变化过大仍会产生“来回跳”的观感。缺少合格微动原画时，宁可暂时锁定同一稳定备战帧，也不要把跨步、转体或不同站姿伪装成呼吸循环；后续再用共享裁切框制作真正的小幅微动。

## 2026-08-16 · UI 截图测试写入运行态前要等待 Autoload 完成 `_ready`

- 截图工具若在场景树首帧之前写入 GameState，autoload 的 `_ready()` 可能随后用默认值覆盖测试数据，导致截图偶发缺技能或显示错误数值。先等待一个 process frame，再播种技能、阅历和角色状态，才能让截图稳定复现目标界面。

## 2026-08-17 · 武侠致敬应转换玩法母题，不能只给原名换同义词

- 合规改编不只是把经典武学换两个字。需要拆出抽象玩法母题（破招、游侠掌法、锻骨心法、凌空孤剑、移劲返力），再重新设计原创名称、传承人物、任务因果、地理线索和战斗机制。
- 正式游戏数据不得出现原作武学名、人物、口诀、对白和一一对应桥段；经典名称只允许留在内部设计的“母题参考”列，且必须同时写清本项目的差异化实现。
- 绝学若在终章才获得，几乎没有成长价值。伏笔应在第二、三章出现，第五、六章结算，至少给玩家留下两章高压战斗验证投入回报。
- 玩家可见名称与稳定资源ID必须分层。绝学改名时只改 `display_name`、任务文本和文档，不改 `skill_id`、资源文件名、奖励引用或熟练度键；这样可以调整武侠辨识度而不破坏旧存档。

## 2026-08-17 · 跨章任务不能沿用普通任务的“任一触发完成”

- 普通任务的 `completion_triggers` 历史上采用 OR 语义；把四个跨章里程碑直接填进去，会在完成第一步时立刻发放绝学。长链必须显式使用“全部触发满足”，并对第一条线索提供自动接取规则。
- 自动接取需要支持旧存档回看：如果首个线索 flag 已经存在，读档后应补接任务；但已完成任务不能被重复接取或再次发奖。
- 跨章任务可在第二、三章任务日志出现，但不能计入这些章节的“本章可完成支线”数量。章节深度统计和长期追踪是两套口径，混用会制造虚假的内容量。

## 2026-08-17 · 新武学必须同时交付战斗语义与独立特效

- 新增 `.tres` 和任务奖励只能证明“可以学到”，不能证明“学到后有独立体验”。穿防、群体虚弱、纯被动成长和移劲返伤都要在战斗层有真实分支与专项断言。
- 一招一特效仍是发布合同。多门新武学可以共用一张生成母图，但母图必须按行保持独立色彩与动作语义，后处理切成不同运行图集并生成不同哈希的网页预览；禁止直接复用旧招式图集。

## 2026-08-17 · 全体绝学不能逐个目标重复单体命中特效

- 逐个目标串行播放同一枚小特效，会把“全体绝学”演成多次普通攻击，也会让三目标战斗的演出时间膨胀。全体绝学应先播放一次战场级图集，再在同一时间窗结算所有存活目标。
- 橙色演出拆成“位阶提示”和“伤害语义”两层：统一蒙版与动态标题负责告诉玩家这是绝学；武学自己的全屏/单体图集负责表达流星雨、剑痕、移劲等差异。两层不能烤成一张带固定文字的图片。
- 黑底特效可以使用加色混合叠加到任何战斗背景；如果生成图带灰金天空或地面，即使画面本身漂亮也不能直接采用，因为会在战斗场景上形成一张不透明海报。必须先生成或编辑为纯黑底，并验证黑区在加色材质下不遮挡场景。

## 2026-08-17 · 全屏四帧母图的总尺寸不等于单帧精度

- 1536×1024 的 2×2 母图切开后，每帧只有 768×512；拉伸到 1920×1080 时横向放大约 2.5 倍，原图看着精致，实机仍会明显发虚。全屏绝学不能沿用普通目标特效的紧凑图集规格。
- 战场级演出改用四张独立的近16:9全幅帧，当前基准为1672×941；运行时只需约1.15倍覆盖到1080P。自动验证应检查单帧尺寸，而不是只检查“母图存在”。

## 2026-08-17 · 绝学标题背景必须表达招式类别

- 标题文字只表达武学位阶，背后的动作负责让玩家在半秒内读出“这是掌、剑、刀还是心法”。掌法使用空手开掌、转腰和掌压扩散；不能放一团与任何门类都兼容的山岳气旋。
- 出场动作可使用匿名墨影，避免与主角当前服装或武器冲突，但必须保证手势、兵器轮廓和发力方向清晰，且不能在掌法里出现佩剑攻击动作。
- 绝学名称应像古籍题签或手抄秘籍，而不是现代粗黑海报字。动态名称使用覆盖完整简体字的文楷/行楷字体、旧金色和细墨描边；粗描边会吞掉书写笔锋，即使更醒目也不采用。
- 古籍题签的出字不使用现代UI常见的弹跳放大。标题从很小的比例开始，以平滑缓出逐渐展开到正常尺寸，并在淡出前留出短暂停顿，才能保留“秘籍显字”的沉稳感。

## 2026-08-17 · GM工具必须与正式游戏规则隔离

- GM面板使用全局 autoload，才能跨Field、战斗和系统界面保留；但创建入口必须受 `OS.is_debug_build()` 约束，正式发布构建不得仅靠“隐藏按钮”保护调试能力。
- 强制学习可以绕过悟性门槛，但不能直接篡改 `player.skills` 后结束；仍需应用心法常驻属性、移除待领悟项、刷新派生属性并广播学习事件，否则GM测试结果与正常流程不一致。
- 可拖动按钮必须区分点击与拖拽。使用最小移动阈值后，短按才切换面板，拖动只更新并钳制屏幕位置，避免每次挪按钮都误打开窗口。
- 自动化截图默认屏蔽GM层，专项GM截图通过显式参数启用；否则所有UI验收图都会多出一个调试按钮并造成错误回归。

## 2026-08-17 · 道具生效与效果反馈必须使用同一调用路径

- 新旧背包界面若各自直接调用 `Inventory.use_item_for()`，很容易出现一个界面有飘字、另一个界面只扣数量。角色界面的普通使用和珍贵道具确认使用必须汇入同一个帮助函数，在调用前记录属性、调用后计算实际差值。
- 永久成长道具要同时区分“上限增加”和“当前值增加”。林西酒应明确显示生命/内功上限与当前值四项变化，不能只写“使用成功”，也不能混用HP/MP。
- 状态解除道具可能没有生命或内功差值，反馈层需要按道具语义补充“解除中毒/虚弱/全部异常”；没有专门语义时仍需显示效果已经生效，禁止成功后静默。

## 2026-08-17 · 武学图标先过语义合同，再追求一招一图

- 空 `icon_path` 回退到“内劲/悟性/防御”属性图标，会让掌法、剑法和棍法失去识别性；旧图即使存在，带人物、烤字或与类型不符也应判定为不合格。
- 第一层合同是类型可读：掌法必须有开掌，剑法必须有直剑，刀法必须有宽刃，棍法必须有长棍，针与短刃必须分开，心法/守御/治疗/身法使用独立符号。第二层才是同类型招式的个性化细分。
- 普通攻击是装备驱动的动态技能，不能永久绑定剑图标；UI必须先读取当前武器类型，在测试/临时卸装导致武器为空时回退角色武学专精，只有明确切到空手专精才显示掌图。否则默认剑客会和绝学掌法错误共用图标。
- “类型正确”仍不等于“可以复用”。普通剑击若与林西剑法共用蓝色剑弧，列表仍无法区分基础动作和命名招式。基础攻击需要单独一族低魔法图标：剑直刺、刀短切、棍直点、空手直拳；正式招式才使用大剑气、刀罡、棍风和掌劲。

## 2026-08-17 · 稳定备战帧需要锚定式微动，战斗数值条不能跟人物一起缩放

- 为消除队友备战跳位而把四帧锁成同一张，只解决了脚底漂移，却会让角色像静态纸片。资源暂时没有合格呼吸帧时，可以用极小的纵向呼吸、横向补偿与摆动恢复生命感，但枢轴必须放在脚底附近，禁止修改人物位置。
- 人物节点为适配远近站位会整体缩放；把气血、内力文字直接挂在人物节点下，0.3 倍后即使数据正确也无法阅读。formation 状态条应是独立、未缩放的 UI 节点，只跟随人物脚点计算屏幕位置。
- 没有内力池的敌人不应显示 `内 0/0`；资源条的存在同样要服从数据语义，而不是所有单位强制占位。

## 2026-08-17 · 装备图标回退与品质展示必须由槽位、品质数据统一驱动

- 将头盔、衣甲和护手合并回退为一张衣服图，会让所有缺独立图标的手甲稳定显示错误；回退图必须按六个装备槽拆开，并对全部显式图标生成接触表审计。
- 装备品质不能只给详情标题上色。背包格子需要持续可见的品质内框与同色名称；选中态是交互状态，应保留独立外框，不能覆盖品质信息。
- 掌法并不等于永远无装备。武侠常用“指虎、拳套、手甲、虎爪”等护手兵器；它们占护手槽、可选地强化掌法，但不能变成施展掌法的硬性前提。

## 2026-08-17 · 绝学演出完成信号必须覆盖蒙版生命周期

- 只延长标题而不延长角色蓄势、全屏帧与最终淡出，会造成名字看清了但攻击仍瞬间结算；三段时长必须作为一条完整时间轴调整。
- 战斗控制器必须等待全屏特效播放和蒙版淡出全部完成后，才结算“当前角色行动结束”。不能在伤害数字出现时就提前恢复按钮或切到下一单位。

## 2026-08-17 · 全身身份立绘不能直接缩进头像框

- 伙伴的 `portrait_path` 可能是用于对话或身份展示的透明全身图。直接放进 68px 队伍卡或窄幅人物肖像区，会让脸部只剩十几像素，即使文件清晰也会看起来像低质量小人。
- 头像与全身立绘是两种展示语义。没有独立头像文件时，应从同一身份源图裁出稳定的头肩区域，并让列表卡和详情区共用同一个裁切函数，避免两处人物比例不一致。
- 裁切不能写死像素尺寸；方形和竖幅源图需要依据短边计算正方形区域。验收除资源存在外，还要锁定裁切范围，并用实际界面截图确认脸部可辨。

## 2026-08-18 · 跨仓库共享美术必须先做匿名化、权利分层和双向清单

- 游戏运行目录适合用业务 ID，公共经验库不适合。直接复制会把角色、门派、剧情和绝对路径一起固化；共享包应把文件重命名为通用语义 ID，同时保留内容说明、规格和哈希，而不是保留业务名。
- 代码仓库使用 MIT 不代表历史 AI 美术自动拥有相同授权。生成服务商、参考图和 sidecar 不完整时，先使用独立 `LICENSE-ASSETS` 限定所有者项目间复用，不得为了“方便共享”虚构 CC0 或自由商用结论。
- 只检查 manifest 指向的文件会漏掉孤儿和误拷贝。发布门禁必须双向比对“清单→文件”和“目录→清单”，并同时扫描重复像素、本机路径、token、候选目录和淘汰资源。
- 本地同名目标仓库可能是 unborn 脏草稿，不能据此判断远端结构，更不能直接提交。应从远端默认分支新鲜克隆，在独立 `codex/` 分支完成验证和推送，保留原工作区不动。

## 2026-08-18 · 主线情报不能依赖玩家接受支线

- 同一个 NPC 可以同时提供主线情报和可选支线，但“听到情报”必须在进入对话时独立写入；不能只在“接受支线”选项后写主线旗标，否则玩家合理拒绝支线就会永久锁死主线出口。
- 连锁出口需要按可解释阶段逐一验证：村内调查解锁密林、林中猛兽解锁洞窟、洞窟送货记录解锁废宅。测试不能只证明每个旗标在某个文件里存在，还要证明前一阶段的必做动作不依赖任何可选选择。

## 2026-08-18 · 支线接取反馈、自动追踪与复访对话是一个完整合同

- 接取成功必须同时产生三种反馈：画面提示、任务列表刷新、无现有追踪时自动追踪。自动追踪只填空位，绝不能覆盖玩家主动选择的目标。
- NPC 第一次邀约、任务进行中、可交付和已完成应是不同语境。数据层优先配置专属 `dialog_variants`；遗漏专属文本时，运行时至少生成“询问进展—主角仍在寻找”的兜底对话，禁止重复播放初次邀约。
- 支线小游戏或秘籍残页可以在一段对话内完成，但普通采集、战斗、寻人支线不得在同一节点既接取又完成。

## 2026-08-18 · 烘焙场景建筑遮挡要隔离建筑像素

- 即使已经有干净底图和旧图前景，直接采样一个大多边形仍会把屋边草地、阴影和道路一起叠加，淡出时形成矩形色块。
- 对同尺寸的原始完整图与 clean plate，可在前景材质中按颜色差分生成建筑遮罩，再配合贴近屋顶/墙体轮廓的 cover polygon。原始完整图仍是运行底图，clean plate 只作遮罩参考；建筑保持不透明，角色进入遮挡区时基础层仍在建筑下方，额外绘制一层半透明角色剪影到前景上方。

## 2026-08-18 · GM 面板不能缓存资源列表到整个运行期

- 调试功能的价值在于快速验证新数据；若只在 autoload `_ready()` 扫描一次，运行中新增或热重载的 `.tres` 会完全不可见，反而让测试者误以为资源没有接入。
- GM 每次打开应重建数据源，并提供显式“刷新数据”按钮。读取资源时使用替换缓存模式，装备选项同时写明品质、槽位和武学类型，避免“掌法护手存在但搜索不到”的假故障。

## 2026-08-18 · 任务、切磋与入队都需要先给玩家语义反馈

- `accept_quest` 在节点展示时立即执行会让“NPC刚开口就自动领任务”，既没有选择也没有叙事节奏。支线应先展示原对白和任务缘由，再由玩家选择接受或暂缓；主线剧情可保持自动推进。
- 功能型切磋 NPC 不能绕过对话系统直弹确认框。至少应有一轮试探台词和“请赐教 / 暂不”的选择，再进入数值、奖励、恢复规则的正式确认。
- 队友加入是关系与战斗配置的双重改变，必须在 Field 显示明确提示，并通过事件总线让所有剧情来源获得同一反馈。

## 2026-08-18 · 换武器精灵必须共享身份、方向、尺度三份合同

- Field 变体不能只换一张正面图，也不能用水平镜像补齐左右。剑、刀、棍、掌必须来自同一身份锁，并各自拥有下/上/左/右四向 idle 与 walk 条带；空手版还要明确禁止残留剑鞘。
- 运行时切换纹理时禁止 `sprite.scale *= variant_scale`。这会把一次合理的比例修正变成累乘，玩家每换一次装备就更小；应保存标准 scale 与场景 multiplier，每次从二者重新计算并赋值。
- Battle 图集的全局缩放只能由 ready 站立行决定。把 attack/hit 的蹲伏或伸展高度混入中位数，会把人物整体错误放大；所有武器变体应锁同一 300px 备战有效高度和 12px 脚底边距。
- 绝学标题蒙版属于前奏，不属于角色攻击。标题动画完成后应先等待蒙版完全透明，再播放角色动作；演出根节点可以继续保留，供动作后的全屏命中特效复用。

## 2026-08-18 · Sprite alpha 边距通过不代表没有跨格，8帧也不代表8个动作

- 把已经被固定格线截断的图片缩小并补透明边，运行时会满足 bottom margin，却不会恢复丢失的头顶和靴子；源母图必须先逐格检查四边安全带，任一可见像素触碰切线就拒绝处理。
- `walk = [frame for frame in frames for _ in range(2)]` 虽然输出文件名是8f，实际只有4个动作且每个动作hold两帧，移动时会呈现“脚不动—突然跳”。8列母图必须直接保留8个独立帧；旧4列源最多重复完整4帧循环，不能连续复制单帧。
- 长武器不能参与人物缩放基准。按每帧 alpha bbox max-fit 会让棍版人物比剑版小；同格生成的武器变体应保持整格统一缩放，以角色在源格中的共同尺度为准。
- 动画验收至少包含三层：源格安全带、运行帧唯一哈希与下半身相邻帧变化量、固定锚点GIF目检。只检查尺寸、alpha和脚底余量会漏掉本次两类错误。

## 2026-08-19 · 巡逻原点必须在入树前赋值，烘焙建筑需要独立角色淡化区

- Godot `add_child()` 会立即触发NPC `_ready()`。若节点在 `_ready()` 中记录巡逻原点，控制器必须先设置 `position` 再加入场景树；反过来会把原点记为 `(0,0)`，所有巡逻NPC下一帧一起消失到左上角。数据测试只能证明NPC定义存在，必须有运行态位置断言。
- 剧情阶段不应通过两个互斥NPC条目替换同一人物并在末期全部隐藏。稳定人物使用一个常驻ID和 `dialog_variants` 切换对白；若场景设计需要两名镖师，应给伙伴独立ID和无副作用对白。
- 建筑已经烘焙进底图时，无法获得真实的前后像素分层，也不应再叠一栋建筑。可用独立归一化多边形按玩家脚点降低角色alpha，模拟人物处于屋檐/屋顶遮挡下；该区域不拥有贴图、碰撞或建筑透明逻辑。
- 烘焙建筑淡化与独立前景遮挡是两种合同：前者淡化基础玩家且不显示ghost，后者保持建筑不透明并在前景上方显示半透明角色剪影，不能混用。

## 2026-08-19 · 命中失败必须在防御与状态之前短路

- 伤害函数返回0后，若守御或反弹逻辑继续用 `max(1, damage)` 处理，未命中会被重新变成1点伤害，还可能消耗护体或触发中毒。
- 攻击结果应先判断 `hit`；未命中时不播受击、不消耗护体/反弹、不施加状态或武器特效，只记录“未命中”。

## 2026-08-19 · 状态机制、行动提交与分类语义必须分层

- “内伤值”是累积量，“内伤封招”才是带持续回合的状态。若只用一个整数同时表示两者，达到100后很难正确表达清零、两回合禁招和UI剩余回合；应分别保存 gauge 与 timed status。
- 战斗背包若只在使用成功时结束行动，玩家可以打开、关闭或连续换装规避回合成本。打开背包后，使用、换装和关闭必须汇入同一个 action-commit 出口，并用单次提交保护防止重复推进。
- 武学分类不是武器资源类型的直接映射。普通攻击属于系统通用项；无伤害增益和治疗属于心法；只有造成对应武器伤害的招式才进入剑、刀、棍、掌、暗器分类。
- 状态图标不能只作为装饰纹理。图标、名称、说明和剩余回合应来自统一状态定义，并允许点击查看，否则玩家无法判断图标含义和何时结束。

## 2026-08-20 · 武器特效需要同时锁定运行数据、品质预算和呈现颜色

- 只在装备描述里写“中毒/流血”不代表战斗会生效；特殊效果必须进入结构化字段，并由命中确认后的统一触发入口处理。
- 特效稀有度不能只靠有没有词条。蓝、紫、橙应分别限制触发率、效果数值和持续回合，否则低品质装备会意外压过高品质装备。
- 特效文字颜色属于装备品质语义，不属于效果类型语义。背包、角色Tooltip、战斗日志和网页若各自写死颜色，会出现同一把橙武在不同界面显示成紫字；所有入口必须读取同一品质色映射。

## 2026-08-20 · 心法的永久、主动与装备效果必须分层

- 习得/提升产生的永久属性、战斗中的主动运功、装备后提供的流派加成是三种不同生命周期。装备或卸下心法绝不能修改角色核心属性，也不能在读档时按熟练度重放成长，否则会和已经保存的属性重复累计。
- “最多装备一门”限制的是装备加成，不等于限制已学主动心法的使用。带主动效果的已学心法仍应进入战斗招式列表；装备心法只在伤害、暴击、内伤和指定招式协同计算时作为门禁。
- 旧招式的 `complemented_by` 若继续按“学会即生效”，会和新心法装备词条重复叠加。兼容旧数据时应保留字段，但把触发条件迁移为“当前确实装备对应心法”，并让队伍战、旧1v1和武学预览共用同一语义。

## 2026-08-20 · 侧向走路必须存在收腿过渡帧

- 8帧互不重复、脚底不漂和像素变化量通过，仍不能证明步态自然；如果每帧两脚都张开，角色会像横向滑动。左右循环必须至少包含一帧明显的收腿/交叉过渡，并验证前后脚真正交替。
- 已验收的方向不应跟着失败方向一起重生。生成模型容易在一次全图返工中引入身份、配色或比例漂移；更稳妥的做法是保留合格的上下行，只重做左右行，再按原格位合成为可追溯的新母图。
- 步态验收应同时看固定脚底锚点GIF和四向接触表；静态母图只能发现裁切、武器和身份问题，无法判断完整循环中是否存在停顿、滑步或双脚长期张开。

## 2026-08-20 · 内容总量与装备槽语义变化后必须同步验收基线

- 内容完整性测试若锁定技能、装备总数和品质分布，新增正式资源后必须在同一提交中更新基线；否则真实资源与投放链都已通过，历史数量仍会制造无效红灯。
- 拳套、指虎等掌法兵器属于 `WEAPON/palm`，护手、护腕才属于 `HANDS` 防具。测试不能仅凭中文名把“拳套”继续断言为护腕槽，否则会把已经修正的装备分类判成回归。
- 数量基线仍有价值，但应和网页目录、资源完整性报告使用同一版本快照，并在错误信息里明确期望值，方便区分“新增内容未登记”与“资源误删”。

## 2026-08-20 · 剧情网页不能靠章节前缀或旧任务文件自动推断现行主线

- 为存档兼容保留的旧对白仍可能使用当前章节前缀；全量扫描 `ch1_*` 会把悦无姮旧版第一章救援错误纳入现行故事，而她的正式登场已经迁到第二章。
- 后期 QuestDef 文件存在不等于剧情已实装，也不等于其内容仍是当前正典。故事目录必须把“运行时可达”“新版规划”“旧数据待迁移”分层显示。
- 最稳妥的资料页不是纯手写，也不是纯自动猜测：用结构化故事清单确定章节语义与顺序，再由生成器反查真实 QuestDef、SceneScript 和 DialogNode，并对核心选项文本与数量做漂移校验。
- 分支卡必须写清选项、持久后果和汇流点。只写“可选择救人或追凶”会漏掉证词/证物、伙伴信任、羁绊事件和城市结果，无法用于后续剧情验收。

## 2026-08-20 · TRES 关键字段前不要夹装饰性尺寸注释

- `WalkableMapLayout.design_size` 前紧贴一行含乘号与尺寸说明的注释时，Godot 曾静默保留脚本默认值 `(1920, 1080)`；资源文本看似已写成 `(2304, 1536)`，运行值却未改变。
- 对关键导出字段不要在同一字段块中夹入装饰性注释；修改后必须加载资源并直接断言运行值，不能只靠文本搜索确认。
- 世界地图和滚动地图应把 `design_size`、背景纹理尺寸与 portal 归一化坐标一起纳入专项测试。

## 2026-08-20 · 城镇安全区与剧情战必须分离

- 删除城镇 encounter 数据不能永久防止随机战；应由场景语义字段 `is_settlement` 在随机遭遇入口统一短路。
- 安全区只禁止移动触发的随机战，不应阻断对白选择、任务节点和切磋使用的显式战斗入口，否则会误伤正常剧情。

## 2026-08-21 · UI 门槛必须和数据门槛一致，禁用按钮也要有正式状态

- 只把“装备心法”按钮置灰并不能阻止存档、GM 或脚本入口直接调用装备函数。所有属性门槛必须在领域/状态层再次校验，界面只显示同一判定结果。
- 悟性等条件可能因换装下降；读档和装备变化后要重新校正已装备内容，但固定剧情队友的锁定心法不能被主角装备规则误清理。
- `Button.disabled=true` 后若没有 `disabled` StyleBox，Godot 主题可能只绘制灰文字，看起来像按钮底图丢失。正式三态按钮必须同时准备或回退一个禁用态纹理。
- RichTextLabel 的尺寸超过美术底图分区时，即使视觉上仍在主面板内，也会压到下一功能区。布局验收要锁定分区边界，并同时开启 `clip_contents` 与滚动阅读。

## 2026-08-21 · 野外展示与战斗动作是两套武器语义

- 装备类型决定身份辨识，但不代表野外必须一直把武器拿在手中。Field 应表达旅行状态：剑刀入鞘、棍背负、掌法戴手套、暗器挂器囊；Battle 才切换到对应持械或出手动作。
- 武器归一化不能只覆盖剑刀棍掌。暗器资源常使用 `hidden/throwing/ring/dagger` 等历史类型，所有入口必须汇入同一个 `hidden` 视觉键，否则装备变化会静默回退剑版。
- Godot 4.6 的 `Button.icon_max_width` 是主题常量而不是可写属性。运行时创建按钮时必须使用 `add_theme_constant_override("icon_max_width", value)`；严格解析不会发现动态赋值错误，测试必须真实实例化并创建状态图标。

## 2026-08-21 · 兼容资源存在不等于现行内容可达

- 为旧存档保留的 QuestDef、DialogScript 和角色资源仍会被全目录扫描器发现。如果目录生成器只看“某个对话写了 accept_quest”，孤立对白就会把退役任务误报为已接入。
- 内容图鉴必须区分“已接入、待接入、兼容旧线”三种状态。兼容任务保留定义但不计入当前可玩数量；对应旧对白也不能作为接取源参与运行图反查。
- 正典隔离要同时检查网页和场景资源。即使故事目录不展示旧线，只要 SceneScript 仍按剧情旗标生成旧 NPC，玩家仍可能在回访时进入退役剧情。
- 每章应有机器可读 `ChapterContentPlan`，只登记当前主场景、主线、真实可玩支线、练级地图和实际战斗节点；历史设计文档不能继续代替运行内容总表。

## 2026-08-21 · 队伍战任务需要独立胜利后续，而不是复用击杀触发

- 护送、守卫等任务若用普通 `enemy_defeated` 结算，同种敌人的随机战可能提前完成任务；若把两名敌人拆成连续单挑，又会损失队伍战目标选择和群攻价值。
- `battle_group_then:<enemy_csv>:<dialog_id>` 把特定编队与胜利对白绑定。胜利对白再写唯一任务旗标，由 QuestManager结算并保证奖励幂等。
- 调查证据只记录可观察事实。“第六行被刮去”可以证明同行人数被改动，但不能顺手写出第六人的身份、阵营和动机；解释必须留给后续证词交叉验证。

## 2026-08-21 · 环境叙事点必须依附画面细节，也必须用完整玩家半径验路

- 环境调查优先绑定底图上真实可见的炭盆、矿车、晾架、绳索和货箱；没有对应画面物件时不要只在空地放一个感叹号，更不要为小奖励重复叠加新资源。
- 交互中心不在 blocker 原矩形内仍不代表玩家能到达。导航验收必须使用与角色相近的碰撞半径扩张阻挡区，再做网格可达性；洞窟矿车点就是被这一层测试拦回的。
- `require_quest_active` 不只属于采集物和触发区。NPC生成入口也必须调用同一个 `_quest_gate_passes()`，否则任务人物会在未接任务时提前出现，破坏叙事顺序。
- 小额探索奖励只补偿绕路和观察，不应替代任务、宝箱或Boss奖励；一次性对白旗标必须和交互 `hide_flag` 使用同一键。

## 2026-08-21 · 获得链要识别武学蜕变，生图候选必须验证真实alpha

- 武学获取并不只有任务、商店和对白直接授予。终境突破可能通过基础武学的 `evolves_to_skill_id` 替换成新武学；获得链审计若不索引蜕变关系，会把已有合法入口误报为缺失，并诱导开发者错误地提前发放后期武学。
- 获取链测试必须同时验证蜕变目标在正式突破函数中确实被处理，不能只看到资源字段就算接入。当前林西终境由 `_apply_linxi_master_breakthrough()` 与 `LINXI_EVOLVED_ARTS` 双重锁定。
- 图像看起来像透明棋盘，不等于文件有alpha。任何准备进入 `game/art` 的人物候选必须读取像素格式并确认真实透明范围；RGB里烤入灰白棋盘的图片必须拒绝，不能靠再次缩放或标记“已抠图”洗白。
- 生图身份通过但技术规格失败时，原图只留在 `assets/raw` 并写拒绝manifest。运行时应继续复用已审核资源，直到候选同时通过身份、alpha、边缘和尺度门禁。

## 2026-08-21 · 章节战斗节奏需要机器数据与实测数值共同约束

- 单场敌人“能打过”不足以证明章节节奏成立。每个关键战斗需要明确教学/检查/精英/守门/可选队伍/Boss角色，以及建议等级、目标回合、战后休整和奖励作用。
- 数值调整必须记录原因、预期和实测。第一章后山凶兽攻击16→26、洞穴头狼22→30，是为了把预计承伤从约1/2提升到6/10；赵无忌仍为26，保持普通、精英、Boss压力梯度。
- 赵无忌不使用硬等级门槛。前置消耗、补给点、可选战和NPC提醒承担软门槛，玩家可以自行决定练级，而不是被等级文字拦截。

## 2026-08-21 · 未接入任务不等于都应该接入

- 任务资源存在但没有入口时，先比较它与现有地图、战斗和奖励的功能。如果需要一张不存在的场景、一套不存在的敌人动作，或只是重复已有切磋，就应明确合并或迁章，而不是为了减少“待接入”数字硬塞进当前章节。
- 第一章已有凶兽、头狼、唐行舟切磋和武馆挑战，因此“独猎猛虎”“村口试剑”直接接入会重复；“祠堂失窃”又缺少祠堂与废窑，并和第六章旧居遗物共用赤琼佩。机器计划必须记录这些决策，避免下次审计再次提出同一草案。
- 任务物件的生命周期是“接取后显示、采集后消失、回交后结算”。采集旗标不能直接承担完成条件，否则委托人复访和交付对白会被跳过。
- 第一章奖励必须按当前成长阶段重新审计。草案中的紫府丹和续命丹即使有数据，也不代表适合早期支线；奖励应服务当前补给，而不是提前投放稀有救命资源。
- 网页状态至少区分“已接入、待接入、规划已处理、兼容旧线”。合并/迁章不是兼容旧档，也不是待制作；把四类混在一起会持续制造错误内容债务。

## 2026-08-21 · 长兵器精灵需要长度、携行和握法三份语义合同

- Field里“背着棍”不能只在肩后露出一截短柄。长棍必须在正面、背面和侧面都能读到上下两端，长度相对人物保持一致；同时双手应自然摆动，避免旅行状态看起来一直临战。
- Battle里资源文件名叫staff并不代表动作是棍法。备战、移动、蓄势、横扫、突刺和回收必须让两只手都明确接触同一根棍，握点之间保留可读距离；单手拎棍或空手出拳会把角色重新读成刀剑动作换皮。
- 手部语义在母图大图上勉强可见，缩到512×384后可能合并成一只手。审核必须同时看原始4×5母图、运行帧接触表和GIF，发现双手重叠要在生图阶段返工，不能靠代码解释。
- 人物身份还包括肤色与面部明暗。不同武器变体若把同一主角生成成灰白病容，即使服装一致也属于身份漂移；应以已通过的剑版正面脸作为肤色锚点。
- 洋红背景不是总能由旧处理器直接清干净。若生成背景偏离纯 `#FF00FF`，先用border自动取色与软边去色生成RGBA，再进入统一尺度切片，避免背景残块被误判为最大连通组件。

## 2026-08-21 · idle、walk与章节入口必须分层

- NPC巡逻不能把idle条带填进 `walk_sprite_path`。节点位置会移动，但帧里双脚不动，结果就是滑行；巡逻角色必须使用真实交替脚步的walk条带，驻守角色则不应为了“热闹”反向来回走。
- 同屏功能相近的NPC也需要身份区分。两名完全相同的镖师即使ID和对白不同，玩家仍会读成复制人；可以让一人巡逻、一人持枪驻守，用外形、职责和运动共同区分。
- idle和walk不能共用切帧速度。守卫转头、衣摆轻动适合接近1秒的慢节奏，行走脚步需要约0.1秒；统一0.28秒会同时造成守卫摇头过快和走路过慢。
- 主角idle若从walk周期直接抽帧，静止仍会原地踏步。运行资源应锁住脚部区域；未来增加衣摆/发梢帧时，只允许上半身与布料变化，脚部像素合同保持不动。
- 开放世界的“能到达”和“主线已开始”是两种状态。城市portal可以无章节锁，自动主线对白必须有独立 `on_enter_require_flag`；支线NPC和商店可提前访问，主线调查物继续由章节旗标控制。
- 锁定危险区域时不要只隐藏出口。保留方向标记并显示世界内提示，比“未解锁”系统术语更自然，也让玩家知道以后可以回来。

## 2026-08-22 · `.tres` 导出字段前不要写 `#` 注释

- Godot 4.6 文本资源在导出字段前出现 `#` 注释时，可能不报解析错误，却把紧随其后的复杂字段保留为脚本默认值。本次世界地图文件文本里有34个道路多边形，但运行加载得到 `walkable_regions.size() == 0`，根因就是字段前的三行 `#` 说明。
- `.tres/.tscn` 的设计解释写入相邻Markdown或GDScript注释，不在资源属性块里插入装饰性注释。关键数组修改后必须真实 `load()` 并断言元素数量、探针和门户可达性，不能只用文本搜索计数。
- 世界地图通行验收至少包含：全部门户中心在任一道路多边形内、walkable探针可走、blocked探针不可走、林西/竹尾距离与茗雾山分区关系。

## 2026-08-22 · 普通放大不是高清，WAV循环也不能只开模式

- 1536×1024图片用Lanczos放到3072×2048只增加像素数量，不增加真实细节；再加锐化会把地表噪点一起放大。大地图最终流程改为“清晰低噪母图 → 官方Real-ESRGAN插画模型 → 3072×2048运行图 → 1080P实机目检”。
- `AudioStreamWAV.loop_mode=LOOP_FORWARD`并不够。导入资源的`loop_end`可能是0，结果是0帧循环、播放立即停止；必须同时写`loop_begin=0`与`loop_end=length*mix_rate`。
- Headless测试使用Dummy音频驱动，`AudioStreamPlayer.playing`会保持false。资源路径测试可用headless，实际播放状态必须用WASAPI离屏窗口验证。

## 2026-08-22 · 场景入口、线索与语音都需要可见合同

- 场景图是有向图。设计入口时必须同时写反向边；“从密林进洞、从洞回村”即使剧情上说得通，操作上仍是错误拓扑。多个来源进入同一场景时，各来源分别保留出口。
- 隐形交互区加近距离感叹号不能承担探索引导。信件、账册、包裹、箱子等任务物必须在任务接取或前置旗标满足后显示，完成后消失，靠近只做描边增强。
- 线索不是只有一条对话文本。获得时显示Tips、QuestManager广播推进、任务卷宗写入已发现记录，三层必须由同一触发器驱动。
- TTS默认男声会把所有漏配角色悄悄变成男性。发布前必须审计speaker→voice映射；可入队角色还要逐节点检查实际音频文件。

## 2026-08-22 · 固定镜头洞窟适合用场景图拼接，而不是一张图硬塞全部内容

- 一张底图即使画了岔路，如果入口、宝箱、精英战和主线证据都在同屏，玩家仍会把它读成单房间；“看起来像迷宫”不能替代真实的探索层级。
- 固定镜头项目扩地牢时，优先用入口Hub、两条短支路和一个汇合目标区组成小图网络。每张图只承担一个明确节奏角色，既减少大图拼接和镜头滚动问题，也方便单独调整碰撞与任务门控。
- 不做死路不等于没有选择。矿道可以用岩柱环路，水道可以用水潭分隔两侧岩台；玩家产生路线选择，但两路最终汇合且回头成本低。
- 场景图生成前先画归一化行走拓扑，并把入口、出口、交互点和不可行走地标写进设计图；生图只负责将拓扑翻译成美术，不能反过来让碰撞迁就随机画出的道路。
- 已烘焙在背景中的宝箱、矿车等实物可直接承担远距离发现，不要再叠加同形状的交互图标造成复制物；只有任务阶段才出现的包裹、信件和货筒才使用独立可见物。

## 2026-08-22 · 切磋身份、物件兜底和悬停说明必须走完整运行入口

- 同一人物的队友定义与切磋敌人定义是两套资源入口。只验证 `CharacterStats.battle_sprite_root` 会漏掉 `EnemyDef.ready_frame_paths`，从而让旧版大幅度帧在NPC切磋时复活。角色表现审计必须按“队友、切磋、剧情敌人”三个身份查全。
- 交互点不能依赖作者记得逐条写 `interaction_visual_kind`。可以根据ID、标签和action推断信件、账册、箱子、包裹与地面痕迹，但必须提供 `visual_baked` 逃生口，否则推断系统会在已有宝箱的底图上再生成一个宝箱。
- 图像生成声称透明不代表文件真的有alpha。敌人脚部修复候选出现了烘焙棋盘，最终通过亮度/色差分离、最大连通体与安全带归一化生成真实RGBA；运行帧仍需检查鞋底下方像素余量。
- TTS映射更新不会自动改变旧音频。说话人更名后，必须重生成情感版和`segXX_dialog`分段文件，因为DialogPlayer优先播放分段文件；只生成普通fallback仍可能继续听到旧声线。
- 自定义Tooltip不要只验证“visible=true”。Container子节点没有明确最小宽高时，自动换行可能把82px提示框撑成整屏高条；需要同时锁定面板和RichTextLabel的宽高，再做实机悬停截图。

## 2026-08-22 · 有五声音阶不等于有武侠配乐

- 单声道正弦旋律即使使用五声音阶，仍会被听成测试音；宽频噪声鼓点越多，越像通用程序化氛围而不是武侠器乐。武侠感需要同时建立拨弦瞬态、气鸣长音、弓弦持续音与中国打击乐层次。
- 旧占位曲的优点是旋律清楚、噪声少，新版应继承这一点，而不是只提高音色复杂度。探索曲让旋律和留白主导，环境噪声保持在非常低的底层。
- 战斗“紧凑”首先是结构问题：第一拍就应出现固定节奏型，普通战控制在122～128 BPM，切磋略轻，Boss再提高到138 BPM并加密堂鼓；不能用普通探索曲加大音量代替战斗编曲。
- 场景图不能单独决定Boss音乐。战斗BGM选择还要读取`EnemyDef.is_chapter_boss`；同时切磋优先级必须更高，避免被高等级切磋对手错误切到Boss主题。
- WAV循环不只看`loop_end`。生成阶段同时检查首尾PCM差值；长交叉淡化解决乐句衔接，最后十几毫秒落零消除残余相位点击。

## 2026-08-22 · 复杂底图不能继续用少量大多边形猜通行范围

- 宽路多边形适合村落广场，不适合洞穴水道、踏脚石和弯曲山路。视觉道路只要有一次转折或高差，少量控制点就会同时产生“路上走不了”和“穿墙可走”两类相反错误。
- 复杂场景使用与底图同尺寸的白/黑通行蒙版，运行时按角色脚底逐像素采样；小型箱柜和石柱保留独立 blocker。这样美术道路、碰撞和验收探针共享同一坐标，不再反复猜矩形。
- 出口不是单向剧情动作，而是场景图的成对边。晨市从废宅进入就必须回废宅；主街若没有对应入口，不应为了方便额外添加返回主街的出口。
- 战斗入口也属于交互合同。不可见区域或皮纸直接开战会让玩家误读因果；应由可见敌人/巢穴先触发对白，胜利后再显示货筒、信件或残迹。
- 透明生图若烤入棋盘格不得入库；只需清除孤立碎片时，使用最大alpha连通体后处理比再次生成更可控，并保留原图与清理脚本的血缘。

## 2026-08-23 · 音乐和战斗反馈必须以“听到的命中点”设计

- 多个文件名不等于多首音乐。若所有曲目都从两首完整伴奏切片，玩家仍会只记住两套和声与音色；场景主题必须分别拥有独立旋律动机、根音、答句和节奏语法。
- BGM切换不能先等待旧播放器淡出。双播放器让新曲立即启动、旧曲同时淡出，能把场景→战斗的听觉响应从一秒以上压到一个渲染帧附近。
- SFX文件没有前置静音，也可能听起来滞后。根因常是调用顺序：若代码`await`完整特效后才调用`play_hit()`，受击声必然晚于画面。起手、命中、受击三个声音必须分别绑定蓄势帧、特效峰值帧和角色反应帧。
- 橙色全屏绝学不能等四帧图集和淡出都结束后再发声；命中声应在图集闪光峰值帧触发，后续受击动画必须禁止重复补音。
- 飘字只延长淡出时间仍会一直变淡、读不清。正确节奏是先完全保持，再上浮淡出；当前基线为1.35秒保持+0.78秒离场。

## 2026-08-23 · 有像素蒙版也不能保留盖住门槛的粗矩形阻挡

- 通行蒙版决定大尺度动线，blocker只应描述箱柜、岩柱和建筑实体内部。晨市虽然门户坐标写在路面上，整栋房屋矩形仍覆盖门前门槛，结果会出现“箭头看得见但走不到”。迁移复杂场景时必须同时缩回旧blocker。
- 新增白区后也要同步更新人类可读的`walkable_regions`和可达探针。运行时优先采样蒙版，但只更新图片会让拓扑审计、编辑器可视化和后续维护继续误判；蒙版、回退多边形、入口中心和探针必须同批提交。

## 2026-08-24 · 高阶装备的风险首先是跨区数量，不只是面板总和

- 同一件橙装拥有高攻击并不天然失衡；真正危险的是同时供给攻击造数、招式系数、暴击率、命中、暴击伤害和控制效果，使其他槽位与构筑选择失去意义。
- 招式基础、兵器、门派、心法、协同和熟练度都描述“攻击系数百分点”，必须在同一区内相加。任何单独再乘一次的实现都会让资源描述相同但实际收益不同。
- 自动预算只能标记“值得复核”，不能直接决定削弱。橙色终章心法、绝学允许更高机制密度，但必须先受总系数、暴击率、暴击倍率、内伤和控制时长上限约束。
- 公式工作簿的假设、权重和风险阈值必须放在可编辑单元格中；结论通过公式引用原始表，避免脚本算完后留下无法追溯的静态红绿标签。

## 2026-08-24 · 伤害拆解必须与最终结算共用同一条代码路径

- 只在调试界面复算一遍伤害会产生“显示公式”和“真实公式”漂移。`DamageBreakdown`必须由真正返回最终伤害的函数生成，GM只负责展示同一个对象。
- 公式外的`raw × 1.2`即使数值正确，也会让日志、预览和回归测试遗漏最终修正。影杀等攻击方增伤应进入统一的命名攻击方修正区，并记录来源名称。
- 日志不能继续使用`1.5 + 加成`重新拼暴击倍率；必须读取拆解中的实际倍率，否则达到2.2上限后日志仍会显示未封顶数值。
- 未命中同样需要拆解对象。它应保留命中率和潜在造数，但最终伤害为0，方便区分“打不动”和“没有命中”。

## 2026-08-24 · 状态倍率必须先分区，再决定叠加方式

- “增伤20%”与“增伤30%”若来自不同来源，应在攻击方同区加算为+50%，而不是连续乘成1.56倍；同一来源刷新时替换旧值，不能因重复施加偷偷叠层。
- 目标易伤属于独立承伤区，不能与攻击方增伤混成一个总百分比；当前上限分别为攻击方2.00倍、目标易伤2.00倍，攻击方减益保留25%伤害下限。
- 残血衰减是角色伤势区，毒/流血是独立持续伤害，防御架势、回澜和反伤是受击处理；这些机制如果全部塞入“状态乘区”，会同时破坏说明文本、平衡上限和GM追踪。
- 触发时机与持续回合是两件事。在行动末尾施加的武器增伤如果仍由同一个行动末尾统一扣回合，会立刻归零；施加行动必须不消耗持续期，测试要锁住这一点。

## 2026-08-24 · 章节平衡不能继续用裸装标准人冒充真实玩家

- 旧验证器只按等级基础攻击、防御与单一招式计算，即使结果落入目标回合，也可能完全漏掉剧情必得武器的攻击、招式系数和暴击率。必须并排展示裸装与同期装备结果。
- 标准角色基础成长和装备档位要拆成两张表。否则装备过强会被误判成等级曲线过快，等级成长问题也会被装备数字掩盖。
- 减法防御下，玩家防御一旦接近敌人造数，敌方伤害会迅速落到1点附近。章节压力不足时优先检查敌方攻击与招式固定伤害，不要先给敌人堆防御或把所有普通怪生命翻倍。
- TKK、TTD只是诊断。毒、流血、治疗、道具和操作策略必须留给实战；电子表格需要明确写出未计入项，避免把模型输出包装成最终平衡结论。

## 2026-08-24 · 可获得不等于主线保底，门派分支也不能全部累加

- 资源有获取路径只能证明它不是孤儿，不能证明只走主线的玩家一定拥有它。章节模型至少区分主线必得、必选分支、支线、商店和跨章秘闻。
- 五派师承虽然会列出五套奖励，但玩家只能选择一派。审计总量可以统计全部候选，标准角色只能取一套，否则第三章战力会被虚增数倍。
- 兼容旧线和规划已处理任务仍保留`.tres`，扫描投放时必须读取任务卷宗状态并排除，不能仅按文件名前缀统计。
- 后期章节拥有橙色装备/绝学资源，不代表章节成长已完成；没有正式战斗锚点、主线接取和结算入口时，必须标成规划缺口。

## 2026-08-24 · 奖励迁移要同时检查旧来源和武器语义

- 把支线武功提升为主线保底时，旧支线必须移除同一奖励；否则重复学习虽可能幂等，玩家仍会失去支线结算价值并产生错误提示。
- 装备和武功必须使用同一武器语义。拳套支线奖励棍法即使数值合理，也会让玩家拿到无法立刻使用的组合；应拆回掌法身份或把棍法迁到棍类装备节点。
- 主线新增武器最好拥有独立图标与明确剧情来源，不能用商店普通铁棍改名冒充剧情奖励。
- 品质上限测试不仅检查面板预算，还要检查特殊效果概率、数值与持续回合；蓝色词条继续遵守20%/12点/2回合上限。

## 2026-08-24 · 主线保底武器要用招式本身承担命中特点

- 早期蓝色武器若同时叠攻击、招式系数、暴击、命中和状态，会在单件装备上塞进过多跨区机制；即使每个数字都小，整体仍会挤压后续品质的成长空间。
- 暗器“高命中”可以由对应招式的基础命中率表达，武器保留攻击、兵器系数和一个低概率状态即可；这样装备身份清楚，技能与武器也有分工。
- 主线奖励不能只写进QuestDef。战后对白需要解释装备从哪里来、为何能安全使用、是谁教授招式，玩家才会把数值成长与剧情事件关联起来。
- 新武学进入主线时，必须同时更新语义图标审计名单、标准256×256图标、独立VFX登记和投放快照，避免“能学会但仍使用旧占位资产”。

## 2026-08-24 · 多人战不能拿单体TKK直接当整场回合

- 两人或三人剧情战中，每个单位都达到整场目标回合会让战斗成倍拖长。单体锚点应先保持普通/精英职责，再由单位数量、毒伤、速度和目标选择形成整体压力。
- ChapterContentPlan中的编队才是正式战斗锚点；仅有EnemyDef或旧任务里的不存在敌人ID，都不能证明章节已有可用战斗。
- 建立战斗数据不等于章节实现。场景、任务入口、胜利后对白和奖励尚未接入时，故事目录必须继续显示规划状态。
- 压力矩阵列数应由战斗锚点数量动态计算。固定写死A:T在锚点扩展后会产生数据溢出、条件格式缺列和渲染裁切。

## 2026-08-24 · 开放游历门禁与主线开场门禁必须分开

- 世界地图入口若直接要求上一章完成，会把“可以提前游历”重新做成线性关卡；地点门户应使用较早的旅行门槛，主线自动对白再用`on_enter_require_flag`控制。
- 局部纵向切片完成时不能把整章改为已实装。故事目录需要允许记录已完成场景，同时继续对缺失的后半章、武功和心法显示规划状态。
- 背景中已经清楚画出的破旗、账册、车辙可以作为可见交互物，不必再叠一张重复贴图；但任务不能在战斗结束时自动跳过调查，必须由玩家走近查验后取得证据。
- 场景行走区域验收至少包含出生点、战斗区、证据点、双向出口和关键阻挡物探针；只检查多边形非空无法防止角色出生在黑区或穿过粮车。

## 2026-08-25 · 章节分包应按首次游玩阶段切割，不能只按章号切割

- 第一章通常承载最多基础角色、武器动作、BGM与教学场景，单纯按章打包会让“第一章包”继续接近完整试玩体积；应进一步按启动段与后半段切割。
- 场景ID到PCK的归属必须由一个运行入口决定，并由契约测试锁定；构建脚本、CDN清单和运行时若各自维护名称，最容易出现导出新包却请求旧包。
- 仅看源资源MiB不能判断玩家下载量；必须实际执行Godot `--export-pack`，再在独立公共工程中验证资源挂载前不存在、挂载后可读。
- 浏览器缓存验收要同时看服务器请求日志：第一次只下载当前阶段包，刷新后必须没有第二次PCK请求，才能证明`user://`缓存、哈希校验和重新挂载形成闭环。

## 2026-08-25 · 转换器日志里的AppID不等于开发者工具实际导入的AppID

- 通用引擎转换器可以打印“设置游戏AppID成功”，但输出`project.config.json`仍保留模板工程AppID；只看控制台日志会把工程导入到错误身份。
- 构建完成后必须重新读取`project.config.json`，强制回写AppID、项目名和游客标记，再由独立预检比较构建报告与项目配置。
- 正式预检必须同时阻断`touristappid`、localhost和HTTP CDN；本地浏览器烟测通过不代表可以上传体验版。

## 2026-08-25 · 通用转换器注入代码前要先展开Emscripten简写箭头函数

- Godot 4.6生成`(args)=>singleExpression`形式的WebGL包装函数；微信转换器若向表达式前插入`if (...) return;`，产物会变成非法JavaScript，即使原始Web包在Chrome完全正常。
- 不应直接修改Godot导出的`index.js`。先复制为微信专用JS，针对唯一已知函数做严格单次替换；匹配数不是1时立即失败，提示上游模板发生变化。
- 转换日志显示成功不代表JS可解析。最终`framework.js`必须进入JavaScript模块语法检查，错误产物不得交给开发者工具。
- 开发者工具游客模式的插件缺失是账号能力门槛，不能靠删除`game.json`插件声明绕过；WXGameKit是转换后运行时依赖，应改用测试号或正式AppID。

## 2026-08-24 · 战斗清场、调查取证和任务结算不能合并成一个按钮

- “击退灭口者”只证明现场暂时安全，不等于玩家已经听到证词。战斗胜利应写入清场旗标，随后才显示证人、账册或遗留物的独立交互。
- 任务完成触发应绑定`testimony_heard:`或`evidence_acquired:`，而不是绑定敌人死亡；这样任务卷宗能记录调查事实，玩家也清楚奖励来自哪一步。
- 奖励武功应与当前战斗场景和必得武器相容。雪岭给刀与刀法、矿道给护息心法，比在章末一次性堆三项成长更易理解，也能在后续Boss前形成可用构筑。
- 复杂场景的蒙版、回退多边形、探针和出口要同批更新；只画蒙版会让测试与编辑器仍读取旧拓扑，只写多边形则会重新出现视觉道路与碰撞不一致。

## 2026-08-24 · 章节选择应改变方法与后续条件，不应删掉已经查实的责任

- 调查型RPG的选择不是“公开真相/隐瞒真相”二选一。证据不完整时，更合理的分支是公开次序、证人保护和补证方式；已经查实的事实在两条路线都必须保留。
- Boss交出的文件如果直接带完整落款，会让后续章节失去调查价值。章末证据应解决当前问题并打开下一层问题：证明行动同源，但保留最终发令者缺口。
- 关键Boss至少需要站立、攻击、受击/倒地和战后负伤四种可读状态。只换一张立绘或让通用精灵上下抖动，无法承担章末过场。
- 场景背景画出调查台后，可再叠一个小型透明证据物并让交互区域标记`visual_baked`，既避免重复大物件，也比空地感叹号更容易发现。

## 2026-08-25 · 世界地图道路必须先成为美术合同，导航不能在事后猜路

- 旧v6看似生成了“精确蒙版”，实际只有约29.5%落在道路色上，并被拆成10个连通块；颜色阈值、低分辨率寻路补线和16px矩形化会依次放大道路错位。
- 正确顺序是冻结路线图→绘制无路地形→把同一路线写入可见道路→向内收缩为导航核心。美术、蒙版、门户和回归都引用同一拓扑，当前v7道路覆盖率92.1%、单连通块。
- 生成模型即使要求“严格保留路线”也会移动道路和地标；对玩法关键几何不能只依赖生图。先让ImageGen负责地貌与道路材质，再以确定性路线合同控制中心线和导航，必要时做一次精修编辑。
- 渡口航线不是海面道路。海面保持不可走，玩家在渡口交互后切换场景；视觉航迹与船只可以存在，但不能进入陆路mask。

## 2026-08-25 · 大地图卡顿通常来自物理世界被当相机移动

- 在`_process()`平移包含StaticBody、Area、CharacterBody和背景的整个WorldContainer，会把渲染平滑、固定物理步和整像素取整混在一起；角色移动稳定也会呈现停顿/跳步。
- 大地图应保持世界固定，使用真实Camera2D跟随玩家；像素角色可继续nearest，连续滚动的大幅背景单独使用linear。
- 每物理帧重新拼贴图路径并查询ResourceLoader虽通常命中缓存，仍会产生字符串与资源表开销；按武器/状态/方向缓存后只在状态变化时切图。
- `moved`必须在`move_and_slide()`之后发送，否则深度、遮挡和返回点永远落后一物理帧；撞边没有实际位移时也不应继续播放走步。

## 2026-08-25 · 用户认可的首版音乐应保留完整录音骨架

- 当前v5虽然给波形函数命名为古琴、箫、二胡，底层仍是程序谐波与噪声，丢失了早期完整旋律、和声推进和真人力度，因此“传统配器名称”不等于“武侠听感”。
- 回归首版不是所有场景播放同一首。以早期CC0探索/战斗母带作骨架，仍可通过段落、速度、主奏、鼓型和空间做8类探索与5类战斗变奏。
- 新变奏先做三首A/B试听再扩全套；v2/v3/v5保留历史参考但不再运行，避免反复覆盖用户认可基线。

## 2026-08-28 · 浏览器注入中文正文必须绕开控制台编码

- PowerShell管道接收Python输出的中文JSON时，控制台代码页可能先把UTF-8正文转成乱码；即使浏览器成功接收，草稿也会保存损坏文本。
- 发布前应直接用UTF-8读取Markdown，转Base64后交给页面内`TextDecoder`恢复；注入完成后把标题和正文前80字再次Base64取回并在本地解码核对。
- 头条新版编辑器会自动显示“草稿已保存”，不一定保留独立存草稿按钮。完成条件应是草稿列表能查到同一标题、摘要和封面，而不是仅看到编辑页提示。

## 2026-08-28 · 头条编辑器图片数量不能直接数DOM里的img

- 头条ProseMirror为每个正文图片保留两个同源`img`节点，编辑器里18个节点实际只代表9个独立媒体；直接报“18张图”会误导。
- 正确验收是先按唯一`src`去重，再从`article/edit`服务端内容统计`<img>`标签。当前草稿编辑器为9个唯一地址，服务端也是9个正文图片。
- 动态WebP先转成4帧GIF再上传，保留180ms/帧循环；静态实机图缩到1280×720、系统诊断图保持无损，能显著减少上传时间并避免正文加载过重。

## 2026-08-29 · 室内场景复用必须同时核对背景、布局和叙事身份

- `linxi_master_hall.tres` 名字看似是师父正屋，实际却引用书生家背景和另一套卧房布局；继续往上叠第六章交互会让视觉、碰撞和剧情身份三层一起错位。
- 复用旧场景前必须同时检查 `background_path`、`map_layout`、主入口/回程和画面中的真实物件；任一层不一致就建立新版布局，不用局部碰撞补丁掩盖底层错配。
- 调查章节的信息揭示应拆成“事实、解释、动机”三层。旧居只给事实证据，师父对质再给解释，幕后动机保留到后续证人与双线调查；不能靠一个木匣塞满婚书、家信和反派关系完成整章揭密。

## 2026-08-29 · 剧情分支要保存方法，不能只保存台词去向

- 师徒对质若只把三个选项跳到三句不同对白，下一章无法知道玩家选择了公开、独查还是先保人，分支等同于没有发生。
- 每个选项应同时写入一项明确立场旗标和一项方法旗标，再汇流到共同主线；后续读取方法改变NPC出场、证人安全与公示节奏，而不是把整条剧情永久分裂。
- 取证任务继续坚持“地点事实→物证→对抗阻力”三拍。物证和战斗均不能相互替代，`require_all_completion_triggers`应成为调查型主线默认审查项。

## 2026-08-29 · 复用正式场景美术时必须隔离旧场景身份

- 同一张客栈背景可以服务不同章节，但不能直接复用带有旧NPC、旧账册和旧回程目标的完整 `SceneScript`；应新建场景与布局，只共享经过验收的背景资源和基础碰撞结构。
- 章末信件应同时具备“场景内可见实物、背包可反复阅读、任务完成旗标”三层合同。对话负责首次演出，背包物品负责复查，旗标负责进度，三者不能相互替代。
- 后续章节尚无现行场景时，章节按钮可以先进入大地图作为调查起点，但目录必须继续标为规划或部分实装；不能为了让按钮亮起而把旧版任务资源冒充成新版可玩内容。

## 2026-08-29 · 调查顺序分支应改变警戒，不应删除内容

- “先查A或B”若直接把另一处入口锁死，玩家会把调查方法误解为阵营站队，也会损失用于交叉验证的必要证据。正确结构是共同解锁两路，首选旗标只改变NPC态度、文书位置与后续阻力。
- 两路线任务必须用全部触发器结算，并在接受任务时回查历史旗标；这样先到任一侧都能记录，补查第二侧后才会完成。
- 世界地图新增门户不能只改运行`.tres`。若地图由脚本生成，还必须同步生成器与拓扑JSON，否则下一次重建会静默抹掉入口，验证器也只会检查旧门户集合。

## 2026-08-30 · 承认一方旧罪不等于证明另一桩案

- 多阵营调查里，一份“对自己不利”的诚实记录很有说服力，但仍必须核对日期、对象与行为。烈云药册能证明强硬派误伤无辜，却因时间不同不能被拿来替代五派弟子案凶证。
- 双线任务最好把阵营自证、对方物证和现实阻力拆成独立触发器；只打赢强硬派或只找到一份簿册都不应结案。
- 首个战斗锚点不等于章节战斗覆盖完成。成长快照应同时记录锚点数量和整体缺口，避免“从0到1”被展示成“全部完成”。

## 2026-08-30 · 死者权限仍在使用不等于死者本人出现

- 暗号、令牌或账号仍被使用，只能证明权限链没有真正注销，可能是本人、冒用者、共享口令或内部放行。没有看清脸的证人不能直接完成身份反转。
- 关键改革派的可信度应来自可被验证的自损证言：公开对自己阵营不利的原页、日期和署名，比一句“请相信我”更有效。
- 图像生成器即使明确要求透明背景，也可能输出RGB烤棋盘。所有透明角色资产必须检查PNG模式和Alpha极值；失败候选拒绝后，可用纯键色重做并走确定性抠图/条带脚本。

## 2026-08-30 · NPC完成后对话不能被基础active门槛先隐藏

- `dialog_variants`只在NPC已经生成后才会选择。基础NPC配置若带`require_quest_active`，任务一完成NPC便不再生成，`require_quest_completed`变体永远无法出现。
- 承担连续主线入口的常驻角色，应让场景本身控制可达阶段，NPC保持存在，再按完成旗标/任务状态切换对话。
- 权限登记人与实际操作人是两种身份字段。调查系统应分别记录“registered owner”和“actual user”，即使名字一致也必须有独立证据完成合并。

## 2026-08-30 · 身份确认至少需要归属、目击与连续时序

- 权限登记只给候选人，直接目击可能受记忆影响，路线时序只能证明同一使用者；三者独立时都不够，互相吻合后才适合写入身份确认旗标。
- 身份确认与幕后授权、行动动机必须拆成后续问题，避免一个反转同时吞掉整章调查空间。

## 2026-08-30 · 机构授权不能冒充个人签发

- 内署双印与机构密令可以证明山庄体系授权，却不能在没有亲笔署名时直接写成苏雾笙个人逐条下令。
- 证人保护选择应改变公开速度、风险承担和外部介入，不应删除已经取得的证词或封锁后续主线。

## 2026-08-30 · 章末选择不能覆盖此前查实事实

- 完整公开、分阶段公开和联合会审只能改变公开时机、证人风险与外部介入；烈云旧罪、薛影身份和茗雾授权等已确认事实必须在三路都保留。

## 2026-08-30 · 终局入口应立即读取前章保护方案

- 证人分散、公开保护和官面收押若到终局入口没有不同反馈，章末选择会显得无效；至少要改变录事对白和即时保护状态。
- 终局首战只负责阻止路线暴露，不能在战斗胜利时自动完成后续盟友汇总或最终证据结算。

## 2026-08-30 · 终局阴谋必须落成可拆解的现场机制

- “挑起各派互杀”不能只写成反派台词；假旗令、错位鼓点、遮蔽首击的迷烟必须成为玩家能分别发现和拆除的现场对象。

## 2026-08-30 · 机关守卫战不能替代断鼓封雾

- 击退机关守卫只代表获得操作空间；鼓阵和雾阀必须分别交互关闭，三项全满足才可结案。

## 2026-08-30 · 终局盟友分工应读取证人保护结果

- 行义帮、烈云与洛阳不能每条路线都做同一件事；证人分散、公开保护和官面收押应分别改变护证、撤离、留档与正面突破职责。

## 2026-08-30 · 终局反派首次正面交锋不应立即变成Boss战

- 先救人、先举证、先问动机三种方法应保存玩家立场；首次交锋负责明确反派逻辑与下一层问题，最终战留给主厅完整责任链。

## 2026-08-30 · 共享UI经验要与跨平台输入规范分层

- “UI经验”容易重新抄一遍安全区、触控目标和联机输入；共享仓库已有这层时，新文应聚焦概念图拆分、状态来源、视觉层级、Tooltip、反馈和截图闭环，并用双向链接连接两类规范。
- 只写手册仍难落地。稳定经验最好同时提供机器可读界面契约、发布检查表和真实失败案例；模板再由验证器锁定关键边界，避免文档正确、示例却逐渐漂移。
- 模板验证不能只跑正常样例。零尺寸、越界、错误嵌套类型、状态遗漏和输入档缺少hover/focus都应作为负例；错误配置必须返回可读错误，不能让验证器自身崩溃。
- 共享仓库默认分支与本地当前分支可能不同；跨仓库贡献必须从远端默认分支新建干净worktree，否则PR会夹带上一批资源或无关修改。

## 2026-08-30 · 连续扩章测试不要把历史规模写成永久精确值

- 分批内容测试若用“场景数恰好等于5”证明第五批成立，第六批正常增加场景后会产生伪失败。历史批次应断言关键场景、角色与分支仍存在，并用“至少保留当时规模”表达累积内容。
- 最新批次仍应使用精确总量断言，作为当前章节计划的单一规模门禁；旧批次负责防回退，不负责锁死未来扩展。
- 对话里的`add_testimonies`不是任意字符串标签，必须同时创建`TestimonyDef`；否则运行时会警告并拒绝写入调查状态，即使资源解析和任务旗标看似正常。

## 2026-08-30 · 多结局处置必须先有共同事实门槛

- 伏法、作证、死战若一进场就无条件三选一，会把前章取证与救人变成装饰。先用授权、证词、撤离三项共同门槛决定是否具备非战斗处置资格，再让玩家选择具体责任路径。
- 非战斗结局不等于免罪：伏法要有多方接押，作证不能作为减刑交换；死战也不能用最后一句人性台词抹去此前杀人责任。
- 透明动作图生成必须检查PNG模式和Alpha；RGB烤棋盘候选即使视觉上像透明也应拒绝。纯键色母图配合确定性切帧脚本更适合正式运行资产。

## 2026-08-30 · 最终Boss战不能替代案件结算

- 调查型RPG的最终Boss负责停止正在发生的伤害，不应在胜利画面里自动完成证据公开、阵营追责和长期关系结算。
- 把“第三声钟前阻止假令”设为战斗即时目标，再把亲令、旧卷、证人和责任清单交给独立公示任务，可同时保留战斗紧迫感和调查系统价值。
- 反派控诉若有真实事实基础，战后应同时保存其控诉与其犯罪证据；写成“Boss败了所以他说的一切都是假的”会破坏前章取证。

## 2026-08-31 · 完整公开不等于公开证人住址和可复现杀招

- 调查结局中的“全部公开”应指全部已核验责任事实；证人当前住处、护送路线和危险武学的操作参数属于新的安全风险，不是历史真相本身。
- 分阶段公开必须同时写明补充期限、负责人和复核条件，否则容易退化为永久压案；联合会审则必须保证单方拒认不会阻止其他副本公开。
- 危险技术归档宜拆分“来源、危害、实操”三层：前两层可公开，实操层用多钥、拆册或限期复核治理，既避免销毁史料，也避免公开即扩散。

## 2026-08-31 · 关系结局不能用终局菜单凭空重选

- 长期关系应先按信任与共同事件计算唯一候选，再让玩家选择接受该关系或独行；直接把所有伴侣都放进最终菜单会让前章共同承担失去意义。
- 分数并列或不足时默认独行比隐藏偏置更诚实。旧存档若某条关系早于通用信任系统，应只用明确已发生的正式剧情旗标补分，不能凭角色人气加权。
- 章节状态字段批量修改必须带章节编号上下文；只匹配第一个`"implementation": "partial"`可能误改其他章节。改完应立即枚举所有章节状态并重建目录。

## 2026-08-31 · 循环Tween必须绑定短生命周期视觉物件

- 场景控制器长期存活时，用控制器`create_tween().set_loops()`驱动临时旗帜、烟雾或灯光，会在场景重建释放目标节点后留下没有有效Tweener的循环，触发Godot无限循环错误。
- 环境动画Tween应由对应视觉根节点、Sprite或Polygon自身创建；节点离树时Tween一并销毁。机械数据测试无法发现这一问题，必须实际加载包含一次性进场旗标重建的场景。
- 环境动画始终属于视觉层：不得把火焰、旗帜或烟雾数据混进blocker、interaction或portal，也不得用动画位置补偿错误的地图坐标。

## 2026-08-31 · 大范围迷雾要用低数量共享纹理而不是大量烟粒子

- 小火堆烟适合局部上升烟团；森林、山门、渡口和地面冷雾需要宽区域缓慢横移。直接放几十个烟雾节点会增加Tween和纹理节点数量，也容易遮住道路。
- 正式迷雾采用单张共享径向纹理、最多6个低透明Sprite、节点Tween和归一化区域；不读取屏幕像素、不改碰撞、不在`_process`中逐帧更新。
- 迷雾必须服务场景来源：渡口是水汽、雪营是冷雾、机关廊是阀门蒸汽。剧情来源被关闭时，雾层也要用同一旗标关闭，不能只剩无因果的氛围特效。

## 2026-08-31 · 水面反光和风雪不需要全屏高成本Shader

- 固定视角2.5D水域可用少量短Line2D在明确水面区域内淡入、漂移、淡出；比全屏扭曲Shader更容易限制到河道，也不会让码头和道路一起波动。
- 风雪应是一层共享纹理Sprite群，而不是每个火盆或区域各建发射器。雪地强度通过count、opacity、wind_x区分，单场仍只有一个顶层雪层。
- 场景名称不能替代像素语义。标为“河营”的场景若背景没有可见水面，就不得添加水波；必须先修正背景资产，再接入水域动画。

## 2026-08-31 · RGBA不等于透明前景，平台降级应减子节点而非删语义

- 图像即使是RGBA且含零Alpha，也可能在主体周围保留大面积半透明色底。透明前景必须检查角点Alpha、半透明像素分布和实际合成；本批竹叶候选因此拒绝。
- 项目已有合格透明素材时应优先复用，不因新生成图更精细就覆盖可追溯资产。竹冠风动复用既有独立前景，比继续抠除绿色光晕可靠。
- 微信/Web降级应减少烟团、雾团、水光线和雪点等同类子节点数量，保留“这里有火、雾、水、雪、旗”的顶层语义；直接删除整类物件会让不同平台呈现不同场景状态。

## 2026-09-01 · 分包下载画面自身必须属于公共包

- Loading图若按普通场景美术的默认规则分到第一章包，首次下载第一章包时反而无法显示Loading图，形成资源依赖死锁；启动、下载、重试所需的全部视觉与字体必须留在common。
- 资源包下载与场景线程加载是同一次玩家等待，应共享一条进度语义：下载占前段、校验与场景加载接续后段，不能在90%时清零或闪回另一套遮罩。
- Loading原画应无烤字并预留稳定信息安全区；中文标题、悬疑短文、真实百分比和错误状态由Godot排版，既能换文案，也能避免AI文字乱码。

## 2026-09-02 · 战斗站位坐标必须描述脚底而不是人物中心

- 2.5D战斗底图的远景可能占据上半屏；把敌方脚底放在0.15～0.33的归一化Y会让人物站进竹冠、建筑或山体。战位合同必须直接记录地面接触点，并按演员画布内的脚底偏移换算Control位置。
- “看起来随机”不等于连续随机坐标。无战位圈的背景应保留五个验收过的固定点，只在安全子集之间轮换；这样既有松散阵型，又不会随机撞UI或离开地面。
- 战场类型必须从剧情地点推导，而不是从敌人类型推导；同一山贼在村口、矿道和雪岭遭遇时应该使用三种不同环境。后期战场路径若写入通用控制器，还需由试玩staging显式阻断未使用资源，避免提前增大第一章包。

## 2026-09-02 · 群体技能不能在逐目标循环里等待完整演出

- 在`for target`内依次`await VFX → take_damage → await play_hit`会把一次群攻变成多次单体攻击；目标越多，结算越晚，群体增益也会出现明显先后顺序。
- 正确时间轴是“施法一次 → 所有目标共享一套特效帧钟 → 同一帧提交全部数值/状态 → 并行启动飘字与受击 → 等待最长反馈一次”。倒地也应在受击结束后并行开始。
- 项目只有Regular中文字体时，不必立刻再打包一套粗体。`FontVariation`小幅`variation_embolden`能保持字体来源和微信兼容性；小字号仍需同时提高亮度与深色描边，单靠放大字号不能解决亮背景上的对比问题。

## 2026-09-02 · 字体加粗后必须重新验收按钮内容框

- 86×38按钮在Regular字体下勉强可用，统一加粗后笔画和描边会吃掉上下安全区；字体方案变更必须同步复查按钮高度、九宫格内容边距和禁用态长文案。
- 小详情卡不一定能继续扩宽。应先增加高度、收敛九宫格内容边距，并把“其他队友已装备”这类状态改成短标签；完整原因留在详情正文或Tooltip。

## 2026-09-03 · 同类战斗底图也应允许独立站位模板

- 通用五点阵只能作为兜底；村落、洞窟、雪山的透视地面和UI留白不同，强行共用坐标会让人物虽然“没出界”，却没有站在构图最舒服的区域。
- 用户标注红框时应换算为归一化脚底范围，再在框内作者化五个安全点；人物头部可以向上延伸，验收对象始终是脚底接触点。

## 2026-09-03 · 人物比例应按有效像素面积复核

- 两张角色帧即使有效身高接近，宽厚服装与瘦长衣袍的视觉体量仍会差很多。主角300px高、23662有效像素，山贼327px高、37497有效像素；只补到相近身高仍会显小。
- 战斗比例验收应同时比较Alpha边界高、宽、有效像素数及实机同屏截图；最终缩放保持等比，避免用单独拉宽破坏人物造型。

## 2026-09-08 · 不限章节的长链必须把入口与结算门槛分开

- “开放世界可提前获得”不能只把`starts_in_chapter`改小；每个入口本身都不能依赖`chapterN_complete`，且任一入口都应能自动接取。
- 线索顺序开放不代表奖励门槛降低。用多个独立原理旗标汇总出最终高潮入口，奖励只绑定最终应用节点，才能同时保留自由探索与长链分量。
- 旧版线索已经写入存档时，应做单向、幂等的等价进度映射；不要要求老玩家重新解一次，也不要因重构收回已学技能。

## 2026-09-09 · 无门派路线必须有等价内容密度而非等量门派奖励

- “可无门派通关”不能只允许跳过入派旗标；必须提供独立的选择反馈、考校、根基奖励、后续获得来源和流程回归，否则玩家实际得到的是残缺路线。
- 五派的优势应是稳定传承、师门任务和流派协同；散修的优势应是方向自由、江湖武学组合和更早接触开放世界奇遇。两者内容结构不同，但都要能支撑完整通关。
- 门派重定位不能只改显示名。技能分类、武器门槛、装备、敌人技能、VFX、任务奖励、图鉴构建和旧档迁移必须一起更新，并用分布统计与获得链测试防止静默遗漏。
# 2026-09-09 · 门派辨识度不等于一派只能用一种兵器

- “五派兵器不重复”适合作为早期视觉区分，却不能覆盖已经明确的门派传统。武当剑、掌可兼修时，应让两套技能并存，并用独立历练成本控制成型速度，而不是用互斥旗标制造伪选择。
- 华山的“剑法为主”要体现为同一武器内的横向选择：单体爆发、破防和群体剑阵都应有可收集招式，而不是只有一条数值升级线。
- 无门派自由不能只写在说明里。公开武教头、城市任务、隐藏大师和残卷必须提供五系实际获得路径；大世界探索、奇遇和招式收集应成为主循环，主线只负责把玩家引向新区域。

## 2026-09-09 · 高清地图分块不能改变逻辑坐标，也不能漏进微信包

- PC地图用2倍纹理时，导航、NPC、出口和任务物件仍应保留原逻辑尺寸；每个高清块以显示倍率映射回逻辑坐标。直接把`design_size`翻倍会让所有归一化之外的像素参数和镜头体验漂移。
- 分块必须来自同一张审核母图并保留重叠裁切；独立生图即使题材相同也无法保证道路、透视和接缝像素连续。
- 只新增分块节点却继续给隐藏`TextureRect`加载整张图，不会节省任何内存。流式场景必须跳过整图预载，整图只作为小地图预览或旧场景兜底。
- 微信staging会递归扫描`.tres`中的所有`res://`字符串，即使运行时永远选择移动档，也会发现PC路径；因此桌面块必须在staging过滤层显式排除，并用资源闭包报告验证“移动块有、桌面块为0”。

## 2026-09-09 · 三人队伍难度先修行动经济，再抬单体攻击

- 队友从0增至2时，玩家每轮行动数近似变成3倍；只给单体敌人加少量气血仍会被第一轮集火，而大幅加攻击只会制造不可预测秒杀。更稳妥的顺序是：普通战改2～3敌、Boss按队伍补护卫、全体敌人按实际参战队友提高耐久，最后只小幅补攻击。
- 教学、正式考校和叙事决斗必须显式标为单人，不能把“队伍存档里有三人”误当成每场都应三人参战；野外阻击和Boss战则不能继续沿用单敌入口的视觉结果。
- 多敌化必须同步归一化战利品。第一名敌人给全额，后续成员给折算收益且不重复必掉剧情物，才能让风险和收益上升但不让经济按人数线性膨胀。

## 2026-09-12 · 人口密集Field卡顿不能只调相机参数

- Shader参数为0不代表Shader没有成本。NPC描边仍会执行纹理采样和TIME计算；十余名NPC同时常驻会让镜头移动时更容易出现Canvas抖动。交互高亮应按范围动态挂载材质。
- `set_walk_direction()`每个物理帧都会调用时，函数内部的纹理路径拼接、缓存查找、材质/缩放赋值也会累积。用“武器:方向:walk/idle”状态键短路不变状态，且巡逻纹理在`_ready()`缓存，不能在`_process()`内调用`ResourceLoader.exists()`。
- 遮挡检测和返回点存档不需要60Hz精度。按实际移动像素采样可降低多边形与Dictionary开销；无任何遮挡区时应直接跳过遮挡路径。
- 短音乐提示必须与循环BGM分离。若复用自动循环播放器，只截取播放时间并不足够；还需显式关闭流循环、处理异步淡出请求ID，并确保新场景BGM可以取消旧提示音。

## 2026-09-09 · 实物交互点坐标应是可站立的观察位

- `visual_baked=true`只能说明物件已经画在底图里，不代表把交互中心直接放在物件碰撞盒上就是正确的；导航会把目标判为不可达，玩家也会被迫穿进桌子或箱子。
- 正确合同是：画面中有明确矿车、铜模、账册或账箱，碰撞盒覆盖物件本体，交互点放在紧邻物件的可站立观察位，标签用“靠近查看”表达。每个新点同时进入栅格可达性验证。
- 生成底图后不能沿用提示词阶段的估算坐标。必须逐张目检成图，再校准导航多边形、阻挡、交互、NPC和火焰/烟雾的归一化位置。

## 2026-09-09 · 面板攻击和招牌技能都必须验证真实运行路径

- `EnemyDef.attack`写得再高，如果编队结算又从敌人的默认筋骨/内劲推导攻击，最终仍会变成同一个低值。数值验收必须调用战斗控制器的真实伤害入口，不能只检查`.tres`或单挑模拟表。
- “技能ID已经挂在敌人身上”不等于技能已接入。AI还会检查内力消耗；`max_mp=0`配25点消耗技能只会让精英整场退化为普通攻击。资源门禁应逐项验证开场至少可施展一次。
- 多人战应以1、2、3人队分别验收。固定三敌编队对三人队合理，不代表独行路线合理；独行时保留2敌群战、满队时恢复3敌，比统一削弱全部敌人数值更稳定。

## 2026-09-09 · 后期数值回归必须使用成型技能并复现AI随机语义

- 让16级主角继续使用第二章基础剑招，会把所有终局战误判为过难；后期基线至少要包含章节稳定可得的进阶武学、预期装备倍率和有限应急药品，同时排除橙色奇遇与门派专属奖励，才能代表可通关的散修路线。
- 模拟器若每回合强制敌人释放最高伤害招式，并让全部单体敌人永久集火同一角色，会制造运行时并不存在的极端压力。招式应按`aggression`和技能顺序轮换，目标应近似实际随机分配。
- 普通追兵误挂玩家橙色终极招式既破坏身份，也让数值难以解释。后期难度应由编队职责、耐久、可读状态和资源消耗构成；Boss可以打得久，但不应靠无预警高攻秒杀独行玩家。
- 剧情危险地图的随机战应在首次作者化阻击清除后再开放，保持普通2敌、低权重3敌；这样既补足多人战密度，也不会让初次进图被剧情战与随机战双重打断。

## 2026-09-10 · 双向传送应记住来源侧真实落点

- 室内出口只写固定 `target_pos`，在室外地图更换底图、碰撞或门位后很容易失效；坐标一旦被可走校验拒绝，就会退回场景默认出生点，玩家看到的表现像“随机出现在角落”。
- 双向门的可靠合同是：首次进入仍用目标场景作者落点，同时记录来源侧玩家实际站过的可行走坐标；反向返回优先使用这份动态坐标。这样地图调整后只要入口本身仍可到达，返回点就不会漂移。
- 返回点必须按“来源场景→目标场景”隔离，并进入存档；否则同一室外地图上的多间房屋会串门，或在室内存档读档后重新退回旧坐标。自动化应遍历所有互为目标的 portal，而不是只测一个师傅房样例。

## 2026-09-12 · 编队数据与运行时截断必须一起验收

- 资源里写了三敌，不代表玩家真的会遇到三敌；场景路由可能根据队伍人数再次裁剪。高级区需要显式声明保留作者编队，并用单人队伍直接调用运行适配器验证最终人数。
- “1～3名随机敌人”不等于等概率。让双敌作为主体、单敌作为节奏喘息、三敌作为低概率压力，比固定三敌或平均分布更易形成变化与风险预期。
- 普攻视觉不能由共享`Skill.animation_id`永久绑定兵器语义。伤害规则可以共享，表现层应在行动结算时依据装备、角色专长或敌方招式契约解析；同时验证每类图集的文件哈希，避免只是换ID却仍复用同一张掌印。
## 2026-09-12 · 全屏天气Shader不能把随机生成放进每个片元

- “没有循环、没有屏幕采样”不等于全屏Shader一定便宜。1080P雨幕若每帧在每个像素中反复做多组`fract/dot/hash`，与大尺寸绘制背景合成时仍会造成移动掉帧。
- 稀疏天气纹理适合在进入天气时一次生成并缓存；片元阶段只采样两次纹理，改变UV速度、尺度和偏移即可保留远近层次与随机观感。
- 落地反馈必须另设数量预算。小雨5组、大雨8组足以传达地面响应；不要因顶层节点少就忽略每组内仍包含多段抗锯齿线与循环Tween。
- 性能报告必须注明渲染器、分辨率与GPU；高端桌面60 FPS只能作为路径稳定证据，不能替代微信/移动端真机验收。

## 2026-09-12 · 高倍率不等于低属性阶段有高阶感

- 固定伤害 + 攻击系数的公式中，开局攻击只有24时，即使高阶招式系数比入门技多42个百分点，也只贡献约10点差距；如果固定伤害也只多34，橙色绝学最终就只领先约44点。
- 审计高阶武学必须同时看低、中、高三档实际攻击与目标防御，不能只比较百分比字段。高阶本体负责跨阶差，心法负责玩法机制，装备与成长负责后期放大。
- 敌我共用资源应先查引用关系。直接修改共享招式会同时改变敌人；玩家专属的额外强度更适合放在已装备心法的指定招式协同中。
- 群攻的命中回复必须按“每次施放”而不是“每个目标”结算，否则敌人数会反向成为无限资源来源。

## 2026-09-12 · 生成式整图不能承担像素级导航真值

- 给生图模型附道路覆盖图，能约束大体拓扑，但不能保证道路曲线、桥口、河岸和地标仍落在原坐标；美术观感合格不等于能直接替换带13个门户和旧档落点的运行地图。
- 稳定做法是保留审定地理母图，以一份机器可读道路几何同时生成可见道路强化层、移动遮罩、门户连通验证和流式分块。单独改背景或单独改遮罩都应被逐像素重建测试拒绝。
- 地图返回点也属于道路合同。城市出口应直接写当前门户坐标；“运行时寻找最近可走点”只用于修复旧档，不能替代正确配置。

## 2026-09-13 · 大地图地标、地区场景和交互语义必须成套设计

- 大地图上的大城、门派和渡口如果进入后只是一屏或重复同一底图，会立即破坏空间尺度。每个分区应有独立底图、独立道路与独立地标，同时在美术语汇上保持地区一致。
- “能点”不等于有内容。任务必须落到通缉榜、案卷桌、货物、碑刻或NPC等可辨识对象；感叹号只能增强提示，不能代替对象本身。
- 硬锁入口会把开放探索变成菜单式解锁。更适合本项目的方式是先让玩家进入，再用高危提示、敌人强度、路线与条件奖励形成软门槛。
- 多屏卡顿要区分逻辑卡顿与观感拖滞：同步加载分块会产生帧尖峰，角色与相机双重平滑会产生迟滞。Web/微信预载、桌面线程预取和单层插值应分别处理。
- 站立图跨帧身高变化不能靠每帧scale修补；应离线统一有效身高和脚底锚点，并用像素级或运行截图验证。

## 2026-09-13 · 大地图的规模感不等于塞入更多地标

- 传统RPG大地图的“大”主要来自留白、远距离地标、宽主路和跨屏旅行，而不是继续提高地标密度。中央开阔区应是正式可走地形，不是道路之间不可进入的装饰草地。
- 生成式底图适合重做整体构图，但导航仍需独立的结构化来源。路网要同时产出可见道路强化、导航蒙版、门户连通和负地形验证，避免美术与碰撞再次漂移。
- 拓扑连通不能替代视觉验收。本批自动化全绿后，实机截图仍发现门派入口落在山体上；最终将转场点放在山脚官道口，以箭头进入独立门派场景，山上建筑只承担远景地标。
- 常驻目的地标签是旅行信息的一部分。地图边缘需要支持文字向内侧排版，标签显示、点击距离和实际转场仍保持同一出口节点，不能另造一套纯UI坐标。

## 2026-09-13 · 城市、通缉、练级点和门派门槛要构成同一个循环

- 只增加城市底图不会自然产生玩法；每个城市至少要提供安全补给、实体榜单、近郊历练入口和返回世界地图的闭环，且城市与练级区都必须有独立底图与导航。
- 通缉犯不能在玩家接榜前预先站在地图里。榜单状态是单一真值：接榜后选择同等级候选藏身处、现场生成目标，战败迁移到另一候选点，归案后移除并一次性结算。
- 榜单必须在接单前完整披露建议等级和奖励明细；随机位置只制造搜索变化，不能隐藏战斗风险或用不相干的高等级地图惩罚玩家。
- 声望应作为外部成长，不混入七项战斗属性。门派入门采用“低声望门槛＋建设物资＋考校任务”三段式，申请阶段不能等同正式入门或提前发武学。
- 刷怪区应同时服务等级成长、武学历练和门派物资，不要为每种资源单独造一条重复劳动链。1/2/3敌以双敌为主体，兼顾独行上手和成队后的压力变化。

## 2026-09-13 · 大场景清晰度、人物比例和门框层级必须一起处理

- 把一张小全景整体缩进屏幕，会同时造成两个问题：人物相对建筑过大，远处道路又因像素不足而模糊。大门派应拆成若干具有明确空间职责的原生多屏地图，而不是继续缩小人物或无限放大同一张图。
- 高清运行图应从生成源直接做神经重建；不能先降采样成运行预览，再对预览做普通插值。大地图若有结构化道路强化层，超分后必须重新叠加同一来源的道路视觉，否则清晰度提升会把路网合同冲掉。
- 背景中已经烘焙的门楼不能只靠Z排序解决层级。用角色脚底进入`actor_fade_zones`触发人物淡化，并用独立blocker保护门柱；门洞、淡化、碰撞、门户四者应在同一测试中验收。
- 探针位于可走多边形内部仍不足以证明能到达。多屏场景要用正式Field碰撞判定从出生点做完整脚底泛洪，确认所有门户、交互前站位和分区连接属于同一连通域。

## 2026-09-13 · 角色透明不能替代真正的前景遮挡

- 对烘焙门楼只降低角色 alpha，门楼仍在底图下方；结果是透明角色依旧画在屋瓦、横梁和门框上。可穿越建筑必须拥有真正的前景采样层，角色半透明影像只负责保证被遮挡时仍可辨识。
- 庭院灯柱、碑、香炉等固定物件不必立刻重画整张空白底图。可先从审定底图按紧边多边形重复采样，并以物件脚底Y为深度线：角色在后时显示前景采样，在前时隐藏重复层。碰撞仍需独立登记，不能让深度层顺便承担导航。
- 前景采样多边形不能用宽松矩形。矩形中的地面也会变成遮挡，造成角色整块消失；必须贴近物件轮廓，并用玩家在物件边缘的实机截图验证局部遮挡。
- 背景画出道路但结构化路源漏记时，视觉审查和门户连通都可能通过。用户报告的每段可见支路应加入道路源和桥面/岸边脚底见证点，再统一重建底图、导航与流式切片。
- 合成音乐的“铜管感”常来自持续低频正弦和低音脉冲，不一定来自音量。用短拨弦包络替代持续低音，并把110Hz以下能量作为机器门禁，能在小音箱上显著降低大号式轰鸣；最终仍需主观试听验收。

## 2026-09-14 · 生成式底图、遮挡真值和功能文字必须分层生产

- 过去从实机截图判断门楼矩形，只能得到粗略区域，无法表达“门洞为空、横梁有实体、屋檐边缘不规则”。结果要么整个人在楼梯上变透明，要么透明人物仍画在屋顶。根治方式是为每张门楼底图交付同尺寸alpha蒙版，让前景采样与角色剪影共用一份像素真值。
- 生成式接口适合生成场景底图，但不适合直接生成要求逐像素对齐的隐藏蒙版：任何局部重绘都可能改变轮廓。遮挡蒙版应由确定性矢量/图像管线制作并验证画布尺寸、门洞透明点和建筑实体不透明点。
- “城市看起来很大”与“城市能作为可玩地图”是两种构图。带地平线、消失点、道路越远越窄的全城远景只适合loading；角色自由行走的地图必须采用固定平行2.5D局部街区，地面尺度跨画布一致，再以多个分区串联出城市规模。
- 世界空间文字会随相机zoom一起被放大。如果字体先在低有效分辨率栅格化，再放大贴到屏幕就会糊；功能地名应使用MSDF/足够字号与描边，并对相机缩放做逆变换，使最终屏幕采样保持1:1。

## 2026-09-14 · 写实场景被动漫超分二次改画，以及导航矩形误吞围栏

- 写实生成源在游戏里呈现油画/卡通感时，应先检查资产转换链而不是继续改提示词。本批根因是城市脚本使用`RealESRGAN_x4plus_anime_6B`，它会重塑石板、瓦片、树叶和边缘；改为源图确定性Lanczos后运行风格恢复。
- 对复杂城市用几块宽矩形拼可走区，会把围栏后的石地、摊棚、墙顶和码头一起开放。应交付独立黑白导航蒙版，白名单绘制明确道路，再用MinFilter给玩家脚底留边，并以彩色叠图人工复核。
- 遮挡与碰撞是两份真值：树冠alpha蒙版决定角色应被哪些像素盖住，导航蒙版决定脚底能否进入。把二者合并会导致“树下不能走”或“围墙能走”的极端结果。
- 音乐质量不能只靠频谱和文件可播放判断。用户主观否决后应立即撤下，回退到已认可音色，并把新曲加入逐首试听门禁；开源生成框架可参考工作流，但不能替代音乐审美和授权核验。

## 2026-09-27 · 返回点、天气和物件层级反复出错的共同根因

- 返回点若记录“角色触发出口时的位置”，入口面积、导航投影和最后一帧移动都会把误差带到下个场景；正确真值是源门户作者明确声明的门外锚点。
- 出生点只测中心像素，会允许人物脚底的一半压在桌、屋顶或围栏上。完整脚底净空应是所有场景统一的最后一道防线，并对旧存档位置同样生效。
- 天气是全局状态，但可见范围不一定全局。剧情雨若没有场景作用域，返回晴天村庄也会继续渲染；作用域必须随存档保存，室内抑制不能顺便清掉剧情状态。
- 烘焙物件的碰撞和遮挡不能互相替代：blocker决定脚底，y-sort前景决定角色被谁盖住；可穿门楼再使用像素alpha蒙版处理局部半透明。
- 大地图重画若只替换背景，入口和路网必然漂移。把结构化路线同时用于轻微道路强化、导航蒙版、入口坐标和自动验证，才允许写实新图进入运行时。

## 2026-09-29 · 外部 CC0 素材合法可用，仍可能视觉不适用

- Poly Haven 的模型可以作为授权素材导入 Godot，并用正交相机转成带 alpha 的独立物件；来源、作者、文件哈希须随资产保存，不能把许可判断等同于最终美术验收。
- 把单独渲染的巨石贴到旧烘焙草地，即使加接地阴影、缩小、调色，仍可能像浮在地上的贴片。改进方向是统一相机、光源和地面接触材质，而不是反复只移动角色或扩大碰撞。
- 候选物件应隔离在独立场景；碰撞、Y 深度和透明像素合同通过后仍需实机目检。视觉失败不得晋级正式地图。

## 2026-10-03 · 城市分层试样：typed Array清理与真实物理检查

- 对`Array[Dictionary]`等typed导出字段，不可假定`Object.set(name, [])`已经清空：本次新试样继承了旧南门两块大型guard-post阻挡，导航／新物件合同判断可走而实际PhysicsShapeQuery拒绝。先证明复制后的数组与源数组不同，再对现有typed数组`.clear()`，复读getter确认空，并检查实际碰撞体白名单。只测源资源未改变或没有alias不足以证明候选正确。
- QA归档`.gd`若位于Godot扫描目录且带`class_name Player`，会污染全局类缓存；`ready`日志和进程OS0可能伴随真实Player未创建。只给明确归档目录加`.gdignore`保留原失败，严格导入后核对class缓存和真实角色、NPC、碰撞shape存在。不删除原证据，不停用户编辑器。
- PowerShell先打印自定义object再打印MatchInfo会按前者字段格式把后者显示为空，导致漏读错误。日志摘要使用独立JSON对象和`.Line`字符串，实际stderr保留；不能把看似空摘要当零ERROR。
- 有效角色身高参考应绑定当前方向、原PNG SHA与真实sprite scale。DOWN132、UP131、LEFT/RIGHT130像素不同，不把113.5134px的DOWN参考套到RIGHT，也不通过扩大误差或放大人物掩盖错误。
- 机制试样的技术通过不授权正式接入。三栋独立建筑和十物件可以验证路线、阻挡／Y排序／局部alpha；空灰砖广场、基础几何灯柱／榜亭仍需美术返工。正式NPC任务／商店／榜单奖励应在地图视觉通过后的独立迁移阶段验证。

## 2026-10-04 · 异步战斗与材质尺度必须按实际执行链定位

- 普通对话结束不等于仍停留在Field。ROOT194最后对话节点已经正常提交 `battle_group:`，LoadingManager仍异步加载时，测试只瞬时寻找攻击按钮而漏接战斗，提前开下一fixture，形成grace失败和大量脱树级联。新的测试应同时识别真实Battle UI及精确的进行中battle.tscn加载，再沿原正常攻击/目标/Victory按钮完成返回；不得以清flag、跳结果或增加计时预算消除失败。
- `get_shader_parameter()`读回数组不是GPU消费证明；但也不能凭画面模糊就断言数组未上传。ROOT196同全域相机真实两点R/G owner诊断（田内255/255，田外0/0）确认旧Array与literal一致，问题应回到实际材质公式，而非继续修已正常的绑定。
- 世界shader以米为单位的0.924m周期，经102.4/72.4077像素每米投影后成为67～95px条带；“短周期”在代码里不等于屏幕上细田垄。田垄必须从逻辑像素目标反算尺度，保留实际ALBEDO/ARM/normal细节，不能先转亮度再用两色替换造成平涂草坪。
- 雪色会放大真实RF台阶，调白、噪声、roughness不能消除分离X/Y平顶几何。派生地貌须让RF、真实网格、selector与脚点投影同源重新生成，并保护道路/门口/桥/物件支撑；不能只改mesh继续沿用旧导航，或把新高度声称为旧RF字节不变。

## 2026-10-07 · JSON 数值必须按实际消费语义比较，不能泛化放宽

- 同次运行的几何缓存身份不能用默认JSON文本：String键与同文本int键、相邻Double可能合并，导致热缓存绕过严格源身份校验。ROOT329用全部消费Variant原生序列化字节SHA，实际四键类型替换/Double bit±1热缓存反例均拒；这不是放宽saved JSON字段比较。
- terrain walk PNG的17鞋白点证明不等于独立物件Physics净空。ROOT331全1344点PNG全白，但94被正确建筑/树石/竹物件阻挡，原writer已明确source solids另由Field检查。应保留原raster证据与正确拒绝负例，另建显式preexecution完整边界物理合同；不能为通过错误混域测试而删碰撞、把94抹去、运行时随失败重选，或宣称旧1344 Physics通过。

- Godot JSON可把`[0]`读为Float数组，与源码整数Array直接比较会误拒合法固定索引；单元素索引应同时严格检查Array、长度和有限numeric零，不接受bool/string或其它索引。
- 同一小数的decimal/exponent文本可能在Godot解析为不同Float64末位。此次17处`collision_offset.x`的实际消费者是Vector2，故仅此字段按两侧native Vector2字节精确比较；不是全字典转Float32，更不能用epsilon消除差异。1 native ULP仍必须拒绝，其他非白名单字段仍原字节/原值规则。
- Float64有限不意味着Vector2转换后有限，例如1e100会溢出native Float32；比较前必须分别拒绝两侧Float64非有限与native非有限，不能让两个inf被视为同值通过。ROOT258实际8256/0、OS0包含这些负例，旧253/255失败保存。
- 大规模GPU候选捕获的地表pass0完成不等于双世界五通道、重复绘制、112独立接缝或最终catalog已通过；无最终Source/M/report与实际OS结果时，来源pin和正式发布必须继续PENDING。
- 内存增量必须绑定实际被测组件的起点：捕获报告的square组件峰值应减square.baseline，而不是整个进程original.baseline。ROOT269误拒经实际旧fixture独立整数复算定位；270正例与错GPU/错RAM/两者都错负例21/0、OS0，保留所有峰值严格比较。
- `World3D.get_instance_id()`来自RefCounted资源，实际高位ObjectID可以表现为负signed-int64，不能拿“正计数”断言通用校验。同时JSON double不能完整保留>2^53的身份低位；实例唯一性须绑定实际原JSON整数字面，而不能用str(parsedFloat64)代替精确身份。节点/Viewport与普通计数仍保持各自原约束，不因此放宽其它数值。
- Float32 RF全量重算得到的最大高度差也可能在默认JSON writer保存后差数个Double ULP。应先独立检查每个原/新RF字节、有限、水陆、限域和节点计数，再仅把native_expected走一次原writer stringify/parse，与未经重编码的saved严格比较；不能两边round或epsilon。ROOT278实际34/0 OS0覆盖saved相邻Double ULP、实际RF Float32 ULP与旧audit拒绝。GDScript长十进制literal自身也有编译解析表示边界，诊断原生Double时用明确IEEE字节而非再写一个长decimal期望值；276/277测试源码与实际失败保留。
- `Shader.get_shader_uniform_list()`当前实际返回普通Array，不能赋给Array[Dictionary]；ROOT281运行时错误导致测试停在函数内而不自动quit，必须核实精确自建进程再中止，原失败保留。ROOT282实际四schema为26/3/26/3，不是headless空列表。原生字段class_name是StringName，而默认JSON为String：原生↔原生应精确比较native Variant bytes，只有saved JSON↔native expected才走一次writer codec。ROOT283四真实资源1252/0、OS0和stderr空，捕获schema/type/order及全mip/native参数检查保持，不能借类型修正略过材质验证。
- 区域预览与最终FULL捕获各有独立输出prefix；FULL catalog没有区域的2063物件副本、240捕获PNG、4材质文件，不等于它们被修改。应以已经SHA绑定的区域result及固定identity/role/ROI/pass结构建立局部只读绑定，逐文件actual SHA校验；物件图还要由唯一source id连回FULL canonical texture/catalog并双边核hash。不同二进制材质不能硬称SHA相同，仍分别验证当前文件、shader/schema/全mip参数。不改冻结报告或向全局_bound加任意路径豁免。
- 实际ShaderMaterial工厂的未显式设置默认值，不保证get_shader_parameter即时能读到：ROOT287/288两个backend均将唯一unused world_size读为NIL，保存先行的冻结捕获则为Vector2；ROOT289挂载绘制后仍NIL，不能以直觉声称异步compile因果。此例只能由完整冻结shader SHA、唯一精确literal和固定尺寸独立重建expected单字段，错误非NIL显式值必须拒绝；saved及记录的类型/native bytes/SHA/text严格不变，不允许泛用NIL回退或从saved反填。ROOT290实际158／0 OS0覆盖58参数与类型／ULP等负例。
- ArrayMesh输入数学数组不等于surface_get_arrays存储数组：Godot会压缩重编码normal并自动生成tangent。ROOT294实际12独立plane/156slot中，数学→独立新ArrayMesh→stored与保存资源全部精确相等；12 normal及12 tangent与未经编码输入不同。应独立重建数学并走同native codec后比较所有slot类型/bytes和记录SHA，不省略normal/tangent、不从saved反填、不epsilon。该诊断自身仍OS1，因为测试误期望单世界6path而实际双世界12；原失败保留，新入口修完整性再跑，不以局部实际一致声称整轮PASS。

## 2026-10-09 · 模型音频候选：真实消费路径、原始样本与试听判断

- “林西音乐”不能仅按文件名判断：当前场景显式引用village_day_v4，AudioManager默认linxi_v6并不是相同消费路径。重制先核实际SceneScript与战斗引用，再保留用户认可的对照；仅改default不能完成全游戏替换。
- Stable Audio官方CLI保存PCM时会clip到±1；应独立保留解码器IEEE float原始样本，再按声明gain／fade导出试听。浮点超过unity不是已经发生硬截幅，整数满幅计数和原始幅度观察必须区分。本轮最终20WAV原始超1与PCM满幅均0，派生关系独立通过，不能把这一结果泛化到以后输出。
- PyAV声道优先与SciPy帧优先排列的RMS累加顺序可能相差1个Float64 ULP。先确认原／派生PCM与SHA，再按实际处理顺序独立重算元数据；保留首拒绝报告，不改音频、round或扩大epsilon来消除差异。
- 模型代码MIT不等于权重MIT：本轮Stable权重适用Community和Gemma，商业用途有登记与主体收入资格条件，公开可下载不证明已经获得商业资格。许可原文、模型revision及权重SHA应随候选保留。
- 民乐提示、模型OS0、非静音、峰值与处理字节通过不能代替武侠听感。音效最高RMS自动裁剪也不能证明选中了正确动作；完整原始输出应保留。BGM首尾15ms淡化只消除文件边缘点击，不是完成乐句无缝循环。详`docs/wuxia-audio-rework-20261009.md`。

## 2026-10-09 · 自主采样作曲：实测根音与原始浮点解码

- 用户随后否决v2的音乐连贯性。先分别测原OGG能量和实际曲：源稳定body无内部长gap，旧谱29.5/64拍休止、重复逐短音收尾、稀疏伴奏才是主要可见原因。修复须重写长乐句和实际连音演奏，不能仅叠echo或调响；技术波形通过不能覆盖用户听感否决。
- 连音同音区可取稳定实录body，按实测根音调音，语句内前后各60ms延展及120ms互补sin²/cos²衔接；body不足明确拒绝，不盲目重复拼接。持续真实筝伴奏与短呼吸是编配选择，RMS/覆盖率只说明能量与事件连续性，不能证明武侠风格或好听。用户要求只再试一次时，不自动扩更多版本。

- 不用音乐模型时可自主写谱/MIDI、演奏许可明确单音样本，保留每事件/真实音源map；不能把越南筝改名古琴/琵琶，Dizi标签也不保证真人演奏。MIDI不嵌采样时只交换谱，不能承诺自包含还原原混音。
- 乐器库音名八度有不同惯例：VCSL筝14源实际比首推定root高12semi。独立多窗自相关＋谐波量级排除2次谐波（D#3峰624Hz而基音312Hz），建立SHA绑定actualroot/细调后同谱NEW重渲染；保留旧FAIL/原曲，补低音区采样避免大幅降调损失音色。当前19实际map用于v2，不从文件名自证。
- OGG浮点解码可能微超1，导PCM16会硬截幅；本次旧便利WAV1文件2样本发生并保留，音乐直接解码原OGG float、最终增益后PCM安全。浮点>1与整数满幅区别记录；libsndfile/libav解码微差3.58e−7..5.96e−7不冒跨库逐位一致。
- 独立SMF/actualroot与声部之和/gain/fade/PCM检查可发现真实生产差异，不重写作曲算法、不以技术指标授武侠听感。未承诺size的Dizi源行不强造字段，核SHA并观察bytes，输出/谱/MIDI仍严格size＋SHA；旧KeyErrorFAIL、仅字节retry1、音高FAIL与最终v2分开归档。详音频专项文档。
## 2026-11-08 室内居中后的全局脚不是地图脚；采集回执只保一条

### 2026-11-11 主角动作：先重做姿态，再分开画面和测速

- 武器特效恢复须按腰佩、裁柄、背负、出鞘与隐藏暗器分开检查；粒子节点可见不保证缩至正常镜头后仍清晰。用正式消费者同姿态开关材质/粒子验证实际像素差异，并保留正常镜头看效果。柄部裁片坐标从新裁线算，不能沿用全鞘锚点；暗器不能当空手动作吞掉原显形。

- 用户否决慢走慢砍不能只调 time_scale：本轮原生制作蓄力、挥击、双手棍、拳掌和翻跃关键姿，再接实际装备/手指遮挡。复杂连招只改变表现，保留单一原生伤害事件与原技能多段处理。
- PNG 截图写盘会卡主线程，污染接敌计时，也会让 tween 跳过采样帧。截图作美术证据、无截图运行作时间/帧序证据，不强迫快动作逐帧截图后宣称真实速度。
- GDScript 条件表达式产生的普通数组不能直接假设满足 typed Array[int]；真实运行会报错，不能仅凭脚本解析通过。用明确兼容数组或逐项赋型。
- AI 条带不一定严格等格。要量实际透明间隔和完整剪影再配 AtlasTexture，尤其横向翻滚姿，不能把跨格身体切断；原图保留且不靠拉伸或局部重画伪造对齐。

### 2026-11-11 竹尾续项：深度范围、实际入口与章节接管

- 大图不能只给人物和物件都加“按脚排序”：若都被截到旧的 255 上限，南半图仍完全失去前后关系。应查实际深度跨度、祖先层和人物/物件同域；本轮仅猎径统一到 1024，不扩大成所有场景。
- 图上已有石阶时，分支入口应绑定阶前真实可走脚，不用默认卷轴、漂浮道具或穿山坐标代表传送。保留真实 G/Space 路径验证，移脚后同步返回脚。
- 同一逻辑章节资源可能被原生街区注册器替换，改 TRES 背景不等于实际生效。第二章晨市须从第一章村庄接管名单精确拆出，保持任务逻辑 ID 与 World 身份；屋内返程使用对应门前安全坐标。
- 新图截图里仍要检查角色职业：船夫原来误用女坐客图，功能检查不能发现这种身份错误。新镜头看到后修正，只复查受影响路线。

- 入口或回程比较先转换到所属场景 `world_container` 局部坐标；小地图宽度小于窗口时整个地图会被居中。不能用全局坐标差或原始资源目录数量推断进错地图。判定改造状态要走实际路由，旧兼容 TRES、测试图与未接候选不计现役。
- 采集成功已发 `item_picked_up`；继续保留它给背包显示与任务订阅者，移除另一路同义 toast。采空隐藏整个资源节点，近距鼠标不能再吃点击，原补充规则保持。

