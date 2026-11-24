"""Authoritative route graph for the realistic v12 Jianghu overworld.

Coordinates are authored against the 1536x1024 ImageGen clean plate.  The
same graph paints the subtle road reinforcement and produces navigation, so
visible roads and walkability cannot drift independently.
"""

SCHEMA_VERSION = 12
AUTHORING_SIZE = (1536, 1024)
LOGICAL_SIZE = (2304, 1536)
FOOT_RADIUS = 5

ROUTES = [
    ("yanmen_road", 58, [(160, 100), (215, 165), (300, 235), (395, 275)]),
    ("huashan_road", 58, [(520, 90), (500, 145), (465, 210), (430, 255)]),
    ("wudang_road", 58, [(840, 80), (830, 145), (815, 215), (780, 260)]),
    ("gufeng_road", 58, [(1070, 85), (1045, 150), (1000, 215), (950, 260)]),
    ("lingyue_road", 58, [(1400, 110), (1370, 175), (1330, 235), (1290, 275)]),
    ("north_crossroad", 72, [(395, 275), (520, 255), (650, 245), (780, 260), (950, 260), (1120, 270), (1290, 275)]),
    ("west_plain_road", 78, [(395, 275), (315, 345), (270, 430), (335, 515), (430, 575)]),
    ("bianzhou_gate_road", 74, [(430, 575), (510, 480), (550, 420), (690, 420)]),
    ("luoyang_gate_road", 74, [(950, 260), (1040, 300), (1100, 350)]),
    ("central_open_crossing", 92, [(430, 575), (560, 600), (720, 610), (875, 575), (1030, 520), (1190, 470)]),
    ("xiangzhou_gate_road", 74, [(720, 610), (720, 575)]),
    ("linxi_road", 66, [(430, 575), (330, 565), (245, 555), (170, 570)]),
    ("zhuwei_road", 64, [(330, 565), (245, 650), (170, 760)]),
    ("qinghe_road", 64, [(430, 575), (365, 650), (300, 735)]),
    ("south_bridge_road", 76, [(790, 625), (900, 635), (1000, 655), (1080, 680)]),
    ("jinling_gate_road", 70, [(1080, 680), (1060, 720)]),
    ("east_sea_shore_approach", 70, [(1190, 470), (1200, 480)]),
    ("bailu_road", 64, [(1000, 655), (1040, 610), (1210, 600), (1320, 600), (1400, 595)]),
    ("lieyun_road", 64, [(1080, 655), (1020, 650), (970, 675)]),
    ("mingwu_tea_road", 66, [(1000, 655), (1010, 750), (1030, 835), (1090, 880), (1250, 895)]),
]

OPEN_REGIONS = {
    "central_open_plain": [
        (275, 285), (470, 245), (680, 270), (860, 285), (1050, 270),
        (1250, 300), (1325, 410), (1260, 535), (1100, 640), (900, 680),
        (700, 660), (510, 620), (355, 585), (265, 505), (225, 405),
    ],
    "southwest_open_meadow": [
        (190, 500), (380, 485), (560, 515), (740, 610),
        (650, 735), (450, 760), (270, 710), (145, 610),
    ],
}

CLOSED_REGIONS = {
    "bianzhou_walled_city": [(535, 280), (900, 280), (900, 400), (535, 400)],
    "xiangzhou_walled_city": [(570, 425), (850, 425), (850, 545), (570, 545)],
    "luoyang_walled_city": [(1115, 280), (1465, 280), (1465, 440), (1115, 440)],
    "jinling_water_city": [(1085, 650), (1460, 650), (1460, 850), (1085, 850)],
    "east_harbor_water": [(1260, 455), (1360, 420), (1535, 395), (1535, 585), (1435, 585), (1370, 580), (1300, 560), (1220, 535)],
}

PORTALS = {
    "yanmen_pass": (160, 100), "huashan": (520, 90), "wudang": (840, 80),
    "gufeng": (1070, 85), "lingyue": (1400, 110), "bianzhou": (690, 420),
    "luoyang": (1100, 350), "xiangzhou": (720, 575), "jinling": (1060, 720),
    "east_sea_port": (1200, 480), "bailu_ferry": (1400, 595),
    "lieyun_valley": (970, 675), "mingwu": (1250, 895),
    "linxi_village": (170, 570), "zhuwei_village": (170, 760),
    "qinghe_town": (300, 735),
}

WALKABLE = {
    "central_plain_west": (455, 470), "central_plain_center": (900, 470),
    "central_plain_east": (1040, 480), "central_plain_south": (760, 610),
    "south_bridge_deck": (1035, 665), "east_coast_junction": (1400, 595),
}

BLOCKED = {
    "northwest_snow_peak": (35, 35), "north_mountain_ridge": (730, 35),
    "bianzhou_inner_roof": (575, 340), "xiangzhou_inner_roof": (720, 500),
    "luoyang_inner_roof": (1210, 340), "luoyang_courtyard": (1340, 330),
    "jinling_inner_roof": (1200, 720), "east_harbor_sailing_lane": (1450, 555),
    "east_harbor_inlet": (1280, 520), "east_deep_water": (1520, 560), "south_deep_water": (970, 940),
    "south_cloud_edge": (700, 1000),
}

ROAD_TINT = (207, 171, 109)
ROAD_TINT_ALPHA = 10
ROAD_EDGE_ALPHA = 7
