# 高清普通武器与七星龙泉剑腰挂

2026-11-08 续修战斗待机握法。七星剑四帧各自对准虎口，使用原图手指轮廓盖住柄身，待机时仅缩短护手与剑首之间的缠柄段。左右镜像均验证柄轴穿过手指遮挡区。实战 41 项与组件 107 项通过，覆盖出招后回到同一握姿。[实战待机图](../../game/build/layered_actor_adoption_20261106/evidence/grip_battle_ready.png)。

当前版本将侧面近侧袖口和护臂绘在剑鞘前。腰身、剑鞘、近侧手臂依次合成，原图不重采样。战斗进入、待机和出招后的备战都持剑。局部地图主角视觉等比放大约 5.9%，侧向待机林西实测约 136px，以原脚点为锚。大世界仍用原旅行比例。

[林西村同镜头对照唐行舟](../../game/build/layered_actor_adoption_20261106/evidence/arm_linxi_tang_comparison.png) · [持剑备战](../../game/build/layered_actor_adoption_20261106/evidence/arm_battle_ready.png) · [本次 40 项实测](../../game/build/layered_actor_adoption_20261106/evidence/arm_game_report.json)。另有 99 项组件检查，覆盖侧向 8 帧和镜像的叠放关系。

2026-11-07 续修。正、背面改成沿侧腰垂挂，背面由衣身挡住靠内一段。左右挂点、比例和步行摆幅沿用。七星剑复用已入库的星芒贴图，蓝白星点沿剑刃或剑鞘镶线流动，部分向两侧飘散淡出。收鞘光较轻，拔剑更亮，普通武器没有这组粒子。

实际林西村与战斗 36 项通过，角色组件 79 项通过。实拍核对正、背腰挂和出鞘效果，组件检查确认人物站定时粒子仍移动，换装时粒子消失。[正面](../../game/build/layered_actor_adoption_20261106/evidence/enchant_fixture_down.png) · [背面](../../game/build/layered_actor_adoption_20261106/evidence/enchant_fixture_up.png) · [实战](../../game/build/layered_actor_adoption_20261106/evidence/enchant_battle_drawn.png)。

冷孤云的常规地图和战斗动作使用同一套原生高清人物帧。普通剑、刀、棍使用各自的类型外观，空手、掌法和隐藏武器使用无外显的人物底图。普通武器按类型共享素材。已有专用招式和采集动作沿用各自的原画。

七星龙泉剑在地图待机、走路时佩在腰间，剑鞘镶线带柔蓝微光。战斗时由虎口挂点握住剑柄，剑身出现流动蓝白刃光，护手和剑柄保留原有材质。

| 内容 | 路径 |
| --- | --- |
| 普通剑、刀、棍与七星剑鞘 | [工程图集](../../game/art/characters/layered_actor_adoption_20261106/weapon_carry_atlas.png) |
| 原图、内置 imagegen 生成提示词 | [原图](../../assets/raw/layered_actor_carry_20261107/weapon_carry_atlas.png) · [提示词](../../assets/raw/layered_actor_carry_20261107/prompt.txt) |
| 武器格、握点与腰挂点 | [配置](../../game/scripts/appearance/weapon_carry_data.gd) |
| 七星剑身与鞘光 | [材质](../../game/scripts/appearance/seven_star_enchantment.gdshader) |
| 按类别浏览及放大 | [资源图鉴](../equipment-skill-catalog.html) |

首版正式桌面项目在林西村实测普通剑、刀、棍和卸下装备后的高清外观，走到全部八帧。首版战斗验证覆盖一次普通攻击命中事件及战后原脚点返回，共 33 项通过。测试使用内存装备并暂停检查点保存。退出时仍有 Godot 纹理及对象清理日志。发布包和 Web 版尚未验证。

- [地图腰挂](../../game/build/layered_actor_adoption_20261106/evidence/carry_linxi_sword.png)
- [普通铁剑高清外观](../../game/build/layered_actor_adoption_20261106/evidence/carry_linxi_iron_sword.png)
- [实战刃光](../../game/build/layered_actor_adoption_20261106/evidence/carry_battle_drawn.png)
- [验证记录](../../game/build/layered_actor_adoption_20261106/evidence/carry_game_report.json)
