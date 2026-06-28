---
title: "EtherNet/IP: промышленный Ethernet от Rockwell и ODVA"
position: 2
kind: lesson
resources:
  - title: "EtherNet/IP Specification — ODVA (Open DeviceNet Vendors Association), официальная спецификация"
    url: "https://www.odva.org/technology-standards/key-technologies/ethernet-ip/"
    kind: norm
    required: true
    language: en
  - title: "EtherNet/IP Quick Start for Vendors — ODVA (краткое практическое введение)"
    url: "https://www.odva.org/portals/0/library/publications_drives/ethernetip_quick_start_for_vendors.pdf"
    kind: norm
    required: false
    language: en
---
EtherNet/IP — доминирующий Industrial Ethernet-протокол в США, Канаде и на объектах с оборудованием Rockwell Allen-Bradley: его CIP-модель объектов и двойной тип соединений отличают его от PROFINET.
---
## Что такое EtherNet/IP

**EtherNet/IP** — промышленный Ethernet-протокол, разработанный компанией Rockwell Automation (Allen-Bradley) и переданный ассоциации **ODVA** (Open DeviceNet Vendors Association) в 2001 году. Сегодня ODVA объединяет более 400 производителей.

Название читается как «Ethernet Industrial Protocol» — не «Ethernet over IP». Протокол работает поверх стандартного TCP/IP на обычном Ethernet-оборудовании.

Ключевое отличие от PROFINET: EtherNet/IP построен на базе протокола **CIP** (Common Industrial Protocol) — той же модели объектов, что использует DeviceNet и ControlNet. Это даёт унификацию на уровне объектной модели устройств.

## CIP: Common Industrial Protocol

**CIP** — основа всей экосистемы ODVA. Он описывает устройство как набор **объектов** с **атрибутами**. Например, объект «Identity Object» содержит атрибуты: название устройства, версия прошивки, серийный номер. Объект «Assembly» — данные входов и выходов.

Такой подход позволяет одинаково обращаться к любому CIP-устройству вне зависимости от производителя — если оно поддерживает нужные объекты.

## Два типа соединений: I/O и Explicit

EtherNet/IP использует два принципиально разных типа обмена данными:

| | I/O Messaging | Explicit Messaging |
|---|---|---|
| **Что передаёт** | Циклические данные (входы/выходы) | Параметры, конфигурацию, диагностику |
| **Транспорт** | UDP (мультикаст или юникаст) | TCP |
| **Инициатор** | Установлен заранее (соединение) | Любая сторона |
| **Время отклика** | <10 мс (типично 1–5 мс) | Секунды |
| **Аналог** | PROFINET RT | PROFINET параметрирование |

**I/O Messaging** — это «конвейер» для технологических данных в реальном времени: ПЛК читает входы датчиков и пишет выходы на приводы с заданным периодом.

**Explicit Messaging** — это «почта» для конфигурации: прочитать серийный номер устройства, записать параметр, получить диагностику.

## PROFINET vs EtherNet/IP: ключевые отличия

| Параметр | PROFINET | EtherNet/IP |
|----------|---------|-------------|
| **Разработчик** | Siemens → PI | Rockwell → ODVA |
| **Доминирует в** | Европа, Азия | Северная Америка |
| **Основа** | Собственный стек RT | CIP поверх TCP/UDP |
| **RT без IP** | Да (RT работает на L2) | Нет (всегда IP) |
| **Синхронизация** | PTP IEEE 1588 (IRT) | PTP IEEE 1588 (CIP Motion) |
| **Обнаружение** | DCP (L2 broadcast) | Broadcast UDP (UCMM) |
| **Профили безопасности** | PROFIsafe | CIP Safety |

> [!СОВЕТ]
> На практике ты встретишь оба протокола: Siemens SIMATIC и Phoenix Contact — чаще PROFINET, Rockwell Allen-Bradley и Omron — чаще EtherNet/IP. Понимать оба нужно даже если работаешь с одним производителем: интеграция разнородных систем на промышленных объектах — обычная задача.

## EDS-файл: как ПО распознаёт устройство

Каждое EtherNet/IP-устройство описывается **EDS-файлом** (Electronic Data Sheet) — текстовым файлом, аналогом PROFINET GSD-файла. EDS содержит:
- Идентификатор устройства (Vendor ID, Product Code)
- Список объектов CIP и их атрибуты
- Описание I/O-данных

При добавлении нового устройства в Studio 5000 (ПО Rockwell) или RSLogix — ты устанавливаешь EDS-файл, и ПО «знает» как с ним работать.

> [!ПРОВЕРЬ]
> 1. Чем CIP отличается от Modbus как модель взаимодействия? Что такое «объект» в CIP?
> 2. Почему EtherNet/IP использует UDP для I/O Messaging, а не TCP? Какой у этого недостаток?
> 3. В чём принципиальное отличие EtherNet/IP от PROFINET в части маршрутизируемости через IP-роутеры?

## Задание

Сравни PROFINET и EtherNet/IP по критериям, важным для сетевого инженера. Составь таблицу из 5–7 строк с критериями:
- Требования к коммутатору (нужна ли поддержка PROFINET/EtherNet/IP?)
- Маршрутизируемость RT-трафика
- Способ обнаружения устройств в сети
- Совместимость с обычным IT-оборудованием

Для каждого критерия — коротко поясни, какое практическое значение это имеет при проектировании сети.

Запиши таблицу в журнал.
