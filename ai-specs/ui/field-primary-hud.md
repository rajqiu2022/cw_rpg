# 一级探索 HUD UI 规格

本文是一级探索界面的布局真值源。后续无论由 Python 资产脚本、Godot 场景脚本，还是 Godot MCP 生成节点，都必须先对齐本规格，不再靠截图猜坐标。

## 1. 范围

目标界面：`game/scenes/field_walkable.tscn`

当前消费者：`game/scripts/field/field_walkable_controller.gd`

设计分辨率：`1920x1080`

正式化范围：

- 左上角角色信息：头像、头像框、姓名、等级、生命、内力、金钱。
- 右上角地图/场景信息：当前场景名、区域/小地图占位、当前主线任务摘要。
- 底部对话框：对话底框、说话人、正文、继续提示、选项按钮、可选立绘/头像。
- 右侧五个菜单按钮：已确认可用，冻结位置和资源，不再重做。

不在本阶段处理：

- 背包、装备、武学、任务完整面板。
- 战斗 HUD。
- 主菜单。
- 新的右侧菜单按钮视觉重做。

## 2. 风格约束

风格名：寒山玄铁 · 雾蓝侠影。

必须保留：

- 冷色玄铁、深墨蓝、冷钢蓝、霜蓝高光。
- 深竹绿/墨玉绿点缀，少量暗酒红/旧血红用于生命或 pressed 状态。
- 港漫厚涂质感，边框有手绘金属起伏。
- 简体中文，清晰可读。

禁止：

- 现代网页扁平 UI。
- 赛博霓虹、大面积暖金、鲜艳红。
- 用纯色 `StyleBoxFlat` 冒充正式面板。
- 把临时拼合图当最终资源。

## 3. 层级结构

建议新增独立场景：

`game/scenes/ui/field_primary_hud.tscn`

建议新增脚本：

`game/scripts/ui/field_primary_hud.gd`

由 `field_walkable_controller.gd` 实例化或引用。长期目标是把当前 `_init_formal_hud()` 中的运行时堆节点逻辑迁出，避免 Field 控制器继续膨胀。

节点建议：

```text
FieldPrimaryHud (Control, full rect, mouse_filter=IGNORE)
├── PlayerInfoPanel (Control)
│   ├── PanelArt (TextureRect)
│   ├── AvatarMask/Avatar (TextureRect)
│   ├── AvatarFrame (TextureRect)
│   ├── NameLabel (Label)
│   ├── LevelLabel (Label)
│   ├── HpBg / HpFill / HpText
│   ├── MpBg / MpFill / MpText
│   └── GoldLabel
├── MapInfoPanel (Control)
│   ├── PanelArt (TextureRect)
│   ├── SceneNameLabel (Label)
│   ├── RegionLabel (Label)
│   └── QuestSummary (RichTextLabel)
├── RightMenuButtons (Control)
│   └── TextureButton x5
├── HintBar (Control)
│   ├── BarArt (TextureRect)
│   └── HintLabel (Label)
└── DialogDock (Control, hidden when no dialog)
    ├── DialogFrameArt (TextureRect)
    ├── Portrait (TextureRect, optional)
    ├── SpeakerLabel (Label)
    ├── TextLabel (RichTextLabel)
    ├── ContinueHint (Label)
    └── ChoicesContainer (VBoxContainer)
```

## 4. 组件坐标

所有坐标为 1920x1080 下的绝对 rect。适配策略先固定 1080P，后续再封装 scale root。

### 4.1 左上角色信息

推荐 rect：

```text
PlayerInfoPanel: x=24, y=18, w=430, h=132
PanelArt:        x=0,  y=0,  w=430, h=132
Avatar:          x=24, y=24, w=76,  h=76
AvatarFrame:     x=16, y=16, w=92,  h=92
NameLabel:       x=122,y=22, w=180, h=24
LevelLabel:      x=312,y=22, w=76,  h=24
HpBg:            x=122,y=58, w=232, h=16
HpFill:          x=122,y=58, w=232, h=16, crop/size by hp ratio
HpText:          x=362,y=55, w=58,  h=22
MpBg:            x=122,y=84, w=232, h=16
MpFill:          x=122,y=84, w=232, h=16, crop/size by mp ratio
MpText:          x=362,y=81, w=58,  h=22
GoldLabel:       x=122,y=108,w=160, h=20
```

