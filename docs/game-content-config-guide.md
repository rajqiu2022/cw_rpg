# 游戏内容配置手册

本手册说明如何通过 `game/data/` 新增和修改游戏内容。配置文件描述内容和关系，脚本负责解析、显示、结算与存档。新增普通内容不应修改核心管理器。

## 配置入口

| 内容 | 配置位置 | 负责人 | ID |
|---|---|---|---|
| 对话剧情 | `game/data/dialogs/*.tres` | `DialogPlayer` | `dialog_id` |
| 主线/支线 | `game/data/quests/*.tres` | `QuestManager` | `quest_id` |
| 道具/装备 | `game/data/items/`、`equipment/` | `Inventory` | `item_id` |
| 招式/心法 | `game/data/skills/*.tres` | Battle / Skill UI | `skill_id` |
| 敌人 | `game/data/enemies/*.tres` | `BattleController` | `enemy_id` |
| NPC 档案 | `game/data/npcs/npc_catalog.tres` | `NPCCatalog` | `npc_id` |
| 场景 | `game/data/scenes/*.tres` | `SceneRouter` / Field | `scene_id` |
| 地图碰撞 | `game/data/maps/*.tres` | `FieldWalkableController` | layout ID |
| 商店 | `game/data/shops/*.tres` | `ShopUI` | `shop_id` |

所有 ID 使用英文 `snake_case`，创建后不要随意修改，否则会影响存档和已有引用。

## 音频与音效

- 素材来源：`game/art/audio/cc0/`（CC0 公版）和 `game/art/audio/free/`（免费授权）
- 战斗与野外已有默认 BGM，切换场景时自动淡入淡出
- 场景 BGM 通过 `SceneScript.bgm_path` 配置即可，AudioManager 自动读取，**不需要额外改代码**
- 战斗音效通过 `EventBus.sfx_requested` 广播，AudioManager 池化播放（8 通道）
- 需要新音效时，直接放 `.ogg`/`.mp3`/`.wav` 到对应目录，Godot 会自动导入

### 对白语音

- `DialogNode.voice_emotion` 可配置 `auto / normal / concerned / solemn / weary / fear / happy / sad / angry / threat`；剧情关键句应显式配置，不依赖自动关键词判断。
- 角色声线在 `scripts/gen_dialog_voices.py` 的 `CHARACTER_PARAMS` 维护。刑樊天使用自然中年声线，仅轻微降调；担忧和凝重主要由节点情绪控制，避免同时大幅降调、减速造成老年机器腔。杜青衫与铁匠刘使用更低、更厚、略沙哑的声线。
- 台词中的括号旁白由统一旁白声线生成 `_narr.mp3`，运行时使用独立 Narrator 播放器；句首旁白先播、对白后播，句末旁白在对白结束后播放，禁止与对白互相抢占。
- 重新生成第一章指定人物：`python scripts/gen_dialog_voices.py --chapter 1 --speaker "刑樊天"`。先用 `--dry-run` 检查条目和情绪，再执行正式生成。

### 战斗音效

- `Skill.cast_sfx_path` 是起手/挥动声，`impact_sfx_path` 是命中声；命中声由 `BattleActor.strike_reached` 在攻击帧中段触发，不应在整段攻击动画结束后播放。
- 显式音效路径优先；未配置时按 `required_weapon_type` 自动回退到剑、刀、棍、掌四类武侠音色。
- 新招式至少配置正确的 `required_weapon_type`。特殊招式再单独配置 cast/impact，避免刀剑招式误用掌风声。

```text
# 对话或 action 中可直接切 BGM / 放音效：
play_bgm:res://art/audio/cc0/bgm_field_bards_tale_cc0.mp3
play_sfx:res://art/audio/free/sfx_attack_free_v1.wav
stop_bgm
```

### 剧情天气

天气是全局剧情状态，不写在 `SceneScript` 场景资源里。对话或 action 可随时切换，状态会跨场景并写入存档；进入室内仅暂时隐藏雨效和雨声，回到室外会继续当前天气。

```text
weather:rain_light          # 小雨
weather:rain_heavy:0.85     # 暴雨，可选强度 0.25～1.50
weather:storm               # 风雨（当前使用更强雨层）
weather:clear               # 转晴/关闭天气
```

