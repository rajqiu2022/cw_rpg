# 2026-11-02b 入口箭头与名称的场景顶层显示

目标：修复用户截图中林西村采药房入口文字被坛罐遮盖，并按同一原因处理实际共享入口消费者。

## 范围与保留

- 只调整 `ExitZone` 的 `MarkerVisual`、`Prompt`、`Indicator` 显示深度；普通入口、World 入口、城内配对入口及动态生成入口共用规则。
- 三显示节点使用世界 Canvas 内绝对最高深度 4096，高于现有 4095 人物遮挡影像。HUD、对话与菜单仍使用更高的 CanvasLayer，不被入口覆盖。
- 保留 Area2D、碰撞、入口/返回坐标、路由、锁定/显隐、箭头颜色动画、文字排版、素材和角色层级。
- 新增独立显示适配器及 project.godot 一个 autoload；不修改原 ExitZone、Field、Router、布局、NAV、来源闭包及美术媒体。
- 不访问真实存档内容、不进行原 171 路径矩阵、旧旅行或整城复验；编辑器保留。

## 验证计划

1. 实际 ExitZone 小范围结构测试：负深度祖先、高深度物件、动态加入与现有显示状态/碰撞不变。
2. 林西采药房原生正常镜头一张截图，公开 near 只用于取景，不冒充实际旅行。
3. project 单行精逆与本批有限原源首末比对。结果待 Root 实际执行后追加。

本项是信息遮挡修复，不代表建筑、地面或全城美术重新验收。

## 实际结果：已正式接入，停止局部复验

- 新适配器 SHA256 `a9a90e73b9e4c9a5961ce3b789740b9c3a2ddbac8bbbcb85a54175914fb25e48`；project 新增唯一 `EntranceOverlayRuntime` autoload 行，当前 SHA `3d5535bbaa8796f91458ec6298fdd02481df8860810c6889cc5e965fdf9ef26b`。删除该精确行后与本批 fresh project 全文字节一致，原先用户改动保留。
- Root 实际结构进程23860自然退出0：[17检查/0失败](../../game/build/entrance_overlay_20261102b_qa01/actual_structure/23860/result.json)，负祖先、4095遮挡、晚新增节点、晚写4095后的纠正、原变换/透明度/范围信号通过。结果SHA `3f6d8b8286f045da4c631d457399fe10765b65815b8c52ebecd8ea5d8b121865`。
- Root 实际正常画面进程132008自然退出0：[12检查/0失败](../../game/build/entrance_overlay_20261102b_qa01/actual_normal/132008/result.json)，结果SHA `da7791678dcfaf9e219e3bb4491640a820efaf4c96fb70a847c82a6f734b8db1`。林西村中采药人家门2790,2148、Jars2原2935,2145和原镜头zoom.9保持；公开near3150,2220仅取景，0输入/不冒连续旅行。
- [现役正常图](../../game/build/entrance_overlay_20261102b_qa01/actual_normal/132008/linxi_herbal_entrance_overlay_normal.png) SHA `bfedabfdd6286ed6d888e78b1b18554078d8f608d4789328369c7e20c7f6e374`：Root亲看文字完整压过原罐子，箭头同在顶层；图中人物、建筑、地形仍原样。实际文字/箭头绝对4096，道具536，HUD Canvas40在上，18显示节点已登记。仅本域接受，不冒全部场景逐图审美通过。
- fresh首末有限5旧源（ExitZone/通用Field/Router/四聚落Field/CityNavigation来源manifest）全部SHA一致；无旧严格闭包或媒体更改，无真实存档内容访问，也未进行旧171矩阵。两个自有引擎自然退出；未操作用户编辑器。
- 保留结构fixture脱树重加Prompt的owner WARNING（生产适配器不reparent）及退出ObjectDB WARNING；正常进程保留既有7纹理退出ERROR、ObjectDB及resource退出警告，不宣称stderr干净。没有为清理旧退出警告重跑成功范围。

真实同类消费者与晚写来源见 [实现范围](../../game/build/entrance_overlay_20261102b_runtime01/PLAN.md)。所有使用同一ExitZone合同的现役及后创建入口均应用显示规则；其他物件名称、任务文字与自定义非ExitZone交互标记不在本批。
