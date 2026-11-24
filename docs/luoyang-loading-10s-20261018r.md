# 场景加载目标：首次约10秒、后续少于10秒 · 2026-10-18r

## 最终结论：已正式默认，停止本轮引擎复验

以下按时序保存历史。本轮正式结果：世界默认进图6.715701秒；四区首次Gate10.078677/Market7.023994/Docks6.332463/Yamen8.135864秒；真实世界Space首次Gate8.988339秒、出世界1.713320秒、再入同Gate1.016003秒。Gate普通略超严格10秒，不写全部<10。四区为同一进程每ID首次，不冒四次SSD冷。

最后WorldContract B01BCF23C45C37CCA5D59072C1BAA56EFD4C6244B290887E51B4F85AC0D0F5B7仅强持首个合法原生Scene元数据，原C10E全文精备。隔离重复parse probe108524自然0：临时Scene三次1112.887/1099.403/1094.307ms，强持首读1091.494ms后同实例0.003/0.002/0.002ms；不是实际玩家耗时。无二进制layout/remap/take_over_path，不持贴图。关键计时修正：默认工具虽不显式提前load世界Scene，但继承入口reset_for_new_game原有formal_version在arm之前；6.715701秒是进图请求到可操作，不包含更早reset初始化/进程启动。先前“默认工具没有预加载”不能作为覆盖所有首次解析的声明。

最终112008自然OS0/process12.787s/whole9.723s，21156检查零失败；result game/build/world_visible_stream_actual_20261018r/112008_2786/result.json，SHA84B6E845CA24A257FA497EFD92D835EE788EEAE165D06B6C11EC975420C2BFCC。默认脚2600,3991.099，required512=actual202、allowed318；16px INPUT后required201包含于actual202包含于allowed317。原2687元数据/2322实体/16Areas、Texture-alpha/ordinal、Scene同实例与原layout、释放drain0均过。137自身source首末/current同、15save exact，Root/QA实看3A09B300默认PNG。LM207预读759.689ms/8槽/27poll，sceneRead2.437ms；prime3.677030s内含attach3.005515s，不叠加。attach峰17.091ms，8ms合作预算不是硬实时。1Image/7旧退出TextureERROR/0SCRIPT/ObjectDB非clean。

最终鲜核818：5授权旧源变、813 SHA/bytes/stringticks同、15保存0变、0engine。WorldContract不在原818，另C10E精备+B01B及finalcore66全SHA核。旧错误预期6/812的false报告原样保存，纠正5/813 freshguard通过，见root01/guard_final_corrected.json。四区默认indexB468true与世界视窗stream已启用。LM F95B候选未部署。停止本轮所有引擎验证，交用户重启正式试玩；不授其它城市、长程LRU/压力驱逐/跨epoch晚任务、全部门/全艺术。code-review技能促成资源安全图、强引用生命周期与计时边界复核。

用户继续授权性能优化，正式q地图/拼装内景已接入，不重做美术或旧十房验收。主控仅运行自有引擎，fresh818路径保护含15保存；原地图、任务、34×24碰撞/87517与已生效的房门/间距不降级。

## 当次正式基线（不是旧o推测）

NEW基线工具先在第一张已绘制、Loading隐藏、角色can_move/can_process且已绑定同Scene finalized来源的帧冻结时间；完整resident_receipt、全当前source独立SHA、Physics与截图随后执行。正确性失败仍FAIL，不用后验检查补早帧。是新Godot进程首次访问，不声称SSD/OS页缓存冷。

proper7672自然OS0；actual111456直接自然OS0/process79.422s，whole脚本76.176s/3417检查零失败，result29EE73FFE7E21F16AFEFBB9E7C101EE3E0EBDB7A9D3D6D7B83692A5667075386，路径game/build/luoyang_loading_baseline_20261018r/111456_2847/result.json。160whole/60arrival，正式无flags，世界原96px正常INPUT+真Space进入Gate；32px来回/真实出城/同城再入，来源/取消/身体/保存不放宽。

