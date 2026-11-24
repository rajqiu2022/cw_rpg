# 华山派：险峰剑院室外首版

用户在三派总规后要求“继续改造其他场景”。按既定华山→古峰→凌月顺序，本批将华山总规落为独立可编辑场景。保留武当/茗雾和旧正式华山地图，未切换正式世界入口。

## 打开与操作

[huashan.tscn](../../game/scenes/drafts/huashan_map_20261029m/huashan.tscn)，打开后F6。默认正式冷孤云跟随、四向待机和行走；WASD/方向键移动，Shift快走，Tab全景/跟随，空格查看附近物件说明，Esc关闭，R返回山口。

5800×5000设计范围内设山门石径、练剑前坪、主堂剑院、弟子居舍、论剑台、思过崖六区，37组物件。场地收为不规则山脊，25段真实外缘阻挡；高程0/240/480，5处必经阶口连接上下层，坡面内连续抬脚，侧墙阻挡横穿。主堂与生活建筑使用同源楼层脚点；地形、阶面与边界保存为原生节点，重开不重复生成或二次抬高。

## 资源、路径与当前使用

八个新组件：五开间主堂、双柱山门、弟子长舍、窄面两层书舍、灶房柴棚、剑架、竖裂花岗岩、细灰石地面。建筑通过开间、楼层与用途区分体量；剑架是可放进场景的实体陈设，无装备/奖励绑定。山门中央通口保留，只两侧柱脚阻挡。

- 原图与完整提示词索引：[manifest.json](../../assets/raw/huashan_map_20261029m/manifest.json)。生产提示词保存于`assets/staging/huashan_map_20261029m/production/*.txt`。
- 来源/留白派生/工程图/消费者：[resource-pack.json](../../game/art/modules/huashan_map_20261029m/resource-pack.json)。
- [布局与阶口数据](../../game/art/modules/huashan_map_20261029m/huashan.json)、[透明留白核对](../../assets/staging/huashan_map_20261029m/padding-verification.json)。
- [分类图鉴](../equipment-skill-catalog.html)与[复用索引](../resource-reuse-index.md)：按华山建筑/场景物件/地表/山体及来源阶段分类，原图可放大。

每图内置imagegen一次，真正render_template预检8项通过，无CLI/fallback/重试；具体model/provider/cost工具未返回，记录null。7透明图按既有许可只扩RGBA0留白，原RGBA全保持，不擦alpha/改色/裁切。原完整alpha留白失败保留。地面RGB原文件字节复制；8工程图导入RGBA与PNG逐字节相等。复用正式主角、旧灰阶/挡土坎、松树、家具与铺地，未用战斗立绘充地图NPC。

## 实际验证

- `import01`自然退出0，无stderr。仅私有工程新资源导入，未运行主工程全量import。
- [verify01](../../assets/staging/huashan_map_20261029m/town_project/artifacts-m/verify01.json)：36项、0失败、4979真实键输入物理ticks。默认出生点开始，山门→主阶→主堂→东侧阶→论剑台→东崖阶→思过崖→西生活阶→生活院→主阶返回出生点，全程中途不传送；随后局部阶口双端净空、5侧墙/非阶崖壁负控、Tab/Space/Esc及8纹理精确通过。自然退出0；8个QA原PNG Image.load_from_file导出提示warning保留，不称stderr空。
- 原全景图视觉拒绝：岩块排列断续、部分压住房屋边缘，地面纹理颗粒过大。原图/源码快照保留。后继只撤20个无碰撞外围岩块、保3块后山体，并沿真实外轮廓以原PNG UV绘连续崖面；减小铺地图案周期，调整全景取景。未改PNG，主角、阶口、道路、楼屋及碰撞保持。
- [视觉后继物理一致核验](../../assets/staging/huashan_map_20261029m/visual02-physical-inheritance.json)：terrain、blockers、roads、spawn完全一致，继承首轮已过路线，不重跑。
- [baked02](../../assets/staging/huashan_map_20261029m/town_project/artifacts-m/baked02.json)：8项、0失败、230真实输入ticks；连续崖面/25边界保留、烘存成功、重开无重复节点/二次视觉高差、默认人物碰撞层正确、保存后主阶上下通过。自然退出0，stderr空。
- 已看最终全景、山门、主堂、生活院、论剑台与首轮阶中图。主角在踏面上可见；功能验证不替代最终美术验收。

## 发布与范围

[发布清单](../../assets/staging/huashan_map_20261029m/publication.json)：41个全新工程文件，含8PNG与16导入缓存叶。411个保护对象SHA/bytes/mtime一致，旧game文件0写；15个被遍历到的既有资源依赖精确保持。未操作用户编辑器PID51856；3个自有Godot进程均自然退出。图鉴仅同步resources，不改装备/技能/任务/章节数据。

当前是**可试玩室外首版**。它落实了真实高差与六区连接，但场地边缘仍偏规整、院落密度较低、主堂侧阶较集中，距原总规的自然险峰、围合院落和人口密度仍有差距。没有门派专属地图NPC/立绘、新室内服务、剧情业务或正式World接线，不能称整派改造全部完成。古峰与凌月仍保留29l设计，尚未施工。

## 原生实机图

![华山全景](../../assets/previews/huashan_map_20261029m/overview_final.png)
![山门正常视角](../../assets/previews/huashan_map_20261029m/gate_final.png)
![主堂正常视角](../../assets/previews/huashan_map_20261029m/hall_final.png)
