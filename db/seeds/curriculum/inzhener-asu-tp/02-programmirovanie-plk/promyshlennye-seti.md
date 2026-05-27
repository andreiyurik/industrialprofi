---
title: "Промышленные сети: Modbus, PROFINET, OPC UA"
position: 6
resources:
  - title: "ГОСТ Р МЭК 61158-2014 — Промышленные сети. Спецификация полевой шины"
    url: "https://example.com/placeholder"
    kind: document
    required: true
    country_code: RU
  - title: "Modbus Application Protocol Specification v1.1b3 (modbus.org)"
    url: "https://example.com/placeholder"
    kind: document
    required: true
  - title: "IEC 62541 — OPC Unified Architecture (обзор, EN)"
    url: "https://example.com/placeholder"
    kind: document
    required: false
---

ПЛК не работает в изоляции — он обменивается данными с датчиками, частотниками, другими ПЛК и SCADA. **Без понимания протоколов** вы не настроите связь.

---

## Основные промышленные протоколы

| Протокол | Среда | Скорость | Применение |
|----------|-------|----------|-----------|
| **Modbus RTU** | RS-485 | 115.2 кбит/с | Датчики, частотники |
| **Modbus TCP** | Ethernet | 100 Мбит/с | ПЛК ↔ SCADA |
| **PROFINET** | Ethernet | 100 Мбит/с | Siemens-экосистема |
| **OPC UA** | Ethernet | — | Универсальный, будущее |

## Modbus — самый распространённый

Modbus работает по принципу **master-slave**:
- ПЛК (master) опрашивает устройства (slave) по адресам
- Типы регистров: Holding Registers, Input Registers, Coils, Discrete Inputs

## OPC UA — будущее промышленной связи

**IEC 62541** — платформонезависимый, с безопасностью и семантической моделью данных. Заменяет классический OPC DA.

> Modbus — для простых систем. OPC UA — для интеграции с IT-системами и облаком.

## Задание

Составьте **таблицу Modbus-регистров** для системы:
- 3 датчика (температура, давление, расход)
- 1 частотный привод

Укажите: адрес slave, тип регистра, адрес регистра, описание, единицы измерения, масштабирование.
