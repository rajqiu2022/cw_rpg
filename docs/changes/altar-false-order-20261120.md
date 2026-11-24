# 范掌柜的谢词与第八章祭台假令

## 古道护商

范掌柜现在说「我会把酬钱和货样交给村里的镖局枪手。回竹尾村后找他就能领到。」整句录音长 13.76 秒。已从正式战后对白的 `thanks` 节点取到新播放流，并核对台本、发言人和 MP3 指纹。本次在该节点验证配音，护商战斗本身沿用既有流程。原 Yunyang 合成服务返回 HTTP 403，本次采用本机普通话男声 Microsoft Kangkang。祭台五句对白也使用此声库，分别调整语速和音高。[录音台本与指纹](../../game/art/audio/voices/altar_and_caravan_cast_20261119.json) · [引擎采样](../../reports/late_campaign_altar_20261119/media.json)

## 祭台上的三方

在「终局分工」之后与传使交谈，烈云护使安排护证，五派代表走近。传使上前宣令时，祭台的 `city_luoyang` 切为 `story_tension`。五派代表指出副卷只有半枚朱印，护令客拔刀逼近，冷孤云挡在证人与对方之间。最后一句和动作收束后，玩家确认进入传使与护令客的双敌战。Esc 和画面上的跳过按钮共用同一处开战入口。[祭台实景](../audits/evidence/altar-false-order/altar_draw.png)

| 第七章保护决定 | 第八章现场 | 验证范围 |
| --- | --- | --- |
| 分开转移 | 行义帮护送内院录事，烈云暗线护旧教习 | 沿用第七章真实结算档，走过雾林、机关廊与终局分工。[抵达祭台](../../reports/late_campaign_altar_20261119/prepare.log) |
| 公开留在烈云 | 两名证人并立，烈云明哨护在前方 | 在独立的祭台存档副本中重选第七章正式对白选项，进场核对。[实景](../audits/evidence/altar-false-order/public.png) · [记录](../../reports/late_campaign_altar_20261119/public_verification.log) |
| 交洛阳府衙 | 两名证人移到后排，由洛阳官差守在身前 | 同样从独立副本重选正式选项，进场核对。[实景](../audits/evidence/altar-false-order/luoyang.png) · [记录](../../reports/late_campaign_altar_20261119/luoyang_verification.log) |

## PC 存档回归

从同一份祭台交谈前的存档分支，使用 Windows 桌面工程、正式菜单和正常战斗指令。下表的开战次数来自战斗开始信号，并与双敌名单和胜利结算核对。重启均退出引擎后另起进程读盘。[交谈前存档](../../reports/late_campaign_altar_20261119/platform_before.json)

| 操作 | 观察结果 |
| --- | --- |
| 完整看完五句 | 五段人声逐句播完，冷孤云实际移到证人身前，随后开战 1 次，胜利转入「庄主问局」。[逐句播放与战斗](../../reports/late_campaign_altar_20261119/full_verification.log) |
| 五派代表质疑时按 F5，退出重开 | 保存时开战 0 次。再与传使交谈，从质疑朱印这一句恢复，紧张曲和站位一起恢复。余下三句结束后开战 1 次。[存入](../../reports/late_campaign_altar_20261119/save_verification.log) · [续玩](../../reports/late_campaign_altar_20261119/resume_verification.log) |
| 宣令时连按两次 Esc 再按空格 | 直接进入原双敌战，收到 1 次开战信号并取得胜利。停在结算页直接退出。[跳过与胜利](../../reports/late_campaign_altar_20261119/skip.log) |
| 从胜利结算的自动存档重开 | 两名对手的击败状态均在。回祭台交谈仅触发胜利对白，完成「截住首令」、增加任务奖励 140 银两并接到「庄主问局」，开战 0 次。再存再读，银两仍为 4334，开战 0 次。[结算页续玩](../../reports/late_campaign_altar_20261119/result.log) · [再次重开](../../reports/late_campaign_altar_20261119/after.log) |

逐句在人声尚未结束时按空格，五次均停留在当前台词。另从同一个存档点击跳过按钮，也只触发一次双敌战。[提前确认](../../reports/late_campaign_altar_20261119/held_verification.log) · [鼠标跳过](../../reports/late_campaign_altar_20261119/click_verification.log)

这一轮验证的是 PC 工程。声音通过引擎播放流与网页试听核对。桌面日志中仍有此前存在的三条来源校验告警，以及引擎退出时的资源清理告警。Steam 导出包仍待单独验证。[六条网页音频与重启后的奖励核对](../../reports/late_campaign_altar_20261119/verified_web_and_rewards.json)
