--[[
-- Модуль обработки аналоговых значений.
--]]

local t = {}
t.MODULE_PATH = "meralualib\\"
t.MODULE_NAME = "'" .. t.MODULE_PATH .. "analog'"


local collect = require("meralualib\\collect")
local dict_find_key = collect.dict_find_key
local list_extend = collect.list_extend

local datatype = require("meralualib\\datatype")
local CH_NOT_READY = datatype.CH_NOT_READY
local CH_STATUS = datatype.CH_STATUS
local DATAST = datatype.DATAST
local SIAM_LOG_CAT = datatype.SIAM_LOG_CAT
local SIAM_LOG_PRIOR = datatype.SIAM_LOG_PRIOR
local UNKNOWN = datatype.UNKNOWN


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
    t.ATrig = ATrig
end


do  -- Класс Канал.


    local Chans = {}

    Chans.class_instances = {}

    -- Получить информацию по аварийности тэгов.
    ---@return {} ALARMS Поканальный список аварий в формате - error(ошибка канала): boolean, msg(сообщение об ошибке): string 
    function Chans:get_alarm_info()
        local ALARMS = {}
        for _, class_instance in ipairs(Chans.class_instances) do
            local alarms = {}
            for i, param in ipairs(class_instance.params) do
                local error = false
                local alarm = {}
                if param.value ~= nil and param.value == CH_NOT_READY or param.status ~= nil and param.status ~= 0 then
                    error = true
                    class_instance.params[i].msg_ = "Неисправен параметр '" .. param.name .. "'. " .. param.msg .. ". " .. class_instance.module_name
                end
                table.insert(alarm, error)
                table.insert(alarm, class_instance.params[i].msg_)
                table.insert(alarms, alarm)
            end
            list_extend(ALARMS, alarms)
        end
        return ALARMS
    end

    function Chans:new(module_name)
        ---@class Chan
        local Chan = {}

        table.insert(Chans.class_instances, Chan)

        Chan.module_name = module_name or ""
        Chan.curr_instance_id = 0
        Chan.params = {}

        function Chan:get_instance_id()
            Chan.curr_instance_id = Chan.curr_instance_id + 1
            return Chan.curr_instance_id
        end

        function Chan:clear_instances()
            Chan.curr_instance_id = 0
        end

        -- Инмициализатор класса.
        ---@param ch_not_ok number Записываемое значение в канал, если его статус невалиден.
        function Chan:init(ch_not_ok)
            CH_NOT_READY = ch_not_ok or CH_NOT_READY
        end

        -- Получить информацию по авариям каналов.
        function Chan:get_alarm_info()
            local alarms = {}
            for i, param in ipairs(Chan.params) do
                local error = false
                local alarm = {}
                if param.value ~= nil and param.value == CH_NOT_READY or param.status ~= nil and param.status ~= 0 then
                    error = true
                    Chan.params[i].msg_ = "Неисправен параметр '" .. param.name .. "'. " .. param.msg .. ". " .. Chan.module_name
                end
                table.insert(alarm, error)
                table.insert(alarm, Chan.params[i].msg_)
                table.insert(alarms, alarm)
            end
            return alarms
        end

        -- Создать канал.
        ---@return Chan obj Возвращает объект Канал.
        function Chan:new(name)
            assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")

            -- Публичные свойства.
            local obj = {
                value = 0,  -- Значение канала.
                time = 0,  -- Время канала.
                status = 0,  -- Статус канала.
                msg = " ",  -- Сообщение в лог.
                msg_ = " 11",  -- Сообщение в лог.
                name = name,  -- Имя параметра.
                id = Chan:get_instance_id()
            }

            -- luacpLogMessage(SIAM_LOG_CAT["LUA_CALC"], "Создали канал "  .. obj.name, SIAM_LOG_PRIOR["NOTIFY"])

            local function status_check()
                if obj.status ~= CH_STATUS["VALID_DATA"] then
                    obj.msg = "Статус: " .. dict_find_key(CH_STATUS, obj.status, UNKNOWN)
                    obj.value = CH_NOT_READY
                end
            end

            local function is_invalid(status)
                return status ~= CH_STATUS["VALID_DATA"]
            end

            -- Получить данные из канала СИАМ.
            function obj:getValueEx(ch_name)
                obj.value, obj.time, obj.status = getValueEx(ch_name)
                status_check()
            end

            -- Получить данные.
            function obj:set(data)
                obj.value = data.value or obj.value
                obj.status = data.status or obj.status
                status_check()
                obj.msg = data.msg or obj.msg
                obj.name = data.name or obj.name
            end

            -- Сохранить данные в канал СИАМ.
            function obj:setValueEx(ch_name)
                setValueEx(ch_name, obj.value, obj.time, obj.status)
            end

            local function calc(a, b, op)
                local c = {}
                local a_
                local b_
                if type(a) == "table" and type(b) == "table" then
                    if is_invalid(a.status) or is_invalid(b.status) then
                        c.status = CH_STATUS.INVALID_DATA
                        c.time = a.status > b.status and a.time or b.time
                        if is_invalid(a.status) and is_invalid(b.status) then
                            c.msg = (
                                "Статус: " .. a.name .. " - "  .. dict_find_key(CH_STATUS, a.status, UNKNOWN) .. ", "
                                .. b.name .. " - "  .. dict_find_key(CH_STATUS, b.status, UNKNOWN)
                        )
                        elseif is_invalid(a.status) then
                            c.msg = "Статус: " .. a.name .. " - "  .. dict_find_key(CH_STATUS, a.status, UNKNOWN)
                        elseif is_invalid(b.status) then
                            c.msg = "Статус: " .. b.name .. " - "  .. dict_find_key(CH_STATUS, b.status, UNKNOWN)
                        end
                    else
                        c.status = CH_STATUS["VALID_DATA"]
                        c.time = a.time
                    end
                    a_ = a.value
                    b_ = b.value
                elseif type(a) == "table" and type(b) == "number" then
                        a_ = a.value
                        b_ = b
                        c.status = a.status
                        c.time = a.time
                        if is_invalid(a.status) then
                            c.msg = "Статус: " .. a.name .. " - "  .. dict_find_key(CH_STATUS, a.status, UNKNOWN)
                        end
                elseif type(a) == "number" and type(b) == "table" then
                        a_ = a
                        b_ = b.value
                        c.status = b.status
                        c.time = b.time
                        if is_invalid(b.status) then
                            c.msg = "Статус: " .. b.name .. " - "  .. dict_find_key(CH_STATUS, b.status, UNKNOWN)
                        end
                else
                    assert(false, "Value is not type of 'Chan' or 'number' ")
                end

                if a_ == CH_NOT_READY or b_ == CH_NOT_READY or is_invalid(c.status) then
                    c.value = CH_NOT_READY
                    c.status = CH_STATUS.INVALID_DATA
                elseif op == "add" then
                    c.value = a_ + b_
                elseif op == "sub" then
                    c.value = a_ - b_
                elseif op == "mul" then
                    c.value = a_ * b_
                elseif op == "div" then
                    c.value = a_ / b_
                elseif op == "pow" then
                    c.value = a_ ^ b_
                end
                return c
            end

            ---@protected
            function self.__add(a, b)
                return calc(a, b, "add")
            end

            ---@protected
            function self.__sub(a, b)
                return calc(a, b, "sub")
            end

            ---@protected
            function self.__mul(a, b)
                return calc(a, b, "mul")
            end

            ---@protected
            function self.__div(a, b)
                return calc(a, b, "div")
            end

            ---@protected
            function self.__pow(a, b)
                return calc(a, b, "pow")
            end

            setmetatable(obj, self)
            self.__index = self

            local instance_not_exist = true
            for i, param in ipairs(Chan.params) do
                if param.id == obj.id then
                    obj = Chan.params[i]
                    instance_not_exist = false
                end
            end

            if instance_not_exist then
                table.insert(Chan.params, obj)
            end

            return obj
        end
        setmetatable(Chan, Chans)
        Chans.__index = Chans
        return Chan
    end


    t.Chans = Chans
