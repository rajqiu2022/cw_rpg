# 南市后勤院檐廊与作业空间整改（2026-10-25g）

状态：已正式合入并通过本轮有限实机，非全南市/全城完成。Stage C972F714→部署7F2A7BE1→末guard6E8DF772；两院建筑围合真正改变，不重复上一批地面材质。

## 已准范围

- 两处后勤院新增真实灰瓦四柱檐廊，完整复用Estate corridor PNG（A335BB05），等比.36，脚位(1720,1372)/(2660,1372)。完整可见包络约[1406,1140..2034,1374]/[2346,1140..2974,1374]，净高128.52、中央柱间111.6≥96。Root明确接受廊内开口比原120院口窄8.4；不能宣称仍120。
- 四个孤立1.3高侧墙改为.65前段，脚x1390/2050/2340/2938,y1372；东末低墙收至2938。檐廊与后仓下沿约25px连接是有意建筑接合，仍必须实图判断，不能用泛化alpha无重叠规则否决合理连体，也不能忽略屋檐互穿。
- 两个大帐棚同ID分别替换为现成布架.12@(1735,1308)、药材工作台.16@(2685,1308)，避免帐棚顶和檐廊双层叠屋顶。净43→45实体，不追加散乱粮袋。

保300主街、北/南横街、144/96服务巷、原六房阈值与返脚、宅园2610/1860入口、NPC位置/巡游与任务互动脚、25f六材料和原12室内、Router/加载算法；只两院局部solid/mask差量。檐廊只柱脚碰撞、按真实alpha与人物局部遮挡工作，不将整片屋顶设禁行，也不淡化整栋建筑。

## 执行与验收

按项目空间设计/环境叙事参考，补出可辨用途的连片作业院。System唯一候选写权；Source继承现役25f四map做最小闭包；QA只验新增/受影响域与一版实图，Root唯一引擎/导入/部署。用code-review核owner取消、来源门禁、碰撞与遮挡、每帧开销。复用原素材，不生成/清理图片、不重旧四native出版、87517全图、旧门/画像/材质55。

Fresh4B8B0FBF确认2121路径/15save精ticks/116全文备/6媒体较25f末零新差，33当前目标正确，仅editor51856，无用户游戏；不要求退出编辑器。原失败与备份全保。

## 独立通行先验实际

Root单次隔离进程33724自然OS0，154检查/0失败/622ms，stderr空。报告`game/build/luoyang_city_revision_20261025g_qa01/prior01_output/33724/prior.json`（SHA4FE0B510）。独立模型不调用System pure/publisher，仅旧geometry一次、旧mask与raw两PNG；两类body/4px局部短路/17边界点、8柱脚拒穿、原1396四个NPC冲突负例均保。四条新起脚1384避开原NPC，不搬NPC。

只147739局部像素域、52354改值，域外RGBA保持且完整逆还原成立；预期新RGBA为EA4BE52C。两处新增1.35中心裕量仅新先验，不冒旧生产body合同。111.6柱间宽保留native f32事实，不声称120。尚无25g出版、实图、正式接线或性能结论。

## 有限出版与审查（进行中）

Root单次publisher04实际115716的237检查/0错误/1793ms，19source首末同；45行投影、geometry、walk、pixel_inverse、finite_proof和小header已产出，局部像素与独立先验一致。原结果A5AEE4BD和自然OS1整体FAIL必须保留：末尾Dictionary.merge未覆盖初始`passed:false`，不是几何未过，也不能篡改原结果补成PASS。只读剩余组件准入另做，不重复几何/路线出版。

Code-review有限范围已核：新45租约独立，先执行不可变D296父43来源/发布校验；新mask与projection/solid指纹继续边界校验；释放仍归同Field/district。无新增每帧文件读取，pure只投影；五正式消费者候选各仅runtime路径/SHA二literal，整字节逆通过。三复用素材PNG/import/ctex本来已在现役1877表，不重导入。必须再确认实际新Sprite alpha/柱脚/人物局部遮挡及正式来源闭包，不能以静审冒实机。

剩余只读组件key进程55696自然0/19检查0/4ms，只锁旧A5AEE结果/8A106 header/五产物/4FE0先验，0PNG或binary解码、0几何。它明确记录旧publisher整体false/自然1，不洗原失败。

