# 2026-10-31a 岚溪寨架空木街侧边阻挡

状态：已正式合入；唯一局部实机83612自然退出0，42检查0错误、18条输入，一张正常画面Root已亲看。本批不再追加引擎检查。

## 缺陷与修复

用户截图不是World五桥，而是岚溪寨 `RaisedMarket3` 高脚木街。同型 `RaisedMarket4` 也缺南侧碰撞；原北栏碰撞短于桥面。两处现在均补完整南边界，并把原北栏碰撞延长到桥面边缘。不封左右端、不把整片桥下支架做成巨型障碍；原贴图、UV、视觉层级、地形高程、三座旧桥和四条台阶保持。

- 木街3物理中心3650,3560，木街4中心6740,3930，均属原L0；不能因画上高脚柱就伪造新高度层。
- 桥面局部X为−574.2..575.94、Y为−20.3..20.3；北碰撞Y−34.3..−22.3，新增南碰撞Y20.3..32.3，layer16/mask0，与原主角mask24一致。
- 原实际脚体34×24。旧脚兼容用更保守35×25全脚，仅旧合法、被新增边界覆盖且整脚X仍在桥面内时，同X移回该桥中心线；目标仍须同层净空。其他合法脚、远处桥下地面及旧非法脚不挪动，不使用nearest或存档内容API。
- 木街3最左端原就处于WaterLast水体，未删旧水或声称该端新可走；本轮只验证其右端干地出口，木街4两端干地可通。

## 正式来源

仅三个旧文件改动及一个新控制器：

- `game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn`：`CD88D0003066EB42A0DCEC5D20404E4BAD6313456B383584386EF3F1EDA9D756`。
- `game/build/three_towns_world_20261029j_system01/native_sources.json`：`0F39017F7F88CDC3F175E1962EE4B0A2882E67BE034814DF95D5D2B35D2AC8DD`；旧200键保留，只更新Scene并追加新控制器至201。
- `game/build/three_towns_world_20261029j_system01/town_registry.gd`：`83CF61BABB48EC7FF2CB2A4CD4C18AE724C6C457FB4BB39A32E41EE46F4F1054`；只后继manifest头。
- 新 `game/build/lanxi_boardwalk_edges_20261031a_system01/boardwalk_controller.gd`：`21CA53A69E7777428A5B1517500BC6849E5DFBAD111901508B03723BFFAAA30A`，继承30l控制器，原控制器和遮挡逻辑不改。

完整六hunk及整逆在 [READY收据](../../game/build/lanxi_boardwalk_edges_20261031a_system01/receipt_READY.json)，SHA `44868BFD01A97B2581D61AB392CA697FEBA6CA6313C7CA500FEED9ECE3F19EAD`。0PNG修改、0生图、0World五桥/武当华山/共享Player/Router/project改写。旧Scene已有166无unique_id节点，本轮不借此对整Scene做UID规范化。

## 唯一实际与保护边界

[实际结果](../../game/build/lanxi_boardwalk_edges_20261031a_qa01/actual/83612/result.json) SHA `CC70017213EBDB5DD96AAFFEF52208FF8DBC5E8C22D838BCA97FAD951E6F9E30`；Root冻结脚本 `58251306…` 首末相同，launcher137748，运行22865ms自然0，未工具强停。

公开native默认进入及局部公开设置明确标为非连续全程旅行；检查新源闭包/两侧真实W、S顶边阻挡/三处可用干地桥端短腿/旧新增边脚精X迁移/远处地面脚不迁移。正常图 [boardwalk3_normal.png](../../game/build/lanxi_boardwalk_edges_20261031a_qa01/actual/83612/boardwalk3_normal.png) SHA `FCD96DF1B6023400371C75F0AB843B0B67ABF7FE4847FB7C4902DC5FD6AC9858` 已亲看。不冒全城ART、全部桥头贯通或整图通行验收。

用户自行退出118864后才采fresh基线 `83B5B871…`：979源、171存档、9合法absent；用户此前save0/bak两处更新原样保留，不以30n旧值回滚。编辑器51856保留。末只读保护见本目录后续收据；171存档只查SHA/bytes/UTCticks，不读内容。既有7条RID/纹理/RenderingServer退出ERROR及ObjectDB警告原样记录，不称stderr clean。

末 [final_guard_ACTUAL.json](../../game/build/lanxi_boardwalk_edges_20261031a_qa01/final_guard_ACTUAL.json) SHA `2581651DA91B1558ED0D53AA523F0495D9F39816A758F903BD4CB7898AB5B861` 已由Root只读运行通过：979源恰3授权变化、0外差；171存档首末SHA/bytes/UTCticks同、9absent保；201真实依赖精核、原其余199键值同、3旧源内存整逆精回fresh基线。前末仅editor51856；0引擎复测、0进程控制、0存档内容读取或写入。
