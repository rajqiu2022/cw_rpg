# 大会考校官同人头像 · 独立首稿候选

本项只一次builtin image_gen参考生成；独立tasks.yaml登记1attempt/skiptrue，无自动retry或CLI收费出图。旧共享prompts/tasks.yaml、透传模板和原精灵未写；初末SHA分别872C1F42/80C8D6AE/4021C7DA保持。CLI --tasks-file --dry-run实际exit0/1task/0API cost，dry-run默认gpt-image-2字样不作实际builtin model，真正model/provider/usage/cost未知null。

原图：assets/raw/luoyang_city_finish_20261022ap/portrait_luoyang_examiner_mature_same_sprite_20261022ap_v1.png，SHA4FBA998B313E66B60F62804EA8968B25742DC5825A76921743265E6A26031DCC，1670479B/实际1254×1254 RGBA。原tool字节逐SHA同，tool路径与output_hint保存在旁meta。未裁切、擦alpha、扩canvas、变色、组合、导入或改正式引用。

ART先实看四帧同人精灵，再实看原图：成熟粗犷方脸/厚眉/高髻鬓髭、宽肩、深青武服与铜肩甲衣着一致，脸部清楚，可供主控进一步审；160px精灵不能作为精细人脸法证，限于大身份/衣服一致。原精灵另被多NPC身份复用，后续不得全局替换所有共享消费者。

FAIL必须保留：原1024²目标未命中；A>0 bbox[0,9,1240,1254]触左底，左24点/底59点A1；A>=8[72,132,1236,1165]、A>=64[72,134,1235,1164]，强主体完整但右肩仅19px边距，三阈值完整10%留白全FAIL。不标runtime-ready，不在本项清图或补生。全统计见alpha_qa.json。

考场两个NPC没有专用portrait_path，当前Field generic fallback是年轻身份的消费缺口；本候选没有绑定到它们。少量已观察消费者和源SHA在spec.json，未修改它们/任何canonical/import/引擎/用户进程，AP其它验收状态不因本图改变。
