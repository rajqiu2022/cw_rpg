# 神兵外显首批

三件已有装备已接入冷孤云的地图与战斗外观。渊冥古剑和虎啸刀平时贴侧腰佩挂，侧面由近侧手臂遮住鞘口，战斗开始后持武器备战。降魔杵按原图标做成短柄重器，地图中持在手上。备战四帧按虎口挂点和原手指遮挡处理。挥击共用现有剑式与重挥动作。

| 装备 | 外显与附魔 | 实战截图 |
| --- | --- | --- |
| 渊冥古剑 | 暗钢直刃、紫纹鞘、慢速紫芒 | [备战](../../game/build/layered_actor_adoption_20261106/evidence/legendary_ready_yuanming_sword.png) · [出招](../../game/build/layered_actor_adoption_20261106/evidence/legendary_attack_yuanming_sword.png) |
| 虎啸刀 | 虎首护手、皮鞘、快流金橙火花 | [佩刀](../../game/build/layered_actor_adoption_20261106/evidence/legendary_field_tiger_roar_blade.png) · [出招](../../game/build/layered_actor_adoption_20261106/evidence/legendary_attack_tiger_roar_blade.png) |
| 降魔杵 | 黑铜鎏金杵头、集中于杵头的金尘 | [出招](../../game/build/layered_actor_adoption_20261106/evidence/legendary_attack_buddha_subduing_staff.png) |

三张图由内置 imagegen 参考原装备图标生成，原图和工程图逐字节相同。尺寸、路径、提示词和 SHA 见[生成记录](../../assets/raw/legendary_weapons_20261108/generation.json)。装备 ID、挂点和附魔配置见[武器配置](../../game/scripts/appearance/legendary_weapon_data.gd)。[资源图鉴](../equipment-skill-catalog.html)收录工程图和原图，支持缩略和放大。

正式 Godot 桌面项目实测林西四向、战斗中依次换装、三个备战握法和普通攻击、撤退返回原脚点。64 项通过，共 3 次原生出招事件。测试使用临时装备并暂停检查点保存。退出仍有既有资源清理日志，发布包和 Web 未验证。
