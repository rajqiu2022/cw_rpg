# 苗族风情山城创建 · 2026-10-29f

2026-10-29g用户反馈：“跟设计稿相差比较大啊”。本首版布局不作为已符合总规的美术基线，原文件保留；当前另存[按原稿重排版](miao-recompose-20261029g.md)。下文为29f历史功能与资源事实，不代表用户通过视觉验收。

状态：六区独立可编辑地图首版已发布，隔离 GPU 实际运行通过；正式世界入口未接。

change-id: miao-town-20261029f

用户已确认29e总规：“可以，按照这个创造”。本批创建独立六区可编辑山城，不把沙漠城换皮，不创建正式地点名/ID、剧情、任务或奖励。

读文件：29e总规与来源、ai-rules、设计空间技能、system/art/qa/producer记忆、正式Player及其预览适配、既有家具与缓存前厅机制。

写范围：本批专有raw/processed/staging、`game/art/modules/miao_town_20261029f`、`game/scripts/drafts/miao_town_20261029f`、`game/scenes/drafts/miao_town_20261029f`，图库/复用索引与项目记忆。共享Router/project/Player、其他城市、根tasks和存档只读。

验收：独立原生组件、三桥/四短阶与桥头通路、六区连通/水域和侧栏负控、正式主角跟随与行走、普通居民真实序列/同人肖像、一处木楼缓存前厅；原UV踏面低于人物、护栏分层；独立导入RGBA精同与原生图亲看。生图每项1次内置，真实renderer预检；原PNG保持，只有已获普遍授权的RGBA0留白，A1原失败保留。

已仅发布本批117个全新工程文件，其中52个新导入叶；0既有game文件覆盖，未全主工程import或控制用户编辑器。实际正式世界与剧情玩法、参考密集度及整城ART另验。

## 使用

主工程场景：[miao_town.tscn](../../game/scenes/drafts/miao_town_20261029f/miao_town.tscn)，SHA256 `91cf987b7e5ee0c25e7cc6cb81c61e07a45a6372c5681acd65f70aeab16e72c8`。在编辑器打开此场景后F6运行；已验的是同源独立项目，未代切用户编辑器、未重跑主工程自动加载链。

- 默认正式冷孤云人物跟随，四向待机与行走；WASD/方向键移动，Shift快走。
- Tab切换全景/人物跟随；1—6观察六区；R回山口出生点。
- 空格查看附近物件/居民同人肖像；Esc关闭说明。
- 西岸绣坊门前（590,1255）空格进入木楼前厅；前厅出口空格精确返回入门原脚。两次进返为同一Player、同一缓存室内节点。

![六区原生运行总览](../../assets/previews/miao_town_20261029f/overview.png)

![芦笙坪正常视角](../../assets/previews/miao_town_20261029f/plaza.png)

## 实际结构

六区为山口寨门、临溪街市、芦笙坪、蜡染绣坊、吊脚民巷、梯田粮院。37民居＋3双铺＋2绣坊＋3粮仓，共45个主要楼体；另有木寨门、1有盖桥/2露天桥、4短阶、3层台地、两处梯田、溪岸石草与芦笙制作架。布局对象263、静态阻挡154；不同于旧沙漠城的浅土坯和赤岩的红砂岩峡壁。

八名室外巡行居民复用两种普通中年男女外观，室内另有静态女掌柜；这是匿名用途槽及本地查看，未创建正式NPC、业务或剧情。家具复用六种既有桌凳/柜架/货物/水罐，原图未改。

门前与桥头有落脚通道。溪流绘制多边形与实际水域碰撞同源，三座桥保留原本的窄通行带。四短阶的原UV中央踏面全局低z，护墙保持原UV前景与真实碰撞；人物脚深度按世界y同步，桥屋顶仅人物周围局部窗口，全景关闭窗口。新房组各自使用独立材质，避免克隆实例共享窗口参数。

## 资源、路径与当前引用

