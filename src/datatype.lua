--[[

]]


-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."


local M = {}


do
    --- Класс Перечислитель (Enum)
    ---@class Enum
    ---@field values table Значения перечисления.
    ---@field names table Имена перечисления.
    ---@field get_name fun(self: Enum, value: any): string Получить имя по значению.
    ---@field get_value fun(self: Enum, name: string): any Получить значение по имени.
    ---@field is_valid_value fun(self: Enum, value: any): boolean Проверить, существует ли значение.
    ---@field is_valid_name fun(self: Enum, name: string): boolean Проверить, существует ли имя.
    ---@field get_all_names fun(self: Enum): string[] Получить все имена.
    ---@field get_all_values fun(self: Enum): any[] Получить все значения.
    ---@field get_all_pairs fun(self: Enum): table[] Получить все пары (имя, значение).
    ---@field to_string fun(self: Enum, value: any): string Преобразовать значение в строку.
    ---@field get_name_enum fun(self: Enum): string Получить имя перечисления.
    ---@field get_description fun(self: Enum): string Получить описание перечисления.
    ---@field pairs fun(self: Enum): fun(): string, any Итератор для перебора всех значений.
    ---@field pairs_sorted fun(self: Enum): fun(): string, any Итератор для перебора всех имён (в алфавитном порядке).
    ---@field find_by_name_pattern fun(self: Enum, pattern: string): table[] Найти значение по частичному совпадению имени.
    local Enum = {}

    -- Константа для несуществующих значений
    local RESERVED_VALUE = -1
    local RESERVED_NAME = "_UNKNOWN"

    --- Создать новый экземпляр перечисления.
    ---@param enum_values table<string, any> Таблица значений перечисления в формате {имя = значение}.
    ---@param options? table<string, any> Опции перечисления.
    ---@param options.name? string Имя перечисления (по умолчанию "Enum").
    ---@param options.description? string Описание перечисления.
    ---@return Enum  -- Созданный экземпляр перечисления.
    ---@raise string Если одно из значений равно -1 (зарезервировано).
    function Enum:new(enum_values, options)
        options = options or {}

        -- Проверка: значение -1 зарезервировано
        for name, value in pairs(enum_values) do
            if value == RESERVED_VALUE then
                error(string.format(
                    "Enum '%s': значение %d зарезервировано для несуществующих ключей. " ..
                    "Используйте другое значение для '%s'.",
                    options.name or "Enum",
                    RESERVED_VALUE,
                    name
                ))
            end
        end

        local obj = {
            _name = options.name or "Enum",  -- Имя перечисления
            _description = options.description or "",  -- Описание
            _reserved_value = RESERVED_VALUE,  -- Зарезервированное значение
            _reserved_name = RESERVED_NAME,  -- Имя для зарезервированного значения
        }

        -- Значения перечисления
        obj.values = {}

        -- Имена перечисления (обратный индекс)
        obj.names = {}

        -- Копируем значения и создаём обратный индекс
        for name, value in pairs(enum_values) do
            obj.values[name] = value
            obj.names[value] = name
            obj[name] = value  -- Добавляем прямой доступ
        end

        -- Резервируем значение -1 для несуществующих ключей
        obj.names[RESERVED_VALUE] = RESERVED_NAME

        -- Устанавливаем метатаблицу с обработкой несуществующих ключей
        setmetatable(obj, {
            __index = function(t, key)
                -- Если ключ существует в перечислении - возвращаем его значение
                if rawget(t, key) ~= nil then
                    return rawget(t, key)
                end

                -- Если это метод класса Enum - возвращаем его
                local method = Enum[key]
                if method then
                    return method
                end

                -- Для несуществующих ключей возвращаем зарезервированное значение
                return RESERVED_VALUE
            end,

            -- Запрещаем присваивание новых ключей
            __newindex = function(t, key, value)
                error(string.format(
                    "Enum '%s': нельзя добавлять новые значения. " ..
                    "Ключ '%s' не существует в перечислении.",
                    t._name,
                    tostring(key)
                ))
            end
        })

        return obj
    end

    --- Получить имя по значению.
    ---@param value any Значение для поиска.
    ---@return string -- Имя значения или "_UNKNOWN" для несуществующих значений.
    function Enum:get_name(value)
        return self.names[value] or self._reserved_name
    end

    --- Получить значение по имени.
    ---@param name string Имя для поиска.
    ---@return any -- Значение или -1 для несуществующих имён.
    function Enum:get_value(name)
        local value = self.values[name]
        return value ~= nil and value or self._reserved_value
    end

    --- Проверить, существует ли значение.
    ---@param value any Значение для проверки.
    ---@return boolean -- true, если значение существует в перечислении.
    function Enum:is_valid_value(value)
        return self.names[value] ~= nil and value ~= self._reserved_value
    end

    --- Проверить, существует ли имя.
    ---@param name string Имя для проверки.
    ---@return boolean -- true, если имя существует в перечислении.
    function Enum:is_valid_name(name)
        return self.values[name] ~= nil
    end

    --- Проверить, является ли значение несуществующим (зарезервированным).
    ---@param value any Значение для проверки.
    ---@return boolean -- true, если значение равно -1.
    function Enum:is_unknown_value(value)
        return value == self._reserved_value
    end

    --- Получить все имена перечисления.
    ---@return string[] -- Массив имён.
    function Enum:get_all_names()
        local names = {}
        for name in pairs(self.values) do
            table.insert(names, name)
        end
        return names
    end

    --- Получить все значения перечисления.
    ---@return any[] -- Массив значений.
    function Enum:get_all_values()
        local values = {}
        for _, value in pairs(self.values) do
            table.insert(values, value)
        end
        return values
    end

    --- Получить все пары (имя, значение).
    ---@return table[] -- Массив таблиц в формате {name = string, value = any}.
    function Enum:get_all_pairs()
        local pairs_list = {}
        for name, value in pairs(self.values) do
            table.insert(pairs_list, {name = name, value = value})
        end
        return pairs_list
    end

    --- Преобразовать значение в строку.
    ---@param value any Значение для преобразования.
    ---@return string -- Строка в формате "ИМЯ (значение)".
    function Enum:to_string(value)
        local name = self:get_name(value)
        if value == self._reserved_value then
            return string.format("%s (%d) [НЕСУЩЕСТВУЮЩИЙ КЛЮЧ]", name, value)
        end
        return string.format("%s (%d)", name, value)
    end

    --- Получить имя перечисления.
    ---@return string -- Имя перечисления.
    function Enum:get_name_enum()
        return self._name
    end

    --- Получить описание перечисления.
    ---@return string -- Описание перечисления.
    function Enum:get_description()
        return self._description
    end

    --- Итератор для перебора всех значений.
    ---@return fun(): string, any -- Итератор, возвращающий имя и значение.
    function Enum:pairs()
        return pairs(self.values)
    end

    --- Итератор для перебора всех имён (в алфавитном порядке).
    ---@return fun(): string, any -- Итератор, возвращающий имя и значение в алфавитном порядке.
    function Enum:pairs_sorted()
        local keys = self:get_all_names()
        table.sort(keys)
        local i = 0
        return function()
            i = i + 1
            if keys[i] then
                return keys[i], self.values[keys[i]]
            end
        end
    end

    --- Найти значение по частичному совпадению имени.
    ---@param pattern string Шаблон для поиска (используется в функции :match()).
    ---@return table[] -- Массив таблиц в формате {name = string, value = any}.
    function Enum:find_by_name_pattern(pattern)
        local results = {}
        for name, value in pairs(self.values) do
            if name:match(pattern) then
                table.insert(results, {name = name, value = value})
            end
        end
        return results
    end
    M.Enum = Enum

    -- Пример использования #1:

    -- -- Создаём перечисление с именем и описанием
    -- local CSAlarmState = Enum:new({
    --     NOT_DEFINED = 255,
    --     NORMAL = 0,
    --     PENDING = 1,
    --     ACTIVE = 2,
    --     WAITING_FOR_CONFIRMATION = 3,
    --     ACTIVE_ACKNOWLEDGED = 4,
    -- }, {
    --     name = "CSAlarmState",
    --     description = "Состояние тревоги из Кодесис",
    -- })

    -- -- Создаём перечисление уровней
    -- local CSAlarmLevel = Enum:new({
    --     INFO = 0,
    --     WARNING = 1,
    --     ERROR = 2,
    --     CRITICAL = 3,
    -- }, {
    --     name = "CSAlarmLevel",
    --     description = "Уровень тревоги",
    -- })

    -- -- Использование:
    -- print("Имя перечисления:", CSAlarmState:get_name_enum())  -- "CSAlarmState"
    -- print("Описание:", CSAlarmState:get_description())        -- "Состояние тревоги из Кодесис"

    -- print("\nПеречисление (отсортировано):")
    -- for name, value in CSAlarmState:pairs_sorted() do
    --     print(string.format("  %s = %d", name, value))
    -- end

    -- -- Поиск по шаблону
    -- print("\nПоиск состояний с 'ACTIVE':")
    -- local results = CSAlarmState:find_by_name_pattern("ACTIVE")
    -- for _, item in ipairs(results) do
    --     print(string.format("  %s = %d", item.name, item.value))
    -- end

    -- -- Функция для работы с любым перечислением
    -- local function print_enum_info(enum)
    --     print(string.format("\n=== %s ===", enum:get_name_enum()))
    --     if enum:get_description() ~= "" then
    --         print("Описание: " .. enum:get_description())
    --     end
    --     print("Значения:")
    --     for name, value in enum:pairs_sorted() do
    --         print(string.format("  %s = %d", name, value))
    --     end
    -- end

    -- print_enum_info(CSAlarmState)
    -- print_enum_info(CSAlarmLevel)


    -- Пример использования #2: Создание перечисления с проверкой значения -1

    -- -- ✓ Корректное создание
    -- local CSAlarmState = Enum:new({
    --     NOT_DEFINED = 255,
    --     NORMAL = 0,
    --     PENDING = 1,
    --     ACTIVE = 2,
    --     WAITING_FOR_CONFIRMATION = 3,
    --     ACTIVE_ACKNOWLEDGED = 4,
    -- }, {
    --     name = "CSAlarmState",
    --     description = "Состояние тревоги из Кодесис"
    -- })

    -- -- ✗ Ошибка: значение -1 зарезервировано
    -- -- local BadEnum = Enum:new({
    -- --     OK = 0,
    -- --     ERROR = -1,  -- Будет ошибка!
    -- -- }, {
    -- --     name = "BadEnum"
    -- -- })
    -- -- Ошибка: "Enum 'BadEnum': значение -1 зарезервировано для несуществующих ключей..."


    -- Пример использования #3: Обращение к несуществующим ключам

    -- local CSAlarmState = Enum:new({
    --     NORMAL = 0,
    --     ACTIVE = 2,
    -- }, {
    --     name = "CSAlarmState"
    -- })

    -- -- Обращение к существующему ключу
    -- print(CSAlarmState.NORMAL)  -- 0
    -- print(CSAlarmState.ACTIVE)  -- 2

    -- -- Обращение к несуществующему ключу - возвращает -1
    -- print(CSAlarmState.UNKNOWN_STATE)  -- -1
    -- print(CSAlarmState.INVALID)  -- -1
    -- print(CSAlarmState.SomeRandomKey123)  -- -1

    -- -- Получение имени для несуществующего значения
    -- print(CSAlarmState:get_name(-1))  -- "UNKNOWN"
    -- print(CSAlarmState:to_string(-1))  -- "UNKNOWN (-1) [НЕСУЩЕСТВУЮЩИЙ КЛЮЧ]"

    -- -- Проверка на несуществующее значение
    -- print(CSAlarmState:is_unknown_value(-1))  -- true
    -- print(CSAlarmState:is_valid_value(-1))  -- false


    -- Пример использования #4: Попытка добавить новое значение (запрещено)

    -- local CSAlarmState = Enum:new({
    --     NORMAL = 0,
    --     ACTIVE = 2,
    -- }, {
    --     name = "CSAlarmState"
    -- })

    -- -- ✗ Ошибка: нельзя добавлять новые значения
    -- -- CSAlarmState.NEW_STATE = 5
    -- -- Ошибка: "Enum 'CSAlarmState': нельзя добавлять новые значения. Ключ 'NEW_STATE' не существует в перечислении."
