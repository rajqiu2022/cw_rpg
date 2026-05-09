# UI 风格与资产规范（当前基准）

> 本文件是 `docs/ui-style-v1.md` 的执行版，记录当前已经被用户认可的 UI 方向、资产来源和后续实现边界。

---

## 1. 当前 UI 方向

风格名：**寒山玄铁 · 雾蓝侠影**

关键词：

- 冷色玄铁
- 深墨蓝、冷钢蓝、霜蓝高光
- 深竹绿 / 墨玉绿点缀
- 暗酒红 / 旧血红点缀
- 山雨、竹影、寒雾、江湖牌匾
- 港漫厚涂质感
- 简体中文、清晰可读

当前亮度规则：

> **后续 UI 不能比 `v6` 主菜单与 `v2` 模块 UI 更暗。**

---

## 2. Canonical 资产

### 2.1 主菜单

| 状态 | 调度台资产 | Godot 资产 |
|---|---|---|
| 普通 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_main_menu_screen_gpt_v6.png` | `game/art/backgrounds/bg_main_menu_gpt_v6.png` |
| hover 新游戏 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_main_menu_hover_new_gpt_v1.png` | `game/art/backgrounds/bg_main_menu_hover_new_gpt_v1.png` |
| hover 读取存档 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_main_menu_hover_load_gpt_v1.png` | `game/art/backgrounds/bg_main_menu_hover_load_gpt_v1.png` |
| hover 离开 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_main_menu_hover_quit_gpt_v1.png` | `game/art/backgrounds/bg_main_menu_hover_quit_gpt_v1.png` |

要求：

- 主菜单按钮视觉状态由 `gpt-image-2` 整图提供。
- Godot 中按钮只作为透明点击热区。
- 不允许程序层临时画正式 hover 边框。

### 2.2 UI 模块概念图

| 模块 | 调度台资产 |
|---|---|
| 探索 HUD | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_field_hud_screen_gpt_v2.png` |
| 背包 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_inventory_screen_gpt_v2.png` |
| 装备 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_equipment_screen_gpt_v2.png` |
| 任务 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_quest_screen_gpt_v2.png` |
| 武学 | `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_skill_screen_gpt_v2.png` |

### 2.3 UI Atlas

| 资产 | 用途 |
|---|---|
| `game/art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png` | 七属性图标、背包/商店/战斗按钮图标 |
| `game/art/ui/cold_wuxia/v1/ui_cold_wuxia_battle_hud_v1.png` | 战斗 HUD 装饰框、日志框、状态框参考 |

### 2.4 鼠标

| 状态 | Godot 资产 | 用途 |
|---|---|---|
| 普通 | `game/art/ui/cursors/cursor_arrow.png` | 默认指针 |
| 手势 | `game/art/ui/cursors/cursor_hand.png` | 按钮/可点击物 |
| 等待 | `game/art/ui/cursors/cursor_wait.png` | 加载/生成/等待 |

由 `game/scripts/autoload/cursor_manager.gd` 注册。

---

## 3. 程序层与美术层边界

### 3.1 程序层可以做

- 透明点击热区。
- 切换已有 PNG 状态图。
- 数据绑定：HP、MP、任务、物品、装备、技能。
- 简单过渡：显隐、淡入淡出、焦点切换。
- Debug / 占位样式。

### 3.2 程序层不应该做

- 正式主菜单 hover 发光边框。
- 正式按钮材质、牌匾纹理、复杂装饰。
- 用纯色 StyleBox 冒充最终视觉。
- 临时拼合图冒充 `gpt-image-2` 产物。

### 3.3 美术层必须做

- 主菜单整图。
- 按钮状态图。
- 关键 UI 模块概念图。
- 大面积纹理和材质。
- 风格统一的图标 / 面板 / 装饰资源。

---

## 4. 出图规范

