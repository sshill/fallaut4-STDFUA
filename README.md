# Модель взаємодії з Fallout 4 («Hands-on Architect»)
### На основі аналізу аналітичного щоденника та діалогового журналу `Gemeni fallaut chat`

---

## 📌 Вступ та призначення репозиторію

Дана модель взаємодії розроблена на основі глибокого аналізу 111+ сесій взаємодії, ігрових рішень, питань та стратегічних маневрів, зафіксованих у документі **`Gemeni fallaut chat`**.

Документ відображає унікальне, високоефективне проходження **Fallout 4: Game of the Year Edition** (з усіма офіційними DLC: *Far Harbor*, *Nuka-World*, *Automatron*, *Vault-Tec Workshop*, *Wasteland Workshop*, *Contraptions* та офіційними модами *Creation Club*, зокрема *Neon Flats* та *X-02 Power Armor*).

Ігровий стиль користувача визначений як **«AI-Driven Hands-on Architect» (Інженер-Стратег / Технократичний Директор)**:
1. **Інженерний раціоналізм:** пріоритет максимальної ефективності систем, автоматизації, захисту периметрів та ресурсної самодостатності.
2. **Гуманістичний порядок:** відхилення експлуататорських практик (наприклад, потогонних налаштувань наглядачки Сховища 88), прагнення до естетики та високого рівня щастя поселенців.
3. **Холодний макіавеллізм:** використання фракцій (Братство Сталі для побудови Ліберті Прайм, рейдери Ядер-Світу для отримання топових перків) з їхньою подальшою утилізацією або нейтралізацією на користь гегемонії **Інституту**.
4. **Двоконтурна бойова спеціалізація:** гнучкий перехід між ультимативним важким танком (X-02 + Гатлінг-лазер на 70+ блоках) та витонченим нуар-інфільтратором (Харизма 22, Спритність 10, глушники, костюми з циліндром Освальда).

---

## 🗂 Структура файлів моделі у теці `fallaut/`