|层级|路径|当前状态|
|---|---|---|
|原生26张|[RAW manifest](../../assets/raw/miao_town_20261029f/manifest.json)|每项内置1次；原输出SHA精同，0CLI/fallback；model/provider/cost未返回，保null|
|授权透明留白|[processed pack](../../assets/processed/miao_town_20261029f/resource-pack.json)|23透明图仅增RGBA0画布，原RGBA逐像素保留；三不透明材质原样复制|
|工程运行图|[game resource-pack](../../game/art/modules/miao_town_20261029f/resource-pack.json)|26张隔离导入解码RGBA精同，全部供本六区场景使用|
|原生精灵UV|[atlases.json](../../game/art/modules/miao_town_20261029f/atlases.json)|运行region/脚锚与等比显示，不裁切重存PNG|
|路径及使用索引|[resource-reuse-index.md](../resource-reuse-index.md)|26条完整原生→派生→工程链，列实际消费者及既有复用来源|
|分类预览|[equipment-skill-catalog.html](../equipment-skill-catalog.html#resources)|新增78个路径条目，缩略图、原图放大及源路径均核对；全库5059条/2752图/2307音|
|原生运行截图|[preview manifest](../../assets/previews/miao_town_20261029f/manifest.json)|总览/院坪/桥/阶/绣坊/前厅，未修改的GPU输出副本|

原透明PNG的完整A>0四边10%留白均失败，历史FAIL不洗白；补白后通过。没有擦除alpha、修画主体、局部拉伸或填回原生缺失身体。男工肖像为腰部裁切构图。

NPC动画须区分：原男女4×4图中四向待机已用，但左右走相重复偏大，未把原稿授予四向行走通过。另登记一张2身份×4相的原生侧向序列，实际巡行采用此四相；左向使用右向运行镜像，上下walk未采用。八巡行居民不等于八张独立外观，也不代表原生四向walk完成。冷孤云使用已有v7剑四向待机/行走，原Player及图像零修改。

## 实际验证与保留失败

Windows Godot4.6.2/Compatibility/RTX4080，仅运行本批隔离项目；每个自有进程自然退出，最终GPU stderr为空。

|批次|结果|范围与边界|
|---|---|---|
|首次city|85检查/1FAIL，自然1|23初始PNG导入、真Player、四向待机/侧向四相、真实键事件三桥和四阶上下、九目的地连通、水/栏负控、两次缓存前厅进返与肖像通过；WestWeaver巡路撞一条凳是真失败，整批保FAIL|
|refined后继|52检查/0FAIL，自然0|原失败凳从520,1400移440,1460；Home13东移60避街；只验新2PNG、15新房占地/深度、受新域影响连通/曲水/三桥，修正踏面绝对深度与各房独立窗口，织工实际走通。旧23导入/四阶行走/室内成功矩阵不复|
|final-prop|7检查/0FAIL，自然0|新增芦笙制作架的单图RGBA、实际阻挡、三接近点、原巡路、绝对脚深度及最后两张图；不复原85/52矩阵|
|图鉴guard首试|字段oracle FAIL保留|脚本误用thumb键；实际为thumbnail/diskPath。仅修检查器，不改生产或前序runtime报告|
|最终guard|通过|117新工程文件SHA/bytes、26原PNG/内置来源/promptSHA、78新图鉴路径的156原图/缩略图入口、非resources全对象精同；1810文本源稳定/显式路径0缺|

证据：[首次报告](../../assets/staging/miao_town_20261029f/town_project/artifacts/verification-city.json)、[52项后继](../../assets/staging/miao_town_20261029f/town_project/artifacts/verification-refined.json)、[7项最终](../../assets/staging/miao_town_20261029f/town_project/artifacts/verification-final-prop.json)、[透明留白精核](../../assets/staging/miao_town_20261029f/padding-verification.json)、[发布清单](../../assets/staging/miao_town_20261029f/publication.json)、[保护与图库guard](../../assets/staging/miao_town_20261029f/final-guard.json)。

170项保护文件首末SHA/bytes/mtime_ns精同，含162个存档/备份、共享project/Router/Player/根tasks、当前沙漠C37F2B1C/赤岩B92D7F02及29e设计原图；用户编辑器51856仍在，自有GPU进程均自然退出。

## 待办与停止边界

本轮完成独立六区编辑地图及资源引用，停止重复验证，交用户细看。正式大地图地点/入口、正式NPC业务/任务/经济/战斗尚未接；其余住宅内景、完整四向原生NPC行走、活动序列未做。当前台地仍有较直的石坎、部分屋型重复，林地与建筑组团尚未达到总规密度，非整城最终艺术验收；不称其他城市一并完成。
