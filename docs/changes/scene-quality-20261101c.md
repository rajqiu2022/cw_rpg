# 2026-11-01c 洛阳城门残余孤墙与巡城军士步态（本域有限通过）

状态：本域有限修复已正式收口交试玩，停止复验。残余57604自然0、7770检查0错/14Input事件、三正常图Root亲看；最终guard `26df2620…` PASS。首102424/66检查1错和World16真Space+C/B1727成功前缀均保留。只授这两残余墙与本批步态节奏改善，不授完美footlock或全城ART；不改写11-01b范围，不把29m旧两墙判为复发。

## 本次用户反馈与证据

- 洛阳城门街段手推车旁仍有一段孤立矮墙，未构成可理解的院界。此为本次独立残余对象，**不是**29m撤掉的原两条`finish_i_gate_queue_low_edge_west/east`自动复发。
- 巡城军士步子跨得大，但实际前进慢，形成滑步/原地迈大步的观感。该时间变化来自用户反馈；单张图只能证明大跨步姿态和当前空间关系，不能测出真实位移、帧周期或速度原因。

[用户原始截图](../assets/scene-quality/20261101c/user-gate-wall-patrol-rejected.png)已按原文件字节复制，未缩放、清理或重编码：4216158 bytes，SHA256 `cd9f67e474ba009026e14a08cb2c082a603c452152b01551efc62812d67fae88`。来源 `C:/Users/rajqiu/AppData/Local/Temp/codex-clipboard-bf6ee240-dcd6-408b-9e24-07d06d402e08.png`，源/归档副本SHA256和bytes相同，原附件保持。

现役Gate为`ch4_s0_luoyang_gate`，本轮墙owner为`seven26c_gate_west_waiting_front`与`seven26c_gate_east_transfer_front`；巡城目标为`harbour_life_gate_patrol_west/east`，同行观察商人为`harbour_life_gate_waiting_merchant_b`。[缺陷册](../scene-art-defect-register.md)的GATE-01与PATROL-01仅按本批这两墙/三actor的实际范围收口，不扩大到全部墙或全NPC。

## 与历史范围分开

[29m历史记录](luoyang-gate-isolated-low-walls-20261029m.md)只撤原两条膝高墙及其对应solid/NAV，保真实围合院墙；原局部功能/正常图信用继续保留。新孤墙须按自己的owner和图/基座/实体/NAV来源定位，不以旧两墙不存在回答当前投诉，也不按“附近有墙”批量删除真实院界。

11-01b的坐客固定朝向、三片区材质/边接口有限改善不涉及本次巡城步态或城门新孤墙，不能沿旧112/0、89/0或图库登记宣布本次问题已修。

## 最小关闭条件：沿S04/S05，不跑全城矩阵

依据：[S04围合门路 / S05人物姿态方向](../scene-art-quality-standard.md)。先列真实同因消费者，区分同素材、同播放配置和仅同名NPC，样板未过不扩铺修法。

| 缺陷 | 功能最小证据 | ART最小证据 | 不可冒充关闭 |
| --- | --- | --- | --- |
| GATE-01 手推车旁残余孤墙 | 精确owner的图/自带基座/实体/NAV处理一致；一段受影响地面完整脚体短走，原车/亭/门/真实院界及邻近NPC路线不误删、不留幽灵阻挡。旧29m两owner保持既有退役状态，不复其已过路线 | 现役正常镜头同位置前后图，墙段不再像孤立装饰，移除/衔接后的地面与周边用途成立。不能只hide墙图留基座/实体，不能挪镜头把墙裁掉 | 找到旧两墙不存在、源码PASS、只清一个矩形NAV、重跑全World入口/全城后报已修 |
| PATROL-01 巡城军士时空速度脱节 | 核实际源帧顺序、方向/flip、周期与同时间段世界脚点位移；取一段稳定巡行和一次自然折返/停步，未改原路线、身体/交互和业务，换向不漂脚/不穿物。只处理确认受影响actor/同因消费者 | 正常镜头连续观察至少一完整步态周期：落脚—收腿/交叉—换脚与前进节奏相称，方向和脚锚可信；减速/停步不能继续大跨步快摆。记录采用的帧语义/节奏选择，由实际动态画面判断，不只比较参数大小 | 单图、大跨步帧彼此RGBA不同、文件叫walk/right、统一加大巡逻速度或只调慢帧率、传送脚点伪造位移 |

不设置通用“每秒多少像素/每秒几帧”美术门槛；先按本角色实际体量、可见步幅、帧接触相位与巡逻语义校准。支撑脚的屏幕运动、世界位移和周期必须来自同一次观察，避免把相机滚动当NPC移动或拿不同运行拼速度。原资源若缺收腿相位须明确缺口，不能以加速掩盖坏步态。

## 实施与保留失败

