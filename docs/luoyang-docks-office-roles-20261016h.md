# 码头职业形象与埠务所外观 · 2026-10-16h（已默认正式接入）

## 修改范围

用户截图中的两名端托盘人物并非剧情NPC，而是码头新增静驻人群。旧投影按静驻序号交替选择农夫/小二，导致装卸和记货岗位都选到小二。本轮只针对以下两人换专用形象，不全局替换小二：

| 原身份与脚点 | 新形象 | 保持不变 |
| --- | --- | --- |
| `harbour_life_docks_loading_attendant`，2000,1430 | 空手、灰褐短打、绑腿的成熟装卸工 | 名称、位置、静驻、比例参数、身体、空对话/空action |
| `harbour_life_docks_booking_attendant`，2010,1900 | 青灰长衫、软巾、持薄账册的记货文吏 | 同上 |

南侧建筑 `harbour_cargo_trade_front` 原为复用的通用敞开货铺，现制作封闭灰砖木构办公门脸：左登记窗、右红褐办事门。显示用途为“埠务所”；**本轮不新增可进入门或室内**。它原来没有门户，不能说保留了原可进门。

## 素材与运行摆放

内置 imagegen 恰三次首稿：一栋办公楼、两个岗位人物。没有第四次调用、自动重试、CLI替代、原图抠图或擦alpha。模型、provider与费用未获工具证据，保留null。

原图位于 `assets/raw/luoyang_docks_office_20261016h/`，完整prompt/spec/preflight位于 `prompts/qa/luoyang_docks_office_20261016h/`；manifest指纹8620D38A。所有原字节保留。3项严格10%透明边距、两人物请求1024²而实际1254²的失败均保留，不能称严格sprite表规范通过。两人仅单帧静驻，不是新待机/行走动画。

两角色原图各做一次全画布Pillow12.2.0 LANCZOS缩160×160，不裁切、阈值清理或重绘，原图与运行图不冒同字节。Root独立重算两个全RGBA结果均与入库运行图一致。Field已有码头人群的140px alpha身高校准和真实脚底逻辑；没有改NPCNode/全局人物比例。160像素单帧保持原22.4×28.8身体。

办公楼原图1536×1024不改像素。为避免等比摆放只有约103px的矮门，采用明确X/Y独立运行投影(.488,.68)，原脚1720,1790、原图anchor768,782；手测基底[92,744]至[1444,782]，投影落在旧闭矩形底座范围内；门叶约143.48世界像素。这是运行摆放，不冒原始等比模型符合门比例。局部实图Root与ART认可比例自然，人物/木构材质相容。

## 接线边界

新增 `luoyang_docks_office_roles_20261016h.gd` 与来源author；唯一旧代码修改为Harbour runtime（原7BD8039B精确全文备份）。旧Scene/layout/manifest/NAV、C、Field、NPCNode、Router、LoadingManager、District、Temple及十一室内数据均未改。

原码头完整source/raster/875+17/存储校验仍执行。新worker在同owner内核来源、三图RGBA和新可见基底包含关系；main先完成原出版Scene全storage比较，随后仅克隆layout替换唯一可见条目。27个其它条目、原record、物理、脚点、深度、任务和门保持。新视觉source/sourceSHA/sourceSize同步；旧GPU证明移到明确historical_parent_visual_provenance，不能挂在新图名下。两角色只替换sprite_path，其他8码头/10城门人群不变。

## 已验证

| 验证 | 结果 | 边界 |
| --- | --- | --- |
| 隔离导入107728 wrapper | 自然OS0 | 3新纹理，不动旧imports |
| 导入核84180 | 自然OS0，3行/0失败，完整source-import-directCTEX RGBA、无mip、23参数 | 3Image提醒保留 |
| Root九文件比较 | PNG/import/CTEX全部SHA及长度相同 | 后置copy receipt不伪装前置ticks |
| CPU103104 | 自然OS0，84/0，354ms；33来源/15保存同 | 独立闭矩形包含、全Scene storage、两角色路径/其余行严格同；非Field |
| 局部GPU47000 | 自然OS0，51/0，1612ms；34来源/15保存同；一张1920×1080实图 | 两真实NPCNode、身体22.4×28.8、原生point命中、alpha高约140、脚差小于0.000001px、原world脚与深度；不是正式码头出生 |

局部实图 `game/build/luoyang_docks_office_roles_local_gpu_20261016h/47000_2590/office_roles_local_preview.png`。该图只摆新楼和两人，原地表ROI中的旧船影未用正式水补片/船只投影，不能拿它冒最终码头画面或判水面回归。实际纹理计数增加约24MiB、预算45,965,312字节，低于256MiB局部上限；Root当时free3795MiB超过单独512MiB局部门槛。这**不是**降低重Field/world原4.188GiB门槛。

