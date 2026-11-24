# 2026-10-31e 洛阳进城加载回归修复

目标：修复大地图洛阳入口出现加载后卡住或返回。只更新城门来源清单及其索引；不改布局、碰撞、剧情、角色状态或真实存档。

## 原因与实际证据

前轮仅验证Region城内新街坊，未验证仍使用旧B包的World→Gate入口。EX/Authority已批准完整后继，不等于B.describe的精确来源集合自动更新；Gate manifest保留三个旧Region来源SHA，并缺少九条后来批准的Router不可变快照。

Root唯一修前探针130784自然退出1，实际调用C._transition_sources与B.describe：expected1695、actual1704，恰3过期SHA、9新增路径、0缺失路径，describe拒绝。记录`game/build/luoyang_entry_20261031e_qa01/bundle_pre_actual/130784/result.json`；保留此真实失败，不以旧Authority成功代替。

## 最小修改

- Gate manifest FEDAAF36→64A14973：legacy1683→1692，仅三精确SHA更新和九已有快照键追加。其他旧键值、导航数据、素材、业务字段保持。
- precomputed bundle index 050CCE00→1774573B：只换此Gate manifest SHA，其余三入口不改。
- Router8EA7、EX7725、RegionEntryE35C/FieldFDB3/manifestE79D、Authority及城市布局全部保持，不增加current-disk fallback、不放宽SHA/集合条件。

候选、前逆补丁与整字节逆证在`game/build/luoyang_entry_20261031e_system01/`；两目标fresh before与本轮基线一致，Root经apply_patch合入后精SHA/bytes匹配。没有新PNG、导入、存档schema或业务改动。

## 唯一修后实际进城

Root68460自然退出0，24检查0失败、4输入事件；公开World原洛阳门近脚4000,2594.491（不冒长途步行），唯一原门can_enter成立后真Space进入ch4_s0_luoyang_gate，落1536,1860，再真D32px至1568,1860。同Player/队伍/生命/内力/金钱保持。正常图Root亲看，SHA92FE5369，原7退出纹理/RenderingServer ERROR与ObjectDB警告保留，不称clean。

报告`game/build/luoyang_entry_20261031e_qa01/entry_post_actual/68460/result.json`；进门至截图11116ms，不冒10秒加载目标。进程收据20B37E3A，Root唯一引擎、无进程强停、编辑器51856保留。停止本次成功入口复验，不扩大为全城/旧桥阶服务矩阵。

## 保护与历史

本轮fresh基线DFD7D99A，2743源/171登记存档/9不存在；真实存档仅SHA/bytes/UTCticks，不反序列化读写。用户运行游戏导致此前两存档变化保留，本轮以新fresh现值保护，不回滚。第一次scope的中文日志路径编码错误在采样报告写出前失败，旧候选保留；scope02直接Unicode字面量修正后capture通过，用户日志精字节副本留存。

最终保护检查06C511AAA276BD2AEF54F546E3BB72D8E1DEA000E5F13C9543ECFFFD9B4A238E通过：2743源仅两授权变动、171save精确SHA/bytes/UTCticks同、9absent保持、30证据精pin同，errors为空，仅编辑器51856。相对31d的两次用户存档历史更新保留，不冒31d以来从未变化。报告`game/build/luoyang_entry_20261031e_qa01/final_guard_ACTUAL.json`。

## 防复发

每次改公共Router后继或Region基础来源，必须对仍使用B包的原城门消费者运行最小真实collector→describe集合比较，不只检EX逆边、manifest自洽或新Region街坊。该检查可零Field/零输入快速定位；入口更改后仅一次原World真门短走，避免重复全城矩阵。
