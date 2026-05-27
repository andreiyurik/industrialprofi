electrician = Path.find_or_create_by!(slug: "elektrik") do |p|
  p.title = "Электрик"
  p.description = "Полный путь от группы допуска II до V: правила устройства электроустановок, техника безопасности, измерения и испытания. Основан на действующих ПУЭ, ПТЭЭП и ГОСТ Р 50571."
  p.position = 1
  p.status = "published"
end

# ── Электробезопасность и допуски ──

lesson = electrician.lessons.find_or_create_by!(slug: "pteep-osnovy") do |l|
  l.title = "ПТЭЭП: основы эксплуатации электроустановок"
  l.stage = "Электробезопасность и допуски"
  l.description = "Зачем это нужно: без знания ПТЭЭП вас не допустят к самостоятельной работе с электроустановками."
  l.body = "Правила технической эксплуатации электроустановок потребителей (ПТЭЭП) — основной документ, определяющий обязанности персонала, порядок допуска к работе и требования к эксплуатации. Изучите главы 1.1–1.4 (общие требования, обязанности потребителей) и главу 1.7 (заземление)."
  l.task = "Прочитайте главы 1.1–1.4 ПТЭЭП. Выпишите 5 обязанностей ответственного за электрохозяйство. Определите, к какой категории относится электроустановка на вашем рабочем месте."
  l.position = 1
end
lesson.resources.find_or_create_by!(title: "ПТЭЭП — полный текст (Приказ Минэнерго №6)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "Памятка: группы допуска по электробезопасности") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "article"
  r.required = false
  r.position = 2
end

lesson = electrician.lessons.find_or_create_by!(slug: "gruppy-dopuska") do |l|
  l.title = "Группы допуска по электробезопасности (II–V)"
  l.stage = "Электробезопасность и допуски"
  l.description = "Зачем это нужно: группа допуска определяет, к каким работам вас допустят и какую ответственность вы несёте."
  l.body = "Система групп допуска — от II (начальный, работа под надзором) до V (ответственный руководитель работ в электроустановках выше 1000 В). Каждая группа требует знания определённого объёма правил и стажа работы."
  l.task = "Определите свою текущую группу допуска. Составьте план подготовки к следующей группе: какие документы нужно изучить, какой стаж требуется, где сдавать экзамен."
  l.position = 2
end
lesson.resources.find_or_create_by!(title: "Приложение 1 к ПТЭЭП — требования к группам допуска") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "Межотраслевые правила по охране труда (ПОТ Р М-016-2001)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = electrician.lessons.find_or_create_by!(slug: "pervaya-pomosh") do |l|
  l.title = "Первая помощь при поражении электрическим током"
  l.stage = "Электробезопасность и допуски"
  l.description = "Зачем это нужно: навык оказания первой помощи — обязательное требование для всех групп допуска."
  l.body = "Поражение электрическим током — одна из главных причин гибели на производстве. Каждый электрик обязан знать порядок освобождения пострадавшего от действия тока, правила СЛР и алгоритм вызова скорой помощи."
  l.task = "Изучите инструкцию по оказанию первой помощи из РД 153-34.0-03.702-99. Отработайте на манекене (или партнёре) алгоритм: обесточить → оценить состояние → СЛР → вызов 112."
  l.position = 3
end
lesson.resources.find_or_create_by!(title: "РД 153-34.0-03.702-99 — Инструкция по оказанию первой помощи") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end

# ── Правила устройства электроустановок (ПУЭ) ──

lesson = electrician.lessons.find_or_create_by!(slug: "pue-zazemlenie") do |l|
  l.title = "ПУЭ глава 1.7: Заземление и защитные меры"
  l.stage = "Правила устройства электроустановок (ПУЭ)"
  l.description = "Зачем это нужно: неправильное заземление — причина №1 электротравм на объектах."
  l.body = "Глава 1.7 ПУЭ определяет системы заземления (TN-C, TN-S, TN-C-S, TT, IT), требования к заземляющим устройствам и защитным проводникам. Это фундамент безопасности любой электроустановки."
  l.task = "Нарисуйте схемы систем заземления TN-S и TN-C-S. Объясните, почему TN-C-S — самая распространённая система в жилых зданиях РФ. Измерьте сопротивление заземления на вашем объекте (если есть доступ)."
  l.position = 4
end
lesson.resources.find_or_create_by!(title: "ПУЭ 7-е издание, глава 1.7 — Заземление и защитные меры") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р 50571.5.54-2013 — Заземляющие устройства") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 2
end

lesson = electrician.lessons.find_or_create_by!(slug: "pue-provodka") do |l|
  l.title = "ПУЭ глава 2.1: Электропроводки"
  l.stage = "Правила устройства электроустановок (ПУЭ)"
  l.description = "Зачем это нужно: выбор сечения провода и способа прокладки — ежедневная задача электрика."
  l.body = "Глава 2.1 ПУЭ охватывает классификацию электропроводок, выбор сечения проводников по допустимому нагреву и потерям напряжения, способы прокладки (открытая, скрытая, в трубах, в кабель-каналах)."
  l.task = "Рассчитайте сечение медного кабеля для линии: однофазная нагрузка 5 кВт, длина 25 м, допустимые потери напряжения 5%. Обоснуйте выбор по таблицам ПУЭ."
  l.position = 5
end
lesson.resources.find_or_create_by!(title: "ПУЭ 7-е издание, глава 2.1 — Электропроводки") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р 50571.5.52-2011 — Выбор и монтаж электрооборудования. Электропроводки") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = electrician.lessons.find_or_create_by!(slug: "pue-osveshchenie") do |l|
  l.title = "ПУЭ глава 6.1: Освещение"
  l.stage = "Правила устройства электроустановок (ПУЭ)"
  l.description = "Зачем это нужно: монтаж освещения — одна из самых частых задач на объекте."
  l.body = "Глава 6.1 ПУЭ регламентирует устройство осветительных установок: нормы освещённости, выбор светильников, групповые сети освещения, аварийное и эвакуационное освещение. Дополняется СП 52.13330 (нормы освещённости)."
  l.task = "Спроектируйте освещение для помещения 6×4 м (офис): определите норму освещённости по СП 52.13330, рассчитайте количество светильников, нарисуйте схему групповой сети."
  l.position = 6
end
lesson.resources.find_or_create_by!(title: "ПУЭ 7-е издание, глава 6.1 — Освещение") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "СП 52.13330.2016 — Естественное и искусственное освещение") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = electrician.lessons.find_or_create_by!(slug: "gost-r-50571") do |l|
  l.title = "ГОСТ Р 50571: Электроустановки зданий"
  l.stage = "Правила устройства электроустановок (ПУЭ)"
  l.description = "Зачем это нужно: серия ГОСТ Р 50571 — российская адаптация международного стандарта IEC 60364, знание обязательно для проектирования."
  l.body = "Серия ГОСТ Р 50571 (более 30 частей) охватывает все аспекты электроустановок зданий: от общих принципов до конкретных требований к различным помещениям. Ключевые части: 50571.3 (общие характеристики), 50571.4.41 (защита от поражения), 50571.4.43 (защита от сверхтоков)."
  l.task = "Изучите ГОСТ Р 50571.4.41 (защита от поражения электрическим током). Перечислите все меры защиты, указанные в стандарте. Сравните с требованиями главы 1.7 ПУЭ — найдите 3 различия."
  l.position = 7
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р 50571.4.41-2022 — Защита от поражения электрическим током") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р 50571.4.43-2012 — Защита от сверхтока") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

