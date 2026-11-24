# v15 分区生态与新增郊外（2026-10-03）

change-id: `world-v15-biomes-playable-outskirts`

## 用户增量与边界

用户指出正式地图中城市、门派仍集中，地表单一，希望增加草地、雪地、沙漠、岩石和竹林、树林、沼泽练级探索区。原文“学习”本轮按“雪地”理解，已向用户说明。

截图是现行正式 v14；独立 v15 的 12288×8192 分区源并未正式接入。不能把候选坐标表、素材图或编译成功当作玩家已能看到的改变。正式 v14 的底图、导航、接受目录及 `world_map_jianghu.tres` 保持；新版世界仍须完整导出、实际入口/导航/存档/视觉验收后才能切换。

## 制作决策

1. 沿用 v15 分区尺寸，不通过拉伸旧地表实现扩大。四城五派共九个核心地标在实际相机投影后的最短间距至少3072逻辑像素，必须包含茗雾；不能只检查未经投影的源坐标。建筑间还应有可辨识的旅行景观，而非同色空草坪。
2. 生态按地域连续过渡：北部寒岭与斑驳积雪、西北旱地/砂砾与裸岩、中原草甸/农田、荆襄树林、南部竹山、江南水网和东南沼泽。不宣称虚构门派位置是历史复原。
3. 雪地需有裸露岩脊与高低形态；竹林需能看出竹秆/冠层；湿地需有水、泥岸和自然芦草。只变地面颜色、使用少量小团植被或圆柱三角叶均不算最终美术通过。
4. 所有树、石、入口标志作为独立物件，绑定脚底阻挡、脚底Y排序与真实alpha局部遮挡；地面与水陆导航同源，不把整株树的外接矩形当成角色透明区。不得重新烘焙大量不可分析障碍。
5. 先新增三处独立可玩郊外：竹林、树林、沼泽。优先从现有村庄/城市相邻可走郊外接驳，使内容不必等待整张v15晋级；正式世界v14资源不因新增地方场景而换成未验收候选。

## 郊外玩法合同

依据 `2d-level-spatial-design.md`，新地方场景应有安全入口、互通回路、一处探索支路和清晰返回路标。该规范不用于强制无缝大地图套用房间式结构。依据 `reinforcement-feedback-systems.md`，重复练级收益沿用正常战斗经验、金钱和已有材料；探索材料点一次性领取，不无限发放永久属性。

三级梯度按现有敌人资源选定：竹林2～4级（村外凶兽/驿路劫匪/探子）、树林7～8级（矿谷悍匪/壮匪）、沼泽10～11级（芦荡私枭/伏击者）；最终推荐队伍等级还须与实际编队难度核对，不改已有敌人/武学数值、不新增大剧情。

稳定场景ID与普通场景接驳草案如下。表中站位尚待实际完整脚底及输入验证，并非入口验收结果：

| 新scene_id | 新原生资产目录 | 源场景/入口站位 | 玩法定位 |
|---|---|---|---|
| `openworld_v15_bamboo_outskirts` | `world_map_v15_outskirts/bamboo/` | 林西南坊(.55,.53) | 早期竹林练级与采集 |
| `openworld_v15_forest_outskirts` | `world_map_v15_outskirts/forest/` | 襄州矿谷(.80,.62) | 中期林间巡游与材料探索 |
| `openworld_v15_marsh_outskirts` | `world_map_v15_outskirts/marsh/` | 金陵芦荡(.72,.58) | 中高级湿地探索与练级 |

回程返回对应源入口安全脚点，不返回世界箭头或随机地图底部。接驳使用限定上述源场景的独立路标层，不修改冻结v14世界资源或旧地图布局。新郊外是普通地方Field，不冒充整张world v15；独立合同只在三个新增scene启用全脚底验证与物件局部alpha遮挡。

一次性材料点拟给药材、木材、布料各一份，使用现有 `DialogScript.blocked_story_flag` / `required_free_inventory_slots` 和正常对话副作用，不新增可绕过领取标记的快捷发奖命令。直接再次启动对话、重访或重载仍须拒绝重复领取。

