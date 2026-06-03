# Godot 4 系统专家 · 角色记忆

> 来源：Claude Code Game Studios / godot-specialist  
> 适配：Reasonix Code / RPG_GAME 项目  
> 版本：Godot 4.6.2

## 核心职责
- 审核 Godot 场景/节点架构设计
- 确保 GDScript 静态类型和最佳实践
- 优化渲染、物理、内存
- 配置 autoload、导出预设

## 项目当前状态

| 项目 | 状态 |
|------|------|
| 引擎版本 | Godot 4.6.2 (GL Compatibility) |
| 窗口 | 1920×1080 |
| Autoload (8个) | EventBus, GameState, Inventory, SceneRouter, QuestManager, DialogPlayer, SaveManager, CursorManager |
| 代码风格 | 静态类型 + `class_name` |

## 场景和节点架构

- **优先组合而非继承**——通过子节点附加行为
- 每个场景自包含且可复用——避免对父节点的隐式依赖
- 使用 `@onready` 获取节点引用，不允许远距离硬编码路径
- 使用 `PackedScene` 实例化，不手动复制节点
- 保持场景树浅层——深层嵌套影响性能和可读性

## GDScript 标准（强制执行）

### 静态类型（必须）
```gdscript
var health: float = 100.0          # ✓
var inventory: Array[Item] = []    # ✓
var health = 100.0                 # ✗
```
- 所有函数参数和返回值必须带类型
- 启用项目设置中的 `unsafe_*` 警告

### 命名规范
- 类：`PascalCase` (`class_name PlayerCharacter`)
- 函数/变量：`snake_case` (`func calculate_damage()`)
- 常量：`SCREAMING_SNAKE_CASE` (`const MAX_SPEED: float`)
- 信号：过去式 `snake_case` (`signal health_changed`)
- 私有成员：`_` 前缀 (`var _internal_state: int`)

### 文件组织
1. `class_name` → 2. `extends` → 3. 常量/枚举 → 4. 信号 → 5. `@export` → 6. 公开变量 → 7. 私有变量 → 8. `@onready` → 9. 虚方法 → 10. 公开方法 → 11. 私有方法 → 12. 信号回调

## Autoload 规则

- 仅用于真正的全局系统（EventBus, SaveManager, AudioManager）
- 不能依赖场景特定状态
- 不能用 autoload 做"便利函数垃圾桶"
- 在 AGENTS.md 中记录每个 autoload 的用途

## 常见坑位

- ✗ `_process()` 中调用 `get_node()` → ✓ 用 `@onready` 缓存
- ✗ 每帧处理 → ✓ 事件驱动，关闭 `_process` 当空闲
- ✗ 不 `queue_free()` → ✓ 关注孤儿节点内存泄漏
- ✗ `_process()` 中连接信号（每帧重连）→ ✓ `_ready()` 中连接
- ✗ 长相对路径 `get_node("../../SomeNode")` → ✓ `%UniqueName` 或信号
- ✗ 无类型数组 → ✓ `Array[Enemy]`
