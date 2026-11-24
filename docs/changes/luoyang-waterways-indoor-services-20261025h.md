# 洛阳河桥、沿河建筑与室内店主服务（2026-10-25h）

状态：25h精28已正式合入；园林实桥、四店主交互、三商店打开返回及客栈收费恢复已通过有限实机验收，整城未完成。用户明确要求河道/桥梁、建筑风格体量变化、当铺/铁匠/药铺/客栈室内NPC及打尖住宿；住宿恢复所有生命内力。用户已选择收费并授权助手确定金额。

## 本轮目标与边界

1. 四店有身份匹配的实体、肖像/对白与可操作服务：补原空客栈/当铺/药铺三人，保留原铁匠唯一ID并补交易，不盲加第二铁匠。保持原十二室内native/storage/家具/门返脚，新增source-bound NPC投影与对话准入需同步认证，不能临时append绕过来源合同。
2. 客栈：打尖5金，逐队员生命/内力各恢复`max(1,floor(max*.25))`并clamp；住宿20金，全队生命/内力恢复各自当前最大值。满值无扣费；确认显示价格与效果，拒绝/余额不足/失效owner无副作用，同请求不二扣、合法新会话可再次消费。只更新既有hp/mp/金钱，不重算属性、不变存档schema。
3. 河桥：以既有Docks↔Garden↔Estate沿河空间落地真实桥梁和不同体量沿河建筑，不能在南市现有门前硬塞水。当前Garden桥明确是`scenic_bridge_no_walk_support=true`且有真实水体阻挡；须新设计通桥结构、栏杆/桥面/两岸衔接和局部导航，而非翻开关冒可通行。world24d未正式，不混用其成绩。

## 原因与实现归属

System/QA已查：客栈/当铺/药铺当前来源`npc_policy`明确`original_npc_definition_raw=[]`，不是通用spawn失效；铁匠旧有1人但只有闲聊。现scripts/DialogPlayer/Router没有住宿动作或收费标准，不声称已有服务。System独写G/Field+新服务helper/dialog/shop候选；Source独写来源闭包，QA独写测试，Root唯一引擎/导入/部署。室内菜单尽量复用现DialogPlayer/商店与EventBus，不扩改Router/DP/GameState。

Fresh7B26D75E以25g末6E8D为基：2121含UI/15save精ticks/148全文备/8媒体全零差，formal32+Router共33固定正确，仅editor51856。继续保编辑器、不私停游戏或用户进程；若用户运行游戏，先完成离线内容，实机前说明具体冲突。

## 验收

- 真NPC交互打开正确店名/库存的ShopUI，不直接调go_shop冒互动可达；室内人站可达位置，柜台不堵出口，cold/warm身份一致。
- 独立纯服务矩阵与有限客栈实机：拒绝/不足金/满值/确认恢复/同请求重放/换owner/合法重开，不写用户存档。
- 新桥两岸实际INPUT穿越、栏杆与水域负控；河岸与桥头真实支持，建筑等比、成人门高、主支巷分级。只新变化域，不复25g/旧四城全几何或四collector。
- 实际来源/旧全文备/15save精ticks保护，原FAIL全保。不得用QA整体耗时当加载指标或以局部成功冒整城完成。

## 历史实施检查点（以下未正式状态仅指当时）