# ════════════════════════════════════════════
# Сварщик НАКС
# ════════════════════════════════════════════

welder = Path.find_or_create_by!(slug: "svarshchik") do |p|
  p.title = "Сварщик"
  p.description = "Путь от ученика до аттестованного специалиста НАКС: виды сварки, стандарты качества, подготовка к аттестации. Основан на ГОСТ, РД и требованиях Ростехнадзора."
  p.position = 2
  p.status = "published"
end

# ── Основы сварки и безопасность ──

lesson = welder.lessons.find_or_create_by!(slug: "ohrana-truda-svarka") do |l|
  l.title = "Охрана труда при сварочных работах"
  l.stage = "Основы сварки и безопасность"
  l.description = "Зачем это нужно: сварка — один из самых травмоопасных видов работ. Без знания ОТ вас не допустят к сварочному посту."
  l.body = "Сварочные работы связаны с рисками: ожоги, поражение электрическим током, отравление газами, повреждение зрения ультрафиолетом. ГОСТ 12.3.003 устанавливает общие требования безопасности для сварочных процессов. Изучите разделы по вентиляции, защитным средствам и пожарной безопасности."
  l.task = "Составьте чек-лист проверки сварочного поста перед началом работ (не менее 10 пунктов). Перечислите все обязательные СИЗ для ручной дуговой сварки."
  l.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 12.3.003-86 — Работы электросварочные. Требования безопасности") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "Типовая инструкция по ОТ для электросварщиков (ТИ Р М-075-2003)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = welder.lessons.find_or_create_by!(slug: "vidy-svarki") do |l|
  l.title = "Виды сварки: РДС, полуавтомат, аргонодуговая"
  l.stage = "Основы сварки и безопасность"
  l.description = "Зачем это нужно: выбор способа сварки определяет качество соединения, скорость работы и стоимость. На аттестации НАКС нужно знать все основные методы."
  l.body = "Три основных вида дуговой сварки: РДС (ручная дуговая сварка покрытыми электродами, ГОСТ 5264), полуавтоматическая сварка в защитных газах (MIG/MAG, ГОСТ 14771), аргонодуговая сварка неплавящимся электродом (TIG, ГОСТ 14806). Каждый метод имеет свою область применения, преимущества и ограничения."
  l.task = "Составьте сравнительную таблицу трёх видов сварки (РДС, MIG/MAG, TIG) по критериям: толщина металла, производительность, качество шва, стоимость оборудования, сложность освоения."
  l.position = 2
