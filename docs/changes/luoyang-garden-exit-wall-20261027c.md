# 2026-10-27 园林孤墙与返回宅园出口

状态：两项正式合入01656F8C，唯一真实出园检查通过，交用户试玩。父版本CE38EF86；不扩大为全城艺术或加载目标验收。

本次只撤园林`seven26c_garden_west_dry_outer_edge`孤墙及其一条真实基线，保留花坛自带边界、道路、原河桥及其它物件。遮罩仅恢复该基线所属像素，保留其它碰撞优先，完整域外RGBA逆不变。

出口两端原落脚可行，静态定位为Garden→Estate虽由AP路由管理，却未启动Estate原校验，且原AP结束分支跳过Estate结束校验。Router仅这条精确路线补原Estate begin/finish，不扩owns_route、不伪造回执、不放松来源校验。门位和目的地不改。

验收仅一次真正Space从园林进入自然冷Estate，检查两原Family FIRST/FINAL、原落脚及短移动；最多两张原相机图，不重旧整城矩阵。15存档使用本次新鲜基线，编辑器51856保留。

## 实施与结果

单园林局部出版109852自然0/23检查0：退NAV[60]/visual_additions[4]/solid[20]，得到66NAV/26solid。只恢复墙基所属2205像素，完整typed payload/RGBA逆通过；花坛、原道路、河桥、NPC、门位不变。单遮罩隔离导入自然0，28676验证165检查0/881ms，整RGBA/23参数一致，只2个新导入叶晋升37019EB8。

Router只有精Garden→Estate且原AP管理的路线补Estate原begin及独立finish；其它owns_route、safe_body及原AP校验保留。Stage02为956F16B0、3694来源首末同，18GD apply_patch与14JSON精copy，旧270证明全保+7=277/10owned，32份本轮全文备/总737；候选均单末LF，Router原13个CRLF仅格式精恢复。Stage01静审发现两个期待集合漏Router，在运行前以Stage02修正，候选不重封；未产生失败实际Stage。

唯一实机100436（launcher70980）自然退出0，128检查0、14.256秒，1次真Space、2张原相机图、0运行位置/相机写。Estate自然serial0未重设；园林入图7.235671秒、真正出园到冷宅园6.045914秒，原落脚2944,1840正确，随后32px左移/5Physics通过。AP serial1→2与Estate0→1两原FIRST/FINAL精源一致；Root已亲看两图，孤墙消失、宅园落地可走。不将此局部near入图时间宣传为默认入城或全城10秒目标。

实际结果：`game/build/luoyang_garden_estate_exit_20261027c_system01/EXIT_ROOT_READY01/output/100436/result.json`，SHA4F349F35；进程收据8E314052。既有退出Texture/RenderingServer错误保留，非全stderr clean。停止本批引擎复测，用户可直接重运行游戏，编辑器不用关闭。

最终保护3CC4D733中2121当前源/32目标、737备份、15存档SHA/bytes/精确ticks、206旧媒体、新Garden三媒体、UI/G/当铺运行时均零差；唯一失败是工具把当铺作者文件固定长度误写19525，实际SHA44053DA4与历史声明完全相同、原长度80026。单fact残余DCD0A7B5引用原A262固定证明修正期待并通过，原FAIL保留，不重跑全部保护、不改生产。最终只有原编辑器51856运行，自有游戏自然退出。