`DialogNode.weather_id` 和 `weather_strength` 可把天气作为节点副作用；选项字典可使用 `{"weather":"rain_light","weather_strength":0.8}`。调试构建按 `F9` 可在晴天/小雨间切换，正式剧情不要依赖调试快捷键。

## 新增任务

在 `game/data/quests/` 新建 `QuestDef` 资源。核心字段：`quest_id`、`title`、`kind`、三个状态描述、`completion_triggers`、`reward_gold`、`reward_exp`、`reward_items`。`kind=0` 是主线，`kind=1` 是支线。

完成条件支持：

```text
enemy_defeated:<enemy_id>
scene_entered:<scene_id>
item_picked_up:<item_id>
flag_set:<flag_key>
npc_talked_to:<npc_id>
defeated:<enemy_id>
```

在对话或场景 action 中接取/完成任务：

```text
accept_quest:q_ch1_side_10_example
complete_quest:q_ch1_side_10_example
```

任务奖励由 `QuestManager` 统一发放。不要在同一段对话里同时写任务奖励和重复的 `give_gold` / `give_item`。

## 新增对话

在 `game/data/dialogs/` 新建 `DialogScript`，由多个 `DialogNode` 组成。节点配置说话人、头像、台词、选项、设置 flag、给道具/金钱、接取/完成任务。

常用结束动作：

```text
end
next:<node_id>
battle:<enemy_id>
battle_then:<enemy_id>:<victory_dialog_id>
battle_group:<enemy_a>,<enemy_b>,<enemy_c>
battle_group_then:<enemy_a>,<enemy_b>:<victory_dialog_id>
scene:<scene_id>
shop:<shop_id>
chapter_end:<chapter_number>
open_inventory
open_equipment
open_quest_log
```

选项产生的 flag 必须写在选项自身，不能写在整个对话节点上，否则玩家选择前就会生效。

## 道具、装备、招式、敌人

道具放在 `game/data/items/`，装备放在 `game/data/equipment/`。配置名称、描述、类别、品质、堆叠、价格、使用场景和数值效果。

物品引用统一使用 ID：

```text
对话：give_item:<item_id>:<count>
任务：QuestDef.reward_items
敌人：EnemyDef.drop_items / drop_random
```

招式放在 `game/data/skills/`，配置类型、内力、威力、目标、学习条件、动画 ID 和音效。武学界面只显示玩家已学会的 `skill_id`。

敌人放在 `game/data/enemies/`，配置属性、技能组、AI、掉落、金币、经验、战斗精灵、动作帧和音效。

## NPC 配置

NPC 分两层：

1. 全局档案：`game/data/npcs/npc_catalog.tres`。配置 `npc_id`、`display_name`、`default_dialog_id`、`sprite_path`、`movement_mode`（`idle`/`patrol`/`seated`）、`quest_ids` 和 `role`。
2. 场景摆放：`game/data/scenes/<scene>.tres`。只配置 `npc_id`、`pos`、局部缩放、`require_flag`、`hide_flag` 和局部行为覆盖。

同一个 NPC 出现在多个地图时只维护一份全局档案。当前历史场景仍有少量重复填写姓名、精灵和对话的旧数据；新增 NPC 不要继续复制这些字段。

NPC 对话会广播 `npc_talked_to:<npc_id>`，任务条件必须引用 ID，不要引用显示名称。

## 调查、证词与分支状态

调查内容分成“定义”和“存档状态”两层：

- 证物定义：`game/data/investigation/evidence/<evidence_id>.tres`，类型为 `EvidenceDef`。
- 证词定义：`game/data/investigation/testimonies/<testimony_id>.tres`，类型为 `TestimonyDef`。
- 玩家已发现、已验证、阵营信任、伙伴信任、关键关系事件、城市结果和办事手段统一由 `InvestigationState` 保存。

对话节点可直接配置：

