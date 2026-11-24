# 地区场景、寻路与音乐重制（2026-09-13）

## 本批结论

- 林西南坊私塾门前新增专用门槛通行带，入口热区下移到道路，角色可以实际靠近并进入。
- 洛阳改为“南城门 → 府衙 / 南市 / 漕渠码头”四张独立2304×1536场景，不再复用同一底图；进入洛阳先经过大型城门，穿过门洞时主角会半透明。
- 任务入口不再以孤立感叹号代替内容。城门使用实体通缉榜，府衙、南市与码头使用现场物件或NPC；仅资源缺失时才允许生成调试兜底标记。
- 白鹿渡改为大型多屏渡口，段长风四帧站立图统一身高与脚底，消除一会大一会小。
- 武当改为独立2.5D山门大场景，具有道路/台阶边界；可从大地图直接进入，守门弟子只说明加入路线，不以章节硬锁挡门。
- 雁门藏剑洞可直接进入，入口仅标注“高危”；原先“两次击退或撤离”的硬门槛与含混提示已移除，洞内守卫和雪径敌人提高强度承担软门槛。
- 江湖地图竹林高岔路补宽到34像素并纳入同源道路审计；当前39条路线、6245个脚底中心样本、608个路面横断面、13个门户保持同一连通域。
- Web/微信路径进入场景时预载全部背景分块，避免行走中同步加载；桌面继续使用线程预取。相机改为直接跟随，移除角色与相机双重插值造成的拖滞。

## 地区音乐

新增12段无随机噪声层的音频：林西村、洛阳城门、府衙、南市、码头、白鹿渡、武当、华山、凌月、孤峰/烈云、茗雾及7.6秒胜利庆祝乐句。所有曲目只使用有音高的笛、弦、拨弦、钟与低鼓合成；峰值为0.537～0.587，未削波，直流偏移绝对值小于0.0004。

## 关键运行资源

- 洛阳城门：`game/data/scenes/ch4_s0_luoyang_gate.tres`
- 洛阳府衙：`game/data/scenes/ch4_s1_luoyang_yamen.tres`
- 洛阳南市：`game/data/scenes/ch4_s3_luoyang_market.tres`
- 洛阳码头：`game/data/scenes/ch4_s2_canal_docks.tres`
- 白鹿渡：`game/data/scenes/openworld_bailu_ferry.tres`
- 武当山门：`game/data/scenes/openworld_wudang_gate.tres`
- 图像生成清单：`assets/raw/scene_background/region_scene_batch_20260913_manifest.json`
- 音乐生成器：`scripts/generate_scene_bgm_v6.py`

## 实机截图

- `game/screenshots/field_ch4_s0_luoyang_gate_1789264465.png`
- `game/screenshots/field_ch4_s1_luoyang_yamen_1789264839.png`
- `game/screenshots/field_ch4_s3_luoyang_market_1789264527.png`
- `game/screenshots/field_ch4_s2_canal_docks_1789264843.png`
- `game/screenshots/field_openworld_bailu_ferry_1789264846.png`
- `game/screenshots/field_openworld_wudang_gate_1789264850.png`

## 验收

- `test_region_scene_polish_20260913.gd`：117项，0失败。
- `test_reported_polish_batch_20260911.gd`：26项，0失败。
- `test_world_map_v9_shared_source.gd`：52项，0失败。
- `test_school_pointer_runtime_20260911.gd`：182项，0失败。
- `test_movement_combat_feedback_20260912.gd`：24项，0失败。
- `test_luoyang_region_v2_runtime.gd`：0失败。
- `capture_openworld_regions_20260910.gd`：白鹿渡NPC/出口、雁门洞口/采集点均由出生点实际寻路抵达，0失败。
- Godot 4.6.1严格导入：exit 0。部分headless用例退出仍有既有ObjectDB/资源清理告警；本批未重新导出Web/微信包。
