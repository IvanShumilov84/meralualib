--[[
-- Модуль обработки аналоговых значений.
--]]

local M = {}
M.MODULE_PATH = "meralualib\\"
M.MODULE_NAME = "'" .. M.MODULE_PATH .. "analog'"


local collect = require("meralualib\\collect")
local dict_find_key = collect.dict_find_key
local dict_sorted = collect.dict_sorted

local datatype = require("meralualib\\datatype")
local CH_NOT_READY = datatype.CH_NOT_READY
local CH_STATUS = datatype.CH_STATUS
local CH_STATUS_MSG = datatype.CH_STATUS_MSG
local DATAST = datatype.DATAST
local SIAM_LOG_CAT = datatype.SIAM_LOG_CAT
local SIAM_LOG_PRIOR = datatype.SIAM_LOG_PRIOR
local UNKNOWN = datatype.UNKNOWN
local UNKNOWN_MSG = datatype.UNKNOWN_MSG

local tags = require("meralualib\\tags")


do -- Класс триггер изменения аналогового значения.
    ATrig = {}

    -- Тело класса.
    function ATrig:new()

        -- Публичные свойства.
        local obj = {
            value = 0, --  [вход] Значение для детектирования его изменения.
            step = 0, --  [вход] Шаг изменения значения.
            q = false, --  [выход] Состояние изменения значения.
            qu = false, --  [выход] Состояние увеличения значения.
            qd = false --  [выход] Состояние уменьшения значения.
        }

        -- Приватные свойства.
        local private = {
            value_last = 0, --  Последнее значение.
            diff = 0, --  Разность между значениями.
        }

        -- Публичные методы.
        function obj:upd(value, step)
            -- Контроллер.
            assert(
                value == nil or type(value) == "number",
                "Argument 'value': expected 'number', got '" .. type(value) .. "'. "
            )
            assert(
                step == nil or type(step) == "number",
                "Argument 'step': expected 'number', got '" .. type(step) .. "'. "
            )
            self.value = value or self.value
            self.step = step or self.step
            private.diff = self.value - private.value_last
            self.q = math.abs(private.diff) > self.step
            self.qu = self.value > private.value_last and math.abs(private.diff) > self.step
            self.qd = self.value < private.value_last and math.abs(private.diff) > self.step
            private.value_last = self.value
            return self.q, self.qu, self.qd
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    M.ATrig = ATrig
end


