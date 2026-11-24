# 中心—东岸材质与接触光影 v10 · 2026-10-01

状态：3072×1024两区开发候选，正式v12／v13 staging未切换。仅改善v9地表材质与接地，不扩大地图、不新增入口，也不代表全场景层级根治。

## 实施范围

- 新增v10渲染器、独立资源合同、隔离运行入口和专项测试；v9地理、高度、拓扑、道路、天然陆地、导航、入口、物理阻挡、13物件位置及五栏柱alpha／底沿全部冻结。
- 使用已登记Poly Haven CC0草地／石土道路工作图，调整扫描尺度与两相位中细节；保留细节、抑制低频航拍旋纹。前庭改不规则磨损石土，耕地边缘扰动，不回退规则灰方格。
- 13物件与城墙／陆侧候船亭共15处接触材质，以物理脚底为源生成破碎裸土与窄暗核。唯一批准的物件字段变化为删除13个旧`ground_shadow_size_px`，避免旧宽椭圆与新接触阴影叠加；不是修改碰撞或排序。
- 新视觉接触缓存独立于继承的高度接触缓存，避免仅调阴影却改变高度／导航。真实重渲land／walk，逐像素与v9比较成功后才保存；不复制旧蒙版掩盖渲染变化。
- `contact.png`及两区裁切由同一正交相机、网格和实际接触Shader输出。可见材质与诊断共享`entity_contact`，天然水域discard、桥／两片甲板support=0；不是额外手画黑白PNG。
- 拓扑／路线和六片运行前景、合并审计图保持v9字节，只复制到v10前缀。修正新版`route_points()`必须读取v10自己的路线文件，而非继续借读v9；物理路线数据保持完全相同。
- 继续使用现有自生成城池／桥／渡口／灌木和程序岩面；这些不因与CC0混用而获得CC0身份。本轮无联网下载、生图或新增生成费用。

## 迭代与验收

仅首轮渲染＋一次定向材质返工。首轮独立headless **1582项0失败**、GPU **1602项0失败**，十张1920×1080实机图。原规则网格和宽圆影去除，但前庭近似土路、窄暗核正常镜头不明显；因此第二轮仅加强石土分离和小范围暗核可读性，不改地理／物件，也不反复调草地凑版本。

首轮接触诊断全像素检查：天然陆地116872个非零像素，天然水域0、桥／甲板0。这个数量证明作用域，不证明接地美术通过。

第二轮／最终独立QA仍为 **headless1582项0失败、GPU1602项0失败，均exit0**；主控独立复跑headless1582项0失败，三个新增dev脚本分别check-only通过，第二次严格资源导入exit0。接触诊断仍为陆地116872／水0／桥与甲板0；土压痕范围不扩大，AO收敛于原半径1.08内。旧v9只headless复跑1437项0失败，不重拍覆盖旧GPU对照。

主控查看最终城池／渡口／中柱前方图，独立QA和审查重新核对全部十图。灰石前庭与棕土官道已可辨，暗核更清楚、旧大圆影未回归；但前庭仍有程序石缝及矩形范围感，低对比软地表、锐利建筑／浅石贴片、重复灌木和孤立城池仍不协调，**整体视觉FAIL**。固定侧边鞋与中柱前方未见v9两个P2回归；两个到达落点在公共路面。

停止第三次材质微调，不批准正式晋级。下一步应先在小样段补真实地貌体积、植被群落差异与物件边缘／统一光照衔接，再评估扩区；不是继续加噪声或铺同质两区凑九区。

## 冻结证据和验证边界

- 实际重渲land SHA：`EA9F2128752600DD7AB85B6F4896BF4894563481A6C3D364B1535C640FE83C87`；walk SHA：`53750265FD7E7021A3EFB9C2C2C72A63272F9C15082BE48C9FC63E7670911E22`。需与v9全像素及文件SHA同时相等。
- 主控保存实施前26文件SHA基线，含v9三脚本／测试／19原帧及派生文件、正式world_map_jianghu.tres、v13 staging与project.godot；最终对比26份均未改变。新版visual像素与SHA实际不同于v9，运行背景／导航／route确实读v10，不是旧图换名字。
- v9既有主路866个≤4px完整脚底、码头52（21水上结构支撑）、曲河5120见证、13完整物理底面、12陡坡／三平缓地、两入口真实输入往返、存档／flags／Router隔离合同全部保留。
- 五栏柱独立底沿、272合法甲板中心×17脚底点、32精确原图实体见证、真实地板负例及中柱677／686／689当前角色格alpha交集继续验证；不把纯排序数值当实际遮挡证据。
- 桥前后截图没有真实前栏alpha相交，不能作为局部遮腿视觉正例。共享Field8px深度带的近邻限制未修改，九区／16入口与全库49待核对候选未完成。
- GPU／生成退出已有Texture RID、RenderingServer和ObjectDB清理告警仍需如实记录。严格导入成功不等于日志无告警；Dummy音频没有听感验收，没有重新导出Web／微信。

## 复现和图片

工程根目录，Godot4.6.2 console参数：

```text
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/build_world_map_native_pair_ortho_v10.gd
--headless --path game --editor --import --quit
--headless --path game --audio-driver Dummy --script res://tests/test_world_native_pair_landmark_v10.gd
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://tests/test_world_native_pair_landmark_v10.gd
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/run_world_native_pair_landmark_v10.gd
```

实机：`game/build/world_native_pair_landmark_v10_{city,bridge,bridge_front,bridge_back,ferry,dock,dock_side,dock_middle_front,city_arrival,ferry_arrival}.png`。

同源诊断：`game/build/world_native_pair_ortho_v10_{contact,center_contact,coast_contact}.png`。外部来源继续遵守`docs/licensed-world-assets-polyhaven-20260929.md`。
