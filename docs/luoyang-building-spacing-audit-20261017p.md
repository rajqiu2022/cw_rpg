# 洛阳建筑间距只读审计 · 20261017p

状态：独立只读盘点，未运行Godot、未修改生产、PNG、碰撞、门户或存档。用户截图 `codex-clipboard-8045a4c7-9097-45cb-a68e-c7622ce96c80.png` 已实看。本文记录的是本轮重排前的现役组装链；SYSTEM正在制作的撤重复仓child尚不作为现役通过。

## 方法与证据边界

- 四区坐标均为世界3072×2048；Temple作者源1536×1024、实际cover1920×1280，不能混域。房屋画布框按 `world_foot − foot_uv×render_size` 求左上角，再加render_size；District替图按独立source anchor／foot／scale覆写，h办公楼按XY非均匀scale覆写。
- 本次只读原PNG的RGBA alpha>0与alpha≥240包围范围（Windows System.Drawing LockBits）。后者仅作主体候选筛选，不擦透明尾、不调整阈值或导入，也不是“真实屋檐多边形”证明。框相交不自动判穿插，阴影／极低alpha尾与主体分域；只有用户实图对应的三叠为可见穿插实证。
- 城墙分段、城门／角台／桥栏、同一明确街面连件允许连接；不能因图片都叫street_row，就把不同可入门功能建筑自动说成同栋。

## 实际来源链

| 区域 | 现役最终布局依据 | 本次额外投影 |
|---|---|---|
| 城门 | `game/build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s0_luoyang_gate/manifest.json`（F43386CE） | District D98C陈设，人流；原城防与街面保持 |
| 码头 | 同目录 `ch4_s2_canal_docks/manifest.json`（0470E79B） | h author DC8D只替`harbour_cargo_trade_front`视觉；District陈设，不移原房屋 |
| 南市 | `game/build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s3_luoyang_market/manifest.json`（EAC64463） | District只替药摊与追加陈设 |
| 府衙 | `game/build/luoyang_yamen_annex_publication_20261016/84632_1726/manifest.json`（B606F491） | District `author.json`（D98C6587）替两厢房；东视觉脚2610，原record／solid脚2640不能混说移动整楼 |
| 古寺 | `game/data/maps/luoyang_temple_assembly_20261016/author.json`（D03AA28B），现Temple v9绑定 | 1主殿＋佛／钟／坛／残墙／竹石，不是多栋住宅 |

## 可复查清单

画布范围格式为`[left,top → right,bottom]`，只是筛查框，非碰撞范围。