| Файл | Опис та зміст |
| :--- | :--- |
| **[`fallout_interaction_model.md`](file:///home/hills/Documents/fallaut/fallout_interaction_model.md)** | **Ядро моделі взаємодії.** Системні цикли, архітектура прийняття рішень, контури управління, діаграма станів та протокол асистування. |
| **[`player_profile_and_strategy.md`](file:///home/hills/Documents/fallaut/player_profile_and_strategy.md)** | **Профіль гравця «Hands-on Architect».** Специфікація S.P.E.C.I.A.L., білд, перки, психологія вибору, еволюція проходження за хронологією. |
| **[`settlement_and_economy_engine.md`](file:///home/hills/Documents/fallaut/settlement_and_economy_engine.md)** | **Інженерно-економічна підсистема.** Водна індустрія, захисні вежі (турелі + ракети), енергомережі, Сховище 88, система васалів. |
| **[`combat_and_equipment_matrix.md`](file:///home/hills/Documents/fallaut/combat_and_equipment_matrix.md)** | **Бойова доктрина та спорядження.** Контури Juggernaut та Noir Stealth, силова броня X-02/T-51, кастомізація Ади, легендарний фарм. |
| **[`factions_and_quests_roadmap.md`](file:///home/hills/Documents/fallaut/factions_and_quests_roadmap.md)** | **Геополітична дорожня карта.** Інститут, нейтралізація Братства Сталі, дипломатія Far Harbor, операція в Nuka-World («Відкритий сезон»). |
| **[`interaction_model_schema.json`](file:///home/hills/Documents/fallaut/interaction_model_schema.json)** | **Машиночитана схема (JSON).** Формалізований граф станів, тригери рішень, ліміти, коефіцієнти та умови переходів. |
| **[`director_executive_setup_and_rd_protocol.md`](file:///home/hills/Documents/fallaut/director_executive_setup_and_rd_protocol.md)** | **Генеральний протокол розгортання та НДДКР.** Реформа Директорату (Кюрі, Дездемона, ДіМА, Валентайн), інтеграція Братства Сталі як повітряного та броньового ВПК, стримувач «Оптімус / Ліберті Прайм», модуль цільових розробок замість RNG, Пакт ненападу та консольний довідник. |
| **[`grand_campaign_expansion_model.md`](file:///home/hills/Documents/fallaut/grand_campaign_expansion_model.md)** | **Модель розширення кампанії та реанімації тупикових гілок.** Матриця прив'язки до офіційних квестів Bethesda, інтеграція супермутантів (Вірджил, Силач) як Радіаційного Корпусу в Сяючому Морі, реформа Атомних Котів, Стрільців, Дітей Атома та Салема. |
| **[`southern_raider_clearing_cycle.md`](file:///home/hills/Documents/fallaut/southern_raider_clearing_cycle.md)** | **Тактичний цикл зачистки південних рейдерів.** Оптимальний маршрут зачистки банд на південь від Даймонд-Сіті, механіка спавну важкої металевої броні, таймери респавну клітинок та фарм босів (Гайд-Парк, Д.Б. Тек тощо). |
| **[`nuka_world_star_control_and_cappy_guide.md`](file:///home/hills/Documents/fallaut/nuka_world_star_control_and_cappy_guide.md)** | **Посібник ліквідації «сліпого пошуку» в Nuka-World.** Повний реєстр усіх 35 Star Cores для Quantum X-01 Power Armor та 10 прихованих графіті Кеппі в окулярах Сьєри за секторами парку без хаотичного блукання. |
| **[`hardware_stand_setup_and_architecture.md`](file:///home/hills/Documents/fallaut/hardware_stand_setup_and_architecture.md)** | **Апаратна специфікація та архітектура Fallout-стенда.** Повний інженерний звіт міграції з PS4 на PC Linux, аудит заліза HP Laptop (Intel Core 3 100U), оновлення Mesa 24.x, стек Gamescope+FSR (60 FPS), двоекранна топологія, мультимодальна 6-канальна матриця біосенсорів (Polar H10, LinX CGM, Zone Vibe 100, DualShock 4, PCsensor FootSwitch, 1-мс хаб `CLOCK_MONOTONIC_RAW`) та обхід GPU blocklist у Chrome. |
| **[`architecture_diagram.puml`](file:///home/hills/Documents/fallaut/architecture_diagram.puml)** | **PlantUML діаграма комплексу.** Візуалізація зв'язків між сенсорами суб'єкта, мобільним мостом (xDrip+ Wi-Fi), центральним ноутбуком, ігровим рушієм, великим ТВ-дисплеєм та Live Research Dashboard. |
| **[`research_protocol.md`](file:///home/hills/Documents/fallaut/research_protocol.md)** | **Науковий протокол дослідження (Digital Therapeutics).** Дослідження регуляції кортизолу, кардіоваскулярної варіабельності (HRV/RMSSD) та вегетативної стабілізації при хронічному бойовому та виробничому стресі засобами адаптивного безшовного геймплею. |
| **[`Gemeni fallaut chat.docx`](file:///home/hills/Documents/fallaut/Gemeni%20fallaut%20chat.docx)** | **Первинний архів діалогового треду.** Повний вивантажений документ (3.3 МБ) 118 сесій взаємодії з Gemini під час проходження. |
| **[`extracted_chat_text.txt`](file:///home/hills/Documents/fallaut/extracted_chat_text.txt)** | Повний розпакований текстовий масив первинного аналітичного щоденника для швидкого пошуку першоджерел. |
| **[`all_user_queries.txt`](file:///home/hills/Documents/fallaut/all_user_queries.txt)** | Структурований реєстр усіх 118 унікальних користувацьких запитів із таймлайном та аналітичними категоріями. |
| **[`launch_fallout4.sh`](file:///home/hills/Documents/fallaut/launch_fallout4.sh)** | **Офіційний нативний лаунчер стенда Fallout 4 GOTY.** Запуск гри на базі Wine 10 + DXVK 2.6 з пріоритетом Vulkan 1.4 для Intel Raptor Lake-U, активацією оверлею MangoHud та автоматичним моніторингом `Papyrus.0.log`. |
| **`Скрипти та утиліти стенда`** | **Програмно-апаратний інструментарій:** [`launch_fallout4.sh`](file:///home/hills/Documents/fallaut/launch_fallout4.sh) (лаунчер гри), [`run_research_session.py`](file:///home/hills/Documents/fallaut/run_research_session.py) (1-мс мультиплексор сесії), [`check_footpad.py`](file:///home/hills/Documents/fallaut/check_footpad.py) та [`footpad_result.txt`](file:///home/hills/Documents/fallaut/footpad_result.txt) (USB-педаль), [`setup-bluetooth.sh`](file:///home/hills/Documents/fallaut/setup-bluetooth.sh) (гарнітура Zone Vibe 100), [`cgm_adb_bridge.py`](file:///home/hills/Documents/fallaut/cgm_adb_bridge.py) / [`decode_mars.py`](file:///home/hills/Documents/fallaut/decode_mars.py) (глікемія), [`get_psn_id.py`](file:///home/hills/Documents/fallaut/get_psn_id.py), [`connect_ps4.sh`](file:///home/hills/Documents/fallaut/connect_ps4.sh) / [`start_chiaki_session.sh`](file:///home/hills/Documents/fallaut/start_chiaki_session.sh) (Chiaki/PS4). |

---

## 🚀 Як використовувати дану модель

- **Для планування подальшого геймплею або нових проходжень:** звіряйтеся з геополітичною картою та інженерними стандартами будівництва захисних споруд.
- **Для взаємодії з AI-помічником:** модель задає стандарти відповідей — інженерна точність, попередження точок неповернення, розрахунок ресурсів без зайвої лірики.
