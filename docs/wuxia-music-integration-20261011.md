# 武侠配乐正式接入 · 2026-10-11

用户明确批准：“可以替换现有的音乐了”。本轮采用已交付的20主题选曲（18原版＋密林ALT＋紧张ALT），以及此前认可的探索、行旅ALT、默认战斗三首循环。用途仍按用户最新说明为个人使用、暂不商用。旧制作记录、试听和封存manifest保留其当时状态，后续采用授权记录在本轮资料中。

## 接入范围

- 新音乐独立入库 `game/art/audio/bgm/wuxia_20261011/`，保留旧音频，便于对照和恢复。
- 城市、村庄、郊外按真实场景身份选曲。林西主街与室内继续使用用户认可的 `bgm_village_day_v4.wav`。
- 剧情紧张、轻松、欢乐、危险按核对过的现有对话身份触发；结束后恢复场景音乐，场景切换和战斗具有优先权。
- 五类战斗曲替换原五类引用，切磋和章末强敌原优先规则保持。
- 新循环从曲首播放，同曲跨房间继续播放，异曲沿用交叉淡入。地图几何、正式/候选开关、剧情文字、数值、音效和玩家存档不在修改范围。

夜村曲用于既有 `ch8_master_ultimate_breakthrough` 对话的 n6/n7 节点（原文从日影西斜进入灯火初上），结束后恢复原场景音乐，不新增昼夜系统。

## 场景与剧情选曲

| 用途 | 接入曲目 |
|---|---|
| 城市与城镇 | 洛阳、汴州、金陵、襄州、清河镇、雁门关各自主题 |
| 村庄 | 竹尾村主题（资源ID沿用qingfeng/zhuwei）；林西13个场景沿用原白日曲；夜村用于上述夜间剧情节点 |
| 郊外 | 竹溪、襄州密林ALT、金陵湿地；山道用已认可探索曲，码头/驿路用行旅ALT |
| 紧张 | 洛阳案件线索 `ch4_case_clue` |
| 轻松 | 林西阿婆留热粥 `linxi_center_granny` |
| 欢乐 | 牡丹诗会 `ch4_peony_poetry`、商队任务完成 `ch1_side_caravan_done` |
| 危险 | 寺院伏击 `ch4_temple_ambush`、路旁尸体 `ch1_road_corpse`，以及原洞窟音乐场景 |
| 战斗 | 切磋、河岸、村落/城街、山地、强敌五类；未知场地用已认可默认战斗曲 |

运行时由 `game/scripts/audio/music_catalog.gd` 根据场景身份和旧曲族返回实际新路径。99个顶层场景中85个选用新曲，13个林西场景保留原曲，1个空曲实验场景仍走默认曲；场景TRES无需重写。`audio_manager.gd`处理播放与剧情恢复，`dialog_player.gd`只增加节点配乐调用，`battle_controller.gd`只替换音乐路径。

## 验证与状态

**音乐已接入当前工程。** 独立源码审查对照真实修改前全文，四份生产源最终SHA固定，见 [source_final_mapping.json](../assets/processed/audio/wuxia_music_adoption_source_20261011/source_final_mapping.json) 和 [scoped_source_review_final.json](../assets/processed/audio/wuxia_audio_install_qa_20261011/scoped_source_review_final.json)。23个WAV与封存选曲逐字节相同，新导入采用PCM16/双声道/44100Hz，避免额外有损压缩；旧音频未覆盖。

本机Godot 4.6.2实际WASAPI运行自然OS0，719检查/0失败，完整stderr为空；进程96828于2026-10-11T05:13:29.5369541Z退出，用户编辑器36036保持。结果 [runtime_actual_retry2.json](../assets/processed/audio/wuxia_audio_install_qa_20261011/runtime_actual_retry2.json)，SHA `0846d5689c93ce559ae729e27c3d541a159f683391c2ac5c97d40c4996fe5074`。

验证包括23首真实导入/播放/完整帧循环/曲首开始、99场景真实属性与预期选曲逐项核对、18个正常scene_entered事件、4剧情情绪的正常DialogPlayer播放与结束恢复、夜间节点、同ID对话重入、战斗/胜利短曲优先、快速A/B/A交叉淡入及同曲不重启。真实BattleController验证原切磋优先于章末强敌、强敌优先于场地和默认曲规则；未运行战斗玩法。行旅与默认战斗各实测一次从尾前seek后自然越过循环边界；不称整曲连续听审。Web待播停止/解锁只做桌面公共API模拟，不授浏览器播放信用。

首轮测试脚本直接引用SceneRouter导致编译OS1，原日志保留；NEW retry1经root节点取得autoload后307/0，但文本正则漏7个无空格的第八章BGM属性，仅有限播放信用。NEW retry2改为逐物理路径/实际scene_id/首保护SHA/属性及预期结果严格核99个资源，并补7个第八章真实事件；生产源未因两次测试修正而改变。

资源导入期间发现历史QA/导出目录的class_name副本污染全局注册。只新增档案扫描标记，原副本保留；生产郊外build目录仍参与扫描。引擎元数据备份、两次明确中止扫描和早期错误日志均保留，最终增量导入自然OS0，仅有已知嵌套project.godot提醒；当前52个全局类路径全部来自生产scripts。详QA目录内 `archive_roots_ignore_applied.json`、`filesystem_cache_restore.json`、`import_incremental_exit.json`，不把早期导入退出0冒称无错误。

独立最终复核 [final.json](../assets/processed/audio/wuxia_audio_install_qa_20261011/final.json) 为 `LIMITED_ACTUAL_AUDIO_ADOPTION_PASS`，SHA `ddd7c8d8c342655a663efd35c3dd6a5bba69242ed5f8e13a9e36c4dba0efa705`。15玩家路径（6存在/9缺席）的SHA/大小/精确mtime/Windows100ns ticks、170独立旧音频、原1307音频库存（含语音/环境/导入元数据）、99场景TRES、685封存源及本次所列档案/标记保护全部零差；执行源固定且当前52类注册路径正确。未审计的其他大型历史PNG树不授全量零差信用。首保护 [before.json](../assets/processed/audio/wuxia_audio_install_qa_20261011/before.json) 保留修改前脚本全文用于恢复。

重新运行游戏即可使用本批音乐；旧曲路径仍保存在场景资源中，由MusicCatalog返回实际新曲。恢复旧选曲须按 `before.json` 的原始源码恢复三份接线并停用目录映射，无需覆盖或重建音频及地图。

本轮只授音乐接入与所列检查，不替代城市工程尚未完成的完整几何、玩法或正式地图验收。
