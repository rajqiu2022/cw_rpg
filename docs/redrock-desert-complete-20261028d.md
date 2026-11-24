# 赤岩关镇与关外商路 · 2026-10-28d

2026-10-29a同一场景已续改街坊生活：两间新民居、22组生活陈设与4名复用精灵巡行人物、砂岩街巷和四院铺地已写回，旧三阶分层保持。[当前街坊改造与资源路径](redrock-city-life-20261029a.md)。本页28d验证是历史基线，新增域以29a增量记录为准。

2026-10-28e用户发现主角被阶面整图盖住，已修正三处石阶的踏面/护墙分层及真实侧墙轮廓碰撞，41检查0失败、三阶真实W/S上下通过。上轮中央通行通过不代表显示验收完成，旧报告保留。[本次修正与原生截图](changes/redrock-stair-surface-20261028e.md)。

当前Godot场景：[redrock_town.tscn](../game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn)，打开后F6。默认正式主角冷孤云跟随视角；WASD/方向键移动，Shift快走，Tab全景/跟随，1—6城区观察，7关外商路，空格查看/进出房间，Esc关闭说明。旧28b保持历史版本，本次使用新28d。

本轮完成的是已确认赤岩六区和相连关外商路的可编辑地图装配。正式江湖大地图里仍没有赤岩入口，也没有新增剧情、战斗数值、收费服务或任务奖励；不能把地图装配完成说成整片沙漠正式游戏流程已完成。

![当前原生全景](../assets/staging/redrock_desert_complete_20261028d/town_project/artifacts/region_overview_current.png)

## 地图落地

- 保留已确认的连体关楼与两翼；西/东/北侧改用专门绘制的连续峡壁，城门及南端补五处原生岩坎接缝。退26块重复离散外岩，避免把独立石块排成城廓。地表延伸到岩壁底部，默认镜头不再露灰色空域。
- 阶街、望台和西巷三处石阶保持中央开放、两侧真实阻挡。主石阶按岩台高差统一放大到400px，侧墙碰撞同步落在可见侧墙，非放大人体/速度。四间民居换侧向双层轮廓，两处遮阳商棚放在实际可通行街面。
- 驿舍、牲口棚、井院与修坊保持四院分工。新增三只普通卧驼，饮水槽、货箱和人行线分开；关外商路、休息小驿、调查货箱及沙狐活动区在同一物理地图中连续可走。
- 驿舍前厅与一处阶街民居分别是缓存的独立原生场景。进出均保持同一主角与原室外脚位；民居新增卧榻/衣架独立碰撞，未将一栋门脸映射多个无关功能。
- 正式主角复用现有Player/v7剑形态；商旅和石匠使用原生16格图中的待机与三相行走，沙狐使用4格动物序列，均按帧数据固定脚底。石匠原图第二行仍朝右，左向由运行时flip_h实现，未重画/改PNG，不宣称四个方向全为独立新原画。
- 商旅/石匠均有同人肖像，普通工作者身份用于本地场景说明，没有新增正式NPC_ID、剧情对白或Boss身份。沙狐是普通动物地图表现，卧驼是非战斗驮兽；没有拿普通动物冒充剧情Boss。

![石阶与修坊](../assets/staging/redrock_desert_complete_20261028d/town_project/artifacts/stairs_follow_delivered.png)

## 资源路径与当前使用

