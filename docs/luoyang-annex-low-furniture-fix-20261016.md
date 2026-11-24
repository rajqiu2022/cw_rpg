# 洛阳厢房分离与低家具遮挡修正

change-id: luoyang-annex-low-furniture-20261016

## 范围与设计

用户图1为府衙东厢房与纵墙相穿，实际底座重叠22×10像素。新局部版本将东厢房2430/1210移至2640/1210、西厢房650/1110移至590/1110，显示与真实碰撞同步平移，保留原墙、人物、任务和入口。东前廊绕行路线对应改经2790，原端点保持，另增四条侧巷和横通路；原24物件中只有两栋变化，其它22项完整保留。

图2为组装铁匠工作台被错误纳入建筑淡化。NEW局部低家具策略明确将workbench、anvil_stump、bellows、quench_tub保持原始不透明度，继续注册真实脚点排序与当帧alpha遮挡；被挡玩家使用已有上层局部透明轮廓，主角色、碰撞体、交互和NPC透明度不变。高炉和兵器架保持原高家具策略，不改全局Player/NPC。

十种房型基线已写入docs/luoyang-ten-assembled-interiors-design-20261016.md，按空间动线和环境叙事参考及write-page文档规范整理。该成果为设计，不代表十种成品已经生成或接入；当前真正组装式内景仍以铁匠为基线。

## 源码与数据验证

Root按code-review审查接线，最初发现新render clone必须同步真实city_v3_solid_polygons_px，不能仅移动Sprite；正式提交的author B106有逐24项断言，两新底座严格等新record并不同于旧底座，其它22项全值相等。新导航来自原RAW支持减新solid，不覆盖旧walk/PNG/import/出版文件。

首CPU20788自然OS1/36.223s，因为输出目录在写PNG前尚未创建，原P6BE1与result90F55C72保留。NEW publisher_retry2只提前mkdir、加完整storage失败诊断与自身路径更新，不松90秒或几何/存储判据。84632自然OS0/53.531s，result851D4B8D048F550777C472A517FD3F1FCA63F09B2F6E52C37F5890B912BA707B：10条路线3074中心完整875＋17/连续身体/≤4px、全部原玩法锚点、完整Scene/TRES相等通过。

新walk018BF1隔离导入自然0；verify66732自然0，fullRGBA及严格23参数通过，仅两个原缺席的新import/ctex目标精确复制。原素材、港口R7BD8/WFA857/BIND4A2E、原角色和原室内作者不改。

最终候选C6A9CE24D/FieldF42D12E6/rooms4552/LOW829E/annexRfalse3B57B024/BIND740A1BA5（13新叶）已完整备份/三diff审阅，独立SOURCE_APPROVE；proper与正常headless动态load C/Field均自然0，1ObjectDB提醒。新房屋布局仍false，尚非正式运行通过。

## 当前关键实机验证

候选测试BACDA未actual。源码预审发现native Float正alpha计数与RGBA8蒙版量化后的非零像素数不是同一域，NEW retry2 0AB4分记两者，并要求真实CPU蒙版与实际texture完整字节相等、可见非零、当帧角色与原.46轮廓同步；不改生产或阈值。原120/60/2000毫秒快返上限、12像素脚点、34×24身体与四站不变。

GPU26088保留为超时失败：四张工作台实机图已保存，ROOT与QA均核家具保持实体、后方人物轮廓透出、前方与同脚侧正常。测试在92998ms才发起第二个府衙public请求，120秒共享截止时仍处于BASE校验；外wrapper135秒精确停止本次PID，无result，不能授整轮、返城计时或府衙通过。原日志、四PNG与测试源码全部保留，不提高旧预算重跑整轮。

NEW仅府衙短测试E53DD8DC固定90秒/到达60秒，仅一次public与原两巷物理判据，不复房间。proper自然0后实际35568自然OS0，wrapper81.567秒、result78.329秒，519检查零失败；result BCFBB5BFAB3E5BDEB5A7C43AAA6651E97BD0195963BB933219B9F4DAAC465EA0。196原生Physics移动样本、完整875＋17/34×24身体/连续多边形、原旧底座清空及新底座仍阻挡通过，489来源和15保存首末相等，480真实finalized来源全部在本次before。实际public ready50.498秒，不能冒加载提速。

ROOT与独立QA亲看560AC228总览，两侧厢房与纵墙均分开，通廊贯通；独审限定APPROVE。55Image提醒/7旧退出textureERROR/0SCRIPT/0ObjectDB，Dummy不授音乐或clean。Root379有限路径首保护采在低家具接线之后，只授后续阶段保护，不冒本轮所有动作之前的零差；26088与35568前后379路径逐exists/bytes/SHA/ticks比较各零差，含15玩家文件。用户editor108140不停止，game101700末观察已退出、ROOT未停止且原因未知；玩家文件不恢复或覆盖。

## 最小正式接入

Root将false3B57全文备份至build/luoyang_interiors10_20261016_root01/yamen_runtime_false_before_formal.gd.txt，唯一布尔改true，当前R7021AF9AEEF4565E239D0FC535C70F63CB5A99505D89E5F693663E196885AF74；完整字符串replace与当前源精确相等。其它候选C/Field/LOW/rooms/BIND保持，旧港口/世界/玩家资源不改。

NEW formal执行版0EDA1225 proper自然0后仅112420普通无candidate单府衙出生，自然OS1、wrapper93.047秒，result DC86415D6C7476142759C64921261D5AFE2E11548BD755D1B4BA20CCBAC8F825：506检查/2失败/89.989秒，0记录/0PNG。到达60秒上限时public已HANDED_OFF/error空，但Field的最后source worker仍active、sources_finalized=false，没有可操作出生通过。随后reset期间出现`[Field] Final transition source identity rejected; no player created`，是否为取消的衍生尚未精确证明，不能称只有超时或没有业务错误。完整stderr BF959D1FFBB7D0ED1C4F47B227C78B36A40804BEFFD743B70F902DB08D7DF143：54Image/8ERROR（含7旧退出纹理）/0SCRIPT/0ObjectDB，保留原FAIL、不延预算、不追加测试。

本轮状态：两处代码修正已接入默认工程，府衙候选两巷与画面通过，低家具四站实图已核；**普通默认启动尚未验证通过，不授正式发布验收完成或冷加载改善**。492来源与15保存首末逐键相等；Root外层379路径的exists/bytes/SHA/ticks在本次正式尝试前后也零差。用户editor108140保持，所有测试进程已退出，未停止用户进程。十房仅设计完成，下一应制作第一批民宅/客栈/档口，并单独处理最后来源校验的耗时，勿再重跑本次已过两巷/家具四站/全城。