| 实际边界 | 首次可动绘制耗时 | 10秒目标 |
| --- | ---: | --- |
| 合法世界近门公开setup（不是旅行） | 24.870989秒 | 未达 |
| 世界真Space首次进洛阳城门 | 21.177711秒 | 未达 |
| 城门真Space回世界 | 9.863793秒 | 当次达标，接近上限 |
| 实际世界真Space再进同城门 | 1.049138秒 | 当次达标，same-live-Field |

实际Gate来源完整651叶；完整QA尾核7.392721秒单列，不加到Loading时间，也不拿这651当未来固定全集。cold resolve14.934秒：source2.225、BASE CPU3.218/main4.945、module1.739、Harbour1.379、enclosure.578/nav.379，包含关系不能简单相加。snapshot64ms/commit10ms不是大瓶颈。后续候选需相同首绘制仪器独立新进程比较，旧o21.837仅历史参考。

## 实现方向与边界

主改动A：用当前完整制作校验管线真正发布最终Scene/layout/record/mask/solids成品，再由独立严格运行合同载入；前移BASE的mesh/material/像素重建、多层raster/路线计算。第一原子保留原完整source首末哈希、当前任务/门户/动态投影与Field/District原检查，明确proof_kind和发布期证明，不伪称每次重跑几何。旧同步/Web/完整制作路径保留；失败/取消/owner变更不提交半份NAV，现rollback保留。

四区共同制作、Gate真实旅行及暖返代表优先；另薄测四区各首次公开入场，不借出版成功冒四区时长。世界实际2687物件，完整碰撞和所有入口保持，视觉改512px预取/1024px保留迟滞。提案在game/build/luoyang_loading_10s_20261018r_system01/PROPOSAL.md。

## WORLD有限实测已通过，城市成品尚未默认开启

生产Field3462/LM17D352与新world9DA2/overlapC41C已接。LM初稿617弱引用类型推断被警告当错误，104996动态检查原FAIL保留；显式WeakRef一行修后107128动态加载自然0；不能用直接check-only缺失autoload的5056失败冒生产不能编译。108792 native index/overlap单元自然0/69检查通过，仅原生数据域。

world-only113456自然OS0/process9.466s、whole6.342s/19104检查零失败，result9A13C3857AEE584C63A203B9B14DF2B044828189E5817564ABA8F56A676B9A3E，路径game/build/world_visible_stream_actual_20261018r/113456_2864/result.json。同基线近Gate合法公开setup首绘可动2.788866s（原24.870989s）；实际出生512集6图/原96px行走后10图，全2322原生实体和16Area/原ordinal/实际Texture-alpha字节均核。108有限源及15保存记录首末同；Root实际看D8AEPNG。自己的Field/stream正常释放且drain0。独立源审同意有限PASS。不是默认出生202图、全球/长程驱逐、在途取消或城市性能信用；attach峰14.613ms，8ms是合作预算非硬实时。

城市完整出版第一次78244自然1/两row成功后Docks拒，实因P binding唯一C旧pin，不是几何坏；NEW PbindingD0FE/Phelper3E07只迁当前C9503依赖，原A52E/author/geometry全留。第二次54968自然1/三row后Yamen on_enter_dialog真实DialogScript被安全_plain拒。两次FAIL与旧r/r2产物均原地保留，不改历史证明。

NEWrevision6 helper6F4E采用固定DialogScript/DialogNode完整storage安全图（含typed Array与共享ref），Objects-disabled bytes只比较，不构造Object。Yamen增加实际dialogTRES与两脚本3个来源叶，不删原闭包。55224实际小单元自然0/17检查/24ms：真实Yamen两Node、var_to_bytes、Scene duplicate/res保存读回、内存改文案拒与unknown Resource拒均过，result620A6FB8；先做预检避免反复整包。

