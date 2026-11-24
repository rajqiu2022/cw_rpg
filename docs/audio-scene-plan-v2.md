# 场景配乐与绝学音效方案 v2

## 场景主题

| 主题 | 运行资源 | 适用场景 |
|---|---|---|
| 江湖行旅 | `bgm_jianghu_journey_v2.wav` | 江湖大地图、长距离旅行 |
| 村落日常 | `bgm_village_day_v2.wav` | 林西村、竹尾村主街、民居、客栈 |
| 山路远行 | `bgm_mountain_path_v2.wav` | 山道、河谷营地、漕渠外围 |
| 密林疑踪 | `bgm_forest_mystery_v2.wav` | 后山密林、旧猎道、废宅外围 |
| 洞窟危机 | `bgm_cave_ominous_v2.wav` | 山洞、地道、禁地、废宅内层 |
| 街市烟火 | `bgm_market_lively_v2.wav` | 竹尾晨市、洛阳街市 |
| 城郭仪典 | `bgm_city_ceremony_v2.wav` | 洛阳府衙、武林大会集会区 |
| 门派云境 | `bgm_sect_clouds_v2.wav` | 山门、武馆、试炼场、古寺 |

## 战斗主题与场景图

| 战场ID | 场景图 | 配乐 | 自动选择 |
|---|---|---|---|
| `village_square` | `bg_battle_default_v2.png` | `bgm_battle_free_v1.wav` | 村镇、街市、洛阳城区 |
| `courtyard_wedge` | `bg_battle_mountain_gate_day_v1.png` | `bgm_battle_mountain_v2.wav` | 山道、密林、洞穴、废宅、地道 |
| `river_skirmish` | `bg_battle_river_valley_day_v1.png` | `bgm_battle_river_v2.wav` | 河谷、漕渠、码头 |
| `bamboo_platforms` | `bg_battle_bamboo_day_v1.png` | CC0 battle track | 门派、武馆、未明确分类的切磋 |

## 绝学题字

- `sfx_legendary_title_reveal_v2.wav` 在“传世绝学 / 招式名”开始放大时播放。
- 音色结构为低锣、上升风啸和金石收音；它只负责题字重量，不替代角色出招和命中特效音。
- 题字、角色动作、全屏命中仍是三段时间轴，避免同一声效同时承担全部阶段。

## 版权与替换

以上 WAV 均由 `scripts/generate_scene_audio_v2.py` 本地确定性合成，不取样商业游戏音频。后续委托正式配乐时保持资源路径或更新 SceneScript 数据即可，无需改 AudioManager。

## Godot WAV循环注意事项

导入的 `AudioStreamWAV.loop_end` 默认为0。运行时启用 `LOOP_FORWARD` 前必须把循环终点设为 `音频长度 × 采样率`；否则WASAPI会执行0帧循环，`play()`后立刻停止。AudioManager已经统一设置完整循环区间，并由WASAPI实机测试覆盖世界地图与战斗配乐。
