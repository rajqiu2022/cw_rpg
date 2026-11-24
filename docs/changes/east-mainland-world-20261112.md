# 东大陆与外海航线 · 施工设计

状态：本文是总规和概念图；[第一批可玩接入](east-mainland-first-build-20261112.md)已按独立东部地图落地，[第二批](east-mainland-unified-chart-20261113.md)已合并 M 键总览。两块可玩区域仍分别加载，不迁移旧坐标。

[大地图概念图](east-mainland-world-20261112.png)

## 海陆布局

- 西部保留现有主线地图与五桥，东岸展开为纵贯南北的外海；保留东海埠的离岸小岛身份。东大陆是一整片继续向东延展的陆地，有河谷、山地和沿岸聚落，不是再加一座小岛。
- 船路分两段：**白鹿渡 ⇄ 东海埠 ⇄ 潮门港**。潮门港只开放与东海埠的回船；既有白鹿渡往返不改。不把海上航线绘成道路，不新增陆桥、浅水步行或快捷瞬移。
- 潮门港上岸后可沿陆路去沧浦城、盐湾村和茶岭村。东大陆陆路在本陆块内部连通，返程仍走港口。

| 地点（暂名） | 布局与用途 |
| --- | --- |
| 潮门港 | 东大陆西岸避风湾，码头与商货院相接，登船点和通往内地的驿道分开。 |
| 沧浦城 | 河湾内陆城，以水陆货运和驿站为中心；桥与城门之间留前坪。 |
| 盐湾村 | 南湾渔村，晒盐场、网棚和沿潮线展开的住宅。 |
| 茶岭村 | 北部缓坡，梯田、茶作坊和错落住宅沿山路布置。 |

## 正式接入边界

1. 现役坐标 16 的世界尺寸为 12288×8192，地形块为 1536×1024。施工基线采用向东扩到 18432×8192 的候选：西域像素坐标原点不挪；旧归一化世界脚先换回像素，再按新尺寸归一化。新坐标版本须单独识别，旧坐标不直接套用。
2. 正式走区、分块纹理、高程、总览和右上小地图要用同一份海岸几何。概念图不当遮罩或可走底图。整幅海域须做陆地连通域检查，防桥、窄浅滩和画布边缘偷渡。
3. 用实际到岸点关联港口→海图与港口→驿道。港口、城市与两个村庄都要先有各自正常可走的场景、入口和反向返脚，再公开地图标记。保留现有已发现标记和正式源校验，先验原两港往返，再验新航段和四个聚落。

[候选海岸、路网与地点坐标](../../game/build/east_mainland_20261112/authoring_candidate.json)：26 个海岸控制点、四处候选聚落、一组分岔驿道。对候选折线做 1,071 次路宽采样，未越过岸线；四处地点的候选路网相通。候选东岸距现役地图最东界至少 2,592 世界像素。此为数据检查，不是运行时碰撞、真实通船或新版坐标迁移验证。

## ImageGen 源记录

内置 imagegen；无修改像素。原件保留于工具生成目录，项目内 PNG 是原件的字节副本。该图是总规视觉参考，不能据此说新大陆已接入。

原提示词：

```text
Use case: stylized-concept
Asset type: environmental layout concept for a wuxia RPG overworld, not a UI screenshot
Primary request: design an enlarged world showing a central Chinese-fantasy mainland on the left, a broad eastern sea, and a substantial new continent across that sea on the right.
Composition: landscape about 2:1, elevated near-top-down orthographic cartographic game view. Western mainland about 51% of frame with the existing geographic rhythm of north mountain range, northwest arid lands, winding west-east rivers, valley roads, market towns, fields and forests. Open slate-teal sea occupies a full 20% wide uninterrupted north-to-south gulf. One small island harbor well off western coast, visibly detached from both mainlands; no land bridge, causeway, walking path or chain of islands. The new eastern mainland fills the rightmost 29%, continuing beyond right frame; a west-facing sheltered stone port on the mainland with a quay, a larger walled city inland on a river bend, a small fishing village at the southern inlet, and a hillside tea village on the northeast ridge, connected by winding pale tracks only on land. Tiny wooden junk on sea for scale, no plotted line or text.
Style: realistic rendered terrain and miniature grounded historical timber and stone architecture with subtle natural light; restrained moss green, buff earth, grey rock and muted blue water, readable at minimap size; gentle shoreline foam, tidal shallows, river delta; no empty uniformly flat lime grass.
Constraints: no text, no symbols, no border, no HUD, no compass, no mountains raised so high they obscure settlements. The sea is an ocean separating two significant landmasses, not a narrow river.
```
