# 其他城镇模块素材首批记录

change-id: other-city-modules-20261022

目标：按照洛阳总规已确定的组件化、成人门洞和用途区分方向，开始制作其他既有城镇的建筑、人物、敌人和任务物件，并同步资源图鉴。设计范围见[制作方案](../other-city-modules-plan-20261022.md)。

## 已完成

- 内置imagegen共22次：18次新生成＋4次以NPC原图为输入的同人立绘；每个登记任务只调用1次，无CLI/API fallback。具体模型、供应商和费用未披露，元数据留空。
- 5建筑入口、4NPC静态待机、4立绘、4人形敌人、1山狼、4任务/采集物件，按汴州/金陵/襄州/清河/雁门/跨城通用和用途分类存放。全部原图及逐件收据在 `assets/raw/other_city_modules_20261022/`。
- 完整性核验通过：22PNG与各自内置输出SHA相同；19个现有设计来源SHA未变；22任务唯一、提示词原文与登记一致；旧tasks字节前缀完全保留。初始离线预检遇到历史重复ID的FAIL保留，仅新22范围预检通过，未改旧重复。
- 图鉴新增22个候选卡片，中文名称、城镇/类别分组、尺寸、复制路径、缩略图及原图放大入口齐全，注明设计依据不等于当前消费者。最新4580文件/2273图片/2307音频。原124装备/67招式/126任务/8剧情及其余非resources字段完全一致；22张新缩略图解码与路径核验通过。
- `resource-reuse-index.md`已增加逐图路径、尺寸、设计来源和候选状态。三张真实alpha合成联系表已实看，见[素材说明](../../assets/raw/other_city_modules_20261022/README.md)。

## 检查结果与限制

**原图已生成，22张均未达到完整alpha四边≥10%留白；原失败保留，未准入game。** 每张都有真实RGBA透明通道。在真实alpha合成联系表中主体清楚，不能把原图查看器的隐藏RGB误当大面积雾底；这也不能替代完整A>0检查。当前没有扩画布、清背景、阈值删alpha或缩放派生图。

四组NPC的原图/立绘身份和服色可辨；待机图俯角偏正面仍需在实际探索尺寸复核。四名人形敌人虽有颜色、装备和体格区别，劫匪/私枭/刀匪姿态与脸型仍相似，保留进一步区分的空间。所有NPC和战斗图仅单帧，不能称已具备行走或攻击动画。建筑的实际成人门尺度、脚锚、碰撞、导航、门户与返回点均未验收。

缉捕木榜和药包纸条均无虚构可读文字；行粮袋/铁矿石/药包沿现有功能，不新增任务、奖励、物品ID或掉落。山狼只作现有可选定义的视觉储备，未新增城镇遭遇。

原登记脚本的并发JSON写入曾漏4条汇总记录，逐图meta和PNG都在。保存 `manifest_before_receipt_reconcile.json` 与 `receipt_reconcile.json` 后，按既有收据/内置输出SHA补齐，没有重新生图。金陵立绘复制后因缺参考SHA登记失败亦保留 `record_failure_jinling_portrait.json`，只补缺失收据；脚本改为事先验证参考、加文件锁并顺序登记。不是原始执行全程无错误。

## 文件与验证

- 生图登记/原文：`prompts/tasks.yaml` 仅追加新22条（skip=true，防止CLI重复执行）、`prompts/templates/other_city_asset_20261022.yaml`、`prompts/other_city_modules_20261022/`。
- 制作/复核：`scripts/other_city_assets_20261022.py`、`scripts/audit_other_city_assets_20261022.py`、`scripts/verify_other_city_gallery_20261022.py`。
- 图鉴/索引维护：`scripts/build_resource_gallery.py`、`scripts/build_resource_reuse_index.py`、`docs/assets/resource-gallery.js` 的说明文案和重建HTML；原放大/筛选控件逻辑未改。
- 检查：Python语法、JS语法、`audit_other_city_assets_20261022.py finish`、资源图鉴数据保留/22缩略图检查通过；索引重建逐项链接检查。新数据同步未另跑浏览器交互，沿用前次控件实测，不新增音频播放/窄屏通过结论。
- 证据：`assets/raw/other_city_modules_20261022/integrity_audit.json`、`visual-review.json`、`tmp/other_city_modules_20261022/gallery_verify.json`。原图库没有移动；本任务未运行Godot、未导入game、未更改正式绑定或操作用户进程。

## 待办

先解决本批透明留白与有限边缘问题，再测建筑门洞、脚锚和世界比例；依据各城路网组装、验证碰撞/导航/门往返。NPC步态和敌人动作须另行制作与逐帧验收。本批不改变洛阳AP当前进行中/正式AO的结论。
