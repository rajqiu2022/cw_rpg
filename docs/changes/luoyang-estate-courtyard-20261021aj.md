# 洛阳宅园建筑层 · 2026-10-21aj

后继说明：用户随后明确确认三新组件本地背景处理，已由[2026-10-21ak](luoyang-estate-cleanup-assembly-20261021ak.md)执行并产生真实组装图。本文件以下为当时冻结记录，原失败和未授权时状态不重标。

状态：实施中。承接ai已验证的独立宅园原型，不复测原2226路径/12对白/四城，不把仅铺地当整区完成。

## 本批目标

- 用三种独立组件建立院落层次：私宅接待主厅、生活厢房、通透回廊。入口门前留可走净空，建筑不互穿；原NPC身份/任务/存档不变。
- imagegen内置逐图生成，0参考，避免继承上一批同楼轮廓/杂色。每种先1次generate，本批最多另1次明确问题edit；不CLI/API fallback，不本地修改PNG。
- 完整A>0包络按世界尺度定宽，主厅约760、厢房440–520、短廊500–560；透明画布不是建筑宽，统一等比换算，所有弱alpha纳入测量。成人净门高度≥120，主厅完整高≤450、厢≤330、廊≤250。
- 书斋/宅门两旧图本地清理仍未明确授权，保持原FAIL与原文件，不在本批处理。

## 分工与验收

ART准备提示词/登记/实际图审；System持有新aj_system01候选作者/几何/出版键；QA独立新当前保护及三组件测量；Root统一调用生成、运行验证与实图检查。原ai actual源和产物全部冻结；新架构影响区域需新实体/NAV/门位同步，不直接覆盖正式数据。

生成与测量、候选生成、有限实际图依次验收，不先启正式外场或改Router。新Scene尚不等于整城完成，也没有新增loading指标。编辑器和Ollama服务保留，只退出自己的检查进程。

## 保护基准

Root在三task登记后、调用生图前，按ai final的2094路径集合重采当前SHA/bytes/String UTCticks，before `49FA6E05DE7C2886655148CDD1689FF8C0D1E0EFB50C3416FF42354B6C1C41AE`。不是登记前快照，不能把该报告说成覆盖此前tasks追加。仅tasks后续可授权变更，其余含15存档保护；NEW资源另列实际清单，不声称整个workspace无变化。

## 实际结果

已执行三次内置零参考生成，原始输出逐字节复制至 `assets/raw/luoyang_estate_components_20261021aj/`，未做本地像素处理、导入或正式替换。

全部提示词及冻结spec位于 `prompts/luoyang_estate_components_20261021aj/`；使用内置imagegen（3generate＋1targeted edit），未使用CLI/API fallback。四个最终保存的raw PNG及同名meta在上述raw目录，原工具输出保留在 `C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/`。

- 主厅：`5DA2B02391BE94B0E4C7B8EAECD34211B0972E60D36F19B1ED8FD90453A8C9A6`。
- 厢房：`19E2213A063AA0EDB5465379AB970610961CD738E57D630ED7BC2466B23A92A4`。
- 回廊：`77D9942F298FA1DBAD0ED72854DD856A1F331D9E533018C6555767B7C283CC04`。

Root 首次只读测量完整执行，报告 `game/build/luoyang_estate_courtyard_20261021aj_qa01/raw_three_first.json` / `61E3A46E5A8C994F5D273798D60413DC4456D3781AE780AEA1E9F2234C2ADA19`。量测完成但像素门禁失败：三张完整 A1 均触边、透明边距不足，不丢弃弱 alpha 后通过。主厅 A1 `[0,0,1732,891]`，厢房 `[0,2,1514,990]`，回廊 `[0,0,1768,839]`。该 shell 末续读 JSON 的退出码不能冒充 Python 成功，Python 摘要明确 passed=false；原失败保留。

Root 实看厢房明显灰雾底，主厅净门粗测约252px，按完整宽1732缩至760后仅110.57px，低于120。已另问三张新图本地去背景／清边／补透明留白许可，未答前不处理；也不泛化此前药铺或湿岸的局部授权。唯一 targeted edit 仅修主厅门高与真实留白。候选源码存在但 AUTHOR_READY 尚缺，不执行出版、不放宽原门禁，不把图已生成称为城区已落地。

唯一主厅 EDIT 已实际完成并保留原始输出，PNG `85BB985E584E0349236AF92A155BC11CF9BCAE9FF49AEEE533DB08FEBB460C94`，元数据 `2C1E457909227C77F6DD136BA81BD45C62D104D02C56E62EE527F4C0B913461C`。Root/ART 实看净门约295±8px，完整 A1 宽1706缩至760后保守127.85px，门高已恢复；但 A1 `[31,25,1737,812]` 四边留白仅31/25/28/79px，仍未达10%，原raw仍拒绝。停止生成，不用更多生图反复碰同一背景问题。

System 当前源码与静态树移范围已冻结为 `game/build/luoyang_estate_courtyard_20261021aj_system01/CHECKPOINT_NOTREADY.json` / `C1C7AE31C885B93259CCE9BA95F64248B694740B26E46B878D047F28AE8B6D67`。计划只移NW/NE两树、同步树脚碰撞与受影响路线；该adapter尚未实施。没有 AUTHOR_READY、实际新geometry、导入或Sprite预览，预备脚本中的62Sprite不能称实际显示。正式仍ae；也未改加载链或取得新的加载耗时。

唯一v2只读实际量测自然退出1，完整执行非异常，报告 `73C94FB430E37FA6F2670509CE8B1FFFC337E1BCE8C5518EACE73F6B221492ED`。Root实际注记 `26A0A502B9558C0CEEB68F9FA5DC7C228EC9CECFF351D58AF5ECF3DDDEA897D4`：门线880,425→880,720、误差8、地脚883,806；旧120成人门高通过但透明边距失败。v2额外宽/保守门高≤5.8设计目标亦未保守达到（1706/287≈5.944），另记而不冒全部edit约束通过。无后续重复量图。

最终保护报告 `game/build/luoyang_estate_courtyard_20261021aj_root01/final_guard.json` / `269226C7181435172846B06560F151F462247312A7ECE7C11B803F77887EF4D5`，自然0，2094目标仅tasks一项授权差、其余2093含15存档SHA/bytes/exactticks一致。最终tasks `4B3B0B25E04658FA4B3ADFC312DB0C8E5BBBF128CE6436DB81C4A6BCE25E99E9`；editor51856/API100140保留，本批没有启动引擎。NEW四raw/metadata/测量文件和候选源码在保护集合外分别登记，不冒整个工作区零变化。