do  -- Класс Канал.

        ---@class Chan
        local Chan = {}
        local DASHLINE = "------------------------------------------------"
        local chprefix = {}  -- Префиксы к названиям каналов.
        local sep = "."  -- Разделитель в названиях каналов.
        local module_name = ""  -- Имя вызывающего модуля.
        local log_module_info = ""  -- Информация о вызывающем модуле для лога.
        local curr_instance_id = 0  -- Текущий идентификационный номер канала.
        local params = {}  -- Список созданных каналов.
        local test_ch_prefix = ""  -- Префикс имён тестовых каналов.
        local test_ch_prefix_def = "test."  -- Префикс имён тестовых каналов по умолчанию.
        local test_mode = false  -- Флаг работы каналов в тестовом режиме на чтение данных.
        local tags_conf = {}  -- Конфигурация для создания тэгов/каналов.
        local test_enbl = false  -- Использовать тестовый режим.
        local comments = {}
        Chan.tags = {}  -- Созданные тэги для манипуляций в коде.

        -- Создать список имён каналов СИАМ.
        local function create_channels()
            local ttag = {}
            for _, tag in ipairs(tags_conf) do
                if tag.type == nil then tag.type = "" end
                if comments[tag.type] == nil then comments[tag.type] = "" end
                if tag.create_chan then
                    local item = {}
                    item.name = chprefix[tag.type] and (chprefix[tag.type] .. tag.chan_name) or tag.chan_name
                    item.info = comments[tag.type] .. " канал для тэга '" .. tag.chan_name  .. "' " .. log_module_info
                    table.insert(ttag, item)
                end
                if tag.test and test_enbl then
                    local item = {}
                    item.name = test_ch_prefix .. tag.tag_name
                    item.info = "Тестовый канал для тэга '" .. tag.tag_name  .. "' " .. log_module_info
                    table.insert(ttag, item)
                end
            end
            tags:CreateNewTags(ttag)
        end

        -- Запись в лог СИАМ.
        local function print_to_log(msg)
            luacpLogMessage(SIAM_LOG_CAT["LUA_CALC"], msg, SIAM_LOG_PRIOR["NOTIFY"])
        end

        -- Создать тэги скриптов.
        local function create_tags()
            -- Создаём тэги.
            for _, tag in ipairs( tags_conf) do
                if tag.create_tag then
                    if not Chan.tags[tag.type] then Chan.tags[tag.type] = {} end
                    Chan.tags[tag.type][tag.tag_name] = Chan:new(tag.tag_name)
                    for k, v in pairs(tag) do
                        Chan.tags[tag.type][tag.tag_name][k] = v
                    end
                    Chan.tags[tag.type][tag.tag_name].chan_name = chprefix[tag.type] and (chprefix[tag.type] .. tag.chan_name) or tag.chan_name

                    if tag.avg then
                        for _, tname in ipairs(tag.values) do
                            Chan.tags[tag.type][tname] = Chan:new(tname)
                            Chan.tags[tag.type][tname].chan_name = tname
                            Chan.tags[tag.type][tname].type = "measure"
                        end
                    end
                end
            end

            -- Функция сортировки.
            local function sort_order(a, b)
                return string.lower(a) < string.lower(b)
            end

            -- Распечатываем список созданных тэгов.
            print_to_log(DASHLINE)
            for tag_type, tag_list in pairs(Chan.tags) do
                local id = 1
                for name, _ in dict_sorted(tag_list, sort_order) do
                    local msg = id .. " Создали '" .. tag_type .. "' тэг '"  ..  Chan.tags[tag_type][name].tag_name .. "' (канал '" .. Chan.tags[tag_type][name].chan_name .. "') " .. log_module_info
                    print_to_log(msg)
                    id = id + 1
                end
            print_to_log(DASHLINE)
            end
        end

        ---@class args
        ---@field tags_conf table Конфигурация для создания тэгов/каналов.
        ---@field module_name? string|nil Имя модуля, из которого вызывается класс.
        ---@field ch_not_ok? number|nil Записываемое значение в канал, если его статус невалиден.
        ---@field test_ch_prefix? string|nil Префикс тестового имени канала.
        ---@field test_enbl? boolean|nil Использавать тестовый режим.
        ---@field chprefix? boolean|nil Словарь префиксов имён каналов.
        ---@field sep? boolean|nil Разделитель в имени канала между префиксом и именем.

        -- Инициализатор класса.
        function Chan:init(args)
            args = args or {}
            tags_conf = args.tags_conf or {}
            module_name = args.module_name or ""
            log_module_info = (module_name == "") and "" or ("[Модуль '" .. module_name .. "']")
            CH_NOT_READY = args.ch_not_ok or CH_NOT_READY
            test_ch_prefix = args.test_ch_prefix or test_ch_prefix_def
            test_enbl = args.test_enbl or false
            chprefix = args.chprefix or {}
            sep = args.sep and args.sep or sep
            for k, v in pairs(chprefix) do
                chprefix[k] = v .. sep
            end
            comments = args.comments or {}
            create_channels()
            create_tags()
        end

        local function get_instance_id()
            curr_instance_id = curr_instance_id + 1
            return curr_instance_id
        end

        ---@class args
        ---@field test_mode boolean Флаг включения тестового режима.

        -- Контроллер.
        function Chan:upd(args)
            curr_instance_id = 0
            test_mode = args.test_mode

            for _, param in ipairs(params) do
                param.error_handle = false
                if test_mode and param.test then
                    param.error_handle = true
                elseif not test_mode and (param.type == "measure" or param.type == "calc") then
                    param.error_handle = true
                end
                param:get_source_name()
                param:get_dest_name()
            end
        end

        -- Получить информацию по авариям каналов.
        function Chan:get_alarm_info(args)
            local alarm_type = args.alarm_type
            local table_id = args.table_id
            local alarms = {}
            local chan_errors = false
            for i, param in ipairs(params) do
                local error = false
                if param.error_handle and (param.value ~= nil and param.value == CH_NOT_READY or param.status ~= nil and param.status ~= 0) then
                    error = true
                    local tag_pref = param.type and param.type or ""
                    params[i].msg_ = "Неисправен тэг '" .. tag_pref .. "." .. param.tag_name .. "' (канал '" .. param.source_name .. "'). " .. param.msg .. ". " .. log_module_info
                end
                local alarm = {
                    event = error,
                    type = alarm_type,
                    table_id = table_id,
                    msg = params[i].msg_,
                }
                table.insert(alarms, alarm)
                chan_errors = error or chan_errors
            end
            return alarms, chan_errors
        end

        -- Получить число созданных каналов.
        function Chan:get_channels_qty()
            return #params
        end

        -- Создать канал.
        ---@return Chan obj Возвращает объект Канал.
        function Chan:new(tag_name)
            assert(type(tag_name) == "string", "Parameter 'tag_name': expected 'string', got '" .. type(tag_name) .. "'. ")

            -- Публичные свойства.
            local obj = {
                calc = false,
                measure = false,
                value = 0,  -- Значение канала.
                time = 0,  -- Время канала.
                status = 0,  -- Статус канала.
                msg = " ",  -- Сообщение в лог.
                msg_ = " ",  -- Сообщение в лог.
                tag_name = tag_name,  -- Имя параметра.
                chan_name = "",  -- Имя канала.
                source_name = "",  -- Имя канала для вычитки значения.
                dest_name = "",  -- Имя канала для записи значения.
                id = get_instance_id(),  -- Идентификационный номер тэга.
                error_handle = false,  -- Флаг необходимости обработки ошибок тэга.
            }

            local function status_check()
                if obj.status ~= CH_STATUS["VALID_DATA"] then
                    local status = dict_find_key(CH_STATUS, obj.status, UNKNOWN)
                    obj.msg = "Статус: '" .. (CH_STATUS_MSG[status] or UNKNOWN_MSG) .. " (" .. status .. ")'"
                    obj.value = CH_NOT_READY
                end
            end

            function obj:get_source_name()
                obj.source_name = test_mode and (test_ch_prefix .. obj.tag_name) or obj.chan_name
            end

            function obj:get_dest_name()
                if obj.type == "measure" then
                    obj.dest_name = test_mode and (test_ch_prefix .. obj.tag_name) or obj.chan_name
                end
                if obj.type == "calc" then
                    obj.dest_name = obj.chan_name
                end
            end

            -- Получить данные из канала СИАМ.
            function obj:getValueEx()
                obj.value, obj.time, obj.status = getValueEx(obj.source_name)
                status_check()
            end

            -- Сохранить данные в тэг.
            function obj:set(data)
                obj.value = data.value or obj.value
                obj.status = data.status or obj.status
                status_check()
                obj.msg = data.msg or obj.msg
                obj.tag_name = data.tag_name or obj.tag_name
            end

            -- Сохранить данные в канал СИАМ.
            function obj:setValueEx()
                setValueEx(obj.dest_name, obj.value, obj.time, obj.status)
            end

            setmetatable(obj, self)
            self.__index = self

            local instance_not_exist = true
            for i, param in ipairs(params) do
                if param.id == obj.id then
                    obj = params[i]
                    instance_not_exist = false
                end
            end

            if instance_not_exist then
                table.insert(params, obj)
            end

            return obj
        end

    M.Chan = Chan