end
lesson.resources.find_or_create_by!(title: "ГОСТ 5264-80 — Ручная дуговая сварка. Соединения сварные") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 14771-76 — Дуговая сварка в защитном газе. Соединения сварные") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 2
end
lesson.resources.find_or_create_by!(title: "ГОСТ 14806-80 — Дуговая сварка алюминия в инертных газах") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 3
end

lesson = welder.lessons.find_or_create_by!(slug: "svarochnye-materialy") do |l|
  l.title = "Сварочные материалы: электроды, проволока, газы"
  l.stage = "Основы сварки и безопасность"
  l.description = "Зачем это нужно: неправильный выбор материалов — причина дефектов шва и отбраковки на контроле."
  l.body = "Сварочные электроды классифицируются по типу покрытия (ГОСТ 9466) и назначению (ГОСТ 9467 — для углеродистых и низколегированных сталей). Сварочная проволока — по ГОСТ 2246. Защитные газы (аргон, углекислый газ, смеси) — по ГОСТ 10157 и ГОСТ 8050. Правильный подбор материалов под конкретную марку стали и условия эксплуатации — ключевой навык сварщика."
  l.task = "Определите марку электрода для сварки стали Ст3 толщиной 8 мм в нижнем положении. Обоснуйте выбор диаметра электрода и силы тока по рекомендациям ГОСТ 9467."
  l.position = 3
end
lesson.resources.find_or_create_by!(title: "ГОСТ 9466-75 — Электроды покрытые. Общие технические условия") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 9467-75 — Электроды для сварки углеродистых и низколегированных сталей") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 2
end

# ── Стандарты и аттестация НАКС ──

lesson = welder.lessons.find_or_create_by!(slug: "rd-03-615-attestaciya") do |l|
  l.title = "РД 03-615-03: Порядок аттестации сварщиков"
  l.stage = "Стандарты и аттестация НАКС"
  l.description = "Зачем это нужно: без аттестации НАКС вас не допустят к сварке на объектах, подконтрольных Ростехнадзору (трубопроводы, сосуды давления, металлоконструкции)."
  l.body = "РД 03-615-03 определяет порядок аттестации сварщиков и специалистов сварочного производства. Четыре уровня аттестации: I (сварщик), II (мастер), III (технолог), IV (инженер). Аттестация включает теоретический экзамен и практическое испытание — сварку контрольных образцов с последующим контролем качества."
  l.task = "Изучите требования к I уровню аттестации НАКС. Составьте список документов для подачи заявки. Определите ближайший аттестационный центр НАКС в вашем регионе."
  l.position = 4
end
lesson.resources.find_or_create_by!(title: "РД 03-615-03 — Порядок применения сварочных технологий при изготовлении и ремонте") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "Сайт НАКС — реестр аттестационных центров") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "tool"
  r.required = false
  r.position = 2
end

lesson = welder.lessons.find_or_create_by!(slug: "gost-iso-9606") do |l|
  l.title = "ГОСТ Р ISO 9606-1: Квалификационные испытания сварщиков"
  l.stage = "Стандарты и аттестация НАКС"
  l.description = "Зачем это нужно: международный стандарт квалификации — нужен для работы на объектах с международными требованиями (ASME, EN)."
  l.body = "ГОСТ Р ISO 9606-1 — российская адаптация международного стандарта ISO 9606-1. Определяет методику квалификационных испытаний сварщиков при сварке сталей. Включает требования к контрольным образцам, диапазон квалификации (толщины, положения, типы швов), методы контроля и критерии приёмки."
  l.task = "Сравните требования ГОСТ Р ISO 9606-1 и РД 03-615-03: в чём основные различия? Какие виды контроля качества применяются при квалификационных испытаниях?"
  l.position = 5
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р ISO 9606-1-2014 — Квалификационное испытание сварщиков. Сварка плавлением. Стали") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ASME Section IX — Qualification Standard for Welding (справочно)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.position = 2
end

