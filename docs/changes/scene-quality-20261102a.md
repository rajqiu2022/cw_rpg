# 2026-11-02a 自然路口分类与11pair双向正式有限交试玩

最终状态：第5自然路口22端分类已实施（14短轴土肩+1已接受South样板原样+7保既有真实道路），Root仅对53220South/73468Docks/97124Civic三类正常图本域接受，非逐22ART或整城ART。第6现有11pair22真实方向完整信用，unique22=11d8+2462414−旧yamen_artisan两向+97124新两向；未改20不复，公开near setup非World全程连续旅行。

Root97124自然0/109检查0/8INPUT/2真向/1新Civic正常图，北移一口720840/返脚824840避真围墙，retired720970与其余21端保。Root唯一[guard02末检](../../game/build/city_navigation_20261102a_guard02/final_guard_ACTUAL.json)实际PASS `c476ebdc8fed2f95579afd73f57d6b038e57c6efaf0595d5f518f18bb20e27ac`：208有限源/204同含134、99现役C237/原96中93叶同、171metadata精同9absent/只after1pass、0内容读写恢复。所有engine已退，前次editor51856保；停止源/进程/171复查，交用户重新运行试玩。46516缩进FAIL、73468整FAIL及旧Civic ART拒、UTF8 hunk预检拒与旧退出ERROR均保。

## 已有实际证据 / 不重复成功域

- [剩余14向实际24624](../../game/build/city_navigation_20261102a_qa01/actual/24624/result.json)：SHA`d0350e044e9ac07252b2e55c1ddc1d4c2b857980f8af2eecb122b24c7abd071b`，351/0、56输入、14新legs；在原760534/96pool上运行，Pair/Geo/host/action/arrival/NAV无改。原11d四对八向只继承，不算这次新输入。
- 样板visual01/46516的QA缩进parserFAIL保留；后继visual02只修QA缩进，不改生产代码迎合测试。[53220实际](../../game/build/city_navigation_20261102a_visual02/actual/53220/result.json) SHA`d2a9d2c5be9d706c58e3eb3a3102d719c18e4350f08783db82bd7b8eea2a393f`，70/0、0输入/1图；[原正常图](../../game/build/city_navigation_20261102a_visual02/actual/53220/temple_south_natural_mouth_sample_normal.png) SHA`c3b13d3238f17cf638d95c0f84c83031873a5e910d919a0eab711f754d1227d1`，Root亲看样板本域接受，不冒其他21端同图全过。
- 样板精2helper：Mouth `985A3D3D→D1F0FB90`、shader `0B46EE80→0AEBE837`；[D057候选/精hunks](../../game/build/city_navigation_20261102a_mouth_sample01/candidate_plan_READY.json)、[DFDB实际apply](../../game/build/city_navigation_20261102a_mouth_sample01/apply_ACTUAL.json)绑定D815完整before。manifest`760534/96→9EBD1F6F/99`只改2helper旧叶/94同、加现货GROUND3；[样板99全文归档](../../game/build/city_navigation_20261102a_guard01/manifest99_sample_9EBD_EXACT.json)保留，后续CFD6/C237各阶段独立归档，不覆盖样板。
- [局部残余97124](../../game/build/city_navigation_20261102a_visual04/actual/97124/result.json) SHA`bc28c762b2b09564346a7bc220dac183e654f3ae031876aaf8936e6685f5c2c8`，109/0、8输入、仅yamen_artisan两向与Docks原zoom1.05/physics/receipt尾项；[新Civic正常图](../../game/build/city_navigation_20261102a_visual04/actual/97124/civic_north_real_opening_normal.png) SHA`064f5cec5fdcdf05008dd7e83e16ec7843a804f67964c61abbbb39ec995e2eda`，Root亲看北移口避墙，本域有限接受。
- [73468整报告FAIL](../../game/build/city_navigation_20261102a_visual03/actual/73468/result.json) SHA`ceb4cd120fd5f3a533ec09a328799f0cb6e66e5a3da0d6145a0f95213ce9a6cc`永久保；[原Docks图](../../game/build/city_navigation_20261102a_visual03/actual/73468/docks_narrow_shore_interface_normal.png) SHA`821e816a81e70f3bcd78d92c5277cdaf58c22cdb83e1fd11f9573594b0e8e240`仅土肩改善有限接受，不重拍。[原Civic图](../../game/build/city_navigation_20261102a_visual03/actual/73468/civic_internal_street_normal.png) SHA`92643ea11e8d903c2260f233330eb88e8e0d0abbf475bb90d892134e0c0fa947`ART拒，不由修Docks oracle变成通过。

## 本批只继续原第5和第6项

| 原要求 | 最终有限状态 / 实际证据 |
| --- | --- |
| 5 出口应读成自然路口，不是硬箭头/石地贴片 | 22端分类已实现14短轴+1acceptedSouth原样+7保真实既有道路；细砂土/worldUV/连续土肩，三类正常图South/Docks/Civic本域接受。非逐22ART/整城ART。Civic一口北移避真墙后新图接受，旧拒图保。 |
| 6 A↔B落脚方向配对 | 11pair22真实方向完整信用：旧8+2462414−被后继旧2+97124新2=22，未改20不复。仅yamen_artisan/a mouth720840/arrival824840后继，retired720970/其它21端及host/Geo/NAV/action保；near setup不冒全World连续旅行。 |

