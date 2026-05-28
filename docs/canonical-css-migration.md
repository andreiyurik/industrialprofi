# Canonical CSS Migration — Writebook style

Промпт для нового чата. Самодостаточный: свежий Claude поймёт всё с нуля.

Цель — переписать стилизацию IndustrialProfi с Tailwind 4 на чистый CSS,
повторяющий 1-в-1 канонический подход **Writebook** (личное open-source
приложение DHH/Basecamp). Без выдумок, только то что реально есть в каноне.

---

## Промпт (копируй ниже всё в новый чат)

```
Я работаю над Rails 8 приложением IndustrialProfi: бесплатная платформа для
обучения рабочим профессиям СНГ через ГОСТы и практические задания. Контентная
структура — три уровня: Profession → Course → Lesson, как The Odin Project.

Стек:
- Ruby 4.0.5 / Rails 8.1.3
- SQLite3 + Solid Queue / Cache / Cable
- Hotwire (Turbo + Stimulus)
- Tailwind CSS 4 через tailwindcss-rails  ← ЭТО ПОЛНОСТЬЮ УБИРАЕМ
- Propshaft + Importmap (no Node, no bundler)
- Kamal 2 + Docker + Thruster
- has_secure_password
- Minitest + fixtures + Capybara

═══════════════════════════════════════════════════════════════════════════
ЦЕЛЬ И ПРИОРИТЕТЫ
═══════════════════════════════════════════════════════════════════════════

Полностью убрать Tailwind. Перейти на чистый CSS точно по образцу Writebook.

Приоритеты пользователя (в порядке важности):
1. Надёжность — минимум движущихся частей, никаких build-step фокусов
2. Простота долгосрочной поддержки — код должен быть читаем через 5 лет
3. Удобство пользователя — light/dark mode из коробки, нативно
4. Каноничность DHH — следуем правилам как у Basecamp / DHH в Writebook

ВАЖНО: НЕ изобретать собственные паттерны. Если что-то есть в Writebook —
копируй 1-в-1. Если в Writebook этого нет — НЕ ПРИДУМЫВАЙ, спроси.
Не комбинируй паттерны Writebook и Fizzy. Writebook — единственный канон.

═══════════════════════════════════════════════════════════════════════════
РЕФЕРЕНС (ЛОКАЛЬНО, ОБЯЗАТЕЛЬНО ИЗУЧИ)
═══════════════════════════════════════════════════════════════════════════

Канон Writebook лежит локально:
  /home/pingvinus/dhh-references/writebook/

Перед стартом ОБЯЗАТЕЛЬНО прочитай:
  app/views/layouts/application.html.erb        — как организован layout
  app/assets/stylesheets/_reset.css             — модерн CSS reset
  app/assets/stylesheets/base.css               — html/body, шрифты, links, focus
  app/assets/stylesheets/colors.css             — OKLCH primitives + abstractions
  app/assets/stylesheets/layout.css             — контейнеры, секции
  app/assets/stylesheets/utilities.css          — мини-утилиты (.flex .gap ...)
  app/assets/stylesheets/text.css               — типографика
  app/assets/stylesheets/buttons.css            — .btn + варианты
  app/assets/stylesheets/inputs.css             — формы
  app/assets/stylesheets/panels.css             — .panel компонент
  app/assets/stylesheets/breadcrumbs.css        — навигация
  app/views/sessions/new.html.erb               — пример формы
  app/views/books/_book.html.erb                — пример карточки

И прочитай память проекта:
  /home/pingvinus/.claude/projects/-home-pingvinus-industrialprofi-dhh/memory/
    MEMORY.md
    design_system_direction.md
    basecamp_reference_apps.md
    design_migration_phases.md

═══════════════════════════════════════════════════════════════════════════
ТЕКУЩЕЕ СОСТОЯНИЕ (PHASE 1+2 УЖЕ СДЕЛАНЫ НА TAILWIND-HYBRID)
═══════════════════════════════════════════════════════════════════════════

В app/assets/tailwind/application.css УЖЕ определены:
  — OKLCH-примитивы в :root
  — Инверсия в @media (prefers-color-scheme: dark)
  — Семантические токены через @theme (--color-canvas, --color-ink, ...)
  — Системные шрифты (--font-sans)
  — ~25 @utility компонентов (.btn-primary, .card-dark, .lesson-prose, ...)

Все 21 ERB-views используют новые токены (bg-canvas, text-ink, text-link,
text-marker, border-subtle, и т.п.) и canonical-style utility-имена.
dark: модификаторов нет нигде.

Phase 1+2 закоммичены: 2ace800 "UI: hybrid css by Writebook" + последующий
коммит миграции views.

ЭТА ФАЗА — Phase 4 (Phase 3 как semantic layout regions откладываем) —
полная замена Tailwind на чистый CSS.

═══════════════════════════════════════════════════════════════════════════
ВЕРИФИЦИРОВАННЫЕ ФАКТЫ О КАНОНЕ WRITEBOOK
═══════════════════════════════════════════════════════════════════════════

ЭТО ВСЁ ПРОВЕРЕНО ЧТЕНИЕМ ИСХОДНИКОВ WRITEBOOK. НЕ ИНТЕРПРЕТИРУЙ ИНАЧЕ.

1. КАК ГРУЗИТСЯ CSS:
   В app/views/layouts/application.html.erb стоит:
     <%= stylesheet_link_tag :all, "data-turbo-track": "reload" %>
   Это говорит Propshaft автоматически собрать все *.css из
   app/assets/stylesheets/ и сгенерировать ОТДЕЛЬНЫЕ <link rel="stylesheet">
   теги для каждого файла. БРАУЗЕР сам разрулит каскад через порядок имён.

   - НЕТ application.css entry point
   - НЕТ @import цепочки между файлами
   - НЕТ @layer объявления каскада
   - НЕТ Gemfile зависимостей кроме propshaft

2. ИМЕНОВАНИЕ КЛАССОВ:
   В Writebook нет жёсткого BEM. Преобладает hyphenated-flat:
     .btn          .btn--reversed     .btn--link       .btn--negative
     .btn--positive .btn--plain       .btn--small      .btn--circle
     .panel        .panel__close      .panel--padded
     .breadcrumbs  .breadcrumbs__crumb
     .txt-large    .txt-small         .txt-ink         .txt-subtle
     .txt-reversed .txt-negative      .txt-positive    .txt-undecorated
     .flex         .flex-column       .flex-wrap
     .gap          .gap-half
     .align-center .align-start       .align-end
     .justify-center .justify-end     .justify-space-between
     .full-width   .half-width        .min-width

   Правило: hyphenated по умолчанию. `--modifier` для вариантов.
   `__element` только когда есть вложенный DOM-элемент компонента
   (например .panel__close — кнопка закрытия внутри .panel).

3. CSS-ПЕРЕМЕННЫЕ ДЛЯ SPACING/SIZING:
   Объявляются в utilities.css:
     --inline-space: 1ch;
     --inline-space-half: calc(var(--inline-space) / 2);
     --inline-space-double: calc(var(--inline-space) * 2);
     --block-space: 1rem;
     --block-space-half: calc(var(--block-space) / 2);
     --block-space-double: calc(var(--block-space) * 2);

4. КОМПОНЕНТЫ ИСПОЛЬЗУЮТ СВОИ ПЕРЕМЕННЫЕ ДЛЯ ТЕМИЗАЦИИ:
   Из buttons.css (реальный код):
     .btn {
       background-color: var(--btn-background, transparent);
       border: var(--btn-border-size, 1px) solid var(--btn-border-color, var(--color-subtle-dark));
       color: var(--btn-color, var(--color-ink));
       padding: var(--btn-padding, 0.5em 1.1em);
       border-radius: var(--btn-border-radius, 2em);
       ...
     }
     .btn--reversed {
       --btn-background: var(--color-ink);
       --btn-color: var(--color-ink-reversed);
     }
   Модификаторы переопределяют локальные переменные. Это canonical pattern.

5. ШРИФТЫ:
   Из base.css (реальный код):
     html, body {
       --font-sans: system-ui;
       --font-serif: ui-serif, serif;
       --font-mono: ui-monospace, monospace;
       font-family: var(--font-sans);
       line-height: 1.4;
       background: var(--color-bg);
       color: var(--color-ink);
       ...
     }

6. ЦВЕТА (из colors.css):
   :root {
     --lch-black: 0% 0 0;       --lch-orange: 70% 0.2 44;
     --lch-white: 100% 0 0;     --lch-gray-light: 96% 0.005 96;
     --lch-blue: 54% 0.15 255;  --lch-gray: 92% 0.005 96;
     --lch-blue-light: 95% 0.03 255;
     --lch-red: 51% 0.2 31;     --lch-gray-dark: 75% 0.005 96;
     --lch-green: 65.59% 0.234 142.49;

     --color-bg: oklch(var(--lch-white));
     --color-ink: oklch(var(--lch-black));
     --color-ink-reversed: oklch(var(--lch-white));
     --color-link: oklch(var(--lch-blue));
     --color-negative: oklch(var(--lch-red));
     --color-positive: oklch(var(--lch-green));
     --color-marker: oklch(var(--lch-orange));
     --color-subtle-light: oklch(var(--lch-gray-light));
     --color-subtle: oklch(var(--lch-gray));
     --color-subtle-dark: oklch(var(--lch-gray-dark));

     @media (prefers-color-scheme: dark) {
       --lch-black: 100% 0 0;   --lch-white: 0% 0 0;
       /* и т.д. */
     }
   }
   ВАЖНО: Writebook использует --color-bg (НЕ --color-canvas) и
   --color-ink-reversed (НЕ --color-canvas-reversed). Это канон.
   У нас Phase 2 ввёл --color-canvas. Переименовать в --color-bg
   для соответствия канону.

7. HOVER/FOCUS PATTERN:
   В base.css :is(a, button, input, textarea) задаёт общий
   transition + hover box-shadow. Не нужно повторять в компонентах.

8. ЦВЕТОВАЯ СХЕМА HTML:
   В <head> ставится:
     <meta name="color-scheme" content="light dark">
     <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
     <meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)">
   Это даёт нативный UI браузера в правильной теме (scrollbars, form controls).

═══════════════════════════════════════════════════════════════════════════
ЦЕЛЕВАЯ СТРУКТУРА ФАЙЛОВ
═══════════════════════════════════════════════════════════════════════════

Скопировать структуру Writebook (наш домен похож на их домен — контент-платформа).

app/assets/stylesheets/
  ── ОСНОВА (минимум для запуска) ──
  _reset.css          — модерн ресет (скопировать из writebook/_reset.css)
  base.css            — html/body + шрифты + links + focus + ::selection
                        (скопировать структуру из writebook/base.css)
  colors.css          — OKLCH primitives + abstractions + dark mode
                        (взять текущий блок из app/assets/tailwind/application.css)
  layout.css          — .container, .container--reading, .section, .section--divided
  utilities.css       — мини-утилиты + spacing CSS-переменные
                        (скопировать из writebook/utilities.css, добавить
                        только то что используем)
  text.css            — типографика: h1-h6, .page-title, .section-title,
                        .prose для markdown-контента уроков

  ── КОМПОНЕНТЫ ──
  buttons.css         — .btn + варианты (--reversed --outline --marker --plain
                        --small --link --negative --positive)
  inputs.css          — .input, labels, form errors
  panels.css          — .panel компонент (карточка-обёртка)
  breadcrumbs.css     — .breadcrumbs + __crumb + __link + __current
  flash.css           — .flash + .flash__inner (мы уже создали partial,
                        добавить CSS)
  badges.css          — .badge + __marker + __admin

  ── ДОМЕННЫЕ ФАЙЛЫ (наши, не Writebook) ──
  paths.css           — .path-card, .topic-card, .topic-icon, .step-icon
  lesson.css          — .lesson, .lesson__intro, .lesson__heading,
                        .lesson__task, .lesson-nav-pill, .lesson-resource
  curriculum.css      — .curriculum + __section + __header (страница пути)
  footer.css          — .footer + __heading + __link
  support.css         — .support секция (поддержите нас)
  admin.css           — стилизация админ-форм и таблиц

ВАЖНО: алфавитный порядок имён файлов важен — он определяет порядок
загрузки и каскад. Резервно начни файлы reset/base с подчёркивания
(_reset.css) чтобы они грузились первыми.

═══════════════════════════════════════════════════════════════════════════
ИЗМЕНЕНИЯ В СТЕКЕ
═══════════════════════════════════════════════════════════════════════════

УДАЛИТЬ:
  - gem "tailwindcss-rails" из Gemfile (запустить bundle)
  - app/assets/tailwind/ — папка целиком
  - app/assets/builds/tailwind.css (после rebuild)
  - tailwindcss watcher из Procfile.dev / bin/dev (или bin/setup)

ОБНОВИТЬ:
  - app/views/layouts/application.html.erb:
    Заменить:
      <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    На:
      <%= stylesheet_link_tag :all, "data-turbo-track": "reload" %>

  - Добавить в head:
      <meta name="color-scheme" content="light dark">
      <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
      <meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)">

  - В .gitignore убрать app/assets/builds/ (или оставить если он используется
    Propshaft'ом для других вещей — проверь).

═══════════════════════════════════════════════════════════════════════════
ПРАВИЛА КАНОНИЧНОСТИ
═══════════════════════════════════════════════════════════════════════════

1. ОТСУТСТВУЕТ entry application.css. Каждый CSS-файл независим.
   stylesheet_link_tag :all грузит все автоматически.

2. БЕЗ @layer. Каскад через порядок имён файлов.
   (Fizzy использует @layer — мы НЕТ. Это критичное отличие.)

3. БЕЗ @import между файлами. Никаких CSS-зависимостей.

4. БЕЗ build-step. Propshaft просто копирует CSS as-is.

5. БЕЗ JS-конфига (postcss.config.js, tailwind.config.js — забудь про них).

6. БЕЗ dark: классов в HTML. Только @media (prefers-color-scheme: dark).

7. Каждый компонент задаёт СВОИ CSS-переменные с дефолтами для темизации
   через `--btn-background, --panel-padding` и т.п. — см. п.4 канона.

8. Цвета через OKLCH. Никаких hex/rgb/hsl.

9. Шрифты только системные. Никаких Google Fonts, Inter, etc.

10. Spacing через переменные --inline-space / --block-space (НЕ rem/px
    в компонентах напрямую).

11. ERB + partials, без ViewComponent/Slim/Haml.

12. Heroicons (через heroicon gem) для иконок — оставить.

═══════════════════════════════════════════════════════════════════════════
МИГРАЦИОННАЯ КАРТА КЛАССОВ
═══════════════════════════════════════════════════════════════════════════

ТЕКУЩИЕ Tailwind @utility — НОВЫЕ имена (по канону Writebook):

  .page-container           → .container
  .content-container        → .container--reading
  .section-padded           → .section
  .section-divided          → .section--divided
  .page-title               → .page-title (оставить, стилизуется в text.css)
  .section-title            → .section-title (стилизуется в text.css)
  .body-text                → УБРАТЬ — текст по умолчанию стилизован в base.css
  .body-text-light          → УБРАТЬ
  .card-dark                → .panel
  .card-dark-hover          → .panel.panel--hover
  .topic-card               → .topic-card (оставить, перенести в paths.css)
  .topic-icon               → .topic-card__icon
  .btn                      → .btn
  .btn-primary              → .btn.btn--reversed   ← canonical primary
  .btn-outline              → .btn.btn--outline
  .btn-gold                 → .btn.btn--marker
  .badge-gold               → .badge.badge--marker
  .nav-link                 → .nav__link
  .step-icon                → .step-icon (перенести в paths.css)
  .testimonial-avatar       → .avatar
  .support-section          → .support
  .breadcrumb               → .breadcrumbs
  .breadcrumb-link          → .breadcrumbs__link
  .breadcrumb-separator     → .breadcrumbs__separator
  .breadcrumb-current       → .breadcrumbs__current
  .lesson-intro             → .lesson__intro
  .lesson-heading           → .lesson__heading
  .lesson-task              → .lesson__task
  .lesson-nav-pill          → .lesson-nav__pill
  .lesson-edit-link         → .lesson-edit-link
  .lesson-prose             → .prose (общая, в text.css)
  .lesson-resource          → .lesson-resource
  .lesson-resource-marker   → .lesson-resource__marker
  .lesson-resource-link     → .lesson-resource__link
  .curriculum-section       → .curriculum__section
  .curriculum-header        → .curriculum__header
  .footer-heading           → .footer__heading
  .footer-link              → .footer__link

ТОКЕНЫ (CSS-переменные):

  --color-canvas            → --color-bg        (canon Writebook)
  --color-ink               → --color-ink       (одинаково)
  --color-ink-subtle        → --color-subtle-dark   (canon Writebook)
  --color-link              → --color-link
  --color-positive          → --color-positive
  --color-negative          → --color-negative
  --color-marker            → --color-marker
  --color-subtle            → --color-subtle
  --color-subtle-light      → --color-subtle-light

INLINE TAILWIND-УТИЛИТЫ В ERB:

  flex                        → flex
  flex-column                 → flex-column
  items-center                → align-center
  justify-center              → justify-center
  justify-between             → justify-space-between
  gap-2 / gap-3 / gap-half    → gap-half
  gap-4 / gap-6 / gap         → gap
  gap-8                       → (gap + локальная --column-gap override)
  mt-*                        → не используем inline. В компоненте через margin-block-start
  mb-*                        → то же
  py-12, py-16                → внутри .section (есть в layout.css)
  px-4, px-6, sm:px-6         → внутри .container (есть в layout.css)
  text-sm                     → txt-small
  text-base                   → текст по умолчанию (не нужен класс)
  text-lg                     → txt-large
  text-xl                     → txt-large
  text-2xl, text-3xl          → txt-x-large
  text-4xl, text-5xl          → txt-xx-large
  font-bold                   → font-weight-bold (в utilities.css)
  font-semibold               → font-weight-semibold
  rounded-md, rounded-lg      → НЕ inline. Внутри компонента через --radius
  shadow-*                    → НЕ inline. В компоненте через --shadow
  ring-1 ring-subtle          → НЕ inline. В компоненте через border var
  hover:bg-*                  → НЕ inline. В CSS компонента :hover
  max-w-2xl, max-w-4xl        → НЕ inline. Через --max-width в компоненте
  hidden, sm:flex             → media queries в компоненте
  group, group-hover:*        → через дочерний селектор внутри :hover в CSS

ЦВЕТА:

  bg-canvas                   → background: var(--color-bg) (в компоненте)
  text-ink                    → color: var(--color-ink) ИЛИ class .txt-ink
  text-ink-subtle             → .txt-subtle
  text-link                   → .txt-link или color: var(--color-link)
  text-marker                 → .txt-marker (новая утилита в utilities.css)
  text-positive               → .txt-positive
  text-negative               → .txt-negative
  border-subtle               → border-color: var(--color-subtle) в компоненте
  bg-subtle-light             → background: var(--color-subtle-light) в компоненте
  bg-subtle                   → background: var(--color-subtle) в компоненте

═══════════════════════════════════════════════════════════════════════════
ФАЗЫ ВЫПОЛНЕНИЯ
═══════════════════════════════════════════════════════════════════════════

ВАЖНО: Делай фазы строго по очереди. После каждой — коммит + дай пользователю
проверить через bin/rails server. Не пытайся за один коммит сделать всё.
Большой коммит = большой откат при проблеме.

— ФАЗА A: Foundation (CSS-фундамент без UI-компонентов)
  1. Скопируй writebook/_reset.css в app/assets/stylesheets/_reset.css 1-в-1.
  2. Скопируй writebook/base.css в app/assets/stylesheets/base.css 1-в-1.
     (Только система шрифтов, body, links, focus.)
  3. Создай app/assets/stylesheets/colors.css на основе текущего блока OKLCH
     из app/assets/tailwind/application.css. Переименуй --color-canvas в
     --color-bg, --color-ink-subtle в --color-subtle-dark (для соответствия
     канону).
  4. Создай app/assets/stylesheets/utilities.css на основе writebook/utilities.css
     (включи только spacing-переменные и часто используемые классы —
     .flex, .gap, .gap-half, .align-center, .justify-center,
     .justify-space-between, .full-width, .txt-small/normal/large/x-large,
     .txt-align-center, .txt-ink/subtle/reversed/negative/positive/link/marker,
     .font-weight-bold/semibold).
  5. Создай минимальный app/assets/stylesheets/layout.css с .container и .section.
  6. Обнови app/views/layouts/application.html.erb:
     - Замени stylesheet_link_tag :app на :all
     - Добавь meta name="color-scheme" + theme-color
  7. Удали gem "tailwindcss-rails" + bundle.
  8. Удали app/assets/tailwind/.
  9. Обнови bin/dev (убери tailwindcss-rails watcher).
  10. Запусти bin/rails server — главная должна рендериться (без компонент-стилей).
      Хедер сломан, кнопки сломаны — это ожидаемо. Шрифты, тёмная тема,
      базовые цвета должны работать.
  11. Коммит: "pure-css A: foundation (reset, base, colors, utilities, layout)"
  12. Стоп. Пользователь проверяет визуально. Покажи скриншот / попроси проверить.

— ФАЗА B: Core UI components
  Поочерёдно создаёшь файлы и сразу мигрируешь использующие их views.
  Структура файла = скопировать примерно из writebook + адаптировать имена.

  B.1 buttons.css → миграция всех .btn-* в views на .btn + модификаторы
  B.2 inputs.css → миграция админ-форм
  B.3 panels.css → миграция .card-dark/.card-dark-hover на .panel
  B.4 flash.css → стилизация уже существующего partial _flash.html.erb
  B.5 breadcrumbs.css → миграция .breadcrumb* в _breadcrumbs.html.erb
  B.6 text.css → .page-title, .section-title, .prose для markdown

  После каждой подфазы — коммит + bin/rails server проверка.
  Коммит-сообщения: "pure-css B.N: <название>"

— ФАЗА C: Layout chrome (хедер + футер)
  C.1 Создай app/assets/stylesheets/header.css или встрой в layout.css —
      .header + .header__brand + .header__nav.
  C.2 Создай footer.css — .footer + .footer__heading + .footer__link.
  C.3 Мигрируй app/views/layouts/application.html.erb на новые классы.
      Используй семантические <header> <main> <footer> теги. Можно
      позже добавить <%= yield :header %> блоки как у Writebook, но
      сейчас не обязательно.
  C.4 Коммит: "pure-css C: layout chrome"

— ФАЗА D: Doménные страницы
  D.1 paths.css → .topic-card, .topic-card__icon, .step-icon, .avatar
      + миграция home.html.erb, paths/index.html.erb
  D.2 lesson.css → все классы для страницы урока
      + миграция lessons/show.html.erb, _lesson_nav.html.erb,
        resources/_resource.html.erb
  D.3 curriculum.css → страница профессии (paths/show.html.erb)
  D.4 support.css → страница поддержки + соответствующая секция в home
  D.5 admin.css → миграция всех admin views
  D.6 badges.css → миграция Admin-бейджа и кнопок-бейджей

  Каждая подфаза — отдельный коммит "pure-css D.N: <название>"

— ФАЗА E: Очистка
  E.1 Финальный grep: убедись, что нет ни одной Tailwind-утилиты в views
      (grep -rn "bg-\|text-\|border-\|ring-\|flex\|grid\|hover:" app/views/
       должен показать только наши custom-классы).
  E.2 Обнови CLAUDE.md:
      - Stack: убери Tailwind, добавь "Pure CSS via Propshaft"
      - UI секция: переписать под Writebook-канон (BEM-ish, OKLCH, system fonts,
        stylesheet_link_tag :all)
      - Anti-patterns: добавь "No Tailwind, no @import in CSS, no build step"
  E.3 Обнови память:
      design_migration_phases.md: отметь Phase 4 (pure CSS) done
      design_system_direction.md: уточни что переход с hybrid на pure CSS сделан
  E.4 Запусти bin/rails test и bin/rails test:system если есть.
  E.5 Финальный коммит: "pure-css E: cleanup + docs"

═══════════════════════════════════════════════════════════════════════════
КАК РАБОТАТЬ
═══════════════════════════════════════════════════════════════════════════

1. Перед стартом прочитай в этом порядке:
   - /home/pingvinus/industrialprofi-dhh/CLAUDE.md
   - .claude/projects/.../memory/MEMORY.md и все memory-файлы
   - Указанные референсы из /home/pingvinus/dhh-references/writebook/

2. Используй TaskCreate для каждой фазы и подфазы. Обновляй статусы
   in_progress / completed по ходу.

3. Делай git commit в конце КАЖДОЙ подфазы — нельзя за один коммит делать
   несколько подфаз. Имя коммита: "pure-css <буква>.<номер>: <название>".

4. После каждой фазы коротко отчитайся пользователю:
   - Что сделал
   - Что закоммитил
   - Попроси проверить через bin/rails server и подтвердить продолжение

5. Если что-то не работает или сомневаешься в каноне — НЕ выдумывай.
   Открой соответствующий файл в /home/pingvinus/dhh-references/writebook/
   и копируй паттерн. Если паттерна нет — спроси пользователя.

6. НЕ используй Fizzy как источник. Только Writebook. Это критично.
   Исключение: иконки и Stimulus-паттерны можно посмотреть у Fizzy,
   но при сомнении — Writebook.

7. Сразу после Фазы A проверь, что Tailwind полностью удалён:
     ls app/assets/tailwind 2>&1   ← должно быть "No such file"
     grep -r "tailwind" Gemfile.lock   ← должно быть пусто
     grep -r "tailwind" config/   ← должно быть пусто
     grep -r "@apply\|@theme\|@variant" app/assets/  ← должно быть пусто

Стартуем с Фазы A. Жду подтверждения, что прочитал референсы и память.
```

---

## Что выкинуто из предыдущей версии (не каноничного)

- ❌ `@layer reset, base, components, utilities;` объявление — Writebook не использует
- ❌ `application.css` с `@import` цепочкой — нет в Writebook
- ❌ `stylesheet_link_tag "application"` — канон `:all`
- ❌ Жёсткий BEM (`.flash__inner` везде) — канон гибче
- ❌ Файлы `typography.css`, `nav.css`, `prose.css` — канон называет иначе
- ❌ `--color-canvas` — канон `--color-bg`
- ❌ `--color-ink-subtle` — канон `--color-subtle-dark`
- ❌ Оценка часов на фазы — выдумка

## Что добавлено (верифицировано чтением)

- ✅ `stylesheet_link_tag :all` точно из layouts/application.html.erb Writebook
- ✅ Структура файлов 1-в-1 как у Writebook
- ✅ Точные имена `.btn--reversed`, `.btn--link` и т.д. из buttons.css
- ✅ Реальный canonical паттерн темизации через локальные `--btn-background`
- ✅ Meta-теги color-scheme + theme-color из реального head Writebook
- ✅ Реальные имена токенов `--color-bg`, `--color-ink-reversed`, `--color-subtle-dark`