1. 正式 UI 出图必须写入 `prompts/tasks.yaml`。
2. 新模板放 `prompts/templates/*.yaml`。
3. 正式跑前必须 `--dry-run`。
4. 产物必须保留 `.meta.json`。
5. 若要求 `gpt-image-2`，必须检查：
   - `model == "gpt-image-2"`
   - `fallback_used == false`
6. 参考图只能作为风格参考，不得直接复制使用，除非用户明确允许。
7. 图片内中文必须简体、清晰、无错字。
8. 避免英文、繁体、乱码、水印、签名。

---

## 5. 色彩与状态

| 用途 | 方向 |
|---|---|
| 主背景 | 明亮冷色寒夜，不压黑 |
| 面板 | 玄铁蓝黑，边框冷钢蓝 |
| 高光 | 霜蓝 / 寒玉青 |
| hover | 深竹绿冷光、寒玉反光 |
| pressed | 轻微暗红 / 旧血红压下反馈 |
| 危险/退出 | 暗酒红边缘点缀，不能喜庆大红 |
| 正文 | 冷白、雾灰蓝 |
| 禁止 | 大面积暖金、橙黄、鲜艳红、赛博霓虹、现代网页风 |

---

## 6. 当前已落地界面

| 界面 | 状态 |
|---|---|
| 主菜单 | `gpt-image-2` v6 + 三张 hover 整图；透明热区切换 |
| 探索 HUD | 已接入 I/E/K/J、角色信息、任务摘要、冷武侠按钮 |
| 背包 | 已正式化三栏布局 |
| 装备 | 已正式化六槽 + 属性 + 可替换装备 |
| 任务 | 已正式化卷宗 + 筛选 + 追踪 |
| 武学 | 已正式化筛选 + 详情 + 快捷招式 |
| 战斗 | 已提亮 HUD，增加回合/状态/内力标签 |
| 商店 | 已提亮，增加库存统计与交易反馈 |
| 存档/读取 | 已改为卷宗风格槽位面板 |

---

## 7. 后续 UI 验收清单

每个 UI 改动至少检查：

- 是否比当前标准更暗？若更暗，打回。
- 是否仍是冷色玄铁 + 深绿/暗红点缀？
- 是否使用简体中文？
- hover / pressed / disabled 是否有状态？
- Esc 是否能关闭弹窗/面板？
- 鼠标手势是否正确？
- 1080P 下位置是否对齐？
- 是否用了原生 `alert/confirm/prompt`？若有，必须替换自定义弹窗。
- 是否有 `.meta.json` 可追溯？

---

## 8. UI 按钮/交互元素标准制作流程（一步到位）

> 基于 2026-05-08 主菜单按钮最终方案总结。后续所有 UI 按钮、面板装饰、交互元素都按此流程执行，避免反复返工。

### 8.1 决策树

```
有现成参考素材/底框？
  ├── 是 → 裁切复用（§8.2）
  └── 否 → AI 生成（§8.3）
```

### 8.2 裁切复用流程（首选）

适用场景：`assets/raw/ui/` 中已有设计好的底框、按钮、面板素材。

| 步骤 | 操作 | 注意事项 |
|------|------|----------|
| 1. 检查素材背景 | 检测四角 + 中心像素 RGBA 值 | **不要假设 PNG 就是透明底！** 灰底(218,218,218)需去除 |
| 2. 去除背景 | `remove_gray_background()` 双条件：通道一致性(spread<30) + 亮度(avg>180) | 单纯阈值会误伤装饰像素 |
| 3. 裁切状态图 | 多态素材按等分裁切 → `getbbox()` 去除透明边缘 | 保持各态裁切尺寸一致 |
| 4. Resize 到目标尺寸 | `Image.LANCZOS` 缩放 | 比例不宜超过 1.5:1 拉伸 |
| 5. 文字渲染 | 华文行楷 (STXINGKA.TTF) + 白色 + 黑色 GaussianBlur(3) 阴影 | 居中，y 偏移避开顶部装饰 |
| 6. 分层合成 | `Image.alpha_composite(frame, shadow)` → `alpha_composite(result, text)` | 不要用混合模式 (MUL/ADD) |
| 7. 输出 | 透明底 RGBA PNG，命名 `btn_<key>_<state>.png` | 9 张 = 3 按钮 × 3 态 |

