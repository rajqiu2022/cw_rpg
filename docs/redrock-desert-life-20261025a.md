# 赤岩沙漠生活资源 · 2026-10-25a

**当前使用更新（2026-10-28）**：本批8张原图已通过字节相同的工程副本供[赤岩六区编辑草案](redrock-town-20261028a.md)使用，详同目录`usage-update-20261028a.json`。原图与A1失败记录保持，未正式世界准入。下文“当前消费者0/未导入”是10月25日原始交付时点记录，以本段与新场景清单为当前消费者依据。

本批沿已选赤岩总规与现有连体关防材质继续生产，新增 **8 张原生透明PNG：3建筑、3场景实体、2植被**。使用内置 image_gen，每个ID一次，无CLI/fallback/自动重试。全部是独立场景/大世界组件；当前游戏消费者为0，未导入game或改世界入口。

所有原图与内置输出逐字节一致，保留真实RGBA、弱alpha及隐藏RGB，**未裁切、缩放、扩画布或清alpha**。8张完整A>0四边留白均未达10%，原失败保留；主体明显留白和诊断alpha128包围盒均不替代完整检查。旧批次像素处理许可没有扩用到本批。

| 类别 | 组件与原图路径 | 尺寸 | 计划放置（非当前使用） | 当前使用/结论 |
|---|---|---|---|---|

| 地图建筑 | [赤岩·平顶商旅驿舍](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_inn_v1.png) | 1585×992 | 驿舍马院 / 沿街接待建筑 | 引用0；候选，完整A1留白FAIL |
| 地图建筑 | [赤岩·商队修车棚](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_repair_shed_v1.png) | 1774×887 | 石作修坊 / 开敞作业棚 | 引用0；候选，完整A1留白FAIL |
| 地图建筑 | [赤岩·蓄水井棚](../assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_cistern_v1.png) | 1536×1024 | 蓄水小院 / 独立取水小建筑 | 引用0；候选，完整A1留白FAIL |
| 场景/世界实体 | [赤岩·封口储水罐组](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_water_jars_v1.png) | 1254×1254 | 蓄水小院与驿舍 / 放置物件 | 引用0；候选，完整A1留白FAIL |
| 场景/世界实体 | [赤岩·车轮轴木工作台](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_wheelbench_v1.png) | 1536×1024 | 石作修坊 / 可调查场景实体 | 引用0；候选，完整A1留白FAIL |
| 沙漠植被 | [赤岩·风蚀旱树](../assets/raw/redrock_desert_life_20261025a/vegetation/redrock_desert_20261025a_dry_tree_v1.png) | 1254×1254 | 阶街边缘与峡壁层台 / 植被 | 引用0；候选，完整A1留白FAIL |
| 沙漠植被 | [赤岩·荒漠枯黄灌木](../assets/raw/redrock_desert_life_20261025a/vegetation/redrock_desert_20261025a_dry_shrub_v1.png) | 1254×1254 | 道路侧肩与岩缝 / 低矮植被 | 引用0；候选，完整A1留白FAIL |
| 场景/世界实体 | [赤岩·岩矿调查点](../assets/raw/redrock_desert_life_20261025a/scene_prop/redrock_desert_20261025a_ore_cluster_v1.png) | 1585×992 | 石作修坊外与野外岩肩 / 采集实体候选 | 引用0；候选，完整A1留白FAIL |

## 逐件使用限制

- **赤岩·平顶商旅驿舍**：平顶双层轮廓、赤砂岩与斑驳土抹灰可辨；正面门前有小台阶。上层门只作外观，未设计楼梯/楼内，不能当作可达门户。
- **赤岩·商队修车棚**：平板木顶与后侧石墙，前方开敞工作湾可辨；车轮与木料收在后墙。柱脚、遮挡和车位净宽尚未实机标定。
- **赤岩·蓄水井棚**：井口、绞盘、木桶与平顶苇棚可辨；是独立取水小建筑。未绑定饮水/任务交互，井沿与柱脚碰撞待做。
- **赤岩·封口储水罐组**：三罐共用低木托，适合水院或驿舍墙边的低矮陈设；不是背包道具图标。前方操作空间尚未布局。
- **赤岩·车轮轴木工作台**：车轮、轴木、木槌与台架组成一个工作点；适合修车棚内部或侧边。真实地图比例与工具可读性待落地。
- **赤岩·风蚀旱树**：树干扭曲、叶色灰黄；树冠比提示词要求偏密，只适合镇内/蓄水院边少量使用，不当作裸旱峡谷的通用稀疏树。
- **赤岩·荒漠枯黄灌木**：低矮枯黄灰绿灌木，结构与乔木分开；叶团仍偏密。后续按成人膝至大腿高标定，不直接用原画布宽度定比例。
- **赤岩·岩矿调查点**：赤色层状岩体夹暗灰矿脉，作为野外调查/采集实体候选；没有新增矿物Item ID、奖励、任务或掉落。

## 查看与复用

[资源图鉴](equipment-skill-catalog.html#resources)沿用缩略图与点击原图放大，按赤岩建筑/场景与大世界物件/沙漠植被分类。图鉴显示当前引用0、计划用途和待装配状态；本批仅做离线路径/缩略图/条目校验，不宣称浏览器实点。

每张PNG旁有同名`.meta.json`，`resource-pack.json`列原图路径、完整提示词路径、输入参考SHA、输出SHA、尺寸和alpha结论。内置工具未提供准确模型/provider/费用，元数据保持null。

本批提示词与独立队列：[production/prompts/tasks.yaml](../assets/staging/redrock_desert_life_20261025a/production/prompts/tasks.yaml)；模板使用项目真实renderer预检8项通过，仅本进程切换模板目录，未写根`prompts/tasks.yaml`或改生成器源码。

参考：已选[赤岩总体图](../assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png)（空间/生活用途），[连体关楼原生模块](../assets/raw/redrock_joint_trial_20261023e/building/redrock_joint_20261023e_core_v1.png)（镜头/材质/光照）。没有恢复用户否定的c版布局。

## 后续待办

先做驿舍马院、石作修坊和蓄水院的分区尺寸平面，再按原像素比例标成人门高、脚点、柱脚与遮挡；不得把新增画布整体fit到旧框而缩小主体。建筑/物件不替代既有NPC待机与行走需求。NPC稳定行走、全镇装配、完整关墙五锚、正式世界接线仍待，不因本批8图生成自动完成。

## 核验范围

图鉴最终4821文件/2514图/2307音。本批8以外，扫描同步了先前未入图鉴的5张洛阳已有资源；旧条目仅主角立绘usageCount71→72，装备/技能/任务/剧情数据精确保持。复用索引1785份文本源稳定，显式缺口0。181项保护观察中180（含162个save/备份文件）SHA/字节/mtime保持；根`prompts/tasks.yaml`在窗口内变化，本批未写该文件并保留当前值，不宣称全保护同。

井棚/工作台原生alpha最大254，首QA误要求必须含精确255而失败，记录见`native-verification-initial-fail.json`；后继只验证透明通道事实并报告原值，未清理/归一alpha，不改变本批8项留白失败结论。

[native-verification.json](../assets/staging/redrock_desert_life_20261025a/native-verification.json)核原始SHA/真实透明/完整A1；[catalog-verification.json](../assets/staging/redrock_desert_life_20261025a/catalog-verification.json)核图鉴新增、缩略图与放大路径及非resources保持；[protected-after.json](../assets/staging/redrock_desert_life_20261025a/protected-after.json)核根队列、生成器、参考、旧赤岩结构工程和已记录save快照。没有运行Godot/import/旧组件复测或操作用户编辑器。
