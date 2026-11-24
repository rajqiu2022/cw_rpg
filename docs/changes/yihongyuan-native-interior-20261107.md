# 怡红院接待厅与雅座原生内景 · 2026-11-07

原南市怡红院入口 `enter_yihongyuan27n` 指向正式房间 `yihongyuan27n_interior`。新版以红金木作、牡丹壁画、帷幔暖灯和乐席区别于普通客栈；保留原六位角色的身份和业务、原门、出生脚点、返回街口及三处未启用的剧情锚点。未开放楼上。

新增琵琶乐师、清曲歌者、侍茶姑娘和迎客姑娘。四位均为成年环境 NPC，各使用 4 帧原生高清固定朝向待机，未增加对白、肖像或配音。两个旧坐客仍用固定坐姿。新壳与四张精灵图均保留原始像素，导入后逐张核对基础 RGBA；原图、提示词、帧锚及导入凭证见[美术记录](../../game/build/interior_identity_20261106_art01/HANDOFF.md)。

正式地图包仅替换这一室；其余九个区域包绑定不变。首轮实测 63892 暴露南市旧地面助手固定了过时的 RegionField SHA；后继仅同步这项 SHA 及地面助手对应的校验值，未改地面或取消检查。64804 实际从原门进入，取到[正常镜头](../../game/build/interior_identity_20261106_system01/formal_actual/64804/yihongyuan_live_normal.png)，四位新角色各显示四帧，两位旧坐客保持稳定，堂中伙计原对白能打开；该轮对话收尾断言未通过，结果保留，不作为真实返程证据。

60764 只复验剩余路线，16 项检查、91 个输入 tick、0 失败，自然退出码 0。原门进入后主角先开口并显示自己的立绘，伙计答完可继续走动；同室前后业务无差。实际从原门退出回南市 `(5206.18, 4280)`；测试脚点迁移使用虚构数据，未读取真实存档。洛阳城门实际来源集合与接入清单 1758/1758 精确相同，这不是从世界地图步行进城的测试。真实存档只检查 15 条存在性/长度/时间戳元数据，0 变化；无真实档内容读写。编辑器保留。原 WASAPI 和退出清理警告见[进程日志](../../game/build/loading_20261106_system02/run_interior_yihong_formal03/stderr.log)，不记为全程无告警。

[正式结果](../../game/build/interior_identity_20261106_system01/formal_actual/60764/result.json) · [部署凭证](../../game/build/loading_20261106_system03/yihong_composite_DEPLOY01/after.json) · [地面守卫同步](../../game/build/loading_20261106_system03/yihong_ground_guard_REVIEW01/installed.json)

高档洛阳客栈与普通清风客栈仍为候选，未改动正式客栈、服务、收费或任务。这一室接线也不代表全部 NPC 高清重制、整城美术验收或进一步冷加载提速。