Root与QA已实看92156的唯一原生作者总览（8BB31713）；自然0/351检查0/2191ms，报告67E41B22。两廊与后仓接合、四段低前界、廊下两作业位局部准，无明显双层屋顶互穿；仍保留大灰空地、双后仓重复/其他孤立商铺问题，不授全南市或全城完成。

新mask唯一隔离导入64920自然0；独立verify42040自然0/82检查0/141ms，EB02AA8A，原图/导入/ctex完整RGBA均EA4B、23参数/mip0/detect0。只两原本ABSENT的`.import`70E7E131与ctex617506EB精确晋升，原PNG不复制、md5不晋升、三复用素材不重导入、主工程零import。导入raw读取警告、作者总览退出Texture错误保留，非clean-stderr。正式runtime尚待闭包与有限Field。

唯一runtime4922879A/binding3E316674与五功能双literal候选已齐，另AA/AC/Coordinator/Temple严格来源后继；32旧目标已全文备207A8DA0（旧116保/总148），Router不在域内。11候选实际104308自然0/59检查0/1521ms，EFC4CDB2，仅load/can_instantiate，0业务方法/Field/collector/几何；保存与候选源首末同。

首Stage输入DC94/driver935D在纯SOURCE_ONLY阶段拒`JSON_EXACT_OLD_VALUE`，无输出/无正式覆盖。定位为四场独立ancestor数学模型18个owned旧值断言尚未迁到new authority，当前9876主增量操作已正确；只准新输入迁18字面量+新输出前缀，不能放宽原8DE0校验或重做地图。原FAIL保留。

## 正式接入与实机结论

NEW输入EF9EC334只迁18个祖先模型断言与新stage02路径，driver935D/权限/候选全不变。Root唯一Stage02自然0，C972F714；原OWNED10、旧162证据与所有旧边保留，必要6成员各追加1边、总170证据/depth16、无shortcut。Root apply_patch17GD后逐SHA精等、15JSON精字节copy，部署7F2A7BE1。32目标全有旧全文备份，无noop；Router/UI/15save与8媒体精ticks同。

Source独审794BFFEE与实际来源核2B5AB3EB通过：固定3284来源仅32授权变化/其余0漂移，四map982/1364/1858/1900精确匹配，无collector或旧native重算。

唯一Field实际122888_2890自然OS0/77检查0/13685ms（整个有限QA耗时，不是入场加载成绩），报告479B1D6D。默认入场后1900自然FINAL与新45租约/mask一致；两明确inspection起脚1720/1384和2660/1384，各真INPUT44px到1340，12INPUT ticks、20Physics、13被动帧、0Space。四实际Sprite/物理多边形按独立source-f32相符；新廊四柱脚不是整屋顶碰撞。两廊各实际alpha命中841px，人物局部ghost有效，四物件alpha/selfalpha始终1；同Field/Player/Scene/layout/mask，无NPC/速度/body改写。只准两短走查，不冒连续长途/全门返程或暖加载。

Root原图实看：[正式南市两处作业院](../../game/build/luoyang_city_revision_20261025g_qa01/Field01_ROOT_READY_output/122888_2890/01_two_new_galleries_work_bays_original105_camera.png)（372882AA）。作者总览与实际1.05图分开；原图仍显同款军士/买菜妇人重复、灰街面较多、旧显眼任务道具，不用局部廊院成功掩盖这些待办。7旧退出Texture等ERROR保，0新SCRIPT，非clean-stderr。

QA独立读实际报告并view同一原图，31F8618F有限准入；不另跑引擎或重出图。资源复用索引已切25g现役45街坊入口，旧24e43列为完整父层，重建1779文本源且无显式缺失路径。

前guardA9F04A0B/末6E8DF772：原2121含UI、15save精ticks、148全文备份、8媒体、33当前目标，本轮实机前后0变化。editor51856始终保留，自身进程自然退，未停止用户进程。停止本组件引擎/几何/旧房重复验收，可普通重运行试玩；下一优先连片街墙后体/余片区密度、实际可用NPC家庭替换、旧任务道具门禁与藏点。24d水桥正式替换、全域首≈10s/重复<10s仍未授予。
