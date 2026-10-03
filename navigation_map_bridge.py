#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fallout 4 GOTY Research Stand - Interactive Navigation & Map Bridge
===================================================================
Bridges fallout4map.com (MapGenie WebGL Interactive Map) with in-game
Creation Engine navigation, cell coordinates, and console shortcuts.

Capabilities:
  1. Instant search across Commonwealth, Nuka-World, and Far Harbor locations.
  2. Generates direct filtered URLs for fallout4map.com (categories, items, bosses).
  3. Translates locations into in-game console commands ('coc <CellID>', 'tmm 1').
  4. Dispatches fast travel or teleport commands via game_console_copilot.py.
  5. Opens interactive map views in system browser on demand.
"""

import os
import sys
import subprocess
import argparse
import webbrowser

STAND_DIR = os.path.dirname(os.path.abspath(__file__))
CONSOLE_COPILOT = os.path.join(STAND_DIR, "game_console_copilot.py")

# ---------------------------------------------------------------------------
# Categories & Direct Filter Links (fallout4map.com)
# ---------------------------------------------------------------------------
MAP_CATEGORIES = {
    "commonwealth": {
        "title": "Співдружність (Commonwealth)",
        "base_url": "https://fallout4map.com/",
        "categories": {
            "bobblehead": {"name": "Пупси Волт-Тек (20 шт)", "url": "https://fallout4map.com/?cat=2587"},
            "magazine": {"name": "Журнали перків (131 шт)", "url": "https://fallout4map.com/?cat=2589"},
            "power_armor": {"name": "Силова броня (57 точок)", "url": "https://fallout4map.com/?cat=2595"},
            "fusion_core": {"name": "Ядерні блоки (110 шт)", "url": "https://fallout4map.com/?cat=2596"},
            "mini_nuke": {"name": "Міні-ядерні заряди (61 шт)", "url": "https://fallout4map.com/?cat=2597"},
            "unique_boss": {"name": "Унікальні вороги / Боси (31 шт)", "url": "https://fallout4map.com/?cat=2680"},
            "settlement": {"name": "Поселення та майстерні (30 шт)", "url": "https://fallout4map.com/?cat=2648"},
            "vault": {"name": "Сховища Волт-Тек", "url": "https://fallout4map.com/?cat=2655"},
            "key": {"name": "Ключі та паролі (110 шт)", "url": "https://fallout4map.com/?cat=2674"}
        }
    },
    "nuka_world": {
        "title": "Ядер-Світ (DLC Nuka-World)",
        "base_url": "https://fallout4map.com/nuka-world",
        "categories": {
            "star_core": {"name": "Ядра Зоряного Диспетчера / Quantum X-01 (35 шт)", "url": "https://fallout4map.com/nuka-world?cat=2682"},
            "hidden_cappy": {"name": "10 прихованих графіті Кеппі", "url": "https://fallout4map.com/nuka-world?cat=2683"},
            "power_armor": {"name": "Силова броня в Ядер-Світі", "url": "https://fallout4map.com/nuka-world?cat=2595"},
            "recipes": {"name": "Рецепти Ядер-Коли", "url": "https://fallout4map.com/nuka-world?cat=2679"},
            "scav_magazine": {"name": "Журнали 'SCAV!' (5 шт)", "url": "https://fallout4map.com/nuka-world?cat=2589"}
        }
    },
    "far_harbor": {
        "title": "Далека Гавань (DLC Far Harbor)",
        "base_url": "https://fallout4map.com/far-harbor",
        "categories": {
            "islander_almanac": {"name": "Альманах остров'янина", "url": "https://fallout4map.com/far-harbor?cat=2589"},
            "power_armor": {"name": "Силова броня Vim!", "url": "https://fallout4map.com/far-harbor?cat=2595"}
        }
    }
}

# ---------------------------------------------------------------------------
# Key In-Game Locations & CellIDs for Direct Console Teleportation ('coc')
# ---------------------------------------------------------------------------
LOCATIONS_DB = [
    # Commonwealth
    {
        "keys": ["sanctuary", "сенкчуарі", "сенкчуари", "дім"],
        "name": "Сенкчуарі-Хіллз (Sanctuary Hills)",
        "region": "Співдружність",
        "cell_id": "SanctuaryExt",
        "map_url": "https://fallout4map.com/?locationIds=350810",
        "desc": "Головна штаб-квартира гравця, верстаки, водна індустрія."
    },
    {
        "keys": ["red rocket", "ред рокет", "ракета"],
        "name": "Стоянка вантажівок 'Червона ракета' (Red Rocket)",
        "region": "Співдружність",
        "cell_id": "RedRocketExt",
        "map_url": "https://fallout4map.com/?locationIds=350812",
        "desc": "Перший ангар силової броні, місце зустрічі з Псиною."
    },
    {
        "keys": ["concord", "конкорд", "музей"],
        "name": "Конкорд / Музей Свободи (Concord)",
        "region": "Співдружність",
        "cell_id": "ConcordExt",
        "map_url": "https://fallout4map.com/?locationIds=350811",
        "desc": "Місце першого бою з Кігтем смерті, Престон Гарві."
    },
    {
        "keys": ["diamond city", "даймонд сіті", "даймонд сити", "базар"],
        "name": "Даймонд-Сіті (Diamond City Market)",
        "region": "Співдружність",
        "cell_id": "DiamondCityEntranceExt",
        "map_url": "https://fallout4map.com/?locationIds=350831",
        "desc": "Центральний торговельний хаб Співдружності, детективне агентство Валентайна."
    },
    {
        "keys": ["goodneighbor", "добросусідство", "добрососедство"],
        "name": "Добросусідство (Goodneighbor)",
        "region": "Співдружність",
        "cell_id": "GoodneighborExt",
        "map_url": "https://fallout4map.com/?locationIds=350838",
        "desc": "Місто гулів, будинок спогадів, Кент Конноллі (Срібний Плащ), Маккріді."
    },
    {
        "keys": ["the castle", "замок", "форт індепенденс"],
        "name": "Замок / Форт Індепенденс (The Castle)",
        "region": "Співдружність",
        "cell_id": "TheCastleExt",
        "map_url": "https://fallout4map.com/?locationIds=350855",
        "desc": "Головна цитадель Мінітменів, артилерійські позиції, потужні генератори."
    },
    {
        "keys": ["vault 111", "сховище 111", "убежище 111"],
        "name": "Сховище 111 (Vault 111 Exterior)",
        "region": "Співдружність",
        "cell_id": "Vault111Ext",
        "map_url": "https://fallout4map.com/?locationIds=350808",
        "desc": "Точка початку гри, кріолятор."
    },
    {
        "keys": ["vault 88", "сховище 88", "убежище 88"],
        "name": "Сховище 88 (Vault 88)",
        "region": "Співдружність",
        "cell_id": "DLC06Vault88SectorEntrance",
        "map_url": "https://fallout4map.com/?locationIds=351650",
        "desc": "DLC Vault-Tec Workshop, велетенський підземний сектор будівництва."
    },
    {
        "keys": ["institute", "інститут", "институт"],
        "name": "Інститут (The Institute Concourse)",
        "region": "Співдружність",
        "cell_id": "InstituteConcourse",
        "map_url": "https://fallout4map.com/?locationIds=350846",
        "desc": "Штаб Інституту, Директорат, нанотехнології, телепортація."
    },
    {
        "keys": ["prydwen", "придвен", "бос", "братство сталі"],
        "name": "Дирижабль 'Придвен' (The Prydwen)",
        "region": "Співдружність",
        "cell_id": "PrydwenHullExt",
        "map_url": "https://fallout4map.com/?locationIds=350850",
        "desc": "Флагман Братства Сталі, старійшина Мексон, термінали озброєння."
    },
    {
        "keys": ["glowing sea", "сяюче море", "светящееся море", "кратер"],
        "name": "Кратер Атома в Сяючому Морі (Crater of Atom)",
        "region": "Співдружність",
        "cell_id": "GlowingSeaPOIDB04Ext",
        "map_url": "https://fallout4map.com/?locationIds=350882",
        "desc": "Епіцентр радіації, база Дітей Атома, шлях до печери Вірджила."
    },
    {
        "keys": ["hyde park", "гайд парк", "гайд-парк"],
        "name": "Гайд-Парк (Hyde Park)",
        "region": "Співдружність",
        "cell_id": "HydeParkExt",
        "map_url": "https://fallout4map.com/?locationIds=350884",
        "desc": "Південний рейдовий сектор фарму важкої металевої броні (бос Скегг)."
    },
    {
        "keys": ["gunner plaza", "ганер плаза", "стрільці", "стрелки"],
        "name": "Плаза Стрільців (Gunner Plaza)",
        "region": "Співдружність",
        "cell_id": "GunnerPlazaExt",
        "map_url": "https://fallout4map.com/?locationIds=350875",
        "desc": "Головна військова база угруповання Стрільців, капітан Вес, багатий лут."
    },

    # Nuka-World
    {
        "keys": ["star control", "зоряний диспетчер", "звездный диспетчер", "ядра", "star core"],
        "name": "Зоряний Диспетчер / Quantum X-01 (Star Control)",
        "region": "Nuka-World",
        "cell_id": "DLC04GZStarControlTerminal",
        "map_url": "https://fallout4map.com/nuka-world?cat=2682",
        "desc": "Термінал 35 Star Cores та вітрина унікальної Quantum X-01 Power Armor."
    },
    {
        "keys": ["nuka town", "ядер-таун", "ядер таун", "ринок ядер"],
        "name": "Ядер-Таун США (Nuka-Town USA)",
        "region": "Nuka-World",
        "cell_id": "DLC04NukaTownUSA",
        "map_url": "https://fallout4map.com/nuka-world?locationIds=351700",
        "desc": "Центральна локація Nuka-World, база босів банд, гора 'Физзтоп'."
    },
    {
        "keys": ["galactic zone", "галактична зона", "галактика"],
        "name": "Галактична Зона (Galactic Zone)",
        "region": "Nuka-World",
        "cell_id": "DLC04GalacticZoneExt",
        "map_url": "https://fallout4map.com/nuka-world?locationIds=351710",
        "desc": "Сектор бойових роботів, зоряний порт 'Нексус', сховища ядер."
    },
    {
        "keys": ["kiddie kingdom", "дитяче королівство", "освальд"],
        "name": "Дитяче Королівство (Kiddie Kingdom)",
        "region": "Nuka-World",
        "cell_id": "DLC04KiddieKingdomExt",
        "map_url": "https://fallout4map.com/nuka-world?locationIds=351720",
        "desc": "Радіаційний сектор гулів, Освальд Чарівник (циліндр та смокінг)."
    },
    {
        "keys": ["nuka power plant", "електростанція ядер", "питание"],
        "name": "Електростанція Ядер-Світу (Nuka-World Power Plant)",
        "region": "Nuka-World",
        "cell_id": "DLC04PowerPlantExt",
        "map_url": "https://fallout4map.com/nuka-world?locationIds=351750",
        "desc": "Рубильник відновлення енергії всього парку, дах для фіналу."
    },

    # Far Harbor
    {
        "keys": ["far harbor", "далека гавань", "фар харбор", "острів"],
        "name": "Далека Гавань (Far Harbor Town)",
        "region": "Far Harbor",
        "cell_id": "DLC03FarHarborExt",
        "map_url": "https://fallout4map.com/far-harbor",
        "desc": "Головне рибальське поселення Острова, Капітан Ейвері, старий Лонгфелло."
    },
    {
        "keys": ["acadia", "акадія", "акадия", "діма", "синти"],
        "name": "Акадія (Acadia)",
        "region": "Far Harbor",
        "cell_id": "DLC03AcadiaExt",
        "map_url": "https://fallout4map.com/far-harbor?locationIds=351500",
        "desc": "Обсерваторія вільних синтів на вершині гори, ДіМА, Касумі Накано."
    },
    {
        "keys": ["nucleus", "ядро", "діти атома остров"],
        "name": "База підводних човнів 'Ядро' (The Nucleus)",
        "region": "Far Harbor",
        "cell_id": "DLC03NucleusExt",
        "map_url": "https://fallout4map.com/far-harbor?locationIds=351520",
        "desc": "Укріплена база Дітей Атома, сповідник Тектус, пускові ключі ракет."
    }
]

def search_locations(query):
    query_lower = query.lower().strip()
    matches = []
    for loc in LOCATIONS_DB:
        score = 0
        if query_lower in loc["name"].lower():
            score += 10
        for k in loc["keys"]:
            if query_lower in k:
                score += 5
            elif k in query_lower:
                score += 3
        if score > 0:
            matches.append((score, loc))
    matches.sort(key=lambda x: x[0], reverse=True)
    return [m[1] for m in matches]

def open_url(url):
    print(f"[Navigation Bridge] Відкриваю у браузері: {url}")
    try:
        webbrowser.open(url)
        return True
    except Exception as e:
        print(f"[Navigation Bridge] Помилка відкриття браузера: {e}")
        return False

def teleport_to_cell(cell_id):
    cmd = f"coc {cell_id}"
    print(f"[Navigation Bridge] Переміщення консоллю -> {cmd}")
    if os.path.exists(CONSOLE_COPILOT):
        subprocess.run([sys.executable, CONSOLE_COPILOT, cmd, "--notify"], check=False)
    else:
        print(f"Виконайте у консолі гри (~): {cmd}")

def show_all_markers():
    cmd = "tmm 1"
    print(f"[Navigation Bridge] Відкриття всіх маркерів карти Піп-Боя -> {cmd}")
    if os.path.exists(CONSOLE_COPILOT):
        subprocess.run([sys.executable, CONSOLE_COPILOT, cmd, "--notify"], check=False)

def list_categories():
    print("=== КАТЕГОРІЙНА НАВІГАЦІЯ FALLOUT4MAP.COM ===")
    for reg_key, reg_data in MAP_CATEGORIES.items():
        print(f"\n📍 {reg_data['title']} ({reg_data['base_url']}):")
        for cat_key, cat_info in reg_data["categories"].items():
            print(f"   • [{cat_key}] {cat_info['name']} -> {cat_info['url']}")

def main():
    parser = argparse.ArgumentParser(description="Fallout 4 Interactive Map & Navigation Console")
    parser.add_argument("query", nargs="*", help="Пошуковий запит (назва локації, предмета чи боса)")
    parser.add_argument("--open", "-o", action="store_true", help="Відкрити знайдену сторінку/фільтр у браузері")
    parser.add_argument("--teleport", "-t", action="store_true", help="Виконати консольне переміщення 'coc <CellID>' у грі")
    parser.add_argument("--markers", "-m", action="store_true", help="Активувати всі маркери на карті Піп-Боя ('tmm 1')")
    parser.add_argument("--categories", "-c", action="store_true", help="Вивести перелік категорійних фільтрів fallout4map.com")

    args = parser.parse_args()

    if args.categories:
        list_categories()
        return

    if args.markers:
        show_all_markers()
        return

    query_str = " ".join(args.query).strip()
    if not query_str:
        parser.print_help()
        sys.exit(0)

    # Check for direct category match
    query_lower = query_str.lower()
    for reg_data in MAP_CATEGORIES.values():
        if query_lower in reg_data["categories"]:
            cat_info = reg_data["categories"][query_lower]
            print(f"\n🎯 Знайдено прямий фільтр карти: {cat_info['name']}")
            print(f"🔗 Посилання: {cat_info['url']}")
            if args.open:
                open_url(cat_info["url"])
            return

    results = search_locations(query_str)
    if not results:
        print(f"Локацію або категорію за запитом '{query_str}' не знайдено.")
        print("Спробуйте: sanctuary, diamond city, castle, star control, cappy, bobblehead, power_armor")
        sys.exit(1)

    best = results[0]
    print(f"\n🎯 ЗНАЙДЕНО ЛОКАЦІЮ: {best['name']} [{best['region']}]")
    print(f" 📝 Опис: {best['desc']}")
    print(f" 🗺️ Карта (fallout4map): {best['map_url']}")
    print(f" 🕹️ Консольна клітинка (CellID): {best['cell_id']}  (Команда: coc {best['cell_id']})")

    if len(results) > 1:
        print("\nІнші схожі збіги:")
        for r in results[1:4]:
            print(f" • {r['name']} ({r['cell_id']}) -> {r['map_url']}")

    if args.open:
        open_url(best["map_url"])

    if args.teleport:
        teleport_to_cell(best["cell_id"])

if __name__ == "__main__":
    main()