end


M.CH_NOT_READY = -111111  -- Значение канала, если его статус НЕ ГОТОВ.
M.UNKNOWN = "UNKNOWN"
M.UNKNOWN_MSG = "НЕИЗВЕСТЕН"

-- Перечислитель состояний данных.
---@enum datast
M.DATAST = {
    OK = 0,  -- Данные корректны.
    NO_CALC = 1,  -- Состояние отсутствия расчёта данных.
    ERROR_CALC = 2,  -- Ошибка вычисления данных.
    NO_DATA = 3,  -- Нет данных.
    ZERO_DIV = 4,  -- Деление на ноль.
    CH_NOT_READY = 5,  -- Канал не готов.
}

-- Приоритеты в логе СИАМ.
---@enum siam_log_prior
M.SIAM_LOG_PRIOR = {
    ZEROTH = 0,  -- Нулевой.
    DEBUG = 1,  -- Отладочный.
    INFO = 2,  -- Информация.
    NOTIFY = 3,  -- Уведомление.
    SP_WARN = 4,  -- Уставка предупредительная.
    SP_ALARM = 5,  -- Уставка аварийная.
    WARNING = 6,  -- Предупреждение.
    ERROR = 7,  -- Ошибка.
    CRITICAL = 8  -- Критическая ошибка.
}