局部完整stderr为1Image+7退出纹理/RenderingServer ERROR，无SCRIPT/ObjectDB；自然OS0与断言零失败不称clean。CPU为6Image+1ObjectDB，无ERROR/SCRIPT。

## 失败与诊断保留

- 79568自然OS1/8项2FAIL：QA source常量多一个e、65位，未跑纹理。NEW retry1只纠正同一原文件实SHA，原失败保持。
- 37044自然OS1/71项2FAIL：3RGBA和基底包含已过，全storage比较拒。26872诊断自然OS0/38/0，证明 expected Scene的duplicate(true)仍共享外部layout，先写期望污染了后续输入；5个差异仅历史来源字段，原语义/类型/字节全部记录。
- NEW retry2只明确克隆expected外部layout，并加完整原source storage不变断言。生产源码、严格_equal、预算和全部原判据不改。103104通过，不冲销旧FAIL；不重局部GPU。

## 当前状态与待办

### 编辑器退出后的真实入场检查

用户已保存退出编辑器108140与游戏64676；Root实查均gone，free显存6182MiB，超过原4.188GiB门槛。首轮真实Docks26584自然OS1，320检查/2失败/30.078s：普通public请求、实际ready、完整1273来源（含h全部26源）、原record/NAV/出生Physics通过；未改仓库的storage比较中止，后续两人/移动/截图未跑，不能授整轮通过。135源与15保存首末保持；完整stderr47Image、7退出纹理ERROR、0SCRIPT保留。

最窄纯原条目诊断108536自然OS0（不调用C.prepare/Field或解码新纹理）定位唯一差异：`depth_sort_foot_y` 原生0.283203125、出版TRES0.28320313，二者Float32字节均`0000913e`。原严格比较为false，工程既有路径限定的`equal_visual_serialized_value`为true。修复范围仅NEW验收夹具沿用现有序列化域，不改生产、来源、碰撞或预算；保留首轮失败及旧键。

候选helper0AE49505/authorDC8D7AE8、Harbour1E1E5221。修后真实Docks100808自然OS0，382检查/0失败/30.832s；135测试来源和15保存首末保持，实际C完整1273来源含h全部26项。27旧物件、办公楼原生底座/脚点/深度、两实际NPC的160单帧/140alpha/22.4×28.8身体/原点位，以及32px正常输入与Physics、树退出释放均通过。Root/QA已实看B00B96整场图，接受本次两职业与办公门脸的有限基础试玩；仍不授全城艺术或加载性能通过。完整stderr47Image、8退出ERROR、1ObjectDB、0SCRIPT保留，不叫clean。

Root精确备份0AE49505完整候选helper后，只将`FORMAL_ENABLED := false`改为true，正式源码627920A9。没有修改任何其它生产源码或资源。最小无候选开关普通入场检查单独记录于下文；不再重复CPU、局部比例、四城区或旧整组测试。

此前加载复用与十一类室内仍按20261016g独立候选状态，不能借本轮局部图宣称二次进城提速、室内正式接入或全城完成。

### 最终普通入场：通过，可重启试玩

`test_luoyang_docks_office_formal_birth_20261016h.gd`（9668B46F）不带任何h候选开关，从普通public默认null出生；108852自然OS0，327检查/0失败/30.856s。137测试来源/15保存首末同；实际C1273来源含h完整26项、Loading已隐藏、玩家可移动且原34×24出生Physics安全、新办公楼Texture与两唯一职业Sprite、原生Field退出与释放均通过。几何、27旧条目及两角色细节复用100808成功证据，不再整组复跑。

Root和独立QA已亲看普通原camera截图：`game/build/luoyang_docks_office_formal_birth_20261016h/108852_2647/ordinary_default_docks_office_roles.png`（9A36C018）；结果SHA9DB3A8C3。完整stderr47Image/7退出纹理ERROR/1ObjectDB/0SCRIPT，非clean。30.856s为整份验收脚本耗时，不是暖加载数据或提速承诺。

恢复前后502个既有限域事实含15保存的SHA、长度、精确stringticks均无变化；新helper0AE4→627920唯一bool修改有完整备份。全部Root测试进程已退出，未重新打开用户编辑器或游戏。本次可直接重启普通工程测试，埠务楼仍为封闭外观，没有新增可进入室内。加载复用和十一类组装室内另按g验收，不属于本h通过范围。
