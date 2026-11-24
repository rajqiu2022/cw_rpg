# 洛阳宅园背景清理与组件组装 · 2026-10-21ak

状态：本批背景处理及真实候选组装完成，整体艺术仍NOTREADY，未正式替换；正式地图仍ae。

## 用户确认与范围

用户对上一轮明确问题回复“确认”：仅允许新主厅、厢房、回廊本地去背景、清边及补透明留白，保留建筑主体与全部原图。采用主厅v2、厢房v1、回廊v1作为三输入；不处理旧书斋／宅门，不再生图。此次依imagegen工作流检查派生，按用户明确许可走本地背景处理例外。

## 实施与验收

1. ART确定外背景掩模、保持区与透明扩画布；Root执行一次并实看，不覆盖原始PNG。
2. QA核对原图、像素改动范围、门洞同尺度、完整A1边界和四柱三开口，不把背景清理冒充所有像素无损。
3. System将合格派生用于新宅园主厅／两厢／两段回廊，NW/NE两树迁移与碰撞、局部mask、受影响路线同步。Root只运行新候选几何与一张真实Sprite组装图；原ai2226路径证明不整批重跑。

保留编辑器和Ollama服务；不改存档、NPC身份／任务、Router或正式城区开关。新候选未通过前不宣称地图已上线，也不宣称加载提速。

## 实际结果

Root实际处理自然0／三张完成。执行源 `DEEAA71B3D60C9DD5413F09F4C27D528148C14D29187E350364F0076176FF15E`，最终先验合同 `A4D7FB3A73CC4017366A9A44F386F272DEF1ECB3E7C0435921A8C2097204F155`，处理报告 `FBA3B0224187E722FE1B2B73A8E2D2A4A0B073193108748D56961F143837A3A9`。未生成、下载或覆盖原图；清理可编辑区以先验策略决定，不从结果差异倒填mask。

派生位于 `assets/processed/luoyang_estate_components_20261021ak/`：主厅1352130E（2560×1072）、厢房7E1783A9（2202×1289）、回廊A335BB05（2615×975）。完整A1四边留白分别427/179/427/179、367/215/367/215、436/163/436/163，均超过10%。主体未重绘、变色或缩放，透明背景边界被裁空再重排，不能称整个原canvas无裁切；所有保护区RGBA保持。厢房门前锚点由整楼中心改为原图556,915，再平移到893,1068。

Root／ART实看三派生无明显主体误擦，厢房灰雾去除；上缘略粗、侧视与主厅正视差异保留。ART `D60766599AE5B9DA25CA2CB240703773EFEA0C9ADE6E135AB728E36AD82B85DB` 仅授离线候选组装。原廊500–560世界宽只有约101–113成人净高，原目标仍失败；Root明确新AK廊段完整宽620–640、高≤250、成人净高≥120，不改人、不非均匀拉伸。实际A1支持新尺寸下净高约127–131。

独立像素首实际自然1／43检查2失败（报告10A85045）：41组件通过，两项仅QA漏掉输出annotation的门高／误差scalar，未发现主体像素改变。旧失败完整保留。NEW只读残余实际自然0／20检查0（98D86A0F），完整两annotation按冻结合同重建，原全部来源SHA/bytes/mtime_ns同，继承41像素组件，0 PNG解码、不重复处理或量图。此不把原whole FAIL改成PASS。

三PNG与相应meta／ART／处理／两QA收据已逐字节复制到新 `game/build/luoyang_estate_courtyard_20261021ak_system01/{candidate_art,receipts}/`，仅供res://候选ImageTexture组装，不进game/art、不授正式导入。新作者、几何和实际图待后补。

## 新候选几何与真实组装图

作者READY `C21097071D8A13EE9E427309A9203FE74AE28250EB36D067C2A101E08185DE55`，仅候选formal_enabled=false。主厅完整世界宽759.99、厢519.99、廊620.01；保守净门／廊口约127.85／125.75／126.99。宽度按完整A1换算、不用透明画布宽。主厅脚1536,520，两厢脚700,860与2222,860，两廊脚680,1180与2392,1180。NW／NE两树迁至390,1510与2740,1780；原主厅入口从院门前1536,1144移到真正主厅门前1536,544，仍未接正式路由或室内返回。

首次check-only自然1：静态GDScript类A不能读取resource_path；原publisher全文E081D051精备在failed_sources，实际日志保留。仅改显式helper路径后publisher475DF919、helperF618E217，NEW check-only自然0。唯一实际几何110824自然OS0／1319ms，报告 `248273FCA90108ED14655C5DD9BAEE9CDD4FD66D1174C2951580CDE725834B9D`：62visual=57+5，20矩形=6（移两树）+14新；原三路661点继承，新四路2710点完整875+17通过，旧dry_garden_loop明确替换而非冒原四路全同。native／packet完整逆、读回与44源首末通过。5次Image读取WARNING，非clean；不是实际Field Physics。

native新三文件位于 `ak_system01/native_candidate/`，walk仅build候选未导入。QA实际收据薄审 `1E6A3309D76C49470BAF3408F9F87FE93222410812CC729A2CEFCCD57D4DF895` 核44源与全部新产物当前SHA同，不重复几何／像素／引擎。

唯一GPU预览：console进程8984自然退出0，实际渲染报告PID115536／1847ms／62个Sprite、1536×1024全场统一0.5比例；不补造独立render子进程OS码。报告 `622BE942FE2B8D63C0AC56FD447440051BF194363100CF0D5CA4CC633F787ECC`；图片 `3BD94C08F6F0617CD687919E1CCB6FED98CCD0CC90F00FCE89D4320B07EC3DE0`：

`game/build/luoyang_estate_courtyard_20261021ak_system01/preview/115536/estate_architecture_actual_sprites.png`

Root／ART实看无建筑叠穿、比例与主次骨架可继续，但整体仍NOTREADY：主厅门洞透草、厢房和回廊孤立，北院无铺装、前庭T形硬边、树少。下一优先院内地面、短墙衔接、门内暗部、低花坛／院墙收边，不继续挤楼；这些后继可复用本次几何，不能再复跑2710／旧2226作新功。7次旧型退出Texture／RenderingServer ERROR保留，0 SCRIPT，不称clean。没有正式Field、NPC／头像语音、门往返或加载指标信用。

## 最终保护与交付边界

本轮fresh before `4254A4AD08A10AF279F2C078EAC5F83DFA7340681A3AC8317479DA4B0A6B7616`，final `41CA8E9A3299B96A4E6FF7DDA833B0C234DCCFB15C8F29F755AA382B09861A95` 自然0：2094固定保护路径全SHA／bytes／exactticks同，包括15存档和tasks。NEW派生／候选／实际收据另行登记，不冒整个workspace零变。自己检查进程已自然退出；用户编辑器51856、Ollama API100140保留。正式地图仍ae，完整洛阳各区未完成；本次交付为三素材背景处理和有真实渲染证据的宅园建筑骨架。
