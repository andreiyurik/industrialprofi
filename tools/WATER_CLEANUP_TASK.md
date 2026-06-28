# Задание: вычистить «воду» из уроков (для исполнителя — Sonnet)

Одноразовая задача по чистке контента. **Ты редактируешь файлы сидов `.md`** в
`db/seeds/curriculum/`. НЕ коммить (git-политика репозитория — коммиты делает
человек). После правок оставь дерево на ревью.

Контекст и правила качества — в `tools/AUTHOR_PROFESSION.md` (рубрика тела урока)
и `tools/QA_REVIEW.md` (критерий «Вода и дублирование»). Эта чистка — следствие
решения: **блок «Что ты сможешь после урока» убран из скелета урока как вода.**

---

## Что такое «вода» здесь (что удалять)

1. **Главная цель — блок «Что ты сможешь после урока»** (и варианты: «Что ты
   узнаешь», «Чему ты научишься», «После урока ты сможешь», «В этом уроке ты»).
   Обычно это `## ...` заголовок + маркированный список в самом начале тела (сразу
   после абзаца ЗАЧЕМ). **Удаляй целиком**, потому что он почти всегда дублирует
   абзац ЗАЧЕМ вверху и/или блок `> [!ПРОВЕРЬ]` внизу.
   - **Исключение (оставить):** только если пункты дают **конкретные проверяемые
     умения**, которых НЕ видно из ЗАЧЕМ и заголовка урока (напр. «рассчитать
     сечение по таблице ПУЭ 1.3.4»), и они НЕ повторяют `[!ПРОВЕРЬ]`. Расплывчатые
     «понять, что такое X» / «разобраться в теме» — это вода, удалять.
   - Суди строго: по умолчанию блок на удаление.
2. Вводные-пустышки: «как известно», «в этом уроке мы рассмотрим», «в данном
   уроке», «стоит отметить», «важно понимать, что» (если дальше нет конкретики),
   лозунги о важности темы. (Беглый grep показал, что таких почти нет — но проверяй
   по ходу.)
3. Повторы — одна и та же мысль разными словами в пределах урока.
4. Предложения-наполнители, которые не объясняют и не ведут к действию.

**Принцип: режь безжалостно, но не трогай полезное.** Цель — максимум пользы при
минимуме воды. Лучше оставить чистый плотный текст, чем удалить смысл.

---

## Инварианты формата — НЕ СЛОМАТЬ

Формат файла: `frontmatter` между `---` → абзац **ЗАЧЕМ** → `---` → тело Markdown
(в т.ч. блоки `> [!ВАЖНО/ОПАСНО/СОВЕТ/ПРИМЕР/ПРОВЕРЬ]` и раздел `## Задание`).

- **Не трогай** frontmatter, абзац ЗАЧЕМ, и три разделителя `---` (их ровно столько,
  сколько было). Внутри тела `---` как разделитель НЕ используется.
- **Не меняй** имя файла (`slug`), `position`, `title`.
- Удаляя блок, убери и его заголовок, и список, и образовавшиеся двойные пустые
  строки — чтобы текст начинался чисто (обычно сразу с ментальной модели / сути).
- Раздел `## Задание` и блоки `[!ПРОВЕРЬ]` оставляй на месте.

После правок (опционально, для проверки загрузки): `bin/rails content:import` —
импортёр обновляет нетронутые черновики на месте. НЕ коммить.

---

## Часть A — удалить outcomes-блок: 72 файла

**ИСТОЧНИК ИСТИНЫ — эта команда** (перечисленный ниже список неполный, см. ⚠️):

```bash
grep -rlE '## (Что ты (сможешь|узнаешь|поймёшь|освоишь)|Чему ты научишься|После (этого )?урока)' db/seeds/curriculum --include=*.md
```

Найдено **72 файла**. Два варианта заголовка: `## Что ты поймёшь` (46) и
`## Что ты сможешь` (26). В каждом файле найди этот раздел (заголовок + список под
ним до следующего `##`) и примени правило выше — по умолчанию удалить целиком,
оставить только редкое исключение с конкретными проверяемыми умениями.

> ⚠️ **Перечисленный ниже список (45 файлов) — НЕПОЛНЫЙ**: он покрывает только
> вариант «Что ты сможешь» и часть «поймёшь». **Бери файлы из grep-команды выше**,
> а список ниже — лишь как ориентир по структуре каталогов.