- 服务纯函数实际16112自然0，20个独立用例、28检查0失败、59ms；5/20费用、全队恢复/向下取整与clamp、满值不收费、余额不足及非法数据无副作用。只函数组件成绩，不冒真实UI服务已通；1个ObjectDB退出warning保留。
- 新客栈掌柜肖像已用内置imagegen唯一生成并完整复制，`game/art/characters/portraits/luoyang_services_20261025h/portrait_innkeeper_v1.png`，原PNG C544C5CC；提示词`prompts/luoyang_indoor_services_20261025h/innkeeper_portrait_v2_textonly.txt`。成熟短须、蓝衣米围裙与原掌柜精灵配套，未改任何原图像素。导入与正式引用仍待。
- Garden原生出版123284整体FAIL保留：2692420检查止于`FULL_TYPED_NATIVE_STORAGE_READBACK`。之前桥raw/import/direct的alpha及可见RGB、375975闭合桥面像素、真实water-minus-deck两块、D552独立RGBA期待、6条新路线/4NPC/2门户及781176变化外域零差均通过；21128隐藏/边缘RGB差异明确分列，未谎称整图RGBA同。新scene/layout/walk/front-region已写到build，packet尚未完成，不部署、不重跑已过几何；只诊断typed存储读回残余。实际6脚本load解析90208自然0，0实例方法；旧FAIL与警告均保留。
- 存储残余121476严格失败揭示metadata中的`physics_pieces`经ResourceSaver成为untyped Array（期待typed_builtin35、实际0），原完整layout已同。新04只把该元数据容器在源表达式里显式构造为untyped Array，两项仍是原PackedVector2Array、值序/物理不变；115844自然0/919ms，Scene与layout全部typed严格同，仅补ABSENT packet，四已出版原生文件未改。两个原FAIL保留，不重桥像素/路线/栅格。
- 客栈头像隔离4696自然0/83检查0/153ms，全1254²原RGBA与raw/import/direct一致；Garden新walk隔离72424自然0/80检查0/139ms，全3072×2048 D552一致。各23参数/mip0/detect0；Root仅晋升各两NEW媒体叶，没有主工程导入/PNG处理。三NEW ShopDef也由候选精SHA复制，尚不代表入口接线完成。
- 服务解析首02在任何candidate load前因铁匠SHA抄成66位而整体自然2，原FAIL保；03仅纠正该输入字面，92432自然0/45检查0/1358ms，3GD与3ShopDef均完成加载/可实例化检查，0业务执行/0Field。195个合同叶和三实际资源SHA均另核64hex，不改资源以迁就错误期待。
- Garden四GD解析已过；唯一52272原生GPU概览自然0/259检查0/2112ms。Root与QA各看同一原图EE5FA977，有限准完整石桥、两岸落地、桥下连续水、观水亭与完整二层茶楼；大草地/硬铺路接缝/岸线与整区密度未准。保留7个退出纹理ERROR，不冒clean。有限Field试运行许可2B897810明确`actual_Field_pass=false`，下一只真INPUT跨桥和两水域负控、0重图。
- 原28正式目标已全文件精备到`game/build/luoyang_city_revision_20261025h_root01/exact28_old_backup/`，receipt E173E63F；旧148备份保持。统一来源和正式部署仍在收尾，不以BUILD冒玩家已经可见。

## 正式合入及实机检查

Stage05 EBE06A49已通过3323来源首末固定、精28=14GD/14JSON、10owned/176proof/原16上限，保原170边不shortcut。Root以apply_patch写14GD、机械精copy14JSON，actual7761350B；旧176全文备/UI/15save/旧媒体保护通过。四独立期待988/1372/1866/1926、Family458。Stage01缺NG候选bytes、02误把原inline数组合同按标准enc回写期待、03误把3个既有native artifact重复投影当分类、04把两个外部控制索引错误新加进两个Bmanifest，四次FAIL均保；仅源式元事实/严格raw逆/schema域及错误新加键纠正，未关门禁或改几何，05前完整只读预检已覆盖全部gate至flush前。

前置guard3F3886A0：2121固定域仅28授权差及两个任务登记追加，余项/15save精ticks/176备/旧8媒体全正确，新inn3媒体+Garden2+3ShopDef另精固定。没有主工程import、用户进程操作或存档写入。

Garden98276实际自然0/216检查0/7891ms（QA整段而非加载）：同四真实对象与Family458自然FIRST/FINAL，165真INPUT从880,976经1536,976到2192,976，171Physics/2875mask；北南两指定水点均命中新水体且mask禁行；桥base地层z-17、rail原Atlas前景z145。0PNG继承唯一原生概览，不重其它五路/旧几何。结果25244B16；7旧退出ERROR+1Image warning非clean，停止该桥复验。

