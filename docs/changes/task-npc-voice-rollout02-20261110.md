# 任务配音改造第二批

2026-11-10。新录并接入 30 条语音，包括 9 条 NPC 台词和 21 条冷孤云台词。录制采用项目已有的 Edge TTS 7.3.1，直接以现行对白资源为文稿。

- 清风镇和山贼洞窟补护商镖师的三句线索及留守山贼的警告。山贼用偏低、偏慢的声线，护商镖师用克制的交代语气。
- 凌月山门补归还腰牌对白。本批将接收线索的凌月弟子设为年轻女性声线，现行台词未明确其具体年龄。
- 第七章两处开放路线对白各有两个实际发言人，分别为旧渡守望、茶镇经手人和聚义厅引路人、外院录事。保留原对白资源，通过游戏现有的发言人回退机制选择各自录音。旧渡守望、茶镇经手人和外院录事沿用同角色已有录音的基础声线。
- 补四条支线的主角对白。第五章「少记的两袋粮」、第六章「三缺一的驿签」、第七章「茶篓差半斤」、第八章「营里两件小事」。

桌面 Godot 4.6.2 共 154 项检查通过。30 条均可加载，逐条核对台词、哈希、时长及播放键。用正式对白播放器实播 11 个样本，含第七章全部四个发言人版本和四条支线开场。用隔离状态满足原前置，未从地图长途游历或验证发布包。未访问真实存档。声线和情绪仍待人工听审。洛阳三条文化支线的动态语音键仍待处理。

## 新增文件

