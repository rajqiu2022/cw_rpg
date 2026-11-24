# 2026-10-31f 三处野外冒险接入江湖大地图

目标：给已有竹尾猎径、襄州深矿、古寺外岸驿曲径增加直接可见的大地图入口、M地图位置和小地图标记，保留原场景G支路及普通F采集，不制作新战斗/配方/奖励。

状态：已正式合入，三处大地图真实进返及原矿谷G入口兼容检查通过，可重新运行游戏试玩。

## 范围

采用现有AdventureRuntime的独立子模块追加，不改World原Scene/map_layout/NAV/道路/城镇门户、Router、EX、project或城门来源清单。三张冒险Scene与点表原样；完整现货地标复用，不新生成/处理PNG。

World进入时记录固定地点身份及真实门前脚，返回同一World来源；从旧G支路进入则仍返回原场景。来源只允许固定三行与v15 World别名，不接受任意目标和坐标。竹尾入口沿原zhuwei_village_inquiry_done锁，矿谷/古寺上游无同类入口flag，不新增剧情门槛。

唯一旧源AdventureRuntime的两处挂钩后SHA89250713；独立helper91D9F23B/mini8B6B45E3。三个声明门脚为猎径6900,4700、深矿5200,6000、曲径5600,3300，对应竹尾村东侧、襄州城东侧、洛阳东南外围。完整林门/矿洞/旧棚各复用，另两丛竹，八处原图UV接地部分的物理轮廓在入口北侧，不以透明画布当巨墙。M标签避让原城市标签，来自冒险的角色标记映射实际World来源脚；只增加标记，不增加地图点击传送。

代码审查发现pending在失败/菜单后可能误擦后来来源，已改为源实例/固定目标/请求代次/60秒边界及精确origin快照匹配，异常仅取消pending，不盲清后来的合法来源。审查为有限源码结论，不当作实际往返通过。

## 实际检查与保留历史

首脚位采样脚本错误访问静态GDScript的resource_path，未到实际检查即解析失败，原01和日志保留；02仅换精确路径常量后自然0，三个原门中心全部通过原World safe_foot及34×24完整代理脚NAV像素/实体交集，0替代点。该项只是来源代理，不冒真实角色Physics/streaming通过。

0Field解析探针自然0，模块与现场脚本可实例化。首现场121152的森林锁拒、真实门进入、可信origin/返门绑定及正常World地标/三mini标记前缀已通过；整体101检查/1失败保留。QA主脚本静态引用WorldMapPanel导致其在SceneRouter autoload注册前编译并缓存失败，M场景nil；不能抹成原退出错误。新02只去QA早期静态class引用，不改生产UI，锁拒/World图不复测；为剩余返程与M重新真实进入森林属于必要前置，不伪造正例origin。

02/47880正常M已显示三新标签与实际World来源角色位置，Root亲看图A6FA8B13；真S走至2048,2852.8（目标2856.96，4.16px容差），但QA随后错误调用原outskirts_exit_zone不存在的can_enter，协程退出，90秒watchdog自然结束，整体102/1。八输入只是进门、M、Esc和S各一按一放；没有执行返程Space，不可据此称生产返程失败。原SCRIPT ERROR与超时保留。03只修两个返回箭头oracle为真实_can_enter+overlaps_body，不改生产，不复M/锁/截图。

唯一残余03/132536自然0，125检查0失败、24输入：三个原World安全门脚真实Space分别进入猎径/深矿/曲径，冒险里真实南走到原返回箭头，真实Space精返6900,4700／5200,6000／5600,3300，HP/MP/金钱/Player/队伍及无关flags保持。旧矿谷1000,1500公开近场后真G进入深矿，来源保持local、原返门未被World记录劫持，真Space精返旧矿谷1000,1500；旧矿谷无额外步行，不触新随机战。隔离QA内存只为森林正例临时设原解锁flag，结束恢复原flags，不触真实档。

两正常图分别位于`game/build/adventure_world_20261031f_qa01/three_doors_actual/121152/`和`three_doors02_actual/47880/`，Root均已看。03退出仍有原7纹理/RenderingServer ERROR及ObjectDB warning，非clean；首两现场额外失败不能并称旧七错误。现场是各入口公开近场设置，不冒从城市连续长途步行、全野外ART或读盘存档恢复实测。源码支持固定origin记录沿现有flags保存，未用SaveManager读写真实档验证。

## 验收边界

仅三处新入口实际进入/原脚返回、M与mini可见、原G返程兼容及非法来源拒绝；继承原采集动作/音效、挑战取消与战斗服务，不重打制作/战斗/全城矩阵。洛阳31e已修城门严格清单保持，新增autoload子模块不扩旧B collector。

## 保护

Root正式改动前fresh基线40868F49：2779源/171save/9absent，两遍SHA/bytes/UTCticks；用户31e之后两save更新保留，不回滚、不解析或写回真实存档。编辑器51856保留，Root唯一引擎。

最终guard27AB92F12F751E0B2CAAFDE6D56E8F72E3F5DCA77FFE96EE64396AA6CC1690FC通过：2779源恰1旧源授权变化、171save精确metadata同、9absent保持、40证据pin同、0其他变化，仅编辑器51856。新两helper按明确SHA列入证据，原runtime两处挂钩移除的全文逆SHA回0C12C332。Router8EA7/EX7725/Region/Gate64A及index1774/采集制作/三原冒险Scene与点表全部不改。停止成功域复验，交用户试玩。