-- Категории элемента СИАМ "Журнал".
---@enum siam_log_cat
M.SIAM_LOG_CAT = {
    LUA_CALC = "Lua Calc",  -- Скрипты Lua.
    PKPAS = "ПКПАС",  -- Сообщения ПКПАС.
}

-- Перечислитель состояний канала СИАМ.
---@enum ch_status
M.CH_STATUS = {
    VALID_DATA = 0,  -- Корректные данные.
    EMPTY = 2147483648,  -- Состояние - нет данных, начальное состояние.
    INVALID_DATA = 1,  -- Не корректные данные в общем.
    ADC_OUT_OF_RANGE = 3,  -- Зашкал АЦП.
    TARE_OUT_OF_RANGE = 4,  -- Выход за границы ГХ.
    ALARM_HI_LOW = 8,  -- Превышение верхней предупредительной уставки.
    ALARM_HI_HI = 16,  -- Превышение верхней аварийной уставки.
    ALARM_LOW_LOW = 32,  -- Превышение нижней аварийной уставки.
    ALARM_LOW_HI = 64,  -- Превышение нижней предупредительной уставки.
    WIRE_BROKEN = 129,  -- Обрыв измерительной линии.
    HARDWARE_FAIL = 257,  -- Отказ оборудования.
    LOST_CONNECTION = 513,  -- Потеря связи с оборудованием.
    CHANNEL_DOWN = 1025,  -- Канал отключён.
    OBSOLETE_DATA = 2049,  -- Данные устарели.
    LINE_SHORT_CIRCUIT = 4097,  -- Короткое замыкание.
}

