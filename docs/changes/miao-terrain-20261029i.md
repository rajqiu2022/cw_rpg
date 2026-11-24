# 苗风山城三级台地与必要石阶 · 2026-10-29i

change-id: miao-terrain-20261029i

用户指出“地形没有变化，楼梯随机摆放没有实质作用”。这是旧版的实际缺陷：f/g/h虽有短阶贴图与侧墙碰撞，人物仍在同一平面行走，旧检查只能证明平面通行，不能证明上下层。本轮另存三级台地版，保留h的建筑类型差异，撤掉4处装饰阶与19段散摆代用岩坎，建立连续台面、坎界和4个必要阶口。

当前：[miao_town.tscn](../../game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn)，编辑器打开后F6。默认正式冷孤云跟随，Tab切全景，WASD/方向键移动，Shift快走，空格查看/进返绣坊。台面、连续坎面、阶口、护墙和物理边界已经保存为原生场景节点，可在编辑器内查看；不是仅在运行时临时出现的设计图。

![三级台地实际场景](../../assets/previews/miao_terrain_20261029i/overview.png)

## 地形与路线

唯一高程/多边形/阶口数据是[terrain.json](../../game/art/modules/miao_terrain_20261029i/terrain.json)。0层为溪谷街市与桥巷，1层为街坊台地/芦笙坪/粮院，高程120；2层为上层木楼民巷，高程240。两块不规则连续平台有闭合边界，4处开口才允许跨层。

|阶口|连接|上口逻辑脚点|下口逻辑脚点|
|---|---|---|---|
|溪市—芦笙坪|0→120|4200,3000|4200,3083.3175|
|桥巷—绣坊台地|0→120|2680,2450|2680,2533.3175|
|芦笙坪—上层民巷|120→240|3800,1850|3800,1933.3175|
|粮院—上层民巷|120→240|5400,1870|5400,1953.3175|

路线为出生点→溪谷街市→广场阶→芦笙坪→民巷阶→上层居住街；西侧桥巷可经绣坊阶上街坊台地，东侧粮院经粮院阶连上民巷。移走挡住绣坊下口的小宅至2740,3080；遮住阶口的Forest178移至2160,2550，原PNG不改。

人物保留真实Player与35×25足底碰撞。逻辑XY是地面脚点，独立Z为高程，显示脚点为(x,y−Z)；阶内连续插值，踏面速度按投影距离校正。只有从对应上下端进入的阶口状态能改变人物所在层；不是靠y_sort、瞬移或进入一个区域就自动升层。实体使用共用水域/边界层8和高程层16/32/64，非阶坎同时阻挡两侧，阶侧护墙防止横向离开。建筑图像、居民脚点按同一台地数据抬高，物理基座保持地面坐标；8居民巡路保持在各自台地，仍为2身份侧向4相/左镜像，未新增NPC上下行走原画。

台地顶使用已有原生土石/林下材质；坎面使用既有terrace.png的原生石面UV，阶踏面和两侧护墙使用原生stairs.png的UV。没有新生图，也没有裁切、拉伸或重绘PNG文件。UV装配与台地顶点是场景几何。编辑器场景保存138个Terrain直接子节点；读取已保存场景时不重复建造、不重复抬高建筑。

![绣坊阶口与桥巷](../../assets/previews/miao_terrain_20261029i/workshop-stair.png)

![主角在连续上层石阶中段](../../assets/previews/miao_terrain_20261029i/stair-middle.png)

## 实际验证与保留失败

独立Compatibility GPU运行，使用Godot物理键事件parse/flush驱动，不是OS键盘，也不是把主角逐点传送冒充旅程。Dummy音频未听测。

1. [首轮36项报告](../../assets/staging/miao_terrain_20261029i/town_project/artifacts-i/verification-terrain.json)：33成功、3失败原样保留。四阶W/S连续升降、每阶至少10个中间高程采样、上下层mask切换、4处侧墙阻挡、3处非阶坎阻挡、8居民同层巡路与缓存前厅同一角色进返成功；共884个记录的输入ticks。失败为JSON浮点数组与整数数组比较的QA误判、绣坊下口被小宅挡住、绣坊非阶负控放到短横边之外。
2. [残余与分层路线16项报告](../../assets/staging/miao_terrain_20261029i/town_project/artifacts-i/verification-routes.json)：15成功、1失败保留。仅修正上述3项，不复33个成功组件；46,293个当前物理导航节点证明默认出生点与前厅/广场/上层民巷/粮院/溪市连通。移除两条0↔1阶边或两条1↔2阶边后，上层均不可达。连续行走验证在出生点附近停止，原失败保留。
3. [连续旅程5项报告](../../assets/staging/miao_terrain_20261029i/town_project/artifacts-i/verification-journey.json)：5/0，3,795个显式记录的输入ticks。验证器补齐按帧刷新键事件，并限制“同层接近路径”不能取经别层上下两阶的捷径；第一次后继因此停在绣坊下口的报告[仍保留](../../assets/staging/miao_terrain_20261029i/town_project/artifacts-i/verification-journey01.json)。最终从默认1610,3900真实步行到广场下口、登1层、跨台地、再登2层、抵达3800,1610民巷，全程没有途中瞬移。
4. [保存场景7项报告](../../assets/staging/miao_terrain_20261029i/town_project/artifacts-i/verification-baked.json)：7/0，65个显式输入ticks，验证原生节点已保存、读取无重复生成/抬高、房屋脚点稳定、下口保持腾空、双层坎碰撞保留，读回场景真实W仍能上阶进入1层。不复全部四阶与连续旅程。原两次验证脚本Variant类型推断解析失败日志保留。

最终有效成功组件合计60项（33继承＋15残余/路线＋5旅程＋7保存），不把原整段FAIL改成PASS。连续旅程与保存场景进程均自然退出0、stderr空。截图是原生GPU PNG逐字节复制，未编辑截图。

![从出生点连续步行抵达上层民巷](../../assets/previews/miao_terrain_20261029i/upper-arrival.png)

## 路径、复用与发布边界

- 新[场景](../../game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn)、[主控](../../game/scripts/drafts/miao_terrain_20261029i/town_controller.gd)、[高程与连接实现](../../game/scripts/drafts/miao_terrain_20261029i/terrain.gd)、[居民脚点投影](../../game/scripts/drafts/miao_terrain_20261029i/resident.gd)、[地面材质](../../game/art/modules/miao_terrain_20261029i/ground.gdshader)、高程JSON及[使用清单](../../game/art/modules/miao_terrain_20261029i/resource-pack.json)共7个全新工程文件；0既有game文件覆盖、0新资源PNG、0新导入叶。
- 复用34张f/g/h原生工程图，逐项来源路径与当前消费者在[资源复用索引](../resource-reuse-index.md)及[分类图鉴](../equipment-skill-catalog.html#resources)中；图鉴缩略图与点击放大沿用，当前消费者更新为三级台地场景。
- [发布收据](../../assets/staging/miao_terrain_20261029i/publication.json)与[依赖字节核对](../../assets/staging/miao_terrain_20261029i/existing-dependencies-exact.json)。343个保护文件含162份真实存档/备份以及f/g/h已发布工程保持SHA/字节/mtime精确一致。共享Router、Player、project.godot及其他城市未写；用户editor51856未操作，其他运行进程不关闭。
- 本批解决“平地上的无作用楼梯”，未声称整城达到原总规艺术终验。山体自然岩层/遮挡细节、建筑朝向与密度仍交视觉细看；正式World入口、剧情/经济/战斗、新木厅/高楼室内业务未接。停止本批成功组件重复检查。
