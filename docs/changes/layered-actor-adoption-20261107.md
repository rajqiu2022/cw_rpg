# 七星龙泉剑与烬河断岳刀正式外显

Godot 打开 `game/project.godot` 后按 F5。给冷孤云装备七星龙泉剑或烬河断岳刀即可在地图和战斗中看到外观。开发环境可用右上角 GM 的「发放道具 / 装备」先拿两件武器，再在背包里更换。

| 资源 | 路径 | 当前使用 |
| --- | --- | --- |
| 人物、武器与附魔光效 | [原生素材](../../game/art/characters/layered_actor_20261106/) | 正式复用 13 张，包含武器图、星芒、余烬和人体关键帧 |
| 走路补间、断岳刀挥击 | [新工程素材](../../game/art/characters/layered_actor_adoption_20261106/) | 三向各增加 4 帧补间，刀使用独立 4 帧挥击 |
| 原图和生成记录 | [生成记录](../../assets/raw/layered_actor_adoption_20261106/generation.json) | 原始 PNG 保留，候选底色不合格稿单独归档 |
| 挂点与素材表 | [appearance.json](../../game/art/characters/layered_actor_adoption_20261106/appearance.json) | 17 张图、52 个姿势。按帧定义脚点、虎口、手部前景和武器角度 |
| 图鉴 | [装备与技能图鉴](../equipment-skill-catalog.html) | 「主角与武器」可看工程素材缩略图，点开看原尺寸和用途 |

地图使用四向待机与八帧行走。左向由右向镜像。正背朝向的刀剑略向外倾，方便辨认。战斗沿用原动作节奏，刀剑各有挥击姿势。虎口挂点与手部前景分开，换刀剑时保留原手型。遮挡沿用角色半透明影像和原有遮罩。其他装备、采集动作和专用招式图继续使用各自已有的显示。

正式测试在 Godot 4.6.2 桌面项目执行。林西村实走记录了全部 8 个行走帧，随后验证卸下、换装、真实战斗内切换剑刀、断岳刀普通攻击、一次命中事件、结算后原脚点返回。另有 71 项角色组件检查，覆盖四向帧同步、侧向受击和倒地、遮挡影像与卸下恢复。战斗测试用临时内存物品，最终运行关闭检查点保存。

- [林西村七星剑](../../game/build/layered_actor_adoption_20261106/evidence/game_linxi_sword.png)
- [七星剑战斗待机](../../game/build/layered_actor_adoption_20261106/evidence/game_battle_sword.png)
- [断岳刀实战挥击](../../game/build/layered_actor_adoption_20261106/evidence/game_battle_dao.png)
- [25 项正式验证记录](../../game/build/layered_actor_adoption_20261106/evidence/game_report.json)

首轮日志保留子视口初始化错误与测试入口错误。最终正式运行 25 项全过，Godot 退出时仍记录纹理和对象清理警告。当前范围为这两件武器的桌面项目接入，发布包和 Web 尚未验证。
