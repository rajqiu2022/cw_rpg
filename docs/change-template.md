# Change 变更模板

> 用途：每次较大功能或高风险修改前，先按此模板建一个 change 说明。可直接复制到 `docs/changes/<change-id>.md` 或本次任务说明中。

---

## 0. 基本信息

```yaml
change_id: <kebab-case-id>
owner: producer/system/battle/art/lore/qa/review
created_at: YYYY-MM-DD
status: proposed | in-progress | testing | done | archived
```

一句话目标：

```text
<本次变更要达成什么>
```

---

## 1. 背景 / 问题

- 当前现象：
- 为什么要做：
- 不做的影响：

---

## 2. 范围

### 2.1 In scope

- [ ] 
- [ ] 

### 2.2 Out of scope

- [ ] 
- [ ] 

---

## 3. 读写边界

### read_files

```text
- 
```

### write_files

```text
- 
```

### 禁止修改

```text
- 
```

---

## 4. 高风险检查

| 检查项 | 是否涉及 | 说明 |
|---|---:|---|
| `game/project.godot` | 否 | |
| Autoload | 否 | |
| `EventBus` signal | 否 | |
| 存档 schema | 否 | |
| `.tscn` 节点路径 | 否 | |
| `.tres` Resource 字段 | 否 | |
| 资源路径 | 否 | |
| `prompts/tasks.yaml` 烧钱任务 | 否 | |

如任一项为“是”，必须先做全库引用搜索：

```text
search_content: <symbol/resource_id/path>
```

---

## 5. 设计方案

简述实现方式：

```text

```

复用已有抽象：

```text
- EventBus:
- SceneRouter:
- WuxiaTheme:
- SaveManager:
- Inventory / QuestManager:
```

是否新增抽象：

```text

```

---

## 6. 任务拆解

> 每个任务建议 5–15 分钟，可独立验证。

- [ ] T1：
  - write_files:
  - verify:
- [ ] T2：
  - write_files:
  - verify:
- [ ] T3：
  - write_files:
  - verify:

---

## 7. 验收标准

- [ ] 功能可用：
- [ ] UI/交互：
- [ ] 数据/存档：
- [ ] Godot 无运行时报错：
- [ ] lint 无新增错误：
- [ ] 1080P 下显示正常：
- [ ] 如有出图，`.meta.json` 可追溯：

---

## 8. 验证记录

```text
命令 / 操作：
结果：
截图 / 日志：
```

---

## 9. Review 记录

- 代码风险：
- UI 风险：
- 存档/数据风险：
- 是否需要写入 `docs/experience-log.md`：

---

## 10. Lessons

```text
本次学到的长期规则：

```

---

_最后更新：2026-05-07。_
