# 2026-11-01 岸驿曲径比例、视角与路草过渡返工

状态：本轮局部返工已正式接入，交试玩；不代表全部野外场景美术完成。

## Change

- 用户截图指向`adventure_luoyang_riverside_route`及其World5600/3300地标。旧棚地标210px画布宽、斜屋顶比例过小；场内深褐路带规整、路肩与草地突兀。
- 新驿棚以林西村屋舍作材质/相机参考，内置imagegen生成1次近正面灰瓦木棚，未使用CLI/API fallback。模型未由工具结果公开，登记为unknown，不猜测。Prompt `prompts/riverside_visual_20261101a/shelter_v1.txt`（4C4242CA）；原图`assets/raw/riverside_visual_20261101a/shelter_v1.png`（8BC58E32）原字节保留。
- 用户既有许可下，仅清46196个保护框外alpha=1点，原全RGB与保护框RGBA精同，并加128px透明留白；无裁切、拉伸或重采样。运行图1792×1280 `game/art/modules/riverside_visual_20261101a/shelter_v1.png`（3DA5C59F），来源与处理证明见source01/asset_ACTUAL.json、asset_registration.json。
- World仅岸驿一行替图，画布宽210→720，完整可见棚约555px宽，按原生基础锚点落地，近正面屋檐不再斜压；新基础完整实体仍在原门前通行域北侧，不改5600/3300门或其他两冒险门。
- 场内仅本ID安装`natural_ground.gd/shader`：复用林西现用的草土/碎石原纹理，按原16段中心线计算单worldUV距离并集、非等宽路肩、材质扰动软过渡；隐藏旧Line2D绘制但保留数据。岔口不再叠暗或出纹理环，mini复用同一地表helper。其他两冒险图仍走原绘制。
- 正式旧文件仅WorldLinks、AdventureRuntime、AdventureMini3个。原岸驿Scene/layout、NAV、12地面Atlas、全部blocker/portals/调查点/锁/奖励不变；无Router/Field/World16/EX/Region/sharedguard变更。World16的source_graph是历史作者溯源，非runtime绑定，不擅改它。

## 实际检查

- 新脚本headless check-only返回0。单张PNG在独立无autoload小工程导入，只新增一份.import与.ctex，未整工程导入。
- 首导入叶复制因PowerShell数组加法优先级错误未成功，Root过早启动trip01：console72748/实际62016自然1，缺PNGloader导致地标拒；原日志与FAIL保留。仅修导入叶推广后才启动02，未改断言或覆盖01。
- trip02 console131312/实际11800保留进程WaitForExit自然0，16427ms，18检查/0错/6输入；原World16真Space进岸驿，验证完整新地标、主画面与mini同材质及隐藏旧路，步行到原返回门并真Space精返5600/3300，业务状态保持。2张正常图Root亲看；原纹理退出ERROR/ObjectDB警告仍保留，不称clean全日志。
- 最终有限保护`source01/final_guard_ACTUAL.json` SHA `6b0885f657183fc947a776dc70ef047d37c0c7cca5178abbe3b5617617273c74`：3授权变化/38冻结源/171fresh存档路径metadata（9缺席）/6新证明/0差异。前次保护后的2个用户更新存档按新现值保留，不回滚、不反序列化或回写。旧3236来源仅继承历史事实，未为本局部任务重哈全库。
- 用户运行游戏PID95272由用户自行退出，编辑器51856始终保留。停止成功路线复验，交用户实际验收。

## 仍有边界

此处只改截图中岸驿World地标和场内地面视觉；场内旧废棚、其余野外及整张World建筑并未全部重做。本轮不增加新剧情、NPC、奖励、收费或地理版本，也不冒真实存档读盘恢复已测。