-- Перечислитель состояний канала СИАМ в виде сообщения.
---@enum ch_status_msg
M.CH_STATUS_MSG = {
    VALID_DATA = "Корректные данные",
    EMPTY = "Состояние - нет данных, начальное состояние",
    INVALID_DATA = "Не корректные данные в общем",
    ADC_OUT_OF_RANGE = "Зашкал АЦП",
    TARE_OUT_OF_RANGE = "Выход за границы ГХ",
    ALARM_HI_LOW = "Превышение верхней предупредительной уставки",
    ALARM_HI_HI = "Превышение верхней аварийной уставки",
    ALARM_LOW_LOW = "Превышение нижней аварийной уставки",
    ALARM_LOW_HI = "Превышение нижней предупредительной уставки",
    WIRE_BROKEN = "Обрыв измерительной линии",
    HARDWARE_FAIL = "Отказ оборудования",
    LOST_CONNECTION = "Потеря связи с оборудованием",
    CHANNEL_DOWN = "Канал отключён",
    OBSOLETE_DATA = "Данные устарели",
    LINE_SHORT_CIRCUIT = "Короткое замыкание",
}

-- Состояния Recorder.
M.RECORDER_STATE = {
	RS_STOP                    = 0x00000001,  -- Остановлен
	RS_VIEW                    = 0x00000002,  -- Режим получения данных/просмотра
	RS_REC                     = 0x00000004,  -- Режим записи
	RS_PLAYING                 = 0x00000008,  -- Режим воспроизведения
	RS_PLAY                    = 0x00000008,  -- Режим воспроизведения
	RS_HARDWAREFAULT           = 0x00000010,  -- Инициализация системы не прошла успешно
	RS_INITFAULT               = 0x00000020,  -- Инициализация системы не прошла успешно
	RS_NEEDDEVICERESET         = 0x00000040,  -- Требуется Reset девайса
	RS_NEEDHARDWARERESET       = 0x00000040,  -- Требуется Reset девайса
	RS_NEEDSOFTWARERESET       = 0x00000080,  -- Требуется програмной части драйвера
	RS_NEEDLINKSREFRESH        = 0x00000100,  -- Требуется обновление ссылок
	RS_PLAYMODE                = 0x00000200,  -- Настройка и работа в режиме воспроизведения
	RS_SIGNALLOADED            = 0x00000400,  -- Конфигурирование прошло успешно
	RS_CONFIGCHANGED           = 0x00000800,  -- Изменена конфигурация, требуется сохранение
	RS_CONFIGMODE              = 0x00001000,  -- Режим конфигурирования
	RS_PAUSE                   = 0x00002000,  -- Режим пауза
	RS_WAIT_REC_FINISH         = 0x00004000,  -- Режим ожидания окончания записи
	RS_CALIBRATE_MODE          = 0x00008000,  -- Режим калибровки
	RS_PACKETLOST              = 0x00010000,  -- Потери во время приема
	RS_RECEIVEERROR            = 0x00020000,  -- Сейчас идут потери
	RS_PLAYMODE_ENABLED        = 0x00040000,  -- Разрешен режим воспроизведения
	RS_ZBALANCE_PROC           = 0x00080000,  -- Находимся в процессе балансировки нуля
	RS_ERROR_CONDITION         = 0x00100000,  -- Находимся в состоянии ошибки
	RS_WARNING_CONDITION       = 0x00200000,  -- Находимся в состоянии предупреждения
	RS_ENABLEDPAUSE            = 0x40000000,
	RS_TERMINATION             = 0x80000000,  -- состояние завершения работы
}


return M
