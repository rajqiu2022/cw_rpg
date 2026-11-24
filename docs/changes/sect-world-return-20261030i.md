# 烈云谷出场world_foot缺键 · 2026-10-30i

已修复，仅正式`town_registry.gd`的三条门派row各补一项`world_foot`，未改Router、native manifest、地图、任务或存档。

原因：30a将凌月派/烈云谷/茗雾山庄加入通用`IDS`，其row只有本地arrival/inner_arrival，没有原3城具有的world_foot。`SceneRouter.get_world_map_position_for_scene()`对所有注册ID直接读取该键，谷外出口调用go_world_map时因此报Invalid access。不是人物碰撞或新地图无法加载。

补充值逐一取正式v15地图原portal.pos×WORLD_SIZE（12288×8192），不新设地标或改原门：凌月(0.9358724,0.55306756)、烈云(0.8300781,0.9141463)、茗雾(0.9033203,0.9636981)。其余键/原14个注册ID都保，反删这三新键后全文精同原备。registry AA3FDF3B→494F7BEC；Router21CAF866/native6FE073B4保持，严格source_valid未放宽。

Root只跑这项回归：`game/build/sect_world_return_20261030i_root01/check_returns.gd`，进程41736自然0/67检查0。真实原Router方法对14ID×两World别名均返回有限坐标，三门派逐个匹配正式地图原portal目标和门脚，0Field/Actor/Input，checkpoint suspend。没有跑完整出谷旅行或其他城。旧七纹理/RenderingServer退出ERROR保留，不冒stderr干净。

fresh基线与末guard覆盖171真实save仅SHA/bytes/UTCticks、Router/native/project精同，0存档反序列化/写入；编辑器51856保留。本轮未停止任何用户进程。详细游玩交用户重启游戏后从谷外出口验证。
