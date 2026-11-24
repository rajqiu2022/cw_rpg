# 赤岩试玩主角与默认镜头修正 · 2026-10-28c

用户发现开场显示制作全景，随后指出受控角色并非主角。原28b受控节点确为匿名巡检兵，本次同一28b场景改为实例化正式`res://scenes/player.tscn`，使用原Player脚本、冷孤云v7剑形态四方向待机4帧/行走8帧及原视觉比例0.945。本地子类只关闭原自主移动循环并暴露动画驱动；城镇控制器继续负责原330/600移动、35×25脚体与进出厅重父，不改共享Player代码。门口匿名兵仍为独立NPC。

默认`view_mode=1`人物跟随；Tab保留全景检查。脚锚使用原Player的`set_ground_anchored`，碰撞与布局不变。状态文案明确主角动画已接、NPC仍为待机。正式世界、存档、任务与收费服务尚未接入。

写域：28b专用Scene/控制脚本、新`preview_player.gd`、隔离staging副本及文档。共享Player、人物PNG、原导入叶只读；不全工程import，不停止用户编辑器或试玩进程。

先镜头窄headless检查通过；主角更换后唯一GPU进程23756自然退出0、stderr空：确认原Player能力/正式八条动画路径、四向帧推进、比例脚锚、原35×25碰撞、门兵保持、Tab往返、进出厅同对象/原脚返回。调用动画接口验证，未冒真实键盘输入或重测旧79路线矩阵。原生画面已查看：[主角跟随](../../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/real-player-follow.png)。

证据：[结果](../../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/verification-real-player.json)、[来源变化](../../assets/staging/redrock_luoyang_standard_20261028b/player-camera-delta-20261028c.json)。28b原发布清单与79检查报告保留历史，不改写成当前后继SHA。

使用：正在运行的旧实例需停止后重新F6；默认角色已为冷孤云并跟随镜头。外峡壁/民巷密度、其他内景、NPC行走及正式世界入口仍待。