### elektrik (часть; полный список — из grep)
- `elektrik/03-pue-i-ustroystvo/01-pue-struktura/01-chto-takoe-pue.md`
- `elektrik/03-pue-i-ustroystvo/04-zashchitnye-apparaty/03-uzip-i-rele-napryazheniya.md`
- `elektrik/04-montazh/04-elektroshchity/02-sborka-kvartirnego-shchita.md`
- `elektrik/06-ekspluataciya-i-karera/01-pteep/01-pteep-prikaz-811.md`
- `elektrik/06-ekspluataciya-i-karera/02-operativnaya-rabota/01-operativnye-obkhody-i-zhurnal.md`

### inzhener-asu-tp (28)
- `inzhener-asu-tp/01-osnovy-i-kipia/01-osnovy-professii-i-arhitektura/chtenie-shem-avtomatizacii-fsa.md`
- `inzhener-asu-tp/01-osnovy-i-kipia/01-osnovy-professii-i-arhitektura/chto-takoe-asutp-urovni-struktura.md`
- `inzhener-asu-tp/01-osnovy-i-kipia/01-osnovy-professii-i-arhitektura/zhiznennyy-cikl-i-dokumentaciya.md`
- `inzhener-asu-tp/01-osnovy-i-kipia/02-polevoy-uroven-kipia/datchiki-davleniya-rashoda-urovnya.md`
- `inzhener-asu-tp/01-osnovy-i-kipia/02-polevoy-uroven-kipia/datchiki-temperatury.md`
- `inzhener-asu-tp/01-osnovy-i-kipia/02-polevoy-uroven-kipia/ispolnitelnye-mehanizmy-i-chastotniki.md`
- `inzhener-asu-tp/01-osnovy-i-kipia/02-polevoy-uroven-kipia/metrologiya-poverka-pogreshnost.md`
- `inzhener-asu-tp/01-osnovy-i-kipia/02-polevoy-uroven-kipia/signaly-4-20ma-i-diskretnye.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/01-programmirovanie-plk/apparatnaya-konfiguraciya-i-rezervirovanie-plk.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/01-programmirovanie-plk/chto-takoe-plk-cikl-skanirovaniya.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/01-programmirovanie-plk/ladder-diagram-ld.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/01-programmirovanie-plk/structured-text-st.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/01-programmirovanie-plk/taymery-schetchiki-tipovye-bloki.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/01-programmirovanie-plk/yazyki-mek-61131-3.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/02-regulirovanie/obratnaya-svyaz-i-kontury-upravleniya.md`
- `inzhener-asu-tp/02-plk-i-regulirovanie/02-regulirovanie/pid-regulirovanie.md`
- `inzhener-asu-tp/03-promyshlennye-seti/01-promyshlennye-seti/modbus-registry-adresaciya.md`
- `inzhener-asu-tp/03-promyshlennye-seti/01-promyshlennye-seti/osnovy-setey-osi-ip-kabeli.md`
- `inzhener-asu-tp/03-promyshlennye-seti/01-promyshlennye-seti/profibus-profinet-opc-ua.md`
- `inzhener-asu-tp/03-promyshlennye-seti/01-promyshlennye-seti/promyshlennye-seti-rs485-master-slave.md`
- `inzhener-asu-tp/04-scada/01-scada/alarmy-trendy-arhivy.md`
- `inzhener-asu-tp/04-scada/01-scada/mnemoshemy.md`
- `inzhener-asu-tp/04-scada/01-scada/scada-osnovy-tegi-arhitektura.md`
- `inzhener-asu-tp/05-proektirovanie-pnr/01-proektirovanie-montazh-pnr/montazh-shkafa-avtomatizacii.md`
- `inzhener-asu-tp/05-proektirovanie-pnr/01-proektirovanie-montazh-pnr/proektirovanie-asutp-rabochaya-dokumentaciya.md`
- `inzhener-asu-tp/05-proektirovanie-pnr/02-bezopasnost-attestaciya-karera/attestaciya-dopuski-i-karera.md`
- `inzhener-asu-tp/05-proektirovanie-pnr/02-bezopasnost-attestaciya-karera/funkcionalnaya-bezopasnost-paz-sil.md`
- `inzhener-asu-tp/05-proektirovanie-pnr/02-bezopasnost-attestaciya-karera/kiberbezopasnost-asutp.md`

