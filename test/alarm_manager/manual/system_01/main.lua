--[[
	Тесть менеджера тревог в скрипте 1.
]]


--#region Импорт модулей.
local am = require("meralualib.src.alarm_manager")  -- Менеджер тревог.
--#endregion Импорт модулей.


am.manager_settings.alarm_appearance = am.ALARM_APPEARANCE.FLASH


local atable = am.Atable:new()  -- Экземпляр 1 таблицы Менеджера тревог.
atable.table_id = 1
atable.display_alarm_state_label = false
atable.display_id_at_msg = false
atable.alarm_delay_on = 1
atable.alarm_delay_off = 1

local atable2 = am.Atable:new()  -- Экземпляр 2 таблицы Менеджера тревог.
atable2.table_id = 2
atable2.display_alarm_state_label = true
atable2.display_id_at_msg = true


-- Менеджер тревог.
function lua_main()

	am:upd()

    --#region Обработка тревог.

    -- Скрипт 1 Таблица 1.
    -- Метод квитирования REP_ACK.
    local alarm = atable:alarm()
    alarm.logic = am.LOGIC.EVENT
    alarm.class = am.ALARM_CLASS.ERROR
    alarm.msg = "am_script_01_table_01_error_rep_ack_01. Авария"
    alarm.confirm_method = am.CONFIRM_METHOD.REP_ACK
    alarm.prior = 1
    alarm.delay_on = 1
    -- alarm.delay_off = 1
    if getValue("am_script_01_table_01_error_rep_ack_01") > 0 then
        alarm.event = true
    end

    local setpoint = 1
    alarm = atable:alarm()
    alarm.logic = am.LOGIC.EVENT
    alarm.class = am.ALARM_CLASS.ERROR
    alarm.confirm_method = am.CONFIRM_METHOD.REP_ACK
    alarm.prior = 3
    alarm.delay_on = 1
    -- alarm.delay_off = 1
    alarm.msg =
        "Авария: " ..
        "am_sine_signal > " .. setpoint .. ". " ..
        "Задержка активации: " .. alarm.delay_on .. ". " ..
        "Задержка деактивации: " .. alarm.delay_off
    alarm.event = getValue("am_sine_signal") > 1

    alarm = atable:alarm{}
    alarm.logic = am.LOGIC.EVENT
    -- alarm.event = getValue("am_script_01_table_01_error_rep_ack_02") > 0
    alarm.class = am.ALARM_CLASS.ERROR
    alarm.msg = "am_script_01_table_01_error_rep_ack_02. Авария"
    alarm.confirm_method = am.CONFIRM_METHOD.REP_ACK
    alarm.prior = 2
    if getValue("am_script_01_table_01_error_rep_ack_02") > 0 then
        alarm.event = true
    end

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_warn_rep_ack_01") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_01_warn_rep_ack_01. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_warn_rep_ack_02") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_01_warn_rep_ack_02. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_info_rep_ack_01") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_01_info_rep_ack_01. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_info_rep_ack_02") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_01_info_rep_ack_02. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }


    -- Метод квитирования REP.
    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_error_rep_01") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_01_table_01_error_rep_01. Авария",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_error_rep_02") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_01_table_01_error_rep_02. Авария",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_warn_rep_01") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_01_warn_rep_01. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_warn_rep_02") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_01_warn_rep_02. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_info_rep_01") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_01_info_rep_01. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_01_info_rep_02") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_01_info_rep_02. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }


    -- -- Скрипт 1 Таблица 2.
    -- -- Метод квитирования REP_ACK.
    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_error_rep_ack_01") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_01_table_02_error_rep_ack_01. Авария",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_error_rep_ack_02") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_01_table_02_error_rep_ack_02. Авария",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_warn_rep_ack_01") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_02_warn_rep_ack_01. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_warn_rep_ack_02") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_02_warn_rep_ack_02. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_info_rep_ack_01") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_02_info_rep_ack_01. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_info_rep_ack_02") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_02_info_rep_ack_02. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }


    -- Метод квитирования REP.
    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_error_rep_01") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_01_table_02_error_rep_01. Авария",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_error_rep_02") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_01_table_02_error_rep_02. Авария",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_warn_rep_01") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_02_warn_rep_01. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_warn_rep_02") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_01_table_02_warn_rep_02. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_info_rep_01") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_02_info_rep_01. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable2:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_01_table_02_info_rep_02") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_01_table_02_info_rep_02. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    --#endregion Обработка тревог.

end
