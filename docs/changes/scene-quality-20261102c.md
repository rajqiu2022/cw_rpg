# 2026-11-02c 矮墙、地图图标、PC显示与切图准备

状态：本轮局部正式合入，可重新启动游戏试玩；不能宣称十项全部完成。第3全人物高清与第9总加载耗时仍开放。只测新增域，未重跑旧22方向或真实存档矩阵。

## 已写入正式资源

- 六张现役洛阳地图共28个孤立小墙owner退出；27组相关solid随退。真正长院界、门楼和城墙保留。古寺零solid的装饰残墙一并撤图，不冒新增物理穿越信用。
- Civic真实正地面补`(620,2264,4904,40)`，不是只涂一个可走颜色。原两街块间40像素漏带与相应visual surface同源。
- `docks_garden/a`移到`(96,1216)`、回脚`(200,1216)`，原南市口保留；旧`(512,1840)`存retired。17392已真Space进园、D10后Space返原200/1216，无中间公开near。
- 独立MapIconRuntime：城内只显示功能点/区域出口，普通门不画；无单图标底框或字；World城市、村庄、郊外、门派、渡口分类，实际到达记访问，未到灰色、已到彩色。只去掉标签的“空格”前缀，不改按键或路由。
- 独立PCSpriteViewRuntime：PC线性显示不是高清重画；已有原生808像素农人下向idle原字节接入。其它贴图没有伪造高清。

## 新素材与未完部分

内置image_gen生成6格透明地图图标，1536×1024，RAW/runtime字节同；无API fallback、实际模型/费用未暴露记null。提示词在`prompts/minimap_icons_20261102c/`。

主角首批4方向合表实出1254方/1774×887，身体不足320或格不整，拒绝采用；原图保留。后继down样板1536×1024：idle4×1人体458–460，walk4×2人体426–443，灰雾为alpha0隐藏RGB、主体外8px无alpha>2，未改PNG。Idle仅清晰度/稳定性局部接受；walk还待真实短循环，不能把8个不同hash冒完整步态通过。其余方向/武器、全NPC高清未完成。

## 实际检查与失败保留

- 纯数据publisher实际140404自然0；stdout152/0、result构造时150/0，28owner/完整typed逆/3张NAV RGBA逆。原payload不覆盖。
- UI135132虽打印13/0但静态preload有GameState编译错误，整体失败保留；QA延后load后85956自然0、13/0。
- PC首8/4与residual2/2保留；第二轮fixture避开真实交互圈，2/0，unique12通过；18个原状态字段同、8脚样本误差小于0.001。只验证农人adapter，非全角色高清。
- 切图基线136480自然0、6/0：真Space一腿，首Loading6186ms，可操作15480ms、退屏后最大帧5861ms。
- 141076新包Culture拒：5新edge路径不符既有`res://build/luoyang_`范围。精合法路径后继21源，旧OWNED/旧edge保，不松guard。
- 127508新包Artisan拒`FINISH_A2_FIXED_PUBLISHED_PAYLOAD`。精换F419598B包pin并退出8已撤墙声明，原136/118地面/18patch/base139与实际lease/mask校验保；23叶有限后继。
- 73400、133776均自然0、6/0，Artisan接入成功且首Loading74/69ms，但退屏后仍4832/4953ms长帧，**延迟整改未完成**。不能据6/0打印宣称性能目标通过。
- typed-vs-call隐藏Screen诊断自然0，两种调用override均1；已否决“强类型绕过override”的猜测，无地图旅行。

## 保护边界

Root唯一实际引擎；只用隔离APPDATA/LOCALAPPDATA并尽早暂停checkpoint。未读、hash、反序列化、恢复或回写真实存档；未执行171 metadata矩阵。Godot编辑器保留。旧退出纹理ERROR/ObjectDB警告及本轮全部失败日志保留。39初接、合法edge21、material23各阶段全文备份/精逆链保留；后两批与前批有交集，不能把阶段数相加冒唯一改动文件数。

## 最终有限结果与剩余项