| 区域／结论 | 实际ID与脚点 | 画布范围／问题 |
|---|---|---|
| 码头，**用户实图确认三叠** | `north_canal_warehouse`(870,580)；`harbour_main_warehouse`(1450,650)；`harbour_quay_supply_shop`(1930,530) | 老仓[320.06,142.28→1419.94,692.22]；主仓[968.88,130.44→1921.20,765.32]；右铺[1530,153.20→2144.40,562.80]。主仓分别交451.06×549.94、391.20×409.60；实图檐／墙体穿插，不是仅阴影。h办公楼在(1720,1790)，不是图中主仓。 |
| 码头，下一组主体候选 | `south_canal_front`(560,1600)；`harbour_small_cargo_store`(500,1130)；`harbour_rope_shop`(720,1420) | 分别[45.44,989.63→1074.56,1675.71]、[-49.94,692.28→1049.94,1242.22]、[295,1019.65→947.80,1454.85]。南街面与绳铺框整652.80×435.20相交，opaque-core框仍交；是否同栋必须明确，否则需后续实图分开。 |
| 码头，小件候选 | `dock_notice`(1400,1500) ↔ `harbour_cargo_trade_front`(1720,1790) | h办公画布[1345.22,1258.24→2094.78,1954.56]与公告亭交193.02×184.32；不能把公告亭误计住宅，但门前视线应核。 |
| 南市，西北／东北候选 | `market_northwest_rear_frontage`(620,500) ↔ `inn`(735,830) ↔ `north_market_front`(1536,630)；`market_northeast_rear_frontage`(2530,500) ↔ `shop`(2320,850) ↔ `market_east_ward_frontage`(2550,1260) | inn框[258.84,232.94→1211.16,867.82]；NW后排[236,44.50→1004,556.50]，交745.16×323.56。shop与NE后排交442×177.50，与东街面交452.72×122.94；core框仍部分交，未以此冒新GPU视觉FAIL或PASS。 |
| 南市，南侧候选 | `southwest_market_front`(520,1700) ↔ `market_west_ward_frontage`(510,1480) ↔ `assembled_market_backlane_row`(1010,1660)；`southeast_market_front`(2680,1700) ↔ `market_east_ward_frontage` ↔ `assembled_market_warehouse_edge`(2760,1450) | 西南与西街面框交829.44×198.02；东南与小仓边框交473.47×247.47。独立房门／功能不能被“同素材”豁免；需按cluster再看实际檐与巷道。SW旧假中柱门仍禁，不能为了间距补数重开。 |
| 府衙，避免透明尾误报 | `magistrate_hall`(1536,620)；西厢`assembled_west_service_annex`(590,1110),.50；东厢`assembled_east_service_annex`视觉(2610,1210),.46 | 主殿画布[721.92,-211.04→2350.08,874.40]与两厢画布交，但主殿alpha≥240 core约[924.38,30.64→2147.62,622.12]，西厢core[210,754.50→785.50,1110]、东厢core[2260.40,882.94→2789.86,1210]不交。不可按整画布判独栋撞屋。 |
| 府衙，公告亭候选 | `notice_pavilion`(550,1180) ↔ 西厢(590,1110) | 两source core框仍交约239×100；亭非住宅，但公告／厢房门前不能互遮。`v11_yamen_*`墙段与`south_court_gate`是围合连件，列明确连接allowlist，不按独栋误报。 |
| 城门，未发现独栋框交 | `west_street_front`(650,420)；`north_court_boundary`(1536,500)；`east_street_front`(2422,420) | 街面画布x[300,1000]／[2072,2772]，中门x[1136,1936]，横缝各136px。墙／角台／桥栏属于刻意接合；不能拿其框交变成新住宅问题。 |
| 古寺，非住宅群 | `temple_main_hall`(768,520),.56 | source1536×1024／anchor(768,880)，source场景框[337.92,27.20→1198.08,600.64]，转实际world再×1.25。其余独立物件不是第二屋；不能宣称21件就是21建筑。 |

## 薄验收标准与本轮修复边界

1. 独立建筑的可见屋檐／墙体应有可辨间隔，重排先以约96世界px为保守目标；alpha1尾／阴影另记，不按此强行扩大PNG或缩人体。当前仅撤Docks无门重复主仓的候选，老仓与右铺全A>0实际横缝约117.5px；不借此宣称其余码头／南市全部修完。
2. 主街／巷道须真实34×24连续体、rounded875＋17／≤4px完整段，门轴前保通，门口Area／普通Space／return脚与绘制门一致。碰撞可走不等于可见建筑不挤。
3. 若移动建筑，sourcefoot／render／native depth／solid／NAV／NPC与door approach必须同原子一致；只挪Sprite不能通过。低件不透明、人物局部ghost，高件只在真正遮挡时淡化；前方与恢复状态另断言。
4. 本审计没有新Physics、入口或美术全通过信用；使用Root唯一后续小测，不跑五城总回归。用户editor102696／game102312仍在，QA不停止它们。

## 十个新室内后续薄键（未执行）

- `game/tests/test_luoyang_assembled_rooms_actual_20261017p.gd`为NOTREADY。Root批准共享180秒whole／每房60秒arrival，十房独立记录＋十张真实组件图＋59件；使用正常public房间入口，重点确认客栈／民宅同ID实际已选g新Scene路径，不只看资源存在。
- 复用既有`luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd`／INPUT与有限保存守护，不重2140／5072／71路／28导入或旧smith四站。每房出生独立875/17／34×24、child0、真实Physics；inn／small_home少量16px正常输入；单独各一LOW/HIGH代表走位与自然帧、柱禁止区和原NPC脚域。
- 当前g普通仍false，仅原smith已按旧16b独立件正式接受；其余旧ID可路由旧内景，不等于十新组装运行。p的9E8E候选只是单bool，不可提前说已部署或GPU通过。
- 三新外门Space／Physics／精确返脚另原子待办，绝不把十房直入截图冒三门通过；用户退出且Root原显存门槛满足前不启动GPU。
