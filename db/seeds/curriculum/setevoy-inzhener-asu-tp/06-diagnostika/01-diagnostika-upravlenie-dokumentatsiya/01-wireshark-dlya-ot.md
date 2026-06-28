---
title: "Wireshark для OT: анализ Modbus, PROFINET и OPC UA"
position: 1
kind: practice
difficulty: beginner
resources:
  - title: "Wireshark — бесплатный анализатор сетевых протоколов (официальный сайт)"
    url: "https://www.wireshark.org/"
    kind: tool
    required: true
  - title: "Wireshark Sample Captures — официальная библиотека учебных PCAP-файлов"
    url: "https://wiki.wireshark.org/SampleCaptures"
    kind: tool
    required: true
  - title: "Wireshark Display Filter Reference — справочник по синтаксису фильтров"
    url: "https://www.wireshark.org/docs/dfref/"
    kind: doc
    required: false
    language: en
---
Wireshark — основной инструмент диагностики OT-сети: знание промышленных фильтров (modbus, pn_dcp, opc.tcp) позволяет за минуты найти причину, по которой ПЛК «не видит» устройство или SCADA получает неверные данные.
---
## Wireshark как инструмент OT-диагностики

Wireshark — бесплатный packet analyzer, понимающий сотни сетевых протоколов включая промышленные: Modbus TCP, PROFINET (DCP, RT, I&M, MRP), EtherNet/IP (CIP), OPC UA, IEC 104, DNP3.

В OT Wireshark применяется в трёх ситуациях:
1. **Поиск неисправности** — почему ПЛК не отвечает? Пакеты вообще доходят?
2. **Проверка конфигурации** — правильно ли настроен VLAN? Работает ли MRP?
3. **Анализ безопасности** — есть ли в сети неизвестные устройства? Нет ли Modbus-запросов с посторонних IP?

> [!СОВЕТ]
> В OT-сети никогда не запускай Wireshark на инженерной станции с открытым TIA Portal или WinCC во время работы — высокая нагрузка захвата может повлиять на RT-коммуникации. Запускай захват на отдельном ноутбуке, подключённом через SPAN-порт коммутатора.

## Настройка захвата

**Прямое подключение** (если ты в нужном VLAN или сегменте):
- Выбери нужный интерфейс, нажми «Start Capture»

**Через SPAN (зеркалирование порта)**:
- На коммутаторе настрой SPAN: скопируй порты ПЛК на свободный порт
- Подключись ноутбуком к SPAN-порту — увидишь трафик от/к ПЛК

Пример настройки SPAN на Cisco-подобном CLI (SCALANCE, Moxa):
```
monitor session 1 source interface GigabitEthernet 0/1
monitor session 1 destination interface GigabitEthernet 0/8
```

## Ключевые фильтры для OT

### Modbus TCP

```
modbus                    # весь Modbus TCP
modbus.func_code == 3     # только Function Code 3 (Read Holding Registers)
modbus.func_code == 6     # FC 6 (Write Single Register) — записи
modbus.func_code >= 128   # ответы с ошибкой (exception responses)
ip.addr == 192.168.10.11  # трафик конкретного ПЛК
```

Что искать при диагностике Modbus:
- Запрос есть → ответ есть → всё ок
- Запрос есть → ответа нет → TCP timeout → проверь IP, VLAN, firewall
- Ответ есть → Exception Code → проверь адрес регистра в спецификации устройства

### PROFINET

```
pn_dcp                   # PROFINET DCP (Device discovery, ненастроен = broadcast)
pn_rt                    # PROFINET RT трафик (циклический)
pn_mrp                   # PROFINET MRP (кольцевое резервирование)
pn_io                    # PROFINET I/O Cyclic
```

**PROFINET DCP Identify** (ключевой для диагностики «устройство не подключается»):
- Ищи `pn_dcp` — там видно broadcast-запросы и ответы устройств
- Если устройство не отвечает на DCP Identify — оно недоступно на L2 (проверь VLAN, кабель)

### OPC UA

```
opc.tcp                  # OPC UA Binary (стандартный порт 4840)
```

OPC UA в Wireshark показывает тип сообщений: `HEL`/`ACK` (handshake), `OPN`/`CLO` (сессия), `MSG` (запросы данных). Конкретные ноды зашифрованы (если включена безопасность) — содержимое не читаемо, но видна структура.

### Полезные универсальные фильтры

```
arp                      # ARP — кто в сети, кто ищет кого
broadcast                # весь broadcast — много? может быть шторм
!(arp or stp)            # скрыть служебный шум, видеть только данные
tcp.analysis.retransmission  # TCP ретрансмиссии — признак потерь
```

## Практика: анализ PCAP с Modbus

### Цель
Научиться читать Modbus TCP трафик в Wireshark: найти запросы, ответы, исключения.

### Понадобится
- Wireshark (бесплатно, wireshark.org)
- PCAP-файл с Modbus трафиком (скачай с wiki.wireshark.org/SampleCaptures, ищи «modbus»; или используй захват из ModRSsim2 + Modbus Poll)

### Шаги

1. Открой PCAP в Wireshark.
2. Введи фильтр `modbus` — увидишь только Modbus-пакеты.
3. Найди запрос с Function Code 3 (Read Holding Registers).
   - Кликни на пакет → в нижней панели разверни «Modbus» → посмотри: Unit ID, FC, Starting Address, Quantity.
4. Найди соответствующий ответ.
   - В разделе «Modbus» ответа найди «Register Data» — прочти значения.
5. Поищи пакет с FC > 128 (exception response). Разберись: какой Exception Code и что он означает?

### Что сдать
Запиши в журнал:
- IP источника и назначения для трёх разных Modbus-пакетов
- Function Code и его смысл для каждого
- Если нашёл Exception Response — какой код и что это значит?
- Вывод: что происходит в этой сети между двумя хостами?

### Самопроверка
- [ ] Ты применил фильтр `modbus` и видишь только Modbus-пакеты
- [ ] Ты нашёл пару запрос/ответ (Request FC03 → Response FC03)
- [ ] Ты прочитал значение регистра из ответа в панели расшифровки
- [ ] Ты знаешь, что FC > 128 означает ошибку (exception)

## Задание: самостоятельный захват

Если у тебя есть доступ к любому OT-устройству (ПЛК, преобразователь частоты с Modbus, контроллер насоса):

1. Подключись к той же сети (или используй SPAN-порт).
2. Запусти захват на 60 секунд.
3. Примени фильтр `modbus` или `pn_rt`.
4. Найди циклические запросы — с какой частотой они идут? (в Wireshark: Statistics → IO Graphs)
5. Есть ли в захвате нечто необычное — устройства, которых не должно быть? Broadcast-шторм?

Запиши результат в журнал.
