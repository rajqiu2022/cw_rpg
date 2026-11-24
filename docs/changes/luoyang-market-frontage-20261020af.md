# 南市独立门脸与街廓 · 2026-10-20af

## 状态与目标

- owner：producer / system / art / qa，各模块单写权。
- 状态：候选检查点，未部署。承接ae正式地面层，本批只推进南市一个建筑簇，不重做码头或全城。
- 用户依据：已认可z十区总规，要求按区实施；商楼不能同时伪装药铺、书房与豪宅，房屋之间须有规划和间距。

## 范围与实施顺序

1. System核对当前eastrow三门、门返脚、实体足迹与导航出版路径；只在新build目录起草。
2. ART检查现资产体量和檐口，冻结一簇布局及必要门脸；正式新图先登记提示词再调用内置生成。
3. QA独立检查间距、门户与任务保护点；Root统一集成、运行有限检查和实景验收。

受保护：原存档、任务身份和奖励、NPC对白与巡游、主角身体34×24、875+17脚印、其余城区；ae四图及既有纹理导入证据复用，不再导入。

## 风险与边界

- 当前Market地面模块冻结36个渲染前缀。建筑变化必须显式继承合同，不能只换视觉却保留错位的solid、门或返回点。
- AC运行作者固定旧District依赖；ae只严格接受0137→C4FB这一后继。本批优先不动公共District，不关闭来源校验。
- 编辑器51856和Ollama API100140在开始观察时仍活；不代停，不要求为常规代码修改关闭编辑器。
- 不预先授予新场景可玩、整区美术完成或加载小于10秒。结果按实际证据补录。

## 本轮实际结果（未完成正式接入）

东街旧三开间楼确认绑定药铺、书斋、豪宅会客厅三个目的地。候选方案将其拆为三栋单主门模块：药铺、书斋和独立宅门；明确复入两个既有建筑身份槽，保留房间ID，而非把旧楼缩小复制。拟保两条侧巷，具体坐标尚未冻结。行商原巡游线不迁；既有灯柱`lamp_1`及`street_tree_3`仍与初稿包络相交，最终排布必须避让，不能用虚化掩盖。

### 素材与提示词

实际使用内置 image_gen：3次generate＋每张1次定点edit，共6次，无CLI/API fallback。工具未披露model/provider/cost，元数据保持null。全部原始PNG与元数据保留；没有本地抠图、透明度阈值删除、变形或运行时导入。

| 类型 | 原稿与修正版 | 提示词 |
|---|---|---|
| 药铺 | [v1](../../assets/raw/luoyang_market_frontage_20261020af/facade_luoyang_apothecary_single_entry_v1.png) / [v2](../../assets/raw/luoyang_market_frontage_20261020af/facade_luoyang_apothecary_single_entry_v2_ratio_margin_edit.png) | [v1](../../prompts/luoyang_market_frontage_20261020af/facade_luoyang_apothecary_single_entry_v1.txt) / [v2](../../prompts/luoyang_market_frontage_20261020af/facade_luoyang_apothecary_single_entry_v2_ratio_margin_edit.txt) |
| 书斋 | [v1](../../assets/raw/luoyang_market_frontage_20261020af/facade_luoyang_scholar_study_single_entry_v1.png) / [v2](../../assets/raw/luoyang_market_frontage_20261020af/facade_luoyang_scholar_study_single_entry_v2_ratio_margin_edit.png) | [v1](../../prompts/luoyang_market_frontage_20261020af/facade_luoyang_scholar_study_single_entry_v1.txt) / [v2](../../prompts/luoyang_market_frontage_20261020af/facade_luoyang_scholar_study_single_entry_v2_ratio_margin_edit.txt) |
| 宅门 | [v1](../../assets/raw/luoyang_market_frontage_20261020af/facade_luoyang_mansion_gate_single_entry_v1.png) / [v2](../../assets/raw/luoyang_market_frontage_20261020af/facade_luoyang_mansion_gate_single_entry_v2_ratio_margin_edit.png) | [v1](../../prompts/luoyang_market_frontage_20261020af/facade_luoyang_mansion_gate_single_entry_v1.txt) / [v2](../../prompts/luoyang_market_frontage_20261020af/facade_luoyang_mansion_gate_single_entry_v2_ratio_margin_edit.txt) |

六张均未通过本批正式素材准入。v2药铺/书斋按拟定380/360px宽缩放，门洞仍只有约99.6/104px，未达到120–150px目标；书桌凳仍干扰正门。宅门弱alpha灰雾未清。三张完整A>0包络仍触及画布边缘，没有达到四边真透明边距要求。即使局部门洞更合理，也不能把完整FAIL改成PASS。

实测与限制见[ART最终记录](../../game/build/luoyang_market_frontage_20261020af_art01/v2_actual_measurement_and_admission.json)，SHA256 `B3B8FDE4A307F30720091738950A9130D125681C7DA7A6C7C1555C4561AE1F5A`。背景处理不能解决形体比例，本轮没有继续请求抠背景或追加生成。

### 接线代码只到草稿

[System候选目录](../../game/build/luoyang_market_frontage_20261020af_system01)保存单Market纯变换/出版器、三个室内return-only后继，以及Bundle、Rooms、RoomIndex和Ground候选。保持公共District/C/Field/Router/GS/fade、原楼以外实体和原室内家具不变。预定24→26 native、36→38前缀必须由新作者与完整父逆绑定；Ground旧36分支保留，不无条件放宽。RoomIndex与新AF外置开关需同步切换，四城仅增加来源权威叶，其他城区不改几何。

Root对8个`.gd`仅做一次`--headless --audio-driver Dummy --check-only --script`：全部自然退出0、stderr为空、脚本首末SHA相同。[语法记录](../../game/build/luoyang_market_frontage_20261020af_root01/syntax01/result.json)。这不是出版、实际CPU几何、Field、门户往返或性能验收；作者仍PENDING，publisher READY=false，未编制正式来源finalizer。

### 正式边界与下一步

当前运行版本仍是ae。没有替换正式楼、门位、返回点、导航或室内，没有运行入城测试，也没有新加载耗时结论。原ae最终记录不改。

Root最终保护检查：[final_guard.json](../../game/build/luoyang_market_frontage_20261020af_root01/final_guard.json)，SHA `9F6BCCA3DAA78E6092E41B8A803581CE57345FD8568E318516713A90906ED833`。2094项当前基准中仅授权的`prompts/tasks.yaml`登记变化，其余2093项（含15存档的SHA/bytes/exactticks）完全相同；无未授权变化。任务登记最终SHA `61DEBFD2DE4E3C528FF6C9B581ABC63DE9025F13FFE1A7C29FF6F0F6F697B28B`。

独立QA仅静态审计：[候选审阅](../../game/build/luoyang_market_frontage_20261020af_qa01/static_candidate_review_NOTREADY.json)，SHA `60EA1B08F6C43B6279E9E5EB8B2BABC422C351CB8F9831FD2F89F5E5EC2BA001`。与已检查候选SHA一致，但所有作者、素材导入、来源finalizer、新native及代表门往返仍未闭合，不能单独部署这些代码副本。

下一步首先重新确定能在可用街宽内保持成人门高的窄门面比例（净门洞不烘桌柜），再重新量完整alpha并避开灯、树和行商；不是继续缩小本批失败图。仅合格后才冻结作者、单Market几何＋三房return薄出版、一次新mask隔离、来源闭包和代表门实际往返。不重做四城、十房或ae四纹理。
