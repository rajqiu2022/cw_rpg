# 洛阳可进入室内候选（2026-10-15）

状态：仅 NEW 数据，未注册 Router、未改任何正式城区、未获引擎或实机通过。

- 3 个净化模板：小宅、普通大宅书房、客栈厅堂；不是豪宅套件。
- 9 栋原建筑各 1 个独立 Scene ID、独立 layout、独立返回门户。只共享视觉/家具几何，不共享返回状态。
- 所有旧图/旧 layout 只读。旧 NPC、对白、flag、箱子、奖励、章节入口都没有复制。
- `home_author.json` 是门→室内→同门返回的接入接口，并固定实际来源 SHA。
- 室外锚点来自当前 manifest 的实际 source foot_uv/world_foot_px/render_size，返脚为其南侧 24px，不是旧地图估算 UV。
- 九个返脚均只获 CPU 完整 875 鞋点及实 solid 局部净空；西/东 ward 前街到南侧 48px 的直连仍被原 plot wall 拒，保持 PENDING，不移动门或偷偷删墙。
- 源模块 foot 不等于全部可见门已验收，尤其复合沿街楼只选中心已测锚点。所有门仍 formal_enabled=false。
- 室内使用原 reviewed layout 的 legacy body-center 模式；返回城市 target_pos 明确为城市 visible-feet UV，不能混域。
- 当前 Router 只拼接顶层 Scene 文件。候选子目录需未来明确新 revision resolver 读 author.scene_path；本文不声称普通游戏已能进房。
- ROOT 可优先显式加载 `inn_room.tres` 与 `shop_room.tres`，实看家具比例/地板、正常步行到出口，再验证新门层的原门返回。不重复全六。

缺口：真正豪宅厅堂/卧房/园林仍缺；本候选不新增故事、NPC 或收费生成。