- 128212误将南市脚传衙门身份，3/1失败保；残余只改fixture logical，真实坐标、碰撞与键输入不改。34956自然1、27/1；已通过同实例S/W跨40px漏带、W跨撤墙域，正常府街/码头两图Root亲看接受墙清理和纯图标本域。其后重复默认码头bootstrap的35秒等待失败保，不把此前27项翻为整场成功。
- 99776单次公开脚116/1216正确、Field complete/四口/mini就绪但尾准备未在35秒内结束，6/1保留。功能残余17392使用65秒就绪上限，同时保留35秒性能记录与180秒总限；自然0、8/0、6真实Input、新口两方向精到点。该次无>35单等待，但报告`performance_passed=false`，不得抹去冷载旧失败或冒整体速度达标。
- 6532自然0、38/0；仅古寺与World两张剩余图，古寺残墙消失获本域接受。World首图灰标太黑，Root明确拒其对比度，功能信用不转ART。
- 新图标按原生PNG六格alpha≥24只读审计边界+2px取图，不改PNG；未到灰shader只采样一次，并以vertex tint保HUD透明度，避免旧fragment COLOR二乘变黑。正式overlay`9645111F…`。69384自然0、35/0，只新增一张World正常图，灰态分类/无框无字对比度Root有限接受。洛阳彩标被人物头像部分遮挡，不冒全部22地点彩态逐图接受；旧GM与World mini重叠仍是遗留，未在此项改HUD布局。
- 137624自然0、6/0，首次Loading95.022ms；隐藏25574.465ms/可操作25574.689ms，后最大帧31.162ms。实际null安装窗按固定pair/Router身份保屏，旧manager自然reset，真实目标complete和入口/mini完成后退屏。**首屏/可操作时机仅此配对路线通过，冷加载总25.6秒与屏内10.5秒长帧仍未优化完成；不授全World/所有普通门同等延迟结果。**
- Root高清对照131536生成正常1×/2×两图、一次8相位，无正式接线。RESULT后清理等待未自然退出，Root核验命令行/父PID后仅停自有131536，console45964随后退出1；不能记自然0或全部动作通过。原图/候选/失败历史保留，主角不以单方向样板上线造成转身清晰度跳变。

唯一有限末核`E3A1AF68…` PASS：1047检查/0错，CityNav102+Art60联合146键/145非project文件首末同，45个最新授权旧目标按所有阶段全文逆链核；project仅两autoload整行删除后精回before；六typed包/三NAV RGBA完整逆，28视觉owner/27solid精退。0真实档内容/171矩阵。此后仅独立新UI overlay对比度后继，不触145冻结源。

### 素材保存与提示词

本轮全部由内置image_gen出图，无CLI/API fallback。实际模型/费用工具未公开，metadata记null，不能编造价格。

- 采用图标：[location_atlas.png](F:/Code/RPG_GAME/game/art/ui/minimap_icons_20261102c/location_atlas.png)，原生1536×1024，RAW同字节，SHA D2786DAA。
- 图标提示词：[location_atlas.txt](F:/Code/RPG_GAME/prompts/minimap_icons_20261102c/location_atlas.txt)。
- 高清下向候选原图位于`assets/raw/sprite/pc_hero_hd_native1536_20261102c/`，未接主角；[对照图](F:/Code/RPG_GAME/game/build/pc_sprite_view_20261102c_grid_candidate01/render_preview/zoom2_contact4.png)。
- 候选提示词：[idle](F:/Code/RPG_GAME/prompts/pc_hero_hd_native1536_20261102c/down_idle_v3.txt)、[walk](F:/Code/RPG_GAME/prompts/pc_hero_hd_native1536_20261102c/down_walk_v3.txt)。原失败合表也保，未放大或重写PNG。

其后独立新UI/PC/两PNG共5叶精SHA末核通过，0写；进程只剩原编辑器51856，Root自有引擎全退。没有重新执行145冻源或171矩阵。

本轮停止重复验证，下一实际工作是全方向/动作一致的PC高清人物和总加载关键路径减负；不是要求用户继续指出同类矮墙才处理。