```gdscript
add_evidence = Array[StringName]([&"ev_ch1_stone_warning"])
verify_evidence = Array[StringName]([])
add_testimonies = Array[StringName]([&"ts_ch1_bandit_claim"])
faction_trust_changes = Array[Dictionary]([{"id": "huashan", "delta": 5}])
companion_trust_changes = Array[Dictionary]([{"id": "yuewuheng", "delta": 8}])
bond_events = Array[Dictionary]([{"companion": "yuewuheng", "event": "shared_the_truth"}])
city_outcomes = Array[Dictionary]([{"city": "zhuwei", "key": "west_ruin_cleared", "value": true}])
method_flags = Array[Dictionary]([{"key": "spared_witness", "value": true}])
```

场景或选项也可使用 action：`add_evidence:`、`verify_evidence:`、`add_testimony:`、`verify_testimony:`、`faction_trust:`、`companion_trust:`、`add_bond:`、`city_outcome:`、`method_flag:`。任务条件支持 `evidence_acquired:`、`evidence_verified:`、`testimony_heard:`、`testimony_verified:`。

证物只记录可观察事实；人物说法必须建成证词，不能直接改写为系统真相。阵营信任与伙伴信任范围固定为 `-100..100`，感情线还必须检查 `bond_events`，不能只用一个好感数字决定结局。

## 新增场景和交互

1. 在 `game/data/scenes/` 创建 `SceneScript`，配置场景 ID、名称、背景、BGM、进场对话和地图 layout。
2. 在 `game/data/maps/` 配置可行走区域、建筑/树木/箱子脚底碰撞、交互区、出口和触发区。
3. 场景 NPC 只写 `npc_id + pos`。
4. 交互使用 action，例如 `dialog:xxx`、`battle:xxx`、`give_item:xxx:1`、`scene:xxx`。
5. 出口 `target_pos` 必须落在目标地图可行走区域内，不能只对准视觉门框。
6. 建筑、树木、门框需要层级时使用独立透明 `scene_objects`，碰撞只覆盖脚底。

剧情入口有两种表现语义：普通道路可保留锁定箭头并配置`locked_label`；密道、暗门、隐藏房间等会剧透的入口必须同时配置`require_flag`或任务门禁以及`reveal_only_when_unlocked=true`。后者在条件满足前不会生成箭头、标签、碰撞和触发区，条件变化后由Field场景刷新链即时揭示。

## 新增商店

在 `game/data/shops/` 创建 `ShopDef`，商品引用物品或装备 ID。NPC 或场景使用 `shop:<shop_id>` 打开商店，商品列表不要硬编码到 UI。

## 推荐制作顺序

新增一条完整支线：先准备道具/敌人 -> 创建任务 -> 创建 NPC 档案 -> 创建对话 -> 摆放 NPC 和交互区 -> 全文搜索 ID 确认引用一致。

## 验证

```powershell
& 'C:\Program Files\Godot\Godot.exe' --headless --editor --path game --quit
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_content_completeness.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_flow.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_balance.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_walkable_map_v2.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_investigation_state.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_ch2_investigation_flow.gd
```

涉及 NPC 或场景摆放时，还要用 `test/capture_ui.gd` 截图检查人物比例、碰撞、出口、对话和交互位置：

```powershell
# 截取野外场景 (检查 NPC 摆放、碰撞、出口)
godot --headless --script test/capture_ui.gd -- field=ch1_s2_qingfeng_walkable

# 截取战斗界面 (检查敌人/角色位置、HUD)
godot --headless --script test/capture_ui.gd -- battle=thug_lone

# 截取任务/技能面板 (检查 UI 控件对齐、贴图)
godot --headless --script test/capture_ui.gd -- scene=quest
godot --headless --script test/capture_ui.gd -- scene=skill
```

截图输出到 `screenshots/` 目录。可用于 AI 视觉对比——把截图发给 AI，让它判断控件是否错位、重叠、缺失。

## 什么时候需要改代码

只有新增全新的 trigger、action、物品效果、任务状态、NPC 行为或场景对象类型时，才需要修改 `game/scripts/`。如果只是新增任务、奖励、对话、NPC、道具、敌人、技能、商店或场景实例，不应修改核心管理器。

相关设计：[游戏数据索引](game-data-index.md)、[系统技术设计](system-technical-design-v0.1.md)、[可行走地图 V2](walkable-map-v2.md)、[世界观与剧情圣经](world-bible.md)、[道具总表](item-master-table.md)。

