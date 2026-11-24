# 神兵外显第二批与 GM 发放

正式游戏的「GM → 发放道具 / 装备 → 神兵外显」集中列出七星龙泉剑、烬河断岳刀、渊冥古剑、虎啸刀、降魔杵、通天棍、镇潮金箍棍、仙尊护手、越纹州句剑、紫砂暗器。输入「神兵」也可筛选，输入「金箍棒」可直接选中镇潮金箍棍。刷新 GM 数据后保留当前筛选。[GM 面板截图](../../game/build/layered_actor_adoption_20261106/evidence/legendary_batch02_gm.png)

| 装备 | 游戏内外显 | 截图 |
| --- | --- | --- |
| 通天棍 | 近手持棍，棍身两端有红色脉冲和游离火星 | [备战](../../game/build/layered_actor_adoption_20261106/evidence/legendary_ready_heaven_piercing_staff.png) |
| 镇潮金箍棍 | 深色棍身配金箍，两端有青色流光与漂散粒子 | [备战](../../game/build/layered_actor_adoption_20261106/evidence/legendary_ready_golden_hoop_staff.png) |
| 仙尊护手 | 黑金材质贴合两只手的原有轮廓，两套金橙粒子分别跟随左右手。被动作遮住的手随帧隐藏 | [地图正面](../../game/build/layered_actor_adoption_20261106/evidence/legendary_field_front_immortal_gauntlets.png) · [出拳](../../game/build/layered_actor_adoption_20261106/evidence/legendary_attack_immortal_gauntlets.png) |
| 越纹州句剑 | 平时佩青铜纹鞘，备战从虎口握柄，出鞘后有金绿色刃光与粒子 | [佩剑](../../game/build/layered_actor_adoption_20261106/evidence/legendary_field_zhouju_bronze_sword.png) · [备战](../../game/build/layered_actor_adoption_20261106/evidence/legendary_ready_zhouju_bronze_sword.png) |
| 紫砂暗器 | 平时隐藏，使用普通攻击时从手中亮出机关壶，壶嘴有紫色粒子 | [出招](../../game/build/layered_actor_adoption_20261106/evidence/legendary_attack_suwusheng_teapot.png) |

当前橙品拳掌装备共用仙尊护手的外显。护手沿用原高清主角动作，双手材质和粒子各自定位。棍共用重挥动作。紫砂暗器沿用现有攻击结算，机关壶没有独立飞行弹道。

五张内置 imagegen 图的生成原件与正式 PNG 逐字节相同，路径、尺寸及 SHA-256 见[生成记录](../../assets/raw/legendary_weapons_batch02_20261108/generation.json)。[资源图鉴](../equipment-skill-catalog.html)新增 10 条来源和工程图记录，沿用缩略图和点击放大。

Godot 桌面实测 134 项通过。检查了十件装备的 GM 实际发放、筛选刷新、林西四向、五件新外显的备战与普通攻击，以及战斗撤退回原脚点，共收到五次原生出招事件。测试使用临时装备并暂停检查点保存。已有退出资源清理错误仍可见。发布包与 Web 未验证。[实测记录](../../game/build/layered_actor_adoption_20261106/evidence/legendary_batch02_report.json)