每处必须是新独立地面/导航/摆放源，不允许给现有剧情地图换一个名字冒充新场景。入口与出口共用实际安全脚点；出生不能落在树根、桌面、屋顶或水面。采集点、入口路标有可见实体和正常交互。

## 写权与验收

- 美术：独立v15源/材质/限样构建、新郊外地面与物件资产、真实许可及原图登记。
- 系统：三处新SceneScript/地图资源、双向接驳、Encounter配置和仅限定新增场景的必要加载胶水。
- QA：独立测试/helper、完整17点脚底与回路、树根/水体负例、Space/鼠标双向入口、至少一条正常遭遇战→正常奖励→返回实图路径、实际截图。
- 主控：实际逐图审查、源/资源差异审查、是否接受地方场景和是否允许世界晋级，维护本文与进展。

GPU/重Godot任务串行安排；不得中断用户编辑器或其运行游戏。测试只使用隔离保存路径，启动前记录真实六份玩家存档SHA，不用旧基线推断用户没有自行存档。

## 当前状态

三个独立1536×1024地方场景已完成第一次完整技术捕获，仍未采用。竹38／林21／沼16个独立物件，三条回路及支路各不相同；第一次GPU因森林压缩纹理不能直接构建mip实际exit1，原产物逐SHA归档保留。仅解压后构建mip、叶片法线及真实森林水探针修正后，第二进程实际exit0并导出三份完整合同，结果位于 `game/build/world_v15_outskirts_retry1/result.json`，不是正式审批。

主控已实际逐张读取三份 `review_scene.png`，视觉仍FAIL：地面同质、竹叶硬绿、芦草几何感、水面像蓝染地面，路牌／采集容器缺乏细节。`outskirts_native_adoption.json` 维持 `NOT_ADOPTED`，普通游戏入口不开放；不能把文件已生成或源预测成功说成新增练级区已可玩。后续视觉返工使用独立v2前缀，旧四份捕获源及三场产物冻结供技术验收。

系统接入代码只限定三个新Field及三个源场景的独立路标层。南坊旧角色原点不等于可见脚底：入口合同明确拆为 `source_foot_pos` 和 `source_spawn_pos`，返回角色原点按实际正常精灵高度／缩放换算；已有feet=true源场景不扣同一偏移。Space、实体路标和箭头使用同一真实脚底矩形及完整净空门禁。新三场采用已有5px接触圆，完整17点鞋仍为10×6半径；不修改旧91地方场景的玩家形状。

主控串行实际检查：严格导入exit0／无ERROR；系统7脚本、三BGM加载与未采用拒绝检查exit0；新导航边界合成单测26项0失败、实际exit0；三合同预检334项0失败、实际exit0，输出 `game/build/world_map_v15_outskirts_qa/run_1354954/`。两次初始检查解析失败日志保留于 `game/build/outskirts_root_checks_20261003/`；单测／预检退出ObjectDB与作者Image加载告警保留。以上不含真实Field输入、战斗回程或GPU玩法验收，六份玩家存档在预检前后SHA／mtime保持。真实地方Field验收继续中，正式世界仍v14。

第一轮真实Field运行实际exit1，2198项／1失败，输出 `game/build/world_map_v15_outskirts_qa/run_1332831/`。三场回路与支路、821个真实移动采样、NPC前后排序均通过；自然遇敌以5次正常攻击胜利，获得8金／35经验并返回原脚点，世界版本仍14，六份玩家档SHA与mtime未变。唯一断言失败为沼泽返回路牌后方：正常抵达使角色改朝左，而原测试搜站位按旧朝向；实体前后排序与精确半透明像素并集检查通过，但实帧强alpha重叠为0，不能以软alpha3像素冒充通过。已只改测试为四方向真实2px输入定向再验证，待新运行；首轮退出资源仍占用ERROR也未被口头宣布解决。

