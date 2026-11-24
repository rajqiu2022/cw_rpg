# 赤岩关镇六区编辑布局 · 2026-10-28a

当前续改版本见[28b生活街段与驿舍前厅](redrock-luoyang-standard-20261028b.md)：四院入口及一处室内已完成本地进返，原28a场景保留；下文为28a历史状态与限制。

已写入主工程：[scenes/drafts/redrock_town_20261028a/redrock_town.tscn](../game/scenes/drafts/redrock_town_20261028a/redrock_town.tscn)，Godot打开后按 **F6**。这是原生节点的六区可走动布局草案；已确认的总规继续作为美术目标，当前外边岩壁/街沿围合仍需深化。未加入正式世界入口。

WASD/方向键移动，Shift快走，Tab全景/跟随，1—6分区镜头，R回关外，空格查看邻近物件，Esc关闭本地说明。镜头定位不传送人物；查看员沿旧匿名112px待机图移动，不宣称行走动画已完成。

![独立Godot原生全景](../assets/staging/redrock_town_20261028a/town_project/artifacts/overview-editor.png)

## 已落地内容

六区：峡口关门、阶街民巷、驿舍马院、石作修坊、蓄水小院、高台望关。连体关防相对变换/碰撞继承，仅整体平移；新增低矮岩台和折返主路、开放棚湾、十一处民居、井院与低物件，共40个实例，另有独立关防和查看角色。所有几何与碰撞都是Scene内可编辑原生节点。

[技术平面](../assets/staging/redrock_town_20261028a/layout-plan.svg)只用于节点与动线定位，不冒充新AI总规或可玩背景。地面使用原生土/岩纹理的世界坐标材质混合，道路软边，未将概念图铺成背景。

## 资源路径与当前使用

|资源|工程PNG|原始来源|当前使用|
|---|---|---|---|
|赤岩·阶街平顶民居|[dwelling.png](../game/art/modules/redrock_town_20261028a/dwelling.png)|[redrock_town_20261028a_dwelling_v1.png](../assets/raw/redrock_town_20261028a/building/redrock_town_20261028a_dwelling_v1.png)|六区编辑草案；未接正式世界|
|赤岩·商旅牲口棚|[stable.png](../game/art/modules/redrock_town_20261028a/stable.png)|[redrock_town_20261028a_stable_v1.png](../assets/raw/redrock_town_20261028a/building/redrock_town_20261028a_stable_v1.png)|六区编辑草案；未接正式世界|
|赤岩·层台岩坎立面|[terrace.png](../game/art/modules/redrock_town_20261028a/terrace.png)|[redrock_town_20261028a_terrace_v1.png](../assets/raw/redrock_town_20261028a/landform/redrock_town_20261028a_terrace_v1.png)|六区编辑草案；未接正式世界|
|赤岩·平顶商旅驿舍|[inn.png](../game/art/modules/redrock_town_20261028a/inn.png)|[redrock_desert_20261025a_inn_v1.png](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_inn_v1.png)|六区编辑草案；未接正式世界|
|赤岩·商队修车棚|[repair_shed.png](../game/art/modules/redrock_town_20261028a/repair_shed.png)|[redrock_desert_20261025a_repair_shed_v1.png](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_repair_shed_v1.png)|六区编辑草案；未接正式世界|
|赤岩·蓄水井棚|[cistern.png](../game/art/modules/redrock_town_20261028a/cistern.png)|[redrock_desert_20261025a_cistern_v1.png](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_cistern_v1.png)|六区编辑草案；未接正式世界|
|赤岩·封口储水罐组|[water_jars.png](../game/art/modules/redrock_town_20261028a/water_jars.png)|[redrock_desert_20261025a_water_jars_v1.png](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_water_jars_v1.png)|六区编辑草案；未接正式世界|
|赤岩·车轮轴木工作台|[wheelbench.png](../game/art/modules/redrock_town_20261028a/wheelbench.png)|[redrock_desert_20261025a_wheelbench_v1.png](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_wheelbench_v1.png)|六区编辑草案；未接正式世界|
|赤岩·风蚀旱树|[dry_tree.png](../game/art/modules/redrock_town_20261028a/dry_tree.png)|[redrock_desert_20261025a_dry_tree_v1.png](../assets/raw/redrock_desert_life_20261025a/vegetation/redrock_desert_20261025a_dry_tree_v1.png)|六区编辑草案；未接正式世界|
|赤岩·荒漠枯黄灌木|[dry_shrub.png](../game/art/modules/redrock_town_20261028a/dry_shrub.png)|[redrock_desert_20261025a_dry_shrub_v1.png](../assets/raw/redrock_desert_life_20261025a/vegetation/redrock_desert_20261025a_dry_shrub_v1.png)|六区编辑草案；未接正式世界|
|赤岩·岩矿调查点|[ore_cluster.png](../game/art/modules/redrock_town_20261028a/ore_cluster.png)|[redrock_desert_20261025a_ore_cluster_v1.png](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_ore_cluster_v1.png)|六区编辑草案；未接正式世界|
|赤岩·连体关楼核心|[core.png](../game/art/modules/redrock_town_20261028a/core.png)|[core.png](../game/art/modules/redrock_joint_editor_20261023f/core.png)|六区编辑草案；未接正式世界|
|赤岩·左墙岩肩|[left.png](../game/art/modules/redrock_town_20261028a/left.png)|[left.png](../game/art/modules/redrock_joint_editor_20261023f/left.png)|六区编辑草案；未接正式世界|
|赤岩·右转墙岩肩|[right.png](../game/art/modules/redrock_town_20261028a/right.png)|[right.png](../game/art/modules/redrock_joint_editor_20261023f/right.png)|六区编辑草案；未接正式世界|
|赤岩·查看员待机|[guard.png](../game/art/modules/redrock_town_20261028a/guard.png)|[guard.png](../game/art/modules/redrock_joint_editor_20261023f/guard.png)|六区编辑草案；未接正式世界|
|赤岩·夯土材质|[earth.png](../game/art/modules/redrock_town_20261028a/earth.png)|[earth.png](../game/art/modules/redrock_joint_editor_20261023f/earth.png)|六区编辑草案；未接正式世界|
|赤岩·望关台|[tower.png](../game/art/modules/redrock_town_20261028a/tower.png)|[redrock_20261023a_tower_v1_padded.png](../assets/processed/redrock_gate_20261023b/tower/redrock_20261023a_tower_v1_padded.png)|六区编辑草案；未接正式世界|
|赤岩·牲口饮水槽|[trough.png](../game/art/modules/redrock_town_20261028a/trough.png)|[redrock_20261023a_trough_v1_padded.png](../assets/processed/redrock_gate_20261023b/trough/redrock_20261023a_trough_v1_padded.png)|六区编辑草案；未接正式世界|
|赤岩·商队货垛|[cargo.png](../game/art/modules/redrock_town_20261028a/cargo.png)|[redrock_20261023a_cargo_v1_padded.png](../assets/processed/redrock_gate_20261023b/cargo/redrock_20261023a_cargo_v1_padded.png)|六区编辑草案；未接正式世界|
|赤岩·裸岩材质|[rock.png](../game/art/modules/redrock_town_20261028a/rock.png)|[redrock_20261023b_rock_v1.png](../assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_rock_v1.png)|六区编辑草案；未接正式世界|