|类别/资源|工程PNG|原始PNG|实际场景消费者|
|---|---|---|---|
|landform · 赤岩·外峡壁转角|[canyon.png](../game/art/modules/redrock_desert_complete_20261028d/canyon.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/landform/redrock_desert_complete_20261028d_canyon_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|landform · 赤岩·阶街连体石阶|[stairs.png](../game/art/modules/redrock_desert_complete_20261028d/stairs.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/landform/redrock_desert_complete_20261028d_stairs_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|building · 赤岩·侧向阶巷民居|[side_house.png](../game/art/modules/redrock_desert_complete_20261028d/side_house.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/building/redrock_desert_complete_20261028d_side_house_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|building · 赤岩·遮阳商棚|[market.png](../game/art/modules/redrock_desert_complete_20261028d/market.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/building/redrock_desert_complete_20261028d_market_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|animal · 赤岩·商队卧驼|[camel.png](../game/art/modules/redrock_desert_complete_20261028d/camel.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/animal/redrock_desert_complete_20261028d_camel_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|npc_walk · 赤岩·商旅四向待机行走|[merchant_walk.png](../game/art/modules/redrock_desert_complete_20261028d/merchant_walk.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/npc_walk/redrock_desert_complete_20261028d_merchant_walk_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|npc_walk · 赤岩·石匠四向待机行走|[worker_walk.png](../game/art/modules/redrock_desert_complete_20261028d/worker_walk.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/npc_walk/redrock_desert_complete_20261028d_worker_walk_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|enemy · 赤岩·沙狐地图序列|[fox.png](../game/art/modules/redrock_desert_complete_20261028d/fox.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/enemy/redrock_desert_complete_20261028d_fox_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|building · 赤岩·关外避风小驿|[waystation.png](../game/art/modules/redrock_desert_complete_20261028d/waystation.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/building/redrock_desert_complete_20261028d_waystation_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|scene_prop · 赤岩·商路调查货箱|[caravan_props.png](../game/art/modules/redrock_desert_complete_20261028d/caravan_props.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/scene_prop/redrock_desert_complete_20261028d_caravan_props_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|portrait · 赤岩·商旅同人立绘|[merchant_portrait.png](../game/art/modules/redrock_desert_complete_20261028d/merchant_portrait.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/portrait/redrock_desert_complete_20261028d_merchant_portrait_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|portrait · 赤岩·石匠同人立绘|[worker_portrait.png](../game/art/modules/redrock_desert_complete_20261028d/worker_portrait.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/portrait/redrock_desert_complete_20261028d_worker_portrait_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|scene_prop · 赤岩民居·卧榻|[bed.png](../game/art/modules/redrock_desert_complete_20261028d/bed.png)|[原PNG](../game/art/modules/luoyang_assembled_interiors_20261016g/household_bed_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/home_room.tscn`|
|scene_prop · 赤岩民居·衣架|[cloth_rack.png](../game/art/modules/redrock_desert_complete_20261028d/cloth_rack.png)|[原PNG](../game/art/modules/luoyang_assembled_interiors_20261016g/garment_rack_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/home_room.tscn`|
|landform · 赤岩·西侧连续峡壁|[west_bank.png](../game/art/modules/redrock_desert_complete_20261028d/west_bank.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/landform/redrock_desert_complete_20261028d_west_bank_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|landform · 赤岩·东侧连续峡壁|[east_bank.png](../game/art/modules/redrock_desert_complete_20261028d/east_bank.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/landform/redrock_desert_complete_20261028d_east_bank_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|
|landform · 赤岩·北侧连续峡壁|[north_bank.png](../game/art/modules/redrock_desert_complete_20261028d/north_bank.png)|[原PNG](../assets/raw/redrock_desert_complete_20261028d/landform/redrock_desert_complete_20261028d_north_bank_v1.png)|`res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`|

共15张本轮新原图、17张新工程图（另两张为既存原生家具复用）。既存28张赤岩组件继续通过原路径引用；清单中记录其依赖SHA，不重复导入或改写旧PNG。图鉴按建筑、地貌、场景物件、NPC行走、立绘、驮兽与野外动物分组，并保留缩略图/原图放大入口。共享旧图的当前消费者同时保留28b和28d。

[资源图鉴](equipment-skill-catalog.html#resources) · [工程清单](../game/art/modules/redrock_desert_complete_20261028d/resource-pack.json) · [完整提示词队列](../assets/staging/redrock_desert_complete_20261028d/production/prompts/tasks.yaml) · [原生帧区域/脚锚](../game/art/modules/redrock_desert_complete_20261028d/atlases.json)

15张均为内置image_gen各1次，无CLI/fallback；原始输出字节复制进项目，模型/provider/费用未由工具返回，元数据保持null。全部原图完整A>0留白仍未达10%：原失败不洗白、未做本地清alpha/扩画布/裁PNG，不能因此宣布正式美术A1终验通过。帧和院墙仅使用Godot原生region，不输出裁切后的新PNG。查看器显示alpha0隐藏RGB雾色不等于游戏里有背景；西/东壁及石匠立绘原alpha_max254保持。

## 检查与结果

- 首次GPU122256自然退出1，66检查/2失败/6477运动采样，完整报告和原图保留：石匠驻点压通路、西巷石阶侧墙压横巷。64个成功组件中原离散岩负控已随组件退休，不继续授信用，其余63成功继承。
- 修复石匠巡行带2590→2660、西巷石阶1190→1250并替换连续峡壁后，13544自然0/24检查0失败/1549运动采样：仅修后两路、3新图RGBA、六壁与保留路线足体余量分离、新峡壁负控、两次真实Space肖像及Esc、石匠和沙狐实际物理行走。
- 五接缝及主阶高差后64352自然0/10检查0失败/104运动采样：新阶中央与侧墙、接缝域分离及局部原生图。原`stairs_delivered.png`检查镜头被持续physics覆盖，实际是城门图，原图保；37076仅改地面UV采样后补3张准确原生图，自然0/空stderr，不重成功几何/导入矩阵。
- 首次通过组件包括14新图RGBA精确、关门至望台/水院/驿舍/马院与新7条路线、两房间真实Space进返、同角色原脚/静态保持、真实W键主角走动与正确上行纹理、商旅实际物理巡行。最终3新图加前14图为17新增工程图RGBA准确。独立项目实测不等于正式World/存档/战斗验收。
- 新发布79文件，含17PNG和51专用导入叶、两GD及UID、shader及UID、atlas数据、三Scene和清单。205保护路径（含162save/备份）SHA/bytes/mtime首末同=True；公共Router/Field/project、旧赤岩、洛阳/汴州和根tasks不写，不运行主工程全量import，不停止用户编辑器。

证据：[首FAIL](../assets/staging/redrock_desert_complete_20261028d/first-runtime-failure/verification-complete.json) · [残余](../assets/staging/redrock_desert_complete_20261028d/town_project/artifacts/verification-residual.json) · [接缝](../assets/staging/redrock_desert_complete_20261028d/town_project/artifacts/verification-edges.json) · [发布](../assets/staging/redrock_desert_complete_20261028d/publication.json) · [保护](../assets/staging/redrock_desert_complete_20261028d/protected-after.json) · [图鉴核对](../assets/staging/redrock_desert_complete_20261028d/catalog-verification.json)

## 正式接入边界

此次完成编辑器地图版及本地互动。赤岩在正式世界缺少已确认城市ID/地理定位与剧情配置，不能私自覆盖现有世界节点或把西域地标改成新城。正式入口、存档导航、剧情任务、收费服务、动物战斗及剧情Boss接线留在后续明确整合范围；当前不冒这些已完成，也不借洛阳/汴州已有权威包信用。
