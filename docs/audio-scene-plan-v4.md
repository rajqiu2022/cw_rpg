# 武侠场景与战斗配乐方案 v4

日期：2026-08-22

## 改版结论

v3 的持续规则拨弦音型在实机中被听成轻快钢琴琶音，不符合武侠气质。v4 不再从合成琶音起步，而是重新使用项目早期获得认可的两首 CC0 音乐作为完整音乐骨架：

- 场景骨架：`bgm_field_bards_tale_cc0.mp3`
- 战斗骨架：`bgm_battle_medieval_cc0.mp3`

两首来源均为 RandomMind、CC0 1.0，来源记录保留在 `game/art/audio/cc0/LICENSES.md`。v4 是项目内的再编配版本，不采样其他商业游戏音乐。

## 编配规则

- 删除 v3 的连续合成拨弦琶音层，禁止以规则八分音符循环充当主要伴奏。
- 探索音乐保留早期版本清晰的完整旋律与和声推进，只增加稀疏的箫、低弦、堂鼓和锣。
- 村落和街市可以明亮，但不能使用钢琴式跳音；节奏由原曲与少量木梆承担。
- 密林、洞窟通过低通、低音持续音和远锣变暗，不依赖噪声铺底。
- 普通战第一小节立即进入堂鼓节奏；切磋减少鼓点，Boss 增加密集堂鼓、低锣和少量唢呐式强句。

## 运行资源

探索主题继续保持八类：`bgm_jianghu_journey_v4.wav`、`bgm_village_day_v4.wav`、`bgm_mountain_path_v4.wav`、`bgm_forest_mystery_v4.wav`、`bgm_cave_ominous_v4.wav`、`bgm_market_lively_v4.wav`、`bgm_city_ceremony_v4.wav`、`bgm_sect_clouds_v4.wav`。

战斗主题保持五类：`bgm_battle_village_v4.wav`、`bgm_battle_mountain_v4.wav`、`bgm_battle_river_v4.wav`、`bgm_battle_spar_v4.wav`、`bgm_battle_boss_v4.wav`。

## 生成与验收

- 生成器：`scripts/generate_wuxia_bgm_v4.py`
- PyAV 解码早期 CC0 骨架，SciPy 完成滤波；新演奏层由项目确定性合成。
- 全部资源为 22050Hz、16-bit、立体声 WAV，32～52 秒。
- 峰值约 -1.5dBFS，峰均比 14～17dB；首尾 PCM 落零并保留交叉淡化。
- v3 文件继续保留，只是不再由运行场景或战斗控制器引用。
