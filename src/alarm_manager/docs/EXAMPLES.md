# Примеры использования 💡

Подробные примеры работы с модулем `alarm_manager`.

## Содержание

- [Минимальный пример](#минимальный-пример)
- [Тревога по событию (EVENT)](#тревога-по-событию-event)
- [Тревога с задержкой активации](#тревога-с-задержкой-активации)
- [Тревога по дискретному каналу (DISCRETE)](#тревога-по-дискретному-каналу-discrete)
- [Тревога по аналоговому каналу (ANALOG)](#тревога-по-аналоговому-каналу-analog)
- [Аналоговая тревога с уставками из каналов](#аналоговая-тревога-с-уставками-из-каналов)
- [Тревога из Кодесис (CS_CLIENT)](#тревога-из-кодесис-cs_client)
- [Способы квитирования](#способы-квитирования)
- [Несколько таблиц тревог](#несколько-таблиц-тревог)
- [Настройка внешнего вида](#настройка-внешнего-вида)
- [Настройка цветов](#настройка-цветов)
- [Кнопка квитирования](#кнопка-квитирования)
- [Отображение значений в сообщении](#отображение-значений-в-сообщении)
- [Приоритеты тревог](#приоритеты-тревог)
- [Продвинутые примеры](#продвинутые-примеры)
- [Типичные ошибки](#типичные-ошибки)

---

## Минимальный пример

```lua
local am = require("meralualib.v1_0_0.alarm_manager")

-- Создаём таблицу тревог
local atable = am.Atable:new()
atable.table_id = 1

function lua_main()
    am:upd()  -- обязательно в начале lua_main

    -- Регистрируем тревогу с изменением параметров после регистрации
    local alarm = atable:alarm()
    alarm.logic = am.LOGIC.EVENT
    alarm.class = am.ALARM_CLASS.ERROR
    alarm.event = getValue("my_signal") > 0
    alarm.msg = "Превышение сигнала"
end
```

Так тоже можно:
```lua
    -- Регистрируем тревогу с передачей параметров в метод
    atable:alarm{
        logic = am.LOGIC.EVENT,
        class = am.ALARM_CLASS.ERROR,
        event = getValue("my_signal") > 0,
        msg = "Превышение сигнала",
    }
```


### ❌ Неправильно - регистрация тревоги внутри условия
> ⚠️ Тревоги автоматически получают ID в каждый цикл скрипта. При таком подходе нарушается идентификация тревоги:

```lua
if getValue("my_signal") > 0 then  -- ⚠️ не допускается оборачивать тревогу в условие
    local alarm = atable:alarm()
    alarm.logic = am.LOGIC.EVENT
    alarm.class = am.ALARM_CLASS.ERROR,
    alarm.event = true,
    alarm.msg = "Превышение сигнала",
end
```

### ❌ Неправильно - присвоение параметров тревоги внутри условия
> ⚠️ Каждый цикл скрипта проверяются типы передаваемых параметров и отсутствие лишних параметров - генерится исключение при несоответствии.
> При таком подходе возможен выброс исключения и остановка выполнения скрипта при выполнении условия:

```lua
local alarm = atable:alarm()
if getValue("my_signal") > 0 then  -- ⚠️ не допускается оборачивать параметры тревоги в условие
    alarm.logic = "BAD_PARAMETER",  -- НЕДОПУСТИМО, должно быть значение из перечислителя am.LOGIC, скрипт остановится
    alarm.class = am.ALARM_CLASS.ERROR,
    alarm.event = true,
    alarm.msg = "Превышение сигнала",
end
```


---

## Тревога по событию (EVENT)

Самый простой тип — срабатывает по булеву условию или числу (> 0).

```lua
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = getValue("pressure") > 10,
    class = am.ALARM_CLASS.ERROR,
    msg = "Давление выше нормы",
    confirm_method = am.CONFIRM_METHOD.REP_ACK,
}
```

> 💡 Если `event` — число, тревога сработает при `event > 0`:

```lua
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = getValue("DI_FIRE"),  -- в СИАМ булевы значения получаем в виде 0/1
    class = am.ALARM_CLASS.ERROR,
    msg = "Пожар!",
    confirm_method = am.CONFIRM_METHOD.REP_ACK,
}
```

---

## Тревога с задержкой активации

Используйте `delay_on` и `delay_off`, чтобы избежать срабатывания на кратковременные выбросы.

```lua
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = getValue("temperature") > 80,
    class = am.ALARM_CLASS.WARN,
    msg = "Перегрев",
    delay_on = 5,    -- сработает, если условие держится 5 секунд
    delay_off = 10,  -- сбросится через 10 секунд после возврата
}
```

---

## Тревога по дискретному каналу (DISCRETE)

Срабатывает, когда значение канала превышает порог `discrete_val`.

```lua
atable:alarm{
    logic = am.LOGIC.DISCRETE,
    channel = "pump_fault",
    discrete_val = 0,  -- сработает при channel > 0
    class = am.ALARM_CLASS.ERROR,
    msg = "Неисправность насоса",
}
```

---

## Тревога по аналоговому каналу (ANALOG)

### Ограничение снизу (`LIMIT_TYPE.LOW`)

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "temperature",
    limit_type = am.LIMIT_TYPE.LOW,
    low = 10,
    hyst_low = 2,  -- сброс при temperature > 12
    class = am.ALARM_CLASS.WARN,
    msg = "Температура ниже нормы",
}
```

### Ограничение сверху (`LIMIT_TYPE.HIGH`)

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "pressure",
    limit_type = am.LIMIT_TYPE.HIGH,
    high = 100,
    hyst_high = 5,  -- сброс при pressure < 95
    class = am.ALARM_CLASS.ERROR,
    msg = "Превышение давления",
}
```

### Ограничение с двух сторон (`LIMIT_TYPE.LOW_HIGH`)

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "level",
    limit_type = am.LIMIT_TYPE.LOW_HIGH,
    low = 20,
    high = 80,
    hyst_low = 2,
    hyst_high = 2,
    class = am.ALARM_CLASS.WARN,
    msg = "Уровень вне диапазона",
}
```

> ⚠️ При `LOW_HIGH` должно выполняться `low ≤ high`, иначе будет ошибка валидации.

---

## Аналоговая тревога с уставками из каналов

Если уставки хранятся в каналах СИАМ, используйте `get_limit_from_chan = true`.

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "temperature",
    limit_type = am.LIMIT_TYPE.LOW_HIGH,
    ch_low = "temperature_low_limit",
    ch_high = "temperature_high_limit",
    hyst_low = 1,
    hyst_high = 1,
    analog = {
        get_limit_from_chan = true,  -- брать low/high из каналов ch_low/ch_high
    },
    class = am.ALARM_CLASS.WARN,
    msg = "Температура вне диапазона",
}
```

> 💡 Значения `low` и `high` в этом случае игнорируются — берутся из каналов `ch_low` и `ch_high` через `getEstimate`.

---

## Тревога из Кодесис (CS_CLIENT)

Повторяет состояние тревоги из менеджера тревог Кодесис.

```lua
atable:alarm{
    logic = am.LOGIC.CS_CLIENT,
    cs_alarm_state = getValue("cs_alarm_state"),  -- значение из CS_ALARM_STATE
    cs_ack = "cs_ack_channel",                     -- канал квитирования
    class = am.ALARM_CLASS.ERROR,
    msg = "Тревога из Кодесис",
}
```

### Возможные состояния `cs_alarm_state`:

| Состояние | Поведение |
|-----------|-----------|
| `NORMAL` | Тревога неактивна |
| `PENDING` | Условие активно, тревога неактивна |
| `ACTIVE` | Тревога активна |
| `WAITING_FOR_CONFIRMATION` | Неактивна, требует квитирования |
| `ACTIVE_ACKNOWLEDGED` | Активна и квитирована |

---

## Способы квитирования

### `CONFIRM_METHOD.REP` — деактивация

Тревога просто исчезает при сбросе условия.

```lua
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = getValue("signal") > 0,
    class = am.ALARM_CLASS.ERROR,
    msg = "Авария",
    confirm_method = am.CONFIRM_METHOD.REP,
}
```

### `CONFIRM_METHOD.REP_ACK` — подтверждение деактивированной

После деактивации тревога остаётся в списке как "неквитированная" (серая), пока оператор не подтвердит.

```lua
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = getValue("signal") > 0,
    class = am.ALARM_CLASS.ERROR,
    msg = "Авария",
    confirm_method = am.CONFIRM_METHOD.REP_ACK,
}
```

---

## Несколько таблиц тревог

### Несколько таблиц тревог в одном скрипте:

```lua
local am = require("meralualib.v1_0_0.alarm_manager")

local atable1 = am.Atable:new{
    table_id = 1,
    module_name = "Система_01",
}

local atable2 = am.Atable:new{
    table_id = 2,
    module_name = "Система_02",
}

function lua_main()
    am:upd()

    atable1:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("signal_1") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "Авария в системе 1",
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("signal_2") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "Предупреждение в системе 2",
    }
end
```

### Несколько таблиц тревог в разных скриптах - каждая таблица имеет свой `table_id`:

```lua
-- скрипт 1
local am = require("meralualib.v1_0_0.alarm_manager")

local atable = am.Atable:new{
    table_id = 1,
    module_name = "Система_01",
}

function lua_main()
    am:upd()

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("signal_1") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "Авария в системе 1",
    }
end
```

```lua
-- скрипт 2
local am = require("meralualib.v1_0_0.alarm_manager")

local atable = am.Atable:new{
    table_id = 2,
    module_name = "Система_02",
}

function lua_main()
    am:upd()

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("signal_2") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "Авария в системе 2",
    }
end
```

### Обращение к одной таблице тревог из разных скриптов - таблицы имеют одинаковый `table_id`:

```lua
-- скрипт 1
local am = require("meralualib.v1_0_0.alarm_manager")

local atable = am.Atable:new{
    table_id = 1,
    module_name = "Система_01",
}

function lua_main()
    am:upd()

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("signal_1") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "Авария в системе 1, сигнал 1",
    }
end
```

```lua
-- скрипт 2
local am = require("meralualib.v1_0_0.alarm_manager")

local atable = am.Atable:new{
    table_id = 1,
    module_name = "Система_01",
}

function lua_main()
    am:upd()

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("signal_2") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "Авария в системе 1, сигнал 2",
    }
end
```

---

## Настройка внешнего вида

### Мигание при появлении (`BLINK`)

```lua
am.manager_settings.alarm_appearance = am.ALARM_APPEARANCE.BLINK
```

### Плавная вспышка (`FLASH`, по умолчанию)

```lua
am.manager_settings.alarm_appearance = am.ALARM_APPEARANCE.FLASH
```

### Без эффектов (`STATIC`)

```lua
am.manager_settings.alarm_appearance = am.ALARM_APPEARANCE.STATIC
```

> ⚠️ Настройки применяются **до** первого вызова `am:upd()`.

---

## Настройка цветов

Можно переопределить стандартные цвета тревог:

```lua
am.manager_settings.msg_color = {
    error = 0x000000FF,  -- красный (в формате BBGGRR)
    warn  = 0x0000A5FF,  -- оранжевый
    info  = 0x0000FFFF,  -- жёлтый
    unack = 0x00808080,  -- серый для неквитированных
}
```

> 💡 Формат цвета — `0x00BBGGRR` (C++ Hex). Например, чистый красный: `0x000000FF`.

---

## Кнопка квитирования 
(⚠️ в разработке)

Если `ack_btn = true`, модуль создаст канал кнопки квитирования для таблицы:

```lua
local atable = am.Atable:new{
    table_id = 1,
    module_name = "Система_01",
    ack_btn = true,  -- создать канал кнопки
}
```

Будет создан канал:
```
alarm_manager.table_id_1.acknow
```

Этот канал можно привязать к кнопке на мнемосхеме для квитирования всех неквитированных тревог таблицы.

---

## Отображение значений в сообщении

### Показывать имя канала и пределы

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "temperature",
    limit_type = am.LIMIT_TYPE.HIGH,
    high = 80,
    analog = {
        msg_detail = true,  -- добавит ": 'temperature' > 80" к сообщению
    },
    class = am.ALARM_CLASS.WARN,
    msg = "Перегрев",
}
-- Сообщение: "Перегрев: 'temperature' > 80"
```

### Показывать текущее значение параметра

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "temperature",
    limit_type = am.LIMIT_TYPE.HIGH,
    high = 80,
    analog = {
        msg_detail = true,
        display_val = true,  -- добавит "(= 85.3)" к сообщению
    },
    class = am.ALARM_CLASS.WARN,
    msg = "Перегрев",
}
-- Сообщение: "Перегрев: 'temperature'(= 85.3) > 80"
```

### Показывать ID тревоги в сообщении

```lua
local atable = am.Atable:new{
    table_id = 1,
    module_name = "Система_01",
    display_id_at_msg = true,  -- добавит "[id5]" в начало
}
```

### Скрывать лейбл состояния

По умолчанию в начале сообщения добавляется `[Активна]`, `[Неактивна, неквитирована]`. Чтобы отключить:

```lua
local atable = am.Atable:new{
    table_id = 1,
    module_name = "Система_01",
    display_alarm_state_label = false,
}
```

---

## Приоритеты тревог

В пределах одного класса можно сортировать тревоги по приоритету (1 — высший, 1000 — низший).

```lua
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = getValue("critical_signal") > 0,
    class = am.ALARM_CLASS.ERROR,
    msg = "Критическая авария",
    prior = 1,  -- самый высокий приоритет
}

atable:alarm{
    logic = am.LOGIC.EVENT,
    event = getValue("minor_signal") > 0,
    class = am.ALARM_CLASS.ERROR,
    msg = "Незначительная авария",
    prior = 500,  -- низкий приоритет
}
```

---

## Продвинутые примеры

### Комплексная тревога с задержкой и гистерезисом

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "reactor_temperature",
    limit_type = am.LIMIT_TYPE.LOW_HIGH,
    low = 200,
    high = 450,
    hyst_low = 10,   -- сброс при < 210
    hyst_high = 15,  -- сброс при < 435
    delay_on = 3,
    delay_off = 5,
    prior = 10,
    analog = {
        msg_detail = true,
        display_val = true,
    },
    class = am.ALARM_CLASS.ERROR,
    msg = "Температура реактора вне диапазона",
}
```

### Динамическая регистрация тревог в цикле

```lua
local signals = {
    { name = "pump_1", msg = "Насос 1" },
    { name = "pump_2", msg = "Насос 2" },
    { name = "pump_3", msg = "Насос 3" },
}

function lua_main()
    am:upd()

    for _, sig in ipairs(signals) do
        atable:alarm{
            logic = am.LOGIC.DISCRETE,
            channel = sig.name .. "_fault",
            discrete_val = 0,
            class = am.ALARM_CLASS.ERROR,
            msg = "Неисправность: " .. sig.msg,
        }
    end
end
```

### Разные классы тревог для одного сигнала

```lua
local temperature = getValue("reactor_temp")

-- Предупреждение при небольшом превышении
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = temperature > 80 and temperature <= 90,
    class = am.ALARM_CLASS.WARN,
    msg = "Температура повышена",
    prior = 100,
}

-- Авария при сильном превышении
atable:alarm{
    logic = am.LOGIC.EVENT,
    event = temperature > 90,
    class = am.ALARM_CLASS.ERROR,
    msg = "Критический перегрев",
    prior = 1,
}
```

---

## Типичные ошибки

### ❌ Ошибка 1: Вызов `atable:alarm{}` внутри `if`

```lua
if some_condition then
    atable:alarm{ ... }  -- ОШИБКА! ID тревоги будет меняться
end
```

**Почему плохо:** ID тревоги генерируется при каждом вызове. Если условие ложно, тревога не зарегистрируется, и в следующем цикле получит новый ID.

**Решение:** Регистрировать всегда, управлять через `event`:

```lua
local alarm = atable:alarm{ logic = am.LOGIC.EVENT, ... }
alarm.event = some_condition
```

### ❌ Ошибка 2: `low > high` при `LIMIT_TYPE.LOW_HIGH`

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    limit_type = am.LIMIT_TYPE.LOW_HIGH,
    low = 100,
    high = 50,  -- ОШИБКА: low > high
}
```

### ❌ Ошибка 3: Пустое имя канала

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "",  -- ОШИБКА: channel name is empty
}
```

### ❌ Ошибка 4: Несуществующий канал в СИАМ

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    channel = "nonexistent_channel",  -- ОШИБКА: does not exist at SIAM
}
```

### ❌ Ошибка 5: Отрицательный гистерезис

```lua
atable:alarm{
    logic = am.LOGIC.ANALOG,
    hyst_low = -5,  -- ОШИБКА: cannot be less than zero
}
```

---

## Связанные разделы

- [README](../README.md) — краткое введение и быстрый старт
- [API](API.md) — подробное описание интерфейса