### 8.3 AI 生成流程（次选）

适用场景：没有现成参考素材，或需要全新风格。

| 步骤 | 操作 | 注意事项 |
|------|------|----------|
| 1. 写 prompt 模板 | 放入 `prompts/templates/` | 参考图选已确认风格的素材 |
| 2. dry-run | `--dry-run --force` 验证模板 | 确认参考图路径正确 |
| 3. 生成 | `gpt-image-2`, size 不低于 1024x1024 | DMXAPI.com + 正确 token |
| 4. 验收 | 人工目视确认风格一致 | 不一致则回 step 1 |
| 5. 后处理 | 去背景 / 裁切 / 合成文字 | 同 §8.2 步骤 |

### 8.4 文字渲染规范

| 项目 | 规范 |
|------|------|
| 字体优先级 | 华文行楷 > 华文隶书 > 华文中宋 > 微软雅黑 |
| 字号 | 按钮：48-60px；面板标题：36-42px；正文标签：24-28px |
| 颜色 | 主文字 (240,240,255)；禁用态 (140,145,155,200) |
| 阴影 | 黑色 (0,0,0,180) + GaussianBlur(radius=3) |
| 对齐 | 水平居中；垂直居中 + y_offset（避开顶部装饰） |
| 语言 | **只用简体中文**，禁止英文/繁体/乱码 |

### 8.5 按钮三态规范

| 状态 | 视觉特征 | Godot 实现 |
|------|----------|------------|
| Normal | 银灰色/冷钢蓝边框 | `texture_normal` |
| Hover | 青色/寒玉绿发光边框 | `texture_hover` |
| Pressed | 金色/暗金边框 | `texture_pressed` |
| Disabled | 整体灰化 modulate (0.58,0.60,0.64,0.94) | `disabled=true` + `modulate` |

### 8.6 Godot 接入规范

```gdscript
# TextureButton 或 Button + _apply_texture_button()
func _apply_texture_button(btn: Button, key: String) -> void:
    var dir = "res://art/ui/main_menu/buttons/final/"
    var tex_n = load(dir + key + "_normal.png")
    var tex_h = load(dir + key + "_hover.png")
    var tex_p = load(dir + key + "_pressed.png")
    if tex_n:
        btn.icon = tex_n
        # 或使用 StyleBoxTexture / TextureButton
```

- `custom_minimum_size` 设为贴图尺寸
- ButtonPanel 用 VBoxContainer，`separation = 20-24`
- 面板位置用 anchor_preset=center + offset 微调

### 8.7 目录结构规范

```
game/art/ui/
├── main_menu/buttons/final/     ← 主菜单按钮（合成完毕，直接用）
├── cold_wuxia/v1/               ← 通用 UI atlas（kit/icons/hud）
├── cursors/                     ← 鼠标指针
└── <module>/                    ← 其他 UI 模块
```

### 8.8 标准脚本模板

复用脚本：`scripts/gen_menu_buttons_from_ref.py`

后续新按钮只需：
1. 准备参考素材（底框三态并排 PNG）
2. 修改 `BUTTONS` 列表（key + 中文文字）
3. 修改 `REF_IMG_PATH` 和 `OUTPUT_DIR`
4. 运行脚本

### 8.9 验收清单

每次 UI 按钮/交互元素制作后必须检查：

- [ ] 透明底（四角 alpha=0）
- [ ] 三态完整（normal/hover/pressed）
- [ ] 文字清晰、简体中文、无错字
- [ ] 文字居中，不压装饰
- [ ] 风格与 `btn_menu_3states.png` 参考一致
- [ ] 在 1080P 下尺寸合适（按钮 500-620px 宽）
- [ ] Disabled 态有明显灰化
- [ ] Godot 中 `custom_minimum_size` 与贴图匹配
- [ ] Lint 通过

---

_最后更新：2026-05-08。_