数据绑定：

- `NameLabel`: `GameState.player.display_name`
- `LevelLabel`: `Lv.%d`
- `HpFill`: `hp / max_hp`
- `HpText`: `%d/%d`
- `MpFill`: `mp / max_mp`
- `MpText`: `%d/%d`
- `GoldLabel`: `金 %d`

资产需求：

- `game/art/ui/field_hud/v2/hud_player_panel.png`
- `game/art/ui/field_hud/v2/hud_avatar_frame.png`
- `game/art/ui/field_hud/v2/hud_hp_bg.png`
- `game/art/ui/field_hud/v2/hud_hp_fill.png`
- `game/art/ui/field_hud/v2/hud_mp_bg.png`
- `game/art/ui/field_hud/v2/hud_mp_fill.png`
- `game/art/characters/portrait_lengguyun_hud.png`

头像要求：

- 重新生成 HUD 专用头像，不直接裁旧全身立绘。
- 3/4 侧脸或半身近景，冷峻、黑衣、武侠厚涂。
- 输出透明底或易抠背景，最终在圆形/牌框内显示。

### 4.2 右上地图/场景信息

推荐 rect：

```text
MapInfoPanel:   x=1480, y=18,  w=400, h=132
PanelArt:       x=0,    y=0,   w=400, h=132
SceneNameLabel: x=24,   y=18,  w=180, h=26
RegionLabel:    x=220,  y=18,  w=150, h=26
QuestSummary:   x=24,   y=56,  w=342, h=58
```

显示内容：

- `SceneNameLabel`: 当前 `SceneScript.display_name`
- `RegionLabel`: 当前章节或区域，例如 `第一章 · 林西村`
- `QuestSummary`: 当前主线任务标题 + 一行摘要。无任务时显示 `暂无追踪任务`。

资产需求：

- `game/art/ui/field_hud/v2/hud_map_info_panel.png`
- 可选：`game/art/ui/field_hud/v2/hud_map_marker.png`

注意：

- 目前右侧菜单按钮位于 `x=1670`，地图信息不能遮挡按钮点击区域。
- 如果信息量放不下，优先保留场景名和主线任务，地图缩略图留到后续。

### 4.3 右侧五个菜单按钮（冻结）

当前位置沿用：

```text
inventory: x=1670, y=120, w=241, h=93
equipment: x=1670, y=218, w=241, h=93
skill:     x=1670, y=316, w=241, h=93
quest:     x=1670, y=414, w=241, h=93
system:    x=1670, y=512, w=241, h=93
```

资源沿用：

- `game/art/ui/field_hud/v1/hud_btn_inventory_normal.png`
- `game/art/ui/field_hud/v1/hud_btn_inventory_hover.png`
- `game/art/ui/field_hud/v1/hud_btn_inventory_pressed.png`
- 同名 `equipment/skill/quest/system`

规则：

- 不参与本轮重做。
- 不改尺寸、位置、三态逻辑。
- 若后续要动，必须另开按钮专项，不与一级 HUD 面板混改。

### 4.4 底部提示条

非对话状态显示操作提示。

推荐 rect：

```text
HintBar:   x=360, y=988, w=1200, h=64
BarArt:    x=0,   y=0,   w=1200, h=64
HintLabel: x=80,  y=18,  w=1040, h=24
```

显示内容：

`WASD 移动   空格/Enter 交互   I 背包   E 装备   K 武学   J 任务   Esc 关闭`

资产需求：

- `game/art/ui/field_hud/v2/hud_hint_bar.png`

规则：

- 对话开始时隐藏。
- 对话结束时恢复。

### 4.5 底部正式对话框

替换当前 `dialog_box.tscn` 的 `ColorRect` 临时底框。

推荐 rect：