### kipia-aes (12) — все подтверждены к удалению (детали в Части B)
- `kipia-aes/01-professiya-aes-i-pnr/01-professiya-i-karera/aes-professiya-i-napravleniya-atomtehenergo.md`
- `kipia-aes/01-professiya-aes-i-pnr/01-professiya-i-karera/aes-s-chego-nachat.md`
- `kipia-aes/01-professiya-aes-i-pnr/02-kak-ustroena-aes/aes-vver-1200-i-kontury.md`
- `kipia-aes/01-professiya-aes-i-pnr/03-process-pnr/aes-process-pnr-programmy-pmi-priyomka.md`
- `kipia-aes/02-yadernaya-specifika/01-yadernaya-bezopasnost/aes-klassy-bezopasnosti-np-001.md`
- `kipia-aes/02-yadernaya-specifika/01-yadernaya-bezopasnost/aes-radiacionnaya-bezopasnost.md`
- `kipia-aes/02-yadernaya-specifika/02-vodno-himicheskiy-rezhim/aes-vhr-i-analizatory.md`
- `kipia-aes/02-yadernaya-specifika/03-metrologiya-na-aes/aes-metrologiya-na-aes.md`
- `kipia-aes/03-kip-i-zashchity-vver/01-pole-na-vver/aes-kip-na-vver-osobennosti.md`
- `kipia-aes/03-kip-i-zashchity-vver/01-pole-na-vver/aes-uroven-pg-2oo3.md`
- `kipia-aes/03-kip-i-zashchity-vver/02-zashchity-aes/aes-zashchity-2oo3-i-c-and-e.md`
- `kipia-aes/03-kip-i-zashchity-vver/03-rabota-na-ploshchadke/aes-rabota-na-ploshchadke.md`

> `svarshchik` (42 урока) — outcomes-блоков НЕ содержит. Отдельно проверять на этот
> блок не нужно (но см. Часть C про общий фильтр воды).

---

## Часть B — дополнительные находки (kipia-aes, проверено вручную)

Помимо outcomes-блока, в этих уроках есть ещё вода:

- `kipia-aes/.../aes-klassy-bezopasnosti-np-001.md` — раздел «Типовые ошибки»
  частично **повторяет** уже сказанное в `[!ВАЖНО]` (класс 4 ≠ «второй сорт») и в
  объяснении 2oo3 → **сократить** до неповторяющегося.
- `kipia-aes/.../aes-rabota-na-ploshchadke.md` — мысль «русский — только внутри
  российской команды, дальше нужен английский» повторена **трижды** → оставить
  один раз, остальное **сократить**.
- `kipia-aes/.../aes-professiya-i-napravleniya-atomtehenergo.md` — наполнитель с
  задвоением: «…это видно в вакансиях на официальном сайте прямо в вакансиях» →
  **сократить** (убрать дубль «в вакансиях»).

Замечание: outcomes-блоки в `aes-vver-1200-i-kontury.md` и `aes-vhr-i-analizatory.md`
чуть конкретнее прочих, но всё покрыто разделами `[!ПРОВЕРЬ]`/`## Задание` — по
строгому правилу всё равно удалить.

---

## Часть C — НЕ доревьюено (примени общий фильтр по ходу)

Глубокий построчный разбор тела на повторы/наполнитель (типы 3–4) был выполнен
**только для kipia-aes** (см. Часть B). Для **elektrik, inzhener-asu-tp,
svarshchik** проведён только машинный поиск:
- outcomes-блоки — найдены и перечислены в Части A;
- вводные-пустышки/лозунги (тип 2) — **не найдено** (grep по типовым маркерам пуст).

**Поэтому:** редактируя файлы из Части A в elektrik и inzhener-asu-tp, заодно
быстро прогляди тело на повторы и наполнитель (типы 3–4) и подчисти очевидное —
консервативно, не трогая полезное. Полный построчный аудит svarshchik и остальных
уроков elektrik/inzhener (без outcomes-блока) можно сделать отдельным проходом, если
понадобится; здесь он не делался ради экономии.

---

## Как сдать
Короткий отчёт: сколько файлов отредактировано, сколько outcomes-блоков удалено,
сколько оставлено как исключение (и почему), какие повторы/наполнители убраны.
Дерево оставь грязным (без коммита).
