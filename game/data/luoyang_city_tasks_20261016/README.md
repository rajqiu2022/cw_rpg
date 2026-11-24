# 洛阳第五层任务投影候选 · 2026-10-16

当前仅 NEW helper＋业务数据＋20 份对白；未接 Field、未运行引擎，不授正式可玩、Physics 或新 NPC 艺术通过。

## 采用方式（SYSTEM 串行接线）

唯一入口：
`project(scene: SceneScript, flags: Dictionary, quest_states: Dictionary, input_interactions: Array) -> Dictionary`。

在 Field 已持有完整 C/R source-proven Scene，并已将 legacy hotspots 转成 interaction 字典之后、生成物件/碰撞/NPC/热区之前调用。返回：
- 成功：`{ok:true, matched:bool, error:"", npcs:Array, visual_objects:Array, interactions:Array, receipt:Dictionary}`。
- 拒绝：`{ok:false, matched:true, error:String}`。不得把拒绝当成空数组成功，亦不得静默启用旧任务 action；应由集成者显式记录/拒绝本任务初始化。
- 非目标 Scene 返回独立副本、matched=false。

只替换局部 render/interaction/NPC 数组；`_current_scene` 必须仍为原证明对象，不把投影资源/数组作为 C 原始精确来源。portals、body、mask、solids、已验证 record、BGM 和保存全部不改。
NPC 数组投影后再附加原 BountyManager NPC；纸匠不要再被 NPC catalog 默认对白覆盖。

所有属于 `luoyang_city_tasks_20261016/` 的 NPC 对话及 field action 入口，启动前调用：
`authorize_dialog(dialog_id: String, flags: Dictionary, quest_states: Dictionary) -> bool`。
非本 namespace 返回 true；本 namespace 未知/不合阶段/源变化返回 false。
`owns_dialog` 和 `stages` 均不写全局；flags/QuestManager.states 传当前值快照。
已有 Dialogue required/blocked flag 同时回挡过时动作，但不能用它替代 active quest 与前缀链授权。

## 最窄业务

漕运：漕工头领接受 → 老漕卒两段证词 → 原废仓泥痕两次明确调查 → 回漕工头领。旧箱退为普通 cargo：原图/原 solid 不动，无任务提示、发光、动作、证物或奖励。真正泥痕原来就是 nonblocking，因此状态显隐不制造隐形墙，也不减旧导航门禁。

纸贵：左明远接受 → 原故事已提到的老纸匠两段区域提示 → 原古寺废纸坊热点找料 → 回左明远。旧古寺点 .38/.34 是 legacy bodycenter，不冒 city feet。新增纸匠候选脚点1320/1290、侧向 approach1240/1290 来自现有纸摊前沿语义，每次 project 都先用原 C.safe_body 全875/多边形和17 mask samples 拒不安全；没有 prepare/坐标修补。
纸坊发现只写材料旗标，原下篇/原 secret quest 接取和两原任务奖励都移到回报时，数值/条款不变。旧 QuestDef 文件未改。

老漕卒保原“含嘉旧刃”的未接/进行/完成分支，修安全接受节点但不改该任务奖励或目标；诗会的一次性行为完全不动。

## 阶段和幂等

started flag 只在选择“接受委托”后前进的 accepted 节点写，offer 节点没有副作用，选择“暂且不接”不推进。NPC 常驻；进行、回报、完成后对白独立。
码头定位与取证是不同节点/不同旗标；未接、未听证词、已取证、已完成都没有任务热区或泥痕图。纸坊同样需 active＋hint，取料后消失。
回报脚本的 completed flag/backstop 与原 QuestManager 一次完成奖励共同保证不重复；不要直接调原旧 turnin，后者仍保留为历史来源。

## 来源与边界

overlay.json 固定 SHA 写在 helper，source_pins 绑定旧 NPC/任务/对白资料、两复用人物资产与全部新对白。城市再核 R metadata/对应 C record、原 NPC 数量与指定 NPC/action/flag/坐标身份。
helper 不改旧 canonical、author、manifest、导入、C/R/Router/LM/Field、玩家保存或存档 schema。不生成图片/声音，不调用网络/API。新层后续由 ROOT 审批后单独接线；新增 source 应加入驻留 epoch，不能让热改后旧驻留对象冒充新来源。

验收范围在 acceptance.json，它是规格不是执行结果。ROOT 只需两个任务阶段短关键及一个新增纸匠可达点；不全六，不授本轮全城艺术完成。