lesson = welder.lessons.find_or_create_by!(slug: "kontrol-kachestva-shvov") do |l|
  l.title = "Контроль качества сварных швов"
  l.stage = "Стандарты и аттестация НАКС"
  l.description = "Зачем это нужно: умение читать результаты контроля и понимать дефекты — обязательно для аттестации и карьерного роста."
  l.body = "Основные методы неразрушающего контроля сварных соединений: визуальный и измерительный (РД 03-606-03), ультразвуковой (ГОСТ Р 55724), радиографический (ГОСТ 7512), капиллярный и магнитопорошковый. Типичные дефекты: поры, непровар, подрез, трещины, шлаковые включения. ГОСТ 30242 — классификация дефектов."
  l.task = "Изучите ГОСТ 30242 (классификация дефектов). Нарисуйте схемы 5 основных дефектов сварного шва. Для каждого укажите: причину возникновения и метод обнаружения."
  l.position = 6
end
lesson.resources.find_or_create_by!(title: "ГОСТ 30242-97 — Дефекты соединений при сварке. Классификация") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "РД 03-606-03 — Визуальный и измерительный контроль") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 2
end
lesson.resources.find_or_create_by!(title: "ГОСТ 7512-82 — Контроль неразрушающий. Радиографический метод") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 3
end

# ════════════════════════════════════════════
# Сантехник
# ════════════════════════════════════════════

plumber = Path.find_or_create_by!(slug: "santehnik") do |p|
  p.title = "Сантехник"
  p.description = "От бытовых систем до промышленных объектов: водоснабжение, канализация, отопление. Основан на действующих СП, СНиП и ГОСТ."
  p.position = 3
  p.status = "published"
end

# ── Водоснабжение и канализация ──

lesson = plumber.lessons.find_or_create_by!(slug: "sp-30-vodosnabzhenie") do |l|
  l.title = "СП 30.13330: Внутренний водопровод и канализация"
  l.stage = "Водоснабжение и канализация"
  l.description = "Зачем это нужно: это главный нормативный документ для любого сантехника — без него невозможно грамотно спроектировать или смонтировать систему."
  l.body = "СП 30.13330 (актуализированная редакция СНиП 2.04.01-85*) устанавливает нормы проектирования внутренних систем холодного и горячего водоснабжения, канализации и водостоков. Ключевые разделы: расчёт расходов воды, гидравлический расчёт трубопроводов, требования к материалам и оборудованию."
  l.task = "Рассчитайте расход воды для квартиры с 4 санитарными приборами (ванна, умывальник, мойка, унитаз) по методике СП 30.13330. Определите диаметр подводящего трубопровода."
  l.position = 1
end
lesson.resources.find_or_create_by!(title: "СП 30.13330.2020 — Внутренний водопровод и канализация зданий") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "СНиП 2.04.01-85* — Внутренний водопровод и канализация (историческая редакция)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = plumber.lessons.find_or_create_by!(slug: "materialy-trub") do |l|
  l.title = "Материалы труб: полипропилен, металлопластик, медь, сталь"
  l.stage = "Водоснабжение и канализация"
  l.description = "Зачем это нужно: выбор материала трубы — это баланс между стоимостью, долговечностью и условиями эксплуатации. Ошибка стоит затопленных соседей."
  l.body = "Основные материалы для внутренних трубопроводов: полипропилен (ПП, ГОСТ 32415 — самый популярный для водоснабжения), металлопластик (ГОСТ Р 53630), медь (ГОСТ Р 52318 — премиум), оцинкованная сталь (ГОСТ 3262 — для стояков). Каждый материал имеет свои температурные ограничения, срок службы и требования к монтажу."
  l.task = "Составьте сравнительную таблицу 4 материалов труб по критериям: максимальная температура, рабочее давление, срок службы, стоимость погонного метра (Ø20), сложность монтажа. Какой материал вы выберете для горячего водоснабжения в квартире и почему?"
  l.position = 2
end
lesson.resources.find_or_create_by!(title: "ГОСТ 32415-2013 — Трубы напорные из полипропилена") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 3262-75 — Трубы стальные водогазопроводные") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = plumber.lessons.find_or_create_by!(slug: "montazh-vodoprovoda") do |l|
  l.title = "Монтаж внутреннего водопровода"
  l.stage = "Водоснабжение и канализация"
  l.description = "Зачем это нужно: грамотный монтаж — это отсутствие протечек, правильное давление и комфорт жильцов на десятилетия."
  l.body = "Порядок монтажа внутреннего водопровода: разметка → крепление труб → сборка стояков → монтаж разводки → подключение приборов → опрессовка. Ключевые моменты: уклоны, компенсация температурного расширения, размещение запорной арматуры, крепление труб к стенам (СП 73.13330)."
  l.task = "Нарисуйте схему разводки водоснабжения для ванной комнаты (ванна, раковина, стиральная машина). Укажите диаметры труб, расположение запорных кранов, высоты вывода точек подключения."
  l.position = 3
end
lesson.resources.find_or_create_by!(title: "СП 73.13330.2016 — Внутренние санитарно-технические системы зданий") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end