```text
DialogDock:      x=160, y=760, w=1600, h=280
DialogFrameArt:  x=0,   y=0,   w=1600, h=280
Portrait:        x=42,  y=34,  w=190,  h=210
SpeakerLabel:    x=270, y=38,  w=260,  h=34
TextLabel:       x=270, y=84,  w=1100, h=116
ContinueHint:    x=1180,y=214, w=300,  h=24
ChoicesContainer:x=1040,y=44,  w=460,  h=190
```

资产需求：

- `game/art/ui/field_hud/v2/hud_dialog_frame.png`
- 可选：`game/art/ui/field_hud/v2/hud_dialog_choice_normal.png`
- 可选：`game/art/ui/field_hud/v2/hud_dialog_choice_hover.png`
- 可选：`game/art/ui/field_hud/v2/hud_dialog_choice_pressed.png`

数据绑定：

- `SpeakerLabel`: `DialogPlayer.text_displayed.speaker`
- `TextLabel`: `DialogPlayer.text_displayed.text`
- `Portrait`: `DialogNode.portrait_path`，为空则隐藏头像区或显示旁白装饰。
- `ChoicesContainer`: `DialogPlayer.choices_displayed`

规则：

- `DialogDock` 显示时隐藏 `HintBar`。
- 选择按钮使用正式纹理按钮；若素材未就绪，允许保留临时按钮，但必须标记为 debug fallback。
- 正文不滚动，单节点文本长度超过两行时优先改文案。

## 5. 资产生产顺序

第一批只做可替换当前临时 HUD 的关键资产：

1. `portrait_lengguyun_hud.png`
2. `hud_player_panel.png`
3. `hud_avatar_frame.png`
4. `hud_hp_bg.png` / `hud_hp_fill.png`
5. `hud_mp_bg.png` / `hud_mp_fill.png`
6. `hud_map_info_panel.png`
7. `hud_hint_bar.png`
8. `hud_dialog_frame.png`

右侧按钮不生成。

## 6. 工程实施顺序

### Step 1：结构层

- 新增 `field_primary_hud.tscn` 和 `field_primary_hud.gd`。
- 先用现有 v1/v2 临时图或 ColorRect 占位，把节点树和坐标搭出来。
- `field_walkable_controller.gd` 只负责传数据，不再直接创建 HUD 子节点。

### Step 2：样式层

- 绑定正式 PNG。
- 统一字体、颜色、阴影。
- 接入头像、血量、内力、场景名、任务摘要。

### Step 3：对话框替换

- 把 `dialog_box.tscn` 改为使用正式 `hud_dialog_frame.png`。
- 保留现有 `DialogPlayer` 信号协议，不改对话数据结构。

### Step 4：验证层

- 生成 `tools/field_primary_hud_layout_preview.png`。
- Godot 中进入 walkable field，检查 1080P 布局。
- 触发对话，检查 hint bar 隐藏/恢复、点击继续、选项按钮。
- 检查右侧五按钮仍可点击。

## 7. Godot MCP 用法预期

当前 Cursor MCP 目录尚未暴露 Godot MCP tools。等 Godot MCP 可用后，优先用于：

- 读取当前场景树，确认节点是否符合本规格。
- 按本规格创建或调整 `Control` 节点坐标。
- 检查 anchors、offset、mouse_filter、z_index。
- 后续批量添加 `AnimationPlayer` 或 Tween preset。

不建议让 Godot MCP 决定视觉风格或临时发明布局；它只能执行本规格。

## 8. 验收清单

- 右侧 5 个菜单按钮未改动。
- 左上角色信息包含头像、头像框、姓名、等级、HP/MP 条和数字、金钱。
- 右上信息区不遮挡菜单按钮，显示场景名和任务摘要。
- 底部非对话时显示正式提示条。
- 对话时显示正式对话框，并隐藏提示条。
- 所有正式 PNG 有透明边界清理，无灰底残留。
- 1080P 下不裁切、不重叠、不遮挡交互。
- 代码中无正式 UI 的 `StyleBoxFlat` 纯色替代方案，除非标记为 fallback。
- 修改后更新 `docs/experience-log.md`。
