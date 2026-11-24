# 南市窄门脸 · 2026-10-21ag

后续：用户已明确授权无损透明扩画布；ah派生图20项独立检查通过，原图及本AG失败记录保持。详`docs/changes/luoyang-apothecary-canvas-padding-20261021ah.md`。仍未导入或部署。

状态：首栋形体检查完成，透明留白处理选择待确认；未导入或部署。当前正式地图仍ae，af候选与六张失败原图冻结保留。

## 本批目标与边界

先完成一栋真正单开间的药铺：先按成人净门高度120–150px确定缩放，再检查整栋面宽是否≤380px。入口内不烘入桌柜，完整A>0轮廓须有真透明留白。首栋通过后才继续书斋与宅门，不先批量生成。

使用内置image_gen，无CLI/API fallback。本次重新设计窄体量，不再引用旧宽楼或失败图。任务和提示词由ART登记，Root调用并保留原始输出，未知模型/费用不补造。

System先只读计算原灯柱、庭树、NPC巡游、任务点与街道约束；可对新建筑采用不同深度和显式新门位，不要求三栋硬排同一条线。公共脚本、现正式native、存档、人物身体及旧内景不因素材准备而变化。

## 分工与验收

1. ART：第一栋药铺的提示词、登记、离线预检、真实门洞和完整alpha测量。
2. System：首栋可用区域与未来分组间距，不先重做af接线或来源审批。
3. QA：新当前事实保护、独立只读素材检查；Root统一运行检查。

合格后再决定最小集成目标；图像生成或离线预检不代表正式地图已替换。所有失败保留，不改af原FAIL，也不重复ae实机、四城和十房测试。

## 实际记录

### 一次内置新生成，零参考

- [原始窄药铺PNG](../../assets/raw/luoyang_market_frontage_20261021ag/facade_luoyang_narrow_apothecary_single_bay_v1.png)：SHA `B329B4941654194B0F1E69EECDAB77A67D08C437526CF589B6C7C857860F2FA9`，1160×1355 RGBA，1974160B；完整RGBA SHA `1A7DF54882C2C40A7CFEF06AEBBD2B6D4F2D8C7C525B9445672F0EAAFF1FEFE2`。
- [提示词](../../prompts/luoyang_market_frontage_20261021ag/facade_luoyang_narrow_apothecary_single_bay_v1.txt)：SHA `32DDBFDB4C0F32F4110155C54FECEC8DE6F0F2453E2A1F61F9F34A62FC87EE88`；单任务离线预检 `A5BD93C8…512273`。实际1次builtin generate、零参考图、无CLI/API fallback、无edit、本地处理、导入或引擎运行。model/provider/cost工具未披露，保持null。
- 原始输出保留于工具默认generated_images目录并原样复制到工程raw；没有裁切、去噪、阈值擦边或变形。

### 有限通过与明确失败

Root、ART和独立QA均看过真实PNG：单层、窄单开间、一个主门、一侧药材窗；主入口内无桌柜横挡。形体比例有实质改善，但这不是整项正式素材准入。

完整A>0包络 `[0,9,1144,1262]`（右/下为exclusive），1144×1253，主体占画布宽98.62%，四边余白0/9/16/93px，左边仍42个非零alpha像素。A1共224个连通块，主块845867像素，其余223块合计599像素；A16包络只能辅助阅读，不能代替完整A1。原图透明留白和占比要求仍FAIL，不改写成PASS。

两份独立人工门洞口径保留：QA以内口纵线`x522,y544→1178`约634±8px，ART以檐下至门槛前沿`y525→1198`约673px。两口径下完整宽/净门高约1.70–1.80，均小于2.3；正式地面脚锚未冻结，不把目视估值当作运行实测。

独立QA报告：[single_raw_png_readonly_review.json](../../game/build/luoyang_market_frontage_20261021ag_qa01/single_raw_png_readonly_review.json)，SHA `9EE2AD21335FF5A1687B9C3363B9A53380EF847C003F3224FCA500EB44284808`。ART原始元数据SHA `676F8E7971E800A4B81740FE1DF2D76776D8087D7867F4884FD25E25DEA4D026`。原图仅获形体/入口有限通过，状态为`RAW_MARGIN_FAIL_BODY_PROPORTION_PASS`，不授import/layout/runtime/formal。

### 真实场景空间约束

System重新测量原native及实际District追加物，而非沿用旧近似尺寸：原灯柱`1940,1450`完整alpha南尾1453.51；另有铺中伙计`2080,1580`、前巷灯`2420,1770`和多棵树。候选小窗口A（280×205）无法同时容纳这张图并保净门高120px；不能把它再整体缩小塞进去。

窗口B（220×284）名义可容纳，按220/1144缩放完整A1约220×240.96，保守内口门高约121.9±1.5px，但该位置与现共享楼相交，必须未来拆楼、门位与返脚一同迁移，不能直接additive接入。只读窗口记录`6E2D856D…`和后续缺口`9EADFA35…`位于[System只读目录](../../game/build/luoyang_market_apothecary_20261021ag_system01)。没有875/Physics、导航或门户往返信用。

### 待确认的无损透明扩画布方案（尚未执行）

原图可作为完整RGBA子矩形无损放到1907×1567真透明画布，偏移`[382,148]`；完整A1包络将变为`[382,157,1526,1410]`，占宽约59.99%，四边均达到10%透明余白。方案不删除任何原图像素或223个离散小块，不重绘主体、不拉伸、不改门洞比例；原始PNG保持不动。

此方案仅解决画布构图，不使窗口A、旧楼相交、solid/NAV、三房用途或正式来源后继自动通过。依据[imagegen图像处理规范](C:/Users/rajqiu/.codex/skills/.system/imagegen/SKILL.md)，本地图片编辑不默认执行；已向用户询问仅背景/透明边距整理选择，目前未收到答复，未写派生PNG。没有追加生图或登记书斋/宅门。

## 下一步

先按用户对背景处理方式的选择完成首栋留白，再对实际派生图做全RGBA保持与完整A1复核；合格后才继续另一门脸及同步拆楼布局。不得把首栋形体有限通过当成南市已改好或新加载性能结论。

Root最终保护检查：[final_guard.json](../../game/build/luoyang_market_frontage_20261021ag_root01/final_guard.json)，SHA `AAA42C63CC444A752518FF50423AF95F063CC202C2FA156C9215638CAE57D919`。从AF2094路径集合重采当前基准`A4BE1F60…`，本轮仅任务登记一项授权差，其余2093项含15个存档SHA/bytes/UTC精确ticks完全相同。任务登记最终SHA `A5DB9712D775021C9F508C6F8BD629FEC3EECB366323EB7DF442972BA9DA773C`。无引擎/导入、无正式代码或地图改动；编辑器与Ollama服务不代停。
