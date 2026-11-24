# 2026-11-06 聊天反馈审计与 World GM 避让有限修复

## 范围

逐项覆盖清单：[AUDIT](../../game/build/feedback_audit_20261106_qa01/AUDIT.md)。它将最新十项、此前七项与52组历史反馈映射到正式消费者和有限继承证据；不把候选、静态可达或局部功能PASS算成全城ART完成。审计没有重新执行171存档矩阵或全入口矩阵，没有读取、写入或恢复真实存档内容。

### 本轮安全小改及明确边界

- **已合入：World GM/minimap冲突**。只移动与真实地图矩形重叠的GM按钮；地图位置、图标投影、访问状态和地形不变。用户主动拖动后，本mini生命周期不再抢回位置；只有视口resize或新World/mini才重新评估。隐藏释放自身位置租约，且不覆盖用户新位置。
- **另组负责：Loading真实热路径**，需分别报告首Loading绘制、冷加载总耗时、退屏可操作；不得只延长遮罩或弱化来源检查。
- **需先查明再小改：服务mini映射**。现有精映射主要覆盖洛阳四类服务；其它城市必须证实真实功能才能加图标，不能只凭掌柜称谓。尚未新增此类映射。
- **需静态清单而非盲改：全NPC开场头像/声音/任务道具可见性**，审计未授全员完成；本轮高清执行另见NPC专题。

### 需大美术重制或设计的真实剩余

CITY-01（金陵/襄州/洛阳地域街坊密度与身份）、LAN-02（岚溪坡界与重复岩带）、HUA-01（华山近景险峰关系）、YIH-03（怡红院旧客栈壳/楼上与故事）、EST-03（豪宅多进院落身份）、EST-04（宅园硬边/空地/重复）、RIV-02（其它野外道路衔接）仍不能靠局部修复关闭。全现役NPC独立方向/动作真高清也不因过滤或一张idle关闭。

## 正式修改

唯一既有文件：

- `game/build/minimap_icons_20261102c_runtime01/icon_overlay.gd`
- SHA256：`9645111F19C9C5ABBEC033B3220055DDC310B0466EEFB8169B0967D675CEB0EB` → `E62915B42761D0B3918126285D16E0866FBBB0B140D6D2AB8573B6C9CD432601`。
- 只加helper持有、World sync、失效/隐藏/退树release；没有改变原图标绘制与调试字段。

新文件：

- `game/build/minimap_gm_20261106_runtime01/gm_minimap_avoidance.gd`
- SHA256 `9E8A428B1D2FEEA2E111F0A27CA971BF08838BB9AD813B6AE8AC8DD6E424A266`。

直接正式消费者为MapIconRuntime preload；102来源表未pin该overlay，未改102、Router、EX、project或任何地形/角色素材。详细只读pin核查见[PIN_PLAN](../../game/build/feedback_audit_20261106_qa01/PIN_PLAN.md)。

## 有限验证和验收

1. 无autoload独立project fixture **12检查/0错，自然退出**：首次避让、重复sync不抖、原位恢复、拖动释放不抢位、隐藏恢复尊重拖动、resize重评、新mini重评、真实CanvasLayer缩放。
2. 唯一正式World public go_world_map probe **7检查/0错、1原图**；新隔离APPDATA/LOCALAPPDATA、最早PlatformBridge暂停checkpoint。没有穿越任何城门，没有真实存档调用。wrapper136304已自然结束。
3. 初始GM矩形(1826,150,72,46)移到(1552.5,150,72,46)，map真实矩形(1634.5,140,259,178)，间距10px；真实GUI press/motion/release拖到(1728,206)，20帧后保持且user_override=true。
4. [正常图](../../game/build/feedback_audit_20261106_qa01/WORLD_GM_NORMAL.png)为1920×1080，Root已亲看：**仅GM避让域ART接受**，mini底图/头像正常，不授全World图标或整城美术PASS。

[实际结果](../../game/build/feedback_audit_20261106_qa01/WORLD_GM_RESULT.json)、[原日志](../../game/build/feedback_audit_20261106_qa01/run01/engine.log)、[fixture日志](../../game/build/feedback_audit_20261106_qa01/fixture-engine.log)保留。WASAPI初始化失败、已有WorldPNG导出warning、7项退出ERROR/ObjectDB warning均原样保留，不称clean log。

停止本域重复验证；编辑器未操作、未停止用户进程。此前AUDIT的“无引擎/只写审计目录”描述的是首版只读阶段；本节精确补记随后Root授权的两文件正式修复和有限引擎阶段。
# 原生高清复用补充（只读，不代表新资源已合入）

9张指定RAW有限审计见 [RAW_REUSE.md](../../game/build/feedback_audit_20261106_qa01/RAW_REUSE.md) 与精确像素JSON。避开npc06已量化10组，不扩非现役资产，不起引擎。年轻蓝灰军士idle1027px/右行四帧557–566px已有真透明RAW和授权825²母帧，现160格消费者可由原生适配替换，无需重生已有动作。岚溪男女侧行原生389–415px、赤岩/沙漠女掌柜1025px已经正式保原像素，不应重复生图或报作本轮新接入；岚溪idle与赤岩merchant/worker四向旧源仍不足320。脚点、镜像语义、正式consumer及复用边界都在表内，Root原图接受与npc06实际采用另记。本子任务不改任何素材或adapter。