新增生图3张（平顶民居、牲口棚、层台岩坎）各内置1次、无fallback/CLI，原PNG和工具输出字节同。[完整提示词/独立队列](../assets/staging/redrock_town_20261028a/production/prompts/tasks.yaml)。20工程贴图均字节原样复制，没有新本地裁切、补白、缩图或清alpha；新3与25a旧8的完整A1留白失败仍保留，只在草案看布局，不获得正式美术准入。既有许可没有扩用。

## 验证结果与限制

首独立GPU实际54检查/2失败/5332运动采样：20导入全RGBA、关门/主路与其它支路、4阻挡负控、W输入、Tab/分区镜头、空格说明/关闭/重置通过；民巷前岩台整段放大过高阻路，原整次FAIL及图片/日志保存在initial-failed-run。没有删碰撞来掩盖。

修订为两段较短等比岩台并补六侧巷房后，仅运行残余：14检查0失败/2438运动采样，自然退出0，继承原52成功组件，不重导入/旧输入矩阵。独立最后3镜头标题/3原生图片检查0失败，stderr空。没有把QA显式定位称连续玩家旅行，也没有重跑洛阳组件。

只发布86新增文件：20 PNG、60独立导入叶、GD/UID、shader/UID、Scene及资源清单。没有复制全局UID数据库、运行生产全import或操作用户编辑器。205观察项首末SHA/bytes/mtime保持=True，其中save/备份文件162；保护范围是本次列出的共享脚本/项目与旧赤岩及save，不冒称全工程未变。

仍待：原图留白准入、外部峡壁/台地连续收口、街沿/院落围合与精细密度、生活NPC稳定行走和同人立绘、室内/任务服务、正式世界接线。四十节点的局部验证不等于完整设计艺术终验或完整NPC系统。

## 与另一城市并行

两对话分别持有各自城市的场景/脚本/素材目录，使用独立project与user-data目录验证。公共Router/Field/autoload、project.godot、根prompts/tasks及用户编辑器不由本批改动。共享接线需要在城市草案稳定后串行整合；本批已落地的文件不依赖另一个城市修改。没有以用户同意并行为由向另一个对话自动发送消息。

证据：[初次FAIL](../assets/staging/redrock_town_20261028a/initial-failed-run/verification.json)、[残余通过](../assets/staging/redrock_town_20261028a/town_project/artifacts/verification-remaining.json)、[最终视觉](../assets/staging/redrock_town_20261028a/town_project/artifacts/final-visual.json)、[发布清单](../assets/staging/redrock_town_20261028a/publication.json)、[保护末检](../assets/staging/redrock_town_20261028a/protected-after.json)。
