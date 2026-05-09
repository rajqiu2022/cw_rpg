# AI 开发硬规则（RPG_GAME）

> 目的：把 AI 开发从“临场发挥”改为“可控变更”。本文件优先约束所有后续 AI 协作，配合 `docs/agent-workflow.md`、`docs/module-owners.md`、`docs/experience-log.md` 使用。

---

## 1. 总原则

1. **先理解，再修改**：任何跨模块任务开始前，必须先读相关现状文档和目标文件，不能凭记忆改。
2. **小步变更**：一次只完成一个可验证目标；复杂需求拆成 5–15 分钟原子任务。
3. **读写边界明确**：动手前必须知道本次读哪些文件、写哪些文件；不能为了小功能顺手重构大文件。
4. **高风险文件先扫描引用**：改公共接口、资源路径、存档 schema、autoload、信号名前必须全库搜索引用。
5. **UI 正式视觉优先使用资产**：正式 UI、按钮状态、主菜单 hover 等视觉状态应由 `gpt-image-2` 或已入库 PNG 资产提供；程序层只负责热区、状态切换、排版和数据绑定。
6. **缺内容就占位**：缺剧情、数值、图标、头像时用 `TODO_*` 或占位资源，不允许 AI 私自编最终设定。
7. **验证后汇报**：每次修改后至少跑对应 lint / 搜索核对；能跑 Godot 时再做实机验证。
8. **踩坑要沉淀**：新坑写入 `docs/experience-log.md`；长期规则写入本文件或对应专项规范。

---

## 2. 每次 change 的最小流程

复杂任务按以下顺序走：

```text
change-id: <短横线命名>
目标: <一句话>
背景: <为什么做>
读文件: <本次需要读取的文件>
写文件: <允许修改的文件>
高风险点: <是否涉及 project/autoload/save/schema/signal/tscn/tres>
验收标准: <可检查条件>
验证方式: <lint / Godot / 命令 / 手测路径>
```

完成后输出：

```text
完成内容:
修改文件:
验证结果:
剩余风险:
下一步:
```

---

## 3. Godot 高风险文件规则

以下文件/模块属于高风险，修改前必须先说明原因并搜索引用：

| 类型 | 文件 / 模块 | 风险 |
|---|---|---|
| 项目配置 | `game/project.godot` | autoload、输入映射、分辨率、主场景会影响全局 |
| Autoload | `game/scripts/autoload/*.gd` | 全局状态、信号、存档、路由，影响所有场景 |
| 存档 | `SaveManager`、`Inventory.to_dict/from_dict`、`QuestManager.to_dict/from_dict` | 旧存档兼容风险 |
| 事件总线 | `EventBus` signal | 订阅方断连风险 |
| 场景文件 | `game/scenes/**/*.tscn` | 节点路径、unique name、信号引用易断 |
| 数据资源 | `game/data/**/*.tres` | Resource 字段、id、路径会影响加载 |
| 美术任务 | `prompts/tasks.yaml`、`prompts/templates/*.yaml` | 可能烧 API 预算、改变视觉风格 |

### 3.1 改高风险文件前必须做

- 搜索引用：`search_content` 查函数名 / signal / resource id / 节点名。
- 明确迁移：如果改 schema 或字段，必须兼容旧数据。
- 小范围替换：优先 `replace_in_file` 定点改，不重写大文件。
- 验证：至少 lint；涉及 `.tscn` 的要在 Godot 编辑器打开验证。

---

## 4. 禁止事项

1. 禁止用一行 Python 脚本批量改源码文件。
2. 禁止无确认执行破坏性 git 操作，如 `git restore`、`git clean`、`reset --hard`。
3. 禁止删除 `.codebuddy/`。
4. 禁止为 UI 使用浏览器原生弹窗；所有弹窗必须自定义 modal/dialog。
5. 禁止把参考图直接当正式图使用，除非用户明确允许。
6. 禁止把本地拼合图冒充 `gpt-image-2` 正式产出。
7. 禁止程序层临时画正式主视觉效果，除非只是 debug/占位；正式视觉状态必须资产化。
8. 禁止在未确认的情况下改世界观、NPC 名、武学名、任务奖励和数值曲线。

---

## 5. 验证最低标准

| 改动类型 | 最低验证 |
|---|---|
| GDScript | `read_lints` 对应文件 0 新错误 |
| `.tscn` 场景 | lint + Godot 打开无节点/脚本报错 |
| UI 交互 | 鼠标 hover / pressed / Esc / 快捷键手测 |
| `gpt-image-2` 出图 | dry-run 通过 + `.meta.json` 确认 `model=gpt-image-2`、`fallback_used=false` |
| 存档 | 新建、保存、读取、旧空槽都可用 |
| 战斗 | 进入战斗、四按钮、胜负结算、返回场景 |
| 背包/装备 | I/E 打开、使用、穿戴、卸下、Esc 关闭 |

---

## 6. 当前项目特别规则

1. 当前窗口目标为 **1080P：1920×1080**。
2. 主菜单正式图：`assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_main_menu_screen_gpt_v6.png`。
3. 主菜单 hover 状态必须走 `gpt-image-2` 整图：
   - `ui_cold_wuxia_main_menu_hover_new_gpt_v1.png`
   - `ui_cold_wuxia_main_menu_hover_load_gpt_v1.png`
   - `ui_cold_wuxia_main_menu_hover_quit_gpt_v1.png`
4. 当前 UI 亮度标准：**不能比 v6 / UI 模块 v2 更暗**。
5. 自定义鼠标资源在 `game/art/ui/cursors/`，由 `CursorManager` 全局注册。
6. UI 文案与视觉必须使用简体中文，不允许英文、繁体、乱码。

---

_最后更新：2026-05-07。_
