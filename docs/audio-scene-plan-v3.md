# 武侠场景与战斗配乐方案 v3

日期：2026-08-22

## 改版原因

v2 为22.05kHz单声道占位合成，旋律层只有正弦波，鼓点主要依靠宽频噪声，辨识度有但缺少武侠器乐质感。v3参考项目早期配乐“旋律清楚、噪声少、循环直接”的优点，重新构建为立体声五声音阶器乐层。

全部曲目由 `scripts/generate_wuxia_bgm_v3.py` 本地确定性生成，不采样商业游戏与外部音乐，可直接用于项目与后续迭代。

## 探索主题

| 主题 | 资源 | 配器与节奏 | 适用场景 |
|---|---|---|---|
| 江湖行旅 | `bgm_jianghu_journey_v3.wav` | 76 BPM，箫/笛长线、古琴低音、疏堂鼓 | 江湖大地图 |
| 村落日常 | `bgm_village_day_v3.wav` | 82 BPM，琵琶轻拨、笛声问答 | 林西、竹尾、客栈与民居 |
| 山路远行 | `bgm_mountain_path_v3.wav` | 64 BPM，箫、古琴、留白 | 山道、河谷外围 |
| 密林疑踪 | `bgm_forest_mystery_v3.wav` | 58 BPM，低箫、暗色古琴、轻环境气息 | 密林、废宅外围 |
| 洞窟危机 | `bgm_cave_ominous_v3.wav` | 52 BPM，低音古琴、埙/箫式长音、远锣 | 洞窟、地道、废宅内层 |
| 街市烟火 | `bgm_market_lively_v3.wav` | 98 BPM，琵琶轮拨、笛、木梆 | 晨市与洛阳街市 |
| 城郭仪典 | `bgm_city_ceremony_v3.wav` | 70 BPM，堂鼓、锣、唢呐式短句 | 府衙、武林大会 |
| 门派云境 | `bgm_sect_clouds_v3.wav` | 60 BPM，古琴、箫、钟锣余韵 | 山门、武馆、古寺 |

## 战斗主题

| 战斗类型 | 资源 | BPM | 设计 |
|---|---|---:|---|
| 村镇遭遇 | `bgm_battle_village_v3.wav` | 122 | 第一拍进入琵琶持续型，不做长前奏 |
| 山地/洞穴 | `bgm_battle_mountain_v3.wav` | 128 | 堂鼓更重，二胡式短句制造压迫 |
| 河谷/漕渠 | `bgm_battle_river_v3.wav` | 126 | 流动琵琶音型与高音回答句 |
| NPC切磋 | `bgm_battle_spar_v3.wav` | 116 | 木梆和琵琶为主，紧凑但不使用Boss压迫配器 |
| 章节Boss | `bgm_battle_boss_v3.wav` | 138 | 密集堂鼓、低锣、二胡/唢呐式强句 |

运行逻辑优先判断切磋，其次读取 `EnemyDef.is_chapter_boss`，最后按战场类型选择普通战斗主题。切磋不会误用Boss曲，章节Boss也不会继续使用普通山地曲。

## 技术合同

- PCM WAV，22050Hz、16-bit、双声道。
- 探索曲29～42秒，战斗曲约29～31秒。
- 峰值约-1.3dBFS，保留13～16dB峰均比，不做砖墙限幅。
- 长交叉淡化负责音乐句衔接，首尾18ms落零；首尾PCM差值为0。
- `AudioManager` 在载入时补齐完整 `loop_end`，WASAPI实机测试确认大地图和战斗曲处于播放状态。
- v2与早期CC0文件保留作A/B参考，但不再由当前SceneScript或BattleController引用。

