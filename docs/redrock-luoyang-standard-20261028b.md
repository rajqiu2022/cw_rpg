# 赤岩生活街段与驿舍前厅 · 2026-10-28b

Godot打开[当前redrock_town.tscn](../game/scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn)，按 **F6**。进入关门后到驿舍门前按空格，进入一处[独立前厅](../game/scenes/drafts/redrock_luoyang_standard_20261028b/inn_hall.tscn)；前厅入口按空格原脚返回。WASD移动、Shift快走、Tab全景/跟随、1—6观察分区、Esc关闭说明。

本轮按[洛阳规范](luoyang-city-masterplan-20261019z.md)先完成生活街段：主街/次街/院巷分级，驿舍与牲口棚各有院门，修坊和水院有真院界。人物112px标尺与35×25脚体保持；房体、院墙与家具均有实际阻挡。赤砂岩平顶/木棚地域风格保持，不搬中原瓦檐。

![驿舍前厅原生渲染](../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/inn-hall-final.png)

## 本轮完成

- 四处院界使用同一完整原PNG的三个原生region视图分层，按后墙/侧墙/前墙落脚排序；未输出裁切PNG、未改alpha，三视图覆盖全原画布。
- 重排驿舍、牲口棚和货物/饮水槽，撤除挡院口的一处民居，移动三处岩台；主街320、次街200、院巷144为材质目标宽。新关键腿和主街左右肩已用完整35×25脚体实测；不把中心线通过冒称全域宽带净空。
- 驿舍一主门对应一处缓存前厅。同一角色进返，原位返回；室外地面、房屋、院墙与前厅实例保持。没有为了说明面板重建静态场景。
- 前厅柜台、桌、凳、酒茶架分别是独立原生节点/碰撞，木家具复用洛阳已入库原PNG，原像素保持；柜台/桌按成人尺缩小后，碰撞同步等比收缩，不留旧大体。
- 普通中年女掌柜新增地图待机与同人肖像；本地说明面板只做布局查看，非新正式NPC、剧情对白、付费服务或商店经济。仍无行走序列。

## 路径与使用状态

