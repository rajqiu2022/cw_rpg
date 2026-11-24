# 汴州城模块化改造试点

**后续纠正：用户于2026-10-22明确否定本试拼，指出必须先做设计图、严格按改造方案。以下全部是失败尝试的历史记录，不能作为获认可的汴州布局。已停止拼装和集成，改先做[汴州整城设计](../bianzhou-city-masterplan-20261022b.md)。**

change-id: bianzhou-city-remodel-20261022a

目标：参考洛阳的功能分区、独立门脸、生活物件和实体导航，以汴州城现有驿丞/行商/缉捕榜及两个出口制作可查看的模块化场景候选。

读文件：汴州城/旧驿SceneScript、汴州v2布局、SceneScript/WalkableMapLayout和Field对象格式、洛阳总规、既有原图和组件。角色依次为producer→system→art复核→qa；读取producer/system/art/qa记忆与相应验收清单，使用项目2D空间布局和环境叙事参考。

写文件：`assets/staging/bianzhou_city_20261022a/`独立工程、`scripts/bianzhou_city_remodel_20261022.py`制作工具、本专题和角色进度。**本批不写game/、不写prompts/tasks.yaml、不改图鉴和公共路由**；洛阳另一对话可以继续保存和运行。源图只读，复制原字节到候选包，不清alpha、不扩画布；候选原图留白失败继承，不因场景预览晋升。

三个步骤：①冻结汴州既有功能和素材来源，确定南北主街/西市货街/东驿馆；②独立装配建筑、摊位、货物和树，发布实体足迹/导航及待集成数据；③在独立project.godot中做有限路径/物理查询与一张原生渲染图，不开生产编辑器、不向其发送命令、不停任何用户进程。

验收：仅本批输出；两个NPC的ID/姓名/对白或商店action及原有BGM、缉捕榜action、两个出口的target/action保留；关键路线通过34×24玩家身体的逐像素净空检查；候选实体有同源碰撞；原图副本SHA相同；已有汴州源文件首末保持。原生预览须实看，正式Field/大地图跳转/任务/UI/音频实测和整城完成不由孤立项目授信。

布局拟定：南门只承担出城；中轴向北通旧驿；西市有货栈和有门脸的商铺；东侧驿馆前设驿丞，通缉榜位于主街可达前庭。街坊以沿街建筑和货运摆件形成用途，主街不堆箱。装饰商楼不新增可进入室内或任务承诺。

状态：制作中，尚未替换游戏地图。

## 本次完成检查点

已产出revision2独立候选：32模块/37实体，6主要建筑与两NPC原功能；8路线2572净空点、522原生motion/37负控、注入预览键与311条目原生布局读回通过。首版裁墙/粗泥地/出生被门压视线保留，修正版有限调整另目录；首导出检查类型推断PARSE失败及仅显式bool后继成功均保。23图像源副本SHA、3汴州源SHA/bytes/mtime_ns保持，候选Scene仅layout路径＋两NPCpos三处全文逆相同。

两个原生渲染进程自然0退出，仅使用独立project.godot；无game/、共享路由/图鉴/tasks或生产缓存写入，也未停/操作editor51856及另线洛阳进程。零新增imagegen调用，全部复用既有原图，不本地删alpha。整体仍NOT_ART_READY，地面硬边、稀疏围合与民居亮脚等限制保留，未正式接入，不授全城或正式任务往返/音频信用。

[独立预览与完整路径](../../assets/staging/bianzhou_city_20261022a/README.md) · [修正版实图](../../assets/staging/bianzhou_city_20261022a/revision2/artifacts/overview.png) · [当前选择](../../assets/staging/bianzhou_city_20261022a/current-candidate.json)。