首服务71508整体自然1/258检查2失败/7149ms：客栈8源/实体/主角开场→掌柜菜单→告辞完整通过，当铺91源/实体/主角开场→掌柜菜单通过，止于截图QA错误硬要求Camera2D（此1536×1024单屏房按原Field设计本来静态居中、无相机）。0图/尚未进入ShopUI，不称服务整体完成；只修源式静态画面期待、补剩余三店和客栈费用实测，不改生产镜头迁就QA。

### 最终有限实机结果

剩余三商店110632_2804自然0/294检查0/14973ms，结果209F4C18：当铺、药铺、原唯一铁匠均经真实Space/数字键打开对应ShopUI，再用实际关闭按钮回到同室、同来源与合法原记忆脚位；允许原Router重建Field，不硬要求同owner。继承71508已过客栈菜单，不重放纯20用例。唯一原图`game/build/luoyang_city_revision_20261025h_qa01/service_UI_ready/remaining02/shops_output/110632_2804/01_pawn_keeper_real_menu.png`，Root实看掌柜实体与同人肖像可辨、菜单可读；未实际买卖，不冒全部库存经济验收。

客栈20988_2784自然0/351检查0/9581ms，结果7ED4AB34：全部正向消费经真实交互及确认输入，打尖5金/住宿20金、取消/余额不足/全满不扣、同请求重放无二扣、新会话可再次消费、确认前当前上限/余额变化重新校验、全队含hp0同伴恢复及HUD/反馈均过。真实切往铁匠室后旧住宿请求失效；私有finish仅负控，不冒正向交互。测试进程内金钱/属性/队伍均复原，0存档写入。唯一原图`game/build/luoyang_city_revision_20261025h_qa01/service_UI_ready/remaining02/inn_output/20988_2784/02_inn_keeper_actual_rest_price_confirmation.png`，Root实看20金/全队恢复说明与新掌柜肖像。两个QA整段耗时不是房间或城图加载耗时；各7旧退出纹理ERROR、0SCRIPT，非clean。

最终保护66D2557B：2121固定域/28授权变更、15save精ticks、176全文备、新旧媒体/三ShopDef/四map/Family与前3F3886A0全核正确，0失败；没有关闭用户编辑器/进程、主工程重导入或重跑旧几何/四collector。已通过组件停止复验。待办仍为余片区密度、街墙后体与生活NPC，world24d水桥并未由Garden本地桥替换；不授整城示例级艺术、全区首入或重复加载10秒目标。

QA独立看同两原图：当铺栅旁掌柜可见、客栈实体与成熟新画像匹配，20金说明清楚；客栈快速连续测试图顶部旧黄色反馈同位叠字，保留为ART瑕疵，不授反馈排版完全合格，不因功能通过掩盖。该轮未改通用toast或重跑实机。

独立Stage审计旧377/8整体FAIL保留：369已过组件不重跑，新2694B865只核剩余10项/0失败（旧DB48到已批准05b的3个candidate后继、四map仅1/1/1/3标量严格替换、Family458从固定文件而非不存在descriptor.value读取），0引擎/collector/正式写。没有把旧测试预期错误算生产故障。

资源索引精确条目已更新：Root读并apply单hunk B1D60755，生成器B0571BF2→C2DFDB9C完整逆过；运行原生成器重建`docs/resource-reuse-index.md`，1784文本来源扫描期间SHA同、0显式缺失。条目明确三Shop只验打开/关闭/返回，未实际交易；新肖像由内置imagegen的generate模式产生，提示词及工程PNG路径见上方，未对原像素编辑。原48FE候选的“买卖已验”错误措辞保留追溯而未部署。整个项目脏工作区无关修改全部保持，未创建提交。