lesson = plumber.lessons.find_or_create_by!(slug: "kanalizaciya-montazh") do |l|
  l.title = "Монтаж канализации: уклоны, гидрозатворы, стояки"
  l.stage = "Водоснабжение и канализация"
  l.description = "Зачем это нужно: канализация работает самотёком — неправильный уклон или отсутствие гидрозатвора означает засоры и запах."
  l.body = "Внутренняя канализация работает по принципу самотёка: уклон для Ø50 мм — 0,03, для Ø110 мм — 0,02 (СП 30.13330). Каждый прибор подключается через гидрозатвор (сифон) высотой не менее 50 мм. Стояки вентилируются через вытяжную часть, выведенную выше кровли. Ревизии и прочистки — через каждые 15 м на горизонтальных участках."
  l.task = "Спроектируйте канализацию для санузла: унитаз + раковина + ванна. Укажите диаметры, уклоны, расположение гидрозатворов. Нарисуйте аксонометрическую схему."
  l.position = 4
end
lesson.resources.find_or_create_by!(title: "СП 30.13330.2020 — раздел «Канализация»") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 32414-2013 — Трубы канализационные из полипропилена") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

# ── Отопление ──

lesson = plumber.lessons.find_or_create_by!(slug: "sp-60-otoplenie") do |l|
  l.title = "СП 60.13330: Системы отопления"
  l.stage = "Отопление"
  l.description = "Зачем это нужно: отопление — самая дорогая инженерная система здания. Ошибки в расчётах стоят десятки тысяч в перерасходе тепла."
  l.body = "СП 60.13330 (актуализированная редакция СНиП 41-01-2003) — основной документ по проектированию систем отопления. Охватывает: классификацию систем (однотрубные, двухтрубные, коллекторные), расчёт тепловых потерь, подбор отопительных приборов, гидравлический расчёт."
  l.task = "Рассчитайте теплопотери комнаты 5×4 м (наружная стена с окном, 2 этаж, Москва) по укрупнённым показателям. Подберите количество секций алюминиевого радиатора."
  l.position = 5
end
lesson.resources.find_or_create_by!(title: "СП 60.13330.2020 — Отопление, вентиляция и кондиционирование воздуха") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "СП 50.13330.2012 — Тепловая защита зданий") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = plumber.lessons.find_or_create_by!(slug: "montazh-otopleniya") do |l|
  l.title = "Монтаж систем отопления: радиаторы, тёплый пол, котлы"
  l.stage = "Отопление"
  l.description = "Зачем это нужно: монтаж отопления — высокооплачиваемая работа. Один правильно установленный котёл обогревает целый дом."
  l.body = "Основные типы систем: радиаторное отопление (настенные, напольные), тёплый пол (водяной — в стяжку или сухим методом), конвекторы. Монтаж включает: установку котла → обвязка → прокладка магистралей → установка приборов → опрессовка → пусконаладка. Ключевые нюансы: воздухоудаление, балансировка системы, группа безопасности котла."
  l.task = "Нарисуйте схему обвязки настенного газового котла: группа безопасности, расширительный бак, циркуляционный насос, запорная арматура. Укажите диаметры труб."
  l.position = 6
end
lesson.resources.find_or_create_by!(title: "СП 73.13330.2016 — раздел «Отопление»") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 31311-2022 — Приборы отопительные. Общие технические условия") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = plumber.lessons.find_or_create_by!(slug: "ohrana-truda-santehnika") do |l|
  l.title = "Охрана труда при санитарно-технических работах"
  l.stage = "Отопление"
  l.description = "Зачем это нужно: работа с трубами под давлением, горячей водой и газовым оборудованием — требует знания ОТ для допуска на объект."
  l.body = "Основные риски при сантехнических работах: ожоги горячей водой и паром, поражение электрическим током (электроинструмент), падение с высоты (работа на стояках), травмы при работе с инструментом. СНиП 12-03-2001 и СНиП 12-04-2002 устанавливают требования безопасности при строительных и монтажных работах."
  l.task = "Составьте инструкцию по охране труда при замене стояка горячего водоснабжения в жилом доме. Укажите этапы работ, необходимые СИЗ, порядок отключения и опрессовки."
  l.position = 7
end
lesson.resources.find_or_create_by!(title: "СНиП 12-03-2001 — Безопасность труда в строительстве. Часть 1") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "СНиП 12-04-2002 — Безопасность труда в строительстве. Часть 2") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

# ════════════════════════════════════════════
# Инженер АСУ ТП (ПЛК + SCADA)
# ════════════════════════════════════════════

acs = Path.find_or_create_by!(slug: "inzhener-asu-tp") do |p|
  p.title = "Инженер АСУ ТП"
  p.description = "Программирование промышленных контроллеров и SCADA-систем: от релейной логики до полноценных проектов автоматизации. Основан на МЭК 61131-3, стандартах промышленной связи и практике Siemens/ОВЕН."
  p.position = 4
  p.status = "published"