publication6实际112724自然OS0/77.636s，完整四区原制作pipeline/source首末/原生Scene-layout-25MiB NAV全storage读回通过，legacy源数Gate653/Market1096/Docks1310/Yamen565，resultEECB06DEAF16FE19D83BA55128B916FDE47BD3F53F7A8F6CABFCD30F1ECD0A0B。新r3产物不覆盖旧目录，indexE03B四entries且formalfalse。此77.636s是制作出版耗时，不是玩家Loading。C9503/P3E07/TempleD1C4+v13依赖冻结；普通城市仍原路径，尚待单位与实际性能/默认启用验收。保留旧退出GL七ERROR/0SCRIPT，非clean。

## 四区已默认正式；当前最后排查世界默认首次

22008单位自然0/185检查0/4.010s，Gate/Market各真实reader+pre-cancel共4线程全join，native Scene/layout全storage、原完整mask RGBA与内存篡改反例过，result514016BCECB636EA3056BE1C93C44ED10915BC337F56218B7EE9ED0DBACD73E5。仅代表单位，不授其它两区运行或几何重跑。

109932候选真实world96px+Space→Gate→world→同Gate自然0/41496检查零失败/34.562s，result1FD8CAF73EA2E127CA7ACEBA4BE7DABEC7401BC5E4DF2681B06437467A789C93。首绘freeze耗时分别2.808199/8.988339/1.713320/1.016003秒，冷Gate postverify7.434443秒另列。实际658完整来源精确等baseline651+三SHA变化(C/Field/P)+七NEW叶，0删叶；770自身source及15保存首末同。same Field/Scene/Player/static/nav/10ambient身份、真实queued cancel与own退出、27Physics通过，根看BEFF图；独立QA有限PASS。当前r3不每次重跑几何的scope如前，0暖worker/没有冒新鲜暖磁盘SHA。10Image/7退出ERROR/0SCRIPT/ObjectDB非clean。

Root精备indexE03B全文后唯一formalfalse→true，现B46838E6D76D6DCA95BC3BBD128240EAC25391FC66D61C68E1612EC432D79E59；helper本身false不动，防止重新冻结legacy自身循环。普通无flag111196自然0/3935检查0/39.654s，result733407CB5CE12A6959F4A082994FD7AF81E40776F4F56D4C0E41C1DB18A32956，四区各首次公开默认setup（同一进程，不是假称四次SSD冷或区间旅行）：

| 区域 | 首绘隐藏可动 | 完整来源 |
| --- | ---: | ---: |
| 南城门 | 10.078677秒 | 658 |
| 南市 | 7.023994秒 | 1101 |
| 漕渠码头 | 6.332463秒 | 1315 |
| 府衙外院 | 8.135864秒 | 570 |

普通requested四区/formaltrue及唯一bool全文等式、每完整map==本区publicationlegacy+5输出叶、4×16px INPUT/16Physics/native34×24 child0/末lease释放通过。69自身source与15保存首末同，Root/QA均实际看4PNG。城门略超严格10s（目标标false），属于用户“约10s”范围，不能写四区严格全<10。7Image/7旧退出TextureERROR/0SCRIPT/ObjectDB非clean。

默认world单独7804自然0/21070检查0、首绘15.069301秒仍未达；出生202图与行后201required/202allowed保留完整，原2322body/16Area、RGBA/ordinal/16px行走/退出drain0通过，Root看默认出生图。86528同一默认点只读诊断自然0/21074/0，首绘14.629668秒；LM完整207预读仅787.002ms（8槽、28poll帧、collect0.399ms），farm patch核310ms在LM时间内；prime3.676563秒内含attach3.020650秒，不能相加或把prime外残差全归预读。故未部署F95B LM分流候选，它最多消除不足1秒屏障，且会破Market/Docks现行来源，收益不足则不试错。

近Gate工具在arm前加载世界Scene取portal，因此其2.8秒不授未预读布局的默认首次；同基线近点前置一致，城市8.99秒真Space边界不受此影响。默认工具没有预加载，已揭示额外同步费用。当前最后只读核18,199,642B世界文本layout是否临时Scene释放导致重复parse；原4区正式包/LM17D保持，不改旧地图素材、NAV、任务或十室内。