end


--- Декоратор проверки валидности передаваемого параметра в функцию.
---@param func table Декорируемая функция.
---@param ch_qty? number|nil Количество каналов, передаваемых в функцию.
---@param ret_qty? number|nil Количество возвращаемых функцией значений.
function M.ch_qlty(func, ch_qty, ret_qty)
    ---@return any res_channels Экземпляры канала, Статус работы передаваемой функции.
    return function(...)
        local args = {...}  -- Список передаваемых аргументов класса Chan в функцию.
        local values = {}  -- Список передаваемых в функцию аргументов.
        local chan_qty = ch_qty or #args  -- Число каналов.
        local ret_qty = ret_qty or 1  -- Число возвращаемых функцией значений.

        -- Проверка передаваемых в функцию каналов на валидность.
        local invalid_args = {}
        for i = 1, chan_qty do
            if args[i].status ~= 0 or args[i].value == CH_NOT_READY then
                table.insert(invalid_args, args[i])
            end
            table.insert(values, args[i].value)
        end

        local res_channels = {}
        if #invalid_args ~= 0 then  -- Если входные каналы функции невалидны.
            local msg = {}
            for _, arg in ipairs(invalid_args) do
                local status = dict_find_key(CH_STATUS, arg.status, UNKNOWN)
                table.insert(msg, "'" .. arg.tag_name .. "' - '" .. (CH_STATUS_MSG[status] or UNKNOWN_MSG) .. " (" .. status .. ")'")
            end
            for i = 1, ret_qty do
                local chan = {}
                chan.value = CH_NOT_READY
                chan.status = CH_STATUS.INVALID_DATA
                chan.msg = "Статус: аргументы функции '" .. func.name .. "' невалидны: " .. table.concat(msg, ", ")
                table.insert(res_channels, chan)
            end
        else  -- Если входные каналы функции валидны - вызываем функцию.
            for i = chan_qty + 1, #args do
                table.insert(values, args[i])
            end
            local f_result = func(table.unpack(values))
            local results = f_result.results
            local f_status = f_result.status

            if f_status.status == 0 then  -- Если функция отработала корректно - возвращаем результаты расчётов.
                for i = 1, ret_qty do
                    local chan = {}
                    chan.value = results[i]
                    chan.status = CH_STATUS["VALID_DATA"]
                    table.insert(res_channels, chan)
                end
            else  -- Если функция отработала некорректно - формируем ошибки в расчётных каналах.
                for i = 1, ret_qty do
                    local chan = {}
                    chan.value = CH_NOT_READY
                    local error = dict_find_key(DATAST, f_status.status, UNKNOWN)
                    chan.status = CH_STATUS.INVALID_DATA
                    chan.msg = "Статус: функция " .. func.name .. " вернула ошибку " .. error .. ", " .. f_status.msg
                    table.insert(res_channels, chan)
                end
            end
        end
        return res_channels
    end