1. Root审31项墙闭包后继及project唯一NPCGaitRuntime hook，17GD仅SHA/BIND path替换，14JSON仅必要source maps；EX只原3owner各追加一精逆边，Router owned整行/OWNED keyset保，原RegionField/RegionManifest/10bin与11b独立域不扩改。实际移除图/solid/NAV各精2：新payload23检查0错、7938专属像素、整typed payload与整RGBA双逆成立，原美术PNG不改、不新生图；精确发布[71200结果](../../game/build/luoyang_gate_front_walls_20261101c_system01/output/71200/result.json)不冒Field接受。
2. 原联合现场[102424结果](../../game/build/npc_gait_20261101c_joint02/actual/102424/result.json) SHA `a18ce8c6e3f34299f6f6e903ebd8ac4a0c85c1eab5fee96f430b1667240c94b9`，`checks=66`、唯一error为西墙完整脚越过断言；不是66PASS。x600碰仍应保留的第55号gallery柱，后继只改QA起脚到原墙跨度内x650，不搬柱/放宽物理。原报告和用户拒图保留；World16真Space与实际C/B1727成功前缀在残余不重跑。
3. 若修复触及实体/来源，按真实依赖做有限保护和必要短路；不因新投诉重跑旧29m撤墙、11-01b坐客/门、全城旅行或其他成功矩阵。
4. 联合实机stderr另暴露native_sources原228键的MainField旧pin155172，与已批准正式1fc80不符。Root先执行精2补充采样 `a924ef82a5cb95f2d2892682775c3384122d6f04ea7454fcf2610cbcf887647d`，只给native/registry全文精ticks备份且与原183 before相同，不重写原capture/strict。Root审两literal整逆后合入native A980E7AC、registry 52F2F424：228键和另227值、registry完整guard/后续函数保持，不扩C/B/EX等新变化。残余此新来源错误消失。
5. prepare_mask的type参数parsed-case首失败、NAVimport01空工程/closure01缺sidecar失败保留；修publicationData后NAVimport02 console111064自然0，closure31成立。Root独立纯解析134984/console7592自然0、21检查0，ObjectDB历史warning保；不把这些出版/解析成功当Field或动态ART。

## 残余实际结果与有限接受

[57604实际报告](../../game/build/npc_gait_20261101c_residual03/actual/57604/result.json) SHA `9dff54a9061a11ddbded586e5fa324318eaa0e2557e24cbcfd1d34f7705303c3`：7770检查/0错、14Input事件、Root记录自然0。此轮公开Gate近脚setup是残余设置，不冒从World连续再走一遍；`World_and_collector_rerun=false`，原102424全次FAIL仍保留。

- 两墙真实W短腿：西650/2010→650/1938、东2490/2010→2490/1938，完整脚体越原墙带，原六owner实例保留；x600物理query确证撞保留gallery柱而非旧墙。正常图中用户指的东侧矮墙已无，廊架、货物与真实院界保。
- 同一次10.5秒观察每actor 627样本：两军士peak约66px/s、距离周期114.8px，实际路程西433.36/东442.41px，flip变化3/2、帧切换各15次；商人peak44px/s、距离周期106.4px，实际269.42px、flip变化3、帧切换20次。距离相位与实际移动关联，保原中心/半径与业务；这里“15/20”是切换计数，不是15/20张独立walk帧，也不授完美落脚锁定。
- 原军士daily真Space开、主角先说，实际1.3秒冻结并由Space自然结束，业务保持；不以Esc冒新增取消能力，不复制其它NPC对白矩阵。
- Root已亲看三张现役正常图：[东墙短走](../../game/build/npc_gait_20261101c_residual03/actual/57604/east_retired_front_wall_true_W_normal.png)、[两军士巡行](../../game/build/npc_gait_20261101c_residual03/actual/57604/gate_dual_armoured_patrol_normal.png)、[原daily冻结](../../game/build/npc_gait_20261101c_residual03/actual/57604/gate_original_daily_freeze_normal.png)。只接受这批孤墙与步态节奏有限修复，非全部NPC/城市ART或完美footlock。
- stderr新native来源错误消除；旧7条退出ERROR、ObjectDB warning及旧Image读取warning保留，不称empty stderr/clean。

## 保护与停止点

原capture `5d6f11d35c377f1ce2742c339ce0fc4fbc35a22d7883a513501ac6b09fcf1670`为183fresh源/171save metadata；33潜在+project精备不等于全部授权。Root实际批准原31+精2native共33旧after和project一行hook，独立16叶manifest `9101db3750c99a6c9ceb63ebd5f28f22db850d07b5d3c32ba18827630c8bba85`未改；新auth只显式增加必要joint/collector/inputs/residual/原FAIL与补充证据pins。Root最终仅将授权文件false→true，实际授权SHA `106361df2fb3b87597a95184f418e7162319a3e182872210438cc898757eed88`。

Root执行[最终补充guard](../../game/build/luoyang_gate_gait_20261101c_source01/final_guard_ACTUAL.json)实际PASS，SHA `26df2620f9cb1238fab7be85243bfcce9b539c3369bb0ff87187a8fabfa7f806`：183源中33授权恰33实际变化，其余无外差；project独立一行精字节逆成立，171save精metadata同（9缺席）、独立16叶与36份全文before备份保持。原183/strict与原guard未重写，精2补充另存；不是全3236重哈或全workspace审计。无真实存档反序列化/恢复/回写、无图片重画。

仅编辑器51856保留，停止本批成功域复验；0真实存档反序列化/恢复/写回。用户可验两墙与巡行本域效果；其它城门、11b内景/地面、全城旅行、任务/战斗和所有其他NPC不借本次数据获得新验证信用。
