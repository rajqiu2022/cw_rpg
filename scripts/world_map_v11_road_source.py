"""Authoritative route graph for the realistic v11 Jianghu overworld."""

SCHEMA_VERSION = 11
AUTHORING_SIZE = (1536, 1024)
LOGICAL_SIZE = (2304, 1536)
FOOT_RADIUS = 5

ROUTES = [
    ("yanmen_to_west", 62, [(150, 170), (225, 225), (315, 260), (405, 285)]),
    ("huashan_road", 62, [(520, 175), (555, 220), (610, 265), (675, 305)]),
    ("wudang_road", 62, [(800, 175), (785, 215), (760, 245)]),
    ("gufeng_road", 62, [(1045, 185), (1035, 235), (985, 275), (930, 310)]),
    ("lingyue_road", 62, [(1370, 205), (1330, 245), (1275, 285), (1220, 320)]),
    ("north_crossroad", 76, [(405, 285), (520, 265), (640, 245), (760, 245), (840, 260), (930, 310), (1050, 315), (1220, 320)]),
    ("west_plain_road", 82, [(405, 285), (335, 360), (300, 430), (355, 510), (420, 575)]),
    ("bianzhou_gate_road", 78, [(730, 405), (730, 455)]),
    ("luoyang_gate_road", 78, [(1220, 320), (1280, 355), (1325, 420)]),
    ("central_open_crossing", 96, [(420, 575), (550, 530), (690, 500), (825, 480), (960, 470), (1100, 475), (1210, 500), (1325, 420)]),
    ("xiangzhou_gate_road", 78, [(730, 565), (790, 610)]),
    ("southwest_village_road", 70, [(420, 575), (330, 585), (235, 555), (175, 545)]),
    ("zhuwei_road", 66, [(330, 585), (270, 650), (225, 735)]),
    ("qinghe_road", 66, [(420, 575), (410, 650), (430, 745)]),
    ("south_bridge_road", 82, [(790, 610), (890, 625), (985, 650), (1050, 680), (1110, 705)]),
    ("jinling_gate_road", 72, [(1050, 680), (1110, 705)]),
    ("east_coast_road", 74, [(1325, 420), (1400, 445), (1460, 485), (1440, 555), (1400, 615)]),
    ("bailu_road", 66, [(1440, 555), (1370, 565), (1300, 590), (1210, 610)]),
    ("lieyun_road", 64, [(1400, 615), (1320, 620), (1240, 640), (1165, 665), (1110, 705)]),
    ("mingwu_tea_road", 68, [(1110, 705), (1040, 760), (1100, 835), (1245, 865)]),
]

OPEN_REGIONS = {
    "central_open_plain": [
        (330, 300), (500, 270), (690, 285), (860, 300), (1040, 285),
        (1210, 330), (1260, 430), (1215, 535), (1110, 615), (950, 660),
        (775, 650), (600, 620), (440, 590), (330, 500), (275, 405),
    ],
    "southwest_open_meadow": [
        (250, 500), (430, 485), (590, 520), (720, 600),
        (640, 700), (470, 730), (300, 680), (210, 585),
    ],
}

CLOSED_REGIONS = {
    "bianzhou_walled_city": [(545, 245), (900, 245), (900, 405), (545, 405)],
    "xiangzhou_walled_city": [(600, 420), (855, 420), (855, 575), (600, 575)],
    "luoyang_walled_city": [(1170, 245), (1500, 245), (1500, 425), (1170, 425)],
    "jinling_water_city": [(1070, 650), (1460, 650), (1460, 815), (1070, 815)],
}

PORTALS = {
    "yanmen_pass": (150, 170),
    "huashan": (520, 175),
    "wudang": (800, 175),
    "gufeng": (1045, 185),
    "lingyue": (1370, 205),
    "bianzhou": (730, 400),
    "luoyang": (1325, 420),
    "xiangzhou": (730, 565),
    "jinling": (1110, 705),
    "east_sea_port": (1460, 485),
    "bailu_ferry": (1440, 555),
    "lieyun_valley": (1400, 615),
    "mingwu": (1245, 865),
    "linxi_village": (175, 545),
    "zhuwei_village": (225, 735),
    "qinghe_town": (430, 745),
}

WALKABLE = {
    "central_plain_west": (455, 470),
    "central_plain_center": (760, 470),
    "central_plain_east": (1060, 480),
    "central_plain_south": (760, 610),
    "south_bridge_deck": (1050, 680),
    "east_coast_junction": (1400, 615),
}

BLOCKED = {
    "northwest_snow_peak": (45, 45),
    "north_mountain_ridge": (700, 55),
    "bianzhou_inner_roof": (620, 365),
    "luoyang_inner_roof": (1400, 330),
    "east_deep_water": (1510, 520),
    "south_deep_water": (900, 900),
    "south_cloud_edge": (700, 1000),
}

ROAD_TINT = (207, 171, 109)
ROAD_TINT_ALPHA = 14
ROAD_EDGE_ALPHA = 10
