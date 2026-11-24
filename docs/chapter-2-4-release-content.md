# 第二至第四章正式内容规划

更新时间：2026-08-05

## 验收目标

- 每章主线正常推进不少于 60 分钟。
- 每章包含支线、练级和探索后的完整体验为 120 至 240 分钟。
- 每章至少 3 条主线任务、5 条支线任务、4 个主线场景和 2 个可重复练级场景。
- 剧情战斗必须同时覆盖 2 人和 3 人敌方编队；随机遭遇必须同时提供 1、2、3 人梯度。
- 所有流程继续采用可行走 RPG 场景，不回退到 AVG 点击场景。

上述指标由 `game/data/chapters/chapter_2_content_plan.tres` 至 `chapter_4_content_plan.tres` 声明，并由 `game/test/validate_chapters_2_4_content_depth.gd` 自动校验。时长是制作期内容预算，正式上线前仍需真人完整游玩计时复核。

## 第二章：竹尾疑云

主线结构：竹尾晨市调查、北林追踪、密林救援、山寨洞窟追查、凌月山门复命。

- 主线任务 4 条，支线任务 7 条。
- 河岸营地和北林旧道提供 1 至 3 人随机遭遇与限额练级。
- 剧情战覆盖双人伏击、三人救援和三人山寨据点战。
- 预计主线 75 分钟，全探索 180 分钟。

## 第三章：门派试炼

主线结构：武林大会抉择、门派训练、双人考校、禁地追踪、三人终试。

- 主线任务 3 条，支线任务 5 条。
- 门派训练场和考校场提供 1 至 3 人训练编队。
- 禁地古冢承担解谜、残页与三人精英战，门派选择只做引导，不替玩家跳过考校。
- 预计主线 70 分钟，全探索 165 分钟。

## 第四章：洛阳暗潮

主线结构：府衙接案、洛阳街市查证、漕渠追凶、古寺调查、地道决战。

- 主线任务 4 条，支线任务 6 条。
- 漕渠码头和古寺地道提供 1 至 3 人巡查、缉盗和精英遭遇。
- 剧情战覆盖漕渠双人战、古寺三人战和首领带两名护卫的地道决战。
- 预计主线 80 分钟，全探索 200 分钟。

## 战斗配置

剧情多人战使用：

```text
battle_group:enemy_a,enemy_b
battle_group:enemy_a,enemy_b,enemy_c
```

随机遭遇在 `SceneScript.encounter_groups` 中配置：

```gdscript
encounter_groups = [
    {"enemy_ids": ["enemy_a"], "weight": 55},
    {"enemy_ids": ["enemy_a", "enemy_a"], "weight": 30},
    {"enemy_ids": ["enemy_elite", "enemy_a", "enemy_a"], "weight": 15},
]
```

单主角对 2 至 3 名敌人同样会初始化完整队伍运行时；胜利结算会逐个处理敌人的掉落、金钱、经验、击败标记和任务事件。缺少正式动作组的旧敌人会使用可见的通用动作兜底，不能出现静态图或空图；上线美术验收仍要求每个重要敌人拥有独立备战、移动、攻击、受击和倒地动作。

## 验证命令

```powershell
& 'C:\Program Files\Godot\Godot.exe' --headless --editor --path game --quit
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_2_4_content_depth.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_resources.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_flow.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_balance.gd
```
