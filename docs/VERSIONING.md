# Версионирование библиотеки MeraLuaLib

## Принцип работы

Используется **семантическое версионирование (SemVer)** - MAJOR.MINOR.PATCH (SemVer: v1.0.0, v1.1.0, и т.д.).

## Структура в репозитории (без версий)

В репозитории модули находятся без версионных папок:

```
meralualib/
├── src/                       # Папка исходного кода библиотеки
   ├── __conf.lua              # Конфигурация библиотеки
   ├── __version.lua           # Версия библиотеки (изменяется при релизе)
   ├── alarm_manager/          # Модуль alarm_manager
   │   ├── init.lua
   │   ├── version.lua
   │   └── utils/
   │       └── main.lua
   ├── datatype.lua
   ├── hmi.lua
   ├── tags.lua
   ├── timers.lua
   └── ... (другие модули)
```

Все внутренние импорты между модулями используют следующие пути:
```lua
local lib_path = "meralualib.src."

local datatype = require(lib_path .. "datatype")
local tags = require(lib_path .. "tags")
local module_utils = require(lib_path .. "module_utils")
```

## Структура при релизе (с версиями)

При выпуске релиза (например, v1.0.0) библиотека разворачивается в целевой среде со следующей структурой:

```
meralualib/
├── v1_0_0/
│   ├── __conf.lua
│   ├── __version.lua           -- версия библиотеки 1.0.0
│   ├── alarm_manager/
│   │   ├── init.lua
│   │   ├── version.lua         -- версия модуля
│   │   └── utils/
│   │       └── main.lua
│   ├── datatype.lua
│   ├── hmi.lua
│   ├── tags.lua
│   ├── timers.lua
│   └── ... (другие модули)
├── v1_1_0/
│   └── ... (следующая версия)
└── ...
```

### Обращение пользователей к модулям

Пользователи обращаются к модулям **через версию библиотеки**:

```lua
-- Для версии v1.0.0
local alarm_manager = require("meralualib.v1_0_0.alarm_manager")
local datatype = require("meralualib.v1_0_0.datatype")

-- Для версии v1.1.0
local alarm_manager = require("meralualib.v1_1_0.alarm_manager")
local datatype = require("meralualib.v1_1_0.datatype")
```

### Внутренние импорты в модулях
После сборки библиотеки внутри модулей используется обращение **через версию библиотеки**, аналогично обращению пользователей (см. выше).

## Процесс выпуска релиза

1. Обновить версию в файле `__version.lua`:
   ```lua
   M.version = {
       major = 1,
       minor = 0,
       patch = 0,
   }
   ```

2. Создать релизную структуру с именем версии (например, `v1_0_0/`).

3. Разместить файлы библиотеки в папке версии.

4. Пользователи могут обращаться к конкретной версии через:
   ```lua
   require("meralualib.v1_0_0.<module_name>")
   ```
   