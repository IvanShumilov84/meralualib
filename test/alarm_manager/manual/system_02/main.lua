--[[
	Тест менеджера тревог в скрипте 2.
]]


--#region Импорт модулей.
local am = require("meralualib.src.alarm_manager")  -- Менеджер тревог.

--#endregion Импорт модулей.


am.manager_settings.alarm_appearance = am.ALARM_APPEARANCE.FLASH

local conf = {  -- Конфигурация менеджера тревог.
    table_id = 3,  -- Номер таблицы тревог.
    module_name = "Система_02.Таблица_03",  -- Имя системы, отображается в комментариях к каналу в генерируемом файле каналов __CREATE_NEWTAGS__.
    ack_btn = true,  -- Создать каналы СИАМ для кнопки квитирования тревог всех классов.
    analog = {  -- Настройки при _LOGIC.ANALOG.
        msg_detail = true,  -- Отображать дополнительную информацию по каналу в сообщении при _LOGIC.ANALOG.
        display_val = true,  -- Отображать значение отслеживаемого параметра в сообщении активной тревоги.
    },
    display_id_at_msg = true,  -- Отображать идентификационный номер тревоги в сообщении.
}
-- local atable = am.Atable:new(conf)  -- Экземпляр таблицы Менеджера тревог.
local atable = am.Atable:new()  -- Экземпляр таблицы Менеджера тревог.
atable.table_id = 3  -- Номер таблицы тревог.
atable.module_name = "Система_02.Таблица_03"
-- atable.module_name = "system_02"  -- Имя системы, отображается в комментариях к каналу в генерируемом файле каналов __CREATE_NEWTAGS__.


-- Менеджер тревог.
function lua_main()

	am:upd()


    -- Скрипт 2 Таблица 3.
    -- Метод квитирования REP_ACK.
    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_error_rep_ack_01") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_02_table_03_error_rep_ack_01. Авария",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_error_rep_ack_02") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_02_table_03_error_rep_ack_02. Авария",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_warn_rep_ack_01") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_02_table_03_warn_rep_ack_01. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_warn_rep_ack_02") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_02_table_03_warn_rep_ack_02. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_info_rep_ack_01") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_02_table_03_info_rep_ack_01. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_info_rep_ack_02") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_02_table_03_info_rep_ack_02. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP_ACK,
        -- prior = 1,
    }


    -- Метод квитирования REP.
    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_error_rep_01") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_02_table_03_error_rep_01. Авария",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_error_rep_02") > 0,
        class = am.ALARM_CLASS.ERROR,
        msg = "am_script_02_table_03_error_rep_02. Авария",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_warn_rep_01") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_02_table_03_warn_rep_01. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_warn_rep_02") > 0,
        class = am.ALARM_CLASS.WARN,
        msg = "am_script_02_table_03_warn_rep_02. Предупреждение",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_info_rep_01") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_02_table_03_info_rep_01. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

    atable:alarm{
        logic = am.LOGIC.EVENT,
        event = getValue("am_script_02_table_03_info_rep_02") > 0,
        class = am.ALARM_CLASS.INFO,
        msg = "am_script_02_table_03_info_rep_02. Инфо",
        confirm_method = am.CONFIRM_METHOD.REP,
        -- prior = 1,
    }

end


