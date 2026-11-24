"""Authoritative wide-road graph for the sparse v10 Jianghu overworld.

Coordinates use the 1536x1024 ImageGen source.  The central polygon is an
intentional roamable plain; routes are broad authored corridors leading from
that plain to every destination.  The same data builds the visible road lift,
navigation mask, layout probes and QA overlay.
"""

SCHEMA_VERSION = 10
AUTHORING_SIZE = (1536, 1024)
LOGICAL_SIZE = (2304, 1536)
FOOT_RADIUS = 5

# Wide travel roads.  Widths are authoring pixels (1.5x at runtime).
ROUTES = [
    ("snow_pass_to_west", 64, [(135, 150), (185, 205), (255, 250), (305, 320), (255, 410), (210, 485), (185, 530)]),
    ("west_plain_entry", 78, [(185, 530), (285, 520), (380, 485), (465, 430), (560, 370)]),
    ("northwest_plain_arc", 82, [(255, 250), (365, 245), (480, 250), (600, 245), (730, 225)]),
    ("north_plain_arc", 86, [(730, 225), (835, 225), (930, 255), (1020, 275), (1105, 300), (1185, 335)]),
    ("lingyue_bamboo_road", 62, [(1285, 300), (1235, 315), (1185, 335)]),
    ("central_crossing", 96, [(560, 370), (660, 360), (760, 370), (860, 390), (960, 420), (1060, 455)]),
    ("south_plain_ring", 92, [(185, 530), (300, 565), (430, 585), (565, 610), (700, 635), (815, 645), (930, 625), (1040, 590), (1160, 570), (1285, 655)]),
    ("zhuwei_lane", 62, [(145, 638), (210, 620), (300, 565)]),
    ("qinghe_lane", 64, [(260, 755), (285, 700), (340, 640), (430, 585)]),
    ("luoyang_south_road", 82, [(1185, 335), (1190, 410), (1160, 500), (1160, 570)]),
    ("luoyang_harbor", 58, [(1185, 335), (1260, 360), (1370, 405)]),
    ("ferry_road", 72, [(1160, 570), (1225, 605), (1285, 655)]),
    # The painting contains a clear south-east branch and a stone bridge here.
    # Keep it in the authoritative graph as well: previously the visible road
    # was missing from the mask, so the actor stopped on apparently open ground.
    ("south_bridge_to_mingwu", 68, [(930, 625), (980, 640), (1020, 670), (1045, 710), (1085, 745), (1135, 760), (1200, 775)]),
    ("lieyun_east_road", 62, [(1285, 655), (1370, 625), (1450, 610)]),
    ("mingwu_tea_road", 68, [(1285, 655), (1245, 710), (1200, 775), (1165, 845)]),
]

# Broad open land rather than another thin corridor.  The small streams shown
# here are shallow wading terrain; large rivers and mountains remain closed.
OPEN_REGIONS = {
    "central_open_plain": [
        (285, 300), (430, 265), (610, 250), (790, 250), (965, 285),
        (1095, 350), (1100, 475), (1035, 555), (900, 615), (720, 635),
        (535, 600), (375, 545), (275, 445),
    ],
    "southwest_meadow": [
        (225, 500), (390, 470), (560, 505), (650, 600),
        (560, 690), (390, 670), (250, 600),
    ],
}

PORTALS = {
    "yanmen_pass": (135, 150),
    # Sect transitions sit at the foot of each mountain road. The painted
    # stairs remain visual distance cues; actors never walk across cliff art.
    "huashan": (600, 245),
    "wudang": (835, 225),
    "gufeng": (1020, 275),
    "lingyue": (1285, 300),
    "luoyang": (1185, 335),
    "east_sea_port": (1370, 405),
    "linxi_village": (185, 530),
    "zhuwei_village": (145, 638),
    "qinghe_town": (260, 755),
    "bailu_ferry": (1285, 655),
    "lieyun_valley": (1450, 610),
    "mingwu": (1165, 845),
}

WALKABLE = {
    "central_field_west": (480, 390),
    "central_field_center": (720, 430),
    "central_field_east": (930, 455),
    "central_field_south": (700, 565),
    "broad_west_junction": (300, 565),
    "broad_east_junction": (1160, 570),
    "south_bridge_north_bank": (1015, 670),
    "south_bridge_deck": (1045, 710),
    "south_bridge_south_bank": (1090, 745),
}

BLOCKED = {
    "northwest_snow_peak": (35, 55),
    "north_mountain_ridge": (700, 50),
    "luoyang_inner_roof": (1255, 250),
    "east_deep_river": (1450, 490),
    "southeast_deep_water": (1390, 760),
    "south_cloud_edge": (760, 995),
}

ROAD_TINT = (214, 177, 112)
ROAD_TINT_ALPHA = 20
ROAD_EDGE_ALPHA = 14