|资源|工程路径|原始PNG|当前消费者|
|---|---|---|---|
|赤岩·阶街平顶民居|[dwelling.png](../game/art/modules/redrock_luoyang_standard_20261028b/dwelling.png)|[来源](../assets/raw/redrock_town_20261028a/building/redrock_town_20261028a_dwelling_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·商旅牲口棚|[stable.png](../game/art/modules/redrock_luoyang_standard_20261028b/stable.png)|[来源](../assets/raw/redrock_town_20261028a/building/redrock_town_20261028a_stable_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·层台岩坎立面|[terrace.png](../game/art/modules/redrock_luoyang_standard_20261028b/terrace.png)|[来源](../assets/raw/redrock_town_20261028a/landform/redrock_town_20261028a_terrace_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·平顶商旅驿舍|[inn.png](../game/art/modules/redrock_luoyang_standard_20261028b/inn.png)|[来源](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_inn_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·商队修车棚|[repair_shed.png](../game/art/modules/redrock_luoyang_standard_20261028b/repair_shed.png)|[来源](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_repair_shed_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·蓄水井棚|[cistern.png](../game/art/modules/redrock_luoyang_standard_20261028b/cistern.png)|[来源](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_cistern_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·封口储水罐组|[water_jars.png](../game/art/modules/redrock_luoyang_standard_20261028b/water_jars.png)|[来源](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_water_jars_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·车轮轴木工作台|[wheelbench.png](../game/art/modules/redrock_luoyang_standard_20261028b/wheelbench.png)|[来源](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_wheelbench_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·风蚀旱树|[dry_tree.png](../game/art/modules/redrock_luoyang_standard_20261028b/dry_tree.png)|[来源](../assets/raw/redrock_desert_life_20261025a/vegetation/redrock_desert_20261025a_dry_tree_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·荒漠枯黄灌木|[dry_shrub.png](../game/art/modules/redrock_luoyang_standard_20261028b/dry_shrub.png)|[来源](../assets/raw/redrock_desert_life_20261025a/vegetation/redrock_desert_20261025a_dry_shrub_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·岩矿调查点|[ore_cluster.png](../game/art/modules/redrock_luoyang_standard_20261028b/ore_cluster.png)|[来源](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_ore_cluster_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·连体关楼核心|[core.png](../game/art/modules/redrock_luoyang_standard_20261028b/core.png)|[来源](../game/art/modules/redrock_joint_editor_20261023f/core.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·左墙岩肩|[left.png](../game/art/modules/redrock_luoyang_standard_20261028b/left.png)|[来源](../game/art/modules/redrock_joint_editor_20261023f/left.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·右转墙岩肩|[right.png](../game/art/modules/redrock_luoyang_standard_20261028b/right.png)|[来源](../game/art/modules/redrock_joint_editor_20261023f/right.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·查看员待机|[guard.png](../game/art/modules/redrock_luoyang_standard_20261028b/guard.png)|[来源](../game/art/modules/redrock_joint_editor_20261023f/guard.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·夯土材质|[earth.png](../game/art/modules/redrock_luoyang_standard_20261028b/earth.png)|[来源](../game/art/modules/redrock_joint_editor_20261023f/earth.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·望关台|[tower.png](../game/art/modules/redrock_luoyang_standard_20261028b/tower.png)|[来源](../assets/processed/redrock_gate_20261023b/tower/redrock_20261023a_tower_v1_padded.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·牲口饮水槽|[trough.png](../game/art/modules/redrock_luoyang_standard_20261028b/trough.png)|[来源](../assets/processed/redrock_gate_20261023b/trough/redrock_20261023a_trough_v1_padded.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·商队货垛|[cargo.png](../game/art/modules/redrock_luoyang_standard_20261028b/cargo.png)|[来源](../assets/processed/redrock_gate_20261023b/cargo/redrock_20261023a_cargo_v1_padded.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·裸岩材质|[rock.png](../game/art/modules/redrock_luoyang_standard_20261028b/rock.png)|[来源](../assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_rock_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·三面低院界|[court_wall.png](../game/art/modules/redrock_luoyang_standard_20261028b/court_wall.png)|[来源](../assets/raw/redrock_luoyang_standard_20261028b/building/redrock_luoyang_standard_20261028b_court_wall_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|赤岩·驿舍前厅空室|[inn_room.png](../game/art/modules/redrock_luoyang_standard_20261028b/inn_room.png)|[来源](../assets/raw/redrock_luoyang_standard_20261028b/building/redrock_luoyang_standard_20261028b_inn_room_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/inn_hall.tscn`；编辑草案|
|赤岩·驿舍女掌柜待机|[keeper_sprite.png](../game/art/modules/redrock_luoyang_standard_20261028b/keeper_sprite.png)|[来源](../assets/raw/redrock_luoyang_standard_20261028b/npc_sprite/redrock_luoyang_standard_20261028b_keeper_sprite_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/inn_hall.tscn`；编辑草案|
|赤岩·驿舍女掌柜同人肖像|[keeper_portrait.png](../game/art/modules/redrock_luoyang_standard_20261028b/keeper_portrait.png)|[来源](../assets/raw/redrock_luoyang_standard_20261028b/portrait/redrock_luoyang_standard_20261028b_keeper_portrait_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/redrock_town.tscn`；编辑草案|
|驿舍木柜台|[counter.png](../game/art/modules/redrock_luoyang_standard_20261028b/counter.png)|[来源](../game/art/modules/luoyang_assembled_interiors_20261016g/inn_counter_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/inn_hall.tscn`；编辑草案|
|前厅木桌|[table.png](../game/art/modules/redrock_luoyang_standard_20261028b/table.png)|[来源](../game/art/modules/luoyang_assembled_interiors_20261016g/dining_table_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/inn_hall.tscn`；编辑草案|
|前厅长凳|[bench.png](../game/art/modules/redrock_luoyang_standard_20261028b/bench.png)|[来源](../game/art/modules/luoyang_assembled_interiors_20261016g/long_bench_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/inn_hall.tscn`；编辑草案|
|前厅酒茶架|[shelf.png](../game/art/modules/redrock_luoyang_standard_20261028b/shelf.png)|[来源](../game/art/modules/luoyang_assembled_interiors_20261016g/wine_tea_shelf_v1.png)|`res://scenes/drafts/redrock_luoyang_standard_20261028b/inn_hall.tscn`；编辑草案|

[图鉴](equipment-skill-catalog.html#resources)新增32记录（4原图、28工程图），分类缩略/原图入口可查；多份有效草案引用的同一原图合并消费者，不覆盖旧28a消费者。

新4原图为内置image_gen各1次/无fallback/CLI；[独立完整提示词](../assets/staging/redrock_luoyang_standard_20261028b/production/prompts/tasks.yaml)。肖像派发前加地图待机为身份锚并再次真实renderer预检。4张完整A>0边距均FAIL保，原PNG未本地处理，不借其它批许可；装配进草案不等于正式美术准入。

## 验证与保护

独立GPU自然退出0，79检查0失败/3094运动采样：28贴图导入全RGBA精确，院墙分层/真阻挡、5条新路线往返及主街双肩，真实Space进厅/掌柜查看/返街与Esc恢复，同角色/原脚、静态节点和缓存前厅保持。QA路线用明确定位起点，不冒连续世界旅行。首报告头误写4Space（实际3Space+1Esc），仅纠正元数据，原报告另存，79检查原值保持。

最后只修桌台尺与观察镜头提示：2新家具负控+2张原图通过/空stderr，不重79检查或旧洛阳/关防矩阵。首隔离project颜色字面量缺前导0造成配置失败及导入叶不存在断言，原记录保留；修配置后导入/实机才为当前信用。

本批发布119新增文件，含28PNG/84专用导入叶、控制GD/UID、shader/UID和两Scene/清单。291保护项（含162save/备份）SHA/bytes/mtime首末同=True；旧28a、公共Router/Field/project/根tasks与用户编辑器不由本批改动。图鉴总4889项/2582图/2307音；非resources精同。

证据：[79检查](../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/verification.json)、[最后比例/提示](../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/verification-final.json)、[发布](../assets/staging/redrock_luoyang_standard_20261028b/publication.json)、[保护](../assets/staging/redrock_luoyang_standard_20261028b/protected-after.json)。

## 后续边界

2026-10-28c试玩修正：受控巡检兵已换为正式Player场景中的冷孤云，复用v7剑形态四向待机/行走，默认人物跟随。门兵仍是NPC；NPC行走与正式世界/任务服务待接。[修正与验证](changes/redrock-player-camera-20261028c.md)，旧79检查保历史。

当前为局部生活街段与一处前厅的编辑草案。民巷/完整外峡壁与台地收口、其他独立室内、正式世界接线、任务/经济与稳定NPC行走仍待；不能把本轮79项授为全城美术或全域通行终验。其他城市在各自目录施工，公共接线待统一串行整合。