按[标准S01–S07](../scene-art-quality-standard.md)处理：用途/道路层级先成立，贴图不是扩大walkable的许可；正常图先过样板，绝对/相对z不得重犯91216/95060。复用现货砂土，不因“更自然”自动生图或改PNG；坐姿/老人/新NPC/整城摆件不在范围。

## 原剩余七对 / 十四向实际记录

以下精pairID取现役`navigation_pairs.gd`，原七对两方向均由24624实际通过，不复制另一套arrival表。后续只有yamen_artisan因一口北移以97124两向替换旧信用，另六对12向不复；与11d8向合成22唯一方向，不因样板或后续推广重复累计。

| pair ID | A→B本轮实际 | B→A本轮实际 |
| --- | --- | --- |
| `yamen_artisan` 府衙↔百工民坊 | 24624旧向后由97124北移口真向替换 | 24624旧返后由97124真返824840替换 |
| `market_estate` 南市↔豪宅庭院 | 24624真向通过 | 24624真返通过 |
| `estate_garden` 宅园↔洛水园林 | 24624真向通过 | 24624真返通过 |
| `docks_garden` 码头↔洛水园林 | 24624真向通过 | 24624真返通过 |
| `gate_civic` 南城门↔府衙街 | 24624真向通过 | 24624真返通过 |
| `yamen_docks` 府衙↔漕渠码头 | 24624真向通过 | 24624真返通过 |
| `market_docks` 南市↔漕渠码头 | 24624真向通过 | 24624真返通过 |

继承、不复跑：`market_artisan`、`market_temple`、`docks_temple`、`temple_riverside`，原131104/25304/109688共8条真方向。11d前后图/失败与final158D证据都保留；本轮公开near setup若采用仍须明确非World连续旅行，截图不冒实际长途走来。

## 最小保护范围

[独立fresh设计](../../game/build/city_navigation_20261102a_guard01/PLAN_READY.md)与[Pair后继](../../game/build/city_navigation_20261102a_guard02/PLAN_READY.md)保护134旧源、原96runtime池、精2visualhelper+1Pair/manifest前后继、3现货媒体叶；208有限并集不扩21/33旧来源闭包，不重跑全图矩阵。

原D815 capture全文备份为96manifest(`760534D8…`)、`mouth_visual.gd`(`985A3D3D…`)与shader(`0B46EE80…`)；补Pair fresh1 `8A450648…`只加一份全文并精核原208 before，未重置基线/重采171。现货三叶`miao_town_20261029f/ground.png`/import/实际ctex保原bytes；详[精清单](../../game/build/city_navigation_20261102a_guard01/PLAN_READY.md)。最终原96只三runtime叶变/93同、追加GROUND3成99；host/Geo/旧134/旧闭包/媒体精同，不扫全图库/重导入。

171只沿158D注册路径做本批一次freshbefore metadata+一次finalafter metadata，保护当前真实值；0内容读/哈希/反序列化/写/恢复。旧158D的ticks/9absent仅历史，不冒本轮fresh值；用户beforecapture已有更新须保留。样板/残余不额外重采171，Root最终一次末检后停止。

## 推广、拒图与最终后继（实际已收口）

分类推广精2helper已合：groups02回执`76B2ADBB…`，Mouth `907B4FD9…`/shader `FF1AFDFC…`，refreeze阶段99为`CFD6D77C…`。22端14短轴+1South原样+7保真路，0deferred；不是22张正常图验收。此阶段原94叶/sample97叶与GROUND3同，原guard01草稿保留未执行；后由明确Pair第三叶续成最终C237/99，不把旧阶段档覆盖为新after。

原计划137548后的实际73468两图已由Root看：技术97/1唯一Docks QA错误要求zoom1，而原Scene为1.05，(304,850)逻辑/物理脚正确，原生图保留；Civic图ART拒，西侧真实围墙/屋瓦投影x627..694/y918..1230挡住旧mouth(720,970)。不能用修QA尾断言替代Civic实景返工，原报告/拒图保留。

Root只批准第三runtime叶Pair的`yamen_artisan/a`口北移至(720,840)、arrival(824,840)，retired旧(720,970)保留、其余21端值精同。[实际apply3B40826F](../../game/build/city_navigation_20261102a_civic_pair03/apply_ACTUAL.json)固定CD338F05/7376B；原677A中文label传输损字hunks首预检拒/生产0写保，实际仅用独立UTF8 `AE22DEA2…`精双逆后apply。显式refreeze最终99 `c237a45c0de473c2c1d1d613933bfad8e2e4906859177e6a0845e06ab6daf28c`，原CFD6全文archive保。

97124只定向复测两向，真返824840与1新Civic图Root接受；Docks原生1.05/全脚/receipt尾项过并继承原图，不重复14/其它20方向。22方向信用按旧8+14−旧2+新2，不累计成24；三类正常图有限接受仍不授逐22自然ART。

Root审核新auth `EB8F02D7…`后唯一guard02实际PASS `C476EBDC…`，sourcepreflight `e1e959d36beb5267d6095dbecf6ced5cad3c8d5fd7f28a96a2f067634a028343`：208源/4明确可变含manifest/204精同含134、99现役/原93叶同、全文双逆及7605→9EBD→CFD6→C237链保；171metadata精同9absent/只after1pass（总before1+after1），0内容读/哈希/反序列化/写/恢复。旧guard01/旧158D未调用，所有旧FAIL/退出ERROR保。停止任何新QA/源/进程/171检测，交重新运行试玩。