end


--- Декоратор проверки валидности передаваемого параметра в функцию.
---@param ch_not_ready number значение, которое запишется в параметр при невалидном статусе параметра.
---@param f_status_bad number статус функции при невалидности параметра.
---@return function
function t.ch_qlty(ch_not_ready, f_status_bad)
    ---@param func function Декорируемая функция.
    ---@param ch_qty number|nil Количество каналов, передаваемых в функцию.
    ---@param ret_qty number|nil Количество возвращаемых функцией значений.
    return function(func, ch_qty, ret_qty)
        ---@return any result Экземпляры канала, Статус работы передаваемой функции.
        return function(...)
            local f_status = {} -- Статус работы передаваемой функции.
            local args = {...}  -- Список передаваемых аргументов класса Chan в функцию.

            local f_result = {}  -- Результат выполнения функции.
            local values = {}  -- Список передаваемых в функцию аргументов.
            local time  -- Время параметра.
            local status  -- Статус параметра.
            local chan_qty = ch_qty or #args  -- Число каналов.
            local ret_qty = ret_qty or 1  -- Число возвращаемых функцией значений.
            local f_calc = true  -- Флаг разрешения работы функции.
            for i = 1, chan_qty do
                if args[i].status ~= 0 or args[i].value == ch_not_ready then
                    time = args[i].time
                    status = args[i].status
                    f_calc = false
                    break
                end
                table.insert(values, args[i].value)
                time = args[i].time
                status = args[i].status
            end
            local params = {}  -- Параметры на выходе декоратора.
            if f_calc then
                for i = chan_qty + 1, #args do
                    table.insert(values, args[i])
                end
                f_result = table.pack(func(table.unpack(values)))
                f_status = f_result[#f_result]
                for i = 1, ret_qty do
                    local param = t.Chan:new()
                    param.value = f_result[i]
                    param.time = time
                    param.status = status
                    table.insert(params, param)
                end
            else
                f_status.status = f_status_bad
                f_status.msg = "msg"
                f_status.func = "func"
                f_status.param = "param"
                for i = 1, ret_qty do
                    local param = t.Chan:new()
                    param.value = ch_not_ready
                    param.time = time
                    param.status = status
                    table.insert(params, param)
                end
            end
            table.insert(params, f_status)
            return table.unpack(params)
        end
    end
end





--- Декоратор проверки валидности передаваемого параметра в функцию.
---@param func table Декорируемая функция.
---@param ch_qty? number|nil Количество каналов, передаваемых в функцию.
---@param ret_qty? number|nil Количество возвращаемых функцией значений.
function t.ch_qlty_2(func, ch_qty, ret_qty)
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
                table.insert(msg, "'" .. arg.name .. "' - " .. dict_find_key(CH_STATUS, arg.status, UNKNOWN))
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


return t
