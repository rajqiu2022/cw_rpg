# 城内小地图简洁半透明底板

状态：已正式合入，单图亲看通过。

用户要求替换厚重装饰框为简单半透明效果。本轮只改城内小地图背景绘制：不再绘制厚白银PNG框，采用贴近实际地图范围的深色半透明底板和低对比细边。实景缓存、地图透明度、玩家/门户标记、位置与GM避让保持，不改世界地图框或其它HUD。

这是用户明确要求的简单原生样式，不新生图片或加工PNG。只做必要来源后继和一张当前宅园实景检查；30c已通过的缓存/移动/远楼等成功结果继承，不重跑。

现役cityhelper `5088D2E6` 只在完整旧C125正文末追加 `_draw`：底板 `_map_rect.grow(8)`，深蓝黑alpha=0.50，1px低对比边alpha=0.26；不调用旧FRAME、不调整widget整体alpha。实景贴图和玩家/门户标记清晰度保持。

正式Router `740B12B7` / Region manifest `9F628C39`。24目标逐冻结候选SHA一致，只有既有小地图源码及必要现存SHA来源头后继；旧cache E700、三Field/CT、花园、十bin/碰撞/门户、World小地图都保持。新Router不可变快照遵循原`luoyang_`前缀准入，不放宽guard；旧逆边和keys保留。补丁使用apply_patch，混CRLF相邻行仅在忽略CR全文相同断言后机械恢复候选行尾。

唯一实际 **137692** 自然退出0，**97检查0失败、0INPUT、一张正常宅园图**；Root确认白银雕花框及大白边已消失，底板能透见树木和地面，地图/标记保持。没有重测旧346/94或其它城市。原七条退出Texture/RenderingServer ERROR与ObjectDB warning保留，不称clean。

末 `final_guard_ROOT_ACTUAL.json` SHA `FB9DFC94`：81个本地来源、24份全文备份、171份最新存档SHA/bytes/UTC ticks一致；四并发路径从开始record-only。仅用户编辑器51856保留，自有进程自然退出。停止成功组件复测，重新运行游戏生效。

![简洁半透明小地图框](../../game/build/city_minimap_simple_frame_20261030d_qa01/actual/137692/simple_translucent_minimap_frame.png)