## 章节内容计划与多人遭遇

每个正式章节都要建立 `ChapterContentPlan`，集中声明主线场景、主线任务、支线任务、练级场景、剧情战编队和预计时长。正式章节最低标准是主线 60 分钟、全探索 120 至 240 分钟、4 个主线场景、3 条主线、5 条支线、2 个练级场景；第二章起还应覆盖2人和3人剧情战。

剧情战使用 `battle_group:enemy_a,enemy_b,enemy_c`；胜利后必须继续专属对白时使用 `battle_group_then:enemy_a,enemy_b:victory_dialog_id`。随机战在 `SceneScript.encounter_groups` 中按 `enemy_ids + weight` 配置1、2、3人梯度。不要把多个敌人拆成连续三场单挑，这会破坏群战资源、目标选择和群体招式的设计价值。

完整规范和第二至第四章清单见 [第二至第四章正式内容规划](chapter-2-4-release-content.md)。新增或修改章节后必须运行：

```powershell
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_2_4_content_depth.gd
```

## 第二章调查分支范例

第二章已经提供一套可复用的“证词冲突 -> 场景证物 -> 手段选择 -> 共同汇合”模板：

1. `ch2_zhuwei_intro` 获取公开证物“三张寻人启事”。
2. `ch2_market_investigation` 分别记录货郎、药铺掌柜、守村人的三份证词，不立即判定谁说谎。
3. `ch2_forest_route` 用血点和车辙证明几条路线同时存在，验证“每个人只说了一部分”。
4. `ch2_rescue_victory` 的两个 choice 分别写入 `method_flags`、悦无姮 `companion_trust_changes`、`bond_events` 和竹尾村 `city_outcomes`。
5. 两个 choice 都跳到各自短节点，再统一 `next:finish`，由公共节点完成任务和切回场景。这样分支改变调查资产与人物关系，但不会复制整条主线。

后续章节应优先复用这个结构。若选择只影响方法与关系，不要为每个选择复制完整场景链；若选择会永久改变城市、NPC 生死或主线入口，再建立独立场景和任务分支。
# 第三章五派调查范例

第三章采用“共享谜面 -> 门派入口 -> 偏向证词 -> 共同验证”的配置结构：

1. `ch3_assembly_intro.tres` 发放所有路线共享的 `ev_ch3_old_official_paper`，确保玩家先看到可验证事实，再听各派解释。
2. `ch3_faction_choice.tres` 的五个分支分别写入 `join_faction`、对应 `faction_trust_changes` 和一个 `method_flags` 调查权限。门派选择改变训练和信息来源，不删除其他城市与伙伴内容。
3. 五个门派完成对话分别记录本派证词。证词允许带立场、遗漏和误判，不能直接改写真凶 flag。
4. `ch3_training_result.tres` 让所有分支重新汇合并验证复合武学痕迹；`ch3_tomb_result.tres` 再用洛阳货运暗记验证共同证物，接到下一调查阶段。

第三章相关内容变更后必须运行：

```powershell
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_ch3_faction_investigation_flow.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_flow.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_investigation_state.gd
```

# 第四章洛阳双案范例

第四章采用“医学验证 -> 两项同时发生的危机 -> 方法选择 -> 古寺汇合”的配置结构：

1. `ch4_case_clue.tres` 同时添加物证和赵思颖证词，再由下一节点验证，形成首次明确的 `evidence_verified` 剧情节点。
2. `ch4_canal_result.tres` 的选择必须放在 choice 字典内写副作用。救证人路线添加活证口供、较高赵思颖信任和“共同救人”关系事件；追信使路线添加完整残卷、信使口供和“分工承担”关系事件。
3. 两条路线分别记录 `ch4_rescue_witness_first` / `ch4_pursue_courier_first`，以及不同洛阳城市结果，但都跳回 `finish`，完成同一任务并进入古寺。
4. `ch4_tunnel_result.tres` 负责共同收束：验证伪造工坊和押运名册、保留冒名首领活口，并继续隐藏幕后委托人。

第四章相关内容变更后必须运行：

```powershell
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_ch4_luoyang_dual_case_flow.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_flow.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_investigation_state.gd
```
