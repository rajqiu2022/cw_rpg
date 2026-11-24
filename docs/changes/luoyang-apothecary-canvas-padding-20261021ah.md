# 药铺无损透明扩画布 · 2026-10-21ah

状态：已完成离线无损扩画布，未导入或部署。用户在“是否允许本地无损补透明画布、原图和全部建筑像素保持不变、不擦背景、不拉伸”的明确问题后回复“允许”。授权仅用于此药铺扩画布，不扩大为抠背景、重绘、新图生成或场景部署。

## 操作与验收

- 输入：ag原始窄药铺1160×1355 RGBA，原PNG SHA `B329B4941654194B0F1E69EECDAB77A67D08C437526CF589B6C7C857860F2FA9`，RGBA SHA `1A7DF54882C2C40A7CFEF06AEBBD2B6D4F2D8C7C525B9445672F0EAAFF1FEFE2`。
- 输出：新建1907×1567透明画布，将完整原RGBA放到偏移`[382,148]`，不使用alpha混合或蒙版；源图不改、不删除任何原有像素、不拉伸。
- ART写确定性处理工具，Root执行；QA单独写只读复核，Root执行。新产物拒绝覆盖，原raw和ag失败记录保留。
- 验收：输出回裁`[382,148,1542,1503]`与原RGBA逐字节相同；该矩形以外全部RGBA为零；实际A1边界、四边留白与占比符合原约束；门洞比例不变。

## 范围

本轮只有派生图片及其来源记录，不调用生图、不改`tasks.yaml`、不导入Godot、不修改正式地图、门、导航、任务或存档。不复测af脚本或ae场景。处理成功不代表B窗口与旧楼相交、A窗口高度不足或三房拆分接线问题已解决。

## 结果

- Root执行ART工具自然退出0；仅Pillow `getdata`弃用警告，无处理失败。执行前审出Python报告字典小写JSON布尔，ART先修为Python布尔，未发生失败执行；最终脚本SHA `D86ED502B69EEAD721C7900A0E606E3E38026AA807F6393CBF11648E1063DC64`。
- 派生图：`assets/processed/luoyang_market_frontage_20261021ah/facade_luoyang_narrow_apothecary_single_bay_v1_padded.png`，1907×1567 RGBA、1878408B、PNG SHA `1741A55D449A25481FF26C4F62C595987D8768F8CC72E4229A896C78485AE56D`；同名`.meta.json` SHA `E9FC7C5F2C1B55603EA2ED76ECF8D6A4DD18775BBBDE44E766B53090D2AF213A`。
- 独立QA工具自然退出0，20项检查/0失败，报告`game/build/luoyang_market_frontage_20261021ah_qa01/padding_verify_62872.json` SHA `2A34811CC87A16252E65440B9892458645C1C2D1244DFE4A6A991E50466325FC`。整幅原RGBA精确保持，框外全零，224连通块/846466非零alpha像素及完整alpha直方图仅新增零画布；没有擦掉599个离散像素。
- A1完整边界`[382,157,1526,1410]`，四边留白`382/157/381/157px`，均≥10%，占画布宽59.9895%。原AG raw留白FAIL仍保留，仅本派生图通过留白检查，门洞像素及比例不变。Root已查看实际派生PNG；原边缘细碎像素保持，不授边缘清理完成。
- Fresh当前守卫2094路径（仅继承AG路径集合，不复制旧值）：before `F5A0B0A343195EFC705AA209BAFF537BA274C72859EF7B8F4740E24FD71BB071`，final `CCAD1E40B3FA8D82084F518C057F02C8937C5AD7D98A1665A951CB7D7B321E03`，2094项SHA/bytes/exactticks零变化，15存档零变化、tasks不改。
- 本轮0次生图。原生成提示词仍见`prompts/luoyang_market_frontage_20261021ag/facade_luoyang_narrow_apothecary_single_bay_v1.txt`；本次机械处理规格见ART目录`pad_transparent_canvas.spec.json`。正式仍ae，下一是另外两门脸与三用途整体拆楼、门返脚/碰撞导航同步，不是直接把新药铺叠加到B窗口。