end

# ── Основы автоматизации ──

lesson = acs.lessons.find_or_create_by!(slug: "osnovy-asu-tp") do |l|
  l.title = "Что такое АСУ ТП: структура, уровни, задачи"
  l.stage = "Основы автоматизации"
  l.description = "Зачем это нужно: без понимания архитектуры АСУ ТП невозможно грамотно спроектировать даже простую систему управления."
  l.body = "АСУ ТП (автоматизированная система управления технологическим процессом) строится по трёхуровневой модели: полевой уровень (датчики и исполнительные механизмы), уровень управления (ПЛК), верхний уровень (SCADA/HMI, серверы, АРМ). ГОСТ 34.601-90 определяет стадии создания АСУ. Каждый уровень имеет свои протоколы, оборудование и требования к надёжности."
  l.task = "Нарисуйте трёхуровневую структуру АСУ ТП для водоочистной станции. Укажите на каждом уровне: типы оборудования, протоколы связи, задачи. Определите, какие датчики нужны для контроля pH, расхода и уровня воды."
  l.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 34.601-90 — Автоматизированные системы. Стадии создания") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р МЭК 62443-1-1 — Промышленные сети. Общие концепции") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = acs.lessons.find_or_create_by!(slug: "chtenie-elektricheskih-shem") do |l|
  l.title = "Чтение электрических схем автоматизации"
  l.stage = "Основы автоматизации"
  l.description = "Зачем это нужно: схема — это язык общения между проектировщиком, программистом ПЛК и наладчиком. Без умения читать схемы вы не запрограммируете ни один контроллер."
  l.body = "Основные типы схем в АСУ ТП: функциональная схема автоматизации (P&ID, ГОСТ 21.208), принципиальная электрическая схема (ГОСТ 2.702), схема внешних проводок. Обозначения приборов и средств автоматизации по ГОСТ 21.208: буквенные коды (T — температура, P — давление, L — уровень, F — расход), функциональные признаки (I — показание, R — регистрация, C — регулирование, A — сигнализация)."
  l.task = "Возьмите P&ID-схему любого технологического процесса (или нарисуйте свою для бака с подогревом воды). Идентифицируйте все приборы по буквенным кодам ГОСТ 21.208. Составьте спецификацию: какой датчик, какой сигнал (4–20 мА, дискретный), куда подключается."
  l.position = 2
end
lesson.resources.find_or_create_by!(title: "ГОСТ 21.208-2013 — Обозначения условные приборов и средств автоматизации") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ГОСТ 2.702-2011 — Правила выполнения электрических схем") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 2
end

lesson = acs.lessons.find_or_create_by!(slug: "mek-61131-3") do |l|
  l.title = "МЭК 61131-3: Стандарт языков программирования ПЛК"
  l.stage = "Основы автоматизации"
  l.description = "Зачем это нужно: МЭК 61131-3 — единый стандарт для всех ПЛК. Знание стандарта позволяет переходить между платформами (Siemens, ОВЕН, Schneider, ABB) без переучивания."
  l.body = "МЭК 61131-3 определяет пять языков программирования ПЛК: LD (Ladder Diagram — релейные диаграммы, самый популярный), FBD (Function Block Diagram — функциональные блоки), ST (Structured Text — текстовый, похож на Pascal), IL (Instruction List — ассемблер, устаревает), SFC (Sequential Function Chart — последовательностные диаграммы, для технологических рецептов). Стандарт также определяет типы данных, организацию программы (POU — Program Organization Unit) и конфигурацию ресурсов."
  l.task = "Напишите одну и ту же логику на трёх языках (LD, FBD, ST): управление насосом с двумя условиями пуска (уровень в баке ниже 30% И нет аварии) и одним условием останова (уровень выше 80% ИЛИ аварийный останов). Сравните читаемость."
  l.position = 3
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р МЭК 61131-3-2016 — Языки программирования контроллеров") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "IEC 61131-3 — Programmable controllers. Programming languages (оригинал, EN)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.position = 2
end

# ── Программирование ПЛК ──

