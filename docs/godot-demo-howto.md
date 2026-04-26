# Godot 4 Demo 运行手册

> v0.1.0 · 框架级 demo（主菜单 → 回合战斗 → 胜利/失败 → 存档闭环）

## 一次性环境准备

1. 下载 **Godot 4.3 Standard**：<https://godotengine.org/download/windows>
   - 单 exe ~80MB，免安装
   - 选 **Standard** 不要 .NET 版本（我们的 demo 是 GDScript）
2. 双击 `Godot_v4.3-stable_win64.exe`
3. 首次启动会进入 Project Manager

## 打开本项目

1. 在 Project Manager 点 **Import**
2. 选 `f:\Code\RPG_GAME\game\project.godot`
3. 点 **Import & Edit**
4. 等待资源导入（首次会扫描 9 张 PNG，~10 秒）

## 运行

- 按 **F5** 或点右上角 ▶
- 主场景已配置为 `scenes/main_menu.tscn`，会直接跳到主菜单

## 验收路径（5 分钟跑完）

| # | 操作 | 期望结果 |
|---|---|---|
| 1 | 启动 → 看到主菜单 | Lovart 主界面图作背景，"風雲·天下會"标题 |
| 2 | 点【开始游戏】| 切到战斗场景，主角立绘左下，敌人立绘右上 |
| 3 | 点【攻击】 | 日志输出"对无名匪徒造成 X 点伤害"，敌人 HP 条减少 |
| 4 | 等敌人反击 | 你的 HP 条减少，进入下一回合 |
| 5 | 点【排云掌】 | MP -5，伤害 ~1.6×攻击 |
| 6 | 干掉敌人（80 HP，约 4-6 回合）| 自动跳胜利结算页 |
| 7 | 点【保存进度】| 按钮变成"已存档 ✓" |
| 8 | 点【返回主菜单】| 回到主菜单 |
| 9 | 看【读取存档】按钮 | 应该从灰色变可点 |
| 10 | 点【读取存档】| 重新进战斗，主角 HP/MP/经验跟存档时一致 |

## 项目结构（Godot 子项目）

```
game/
├── project.godot                  # Godot 项目配置 + 3 个 autoload
├── icon.svg
├── art/
│   ├── backgrounds/               # 4 张 Lovart UI/场景
│   ├── characters/                # 2 张 DMXAPI 立绘（主角、敌人）
│   ├── concepts/                  # 2 张 Lovart 角色概念图（暂不用）
│   └── icons/skills/              # 1 张技能图标
├── scenes/
│   ├── main_menu.tscn
│   ├── battle.tscn
│   ├── result_victory.tscn
│   └── result_defeat.tscn
└── scripts/
    ├── autoload/                  # 全局单例（项目启动时自动加载）
    │   ├── game_state.gd          # 跨场景的会话级数据
    │   ├── scene_router.gd        # 场景跳转中转
    │   └── save_manager.gd        # JSON 存档读写
    ├── domain/                    # class_name 全局可见的领域模型
    │   ├── character_stats.gd     # 角色面板 + 伤害/治疗/升级
    │   └── skill.gd               # 技能数据 Resource
    ├── battle/
    │   └── battle_controller.gd   # 回合战斗状态机
    └── ui/
        ├── main_menu.gd
        ├── result_victory.gd
        └── result_defeat.gd
```

## 存档位置

存档不在项目目录，在 Godot 的 user 目录：
- Windows：`%APPDATA%\Godot\app_userdata\风云·天下会（致敬）\save_0.json`

可以打开看，是可读的 JSON：
```json
{
  "version": 1,
  "timestamp": 1745650000,
  "chapter": 1,
  "gold": 47,
  "flags": {},
  "player": {
    "character_id": "protagonist",
    "level": 1,
    "hp": 96, "max_hp": 120,
    ...
  }
}
```

## 常见问题排查

### Q1: 启动报 `Could not find type "CharacterStats"`
- 原因：Godot 第一次没扫描全 class_name
- 解决：编辑器顶部菜单 **Project → Reload Current Project**，或者先打开 `scripts/domain/character_stats.gd` 触发解析

### Q2: 启动黑屏，主菜单没显示
- 检查 **Project → Project Settings → Application → Run → Main Scene** 是否是 `res://scenes/main_menu.tscn`
- `project.godot` 已写好这一条，正常无需手动配

### Q3: 战斗里点【排云掌】无反应
- MP 不够（< 5）。新游戏开局 40 MP，能放 8 次
- 按钮文字会变灰

### Q4: PNG 显示模糊/拉伸变形
- 我们用了 `stretch_mode = 6`（KEEP_ASPECT_COVERED），背景图会等比裁切填满
- 立绘用 `stretch_mode = 5`（KEEP_ASPECT_CENTERED），保持比例不变形

### Q5: 想改窗口大小
- 当前默认 1280×720（设计分辨率 1920×1080，自动 keep aspect）
- 改 `project.godot` 的 `window_width_override` / `window_height_override`

## 下一步可以做什么

| 优先级 | 任务 | 工时 |
|---|---|---|
| P0 | 加 1-2 个测试敌人（不同数值）+ 敌人选择菜单 | 1h |
| P0 | 把 `data/enemies/<id>.tres` 抽出来（替换硬编码）| 1.5h |
| P1 | 升级时弹"角色升级"提示 | 30min |
| P1 | 加多个技能（一个治疗，一个 buff）| 2h |
| P1 | 队伍系统（多角色出战）| 3-4h |
| P2 | 大地图场景（用 Lovart 场景图作背景，玩家可以走）| 4h |
| P2 | 装备系统（用现有 bg_equipment.png 做装备界面）| 5h |
| P2 | 对话系统（驱动剧情）| 6h |

## 经验记录

### 关键认知
1. **Godot 4 的 .tscn 是文本文件**，可以直接手写或脚本生成
2. **`unique_name_in_owner = true`** + `%NodeName` 的语法可以跨层级访问，不依赖路径
3. **autoload 顺序**：在 `project.godot` 的 `[autoload]` 里按声明顺序加载，依赖关系手动管理
4. **`class_name` ≠ autoload**：class_name 是把脚本注册成全局类型（可以 `.new()` 创建），autoload 是常驻实例
5. **`res://` vs `user://`**：`res://` 打包后只读，存档必须写 `user://`

### 中文路径坑
- Lovart 出图带中文文件名（"游戏主界面UI.png"），**不能直接放进 `res://`**
- Godot 4 的资源 import 系统用 UTF-8 但有 bug，中文路径偶发 .import 文件错位
- 标准做法：导入前批量重命名为 ASCII（脚本里 `Copy-Item` 一次到位）

### 战斗状态机
- 用 enum 而不是字符串状态，编译期就能查错
- `await get_tree().create_timer(N).timeout` 是 Godot 4 标准异步等待
- Godot 4 的 GDScript lambda：`func(): xxx`（不能有参数 = 简化形式）

### 资源命名约定（建议固化）
```
art/backgrounds/bg_<scene>_<variant>.png      # bg_main_menu, bg_battle_default
art/characters/<role>_<emotion>.png           # protagonist_neutral, enemy_thug_angry
art/icons/skills/skill_<id>.png               # skill_palm_strike
data/enemies/<id>.tres                        # default_thug.tres
data/skills/<id>.tres                         # palm_strike.tres
scenes/<category>/<name>.tscn                 # ui/main_menu.tscn, battle/battle.tscn
```
