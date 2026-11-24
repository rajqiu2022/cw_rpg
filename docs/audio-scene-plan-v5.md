# 武侠场景与战斗配乐方案 v5

日期：2026-08-23

## 改版原因

v4 虽恢复了早期曲目的风格，但13首运行曲全部取自两首旧曲的不同切片，长期游玩时会被听成“始终只有场景曲和战斗曲两首”。同时探索曲仅32～52秒，重复段落过早出现。

## v5原则

- 不再使用两首完整旧曲作伴奏骨架。
- 8首探索曲、5首战斗曲分别拥有独立根音、旋律动机、答句、节奏型和段落长度。
- 探索曲以低音古琴点句、箫/笛长句、二胡答句和大量留白为主，不使用连续钢琴式琶音。
- 战斗曲第一拍进入堂鼓；村镇、山地、河谷、切磋、Boss使用不同鼓点语法和旋律动机。
- 探索曲约84～106秒，战斗曲约54～62秒；Godot按完整采样长度循环。

## 切换机制

`AudioManager` 使用两路 `AudioStreamPlayer`。新曲在收到切换请求后立即从0秒播放，同时用约0.08～0.18秒淡入；旧曲并行淡出后停止，不再先等待旧曲退完再启动新曲。

实测从场景曲请求切到山地战斗曲，函数提交耗时约2ms，新流在0.2秒检查时已播放到约0.19秒。

## 战斗反馈同步

- 招式起手音在角色蓄势开始时播放。
- 普通招式命中音在目标特效开始时播放，受击动画不再于特效结束后重复补一声。
- 橙色绝学的命中音绑定全屏图集第3帧，与闪光峰值同步。
- 核心战斗SFX在AudioManager启动时预载，避免第一次出招临时读取资源。

## 运行资源

探索：`bgm_jianghu_journey_v5.wav`、`bgm_village_day_v5.wav`、`bgm_mountain_path_v5.wav`、`bgm_forest_mystery_v5.wav`、`bgm_cave_ominous_v5.wav`、`bgm_market_lively_v5.wav`、`bgm_city_ceremony_v5.wav`、`bgm_sect_clouds_v5.wav`。

战斗：`bgm_battle_village_v5.wav`、`bgm_battle_mountain_v5.wav`、`bgm_battle_river_v5.wav`、`bgm_battle_spar_v5.wav`、`bgm_battle_boss_v5.wav`。

生成器：`scripts/generate_wuxia_bgm_v5.py`。