lesson = acs.lessons.find_or_create_by!(slug: "plk-ladder-diagram") do |l|
  l.title = "Ladder Diagram (LD): релейная логика на ПЛК"
  l.stage = "Программирование ПЛК"
  l.description = "Зачем это нужно: LD — самый распространённый язык в промышленности. 70% программ ПЛК в СНГ написаны на LD, потому что его понимают и программисты, и электрики."
  l.body = "Ladder Diagram — графический язык, имитирующий релейные схемы. Основные элементы: нормально открытый контакт (NO), нормально закрытый контакт (NC), катушка (выход), таймеры (TON, TOF, TP), счётчики (CTU, CTD), компараторы. Программа выполняется слева направо, сверху вниз. Каждая «ступенька» (rung) — одно логическое условие с результатом."
  l.task = "Напишите программу на LD для автоматического управления освещением: кнопка ПУСК включает свет, кнопка СТОП выключает, датчик движения удерживает свет включённым 5 минут после последнего срабатывания. Нарисуйте LD-диаграмму, укажите адреса входов/выходов."
  l.position = 4
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р МЭК 61131-3-2016 — раздел «LD»") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "OpenPLC — открытая среда для практики LD/ST/FBD") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "tool"
  r.required = false
  r.position = 2
end

lesson = acs.lessons.find_or_create_by!(slug: "plk-structured-text") do |l|
  l.title = "Structured Text (ST): текстовый язык для сложной логики"
  l.stage = "Программирование ПЛК"
  l.description = "Зачем это нужно: ST необходим для вычислений, PID-регулирования и работы с массивами — того, что неудобно делать в LD."
  l.body = "Structured Text — текстовый язык, похожий на Pascal. Поддерживает: условия (IF/ELSIF/ELSE, CASE), циклы (FOR, WHILE, REPEAT), функции и функциональные блоки, работу с массивами и структурами. Типичные применения: PID-регулирование, математические расчёты, обработка рецептов, управление последовательностями (совместно с SFC). В современных проектах ST часто сочетается с LD: простая логика на LD, вычисления на ST."
  l.task = "Напишите на ST функциональный блок PID-регулятора температуры: вход — текущая температура (REAL), уставка (REAL), выход — управляющее воздействие 0–100% (REAL). Реализуйте пропорциональную и интегральную составляющие. Добавьте ограничение выхода (anti-windup)."
  l.position = 5
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р МЭК 61131-3-2016 — раздел «ST»") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "CODESYS — среда разработки для практики ST (бесплатный симулятор)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "tool"
  r.required = false
  r.position = 2
end

lesson = acs.lessons.find_or_create_by!(slug: "promyshlennye-seti") do |l|
  l.title = "Промышленные сети: Modbus, PROFINET, OPC UA"
  l.stage = "Программирование ПЛК"
  l.description = "Зачем это нужно: ПЛК не работает в изоляции — он обменивается данными с датчиками, частотниками, другими ПЛК и SCADA. Без понимания протоколов вы не настроите связь."
  l.body = "Основные промышленные протоколы: Modbus RTU/TCP (самый распространённый, простой, ГОСТ Р МЭК 61158), PROFINET/PROFIBUS (Siemens-экосистема), EtherNet/IP (Rockwell), OPC UA (универсальный, IEC 62541 — будущее промышленной связи). Modbus работает по принципу master-slave: ПЛК (master) опрашивает датчики и частотники (slave) по адресам регистров (Holding Registers, Input Registers, Coils)."
  l.task = "Составьте таблицу Modbus-регистров для системы из 3 датчиков (температура, давление, расход) и 1 частотного привода. Укажите: адрес slave, тип регистра, адрес регистра, описание, единицы измерения, масштабирование."
  l.position = 6
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р МЭК 61158-2014 — Промышленные сети. Спецификация полевой шины") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "Modbus Application Protocol Specification v1.1b3 (modbus.org)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.position = 2
end
lesson.resources.find_or_create_by!(title: "IEC 62541 — OPC Unified Architecture (обзор, EN)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.position = 3
end

# ── SCADA-системы ──

lesson = acs.lessons.find_or_create_by!(slug: "scada-osnovy") do |l|
  l.title = "Введение в SCADA: архитектура, функции, выбор платформы"
  l.stage = "SCADA-системы"
  l.description = "Зачем это нужно: SCADA — это глаза и руки оператора. Без визуализации процесса оператор работает вслепую."
  l.body = "SCADA (Supervisory Control And Data Acquisition) — система диспетчерского управления. Основные функции: визуализация (мнемосхемы процесса), архивирование (тренды, историческая база), алармы (аварийные и предупредительные), отчёты, удалённый доступ. Популярные SCADA в СНГ: MasterSCADA (российская, для критической инфраструктуры), WinCC (Siemens), Citect (Schneider), Ignition (Inductive Automation — веб-архитектура). Выбор зависит от платформы ПЛК, требований к импортозамещению и масштаба проекта."
  l.task = "Сравните 3 SCADA-системы (MasterSCADA, WinCC, Ignition) по критериям: поддерживаемые ПЛК, лицензирование, стоимость на 500 тегов, поддержка веб-клиентов, наличие в реестре российского ПО. Какую систему вы выберете для водоканала и почему?"
  l.position = 7
end
lesson.resources.find_or_create_by!(title: "ГОСТ 34.003-90 — Автоматизированные системы. Термины и определения") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "Реестр российского ПО — раздел «АСУ ТП и SCADA»") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "tool"
  r.required = false
  r.country_code = "RU"
  r.position = 2
