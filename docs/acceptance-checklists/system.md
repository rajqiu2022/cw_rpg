# Godot 系统验收清单（system）

> 适用对象：autoload / scene / UI / domain 改动提交前的自检。

## 必过项

- [ ] Godot 编辑器无 Parser Error / Resource Load Error。
- [ ] `game/project.godot` autoload 列表与脚本实际存在的文件一致。
- [ ] 新增 / 修改 autoload 信号时，所有订阅方都已同步更新。
- [ ] `SceneRouter.resolve_action()` 支持的 action 字符串列表更新到 `docs/design-mvp-chapter1.md` 或注释里。
- [ ] `SaveManager` schema 升版必须：
  - [ ] 提供旧版本迁移函数
  - [ ] 把版本号写进主菜单或日志
  - [ ] 在 `docs/experience-log.md` 留一条变更记录
- [ ] `Inventory` / `Equipment` 槽位字段变更已更新存档 schema 与 UI。
- [ ] UI 字符串没有硬写「沈不归 / 清风镇」等旧名。
- [ ] 没有把背景路径硬写成 `res://art/...`，且尊重 `FallbackBg` 兜底逻辑。

## 自动化

- [ ] `game/tests/test_inventory_m5.gd` 通过（如本机有 `GODOT_BIN`）。
- [ ] 主菜单「新游戏」与「继续游戏」都能进入 Field 不报错。

## 提交时附带

- 改动文件清单
- 是否破坏旧存档（如是，给出迁移说明）
- 是否需要 art 先入新资源（如是，列出依赖资源）