竹林独立v2样本实际exit0，原地形／水陆／导航／RF字节保持，水面改善；主控实际读取后仍判FAIL，竹叶依然像硬纸片。没有据此重跑三图或正式采用。新核实原作者Yughues／Nobiax的[Free Bamboo v1](https://opengameart.org/content/free-bamboo-v1)为CC0，原包及作者许可、HTML和全部文件SHA已登记 `game/art/external/opengameart/yughues_bamboo_v1/SOURCE.json`；实际模型1440三角形、贴图512×512，不采用原预览宣称1024的数值。此时仅取得资产并准备原生导入检查，尚无游戏实渲或美术通过结论。

主控复核v15位置草案发现：原8核心间距约束漏掉茗雾，茗雾与金陵源锚点只约1392px。后续须将所有城市／可加入门派纳入实际投影间距审查，不能只用8点通过宣称全部拉开。正式坐标尚未变更。

第二轮完整local links实际exit1，2347项／24失败，输出 `game/build/world_map_v15_outskirts_qa/run_1365327/`，1104记录输入采样、1次自然胜利回程，六玩家档SHA／mtime保持。新四向正常输入alpha夹点复验没有失败。三旧source实际仅声明walkable_regions，并没有丢失的导航PNG；测试oracle错误无条件读空PNG造成9次拒绝与3个模式未执行级联，已在新helper内明确原生PNG与legacy多边形模式，旧非空损坏PNG仍拒绝，不改生产导航。另12项材料级联失败确由新缓存交互锁导致：首次满袋点击fallback后不离开范围，第二次正常实体点击被inflight锁拦；随后public play首次发奖不是click通过。系统窄修仅exact3 native／discovery_cache／本场action，记录真实dialog_started ID，仅同一dialog_ended释放这一项锁；不清其他trigger、不绕容量／一次性flag、不自动发奖。root实际系统7源重编译exit0，待重验。

第二轮verbose另定位退出在用资源为 `bgm_victory_v4_approved.wav`，正常公开音乐sting协程在最多8秒的timer内持有局部stream，stop_music_sting清player不等于协程已结束；保留退出ERROR，测试将自然有界等待并用WeakRef证明释放，不改生产音频。所有图仍未采用。

第三轮真实local links已结束，实际OS exit0／2499项0失败，输出 `game/build/world_map_v15_outskirts_qa/run_1373206/`，日志与16份执行源快照保存在 `game/build/outskirts_links_actual_retry2_20261003/`。三场×Space／实体路标／箭头共9条原入口→新图→准确原脚点返回均通过；三材料点原地满袋提示→腾空→第二次点击原实体领取恰好1份，play／play_at及隔离SaveManager重新载入后均不能重复发奖。1122真实移动采样、1次自然战斗胜利／正常奖励回原图，世界版本14、正常active_slot与六份真实启动枚举玩家存档SHA／mtime保持。root实际读取返回／材料／总结果，不以QA口头回报替代。

采样单测扩为40项，首次40／1是合成阻挡测试点的最右鞋已出原多边形，测试把“导航先拒绝”误期待为“物理阻挡”；只修合成点44→40，原断言和真实margin不改，第二次实际exit0／40项0失败，原失败保留。胜利WAV弱引用由true→false，公开stop后自然等待6774ms，无resource cache purge，第三轮退出没有ERROR；113次作者Image／ObjectDB WARNING及25个SceneTreeTimer等退出警告仍保留，不称零告警。此为新3图技术玩法验收，不是视觉采用／GPU游戏验收／整张v15通过。

新CC0竹模型原生导入与实际GPU原型均OS exit0，1440三角形／原UV与法线数组不变，三张512原TGA绑定，不重构作者几何。`game/build/world_v15_bamboo_external_probe/prototype/body.png` 与 `sparse_scene_actor_scale.png` 已由root实际读取，竹秆细叶疏密方向PASS；裸单色地面与T形路牌只是比例原型，不能称为已完成竹林场景。实际.91玩家叠帧为比例参照，不冒充真实Field输入截图。原图／ON-OFF阴影及raw重复一致，下一三场有限材质样本仍须逐图审查。

九城派地域source v4实际CPU预测已结束，OS exit0，结果 `game/build/world_map_v15_geography_v4/result.json`（SHA B944A63C70B2348F820EFAF573AF05D0330DF533B3D322EEAD331A0A08BE9FA1）。保持12288×8192／64块画布，不拉伸旧地图；茗雾source脚点移至(11100,7900)，凌月至(11500,4550)，对应三道路末段、竹丘／茶庄生态随动，其他地标ID／目标未变。九城派按真实RF分片仿射高度投影的**门口锚点**最近距3311.656px（金陵／茗雾），达到3072px；27条路12480个中心×17鞋与16source锚点支持预测通过。桥交点重新枚举为5座（不是沿用旧6个可能悬空物件）。root实际读源码与结果，未将这些预测视为实图入口／GPU验收；12张legacy门口UV尚待实际测量，不能冒称缩略建筑中心间距已通过。新源 `world_map_v15_source_geography_v4.gd` 冻结SHA04D410AFEA9DD395EE5CE997075804B25559E854D11B0A3A78ACD5B646D88A0A，正式838380FD地图仍不变。

## 后续有限视觉复核：v3 保留，不采用

三个独立v3阶段已串行实际GPU捕获，竹／林／沼均OS exit0，31／23／6物件，原帧、本体和ON/OFF阴影重复一致；每阶段15条作者Image载图警告保留，没有SCRIPT／SHADER／ERROR／RID。root实际逐张读取以下原图，而非仅听取回报：

| 阶段 | `game/build/world_v15_outskirts_visual_v3/` 下原图 | SHA256 | 判定 |
|---|---|---|---|
| 竹 | `bamboo/review_scene.png` | `3F5F5E5E38A2AD8D8F78B4C783EDB2ED920664A382F84C76C8D8CB008A168B41` | 真竹改善；地面单一、中央空、两竹冠跨上沿，整场FAIL |
| 林 | `forest/review_scene.png` | `52695FA012346AE7AB9ACA3B54B0BE95CD300521D3AB59BADF870906A3F52FB2` | 真树成立；大面积碎石林土、黄草路肩，生态FAIL |
| 沼 | `marsh/review_scene.png` | `EA8C193E4F4DA1841BEC935D014D03D493826A4FB18DA964CDEA3093B06C4C8B` | 两个规则水盘与四株低草不能构成南泽，FAIL |

v3四源冻结：source `48284509…0B400`、surface `B878716D…E0838`、vegetation `032A4832…9A23F`、builder `51A3E6BE…07597`，完整SHA绑定在每阶段result的executed_source_graph。root实读注册forest_ground_04／brown_mud_03／leafy_grass原始diff：前者本身是石屑林土，不可只改色后声称腐殖落叶；已登记leafy_grass真实2m、CC0落叶低草材质尚未参与v3。下一独立v4优先统一ALBEDO／ARM／normal生态权重，增加落叶低草、根际林土和水岸泥，道路不用黄草条。两株竹仅改实测摆位，不裁作者alpha；湿地改与左右边界相连的自然浅湾和安全岸带低草，保持回路并重新计算RF／导航，不能只画水域。v4此时只授权source-only，不据v3旧技术或2499通过自动采用新物件。

门户只读核查纠正旧forecast的统计：当前16项为5张新门派建筑+11张legacy，并非4+12；semantics仅三新图，另两新门派及11legacy共13项尚无完整实测绑定。独立门户量测应绑定真实source SHA、像素门槛、点击门面及实际缩略转换；关闭城门以门前石阶交互，不要求穿透门扇。此统计不构成实际入口验收，正式v14及NOT_ADOPTED保持。

## v4 有限源与实渲：仍未采用

root实际审v3→v4代码差异及三份source_forecast：471／511／490完整17鞋中心、返回脚点(768,915.293518)、支路均0失败；实际check-only和CPU进程均exit0／stderr空。物件30／23／45：两株竹改摆位后其中02_12触及原90px道路保留带而被排除，另一株00_12南移32px保留；不声称两株均保留。湿地按真实bank／高度／道路净空筛选43株独立低草，不冒充高芦苇，左右开放湾形RF／水陆／导航同源。

仅竹v4获准实际GPU，owned62244实际exit0。root实际读取 `game/build/world_v15_outskirts_visual_v4/bamboo/review_scene.png`，SHA `0C64247E18E5904BF6971CB200CC30A93007F27CB0E8ED352F7EE632776F0764`，泥路和落叶地面可读性改善、所有竹冠最北21.71px不再跨顶；但粉绿细噪均一、规则池塘和中央空构图仍视觉FAIL。五原生本体和ground ON/OFF原帧重复精确一致，体外暗化706644px不代表整场艺术通过。18条作者Image告警保留，无SCRIPT／SHADER／ERROR／RID；林／沼v4没有GPU捕获，不宣称实际画面已合格。四源冻结CD829E42／71EE4453／032A4832／A4780A92，完整SHA见 `game/build/world_v15_outskirts_visual_v4/limited_review.md`，旧v3四源逐SHA保持。

三郊外运行默认仍绑定旧候选目录，2499／0只证明那组冻结产物。v4 `build/` 产物需要显式候选根同步materialize地面、导航、物件、RF／相机合同；只换contract而保留旧SceneScript背景／walk会混用版本，必须拒绝。根转换不构成采用，更不能覆盖NOT_ADOPTED或以旧2499充当新v4玩法验收。正式大地图原SHA `838380FDB05D08B4B521D92EFB12A13369358090740DC5C7D4CB7C9EC6F4C015` 仍不变。

16门户像素量测已写独立 `game/data/maps/world_map_v15_portal_measurements_v1.json`。原图完整17鞋样本按运行缩略比例逆算（如洛阳21.333×12.8源像素），源alpha仅证明像素支撑，不替代导航。root本轮实际逐张读取四城、五派及其余七原图，门前阶／围栏缺口／渡口陆侧／峡口位置方向成立；原图与测量仍须绑定SHA，关闭汴州／金陵门扇不得当可穿。凌月原RGBA边缘可见红黄碎边，实际背景缩略合成仍需复审。全部world导航、实体碰撞和正常Space／鼠标入口仍NOT_RUN、runtime_eligible=false，禁止量测表直接发布。

## 候选目录与内存隔离轻检：不替代 Field 验收

新helper只在 `--outskirts-candidate-preview --outskirts-visual-v4` 同时存在时选择固定v4目录；单visual旗拒绝，普通运行仍受NOT_ADOPTED阻止。地面、导航、独立物件、源路牌及RF／mesh／camera合同必须同根且SHA一致，不回退混用旧地表。

root首次四模式实际检查中，默认／单visual／双旗各24项0失败、OS0；旧candidate-preview实际OS1／123项，三场“原资源壳被修改”失败，日志原样保留。SceneScript的 `duplicate(true)` 对外部layout仍共享引用：后续四个独立真实进程均打印三图 `same_layout=true, same_objects_array=true`，不能靠深复制名称推断隔离。窄修明确复制layout和其所有STORAGE数组／字典，新增场景与三旧source路牌两条路径使用同一隔离副本；旧场景文件不改。

最终helper SHA `6DC16FE0804C1B47D1BC1EEB21C1F902068AE682D2308F55C54D42F4DC2042D4`，checker SHA `395487DE98EEC8E58A4BEB9D5D3105F353C9AF5D982202D5DCD21BD55D7B3B5A`。root串行重跑：默认90／0、单visual90／0、双旗90／0且拒绝三未就绪v4、旧候选282／0且绑定三场，四Godot实际OS exit0。源layout全部持久化字段快照不变，修改数组及layout引用独立、Router导航不变。日志 `game/build/outskirts_v4_binding_checks_20261003/*_retry1.stdout.log`／stderr；前三模式WARNING数1／1／0，旧候选91条Image等WARNING保留，无ERROR／SCRIPT ERROR／SHADER ERROR。v4拒绝不是Field或画面通过，本轮不执行导入、GPU、64块构建或新Field验收。旧2499仅属于之前冻结执行版本，不能继承到新隔离helper。

16门口独立CPU校验由root实际复跑2030项通过，源审查与未运行导航／输入状态保持。正式地图SHA838380FD、adoption SHA203C9F08及六份玩家档SHA／mtime在轻检前后保持。