end

lesson = acs.lessons.find_or_create_by!(slug: "scada-mnemoschemy") do |l|
  l.title = "Проектирование мнемосхем: от P&ID к экрану оператора"
  l.stage = "SCADA-системы"
  l.description = "Зачем это нужно: плохая мнемосхема — это пропущенная авария. Оператор должен за 3 секунды понять состояние процесса."
  l.body = "Мнемосхема — графическое представление технологического процесса на экране оператора. Принципы проектирования (ISA-101, ANSI/ISA-18.2): серый фон (не чёрный — снижает утомляемость), цвет только для отклонений (красный — авария, жёлтый — предупреждение, зелёный — норма используется минимально), динамические элементы (уровни в баках, положения задвижек, тренды в реальном времени). Навигация: иерархия от обзорного экрана к детальным."
  l.task = "Спроектируйте мнемосхему для насосной станции: 2 насоса (рабочий + резервный), бак-накопитель с датчиком уровня, задвижка на выходе. Нарисуйте макет экрана с учётом принципов ISA-101. Укажите, какие динамические элементы нужны и какие цвета для каких состояний."
  l.position = 8
end
lesson.resources.find_or_create_by!(title: "ISA-101.01-2015 — Human Machine Interfaces for Process Automation") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "ANSI/ISA-18.2 — Management of Alarm Systems (основы алармов)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.position = 2
end

lesson = acs.lessons.find_or_create_by!(slug: "scada-alarmy-trendy") do |l|
  l.title = "Алармы, тренды и архивирование данных"
  l.stage = "SCADA-системы"
  l.description = "Зачем это нужно: правильно настроенные алармы спасают оборудование и жизни. Плохо настроенные — приводят к alarm flooding, когда оператор игнорирует все сигналы."
  l.body = "Система алармов (ANSI/ISA-18.2): приоритеты (критический, высокий, средний, низкий), состояния (активен, подтверждён, снят), журналирование. Alarm flooding — когда более 10 алармов в минуту: оператор физически не успевает реагировать. Тренды: реальное время (для наблюдения) и исторические (для анализа). Архивирование: циклическое или по событиям, сжатие данных (deadband), типичный объём — 1–5 лет для критических параметров."
  l.task = "Спроектируйте систему алармов для котельной: определите 10 аварийных параметров (температура, давление, уровень, пламя и т.д.), назначьте приоритеты, определите уставки и гистерезис. Рассчитайте объём архива при записи 50 параметров с интервалом 1 секунда за 1 год."
  l.position = 9
end
lesson.resources.find_or_create_by!(title: "ANSI/ISA-18.2-2016 — Management of Alarm Systems for the Process Industries") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "EEMUA 191 — Alarm Systems: A Guide to Design, Management and Procurement") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.position = 2
end

lesson = acs.lessons.find_or_create_by!(slug: "kiberbezopasnost-asu") do |l|
  l.title = "Кибербезопасность АСУ ТП"
  l.stage = "SCADA-системы"
  l.description = "Зачем это нужно: атака на АСУ ТП — это не утечка данных, а физическое разрушение оборудования и угроза жизни. После Stuxnet это понимает весь мир."
  l.body = "Промышленные системы всё чаще подключаются к корпоративным сетям и интернету. Стандарт МЭК 62443 (серия из 14 частей) определяет требования к кибербезопасности АСУ ТП: зоны и кондуиты (сегментация сети), уровни безопасности (SL1–SL4), управление доступом, мониторинг. В России — приказы ФСТЭК (№31 от 2014) и ФЗ-187 о критической информационной инфраструктуре."
  l.task = "Нарисуйте схему сети АСУ ТП с разделением на зоны по МЭК 62443: полевой уровень, уровень управления, DMZ, корпоративная сеть. Укажите, какие средства защиты (firewall, diode, IDS) размещаются на каждой границе."
  l.position = 10
end
lesson.resources.find_or_create_by!(title: "ГОСТ Р МЭК 62443-2-1 — Промышленные сети. Требования к системе менеджмента") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 1
end
lesson.resources.find_or_create_by!(title: "Приказ ФСТЭК №31 — Требования к защите АСУ ТП") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = true
  r.country_code = "RU"
  r.position = 2
end
lesson.resources.find_or_create_by!(title: "IEC 62443-3-3 — System security requirements and security levels (EN)") do |r|
  r.url = "https://example.com/placeholder"
  r.kind = "document"
  r.required = false
  r.position = 3
end

puts "Seeded: #{Path.count} paths, #{Lesson.count} lessons, #{Resource.count} resources"
