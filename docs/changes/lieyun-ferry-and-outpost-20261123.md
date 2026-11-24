# 烈云峡谷旧渡与分舵外区

## 玩家视角

旧渡的船系在河边，桨篙收进岸棚，两根桩之间系着新封绳。查渡痕的位置在跳板右前方，前景松树和岩脊避开了查证点。沿货路折回山道，两段验路横木把来人引到旧渡守望的棚前。

[渡口同位置对照](../../reports/lieyun_checkpoint_20261123/ferry-compare.jpg) · [守望棚对照](../../reports/lieyun_checkpoint_20261123/sentry-compare.jpg)

分舵南口的两道拒马错开布置。西侧棚下查隔离药册，东侧兵架靠近守岗位置，巡守拦在北门前。两座哨楼嵌在寨墙内，墙体沿门楼两侧延至崖壁再向南折回。引路人放行后，门槛前的横木移到东侧。

[外区同位置对照](../../reports/lieyun_checkpoint_20261123/outpost-compare.jpg) · [查册后](../../reports/lieyun_checkpoint_20261123/after/04-register.jpg) · [放行后](../../reports/lieyun_checkpoint_20261123/after/07-open-yard.jpg)

## 发行包实走

两轮均从主菜单读取同一个旧渡 18 级「存档二」副本，起档 SHA-256 为 `1a676d05016ce4fc8f7c3b8647e884056b7d45603033dcd0ab243b9c407ac101`。Windows x64 Release 在无工程读取权限的独立进程中运行。测试驱动通过玩家的移动、交互、对白选项和战斗操作推进。

| 实走步骤 | 最终版结果 |
| --- | --- |
| 查旧渡痕迹、问旧渡守望，去茗雾取证后回烈云 | 完成「双线求证」，查过外院转运目录，从峡谷进入分舵。 |
| 查册前后 | 查册前聚义厅门锁住，横木有实体碰撞。在西棚查到隔离药册后，巡守现身，与他对话触发封渡战。 |
| 封渡战 | 从巡守对白开战，对手为烈云强硬派巡守和烈云封渡寻迹手。主角以 559/655 气血获胜，胜利面板显示经验 165、金钱 110 两、解毒丹一枚。 |
| 引路人放行 | 门前碰撞消失，东侧停放位置出现碰撞。角色以方向输入走到横木原占地，再经正常出口进入聚义厅。 |
| 回程 | 从聚义厅回外区，再回旧渡。此次连续试玩只启动了一场战斗。 |

第一轮改版碰到过横木移走后仍无法过门的问题。最终版把活动横木的实体碰撞挂到对应精灵上，查验状态切换时随精灵一起重建。最终包另用洛阳府衙旧档冷启动并实走，确认普通场景加载与移动。

[改前日志](../../reports/lieyun_checkpoint_20261123/before/release.log) · [改后日志](../../reports/lieyun_checkpoint_20261123/after/release.log) · [封渡战](../../reports/lieyun_checkpoint_20261123/after/02-ferry-battle.jpg) · [胜利结算](../../reports/lieyun_checkpoint_20261123/after/06-victory.jpg) · [进入聚义厅](../../reports/lieyun_checkpoint_20261123/after/05-passage.jpg) · [府衙旧档](../../reports/lieyun_checkpoint_20261123/city-smoke.log) · [实测包校验值](../../reports/lieyun_checkpoint_20261123/package-sha256.txt)

日志仍有原发行包已有的三项启动校验提示、部分 NPC 对话镜像回退提示，以及退出时的纹理释放报错。
