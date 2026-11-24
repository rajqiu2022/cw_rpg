# 洛阳进城回归修复

change-id: luoyang-entry-regression-20261029l

## 目标与证据

用户在三城接入后反馈“洛阳城又进不去”。本轮只恢复旧World→洛阳城门入口，不改城内布局、人物、剧情、状态或存档，不撤销赤岩/沙漠/岚溪接线。

用户原日志已先保存为`game/build/luoyang_entry_regression_20261029l_root01/user_godot_before_ACTUAL.log`，SHA369C9036E37835684DC554E7B1012DC3AAAF8E546A393B1247D3046BCEA73F93；第49行实际报`Cultural resident projection refused: CULTURE_X_SOURCE_CHANGED:res://scripts/autoload/scene_router.gd`。未启动新引擎去重复已确认失败。

当前Router5D6AAA78、Field E22564EC与上批最终guard一致，不是编辑器改了末尾空行或用户存档问题。文化Coordinator.readiness原26项直SHA校验中仅Router一项仍锁D25DA6FE，与EX来源后继表独立。另发现EX后两Router边的不可变snapshot目录为jinling_city/three_towns，违反原Authority.edge_valid只允许`res://build/luoyang_`前缀，旧9目标机械逆校验并未验证该运行时准入条件；上轮三城成功不代表洛阳旧入口通过。

## 范围和最小方案

System唯一候选写权，Root唯一合入/引擎；QA仅准备修后单腿World原洛阳门户实际Space→城门/短走/一图。保存当前来源、171登记save精确事实和编辑器51856；不重三城、楼梯、桥、全城业务矩阵。

- Authority、Router、Field、文化runtime_contract及原三城均保持。
- 两个实际不可变Router快照以全字节相同副本发布到合法luoyang_专用目录；仅修必要边的snapshot引用并增加精确来源键，原快照与旧键保历史，不放宽规则。
- Coordinator仅对精确Router路径使用既有AP_NPC._source_matches，依原闭集和逐边完整逆校验承认已批准后继；其余25项继续严格SHA相等。
- Coordinator与EX/index、Gate/Docks/Quarters必要来源后继封包；不加未知路径允许或current-disk fallback。

## 状态

已修复并完成本批唯一单腿实机。9目标精合：Coordinator50500E8D、EX56D19060及4索引/3必要manifest；Router5D6AAA78、Field E22564EC、Authority、文化runtime_contract及三城模块完全未改。EX保原302来源后增3键至305，Router13边数量不变，仅两实际快照的3处引用换为合法同字节副本；Coordinator39→40完整逆边。原用户失败与上轮验收不足均保留，不冒旧9机械检查已授洛阳可入。

Root headless准入33236自然0、21检查/0失败：13条Router边均经实际edge_valid逐条验证，D25DA6FE历史pin完整承认、未知SHA仍拒、原文化合同readiness和AP source_paths恢复。0输入/0场景实例化；ObjectDB退出warning保留。

Root唯一修后实机127460自然0、86检查/0失败、5真实输入ticks、总17.346秒：公开World原洛阳门脚setup(4000,2594.4912)，唯一原门can_enter后真实Space进`ch4_s0_luoyang_gate`，落脚1536,1860，D4ticks真实走32px至1568,1860；同Player/队伍/HP/MP/金钱保持，一张正常1920×1080原图Root已看。Space起至截图11.091秒，不冒整个洛阳10秒加载目标。无文化来源拒绝或SCRIPT ERROR，退出仍有既有7条纹理/RenderingServer ERROR，非空stderr。不重三城或全城矩阵。

最后小guard `game/build/luoyang_entry_20261029l_qa01/final_guard_ROOT_ACTUAL.json` SHA4446C44BE6BF70AA6934F8346D03E31929C50955E964BB0D20A5C06E9F049DF7：75冻结源/60全文备份/171登记save SHA、bytes、精确UTC ticks保持，仅9授权来源差；原编辑器51856保留，自有进程自然全部退出。没有新PNG/导入，没有存档或布局写。停止本批检查，交用户重新运行游戏。

## 防复发要求

后续公共Router接线必须在封包时检查新snapshot符合原Authority路径闭集，且实际运行Culture.readiness与Authority.approved关键历史pin准入；机械整逆、仅新增城市进返成功都不能替代旧洛阳消费者准入。优先复用此最小源准入探针，不为此扩成全城重复验证。