| 发言人 | 对白节点 | 基础声线 | 录制参数 | 音频 |
|---|---|---|---|---|
| 护商镖师 | [ch1_s2_bandit_cave_rumour](../../game/data/dialogs/ch1_s2_bandit_cave_rumour.tres) · start | zh-CN-YunjianNeural | -7% / -6Hz | [10.44 秒](../../game/art/audio/voices/ch1/ch1_s2_bandit_cave_rumour/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start_seg01_dialog.mp3) |
| 护商镖师 | [ch1_s2_bandit_cave_rumour](../../game/data/dialogs/ch1_s2_bandit_cave_rumour.tres) · accept | zh-CN-YunjianNeural | -7% / -6Hz | [9.82 秒](../../game/art/audio/voices/ch1/ch1_s2_bandit_cave_rumour/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_accept_seg01_dialog.mp3) |
| 护商镖师 | [ch1_s2_scout_main_clue](../../game/data/dialogs/ch1_s2_scout_main_clue.tres) · start | zh-CN-YunjianNeural | -7% / -6Hz | [9.00 秒](../../game/art/audio/voices/ch1/ch1_s2_scout_main_clue/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start_seg01_dialog.mp3) |
| 留守山贼 | [interior_bandit_cave_guard](../../game/data/dialogs/interior_bandit_cave_guard.tres) · start | zh-CN-YunjianNeural | -12% / -8Hz | [6.84 秒](../../game/art/audio/voices/int/interior_bandit_cave_guard/%E7%95%99%E5%AE%88%E5%B1%B1%E8%B4%BC_start_seg01_dialog.mp3) |
| 冷孤云 | [ch2_missing_disciple_complete](../../game/data/dialogs/ch2_missing_disciple_complete.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [6.62 秒](../../game/art/audio/voices/ch2/ch2_missing_disciple_complete/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 凌月弟子 | [ch2_missing_disciple_complete](../../game/data/dialogs/ch2_missing_disciple_complete.tres) · n2 | zh-CN-XiaoyiNeural | -2% / +0Hz | [7.78 秒](../../game/art/audio/voices/ch2/ch2_missing_disciple_complete/%E5%87%8C%E6%9C%88%E5%BC%9F%E5%AD%90_n2_seg01_dialog.mp3) |
| 冷孤云 | [ch7_outer_routes_open](../../game/data/dialogs/ch7_outer_routes_open.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [10.63 秒](../../game/art/audio/voices/ch7/ch7_outer_routes_open/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 旧渡守望 | [ch7_outer_routes_open](../../game/data/dialogs/ch7_outer_routes_open.tres) · open | zh-CN-YunjianNeural | -6% / -3Hz | [9.50 秒](../../game/art/audio/voices/ch7/ch7_outer_routes_open/%E6%97%A7%E6%B8%A1%E5%AE%88%E6%9C%9B_open_seg01_dialog.mp3) |
| 茶镇经手人 | [ch7_outer_routes_open](../../game/data/dialogs/ch7_outer_routes_open.tres) · open | zh-CN-YunjianNeural | -2% / +0Hz | [9.12 秒](../../game/art/audio/voices/ch7/ch7_outer_routes_open/%E8%8C%B6%E9%95%87%E7%BB%8F%E6%89%8B%E4%BA%BA_open_seg01_dialog.mp3) |
| 冷孤云 | [ch7_inner_routes_open](../../game/data/dialogs/ch7_inner_routes_open.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [10.68 秒](../../game/art/audio/voices/ch7/ch7_inner_routes_open/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 聚义厅引路人 | [ch7_inner_routes_open](../../game/data/dialogs/ch7_inner_routes_open.tres) · open | zh-CN-YunjianNeural | -3% / -2Hz | [8.18 秒](../../game/art/audio/voices/ch7/ch7_inner_routes_open/%E8%81%9A%E4%B9%89%E5%8E%85%E5%BC%95%E8%B7%AF%E4%BA%BA_open_seg01_dialog.mp3) |
| 外院录事 | [ch7_inner_routes_open](../../game/data/dialogs/ch7_inner_routes_open.tres) · open | zh-CN-YunyangNeural | -6% / -3Hz | [7.70 秒](../../game/art/audio/voices/ch7/ch7_inner_routes_open/%E5%A4%96%E9%99%A2%E5%BD%95%E4%BA%8B_open_seg01_dialog.mp3) |
| 冷孤云 | [ch5_relief_receipt_report](../../game/data/dialogs/ch5_relief_receipt_report.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [12.74 秒](../../game/art/audio/voices/ch5/ch5_relief_receipt_report/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch5_relief_receipt_seal](../../game/data/dialogs/ch5_relief_receipt_seal.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [12.10 秒](../../game/art/audio/voices/ch5/ch5_relief_receipt_seal/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch5_relief_receipt_start](../../game/data/dialogs/ch5_relief_receipt_start.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [11.64 秒](../../game/art/audio/voices/ch5/ch5_relief_receipt_start/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch6_courier_tally_crate](../../game/data/dialogs/ch6_courier_tally_crate.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [9.98 秒](../../game/art/audio/voices/ch6/ch6_courier_tally_crate/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch6_courier_tally_crate](../../game/data/dialogs/ch6_courier_tally_crate.tres) · retry | zh-CN-YunxiNeural | +0% / +0Hz | [5.21 秒](../../game/art/audio/voices/ch6/ch6_courier_tally_crate/%E5%86%B7%E5%AD%A4%E4%BA%91_retry_seg01_dialog.mp3) |
| 冷孤云 | [ch6_courier_tally_crate](../../game/data/dialogs/ch6_courier_tally_crate.tres) · solved | zh-CN-YunxiNeural | +0% / +0Hz | [8.83 秒](../../game/art/audio/voices/ch6/ch6_courier_tally_crate/%E5%86%B7%E5%AD%A4%E4%BA%91_solved_seg01_dialog.mp3) |
| 冷孤云 | [ch6_courier_tally_start](../../game/data/dialogs/ch6_courier_tally_start.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [9.89 秒](../../game/art/audio/voices/ch6/ch6_courier_tally_start/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch7_tea_basket_report](../../game/data/dialogs/ch7_tea_basket_report.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [7.85 秒](../../game/art/audio/voices/ch7/ch7_tea_basket_report/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch7_tea_basket_report](../../game/data/dialogs/ch7_tea_basket_report.tres) · recheck | zh-CN-YunxiNeural | +0% / +0Hz | [6.89 秒](../../game/art/audio/voices/ch7/ch7_tea_basket_report/%E5%86%B7%E5%AD%A4%E4%BA%91_recheck_seg01_dialog.mp3) |
| 冷孤云 | [ch7_tea_basket_report](../../game/data/dialogs/ch7_tea_basket_report.tres) · verified | zh-CN-YunxiNeural | +0% / +0Hz | [9.60 秒](../../game/art/audio/voices/ch7/ch7_tea_basket_report/%E5%86%B7%E5%AD%A4%E4%BA%91_verified_seg01_dialog.mp3) |
| 冷孤云 | [ch7_tea_basket_rope](../../game/data/dialogs/ch7_tea_basket_rope.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [14.18 秒](../../game/art/audio/voices/ch7/ch7_tea_basket_rope/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch7_tea_basket_start](../../game/data/dialogs/ch7_tea_basket_start.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [13.58 秒](../../game/art/audio/voices/ch7/ch7_tea_basket_start/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch7_tea_basket_start](../../game/data/dialogs/ch7_tea_basket_start.tres) · accepted | zh-CN-YunxiNeural | +0% / +0Hz | [4.39 秒](../../game/art/audio/voices/ch7/ch7_tea_basket_start/%E5%86%B7%E5%AD%A4%E4%BA%91_accepted_seg01_dialog.mp3) |
| 冷孤云 | [ch7_tea_basket_tag](../../game/data/dialogs/ch7_tea_basket_tag.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [11.40 秒](../../game/art/audio/voices/ch7/ch7_tea_basket_tag/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch8_camp_supplies_east](../../game/data/dialogs/ch8_camp_supplies_east.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [8.95 秒](../../game/art/audio/voices/ch8/ch8_camp_supplies_east/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch8_camp_supplies_start](../../game/data/dialogs/ch8_camp_supplies_start.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [11.02 秒](../../game/art/audio/voices/ch8/ch8_camp_supplies_start/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
| 冷孤云 | [ch8_camp_supplies_start](../../game/data/dialogs/ch8_camp_supplies_start.tres) · accepted | zh-CN-YunxiNeural | +0% / +0Hz | [5.40 秒](../../game/art/audio/voices/ch8/ch8_camp_supplies_start/%E5%86%B7%E5%AD%A4%E4%BA%91_accepted_seg01_dialog.mp3) |
| 冷孤云 | [ch8_camp_supplies_west](../../game/data/dialogs/ch8_camp_supplies_west.tres) · start | zh-CN-YunxiNeural | +0% / +0Hz | [9.29 秒](../../game/art/audio/voices/ch8/ch8_camp_supplies_west/%E5%86%B7%E5%AD%A4%E4%BA%91_start_seg01_dialog.mp3) |
