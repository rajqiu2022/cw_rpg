# v14 主控逐图验收与正式切换授权

本文件由实际主控 `/root` 记录，依据用户“直接全部改造完接入正式地图”的授权。范围为 4608×3072 连续九区大地图及 16 个既有目的地，不代表 91 张地方场景全部重做或原 49 个旧遮挡候选全部清零。

## 当前候选结论

主控视觉结论：PASS，允许机械证据打包、独立审批门禁以及正式 `world_map_jianghu` 切换。技术结果本身没有被当作视觉批准。

- 固定完整测试 068DC74F3C5025056B14B5CDDCCF8693FC94F739537E7AC165A351FD5528E55C，连续域 helper B6DE881A4600A3CFD3411521B0EB0ED32813B5E92C6073E8C989E159157D2989。main/ninth builder 76E4A8FFBD326260EB3B0B4125B426B6BB92DAF63677236ED3338DE6DDDE3654，material helper 01D231CA4FF6CCC8D93A8D0D3FCDE8CE6B03E12943F87E5F23D9CBA7A9D39C62。
- 两次完整程序均由主控实际取得 OS exit 0：`candidate_headless_1790950478/result.json` 106159 检查／0失败；`candidate_gpu_1790952075/result.json` 107953 检查／0失败／592 原始PNG。16 入口真实输入往返、12 接缝输入、16168 完整脚底中心；玩家六份存档未变。
- 主控实际读取所有 592 当前原始截图的联系页：batch1 的第1～15页（173图），batch2 第1～25页（289图），排除已审SHA后的 batch3 第1～13页（153图）；重复图去重后覆盖整个当前GPU目录，不把联系页当作额外原始截图。三个index依次为 `root_visual_partial_1790952075_batch1/index.json`、`root_visual_partial_1790952075_batch2/index.json`、`root_visual_complete_1790952075_batch3/index.json`，均位于 `game/build/world_map_v14_qa/`。
- 另按原分辨率实读九张 region 图、汴州地标前方、original_grove_21 前后、ghost_transparent_rectangle、mature_canopy_performance_station 和 overview_M。地形、水岸、桥面/护栏、城市抵达、独立物件前后、植被、透明矩形负例及M概览没有新增阻断；审查对象明确绑定 index 所载原PNG SHA。
- 普通NPC不是区域截图中的虚构覆盖：主控全文读完整GPU的 `normal_patrol_same_band.json` 72条自然过程记录（前22／后38，四动画格，净空及排序均真），另全文读独立 `supplemental_normal_npc_gpu_2257343/supplemental_normal_npc_cases.json` 及正反当帧JSON，并实读两张原始1920×1080 PNG。自然巡逻两侧当前alpha分别481／477命中、真实脚线同band，矩形物理支撑不相交、完整17脚底通过；同脚线静止NPC保持稳定顺序。该附件程序 EA49D6DBBC4CB369F767FD8A3C8166049A5C0EA9CEE4F2A70B36958491206D55 实际 exit0、5235／0、2图，scope仅 SUPPLEMENTAL_NORMAL_NPC_VISUAL，不是第二个完整验收。
- 独立review逐份复核73个alpha文件和原始完成行、冻结源码及全部玩家存档；四向当前idle frame0连续域无未决，原阈值与预算未提高。这不外推所有武器/动作动画的逐像素连续域覆盖。

## 保留的限制，不隐去

- 实测240帧站位：空地/近城p95约17.2ms，密冠站位p95约31.22ms，不能宣称所有区域60fps。此次没有以改性能阈值获得通过。
- 完整程序退出保留7个SceneTreeTimer ObjectDB警告，headless另有2个refcount0 RefCounted诊断；没有SCRIPT、SHADER、资源ERROR。原始日志和所有旧失败候选保留。独立NPC附件只有原PNG oracle的开发测试导出提示。
- 地表视觉保留较开阔的旅行地图尺度，不宣称AAA品质；后续视觉填充仍必须使用独立物件和同源导航，不能回到整图烘焙建筑。
- 当前授权仅Godot工程接入，未承诺Web／微信重导、提交推送或修改用户正在运行的编辑器。切换后须由新进程读取正式资源再完成真实回归，未切换前不得报告已接入。

本文件授权与逐图证据一旦用于审批即冻结SHA；后续切换与回归结果写其他进展文档，不能反写这份批准依据。
