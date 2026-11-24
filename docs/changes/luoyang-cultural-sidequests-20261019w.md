# change-id: luoyang-cultural-sidequests-20261019w

目标：为洛阳新增三条有出处、可调查、可重试且有居民后续反应的文化支线原型；第四条独乐园主题先作储备。

已读：当前快照、AI规则、角色工作流、lore/system/QA记忆、世界观v0.5优先级、开放世界修订、任务设计参考、QuestDef及洛阳现有七支线。新增内容不能覆盖历史主线旧稿或以典故替代证据。

写权：lore只写NEW文化任务设计、3候选QuestDef和21候选DialogScript；system只写NEW合同manifest与纯状态机；QA只写NEW薄键；Root维护史料清单、外守卫与总交付记录。禁止改旧任务/数值/正式来源校验/玩家保存，不创建付费音频或图片任务。

验收：接取与拒绝不发奖；三条线索全部齐备才允许推理；未知、错误人物/地点、提前回报拒绝；错解可重试；正确解后仍须向指定人物回报且不能重复；状态可JSON往返，所有输入不被原地修改。九宫要独立校验1—9、八条和及固定方位，不只比较答案字符串。实际加载3QuestDef/21对白，节点不暗中改变真实GameState或奖励；15保存与既有工程源保持。

边界：候选纯逻辑的scene_id/npc_id匹配不等于真实行走/碰撞/距离验收；NPC入口、调查热区和任务管理器正式发布需要后续来源继承与代表实机。数值奖励暂0并明确待平衡，不以候选零奖励冒最终成品。暂不重已通过的城门/十房检查。

史料区分：董宣为历史典故；洛神赋为文学；洛书为传说；独乐园为历史文化主题。具体接状案、九宫题板、归信故事为游戏原创。出处见 `assets/specs/luoyang_cultural_sources_20261019w.json`。

完成候选里程碑：3QuestDef／21对白31节点／纯状态机与完整26来源。归信补独立pickup→collected，不能solve后直接Market report；候选事件不证明实际本人到场。proper自然0，唯一actual113772自然0／1723检查0／646ms，15save与真实状态不变，923外精确ticks/SHA零差，editor51856保留。退出1ObjectDB warning，不称clean。正式入口、真实领取与奖励仍待，详 `docs/luoyang-cultural-sidequests-status-20261019w.md`。
