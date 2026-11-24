# 2026-10-30n 武当、华山新版室外正式采用

状态：两原大地图入口已正式接入既有新版室外，可试玩。Root实际109820自然0、54检查0错误、20条输入，武当与华山两正常图已亲看；本批停止追加实机，细节交用户验收。

用户已明确确认：“一并接入武当、华山”，保留原任务、NPC和进出关系。采用现有室外成品，不重画建筑或地图；凌月内庭不在本轮范围。

## 目标和边界

- 武当：`openworld_wudang_gate` → 现有 `game/scenes/drafts/sect_maps_20261029k/wudang.tscn`。
- 华山：`openworld_huashan_forecourt` → 现有 `game/scenes/drafts/huashan_map_20261029m/huashan.tscn`。
- 独立宿主/接线适配器放 `game/build/sect_adoption_20261030n_system01`，不改两原草案、原NPC/对白/任务资源或原后续内区。
- 保留World原门ID/坐标及下山目标、原第一内区入口与返回新外场脚；真实NPC按原身份和业务迁移到同层净空位置，不用装饰居民冒任务角色。
- 必要旧源仅town registry和native_sources精后继，保原14入口/166源，不松source guard，不改共享Router、MainField、Player、project或存档schema。
- 本轮不重跑30m五桥、30j/30l采集制作、旧三门派或全城矩阵。编辑器51856保留；只Root运行有限新场景验收。

## 工作分工

System：新两派宿主、原业务脚映射、版本迁移/返脚及精来源候选。

Source：只读原SceneScript/门户/NPC/草案地形，给显式ID映射和空间出处，不编新剧情。

QA：本轮fresh元数据保护、公开World进新两派/原NPC对白/原内区进返/下山的有限验收。171存档只SHA/bytes/UTCticks，明确9合法absent；不读内容、不写、不恢复。

## 已合入

- 新独立Field继承现30a门派宿主，复用原Scene/Terrain/controller；不在ready后set_script、不改两草案。只在新adapter补原业务显式ID脚位、控制权/离场归属与中性Space说明；原说明里的“正式世界未接”只在新无目标fallback替换，原草案文本保留。
- `town_registry.gd` 当前 `229D6B687DB124B5277D74530B0DBAF8FEDE9CA779752DD9BB0BD2A19BE49E08`，native manifest `44E291A295DEC854A3C3BBB21CEB6BF4CDED52F7BCF96ABC70309402B331693D`；原14ID顺序保→16，原3条SECT_IDS不动；原166source键值保→200，仅34真实新增依赖。
- 新Field `720F051244047A9D0E46DCA20C1AECEEAFE9260DF980BB5ADA25F866376F84F6`、contract `33F0AE67`、entry `CF33A0EE`、data `21DBE0C0`、tscn `9E92525E`；完整精pin和逆见[首收据](../../game/build/sect_adoption_20261030n_system01/closure_receipt_READY.json)与[唯一说明后继](../../game/build/sect_adoption_20261030n_system01/fallback02_receipt_READY.json)。
- native版本3005隔离旧UV；先验证旧3072×2048原全脚合法再显式迁门前，原首内区返回映原生同层脚；同版合法脚精保，楼内/未来版本仍拒。不以nearest、宽松距离或关闭source_valid躲过校验。
- 武当默认1700,4100、下山1700,4200、内区门2500,2620/返2500,2700（L1高180）；原弟子1900,3900。华山默认2780,4420、下山2780,4520、内区门2700,2500/返2700,2580（L1高240）。箭头显示用持久-elevation偏移，物理Area仍在地面XY。
- 保留原一名武当守山弟子的身份、精灵、对白；华山山门原0NPC，不把原后续人物搬来凑数、不造新任务/奖励。原原生草案也只有Player，无装饰NPC被删除。
- 原World action行/门户ID保，只在这两处宿主复用既有leave_town按真实入门前脚返回，避免通用go_world_map覆盖为默认门点。原太极场、演武坪、更深内区的Scene/dialog/quest/地图文件均不改。凌月内庭与主线另用ch3场景不在本轮采用范围，不能称所有门派内景已改造。

## 实际验证与保护

[唯一实际结果](../../game/build/sect_adoption_20261030n_qa01/actual/109820/result.json) `2B69367EC719075582F192AA44FBB57A8D7A0A1C6387DB3051BDD80B138716B5`：自然0、54/0、20输入，约50秒；新3GD/场景与原source_valid先核，四个代表版本分支、两原World门真Space入场、武当真实主角先开口→原弟子单节点、W主阶连续0→180与L0→L1、两原首内区真进返与下山返回精World原脚均过。华山原后续NPC只静态保护，未冒实际NPC对白；近场由公开3005设置明确标非连续全程登山，不把脚本列未走路段算已实走。

Root亲看[武当正常图](../../game/build/sect_adoption_20261030n_qa01/actual/109820/wudang_normal.png)和[华山正常图](../../game/build/sect_adoption_20261030n_qa01/actual/109820/huashan_normal.png)。仅授本轮既有室外采用/流程正常，不授全地图美术终验或所有房间业务重做。

[末保护](../../game/build/sect_adoption_20261030n_qa01/final_guard_ACTUAL.json) `B7F99A06D1F83F5C4E3C93A9BFFE2436451CDDDB924A7B42E65A0D190FD2C162`：970原源中只有2授权变化；171真实存档SHA/bytes/UTCticks精同，9合法缺省明确保；200依赖/5新叶精核、0外差。只有editor51856保留，自有游戏自然退出。真实save仅哈希与文件元数据，不解析内容、不调存档业务API、不写入或恢复；原7退出ERROR/ObjectDB警告仍在，不称空stderr。

首launcher01因Root日志目录未建而pre-engine失败，记录[原失败](../../game/build/sect_adoption_20261030n_root01/launch01_FAILURE.json)，未启动引擎/未停用户进程；创建独立日志目录后fresh adoption02运行。首次native apply_patch保旧CRLF导致仅换行SHA不同，证明去CR全文精同后按封存JSON数据精晋升LF；不把格式差异当语义或guard放宽。

## 后续

图鉴总数5253不变，55条既有资源只更新当前消费者/场景用途和当前采用说明，旧消费者与旧说明保留为历史；其余5198条、非resources、summary/categories及原缩略cache精同，新增记录/缩略/PNG处理为0。见[图鉴精证](../../game/build/sect_adoption_20261030n_source01/catalog55_final_PROOF.json) `BB57153048B5BBF862BCAAAF9E1AF7AE6D9DBD7C43657C96AF6E00F8F2FC1F04`。

交用户验证两新版室外的布局/尺度/素材细节。本轮不新生图、不导入图、不重测五桥/旧三门派/完整内区矩阵；停止本批重复实机。