end


do  -- Функция арифметических вычислений.

    local fname = "arithmetic_function"
    M[fname] = {name = fname}
    local mt = {}
    setmetatable(M[fname], mt)

    -- Функция арифметических вычислений.
    ---@param value number Тэг.
    ---@param const number Константа.
    ---@param op string Вид арифметической операции: "+", "-", "*", "/", "^", .
    ---@return {results: {result_1: number}, status: {status: number, msg: string}} ret 
    mt.__call = function(self, value, const, op)
        local ret = {}  -- Возвращаемое функцией значение.
        local results = {}  -- Результаты расчётов.
        local result_1  -- Расчёт функции.
        local status = {  -- Статус работы функции.
            ["status"] = DATAST["OK"],
            ["msg"] = "",
        }
        if op == "+" then
            result_1 = value + const
        elseif op == "-" then
            result_1 = value - const
        elseif op == "*" then
            result_1 = value * const
        elseif op == "/" then
            result_1 = value / const
        elseif op == "^" then
            result_1 = value ^ const
        else
            result_1 = CH_NOT_READY
            status["status"] = DATAST.ERROR_CALC
            status["msg"] = "Не разрешённая операция"
        end
        table.insert(results, result_1)
        ret.results = results
        ret.status = status
        return ret
    end
end


return M
